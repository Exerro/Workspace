
-- @include subfs
-- @include util

-- @localise create_sub_environment
function create_sub_environment( path, links, workspace_api )
	local subfs
	local env = setmetatable( {}, { __index = _G } )

	subfs = create_sub_fs( path, links )

	env.fs = subfs
	env.workspace = workspace_api
	env._G = env
	env._ENV = env
	env.os = {}; for k, v in pairs( os ) do env.os[k] = v end

	function env.loadfile( _sFile, _tEnv )
		local file = subfs.open( _sFile, "r" )
		if file then
			local func, err = load( file.readAll(), subfs.getName( _sFile ), "t", _tEnv )
			file.close()
			return func, err
		end
		return nil, "File not found"
	end

	function env.dofile( _sFile )
		local fnFile, e = env.loadfile( _sFile, env )
		if fnFile then
			return fnFile()
		else
			error( e, 2 )
		end
	end

	local tAPIsLoading = {}
	function env.os.loadAPI( _sPath )
		local sName = subfs.getName( _sPath )
		if sName:sub(-4) == ".lua" then
			sName = sName:sub(1,-5)
		end
		if tAPIsLoading[sName] == true then
			printError( "API "..sName.." is already being loaded" )
			return false
		end
		tAPIsLoading[sName] = true

		local tEnv = {}
		setmetatable( tEnv, { __index = env } )
		local fnAPI, err = env.loadfile( _sPath, tEnv )
		if fnAPI then
			local ok, err = pcall( fnAPI )
			if not ok then
				printError( err )
				tAPIsLoading[sName] = nil
				return false
			end
		else
			printError( err )
			tAPIsLoading[sName] = nil
			return false
		end

		local tAPI = {}
		for k,v in pairs( tEnv ) do
			if k ~= "_ENV" then
				tAPI[k] =  v
			end
		end

		env[sName] = tAPI
		tAPIsLoading[sName] = nil
		return true
	end

	function env.os.unloadAPI( name )
		env[name] = nil
	end

	function env.os.run( _tEnv, _sPath, ... )
		local tArgs = table.pack( ... )
		local tEnv = _tEnv
		setmetatable( tEnv, { __index = env } )
		local fnFile, err = env.loadfile( _sPath, tEnv )
		if fnFile then
			local ok, err = pcall( function()
				fnFile( table.unpack( tArgs, 1, tArgs.n ) )
			end )
			if not ok then
				if err and err ~= "" then
					printError( err )
				end
				return false
			end
			return true
		end
		if err and err ~= "" then
			printError( err )
		end
		return false
	end

	env.os.loadAPI "rom/apis/io.lua"
	env.os.loadAPI "rom/apis/settings.lua"

	for i, name in ipairs( settings.getNames() ) do
		env.settings.set( name, settings.get( name ) )
	end

	return env
end
