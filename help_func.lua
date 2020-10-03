parse_mode_bits = function(mode)
    local res = {}
    local perms = {
        ["DIR"] = 0x80,
        ["APPEND"] = 0x40,
        ["EXCL"] = 0x20,
        ["MOUNT"] = 0x10,
        ["AUTH"] = 0x08,
        ["TMP"] = 0x04,
        ["LINK"] = 0x02
    }

    local owner = {}
    table.insert(owner, {["r"] = 0x0100})
    table.insert(owner, {["w"] = 0x0080})
    table.insert(owner, {["x"] = 0x0040})
    local group = {}
    table.insert(group, {["r"] = 0x0020})
    table.insert(group, {["w"] = 0x0010})
    table.insert(group, {["x"] = 0x0008})
    local others = {}
    table.insert(others, {["r"] = 0x0004})
    table.insert(others, {["w"] = 0x0002})
    table.insert(others, {["x"] = 0x0001})

    local permissions = {}
    table.insert(permissions, owner)
    table.insert(permissions, group)
    table.insert(permissions, others)

    local bytes = {}
    for i = 0, 3 do bytes[i + 1] = bit.band(bit.rshift(mode, i * 8), 0xff) end
    local d = data.new {unpack(bytes)}

    local l = data.layout {
        bits = {24, 8, 'number', 'le'},
        permissions = {0, 16, 'number', 'le'}
    }

    local result = d:layout(l)

    local mode_bits = {}
    for k, v in pairs(perms) do
        local r = (bit.band(result.bits, v) ~= 0) and table.insert(mode_bits, k)
    end
    res["mode_bits"] = mode_bits

    local p = ""
    for _, v in pairs(permissions) do
        for m, b in pairs(v) do
            for y, z in pairs(b) do
                local r = (bit.band(result.permissions, z) ~= 0) and y or "-"
                p = p .. r
            end
        end
    end

    res["perms"] = p

    return res
end

get_stats = function(host_info, path)
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        tcp:close()
        return
    end
    local conn = np.attach(tcp, "root", "")

    local f = conn:newfid()
    local stats = nil
    if pcall(np.walk, conn, conn.rootfid, f, path) then
        conn:open(f, 0)
        stats = conn:stat(f)
        conn:clunk(f)
    end
    tcp:close()
    return stats
end

get_dir = function(host_info, path)
    path = path or host_info["path"]
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        tcp:close()
        return
    end
    local conn = np.attach(tcp, "root", "")
    local result, dir = pcall(readdir, conn, path == "/" and "./" or path)
    if not result then
        tcp:close()
        return
    end
    local listing = {}
    if dir ~= nil then
        for n, file in pairs(dir) do
            listing[file.name] = {
                name = file.name,
                path = (path == "/" and "/" .. file.name or path .. "/" ..
                    file.name),
                type = (file.qid.type == 128 and 128 or 0)
            }
        end
        return listing
    end
end

parse_remote_address = function(remote_address)
    local t = {}
    for str in string.gmatch(remote_address, "[^! ]+") do
        table.insert(t, str)
    end
    local conn_type = t[1]
    local conn_host = t[2]
    local conn_port = tonumber(t[3])
    local conn_path = "/"
    if t[4] ~= nil then conn_path = t[4] end
    local host_info = {
        type = conn_type,
        host = conn_host,
        port = conn_port,
        path = conn_path
    }
    return host_info
end

get_pos_rand = function(player, s)
    local p = player:get_pos()
    local d = player:get_look_dir()
    local c = vector.new(-(s / 2), 0, (s / 2))
    return vector.round(vector.add(p, vector.multiply(c, d)))
end

list_dir = function(listing, pos)
    local empty_slots = platforms.storage_get(pos, "empty_slots")
    local orientation = platforms.get_creation_info(pos).orientation
    if listing ~= nil then
        for n, file in pairs(listing) do
            local index, empty_slot = next(empty_slots)
            local p = spawn_file(file, empty_slot, orientation)
            listing[file.name].pos = p
            table.remove(empty_slots, index)
        end
    end
    platforms.storage_set(pos, "empty_slots", empty_slots)
    platforms.storage_set(pos, "listing", listing)
    return listing
end

get_next_pos = function(storage)
    local x = storage.x + math.random(-15, 15)
    local y = storage.y + 10 + math.random(5)
    local z = storage.z + math.random(-15, 15)
    return {x = x, y = y, z = z}
end

spawn_file = function(file, empty_slot, orientation)

    local p = {
        x = empty_slot.x,
        y = orientation == "horizontal" and empty_slot.y + math.random(3, 8) or
            empty_slot.y,
        z = orientation == "horizontal" and empty_slot.z or empty_slot.z +
            math.random(3, 8)
    }

    local entity = minetest.add_entity(p,
                                       file.type == 128 and "directories:dir" or
                                           "directories:file")

    entity:set_nametag_attributes({color = "black", text = file.name})
    entity:set_armor_groups({immortal = 0})
    entity:set_acceleration({
        x = 0,
        y = orientation == "horizontal" and -6 or 0,
        z = orientation == "horizontal" and 0 or -6
    })

    entity:get_luaentity().path = file.path

    return empty_slot, entity
