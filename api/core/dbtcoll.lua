
local dbc = require "api.core.dbtcommon"
------------------------------------------
--- DataCollections and its functions  
------------------------------------------
DataCollection = {}
	DataCollection.__index = DataCollection

	function DataCollection:new(t)
	   local data_func = t or {}
	   setmetatable(data_func, DataCollection)
	   return data_func
	end
	
	function DataCollection:__tostring()
		return string.format("<DataCollection.T: size=%d>", #self)
	end

function DataCollection:max(key)
	return dbc.max(self,key)
end

function DataCollection:min(key)
	return dbc.min(self,key)
end

function DataCollection:sum(key)
	return dbc.sum(self,key)
end

function DataCollection:avg(key)
  return dbc.avg(self,key)
end

function DataCollection:count()
  return #self
end
	
function DataCollection:range(vMin,vMax,key)
	return dbc.range(self,vMin,vMax,key)
end

function DataCollection:anyOf(value,key)
	return dbc.anyOf(self,value,key)
end

function DataCollection:noneOf(value,key)
	return dbc.noneOf(self,value,key)
end

function DataCollection:median(key)
  return dbc.median(self,key)
end

-------------------------------------------------
-- collects tree elements in to a map by value
-------------------------------------------------
function DataCollection:map(key)
	local res = {}
	for k,o in pairs(self) do
		res[o[key]] = res[o[key]] or {}
		table.insert(res[o[key]],o)
	end
	return DataCollection:new(res)
end

-------------------------------------------------
-- collects tree elements by name /and properties
-------------------------------------------------
function DataCollection:collect(name,key)
	local res = {}
	local function doCollect(tbl,name)
		local fnd 
		for id,elem in pairs(tbl) do
			if type(id) == "string" and id==name then
				for _,o in pairs(tbl[name]) do
					if key then
						table.insert(res,o[key])
					else
						table.insert(res,o)
					end
				end
			elseif (type(elem) == "table") then
				fnd = doCollect(elem,name)
			end
		end
		return fnd
	end
	local tbl = self
	doCollect(tbl,name)
	return DataCollection:new(res)
end

function DataCollection:each(f)
  dbc.each(self,f)
end

function DataCollection:eachi(f)
  dbc.eachi(self,f)
end

function DataCollection:sort(comp)
  return dbc.sort(self,comp)
end

function DataCollection:clone()
  return M_clone(self)
end

-- Initialization --
local m = {}

function m.new(t)
	return DataCollection:new(t)
end

return m
