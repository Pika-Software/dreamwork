---@class dreamwork
local dreamwork = dreamwork

-- packages of the previous instance hold engine resources (timers, hooks, mounts), they have to go first
do

    local previous = dreamwork.loader
    if previous ~= nil and previous.shutdown ~= nil then
        previous.shutdown()
    end

end

local dreamwork_getUpTime = dreamwork.getUpTime

local engine_hook = dreamwork.engine.hook

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call
local exceptions_catch = dreamwork_exceptions.catch
local exceptions_report = dreamwork_exceptions.report

local dreamwork_sigil = dreamwork.sigil
local sigil_preprocess = dreamwork_sigil.preprocess

---@type dreamwork.transport | nil
local dreamwork_transport = dreamwork.transport

local dreamwork_sandbox = dreamwork.sandbox
local sandbox_bind = dreamwork_sandbox.bind
local sandbox_proxy = dreamwork_sandbox.proxy
local sandbox_release = dreamwork_sandbox.release

local vfs = dreamwork.vfs
local vfs_mount = vfs.mount
local vfs_search = vfs.search
local vfs_isFile = vfs.isFile
local vfs_getInfo = vfs.getInfo
local vfs_foreach = vfs.foreach
local vfs_isDirectory = vfs.isDirectory
local vfs_readFile = vfs.readFile
local vfs_writeFile = vfs.writeFile
local vfs_deleteFile = vfs.deleteFile
local vfs_deleteDirectory = vfs.deleteDirectory

---@class dreamwork.std
local std = dreamwork.std

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU
local LUA_REALM = std.LUA_REALM

local class = std.class

local debug = std.debug
local debug_getinfo = debug.getinfo

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_next = raw.next
local raw_index = raw.index
local raw_pairs = raw.pairs
local raw_tostring = raw.tostring

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match
local string_format = string.format
local string_hasPrefix = string.hasPrefix
local string_hasSuffix = string.hasSuffix
local string_isBytecode = string.isBytecode

local table = std.table
local table_sort = table.sort
local table_remove = table.remove

local path = std.path
local path_resolve = path.resolve
local path_normalize = path.normalize
local path_getDirectory = path.getDirectory
local path_getExtension = path.getExtension

local json = std.json
local json_deserialize = json.deserialize

local coroutine = std.coroutine
local coroutine_running = coroutine.running

local futures = std.futures
local futures_run = futures.run
local futures_cancel = futures.cancel
local futures_wakeup = futures.wakeup
local futures_pending = futures.pending

local console = std.console
local console_Logger = console.Logger

local color = std.color
local color_scheme = color.Scheme
local color_fromHex = color.fromHex

local Version = std.Version
local Version_validate = Version.validate
local Version_fromString = Version.fromString

local jit = std.jit
local jit_version_byte = jit.version_byte

local try = std.try
local pcall = std.pcall
local error = std.error
local xpcall = std.xpcall
local getfenv = std.getfenv
local tostring = std.tostring
local isTable = std.isTable
local isString = std.isString
local loadstring = std.loadstring
local loadbytecode = std.loadbytecode
local setmetatable = std.setmetatable

local Event = std.Event
local FileClass = std.File
local DirectoryClass = std.Directory
local Zip = std.Zip

--- [SHARED AND MENU]
---
--- The package manager.
---
--- A package is a directory with `package.json` at its root, see `dreamwork.PackageManifest`,
--- every sub-folder of `packages` in an addon is a package, so one addon (one git repository) holds many of them:
---
--- ```
--- /garrysmod/addons/my_addon/packages/my_pkg/package.json
--- /garrysmod/addons/my_addon/packages/my_pkg/lua/init.lua
--- /garrysmod/addons/my_addon/packages/my_pkg/config.json
--- /garrysmod/addons/my_addon/packages/my_lib.zip
--- ```
---
--- Archives (`.zip`, `data_static/packages/*.zip.dat` of Workshop addons and repository archives) have the package root
--- at the archive root, `/package.json`.
---
--- Every file of the package is kept in memory at `/packages/{author}/{name}@{version}` in the virtual file system,
--- `{author}` is the lowercase `author` with `_` in place of spaces and symbols, packages of different authors never collide.
--- Nothing is mounted into the game, the game file system mixes the files of all mounts, so the engine does not see
--- the materials, models or sounds of packages.
---
--- Every Lua file runs in its own module environment with `__file`, `__dir` and `__module`,
--- globals are written into the package environment, missing ones are read from `std`,
--- `std` tables are given as read-only views, so a package never changes `std`.
---
--- Named objects created by a package (`Timer`, `Network`, `Message`, `NetTable`, `http.Server`) get the `{id}::` prefix,
--- e.g. `pika_software/my_pkg@1.0.0::tick`,
--- handlers attached by a package are detached, and its timers, servers and timeouts are stopped when it unloads.
---
--- Packages that depend on an unloaded package are unloaded first.
---
--- On the server the Lua files are preprocessed by `sigil` for the client and sent with `dreamwork.transport`,
--- the client runs only what the server sent. The menu loads its local packages for itself.
---
---@class dreamwork.loader
local loader = dreamwork.loader or {}
dreamwork.loader = loader

--- The state and functions shared by the files of the package manager, not a public API.
---
---@class dreamwork.loader.Internal
local internal = {}
loader.Internal = internal


-- the events outlive a reload, so handlers of other modules stay attached

--- [SHARED AND MENU]
---
--- Called with the package before it starts to load (after its dependencies are resolved by the caller).
---
---@type dreamwork.std.Event
local PackageLoading = loader.PackageLoading or Event( "loader.PackageLoading" )
loader.PackageLoading = PackageLoading

--- [SHARED AND MENU]
---
--- Called with the package after it was loaded.
---
---@type dreamwork.std.Event
local PackageLoaded = loader.PackageLoaded or Event( "loader.PackageLoaded" )
loader.PackageLoaded = PackageLoaded

--- [SHARED AND MENU]
---
--- Called with the package and the `Error` after it failed to load.
---
---@type dreamwork.std.Event
local PackageFailed = loader.PackageFailed or Event( "loader.PackageFailed" )
loader.PackageFailed = PackageFailed

--- [SHARED AND MENU]
---
--- Called with the package before it unloads, while its handlers are still attached.
---
---@type dreamwork.std.Event
local PackageUnloading = loader.PackageUnloading or Event( "loader.PackageUnloading" )
loader.PackageUnloading = PackageUnloading

--- [SHARED AND MENU]
---
--- Called with the package after it was unloaded.
---
---@type dreamwork.std.Event
local PackageUnloaded = loader.PackageUnloaded or Event( "loader.PackageUnloaded" )
loader.PackageUnloaded = PackageUnloaded

if LUA_CLIENT then

    --- [CLIENT]
    ---
    --- Called with the number of packages to load when the packages from the server start to apply.
    ---
    ---@type dreamwork.std.Event
    local Synchronizing = loader.Synchronizing or Event( "loader.Synchronizing" )
    loader.Synchronizing = Synchronizing

    --- [CLIENT]
    ---
    --- Called when the packages from the server are applied.
    ---
    ---@type dreamwork.std.Event
    local Synchronized = loader.Synchronized or Event( "loader.Synchronized" )
    loader.Synchronized = Synchronized

end

--- The realms a package runs in when `package.json` has no `realms`.
---
---@type table<dreamwork.PackageRealm, boolean>
local DEFAULT_REALMS = { server = true, client = true }

