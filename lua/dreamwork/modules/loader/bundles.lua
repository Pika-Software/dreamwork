---@class dreamwork
local dreamwork = dreamwork

local dreamwork_sigil = dreamwork.sigil
local sigil_preprocess = dreamwork_sigil.preprocess

---@type dreamwork.transport | nil
local dreamwork_transport = dreamwork.transport

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_type = raw.type
local raw_pairs = raw.pairs

local string = std.string
local string_sub = string.sub
local string_find = string.find
local string_match = string.match
local string_format = string.format
local string_gmatch = string.gmatch
local string_isBytecode = string.isBytecode

local table = std.table
local table_sort = table.sort
local table_concat = table.concat

local path_wildcard = std.path.wildcard

local futures = std.futures
local futures_run = futures.run

local jit_version_byte = std.jit.version_byte

local pcall = std.pcall

local json = std.json
local json_serialize = json.serialize
local json_deserialize = json.deserialize

local cli_formatBytes = dreamwork.cli.formatBytes

local Zip = std.Zip


---@class dreamwork.loader
local loader = dreamwork.loader

local internal = loader.Internal
local package_states = internal.package_states
local by_id = internal.by_id
local create_sigil_env = internal.create_sigil_env
local source_files = internal.source_files
local source_read = internal.source_read
local is_lua_file = internal.is_lua_file
local include_reader = internal.include_reader
local parse_manifest = internal.parse_manifest
local register = internal.register
local load_package = internal.load_package

---@param data string
---@return dreamwork.std.Zip
local function parse_zip( data )
    return Zip( data )
end


--- [SHARED]
---
--- Client bundles: the server packs the files of client packages with Lua preprocessed for the client
--- and gives them to `dreamwork.transport`, the client registers and loads the packages it received.
---

---@type dreamwork.std.Event
local Synchronizing = loader.Synchronizing

---@type dreamwork.std.Event
local Synchronized = loader.Synchronized

--- The `Zip` comment of client bundles, their Lua files are already preprocessed.
---
---@type string
local BUNDLE_COMMENT = "dreamwork.bundle"

--- The modification time of files in client bundles, `2000-01-01 00:00:00` UTC.
---
---@type integer
local BUNDLE_TIMESTAMP = 946684800

--- Files of at least this size (other than Lua) are sent as their own transport files, `{id}/{path}`,
--- so a change of the code does not download them again, the client keeps them by their hashes.
---
---@type integer
local EXTERNAL_FILE_SIZE = 0x10000

--- The list of the files sent on their own, inside of the client bundle: `<hash> <path>` lines sorted by path,
--- a hidden file, so it never shows in the package.
---
---@type string
local EXTERNAL_LIST = ".dreamwork/external"

--- The packages received from the server, by transport file names.
---
---@type table<string, dreamwork.Package>
local remote_packages = {}

--- The `#if` environment of the client bundles.
local client_sigil_env = create_sigil_env( "client" )

--- Returns the files of the package that are sent to clients, the ones matching `client_files` in `package.json`.
---
--- `package.json` and the client entrypoint are always sent, the client can't register or load the package without them.
--- Without `client_files` only they are sent, so a forgotten list never sends the whole project.
---
---@param state dreamwork.Package.State
---@return string[] files
---@return integer file_count
local function client_files( state )
    local files, file_count = source_files( state.source )

    local manifest = state.manifest

    local wildcards = manifest.client_files
    local pattern_count = wildcards == nil and 0 or #wildcards

    ---@type string[]
    local patterns = {}

    for index = 1, pattern_count, 1 do
        ---@cast wildcards string[]
        patterns[ index ] = path_wildcard( wildcards[ index ], false )
    end

    -- `main.client` is `nil` only for packages that do not run on the client
    local main = manifest.main.client

    ---@type string[]
    local selected = {}
    local selected_count = 0

    for index = 1, file_count, 1 do
        local file_path = files[ index ]

        local is_selected = file_path == "package.json" or file_path == main

        if not is_selected then
            for pattern_index = 1, pattern_count, 1 do
                if string_find( file_path, patterns[ pattern_index ] ) ~= nil then
                    is_selected = true
                    break
                end
            end
        end

        if is_selected then
            selected_count = selected_count + 1
            selected[ selected_count ] = file_path
        end
    end

    return selected, selected_count
end

