--
-- usage example:
--       http://localhost:8080/bikestore/custorders
--  

local json = require "api.core.json"
local dtc = require "api.core.dbtcoll"
local pool = require "api.core.dbpool"

local calc_total = function(orders)
	dtc.new(orders):each ( function(o)
		dtc.new(o.ORDER_ITEMS):each ( function(o_item)
			-- calculates total of items,amount and discount for each order processing its order_items											
			o.total_items = (o.total_items or 0) + 1
			o.total_amount = (o.total_amount or 0) + o_item.list_price * o_item.quantity
			o.total_discount = (o.total_discount or 0) + o_item.list_price * o_item.discount
		end )
	end )
end

-- customer orders, full detailed list
requestHandler = function(req)
	local db = pool.get("bikestore")
	local dataset = db 
		: select{object="CUSTOMERS"}
			: join{object="ORDERS", index="idx_customer_id"}
				: join{object="ORDER_ITEMS", on="ORDERS", index="idx_order_id"}
					: join{object="PRODUCTS", on="ORDER_ITEMS"} -- index: pk as default		
						: join{object="BRANDS", on="PRODUCTS", merge=true} -- index: pk as default
						: join{object="CATEGORIES", on="PRODUCTS", merge=true} -- index: pk as default
			: func{ on="ORDERS", call = calc_total }
		
	return { error=0, result = dataset:content() }
end 