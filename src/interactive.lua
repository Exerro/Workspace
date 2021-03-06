
local function help_interactive( topic )
	local breadcrumbs = { "Home", topic and "commands" or nil, topic and topic ~= "commands" and topic or nil }
	local scroll = 0
	local ch = 0
	local scrollbar = false
	local content_height = 0
	local w, h = term.getSize()
	local t = {}

	while true do
		local breadcrumb_text_length = #table.concat( breadcrumbs, " > " )
		local text
		local c = 0

		w, h = term.getSize()
		ch = h - 6
		scrollbar = false
		scrollbar_height = 0

		term.setBackgroundColour( colours.white )
		term.clear()
		term.setBackgroundColour( colours.grey )

		for i = 1, 3 do
			term.setCursorPos( 1, i )
			term.clearLine()
		end

		term.setCursorPos( 2, 2 )
		term.setTextColour( colours.white )
		term.write "Help"
		term.setBackgroundColour( colours.cyan )
		term.setTextColour( colours.white )
		term.setCursorPos( w - 6, 2 )
		term.write " exit "

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
			c = writef( t[i + scroll], c, colours.grey, colours.lightGrey )
		end

		if #breadcrumbs == 1 then
			term.setTextColour( colours.blue )
			term.setCursorPos( 3, #t + 7 - scroll )
			term.write "See command list"
			content_height = content_height + 2
		end

		if scrollbar then
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

		local ev = { os.pullEvent() }

		if ev[1] == "mouse_click" and ev[2] == 1 and ev[3] >= w - 6 and ev[3] <= w - 1 and ev[4] == 2 then
			break
		else
			if ev[1] == "mouse_scroll" and scrollbar then
				if ev[2] == 1 and scroll < content_height - ch or ev[2] == -1 and scroll > 0 then
					scroll = scroll + ev[2]
				end
			elseif ev[1] == "key" then
				if ev[2] == keys.down and scroll < content_height - ch or ev[2] == keys.up and scroll > 0 then
					scroll = scroll + (ev[2] == keys.up and -1 or 1)
				elseif ev[2] == keys.backspace then
					break
				end
			elseif ev[1] == "mouse_click" and ev[2] then
				local x, y = ev[3], ev[4]
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
	end
end
