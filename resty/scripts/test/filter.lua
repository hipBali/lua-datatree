--
-- usage example:
-- 		curl -X POST -H "Content-Type: application/json" \
--		-d '{"filter":{"customer_id":123, "staff_id":8}, "range":[100,200]}' \
--		localhost:8080/test/filter
--  

local redc = require "api.core.redis_client"
local dt_red = require "api.core.dtree_redis"

requestHandler = function(params)
	local red = redc.connect()
	local dt = dt_red.new('BIKESTORE',red)
	local dataset = dt 
		: tc_select{object="ORDERS", filter = params.filter, range=params.range }
	return { error=0, result = dataset }
end 
