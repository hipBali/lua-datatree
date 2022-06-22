--
-- usage example:
-- 		curl localhost:8080/data/bikestore/load
--  

local dbtloader = require "data.bikestore.data.dataloader"
local pool = require "api.core.dbpool"

requestHandler = function()
	-- remove previous version
	pool.set("bikestore",nil)
	collectgarbage("collect")
	return {"ok"}
end 