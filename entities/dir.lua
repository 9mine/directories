-- register directory entity blueprint
minetest.register_entity("directories:dir", {
    initial_properties = {
        physical = true,
        pointable = true,
        visual = "sprite",
        collide_with_objects = true,
        textures = {"directories_dir.png"},
        is_visible = true,
        nametag_color = "black",
        infotext = "",
        static_save = true,
        shaded = true
    },
    -- path of the folder, set at time of adding
    path = "",
    size = 0,
    -- when hit with appropriate tool, create new platform for this directory
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities,
                        dir)
        if tool_capabilities.damage_groups.enter == 1 then
            local pos = puncher:get_pos()
            local node_pos = minetest.find_node_near(pos, 6, {"mine9:platform"})
            local host_info = platforms.get_host_info(node_pos)
            local origin = platforms.get_creation_info(node_pos).origin
            local pos = get_next_pos(origin)
            local content = get_dir(host_info, self.path)
            local orientation = "horizontal"
            local dir_size = content == nil and 2 or #content

            local platform_size = math.ceil(math.sqrt((dir_size / 15) * 100)) <
                                      3 and 3 or
                                      math.ceil(math.sqrt((dir_size / 15) * 100))

            platforms.create(pos, platform_size, orientation, "mine9:platform")
            platforms.set_meta(pos, platform_size, "horizontal", "host_info",
                               host_info)
            puncher:set_pos({x = pos.x + 1, y = pos.y + 1, z = pos.z + 1})
            list_dir(content, pos)
        end

        if tool_capabilities.damage_groups.stats == 1 then
            show_stats(puncher, self.path)
        end
    end,

    get_staticdata = function(self)
        local attributes = self.object:get_nametag_attributes()
        local data = {attr = attributes, path = self.path, size = self.size}
        return minetest.serialize(data)
    end,

    on_activate = function(self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.deserialize(staticdata) or {}
            self.object:set_nametag_attributes(data.attr)
            self.path = data.path
            self.size = data.size
        end
    end
})
