
-- @define insert(t, v) t[#t + 1] = v
-- @define insert(t, v, i) table.insert( t, i, v )
-- @define pop_bottom(t) table.remove( t, 1 )

-- not used as they break the linter :/
--/ @define foreach(x) for i = 1, #x do
--/ @define foreach(i, x) for i = 1, #x do
--/ @define foreach(i, v, x) for i = 1, #x do local v = x[i]

local function fmtcmd( cmd, nodesc )
	return cmd.name
	    .. (#cmd.params > 0 and " <" or "") .. table.concat( cmd.params, "> <" ) .. (#cmd.params > 0 and ">" or "")
	    .. (#cmd.flags > 0 and " [--" or "") .. table.concat( cmd.flags, "] [--" ) .. (#cmd.flags > 0 and "]" or "")
	    .. (nodesc and "" or " - " .. cmd.description)
end

local function recur_cmd( t, f, p )
	for i = 1, #t do
		f( t[i], p or {} )

		if t[i].commands then
			recur_cmd( t[i].commands,f, { t[i], unpack( p or {} ) } )
		end
	end
end

local function assert0( a, ... )
	return a or error( ..., 0 ), ...
end

local function getcmd( name )
	local t = program
	for section in name:gmatch "%.([^%.]+)" do
		if t.commands then
			for i = 1, #t.commands do
				if t.commands[i].name == section then
					t = t.commands[i]
					break
				end
			end
		else
			return nil
		end
	end
	return t
end

local function escape_patterns( pat )
	return pat:gsub( "[%.%^%$%*%+%-%?%%%[%]]", "%%%1" )
end

local function get_command_and_data( args )
	local t = program
	local command = t.name
	local parameters = {}
	local flags = {}
	local warnings = {}
	local interactive = false

	while t.commands do
		local cmd = args[1]
		local set = false

		for i = 1, #t.commands do
			if t.commands[i].name == cmd or "-" .. t.commands[i].alias == cmd then
				command = command .. "." .. t.commands[i].name
				pop_bottom( args )
				t = t.commands[i]
				set = true
				break
			end
		end

		if not set then
			break
		end
	end

	for i = 1, #t.params do
		if t.params[i] == "current-workspace-name" and workspace.get_active() then
			insert( parameters, workspace.get_active().name )
		elseif args[1] and args[1]:sub( 1, 2 ) ~= "--" and (args[1]:sub( 1, 1 ) ~= "-" or #args[1] ~= 2) then
			insert( parameters, pop_bottom( args ) )
		else
			break
		end
	end

	interactive = t.commands ~= nil or #parameters < #t.params

	for i = 1, #t.flags do
		flags[t.flags[i]] = false
	end

	if interactive then
		flags.interactive = false
	end

	while args[1] do
		local set = false

		for i = 1, #t.flags do
			if args[1] == "--" .. t.flags[i] or args[1] == "-" .. t.flags[i]:sub( 1, 1 ) then
				if flags[t.flags[i]] then
					insert( warnings, "duplicated flag set '" .. t.flags[i] .. "'" )
				else
					flags[t.flags[i]] = true
				end

				set = true
				pop_bottom( args )
				break
			end
		end

		if not set and interactive and (args[1] == "--interactive" or args[1] == "-i") then
			if flags.interactive then
				insert( warnings, "duplicated flag set 'interactive'" )
			else
				flags.interactive = true
			end

			set = true
			pop_bottom( args )
		end

		if not set then
			break
		end
	end

	while args[1] do
		insert( warnings, ("unused argument %q"):format( pop_bottom( args ) ) )
	end

	return command, parameters, flags, warnings
end

local function filter_command_list( list, cur_text )
	local t = {}

	for i = 1, #list do
		if cur_text == "" or list[i].name:find( "^" .. escape_patterns( cur_text ) ) then
			insert( t, list[i].name:sub( #cur_text + 1 ) )
		elseif ("-" .. list[i].alias):find( "^" .. escape_patterns( cur_text ) ) then
			insert( t, list[i].alias:sub( #cur_text ) )
		end
	end

	if ("--interactive"):find( "^" .. escape_patterns( cur_text ) ) then
		insert( t, ("--interactive"):sub( #cur_text + 1 ) )
	end

	return t
end

local function filter_text( list, cur_text )
	local r = {}

	for i = 1, #list do
		if list[i]:find( "^" .. escape_patterns( cur_text ) ) then
			insert( r, list[i]:sub( #cur_text + 1 ) )
		end
	end

	return r
end

local function file_find( cur_text )
	local dir = cur_text:match "(.+)/" or ""
	local file = cur_text:gsub( ".+/", "" )
	local files = fs.list( dir or "" )
	local r = {}

	for i = 1, #files do
		if files[i]:find( "^" .. escape_patterns( file ) ) then
			r[#r + 1] = files[i]
		end
	end

	return r
end
