--
-- usage example:
-- 		curl localhost:8080/bikestore/report
--  

local pool = require "api.core.dbpool"
local dtc = require "api.core.dbtcoll"
local hfn = require "api.core.hlpfunc"

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

requestHandler = function(flt_param)
	local db = pool.get("bikestore")
	local report = fn_stock_report(db:tc_select{object="STOCKS"})
	return { error=0, result = report }
end 