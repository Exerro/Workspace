
local function drawheader( name, w, h )
	term.setBackgroundColour( colours.white )
	term.clear()
	term.setBackgroundColour( colours.grey )

	for i = 1, 3 do
		term.setCursorPos( 1, i )
		term.clearLine()
	end

	term.setCursorPos( 2, 2 )
	term.setTextColour( colours.white )
	term.write( name )
	term.setBackgroundColour( colours.cyan )
	term.setTextColour( colours.white )
	term.setCursorPos( w - 6, 2 )
	term.write( root_interactive and " back " or " exit " )
end

local function drawscrollbar( w, h, ch, content_height, scroll )
	local scrollbar_height = math.floor( math.max( 2, ch * ch / content_height ) + 0.5 )
	local scrollbar_offset = math.floor( scroll / (content_height - ch) * (ch - scrollbar_height) + 0.5 )

	term.setBackgroundColour( colours.grey )

	for i = 0, ch - 1 do
		term.setCursorPos( w - 1, h - ch + i )

		if i == scrollbar_offset then
			term.setBackgroundColour( colours.lightGrey )
		elseif i == scrollbar_offset + scrollbar_height then
			term.setBackgroundColour( colours.grey )
		end

		term.write " "
	end
end

local function eventloop( draw, handle )
	while true do
		local w, h, ch, scrollbar, content_height, scroll = draw()

		if scrollbar then
			drawscrollbar( w, h, ch, content_height, scroll )
		end

		local ev = { os.pullEvent() }

		if ev[1] == "mouse_click" and ev[2] == 1 and ev[3] >= w - 6 and ev[3] <= w - 1 and ev[4] == 2 then
			break
		elseif ev[1] == "mouse_scroll" and scrollbar then
			if ev[2] == 1 and scroll < content_height - ch or ev[2] == -1 and scroll > 0 then
				handle( "scroll", ev[2] )
			end
		elseif ev[1] == "key" then
			if ev[2] == keys.down and scroll < content_height - ch or ev[2] == keys.up and scroll > 0 then
				handle( "scroll", ev[2] == keys.up and -1 or 1 )
			elseif ev[2] == keys.backspace then
				break
			end
		else
			handle( unpack( ev ) )
		end
	end
end

local function interactive( wname )
	
end

local function help_interactive( topic )
	local breadcrumbs = { "Home", topic and "commands" or nil, topic ~= "commands" and topic }
	local scroll = 0
	local ch = 0
	local scrollbar = false
	local content_height = 0
	local w, h = term.getSize()
	local t = {}

	local function draw()
		local breadcrumb_text_length = #table.concat( breadcrumbs, " > " )
		local text
		local c = 0

		w, h = term.getSize()
		ch = h - 6
		scrollbar = false
		scrollbar_height = 0

		drawheader( "Help", w, h )

		term.setBackgroundColour( colours.white )
		term.setCursorPos( math.min( 2, w - breadcrumb_text_length - 1 ), 4 )
		term.setTextColour( colours.grey )
		term.write( breadcrumbs[1] )

		for i = 2, #breadcrumbs do
			term.setTextColour( colours.lightGrey )
			term.write " > "
			term.setTextColour( colours.grey )
			term.write( breadcrumbs[i] )
		end

		if #breadcrumbs == 1 then
			text = workspace.get_help_text():gsub( "\n", "\n\n" )
		elseif #breadcrumbs == 2 then
			text = workspace.get_help_text( "commands" ):gsub( "\n", "\n\n" )
		elseif #breadcrumbs == 3 then
			text = workspace.get_help_text( breadcrumbs[3] ):gsub( "\n", "`\n\n" ):gsub( " %- ", "\n`" )
		end

		t = wordwrap( text, w - 2 )

		if #t > ch then
			t = wordwrap( text, w - 3 )
			scrollbar = true
			content_height = #t
		end

		for i = 1, math.min( #t - scroll, ch ) do
			term.setCursorPos( 2, i + 5 )
			c = writef( t[i + scroll], c )
		end

		if #breadcrumbs == 1 then
			term.setTextColour( colours.blue )
			term.setCursorPos( 3, #t + 7 - scroll )
			term.write "See command list"
			content_height = content_height + 2
		end

		return w, h, ch, scrollbar, content_height, scroll
	end

	local function handle( event, ... )
		if event == "scroll" then
			scroll = scroll + ...
		elseif event == "mouse_click" and (...) == 1 then
			local _, x, y = ...
			if #breadcrumbs == 1 and x >= 3 and x <= 18 and y == #t + 7 - scroll then
				breadcrumbs[2] = "commands"
				scroll = 0
			elseif y == 4 then
				if x >= 2 and x <= 5 then
					breadcrumbs = { breadcrumbs[1] }
					scroll = 0
				elseif breadcrumbs[2] and x >= 9 and x <= 8 + #breadcrumbs[2] then
					breadcrumbs[3] = nil
					scroll = 0
				end
			elseif #breadcrumbs == 2 and y > 5 then
				local l = y + scroll - 5
				local lt = t[l]

				while not lt:find "^workspace %w+" do
					if lt == "" then
						return
					end
					l = l - 1
					lt = t[l]
				end

				breadcrumbs[3] = lt:match "^workspace (%w+)"
				scroll = 0
			end
		end
	end

	eventloop( draw, handle )
end

local function show_interactive( all )
	local scroll = 0
	local ch = 0
	local scrollbar = false
	local content_height = 0
	local w, h = term.getSize()
	local t = {}

	local function draw()
		w, h = term.getSize()
		ch = h - 5
		scrollbar = false
		scrollbar_height = 0
		t = workspace.get_workspace_list( all and workspace.WORKSPACE_NOCONFIG or workspace.WORKSPACE_EMPTY )

		drawheader( "Show", w, h )

		if #t > ch then
			scrollbar = true
			content_height = #t
		end

		term.setBackgroundColour( colours.white )

		for i = 1, math.min( #t - scroll, ch ) do
			local wspace = t[i + scroll]
			term.setCursorPos( 2, i + 4 )
			term.setTextColour( wspace.mode == workspace.WORKSPACE_NOCONFIG and colours.yellow or wspace.mode == workspace.WORKSPACE_EMPTY and colours.lightGrey or colours.grey )
			term.write( wspace.name )
			term.setTextColour( colours.blue )
			term.setCursorPos( scrollbar and w - 5 or w - 4, i + 4 )
			term.write "..."
		end

		return w, h, ch, scrollbar, content_height, scroll
	end

	local function handle( event, ... )
		if event == "scroll" then
			scroll = scroll + ...
		elseif event == "mouse_click" and (...) == 1 then
			local _, x, y = ...

			if x <= w - (scrollbar and 3 or 2) and x >= w - (scrollbar and 5 or 4) and y >= 5 and y <= h - 1 then
				local wspace = t[y - 4 + scroll]

				if wspace then
					return interactive( wspace.name )
				end
			end
		end
	end

	eventloop( draw, handle )
end
