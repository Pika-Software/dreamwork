---@class dreamwork
local dreamwork = dreamwork

local dreamwork_engine = dreamwork.engine

local engine_timer = dreamwork_engine.timer
local engine_timer_create = engine_timer.create

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile
local vfs_deleteFile = vfs.deleteFile

local dreamwork_storage = dreamwork.storage

local storage_files = dreamwork_storage.files
local storage_files_write = storage_files.write
local storage_files_touch = storage_files.touch
local storage_files_delete = storage_files.delete
local storage_files_expired = storage_files.expired

local storage_http = dreamwork_storage.http

local std = dreamwork.std

local raw_pairs = std.raw.pairs

local gc = std.gc
local gc_collect = gc.collect
local gc_getMemory = gc.getMemory

local console = std.console
local console_Variable = console.Variable


--- [SHARED AND MENU]
---
--- Deletes cached and temporary files once their time to live has passed,
--- and empties in-memory Lua caches before a full garbage collection.
---
--- A file is registered when it is written. `access` moves that time forward while the file is still in use.
--- Expired files are deleted when this module loads, which is after `storage.init`, and again every hour.
---
--- Lua caches are emptied every `dreamwork_gc_interval` seconds ( `dreamwork_menu_gc_interval` on the menu ), then the garbage is collected.
---
--- ```lua
--- dreamwork.cleanup.register( "/garrysmod/data/my_addon/dump.dat", 3600 )
--- dreamwork.cleanup.access( "/garrysmod/data/my_addon/dump.dat" )
---
--- local cache = {}
---
--- dreamwork.cleanup.attachCache( "my_addon.cache", function()
---     cache = {}
--- end )
--- ```
---
---@class dreamwork.cleanup
local cleanup = dreamwork.cleanup or {}
dreamwork.cleanup = cleanup

---@type dreamwork.std.console.Variable<integer>
local cache_lifetime = console_Variable( {
    name = dreamwork.selectVariableName( "cache_lifetime" ),
    description = "The number of days cached files ( e.g. materials ) are kept for since their last use, '0' keeps them forever.",
    type = "integer",
    default = 30,
    min = 0,
    max = 3650,
    archive = true,
    hidden = true
} )

---@type dreamwork.std.console.Variable<integer>
local temporary_lifetime = console_Variable( {
    name = dreamwork.selectVariableName( "temporary_lifetime" ),
    description = "The number of hours temporary files ( e.g. mounted addons ) are kept for since their last use, '0' keeps them forever.",
    type = "integer",
    default = 1,
    min = 0,
    max = 87600,
    archive = true,
    hidden = true
} )

--- [SHARED AND MENU]
---
--- Registers the file, or replaces its record. It expires `lifetime` after this call.
---
---@param file_path string The absolute path to the file.
---@param lifetime number The number of seconds the file is kept for, `0` keeps it forever.
function cleanup.register( file_path, lifetime )
    storage_files_write( { file_path }, 1, lifetime * 1000 )
end

local cleanup_register = cleanup.register

--- [SHARED AND MENU]
---
--- Registers a cached file. It is kept for `dreamwork_cache_lifetime` days since this call.
---
---@param file_path string The absolute path to the file.
function cleanup.registerCache( file_path )
    cleanup_register( file_path, cache_lifetime.value * 86400 )
end

--- [SHARED AND MENU]
---
--- Registers a temporary file. It is kept for `dreamwork_temporary_lifetime` hours since this call.
---
---@param file_path string The absolute path to the file.
function cleanup.registerTemporary( file_path )
    cleanup_register( file_path, temporary_lifetime.value * 3600 )
end

--- [SHARED AND MENU]
---
--- Marks the file as used now, so it is kept for its lifetime again.
---
--- Does nothing when the file has no record. Register it first.
---
---@param file_path string The absolute path to the file.
---@return boolean updated `true` if the record was updated.
function cleanup.access( file_path )
    return storage_files_touch( file_path )
end

--- [SHARED AND MENU]
---
--- Deletes every registered file whose time to live has passed, and the records of files that are already gone.
---
--- A file that cannot be deleted ( e.g. locked by the game ) keeps its record and is deleted by a later cleanup.
---
function cleanup.sweep()
    local file_paths, file_count = storage_files_expired()

    ---@type string[]
    local deleted = {}
    local deleted_count = 0

    for index = 1, file_count, 1 do
        local file_path = file_paths[ index ]
        if not vfs_isFile( file_path ) or vfs_deleteFile( file_path, true ) then
            deleted_count = deleted_count + 1
            deleted[ deleted_count ] = file_path
        end
    end

    if deleted_count ~= 0 then
        storage_files_delete( deleted, deleted_count )
        dreamwork.Logger:debug( "Cleanup: %d expired file(s) deleted.", deleted_count )
    end
end

engine_timer_create( "dreamwork.cleanup", 3600, 0, function()
    exceptions_call( cleanup.sweep )
end, true )

-- `storage.init` has already run. vfs is loaded, so the expired files can be deleted now.
exceptions_call( cleanup.sweep )

---@type table<string, fun()>
local cache_clearers = {}

--- [SHARED AND MENU]
---
--- Registers a function that empties an in-memory Lua cache, or replaces the one with the same name.
---
--- It is called by `cleanup.collect` before the garbage is collected.
--- Entries still in use must be recreated on demand, the cache can be emptied at any time.
---
---@param name string The unique name of the cache.
---@param clear fun() The function that empties the cache.
function cleanup.attachCache( name, clear )
    cache_clearers[ name ] = clear
end

--- [SHARED AND MENU]
---
--- Removes the cache function registered under the name, does nothing if there is none.
---
---@param name string The unique name of the cache.
function cleanup.detachCache( name )
    cache_clearers[ name ] = nil
end

--- [SHARED AND MENU]
---
--- Empties every registered Lua cache, then performs a full garbage collection.
---
--- An error in one cache function is reported and does not stop the others.
---
---@return number freed The memory freed, in kilobytes.
function cleanup.collect()
    local memory = gc_getMemory()

    for _, clear in raw_pairs( cache_clearers ) do
        exceptions_call( clear )
    end

    gc_collect()

    local freed = memory - gc_getMemory()
    dreamwork.Logger:debug( "Cleanup: Lua caches emptied, %.2f MB of garbage collected.", freed / 1024 )
    return freed
end

cleanup.attachCache( "dreamwork.storage", dreamwork_storage.clearCache )
cleanup.attachCache( "dreamwork.storage.http", storage_http.clearCache )

---@type dreamwork.std.console.Variable<integer>
local gc_interval = console_Variable( {
    name = dreamwork.selectVariableName( "gc_interval" ),
    description = "The number of seconds between emptying Lua caches and collecting the garbage, '0' disables it.",
    type = "integer",
    default = 600,
    min = 0,
    max = 86400,
    archive = true,
    hidden = true
} )

---@param interval integer
local function schedule( interval )
    engine_timer_create( "dreamwork.cleanup.collect", interval, 0, function()
        exceptions_call( cleanup.collect )
    end, interval ~= 0 )
end

schedule( gc_interval.value )

gc_interval:attach( function( _, value )
    schedule( value )
end )
