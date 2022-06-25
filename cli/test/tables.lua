package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dt_red = require "api.core.dtree_redis"
local json = require "api.core.json"

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)

for k,v in pairs(dt._base) do

	print(string.format("name:%s  size:%d",k,v))
end
