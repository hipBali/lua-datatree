
local dtc = require "api.core.dtcommon"
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
	return dtc.max(self,key)
end

function DataCollection:min(key)
	return dtc.min(self,key)
end

function DataCollection:sum(key)
	return dtc.sum(self,key)
end

function DataCollection:avg(key)
  return dtc.avg(self,key)
end

function DataCollection:count()
  return #self
end
	
function DataCollection:range(vMin,vMax,key)
	return dtc.range(self,vMin,vMax,key)
end

function DataCollection:anyOf(value,key)
	return dtc.anyOf(self,value,key)
end

function DataCollection:noneOf(value,key)
	return dtc.noneOf(self,value,key)
end

function DataCollection:median(key)
  return dtc.median(self,key)
end

-------------------------------------------------
-- collects tree elements in to a map by value
-------------------------------------------------
function DataCollection:map(key)
	local res = {}
	for k,o in pairs(self) do
		if o[key] then
			res[o[key]] = res[o[key]] or {}
			table.insert(res[o[key]],o)
		end
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
  dtc.each(self,f)
end

function DataCollection:eachi(f)
  dtc.eachi(self,f)
end

function DataCollection:sort(comp)
  return dtc.sort(self,comp)
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
