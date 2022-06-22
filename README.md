# lua-datatree
Lua based dataset analyzer tool

## Requirements
>**OpenResty**
>[openresty.org](https://openresty.org/)

## Installation

1. *install openresty*
2. *create your own workspace*
~~~
    mkdir ~/work 
    cd ~/work 
    git clone https://github.com/hipBali/lua-datatree.git
    cd lua-datatree
    mkdir logs/ conf/ 
~~~

3. *prepare the nginx.conf config file*
You can use the configuration attached to the package, or just create a simple plain text file named  `conf/nginx.conf`  with the following contents in it:
~~~
    worker_processes 1;
    events {
      worker_connections 8;
    }
    http {
      access_log /dev/stdout;
      error_log /dev/stderr; 
      server {
        listen 8080;
        server_name localhost;
        charset utf-8;
        charset_types application/json;
        default_type application/json;
        location / {
          content_by_lua_file api/rest.lua;
        }
      }
    }
~~~
 4. *run Nginx rest service*
~~~
nginx -p `pwd`/ -c conf/nginx.conf
~~~

## Usage
### using curl without parameters
~~~
$ curl localhost:8080/bikestore/sum
127.0.0.1 - - [22/Jun/2022:10:48:40 +0200] "GET /bikestore/sum HTTP/1.1" 200 98 "-" "curl/7.68.0"
{"result":[{"product_id":1,"product_name":"Trek 820 - 2016","on_stock":55}],"error":0}
~~~
### using curl with parameters
~~~
$ curl -X POST -H "Content-Type: application/json" \
-d '{"customer_id":123, "staff_id":1}' \
localhost:8080/bikestore/filter
127.0.0.1 - - [22/Jun/2022:10:52:11 +0200] "POST /bikestore/filter HTTP/1.1" 200 360 "-" "curl/7.68.0"
{"result":[
{"order_date":"2003-01-25","order_id":3258,"order_status":4,"shipped_date":"2003-01-27","store_id":1,"required_date":"2003-01-28","customer_id":123,"staff_id":1},
{"order_date":"2007-01-04","order_id":10616,"order_status":4,"shipped_date":"2007-01-07","store_id":1,"required_date":"2007-01-09","customer_id":123,"staff_id":1}
],"error":0}
~~~
## How-to

**create dataloader**
		The dataloader should define detailed structure of the json file(s).
		
~~~
local dataPath = "mydata/bikestore/"

local db_model = {
	{ name = "CUSTOMERS", 
	filename = dataPath.."customers.json", 
	index = {{ name = "pk", segments = {"customer_id"} }},
	},
	...
}
~~~

publish an entry point to the loader
		
~~~
local dbt = require"api.core.dbtree"
local dbu = require "api.core.dbutil"

local m = {}

function m.getDbt()
	return dbt.new("BIKESTORE",dbu.loadModel(db_model,"rows"))
end

return m
~~~
		
*Loading dataset from different json format*
						dbu.loadModel(dataset_descriptor,**path_to_dataset**)
		
*this loader tries to find records at the 'rows' node, so you can change the path with changing this parameter*

~~~
{
"table": "products",
"rows":
[
	{
		"product_id": 1,
		"product_name": "Trek 820 - 2016",
		"brand_id": 9,
		"category_id": 6,
		"model_year": 2016,
		"list_price": 379.99
	},
...
~~~

**initialize and load dataset at service startup**
Add loader script with an 'init_by_lua_block' command to ___nginx.conf___ file,
~~~
http {

  access_log /dev/stdout;
  error_log /dev/stderr;
  
  # this runs before forking out nginx worker processes:
  init_by_lua_block { 
	local dbtloader = require "bikestore.data.dataloader"
	local pool = require "api.core.dbpool"
	local db = dbtloader.getDbt()
	pool.set("bikestore",db)
  }
  
  server {
    listen 8080;
    server_name localhost;
	...

~~~
or create your own data loader script and execute it anytime
~~~
local dbtloader = require "bikestore.data.dataloader_big"
local pool = require "api.core.dbpool"

requestHandler = function()
	-- remove previous version
	pool.set("bikestore",nil)
	collectgarbage("collect")
	-- load new version
	local db = dbtloader.getDbt()
	pool.set("bikestore",db)
	local _,desc = db:getInfo()
	return{desc}
end 
~~~

**prepare your query**
~~~
local pool = require "api.core.dbpool"

requestHandler = function()
	local dataSet = pool.get("bikestore")
	local script= dataSet: ...
	...
	return { error=0, result = script:content() }
end 
~~~

## Api documentation

***DataTree class***

Datatree is a complete representation of the datas loaded into the memory as set of data. Datatree can't be converted  directly to JSON you should use **content()** or **toCollection()** methods to convert it first to a lua table. 
The following methods available to manipulate your dataset.

**select{ }**
Result is the base dataset for further manipulating.
	*parameters:*
- object: 
name of the json object to select as main element of your query
- as:
alias for object
- index:
name of required index, default is "pk"
- filter:
table of key-value pairs or function
- fields:
list of fields included in each record, default is all
- limit:
maximum size of result dataset
- call:
user defined function wich is called on each records in result dataset

*examples*:

~~~
ds:select{object="PRODUCTS", as="MYPROD", limit=3}

-- filter list
ds:select{object="PRODUCTS", filter={"product_id=1}}

-- filter function
ds:select{object="PRODUCTS", filter=
	function(p) return p.product_id<100 end
	}

-- select fields
ds:select{object="PRODUCTS", fields={"product_id","product_name"}}

-- process each objects
ds:select{object="PRODUCTS", call=function(o) ... end }

-- indexed 'subselect', calculates stocks available for each products
ds:select{object="PRODUCTS", fields={"product_id", "product_name"}, 
			call = function(o)
					local ss = ds:select{object="STOCKS", index="idx_product_id", filter={product_id=o.product_id}}:toCollection()
					o.on_stock = dtc.new(ss.STOCKS):sum("quantity")
					return o
			end}
~~~

**join{ }**
Adds related object(s) to your targeted object
	*parameters:*
- on: 
name of the targeted object in the dataset chain, default is the main dataset
- as:
alias for object
- index:
name of required index, default is "pk"
- filter:
-- table of key-value pairs or function
or
-- function with boolean return value

- fields:
list of fields included in each record, default is all
- limit:
maximum size of result dataset
- merge:
-- boolean parameter, on true the engine will merge the joined object properties with targeted object if the relation of object is 1:1
or
-- function(target, source)  the engine calls the given function to manage 1:n relation merge
- call:
function(target,source) the engine calls the given function

*example*:

~~~
ds:select{object="PRODUCTS"}
	:join{object="STOCKS",index="idx_product_id"}
	:join{object="STORES", on="STOCKS", merge=true}
~~~

**func{ }** or **fn{ }**
Calls a function on any element of the dataset chain
	*parameters:*
- on: 
name of the targeted object in the dataset chain which is the input parameter of your function 
- call:
function to call
*example*:
~~~
function fn_stock_calc(stocks)
	...
end

ds:select{object="PRODUCTS"} 		
	:join{object="STOCKS", index="idx_product_id"} 
	:func{on="STOCKS", call = fn_stock_calc}
~~~

**sort{ }**
Calls a sort function on any element of the dataset chain
	*parameters:*
- on: 
name of the targeted object in the dataset chain which is will be sorted
- call:
function to call, input parameter is a data collection
*example*:
~~~
-- sort result dataset by date in descending order
ds:select{object="ORDERS", fields={"order_id","customer_id","order_date"}}
:sort{ function(a,b) return a.order_date > b.order_date end } 
~~~

**tc_select{ }**
Same as ___select___ method, but the result will be automatically converted to ___collection___ class

**tc_join{ }**
Same as ___join___ method, but the result will be automatically converted to ___collection___ class

---
The datatree object contains raw data including some non relevant informatons beyond what is expected. The following methods will cleanup the result.
**content( )**
Returns datatree content as lua table
**toCollection( )**  or **tc( )**
Returns  datatree content as ___collection class___.  

---

***Collection class***
Datacollection is the cleaned version of the datatree, with some helper function for further manipulation of the result set.

*creating data collection*
~~~
local dtc = require "api.core.dbtcoll"
...
local function fn_stock_calc(stocks)
	local sColl = dtc.new(stocks)
~~~

**map( key )**
collects elements in to a map by given key
~~~
local function fn_stock_calc(stocks)
	dtc.new(stocks):map("product_id")
~~~
the result should looks like this 
~~~
# product_id is 311
[311] =     {

# stock information for each store
	# store_id = 1
      [1] =         {
          product_id= 311,
          quantity= 20,
          store_id= 1,
        },
    # store_id = 2
      [2] =         {
          product_id= 311,
          quantity= 27,
          store_id= 2,
        },
    # store_id = 3
      [3] =         {
          product_id= 311,
          quantity= 23,
          store_id= 3,
        },
    }
~~~

**each( function )** and **eachi( function )**
iterator function for the collection

**max( key )**
**min( key )**
**sum( key )**
**avg( key )**
**count( )**
**median( key )**
aggregate functions

**range( vMin, vMax, key )**
returns a part of the collection in given range

**anyOf( values, key )**
returns a part of the collection which are belongs to the set of values

**noneOf( value, key )**
returns a part of the collection which are out of the set of values

**clone( )**
makes a new individual object from the original 

*examples*:
~~~
local pool = require "api.core.dbpool"
local dtc = require "api.core.dbtcoll"

local function fn_stock_report(stocks)
	t ={}
	-- creates map from products by id, and iterates on each group
	stocks:map("product_id"):each ( 
		function(map_elem, index)
			-- create collection from current product stock details
			local prod_stock = dtc.new(map_elem)
			-- calculates percent of available stock for each product
			stocks[index].sum = prod_stock:sum("quantity")
			stocks[index].avg = prod_stock:avg("quantity")
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
~~~
---
