
local ARGS = { ... }

-- @define WORKSPACE_META ('{\n\tname = %q,\n\tlinks = {\n\t\t["rom"] = "rom"\n\t}\n}')

-- @include lib
-- @include autocomplete
-- @include util
-- @include interactive

-- @localise program
program = {
	name = "workspace",
	description = "Allows switching between multiple workspaces with a unique filesystem",
	flags = {},
	params = {},
	commands = {
		{ name = "help", alias = "h", description = "Displays help", flags = { "interactive" }, params = { "help-topic" } },
		{ name = "show", alias = "s", description = "Displays a list of all workspaces", flags = { "all" }, params = {} },
		{ name = "create", alias = "c", description = "Creates a new workspace (--repair is internally used)", flags = { "repair" }, params = { "new-workspace-name" } },
		{ name = "remove", alias = "r", description = "Removes an existing workspace, use --hard to remove all workspace files", flags = { "hard" }, params = { "workspace-name" } },
		{ name = "link", alias = "l", description = "Manages workspace links", flags = {}, params = {}, commands = {
			{ name = "add", alias = "a", description = "Adds a link to the workspace", flags = {}, params = { "current-workspace-name", "new-link-name", "path" } },
			{ name = "remove", alias = "r", description = "Removes a link from the workspace", flags = {}, params = { "current-workspace-name", "link-name" } },
			{ name = "list", alias = "l", description = "Lists all links of the workspace", flags = {}, params = { "current-workspace-name" } }
		} },
		{ name = "open", alias = "o", description = "Opens a workspace, or shows the open workspace if no name is given", flags = {}, params = { "workspace-name" } },
		{ name = "close", alias = "x", description = "Closes the open workspace", flags = {}, params = {} },
		{ name = "init", alias = nil, description = "Initialises autocomplete (--shell is internally used)", flags = { "shell" }, params = {}, hidden = true },
		{ name = "config", alias = "g", description = "Manages the workspace configuration", flags = {}, params = {}, commands = {
			{ name = "set", alias = "s", description = "Sets a config option", flags = {}, params = { "config-option", "config-value" } },
			{ name = "get", alias = "g", description = "Gets a config option", flags = {}, params = { "config-option" } },
			{ name = "list", alias = "l", description = "Lists config options", flags = {}, params = {} },
		} }
	}
}

local command, params, flags, warnings = get_command_and_data( ARGS )
local command_data = getcmd( command )

term.setTextColour( term.isColour() and colours.yellow or colours.lightGrey )
for i = 1, #warnings do
	print( warnings[i] )
end
term.setTextColour( colours.white )

if command == "workspace.help" then
	if flags.interactive then
		return help_interactive( params[1] )
	else
		local w, h = term.getSize()
		local lines = wordwrap( workspace.get_help_text( params[1] ), w )
		local c = nil
		local o = select( 2, term.getCursorPos() ) - 1

		for i = 1, #lines do
			c = writef( lines[i], c, colours.white, colours.grey )
			write "\n"

			if i >= h - 2 then
				local c = term.getTextColour()
				term.setTextColour( colours.white )
				write "Press any key to continue"
				os.pullEvent "key"
				term.clearLine()
				term.setCursorPos( 1, h )
				term.setTextColour( c )
			end
		end
	end
elseif command == "workspace.init" then
	shell.setCompletionFunction( shell.getRunningProgram(), autocomplete )

	if not getconf() then
		if not initconf() then
			return error( "failed to initialise config", 0 )
		end
	end

	if flags.shell then
		shell.run "rom/startup"
		shell.run "rom/programs/shell"
	end
elseif command == "workspace.show" then
	local list = workspace.list_workspaces( flags.all and workspace.WORKSPACE_INVALID or workspace.WORKSPACE_EMPTY )
	local maxwidth = 0
	local red, orange, green = {}, {}, {}

	for i = 1, #list do
		local t = list[i].mode == workspace.WORKSPACE_INVALID and red
		       or list[i].mode == workspace.WORKSPACE_NOCONFIG and orange
			   or green
		insert( t, list[i].name )
	end

	textutils.pagedTabulate( colours.green, green, colours.orange, orange, colours.red, red )
elseif command == "workspace.create" then
	if params[1] then
		return assert0( workspace.create( params[1], flags.repair ) )
	else
		return error( "expected workspace name, got nothing", 0 )
	end
elseif command == "workspace.remove" then
	if params[1] then
		return assert0( workspace.remove( params[1], flags.hard ) )
	else
		return error( "expected workspace name, got nothing", 0 )
	end
elseif command == "workspace.link" then
	return error( "expected subcommand [add, remove, list] for `workspace link`", 0 )
elseif command == "workspace.link.add" then
	if params[1] then
		if params[2] then
			params[3] = params[3] or params[2]
		else
			return error( "expected link name for `workspace link add`" )
		end

		return assert0( workspace.set_link( params[1], params[2], params[3] ) )
	else
		return error( "expected workspace name for `workspace link add`" )
	end
elseif command == "workspace.link.remove" then
	if params[1] then
		if not params[2] then
			return error( "expected link name for `workspace link remove`" )
		end

		return assert0( workspace.set_link( params[1], params[2], nil ) )
	else
		return error( "expected workspace name for `workspace link remove`" )
	end
elseif command == "workspace.link.list" then
	if params[1] then
		local links = workspace.list_links( params[1] )

		for i = 1, #links do
			term.setTextColour( colours.white )
			write( links[i].name )
			term.setTextColour( colours.grey )
			write " -> "
			term.setTextColour( colours.lightGrey )
			print( links[i].link )
		end
	else
		return error( "expected workspace name for `workspace link list`" )
	end
elseif command == "workspace.open" then
	if params[1] then
		return assert0( workspace.open( params[1] ) )
	else
		local active = workspace.get_active()

		if active then
			write( active.name )
			term.setTextColour( colours.lightGrey )
			print " is open"
		else
			write "nothing"
			term.setTextColour( colours.lightGrey )
			print " is open"
		end
	end
elseif command == "workspace.close" then
	return assert0( workspace.close() )
elseif command == "workspace.config" then
	return error( "expected subcommand [set, get, list] for `workspace config`", 0 )
elseif command == "workspace.config.set" then
	if not params[1] then
		return error( "expected config option name", 0 )
	elseif not params[2] then
		return error( "expected config option value", 0 )
	end

	local t = getconf()
	t[params[1]] = params[2]
	setconf( t )
elseif command == "workspace.config.get" then
	if not params[1] then
		return error( "expected config option name", 0 )
	end

	print( getconf( params[1] ) or "nothing found" )
elseif command == "workspace.config.list" then
	for k, v in pairs( getconf() ) do
		term.setTextColour( colours.white )
		write( k )
		term.setTextColour( colours.grey )
		write " = "
		term.setTextColour( colours.lightGrey )
		print( v )
	end
elseif command == "workspace" then
	return error( "expected valid subcommand after `workspace`", 0 )
else
	error( command, table.concat( params, ", " ) )
end
