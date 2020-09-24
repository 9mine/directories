minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then
            if (fields["remote_address"] == nil) then return nil end
            local remote_address = fields["remote_address"]
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
            local tcp = socket:tcp()
            local content = get_dir(host_info, conn_path)
            print("dump content" .. dump(content))
            local p1 = {x = 0, y = 0, z = 0}
            local p2 = p1
            platforms.create(p1, 8, "horizontal")
        end
    end)
