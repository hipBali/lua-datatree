-- DataTree module
local dbu = require "api.core.dbutil"
local dbc = require "api.core.dbtcommon"
local DataCollection = require "api.core.dbtcoll"
-----------------------
-- DataTree class
-----------------------
DataTree = {}
	DataTree.__index = DataTree
    
	function DataTree:new(name,base,desc,data)
		local data_tree = {}
		data_tree._name = name
		data_tree._base = base
		data_tree._desc = desc
		-- data_tree._asrt = function() end
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
	
	function DataTree:addIndex(t_name,newIndex)
		dbu.addIndex(self._base[t_name],self._desc[t_name],newIndex)
	end
	
	function DataTree:select(prm)
	
		assert(prm.object,string.format("select(): invalid object!"))
		
		-- make an own datatree for the select
		local result =DataTree:new(prm.object,self._base,self._desc)
		local resdata = result._data
		
		-- detects alias, and uses as default target
		local alias = prm.as or prm.object 
		resdata[alias] = resdata[alias] or {}
		dbc.proxy(resdata[alias])
		
		result._name = alias
		
		-- select root for the tree
		local root = self._base
		if root[prm.object] then
			root = root[prm.object]
		end
		
		-- descriptor for the object
		local dsc = self._desc[prm.object]
		assert(dsc,string.format("select(): descriptor missing for %s!",prm.object))
		
		-- find index for the joining object
		local ix = "_raw_data"
				
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
				
		if prm.index and prm.index ~= "pk" then
			local ixn = dbu.findIndex(dsc.index, prm.index) or {}
			ix = ixn.name or ix
			iroot = root.index
			for ko,o in pairs(iroot[ix]) do
				local prc
				for _,ptr in pairs(o) do
					local oo = root._raw_data[ptr]
					prc = processObject(oo)
				end
				-- apply limit parameter
				if prc then
					n = n + 1
					if prm.limit and n == prm.limit then break end
				end
			end
		else
			for ko,o in pairs(root[ix]) do
				local prc = processObject(o)
				-- apply limit parameter
				if prc then
					n = n + 1
					if prm.limit and n == prm.limit then break end
				end
			end
		end
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
			root = dbu.getChilds(self._data,prm.on)
			trgName = prm.on
		else
			root = root[self._name]
			trgName = self._name
		end
		
		local joinIdx = dbu.findIndex(dsc.index, prm.index or "pk")
		assert(joinIdx,string.format("join(): index %s not found ( %s on %s)!", prm.index or "pk", tostring(prm.object), trgName))
		
		local alias = prm.as or prm.object 
		
		assert(root,string.format("join(): descriptor missing for targeted object %s!", tostring(prm.on)))
		----------------------------------------------------------------------------------------
		for _,obj in pairs(root) do
			local res =  dbc.clone(object.index[joinIdx.name][dbu.toIndex(obj,joinIdx)])
			if res and type(res)=="table" then
				-- index to object
				for k,v in pairs(res) do
					res[k] = object._raw_data[v]
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

	function m.new(name,ot,dt)
		return DataTree:new(name,ot,dt)
	end


	function m.load(mdl,opt)
		return dbu.loadModel(mdl,opt)
	end

	return m