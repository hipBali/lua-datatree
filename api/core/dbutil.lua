local json = require "api.core.json"
local dbc = require "api.core.dbtcommon"

local m = {}

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

function m.getChilds(tree,nodeName)
	-- tree compatible structure --
	local t = {}
	local function findT(tbl,name)
		local fnd 
		for key,data in pairs(tbl) do
			if type(key) == "string" and key==name then
				for _,o in pairs(tbl[name]) do
					if type(o)=="table" then
						table.insert(t,dbc.proxy(o))
					end
				end
			elseif (type(data) == "table") then
				fnd = findT(data,name)
			end
		end
		return fnd
	end
	findT(tree,nodeName)
	return t
end

function m.addIndex(t,td,newIndex)
	local i_name = newIndex.name
	if t.index[i_name] then 
		return
	else
		t.index[i_name] = {} 
		table.insert(td.index,newIndex)
	end
	for o_id,rec in pairs(t._raw_data) do
		local ix = m.toIndex(rec,newIndex)
		t.index[i_name][ix] = t.index[i_name][ix] or {}
		table.insert(t.index[i_name][ix],o_id)
	end
end

function m.loadObjects(t,td)
	local objects = {index={}}
	objects._raw_data = objects._raw_data or {}
	for _,idsc in pairs(td.index) do
		objects.index[idsc.name] = objects.index[idsc.name] or {}
	end
	local n = 0
	for _,rec in pairs(t) do
		table.insert(objects._raw_data,rec)
		local o_index = #objects._raw_data 
		if td.index then
			local i_name,ix
			for _,idsc in pairs(td.index) do
				i_name = idsc.name
				ix = m.toIndex(rec,idsc)
				objects.index[i_name][ix] = objects.index[i_name][ix] or {}
				table.insert(objects.index[i_name][ix],o_index)
			end
		end
		n = n + 1
	end
	t = nil
	collectgarbage("collect")
	return objects, n
end

function m.loadModel(dbt_model,tagId)
	local startTime = os.clock()
	local dbdta = {}
	local desc = {}
	local cnt
	for _,dt in pairs(dbt_model) do
		io.stderr:write( string.format(  "loading %s ",dt.name))
		local t =  json.load( dt.filename )
		if tagId then t = t[tagId] end
		dbdta[dt.name],cnt = m.loadObjects(t,dt)
		-- dt.size = cnt
		desc[dt.name] = dt
		io.stderr:write( string.format("\r%s loaded (%d)  \n",dt.name,cnt))
	end
	local endTime = os.clock()
	io.stderr:write( endTime - startTime )
	io.stderr:write( "seconds \n" )
	return dbdta, desc
end

return m
