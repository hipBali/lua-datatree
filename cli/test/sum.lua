package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dtc = require "api.core.dtcoll"
local dt_red = require "api.core.dtree_redis"
local json = require "api.core.json"

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)
local result = dt:tc_select{object="PRODUCTS", fields={"product_id", "product_name"}, call = 
	function(o)
		local ss = ds:select_ix{object="STOCKS", index="idx_product_id", item=o.product_id}
		o.on_stock = dtc.new(ss):sum("quantity")
		if o.on_stock==0 then
			return nil
		end
		return o
	end
}
		
print(json.encode( result ))