--- Builds the client bundle of the package and gives it to the transport.
---
--- Lua files are preprocessed by `sigil` for the client, so code under `#if LUA_SERVER` never leaves the server.
--- Only the files matching `client_files` of `package.json` are packed, see `dreamwork.PackageManifest.client_files`.
---
---@param state dreamwork.Package.State
---@async
local function publish( state )
    local transport = dreamwork_transport
    if transport == nil then
        return
    end

    local source = state.source

    local reader = include_reader( state, function( vfs_path )
        local file_path = string_sub( vfs_path, #state.root + 2 )

        local success, content = pcall( source_read, source, file_path )
        if success then
            return content
        end

        return nil
    end )

    local zip = Zip()
    zip.comment = BUNDLE_COMMENT

    local files, file_count = client_files( state )

    ---@type string[]
    local external_paths = {}

    ---@type string[]
    local external_contents = {}

    local external_count = 0

    for index = 1, file_count, 1 do
        local file_path = files[ index ]
        local content = source_read( source, file_path )

        -- the client finds repository packages by `repository` too (`import( "user/repo" )`)
        if file_path == "package.json" and source.repository ~= nil then
            local success, data = pcall( json_deserialize, content )
            if success and raw_type( data ) == "table" and data.repository == nil then
                data.repository = source.repository
                content = json_serialize( data )
            end
        end

        local is_lua = is_lua_file( file_path )

        if not is_lua and #content >= EXTERNAL_FILE_SIZE then
            external_count = external_count + 1
            external_paths[ external_count ] = file_path
            external_contents[ external_count ] = content
            goto file_packed
        end

        if is_lua and not source.preprocessed and not string_isBytecode( content, jit_version_byte ) then
            local vfs_path = state.root .. "/" .. file_path

            content = sigil_preprocess( content, {
                name = vfs_path,
                path = vfs_path,
                env = client_sigil_env,
                logger = state.logger,
                read = reader,
                -- clients have no native bit operators
                bit_operators = false
            } )
        end

        -- a fixed time keeps the bundle of the same files byte-identical, so clients keep their cached copy
        zip:addFile( file_path, content, nil, 14 ).timestamp = BUNDLE_TIMESTAMP

        ::file_packed::
    end

    -- unloaded while the bundle was built
    if state.realms.server and state.status ~= "loaded" then
        return
    end

    local id = state.id

    ---@type string[]
    local external_names = {}

    ---@type table<string, boolean>
    local is_external = {}

    ---@type string[]
    local lines = {}

    local external_size = 0

    -- `client_files` gives the paths sorted, so the list is the same for the same files
    for index = 1, external_count, 1 do
        local file_path, content = external_paths[ index ], external_contents[ index ]

        local name = id .. "/" .. file_path
        transport.addFile( name, content )

        external_names[ index ] = name
        is_external[ name ] = true

        lines[ index ] = transport.getFiles()[ name ].hash .. " " .. file_path
        external_size = external_size + #content
    end

    -- the files of the previous bundle that are not sent anymore
    local previous_names = state.external_files
    if previous_names ~= nil then
        for index = 1, #previous_names, 1 do
            local name = previous_names[ index ]
            if not is_external[ name ] then
                transport.delFile( name )
            end
        end
    end

    state.external_files = external_names

    if external_count ~= 0 then
        zip:addFile( EXTERNAL_LIST, table_concat( lines, "\n", 1, external_count ), nil, 14 ).timestamp = BUNDLE_TIMESTAMP
    end

    local data = zip:compile()

    transport.addFile( id, data )
    state.published = true

    if external_count == 0 then
        dreamwork.Logger:debug( "Package '%s' is sent to the clients: %d file(s), %s.", state.id, file_count, cli_formatBytes( #data ) )
    else
        dreamwork.Logger:debug( "Package '%s' is sent to the clients: %d file(s), %s, and %d large file(s) on their own, %s.", state.id, file_count - external_count, cli_formatBytes( #data ), external_count, cli_formatBytes( external_size ) )
    end
end

internal.publish = publish

--- Removes the client bundle of the package and its files sent on their own from the transport.
---
---@param state dreamwork.Package.State
local function unpublish( state )
    if not state.published then
        return
    end

    state.published = false

    local transport = dreamwork_transport
    if transport == nil then
        return
    end

    transport.delFile( state.id )

    local names = state.external_files
    if names ~= nil then
        state.external_files = nil

        for index = 1, #names, 1 do
            transport.delFile( names[ index ] )
        end
    end
end

internal.unpublish = unpublish

--- Returns the files of the client bundle that were sent on their own, by their paths.
---
---@param archive dreamwork.std.Zip
---@param id string The package id, the name of the bundle.
---@param files table<string, dreamwork.transport.File>
---@return table<string, string> | nil extra The contents by paths, `nil` if a file is missing or does not match its hash.
---@return string | nil message
local function external_files( archive, id, files )
    ---@type table<string, string>
    local extra = {}

    local list = archive:readFile( EXTERNAL_LIST )
    if list == nil then
        return extra
    end

    for line in string_gmatch( list, "[^\n]+" ) do
        local hash, file_path = string_match( line, "^(%x+) (.+)$" )
        if hash == nil then
            return nil, "the list of its large files is damaged"
        end

        local file = files[ id .. "/" .. file_path ]
        if file == nil or file.hash ~= hash then
            return nil, string_format( "'%s' was not received", file_path )
        end

        extra[ file_path ] = file.content
    end

    return extra
end

--- Applies the bundles sent by the server: removed and changed packages are unloaded, new ones are loaded.
---
---@param files table<string, dreamwork.transport.File>
---@async
local function apply_bundles( files )
    for name, package in raw_pairs( remote_packages ) do
        local file = files[ name ]
        if file == nil or file.hash ~= package_states[ package ].source.hash then
            remote_packages[ name ] = nil
            loader.remove( package )
        end
    end

    ---@type dreamwork.Package[]
    local added = {}
    local added_count = 0

    for name, file in raw_pairs( files ) do
        -- bundles are `{author}/{name}@{version}`, `{id}/{path}` are the large files of the packages
        if remote_packages[ name ] == nil and string_find( name, "^[^/]+/[^/]+$" ) ~= nil then
            local success, archive = pcall( parse_zip, file.content )
            if success then
                ---@cast archive dreamwork.std.Zip

                local manifest, message = parse_manifest( archive:readFile( "package.json" ) or "" )

                ---@type table<string, string> | nil
                local extra

                if manifest ~= nil then
                    extra, message = external_files( archive, name, files )
                end

                if manifest == nil or extra == nil then
                    dreamwork.Logger:error( "Package '%s' from the server is invalid: %s", name, message )
                else
                    ---@cast manifest dreamwork.PackageManifest

                    local package = register( manifest, {
                        kind = "archive",
                        archive = archive,
                        base = "",
                        preprocessed = archive.comment == BUNDLE_COMMENT,
                        hash = file.hash,
                        extra = extra
                    } )

                    remote_packages[ name ] = package

                    added_count = added_count + 1
                    added[ added_count ] = package
                end
            else
                dreamwork.Logger:error( "Package '%s' from the server is not an archive: %s", name, archive )
            end
        end
    end

    table_sort( added, by_id )

    ---@type dreamwork.Package[]
    local loads = {}
    local load_count = 0

    for index = 1, added_count, 1 do
        local package = added[ index ]
        if package_states[ package ].realms.client then
            load_count = load_count + 1
            loads[ load_count ] = package
        end
    end

    -- packages that failed before (e.g. a broken dependency) get another try with every file set
    ---@type dreamwork.Package[]
    local retries = {}
    local retry_count = 0

    for _, package in raw_pairs( remote_packages ) do
        local state = package_states[ package ]
        if state.status == "failed" and state.realms.client then
            retry_count = retry_count + 1
            retries[ retry_count ] = package
        end
    end

    table_sort( retries, by_id )

    for index = 1, retry_count, 1 do
        load_count = load_count + 1
        loads[ load_count ] = retries[ index ]
    end

    Synchronizing:call( load_count )

    for index = 1, load_count, 1 do
        load_package( loads[ index ] )
    end

    Synchronized:call()
end

--- The newest file set that arrived while the previous one was applied.
---
---@type table<string, dreamwork.transport.File> | nil
local pending_files

local is_synchronizing = false

--- Applies the file sets one after another, only the newest one waiting is applied.
---
---@param files table<string, dreamwork.transport.File>
local function synchronize( files )
    if is_synchronizing then
        pending_files = files
        return
    end

    is_synchronizing = true

    futures_run( apply_bundles, function()
        is_synchronizing = false

        local next_files = pending_files
        if next_files ~= nil then
            pending_files = nil
            synchronize( next_files )
        end
    end, files )
end

internal.synchronize = synchronize
