print("directories mod is loading ...")
-- libs
np = require '9p'
data = require 'data'
nmine = require 'nmine'
socket = require 'socket'
pprint = require 'pprint'
readdir = require 'readdir'
platforms = require 'platforms'
-- mod files
local path = minetest.get_modpath("directories")
dofile(path .. "/tools.lua")
dofile(path .. "/events.lua")
dofile(path .. "/on_join.lua")
print("directories mod finished loading.")