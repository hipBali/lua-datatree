--
-- data pool for openresty
--  

local m = {}

local pool = {}

function m.get(name)
	return pool[name]
end

function m.set(name, value)
	pool[name] = value
end

function m.list()
	local names = {}
	for k,v in pairs(pool) do
		table.insert(names,k)
	end
	return names
end

return m