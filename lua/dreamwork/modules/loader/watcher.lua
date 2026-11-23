---@class dreamwork
local dreamwork = dreamwork

---@class dreamwork.std
local std = dreamwork.std

-- the client only runs the packages sent by the server, the server reloads and sends them again
if std.LUA_CLIENT then return end

local engine = dreamwork.engine
local engine_hook = engine.hook
local engine_timer = engine.timer

local vfs = dreamwork.vfs
local vfs_watch = vfs.watch
local vfs_unwatch = vfs.unwatch
local vfs_isFile = vfs.isFile
local vfs_iterator = vfs.iterator
local vfs_readFile = vfs.readFile
local vfs_isDirectory = vfs.isDirectory

local raw_pairs = std.raw.pairs

local string = std.string
local string_sub = string.sub
local string_find = string.find

local futures_run = std.futures.run

local LUA_SERVER = std.LUA_SERVER
local LUA_REALM = std.LUA_REALM

---@class dreamwork.loader
local loader = dreamwork.loader

local internal = loader.Internal
local package_states = internal.package_states
local packages = internal.packages
local is_inside = internal.is_inside
local parse_manifest = internal.parse_manifest
local register = internal.register
local load_package = internal.load_package

--- [SERVER AND MENU]
---
--- Auto-reload: the folders of local packages (`/garrysmod/packages/*` and `/garrysmod/addons/*/packages/*`) are watched,
--- a changed package is reloaded with its dependents, a changed `package.json` registers the package again.
---
--- Archives (`.zip`, `data_static/packages/*.zip.dat` of Workshop addons), repository packages and their cache are never watched.
---
--- Enabled while the `developer` console variable is not `0`.
---

--- The delay after the last change before the package reloads, editors write files in several steps.
---
---@type number
local RELOAD_DELAY = 0.5

---@type string
local TIMER_NAME = "dreamwork.loader.watcher"

---@type string
local HOOK_IDENTIFIER = "modules.loader.watcher"

--- The watched package folders and their packages.
---
---@type table<string, dreamwork.Package>
local folder_packages = {}

--- The watched directories of the package folders, `vfs.watch` does not descend into subdirectories.
---
---@type table<string, table<string, boolean>>
local folder_directories = {}

--- The folders with changes waiting for the reload, `true` if `package.json` changed.
---
---@type table<string, boolean>
local pending = {}

--- The folders whose package was unloaded because `package.json` or the folder was removed, loaded again once it is back.
---
---@type table<string, boolean>
local removed = {}

local is_enabled = false

---@type dreamwork.transport | nil
local dreamwork_transport = LUA_SERVER and dreamwork.transport or nil

--- The number of running reloads, the transport holds the client updates until all of them finish.
local reload_count = 0

---@param file_path string The path relative to the package folder.
---@return boolean
local function is_hidden( file_path )
    return string_find( file_path, "^%." ) ~= nil or string_find( file_path, "/%." ) ~= nil
end

