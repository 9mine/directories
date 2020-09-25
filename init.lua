print("directories mod is loading ...")
-- libs
np = require '9p'
data = require 'data'
socket = require 'socket'
pprint = require 'pprint'
readdir = require 'readdir'
-- mod files
local path = minetest.get_modpath("directories")
dofile(path .. "/entities/dir.lua")
dofile(path .. "/entities/file.lua")
dofile(path .. "/help_func.lua")
dofile(path .. "/tools.lua")
dofile(path .. "/events.lua")
dofile(path .. "/on_join.lua")
print("directories mod finished loading.")
