minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then
            if (fields["remote_address"] == nil) then return nil end
            local host_info = parse_remote_address(fields["remote_address"])
            if not host_info["host"] or not host_info["port"] then return end
            local content = get_dir(host_info, host_info.path)
            local size = content == nil and 2 or math.ceil(math.sqrt((#content / 15) * 100))
            local pos = get_pos_rand(player, size)
            platforms.create(pos, size, "horizontal", "mine9:platform")
            if content ~= nil then
                list_dir(content, pos)
            end
        end
    end)
