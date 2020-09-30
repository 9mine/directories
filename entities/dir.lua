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
            local player_name = puncher:get_player_name()
            change_directory(player_name, self.path)
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
