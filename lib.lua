
-- @localise workspace
-- @define parent_workspace(name) if _G.workspace and _G.workspace ~= workspace then return _G.workspace.name() end
-- @define parent_workspace(name, x) if _G.workspace and _G.workspace ~= workspace then return _G.workspace.name(x) end
-- @define parent_workspace(name, x, y) if _G.workspace and _G.workspace ~= workspace then return _G.workspace.name(x, y) end
-- @define parent_workspace(name, x, y, z) if _G.workspace and _G.workspace ~= workspace then return _G.workspace.name(x, y, z) end

-- @include subenv
-- @include util

local active = nil

local function names( t )
	local r = {}

	for i = 1, #t do
		r[i] = t[i].name
	end

	return r
end

workspace = {
	WORKSPACE_INVALID = 0,
	WORKSPACE_NOCONFIG = 1,
	WORKSPACE_EMPTY = 2,
	WORKSPACE_VALID = 3
}

function workspace.get_API()
	parent_workspace( get_API )
	return workspace
end

function workspace.get_help_text( option )
	if option == "commands" then
		local t = {}

		recur_cmd( program.commands, function( node, parents )
			if not node.commands or #node.commands == 0 then
				local text = fmtcmd( node, true )

				for i = 1, #parents do
					text = parents[i].name .. " " .. text
				end

				insert( t, text )
			end
		end, { program } )

		return table.concat( t, "\n" )

	elseif not option then
		return program.name .. " - " .. program.description .. "\nUse `workspace help commands` for help with commands"
	else
		for i = 1, #program.commands do
			if program.commands[i].name == option then
				local t = { "workspace " .. fmtcmd( program.commands[i] ) }

				if program.commands[i].commands then
					recur_cmd( program.commands[i].commands, function( node, parents )
						local text = fmtcmd( node )

						for i = 1, #parents do
							text = parents[i].name .. " " .. text
						end

						insert( t, text )
					end, { program.commands[i], program } )
				end

				return table.concat( t, "\n" )
			end
		end

		return "No such help page for '" .. option .. "'\nUse `workspace help commands` to see available commands"
	end
end

function workspace.get_workspace_dir(...)
	parent_workspace( get_workspace_dir )
	return WORKSPACE_DIR
end

function workspace.get_path( name )
	parent_workspace( get_path, name )

	return WORKSPACE_DIR .. "/" .. name
end

function workspace.exists( name, filter )
	parent_workspace( name, filter )

	local path = workspace.get_path( name )
	local mode = workspace.WORKSPACE_INVALID

	if fs.isDir( path ) then
		mode = workspace.WORKSPACE_NOCONFIG

		if fs.exists( path .. "/.workspace" ) and not fs.isDir( path .. "/.workspace" ) then
			mode = workspace.WORKSPACE_EMPTY

			if #fs.list( path ) > 1 then
				mode = workspace.WORKSPACE_VALID
			end
		end
	end

	if not filter or filter <= mode then
		return path, mode
	end

	return nil, mode
end

function workspace.get_workspace_list( filter )
	parent_workspace( get_workspace_list, filter )

	local file_list = fs.list( WORKSPACE_DIR )
	local result = { names = names }

	for i = 1, #file_list do
		local path = workspace.get_path( file_list[i] )
		local mode = workspace.WORKSPACE_INVALID

		if fs.isDir( path ) then
			mode = workspace.WORKSPACE_NOCONFIG

			if fs.exists( path .. "/.workspace" ) and not fs.isDir( path .. "/.workspace" ) then
				mode = workspace.WORKSPACE_EMPTY

				if #fs.list( path ) > 1 then
					mode = workspace.WORKSPACE_VALID
				end
			end
		end

		if not filter or filter <= mode then
			insert( result, { name = file_list[i], path = path, mode = mode } )
		end
	end

	return result
end

function workspace.create( name )
	parent_workspace( create, name )

	if workspace.exists( name, workspace.WORKSPACE_EMPTY ) then
		return false, "workspace '" .. name .. "' already exists"
	elseif workspace.exists( name, workspace.WORKSPACE_NOCONFIG ) then
		return false, "cannot create folder '" .. workspace.get_path( name ) .. "'"
	else
		local path = workspace.get_path( name )
		local h

		fs.makeDir( path )
		h = fs.open( path .. "/.workspace", "w" )

		if h then
			h.write( WORKSPACE_META:format( name ) )
			h.close()
		else
			return false, "cannot write to '" .. path .. "/.workspace'"
		end

		return true
	end
