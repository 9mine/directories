minetest.register_entity("directories:file", {
    initial_properties = {
        physical = true,
        pointable = true,
        visual = "sprite",
        collide_with_objects = true,
        textures = {"directories_file.png"},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
        is_visible = true,
        makes_footstep_sound = false,
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
        if tool_capabilities.damage_groups.stats == 1 then
            local host_info = get_host_near(puncher)
            local s = get_stats(host_info, self.path)
            local idx = puncher:hud_add({
                hud_elem_type = "text",
                position = {x = 0.5, y = 0.5},
                offset = {x = 0, y = 0},
                text =  "name:      " .. s.name .. "\n" .. 
                        "length:    " .. s.length .. "\n" .. 
                        "owner:     " .. s.uid .. "\n" ..
                        "group:     " .. s.gid .. "\n" .. 
                        "access:    " .. s.atime .. "\n" ..
                        "modified:  " .. s.mtime .. "\n" ..
                        "mod. by:   " .. s.muid .. "\n" ..
                        "mode:      " .. s.mode .. "\n" ..   
                        "type:      " .. s.type .. "\n" ..                                                     
                        "qid:       " .. "\n" ..
                        "       type:       " .. s.qid.type .. "\n" .. 
                        "       version:    " .. s.qid.version .. "\n" ..                                
                        "       path:       " .. s.qid.path .. "\n",                           
                                     
                alignment = {x = 0, y = 0}, -- center aligned
                scale = {x = 100, y = 100} -- covered later
            })
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
