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
local path_getExtension = path.getExtension

---@type table<string, boolean>
local reserved_names = {
    [ "^dreamwork_tmp$.dat" ] = true
}

---@class dreamwork.std.fs.MountInfo
---@field writable boolean If `true` the mount allows creating directories inside.
---@field writable_extensions table<string, boolean> The extension map of allowed extensions to write.
---@field deletable boolean If `true` the mount allows deleting files and directories.

---@type table<string, dreamwork.std.fs.MountInfo>
local fstab = {
    [ "DATA" ] = {
        writable = true,
        deletable = true,
        writable_extensions = {
            -- Taken from https://wiki.facepunch.com/gmod/file.Write
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
            ogg = true
        }
    },
    [ "MOD" ] = {
        writable = false,
        deletable = MENU,
        writable_extensions = {}
    }
}


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
    gc_setTableRules( tmp, false, true )

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
    gc_setTableRules( tmp, false, true )

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
---@field writable boolean If `true`, the directory is directly writable.
---@field parent dreamwork.std.fs.Directory | nil The parent directory. **READ-ONLY**
local Directory = class.base( "Directory", true )

---@class dreamwork.std.fs.FileClass : dreamwork.std.fs.File
---@field __base dreamwork.std.fs.File
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.fs.File
local FileClass = class.create( File )

---@class dreamwork.std.fs.DirectoryClass : dreamwork.std.fs.Directory
---@field __base dreamwork.std.fs.Directory
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.fs.Directory
local DirectoryClass = class.create( Directory )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias File dreamwork.std.fs.File
---@alias Directory dreamwork.std.fs.Directory
---@alias dreamwork.std.fs.Object dreamwork.std.fs.File | dreamwork.std.fs.Directory

---@type table<dreamwork.std.fs.Object, string>
local names = {}

