local m = {}

local redis = require "resty.redis"

local rc 

function m.connect()
	local red = redis:new()
	red:set_timeouts(1000, 1000, 1000) -- 1 sec
	-- or connect to a unix domain socket file listened
	-- by a redis server:
	--     local ok, err = red:connect("unix:/path/to/redis.sock")
	local ok, err = red:connect("127.0.0.1", 6379)
	if not ok then
		ngx.say("failed to connect: ", err)
		return
	end
	rc = red
	return red
end

function m.close()
	local ok, err = rc:close()
    if not ok then
		ngx.say("failed to close: ", err)
		return
	end
	return true
end

function m.keepalive(sec,size)
	local ok, err = rc:set_keepalive(sec*1000, size)
	if not ok then
		ngx.say("failed to set keepalive: ", err)
		return
	end
	return true
end


return m