end

function workspace.remove( name, hard )
	parent_workspace( remove, name, hard )

	local rem = false

	if workspace.exists( name, workspace.WORKSPACE_EMPTY ) then
		fs.delete( workspace.get_path( name ) .. "/.workspace" )
		rem = true
	end

	if hard and workspace.exists( name, workspace.WORKSPACE_NOCONFIG ) then
		fs.delete( workspace.get_path( name ) )
		rem = true
	end

	return rem
end

function workspace.read_config( wname )
	parent_workspace( read_config, wname )

	if workspace.exists( wname, workspace.WORKSPACE_EMPTY ) then
		local h = fs.open( workspace.get_path( wname ) .. "/.workspace", "r" )

		if h then
			local content = h.readAll()
			local data

			h.close()
			data = textutils.unserialize( content )

			if type( data ) == "table" then
				return data
			else
				return false, "invalid config file of '" .. wname .. "'"
			end
		end

		return false, "couldn't read config file of '" .. wname .. "'"
	end

	return false, "workspace '" .. wname .. "' doesn't exist"
end

function workspace.write_config( wname, config )
	parent_workspace( write_config, wname, config )

	local serialized = textutils.serialize( config )

	if workspace.exists( wname, workspace.WORKSPACE_EMPTY ) then
		local h = fs.open( workspace.get_path( wname ) .. "/.workspace", "w" )

		if h then
			h.write( serialized )
			h.close()

			return true
		end

		return false, "couldn't write to config file of '" .. wname .. "'"
	end

	return false, "workspace '" .. wname .. "' doesn't exist"
end

function workspace.set_link( wname, lname, lvalue )
	parent_workspace( set_link, wname, lname, lvalue )

	local config, err = workspace.read_config( wname )

	if config then
		config.links[lname] = lvalue

		local ok, err = workspace.write_config( wname, config )

		if ok then
			if active and active.name == wname then
				active.links[lname] = lvalue
			end

			return true
		else
			return false, err
		end
	end

	return false, err
end

function workspace.list_links( wname )
	parent_workspace( list_links, wname )

	local config, err = workspace.read_config( wname )
	local t = { names = names }

	if config then
		for k, v in pairs( config.links ) do
			insert( t, { name = k, link = v } )
		end

		return t
	end

	return false, err
end

function workspace.open( wname )
	parent_workspace( open, wname )

	local config, err = workspace.read_config( wname )

	if config then
		local links = { ["workspace.lua"] = shell.getRunningProgram() }; for k, v in pairs( config.links ) do links[k] = v end
		local env = create_sub_environment( workspace.get_path( wname ), links, workspace.get_API() )
		local h = assert0( fs.open( "rom/programs/shell.lua", "r" ) or fs.open( "rom/programs/shell", "r" ), "Failed to read shell" )
		local shell_contents = h.readAll()
		local shell_f

		if active then
			print( "Closed running workspace " .. active.name )
			active = nil
		end

		h.close()

		shell_f = (load or loadstring)( shell_contents, "shell", nil, env )
		active = {
			name = wname,
			filesystem = env.fs,
			environment = env,
			links = links,
			co = coroutine.create( shell_f ),
			running = true,
		}

		if setfenv then setfenv( shell_f, env ) end

		local filter = nil
		local ev = {}

		while active and active.running do
			if not filter or filter == ev[1] then
				local ok, data = coroutine.resume( active.co, unpack( ev ) )

				if not ok then
					active.running = false
					return error( data, 0 )
				elseif active and coroutine.status( active.co ) == "dead" then
					active.running = false
				end

				filter = data
			end

			ev = { coroutine.yield( filter ) }
		end

		active = nil
	else
		return false, err
	end
end

function workspace.get_active()
	parent_workspace( get_active )

	return active
end

function workspace.close()
	parent_workspace( close )

	if active then
		active.running = false
		return coroutine.yield()
	else
		return false, "no running workspace"
	end
end
