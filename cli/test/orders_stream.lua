package.path = "../?.lua;" .. package.path

local json = require "api.core.json"
local dtc = require "api.core.dtcoll"
local redc = require "api.core.redis_client_cli"
local dt_red = require "api.core.dtree_redis"

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

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)
local dataset = dt 
	: select{object="CUSTOMERS", limit=50, call=
		function(o)
			local ord_ss = dt:select_ix{object="ORDERS", index="customer_id", item=o.customer_id}
			o.ORDERS = ord_ss
			dtc.new(o.ORDERS):each(
				function(oi)
					local ordit_ss = dt:select_ix{object="ORDER_ITEMS", index="order_id", item=oi.order_id}
					oi.ORDER_ITEMS = ordit_ss
				end
			)
			calc_total(o.ORDERS)
			-- call streaming function here
			io.stdout:write(json.encode(o))
			io.stdout:write( "\n" )
			io.flush()
			-------------------------------
			return o
		end
	}