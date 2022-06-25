 m={}
 
 --
 -- returns percent of value/total in % with fractional part
 -- 
 -- percent(4,10) --> 40
 -- percent(7,11,2) --> 63,64 
 -- 
function m.percent(v,sum,frac_len)
	return m.round(v*100/sum,frac_len)
end

-- 
-- signum of value
-- 
function m.sign(v)
	return (v >= 0 and 1) or -1
end

 -- (Luc Bloom)
 -- returns rounded value on given bracket
 -- 
 -- round(119.68, 2) --> 119.68
 -- round(119.68) --> 120
 -- round(119.68, -2) --> 100
 -- 
function m.round(v, bracket)
	bracket =  math.pow(10, -bracket or 0)
	return math.floor(v/bracket + m.sign(v) * 0.5) * bracket
end

return m