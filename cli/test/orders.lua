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

local test_range = {100,200}

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)
local dataset = dt 
	: select{object="CUSTOMERS", range=test_range}
		: join{object="ORDERS", index="customer_id"}
			: join{object="ORDER_ITEMS", on="ORDERS", index="order_id"}
		: func{ on="ORDERS", call = calc_total } 

print(json.encode(dataset:content()))