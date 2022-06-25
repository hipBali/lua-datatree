package.path = "../src/?.lua;src/?.lua;" .. package.path
pcall(require, "luarocks.require")
local redis = require 'redis'

local params = {
    host = '127.0.0.1',
    port = 6379,
}
local client = redis.connect(params)
-- client:flushall()
----------------------------------------------------
local json = require "json"

function r_toIndex(record,index)
	local idx = nil
	if type(index)=="table" then
		local ix = {}
		local r = record
		-- unique index passing
		r = record
		for n = 1,#index.segments do
			table.insert(ix,tostring(r[index.segments[n]]))
		end
		idx = table.concat(ix,"-")
	end
	return idx
end

function r_loadObjects(t,td)
	local n = 0
	for _,rec in pairs(t) do
		n = n + 1
		client:set(string.format("%s:%d",td.name,n),json.encode(rec))
		local o_index = n 
		if td.index then
			local i_name,ix 
			local set = {}
			for _,idsc in pairs(td.index) do
				i_name = idsc.name
				ix = r_toIndex(rec,idsc)
				client:sadd(string.format("%s:%s:%s",td.name,i_name, ix), o_index )
			end
		end
	end
	t = nil
	collectgarbage("collect")
	return n
end

function r_loadModel(dbt_model,tagId)
	local desc = {}
	local base = {}
	for _,dt in pairs(dbt_model) do
		local t =  json.load( dt.filename )
		if tagId then t = t[tagId] end
		dt.size = r_loadObjects(t,dt)
		desc[dt.name] = dt
		base[dt.name] = dt.size
		t = nil
		collectgarbage("collect")
	end
	client:set("base", json.encode(base))
	client:set("desc", json.encode(desc))
	base = nil
	desc = nil
	collectgarbage("collect")
end

return r_loadModel
