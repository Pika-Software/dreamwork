local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local engine_hook = dreamwork_engine.hook
local hook_catch = engine_hook.catch
local hook_call = engine_hook.call

local dreamwork_getUpTime = dreamwork.getUpTime
local exceptions_call = dreamwork.exceptions.call

local detour = dreamwork.detour

---@type garrysmod.file
local glua_file = dreamwork_engine.requireLibrary( "file" )

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

local coroutine = std.coroutine
local coroutine_isyieldable = coroutine.isyieldable

local error = std.error
local isString = std.isString
local isNumber = std.isNumber


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
            dreamwork_Logger:info( "'%s' was loaded & connected as file system driver.", name )
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
                exceptions_call( callback, job.path, status )
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
                    exceptions_call( callback, job.path, status )
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
                    exceptions_call( callback, file_path, write_status )
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

-- the engine reports directories that have no files of their own as missing even though they are listed,
-- top level ones of some search paths ('materials' in 'cstrike') and vpk ones ('materials/games' in 'MOD'),
-- so the listing is the source of truth
---@param relative_path string
---@param search_path string
---@return boolean exists
---@return boolean is_directory
local function probe_listing( relative_path, search_path )
    local files, directories = driver_Find( relative_path, search_path )
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

    if string_byte( relative_path, 1, 1 ) == nil then
        return false
    end

    return (probe_listing( relative_path, search_path ))
end

---@param relative_path string
---@param search_path string
---@return boolean
local function file_IsDir( relative_path, search_path )
    if driver_IsDir( relative_path, search_path ) then
        return true
    end

    if relative_path == "" then
        return false
    end

    local _, is_directory = probe_listing( relative_path, search_path )
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
--- Like overlayfs, writes where the search path is read-only or there is none (intermediate directories) go to the memory layer on top:
---
--- * memory files and directories shadow files of the search path, appending or touching such a file copies it into memory first;
--- * memory directories created over directories of the search path are merged with them;
--- * deleting from a search path that does not allow deleting hides the file or directory with a whiteout,
---   writing into the path again replaces the whiteout;
--- * memory content stays at its path when mounts change, it is lost on reload and is never written to the disk,
---   see `vfs.getMemoryUsage` and `vfs.setMemoryLimit`.
---
--- Memory files exist only for `vfs` and functions built on it, like `std.loadfile`, a memory `.lua` file under `/game/lua`
--- is loaded by them instead of the real one. The engine, `include` and the `file` library never see memory files and whiteouts.
---
--- Every Lua state (server, client and menu) has its own memory layer, nothing is shared or networked.
---
--- ```lua
--- dreamwork.vfs.writeFile( "/game/lua/my_addon/generated.lua", "return 1" ) -- 'lsv' is read-only, kept in memory
--- dreamwork.vfs.createDirectory( "/game/level/cache" ) -- 'BSP' is read-only, a memory directory
--- dreamwork.vfs.writeFile( "/garrysmod/data/settings.txt", "{}" ) -- 'DATA' is writable, written to the disk
--- ```
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

--- The mounts that provide nodes, missing for intermediate directories.
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

--- The mount roots, intermediate directories and memory files and directories attached to directories, they shadow the search path.
---
---@type table<dreamwork.vfs.Node, dreamwork.vfs.Node[]>
local node_overlays = {}
gc_setTableRules( node_overlays, true, false )

--- The creation time of intermediate directories and mount roots.
---
---@type table<dreamwork.vfs.Node, integer>
local node_created = {}
gc_setTableRules( node_created, true, false )

--- The last modification time of intermediate directories and memory files.
---
---@type table<dreamwork.vfs.Node, integer>
local node_modified = {}
gc_setTableRules( node_modified, true, false )

--- The files and directories kept in memory, the upper layer over search paths.
---
--- They are created where search paths are read-only, shadow files of search paths and stay at their paths when mounts change.
---
---@type table<dreamwork.vfs.Node, boolean>
local node_memory = {}
gc_setTableRules( node_memory, true, false )

--- The data of memory files.
---
---@type table<dreamwork.vfs.Node, string>
local node_data = {}
gc_setTableRules( node_data, true, false )

--- The whiteouts, memory files without data that hide files and directories of search paths that cannot be deleted.
---
--- They are never returned by lookups, writing into their path replaces them.
---
---@type table<dreamwork.vfs.Node, boolean>
local node_whiteout = {}
gc_setTableRules( node_whiteout, true, false )

--- The directories of search paths and mount roots memory directories were merged into, with the creation time of the memory directory.
---
--- The memory directory is created again at their path once they are gone.
---
---@type table<dreamwork.vfs.Node, integer>
local node_merged = {}
gc_setTableRules( node_merged, true, false )

--- The number of memory files, memory directories, whiteouts and merged memory directories.
local memory_count = 0

--- The total size of memory files in bytes.
local memory_bytes = 0

--- The maximal total size of memory files in bytes, `0` for no limit.
local memory_limit = 0

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

---@param node dreamwork.vfs.Node
local function memory_add( node )
    node_memory[ node ] = true
    memory_count = memory_count + 1
end

