local m = {}

package.path = "../src/?.lua;src/?.lua;" .. package.path
pcall(require, "luarocks.require")
local redis = require 'redis'

local rc 

local default_params = {
    host = '127.0.0.1',
    port = 6379,
}

function m.connect(par)
	params = params or default_params
	local client = redis.connect(params)
	return client
end

return m