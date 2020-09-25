minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then
            if (fields["remote_address"] == nil) then return nil end
            local host_info = parse_remote_address(fields["remote_address"])
            if not host_info["host"] or not host_info["port"] then return end
            local content = get_dir(host_info, host_info.path)
            local p = get_pos_rand(player, #content)
            platforms.create(p, #content, "horizontal", "mine9:platform")
        end
    end)
