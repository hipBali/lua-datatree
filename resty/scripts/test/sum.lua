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
	local dataset = dt:tc_select{object="PRODUCTS", fields={"product_id", "product_name"}, call = 
		function(o)
			local ss = ds:select_ix{object="STOCKS", index="idx_product_id", item=o.product_id}
			o.on_stock = dtc.new(ss):sum("quantity")
			if o.on_stock==0 then
				return nil
			end
			return o
		end}
		
	return { error=0, result = dataset }
end 