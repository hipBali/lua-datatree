--
-- usage example:
--       http://localhost:8080/bikestore/sum
--  

local dtc = require "api.core.dtcoll"
local redc = require "api.core.redis_client"
local dt_red = require "api.core.dtree_redis"

requestHandler = function()
	local red = redc.connect()
	local dt = dt_red.new('BIKESTORE',red)
	local dataset = dt
		: tc_select{object="PRODUCTS", limit=1, fields={"product_id", "product_name"}, 
			call = function(o)
					local ss = dt:tc_select{object="STOCKS", index="idx_product_id", filter={product_id=o.product_id}}
					o.on_stock = ss:sum("quantity")
					return o
			end}
		
	return { error=0, result = dataset }
end 