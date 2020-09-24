minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "cdmod:spawn_rootdir" then
            if (fields["remote_address"] == nil) then end
            local conn_string = fields["remote_address"]
            local t = {}
            for str in string.gmatch(remote_address, "[^!]+") do
                table.insert(t, str)
            end
            local conn_type = t[1]
            local conn_host = t[2]
            local conn_port = tonumber(t[3])
            local path = "/"
            if t[4] ~= nil then path = t[4] end
            local host_info = {
                type = conn_type,
                host = conn_host,
                port = conn_port,
                path = path
            }

            local tcp = socket:tcp()
            local connection, err = tcp:connect(conn_host, conn_port)
            if (err ~= nil) then
                print("dump of error newest .. " .. dump(err))
                print("Connection error")
                return
            end
            local conn = np.attach(tcp, "dievri", "")
            tcp:close()
        end
    end)
