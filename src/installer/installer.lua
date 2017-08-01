
local h = http.get "https://api.github.com/repos/Exerro/Workspace/releases"
local file_url = "https://github.com/Exerro/Workspace/releases/download/v0.1.0/workspace.lua"
local file_url_min = "https://github.com/Exerro/Workspace/releases/download/v0.1.0/workspace.min.lua"
local install_path = "/"
local workspaces_path = "/workspaces"
local startup_init = false
local startup_workspace = nil
local startup_alias = false

local function option( t )
	local idx = t.default
	local ev = {}

	while true do
		if ev[1] == "key" then
			if ev[2] == keys.left and idx > 1 then
				idx = idx - 1
			elseif ev[2] == keys.right and idx < #t then
				idx = idx + 1
			elseif ev[2] == keys.enter then
				write "\n"
				return t[idx]
			end
		end

		term.clearLine()
		term.setCursorPos( 1, select( 2, term.getCursorPos() ) )

		for i = 1, #t do
			term.write( i == idx and "[" or " " )
			term.write( t[i] )
			term.write( i == idx and "] " or "  " )
		end

		ev = { os.pullEvent() }
	end
end

--[[ JSON decoder

	A modified version of http://pastebin.com/4nRg9CHU
	by ElvishJerricco. All credit goes to him.
	Changes include removing the encoder and
	removing global function definitions.

]]

------------------------------------------------------------------ utils
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}

local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
local function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

------------------------------------------------------------------ decoding

local parseBoolean, parseNull, parseNumber, parseString, parseArray, parseObject, parseMember, parseValue

local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end

function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

function parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1,1) ~= "\"" do
		local next = str:sub(1,1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")

		if next == "\\" then
			local escape = str:sub(1,1)
			str = str:sub(2)

			next = assert(decodeControls[next..escape], "Invalid escape character")
		end

		s = s .. next
	end
	return s, removeWhite(str:sub(2))
end

function parseArray(str)
	str = removeWhite(str:sub(2))

	local val, i, v = {}, 1
	while str:sub(1, 1) ~= "]" do
		val[i], str = parseValue(str)
		i = i + 1
		str = removeWhite(str)
	end

	return val, removeWhite(str:sub(2))
end

function parseObject(str)
	str = removeWhite(str:sub(2))

	local val, k, v = {}
	while str:sub(1, 1) ~= "}" do
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end

	return val, removeWhite(str:sub(2))
end

function parseMember(str)
	local k, str = parseValue(str)
	return k, parseValue(str)
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

--[[ End of JSON decoder ]]

if h then
	local text = h.readAll()
	h.close()

	local obj = parseValue( text )
	local ver = obj[1]

	local function compare_tags( a, b )
		local i = 1
		for d in a.tag:gmatch "%d+" do
			local an = tonumber( d )
			local bn = tonumber( b.tag:match( ("%d+%."):rep( i - 1 ) .. "(%d+)" .. ("%.%d+"):rep( 3 - i ) ) or "0" )
			if an > bn then return true end
			if bn > an then return false end
			i = i + 1
		end
		return false
	end

	for i = 2, #obj do
		if comparetags( obj[i], ver ) then
			ver = obj[i]
		end
	end

	for n = 1, #ver.assets do
		local a = ver.assets[n].name

		if a:find "^%w+%.lua$" then
			file_url = ver.assets[n].browser_download_url
		elseif a:find "^%w+%.min.lua$" then
			file_url_min = ver.assets[n].browser_download_url
		end
	end
end

print "Welcome to the Workspace installer"
print "Download minified program?"

if option { default = 2, "Yes", "No" } == "Yes" then
	file_url = file_url_min
end

print( "Use default program install path (" .. install_path .. ")?" )

if option { default = 1, "Yes", "No" } == "No" then
	print "Please enter install path"
	repeat
		 install_path = read()
	until fs.isDir( install_path ) or print( "Please enter a directory path" ) and false
end

print( "Use default workspaces path (" .. workspaces_path .. ")?" )

if option { default = 1, "Yes", "No" } == "No" then
	print "Please enter workspaces path"
	repeat
		 workspaces_path = read()
	until fs.isDir( workspaces_path ) or not fs.exists( workspaces_path ) or print( "Please enter a valid path" ) and false
end

print "Installing..."

fs.makeDir( workspaces_path )

local h = http.get( file_url )

if h then
	local text = h.readAll()
	h.close()

	print "Move computer files to workspace?"

	if option { default = 2, "Yes", "No" } == "Yes" then
		print "Enter workspace name: "
		local wname = read()
		local wdir = fs.combine( workspaces_path, wname )

		fs.makeDir( wdir )

		for i, v in ipairs( fs.list "/" ) do
			if not fs.isReadOnly( v ) and v ~= (workspaces_path:match "([^/]+)/" or workspaces_path) then
				print( "Moving " .. v )
				fs.move( v, fs.combine( wdir, v ) )
			end
		end
	end

	local h = fs.open( fs.combine( install_path, "workspace.lua" ), "w" )

	if h then
		h.write( text )
		h.close()
	else
		return error( "Failed to install workspace.lua", 0 )
	end
else
	return error( "Failed to download workspace.lua", 0 )
end

local h = fs.open( ".workspace", "w" )

if h then
	h.write( ("{\n\tworkspaces_path = %q,\n\tinstall_path = %q,\n}"):format( workspaces_path, install_path ) )
	h.close()
else
	printError( "Warning: failed to write config file" )
end

print "Initialise on startup?"

if option { default = 1, "Yes", "No" } == "Yes" then
	startup_init = true
	print "Run specific workspace on startup?"

	if option { default = 2, "Yes", "No" } == "Yes" then
		print "Enter workspace name:"
		startup_workspace = read()
	end
end

print "Alias workspace.lua ?"
startup_alias = option { default = fs.combine( install_path, "" ) ~= "" and 1 or 2, "workspace", "w", "<none>" }

if startup_alias == "<none>" then
	startup_alias = nil
end

if startup_init or startup_alias then
	local h = fs.open( "startup", "w" )

	if h then
		if startup_init then
			h.writeLine( ([[shell.run %q]]):format( fs.combine( install_path, "workspace.lua init" ) ) )
		end
		if startup_alias then
			h.writeLine( ([[shell.setAlias( %q, %q )]]):format( startup_alias, fs.combine( install_path, "workspace.lua" ) ) )
		end
		if startup_workspace then
			h.writeLine( ([[shell.run %q]]):format( fs.combine( install_path, "workspace.lua open " .. startup_workspace ) ) )
		end
		h.close()
	else
		return error( "Failed to write to startup", 0 )
	end
end
