local json = require "cjson"
local pool = require "api.core.dbpool"

-- globals
requestHandler = nil
local params = nil
local home = "data/"

-- handle request	
local ret = { error=1, result = {}} 	-- bad request
local reqPath = string.gsub(ngx.var.request_uri, "?.*", ""):sub(2)

if ngx.req.get_method() == "POST" then
	ngx.req.read_body()
	params = json.decode(ngx.req.get_body_data() or {})
end
dofile( home..reqPath..".lua" )

-- execute endpoint
if type(requestHandler)=="function" then
	local ran, errorMsg = pcall( requestHandler, params )
	if not ran then
		errorMsg = {error=errorMsg}
	end
	ret = errorMsg 
end	

ngx.say(json.encode(ret)) 

ret = nil
