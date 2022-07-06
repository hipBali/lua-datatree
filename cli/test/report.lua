package.path = "../?.lua;" .. package.path

local redc = require "api.core.redis_client_cli"
local dtc = require "api.core.dtcoll"
local dt_red = require "api.core.dtree_redis"
local hfn = require "api.core.hlpfunc"

local json = require "api.core.json"

local function fn_stock_report(stocks)
	t ={}
	-- creates map from products by id, and iterates on each group
	stocks:map("product_id"):each ( 
		function(map_elem, index)
			-- create collection from current product stock details
			local prod_stock = dtc.new(map_elem)
			-- calculates percent of available stock for each product
			stocks[index].sum = prod_stock:sum("quantity")
			stocks[index].avg = hfn.round(prod_stock:avg("quantity"),2)
			table.insert(t,stocks[index])
		end 
	)
	return t
end

local red = redc.connect()
local dt = dt_red.new('BIKESTORE',red)
local result = fn_stock_report(dt:tc_select{object="STOCKS"})
print(json.encode( result ))
