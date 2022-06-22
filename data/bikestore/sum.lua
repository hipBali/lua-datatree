--
-- usage example:
--       http://localhost:8080/bikestore/sum
--  

local dtc = require "api.core.dbtcoll"
local pool = require "api.core.dbpool"

requestHandler = function()
	local db = pool.get("bikestore")
	local dataset = db
		: tc_select{object="PRODUCTS", limit=1, fields={"product_id", "product_name"}, 
			call = function(o)
					local ss = db:tc_select{object="STOCKS", index="idx_product_id", filter={product_id=o.product_id}}
					o.on_stock = ss:sum("quantity")
					return o
			end}
		
	return { error=0, result = dataset }
end 