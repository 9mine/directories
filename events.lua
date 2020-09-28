minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then
            if (fields["remote_address"] == nil) then return nil end
            local host_info = parse_remote_address(fields["remote_address"])
            if not host_info["host"] or not host_info["port"] then
                return
            end
            local content = get_dir(host_info, host_info.path)
            local size = content == nil and 2 or
                             math.ceil(math.sqrt((#content / 15) * 100))
            local pos = get_pos_rand(player, size)
            platforms.create(pos, size, "horizontal", "mine9:platform")
            platforms.set_meta(pos, size, "horizontal", "host_info", host_info)
            if content ~= nil then list_dir(content, pos) end
        end

        if formname == "directories:create_file" then
            if (fields["file_name"] == nil) then return nil end
            local file_name = fields["file_name"]
            local file_content = fields["file_content"]
            local pos = player:get_pos()
            local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
            local creation_info = platforms.get_creation_info(node_pos)
            local host_info = platforms.get_host_info(node_pos)
            local empty_slots = platforms.get_empty_slots(node_pos)
            local full_slots = platforms.get_full_slots(node_pos)
            create_file(host_info, file_name, file_content)
            local file = get_stat(host_info, file_name)

            local index, empty_slot = next(empty_slots)
            local p = spawn_file(file, empty_slot, creation_info["orientation"])
            table.insert(full_slots, p)
            table.remove(empty_slots, index)

            platforms.set_empty_slots(node_pos, empty_slots)
            platforms.set_full_slots(node_pos, full_slots)

        end

    end)
