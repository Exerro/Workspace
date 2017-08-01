
-- @include util

-- @localise autocomplete
function autocomplete( shell, par_number, cur_text, last_text )
	local ok, data = pcall( function()
		if #last_text == 1 then
			return filter_command_list( program.commands, cur_text )
		end

		local cmd, params, flags, warnings = get_command_and_data( { unpack( last_text, 2 ) } )
		local command_data = getcmd( cmd )
		local suggestions = {}
		local wname = nil

		for i = 1, #command_data.params do
			if params[i] then
				if command_data.params[i] == "current-workspace-name" or command_data.params[i] == "workspace-name" then
					wname = params[i]
				end
			else
				break
			end
		end

		if cmd == "workspace.link" or cmd == "workspace.config" then
			return filter_command_list( command_data.commands, cur_text )
		end

		if #params < #command_data.params then
			local param = command_data.params[#params + 1]

			if param == "workspace-name" or param == "current-workspace-name" then
				suggestions = filter_text( workspace.list_workspaces( workspace.WORKSPACE_EMPTY ):names(), cur_text )
			elseif param == "new-workspace-name" then
				suggestions = cur_text == "" and { "workspace-name" } or {}
			elseif param == "link-name" and wname then
				suggestions = filter_text( workspace.list_links( wname ):names(), cur_text )
			elseif param == "new-link-name" or param == "link-name" then
				suggestions = filter_text( cur_text == "" and { "link-name" } or {}, cur_text )
			elseif param == "path" then
				suggestions = filter_text( file_find( cur_text, true ), cur_text )
			elseif param == "config-option" then
				local t = {}
				for k, v in pairs( getconf() ) do
					t[#t + 1] = k
				end
				suggestions = filter_text( t, cur_text )
			elseif param == "config-value" then
				local config_option = last_text[#last_text] or ""

				if config_option == "install_path" or config_option == "workspaces_path" then
					suggestions = filter_text( file_find( cur_text, false ), cur_text )
				else
					suggestions = {}
				end
			elseif param == "help-topic" then
				local t = { "commands" }

				for i = 1, #program.commands do
					insert( t, program.commands[i].name )
				end

				suggestions = filter_text( t, cur_text )
			end

			if #params < #command_data.params - 1 then
				for i = 1, #suggestions do
					suggestions[i] = suggestions[i] .. " "
				end
			end
		end

		for k, v in pairs( flags ) do
			if not v then
				if cur_text == "" or ("--" .. k):find( "^" .. escape_patterns( cur_text ) ) then
					insert( suggestions, ("--" .. k):sub( #cur_text + 1 ) )
				end
			end
		end

		return suggestions
	end )

	if not ok then
		return { "error: " .. tostring( data ) }
	end

	return data
end
