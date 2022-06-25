package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dtc = require "api.core.dtcoll"
local dt_red = require "api.core.dtree_redis"
local json = require "api.core.json"

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)
local result = dt
	: select{object="PRODUCTS", limit=10, fields={"product_id", "product_name"}, 
		call = function(o)
				local ss = dt:tc_select{object="STOCKS", index="idx_product_id", filter={product_id=o.product_id}}
				o.on_stock = ss:sum("quantity")
				return o
		end}:content()
		
print(json.encode( result ))