---@param folder string
---@param directory_path string
local function watch_directory( folder, directory_path )
    local directories = folder_directories[ folder ]
    if directories[ directory_path ] then
        return
    end

    directories[ directory_path ] = true
    vfs_watch( directory_path )

    for vfs_path, is_directory in vfs_iterator( directory_path ) do
        if is_directory and not directories[ vfs_path ] and not is_hidden( string_sub( vfs_path, #folder + 2 ) ) then
            directories[ vfs_path ] = true
            vfs_watch( vfs_path )
        end
    end
end

--- Stops watching the directory and its subdirectories, the package folder itself stays watched until the package is forgotten.
---
---@param folder string
---@param directory_path string
local function unwatch_directory( folder, directory_path )
    local directories = folder_directories[ folder ]

    for vfs_path in raw_pairs( directories ) do
        if vfs_path ~= folder and (vfs_path == directory_path or is_inside( vfs_path, directory_path )) then
            directories[ vfs_path ] = nil
            vfs_unwatch( vfs_path )
        end
    end
end

---@param folder string
---@param package dreamwork.Package
local function watch_folder( folder, package )
    folder_packages[ folder ] = package

    if folder_directories[ folder ] == nil then
        folder_directories[ folder ] = {}
        watch_directory( folder, folder )
    end
end

---@param folder string
local function unwatch_folder( folder )
    local directories = folder_directories[ folder ]
    if directories ~= nil then
        for vfs_path in raw_pairs( directories ) do
            vfs_unwatch( vfs_path )
        end
    end

    folder_directories[ folder ] = nil
    folder_packages[ folder ] = nil
    pending[ folder ] = nil
    removed[ folder ] = nil
end

--- Returns the dependents of the package and their dependents, in the order they were found.
---
---@param package dreamwork.Package
---@param list dreamwork.Package[]
---@return dreamwork.Package[] list
local function collect_dependents( package, list )
    for dependent in raw_pairs( package_states[ package ].dependents ) do
        list[ #list + 1 ] = dependent
        collect_dependents( dependent, list )
    end

    return list
end

--- Loads the package if it runs in this realm, sends it to the clients otherwise.
---
---@param package dreamwork.Package
---@async
local function activate( package )
    local state = package_states[ package ]

    if state.realms[ LUA_REALM ] then
        load_package( package )
    elseif LUA_SERVER and state.realms.client then
        internal.publish( state )
    end
end

--- Registers the package of the folder again with the new `package.json`, the version or the realms could change.
---
---@param folder string
---@param package dreamwork.Package
---@async
local function replace_package( folder, package )
    local state = package_states[ package ]
    local manifest_path = folder .. "/package.json"

    if not vfs_isFile( manifest_path ) then
        local was_published = state.published
        internal.unpublish( state )

        if loader.unload( package ) or was_published then
            removed[ folder ] = true
            dreamwork.Logger:warn( "'%s' was removed, package '%s' is unloaded.", manifest_path, state.id )
        end

        return
    end

    local manifest, message = parse_manifest( vfs_readFile( manifest_path ) )
    if manifest == nil then
        dreamwork.Logger:error( "'%s' is invalid, package '%s' is kept: %s", manifest_path, state.id, message )
        return
    end

    ---@cast manifest dreamwork.PackageManifest

    local was_active = state.status ~= "installed" or state.published or removed[ folder ] == true
    removed[ folder ] = nil

    local dependents = collect_dependents( package, {} )

    internal.unpublish( state )
    loader.remove( package )

    local new_package, is_new = register( manifest, state.source )
    if not is_new then
        dreamwork.Logger:warn( "'%s' is installed twice, '%s' is ignored.", package_states[ new_package ].id, folder )
        unwatch_folder( folder )
        return
    end

    folder_packages[ folder ] = new_package
    dreamwork.Logger:info( "Package '%s' is registered again as '%s'.", state.id, package_states[ new_package ].id )

    if not was_active then
        return
    end

    activate( new_package )

    for index = 1, #dependents, 1 do
        local dependent = dependents[ index ]
        if package_states[ dependent ].status == "installed" then
            activate( dependent )
        end
    end
end

--- Reloads the package of the folder.
---
---@param folder string
---@param manifest_changed boolean
---@async
local function reload_folder( folder, manifest_changed )
    local package = folder_packages[ folder ]
    if package == nil then
        return
    end

    local state = package_states[ package ]

    -- forgotten by `loader.remove`
    if packages[ state.id ] ~= package then
        unwatch_folder( folder )
        return
    end

    if manifest_changed or not vfs_isDirectory( folder ) then
        replace_package( folder, package )
        return
    end

    local status = state.status
    if status == "loaded" or status == "failed" then
        dreamwork.Logger:info( "Package '%s' has changed, reloading...", state.id )
        package:reload()
    elseif state.published then
        -- a client-only package on the server
        internal.publish( state )
    end
end

--- Clients are told about the changes once the reloads finish, a reloading package drops the bundles of its dependents
--- for a while, a client told in between would unload them.
---
---@param folder string
---@param manifest_changed boolean
local function run_reload( folder, manifest_changed )
    local transport = dreamwork_transport

    if transport ~= nil and reload_count == 0 then
        transport.setReady( false )
    end

    reload_count = reload_count + 1

    futures_run( reload_folder, function()
        reload_count = reload_count - 1

        if transport ~= nil and reload_count == 0 then
            transport.setReady( true )
        end
    end, folder, manifest_changed )
end

local function process_pending()
    -- reloads can change files and add new pending folders
    local batch = pending
    pending = {}

    local schedule_again = false

    for folder, manifest_changed in raw_pairs( batch ) do
        local package = folder_packages[ folder ]

        -- the load in progress would miss the change, it is reloaded after it
        if package ~= nil and package_states[ package ].status == "loading" then
            pending[ folder ] = pending[ folder ] or manifest_changed
            schedule_again = true
        else
            run_reload( folder, manifest_changed )
        end
    end

    if schedule_again then
        engine_timer.create( TIMER_NAME, RELOAD_DELAY, 1, process_pending, true )
    end
end

---@param vfs_path string
---@param is_directory boolean
---@param is_deleted boolean
local function on_change( vfs_path, is_directory, is_deleted )
    for folder in raw_pairs( folder_packages ) do
        if vfs_path == folder or is_inside( vfs_path, folder ) then
            local file_path = string_sub( vfs_path, #folder + 2 )
            if file_path ~= "" and is_hidden( file_path ) then
                return
            end

            if is_directory and vfs_path ~= folder then
                if is_deleted then
                    unwatch_directory( folder, vfs_path )
                elseif vfs_isDirectory( vfs_path ) then
                    watch_directory( folder, vfs_path )
                end
            end

            pending[ folder ] = pending[ folder ] or file_path == "package.json"
            engine_timer.create( TIMER_NAME, RELOAD_DELAY, 1, process_pending, true )
            return
        end
    end
end

---@param vfs_path string
---@param is_directory boolean
local function on_created( vfs_path, is_directory )
    on_change( vfs_path, is_directory, false )
end

---@param vfs_path string
---@param is_directory boolean
local function on_deleted( vfs_path, is_directory )
    on_change( vfs_path, is_directory, true )
end

---@param vfs_path string
---@param is_directory boolean
local function on_modified( vfs_path, is_directory )
    if not is_directory then
        on_change( vfs_path, false, false )
    end
end

local function enable()
    if is_enabled then
        return
    end

    is_enabled = true

    local list, count = loader.getPackages()

    for index = 1, count, 1 do
        local source = package_states[ list[ index ] ].source

        -- only folders are local, archives and repository packages are never watched
        local folder = source.path
        if source.kind == "folder" and folder ~= nil and vfs_isDirectory( folder ) then
            watch_folder( folder, list[ index ] )
        end
    end

    engine_hook.catch( "dreamwork.vfs.created", HOOK_IDENTIFIER, on_created )
    engine_hook.catch( "dreamwork.vfs.deleted", HOOK_IDENTIFIER, on_deleted )
    engine_hook.catch( "dreamwork.vfs.modified", HOOK_IDENTIFIER, on_modified )
end

local function disable()
    if not is_enabled then
        return
    end

    is_enabled = false

    engine_hook.release( "dreamwork.vfs.created", HOOK_IDENTIFIER )
    engine_hook.release( "dreamwork.vfs.deleted", HOOK_IDENTIFIER )
    engine_hook.release( "dreamwork.vfs.modified", HOOK_IDENTIFIER )

    engine_timer.remove( TIMER_NAME )

    for folder in raw_pairs( folder_directories ) do
        unwatch_folder( folder )
    end
end

local developer = std.console.Variable.get( "developer", "integer" )

---@param _ dreamwork.std.console.Variable<integer>
---@param value integer
local function on_developer( _, value )
    if value == 0 then
        disable()
    else
        enable()
    end
end

--- Starts watching the local packages if the developer mode is on, called once the local packages are registered.
local function watcher_start()
    developer:attach( on_developer )

    if developer.value ~= 0 then
        enable()
    end
end

internal.watcher_start = watcher_start

--- Stops watching the local packages, called when the package manager shuts down.
local function watcher_stop()
    developer:detach( on_developer )
    disable()
end

internal.watcher_stop = watcher_stop
