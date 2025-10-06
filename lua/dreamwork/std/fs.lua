local _G = _G
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std
local engine = dreamwork.engine

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU
local engine_hookCall = engine.hookCall
local setmetatable = std.setmetatable
local tostring = std.tostring

local futures = std.futures
local Future = futures.Future

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

-- TODO: https://github.com/RaphaelIT7/gmod-holylib#filesystem

local glua_file = _G.file
local file_Time = glua_file.Time
local file_Find = glua_file.Find
local file_Size = glua_file.Size
local file_Open = glua_file.Open
local file_IsDir = glua_file.IsDir
local file_Exists = glua_file.Exists
local file_Delete = glua_file.Delete
local file_CreateDir = glua_file.CreateDir

local FILE = std.debug.findmetatable( "File" )
---@cast FILE File

local FILE_Read, FILE_Write = FILE.Read, FILE.Write
local FILE_Close = FILE.Close
local FILE_Size = FILE.Size

local debug = std.debug
local gc_setTableRules = debug.gc.setTableRules

local table = std.table
local table_concat = table.concat
local table_remove = table.remove

local string = std.string
local string_len = string.len
local string_byte = string.byte
local string_hasByte = string.hasByte
local string_byteTrim = string.byteTrim
local string_byteSplit = string.byteSplit

local class = std.class

local time = std.time
local time_now = time.now

local raw = std.raw
local raw_set = raw.set
local raw_index = raw.index

local path = std.path
local path_split = path.split
local path_resolve = path.resolve

do

    local require = _G.require or debug.fempty

    local is_edge = std.JIT_VERSION_INT ~= 20004
    local is_x86 = std.x86

    local head = "lua/bin/gm" .. ( ( CLIENT and not MENU ) and "cl" or "sv" ) .. "_"
    local tail = "_" .. ( { "osx64", "osx", "linux64", "linux", "win64", "win32" } )[ ( std.WINDOWS and 4 or 0 ) + ( std.LINUX and 2 or 0 ) + ( is_x86 and 1 or 0 ) + 1 ]

    --- [SHARED AND MENU]
    ---
    --- Checks if a binary module is installed and returns its path.
    ---
    ---@param name string The binary module name.
    ---@return boolean installed `true` if the binary module is installed, `false` otherwise.
    ---@return string path The absolute path to the binary module.
    local function lookupbinary( name )
        if string.isEmpty( name ) then
            return false, ""
        end

        local file_path = head .. name .. tail

        local dll_path = file_path .. ".dll"
        if file_Exists( dll_path, "MOD" ) then
            return true, "/garrysmod/" .. dll_path
        end

        local so_path = file_path .. ".so"
        if file_Exists( so_path, "MOD" ) then
            return true, "/garrysmod/" .. so_path
        end

        if is_edge and is_x86 and tail == "_linux" then
            file_path = head .. name .. "_linux32"

            dll_path = file_path .. ".dll"
            if file_Exists( dll_path, "MOD" ) then
                return true, "/garrysmod/" .. dll_path
            end

            so_path = file_path .. ".so"
            if file_Exists( so_path, "MOD" ) then
                return true, "/garrysmod/" .. so_path
            end
        end

        return false, "/" .. file_path .. ( std.WINDOWS and ".dll" or ".so" )
    end

    std.lookupbinary = lookupbinary

    local sv_allowcslua

    if SERVER then
        sv_allowcslua = std.console.Variable.get( "sv_allowcslua", "boolean" )
    end

    --- [SHARED AND MENU]
    ---
    --- Loads a binary module by name.
    ---
    ---@param name string The binary module name, for example: "chttp"
    ---@return boolean success true if the binary module is installed
    function std.loadbinary( name )
        if lookupbinary( name ) then
            if sv_allowcslua ~= nil and sv_allowcslua.value then
                sv_allowcslua.value = false
            end

            require( name )
            return true
        end

        return false
    end

end

local async_read, async_write, async_append

---@class dreamwork.std.fs.WriteRespond
---@field status integer
---@field file_path string
---@field game_path string

---@class dreamwork.std.fs.ReadRespond : dreamwork.std.fs.WriteRespond
---@field data string | nil

---@alias async_read_callback fun( file_path: string, game_path: string, status: integer, data: string )

if std.lookupbinary( "asyncio" ) and file.AsyncRead ~= nil and file.AsyncWrite ~= nil and file.AsyncAppend ~= nil then

    local timer = _G.timer
    local timer_Create = timer.Create

    ---@param identifier string
    ---@param delay number
    ---@param repetitions integer
    ---@param event_fn function
    ---@diagnostic disable-next-line: duplicate-set-field
    function timer.Create( identifier, delay, repetitions, event_fn )
        if identifier == "__ASYNCIO_THINK" then
            dreamwork.Logger:debug( "Catched 'gm_asyncio' tick event %s, re-attaching to dreamwork engine...", event_fn )
            engine.hookCatch( "Tick", event_fn, 1 )
        else
            timer_Create( identifier, delay, repetitions, event_fn )
        end
    end

    if std.loadbinary( "asyncio" ) then

        ---@alias asyncio_write_callback fun( file_path: string, game_path: string, status: integer )

        ---@type fun( file_path: string, game_path: string, callback: async_read_callback ): integer
        local file_AsyncRead = file.AsyncRead

        ---@type fun( file_path: string, data: string, callback: asyncio_write_callback, game_path: string ): integer
        local file_AsyncWrite = file.AsyncWrite

        ---@type fun( file_path: string, data: string, callback: asyncio_write_callback, game_path: string ): integer
        local file_AsyncAppend = file.AsyncAppend

        ---@param file_path string
        ---@param game_path string
        ---@return dreamwork.std.futures.Future future
        ---@async
        function async_read( file_path, game_path )
            local f = Future()

            local status = file_AsyncRead( file_path, game_path, function( _, __, status, data )
                if f:isFinished() then
                    return
                end

                ---@type dreamwork.std.fs.ReadRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status,
                    data = data
                } )
            end )

            if status < 0 and not f:isFinished() then
                ---@type dreamwork.std.fs.ReadRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status
                } )
            end

            return f
        end

        ---@param file_path string
        ---@param game_path string
        ---@param data string
        ---@return dreamwork.std.futures.Future future
        ---@async
        function async_write( file_path, game_path, data )
            local f = Future()

            local status = file_AsyncWrite( file_path, data, function( _, __, status )
                if f:isFinished() then
                    return
                end

                ---@type dreamwork.std.fs.WriteRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status
                } )
            end, game_path )

            if status < 0 and not f:isFinished() then
                ---@type dreamwork.std.fs.WriteRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status
                } )
            end

            return f
        end

        ---@param file_path string
        ---@param game_path string
        ---@param data string
        ---@return dreamwork.std.futures.Future future
        ---@async
        function async_append( file_path, game_path, data )
            local f = Future()

            local status = file_AsyncAppend( file_path, data, function( _, __, status )
                if f:isFinished() then
                    return
                end

                ---@type dreamwork.std.fs.WriteRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status
                } )
            end, game_path )

            if status < 0 and not f:isFinished() then
                ---@type dreamwork.std.fs.WriteRespond
                f:setResult( {
                    file_path = file_path,
                    game_path = game_path,
                    status = status
                } )
            end

            return f
        end

        dreamwork.Logger:info( "'asyncio' was loaded & connected as file system driver." )
    else
        dreamwork.Logger:error( "'asyncio' failed to load, unknown error." )
    end

    timer.Create = timer_Create

end

if ( async_write == nil or async_append == nil ) and std.loadbinary( "async_write" ) and file.AsyncWrite ~= nil and file.AsyncAppend ~= nil then

    ---@alias async_write_write_callback fun( file_path: string, status: integer )

    ---@type fun( file_path: string, data: string, callback: async_write_write_callback, sync: boolean, game_path: string ): integer
    local file_AsyncWrite = file.AsyncWrite

    ---@type fun( file_path: string, data: string, callback: async_write_write_callback, sync: boolean, game_path: string ): integer
    local file_AsyncAppend = file.AsyncAppend

    ---@param file_path string
    ---@param game_path string
    ---@param data string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_write( file_path, game_path, data )
        local f = Future()

        local status = file_AsyncWrite( file_path, data, function( _, status )
            if f:isFinished() then
                return
            end

            ---@type dreamwork.std.fs.WriteRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status
            } )
        end, false, game_path )

        if status < 0 and not f:isFinished() then
            ---@type dreamwork.std.fs.WriteRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status
            } )
        end

        return f
    end

    ---@param file_path string
    ---@param game_path string
    ---@param data string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_append( file_path, game_path, data )
        local f = Future()

        local status = file_AsyncAppend( file_path, data, function( _, status )
            if f:isFinished() then
                return
            end

            ---@type dreamwork.std.fs.WriteRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status
            } )
        end, false, game_path )

        if status < 0 and not f:isFinished() then
            ---@type dreamwork.std.fs.WriteRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status
            } )
        end

        return f
    end

    dreamwork.Logger:info( "'async_write' was loaded & connected as file system driver." )