-- `/packages` is an empty read-only mount, so package files always go to the virtual layer,
-- even where the root search path is writable (HolyLib)
do

    local info = vfs_getInfo( "/packages" )
    if info == nil or not info.is_mount_root then
        vfs_mount( "/packages", "dreamwork::packages", nil, false, false )
    end

end

--- The state of packages.
---
---@type table<dreamwork.Package, dreamwork.Package.State>
local package_states = {}
gc_setTableRules( package_states, true, false )

--- The state of modules.
---
---@type table<dreamwork.Module, dreamwork.Module.State>
local module_states = {}
gc_setTableRules( module_states, true, false )

--- The modules by their environments, used to find the package of a running function.
---
---@type table<table, dreamwork.Module>
local environment_modules = {}
gc_setTableRules( environment_modules, true, false )

--- The registered packages by their ids, `{author}/{name}@{version}`.
---
---@type table<string, dreamwork.Package>
local packages = {}

--- The registered packages by their names, the newest version first.
---
---@type table<string, dreamwork.Package[]>
local package_lists = {}


internal.package_states = package_states
internal.module_states = module_states
internal.environment_modules = environment_modules
internal.packages = packages
internal.package_lists = package_lists

---@param tbl table
---@return string[] keys
---@return integer key_count
local function sorted_keys( tbl )
    local keys, key_count = {}, 0

    for key in raw_pairs( tbl ) do
        key_count = key_count + 1
        keys[ key_count ] = key
    end

    table_sort( keys )
    return keys, key_count
end

