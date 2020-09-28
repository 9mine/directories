minetest.register_on_joinplayer(function(player)
    local inventory = player.get_inventory(player)
    nmine.populate_inventory(inventory, "directories:enter",
                             "directories:spawn_rootdir", "directories:read",
                             "directories:write", "directories:stats")
end)
