

# lua-datatree-redis

Lua based dataset analyzer tool using redis storage


# Table of Contents
[Requirements](#req)

[Directory structure](#dir_struct)

[Api documentation](#api_doc)

[Usage](#usage)

[Preparing data for Redis](#prep_redis)

[Redis Datatree structure](#red_struct)

[How-to](#howto)



## Requirements  <a name="req"></a>

>**Redis**
>[redis.io](https://redis.io)

for use as rest service
>**OpenResty**
>[openresty.org](https://openresty.org/)

for use from command line
>**redis-lua**
>[nrk/redis-lua](https://github.com/nrk/redis-lua)
>

## Directory structure <a name="dir_struct"></a>
~~~
dtree-redis
├── cli
│   ├── api
│   │   └── core
|   |       └── __copy_src__content_here__
│   └── test
|		├── tables.lua
│       └── sum.lua
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

## Usage <a name="usage"></a>
### using rest service
1. *install openresty*
2. *create your own workspace and install lua-datatree-redis*
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

***simple curl request***
~~~
$ curl localhost:8080/test/sum
~~~
***curl request with parameters***
~~~
$ curl -X POST -H "Content-Type: application/json" \
-d '{"customer_id":123, "staff_id":1}' \
localhost:8080/test/filter
~~~

### using command line interface
1. *create your own workspace and install lua-datatree-redis*
~~~
   mkdir ~/work 
   cd ~/work 
   git clone https://github.com/hipBali/lua-datatree-redis.git
   cd dtree-redis
   cp src/* cli/api/core
~~~

2. *create your own workspace*
~~~
   cd ~/work/dtree-redis/cli 
   mkdir ~/mytest
   cd ~/mytest 
~~~
 3. *put your scripts in to the workspace considering the **package.path** variable*
~~~
package.path = "../?.lua;" .. package.path
local redc = require "api.core.redis_client_cli"
...
~~~

## Preparing data for Redis <a name="prep_redis"></a>

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

## Redis Datatree structure <a name="red_struct"></a>

### Descriptors
***base***

- format : JSON
- access: GET/SET
- key: -
~~~
{TABLE_NAME: RECORD_COUNT}
~~~

***desc***

- format : JSON
- access: GET/SET
- key: -

~~~
{TABLE_NAME:{
	"index":[
		{"name":INDEX_NAME,
		 "segments":[FIELD_NAME(S)]
		}
	]}
}	
~~~ 

***record***
- format : JSON
- access: GET/SET
- key: TABLE_NAME:ROWID	

***index***
- format : table of integers
- access: SADD/SMEMBERS
- key: TABLE_NAME:INDEX_NAME:INDEX_ROWID


## Api documentation <a name="req"></a>

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
Same as ___select___ method, but the result will be automatically converted to ___collection___ class. This is the final result of the select ommand only DataCollection methods or lua table functions can be used for further manipulations!

**tc_join{ }**
Same as ___join___ method, but the result will be automatically converted to ___collection___ class. This is the final result of the select-join command chain only DataCollection methods or lua table functions can be used for further manipulations!

---
The datatree object contains raw data including some non relevant informatons beyond what is expected. The following methods will cleanup the result.
**content( )**
Returns datatree content as simple lua table
**toCollection( )**  or **tc( )**
Returns  datatree content as ___collection class___.  

---

***Collection class***
DataCollection is the 'pure data only' part of the DataTree.

*creating data collection*
~~~
local dtc = require "api.core.dtcoll"
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

the
**max( key )**
**min( key )**
**sum( key )**
**avg( key )**
**count( )**
**median( key )**
are aggregate functions

**range( vMin, vMax, key )**
returns a part of the collection in given range

**anyOf( values, key )**
returns a part of the collection which are belongs to the set of values

**noneOf( value, key )**
returns a part of the collection which are out of the set of values

**clone( )**
makes a new individual object from the original 

---

## How-to <a name="howto"></a>

### Prepare your query

***cli***
~~~
local redc = require "api.core.redis_client_cli"
local dt_red = require "api.core.dtree_redis"
local json= require "api.core.json"

local red = redc.connect()
local dt = dt_red.new('MY_DB_NAME',red)

local result = dt:select{ ... }
local serializable_datatree

-- result as collection
serializable_datatree = result:tc()
-- result as lua table
serializable_datatree = result:content()

print(json.encode( serializable_datatree ))
~~~

***resty***
~~~
local redc = require "api.core.redis_client"
local dt_red = require "api.core.dtree_redis"

local red = redc.connect()
local dt = dt_red.new('MY_DB_NAME',red)

requestHandler = function()
	local red = redc.connect()
	local dt = dt_red.new('MY_DB_NAME',red)
	local ds = dt:select{ ... }:content()
	return { error=0, result = ds }
end 
~~~

### Get POST params
curl command
~~~
curl \
-X POST \
-H "Content-Type: application/json" \
-d '{"customer_id":123, "staff_id":1}' \
...
~~~
lua script will get the parameters as lua table
~~~
requestHandler = function(par)
	print(par.customer_id)
	print(par.staff_id)
	...
~~~

### License


BSD 2-Clause License
Copyright (c) 2022, hipBali
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
