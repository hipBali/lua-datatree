--
-- usage example:
-- 		curl -X POST -H "Content-Type: application/json" \
--		-d '{"customer_id":123, "staff_id":8}' \
--		localhost:8080/bikestore/filter
--  

local redc = require "api.core.redis_client"
local dt_red = require "api.core.dtree_redis"

requestHandler = function(flt_param)
	local red = redc.connect()
	local dt = dt_red.new('BIKESTORE',red)
	local dataset = dt 
		: tc_select{object="ORDERS", filter = flt_param }
	return { error=0, result = dataset }
end 