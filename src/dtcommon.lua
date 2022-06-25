local m={}

-- BASED on moses library @copyright [Roland Yonaba](http://github.com/Yonaba)
local tbl = table
local t_insert, t_sort           = tbl.insert, tbl.sort
local t_remove,t_concat          = tbl.remove, tbl.concat
local randomseed, random, huge   = math.randomseed, math.random, math.huge
local floor, max, min, ceil      = math.floor, math.max, math.min, math.ceil


local function f_max(a,b) return a>b end
local function f_min(a,b) return a<b end
local function M_identity(value) return value end

local function M_extract(list,comp,transform,...) -- extracts value from a list
  transform = transform or M_identity
  local _ans  
  for k,v in pairs(list) do
    if not _ans then _ans = transform(v,...)
    else
      local val = transform(v,...)
      _ans = comp(_ans,val) and _ans or val
    end
  end
  return _ans
end

local function M_keys(obj)
  local keys = {}
  for key in pairs(obj) do keys[#keys+1] = key end
  return keys
end

local function M_clone(obj, shallow)
  if type(obj) ~= 'table' then return obj end
  local _obj = {}
  for i,v in pairs(obj) do
    if type(v) == 'table' then
      if not shallow then
        _obj[i] = M_clone(v,shallow)
      else _obj[i] = v
      end
    else
      _obj[i] = v
    end
  end
  return _obj
end

--- Extracts values in a table having a given key.
-- @name pluck
-- @param t a table
-- @param key a key, will be used to index in each value: `value[key]`
-- @return an array of values having the given key
local function M_pluck(t, key)
  local _t = {}
  for k, v in pairs(t) do
    if v[key] then _t[#_t+1] = v[key] end
  end
  return _t
end

--- Selects and returns values passing an iterator test.
-- <br/><em>Aliased as `filter`</em>.
-- @name select
-- @param t a table
-- @param f an iterator function, prototyped as `f (v, k)`
-- @return the selected values
-- @see reject
local function M_select(t, f)
  local _t = {}
  for index,value in pairs(t) do
    if f(value,index) then _t[#_t+1] = value end
  end
  return _t
end

--- Checks if the given argument is an integer.
-- @name isInteger
-- @param obj an object
-- @return `true` or `false`
local function M_isInteger(obj)
  return type(obj) == 'number' and floor(obj)==obj
end

local function f_eqOrIn(a,b)
	local isIn = false
	if type(b) == "table" then
		for _,v in pairs(b) do
			isIn = isIn or (a==v)
			if isIn then break end
		end
	else
		isIn = (a==b)
	end
	return isIn
end
-----------------------------------------------------------------
function m.max(t,key)
	if key then
		return M_extract(t, f_max, function(o) return o[key] end)
	else
		return M_extract(t, f_max)
	end
end

function m.min(t,key)
	if key then
		return M_extract(t, f_min, function(o) return o[key] end)
	else
		return M_extract(t, f_min)
	end
	
end

function m.sum(t,key)
	local s = 0
	for k, v in ipairs(t) do 
		if key then
			if type(v[key])=="number" then
				s = s + v[key]
			end
		else
			if type(v)=="number" then
				s = s + v
			end
		end
	end
	return s
end

function m.avg(t,key)
  return m.sum(t,key)/#t
end

function m.range(t,vMin,vMax,key)
	if key then
		t = M_pluck(t,key)
	end
	for _,v in pairs(t) do
		if v<vMin or v>vMax then return false end
	end
	return true
end

function m.anyOf(t,value,key)
	if key then
		t = M_pluck(t,key)
	end
	local _iter = (type(value) == 'function') and value or f_eqOrIn
	for k,v in pairs(t) do
		if _iter(v,value) then return true end
	end
	return false
end

function m.noneOf(t,value,key)
	return not m.anyOf(t,value,key)
end

--- Returns the median of an array of numbers.
-- @name median
-- @param array an array of numbers
-- @return a number
-- @see sum
-- @see product
-- @see mean
function m.median(t,key)
  if key then
	t = M_pluck(t,key)
  end
  t = m.sort(M_clone(t))
  
  local n = #t
  if n == 0 then 
    return 
  elseif n==1 then 
    return t[1]
  end
  local mid = ceil(n/2)
  return n%2==0 and (t[mid] + t[mid+1])/2 or t[mid]
end

function m.sort(t,comp)
  t_sort(t, comp)
  return t
end

-- table iterator
function m.proxy (t)
	local _t = t or {}
	local mt = {
		__call = function(self,f)
			for k,v in pairs(t) do
				if type(v)~="function" then
					f(v,k)
				end
			end
		end
	}
	setmetatable(_t, mt)
	return _t
end

function m.each(t,f)
  for index,value in pairs(t) do
	if type(value)~="function" then
		f(value, index)
	end
  end
end

function m.eachi(t,f)
  local lkeys = m.sort(t,M_select(M_keys(t), M_isInteger))
  for k, key in ipairs(lkeys) do
	if type(t[key])~="function" then
		f(t[key], key)
	end
  end
end

function m.clone(obj, shallow)
  return M_clone(obj, shallow)
end

return m
