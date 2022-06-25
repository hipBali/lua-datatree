
# lua-datatree-redis
__Lua based dataset analyzer tool using redis storage__

## Requirements
>**Redis**
>[redis.io](https://redis.io)

for use as rest service
>**OpenResty**
>[openresty.org](https://openresty.org/)

for use from command line
>**redis-lua**
>[nrk/redis-lua](https://github.com/nrk/redis-lua)
>

## Directory structure
~~~
dtree-redis
├── cli
│   └── test
├── readme.md
├── resty
│   ├── api
│   │   └── core
│   │       └── __copy_src__content_here__
│   ├── conf
│   │   └── nginx.conf
│   ├── logs
│   ├── rest.lua
│   └── scripts
│       └── test
│           ├── custorders.lua
│           ├── filter.lua
│           ├── report.lua
│           ├── sort.lua
│           └── sum.lua
├── src
│   ├── dtcoll.lua
│   ├── dtcommon.lua
│   ├── dtree_redis.lua
│   ├── dtutil_redis.lua
│   ├── hlpfunc.lua
│   ├── json.lua
│   ├── redis_client.lua
│   └── redis_client_cli.lua
└── to-redis
    ├── bikestore_loader.lua
    ├── data
    │   ├── # bikestore example files (json)
    └── toredis.lua
~~~

## Usage
### using as rest service
1. *install openresty*
2. *create your own workspace*
~~~
    mkdir ~/work 
    cd ~/work 
	git clone https://github.com/hipBali/lua-datatree-redis.git
	cd dtree-redis
	cp src/* resty/api/core
~~~
 3. *run Nginx rest service*
~~~
	nginx -p `pwd`/ -c conf/nginx.conf
~~~

### using curl without parameters
~~~
$ curl localhost:8080/test/sum
~~~
### using curl with parameters
~~~
$ curl -X POST -H "Content-Type: application/json" \
-d '{"customer_id":123, "staff_id":1}' \
localhost:8080/test/filter
~~~
## Preparing data for Redis
### Creating dataset from json files
**create dataloader**
		The dataloader should define detailed structure of the json file(s).
		
~~~
local dataPath = "mydata/bikestore/"

local db_model = {
  { name = "CUSTOMERS", 
	filename = dataPath.."customers.json", 
	index = {
	  { name = "pk", segments = {"customer_id"} },
	  { name = "idx_name", segments = {"last_name", "last_name"}, unique = false },
		...
	},
  },
  ...
}
~~~
use toredis.lua utility to put dataset to Redis
~~~
local db_model = {
	...
}
local ldr = require "toredis"
ldr(db_model)
~~~
save  your script e.g. myloader.lua and run...
~~~
	$ lua myloader.lua
~~~

		
**Loading dataset from different json structure**
						r_loadModel(dataset_descriptor,**path_to_dataset**)
		
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

### Creating dataset from database tables


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
