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
    local z = vector.new(math.random(s), math.random(s), math.random(s))
    print("ZERO VECTOR: " .. dump(z))
    return vector.add(p, vector.multiply(vector.add(p, z), d))
end
