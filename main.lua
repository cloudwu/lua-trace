trace = require "trace"

local function factorial(n)
	if n <= 1 then
		return 1
	end
	return factorial(n-1) * n
end

function foo(n)
	trace.trace("n s",n)
	local s =  factorial(100)
	return s
end

function hello()
	print "hello"
end

foo(3)
hello()
foo()

