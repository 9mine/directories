minetest.register_on_player_receive_fields(
    function(player, formname, fields)
        if formname == "directories:spawn_rootdir" then

            if (fields["remote_address"] == nil) then return nil end

            local host_info = parse_remote_address(fields["remote_address"])
            if not host_info["host"] or not host_info["port"] then
                return
            end

            local listing = get_dir(host_info, host_info.path)
            local size = listing == nil and 2 or
                             platforms.get_size_by_dir(tablelength(listing))

            local pos = get_pos_rand(player, size)

            local count = sd:get_int("count") + 1

            local creation_info = platforms.create(pos, size, "horizontal",
                                                   "mine9:platform", count)

            platforms.storage_set(pos, "host_info", host_info)

            if listing ~= nil then
                local lst = list_dir(listing, pos)
                sd:set_int("count", count)

                local sd_platforms = minetest.deserialize(
                                         sd:get_string("platforms"))
                sd_platforms[count] = {}
                sd_platforms[count].listing = lst
                sd_platforms[count].host_info = host_info
                sd_platforms[count].creation_info = creation_info

                sd:set_string("platforms", minetest.serialize(sd_platforms))
            end

        end

        if formname == "directories:create_file" then

            if (fields["file_name"] == nil) then return nil end

            local file_name = fields["file_name"]
            local file_content = fields["file_content"]

            local pos = player:get_pos()
            local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})

            local creation_info = platforms.get_creation_info(node_pos)
            local host_info = platforms.storage_get(node_pos, "host_info")
            local empty_slots = platforms.storage_get(node_pos, "empty_slots")

            create_new_file(host_info, file_name, file_content)

            local index, empty_slot = next(empty_slots)

            local file = get_stat(host_info, file_name)

            local p = spawn_file(file, empty_slot, creation_info["orientation"])

            table.remove(empty_slots, index)

            platforms.storage_set(node_pos, "empty_slots", empty_slots)
        end

    end)
