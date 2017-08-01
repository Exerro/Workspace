
local function normalise_filesystem_path( path ) -- TODO: revise these
	return path:gsub( "//+", "/" )
	           :gsub( "^/", "" )
			   :gsub( "/$", "" )
			   :gsub( "[^/]*/%.%./", "/" )
			   :gsub( "/%./", "/" )
			   :gsub( "^%.%./", "" )
			   :gsub( "^%./", "" )
end

local function wildcard_to_pattern( wildcard )
	return "^" .. wildcard:gsub( "[%%%.%-%+%$%^%?]", "%%%1" ):gsub( "%*", ".*" ) .. "$"
end

-- @localise create_sub_fs
function create_sub_fs( subpath, links )
	local subfs = { _workspace_filesystem = true }

	subpath = normalise_filesystem_path( subpath )

	local function resolve_path( path )
		path = normalise_filesystem_path( path )

		for k, v in next, links do
			local s = path:sub( 1, #k + 1 )

			if s == k or s == k .. "/" then
				return v .. "/" .. path:sub( #k + 2 )
			end
		end

		return subpath .. "/" .. path
	end

	function subfs.open( path, mode )
		return fs.open( resolve_path( path ), mode )
	end

	function subfs.isReadOnly( path )
		return fs.isReadOnly( resolve_path( path ) )
	end

	function subfs.move( path1, path2 )
		return fs.move( resolve_path( path1 ), resolve_path( path2 ) )
	end

	function subfs.copy( path1, path2 )
		return fs.copy( resolve_path( path1 ), resolve_path( path2 ) )
	end

	function subfs.delete( path )
		return fs.delete( resolve_path( path ) )
	end

	function subfs.isDir( path )
		return fs.isDir( resolve_path( path ) )
	end

	function subfs.getFreeSpace( path )
		return fs.getFreeSpace( resolve_path( path ) )
	end

	function subfs.getDrive( path )
		return fs.getDrive( resolve_path( path ) )
	end

	function subfs.getSize( path )
		return fs.getSize( resolve_path( path ) )
	end

	function subfs.list( path ) -- TODO: add listings for drives
		local npath = normalise_filesystem_path( path )
		local rpath = resolve_path( path )
		local resort = false
		local t

		if fs.isDir( rpath ) then
			t = fs.list( rpath )
		else
			return error "Not a directory"
		end

		for k, v in pairs( links ) do
			local insert = false
			local toinsert

			if path == "" or k:find( "^" .. npath .. "/" ) then
				insert = true
				toinsert = k:sub( #npath + 1 ):gsub( "^/?(.-)/.*", "%1" )

				for n = 1, #t do
					if t[i] == toinsert then
						insert = false
					end
				end
			end

			if insert then
				resort = true
				t[#t + 1] = toinsert
			end
		end

		if resort then
			table.sort( t )
		end

		return t
	end

	function subfs.exists( path )
		return fs.exists( resolve_path( path ) )
	end

	function subfs.makeDir( path )
		return fs.makeDir( resolve_path( path ) )
	end

	-- ported from https://github.com/alekso56/ComputercraftLua/blob/master/bios.lua#L676
	function subfs.complete( sPath, sLocation, bIncludeFiles, bIncludeDirs )
	    bIncludeFiles = (bIncludeFiles ~= false)
	    bIncludeDirs = (bIncludeDirs ~= false)
	    local sDir = sLocation
	    local nStart = 1
	    local nSlash = string.find( sPath, "[/\\]", nStart )
	    if nSlash == 1 then
	        sDir = ""
	        nStart = 2
	    end
	    local sName
	    while not sName do
	        local nSlash = string.find( sPath, "[/\\]", nStart )
	        if nSlash then
	            local sPart = string.sub( sPath, nStart, nSlash - 1 )
	            sDir = subfs.combine( sDir, sPart )
	            nStart = nSlash + 1
	        else
	            sName = string.sub( sPath, nStart )
	        end
	    end

	    if subfs.isDir( sDir ) then
	        local tResults = {}
	        if bIncludeDirs and sPath == "" then
	            table.insert( tResults, "." )
	        end
	        if sDir ~= "" then
	            if sPath == "" then
	                table.insert( tResults, (bIncludeDirs and "..") or "../" )
	            elseif sPath == "." then
	                table.insert( tResults, (bIncludeDirs and ".") or "./" )
	            end
	        end
	        local tFiles = subfs.list( sDir )
	        for n=1,#tFiles do
	            local sFile = tFiles[n]
	            if #sFile >= #sName and string.sub( sFile, 1, #sName ) == sName then
	                local bIsDir = subfs.isDir( subfs.combine( sDir, sFile ) )
	                local sResult = string.sub( sFile, #sName + 1 )
	                if bIsDir then
	                    table.insert( tResults, sResult .. "/" )
	                    if bIncludeDirs and #sResult > 0 then
	                        table.insert( tResults, sResult )
	                    end
	                else
	                    if bIncludeFiles and #sResult > 0 then
	                        table.insert( tResults, sResult )
	                    end
	                end
	            end
	        end
	        return tResults
	    end
	    return tEmpty
	end

	function subfs.find( wildcard )
		local segments = {}

		for seg in normalise_filesystem_path( wildcard ):gmatch( "[^/]+" ) do
			segments[#segments + 1] = seg
		end

		local srcdirectories = { "" }

		for i = 1, #segments do
			local pat = wildcard_to_pattern( segments[i] )

			for n = #srcdirectories, 1, -1 do
				local subdir = table.remove( srcdirectories, n )
				local file_list = subfs.list( subdir )

				for j = #file_list, 1, -1 do
					if not file_list[j]:find( pat ) then
						table.remove( file_list, j )
					end
				end

				for j = 1, #file_list do
					table.insert( srcdirectories, n + j - 1, fs.combine( subdir, file_list[j] ) )
				end
			end
		end

		return srcdirectories
	end

	subfs.getName = fs.getName
	subfs.combine = fs.combine
	subfs.getDir = fs.getDir

	return subfs
end