--- Forgets memory files and directories, whiteouts and merges in the dropped node, mounts nested in it are skipped.
---
---@param node dreamwork.vfs.Node
local function memory_release( node )
    if memory_count == 0 then
        return
    end

    if node_memory[ node ] then
        node_memory[ node ], node_whiteout[ node ] = nil, nil
        memory_count = memory_count - 1

        local data = node_data[ node ]
        if data ~= nil then
            node_data[ node ] = nil
            memory_bytes = memory_bytes - string_len( data )
        end
    elseif node_merged[ node ] ~= nil then
        node_merged[ node ] = nil
        memory_count = memory_count - 1
    end

    local children = node_children[ node ]
    if children ~= nil then
        for _, child in raw_pairs( children ) do
            if not node_is_mount_root( child ) then
                memory_release( child )
            end
        end
    end
end

---@param name string
---@param unix_time integer The creation time.
---@return dreamwork.vfs.Node directory
local function memory_directory( name, unix_time )
    local directory = NodeClass( name, nil, "", true )
    node_created[ directory ], node_modified[ directory ] = unix_time, unix_time

    memory_add( directory )
    return directory
end

---@param parent dreamwork.vfs.Node
---@param node dreamwork.vfs.Node
local function attach( parent, node )
    local children, name = node_children[ parent ], node_names[ node ]

    -- the name is taken again, the whiteout is not needed anymore
    local existing = children[ name ]
    if existing ~= nil and node_whiteout[ existing ] then
        detach( existing )
        memory_release( existing )
    end

    node_parents[ node ] = parent
    children[ name ] = node

    if node_mounts[ node ] == nil or node_is_mount_root( node ) then
        local overlays = node_overlays[ parent ]
        if overlays == nil then
            node_overlays[ parent ] = { node }
        else
            overlays[ #overlays + 1 ] = node
        end
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

--- Collects mount roots nested in the directory without descending into them, and memory files and directories too if `memory` is `true`.
---
---@type fun( directory: dreamwork.vfs.Node, directory_path: string, nodes: dreamwork.vfs.Node[], paths: string[], count: integer, memory: boolean ): integer
local collect_upper

--- Collects mount roots and memory files and directories in the directory that is going away, the memory directory merged into it is created again.
---
---@type fun( directory: dreamwork.vfs.Node, directory_path: string, nodes: dreamwork.vfs.Node[], paths: string[] ): integer
local collect_detached

--- Places collected mount roots and memory files and directories back at their paths, mounts that do not fit anymore are dropped.
---
---@type fun( nodes: dreamwork.vfs.Node[], paths: string[], count: integer )
local reattach

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
        if node_whiteout[ child ] then
            return nil
        end

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

        if node_children[ child ] == nil then
            detach( child )
        else
            -- memory files and directories and mounts nested in the gone directory stay at their paths
            local nodes, paths = {}, {}
            local count = collect_detached( child, node_path( child ), nodes, paths )

            detach( child )
            reattach( nodes, paths, count )

            -- reattached nodes could create an intermediate or memory directory in its place
            child = node_children[ directory ][ name ]
            if child ~= nil then
                if node_whiteout[ child ] then
                    return nil
                end

                return child
            end
        end
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

function collect_upper( directory, directory_path, nodes, paths, count, memory )
    for name, child in raw_pairs( node_children[ directory ] ) do
        if node_is_mount_root( child ) then
            count = count + 1
            nodes[ count ], paths[ count ] = child, node_mounts[ child ].path
        elseif memory and node_memory[ child ] then
            count = count + 1
            nodes[ count ], paths[ count ] = child, child_path( directory_path, name )
        elseif node_children[ child ] ~= nil then
            local vfs_path = child_path( directory_path, name )

            local unix_time = node_merged[ child ]
            if memory and unix_time ~= nil then
                -- the memory directory merged into it is created again
                node_merged[ child ] = nil
                memory_count = memory_count - 1

                count = count + 1
                nodes[ count ], paths[ count ] = memory_directory( name, unix_time ), vfs_path
            end

            count = collect_upper( child, vfs_path, nodes, paths, count, memory )
        end
    end

    return count
end

function collect_detached( directory, directory_path, nodes, paths )
    local count = 0

    local unix_time = node_merged[ directory ]
    if unix_time ~= nil then
        node_merged[ directory ] = nil
        memory_count = memory_count - 1

        count = 1
        nodes[ 1 ], paths[ 1 ] = memory_directory( node_names[ directory ], unix_time ), directory_path
    end

    return collect_upper( directory, directory_path, nodes, paths, count, true )
end

---@param directory dreamwork.vfs.Node
---@return boolean
local function has_memory_nested( directory )
    for _, child in raw_pairs( node_children[ directory ] ) do
        if node_memory[ child ] or node_merged[ child ] ~= nil then
            return true
        end

        if node_children[ child ] ~= nil and not node_is_mount_root( child ) and has_memory_nested( child ) then
            return true
        end
    end

    return false
end

--- Checks if memory files and directories or whiteouts are nested in the directory, mounts nested in it are not checked.
---
---@param directory dreamwork.vfs.Node
---@return boolean
local function has_memory( directory )
    return memory_count ~= 0 and has_memory_nested( directory )
end

--- Forgets intermediate directories without anything inside, from the directory up, memory directories are kept.
---
---@param directory dreamwork.vfs.Node | nil
local function prune( directory )
    while directory ~= nil and directory ~= root and node_mounts[ directory ] == nil and not node_memory[ directory ] and raw_next( node_children[ directory ] ) == nil do
        local parent = node_parents[ directory ]
        detach( directory )
        directory = parent
    end
end

--- Places the mount root or the memory file or directory at the path, creating intermediate directories on the way.
---
--- Mount roots replace existing directories, memory files and directories shadow files of search paths,
--- memory directories are merged into existing directories.
---
---@type fun( vfs_path: string, node: dreamwork.vfs.Node ): boolean, string | nil
local attach_at

function reattach( nodes, paths, count )
    for index = 1, count, 1 do
        local node, vfs_path = nodes[ index ], paths[ index ]
        detach( node )

        if not attach_at( vfs_path, node ) then
            if node_is_mount_root( node ) then
                local mount = node_mounts[ node ]
                mounts[ mount.path ] = nil
                hook_call( "dreamwork.vfs.directory.mount", mount.path, mount.search_path, false )
            elseif node_children[ node ] ~= nil then
                -- mounts nested in the dropped memory directory stay at their paths
                local nested_nodes, nested_paths = {}, {}
                reattach( nested_nodes, nested_paths, collect_upper( node, vfs_path, nested_nodes, nested_paths, 0, false ) )
            end

            memory_release( node )
        end
    end
end

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
            return false, string_format( "'%s' is a file, nothing can be placed inside it.", node_path( child ) )
        end

        directory = child
    end

    local existing = child_get( directory, node_names[ node ] )
    if existing == nil then
        attach( directory, node )
        return true
    end

    if node_memory[ node ] then
        -- files of search paths are shadowed, whiteouts hide directories of search paths too
        if node_mounts[ existing ] ~= nil and not node_is_mount_root( existing ) and (node_children[ existing ] == nil or node_whiteout[ node ]) then
            local nodes, paths = {}, {}
            local count = 0

            if node_children[ existing ] ~= nil then
                count = collect_upper( existing, vfs_path, nodes, paths, 0, false )
            end

            detach( existing )
            memory_release( existing )
            attach( directory, node )
            reattach( nodes, paths, count )

            return true
        end

        if node_children[ node ] == nil or node_children[ existing ] == nil then
            prune( directory )
            return false, string_format( "'%s' already exists.", vfs_path )
        end

        if node_mounts[ existing ] == nil and not node_memory[ existing ] then
            -- the intermediate directory is replaced, mounts and memory content inside of it are placed into the memory directory
            local nodes, paths = {}, {}
            local count = collect_upper( existing, vfs_path, nodes, paths, 0, true )

            detach( existing )
            attach( directory, node )
            reattach( nodes, paths, count )

            return true
        end

        -- merged into the existing directory, the content is moved there
        local nodes, paths, count = {}, {}, 0

        for name, child in raw_pairs( node_children[ node ] ) do
            count = count + 1
            nodes[ count ], paths[ count ] = child, child_path( vfs_path, name )
        end

        node_memory[ node ] = nil
        memory_count = memory_count - 1

        if not node_memory[ existing ] then
            -- remembered by the directory of the search path or the mount root, it is created again once they are gone
            local unix_time, merged_time = node_created[ node ] or time_now(), node_merged[ existing ]
            if merged_time == nil then
                node_merged[ existing ] = unix_time
                memory_count = memory_count + 1
            elseif unix_time < merged_time then
                node_merged[ existing ] = unix_time
            end
        end

        reattach( nodes, paths, count )
        return true
    end

    if node_is_mount_root( existing ) then
        return false, string_format( "'%s' is already mounted.", vfs_path )
    end

    if node_children[ existing ] == nil then
        prune( directory )
        return false, string_format( "'%s' is a file, it cannot be a mount point.", vfs_path )
    end

    -- memory files and directories and mounts nested in the replaced directory stay at their paths
    local nodes, paths = {}, {}
    local count = collect_detached( existing, vfs_path, nodes, paths )

    if node_memory[ existing ] then
        -- the replaced memory directory is created again once the mount is gone
        node_memory[ existing ] = nil
        node_merged[ node ] = node_created[ existing ] or time_now()
    end

    detach( existing )
    attach( directory, node )
    reattach( nodes, paths, count )

    return true
end

---@param mount dreamwork.vfs.Mount
local function map_unmount( mount )
    local node = mount.node

    -- memory files and directories and mounts nested in the unmounted directory stay at their paths
    local nodes, paths = {}, {}
    local count = collect_detached( node, mount.path, nodes, paths )

    if node == root then
        node_mounts[ root ], node_relative_paths[ root ] = nil, ""
        node_children[ root ] = {}
        node_overlays[ root ] = nil
    else
        local parent = node_parents[ node ]
        detach( node )

        -- intermediate directories without anything inside are not needed anymore
        prune( parent )
    end

    mounts[ mount.path ] = nil
    reattach( nodes, paths, count )
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

--- Returns where writes into the file, or into the directory, are stored.
---
---@param node dreamwork.vfs.Node
---@return dreamwork.vfs.Storage | nil storage `nil` if the file cannot be written, the extension is not allowed by its search path.
local function write_storage( node )
    if node_memory[ node ] then
        return "memory"
    end

    local is_directory = node_children[ node ] ~= nil

    local mount
    if is_directory then
        mount = node_mounts[ node ]
    else
        mount = node_mounts[ node_parents[ node ] ]
    end

    if mount == nil or not mount.writable then
        return "memory"
    end

    if is_directory or is_allowed_extension( mount, node_names[ node ] ) then
        return "mount"
    end

    return nil
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

--- Writes the data into `DATA` with async_write or gm_asyncio from a coroutine, synchronously otherwise.
---
--- Paths rejected by the driver are written synchronously, async_write allows fewer extensions than `DATA`.
---
---@param relative_path string
---@param data string
---@param append_mode boolean
---@return boolean success
---@async
local function write_data_async( relative_path, data, append_mode )
    if not coroutine_isyieldable() then
        return write_data( "DATA", relative_path, data, append_mode )
    end

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
    local data = node_data[ node ]
    if data ~= nil then
        return data
    end

    local handle = driver_Open( node_relative_paths[ node ], "rb", node_mounts[ node ].search_path )
    if handle == nil then
        return nil, string_format( "'%s' could not be opened for reading.", node_path( node ) )
    end

    data = handle:Read( handle:Size() ) or ""
    handle:Close()

    return data
end

--- Reads the file asynchronously where possible from a coroutine, synchronously otherwise.
---
---@param node dreamwork.vfs.Node
---@return string | nil data
---@return string | nil message
---@async
local function read_node_async( node )
    if file_AsyncRead == nil or node_data[ node ] ~= nil or not coroutine_isyieldable() then
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

--- Lists the directory, mount roots, intermediate directories and memory files and directories shadow the search path, whiteouts hide it.
---
---@type fun( directory: dreamwork.vfs.Node, pattern: string? ): string[], boolean[], integer
local list_children

---@type table<dreamwork.vfs.Mount | boolean, boolean>
local memory_noticed = {}
gc_setTableRules( memory_noticed, true, false )

---@type table<dreamwork.vfs.Mount, boolean>
local whiteout_noticed = {}
gc_setTableRules( whiteout_noticed, true, false )

--- Logs the first write kept in memory for the mount, so an unexpected fallback is easy to notice.
---
---@param directory dreamwork.vfs.Node The directory that is not a memory directory.
---@param vfs_path string
local function memory_notice( directory, vfs_path )
    local mount = node_mounts[ directory ]

    local key = mount or false
    if memory_noticed[ key ] then
        return
    end

    memory_noticed[ key ] = true

    if mount == nil then
        dreamwork_Logger:debug( "'%s' has no search path, writes into intermediate directories are kept in memory.", vfs_path )
    else
        dreamwork_Logger:debug( "'%s' is read-only, writes into '%s' mounted at '%s' are kept in memory.", vfs_path, mount.search_path, mount.path )
    end
end

--- Creates the directory, in memory if the search path of the parent directory is read-only or it has none.
---
---@param parent dreamwork.vfs.Node
---@param name string
---@return dreamwork.vfs.Node | nil directory
---@return string | nil message
local function make_directory( parent, name )
    local message = check_name( name )
    if message ~= nil then
        return nil, message
    end

    local mount = node_mounts[ parent ]
    if mount == nil or not mount.writable then
        local directory = memory_directory( name, time_now() )
        attach( parent, directory )

        local vfs_path = node_path( directory )

        if not node_memory[ parent ] then
            memory_notice( parent, vfs_path )
        end

        watchdog_change( "dreamwork.vfs.created", vfs_path, true )
        return directory
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

--- Writes the memory file, the file of the search path is shadowed by it and copied into memory first when appended to.
---
---@param directory dreamwork.vfs.Node
---@param node dreamwork.vfs.Node | nil The existing file.
---@param vfs_path string
---@param name string
---@param data string
---@param append_mode boolean
---@return boolean success
---@return string | nil message
local function write_memory_file( directory, node, vfs_path, name, data, append_mode )
    if append_mode and node ~= nil then
        local old_data, message = read_node( node )
        if old_data == nil then
            return false, message
        end

        data = old_data .. data
    end

    local is_memory = node ~= nil and node_memory[ node ] == true

    local old_size = 0
    if is_memory then
        old_size = string_len( node_data[ node ] )
    end

    -- shrinking writes are allowed over the limit, the limit could be lowered after the file was written
    local new_bytes = memory_bytes - old_size + string_len( data )
    if memory_limit ~= 0 and new_bytes > memory_limit and new_bytes > memory_bytes then
        return false, string_format( "'%s' cannot be kept in memory, %d bytes in memory would exceed the limit of %d bytes.", vfs_path, new_bytes, memory_limit )
    end

    local unix_time = time_now()
    local existed = node ~= nil

    if not is_memory then
        if node ~= nil then
            detach( node )
        end

        node = NodeClass( name, nil, "", false )
        node_created[ node ] = unix_time
        memory_add( node )

        attach( directory, node )

        if not node_memory[ directory ] then
            memory_notice( directory, vfs_path )
        end
    end

    memory_bytes = new_bytes
    node_data[ node ], node_modified[ node ] = data, unix_time

    watchdog_change( existed and "dreamwork.vfs.modified" or "dreamwork.vfs.created", vfs_path, false )
    return true
end

--- Writes the file, missing directories are created.
---
--- Files are kept in memory where the search path is read-only or there is none.
---
---@param vfs_path string
---@param data string
---@param append_mode boolean
---@param async boolean? `true` to write with gm_asyncio where possible, synchronously outside of a coroutine.
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

    local mount = node_mounts[ directory ]
    if mount == nil or not mount.writable or node_memory[ node ] then
        return write_memory_file( directory, node, vfs_path, name, data, append_mode )
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

    -- the file could be discovered by someone else while the write was awaited, a whiteout is replaced
    local children = node_children[ directory ]
    if children ~= nil then
        local existing = children[ name ]
        if existing == nil or node_whiteout[ existing ] then
            discover( directory, name, false )
        end
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
    local directory, vfs_path = node_parents[ node ], node_path( node )

    -- files of read-only search paths are copied into memory
    local mount = node_mounts[ directory ]
    if mount == nil or not mount.writable or node_memory[ node ] then
        return write_memory_file( directory, node, vfs_path, node_names[ node ], "", true )
    end

    if not is_allowed_extension( mount, node_names[ node ] ) then
        return false, string_format( "'%s' cannot be touched, extension is not allowed by '%s'.", vfs_path, mount.search_path )
    end

    local data, message = read_node( node )
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
    if node_mounts[ node ] == nil then
        node_modified[ node ] = time_now()

        watchdog_change( "dreamwork.vfs.modified", node_path( node ), true )
        return true
    end

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

--- Returns the mount of the file or directory of the search path that is deleted or moved away.
---
---@param node dreamwork.vfs.Node
---@return dreamwork.vfs.Mount | nil mount
---@return string | nil message
local function removable_mount( node )
    if node_is_mount_root( node ) then
        return nil, string_format( "'%s' is a mount point, use `vfs.unmount` instead.", node_path( node ) )
    end

    local mount = node_mounts[ node ]
    if mount == nil then
        return nil, string_format( "'%s' is an intermediate directory of mount points, it cannot be deleted.", node_path( node ) )
    end

    return mount
end

--- Hides the file or directory of the search path that does not allow deleting with a whiteout, memory content inside is deleted.
---
---@param node dreamwork.vfs.Node
---@param mount dreamwork.vfs.Mount
---@param recursive boolean
---@return boolean success
---@return string | nil message
local function whiteout_node( node, mount, recursive )
    local vfs_path = node_path( node )
    local is_directory = node_children[ node ] ~= nil

    if is_directory then
        if not recursive then
            local _, _, count = list_children( node )
            if count ~= 0 then
                return false, string_format( "'%s' is not empty.", vfs_path )
            end
        end

        local nodes, paths = {}, {}
        if collect_upper( node, vfs_path, nodes, paths, 0, false ) ~= 0 then
            return false, string_format( "'%s' cannot be hidden, mount points are nested in it.", vfs_path )
        end
    end

    local parent = node_parents[ node ]

    detach( node )
    memory_release( node )

    local whiteout = NodeClass( node_names[ node ], nil, "", false )
    node_whiteout[ whiteout ] = true
    memory_add( whiteout )

    attach( parent, whiteout )

    if not whiteout_noticed[ mount ] then
        whiteout_noticed[ mount ] = true
        dreamwork_Logger:debug( "'%s' cannot be deleted from '%s' mounted at '%s', it is hidden by a whiteout in memory.", vfs_path, mount.search_path, mount.path )
    end

    watchdog_change( "dreamwork.vfs.deleted", vfs_path, is_directory )
    return true
end

---@type fun( node: dreamwork.vfs.Node, recursive: boolean ): boolean, string | nil
local delete_node

--- Deletes the memory file or directory, the file or directory of the search path shadowed by it is deleted too or hidden by a whiteout.
---
---@param node dreamwork.vfs.Node
---@param recursive boolean
---@return boolean success
---@return string | nil message
local function delete_memory_node( node, recursive )
    local vfs_path = node_path( node )

    local children = node_children[ node ]
    local is_directory = children ~= nil

    if is_directory and not recursive then
        local _, _, count = list_children( node )
        if count ~= 0 then
            return false, string_format( "'%s' is not empty.", vfs_path )
        end
    end

    local parent = node_parents[ node ]

    if is_directory then
        -- mounts nested in the deleted directory stay at their paths
        local nodes, paths = {}, {}
        local count = collect_upper( node, vfs_path, nodes, paths, 0, false )

        detach( node )
        reattach( nodes, paths, count )
    else
        detach( node )
    end

    memory_release( node )
    prune( parent )

    local replacement = lookup( vfs_path )
    if replacement == nil then
        watchdog_change( "dreamwork.vfs.deleted", vfs_path, is_directory )
        return true
    end

    -- the path must be gone like after any other deletion
    if node_mounts[ replacement ] ~= nil and not node_is_mount_root( replacement ) then
        return delete_node( replacement, true )
    end

    -- mounts nested in the deleted directory created an intermediate directory in its place
    if is_directory then
        watchdog_change( "dreamwork.vfs.modified", vfs_path, true )
    else
        watchdog_change( "dreamwork.vfs.deleted", vfs_path, false )
        watchdog_change( "dreamwork.vfs.created", vfs_path, true )
    end

    return true
end

function delete_node( node, recursive )
    if node_memory[ node ] then
        return delete_memory_node( node, recursive )
    end

    local mount, message = removable_mount( node )
    if mount == nil then
        return false, message
    end

    if not mount.deletable then
        return whiteout_node( node, mount, recursive )
    end

    local search_path, relative_path = mount.search_path, node_relative_paths[ node ]

    if node_children[ node ] ~= nil then
        local files, directories = driver_Find( join_path( relative_path, "*" ), search_path )
        local has_content = (files ~= nil and files[ 1 ] ~= nil) or (directories ~= nil and directories[ 1 ] ~= nil)

        if not recursive then
            local _, _, count = list_children( node )
            if count ~= 0 then
                return false, string_format( "'%s' is not empty.", node_path( node ) )
            end
        end

        if has_content then
            delete_tree( search_path, relative_path )
        end
    end

    driver_Delete( relative_path, search_path )

    local vfs_path = node_path( node )

    if file_Exists( relative_path, search_path ) then
        return false, string_format( "'%s' could not be deleted.", vfs_path )
    end

    if node_children[ node ] ~= nil then
        -- mounts nested in the deleted directory stay at their paths, memory files and directories are deleted with it
        local nodes, paths = {}, {}
        local count = collect_upper( node, vfs_path, nodes, paths, 0, false )

        detach( node )
        reattach( nodes, paths, count )
        memory_release( node )
    else
        detach( node )
    end

    watchdog_change( "dreamwork.vfs.deleted", vfs_path, node_children[ node ] ~= nil )
    return true
end

---@param node dreamwork.vfs.Node
---@param getter fun( relative_path: string, search_path: string ): integer
---@param times table<dreamwork.vfs.Node, integer> The times of intermediate directories and memory files, the creation time if missing.
---@return integer unix_time
local function node_time( node, getter, times )
    local mount = node_mounts[ node ]
    if mount ~= nil then
        local unix_time = getter( node_relative_paths[ node ], mount.search_path )
        if unix_time ~= nil and unix_time > 0 then
            return unix_time
        end
    end

    return times[ node ] or node_created[ node ] or 0
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
        overlay_count = 0,
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

        -- mount roots, intermediate directories and memory files go first, they shadow the search path
        --- The names hidden by whiteouts.
        ---
        ---@type table<string, boolean>
        local hidden = {}

        local overlays = node_overlays[ directory ]
        if overlays ~= nil then
            for index = 1, #overlays, 1 do
                local overlay = overlays[ index ]
                local name = node_names[ overlay ]

                if node_whiteout[ overlay ] then
                    hidden[ name ] = true
                else
                    count = count + 1

                    names[ count ], directories[ count ] = name, node_children[ overlay ] ~= nil
                    times[ count ], sizes[ count ] = 0, 0

                    indexes[ name ] = count
                end
            end
        end

        local overlay_count = count

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
                    if indexes[ name ] == nil and not hidden[ name ] and not restricted_names[ name ] then
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
                    if indexes[ name ] == nil and not hidden[ name ] and not restricted_names[ name ] then
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
            overlay_count = overlay_count,
            search_path = search_path,
            relative_path = relative_path
        }
    end

    --- Checks the file of the directory content, the first check only remembers the time and size.
    ---
    ---@param vfs_path string The path of the directory.
    ---@param content dreamwork.vfs.WatchContent
    ---@param index integer
    ---@return boolean is_checked `true` if the file was checked, `false` for directories and memory files.
    local function check_child( vfs_path, content, index )
        -- memory files are changed only through `vfs`, the changes are reported right away
        if index <= content.overlay_count or content.directories[ index ] then
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
            local mount = node_mounts[ node ]
            if mount == nil then
                file_time, file_size = node_modified[ node ] or 0, string_len( node_data[ node ] or "" )
            else
                local search_path, relative_path = mount.search_path, node_relative_paths[ node ]
                file_time, file_size = driver_Time( relative_path, search_path ) or 0, driver_Size( relative_path, search_path ) or 0
            end
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

    --- Reports changes of a mount, intermediate directories can be created or pruned anywhere on the way to it.
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
    ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
    ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
    ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
    ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
        --- Missing directories on the way to the mount point are created as intermediate directories,
        --- an existing directory at the mount point is replaced, mounts nested in it are kept.
        ---
        --- ```lua
        --- dreamwork.vfs.mount( "/hl2", "hl2" )
        --- dreamwork.vfs.mount( "/packages/my_package", "DATA", "packages/my_package" )
        --- ```
        ---
        ---@param mount_path string The absolute virtual path of the mount.
        ---@param search_path string The [search path](https://wiki.facepunch.com/gmod/File_Search_Paths), e.g. `MOD`, `DATA`, `hl2` or an addon title.
        ---@param search_directory string? The directory inside of the search path, its root by default.
        ---@param writable boolean? If `true`, files and directories can be created and written, defaults depend on the search path. Writing anywhere except `DATA` requires HolyLib.
        ---@param deletable boolean? If `true`, files and directories can be deleted, defaults depend on the search path.
        ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
    ---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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

function list_children( directory, pattern )
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
            local overlay = overlays[ index ]
            local name = node_names[ overlay ]
            listed[ name ] = true

            if not node_whiteout[ overlay ] and (pattern == nil or string_match( name, pattern ) ~= nil) then
                count = count + 1
                names[ count ], directories[ count ] = name, node_children[ overlay ] ~= nil
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
        local data = node_data[ node ]
        if data ~= nil then
            return string_len( data )
        end

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
---@param async boolean `true` to read and write asynchronously where possible, synchronously outside of a coroutine.
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

--- Moves the file or the directory into an existing directory, renames it in the search path if possible, otherwise copies and deletes it.
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

    -- memory files and directories are copied and deleted, files and directories of search paths that do not allow deleting are copied and hidden by whiteouts
    local is_memory = node_memory[ source ] == true

    local mount
    if not is_memory then
        mount, message = removable_mount( source )
        if mount == nil then
            return false, message
        end
    end

    local directory_path, name = path_split( target_path, false )

    message = check_name( name )
    if message ~= nil then
        return false, message
    end

    -- like `mv`, the target directory must exist
    local directory
    directory, message = directory_lookup( directory_path )
    if directory == nil then
        return false, message
    end

    local target_mount = node_mounts[ directory ]

    -- directories are merged into an existing one by copying, memory files and directories inside are copied too
    if mount ~= nil and mount.deletable and driver_Rename ~= nil and target_mount ~= nil and target_mount.writable and target_mount.search_path == mount.search_path
        and (is_directory or is_allowed_extension( target_mount, name )) and (target == nil or not is_directory)
        and node_merged[ source ] == nil and not (is_directory and has_memory( source )) then

        local search_path = mount.search_path

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
                local nodes, paths = {}, {}
                local count = collect_upper( source, source_path, nodes, paths, 0, false )

                detach( source )
                reattach( nodes, paths, count )
            else
                detach( source )
            end

            local children = node_children[ directory ]
            if children ~= nil then
                local existing = children[ name ]
                if existing == nil or node_whiteout[ existing ] then
                    discover( directory, name, is_directory )
                end
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Reads the whole file asynchronously when called from a coroutine, synchronously otherwise.
---
--- Falls back to a synchronous read where the engine has no asynchronous reading.
---
---@param file_path string The path to the file.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Kept in memory where the search path is read-only or there is none.
---
---@param file_path string The path to the file.
---@param data string The new data.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Kept in memory where the search path is read-only or there is none, the file of the search path is copied into memory first.
---
---@param file_path string The path to the file.
---@param data string The data to append.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.appendFile( file_path, data, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = write_file( path_resolve( file_path, stack_level ), data, true )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Replaces the file data asynchronously when called from a coroutine, synchronously otherwise.
---
--- Writes synchronously where neither async_write nor gm_asyncio is installed or the file is outside of `DATA`,
--- kept in memory where the search path is read-only or there is none.
---
---@param file_path string The path to the file.
---@param data string The new data.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Appends data to the end of the file asynchronously when called from a coroutine, synchronously otherwise.
---
--- Appends synchronously where neither async_write nor gm_asyncio is installed or the file is outside of `DATA`,
--- kept in memory where the search path is read-only or there is none.
---
---@param file_path string The path to the file.
---@param data string The data to append.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Files of search paths that do not allow deleting are hidden by a whiteout instead, see `vfs`.
---
---@param file_path string The path to the file.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Directories are created in memory where the search path is read-only or there is none.
---
---@param directory_path string The path to the directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Memory files and directories inside are deleted with it, mounts nested in it stay at their paths.
---
--- Directories of search paths that do not allow deleting are hidden by a whiteout instead, see `vfs`,
--- this fails if mounts are nested in them.
---
---@param directory_path string The path to the directory.
---@param recursive boolean? If `true`, the directory is deleted with everything in it, otherwise it must be empty.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.copyFile( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the file, missing directories are created asynchronously when called from a coroutine, synchronously otherwise.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Moves the file, the target directory must exist.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.moveFile( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, false, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the file asynchronously when called from a coroutine, synchronously otherwise, the target directory must exist.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the file.
---@param target_path string The new path of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Renames the file asynchronously when called from a coroutine, synchronously otherwise, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param file_path string The path to the file.
---@param name string The new name of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.copyDirectory( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = copy( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Copies the directory with everything in it, missing directories are created asynchronously when called from a coroutine, synchronously otherwise.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Moves the directory with everything in it, the target directory must exist.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
function vfs.moveDirectory( source_path, target_path, overwrite, stack_level )
    stack_level = (stack_level or 1) + 1

    local success, message = move( path_resolve( source_path, stack_level ), path_resolve( target_path, stack_level ), overwrite == true, true, false )
    if not success then
        error( message, stack_level )
    end
end

--- [SHARED AND MENU]
---
--- Moves the directory with everything in it asynchronously when called from a coroutine, synchronously otherwise, the target directory must exist.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Fails midway if anything cannot be copied, the copied part is kept.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param source_path string The path to the directory.
---@param target_path string The new path of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Renames the directory asynchronously when called from a coroutine, synchronously otherwise, it stays in its parent directory.
---
--- Renamed in the search path if possible, otherwise copied and deleted, mounts nested in it stay at their paths.
---
--- Reads and writes synchronously where the engine, async_write or gm_asyncio cannot do it asynchronously.
---
---@param directory_path string The path to the directory.
---@param name string The new name of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
--- Writes into read-only search paths and intermediate directories go to memory, see `vfs`,
--- pass `"mount"` as the storage to check that writes reach the search path.
---
--- ```lua
--- dreamwork.vfs.isWritable( "/garrysmod/data" ) -- true, "mount"
--- dreamwork.vfs.isWritable( "/game/lua", "mount" ) -- false, "memory"
--- ```
---
---@param path_to string The path to the file or directory.
---@param storage dreamwork.vfs.Storage? The storage writes must go to, `nil` accepts any.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_writable `true` if writing is allowed and goes to the storage, `false` otherwise or if the path does not exist.
---@return dreamwork.vfs.Storage | nil write_storage Where writes go, `nil` if the path does not exist or the file cannot be written.
---@nodiscard
function vfs.isWritable( path_to, storage, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return false, nil
    end

    local write_to = write_storage( node )
    if write_to == nil then
        return false, nil
    end

    return storage == nil or storage == write_to, write_to
end

--- [SHARED AND MENU]
---
--- Checks if a file can be opened for reading, or a directory exists.
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return boolean is_readable `true` if reading is allowed, `false` otherwise or if the path does not exist.
---@nodiscard
function vfs.isReadable( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return false
    end

    local mount = node_mounts[ node ]
    if node_children[ node ] ~= nil or mount == nil then
        return true
    end

    local handle = driver_Open( node_relative_paths[ node ], "rb", mount.search_path )
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
--- Intermediate directories created on the way to mount points and memory files and directories have no mount, their mount fields are `nil`.
---
--- ```lua
--- local info = dreamwork.vfs.getInfo( "/garrysmod/data/settings.txt" )
--- print( info.mount_path, info.search_path, info.relative_path ) -- "/garrysmod/data", "DATA", "settings.txt"
--- ```
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return dreamwork.vfs.Info | nil info The information, `nil` if the path does not exist.
---@nodiscard
function vfs.getInfo( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return nil
    end

    local mount = node_mounts[ node ]
    if mount == nil then
        local is_memory = node_memory[ node ] == true

        ---@type dreamwork.vfs.Info
        return {
            storage = is_memory and "memory" or "none",
            is_mount_root = false,
            writable = is_memory,
            deletable = is_memory
        }
    end

    ---@type dreamwork.vfs.Info
    return {
        mount_path = mount.path,
        search_path = mount.search_path,
        search_directory = mount.search_directory,
        relative_path = node_relative_paths[ node ],
        storage = "mount",
        is_mount_root = mount.node == node,
        writable = mount.writable,
        deletable = mount.deletable
    }
end

--- [SHARED AND MENU]
---
--- Returns how much is kept in memory, see `vfs`.
---
---@return integer bytes The total size of memory files in bytes.
---@return integer count The number of memory files, memory directories and whiteouts.
---@nodiscard
function vfs.getMemoryUsage()
    return memory_bytes, memory_count
end

--- [SHARED AND MENU]
---
--- Returns the maximal total size of memory files.
---
---@return integer bytes The limit in bytes, `0` if there is no limit.
---@nodiscard
function vfs.getMemoryLimit()
    return memory_limit
end

--- [SHARED AND MENU]
---
--- Sets the maximal total size of memory files, writes into memory that would exceed it fail.
---
--- Files already in memory are kept when the limit is lowered, writes that shrink them are still allowed.
---
---@param bytes integer? The limit in bytes, `0` or `nil` for no limit (default).
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it.
function vfs.setMemoryLimit( bytes, stack_level )
    if bytes == nil then
        bytes = 0
    elseif not isNumber( bytes ) or bytes < 0 or bytes % 1 ~= 0 then
        error( "memory limit must be a non-negative integer", (stack_level or 1) + 1 )
    end

    memory_limit = bytes
end

--- [SHARED AND MENU]
---
--- Returns the last access time of a file or directory.
---
--- Without HolyLib the last modification time is returned.
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The last access time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeAccessed( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_TimeAccessed, node_modified )
end

--- [SHARED AND MENU]
---
--- Returns the creation time of a file or directory.
---
--- Without HolyLib the last modification time is returned.
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The creation time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeCreated( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_TimeCreated, node_created )
end

--- [SHARED AND MENU]
---
--- Returns the last modification time of a file or directory.
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
---@return integer unix_time The last modification time, `0` if the path does not exist.
---@nodiscard
function vfs.getTimeModified( path_to, stack_level )
    local node = lookup( path_resolve( path_to, (stack_level or 1) + 1 ) )
    if node == nil then
        return 0
    end

    return node_time( node, driver_Time, node_modified )
end

--- [SHARED AND MENU]
---
--- Returns the size of a file, or the total size of everything in a directory, including nested mounts.
---
--- Directories are walked recursively, large trees can take a while.
---
---@param path_to string The path to the file or directory.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
--- Mount roots, intermediate directories and memory files and directories inside of the directory are found too, they shadow the search path.
---
--- ```lua
--- local files, file_count, directories, directory_count = dreamwork.vfs.search( "/garrysmod/data", "*.txt" )
--- ```
---
---@param directory_path string The path to the directory.
---@param wildcard string? The wildcard names must match, see `path.wildcard`, `*` by default.
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
---@param stack_level integer? The stack level of the caller, `1` (default) is the function calling this one, errors blame it and relative paths are resolved against its file.
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
