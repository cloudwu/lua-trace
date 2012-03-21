local debug = debug
local print = print
local ipairs = ipairs
local pairs = pairs
local string = string
local rawget = rawget

local info = { file = {} }

local trace = {}

local function setname(level)
	info.filename = debug.getinfo(level + 1,"S").short_src
	if info.file[info.filename] == nil then
		info.file[info.filename] = {}
	end
	info.var = info.file[info.filename]
end

local function make_local(index)
	return function()
		local name , value = debug.getlocal(4 , index)
		return name , "local", value
	end
end

local function make_upvalue(func, index)
	return function()
		local name , value = debug.getupvalue(func, index)
		return name , "upvalue", value
	end
end

local function make_global(env, name)
	return function()
		return name , "global" , rawget(env,name)
	end
end

local function gen_var(var_name, level)
	local i = 1
	while true do
		local name,v = debug.getlocal(5,i)
		if name == var_name then
			return make_local(i)
		end
		if name == nil then
			break
		end
		i=i+1
	end
	i = 1
	local f = debug.getinfo(5, "f").func
	while true do
		local name = debug.getupvalue(f,i)

		if name == var_name then
			return make_upvalue(f,i)
		end
		if name == nil then
			break
		end
		i=i+1
	end
	local name,env = debug.getupvalue(f,1)
	if name == '_ENV' then
		return make_global(env, var_name)
	end
end

local function dump_local(level)
	local i = 1
	while true do
		local name,v = debug.getlocal(level,i)
		if name == nil then
			break
		end
		if name == "(*temporary)" then
			print(name,v)
		end
		i=i+1
	end
end

local function gen_vars(var, call)
	local ret = {}
	for _,k in ipairs(var) do
		local f = gen_var(k, call)
		if f then
			table.insert(ret, f)
		end
	end
	return ret
end

local function hookline(var , call, line)
	print(info.filename, ":" , line)
	if info.var[line] == nil then
		info.var[line] = gen_vars(var, call)
	end

	for _,v in ipairs(info.var[line]) do
		local name , type , value = v()
		if info.last[name] ~= value then
			print(name , type, value)
			info.last[name] = value
		end
	end
end

local function hook(var , level)
	local call = 0
	local index = {}
	for w in string.gmatch(var, "%w+") do
		table.insert(index,w)
	end
	local function f (mode, line)
		if mode == 'return' then
			if call <= 0 then
				debug.sethook()
				trace.on = nil
				return
			end
			setname(3)
			call = call - 1
			if call == level then
				debug.sethook(f,'crl')
			end
		elseif mode == 'call' then
			setname(2)
			call = call + 1
			if call > level then
				debug.sethook(f,'cr')
			end
		elseif mode == 'line' then
			hookline(index , call, line)
		end
	end

	return f
end

local function up(level, f)
	local call = 0
	return function(mode)
		if mode == 'return' then
			call = call + 1
			if call == level then
				setname(3)
				debug.sethook(f,'crl')
			end
		elseif mode == 'call' then
			call = call - 1
		end
	end
end

function trace.trace(var , level)
	if trace.on then
		return
	end

	trace.on = true
	info.last = {}
	debug.sethook(up(2 , hook(var or  "" , level or 0)) , 'cr')
end

return trace