do

    local invalid_characters = {
        [ 0x22 ] = true, -- "
        [ 0x27 ] = true, -- '
        [ 0x2A ] = true, -- *
        [ 0x2F ] = true, -- /
        [ 0x5C ] = true, -- \
        [ 0x7C ] = true, -- |
        [ 0x7F ] = true, -- DEL
        [ 0x3A ] = true  -- :
    }

    -- Control characters
    for i = 0, 31, 1 do
        invalid_characters[ i ] = true
    end

    -- Non-printable characters
    for i = 59, 63, 1 do
        invalid_characters[ i ] = true
    end

    setmetatable( names, {
        __newindex = function( self, fs_object, name )
            for index = 1, string_len( name ), 1 do
                if invalid_characters[ string_byte( name, index, index ) ] then
                    std.errorf( 2, false, "directory or file name contains invalid character \\%X at index %d in '%s'", string_byte( name, index, index ), index, name )
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

---@type table<dreamwork.std.fs.Object, string>
local mount_points = {}
gc_setTableRules( mount_points, true, false )

---@type table<dreamwork.std.fs.Object, string>
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

---@type table<dreamwork.std.fs.Object, dreamwork.std.futures.Future[]>
local async_jobs = {}
gc_setTableRules( async_jobs, true, false )

---@type table<dreamwork.std.fs.Object, integer>
local async_job_counts = {}

setmetatable( async_job_counts, {
    __index = function()
        return 0
    end,
    __mode = "k"
} )

--- [SHARED AND MENU]
---
--- Registers a file or directory for asynchronous monitoring.
---
---@param fs_object dreamwork.std.fs.Object
---@param future dreamwork.std.futures.Future
---@return boolean is_registered
local function async_job_register( fs_object, future )
    if future:isFinished() then
        return false
    end

    local job_count = async_job_counts[ fs_object ]

    if job_count == 0 then
        async_jobs[ fs_object ] = { [ 0 ] = Future() }
    end

    job_count = job_count + 1
    async_jobs[ fs_object ][ job_count ] = future

    async_job_counts[ fs_object ] = job_count

    local parent = parents[ fs_object ]
    if parent ~= nil then
        async_job_register( parent, future )
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
local function async_job_unregister( fs_object, future )
    local job_count = async_job_counts[ fs_object ]
    if job_count == 0 then
        return false
    end

    local jobs = async_jobs[ fs_object ]

    for i = job_count, 1, -1 do
        if jobs[ i ] == future then
            table_remove( jobs, i )
            job_count = job_count - 1

            if job_count == 0 then
                jobs[ 0 ]:setResult()
                async_jobs[ fs_object ] = nil
                async_job_counts[ fs_object ] = nil
            else
                async_job_counts[ fs_object ] = job_count
            end

            local parent = parents[ fs_object ]
            if parent ~= nil then
                async_job_unregister( parent, future )
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
local function is_busy( fs_object )
    return async_job_counts[ fs_object ] ~= 0
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
        for i = 1, descendant_counts[ fs_object ], 1 do
            update_path( descendant_list[ i ], fs_object )
        end
    end
end

---@param directory_object dreamwork.std.fs.Directory
---@param name string
local function abs_path( directory_object, name )
    local directory_path = paths[ directory_object ]

    local uint8_1, uint8_2 = string_byte( directory_path, 1, 2 )
    if uint8_1 == 0x2F --[[ '/' ]] and uint8_2 == nil then
        return directory_path .. name
    else
        return directory_path .. "/" .. name
    end
end

---@param directory_object dreamwork.std.fs.Directory
---@param name string
local function rel_path( directory_object, name )
    local mount_path = mount_paths[ directory_object ]
    if mount_path == nil then
        return name
    else
        return mount_path .. "/" .. name
    end
end

---@param directory_object dreamwork.std.fs.Directory
---@param byte_count integer
local function size_add( directory_object, byte_count )
    while directory_object ~= nil do
        sizes[ directory_object ] = sizes[ directory_object ] + byte_count
        directory_object = parents[ directory_object ]
    end
end

---@param directory_object dreamwork.std.fs.Directory
---@param descendant dreamwork.std.fs.Object
local function insert( directory_object, descendant )
    if is_directory_object[ descendant ] == nil then
        error( "new descendant must be a File or a Directory", 2 )
    end

    local name = names[ descendant ]
    local descendants_table = descendants[ directory_object ]

    local previous = descendants_table[ name ]
    if previous ~= nil then
        if previous == descendant then
            return
        else
            error( "file or directory with the same name already exists", 2 )
        end
    end

    local parent = directory_object
    while parent ~= nil do
        if parent == descendant then
            error( "descendant directory cannot be parent", 2 )
        end

        parent = parents[ parent ]
    end

    parents[ descendant ] = directory_object

    local index = descendant_counts[ directory_object ] + 1
    descendant_counts[ directory_object ] = index

    indexes[ descendant ] = index

    descendants_table[ index ] = descendant
    descendants_table[ name ] = descendant

    update_path( descendant, directory_object )

    times[ directory_object ] = nil
    size_add( directory_object, sizes[ descendant ] )
end

---@param directory_object dreamwork.std.fs.Directory
---@param name string
local function eject( directory_object, name )
    local descendants_table = descendants[ directory_object ]

    local descendant = descendants_table[ name ]
    if descendant == nil then
        return
    end

    size_add( directory_object, -sizes[ descendant ] )

    if mount_points[ descendant ] == nil then
        times[ directory_object ] = time_now()
    else
        times[ directory_object ] = nil
    end

    update_path( descendant, nil )

    descendants_table[ name ] = nil
    table_remove( descendants_table, indexes[ descendant ] )

    indexes[ descendant ] = nil

    descendant_counts[ directory_object ] = descendant_counts[ directory_object ] - 1

    parents[ descendant ] = nil
end

---@param directory_object dreamwork.std.fs.Directory
---@param name string
---@return dreamwork.std.fs.Object | nil fs_object
---@return boolean is_directory
local function directory_get( directory_object, name )
    if reserved_names[ name ] then
        return nil, false
    end

    local fs_object = descendants[ directory_object ][ name ]
    if fs_object ~= nil then
        return fs_object, is_directory_object[ fs_object ]
    end

    local mount_point = mount_points[ directory_object ]
    if mount_point == nil then
        return nil, false
    end

    local mount_path = rel_path( directory_object, name )

    if file_Exists( mount_path, mount_point ) then
        local is_directory = file_IsDir( mount_path, mount_point )

        if is_directory then
            fs_object = DirectoryClass( name, mount_point, mount_path )
        else
            fs_object = FileClass( name, mount_point, mount_path )
        end

        insert( directory_object, fs_object )

        return fs_object, is_directory
    end

    return nil, false
end

---@param directory_object dreamwork.std.fs.Directory
---@param path_to string
---@param start_position? integer
---@return dreamwork.std.fs.Object | nil fs_object
---@return boolean is_directory
local function directory_lookup( directory_object, path_to, start_position )
    local segments, segment_count = string_byteSplit( path_to, 0x2F --[[ '/' ]], start_position )

    for i = 1, segment_count, 1 do
        local fs_object, is_directory = directory_get( directory_object, segments[ i ] )
        if i == segment_count then
            return fs_object, is_directory
        elseif is_directory then
            ---@cast fs_object dreamwork.std.fs.Directory
            directory_object = fs_object
        else
            break
        end
    end

    return nil, false
end

---@param file_object dreamwork.std.fs.File
---@param stack_level integer
---@async
local function delete_file( file_object, stack_level )
    if stack_level == nil then
        stack_level = 1
    end

    stack_level = stack_level + 1

    local mount_point = mount_points[ file_object ]
    if mount_point == nil then
        std.errorf( stack_level, false, "'%s' cannot be deleted, file is not mounted.", file_object )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not mount_info.deletable then
        std.errorf( stack_level, false, "'%s' cannot be deleted, parent directory is not allowing file deletion.", file_object )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    if is_busy( file_object ) then
        async_jobs[ file_object ][ 0 ]:await()
    end

    local parent = parents[ file_object ]
    if parent == nil then
        std.errorf( stack_level, false, "'%s' cannot be deleted, file already deleted.", paths[ file_object ] )
    end

    ---@cast parent dreamwork.std.fs.Directory

    eject( parent, names[ file_object ] )
    file_Delete( mount_paths[ file_object ], mount_point )
end

---@param directory_object dreamwork.std.fs.Directory
---@param recursive boolean
---@async
local function delete_directory( directory_object, recursive, stack_level )
    if stack_level == nil then
        stack_level = 1
    end

    stack_level = stack_level + 1

    if async_job_counts[ directory_object ] ~= 0 then
        async_jobs[ directory_object ][ 0 ]:await()
    end

    local mount_point = mount_points[ directory_object ]
    if mount_point == nil then
        std.errorf( stack_level, false, "'%s' cannot be deleted, directory is not mounted.", directory_object )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not mount_info.deletable then
        std.errorf( stack_level, false, "'%s' cannot be deleted, parent directory is not allowing directory deletion.", directory_object )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    local mount_path = mount_paths[ directory_object ] or ""

    if not ( file_Exists( mount_path, mount_point ) and file_IsDir( mount_path, mount_point ) ) then
        return
    end

    if recursive then

        local files, file_count,
            directories, directory_count = directory_object:select()

        for i = 1, directory_count, 1 do
            delete_directory( directories[ i ], recursive, stack_level )
        end

        for i = 1, file_count, 1 do
            delete_file( files[ i ], stack_level )
        end

    else

        directory_object:scan( false, false )

        local file_count, directory_count = directory_object:count()
        if file_count ~= 0 or directory_count ~= 0 then
            std.errorf( stack_level, false, "'%s' cannot be deleted, directory is not empty.", paths[ directory_object ] )
        end

    end

    if is_busy( directory_object ) then
        async_jobs[ directory_object ][ 0 ]:await()
    end

    local parent = parents[ directory_object ]
    if parent == nil then
        std.errorf( stack_level, false, "'%s' cannot be deleted, directory is root or already deleted.", paths[ directory_object ] )
    end

    ---@cast parent dreamwork.std.fs.Directory

    eject( parent, names[ directory_object ] )
    file_Delete( mount_path, mount_point )
end

-- TODO: rework delete/create/modify events for watchdog to work properly with manual deletion

---@param parent dreamwork.std.fs.Directory
---@param name string
---@param forced boolean
---@param stack_level integer
---@return dreamwork.std.fs.Directory new_directory
---@async
local function make_directory( parent, name, forced, stack_level )
    stack_level = stack_level + 1

    if reserved_names[ name ] then
        std.errorf( stack_level, false, "Directory cannot be created with reserved name '%s'.", name )
    end

    local fs_object, is_directory = directory_get( parent, name )
    if fs_object ~= nil then
        if is_directory then
            ---@cast fs_object dreamwork.std.fs.Directory
            return fs_object
        elseif forced then
            ---@cast fs_object dreamwork.std.fs.File
            fs_object:delete()
        else
            std.errorf( stack_level, false, "Directory cannot be created with name '%s', '%s' already exists.", name, fs_object )
        end
    end

    local mount_point = mount_points[ parent ]
    if mount_point == nil then
        std.errorf( stack_level, false, "'%s' won't allow directory creation, directory is not mounted.", parent )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not mount_info.writable then
        std.errorf( stack_level, false, "'%s' won't allow directory creation, parent directory is not writable.", parent )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    local mount_path = rel_path( parent, name )

    ---@diagnostic disable-next-line: redundant-parameter
    file_CreateDir( mount_path, mount_point )

    local directory_object = DirectoryClass( name, mount_point, mount_path )
    insert( parent, directory_object )
    return directory_object
end

---@param parent dreamwork.std.fs.Directory
---@param name string
---@param forced boolean
---@param stack_level? integer
---@param data? string
---@return dreamwork.std.fs.File
---@async
local function make_file( parent, name, forced, stack_level, data )
    if stack_level == nil then
        stack_level = 1
    end

    stack_level = stack_level + 1

    if reserved_names[ name ] then
        std.errorf( stack_level, false, "File cannot be created with reserved name '%s'.", name )
    end

    local fs_object, is_directory = directory_get( parent, name )
    if fs_object ~= nil then
        if is_directory then
            if forced then
                ---@cast fs_object dreamwork.std.fs.Directory
                fs_object:delete( true )
            else
                std.errorf( stack_level, false, "File cannot be created with name '%s', '%s' already exists.", name, fs_object )
            end
        else
            ---@cast fs_object dreamwork.std.fs.File
            return fs_object
        end
    end

    local mount_point = mount_points[ parent ]
    if mount_point == nil then
        std.errorf( stack_level, false, "'%s' won't allow file creation, directory is not mounted.", parent )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil then
        std.errorf( stack_level, false, "'%s' won't allow file creation, parent directory is not writable.", parent )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    if not mount_info.writable_extensions[ path_getExtension( name, false ) ] then
        if forced then
            name = name .. ".dat"
        else
            std.errorf( stack_level, false, "'%s' won't allow file creation with name '%s', parent directory is not allowing this extension.", parent, name )
        end
    end

    local file_object = FileClass( name, mount_point, rel_path( parent, name ) )
    insert( parent, file_object )

    file_object:write( data or "" )

    return file_object
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

        local fs_object, is_directory = fs.get( "/garrysmod/" .. file_path )
        if fs_object == nil or reserved_names[ path.getName( file_path, true ) ] then
            return
        end

        if action == 1 then
            engine_hookCall( "fs.watchdog.Created", fs_object, is_directory )
        elseif action == 2 then
            engine_hookCall( "fs.watchdog.Deleted", fs_object, is_directory )
        elseif action == 3 then
            engine_hookCall( "fs.watchdog.Modified", fs_object, is_directory )
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

        if reserved_names[ names[ fs_object ] ] then
            return false, -4
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
                    times[ file_object ] = file_Time( mount_paths[ file_object ] or names[ file_object ], file_mount_point )
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
            -- print( "fs.gc", dead_fs_object )

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

        engine.hookCatch( "fs.Directory.__gc", on_gc, 1 )
        engine.hookCatch( "fs.File.__gc", on_gc, 1 )

    end

    local function watchdog_update( fs_object )
        local mount_path, mount_point = mount_paths[ fs_object ] or "", mount_points[ fs_object ]

        if not file_Exists( mount_path, mount_point ) then
            watchdog.unwatch( fs_object )
            engine_hookCall( "fs.watchdog.Deleted", fs_object, is_directory_object[ fs_object ] == true )
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
                    times[ fs_child ] = last_modified
                    engine_hookCall( "fs.watchdog.Modified", fs_child, is_directory_object[ fs_child ] == true )
                end
            end

            return
        end

        times[ fs_object ] = last_modified

        local content_list = content_lists[ fs_object ]
        if content_list == nil then
            ---@cast fs_object dreamwork.std.fs.File
            engine_hookCall( "fs.watchdog.Modified", fs_object, false )
            return
        end

        ---@cast fs_object dreamwork.std.fs.Directory
        engine_hookCall( "fs.watchdog.Modified", fs_object, true )

        ---@type integer
        local content_length = content_counts[ fs_object ] or 0

        ---@type table<string, dreamwork.std.fs.Object>
        local directory_files = {}

        for i = 1, content_length, 1 do
            local fs_child = content_list[ i ]
            directory_files[ names[ fs_child ] ] = fs_child
        end

        fs_object:scan( false, false )

        local fs_files, fs_file_count,
            fs_dirs, fs_dir_count = fs_object:select()

        local current_files = {}

        for i = 1, fs_file_count, 1 do
            local file_object = fs_files[ i ]
            local name = names[ file_object ]

            if directory_files[ name ] == nil then
                content_length = content_length + 1
                content_list[ content_length ] = file_object
                engine_hookCall( "fs.watchdog.Created", file_object, false )
            end

            current_files[ name ] = true
        end

        for i = 1, fs_dir_count, 1 do
            local directory_object = fs_dirs[ i ]
            local name = names[ directory_object ]

            if directory_files[ name ] == nil then
                content_length = content_length + 1
                content_list[ content_length ] = directory_object
                engine_hookCall( "fs.watchdog.Created", directory_object, true )
            end

            current_files[ name ] = true
        end

        for i = content_length, 1, -1 do
            local fs_child = content_list[ i ]

            if current_files[ names[ fs_child ] ] == nil then
                for j = content_length, 1, -1 do
                    if content_list[ j ] == fs_child then
                        table_remove( content_list, j )
                        content_length = content_length - 1
                        break
                    end
                end

                engine_hookCall( "fs.watchdog.Deleted", fs_child, is_directory_object[ fs_child ] == true )
            else
                last_modified = file_Time( mount_paths[ fs_child ] or "", mount_points[ fs_child ] )
                if times[ fs_child ] ~= last_modified then
                    times[ fs_child ] = last_modified
                    engine_hookCall( "fs.watchdog.Modified", fs_child, is_directory_object[ fs_child ] == true )
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

engine.hookCatch( "fs.Directory.__gc", watchdog.unwatch )
engine.hookCatch( "fs.File.__gc", watchdog.unwatch )

do

    local watchdog_Created = std.Hook( "fs.watchdog.Created" )
    engine.hookCatch( "fs.watchdog.Created", watchdog_Created )
    watchdog.Created = watchdog_Created

    local watchdog_Deleted = std.Hook( "fs.watchdog.Deleted" )
    engine.hookCatch( "fs.watchdog.Deleted", watchdog_Deleted )
    watchdog.Deleted = watchdog_Deleted

    local watchdog_Modified = std.Hook( "fs.watchdog.Modified" )
    engine.hookCatch( "fs.watchdog.Modified", watchdog_Modified )
    watchdog.Modified = watchdog_Modified

end

---@protected
function File:__gc()
    engine_hookCall( "fs.File.__gc", self )
end

---@protected
---@param name string
---@param mount_point string | nil
---@param mount_path string | nil
function File:__init( name, mount_point, mount_path )
    is_directory_object[ self ] = false
    names[ self ] = name

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

    local parent = parents[ self ]
    if parent ~= nil then
        size_add( parent, -sizes[ self ] )
        size_add( parent, new_size )
    end

    sizes[ self ] = new_size

    if watchdog.isWatched( self ) then
        engine_hookCall( "fs.watchdog.Modified", self, false )
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

    local parent = parents[ self ]
    if parent ~= nil then
        size_add( parent, -sizes[ self ] )
        size_add( parent, new_size )
    end

    sizes[ self ] = new_size

    if watchdog.isWatched( self ) then
        engine_hookCall( "fs.watchdog.Modified", self, false )
    end

    return respond
end

--- [SHARED AND MENU]
---
--- Deletes a file.
---
---@async
function File:delete()
    return delete_file( self, 2 )
end

--- [SHARED AND MENU]
---
--- Renames a file.
---
---@param name string The new name of the file.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@async
function File:rename( name, forced )
    local mount_point = mount_points[ self ]
    if mount_point == nil then
        std.errorf( 2, false, "'%s' cannot be renamed, parent directory is not mounted.", self )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not ( mount_info.writable and mount_info.deletable ) then
        std.errorf( 2, false, "'%s' cannot be renamed, parent directory is not allowing file renaming.", self )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    if not mount_info.writable_extensions[ path_getExtension( name, false ) ] then
        if forced then
            name = name .. ".dat"
        else
            std.errorf( 2, false, "'%s' cannot be renamed to '%s', parent directory is not allowing this extension.", self, name )
        end
    end

    local parent = parents[ self ]
    if parents[ self ] == nil then
        std.errorf( 2, false, "'%s' has no parent directory and cannot be renamed.", self )
    end

    ---@cast parent dreamwork.std.fs.Directory

    local existing_object, is_directory = directory_get( parent, name )
    if existing_object ~= nil then
        if forced then
            if is_directory then
                ---@cast existing_object dreamwork.std.fs.Directory
                existing_object:delete( forced )
            else
                ---@cast existing_object dreamwork.std.fs.File
                existing_object:delete()
            end
        else
            std.errorf( 2, false, "'%s' already exists in '%'. Use `forced=true` to overwrite it.", existing_object, parent )
        end
    end

    ---@cast existing_object nil

    local data = self:read()

    if is_busy( self ) then
        async_jobs[ self ][ 0 ]:await()
    end

    if parents[ self ] ~= parent then
        std.errorf( 2, false, "'%s' has changed its location or been deleted, renaming failed.", self )
    end

    ---@cast parent dreamwork.std.fs.Directory

    file_Delete( mount_paths[ self ], mount_point )
    mount_paths[ self ] = rel_path( parent, name )

    names[ self ] = name
    update_path( self, parent )

    self:write( data )
end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory_object dreamwork.std.fs.Directory The directory to copy the file to.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@return dreamwork.std.fs.File file_object The copied file.
---@async
function File:copy( directory_object, forced, name )
    if name == nil then
        name = names[ self ]
    end

    local mount_point = mount_points[ directory_object ]
    if mount_point == nil then
        std.errorf( 2, false, "'%s' cannot be copied, parent directory is not mounted.", self )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not mount_info.writable then
        std.errorf( 2, false, "'%s' cannot be copied, parent directory is not writable.", self )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    if not mount_info.writable_extensions[ path_getExtension( name, false ) ] then
        if forced then
            name = name .. ".dat"
        else
            std.errorf( 2, false, "'%s' cannot be copied with name '%s', parent directory is not allowing this extension.", self, name )
        end
    end

    local fs_object, is_directory = directory_get( directory_object, name )
    if fs_object == nil then
        fs_object = FileClass( name, mount_point, rel_path( directory_object, name ) )
        insert( directory_object, fs_object )
    elseif is_directory then
        ---@cast fs_object dreamwork.std.fs.Directory
        fs_object:delete( forced )
    end

    ---@cast fs_object dreamwork.std.fs.File
    fs_object:write( self:read() )
    return fs_object
end

--- [SHARED AND MENU]
---
--- Moves a file to another directory.
---
---@param directory_object dreamwork.std.fs.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@return dreamwork.std.fs.File file_object The moved file.
---@async
function File:move( directory_object, name, forced )
    if name == nil then
        name = names[ self ]
    end

    local mount_point = mount_points[ directory_object ]
    if mount_point == nil then
        std.errorf( 2, false, "'%s' cannot be moved, parent directory is not mounted.", self )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not ( mount_info.writable and mount_info.deletable ) then
        std.errorf( 2, false, "'%s' cannot be moved, parent directory is not allowing file moving.", self )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    if not mount_info.writable_extensions[ path_getExtension( name, false ) ] then
        if forced then
            name = name .. ".dat"
        else
            std.errorf( 2, false, "'%s' cannot be moved with name '%s', parent directory is not allowing this extension.", self, name )
        end
    end

    local data = self:read()

    local parent = parents[ self ]
    if parent == nil then
        std.errorf( 2, false, "'%s' has no parent directory and cannot be moved.", self )
    else
        eject( parent, name )
    end

    local fs_object, is_directory = directory_get( directory_object, name )
    if fs_object ~= nil then
        if is_directory then
            ---@cast fs_object dreamwork.std.fs.Directory
            fs_object:delete( forced )
        else
            ---@cast fs_object dreamwork.std.fs.File
            fs_object:delete()
        end
    end

    names[ self ] = name
    mount_points[ self ] = mount_point
    mount_paths[ self ] = rel_path( directory_object, name )

    insert( directory_object, self )

    self:write( data )

    return self
end

do

    local handlers = {}

    -- TODO: Reader and Writer or something better like FileClass that can returns FileReader and FileWriter in cases

    function File:open()

    end

    function File:close()

    end

end

---@protected
function Directory:__gc()
    engine_hookCall( "fs.Directory.__gc", self )
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
    elseif key == "writable" then
        local mount_point = mount_points[ self ]
        if mount_point == nil then
            return false
        end

        local mount_info = fstab[ mount_point ]
        return mount_info ~= nil and mount_info.writable
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

---@param relative_path string
---@return dreamwork.std.fs.Object | nil fs_object
---@return boolean is_directory
function Directory:lookup( relative_path )
    return directory_lookup( self, relative_path, nil )
end

Directory.get = directory_get

---@param wildcard string | nil
---@return dreamwork.std.fs.File[], integer, dreamwork.std.fs.Directory[], integer
function Directory:select( wildcard )
    local descendants_table = descendants[ self ]

    local directories, directory_count = {}, 0
    local files, file_count = {}, 0

    for i = 1, descendant_counts[ self ], 1 do
        ---@type dreamwork.std.fs.Object
        local fs_object = descendants_table[ i ]
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
        return files, file_count,
            directories, directory_count
    end

    if wildcard == nil then
        wildcard = "*"
    elseif string_hasByte( wildcard, 0x2F --[[ '/' ]] ) then
        error( "wildcard cannot contain '/'", 2 )
    end

    local mount_path = mount_paths[ self ]
    if mount_path == nil then

        local fs_files, fs_directories = file_Find( wildcard, mount_point )

        for i = 1, #fs_files, 1 do
            local file_name = fs_files[ i ]
            if descendants_table[ file_name ] == nil and not reserved_names[ file_name ] then
                local file_object = FileClass( file_name, mount_point, file_name )
                insert( self, file_object )

                file_count = file_count + 1
                files[ file_count ] = file_object
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if descendants_table[ directory_name ] == nil and not reserved_names[ directory_name ] and string_byte( directory_name, 1, 1 ) ~= 0x2F --[[ '/' ]] then
                local directory_object = DirectoryClass( directory_name, mount_point, directory_name )
                insert( self, directory_object )

                directory_count = directory_count + 1
                directories[ directory_count ] = directory_object
            end
        end


    else

        local fs_files, fs_directories = file_Find( mount_path .. "/" .. wildcard, mount_point )

        for i = 1, #fs_files, 1 do
            local file_name = fs_files[ i ]
            if descendants_table[ file_name ] == nil and not reserved_names[ file_name ] then
                local file_object = FileClass( file_name, mount_point, mount_path .. "/" .. file_name )
                insert( self, file_object )

                file_count = file_count + 1
                files[ file_count ] = file_object
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if descendants_table[ directory_name ] == nil and not reserved_names[ directory_name ] and string_byte( directory_name, 1, 1 ) ~= 0x2F --[[ '/' ]] then
                local directory_object = DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name )
                insert( self, directory_object )

                directory_count = directory_count + 1
                directories[ directory_count ] = directory_object
            end
        end

    end

    return files, file_count,
        directories, directory_count
end

---@return integer, integer
function Directory:count()
    local file_count, directory_count = 0, 0
    local descendants_table = descendants[ self ]

    for i = 1, descendant_counts[ self ], 1 do
        if is_directory_object[ descendants_table[ i ] ] then
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
---@param on_finish nil | fun( directory_object: dreamwork.std.fs.Directory )
function Directory:scan( deep_scan, full_update, on_new, on_finish )
    local descendant_count = descendant_counts[ self ]
    local descendants_table = descendants[ self ]

    local mount_point = mount_points[ self ]
    local mount_path = mount_paths[ self ]

    if full_update and descendant_count ~= 0 then

        size_add( self, -sizes[ self ] )

        for i = 1, descendant_count, 1 do
            local descendant = descendants[ self ][ i ]
            if not is_directory_object[ descendant ] then
                local descendant_mount_point = mount_points[ descendant ]
                local size, unix_time

                if descendant_mount_point == nil then
                    size = sizes[ descendant ]
                    unix_time = times[ descendant ]
                else
                    local descendant_mount_path = mount_paths[ descendant ] or ""
                    size = file_Size( descendant_mount_path, descendant_mount_point )
                    unix_time = file_Time( descendant_mount_path, descendant_mount_point )
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
            if descendants_table[ file_name ] == nil and not reserved_names[ file_name ] then
                local file_object = FileClass( file_name, mount_point, mount_path == nil and file_name or ( mount_path .. "/" .. file_name ) )
                insert( self, file_object )

                if on_new ~= nil then
                    on_new( file_object, false )
                end
            end
        end

        for i = 1, #fs_directories, 1 do
            local directory_name = fs_directories[ i ]
            if descendants_table[ directory_name ] == nil and not reserved_names[ directory_name ] then
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
            local directory_object = descendants_table[ i ]
            if is_directory_object[ directory_object ] then
                ---@cast directory_object dreamwork.std.fs.Directory
                directory_object:scan( deep_scan, full_update, on_new, on_finish )
            end
        end
    end
end

---@return boolean
function Directory:isEmpty()
    local file_count, directory_count = self:count()
    return file_count == 0 and directory_count == 0
end

---@param file_callback nil | fun( file: dreamwork.std.fs.File )
---@param directory_callback nil | fun( directory_object: dreamwork.std.fs.Directory )
function Directory:foreach( file_callback, directory_callback )
    local files, file_count,
        directories, directory_count = self:select()

    if file_callback == nil then
        if directory_callback == nil then
            return
        end
    else
        for i = 1, file_count, 1 do
            ---@type dreamwork.std.fs.File
            ---@diagnostic disable-next-line: param-type-mismatch
            file_callback( files[ i ] )
        end
    end

    for i = 1, directory_count, 1 do
        ---@type dreamwork.std.fs.Directory
        ---@diagnostic disable-next-line: assign-type-mismatch
        local directory_object = directories[ i ]

        if directory_callback ~= nil then
            directory_callback( directory_object )
        end

        directory_object:foreach( file_callback, directory_callback )
    end
end

--- [SHARED AND MENU]
---
--- Creates a file in the directory.
---
---@param file_name string The name of the file.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@return dreamwork.std.fs.File file_object The created file.
---@async
function Directory:makeFile( file_name, forced )
    return make_file( self, file_name, forced == true, 2 )
end

--- [SHARED AND MENU]
---
--- Creates a directory in the directory.
---
---@param directory_name string The name of the directory.
---@param forced? boolean If `true`, the directory will be overwritten if it already exists.
---@return dreamwork.std.fs.Directory directory_object The created directory.
---@async
function Directory:makeDirectory( directory_name, forced )
    return make_directory( self, directory_name, forced == true, 2 )
end

-- ---@param name string
-- ---@return dreamwork.std.fs.Object fs_object
-- ---@return boolean is_directory
-- ---@async
-- function Directory:touch( name )
--     if reserved_names[ name ] then
--         error( "File or directory cannot be touched with reserved name.", 2 )
--     end

--     local fs_object, is_directory = directory_get( self, name )
--     if fs_object == nil then
--         return make_file( self, name, false, 2 ), false
--     end

--     local mount_point = mount_points[ fs_object ]
--     if mount_point == nil then
--         std.errorf( 2, false, "'%s' touch failed, parent directory is not mounted.", fs_object )
--     end

--     ---@cast mount_point string

--     local mount_info = fstab[ mount_point ]
--     if mount_info == nil or not ( mount_info.writable and mount_info.deletable ) then
--         std.errorf( 2, false, "'%s' touch failed, parent directory is not allowing touching.", fs_object )
--     end

--     ---@cast mount_info dreamwork.std.fs.MountInfo

--     if is_busy( fs_object ) then
--         async_jobs[ fs_object ][ 0 ]:await()
--     end

--     if parents[ fs_object ] ~= self then
--         std.errorf( 2, false, "'%s' changed directory and cannot be touched.", fs_object )
--     end

--     if is_directory then
--         ---@cast fs_object dreamwork.std.fs.Directory

--         local mount_path = rel_path( fs_object, "^dreamwork_tmp$.dat" )
--         local f = async_write( mount_path, mount_point, "" )
--         local is_registered = async_job_register( fs_object, f )

--         ---@type dreamwork.std.fs.WriteRespond
--         local respond = f:await()

--         if is_registered then
--             async_job_unregister( fs_object, f )
--         end

--         if respond.status ~= 0 then
--             error( make_async_message( respond.status, fs_object, false ), 2 )
--         end

--         file_Delete( mount_path, mount_point )

--         times[ fs_object ] = file_Time( mount_paths[ fs_object ] or "", mount_point )

--     else
--         ---@cast fs_object dreamwork.std.fs.File

--         local mount_path = mount_paths[ fs_object ] or names[ fs_object ]

--         local handler = file_Open( mount_path, "wb", mount_point )
--         if handler == nil then
--             std.errorf( 2, false, "Failed to open file '%s' for writing.", fs_object )
--         end

--         ---@diagnostic disable-next-line: cast-type-mismatch
--         ---@cast handler File
--         FILE_Close( handler )

--         times[ fs_object ] = file_Time( mount_path, mount_point )
--     end

--     return fs_object, is_directory
-- end

--- [SHARED AND MENU]
---
--- Deletes a directory.
---
---@param recursive? boolean If `true`, the directory will be deleted even if it contains files or directories.
---@async
function Directory:delete( recursive )
    delete_directory( self, recursive == true, 2 )
end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory_object dreamwork.std.fs.Directory The directory to copy the file to.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function Directory:copy( directory_object, forced, name )
    if name == nil then
        name = names[ self ]
    end

    local mount_point = mount_points[ directory_object ]
    if mount_point == nil then
        std.errorf( 2, false, "'%s' cannot be copied, parent directory is not mounted.", self )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not mount_info.writable then
        std.errorf( 2, false, "'%s' cannot be copied, parent directory is not writable.", self )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    -- TODO: add checks to prevent recursion copying

    local fs_object, is_directory = directory_get( directory_object, name )
    if fs_object == nil then
        fs_object = directory_object:makeDirectory( name, forced )
    elseif not is_directory then
        ---@cast fs_object dreamwork.std.fs.File
        if forced then
            fs_object:delete()
            fs_object = directory_object:makeDirectory( name, forced )
        else
            std.errorf( 2, false, "'%s' already exists and cannot be overwritten.", fs_object )
        end
    end

    ---@cast fs_object dreamwork.std.fs.Directory

    local files, file_count, directories, directory_count = self:select()

    for i = 1, directory_count, 1 do
        directories[ i ]:copy( fs_object, forced, nil )
    end

    for i = 1, file_count, 1 do
        files[ i ]:copy( fs_object, forced, nil )
    end

    times[ fs_object ] = file_Time( mount_paths[ fs_object ] or "", mount_point )

    return fs_object
end

--- [SHARED AND MENU]
---
--- Moves a file to another directory.
---
---@param directory_object dreamwork.std.fs.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@param forced? boolean If `true`, the file will be overwritten if it already exists.
---@async
function Directory:move( directory_object, name, forced )

end

-- TODO: finish directory methods

--- [SHARED AND MENU]
---
--- Renames a file.
---
---@param name string The new name of the file.
---@param forced? boolean If `true`, the file will be renamed even if it already exists.
---@async
function Directory:rename( name, forced )
    local mount_point = mount_points[ self ]
    if mount_point == nil then
        std.errorf( 2, false, "'%s' cannot be renamed, parent directory is not mounted.", self )
    end

    ---@cast mount_point string

    local mount_info = fstab[ mount_point ]
    if mount_info == nil or not ( mount_info.writable and mount_info.deletable ) then
        std.errorf( 2, false, "'%s' cannot be renamed, parent directory is not allowing file renaming.", self )
    end

    ---@cast mount_info dreamwork.std.fs.MountInfo

    local parent = parents[ self ]
    if parents[ self ] == nil then
        std.errorf( 2, false, "'%s' has no parent directory and cannot be renamed.", self )
    end

    ---@cast parent dreamwork.std.fs.Directory

    local existing_object, is_directory = directory_get( parent, name )
    if existing_object ~= nil then
        if forced then
            if is_directory then
                ---@cast existing_object dreamwork.std.fs.Directory
                existing_object:delete( forced )
            else
                ---@cast existing_object dreamwork.std.fs.File
                existing_object:delete()
            end
        else
            std.errorf( 2, false, "'%s' already exists in '%'. Use `forced=true` to overwrite it.", existing_object, parent )
        end
    end

    ---@cast existing_object nil

    if parents[ self ] ~= parent then
        std.errorf( 2, false, "'%s' has changed its location or been deleted, renaming failed.", self )
    end

    local files, file_count,
        directories, directory_count = self:select()




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
engine.hookCatch( "engine.Game.mounted", function( game_info )
    local game_folder = game_info.folder
    eject( root, game_folder )
    insert( root, DirectoryClass( game_folder, game_folder ) )
end, 2 )

---@param game_info dreamwork.engine.GameInfo
engine.hookCatch( "engine.Game.unmounted", function( game_info )
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
    engine.hookCatch( "engine.Addon.mounted", function( addon_info )
        local addon_folder = addon_info.folder
        eject( addons, addon_folder )
        insert( addons, DirectoryClass( addon_folder, addon_info.title ) )
    end, 2 )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "engine.Addon.unmounted", function( addon_info )
        eject( addons, addon_info.folder )
    end, 2 )

    local download = DirectoryClass( "download", "DOWNLOAD" )
    insert( workspace, download )

    local lua = DirectoryClass( "lua", ( SERVER and "lsv" or ( CLIENT and "lcl" or ( MENU and "LuaMenu" or "LUA" ) ) ) )
    insert( workspace, lua )

    local map = DirectoryClass( "map", "BSP" )
    insert( workspace, map )

end

--[[

    TODO: make fake fs file for addon presets that will exists only in menu realm

    _G.LoadAddonPresets
    _G.SaveAddonPresets

    https://wiki.facepunch.com/gmod/Global.LoadPresets
    https://wiki.facepunch.com/gmod/Global.SavePresets

]]

-- TODO: add more fs hooks

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
function fs.lookup( path_to )
    return directory_lookup( root, prepare_path( path_to ), 2 )
end

--- [SHARED AND MENU]
---
--- Creates a file by given path.
---
--- Does nothing if the file already exists.
---
--- If `forced` is `true`, all files in the path will be deleted if they exist.
---
---@param file_path string
---@param forced? boolean
---@return dreamwork.std.fs.File file_object
---@async
function fs.makeFile( file_path, forced )
    local segments, segment_count = string_byteSplit( prepare_path( file_path ), 0x2F --[[ '/' ]], 2 )
    local directory_object = root

    forced = forced == true

    for i = 1, segment_count - 1, 1 do
        directory_object = make_directory( directory_object, segments[ i ], forced, 2 )
    end

    return make_file( directory_object, segments[ segment_count ], forced == true, 2 )
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
---@return dreamwork.std.fs.Directory directory_object
---@async
function fs.makeDirectory( directory_path, forced )
    local segments, segment_count = string_byteSplit( prepare_path( directory_path ), 0x2F --[[ '/' ]], 2 )
    local directory_object = root

    forced = forced == true

    for i = 1, segment_count, 1 do
        directory_object = make_directory( directory_object, segments[ i ], forced, 2 )
    end

    return directory_object
end

-- --- [SHARED AND MENU]
-- ---
-- --- Creates a file by given path.
-- ---
-- --- Does nothing if the file already exists.
-- ---
-- --- If `forced` is `true`, all files in the path will be deleted if they exist.
-- ---
-- ---@param file_path string The path to the file to create.
-- ---@param forced? boolean
-- ---@return dreamwork.std.fs.Object fs_object
-- ---@return boolean is_directory
-- ---@async
-- function fs.touch( file_path, forced )
--     local directory_path, file_name = path_split( prepare_path( file_path ), false )

--     local directory_object, is_directory = directory_lookup( root, directory_path, 2 )
--     if directory_object == nil then
--         if forced then
--             directory_object = root:makeDirectory( directory_path, true )
--         else
--             std.errorf( 2, false, "Path '%s' does not exist.", directory_path )
--         end
--     elseif not is_directory then
--         if forced then
--             directory_object = root:makeDirectory( directory_path, true )
--         else
--             std.errorf( 2, false, "'%s' is not a directory.", directory_object )
--         end
--     end

--     ---@cast directory_object dreamwork.std.fs.Directory
--     return directory_object:touch( file_name )
-- end

--- [SHARED AND MENU]
---
--- Checks if a file or directory exists by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean exists Returns `true` if the file or directory exists, otherwise `false`.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.exists( path_to )
    local fs_object, is_directory = directory_lookup( root, prepare_path( path_to ), 2 )
    return fs_object ~= nil, is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists by given path.
---
---@param directory_path string The path to the directory.
---@return boolean exists Returns `true` if the directory exists and is not a file, otherwise `false`.
function fs.isDirectory( directory_path )
    local directory_object, is_directory = directory_lookup( root, prepare_path( directory_path ), 2 )
    return directory_object ~= nil and is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file exists by given path.
---
---@param file_path string The path to the fs.
---@return boolean exists Returns `true` if the file exists and is not a directory, otherwise `false`.
function fs.isFile( file_path )
    local file_object, is_directory = directory_lookup( root, prepare_path( file_path ), 2 )
    return file_object ~= nil and not is_directory
end

--- [SHARED AND MENU]
---
--- Checks if a file or directory is empty by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean empty Returns `true` if the file or directory is empty, otherwise `false`.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.isEmpty( path_to, forced )
    local fs_object, is_directory = directory_lookup( root, prepare_path( path_to ), 2 )
    if fs_object == nil then
        if not forced then
            std.errorf( 2, false, "Path '%s' does not exist.", path_to )
        end

        return true, false
    end

    if is_directory then
        ---@cast fs_object dreamwork.std.fs.Directory
        return fs_object:isEmpty(), true
    end

    return fs_object.size == 0, false
end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function fs.time( file_path, forced )
    local fs_object = directory_lookup( root, prepare_path( file_path ), 2 )
    if fs_object == nil then
        if not forced then
            std.errorf( 2, false, "Path '%s' does not exist.", file_path )
        end

        return 0
    end

    return fs_object.time
end

--- [SHARED AND MENU]
---
--- Returns the size of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer size The size of the file or directory in bytes.
function fs.size( file_path, forced )
    local fs_object = directory_lookup( root, prepare_path( file_path ), 2 )
    if fs_object == nil then
        if not forced then
            std.errorf( 2, false, "Path '%s' does not exist.", file_path )
        end

        return 0
    end

    return fs_object.size
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
    local directory_object, is_directory = directory_lookup( root, prepare_path( directory_path ), 2 )
    if directory_object == nil or not is_directory then
        return {}, 0, {}, 0
    end

    ---@cast directory_object dreamwork.std.fs.Directory
    return directory_object:select( wildcard )
end

do

    local futures_yield = std.futures.yield

    ---@param file_object dreamwork.std.fs.File
    ---@async
    local function iterate_file( file_object )
        return futures_yield( paths[ file_object ], false )
    end

    ---@param directory_object dreamwork.std.fs.Directory
    ---@async
    local function iterate_directory( directory_object )
        return futures_yield( paths[ directory_object ], true )
    end

    --- [SHARED AND MENU]
    ---
    --- Iterates over all files and directories in a directory by given path.
    ---
    ---@param directory_path string The path to the directory.
    ---@async
    ---@return AsyncIterator<dreamwork.std.fs.Object, boolean> iterator An async iterator that yields the path and a boolean indicating if the object is a directory.
    function fs.iterator( directory_path )
        local fs_object, is_directory = directory_lookup( root, prepare_path( directory_path ), 2 )
        if fs_object ~= nil and is_directory then
            ---@cast fs_object dreamwork.std.fs.Directory
            fs_object:foreach( iterate_file, iterate_directory )
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
    local file_object, is_directory = directory_lookup( root, prepare_path( file_path ), 2 )
    if file_object == nil then
        std.errorf( 2, false, "Path '%s' does not exist.", file_path )
    end

    if is_directory then
        std.errorf( 2, false, "Path '%s' is a directory.", file_path )
    end

    ---@cast file_object dreamwork.std.fs.File

    return file_object:read()
end

--- [SHARED AND MENU]
---
--- Writes data to a file by given path.
---
---@param file_path string The path to the file.
---@param data string The data to write to the file.
---@async
function fs.write( file_path, data )
    local full_path = prepare_path( file_path )
    local directory_path, file_name = path_split( full_path, false )

    local directory_object, is_directory = directory_lookup( root, directory_path, 2 )

    if directory_object == nil then

    end


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

-- TODO: finish fs file functions

--- [SHARED AND MENU]
---
--- Deletes a file or directory by given path.
---
---@param path_to string The path to the file or directory.
---@param recursive? boolean If `true`, the file or directory will be deleted even if it contains files or directories.
---@async
function fs.delete( path_to, recursive )
    local full_path = prepare_path( path_to )

    local fs_object, is_directory = directory_lookup( root, full_path, 2 )
    if fs_object == nil then
        std.errorf( 2, false, "Path '%s' does not exist.", full_path )
    end

    ---@cast fs_object dreamwork.std.fs.Object

    if is_directory then
        ---@cast fs_object dreamwork.std.fs.Directory
        fs_object:delete( recursive )
    else
        ---@cast fs_object dreamwork.std.fs.File
        fs_object:delete()
    end
end

--- [SHARED AND MENU]
---
--- Copies a file or directory by given path.
---
---@param source_path string The path to the file or directory to copy.
---@param target_path string The path to the file or directory to copy to.
---@param forced? boolean If `true`, the file or directory will be copied even if it already exists.
---@return dreamwork.std.fs.Object object_copy The copied file or directory.
---@return boolean is_directory `true` if copied object is a directory, otherwise `false`.
---@async
function fs.copy( source_path, target_path, forced )
    local resource_source_path = prepare_path( source_path )

    local source_object, source_is_directory = directory_lookup( root, resource_source_path, 2 )
    if source_object == nil then
        std.errorf( 2, false, "Path '%s' does not exist.", resource_source_path )
    end

    ---@cast source_object dreamwork.std.fs.Object

    local resolved_target_path = prepare_path( target_path )
    local segments, segment_count = string_byteSplit( resolved_target_path, 0x2F --[[ '/' ]], 2 )

    for i = segment_count, 1, -1 do
        local fs_object, is_directory = directory_lookup( root, table_concat( segments, "/", 1, i ), 2 )
        if is_directory then
            ---@cast fs_object dreamwork.std.fs.Directory

            if i == segment_count then
                return source_object:copy( fs_object, forced, nil ), source_is_directory
            end

            local segments_remaining = segment_count - i
            if segments_remaining ~= 1 then
                for j = 1, segments_remaining - 1, 1 do
                    fs_object = fs_object:makeDirectory( segments[ i + j ], forced )
                end
            end

            return source_object:copy( fs_object, forced, segments[ segment_count ] ), source_is_directory
        end
    end

    ---@diagnostic disable-next-line: missing-return
    std.errorf( 2, false, "Path '%s' does not exist.", resolved_target_path )
end

-- TODO: finish fs functions

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
