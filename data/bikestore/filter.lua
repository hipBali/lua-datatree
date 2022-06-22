--
-- usage example:
-- 		curl -X POST -H "Content-Type: application/json" \
--		-d '{"customer_id":123, "staff_id":4}' \
--		localhost:8080/bikestore/filter
--  

local pool = require "api.core.dbpool"

requestHandler = function(flt_param)
	local oo
	local db = pool.get("bikestore")
	local dataset = db 
		: tc_select{object="ORDERS", filter = flt_param }
	return { error=0, result = dataset }
end 