local dreamwork_engine = dreamwork.engine

local engine_mounts = dreamwork_engine.mounts

local engine_hook = dreamwork_engine.hook
local hook_catch = engine_hook.catch
local hook_call = engine_hook.call

local dreamwork_getUpTime = dreamwork.getUpTime
local error_handler = dreamwork.errorHandler

local detour = dreamwork.detour

local glua_file = file

---@type holylib.filesystem | nil
local filesystem = filesystem
local has_filesystem = filesystem ~= nil

local driver = filesystem or glua_file

local driver_Time = driver.Time
local driver_Find = driver.Find
local driver_Open = driver.Open
local driver_Size = driver.Size
local driver_IsDir = driver.IsDir
local driver_Exists = driver.Exists
local driver_Delete = driver.Delete
local driver_Rename = driver.Rename
local driver_CreateDir = driver.CreateDir
local driver_TimeCreated = driver.TimeCreated or driver_Time
local driver_TimeAccessed = driver.TimeAccessed or driver_Time

---@class dreamwork.std
local std = dreamwork.std

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER
local LUA_MENU = std.LUA_MENU

local raw = std.raw
local raw_next = raw.next
local raw_pairs = raw.pairs

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_match = string.match
local string_lower = string.lower
local string_format = string.format
local string_byteSplit = string.byteSplit
local string_containsByte = string.containsByte
local string_containsBytes = string.containsBytes

local path = std.path
local path_split = path.split
local path_resolve = path.resolve
local path_wildcard = path.wildcard
local path_normalize = path.normalize
local path_getExtension = path.getExtension
local path_stripLeadingSlash = path.stripLeadingSlash

local table = std.table
local table_removeByValue = table.removeByValue

local time = std.time
local time_now = time.now

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local class = std.class
local Future = std.Future

local isNumber = std.isNumber
local isString = std.isString
local xpcall = std.xpcall
local error = std.error


do

    local glua_require = require or std.debug.fempty
    local pcall = std.pcall

    local SYSTEM_WINDOWS = std.SYSTEM_WINDOWS
    local SYSTEM_LINUX = std.SYSTEM_LINUX
    local SYSTEM_X32 = std.SYSTEM_X32

    local jit_edge = std.jit.edge

    local head = "lua/bin/gm" .. (LUA_CLIENT and "cl" or "sv") .. "_"
    local tail = "_" .. std.SYSTEM_NAME

    --- [SHARED AND MENU]
    ---
    --- Checks if a binary module is available and can be loaded.
    ---
    ---@param name string The binary module name.
    ---@return boolean installed `true` if binary module is available, `false` otherwise.
    ---@return string abs_path The absolute path to binary module.
    local function lookupbinary( name )
        local file_path = head .. name .. tail

        local dll_path = file_path .. ".dll"
        if driver_Exists( dll_path, "MOD" ) then
            return true, "/garrysmod/" .. dll_path
        end

        local so_path = file_path .. ".so"
        if driver_Exists( so_path, "MOD" ) then
            return true, "/garrysmod/" .. so_path
        end

        if jit_edge and SYSTEM_LINUX and SYSTEM_X32 then
            file_path = head .. name .. "_linux32"

            dll_path = file_path .. ".dll"
            if driver_Exists( dll_path, "MOD" ) then
                return true, "/garrysmod/" .. dll_path
            end

            so_path = file_path .. ".so"
            if driver_Exists( so_path, "MOD" ) then
                return true, "/garrysmod/" .. so_path
            end
        end

        return false, "/garrysmod/" .. file_path .. (SYSTEM_WINDOWS and ".dll" or ".so")
    end

    std.lookupbinary = lookupbinary

    local sv_allowcslua

    if LUA_SERVER then
        sv_allowcslua = std.console.Variable.get( "sv_allowcslua", "boolean" )
    end

    --- [SHARED AND MENU]
    ---
    --- Loads a binary module if available.
    ---
    ---@param name string The binary module name, for example: "chttp".
    ---@return boolean success `true` if binary module is successfully installed, `false` otherwise.
    function std.loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua.value then
                sv_allowcslua.value = false
            end

            return (pcall( glua_require, name ))
        end

        return false
    end

end

do

    ---@type string[]
    local queue = {
        "asyncio",
        "async_write"
    }

    ---@type string | nil
    local driver_name

    for i = 1, 2, 1 do
        local name = queue[ i ]
        if std.loadbinary( name ) then
            dreamwork.Logger:info( "'%s' was loaded & connected as file system driver.", name )
            driver_name = name
            break
        end
    end

    -- async_write runs every job in parallel, so writes into one file land in any order,
    -- `AsyncAppend` returns the last argument instead of the status, rejected paths are never called back
    -- and callbacks are called unprotected from Rust, an error in them unwinds through native frames
    if driver_name == "async_write" then
        ---@type table<string, boolean>
        local extensions = {
            txt = true,
            dat = true,
            json = true,
            xml = true,
            csv = true,
            jpg = true,
            jpeg = true,
            png = true,
            vtf = true,
            vmt = true,
            mp3 = true,
            wav = true,
            ogg = true
        }

        ---@class dreamwork.vfs.AsyncWriteJob
        ---@field fn function The original `file.AsyncWrite` or `file.AsyncAppend`.
        ---@field path string
        ---@field data string
        ---@field callback gm_async_write.Callback | nil
        ---@field next dreamwork.vfs.AsyncWriteJob | nil

        ---@type table<string, { first: dreamwork.vfs.AsyncWriteJob, last: dreamwork.vfs.AsyncWriteJob }>
        local queues = {}

        ---@type fun( key: string, job: dreamwork.vfs.AsyncWriteJob ): integer
        local dispatch

        ---@param key string
        ---@param job dreamwork.vfs.AsyncWriteJob
        ---@param status integer
        local function complete( key, job, status )
            local next_job = job.next
            if next_job == nil then
                queues[ key ] = nil
            else
                queues[ key ].first = next_job
            end

            local callback = job.callback
            if callback ~= nil then
                xpcall( callback, error_handler, job.path, status )
            end

            -- the callback could not write into the file before, its job is behind `next_job`
            while next_job ~= nil do
                status = dispatch( key, next_job )
                if status >= 0 then
                    break
                end

                -- rejected by the module, it never calls back
                job, next_job = next_job, next_job.next

                if next_job == nil then
                    queues[ key ] = nil
                else
                    queues[ key ].first = next_job
                end

                callback = job.callback
                if callback ~= nil then
                    xpcall( callback, error_handler, job.path, status )
                end
            end
        end

        function dispatch( key, job )
            local status = job.fn( job.path, job.data, function( _, write_status )
                complete( key, job, write_status )
            end )

            if isNumber( status ) and status < 0 then
                return status
            end

            return 0
        end

        ---@param fn function
        ---@param file_path string
        ---@param data string
        ---@param callback gm_async_write.Callback | nil
        ---@param sync boolean | nil
        ---@return integer status
        local function async_write( fn, file_path, data, callback, sync )
            -- the module rejects these without calling back, the same checks keep the status right for queued jobs
            local last_byte = string_byte( file_path, -1 )
            if last_byte == nil or last_byte == 0x2F --[[ / ]] or last_byte == 0x5C --[[ \ ]] then
                return -1
            end

            local extension = string_match( file_path, "%.([^%./\\]+)$" )
            if extension == nil or not extensions[ extension ] then
                return -1
            end

            local key = path_stripLeadingSlash( path_normalize( file_path, false ) )
            if key == ".." or string_sub( key, 1, 3 ) == "../" then
                return -1
            end

            if driver_IsDir( key, "DATA" ) then
                return -1
            end

            local file_queue = queues[ key ]

            if sync == true then
                if file_queue ~= nil then
                    error( string_format( "'%s' has pending asynchronous writes, it cannot be written synchronously.", key ), 2 )
                end

                local status = fn( file_path, data, callback and function( _, write_status )
                    xpcall( callback, error_handler, file_path, write_status )
                end, true )

                if isNumber( status ) and status < 0 then
                    return status
                end

                return 0
            end

            ---@type dreamwork.vfs.AsyncWriteJob
            local job = {
                fn = fn,
                path = file_path,
                data = data,
                callback = callback
            }

            if file_queue ~= nil then
                file_queue.last.next = job
                file_queue.last = job
                return 0
            end

            queues[ key ] = {
                first = job,
                last = job,
            }

            local status = dispatch( key, job )
            if status < 0 then
                queues[ key ] = nil
            end

            return status
        end

        detour.attach( async_write, glua_file, "AsyncWrite" )
        detour.attach( async_write, glua_file, "AsyncAppend" )
    end

end

---@type nil | fun( relative_path: string, search_path: string, callback: garrysmod.file.AsyncReadCallback, sync_read: boolean? ): garrysmod.file.AsyncStatus
local file_AsyncRead

-- rubat removed this function in menu because he's a lazy jerk
if not LUA_MENU then
    file_AsyncRead = driver.AsyncRead
end

---@type nil | fun( relative_path: string, data: string, callback: gm_async_write.Callback ): garrysmod.file.AsyncStatus | gm_async_write.Callback
local file_AsyncWrite = glua_file.AsyncWrite

---@type nil | fun( relative_path: string, data: string, callback: gm_async_write.Callback ): garrysmod.file.AsyncStatus | gm_async_write.Callback
local file_AsyncAppend = glua_file.AsyncAppend

if asyncio ~= nil then
    file_AsyncRead = asyncio.AsyncRead or file_AsyncRead

    if file_AsyncWrite == nil then
        local asyncio_AsyncWrite = asyncio.AsyncWrite

        function file_AsyncWrite( relative_path, data, callback )
            return asyncio_AsyncWrite( relative_path, data, function( file_name, _, status )
                return callback( file_name, status )
            end )
        end

    end

    if file_AsyncAppend == nil then
        local asyncio_AsyncAppend = asyncio.AsyncAppend

        function file_AsyncAppend( relative_path, data, callback )
            return asyncio_AsyncAppend( relative_path, data, function( file_name, _, status )
                return callback( file_name, status )
            end )
        end
    end
end

if file_AsyncWrite == nil or file_AsyncAppend == nil then
    file_AsyncWrite, file_AsyncAppend = nil, nil