end

get_host_near = function(puncher)
    local pos = puncher:get_pos()
    local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
    return platforms.storage_get(node_pos, "host_info")
end

show_stats = function(puncher, path)
    local host_info = get_host_near(puncher)
    local s = get_stats(host_info, path)
    local result = parse_mode_bits(s.mode)
    local mode_bits = ""
    for k, v in ipairs(result["mode_bits"]) do
        mode_bits = mode_bits .. v .. " "
    end
    local perms = result["perms"]
    puncher:hud_remove(current_hud[puncher:get_player_name()])
    local stats = puncher:hud_add({
        hud_elem_type = "text",
        position = {x = 0.8, y = 0.2},
        offset = {x = 0, y = 0},
        text = "name:\t\t" .. s.name .. "\n" .. "length:\t\t" ..
            filesize(s.length) .. "\n" .. "owner:\t\t" .. s.uid .. "\n" ..
            "group:\t\t" .. s.gid .. "\n" .. "access:\t\t" ..
            os.date("%x %X", s.atime) .. "\n" .. "modified:\t\t" ..
            os.date("%x %X", s.mtime) .. "\n" .. "mod. by:\t\t" ..
            (s.muid == "" and "-" or s.muid) .. "\n" .. "mode:\t\t" ..
            (mode_bits == "" and "FILE" or mode_bits) .. "\n" .. "perms:\t\t" ..
            perms .. "\n" .. "type:\t\t" .. s.type .. "\n" .. "qid:\t\t" .. "\n" ..
            "       type:\t" .. s.qid.type .. "\n" .. "       version:\t" ..
            s.qid.version .. "\n" .. "       path:\t" .. "0x" ..
            string.format("%08X%08X", s.qid.path_hi, s.qid.path_lo) .. "\n",

        alignment = {x = 1, y = 0}
    })
    current_hud[puncher:get_player_name()] = stats
end

change_directory = function(player_name, destination)
    local node_pos, player = nmine.node_pos_near(player_name)

    local host_info = platforms.storage_get(node_pos, "host_info")

    local storage = platforms.get_creation_info(node_pos).storage

    local pos = get_next_pos(storage)

    destination = string.match(destination, "^/") and destination or
                      host_info.path .. "/" .. destination

    host_info.path = destination

    local content = get_dir(host_info)

    local orientation = "horizontal"

    local dir_size = content == nil and 2 or #content

    local platform_size = platforms.get_size_by_dir(dir_size)

    local count = sd:get_int("count") + 1

    local creation_info = platforms.create(pos, platform_size, orientation,
                                           "mine9:platform", count)

    platforms.storage_set(pos, "host_info", host_info)

    player:set_pos({x = pos.x + 1, y = pos.y + 1, z = pos.z + 1})

    local listing = list_dir(content, pos)

    sd:set_int("count", count)

    local sd_platforms = minetest.deserialize(sd:get_string("platforms"))

    sd_platforms[count] = {}
    sd_platforms[count].listing = lst
    sd_platforms[count].host_info = host_info
    sd_platforms[count].creation_info = creation_info

    sd:set_string("platforms", minetest.serialize(sd_platforms))

end

remove_file = function(file) file:remove() end

compare_listings = function(pos, old_listing, new_listing)
    local empty_slots = platforms.storage_get(pos, "empty_slots")
    local creation_info = platforms.get_creation_info(pos)
    local orientation = creation_info.orientation
    local count = creation_info.count
    for k, v in pairs(new_listing) do
        if old_listing[k] ~= nil then
            new_listing[k] = old_listing[k]
            old_listing[k] = nil
        else
            local index, empty_slot = next(empty_slots)
            local p = spawn_file(v, empty_slot, orientation)
            new_listing[k].pos = p
            table.remove(empty_slots, index)
        end
    end
    for k, v in pairs(old_listing) do
        local objects = minetest.get_objects_inside_radius(v.pos, 1.3)
        if objects[1] ~= nil then
            objects[1]:set_acceleration({x = 0, y = 20, z = 0})
            objects[1]:set_properties({
                physical = false,
                textures = {
                    "directories_file.png^[colorize:grey:" ..
                        math.random(50, 200)
                }
            })
            minetest.after(3, remove_file, objects[1])

            table.insert(empty_slots, v.pos)
        end
    end
    local sd_platforms = minetest.deserialize(sd:get_string("platforms"))
    sd_platforms[count].listing = new_listing
    sd:set_string("platforms", minetest.serialize(sd_platforms))
    platforms.storage_set(pos, "listing", new_listing)
    platforms.storage_set(pos, "empty_slots", empty_slots)
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end
