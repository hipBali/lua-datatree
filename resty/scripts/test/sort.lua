--
-- usage example:
--		curl localhost:8080/bikestore/sort
--  

local json = require "api.core.json"
local redc = require "api.core.redis_client"
local dt_red = require "api.core.dtree_redis"

requestHandler = function()
	local red = redc.connect()
	local dt = dt_red.new('BIKESTORE',red)
	local dataset = dt
		: select{object="ORDERS", fields={"order_id","customer_id","order_date"}, filter={customer_id=100}}
		: join{ object="CUSTOMERS", fields={"first_name","last_name","email"}, merge=true }
		-- sort result dataset by date in descending order
		: sort{ function(a,b) return a.order_date > b.order_date end } 

	return { error=0, result = dataset:tc() }
end 