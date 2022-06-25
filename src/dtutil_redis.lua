local json = require "api.core.json"

local m = {}

function m.r_getBase(client)
	local res, err = client:get("base")
	return json.decode(res)
end

function m.r_getDesc(client)
	local res, err = client:get("desc")
	return json.decode(res)
end

function m.r_getObject(client,t_name, idx)
	local res, err = client:get(string.format("%s:%d",t_name,idx))
	return json.decode(res)
end

function m.r_getObjectsByIndex(client,t_name,i_name,k_name)
	local res, err = client:smembers(string.format("%s:%s:%s",t_name,i_name,k_name))
	return res
end

function m.r_getSizeByIndex(client,t_name,i_name,k_name)
	local res, err = client:scard(string.format("%s:%s:%s",t_name,i_name,k_name))
	return res
end

function m.toIndex(record,index)
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

function m.findIndex(indexDef,name)
	local fix
	for _,ix in pairs(indexDef) do
		if ix.name == name then
			fix = ix
			break
		end
	end
	return fix
end

return m