end

-- the engine reports top level directories of some search paths ('materials' in 'cstrike') as missing
-- even though they are listed, so the listing is the source of truth for names without a parent
---@param name string
---@param search_path string
---@return boolean exists
---@return boolean is_directory
local function probe_root( name, search_path )
    local files, directories = driver_Find( name, search_path )
    if directories ~= nil and directories[ 1 ] ~= nil then
        return true, true
    end

    return files ~= nil and files[ 1 ] ~= nil, false
end

---@param relative_path string
---@param search_path string
---@return boolean
local function file_Exists( relative_path, search_path )
    if driver_Exists( relative_path, search_path ) then
        return true
    end

    if string_byte( relative_path, 1, 1 ) == nil or
        string_containsByte( relative_path, 0x2F --[[ / ]] ) then
        return false
    end

    return (probe_root( relative_path, search_path ))
end

---@param relative_path string
---@param search_path string
---@return boolean
local function file_IsDir( relative_path, search_path )
    if driver_IsDir( relative_path, search_path ) then
        return true
    end

    if relative_path == "" or string_containsByte( relative_path, 0x2F --[[ / ]] ) then
        return false
    end

    local _, is_directory = probe_root( relative_path, search_path )
    return is_directory
end


--- [SHARED AND MENU]
---
--- The virtual file system library.
---
--- Every path is absolute and starts at the game root (`steamapps/common/GarrysMod/`),
--- directories of the map are backed by [search paths](https://wiki.facepunch.com/gmod/File_Search_Paths) mounted into it:
---
--- ```
--- /bin/linux64/...          BASE_PATH
--- /garrysmod/models/...     MOD
--- /garrysmod/data/...       DATA
--- /game/...                 GAME
--- /game/lua/...             lsv | lcl | LuaMenu
--- /hl2/materials/...        hl2 (mounted games)
--- /addons/gma_0001/...      addon title (mounted addons)
--- ```
---
--- Every function takes a path inside of the virtual file system, relative paths are resolved against the calling file, see `path.resolve`:
---
--- ```lua
--- -- in /game/lua/autorun/init.lua
--- dreamwork.vfs.readFile( "/garrysmod/data/settings.txt" ) -- "/garrysmod/data/settings.txt"
--- dreamwork.vfs.readFile( "settings.txt" ) -- "/game/lua/autorun/settings.txt"
--- ```
---
--- Mounts only give access to a search path, they never mount or unmount anything in the engine.
---
---@class dreamwork.vfs
local vfs = {}
dreamwork.vfs = vfs

---@type table<string, dreamwork.vfs.MountInfo>
local engine_mounts = {
    [ "DATA" ] = {
        writable = true,
        deletable = true,
        -- https://wiki.facepunch.com/gmod/file.Write
        extensions = {
            txt = true,
            dat = true,
            json = true,
            xml = true,
            csv = true,
            dem = true,
            vcd = true,
            gma = true,
            mdl = true,
            phy = true,
            vvd = true,
            vtx = true,
            ani = true,
            vtf = true,
            vmt = true,
            png = true,
            jpg = true,
            jpeg = true,
            mp3 = true,
            wav = true,
            ogg = true,
        }
    },
    [ "MOD" ] = {
        writable = has_filesystem,
        deletable = LUA_MENU
    },
    [ "GAME" ] = {
        writable = has_filesystem,
        deletable = false
    },
    [ "BASE_PATH" ] = {
        writable = has_filesystem,
        deletable = false
    },
    [ "DOWNLOAD" ] = {
        writable = has_filesystem,
        deletable = false
    },
    [ "BSP" ] = {
        writable = false,
        deletable = false
    },
    [ "lsv" ] = {
        writable = false,
        deletable = false
    },
    [ "lcl" ] = {
        writable = false,
        deletable = false
    },
    [ "LuaMenu" ] = {
        writable = false,
        deletable = false
    }
}

---@type table<string, boolean>
local restricted_names = {
    [ "^dreamwork_tmp$.dat" ] = true,
    [ ".." ] = true,
    [ "." ] = true,
    [ "" ] = true,
    -- `file.Find( "*", "GAME" )` lists the root itself as a folder named "/"
    [ "/" ] = true
}

---@type table<integer, boolean>
local invalid_characters = {
    [ 0x22 ] = true, -- "
    [ 0x27 ] = true, -- '
    [ 0x2A ] = true, -- *
    [ 0x2F ] = true, -- /
    [ 0x3A ] = true, -- :
    [ 0x3C ] = true, -- <
    [ 0x3E ] = true, -- >
    [ 0x3F ] = true, -- ?
    [ 0x5C ] = true, -- \
    [ 0x7C ] = true, -- |
    [ 0x7F ] = true  -- DEL
}

for byte = 0, 31, 1 do
    invalid_characters[ byte ] = true
end

---@param name string
---@return string | nil message
local function check_name( name )
    if restricted_names[ name ] then
        return string_format( "name '%s' is reserved.", name )
    end

    local has_restricted_byte, position, uint8 = string_containsBytes( name, invalid_characters )
    if has_restricted_byte then
        return string_format( "name '%s' contains invalid character \\x%02X at index %d.", name, uint8, position )
    end

    return nil
end

---@param relative_path string
---@param name string
---@return string
local function join_path( relative_path, name )
    if string_byte( relative_path, 1, 1 ) == nil then
        return name
    end

    return relative_path .. "/" .. name
end

---@param vfs_path string
---@param name string
---@return string
local function child_path( vfs_path, name )
    if vfs_path == "/" then
        return "/" .. name
    end

    return vfs_path .. "/" .. name
end

---@param vfs_path string
---@param directory_path string
---@return boolean
local function is_inside( vfs_path, directory_path )
    return directory_path == "/" or string_sub( vfs_path, 1, string_len( directory_path ) + 1 ) == directory_path .. "/"
end

---@type table<string, dreamwork.vfs.Mount>
local mounts = {}

--- The names of files and directories.
---
---@type table<dreamwork.vfs.Node, string>
local node_names = {}
gc_setTableRules( node_names, true, false )

--- The parent directories, missing for the root or forgotten nodes.
---
--- Values are weak, parents are kept alive by their own parents up to the root.
---
---@type table<dreamwork.vfs.Node, dreamwork.vfs.Node>
local node_parents = {}
gc_setTableRules( node_parents, true, true )

--- The mounts that provide nodes, missing for virtual directories.
---
--- Values are weak, mounts are kept alive by `mounts`,
--- a strong value would keep the mount root alive forever through `mount.node`.
---
---@type table<dreamwork.vfs.Node, dreamwork.vfs.Mount>
local node_mounts = {}
gc_setTableRules( node_mounts, true, true )

--- The paths inside of the search path.
---
---@type table<dreamwork.vfs.Node, string>
local node_relative_paths = {}
gc_setTableRules( node_relative_paths, true, false )

--- The cached children of directories, files have none.
---
---@type table<dreamwork.vfs.Node, table<string, dreamwork.vfs.Node>>
local node_children = {}
gc_setTableRules( node_children, true, false )

--- The mount roots and virtual directories attached to directories, they shadow the search path.
---
---@type table<dreamwork.vfs.Node, dreamwork.vfs.Node[]>
local node_overlays = {}
gc_setTableRules( node_overlays, true, false )

--- The creation time of virtual directories and mount roots.
---
---@type table<dreamwork.vfs.Node, integer>
local node_created = {}
gc_setTableRules( node_created, true, false )

--- A file or directory of the map.
---
---@class dreamwork.vfs.Node : dreamwork.std.Object
---@field __class dreamwork.vfs.NodeClass
local Node = class.base( "vfs.Node", true )

---@param name string
---@param mount dreamwork.vfs.Mount | nil
---@param relative_path string
---@param is_directory boolean
---@protected
function Node:__init( name, mount, relative_path, is_directory )
    node_names[ self ] = name
    node_mounts[ self ] = mount
    node_relative_paths[ self ] = relative_path

    if is_directory then
        node_children[ self ] = {}
    end
end

---@class dreamwork.vfs.NodeClass : dreamwork.vfs.Node, dreamwork.std.Class
---@field __base dreamwork.vfs.Node
---@overload fun( name: string, mount: dreamwork.vfs.Mount | nil, relative_path: string, is_directory: boolean ): dreamwork.vfs.Node
local NodeClass = class.create( Node )

--- The root directory, `/`.
local root = NodeClass( "", nil, "", true )
node_created[ root ] = time_now()

---@param node dreamwork.vfs.Node
---@return boolean
local function node_is_mount_root( node )
    local mount = node_mounts[ node ]
    return mount ~= nil and mount.node == node
end

---@param node dreamwork.vfs.Node
---@return string
local function node_path( node )
    if node == root then
        return "/"
    end

    local parent = node_parents[ node ]
    if parent == nil or parent == root then
        return "/" .. node_names[ node ]
    end

    return node_path( parent ) .. "/" .. node_names[ node ]
end

---@param parent dreamwork.vfs.Node
---@param node dreamwork.vfs.Node
local function attach( parent, node )
    node_parents[ node ] = parent
    node_children[ parent ][ node_names[ node ] ] = node

    if node_mounts[ node ] == nil or node_is_mount_root( node ) then
        local overlays = node_overlays[ parent ]
        if overlays == nil then
            node_overlays[ parent ] = { node }
        else
            overlays[ #overlays + 1 ] = node
        end
    end
end

---@param node dreamwork.vfs.Node
local function detach( node )
    local parent = node_parents[ node ]
    if parent == nil then
        return
    end

    node_parents[ node ] = nil

    local children, name = node_children[ parent ], node_names[ node ]
    if children[ name ] == node then
        children[ name ] = nil
    end

    local overlays = node_overlays[ parent ]
    if overlays ~= nil then
        table_removeByValue( overlays, node )
    end
end

--- Creates a node for a file or directory that exists in the mount of the parent directory.
---
---@param directory dreamwork.vfs.Node
---@param name string
---@param is_directory boolean | nil `nil` to check the search path.
---@return dreamwork.vfs.Node | nil
local function discover( directory, name, is_directory )
    local mount = node_mounts[ directory ]
    if mount == nil then
        return nil
    end

    local search_path = mount.search_path
    local relative_path = join_path( node_relative_paths[ directory ], name )

    if is_directory == nil then
        if not file_Exists( relative_path, search_path ) then
            return nil
        end

        is_directory = file_IsDir( relative_path, search_path )
    end

    local node = NodeClass( name, mount, relative_path, is_directory )
    attach( directory, node )
    return node
end

--- Returns the child by name, cached children are checked for being still alive.
---
---@param directory dreamwork.vfs.Node
---@param name string
---@return dreamwork.vfs.Node | nil
local function child_get( directory, name )
    if restricted_names[ name ] then
        return nil
    end

    local child = node_children[ directory ][ name ]
    if child ~= nil then
        local mount = node_mounts[ child ]
        if mount == nil or node_is_mount_root( child ) then
            return child
        end

        -- a file could be replaced by a directory and vice versa
        local search_path, relative_path = mount.search_path, node_relative_paths[ child ]
        if node_children[ child ] ~= nil then
            if file_IsDir( relative_path, search_path ) then
                return child
            end
        elseif file_Exists( relative_path, search_path ) and not file_IsDir( relative_path, search_path ) then
            return child
        end

        detach( child )
    end

    return discover( directory, name, nil )
end

---@param vfs_path string The absolute normalized path.
---@return dreamwork.vfs.Node | nil
local function lookup( vfs_path )
    if vfs_path == "/" then
        return root
    end

    local segments, segment_count = string_byteSplit( vfs_path, 0x2F --[[ / ]], 2 )
    local node = root

    for index = 1, segment_count, 1 do
        if node_children[ node ] == nil then
            return nil
        end

        local next_node = child_get( node, segments[ index ] )
        if next_node == nil then
            return nil
        end

        node = next_node
    end

    return node
end

--- Collects mounts nested in the directory, without descending into them.
---
---@param directory dreamwork.vfs.Node
---@param list dreamwork.vfs.Mount[]
---@param count integer
---@return integer count
local function collect_mounts( directory, list, count )
    for _, child in raw_pairs( node_children[ directory ] ) do
        if node_is_mount_root( child ) then
            count = count + 1
            list[ count ] = node_mounts[ child ]
        elseif node_children[ child ] ~= nil then
            count = collect_mounts( child, list, count )
        end
    end

    return count
end

--- Forgets virtual directories without anything inside, from the directory up.
---
---@param directory dreamwork.vfs.Node | nil
local function prune( directory )
    while directory ~= nil and directory ~= root and node_mounts[ directory ] == nil and raw_next( node_children[ directory ] ) == nil do
        local parent = node_parents[ directory ]
        detach( directory )
        directory = parent
    end
end

local attach_at

--- Places detached nested mounts back at their paths, mounts that do not fit anymore are dropped.
---
---@param nested dreamwork.vfs.Mount[]
---@param nested_count integer
local function reattach( nested, nested_count )
    for index = 1, nested_count, 1 do
        local mount = nested[ index ]
        detach( mount.node )

        if not attach_at( mount.path, mount.node ) then
            mounts[ mount.path ] = nil
            hook_call( "dreamwork.vfs.directory.mount", mount.path, mount.search_path, false )
        end
    end
end

--- Places the mount root at the path, creating virtual directories on the way.
---
---@param vfs_path string
---@param node dreamwork.vfs.Node
---@return boolean success
---@return string | nil message
function attach_at( vfs_path, node )
    local segments, segment_count = string_byteSplit( vfs_path, 0x2F --[[ / ]], 2 )
    local directory = root

    for index = 1, segment_count - 1, 1 do
        local name = segments[ index ]

        local child = child_get( directory, name )
        if child == nil then
            child = NodeClass( name, nil, "", true )
            node_created[ child ] = time_now()
            attach( directory, child )
        elseif node_children[ child ] == nil then
            prune( directory )
            return false, string_format( "'%s' is a file, nothing can be mounted inside it.", node_path( child ) )
        end

        directory = child
    end

    local existing = child_get( directory, node_names[ node ] )
    if existing == nil then
        attach( directory, node )
        return true
    end

    if node_is_mount_root( existing ) then
        return false, string_format( "'%s' is already mounted.", vfs_path )
    end

    if node_children[ existing ] == nil then
        prune( directory )
        return false, string_format( "'%s' is a file, it cannot be a mount point.", vfs_path )
    end

    -- mounts nested in the replaced directory stay at their paths
    local nested = {}
    local nested_count = collect_mounts( existing, nested, 0 )

    detach( existing )
    attach( directory, node )
    reattach( nested, nested_count )

    return true
end

---@param mount dreamwork.vfs.Mount
local function map_unmount( mount )
    local node = mount.node

    local nested = {}
    local nested_count = collect_mounts( node, nested, 0 )

    if node == root then
        node_mounts[ root ], node_relative_paths[ root ] = nil, ""
        node_children[ root ] = {}
        node_overlays[ root ] = nil
    else
        local parent = node_parents[ node ]
        detach( node )

        -- virtual directories without anything inside are not needed anymore
        prune( parent )
    end

    mounts[ mount.path ] = nil
    reattach( nested, nested_count )
end

---@param node dreamwork.vfs.Node
---@return dreamwork.vfs.Mount | nil mount
---@return string | nil message
local function writable_mount( node )
    local mount = node_mounts[ node ]
    if mount == nil or not mount.writable then
        return nil, string_format( "'%s' is read-only.", node_path( node ) )
    end

    return mount
end

---@param mount dreamwork.vfs.Mount
---@param file_name string
---@return boolean
local function is_allowed_extension( mount, file_name )
    local extensions = mount.extensions
    return extensions == nil or extensions[ string_lower( path_getExtension( file_name, false ) ) ] == true
end

---@param node dreamwork.vfs.Node
---@return boolean
local function is_writable( node )
    local mount = node_mounts[ node ]
    if mount == nil or not mount.writable then
        return false
    end

    return node_children[ node ] ~= nil or is_allowed_extension( mount, node_names[ node ] )
end

---@param search_path string
---@param relative_path string
---@param data string
---@param append_mode boolean
---@return boolean success
local function write_data( search_path, relative_path, data, append_mode )
    local handle = driver_Open( relative_path, append_mode and "ab" or "wb", search_path )
    if handle == nil then
        return false
    end

    handle:Write( data )
    handle:Close()

    return true
end

--- Writes the data into `DATA` with async_write or gm_asyncio, must be called from a coroutine.
---
--- Paths rejected by the driver are written synchronously, async_write allows fewer extensions than `DATA`.
---
---@param relative_path string
---@param data string
---@param append_mode boolean
---@return boolean success
---@async
local function write_data_async( relative_path, data, append_mode )
    local f = Future()

    local status = (append_mode and file_AsyncAppend or file_AsyncWrite)( relative_path, data, function( _, write_status )
        if f:isPending() then
            f:setResult( write_status )
        end
    end )

    -- async_write's `AsyncAppend` returns the last argument instead of the status, rejected paths are never called back
    if isNumber( status ) and status < 0 and f:isPending() then
        return write_data( "DATA", relative_path, data, append_mode )
    end

    return f:await() == 0
end

---@param node dreamwork.vfs.Node
---@return string | nil data
---@return string | nil message
local function read_node( node )
    local handle = driver_Open( node_relative_paths[ node ], "rb", node_mounts[ node ].search_path )
    if handle == nil then
        return nil, string_format( "'%s' could not be opened for reading.", node_path( node ) )
    end

    local data = handle:Read( handle:Size() ) or ""
    handle:Close()

    return data
end

--- Reads the file asynchronously where possible, must be called from a coroutine.
---
---@param node dreamwork.vfs.Node
---@return string | nil data
---@return string | nil message
---@async
local function read_node_async( node )
    if file_AsyncRead == nil then
        return read_node( node )
    end

    local f = Future()

    local status = file_AsyncRead( node_relative_paths[ node ], node_mounts[ node ].search_path, function( _, _, read_status, data )
        if f:isPending() then
            f:setResult( read_status == 0 and (data or "") or read_status )
        end
    end, false )

    if status < 0 and f:isPending() then
        f:setResult( status )
    end

    local result = f:await()
    if isString( result ) then
        return result
    end

    return nil, string_format( "'%s' could not be read, status %d.", node_path( node ), result )
end

--- Reports the change made by `vfs` right away, file systems do not always update the modification time.
---
---@type fun( event_name: string, vfs_path: string, is_directory: boolean )
local watchdog_change

--- Mounts the search path at the absolute virtual path.
---
---@type fun( mount_path: string, search_path: string, search_directory: string | nil, writable: boolean | nil, deletable: boolean | nil ): boolean, string | nil
local mount_search_path

--- Unmounts the absolute virtual path, `false` if nothing is mounted there.
---
---@type fun( mount_path: string ): boolean
local unmount_path

---@param parent dreamwork.vfs.Node
---@param name string
---@return dreamwork.vfs.Node | nil directory
---@return string | nil message
local function make_directory( parent, name )
    local message = check_name( name )
    if message ~= nil then
        return nil, message
    end

    local mount
    mount, message = writable_mount( parent )
    if mount == nil then
        return nil, message
    end

    local search_path, relative_path = mount.search_path, join_path( node_relative_paths[ parent ], name )

    driver_CreateDir( relative_path, search_path )

    if not file_IsDir( relative_path, search_path ) then
        return nil, string_format( "directory '%s' could not be created in '%s'.", name, node_path( parent ) )
    end

    local directory = discover( parent, name, true )
    if directory ~= nil then
        watchdog_change( "dreamwork.vfs.created", node_path( directory ), true )
    end

    return directory
end

--- Walks the absolute path, creating missing directories.
---
---@param vfs_path string
---@return dreamwork.vfs.Node | nil directory
---@return string | nil message
local function make_directory_chain( vfs_path )
    if vfs_path == "/" then
        return root
    end

    local segments, segment_count = string_byteSplit( vfs_path, 0x2F --[[ / ]], 2 )
    local directory = root

    for index = 1, segment_count, 1 do
        local name = segments[ index ]

        local child = child_get( directory, name )
        if child == nil then
            local message
            child, message = make_directory( directory, name )

            if child == nil then
                return nil, message
            end
        elseif node_children[ child ] == nil then
            return nil, string_format( "'%s' is a file.", node_path( child ) )
        end

        directory = child
    end

    return directory
end

--- Writes the file, missing directories are created.
---
---@param vfs_path string
---@param data string
---@param append_mode boolean
---@param async? boolean `true` to write with gm_asyncio where possible, must be called from a coroutine then.
---@return boolean success
---@return string | nil message
local function write_file( vfs_path, data, append_mode, async )
    local directory_path, name = path_split( vfs_path, false )

    local message = check_name( name )
    if message ~= nil then
        return false, message
    end

    local directory
    directory, message = make_directory_chain( directory_path )
    if directory == nil then
        return false, message
    end

    local node = child_get( directory, name )
    if node ~= nil and node_children[ node ] ~= nil then
        return false, string_format( "'%s' is a directory.", vfs_path )
    end

    local mount
    mount, message = writable_mount( directory )
    if mount == nil then
        return false, message
    end

    if not is_allowed_extension( mount, name ) then
        return false, string_format( "'%s' cannot be written, extension is not allowed by '%s'.", vfs_path, mount.search_path )
    end

    local search_path, relative_path = mount.search_path, join_path( node_relative_paths[ directory ], name )

    if async and search_path == "DATA" and file_AsyncWrite ~= nil then
        if not write_data_async( relative_path, data, append_mode ) then
            return false, string_format( "'%s' could not be written.", vfs_path )
        end
    elseif not write_data( search_path, relative_path, data, append_mode ) then
        return false, string_format( "'%s' could not be opened for writing.", vfs_path )
    end

    -- the file could be discovered by someone else while the write was awaited
    local children = node_children[ directory ]
    if children ~= nil and children[ name ] == nil then
        discover( directory, name, false )
    end

    if node == nil then
        watchdog_change( "dreamwork.vfs.created", vfs_path, false )
    else
        watchdog_change( "dreamwork.vfs.modified", vfs_path, false )
    end

    return true
end

--- Updates the modification time of the existing file without changing its content, like `touch` does.
---
---@param node dreamwork.vfs.Node
---@return boolean success
---@return string | nil message
local function touch_file_node( node )
    local mount, message = writable_mount( node_parents[ node ] )
    if mount == nil then
        return false, message
    end

    local vfs_path = node_path( node )
    if not is_allowed_extension( mount, node_names[ node ] ) then
        return false, string_format( "'%s' cannot be touched, extension is not allowed by '%s'.", vfs_path, mount.search_path )
    end

    local data
    data, message = read_node( node )
    if data == nil then
        return false, message
    end

    -- the file system has no way to set the time, rewriting the same content makes it current
    if not write_data( mount.search_path, node_relative_paths[ node ], data, false ) then
        return false, string_format( "'%s' could not be opened for writing.", vfs_path )
    end

    watchdog_change( "dreamwork.vfs.modified", vfs_path, false )
    return true
end

--- Updates the modification time of the existing directory, creating and deleting a temporary file inside of it.
---
---@param node dreamwork.vfs.Node
---@return boolean success
---@return string | nil message
local function touch_directory_node( node )
    local mount, message = writable_mount( node )
    if mount == nil then
        return false, message
    end

    local search_path, relative_path = mount.search_path, join_path( node_relative_paths[ node ], "^dreamwork_tmp$.dat" )

    if not write_data( search_path, relative_path, "", false ) then
        return false, string_format( "'%s' cannot be touched, temporary file could not be created.", node_path( node ) )
    end

    driver_Delete( relative_path, search_path )

    watchdog_change( "dreamwork.vfs.modified", node_path( node ), true )
    return true
end

--- Deletes the directory with everything in it from the search path.
---
---@param search_path string
---@param relative_path string
local function delete_tree( search_path, relative_path )
    local files, directories = driver_Find( join_path( relative_path, "*" ), search_path )

    if files ~= nil then
        for index = 1, #files, 1 do
            driver_Delete( join_path( relative_path, files[ index ] ), search_path )
        end
    end

    if directories ~= nil then
        for index = 1, #directories, 1 do
            delete_tree( search_path, join_path( relative_path, directories[ index ] ) )
        end
    end

    driver_Delete( relative_path, search_path )
end

---@param node dreamwork.vfs.Node
---@return dreamwork.vfs.Mount | nil mount
---@return string | nil message
local function deletable_mount( node )
    if node_is_mount_root( node ) then
        return nil, string_format( "'%s' is a mount point, use `vfs.unmount` instead.", node_path( node ) )
    end

    local mount = node_mounts[ node ]
    if mount == nil then
        return nil, string_format( "'%s' is virtual and cannot be deleted.", node_path( node ) )
    end

    if not mount.deletable then
        return nil, string_format( "'%s' cannot be deleted, '%s' does not allow deleting.", node_path( node ), mount.search_path )
    end

    return mount
end

---@param node dreamwork.vfs.Node
---@param recursive boolean
---@return boolean success
---@return string | nil message
local function delete_node( node, recursive )
    local mount, message = deletable_mount( node )
    if mount == nil then
        return false, message
    end

    local search_path, relative_path = mount.search_path, node_relative_paths[ node ]

    if node_children[ node ] ~= nil then
        local files, directories = driver_Find( join_path( relative_path, "*" ), search_path )
        if (files ~= nil and files[ 1 ] ~= nil) or (directories ~= nil and directories[ 1 ] ~= nil) then
            if not recursive then
                return false, string_format( "'%s' is not empty.", node_path( node ) )
            end

            delete_tree( search_path, relative_path )
        end
    end

    driver_Delete( relative_path, search_path )

    local vfs_path = node_path( node )

    if file_Exists( relative_path, search_path ) then
        return false, string_format( "'%s' could not be deleted.", vfs_path )
    end

    if node_children[ node ] ~= nil then
        -- mounts nested in the deleted directory stay at their paths
        local nested = {}
        local nested_count = collect_mounts( node, nested, 0 )

        detach( node )
        reattach( nested, nested_count )
    else
        detach( node )
    end

    watchdog_change( "dreamwork.vfs.deleted", vfs_path, node_children[ node ] ~= nil )
    return true
end

---@param node dreamwork.vfs.Node
---@param getter fun( relative_path: string, search_path: string ): integer
---@return integer unix_time
local function node_time( node, getter )
    local mount = node_mounts[ node ]
    if mount ~= nil then
        local unix_time = getter( node_relative_paths[ node ], mount.search_path )
        if unix_time ~= nil and unix_time > 0 then
            return unix_time
        end
    end

    return node_created[ node ] or 0
end

do

    ---@type table<string, dreamwork.vfs.Watch>
    local watches = {}

    --- The watched paths in the order of checking.
    ---
    ---@type string[]
    local watch_list = {}

    ---@type integer
    local watch_count = 0

    ---@type integer
    local watch_index = 0

    --- The minimal delay between checks of the same path in seconds.
    local WATCH_INTERVAL = 1

    --- The maximal number of files checked per tick, a directory listing counts as one file.
    local WATCH_BUDGET = 16

    --- The watched directory which files are being checked, a few files per tick.
    ---
    ---@type dreamwork.vfs.Watch | nil
    local scan_watch

    ---@type string
    local scan_path = ""

    --- The index of the next file to check in the content of the scanned directory.
    ---
    ---@type integer
    local scan_index = 1

    --- The content of a path that is not a directory, used instead of `nil` to compare contents without nil checks.
    ---
    ---@type dreamwork.vfs.WatchContent
    local no_content = {
        count = 0,
        names = {},
        directories = {},
        times = {},
        sizes = {},
        indexes = {},
        relative_path = ""
    }

    --- The path of the change reported by `vfs` right now, the watchdog does not report it again.
    ---
    ---@type string | nil
    local reported_path

    ---@param event_name string
    ---@param vfs_path string
    ---@param is_directory boolean
    local function watch_report( event_name, vfs_path, is_directory )
        if vfs_path ~= reported_path then
            hook_call( event_name, vfs_path, is_directory )
        end
    end

    --- Lists the directory content, files keep the times and sizes of the old content and new files are not checked yet.
    ---
    ---@param directory dreamwork.vfs.Node
    ---@param old_content dreamwork.vfs.WatchContent | nil
    ---@return dreamwork.vfs.WatchContent content
    local function list_directory( directory, old_content )
        ---@type string[]
        local names = {}

        ---@type boolean[]
        local directories = {}

        ---@type integer[]
        local times = {}

        ---@type integer[]
        local sizes = {}

        ---@type table<string, integer>
        local indexes = {}

        local count = 0

        -- mount roots and virtual directories go first, they shadow the search path
        local overlays = node_overlays[ directory ]
        if overlays ~= nil then
            for index = 1, #overlays, 1 do
                local name = node_names[ overlays[ index ] ]
                count = count + 1

                names[ count ], directories[ count ] = name, true
                times[ count ], sizes[ count ] = 0, 0

                indexes[ name ] = count
            end
        end

        local mount = node_mounts[ directory ]
        local relative_path = node_relative_paths[ directory ]

        ---@type string | nil
        local search_path

        if mount ~= nil then
            search_path = mount.search_path

            local files, folders = driver_Find( join_path( relative_path, "*" ), search_path )

            if files ~= nil then
                local previous = old_content or no_content
                local old_indexes, old_directories, old_times, old_sizes = previous.indexes, previous.directories, previous.times, previous.sizes

                for index = 1, #files, 1 do
                    local name = files[ index ]
                    if indexes[ name ] == nil and not restricted_names[ name ] then
                        count = count + 1
                        names[ count ], directories[ count ] = name, false

                        local old_index = old_indexes[ name ]
                        if old_index == nil or old_directories[ old_index ] then
                            times[ count ], sizes[ count ] = -1, -1
                        else
                            times[ count ], sizes[ count ] = old_times[ old_index ], old_sizes[ old_index ]
                        end

                        indexes[ name ] = count
                    end
                end
            end

            if folders ~= nil then
                for index = 1, #folders, 1 do
                    local name = folders[ index ]
                    if indexes[ name ] == nil and not restricted_names[ name ] then
                        count = count + 1

                        names[ count ], directories[ count ] = name, true
                        times[ count ], sizes[ count ] = 0, 0

                        indexes[ name ] = count
                    end
                end
            end
        end

        return {
            count = count,
            names = names,
            directories = directories,
            times = times,
            sizes = sizes,
            indexes = indexes,
            search_path = search_path,
            relative_path = relative_path
        }
    end

    --- Checks the file of the directory content, the first check only remembers the time and size.
    ---
    ---@param vfs_path string The path of the directory.
    ---@param content dreamwork.vfs.WatchContent
    ---@param index integer
    ---@return boolean is_checked `true` if the file was checked, `false` for directories.
    local function check_child( vfs_path, content, index )
        if content.directories[ index ] then
            return false
        end

        local name, search_path = content.names[ index ], content.search_path
        local file_path = join_path( content.relative_path, name )

        local file_time = driver_Time( file_path, search_path ) or 0
        if file_time == 0 then
            -- deleted after the listing, the next listing reports it
            return true
        end

        local file_size = driver_Size( file_path, search_path ) or 0

        local times, sizes = content.times, content.sizes
        local old_time, old_size = times[ index ], sizes[ index ]
        times[ index ], sizes[ index ] = file_time, file_size

        if old_time ~= -1 and (file_time ~= old_time or file_size ~= old_size) then
            local child_vfs_path = child_path( vfs_path, name )

            -- watched children report changes by themselves
            if watches[ child_vfs_path ] == nil then
                watch_report( "dreamwork.vfs.modified", child_vfs_path, false )
            end
        end

        return true
    end

    --- Reports files and directories of the old content that were deleted or replaced.
    ---
    --- Watched children report changes by themselves.
    ---
    ---@param vfs_path string
    ---@param old_content dreamwork.vfs.WatchContent
    ---@param content dreamwork.vfs.WatchContent | nil `nil` if the path is not a directory anymore.
    local function report_old_children( vfs_path, old_content, content )
        local old_names, old_directories = old_content.names, old_content.directories

        local current = content or no_content
        local new_indexes, new_directories = current.indexes, current.directories

        for index = 1, old_content.count, 1 do
            local child_is_directory = old_directories[ index ]
            local new_index = new_indexes[ old_names[ index ] ]

            if new_index == nil or new_directories[ new_index ] ~= child_is_directory then
                local child_vfs_path = child_path( vfs_path, old_names[ index ] )
                if watches[ child_vfs_path ] == nil then
                    watch_report( "dreamwork.vfs.deleted", child_vfs_path, child_is_directory )
                end
            end
        end
    end

    --- Reports files and directories of the new content that were created.
    ---
    --- Watched children report changes by themselves.
    ---
    ---@param vfs_path string
    ---@param content dreamwork.vfs.WatchContent
    ---@param old_content dreamwork.vfs.WatchContent | nil `nil` if the path was not a directory.
    local function report_new_children( vfs_path, content, old_content )
        local names, directories = content.names, content.directories

        local previous = old_content or no_content
        local old_indexes, old_directories = previous.indexes, previous.directories

        for index = 1, content.count, 1 do
            local child_is_directory = directories[ index ]
            local old_index = old_indexes[ names[ index ] ]

            if old_index == nil or old_directories[ old_index ] ~= child_is_directory then
                local child_vfs_path = child_path( vfs_path, names[ index ] )
                if watches[ child_vfs_path ] == nil then
                    watch_report( "dreamwork.vfs.created", child_vfs_path, child_is_directory )
                end
            end
        end
    end

    --- Checks the watched path that is a file or does not exist.
    ---
    ---@param vfs_path string
    ---@param watch dreamwork.vfs.Watch
    ---@param node dreamwork.vfs.Node | nil The file, `nil` if the path does not exist.
    ---@param silent boolean `true` to take the snapshot without events.
    local function watch_update_file( vfs_path, watch, node, silent )
        local exists = node ~= nil
        local file_time, file_size = 0, 0

        if exists then
            local search_path, relative_path = node_mounts[ node ].search_path, node_relative_paths[ node ]
            file_time, file_size = driver_Time( relative_path, search_path ) or 0, driver_Size( relative_path, search_path ) or 0
        end

        local was_existing, was_directory = watch.exists, watch.is_directory
        local old_time, old_size = watch.time, watch.size
        local old_content = watch.content

        -- the snapshot is replaced before events, handlers can change the path again
        watch.exists, watch.is_directory = exists, false
        watch.time, watch.size = file_time, file_size
        watch.content = nil

        watch.checked = dreamwork_getUpTime()

        if silent then
            return
        end

        if old_content ~= nil then
            report_old_children( vfs_path, old_content, nil )
        end

        if was_existing ~= exists or was_directory then
            if was_existing then
                watch_report( "dreamwork.vfs.deleted", vfs_path, was_directory )
            end

            if exists then
                watch_report( "dreamwork.vfs.created", vfs_path, false )
            end
        elseif exists and (file_time ~= old_time or file_size ~= old_size) then
            watch_report( "dreamwork.vfs.modified", vfs_path, false )
        end
    end

    --- Lists the watched path that is a directory, files of it are checked later by the scan.
    ---
    ---@param vfs_path string
    ---@param watch dreamwork.vfs.Watch
    ---@param node dreamwork.vfs.Node The directory.
    ---@param silent boolean `true` to take the snapshot without events.
    local function watch_update_directory( vfs_path, watch, node, silent )
        local was_existing, was_directory = watch.exists, watch.is_directory
        local old_content = watch.content

        local content = list_directory( node, old_content )

        -- the snapshot is replaced before events, handlers can change the path again
        watch.exists, watch.is_directory = true, true
        watch.time, watch.size = 0, 0
        watch.content = content
        watch.checked = dreamwork_getUpTime()

        if silent then
            return
        end

        if old_content ~= nil then
            report_old_children( vfs_path, old_content, content )
        end

        if not was_directory then
            if was_existing then
                watch_report( "dreamwork.vfs.deleted", vfs_path, false )
            end

            watch_report( "dreamwork.vfs.created", vfs_path, true )
        end

        report_new_children( vfs_path, content, old_content )
    end

    --- Checks the watched path.
    ---
    ---@param vfs_path string
    ---@param watch dreamwork.vfs.Watch
    ---@param silent boolean `true` to take the snapshot without events.
    local function watch_update( vfs_path, watch, silent )
        local node = lookup( vfs_path )
        if node ~= nil and node_children[ node ] ~= nil then
            watch_update_directory( vfs_path, watch, node, silent )
        else
            watch_update_file( vfs_path, watch, node, silent )
        end

        -- the content was replaced, the scan starts over
        if watch == scan_watch then
            scan_index = 1
        end
    end

    function watchdog_change( event_name, vfs_path, is_directory )
        if watch_count ~= 0 then
            -- event handlers can make changes too, the outer path is restored after them
            local previous_path = reported_path
            reported_path = vfs_path

            local watch = watches[ vfs_path ]
            if watch ~= nil then
                watch_update( vfs_path, watch, false )
            end

            if vfs_path ~= "/" then
                local directory_path, name = path_split( vfs_path, false )

                watch = watches[ directory_path ]
                if watch ~= nil then
                    watch_update( directory_path, watch, false )

                    -- the time and size of the changed file are taken right away, so the scan does not report it again
                    local content = watch.content
                    if content ~= nil then
                        local index = content.indexes[ name ]
                        if index ~= nil then
                            check_child( directory_path, content, index )
                        end
                    end
                end
            end

            reported_path = previous_path
        end

        hook_call( event_name, vfs_path, is_directory )
    end

    --- Reports changes of a mount, virtual directories can be created or pruned anywhere on the way to it.
    ---
    ---@param mount_path string
    ---@param is_mounted boolean `true` to check from the root down, `false` from the mount path up.
    local function watchdog_refresh_mount( mount_path, is_mounted )
        if watch_count == 0 then
            return
        end

        ---@type string[]
        local chain = { mount_path }
        local chain_length = 1

        while mount_path ~= "/" do
            mount_path = path_split( mount_path, false )

            chain_length = chain_length + 1
            chain[ chain_length ] = mount_path
        end

        local start, stop, step = 1, chain_length, 1
        if is_mounted then
            start, stop, step = chain_length, 1, -1
        end

        for index = start, stop, step do
            local vfs_path = chain[ index ]

            local watch = watches[ vfs_path ]
            if watch ~= nil then
                watch_update( vfs_path, watch, false )
            end
        end
    end

    hook_catch( "Tick", "dreamwork.vfs.watchdog", function()
        if watch_count == 0 then return end

        -- the scanned directory could be unwatched by an event handler
        if scan_watch ~= nil and watches[ scan_path ] ~= scan_watch then
            scan_watch = nil
        end

        local uptime = dreamwork_getUpTime()
        local budget = WATCH_BUDGET

        --- The number of watches in a row that are not due yet.
        local skipped = 0

        while budget > 0 do
            if scan_watch == nil then
                if skipped >= watch_count then
                    break
                end

                watch_index = (watch_index % watch_count) + 1

                local vfs_path = watch_list[ watch_index ]
                local watch = watches[ vfs_path ]

                if (uptime - watch.checked) < WATCH_INTERVAL then
                    skipped = skipped + 1
                else
                    skipped = 0
                    budget = budget - 1

                    watch_update( vfs_path, watch, false )

                    if watch.content ~= nil and watches[ vfs_path ] == watch then
                        scan_watch, scan_path, scan_index = watch, vfs_path, 1
                    end
                end
            else
                local content = scan_watch.content
                if content == nil or scan_index > content.count then
                    scan_watch = nil
                else
                    local index = scan_index
                    scan_index = index + 1

                    if check_child( scan_path, content, index ) then
                        budget = budget - 1
                    end
                end
            end
        end
    end )

    --- [SHARED AND MENU]
    ---
    --- Starts watching a file or directory.
    ---
    --- Changes are reported by `dreamwork.vfs.created`, `dreamwork.vfs.deleted` and `dreamwork.vfs.modified`
    --- engine events with the virtual path and `is_directory` arguments.
    ---
    --- Changes made through `vfs` are always reported right away, watching is needed only for changes made by anything else,
    --- they are found by listing directories and checking modification times and sizes of a few files per tick.
    ---
    --- Directories are watched without descending into subdirectories, a missing path is reported once it is created.
    ---
    --- Every `vfs.watch` call must be paired with a `vfs.unwatch` call.
    ---
    --- ```lua
    --- dreamwork.vfs.watch( "/garrysmod/data/my_addon" )
    ---
    --- dreamwork.engine.hookCatch( "dreamwork.vfs.created", "my_addon", function( vfs_path, is_directory )
    ---     print( vfs_path, is_directory )
    --- end )
    --- ```
    ---
    ---@param path_to string The path to the file or directory.
    ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
    function vfs.watch( path_to, stack_level )
        local vfs_path = path_resolve( path_to, (stack_level or 1) + 1 )

        local watch = watches[ vfs_path ]
        if watch == nil then
            ---@type dreamwork.vfs.Watch
            watch = {
                count = 0,
                exists = false,
                is_directory = false,
                time = 0,
                size = 0,
                checked = 0
            }

            watch_update( vfs_path, watch, true )

            watches[ vfs_path ] = watch

            watch_count = watch_count + 1
            watch_list[ watch_count ] = vfs_path
        end

        watch.count = watch.count + 1
    end

    --- [SHARED AND MENU]
    ---
    --- Stops watching a file or directory, fails if it is not watched.
    ---
    ---@param path_to string The path to the file or directory.
    ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
    function vfs.unwatch( path_to, stack_level )
        stack_level = (stack_level or 1) + 1

        local vfs_path = path_resolve( path_to, stack_level )

        local watch = watches[ vfs_path ]
        if watch == nil then
            error( string_format( "'%s' is not watched.", vfs_path ), stack_level )
        end

        local count = watch.count - 1
        if count == 0 then
            watches[ vfs_path ] = nil

            table_removeByValue( watch_list, vfs_path, watch_count )
            watch_count = watch_count - 1
        else
            watch.count = count
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if changes of a file or directory are reported, by watching it or its parent directory.
    ---
    ---@param path_to string The path to the file or directory.
    ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
    ---@return boolean is_watched `true` if the path is watched, `false` otherwise.
    ---@nodiscard
    function vfs.isWatched( path_to, stack_level )
        local vfs_path = path_resolve( path_to, (stack_level or 1) + 1 )

        if watches[ vfs_path ] ~= nil then
            return true
        end

        return vfs_path ~= "/" and watches[ path_split( vfs_path, false ) ] ~= nil
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the number of `vfs.watch` calls without `vfs.unwatch` for a file or directory, watches of its parent directory are not counted.
    ---
    ---@param path_to string The path to the file or directory.
    ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
    ---@return integer count The number of watches, `0` if the path is not watched.
    ---@nodiscard
    function vfs.getWatchCount( path_to, stack_level )
        local watch = watches[ path_resolve( path_to, (stack_level or 1) + 1 ) ]
        if watch == nil then
            return 0
        end

        return watch.count
    end

    do

        ---@type dreamwork.vfs.MountInfo
        local default_info = {
            writable = false,
            deletable = false
        }

        --- [SHARED AND MENU]
        ---
        --- Mounts the search path into the virtual file system.
        ---
        --- Missing directories on the way to the mount point are created as virtual directories,
        --- an existing directory at the mount point is replaced, mounts nested in it are kept.
        ---
        --- ```lua
        --- dreamwork.vfs.mount( "/hl2", "hl2" )
        --- dreamwork.vfs.mount( "/packages/my_package", "DATA", "packages/my_package" )
        --- ```
        ---
        ---@param mount_path string The absolute virtual path of the mount.
        ---@param search_path string The [search path](https://wiki.facepunch.com/gmod/File_Search_Paths), e.g. `MOD`, `DATA`, `hl2` or an addon title.
        ---@param search_directory? string The directory inside of the search path, its root by default.
        ---@param writable? boolean If `true`, files and directories can be created and written, defaults depend on the search path. Writing anywhere except `DATA` requires HolyLib.
        ---@param deletable? boolean If `true`, files and directories can be deleted, defaults depend on the search path.
        ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
        function vfs.mount( mount_path, search_path, search_directory, writable, deletable, stack_level )
            stack_level = (stack_level or 1) + 1

            if string_byte( search_path, 1, 1 ) == nil then
                error( "search path must be a non-empty string", stack_level )
            end

            local success, message = mount_search_path( path_resolve( mount_path, stack_level ), search_path, search_directory, writable, deletable )
            if not success then
                error( message, stack_level )
            end
        end

        function mount_search_path( mount_path, search_path, search_directory, writable, deletable )
            if mounts[ mount_path ] ~= nil then
                return false, string_format( "'%s' is already mounted.", mount_path )
            end

            if search_directory == nil then
                search_directory = ""
            else
                search_directory = path_stripLeadingSlash( path_normalize( search_directory, false ) )

                if search_directory == "." then
                    search_directory = ""
                elseif search_directory ~= "" and not file_IsDir( search_directory, search_path ) then
                    return false, string_format( "directory '%s' does not exist in '%s'.", search_directory, search_path )
                end
            end

            local info = engine_mounts[ search_path ] or default_info

            if writable == nil then
                writable = info.writable
            elseif writable and not has_filesystem and search_path ~= "DATA" then
                return false, string_format( "'%s' cannot be writable, writing into '%s' requires HolyLib.", mount_path, search_path )
            end

            if deletable == nil then
                deletable = info.deletable
            end

            ---@type dreamwork.vfs.Mount
            ---@diagnostic disable-next-line: missing-fields
            local mount = {
                path = mount_path,
                search_path = search_path,
                search_directory = search_directory,
                writable = writable == true,
                deletable = deletable == true,
                extensions = info.extensions
            }

            if mount_path == "/" then
                node_mounts[ root ], node_relative_paths[ root ] = mount, search_directory
                mount.node = root
            else
                local _, name = path_split( mount_path, false )

                local message = check_name( name )
                if message ~= nil then
                    return false, message
                end

                local node = NodeClass( name, mount, search_directory, true )
                node_created[ node ] = time_now()
                mount.node = node

                local success
                success, message = attach_at( mount_path, node )
                if not success then
                    return false, message
                end
            end

            mounts[ mount_path ] = mount
            hook_call( "dreamwork.vfs.directory.mount", mount_path, search_path, true )
            watchdog_refresh_mount( mount_path, true )

            return true
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Unmounts the search path from the virtual file system.
    ---
    --- Only access is removed, the search path stays mounted in the engine.
    ---
    --- Mounts nested in the unmounted directory are kept at their paths.
    ---
    --- Fails if nothing is mounted at the path.
    ---
    ---@param mount_path string The absolute virtual path of the mount.
    ---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
    function vfs.unmount( mount_path, stack_level )
        stack_level = (stack_level or 1) + 1

        mount_path = path_resolve( mount_path, stack_level )

        if not unmount_path( mount_path ) then
            error( string_format( "'%s' is not mounted.", mount_path ), stack_level )
        end
    end

    function unmount_path( mount_path )
        local mount = mounts[ mount_path ]
        if mount == nil then
            return false
        end

        map_unmount( mount )
        hook_call( "dreamwork.vfs.directory.mount", mount.path, mount.search_path, false )
        watchdog_refresh_mount( mount.path, false )

        return true
    end

end

---@param vfs_path string
---@return dreamwork.vfs.Node | nil node
---@return string | nil message
local function file_lookup( vfs_path )
    local node = lookup( vfs_path )
    if node == nil then
        return nil, string_format( "file '%s' does not exist.", vfs_path )
    end

    if node_children[ node ] ~= nil then
        return nil, string_format( "'%s' is a directory.", vfs_path )
    end

    return node
end

---@param vfs_path string
---@return dreamwork.vfs.Node | nil node
---@return string | nil message
local function directory_lookup( vfs_path )
    local node = lookup( vfs_path )
    if node == nil then
        return nil, string_format( "directory '%s' does not exist.", vfs_path )
    end

    if node_children[ node ] == nil then
        return nil, string_format( "'%s' is a file.", vfs_path )
    end

    return node
end

--- Lists the directory, mount roots and virtual directories shadow the search path.
---
---@param directory dreamwork.vfs.Node
---@param pattern? string Lua pattern names must match, `nil` lists everything.
---@return string[] names
---@return boolean[] directories
---@return integer count
local function list_children( directory, pattern )
    ---@type string[]
    local names = {}

    ---@type boolean[]
    local directories = {}

    ---@type table<string, boolean>
    local listed = {}

    local count = 0

    local overlays = node_overlays[ directory ]
    if overlays ~= nil then
        for index = 1, #overlays, 1 do
            local name = node_names[ overlays[ index ] ]
            listed[ name ] = true

            if pattern == nil or string_match( name, pattern ) ~= nil then
                count = count + 1
                names[ count ], directories[ count ] = name, true
            end
        end
    end

    local mount = node_mounts[ directory ]
    if mount ~= nil then
        local files, folders = driver_Find( join_path( node_relative_paths[ directory ], "*" ), mount.search_path )

        for pass = 1, 2, 1 do
            local list = pass == 1 and files or folders
            if list ~= nil then
                local is_directory = pass == 2

                for index = 1, #list, 1 do
                    local name = list[ index ]
                    if not listed[ name ] and not restricted_names[ name ] and (pattern == nil or string_match( name, pattern ) ~= nil) then
                        count = count + 1
                        names[ count ], directories[ count ] = name, is_directory
                        listed[ name ] = true
                    end
                end
            end
        end
    end

    return names, directories, count
end

--- Returns the size of the file, or the total size of everything in the directory.
---
---@param node dreamwork.vfs.Node
---@return integer size
local function node_size( node )
    if node_children[ node ] == nil then
        local size = driver_Size( node_relative_paths[ node ], node_mounts[ node ].search_path )
        if size == nil or size < 0 then
            return 0
        end

        return size
    end

    local names, _, count = list_children( node )
    local size = 0

    for index = 1, count, 1 do
        local child = child_get( node, names[ index ] )
        if child ~= nil then
            size = size + node_size( child )
        end
    end

    return size
end

--- Copies the file or the directory with everything in it, existing files are overwritten.
---
---@param node dreamwork.vfs.Node
---@param target_path string
---@param async boolean `true` to read and write asynchronously where possible, must be called from a coroutine then.
---@return boolean success
---@return string | nil message
local function copy_node( node, target_path, async )
    if node_children[ node ] == nil then
        local data, message

        if async then
            data, message = read_node_async( node )
        else
            data, message = read_node( node )
        end

        if data == nil then
            return false, message
        end

        return write_file( target_path, data, false, async )
    end

    local directory, message = make_directory_chain( target_path )
    if directory == nil then
        return false, message
    end

    local names, _, count = list_children( node )

    for index = 1, count, 1 do
        local name = names[ index ]

        -- the child could be deleted while the copy was awaited
        local child = child_get( node, name )
        if child ~= nil then
            local success
            success, message = copy_node( child, child_path( target_path, name ), async )

            if not success then
                return false, message
            end
        end
    end

    return true
end

--- Checks the source and the target of a copy or a move.
---
---@param source_path string
---@param target_path string
---@param overwrite boolean
---@param is_directory boolean
---@return dreamwork.vfs.Node | nil source
---@return dreamwork.vfs.Node | nil target The existing target.
---@return string | nil message
local function transfer_lookup( source_path, target_path, overwrite, is_directory )
    local source, message

    if is_directory then
        source, message = directory_lookup( source_path )
    else
        source, message = file_lookup( source_path )
    end

    if source == nil then
        return nil, nil, message
    end

    if source_path == target_path then
        return nil, nil, string_format( "'%s' cannot be copied or moved into itself.", source_path )
    end

    if is_directory and is_inside( target_path, source_path ) then
        return nil, nil, string_format( "'%s' cannot be copied or moved inside itself.", source_path )
    end

    local target = lookup( target_path )
    if target == nil then
        return source, nil
    end

    if not overwrite then
        return nil, nil, string_format( "'%s' already exists.", target_path )
    end

    if node_children[ target ] == nil then
        if is_directory then
            return nil, nil, string_format( "'%s' is a file.", target_path )
        end
    elseif not is_directory then
        return nil, nil, string_format( "'%s' is a directory.", target_path )
    end

    return source, target
end

---@param source_path string
---@param target_path string
---@param overwrite boolean
---@param is_directory boolean
---@param async boolean
---@return boolean success
---@return string | nil message
local function copy( source_path, target_path, overwrite, is_directory, async )
    local source, _, message = transfer_lookup( source_path, target_path, overwrite, is_directory )
    if source == nil then
        return false, message
    end

    return copy_node( source, target_path, async )
end

--- Moves the file or the directory, renames it in the search path if possible, otherwise copies and deletes it.
---
---@param source_path string
---@param target_path string
---@param overwrite boolean
---@param is_directory boolean
---@param async boolean
---@return boolean success
---@return string | nil message
local function move( source_path, target_path, overwrite, is_directory, async )
    local source, target, message = transfer_lookup( source_path, target_path, overwrite, is_directory )
    if source == nil then
        return false, message
    end

    local mount
    mount, message = deletable_mount( source )
    if mount == nil then
        return false, message
    end

    local directory_path, name = path_split( target_path, false )

    message = check_name( name )
    if message ~= nil then
        return false, message
    end

    local directory
    directory, message = make_directory_chain( directory_path )
    if directory == nil then
        return false, message
    end

    local search_path = mount.search_path
    local target_mount = node_mounts[ directory ]

    -- directories are merged into an existing one by copying
    if driver_Rename ~= nil and target_mount ~= nil and target_mount.writable and target_mount.search_path == search_path
        and (is_directory or is_allowed_extension( target_mount, name )) and (target == nil or not is_directory) then

        if target ~= nil then
            local success
            success, message = delete_node( target, false )

            if not success then
                return false, message
            end
        end

        local relative_path, new_relative_path = node_relative_paths[ source ], join_path( node_relative_paths[ directory ], name )
        driver_Rename( relative_path, new_relative_path, search_path )

        if file_Exists( new_relative_path, search_path ) and not file_Exists( relative_path, search_path ) then
            if is_directory then
                -- mounts nested in the moved directory stay at their paths
                local nested = {}
                local nested_count = collect_mounts( source, nested, 0 )

                detach( source )
                reattach( nested, nested_count )
            else
                detach( source )
            end

            local children = node_children[ directory ]
            if children ~= nil and children[ name ] == nil then
                discover( directory, name, is_directory )
            end

            watchdog_change( "dreamwork.vfs.deleted", source_path, is_directory )
            watchdog_change( "dreamwork.vfs.created", target_path, is_directory )
            return true
        end
    end

    local success
    success, message = copy_node( source, target_path, async )

    if not success then
        return false, message
    end

    return delete_node( source, true )
end

--- [SHARED AND MENU]
---
--- Reads the whole file.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@return string data The file data.
---@nodiscard
function vfs.readFile( file_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local node, message = file_lookup( path_resolve( file_path, stack_level ) )
    if node == nil then
        error( message, stack_level )
    end

    local data
    data, message = read_node( node )
    if data == nil then
        error( message, stack_level )
    end

    return data
end

--- [SHARED AND MENU]
---
--- Reads the whole file asynchronously, must be called from a coroutine.
---
--- Falls back to a synchronous read where the engine has no asynchronous reading.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@return string data The file data.
---@nodiscard
---@async
function vfs.readFileAsync( file_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local node, message = file_lookup( path_resolve( file_path, stack_level ) )
    if node == nil then
        error( message, stack_level )
    end

    local data
    data, message = read_node_async( node )
    if data == nil then
        error( message, stack_level )
    end

    return data
end

--- [SHARED AND MENU]
---
--- Replaces the file data, the file and missing directories are created.
---
---@param file_path string The path to the file.
---@param data string The new data.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.writeFile( file_path, data, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = write_file( path_resolve( file_path, stack_level ), data, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Appends data to the end of the file, the file and missing directories are created.
---
---@param file_path string The path to the file.
---@param data string The data to append.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.appendFile( file_path, data, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = write_file( path_resolve( file_path, stack_level ), data, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Replaces the file data asynchronously, must be called from a coroutine.
---
--- Writes synchronously where neither async_write nor gm_asyncio is installed or the file is outside of `DATA`.
---
---@param file_path string The path to the file.
---@param data string The new data.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.writeFileAsync( file_path, data, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = write_file( path_resolve( file_path, stack_level ), data, false, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Appends data to the end of the file asynchronously, must be called from a coroutine.
---
--- Appends synchronously where neither async_write nor gm_asyncio is installed or the file is outside of `DATA`.
---
---@param file_path string The path to the file.
---@param data string The data to append.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.appendFileAsync( file_path, data, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = write_file( path_resolve( file_path, stack_level ), data, true, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Creates an empty file with missing directories, fails if the path already exists.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.createFile( file_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( file_path, stack_level )

    if lookup( vfs_path ) ~= nil then
        error( string_format( "'%s' already exists.", vfs_path ), stack_level )
    end

    local success, message = write_file( vfs_path, "", false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates an empty file with missing directories, or updates the modification time of an existing one keeping its content.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.touchFile( file_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( file_path, stack_level )

    local node = lookup( vfs_path )
    if node == nil then
        local success, message = write_file( vfs_path, "", false )
        if not success then
            error( message, stack_level )
        end

        return
    end

    if node_children[ node ] ~= nil then
        error( string_format( "'%s' is a directory.", vfs_path ), stack_level )
    end

    local success, message = touch_file_node( node )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Deletes the file.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.deleteFile( file_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local node, message = file_lookup( path_resolve( file_path, stack_level ) )
    if node == nil then
        error( message, stack_level )
    end

    local success
    success, message = delete_node( node, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Creates a directory with missing parent directories, an existing directory is kept as is, fails if the path is a file.
---
---@param directory_path string The path to the directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.createDirectory( directory_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local directory, message = make_directory_chain( path_resolve( directory_path, stack_level ) )
    if directory == nil then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates a directory with missing parent directories, or updates the modification time of an existing one.
---
---@param directory_path string The path to the directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.touchDirectory( directory_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( directory_path, stack_level )

    local existed = lookup( vfs_path ) ~= nil

    local directory, message = make_directory_chain( vfs_path )
    if directory == nil then
        error( message, stack_level )
    end

    if existed then
        local success
        success, message = touch_directory_node( directory )
        if not success then
            error( message, stack_level )
        end
    end
end

--- [SHARED AND MENU]
---
--- Deletes the directory.
---
---@param directory_path string The path to the directory.
---@param recursive? boolean If `true`, the directory is deleted with everything in it, otherwise it must be empty.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.deleteDirectory( directory_path, recursive, stack_level )
    stack_level = (stack_level or 1) + 1

    local node, message = directory_lookup( path_resolve( directory_path, stack_level ) )
    if node == nil then
        error( message, stack_level )
    end

    local success
    success, message = delete_node( node, recursive == true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the file, missing directories are created.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.copyFile( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the file, missing directories are created asynchronously, must be called from a coroutine.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.copyFileAsync( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the file, missing directories are created.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.moveFile( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the file, missing directories are created asynchronously, must be called from a coroutine.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.moveFileAsync( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Renames the file, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
---@param file_path string The path to the file.
---@param name string The new name of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.renameFile( file_path, name, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( file_path, stack_level )

    local message = check_name( name )
    if message ~= nil then
        error( message, stack_level )
    end

    local success
    success, message = move( vfs_path, child_path( path_split( vfs_path, false ), name ), overwrite == true, false, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Renames the file asynchronously, must be called from a coroutine, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param file_path string The path to the file.
---@param name string The new name of the file.
---@param overwrite? boolean If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.renameFileAsync( file_path, name, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( file_path, stack_level )

    local message = check_name( name )
    if message ~= nil then
        error( message, stack_level )
    end

    local success
    success, message = move( vfs_path, child_path( path_split( vfs_path, false ), name ), overwrite == true, false, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the directory with everything in it, missing directories are created.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.copyDirectory( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the directory with everything in it, missing directories are created asynchronously, must be called from a coroutine.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.copyDirectoryAsync( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the directory with everything in it, missing directories are created.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.moveDirectory( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the directory with everything in it, missing directories are created asynchronously, must be called from a coroutine.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.moveDirectoryAsync( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Renames the directory, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
---@param directory_path string The path to the directory.
---@param name string The new name of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.renameDirectory( directory_path, name, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( directory_path, stack_level )

    local message = check_name( name )
    if message ~= nil then
        error( message, stack_level )
    end

    local success
    success, message = move( vfs_path, child_path( path_split( vfs_path, false ), name ), overwrite == true, true, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Renames the directory asynchronously, must be called from a coroutine, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param directory_path string The path to the directory.
---@param name string The new name of the directory.
---@param overwrite? boolean If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@async
function vfs.renameDirectoryAsync( directory_path, name, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( directory_path, stack_level )

    local message = check_name( name )
    if message ~= nil then
        error( message, stack_level )
    end

    local success
    success, message = move( vfs_path, child_path( path_split( vfs_path, false ), name ), overwrite == true, true, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean exists `true` if the file or directory exists, `false` otherwise.
---@return boolean is_directory `true` if it is a directory, `false` otherwise.
---@nodiscard
function vfs.isExists( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return false, false
    end

    return true, node_children[ node ] ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if a file exists.
---
---@param file_path string The path to the file.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_file `true` if the file exists, `false` otherwise.
---@nodiscard
function vfs.isFile( file_path, stack_level )
    local node = lookup( path_resolve( file_path, (stack_level or 1) + 1 ) )
    return node ~= nil and node_children[ node ] == nil
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists.
---
---@param directory_path string The path to the directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_directory `true` if the directory exists, `false` otherwise.
---@nodiscard
function vfs.isDirectory( directory_path, stack_level )
    local node = lookup( path_resolve( directory_path, (stack_level or 1) + 1 ) )
    return node ~= nil and node_children[ node ] ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if a file can be written, or files and directories can be created inside of a directory.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_writable `true` if writing is allowed, `false` otherwise or if the path does not exist.
---@nodiscard
function vfs.isWritable( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    return node ~= nil and is_writable( node )
end

--- [SHARED AND MENU]
---
--- Checks if a file can be opened for reading, or a directory exists.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_readable `true` if reading is allowed, `false` otherwise or if the path does not exist.
---@nodiscard
function vfs.isReadable( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return false
    end

    if node_children[ node ] ~= nil then
        return true
    end

    local handle = driver_Open( node_relative_paths[ node ], "rb", node_mounts[ node ].search_path )
    if handle == nil then
        return false
    end

    handle:Close()
    return true
end

--- [SHARED AND MENU]
---
--- Returns the information about the mount that provides a file or directory.
---
--- Virtual directories are created on the way to mount points and have no mount, their mount fields are `nil`.
---
--- ```lua
--- local info = dreamwork.vfs.getInfo( "/garrysmod/data/settings.txt" )
--- print( info.mount_path, info.search_path, info.relative_path ) -- "/garrysmod/data", "DATA", "settings.txt"
--- ```
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return dreamwork.vfs.Info | nil info The information, `nil` if the path does not exist.
---@nodiscard
function vfs.getInfo( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return nil
    end

    local mount = node_mounts[ node ]
    if mount == nil then
        ---@type dreamwork.vfs.Info
        return {
            is_virtual = true,
            is_mount_root = false,
            writable = false,
            deletable = false
        }
    end

    ---@type dreamwork.vfs.Info
    return {
        mount_path = mount.path,
        search_path = mount.search_path,
        search_directory = mount.search_directory,
        relative_path = node_relative_paths[ node ],
        is_virtual = false,
        is_mount_root = mount.node == node,
        writable = mount.writable,
        deletable = mount.deletable
    }
end

--- [SHARED AND MENU]
---
--- Returns the last access time of a file or directory.
---
--- Without HolyLib the last modification time is returned.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The last access time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeAccessed( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_TimeAccessed )
end

--- [SHARED AND MENU]
---
--- Returns the creation time of a file or directory.
---
--- Without HolyLib the last modification time is returned.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The creation time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeCreated( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_TimeCreated )
end

--- [SHARED AND MENU]
---
--- Returns the last modification time of a file or directory.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The last modification time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeModified( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_Time )
end

--- [SHARED AND MENU]
---
--- Returns the size of a file, or the total size of everything in a directory, including nested mounts.
---
--- Directories are walked recursively, large trees can take a while.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer size The size in bytes, `0` if the path does not exist.
---@nodiscard
function vfs.size( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_size( node )
end

--- [SHARED AND MENU]
---
--- Checks if a file has no data, or a directory has nothing inside, fails if the path does not exist.
---
---@param path_to string The path to the file or directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@return boolean is_empty `true` if the file size is `0` or the directory has no files and directories, `false` otherwise.
---@nodiscard
function vfs.isEmpty( path_to, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( path_to, stack_level )

    local node = lookup( vfs_path )
    if node == nil then
        error( string_format( "'%s' does not exist.", vfs_path ), stack_level )
    end

    if node_children[ node ] == nil then
        return node_size( node ) == 0
    end

    local _, _, count = list_children( node )
    return count == 0
end

--- [SHARED AND MENU]
---
--- Searches for files and directories in a directory by wildcard, subdirectories are not searched.
---
--- Mount roots and virtual directories inside of the directory are found too, they shadow the search path.
---
--- ```lua
--- local files, file_count, directories, directory_count = dreamwork.vfs.search( "/garrysmod/data", "*.txt" )
--- ```
---
---@param directory_path string The path to the directory.
---@param wildcard? string The wildcard names must match, see `path.wildcard`, `*` by default.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@return string[] files The names of the found files.
---@return integer file_count The number of the found files.
---@return string[] directories The names of the found directories.
---@return integer directory_count The number of the found directories.
---@nodiscard
function vfs.search( directory_path, wildcard, stack_level )
    stack_level = (stack_level or 1) + 1

    ---@type string | nil
    local pattern

    if wildcard ~= nil and wildcard ~= "*" then
        if string_containsByte( wildcard, 0x2F --[[ / ]] ) then
            error( "wildcard cannot contain '/'", stack_level )
        end

        pattern = path_wildcard( wildcard, false )
    end

    local node, message = directory_lookup( path_resolve( directory_path, stack_level ) )
    if node == nil then
        error( message, stack_level )
    end

    local names, is_directory, count = list_children( node, pattern )

    ---@type string[]
    local files = {}
    local file_count = 0

    ---@type string[]
    local directories = {}
    local directory_count = 0

    for index = 1, count, 1 do
        if is_directory[ index ] then
            directory_count = directory_count + 1
            directories[ directory_count ] = names[ index ]
        else
            file_count = file_count + 1
            files[ file_count ] = names[ index ]
        end
    end

    return files, file_count, directories, directory_count
end

--- [SHARED AND MENU]
---
--- Returns the iterator over every file and directory inside of the directory, subdirectories included.
---
--- Each directory is listed when the loop gets to it, so changes made inside of the loop are seen,
--- a directory deleted in the loop is skipped. Mounts nested in the directory are walked too.
---
--- ```lua
--- for vfs_path, is_directory in dreamwork.vfs.foreach( "/garrysmod/data" ) do
---     print( vfs_path, is_directory )
--- end
--- ```
---
---@param directory_path string The path to the directory.
---@param stack_level? integer The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
---@return fun(): string | nil, boolean | nil iterator The iterator that returns the absolute virtual path and `true` for directories.
---@nodiscard
function vfs.foreach( directory_path, stack_level )
    stack_level = (stack_level or 1) + 1

    local vfs_path = path_resolve( directory_path, stack_level )

    local node, message = directory_lookup( vfs_path )
    if node == nil then
        error( message, stack_level )
    end

    --- The stack of paths to return, the last one goes first.
    ---
    ---@type string[]
    local paths = {}

    ---@type boolean[]
    local flags = {}

    local size = 0

    --- The directory which content is pushed on the next call.
    ---
    ---@type string | nil
    local pending_path = vfs_path

    return function()
        if pending_path ~= nil then
            local directory = lookup( pending_path )
            if directory ~= nil and node_children[ directory ] ~= nil then
                local names, is_directory, count = list_children( directory )

                -- pushed in reverse, so they are returned in the listed order
                for index = count, 1, -1 do
                    size = size + 1
                    paths[ size ], flags[ size ] = child_path( pending_path, names[ index ] ), is_directory[ index ]
                end
            end

            pending_path = nil
        end

        if size == 0 then
            return nil, nil
        end

        local entry_path, entry_is_directory = paths[ size ], flags[ size ]
        paths[ size ], flags[ size ] = nil, nil
        size = size - 1

        if entry_is_directory then
            pending_path = entry_path
        end

        return entry_path, entry_is_directory
    end
end

vfs.mount( "/", "BASE_PATH" )
vfs.mount( "/garrysmod", "MOD" )
vfs.mount( "/garrysmod/data", "DATA" )

vfs.mount( "/game", "GAME" )
vfs.mount( "/game/lua", LUA_SERVER and "lsv" or (LUA_CLIENT and "lcl" or "LuaMenu") )
vfs.mount( "/game/download", "DOWNLOAD" )

if not LUA_MENU then
    vfs.mount( "/game/level", "BSP" )
end

do

    ---@param game_info dreamwork.engine.mounts.GameInfo
    ---@param is_mounted boolean
    local function game_mount( game_info, is_mounted )
        local folder = game_info.folder
        local mount_path = "/" .. folder

        unmount_path( mount_path )

        if is_mounted then
            mount_search_path( mount_path, folder )
        end
    end

    ---@param addon_info dreamwork.engine.mounts.AddonInfo
    ---@param is_mounted boolean
    local function addon_mount( addon_info, is_mounted )
        local mount_path = "/addons/" .. addon_info.folder
        unmount_path( mount_path )

        if is_mounted then
            mount_search_path( mount_path, addon_info.title )
        end
    end

    hook_catch( "dreamwork.game.mount", "dreamwork.vfs", game_mount, 2 )
    hook_catch( "dreamwork.addon.mount", "dreamwork.vfs", addon_mount, 2 )

    local game_list = engine_mounts.GameList
    for index = 1, engine_mounts.GameCount or 0, 1 do
        game_mount( game_list[ index ], true )
    end

    local addon_list = engine_mounts.AddonList
    for index = 1, engine_mounts.AddonCount or 0, 1 do
        addon_mount( addon_list[ index ], true )
    end

end
