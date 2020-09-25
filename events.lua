minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then
            if (fields["remote_address"] == nil) then return nil end
            local host_info = parse_remote_address(fields["remote_address"])
            local content = get_dir(host_info, host_info.path)
            local p1 = {x = 0, y = 4, z = 0}
            local p2 = p1
            platforms.create(p1, #content, "horizontal", "mine9:platform")
        end
    end)