end

if async_read == nil and not MENU and file.AsyncRead ~= nil then

    ---@type fun( file_path: string, game_path: string, callback: async_read_callback, sync: boolean ): integer
    local file_AsyncRead = file.AsyncRead

    ---@param file_path string
    ---@param game_path string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_read( file_path, game_path )
        local f = Future()

        local status = file_AsyncRead( file_path, game_path, function( _, __, status, data )
            if f:isFinished() then
                return
            end

            ---@type dreamwork.std.fs.ReadRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status,
                data = data
            } )
        end, false )

        if status < 0 and not f:isFinished() then
            ---@type dreamwork.std.fs.ReadRespond
            f:setResult( {
                file_path = file_path,
                game_path = game_path,
                status = status
            } )
        end

        return f
    end

end

if async_read == nil then

    ---@param file_path string
    ---@param game_path string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_read( file_path, game_path )
        ---@type dreamwork.std.fs.ReadRespond
        local respond = {
            file_path = file_path,
            game_path = game_path,
            status = 0
        }

        local handler = file_Open( file_path, "rb", game_path )
        if handler == nil then
            respond.status = -1
        else
            respond.data = FILE_Read( handler, FILE_Size( handler ) )
            FILE_Close( handler )
        end

        local f = Future()
        f:setResult( respond )
        return f
    end

end

if async_write == nil then

    ---@param file_path string
    ---@param game_path string
    ---@param data string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_write( file_path, game_path, data )
        ---@type dreamwork.std.fs.WriteRespond
        local respond = {
            file_path = file_path,
            game_path = game_path,
            status = 0
        }

        local handler = file_Open( file_path, "wb", game_path )
        if handler == nil then
            respond.status = -1
        else
            FILE_Write( handler, data )
            FILE_Close( handler )
        end

        local f = Future()
        f:setResult( respond )
        return f
    end

end

if async_append == nil then

    ---@param file_path string
    ---@param game_path string
    ---@param data string
    ---@return dreamwork.std.futures.Future future
    ---@async
    function async_append( file_path, game_path, data )
        ---@type dreamwork.std.fs.WriteRespond
        local respond = {
            file_path = file_path,
            game_path = game_path,
            status = 0
        }

        local handler = file_Open( file_path, "ab", game_path )
        if handler == nil then
            respond.status = -1
        else
            FILE_Write( handler, data )
            FILE_Close( handler )
        end

        local f = Future()
        f:setResult( respond )
        return f
    end

end

local make_async_message
do

    ---@type table<integer, string>
    local status_messages = {
        [ -16 ] = "'{1}' {2} failed, unknown error.",
        [ -8 ]  = "'{1}' {2} failed, file name is not part of the specified file system; please try another one.",
        [ -7 ]  = "'{1}' {2} failed, please retry later. (network problems, etc)",
        [ -6 ]  = "'{1}' {2} failed, read parameters are invalid for unbuffered I/O.",
        [ -5 ]  = "'{1}' {2} failed, hard subsystem failure.",
        [ -4 ]  = "'{1}' {2} failed, read error on file.",
        [ -3 ]  = "'{1}' {2} failed, not enough memory.",
        [ -2 ]  = "'{1}' {2} failed, identifier provided by the caller is not recognized.",
        [ -1 ]  = "'{1}' {2} failed, file could not be opened (bad path, not exist, etc).",
        [ 0 ]   = "'{1}' {2} was successfully completed.",
        [ 1 ]   = "'{1}' {2} has been properly queued and awaiting for service.",
        [ 2 ]   = "'{1}' {2} is being accessed.",
        [ 3 ]   = "'{1}' {2} has been interrupted by the caller.",
        [ 4 ]   = "'{1}' {2} has not yet been queued."
    }

    local tmp = {}

    ---@param status integer
    ---@param fs_object dreamwork.std.fs.Object
    ---@param is_writing boolean
    ---@return string
    function make_async_message( status, fs_object, is_writing )
        tmp[ 1 ] = tostring( fs_object )
        tmp[ 2 ] = is_writing and "writing" or "reading"
        return string.interpolate( status_messages[ status ] or status_messages[ -16 ], tmp )
    end

end

--- [SHARED AND MENU]
---
--- The filesystem library.
---
--- The filesystem library provides access to the file system of the game.
---
---@class dreamwork.std.fs
local fs = std.fs or {}
std.fs = fs

---@class dreamwork.std.fs.File : dreamwork.std.Object
---@field __class dreamwork.std.fs.FileClass
---@field name string The name of the file. **READ-ONLY**
---@field size integer The size of the file in bytes. **READ-ONLY**
---@field time integer The last modified time of the file. **READ-ONLY**
---@field path string The path to the file. **READ-ONLY**
---@field parent dreamwork.std.fs.Directory | nil The parent directory. **READ-ONLY**
local File = class.base( "File", true )

---@class dreamwork.std.fs.Directory : dreamwork.std.Object
---@field __class dreamwork.std.fs.DirectoryClass
---@field name string The name of the directory. **READ-ONLY**
---@field size integer The size of the directory in bytes. **READ-ONLY**
---@field time integer The last modified time of the directory. **READ-ONLY**
---@field path string The full path of the directory. **READ-ONLY**
---@field writeable boolean If `true`, the directory is directly writeable.
---@field parent dreamwork.std.fs.Directory | nil The parent directory. **READ-ONLY**
local Directory = class.base( "Directory", true )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias File dreamwork.std.fs.File
---@alias Directory dreamwork.std.fs.Directory
---@alias dreamwork.std.fs.Object dreamwork.std.fs.File | dreamwork.std.fs.Directory

---@type table<dreamwork.std.fs.Object, string>
local names = {}

do

    local invalid_characters = {
        [ 0x22 ] = true,
        [ 0x27 ] = true,
        [ 0x2A ] = true,
        [ 0x2F ] = true,
        [ 0x5C ] = true,
        [ 0x7C ] = true,
        [ 0x7F ] = true,
        [ 0x3A ] = true
    }

    for i = 0, 31, 1 do
        invalid_characters[ i ] = true
    end

    for i = 59, 63, 1 do
        invalid_characters[ i ] = true
    end

    setmetatable( names, {
        __newindex = function( self, fs_object, name )
            for index = 1, string_len( name ), 1 do
                if invalid_characters[ string_byte( name, index, index ) ] then
                    error( string.format( "directory or file name contains invalid character \\%X at index %d in '%s'", string_byte( name, index, index ), index, name ), 2 )
                end
            end

            raw_set( self, fs_object, name )
        end,
        __mode = "k"
    } )

end

---@type table<dreamwork.std.fs.Object, string>
local paths = {}