---@param vfs_path string
---@param directory_path string
---@return boolean
local function is_inside( vfs_path, directory_path )
    return string_sub( vfs_path, 1, #directory_path + 1 ) == (directory_path .. "/")
end

---@param a dreamwork.Package
---@param b dreamwork.Package
---@return boolean
local function newer_first( a, b )
    return package_states[ a ].version > package_states[ b ].version
end

---@param a dreamwork.Package
---@param b dreamwork.Package
---@return boolean
local function by_id( a, b )
    return package_states[ a ].id < package_states[ b ].id
end

---@param realm string
---@return table
local function create_sigil_env( realm )
    local is_server = realm == "server"
    local is_client = realm == "client"
    local is_menu = realm == "menu"

    return setmetatable( {
        LUA_REALM = realm,
        LUA_SERVER = is_server,
        LUA_CLIENT = is_client,
        LUA_MENU = is_menu,
        LUA_CLIENT_SERVER = is_client or is_server,
        LUA_CLIENT_MENU = is_client or is_menu,
        LUA_MENU_SERVER = is_menu or is_server,
        SERVER = is_server,
        CLIENT = is_client,
        MENU = is_menu
    }, { __index = std } )
end

--- The `#if` environment of the current realm.
local sigil_env = create_sigil_env( LUA_REALM )

--- [SHARED AND MENU]
---
--- A loaded Lua file of a package.
---
---@class dreamwork.Module : dreamwork.std.Object
---@field __class dreamwork.ModuleClass
---@field path string The absolute virtual path of the file. **Read-only.**
---@field file dreamwork.std.File The file. **Read-only.**
---@field public package dreamwork.Package The package of the module. **Read-only.**
---@field environment table The module environment. **Read-only.**
---@field result any The value returned by the file, `true` if it returned nothing. **Read-only.**
local Module = class.base( "dreamwork.Module", true )

--- [SHARED AND MENU]
---
--- The class of `Module`, modules are created by `require` and `dofile`.
---
---@class dreamwork.ModuleClass : dreamwork.Module, dreamwork.std.Class
---@field __base dreamwork.Module
---@overload fun( package: dreamwork.Package, vfs_path: string ): dreamwork.Module
local ModuleClass = class.create( Module )
loader.Module = ModuleClass

---@param package dreamwork.Package
---@param vfs_path string
---@protected
function Module:__init( package, vfs_path )
    local package_state = package_states[ package ]

    local file = FileClass( vfs_path )

    local env = setmetatable( {
        __file = file,
        __dir = DirectoryClass( package_state.root ),
        __module = self
    }, {
        __index = package_state.environment,
        __newindex = package_state.environment
    } )

    module_states[ self ] = {
        package = package,
        path = vfs_path,
        file = file,
        environment = env,
        result = nil,
        loading = false
    }

    environment_modules[ env ] = self
    sandbox_bind( env, package_state )
end

---@param key string
---@return any
---@protected
function Module:__index( key )
    local state = module_states[ self ]
    if state ~= nil and (key == "path" or key == "file" or key == "package" or key == "environment" or key == "result") then
        return state[ key ]
    end

    return raw_index( Module, key )
end

---@param key string
---@protected
function Module:__newindex( key )
    error( string_format( "attempt to modify read-only Module property '%s'", raw_tostring( key ) ), 2 )
end

---@return string
---@protected
function Module:__represent()
    local state = module_states[ self ]
    if state == nil then
        return string_format( "Module: %p", self )
    end

    return string_format( "Module: %p [%s]", self, state.path )
end

--- [SHARED AND MENU]
---
--- A package, created by the package manager for every found `package.json`.
---
---@class dreamwork.Package : dreamwork.std.Object
---@field __class dreamwork.PackageClass
---@field name string The name of the package. **Read-only.**
---@field version dreamwork.std.Version The version of the package. **Read-only.**
---@field id string The unique id of the package, `{author}/{name}@{version}`, `{author}` is the lowercase `author` with `_` in place of spaces and symbols, also the prefix of its named objects. **Read-only.**
---@field author string The author of the package. **Read-only.**
---@field license string The license of the package. **Read-only.**
---@field description string The description of the package. **Read-only.**
---@field repository string | nil The repository of the package, e.g. `github.com/user/my_lib`. **Read-only.**
---@field status dreamwork.PackageStatus The status of the package. **Read-only.**
---@field root string The absolute virtual path of the package directory, `/packages/{id}`. **Read-only.**
---@field environment table | nil The package environment, `nil` while the package is not running. **Read-only.**
---@field exports any The value returned by the entrypoint, `nil` while the package is not running. **Read-only.**
---@field error dreamwork.std.Error | nil The error of the last failed load. **Read-only.**
---@field logger dreamwork.std.console.Logger The logger of the package. **Read-only.**
---@field origin "local" | "repository" | "server" Where the package came from: an addon folder, a repository archive or the server (client). **Read-only.**
local Package = class.base( "dreamwork.Package", true )

--- [SHARED AND MENU]
---
--- The class of `Package`.
---
---@class dreamwork.PackageClass : dreamwork.Package, dreamwork.std.Class
---@field __base dreamwork.Package
---@overload fun( manifest: dreamwork.PackageManifest, source: dreamwork.loader.Source ): dreamwork.Package
local PackageClass = class.create( Package )
loader.Package = PackageClass

--- Returns the folder name of the author, lowercase with `_` in place of anything but letters, digits, `-` and `.`,
--- the `<email>` and `(url)` parts of `"Name <email> (url)"` are dropped.
---
---@param author string
---@return string folder_name
local function author_folder( author )
    author = string_gsub( string_gsub( author, "%b<>", "" ), "%b()", "" )
    author = string_gsub( string_gsub( string_lower( author ), "[^%w%-%.]+", "_" ), "^_*(.-)_*$", "%1" )

    -- empty, `.` and `..` are not folders
    if author == "" or string_find( author, "^%.+$" ) ~= nil then
        return "unknown"
    end

    return author
end

--- Returns the id of the package, `{author}/{name}@{version}`.
---
---@param manifest dreamwork.PackageManifest
---@return string id
local function package_id( manifest )
    return author_folder( manifest.author ) .. "/" .. manifest.name .. "@" .. manifest.version
end

---@param manifest dreamwork.PackageManifest
---@param source dreamwork.loader.Source
---@protected
function Package:__init( manifest, source )
    local id = package_id( manifest )
    local root = "/packages/" .. id

    local entrypoint = manifest.main[ LUA_REALM ]

    local handlers = {}
    gc_setTableRules( handlers, true, false )

    local objects = {}
    gc_setTableRules( objects, true, false )

    package_states[ self ] = {
        name = manifest.name,
        version = Version_fromString( manifest.version ),
        id = id,
        manifest = manifest,
        source = source,
        realms = manifest.realms,
        root = root,
        main = entrypoint ~= nil and (root .. "/" .. entrypoint) or nil,
        status = "installed",
        logger = console_Logger( {
            title = id,
            color = manifest.color or color_scheme.white_smoke,
            interpolation = false
        } ),
        modules = {},
        dependencies = {},
        dependents = {},
        handlers = handlers,
        objects = objects,
        waiting = {},
        published = false
    }
end

---@type table<string, boolean>
local package_fields = {
    name = true,
    version = true,
    id = true,
    status = true,
    root = true,
    environment = true,
    exports = true,
    error = true,
    logger = true
}

---@type table<string, boolean>
local manifest_fields = {
    author = true,
    license = true,
    description = true,
    repository = true
}

---@param key string
---@return any
---@protected
function Package:__index( key )
    local state = package_states[ self ]
    if state ~= nil then
        if package_fields[ key ] then
            return state[ key ]
        elseif manifest_fields[ key ] then
            return state.manifest[ key ]
        elseif key == "origin" then
            local source = state.source
            if source.repository ~= nil then
                return "repository"
            elseif source.path ~= nil then
                return "local"
            end

            return "server"
        end
    end

    return raw_index( Package, key )
end

---@param key string
---@protected
function Package:__newindex( key )
    error( string_format( "attempt to modify read-only Package property '%s'", raw_tostring( key ) ), 2 )
end

---@return string
---@protected
function Package:__represent()
    local state = package_states[ self ]
    if state == nil then
        return string_format( "Package: %p", self )
    end

    return string_format( "Package: %p [%s][%s]", self, state.id, state.status )
end

---@return boolean
---@protected
function Package:__isvalid()
    local state = package_states[ self ]
    return state ~= nil and state.status == "loaded"
end

---@type fun( package: dreamwork.Package ): boolean
local unload_package

--- `true` once this instance of the package manager is shut down (a reloaded one takes over, or the game shuts down).
local is_shutdown = false

---@protected
function Package:__gc()
    -- after the shutdown the game may be closing the Lua state, any call into the engine (even a log) crashes it,
    -- the engine frees the resources of the packages by itself
    if is_shutdown then
        return
    end

    local state = package_states[ self ]
    if state ~= nil and state.status == "loaded" then
        exceptions_call( unload_package, self )
    end
end

--- Returns the package of the module that the function at the stack level belongs to,
--- C functions and functions that do not belong to packages are skipped.
---
---@param stack_level integer The level to start from, `1` is the function calling `find_module`.
---@return dreamwork.Module | nil
local function find_module( stack_level )
    stack_level = stack_level + 1

    ::module_lookup::

    local info = debug_getinfo( stack_level, "f" )
    if info == nil then
        return nil
    end

    local module = environment_modules[ getfenv( info.func ) ]
    if module ~= nil then
        return module
    end

    stack_level = stack_level + 1
    goto module_lookup
end

--- [SHARED AND MENU]
---
--- Returns the module of the calling function.
---
---@param stack_level integer? The stack level to start from, `1` (default) is the function calling `getModule`.
---@return dreamwork.Module | nil module The module, `nil` if the code does not belong to a package.
---@nodiscard
function loader.getModule( stack_level )
    return find_module( (stack_level or 1) + 1 )
end

--- [SHARED AND MENU]
---
--- Returns the package of the calling function.
---
---@param stack_level integer? The stack level to start from, `1` (default) is the function calling `getPackage`.
---@return dreamwork.Package | nil package The package, `nil` if the code does not belong to a package.
---@nodiscard
function loader.getPackage( stack_level )
    local module = find_module( (stack_level or 1) + 1 )
    if module == nil then
        return nil
    end

    return module_states[ module ].package
end

--- [SHARED AND MENU]
---
--- Returns the working directory of the calling function:
--- the package directory for packages, the directory of the file otherwise.
---
---@param stack_level integer? The stack level to start from, `1` (default) is the function calling `getDirectory`.
---@return string abs_path The absolute virtual path of the directory.
---@nodiscard
function loader.getDirectory( stack_level )
    stack_level = (stack_level or 1) + 1

    local module = find_module( stack_level )
    if module ~= nil then
        return package_states[ module_states[ module ].package ].root
    end

    return path_getDirectory( path.get( stack_level ), false ) or "/"
end

--- Lists the files of the source, paths are relative to the package root, hidden files are skipped.
---
---@param source dreamwork.loader.Source
---@return string[] files
---@return integer file_count
local function source_files( source )
    ---@type string[]
    local files = {}
    local file_count = 0

    if source.kind == "folder" then
        local base = source.path
        ---@cast base string

        local offset = #base + 2

        for vfs_path, is_directory in vfs_foreach( base ) do
            if not is_directory then
                local file_path = string_sub( vfs_path, offset )
                if string_find( file_path, "^%." ) == nil and string_find( file_path, "/%." ) == nil then
                    file_count = file_count + 1
                    files[ file_count ] = file_path
                end
            end
        end
    else
        local archive, base = source.archive, source.base
        ---@cast archive dreamwork.std.Zip
        ---@cast base string

        local offset = #base + 1
        local archive_files = archive.files

        for index = 1, archive.file_count, 1 do
            local archive_path = archive_files[ index ].path
            if string_byte( archive_path, -1 ) ~= 0x2F --[[ / ]] and string_hasPrefix( archive_path, base ) then
                local file_path = string_sub( archive_path, offset )
                if string_find( file_path, "^%." ) == nil and string_find( file_path, "/%." ) == nil then
                    file_count = file_count + 1
                    files[ file_count ] = file_path
                end
            end
        end

        local extra = source.extra
        if extra ~= nil then
            for file_path in raw_pairs( extra ) do
                file_count = file_count + 1
                files[ file_count ] = file_path
            end
        end
    end

    table_sort( files )
    return files, file_count
end

--- Finds the package root in the archive, `package.json` must be at the archive root.
---
--- Repository archives (GitHub) wrap the repository into one folder, `{owner}-{repo}-{commit}/`,
--- the root of that folder is the package root then.
---
---@param archive dreamwork.std.Zip
---@param is_wrapped boolean? `true` for repository archives, `package.json` can be in the single top-level folder.
---@return string | nil base The directory with the trailing `/`, empty for the archive root, `nil` without `package.json`.
local function archive_base( archive, is_wrapped )
    ---@type string | nil
    local wrapped_base

    local files = archive.files

    for index = 1, archive.file_count, 1 do
        local file_path = files[ index ].path
        if file_path == "package.json" then
            return ""
        end

        if is_wrapped and wrapped_base == nil then
            wrapped_base = string_match( file_path, "^([^/]+/)package%.json$" )
        end
    end

    return wrapped_base
end

--- Reads the file of the source.
---
---@param source dreamwork.loader.Source
---@param file_path string The path relative to the package root.
---@return string content
---@async
local function source_read( source, file_path )
    if source.kind == "folder" then
        return vfs_readFile( source.path .. "/" .. file_path )
    end

    local extra = source.extra
    if extra ~= nil then
        local extra_content = extra[ file_path ]
        if extra_content ~= nil then
            return extra_content
        end
    end

    local archive = source.archive
    ---@cast archive dreamwork.std.Zip

    local content = archive:readFile( source.base .. file_path )
    if content == nil then
        error( string_format( "file '%s' is missing in the archive", file_path ), 2 )
    end

    ---@cast content string
    return content
end

---@param file_path string
---@return boolean
local function is_lua_file( file_path )
    return string_lower( path_getExtension( file_path, false ) ) == "lua"
end

--- Returns the reader of `#include` for the files of the package.
---
---@param state dreamwork.Package.State
---@param read_fn fun( vfs_path: string ): string | nil
---@return fun( file_path: string ): string | nil
local function include_reader( state, read_fn )
    local root = state.root

    return function( file_path )
        if string_byte( file_path, 1, 1 ) ~= 0x2F --[[ / ]] then
            file_path = root .. "/lua/" .. file_path
        end

        file_path = path_normalize( file_path, false )

        if is_inside( file_path, root ) then
            return read_fn( file_path )
        end

        return nil
    end
end

--- Places the files of the package into the virtual file system.
---
---@param state dreamwork.Package.State
---@async
local function materialize( state )
    local source, root = state.source, state.root
    local files, file_count = source_files( source )

    for index = 1, file_count, 1 do
        local file_path = files[ index ]
        vfs_writeFile( root .. "/" .. file_path, source_read( source, file_path ) )
    end
end

--- Deletes the virtual files and directories left at the path,
--- an intermediate directory goes away by itself once nothing is left in it.
---
---@param directory_path string
local function clear_virtual( directory_path )
    local info = vfs_getInfo( directory_path )
    if info == nil then
        return
    end

    if info.storage == "memory" then
        exceptions_call( vfs_deleteDirectory, directory_path, true )
        return
    end

    local file_names, file_count, directory_names, directory_count = vfs_search( directory_path )

    for index = 1, file_count, 1 do
        exceptions_call( vfs_deleteFile, directory_path .. "/" .. file_names[ index ] )
    end

    for index = 1, directory_count, 1 do
        clear_virtual( directory_path .. "/" .. directory_names[ index ] )
    end
end

--- Removes the files of the package from the virtual file system.
---
---@param state dreamwork.Package.State
local function dematerialize( state )
    clear_virtual( state.root )

    -- the author folder goes with its last package.
    -- it is missing when the package never materialized, and an empty one is pruned with the package directory
    local author_path = string_match( state.root, "^(.+)/[^/]+$" )
    if author_path == nil or vfs_getInfo( author_path ) == nil then
        return
    end

    local _, file_count, _, directory_count = vfs_search( author_path )
    if file_count == 0 and directory_count == 0 then
        exceptions_call( vfs_deleteDirectory, author_path, true )
    end
end

--- Compiles the Lua file of the package in a new module.
---
---@param package dreamwork.Package
---@param state dreamwork.Package.State
---@param vfs_path string
---@return dreamwork.Module module
---@return function fn
---@async
local function compile_module( package, state, vfs_path )
    local content = vfs_readFile( vfs_path )

    local module = ModuleClass( package, vfs_path )
    local env = module_states[ module ].environment

    if string_isBytecode( content, jit_version_byte ) then
        return module, loadbytecode( content, env )
    end

    if not state.source.preprocessed then
        content = sigil_preprocess( content, {
            name = vfs_path,
            path = vfs_path,
            env = sigil_env,
            logger = state.logger,
            read = include_reader( state, function( file_path )
                if vfs_isFile( file_path ) then
                    return vfs_readFile( file_path )
                end

                return nil
            end )
        } )
    end

    return module, loadstring( content, vfs_path, env )
end

--- Runs the Lua file of the package once, the result is cached in the package.
---
---@param package dreamwork.Package
---@param state dreamwork.Package.State
---@param vfs_path string
---@return any result
---@async
local function require_path( package, state, vfs_path, ... )
    local modules = state.modules

    local module = modules[ vfs_path ]
    if module ~= nil then
        local module_state = module_states[ module ]
        if module_state.loading then
            error( string_format( "loop while loading module '%s'", vfs_path ), 3 )
        end

        return module_state.result
    end

    local fn
    module, fn = compile_module( package, state, vfs_path )

    local module_state = module_states[ module ]
    module_state.loading = true
    modules[ vfs_path ] = module

    local success, result = xpcall( fn, exceptions_catch, ... )
    module_state.loading = false

    if not success then
        modules[ vfs_path ] = nil
        error( result, 0 )
    end

    if result == nil then
        result = true
    end

    module_state.result = result
    return result
end

--- Resolves the name of a module of the package to the path of its file.
---
--- Dotted names (`utils.math`) are looked up in `lua/` of the package,
--- paths (`./utils.lua`, `../shared/init.lua`) are relative to the directory of the calling file.
---
---@param state dreamwork.Package.State
---@param base_directory string
---@param name string
---@param dotted boolean
---@return string | nil vfs_path
local function resolve_module( state, base_directory, name, dotted )
    local root = state.root

    ---@type string
    local candidate

    local uint8 = string_byte( name, 1, 1 )
    if uint8 == 0x2F --[[ / ]] then
        candidate = path_normalize( name, false )
    elseif not dotted or uint8 == 0x2E --[[ . ]] or string_find( name, "/", 1, true ) ~= nil or string_hasSuffix( name, ".lua" ) then
        candidate = path_normalize( base_directory .. "/" .. name, false )
    else
        candidate = root .. "/lua/" .. string_gsub( name, "%.", "/" )
    end

    if not is_inside( candidate, root ) then
        return nil
    end

    if string_hasSuffix( candidate, ".lua" ) then
        if vfs_isFile( candidate ) then
            return candidate
        end
    elseif vfs_isFile( candidate .. ".lua" ) then
        return candidate .. ".lua"
    elseif vfs_isFile( candidate .. "/init.lua" ) then
        return candidate .. "/init.lua"
    end

    return nil
end

--- Remembers that the package depends on the dependency.
---
---@param package dreamwork.Package
---@param dependency dreamwork.Package
local function link( package, dependency )
    package_states[ package ].dependencies[ dependency ] = true
    package_states[ dependency ].dependents[ package ] = true
end

--- Checks if the package depends on the dependency, directly or through other packages.
---
---@param package dreamwork.Package
---@param dependency dreamwork.Package
---@param visited table<dreamwork.Package, boolean>?
---@return boolean
local function depends_on( package, dependency, visited )
    if package == dependency then
        return true
    end

    if visited == nil then
        visited = {}
    elseif visited[ package ] then
        return false
    end

    visited[ package ] = true

    for child in raw_pairs( package_states[ package ].dependencies ) do
        if depends_on( child, dependency, visited ) then
            return true
        end
    end

    return false
end

--- Stops everything the package created and removes its files.
---
---@param package dreamwork.Package
---@param state dreamwork.Package.State
local function cleanup( package, state )
    sandbox_release( state )

    for dependency in raw_pairs( state.dependencies ) do
        package_states[ dependency ].dependents[ package ] = nil
    end

    state.dependencies = {}
    state.modules = {}
    state.environment = nil
    state.exports = nil

    dematerialize( state )
end

--- The read-only view of `std`.
---
---@type dreamwork.std
local std_proxy = sandbox_proxy( std )

--- The metatable of package environments, missing globals come from `std`.
---
---@type metatable
local package_metatable = {
    __index = function( _, key )
        return sandbox_proxy( std[ key ] )
    end
}

--- Returns the package environment, the globals of the package.
---
---@param package dreamwork.Package
---@param state dreamwork.Package.State
---@return table
local function create_environment( package, state )
    return setmetatable( {
        __package = package,
        Logger = state.logger,
        std = std_proxy
    }, package_metatable )
end

---@type fun( package: dreamwork.Package ): boolean
local load_package

---@param package dreamwork.Package
---@param state dreamwork.Package.State
---@async
local function load_steps( package, state )
    local dependencies = state.manifest.dependencies
    local names, name_count = sorted_keys( dependencies )

    for index = 1, name_count, 1 do
        local name = names[ index ]
        local selector = dependencies[ name ]

        local dependency = internal.resolve_package( name, selector ~= "" and selector or nil )
        if dependency == nil then
            error( string_format( "dependency '%s@%s' is not installed", name, selector ), 2 )
        end

        ---@cast dependency dreamwork.Package

        link( package, dependency )

        if depends_on( dependency, package ) then
            error( string_format( "circular dependency between '%s' and '%s'", state.id, package_states[ dependency ].id ), 2 )
        end

        if not load_package( dependency ) then
            error( string_format( "dependency '%s' failed to load", package_states[ dependency ].id ), 2 )
        end
    end

    materialize( state )

    state.environment = create_environment( package, state )

    local main = state.main
    if main == nil then
        error( string_format( "no entrypoint for the realm '%s'", LUA_REALM ), 2 )
    end

    if not vfs_isFile( main ) then
        error( string_format( "entrypoint '%s' does not exist", main ), 2 )
    end

    state.exports = require_path( package, state, main )
end

--- Returns where the files of the package come from, for the log.
---
---@param source dreamwork.loader.Source
---@return string
local function describe_source( source )
    if source.hash ~= nil then
        return "the server"
    end

    local repository = source.repository
    if repository ~= nil then
        return repository
    end

    return string_format( "'%s'", source.path or "memory" )
end

--- [SHARED AND MENU]
---
--- Loads the package with its dependencies, does nothing if it is already loaded.
---
--- If the package is being loaded by another coroutine, waits for it.
---
---@param package dreamwork.Package The package to load.
---@return boolean success `true` if the package is loaded, see `Package.error` otherwise.
---@async
function load_package( package )
    if is_shutdown then
        return false
    end

    local state = package_states[ package ]

    local status = state.status
    if status == "loaded" then
        return true
    end

    if status == "loading" then
        local co = coroutine_running()
        if co == nil or co == state.thread then
            error( string_format( "package '%s' is already loading", state.id ), 2 )
        end

        local waiting = state.waiting
        waiting[ #waiting + 1 ] = co

        futures_pending()
        return state.status == "loaded"
    end

    if not state.realms[ LUA_REALM ] then
        error( string_format( "package '%s' does not run on the %s", state.id, LUA_REALM ), 2 )
    end

    PackageLoading:call( package )

    local start_time = dreamwork_getUpTime()

    state.status = "loading"
    state.thread = coroutine_running()
    state.error = nil

    local success, error_object = try( load_steps, package, state )
    state.thread = nil

    if success then
        state.status = "loaded"
        dreamwork.Logger:info( "Package '%s' loaded from %s in %.2f ms.", state.id, describe_source( state.source ), (dreamwork_getUpTime() - start_time) * 1000 )
        PackageLoaded:call( package )

        if LUA_SERVER and state.realms.client then
            exceptions_call( internal.publish, state )
        end
    else
        cleanup( package, state )

        state.status = "failed"
        state.error = error_object

        -- cancelled by the shutdown, the reloaded package manager loads it again
        if not is_shutdown then
            dreamwork.Logger:error( "Package '%s' from %s failed to load in %.2f ms:", state.id, describe_source( state.source ), (dreamwork_getUpTime() - start_time) * 1000 )
            exceptions_report( error_object )
            PackageFailed:call( package, error_object )
        end
    end

    local waiting = state.waiting
    state.waiting = {}

    for index = 1, #waiting, 1 do
        futures_wakeup( waiting[ index ] )
    end

    return success
end

loader.load = load_package

--- [SHARED AND MENU]
---
--- Unloads the package, the packages that depend on it are unloaded first.
---
--- Handlers attached by the package are detached, its timers, servers and timeouts are stopped and its files are removed.
---
---@param package dreamwork.Package The package to unload.
---@return boolean success `true` if the package was loaded.
function unload_package( package )
    local state = package_states[ package ]
    if state.status ~= "loaded" then
        return false
    end

    local dependents, dependent_count = {}, 0

    for dependent in raw_pairs( state.dependents ) do
        dependent_count = dependent_count + 1
        dependents[ dependent_count ] = dependent
    end

    for index = 1, dependent_count, 1 do
        unload_package( dependents[ index ] )
    end

    PackageUnloading:call( package )

    internal.unpublish( state )

    cleanup( package, state )
    state.status = "installed"

    if dependent_count == 0 then
        dreamwork.Logger:info( "Package '%s' unloaded.", state.id )
    else
        dreamwork.Logger:info( "Package '%s' unloaded with %d dependent package(s).", state.id, dependent_count )
    end

    PackageUnloaded:call( package )

    return true
end

loader.unload = unload_package

--- [SHARED AND MENU]
---
--- Loads the package with its dependencies, see `loader.load`.
---
---@return boolean success `true` if the package is loaded.
---@async
function Package:load()
    return load_package( self )
end

--- [SHARED AND MENU]
---
--- Unloads the package and the packages that depend on it, see `loader.unload`.
---
---@return boolean success `true` if the package was loaded.
function Package:unload()
    return unload_package( self )
end

--- [SHARED AND MENU]
---
--- Unloads and loads the package again, the packages that depended on it are loaded again too.
---
---@return boolean success `true` if the package is loaded.
---@async
function Package:reload()
    local state = package_states[ self ]

    ---@type dreamwork.Package[]
    local dependents = {}

    ---@param package dreamwork.Package
    local function collect( package )
        for dependent in raw_pairs( package_states[ package ].dependents ) do
            dependents[ #dependents + 1 ] = dependent
            collect( dependent )
        end
    end

    collect( self )
    unload_package( self )

    local success = load_package( self )

    if success then
        for index = 1, #dependents, 1 do
            local dependent = dependents[ index ]
            if package_states[ dependent ].status == "installed" then
                load_package( dependent )
            end
        end
    end

    return success and state.status == "loaded"
end

--- [SHARED AND MENU]
---
--- Returns the packages this package depends on.
---
---@return dreamwork.Package[] dependencies The dependencies.
---@return integer dependency_count The number of dependencies.
---@nodiscard
function Package:getDependencies()
    local list, count = {}, 0

    for dependency in raw_pairs( package_states[ self ].dependencies ) do
        count = count + 1
        list[ count ] = dependency
    end

    table_sort( list, by_id )
    return list, count
end

--- [SHARED AND MENU]
---
--- Returns the packages that depend on this package.
---
---@return dreamwork.Package[] dependents The dependents.
---@return integer dependent_count The number of dependents.
---@nodiscard
function Package:getDependents()
    local list, count = {}, 0

    for dependent in raw_pairs( package_states[ self ].dependents ) do
        count = count + 1
        list[ count ] = dependent
    end

    table_sort( list, by_id )
    return list, count
end

--- [SHARED AND MENU]
---
--- Checks if the package runs in the realm.
---
---@param realm dreamwork.PackageRealm The realm.
---@return boolean runs `true` if the package runs in the realm.
---@nodiscard
function Package:hasRealm( realm )
    return package_states[ self ].realms[ realm ] == true
end

--- Normalizes the entrypoint path, relative to the package root.
---
---@param file_path string
---@return string | nil entrypoint `nil` if it is not a `.lua` file.
local function normalize_entrypoint( file_path )
    file_path = path_normalize( "/" .. file_path, false )
    if not string_hasSuffix( file_path, ".lua" ) then
        return nil
    end

    return string_sub( file_path, 2 )
end

--- Parses and validates `package.json`.
---
---@param json_str string
---@return dreamwork.PackageManifest | nil manifest
---@return string | nil message
local function parse_manifest( json_str )
    local success, data = pcall( json_deserialize, json_str )
    if not success then
        return nil, "invalid JSON: " .. tostring( data )
    end

    ---@cast data table

    local name = data.name
    if not isString( name ) or string_match( name, "^[%w_%-%.]+$" ) == nil or string_find( name, "^%.+$" ) ~= nil then
        return nil, "'name' must be a string of letters, digits, '_', '-' and '.'"
    end

    local version = data.version
    if not isString( version ) or not Version_validate( version ) then
        return nil, "'version' must be a semantic version"
    end

    -- `v1.0.0` and `1.0.0` must give the same prefix
    version = tostring( Version_fromString( version ) )

    ---@type table<dreamwork.PackageRealm, string>
    local main = {}

    local main_value = data.main
    if isTable( main_value ) then
        for realm, file_path in raw_pairs( main_value ) do
            if realm ~= "server" and realm ~= "client" and realm ~= "menu" then
                return nil, string_format( "unknown realm '%s' in 'main', expected 'server', 'client' or 'menu'", tostring( realm ) )
            end

            local entrypoint = isString( file_path ) and normalize_entrypoint( file_path ) or nil
            if entrypoint == nil then
                return nil, string_format( "'main.%s' must be a path to a .lua file", realm )
            end

            main[ realm ] = entrypoint
        end
    else
        local entrypoint = normalize_entrypoint( isString( main_value ) and main_value or "lua/init.lua" )
        if entrypoint == nil then
            return nil, "'main' must be a path to a .lua file"
        end

        main.server, main.client, main.menu = entrypoint, entrypoint, entrypoint
    end

    ---@type table<dreamwork.PackageRealm, boolean>
    local realms = DEFAULT_REALMS

    local realm_list = data.realms
    if isTable( realm_list ) then
        realms = {}

        for index = 1, #realm_list, 1 do
            local realm = realm_list[ index ]
            if realm == "server" or realm == "client" or realm == "menu" then
                realms[ realm ] = true
            else
                return nil, string_format( "unknown realm '%s', expected 'server', 'client' or 'menu'", tostring( realm ) )
            end
        end
    end

    for realm in raw_pairs( realms ) do
        if main[ realm ] == nil then
            return nil, string_format( "'main' has no entrypoint for the realm '%s'", realm )
        end
    end

    ---@type table<string, string>
    local dependencies = {}

    local dependency_map = data.dependencies
    if isTable( dependency_map ) then
        for dependency_name, spec in raw_pairs( dependency_map ) do
            if not isString( dependency_name ) or not isString( spec ) then
                return nil, "'dependencies' must map repositories ('user/repo') to version ranges"
            end

            dependencies[ dependency_name ] = spec
        end
    end

    ---@type string[] | nil
    local client_files

    local client_file_list = data.client_files
    if client_file_list ~= nil then
        if not isTable( client_file_list ) then
            return nil, "'client_files' must be a list of wildcards"
        end

        client_files = {}

        for index = 1, #client_file_list, 1 do
            local wildcard_str = client_file_list[ index ]
            if not isString( wildcard_str ) then
                return nil, "'client_files' must be a list of wildcards"
            end

            -- wildcards are relative to the package root, `./lua/*` and `/lua/*` are `lua/*`
            client_files[ index ] = string_gsub( wildcard_str, "^%.?/+", "", 1 )
        end
    end

    ---@type dreamwork.std.Color | nil
    local logger_color

    local color_value = data.color
    if color_value ~= nil then
        local digits = isString( color_value ) and string_match( color_value, "^#?(%x+)$" ) or nil
        if digits == nil or (#digits ~= 3 and #digits ~= 6) then
            return nil, "'color' must be a hex color code, '#RGB' or '#RRGGBB'"
        end

        -- `#RGB` is `#RRGGBB` with every digit doubled
        if #digits == 3 then
            digits = string_gsub( digits, "%x", "%0%0" )
        end

        logger_color = color_fromHex( digits )
    end

    local author, license, description, repository = data.author, data.license, data.description, data.repository

    ---@type dreamwork.PackageManifest
    return {
        name = name,
        version = version,
        author = isString( author ) and author or "unknown",
        license = isString( license ) and license or "unknown",
        description = isString( description ) and description or "",
        main = main,
        realms = realms,
        dependencies = dependencies,
        repository = isString( repository ) and repository or nil,
        client_files = client_files,
        color = logger_color
    }
end

--- Registers the package, a package with the same id keeps the first one.
---
---@param manifest dreamwork.PackageManifest
---@param source dreamwork.loader.Source
---@return dreamwork.Package package
---@return boolean is_new `false` if a package with the same id was already registered.
local function register( manifest, source )
    local id = package_id( manifest )

    local existing = packages[ id ]
    if existing ~= nil then
        return existing, false
    end

    local package = PackageClass( manifest, source )
    packages[ id ] = package

    local name = manifest.name

    local list = package_lists[ name ]
    if list == nil then
        list = {}
        package_lists[ name ] = list
    end

    list[ #list + 1 ] = package
    table_sort( list, newer_first )

    return package, true
end

--- [SHARED AND MENU]
---
--- Unloads the package and forgets it, its source has to be found again to load it.
---
---@param package dreamwork.Package The package to remove.
function loader.remove( package )
    local state = package_states[ package ]

    if state.status == "loaded" then
        unload_package( package )
    end

    if packages[ state.id ] == package then
        packages[ state.id ] = nil
    end

    local list = package_lists[ state.name ]
    if list ~= nil then
        for index = #list, 1, -1 do
            if list[ index ] == package then
                table_remove( list, index )
            end
        end

        if list[ 1 ] == nil then
            package_lists[ state.name ] = nil
        end
    end
end

--- [SHARED AND MENU]
---
--- Returns every registered package, sorted by id.
---
---@return dreamwork.Package[] list The packages.
---@return integer count The number of packages.
---@nodiscard
function loader.getPackages()
    local list, count = {}, 0

    for _, package in raw_pairs( packages ) do
        count = count + 1
        list[ count ] = package
    end

    table_sort( list, by_id )
    return list, count
end

---@param version dreamwork.std.Version
---@param selector string | nil
---@return boolean
local function version_matches( version, selector )
    return selector == nil or selector == "" or selector == "*" or selector == "latest" or version:match( selector )
end

--- [SHARED AND MENU]
---
--- Finds a registered package, a loaded one is preferred, then the newest one.
---
--- `author/name` finds only the packages of the author, `name` finds the packages of any author.
---
---@param name string The name of the package, `name` or `author/name`.
---@param selector string? The version range, e.g. `^1.0.0`, any version by default.
---@return dreamwork.Package | nil package The package, `nil` if not found.
---@nodiscard
function loader.findPackage( name, selector )
    ---@type string | nil
    local author

    local author_str, package_name = string_match( name, "^(.+)/([^/]+)$" )
    if author_str ~= nil then
        author, name = author_folder( author_str ) .. "/", package_name
    end

    local list = package_lists[ name ]
    if list == nil then
        return nil
    end

    ---@type dreamwork.Package | nil
    local fallback

    for index = 1, #list, 1 do
        local package = list[ index ]
        local state = package_states[ package ]

        if version_matches( state.version, selector ) and (author == nil or string_sub( state.id, 1, #author ) == author) then
            if state.status == "loaded" then
                return package
            elseif fallback == nil then
                fallback = package
            end
        end
    end

    return fallback
end

--- [SHARED AND MENU]
---
--- Loads the package and returns the value returned by its entrypoint.
---
--- An installed package is used if its `{author}/{name}` is `user/repo` or it comes from the repository,
--- a missing one is installed from the repository (not on the client): the default branch without a range,
--- the newest version tag (`v1.0.0` or `1.0.0`) that matches the range otherwise, see `loader.install`.
---
--- The calling package starts to depend on the imported one, so it is unloaded when the imported one unloads.
---
--- ```lua
--- local my_lib = import( "user/my_lib" )          -- the default branch
--- local old_lib = import( "user/my_lib@^1.0.0" )  -- the newest tag that matches the range
--- local other = import( "https://github.com/user/other_lib@1.2.0" )
--- ```
---
---@param spec string `user/repo[@range]`, `host/user/repo[@range]` or `https://host/user/repo[@range]`.
---@return any exports The value returned by the entrypoint.
---@async
function std.import( spec )
    local repository, selector = internal.parse_spec( spec )

    local package = internal.resolve_package( repository, selector )
    if package == nil then
        error( string_format( "package '%s' was not found", spec ), 2 )
    end

    ---@cast package dreamwork.Package

    local state = package_states[ package ]

    local module = find_module( 2 )
    if module ~= nil then
        local importer = module_states[ module ].package
        if importer == package then
            error( string_format( "package '%s' cannot import itself", state.id ), 2 )
        end

        link( importer, package )

        if depends_on( package, importer ) then
            package_states[ importer ].dependencies[ package ] = nil
            state.dependents[ importer ] = nil
            error( string_format( "circular import between '%s' and '%s'", package_states[ importer ].id, state.id ), 2 )
        end
    end

    if not load_package( package ) then
        error( string_format( "package '%s' failed to load", state.id ), 2 )
    end

    return state.exports
end

--- [SHARED AND MENU]
---
--- Runs the Lua file and returns its results, every call runs it again.
---
--- In a package the file must be inside of the package and runs as a new module,
--- relative paths are relative to the directory of the calling file.
---
---@param file_path string The path to the Lua file.
---@param ... any The arguments passed to the file.
---@return any ... The values returned by the file.
---@async
function std.dofile( file_path, ... )
    local module = find_module( 2 )
    if module == nil then
        return std.loadfile( path_resolve( file_path, 2 ), getfenv( 2 ) )( ... )
    end

    local module_state = module_states[ module ]
    local package = module_state.package
    local state = package_states[ package ]

    local vfs_path = resolve_module( state, path_getDirectory( module_state.path, false ) or state.root, file_path, false )
    if vfs_path == nil then
        error( string_format( "file '%s' was not found in '%s'", file_path, state.id ), 2 )
    end

    ---@cast vfs_path string

    local _, fn = compile_module( package, state, vfs_path )
    return fn( ... )
end

do

    --- The results of files required outside of packages, by their paths.
    ---
    ---@type table<string, any>
    local global_modules = {}

    --- [SHARED AND MENU]
    ---
    --- Runs the Lua module once and returns its result, the next calls return the same result.
    ---
    --- In a package, dotted names (`utils.math`) are looked up in `lua/` of the package and paths (`./utils.lua`)
    --- are relative to the calling file, only files of the package can be required and every package has its own modules.
    ---
    --- Outside of packages, dotted names are looked up in `/game/lua` and paths are relative to the calling file.
    ---
    ---@param module_name string The name or the path of the module.
    ---@param ... any The arguments passed to the module when it runs for the first time.
    ---@return any result The value returned by the module, `true` if it returned nothing.
    ---@async
    function std.require( module_name, ... )
        local module = find_module( 2 )
        if module ~= nil then
            local module_state = module_states[ module ]
            local package = module_state.package
            local state = package_states[ package ]

            local vfs_path = resolve_module( state, path_getDirectory( module_state.path, false ) or state.root, module_name, true )
            if vfs_path == nil then
                error( string_format( "module '%s' was not found in '%s'", module_name, state.id ), 2 )
            end

            ---@cast vfs_path string

            return require_path( package, state, vfs_path, ... )
        end

        ---@type string
        local vfs_path

        if string_byte( module_name, 1, 1 ) == 0x2E --[[ . ]] or string_find( module_name, "/", 1, true ) ~= nil or string_hasSuffix( module_name, ".lua" ) then
            vfs_path = path_resolve( module_name, 2 )
        else
            vfs_path = "/game/lua/" .. string_gsub( module_name, "%.", "/" )
        end

        if not string_hasSuffix( vfs_path, ".lua" ) then
            if vfs_isFile( vfs_path .. ".lua" ) then
                vfs_path = vfs_path .. ".lua"
            else
                vfs_path = vfs_path .. "/init.lua"
            end
        end

        local result = global_modules[ vfs_path ]
        if result ~= nil then
            return result
        end

        if not vfs_isFile( vfs_path ) then
            error( string_format( "module '%s' was not found", module_name ), 2 )
        end

        result = std.loadfile( vfs_path, getfenv( 2 ) )( ... )
        if result == nil then
            result = true
        end

        global_modules[ vfs_path ] = result
        return result
    end

end

---@param data string
---@return dreamwork.std.Zip
local function parse_zip( data )
    return Zip( data )
end

--- Registers the package from the local archive, errors are logged.
---
---@param vfs_path string The absolute virtual path of the archive.
---@async
local function register_local_archive( vfs_path )
    local success, archive = pcall( parse_zip, vfs_readFile( vfs_path ) )
    if not success then
        dreamwork.Logger:error( "'%s' is not an archive: %s", vfs_path, archive )
        return
    end

    ---@cast archive dreamwork.std.Zip

    local base = archive_base( archive )
    if base == nil then
        dreamwork.Logger:error( "'%s' is invalid: 'package.json' is missing at the root of the archive", vfs_path )
        return
    end

    local manifest, message = parse_manifest( archive:readFile( base .. "package.json" ) or "" )
    if manifest == nil then
        dreamwork.Logger:error( "'%s' is invalid: %s", vfs_path, message )
        return
    end

    ---@cast manifest dreamwork.PackageManifest

    local package, is_new = register( manifest, {
        kind = "archive",
        path = vfs_path,
        archive = archive,
        base = base,
        preprocessed = false
    } )

    if not is_new then
        dreamwork.Logger:warn( "'%s' is installed twice, '%s' is ignored.", package_states[ package ].id, vfs_path )
    end
end

--- Registers the package folder, `package.json` at its root.
---
---@param folder string
local function register_local_folder( folder )
    local manifest_path = folder .. "/package.json"

    local manifest, message = parse_manifest( vfs_readFile( manifest_path ) )
    if manifest == nil then
        dreamwork.Logger:error( "'%s' is invalid: %s", manifest_path, message )
        return
    end

    ---@cast manifest dreamwork.PackageManifest

    local package, is_new = register( manifest, {
        kind = "folder",
        path = folder,
        preprocessed = false
    } )

    if not is_new then
        dreamwork.Logger:warn( "'%s' is installed twice, '%s' is ignored.", package_states[ package ].id, folder )
    end
end

--- Registers the packages of the `packages` folder: its sub-folders with `package.json` and its `.zip` archives.
---
--- The id comes from `package.json`, the names of folders and archives do not matter.
---
---@param folder string
local function discover_folder( folder )
    if not vfs_isDirectory( folder ) then
        return
    end

    if vfs_isFile( folder .. "/package.json" ) then
        dreamwork.Logger:warn( "'%s/package.json' is ignored, every package goes into its own folder: '%s/{name}/package.json'.", folder, folder )
    end

    local file_names, file_count, directory_names, directory_count = vfs_search( folder )

    for index = 1, directory_count, 1 do
        local package_folder = folder .. "/" .. directory_names[ index ]
        if vfs_isFile( package_folder .. "/package.json" ) then
            register_local_folder( package_folder )
        end
    end

    for index = 1, file_count, 1 do
        local file_name = file_names[ index ]
        if string_hasSuffix( string_lower( file_name ), ".zip" ) then
            register_local_archive( folder .. "/" .. file_name )
        end
    end
end

--- The archives of packages in mounted addons (Workshop), `.zip` archives named `*.zip.dat`,
--- the `gmad` whitelist allows only `.dat` files there, see `loader.export`.
---
--- The engine keeps one file per path for all mounted addons (the last mounted wins, even in the search path of each addon),
--- so archives must have unique file names, `loader.export` uses `{name}-{version}.zip.dat`.
--- The id comes from `package.json` of the archive, the file name does not matter.
---
---@type string
local STATIC_DIRECTORY = "/game/data_static/packages"

--- Registers the local packages: the package folders (`*/package.json`) and `.zip` archives in `/garrysmod/packages`
--- and `/garrysmod/addons/*/packages`, and the `*.zip.dat` archives in `data_static/packages` of the mounted addons (Workshop).
---
--- Packages with the same name and different versions or authors are all registered, the same id keeps the first one found.
---@async
local function discover_local()
    discover_folder( "/garrysmod/packages" )

    local _, _, directories, directory_count = vfs_search( "/garrysmod/addons" )

    for index = 1, directory_count, 1 do
        discover_folder( "/garrysmod/addons/" .. directories[ index ] .. "/packages" )
    end

    if vfs_isDirectory( STATIC_DIRECTORY ) then
        local file_names, file_count = vfs_search( STATIC_DIRECTORY, "*.zip.dat" )

        for index = 1, file_count, 1 do
            register_local_archive( STATIC_DIRECTORY .. "/" .. file_names[ index ] )
        end
    end
end

internal.sorted_keys = sorted_keys
internal.is_inside = is_inside
internal.by_id = by_id
internal.create_sigil_env = create_sigil_env
internal.source_files = source_files
internal.source_read = source_read
internal.archive_base = archive_base
internal.is_lua_file = is_lua_file
internal.include_reader = include_reader
internal.parse_manifest = parse_manifest
internal.register = register
internal.version_matches = version_matches
internal.load_package = load_package

-- packages from repositories (GitHub) and their downloaded archives
dreamwork.load( "modules/loader/repositories.lua" )

-- client bundles: built on the server, applied on the client
dreamwork.load( "modules/loader/bundles.lua" )

-- packing packages into archives and Workshop addons
dreamwork.load( "modules/loader/export.lua" )

-- auto-reload of local package folders in the developer mode
dreamwork.load( "modules/loader/watcher.lua" )

---@async
local function startup()
    local start_time = dreamwork_getUpTime()

    if LUA_CLIENT then
        local transport = dreamwork_transport
        if transport == nil then
            return
        end

        local previous_handler = loader.TransportHandler
        if previous_handler ~= nil then
            transport.Updated:detach( previous_handler )
        end

        local synchronize = internal.synchronize

        loader.TransportHandler = synchronize
        transport.Updated:attach( synchronize )

        -- a reloaded package manager applies the files the transport already has, it tells only about changes
        local files = transport.getFiles()
        if raw_next( files ) ~= nil then
            synchronize( files )
        end

        transport.startup()
        return
    end

    if LUA_SERVER and dreamwork_transport ~= nil then
        dreamwork_transport.startup()
    end

    discover_local()
    internal.discover_archives()

    local list, count = loader.getPackages()

    for index = 1, count, 1 do
        if is_shutdown then
            return
        end

        local package = list[ index ]
        local state = package_states[ package ]

        if state.realms[ LUA_REALM ] then
            load_package( package )
        elseif LUA_SERVER and state.realms.client then
            exceptions_call( internal.publish, state )
        end
    end

    if is_shutdown then
        return
    end

    if LUA_SERVER and dreamwork_transport ~= nil then
        dreamwork_transport.setReady( true )
    end

    internal.watcher_start()

    if count ~= 0 then
        local loaded_count, failed_count = 0, 0

        for index = 1, count, 1 do
            local status = package_states[ list[ index ] ].status
            if status == "loaded" then
                loaded_count = loaded_count + 1
            elseif status == "failed" then
                failed_count = failed_count + 1
            end
        end

        local elapsed = (dreamwork_getUpTime() - start_time) * 1000

        if failed_count == 0 then
            dreamwork.Logger:info( "%d of %d package(s) loaded in %.2f ms.", loaded_count, count, elapsed )
        else
            dreamwork.Logger:warn( "%d of %d package(s) loaded in %.2f ms, %d failed.", loaded_count, count, elapsed, failed_count )
        end
    end
end

--- [SHARED AND MENU]
---
--- Finds and loads the packages: local packages and downloaded ones on the server and in the menu,
--- the packages sent by the server on the client.
---
--- Called once the package manager is loaded, a reloaded package manager starts again by itself.
---
function loader.startup()
    futures_run( startup )
end

--- [SHARED AND MENU]
---
--- Stops the package manager: cancels the packages that are loading and unloads every package,
--- used when the package manager reloads and when the game shuts down (map change, disconnect).
---
function loader.shutdown()
    if is_shutdown then
        return
    end

    is_shutdown = true

    local watcher_stop = internal.watcher_stop
    if watcher_stop ~= nil then
        exceptions_call( watcher_stop )
    end

    local list, count = loader.getPackages()
    local current_thread = coroutine_running()

    for index = 1, count, 1 do
        local thread = package_states[ list[ index ] ].thread
        if thread ~= nil and thread ~= current_thread then
            futures_cancel( thread )
        end
    end

    for index = count, 1, -1 do
        local package = list[ index ]
        if package_states[ package ].status == "loaded" then
            exceptions_call( unload_package, package )
        end
    end
end

-- packages unloaded by `__gc` while the game closes the Lua state log into a dead state and crash it,
-- so they are unloaded while the game still runs
engine_hook.catch( "ShutDown", "modules.loader.shutdown", loader.shutdown )

loader.startup()
