
local ARGS = { ... }

-- @define WORKSPACE_DIR ('/workspaces')
-- @define WORKSPACE_META ('{\n\tname = %q,\n\tlinks = {\n\t\t["rom"] = "rom"\n\t}\n}')

-- @include lib
-- @include autocomplete
-- @include util

-- @localise program
program = {
	name = "workspace",
	description = "Allows switching between multiple workspaces with a unique filesystem",
	flags = {},
	params = {},
	commands = {
		{ name = "help", alias = "h", description = "Displays help", flags = {}, params = { "help-topic" } },
		{ name = "show", alias = "s", description = "Displays a list of all workspaces", flags = { "all", "interactive" }, params = {} },
		{ name = "create", alias = "c", description = "Creates a new workspace", flags = {}, params = { "new-workspace-name" } },
		{ name = "remove", alias = "r", description = "Removes an existing workspace, use --hard to remove all workspace files", flags = { "hard" }, params = { "workspace-name" } },
		{ name = "link", alias = "l", description = "Manages workspace links", flags = {}, params = {}, commands = {
			{ name = "add", alias = "a", description = "Adds a link to the workspace", flags = {}, params = { "current-workspace-name", "new-link-name", "path" } },
			{ name = "remove", alias = "r", description = "Removes a link from the workspace", flags = {}, params = { "current-workspace-name", "link-name" } },
			{ name = "list", alias = "l", description = "Lists all links of the workspace", flags = { "interactive" }, params = { "current-workspace-name" } }
		} },
		{ name = "open", alias = "o", description = "Opens a workspace, or shows the open workspace if no name is given", flags = {}, params = { "workspace-name" } },
		{ name = "close", alias = "x", description = "Closes the open workspace", flags = {}, params = {} },
		{ name = "init", alias = "i", description = "Initialises workspace-related globals", flags = { "shell" }, params = {}, hidden = true }
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
		return print( "`help --interactive` not yet implemented" ) or help_interactive()
	else
		local y = 1

		local function newline()
			y = y + 1
			if y > select( 2, term.getSize() ) - 2 then
				local c = term.getTextColour()
				term.setTextColour( colours.white )
				write "\nPress any key to continue"
				os.pullEvent "key"
				term.clearLine()
				term.setCursorPos( 1, select( 2, term.getCursorPos() ) )
				term.setTextColour( c )
			else
				write "\n"
			end
		end

		for line in workspace.get_help_text( params[1] ):gmatch "[^\n]+" do
			term.setTextColour( colours.white )

			for word in line:gmatch "%S+" do
				if word:sub( 1, 1 ) == "<" or word:sub( 1, 1 ) == "[" or word:sub( 1, 1 ) == "'" or word:sub( 1, 1 ) == "`" then
					term.setTextColour( colours.lightGrey )
				end

				if word == "-" then
					term.setTextColour( colours.grey )
				end

				if #word > term.getSize() - term.getCursorPos() + 1 then
					newline()
				end

				term.write( word:gsub( "^`", "", 1 ):gsub( "`$", "", 1 ) .. " " )

				if word:sub( -1 ) == ">" or word:sub( -1 ) == "]" or word:sub( -1 ) == "'" or word:sub( -1 ) == "`" then
					term.setTextColour( colours.white )
				end
			end

			newline()
		end
		term.setTextColour( colours.white )
	end
elseif command == "workspace.init" then
	shell.setCompletionFunction( shell.getRunningProgram(), autocomplete )
elseif command == "workspace.show" then
	if flags.interactive then
		return print( "`show --interactive` not yet implemented" ) or show_interactive( flags.all )
	end

	local list = workspace.get_workspace_list( flags.all and workspace.WORKSPACE_INVALID or workspace.WORKSPACE_EMPTY )
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
	if flags.interactive then
		return print( "`create --interactive` not yet implemented" ) or create_interactive( params[1] )
	elseif params[1] then
		return assert0( workspace.create( params[1] ) )
	else
		return error( "expected workspace name, got nothing", 0 )
	end
elseif command == "workspace.remove" then
	if flags.interactive then
		return print( "`remove --interactive` not yet implemented" ) or create_interactive( params[1] )
	elseif params[1] then
		return assert0( workspace.remove( params[1], flags.hard ) )
	else
		return error( "expected workspace name, got nothing", 0 )
	end
elseif command == "workspace.link" then
	if flags.interactive then
		return print( "`link --interactive` not yet implemented" ) or link_interactive( nil )
	else
		return error( "expected subcommand [add, remove, list] for `workspace link`", 0 )
	end
elseif command == "workspace.link.add" then
	if flags.interactive then
		return print( "`link add --interactive` not yet implemented" ) or link_interactive( "add", params )
	elseif params[1] then
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
	if flags.interactive then
		return print( "`link remove --interactive` not yet implemented" ) or link_interactive( "remove", params )
	elseif params[1] then
		if not params[2] then
			return error( "expected link name for `workspace link remove`" )
		end

		return assert0( workspace.set_link( params[1], params[2], nil ) )
	else
		return error( "expected workspace name for `workspace link remove`" )
	end
elseif command == "workspace.link.list" then
	if flags.interactive then
		return print( "`link list --interactive` not yet implemented" ) or link_interactive( "list", params )
	elseif params[1] then
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
	if flags.interactive then
		return print( "`open --interactive` not yet implemented" ) or open_interactive()
	elseif params[1] then
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
elseif command == "workspace" then
	if flags.interactive then
		return print( "`--interactive` not yet implemented" ) or interactive()
	else
		return error( "expected valid subcommand after `workspace`", 0 )
	end
else
	error( command, table.concat( params, ", " ) )
end
