--
-- usage example:
--		curl localhost:8080/bikestore/sort
--  

local pool = require "api.core.dbpool"

requestHandler = function()
	local db = pool.get("bikestore")
	local dataset = db 
		: select{object="ORDERS", fields={"order_id","customer_id","order_date"}, limit=20}
		: join{ object="CUSTOMERS", fields={"first_name","last_name","email"}, merge=true }
		-- sort result dataset by date in descending order
		: sort{ function(a,b) return a.order_date > b.order_date end } 
	return { error=0, result = dataset:content() }
end 