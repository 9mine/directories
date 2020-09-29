parse_mode_bits = function(mode)
    local res = {}
    local perms = {
        ["DIR"] = 0x80,
        ["APPEND"] = 0x40,
        ["EXCL"] = 0x20,
        ["MOUNT"] = 0x10,
        ["AUTH"] = 0x08,
        ["TMP"] = 0x04,
        ["LINK"] = 0x02,
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
            local r = (bit.band(result.permissions, z) ~=  0) and y or "-"
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
    local content = {}
    if dir ~= nil then
        for n, file in pairs(dir) do
            table.insert(content, {
                name = file.name,
                path = (path == "/" and "/" .. file.name or path .. "/" ..
                    file.name),
                type = (file.qid.type == 128 and 128 or 0)
            })
        end
        return content
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

list_dir = function(content, pos)
    local empty_slots = platforms.get_empty_slots(pos)
    local orientation = platforms.get_creation_info(pos).orientation
    local full_slots = {}
    if content ~= nil then
        for n, file in pairs(content) do
            local index, empty_slot = next(empty_slots)
            local p = spawn_file(file, empty_slot, orientation)
            table.insert(full_slots, p)
            table.remove(empty_slots, index)
        end
    end
    platforms.set_empty_slots(pos, empty_slots)
    platforms.set_full_slots(pos, full_slots)

end

get_next_pos = function(origin)
    local x = origin.x + math.random(-15, 15)
    local y = origin.y + 10 + math.random(5)
    local z = origin.z + math.random(-15, 15)
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
    return p, entity
end

get_host_near = function(puncher)
    local pos = puncher:get_pos()
    local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
    return platforms.get_host_info(node_pos)
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
        text = "name:\t\t" .. s.name .. "\n" .. 
        "length:\t\t" ..
            filesize(s.length) .. "\n" .. 
            "owner:\t\t" .. s.uid .. "\n" ..
            "group:\t\t" .. s.gid .. "\n" .. 
            "access:\t\t" .. os.date("%x %X", s.atime) .. "\n" .. 
            "modified:\t\t" .. os.date("%x %X", s.mtime) .. "\n" .. 
            "mod. by:\t\t" .. (s.muid == "" and "-" or s.muid) .. "\n" .. 
            "mode:\t\t" .. (mode_bits == "" and "FILE" or mode_bits) .. "\n" .. 
            "perms:\t\t" .. perms .. "\n" ..
            "type:\t\t" .. s.type .. "\n" .. 
            "qid:\t\t" .. "\n" .. 
            "       type:\t" .. s.qid.type .. "\n" ..
            "       version:\t" .. s.qid.version .. "\n" .. 
            "       path:\t" .. "0x" .. string.format("%08X%08X", s.qid.path_hi, s.qid.path_lo) .. "\n",


        alignment = {x = 1, y = 0} 
    })
    current_hud[puncher:get_player_name()] = stats
end

