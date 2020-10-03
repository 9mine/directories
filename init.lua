-- storage for mod directories 
sd = minetest.get_mod_storage()
sd:set_string("platforms", minetest.serialize({}))
print("directories mod is loading ...")
-- libs
np = require '9p'
data = require 'data'
socket = require 'socket'
pprint = require 'pprint'
readdir = require 'readdir'
filesize = require 'filesize'
bit = require 'bit'
-- mod files
current_hud = {}
local path = minetest.get_modpath("directories")
dofile(path .. "/help_func_files.lua")
dofile(path .. "/entities/dir.lua")
dofile(path .. "/entities/file.lua")
dofile(path .. "/help_func.lua")
dofile(path .. "/tools.lua")
dofile(path .. "/events.lua")
dofile(path .. "/on_join.lua")
print("directories mod finished loading.")
