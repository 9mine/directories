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
    print("POSITION: " .. dump(p))
    print("DIRECTION: " .. dump(d))
    print("SIZE: " .. dump(s))
    local ds = 1
    -- TODO: spawn in right position
    -- local s = vector.new(ds, ds, ds)
    -- local increase = vector.multiply(d, s)
    -- local endpoint = vector.add(p, increase)
    -- endPos = startPos + direction * distance;
    local c = vector.new(s, 0, s)

    return vector.round(vector.add(p, vector.multiply(c, d)))
end