setmetatable( paths, {
    ---@param fs_object dreamwork.std.fs.Object
    __index = function( self, fs_object )
        local object_path = "/" .. names[ fs_object ]
        raw_set( self, fs_object, object_path )
        return object_path
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.fs.Object, dreamwork.std.fs.Directory>
local parents = {}
-- gc_setTableRules( parents, true, false )

---@type table<dreamwork.std.fs.Directory, table<string | integer, dreamwork.std.fs.Object>>
local descendants = {}

setmetatable( descendants, {
    __index = function( self, fs_object )
        ---@type table<string | integer, dreamwork.std.fs.Object>
        local directory_children = {}
        raw_set( self, fs_object, directory_children )
        return directory_children
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.fs.Directory, integer>
local descendant_counts = {}

setmetatable( descendant_counts, {
    __index = function( self, fs_object )
        return 0
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.fs.Object, integer>
local indexes = {}
gc_setTableRules( indexes, true, false )

---@type table<dreamwork.std.fs.Object, boolean>
local is_directory_object = {}
gc_setTableRules( is_directory_object, true, false )

---@type table<dreamwork.std.fs.Directory, string>
local mount_points = {}
gc_setTableRules( mount_points, true, false )

---@type table<dreamwork.std.fs.Directory, string>
local mount_paths = {}
gc_setTableRules( mount_paths, true, false )

---@type table<dreamwork.std.fs.Object, integer>
local sizes = {}

setmetatable( sizes, {
    ---@param fs_object dreamwork.std.fs.Object
    __index = function( self, fs_object )
        local object_size

        local mount_point = mount_points[ fs_object ]
        if mount_point == nil or is_directory_object[ fs_object ] then
            object_size = 0
        else
            object_size = file_Size( mount_paths[ fs_object ] or "", mount_point ) or 0
        end

        raw_set( self, fs_object, object_size )
        return object_size
    end,
    __mode = "k"
} )

---@param directory dreamwork.std.fs.Directory
---@param byte_count integer
local function size_add( directory, byte_count )
    while directory ~= nil do
        sizes[ directory ] = sizes[ directory ] + byte_count
        directory = parents[ directory ]
    end
end

---@type table<dreamwork.std.fs.Object, integer>
local times = {}

setmetatable( times, {
    ---@param fs_object dreamwork.std.fs.Object
    __index = function( self, fs_object )
        local object_time

        local mount_point = mount_points[ fs_object ]
        if mount_point == nil then
            object_time = time_now()
        else
            object_time = file_Time( mount_paths[ fs_object ] or "", mount_point )
        end

        raw_set( self, fs_object, object_time )
        return object_time
    end,
    __mode = "k"
} )

local make_watchdog_message
do

    local status_messages = {
        [ 1 ] = "File system object '{1}' created.",
        [ 2 ] = "File system object '{1}' deleted.",
        [ 3 ] = "File system object '{1}' modified.",

        [ -1 ] = "File system object '{1}' not found.",
        [ -2 ] = "File system object '{1}' not readable.",
        [ -3 ] = "File system object '{1}' out of scope.",
        [ -4 ] = "File system object '{1}' unavailable.",
        [ -5 ] = "File system object '{1}' already watched.",
        [ -6 ] = "File system object '{1}' unknown error.",
    }

    local tmp = {}

    ---@param status integer
    ---@param fs_object dreamwork.std.fs.Object
    ---@return string message
    function make_watchdog_message( status, fs_object )
        tmp[ 1 ] = tostring( fs_object )
        return string.interpolate( status_messages[ status ] or status_messages[ -16 ], tmp )
    end

end

--- [SHARED AND MENU]
---
--- The watchdog module.
---
--- Used for files and directories monitoring. (File creation, deletion, modification, etc.)
---
---@class dreamwork.std.fs.watchdog
local watchdog = {}
fs.watchdog = watchdog

local watchdog_Created = std.Hook( "fs.watchdog.Created" )
watchdog.Created = watchdog_Created

local watchdog_Deleted = std.Hook( "fs.watchdog.Deleted" )
watchdog.Deleted = watchdog_Deleted

local watchdog_Modified = std.Hook( "fs.watchdog.Modified" )
watchdog.Modified = watchdog_Modified

if std.loadbinary( "efsw" ) then

    local hook = _G.hook
    local hook_Add = hook.Add

    ---@param event_name string
    ---@param identifier string
    ---@param event_fn function
    ---@diagnostic disable-next-line: duplicate-set-field
    function hook.Add( event_name, identifier, event_fn )
        if event_name == "Think" and identifier == "__ESFW_THINK" then
            dreamwork.Logger:debug( "Catched 'gm_efsw' tick event %s, re-attaching to dreamwork engine...", event_fn )
            engine.hookCatch( "Tick", event_fn, 1 )
        else
            hook_Add( event_name, identifier, event_fn )
        end
    end

    if std.loadbinary( "efsw" ) then
        dreamwork.Logger:info( "'gm_efsw' was loaded & connected as file system watcher." )
    else
        dreamwork.Logger:error( "'gm_efsw' failed to load, unknown error." )
    end

    hook.Add = hook_Add

    ---@type table<dreamwork.std.fs.Object, integer>
    local watch_ids = {}
    gc_setTableRules( watch_ids, true, false )

    ---@diagnostic disable-next-line: undefined-field
    local efsw = _G.efsw

    ---@type fun( file_path: string, game_path: string ): integer
    local efsw_watch = efsw ~= nil and efsw.Watch or debug.fempty

    ---@type fun( watch_id: integer )
    local efsw_unwatch = efsw ~= nil and efsw.Unwatch or debug.fempty

    --- [SHARED AND MENU]
    ---
    --- Starts monitoring a file or directory.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@return boolean success
    ---@return integer watch_id
    function watchdog.watch( fs_object )
        local watch_id = watch_ids[ fs_object ]
        if watch_id == nil then
            local mount_point = mount_points[ fs_object ]

            if mount_point == nil then
                return false, -3
            end

            watch_id = efsw_watch( mount_paths[ fs_object ] or "", mount_point ) or -1

            if watch_id < 0 then
                return false, watch_id
            else
                watch_ids[ fs_object ] = watch_id
            end
        end

        return true, watch_id
    end

    --- [SHARED AND MENU]
    ---
    --- Stops monitoring a file or directory.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@return boolean success
    function watchdog.unwatch( fs_object )
        local watch_id = watch_ids[ fs_object ]
        if watch_id == nil then
            return false
        end

        watch_ids[ fs_object ] = nil
        efsw_unwatch( watch_id )

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a file or directory is being watched.
    ---
    ---@param fs_object string
    ---@return boolean is_watched
    function watchdog.isWatched( fs_object )
        return watch_ids[ fs_object ] ~= nil
    end

    engine.hookCatch( "FileWatchEvent", function( action, watch_id, file_path )
        if watch_id < 0 then
            return
        end

        local fs_object = fs.get( "/garrysmod/" .. file_path )
        if fs_object == nil then
            return
        end

        if action == 1 then
            watchdog_Created:call( fs_object, is_directory_object[ fs_object ] == true )
        elseif action == 2 then
            watchdog_Deleted:call( fs_object, is_directory_object[ fs_object ] == true )
        elseif action == 3 then
            watchdog_Modified:call( fs_object, is_directory_object[ fs_object ] == true )
        end
    end )

else

    ---@type table<dreamwork.std.fs.Object, integer>
    local watch_map = {}
    gc_setTableRules( watch_map, true, false )

    ---@type dreamwork.std.fs.Object[]
    local watch_list = {}
    gc_setTableRules( watch_list, false, true )

    ---@type integer
    local watch_list_size = 0

    ---@type table<dreamwork.std.fs.Directory, dreamwork.std.fs.Object[]>
    local content_lists = {}
    gc_setTableRules( content_lists, true, false )

    ---@type table<dreamwork.std.fs.Directory, integer>
    local content_counts = {}
    gc_setTableRules( content_counts, true, false )

    --- [SHARED AND MENU]
    ---
    --- Starts monitoring a file or directory.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@return boolean success
    ---@return integer watch_id
    function watchdog.watch( fs_object )
        local watch_id = watch_map[ fs_object ]
        if watch_id ~= nil then
            return true, watch_id
        end

        local mount_point = mount_points[ fs_object ]
        if mount_point == nil then
            return false, -3
        end

        local mount_path = mount_paths[ fs_object ] or ""

        if not file_Exists( mount_path, mount_point ) then
            return false, -1
        end

        if is_directory_object[ fs_object ] then

            ---@cast fs_object dreamwork.std.fs.Directory

            ---@type dreamwork.std.fs.Object[]
            local content_list = {}

            ---@type integer
            local content_count = content_counts[ fs_object ] or 0

            fs_object:scan( false, false )

            ---@type dreamwork.std.fs.Object[]
            local fs_files, fs_file_count,
                fs_dirs, fs_dir_count = fs_object:select()

            for i = 1, fs_file_count, 1 do
                local file_object = fs_files[ i ]

                local file_mount_point = mount_points[ file_object ]
                if file_mount_point ~= nil then
                    content_count = content_count + 1
                    content_list[ content_count ] = file_object
                    times[ file_object ] = file_Time( mount_paths[ file_object ] or file_object.name, file_mount_point )
                end
            end

            for i = 1, fs_dir_count, 1 do
                local directory_object = fs_dirs[ i ]

                local directory_mount_point = mount_points[ directory_object ]
                if directory_mount_point ~= nil then
                    content_count = content_count + 1
                    content_list[ content_count ] = directory_object
                    times[ directory_object ] = file_Time( mount_paths[ directory_object ] or "", directory_mount_point )
                end
            end

            content_lists[ fs_object ] = content_list
            content_counts[ fs_object ] = content_count

        end

        watch_list_size = watch_list_size + 1

        watch_list[ watch_list_size ] = fs_object
        watch_map[ fs_object ] = watch_list_size

        times[ fs_object ] = file_Time( mount_path, mount_point )

        return true, watch_list_size
    end

    --- [SHARED AND MENU]
    ---
    --- Stops monitoring a file or directory.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    function watchdog.unwatch( fs_object )
        if watch_map[ fs_object ] == nil then
            return
        end

        for i = watch_list_size, 1, -1 do
            if watch_list[ i ] == fs_object then
                table_remove( watch_list, i )
                watch_list_size = watch_list_size - 1
                break
            end
        end

        watch_map[ fs_object ] = nil
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a file or directory is being watched.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@return boolean is_watched
    function watchdog.isWatched( fs_object )
        return watch_map[ fs_object ] ~= nil
    end

    do

        ---@param dead_fs_object dreamwork.std.fs.Object
        local function on_gc( dead_fs_object )
            for i = watch_list_size, 1, -1 do
                local fs_object = watch_list[ i ]
                if fs_object == dead_fs_object then
                    table_remove( watch_list, i )
                    watch_list_size = watch_list_size - 1
                elseif is_directory_object[ fs_object ] then
                    ---@cast fs_object dreamwork.std.fs.Directory

                    local content_list = content_lists[ fs_object ]
                    if content_list ~= nil then
                        local content_length = content_counts[ fs_object ] or 0

                        for j = content_length, 1, -1 do
                            if content_list[ j ] == fs_object then
                                table_remove( content_list, j )
                                content_length = content_length - 1
                            end
                        end

                        content_counts[ fs_object ] = content_length
                    end
                end
            end
        end

        engine.hookCatch( "DirectoryGC", on_gc, 1 )
        engine.hookCatch( "FileGC", on_gc, 1 )

    end

    local function watchdog_update( fs_object )
        local mount_path, mount_point = mount_paths[ fs_object ] or "", mount_points[ fs_object ]

        if not file_Exists( mount_path, mount_point ) then
            watchdog.unwatch( fs_object )
            watchdog_Deleted:call( fs_object, is_directory_object[ fs_object ] == true )
            return
        end

        local last_modified = file_Time( mount_path, mount_point )

        if times[ fs_object ] == last_modified then
            local content_list = content_lists[ fs_object ]
            if content_list == nil then
                return
            end

            ---@cast fs_object dreamwork.std.fs.Directory

            for i = content_counts[ fs_object ] or 0, 1, -1 do
                local fs_child = content_list[ i ]

                last_modified = file_Time( mount_paths[ fs_child ] or "", mount_points[ fs_child ] )
                if times[ fs_child ] ~= last_modified then
                    watchdog_Modified:call( fs_child, is_directory_object[ fs_child ] == true )
                    times[ fs_child ] = last_modified
                end
            end

            return
        end

        times[ fs_object ] = last_modified
        watchdog_Modified:call( fs_object, is_directory_object[ fs_object ] == true )

        local content_list = content_lists[ fs_object ]
        if content_list == nil then
            return
        end

        ---@cast fs_object dreamwork.std.fs.Directory

        ---@type integer
        local content_length = content_counts[ fs_object ] or 0

        ---@type table<string, dreamwork.std.fs.Object>
        local directory_files = {}

        for i = 1, content_length, 1 do
            local fs_child = content_list[ i ]
            directory_files[ fs_child.name ] = fs_child
        end

        fs_object:scan( false, false )

        local fs_files, fs_file_count,
            fs_dirs, fs_dir_count = fs_object:select()

        local current_files = {}

        for i = 1, fs_file_count, 1 do
            local file_object = fs_files[ i ]
            local name = file_object.name

            if directory_files[ name ] == nil then
                content_length = content_length + 1
                content_list[ content_length ] = file_object
                watchdog_Created:call( file_object, is_directory_object[ file_object ] == true )
            end

            current_files[ name ] = true
        end

        for i = 1, fs_dir_count, 1 do
            local directory_object = fs_dirs[ i ]
            local name = directory_object.name

            if directory_files[ name ] == nil then
                content_length = content_length + 1
                content_list[ content_length ] = directory_object
                watchdog_Created:call( directory_object, is_directory_object[ directory_object ] == true )
            end

            current_files[ name ] = true
        end

        for i = content_length, 1, -1 do
            local fs_child = content_list[ i ]

            if current_files[ fs_child.name ] == nil then
                for j = content_length, 1, -1 do
                    if content_list[ j ] == fs_child then
                        table_remove( content_list, j )
                        content_length = content_length - 1
                        break
                    end
                end

                watchdog_Deleted:call( fs_child, is_directory_object[ fs_child ] == true )
            else
                last_modified = file_Time( mount_paths[ fs_child ] or "", mount_points[ fs_child ] )
                if times[ fs_child ] ~= last_modified then
                    watchdog_Modified:call( fs_child, is_directory_object[ fs_child ] == true )
                    times[ fs_child ] = last_modified
                end
            end
        end

        content_counts[ fs_object ] = content_length
    end

    local pointer = 1

    engine.hookCatch( "Tick", function()
        if watch_list_size == 0 then
            return
        end

        -- time.tick()

        watchdog_update( watch_list[ pointer ] )

        if pointer == watch_list_size then
            pointer = 1
        else
            pointer = pointer + 1
        end

        -- std.printf( "watchdog: %f s", time.tick() )
    end, 1 )

    dreamwork.Logger:info( "'watchdog' was loaded & connected as file system watcher." )

end

engine.hookCatch( "DirectoryGC", watchdog.unwatch )
engine.hookCatch( "FileGC", watchdog.unwatch )

---@type table<string, boolean>
local writeable_mounts = {
    ["DATA"] = true
}

---@type table<string, boolean>
local deletable_mounts = {
    ["DATA"] = true,
    ["MOD"] = MENU
}

---@protected
function File:__gc()
    engine_hookCall( "FileGC", self )
end

---@protected
---@param name string
---@param mount_point string | nil
---@param mount_path string | nil
function File:__init( name, mount_point, mount_path )
    names[ self ] = name
    is_directory_object[ self ] = false
    mount_paths[ self ] = mount_path
    mount_points[ self ] = mount_point
end

---@protected
---@param key string
---@return any
function File:__index( key )
    if key == "name" then
        return names[ self ]
    elseif key == "size" then
        return sizes[ self ]
    elseif key == "time" then
        return times[ self ]
    elseif key == "path" then
        return paths[ self ]
    elseif key == "parent" then
        return parents[ self ]
    else
        return raw_index( File, key )
    end
end

---@protected
---@return string
function File:__tostring()
    return string.format( "File: %p [%s][%s][%d bytes]", self, self.path, time.toDuration( time_now() - self.time ), self.size )
end

local async_job_register, async_job_unregister, is_busy
do

    ---@type table<dreamwork.std.fs.Object, dreamwork.std.futures.Future[]>
    local async_jobs = {}
    gc_setTableRules( async_jobs, true, false )

    ---@type table<dreamwork.std.fs.Object, integer>
    local async_job_counts = {}
    gc_setTableRules( async_job_counts, true, false )

    --- [SHARED AND MENU]
    ---
    --- Registers a file or directory for asynchronous monitoring.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@param future dreamwork.std.futures.Future
    ---@return boolean is_registered
    function async_job_register( fs_object, future )
        if future:isFinished() then
            return false
        end

        local job_count = ( async_job_counts[ fs_object ] or 0 ) + 1

        local jobs = async_jobs[ fs_object ]
        if jobs == nil then
            async_jobs[ fs_object ] = { future }
        else
            jobs[ job_count ] = future
        end

        async_job_counts[ fs_object ] = job_count

        local directory_object = parents[ fs_object ]
        if directory_object ~= nil then
            async_job_register( directory_object, future )
        end

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Unregisters a file or directory from asynchronous monitoring.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@param future dreamwork.std.futures.Future
    ---@return boolean is_unregistered
    function async_job_unregister( fs_object, future )
        local job_count = async_job_counts[ fs_object ] or 0
        local jobs = async_jobs[ fs_object ]

        for i = job_count, 1, -1 do
            if jobs[ i ] == future then
                table_remove( jobs, i )
                async_job_counts[ fs_object ] = job_count - 1

                local directory_object = parents[ fs_object ]
                if directory_object ~= nil then
                    async_job_unregister( directory_object, future )
                end

                return true
            end
        end

        return false
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the file or directory is busy, otherwise `false`.
    ---
    ---@param fs_object dreamwork.std.fs.Object
    ---@return boolean is_busy
    function is_busy( fs_object )
        return async_job_counts[ fs_object ] ~= 0
    end

end

--- [SHARED AND MENU]
---
--- Returns the data of a file by given path.
---
---@return string data The data of the file.
---@async
function File:read()
    local f = async_read( mount_paths[ self ], mount_points[ self ] )
    local is_registered = async_job_register( self, f )

    ---@type dreamwork.std.fs.ReadRespond
    local respond = f:await()

    if is_registered then
        async_job_unregister( self, f )
    end

    if respond.status ~= 0 then
        error( make_async_message( respond.status, self, false ), 2 )
    end

    return respond.data
end

--- [SHARED AND MENU]
---
--- Replaces the data of a file.
---
---@param data string The new data of the file.
---@async
function File:write( data )
    local mount_path, mount_point = mount_paths[ self ], mount_points[ self ]

    local f = async_write( mount_path, mount_point, data )
    local is_registered = async_job_register( self, f )

    ---@type dreamwork.std.fs.WriteRespond
    local respond = f:await()

    if is_registered then
        async_job_unregister( self, f )
    end

    if respond.status ~= 0 then
        error( make_async_message( respond.status, self, false ), 2 )
    end

    times[ self ] = file_Time( mount_path, mount_point )

    local new_size = string_len( data )

    local directory_object = parents[ self ]
    if directory_object ~= nil then
        size_add( directory_object, -sizes[ self ] )
        size_add( directory_object, new_size )
    end

    sizes[ self ] = new_size

    if watchdog.isWatched( self ) then
        watchdog_Modified:call( self, false )
    end

    return respond
end

--- [SHARED AND MENU]
---
--- Appends data to the end of a file.
---
---@param data string The data to append.
---@async
function File:append( data )
    local mount_path, mount_point = mount_paths[ self ], mount_points[ self ]

    local f = async_append( mount_path, mount_point, data )
    local is_registered = async_job_register( self, f )

    ---@type dreamwork.std.fs.WriteRespond
    local respond = f:await()

    if is_registered then
        async_job_unregister( self, f )
    end

    if respond.status ~= 0 then
        error( make_async_message( respond.status, self, false ), 2 )
    end

    times[ self ] = file_Time( mount_path, mount_point )

    local new_size = file_Size( mount_path, mount_point )

    local directory_object = parents[ self ]
    if directory_object ~= nil then
        size_add( directory_object, -sizes[ self ] )
        size_add( directory_object, new_size )
    end

    sizes[ self ] = new_size

    if watchdog.isWatched( self ) then
        watchdog_Modified:call( self, false )
    end

    return respond
end

--- [SHARED AND MENU]
---
--- Renames a file.
---
---@param name string The new name of the file.
---@async
function File:rename( name )

end

--- [SHARED AND MENU]
---
--- Moves a file to another directory.
---
---@param directory dreamwork.std.fs.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function File:move( directory, name )

end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory dreamwork.std.fs.Directory The directory to copy the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function File:copy( directory, name )

end

--- [SHARED AND MENU]
---
--- Deletes a file.
---
function File:delete()

end

do

    local handlers = {}

    function File:open()

    end

    function File:close()

    end

end

---@param fs_object dreamwork.std.fs.Object
---@param parent dreamwork.std.fs.Directory | nil
local function update_path( fs_object, parent )
    if parent == nil then
        paths[ fs_object ] = "/" .. names[ fs_object ]
    else

        local parent_path = paths[ parent ]

        local uint8_1, uint8_2 = string_byte( parent_path, 1, 2 )
        if uint8_1 == 0x2F --[[ '/' ]] and uint8_2 == nil then
            paths[ fs_object ] = parent_path .. names[ fs_object ]
        else
            paths[ fs_object ] = parent_path .. "/" .. names[ fs_object ]
        end

    end

    if is_directory_object[ fs_object ] then
        ---@cast fs_object dreamwork.std.fs.Directory

        local descendant_list = descendants[ fs_object ]
        for index = 1, descendant_counts[ fs_object ], 1 do
            update_path( descendant_list[ index ], fs_object )
        end
    end
end

---@param directory dreamwork.std.fs.Directory
---@param name string
local function abs_path( directory, name )
    local directory_path = directory.path

    local uint8_1, uint8_2 = string_byte( directory_path, 1, 2 )
    if uint8_1 == 0x2F --[[ '/' ]] and uint8_2 == nil then
        return directory_path .. name
    else
        return directory_path .. "/" .. name
    end
end

---@param directory dreamwork.std.fs.Directory
---@param name string
local function rel_path( directory, name )
    local mount_path = mount_paths[ directory ]
    if mount_path == nil then
        return name
    else
        return mount_path .. "/" .. name
    end
end

---@protected
function Directory:__gc()
    engine_hookCall( "DirectoryGC", self )
end

---@param name string
---@param mount_point string | nil
---@param mount_path string | nil
---@protected
function Directory:__init( name, mount_point, mount_path )
    names[ self ] = name
    is_directory_object[ self ] = true
    mount_paths[ self ] = mount_path
    mount_points[ self ] = mount_point
    update_path( self, nil )
end

---@protected
---@param key string
---@return any
function Directory:__index( key )
    if key == "name" then
        return names[ self ]
    elseif key == "size" then
        return sizes[ self ]
    elseif key == "time" then
        return times[ self ]
    elseif key == "path" then
        return paths[ self ]
    elseif key == "writeable" then
        local mount_point = mount_points[ self ]
        if mount_point == nil then
            return false
        else
            return writeable_mounts[ mount_point ] == true
        end
    elseif key == "parent" then
        return parents[ self ]
    else
        return raw_index( Directory, key )
    end
end

---@protected
---@return string
function Directory:__tostring()
    return string.format( "Directory: %p [%s][%s][%d bytes][%d files][%d directories]", self, self.path, time.toDuration( time_now() - self.time ), self.size, self:count() )
end

---@class dreamwork.std.fs.FileClass : dreamwork.std.fs.File
---@field __base dreamwork.std.fs.File
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.fs.File
local FileClass = class.create( File )

---@class dreamwork.std.fs.DirectoryClass : dreamwork.std.fs.Directory
---@field __base dreamwork.std.fs.Directory
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.fs.Directory
local DirectoryClass = class.create( Directory )

---@param directory dreamwork.std.fs.Directory
---@param descendant dreamwork.std.fs.Object
local function insert( directory, descendant )
    if is_directory_object[ descendant ] == nil then
        error( "new descendant must be a File or a Directory", 2 )
    end

    local name = names[ descendant ]
    local descendants_table = descendants[ directory ]

    local previous = descendants_table[ name ]
    if previous ~= nil then
        if previous == descendant then
            return
        else
            error( "file or directory with the same name already exists", 2 )
        end
    end

    local parent = directory
    while parent ~= nil do
        if parent == descendant then
            error( "descendant directory cannot be parent", 2 )
        end

        parent = parents[ parent ]
    end

    parents[ descendant ] = directory

    local index = descendant_counts[ directory ] + 1
    descendant_counts[ directory ] = index

    indexes[ descendant ] = index

    descendants_table[ index ] = descendant
    descendants_table[ name ] = descendant

    update_path( descendant, directory )

    times[ directory ] = nil
    size_add( directory, sizes[ descendant ] )
end

---@param directory dreamwork.std.fs.Directory
---@param name string
local function eject( directory, name )
    local descendants_table = descendants[ directory ]

    local descendant = descendants_table[ name ]
    if descendant == nil then
        return
    end

    size_add( directory, -sizes[ descendant ] )

    if mount_points[ descendant ] == nil then
        times[ directory ] = time_now()
    else
        times[ directory ] = nil
    end

    update_path( descendant, nil )

    descendants_table[ name ] = nil
    table_remove( descendants_table, indexes[ descendant ] )

    indexes[ descendant ] = nil

    descendant_counts[ directory ] = descendant_counts[ directory ] - 1

    parents[ descendant ] = nil
end

---@param wildcard string | nil
---@return dreamwork.std.fs.File[], integer, dreamwork.std.fs.Directory[], integer
function Directory:select( wildcard )
    local descendants_table = descendants[ self ]

    local directories, directory_count = {}, 0
    local files, file_count = {}, 0

    for index = 1, descendant_counts[ self ], 1 do
        ---@type dreamwork.std.fs.Object
        local fs_object = descendants_table[ index ]
        if is_directory_object[ fs_object ] then
            directory_count = directory_count + 1
            directories[ directory_count ] = fs_object
        else
            file_count = file_count + 1
            files[ file_count ] = fs_object
        end
    end

    local mount_point = mount_points[ self ]

    if mount_point == nil then
        return files, file_count, directories, directory_count
    end

    if wildcard == nil then
        wildcard = "*"
    elseif string_hasByte( wildcard, 0x2F --[[ '/' ]] ) then
        error( "wildcard cannot contain '/'", 2 )
    end

    local mount_path = mount_paths[ self ]
    if mount_path == nil then

        local fs_files, fs_directories = file_Find( wildcard, mount_point )

        for index = 1, #fs_files, 1 do
            local file_name = fs_files[ index ]
            if descendants_table[ file_name ] == nil then
                local file_object = FileClass( file_name, mount_point, file_name )
                insert( self, file_object )

                file_count = file_count + 1
                files[ file_count ] = file_object
            end
        end

        for index = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ index ]
            if descendants_table[ directory_name ] == nil and string_byte( directory_name, 1, 1 ) ~= 0x2F --[[ '/' ]] then
                local directory_object = DirectoryClass( directory_name, mount_point, directory_name )
                insert( self, directory_object )

                directory_count = directory_count + 1
                directories[ directory_count ] = directory_object
            end
        end


    else

        local fs_files, fs_directories = file_Find( mount_path .. "/" .. wildcard, mount_point )

        for index = 1, #fs_files, 1 do
            local file_name = fs_files[ index ]
            if descendants_table[ file_name ] == nil then
                local file_object = FileClass( file_name, mount_point, mount_path .. "/" .. file_name )
                insert( self, file_object )

                file_count = file_count + 1
                files[ file_count ] = file_object
            end
        end

        for index = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ index ]
            if descendants_table[ directory_name ] == nil and string_byte( directory_name, 1, 1 ) ~= 0x2F --[[ '/' ]] then
                local directory_object = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name )
                insert( self, directory_object )

                directory_count = directory_count + 1
                directories[ directory_count ] = directory_object
            end
        end

    end

    return files, file_count, directories, directory_count
end

---@return integer, integer
function Directory:count()
    local file_count, directory_count = 0, 0
    local descendants_table = descendants[ self ]

    for index = 1, descendant_counts[ self ], 1 do
        if is_directory_object[ descendants_table[ index ] ] then
            directory_count = directory_count + 1
        else
            file_count = file_count + 1
        end
    end

    return file_count, directory_count
end

---@param deep_scan boolean
---@param full_update boolean
---@param on_new nil | fun( fs_object: dreamwork.std.fs.Object, is_directory: boolean )
---@param on_finish nil | fun( directory: dreamwork.std.fs.Directory )
function Directory:scan( deep_scan, full_update, on_new, on_finish )
    local descendant_count = descendant_counts[ self ]
    local descendants_table = descendants[ self ]

    local mount_point = mount_points[ self ]
    local mount_path = mount_paths[ self ]

    if full_update then

        size_add( self, -sizes[ self ] )

        for index = 1, descendant_count, 1 do
            local descendant = descendants[ self ][ index ]
            if not is_directory_object[ descendant ] then
                local mount_point = mount_points[ descendant ]
                local size, unix_time

                if mount_point == nil then
                    size = sizes[ descendant ]
                    unix_time = times[ descendant ]
                else
                    local mount_path = mount_paths[ descendant ] or ""
                    size = file_Size( mount_path, mount_point )
                    unix_time = file_Time( mount_path, mount_point )
                end

                times[ descendant ] = unix_time
                sizes[ descendant ] = size

                size_add( self, size )
            end
        end

        if mount_point == nil then
            times[ self ] = time_now()
        else
            times[ self ] = file_Time( mount_path or "", mount_point )
        end

    end

    if mount_point ~= nil then

        local fs_files, fs_directories = file_Find( mount_path == nil and "*" or ( mount_path .. "/*" ), mount_point )

        for i = 1, #fs_files, 1 do
            local file_name = fs_files[ i ]
            if descendants_table[ file_name ] == nil then
                local file_object = FileClass( file_name, mount_point, mount_path == nil and file_name or ( mount_path .. "/" .. file_name ) )
                insert( self, file_object )

                if on_new ~= nil then
                    on_new( file_object, false )
                end
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if descendants_table[ directory_name ] == nil then
                local directory_object = DirectoryClass( directory_name, mount_point, mount_path == nil and directory_name or ( mount_path .. "/" .. directory_name ) )
                insert( self, directory_object )

                if on_new ~= nil then
                    on_new( directory_object, true )
                end
            end
        end

    end

    if on_finish ~= nil then
        on_finish( self )
    end

    if deep_scan then
        for i = 1, descendant_count, 1 do
            local directory = descendants_table[ i ]
            if is_directory_object[ directory ] then
                ---@cast directory dreamwork.std.fs.Directory
                directory:scan( deep_scan, full_update, on_new, on_finish )
            end
        end
    end
end

---@param path_to string
function Directory:get( path_to )
    local segments, segment_count = string_byteSplit( path_to, 0x2F --[[ '/' ]], string_byte( path_to, 1, 1 ) == 0x2F --[[ '/' ]] and 2 or 1 )

    for i = 1, segment_count, 1 do
        local name = segments[ i ]
        local content_value = descendants[ self ][ name ]

        if content_value == nil then
            ---@cast self dreamwork.std.fs.Directory

            local mount_point = mount_points[ self ]
            if mount_point == nil then
                return nil, false
            end

            local mount_path = rel_path( self, name )

            if file_Exists( mount_path, mount_point ) then
                if file_IsDir( mount_path, mount_point ) then
                    local directory_object = DirectoryClass( name, mount_point, mount_path )
                    insert( self, directory_object )

                    if i == segment_count then
                        return directory_object, true
                    else
                        self = directory_object
                    end
                elseif i == segment_count then
                    local file_object = FileClass( name, mount_point, mount_path )
                    insert( self, file_object )
                    return file_object, false
                else
                    return nil, false
                end
            else
                return nil, false
            end
        elseif is_directory_object[ content_value ] then
            if i == segment_count then
                ---@diagnostic disable-next-line: cast-type-mismatch
                ---@cast content_value dreamwork.std.fs.File
                return content_value, true
            else
                self = content_value
            end
        elseif i == segment_count then
            return content_value, false
        else
            return nil, false
        end
    end

    return nil, false
end

---@return boolean
function Directory:isEmpty()
    local file_count, directory_count = self:count()
    return file_count == 0 and directory_count == 0
end

---@param file_callback nil | fun( file: dreamwork.std.fs.File )
---@param directory_callback nil | fun( directory: dreamwork.std.fs.Directory )
function Directory:foreach( file_callback, directory_callback )
    local files, file_count,
        directories, directory_count = self:select()

    if file_callback == nil then
        if directory_callback == nil then
            return
        end
    else
        for index = 1, file_count, 1 do
            ---@type dreamwork.std.fs.File
            ---@diagnostic disable-next-line: param-type-mismatch
            file_callback( files[ index ] )
        end
    end

    for index = 1, directory_count, 1 do
        ---@type dreamwork.std.fs.Directory
        ---@diagnostic disable-next-line: assign-type-mismatch
        local directory = directories[ index ]

        if directory_callback ~= nil then
            directory_callback( directory )
        end

        directory:foreach( file_callback, directory_callback )
    end
end

---@param parent dreamwork.std.fs.Directory
---@param name string
---@param forced? boolean
---@return dreamwork.std.fs.Directory | nil new_directory
---@return nil | string error_message
local function create_directory( parent, name, forced )
    local directory_object = descendants[ parent ][ name ]
    if directory_object == nil then
        local mount_point = mount_points[ parent ]
        if mount_point == nil then
            return DirectoryClass( name ), nil
        end

        local mount_path = rel_path( parent, name )

        if file_Exists( mount_path, mount_point ) then
            if file_IsDir( mount_path, mount_point ) then
                return DirectoryClass( name, mount_point, mount_path ), nil
            elseif forced then
                if deletable_mounts[ mount_point ] then
                    file_Delete( mount_path, mount_point )
                else
                    return nil, "Path '" .. abs_path( parent, name ) .. "' does not support file removal."
                end

                eject( parent, name )

                if writeable_mounts[ mount_point ] then
                    ---@diagnostic disable-next-line: redundant-parameter
                    file_CreateDir( mount_path, mount_point )
                else
                    return nil, "Path '" .. abs_path( parent, name ) .. "' does not support directory creation."
                end

                return DirectoryClass( name, mount_point, mount_path ), nil
            else
                return nil, "Path '" .. abs_path( parent, name ) .. "' is already occupied by a file."
            end
        elseif writeable_mounts[ mount_point ] then
            ---@diagnostic disable-next-line: redundant-parameter
            file_CreateDir( mount_path, mount_point )

            return DirectoryClass( name, mount_point, mount_path ), nil
        else
            return nil, "Path '" .. abs_path( parent, name ) .. "' does not support directory creation."
        end
    elseif is_directory_object[ directory_object ] then
        ---@cast directory_object dreamwork.std.fs.Directory
        return directory_object, nil
    elseif forced then
        local mount_point = mount_points[ directory_object ]
        if mount_point == nil then
            eject( parent, name )
            return DirectoryClass( name ), nil
        end

        local mount_path = rel_path( parent, name )

        if deletable_mounts[ mount_point ] then
            file_Delete( mount_path, mount_point )
        else
            return nil, "Path '" .. abs_path( parent, name ) .. "' does not support file removal."
        end

        eject( parent, name )

        if writeable_mounts[ mount_point ] then
            ---@diagnostic disable-next-line: redundant-parameter
            file_CreateDir( mount_path, mount_point )
        else
            return nil, "Path '" .. abs_path( parent, name ) .. "' does not support directory creation."
        end

        return DirectoryClass( name, mount_point, mount_path ), nil
    else
        return nil, "Path '" .. abs_path( parent, name ) .. "' is already occupied by a file."
    end
end

---@param directory_path string
---@param forced? boolean
---@return dreamwork.std.fs.Directory
function Directory:makeDirectory( directory_path, forced )
    local segments, segment_count = string_byteSplit( directory_path, 0x2F --[[ '/' ]], string_byte( directory_path, 1, 1 ) == 0x2F --[[ '/' ]] and 2 or 1 )

    for i = 1, segment_count, 1 do
        local directory_object, error_message = create_directory( self, segments[ i ], forced )
        if directory_object == nil then
            error( error_message, 2 )
        end

        insert( self, directory_object )
        self = directory_object
    end

    return self
end

---@param name string
---@return dreamwork.std.fs.Object fs_object
---@return boolean is_directory
function Directory:touch( name )
    if string_byte( name, 1, 1 ) == nil then
        error( "file or directory name cannot be empty", 2 )
    end

    local fs_object = descendants[ self ][ name ]

    if fs_object == nil then
        local mount_point = mount_points[ self ]
        if mount_point == nil or not writeable_mounts[ mount_point ] then
            error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory creation.", 2 )
        end

        local mount_path = rel_path( self, name )

        local handler = file_Open( mount_path, "wb", mount_point )
        if handler == nil then
            error( "Unknown filesystem error, handler is not available.", 2 )
        end

        FILE_Close( handler )

        fs_object = FileClass( name, mount_point, mount_path )
        insert( self, fs_object )
        return fs_object, false
    end

    local mount_point = mount_points[ fs_object ]
    if mount_point == nil or not writeable_mounts[ mount_point ] then
        error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory creation.", 2 )
    end

    if is_directory_object[ fs_object ] then
        -- Doesn't work...
        ---@diagnostic disable-next-line: redundant-parameter
        -- file_CreateDir( rel_path( self, name ), mount_point )

        local tmp_path = rel_path( self, name .. "/^dreamwork_tmp$.dat" )

        local handler = file_Open( tmp_path, "wb", mount_point )
        if handler == nil then
            error( "Unknown filesystem error, handler is not available.", 2 )
        else
            FILE_Close( handler )
        end

        file_Delete( tmp_path, mount_point )

        times[ fs_object ] = file_Time( rel_path( self, name ), mount_point )

        return fs_object, true
    end

    local mount_path = mount_paths[ fs_object ]

    local handler = file_Open( mount_path, "wb", mount_point )
    if handler == nil then
        error( "Unknown filesystem error, handler is not available.", 2 )
    end

    FILE_Close( handler )

    times[ fs_object ] = file_Time( mount_path, mount_point )

    return fs_object, false
end

--- [SHARED AND MENU]
---
--- Renames a file.
---
---@param name string The new name of the file.
---@async
function Directory:rename( name )

end

--- [SHARED AND MENU]
---
--- Moves a file to another directory.
---
---@param directory dreamwork.std.fs.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function Directory:move( directory, name )

end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory dreamwork.std.fs.Directory The directory to copy the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function Directory:copy( directory, name )

end

--- [SHARED AND MENU]
---
--- Deletes a directory.
---
function Directory:delete()

end

-- TODO: make this function local, maybe required rewrite
---@param name string
---@param forced? boolean
---@param recursive? boolean
function Directory:remove( name, forced, recursive )
    if string_byte( name, 1, 1 ) == nil then
        error( "file or directory name cannot be empty", 2 )
    end

    local fs_object = descendants[ self ][ name ]

    if fs_object == nil then
        local mount_point = mount_points[ self ]
        if mount_point == nil or not deletable_mounts[ mount_point ] then
            error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory removal.", 2 )
        end

        local mount_path = rel_path( self, name )

        if file_Exists( mount_path, mount_point ) then
            if file_IsDir( mount_path, mount_point ) then
                if recursive then
                    local directory_object = DirectoryClass( name, mount_point, mount_path )
                    local files, file_count,
                        directories, directory_count = directory_object:select()

                    for i = 1, file_count, 1 do
                        local file_object = files[ i ]
                        file_Delete( mount_paths[ file_object ], mount_points[ file_object ] )
                        eject( self, file_object.name )
                    end

                    for i = 1, directory_count, 1 do
                        directory_object:remove( directories[ i ].name, forced, recursive )
                    end
                else

                    local files, directories = file_Find( mount_path .. "/*", mount_point )
                    if ( #files + #directories ) ~= 0 then
                        error( "Directory '" .. abs_path( self, name ) .. "' is not empty.", 2 )
                    end

                end
            end
        elseif not forced then
            error( "Path '" .. abs_path( self, name ) .. "' does not exist.", 2 )
        end

        file_Delete( mount_path, mount_point )
        eject( self, name )
        return
    end

    local mount_point = mount_points[ fs_object ]
    if mount_point == nil or not deletable_mounts[ mount_point ] then
        error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory removal.", 2 )
    end

    if is_directory_object[ fs_object ] then
        ---@cast fs_object dreamwork.std.fs.Directory
        if recursive then
            local files, file_count,
                directories, directory_count = fs_object:select()

            for i = 1, file_count, 1 do
                local file_object = files[ i ]
                file_Delete( mount_paths[ file_object ], mount_points[ file_object ] )
                eject( self, file_object.name )
            end

            for i = 1, directory_count, 1 do
                fs_object:remove( directories[ i ].name, forced, recursive )
            end
        else

            local files, directories = file_Find( mount_points[ fs_object ] .. "/*", mount_point )
            if ( #files + #directories ) ~= 0 then
                error( "Directory '" .. abs_path( self, name ) .. "' is not empty.", 2 )
            end

        end
    end

    file_Delete( mount_paths[ fs_object ], mount_point )
    eject( self, name )
end

---@param prefix? string
---@param is_last? boolean
---@return string
function Directory:toStringTree( prefix, is_last )
    local lines, line_count = {}, 1

    local descendants_table = descendants[ self ]

    local next_prefix
    if prefix == nil then
        lines[ 1 ] = tostring( self )
        next_prefix = " "
    else
        lines[ 1 ] = prefix .. ( is_last and "╚═ " or "╠═ " ) .. tostring( self )

        local spaces = ( is_last and "    " or " " )
        next_prefix = prefix .. ( is_last and spaces or "║  " .. spaces )
    end

    local children_length = descendant_counts[ self ]

    for i = 1, children_length, 1 do
        line_count = line_count + 1
        lines[ line_count ] = next_prefix .. "║  "

        line_count = line_count + 1

        local descendant = descendants_table[ i ]
        if is_directory_object[ descendant ] then
            ---@cast descendant dreamwork.std.fs.Directory
            lines[ line_count ] = descendant:toStringTree( next_prefix, i == children_length )
        else
            ---@cast descendant dreamwork.std.fs.File
            lines[ line_count ] = next_prefix .. string.format( "%s %s", i == children_length and "╚═ " or "╠═ ", descendant )
        end
    end

    return table_concat( lines, "\n", 1, line_count )
end

local root = DirectoryClass( "", "BASE_PATH" )

---@param game_info dreamwork.engine.GameInfo
engine.hookCatch( "GameMounted", function( game_info )
    local game_folder = game_info.folder
    eject( root, game_folder )
    insert( root, DirectoryClass( game_folder, game_folder ) )
end, 2 )

---@param game_info dreamwork.engine.GameInfo
engine.hookCatch( "GameUnmounted", function( game_info )
    eject( root, game_info.folder )
end, 2 )

do

    local garrysmod = DirectoryClass( "garrysmod", "MOD" )
    insert( root, garrysmod )

    local data = DirectoryClass( "data", "DATA" )
    insert( garrysmod, data )

end

do

    local workspace = DirectoryClass( "workspace", "GAME" )
    insert( root, workspace )

    local addons = DirectoryClass( "addons" )
    insert( workspace, addons )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "AddonMounted", function( addon_info )
        local addon_folder = addon_info.folder
        eject( addons, addon_folder )
        insert( addons, DirectoryClass( addon_folder, addon_info.title ) )
    end, 2 )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "AddonUnmounted", function( addon_info )
        eject( addons, addon_info.folder )
    end, 2 )

    local download = DirectoryClass( "download", "DOWNLOAD" )
    insert( workspace, download )

    local lua = DirectoryClass( "lua", ( SERVER and "lsv" or ( CLIENT and "lcl" or ( MENU and "LuaMenu" or "LUA" ) ) ) )
    insert( workspace, lua )

    local map = DirectoryClass( "map", "BSP" )
    insert( workspace, map )

end

-- TODO: fs hooks

local function prepare_path( path_to )
    local resolved_path = path_resolve( path_to )

    local resolved_length = string_len( resolved_path )
    if string_byte( resolved_path, resolved_length, resolved_length ) == 0x2F --[[ '/' ]] then
        resolved_path, resolved_length = string_byteTrim( resolved_path, 0x2F, true, resolved_length )
    end

    return resolved_path
end

--- [SHARED AND MENU]
---
--- Returns the file or directory by given path as a `dreamwork.std.fs.File` or `dreamwork.std.fs.Directory` object.
---
---@param path_to string The path to the file or directory.
---@return dreamwork.std.fs.Object | nil fs_object The file or directory.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.get( path_to )
    return root:get( prepare_path( path_to ) )
end

--- [SHARED AND MENU]
---
--- Creates a directory by given path.
---
--- Does nothing if the directory already exists.
---
--- If `forced` is `true`, all files in the path will be deleted if they exist.
---
---@param directory_path string
---@param forced? boolean
function fs.makeDirectory( directory_path, forced )
    return root:makeDirectory( prepare_path( directory_path ), forced )
end

--- [SHARED AND MENU]
---
--- Creates a file by given path.
---
--- Does nothing if the file already exists.
---
--- If `forced` is `true`, all files in the path will be deleted if they exist.
---
---@param file_path string The path to the file to create.
---@param forced? boolean
function fs.touch( file_path, forced )
    local directory_path, file_name = path_split( prepare_path( file_path ), false )

    local directory, is_directory = root:get( directory_path )
    if directory == nil then
        if forced then
            directory = root:makeDirectory( directory_path, true )
        else
            error( "Path '" .. directory_path .. "' does not exist.", 2 )
        end
    elseif not is_directory then
        if forced then
            directory = root:makeDirectory( directory_path, true )
        else
            error( "Path '" .. directory_path .. "' is not a directory.", 2 )
        end
    end

    ---@cast directory dreamwork.std.fs.Directory
    return directory:touch( file_name )
end

--- [SHARED AND MENU]
---
--- Removes a file or directory by given path.
---
---@param path_to string The path to the file or directory.
---@param forced? boolean If `true`, the file or directory will be deleted if it already exists.
---@param recursive? boolean If `true`, the directory will be deleted recursively.
function fs.remove( path_to, forced, recursive )
    local directory_path, file_name = path_split( prepare_path( path_to ), false )

    local directory, is_directory = root:get( directory_path )
    if directory == nil then
        if forced then
            return
        else
            error( "Path '" .. directory_path .. "' does not exist.", 2 )
        end
    elseif not is_directory then
        if forced then
            return
        else
            error( "Path '" .. directory_path .. "' is not a directory.", 2 )
        end
    end

    ---@cast directory dreamwork.std.fs.Directory
    return directory:remove( file_name, forced, recursive )
end

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean exists Returns `true` if the file or directory exists, otherwise `false`.
function fs.exists( path_to )
    return root:get( prepare_path( path_to ) ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists and is not a file by given path.
---
---@param directory_path string The path to the directory.
---@return boolean exists Returns `true` if the directory exists and is not a file, otherwise `false`.
function fs.isExistingDirectory( directory_path )
    local directory_object, is_directory = root:get( prepare_path( directory_path ) )
    return directory_object ~= nil and is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file exists and is not a directory by given path.
---
---@param file_path string The path to the fs.
---@return boolean exists Returns `true` if the file exists and is not a directory, otherwise `false`.
function fs.isExistingFile( file_path )
    local file_object, is_directory = root:get( prepare_path( file_path ) )
    return file_object ~= nil and not is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file or directory is a directory by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.isDirectory( path_to )
    local _, is_directory = root:get( prepare_path( path_to ) )
    return is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file or directory is empty by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean empty Returns `true` if the file or directory is empty, otherwise `false`.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.isEmpty( path_to, forced )
    local fs_object, is_directory = root:get( prepare_path( path_to ) )
    if fs_object == nil then
        if forced then
            return true, false
        else
            error( "Path '" .. path_to .. "' does not exist.", 2 )
        end
    elseif is_directory then
        ---@cast fs_object dreamwork.std.fs.Directory
        return fs_object:isEmpty(), true
    else
        return fs_object.size == 0, false
    end
end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function fs.time( file_path, forced )
    local fs_object = root:get( prepare_path( file_path ) )
    if fs_object == nil then
        if forced then
            return 0
        else
            error( "Path '" .. file_path .. "' does not exist.", 2 )
        end
    else
        return fs_object.time
    end
end

--- [SHARED AND MENU]
---
--- Returns the size of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer size The size of the file or directory in bytes.
function fs.size( file_path, forced )
    local fs_object = root:get( prepare_path( file_path ) )
    if fs_object == nil then
        if forced then
            return 0
        else
            error( "Path '" .. file_path .. "' does not exist.", 2 )
        end
    else
        return fs_object.size
    end
end

--- [SHARED AND MENU]
---
--- Returns the list of files and directories in a directory by given path.
---
--- Can be used for file search by setting `searchable` to a wildcard string.
---
---@param directory_path string The path to the directory.
---@param wildcard? string The wildcard to search for.
---@return dreamwork.std.fs.File[] files The list of files in the directory.
---@return integer file_count The number of files in the directory.
---@return dreamwork.std.fs.Directory[] directories The list of directories in the directory.
---@return integer directory_count The number of directories in the directory.
function fs.select( directory_path, wildcard )
    local directory_object, is_directory = root:get( prepare_path( directory_path ) )
    if directory_object == nil or not is_directory then
        return {}, 0, {}, 0
    else
        ---@cast directory_object dreamwork.std.fs.Directory
        return directory_object:select( wildcard )
    end
end

do

    local futures_yield = std.futures.yield

    ---@param file_object dreamwork.std.fs.File
    ---@async
    local function iterate_file( file_object )
        return futures_yield( file_object.path, false )
    end

    ---@param directory_object dreamwork.std.fs.Directory
    ---@async
    local function iterate_directory( directory_object )
        return futures_yield( directory_object.path, true )
    end

    ---@async
    function fs.iterator( directory_path )
        local directory_object, is_directory = root:get( prepare_path( directory_path ) )
        if directory_object ~= nil and is_directory then
            ---@cast directory_object dreamwork.std.fs.Directory
            directory_object:foreach( iterate_file, iterate_directory )
        end
    end

end

--- [SHARED AND MENU]
---
--- Returns the data of a file by given path.
---
---@param file_path string The path to the file.
---@return string data The data of the file.
---@async
function fs.read( file_path )

end

--- [SHARED AND MENU]
---
--- Writes data to a file by given path.
---
---@param file_path string The path to the file.
---@param data string The data to write to the file.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@param recursive? boolean If `true`, all directories in the path will be created if they don't exist.
---@async
function fs.write( file_path, data, forced, recursive )

end

--- [SHARED AND MENU]
---
--- Appends data to a file by given path.
---
---@param file_path string The path to the file.
---@param data string The data to append to the file.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@param recursive? boolean If `true`, all directories in the path will be created if they don't exist.
---@async
function fs.append( file_path, data, forced, recursive )

end

--- [SHARED AND MENU]
---
--- Deletes a file or directory by given path.
---
---@param path_to string The path to the file or directory.
---@param forced? boolean If `true`, the file or directory will be deleted even if it is not empty.
---@param recursive? boolean If `true`, all directories in the path will be deleted if they are empty.
function fs.delete( path_to, forced, recursive )

end

--- [SHARED AND MENU]
---
--- Renames a file or directory by given path.
---
---@param path_to string The path to the file or directory.
---@param name string The new name of the file or directory.
---@param forced? boolean If `true`, the file or directory will be renamed even if it already exists.
---@param recursive? boolean If `true`, all directories in the path will be renamed if they already exist.
---@async
function fs.rename( path_to, name, forced, recursive )

end

--- [SHARED AND MENU]
---
--- Copies a file or directory by given path.
---
---@param source_path string The path to the file or directory to copy.
---@param target_path string The path to the file or directory to copy to.
---@param forced? boolean If `true`, the file or directory will be copied even if it already exists.
---@param recursive? boolean If `true`, all directories in the path will be copied if they already exist.
---@async
function fs.copy( source_path, target_path, forced, recursive )

end

--- [SHARED AND MENU]
---
--- Moves a file or directory by given path.
---
---@param source_path string The path to the file or directory to move.
---@param target_path string The path to the file or directory to move to.
---@param forced? boolean If `true`, the file or directory will be moved even if it already exists.
---@param recursive? boolean If `true`, all directories in the path will be moved if they already exist.
---@async
function fs.move( source_path, target_path, forced, recursive )

end

-- TODO: Reader and Writer or something better like FileClass that can returns FileReader and FileWriter in cases

--[[

    TODO:

    _G.LoadAddonPresets
    _G.SaveAddonPresets

    https://wiki.facepunch.com/gmod/Global.LoadPresets
    https://wiki.facepunch.com/gmod/Global.SavePresets

]]

-- watchdog_Created:attach( function( fs_object )
--     dreamwork.Logger:info( "%s '%s' was created.", is_directory_object[ fs_object ] and "Directory" or "File", fs_object.path )
-- end )

-- watchdog_Deleted:attach( function( fs_object )
--     dreamwork.Logger:info( "%s '%s' was deleted.", is_directory_object[ fs_object ] and "Directory" or "File", fs_object.path )
-- end )

-- watchdog_Modified:attach( function( fs_object )
--     dreamwork.Logger:info( "%s '%s' was modified.", is_directory_object[ fs_object ] and "Directory" or "File", fs_object.path )
-- end )

-- watchdog.watch( fs.get( "/garrysmod/data" ) )

-- fs.get( "/garrysmod/data" ):scan()

-- std.setTimeout( function()
--     root:get( "workspace/lua/dreamwork" ):scan( true, true )
--     std.print( root:toStringTree())
-- end, 1 )

