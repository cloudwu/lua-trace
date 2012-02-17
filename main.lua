trace = require "trace"

local function factorial(n)
	if n <= 1 then
		return 1
	end
	return factorial(n-1) * n
end

function foo()
	trace.trace("n s",3)
	local s =  factorial(100)
	return s
end

foo()
