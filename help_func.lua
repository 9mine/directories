get_dir = function(host_info, path)
    local tcp = socket:tcp()
    local connection, err = tcp:connect(host_info["host"], host_info["port"])
    if (err ~= nil) then
        print("Connection error: " .. dump(err))
        tcp:close()
        return
    end
    local conn = np.attach(tcp, "root", "/")
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
    for n, file in pairs(content) do
        local index, empty_slot = next(empty_slots)
        local p = spawn_file(file, empty_slot, orientation)
        table.insert(full_slots, p)
        table.remove(empty_slots, index)
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
