-- DataTree module
local dbu_red = require "api.core.dtutil_redis"
local json = require "api.core.json"
local dbc = require "api.core.dtcommon"
local DataCollection = require "api.core.dtcoll"
-----------------------
-- DataTree class
-----------------------
DataTree = {}
	DataTree.__index = DataTree
	DataTree.__index = DataTree
    
	function DataTree:new(name,client,data)
		local data_tree = {}
		data_tree._name = name
		-- #REDIS#
		data_tree._rc = client
		data_tree._base = dbu_red.r_getBase(client)
		data_tree._desc = dbu_red.r_getDesc(client)
		--
		data_tree._asrt = function() end -- not serializable
		if name == nil then
			data_tree = data -- push as query result
		else
			data_tree._data = data or {}
		end
		dbc.proxy(data_tree._data)
		setmetatable(data_tree, DataTree)
		return data_tree
	end
	
	function DataTree:content()
		return self._data[self._name] or self._data
	end
	
	function DataTree:getInfo()
		return self._base, self._desc
	end
	
	function DataTree:__tostring()
		local size = #(self._data[self._name] or self._data)
		return string.format("<DataTree: name=%s size=%d>", tostring(self._name), size)
	end
	
	function DataTree:toCollection()
		return DataCollection.new(self._data)
	end
	
	DataTree.tc = DataTree.toCollection
	
	function DataTree:select(prm)
		assert(prm.object,string.format("select(): invalid object!"))
		assert(self._base[prm.object],string.format("select(): object %s does not exists!",prm.object))
		-- make an own datatree for the select
		-- #REDIS#
		local result = DataTree:new(prm.object,self._rc)
		local resdata = result._data
		
		-- detects alias, and uses as default target
		local alias = prm.as or prm.object 
		resdata[alias] = resdata[alias] or {}
		dbc.proxy(resdata[alias])
		
		result._name = alias
		
		-- descriptor for the object
		local dsc = self._desc[prm.object]
		assert(dsc,string.format("select(): descriptor missing for %s!",prm.object))
				
		local function processObject(o)
			o = dbc.clone(o)
			local fit = true
			-- apply filter
			if type(prm.filter)=="function" then
				fit = prm.filter(o)
			elseif type(prm.filter)=="table" then
				for k,v in pairs(prm.filter) do
					if o[k]~=v then 
						fit = false
						break
					end
				end
			end
			-- fields to select
			if type(prm.fields)=="table" then
				for k,_ in pairs(o) do
					if dbc.noneOf(prm.fields,k) then
						o[k] = nil
					end
				end
			end
			-- add object to the tree 
			if fit then 
				-- postprocessing 
				if type(prm.call)=="function" then
					o = prm.call(o)
				end
				table.insert(resdata[alias],o)
				return o
			else
				return
			end
		end
				
		local n = 0
		-- find index for the joining object
		
		-- #REDIS#
		if prm.index and prm.index ~= "pk" then
			local ixn = dbu_red.findIndex(dsc.index, prm.index)
			assert(ixn,string.format("select(): %s:%s invalid index!",prm.object,prm.index))
			
			local size = self._base[prm.object]
			for i=1,size do
				local it = dbu_red.r_getObjectsByIndex(self._rc,prm.object,ixn.name,i)
				if it == nil then break end
				local prc
				for _,ptr in pairs(it) do
					prc = processObject(dbu_red.r_getObject(self._rc,prm.object, ptr))
				end
				-- apply limit parameter
				if prc then
					n = n + 1
					if prm.limit and n == prm.limit then break end
				end
			end
		else
			local size = self._base[prm.object]
			for i=1,size do 
				local prc = processObject(dbu_red.r_getObject(self._rc,prm.object, i))
				-- apply limit parameter
				if prc then
					n = n + 1
					if prm.limit and n == prm.limit then break end
				end
			end
		end
		-- 
		return result, alias
	end
	
	function DataTree:join(prm)
		local root = self._data

		-- finding the object
		local object = self._base[prm.object]
		assert(object,string.format("join(): %s invalid object!", tostring(prm.object)))
		
		-- descriptor for the object
		local dsc = self._desc[prm.object]
		
		assert(dsc,string.format("join(): descriptor missing for %s!",prm.object))
		
		-- find targeted object in the chain
		local trgName
		if prm.on then
			root = self:getChilds(prm.on)
			trgName = prm.on
		else
			root = root[self._name]
			trgName = self._name
		end
		
		local joinIdx = dbu_red.findIndex(dsc.index, prm.index or "pk")
		assert(joinIdx,string.format("join(): index %s not found ( %s on %s)!", prm.index or "pk", tostring(prm.object), trgName))
		
		local alias = prm.as or prm.object 
		
		assert(root,string.format("join(): descriptor missing for targeted object %s!", tostring(prm.on)))
		----------------------------------------------------------------------------------------
		local size = self._base[prm.object]
		for _,obj in pairs(root) do 
			local res = dbu_red.r_getObjectsByIndex(self._rc,prm.object,joinIdx.name,dbu_red.toIndex(obj,joinIdx))
			if res and type(res)=="table" then
				-- index to object
				for k,v in pairs(res) do
					res[k] = dbu_red.r_getObject(self._rc,prm.object, v)
				end
				-- apply filter if any
				if type(prm.filter)=="function" then
					local t = {}
					if #res then
						for _,o in pairs(res) do
							if prm.filter(o,root) then table.insert(t,o) end
						end
					else
						if prm.filter(res,root) then
							t = res
						end
					end
					res = t
				elseif type(prm.filter)=="table" then
					local t = {}
					if #res then
						for _,o in pairs(res) do
							for k,v in pairs(prm.filter) do
								if o[k]==v then table.insert(t,o) end
							end
						end
					else
						t = res
						for k,v in pairs(prm.filter) do
							if res[k]~=v then 
								res = {}
								break
							end
						end
					end
					res = t
				end
				
				-- fields to select
				if type(prm.fields)=="table" then
					if #res then
						for _,o in pairs(res) do
							for k,_ in pairs(o) do
								if dbc.noneOf(prm.fields,k) then
									o[k] = nil
								end
							end
						end
					else
						for k,_ in pairs(res) do
							if dbc.noneOf(prm.fields,k) then
								res[k] = nil
							end
						end
					end
				end

				-- apply limit parameter
				if prm.limit and #res>prm.limit then
					local t = {}
					for i=1,prm.limit do
						if res[i] then
							t[i] = res[i]
						end
					end
					res = t
				end
				
				-- puts result in to the chain
				if res then
					res = dbc.clone(res)
					if type(prm.call)=="function" then
						prm.merge = prm.call
					end
					if prm.merge and #res == 1 then
						if type(prm.merge)=="function" then
							prm.merge(obj,res)
						else
							for k,v in pairs(res[1]) do
								if obj[1] then 
									obj[1][k]=v 
								else 
									obj[k]=v 
								end
							end
						end
					else
						obj[alias] = obj[alias]
						obj[alias] = res
						dbc.proxy(obj[alias])
					end
				end
			end
			
		end
		return self, alias
	end
	
	----------------------------------------
	function DataTree:getChilds(nodeName)
		-- tree compatible structure --
		local tree = self._data
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

	----------------------------------------
	-- user function to manipulate the chain
	----------------------------------------
	function DataTree:proc(fn)
		local root = self._data
		-- or function as parameter
		if type(fn) == "function" then
			fn(root)
		else
			assert(nil,string.format("proc(): parameter must be a function!"))
		end
		return self
	end
	
	function DataTree:sort(prm)
		local root = self._data
		local alias = prm.on or self._name
		local tc = DataCollection.new(root[alias])
		-- named function
		local fn
		-- or function as parameter
		if type(prm[1]) == "function" then
			fn = prm[1]
		else
			fn = prm.call
		end		
		table.sort(tc, fn)
		return self
	end
	
	function DataTree:func(prm)
		local root = self._data
		local alias = prm.on or self._name
		local tc = DataCollection.new(root[alias])
		-- named function
		local fn
		-- or function as parameter
		if type(prm[1]) == "function" then
			fn = prm[1]
		else
			fn = prm.call
		end		
		fn(tc)
		return self
	end
	
	DataTree.fn = DataTree.func
	
	function DataTree:tc_select(prm)
		local dt,alias = self:select(prm)
		return DataCollection.new(dt._data[alias])
	end
	
	function DataTree:tc_join(prm)
		local dt,alias = self.join(prm)
		return DataCollection.new(dt._data[alias])
	end


-- Initialization ----------------------------------
local m = {}

function m.new(name,client)
	return DataTree:new(name,client)
end

return m