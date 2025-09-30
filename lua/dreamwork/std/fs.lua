local _G = _G
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std
local engine = dreamwork.engine

local CLIENT, SERVER, MENU = std.CLIENT, std.SERVER, std.MENU
local engine_hookCall = engine.hookCall
local setmetatable = std.setmetatable

local futures = std.futures
local Future = futures.Future

-- TODO: https://wiki.facepunch.com/gmod/resource
-- TODO: https://wiki.facepunch.com/gmod/Global.AddCSLuaFile

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
        if file_Exists( file_path .. ".dll", "MOD" ) then
            return true, "/" .. file_path .. ".dll"
        end

        if file_Exists( file_path .. ".so", "MOD" ) then
            return true, "/" .. file_path .. ".so"
        end

        if is_edge and is_x86 and tail == "_linux" then
            file_path = head .. name .. "_linux32"

            if file_Exists( file_path .. ".dll", "MOD" ) then
                return true, "/" .. file_path .. ".dll"
            end

            if file_Exists( file_path .. ".so", "MOD" ) then
                return true, "/" .. file_path .. ".so"
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
    --- Loads a binary module
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

if std.loadbinary( "asyncio" ) then
    local file_AsyncRead, file_AsyncWrite, file_AsyncAppend = file.AsyncRead, file.AsyncWrite, file.AsyncAppend

    ---@param file_name string
    ---@param game_path string
    ---@return string data
    ---@async
    function async_read( file_name, game_path )

    end

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_write( file_name, game_path, data )

    end

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_append( file_name, game_path, data )

    end

    dreamwork.Logger:info( "Async File System I/O - was loaded & connected as file system driver." )
elseif std.loadbinary( "async_write" ) then
    local file_AsyncWrite, file_AsyncAppend = file.AsyncWrite, file.AsyncAppend

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_write( file_name, game_path, data )

    end

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_append( file_name, game_path, data )

    end

    dreamwork.Logger:info( "Async File Write - was loaded & connected as file system driver." )
elseif not MENU and file.AsyncRead ~= nil then
    local file_AsyncRead = file.AsyncRead

    ---@param file_name string
    ---@param game_path string
    ---@return string data
    ---@async
    function async_read( file_name, game_path )

    end

end

if async_read == nil then

    ---@param file_name string
    ---@param game_path string
    ---@return string data
    ---@async
    function async_read( file_name, game_path )
        local handler = file_Open( file_name, "rb", game_path )
        if handler == nil then
            error( "Unknown filesystem error, file handler is not available.", 2 )
        end

        local data = FILE_Read( handler, FILE_Size( handler ) )
        FILE_Close( handler )
        return data
    end

end

if async_write == nil then

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_write( file_name, game_path, data )

    end

end

if async_append == nil then

    ---@param file_name string
    ---@param game_path string
    ---@param data string
    ---@async
    function async_append( file_name, game_path, data )

    end

end


if std.loadbinary( "efsw" ) then

    local hook = _G.hook
    local hook_Add = hook.Add

    ---@diagnostic disable-next-line: duplicate-set-field
    function hook.Add( event_name, identifier, fn )
        if event_name == "Think" and identifier == "__ESFW_THINK" then
            dreamwork.Logger:debug( "Catched gm_efsw 'Think' event function %p, re-attaching to dreamwork engine...", fn )
            engine.hookCatch( "Tick", fn, 1 )
        else
            return hook_Add( event_name, identifier, fn )
        end
    end

    if std.loadbinary( "gm_efsw" ) then
        dreamwork.Logger:info( "Entry File System Watcher - was loaded & connected as file system watcher." )
    else
        dreamwork.Logger:error( "Entry File System Watcher - failed to load, unknown error." )
    end

    hook.Add = hook_Add

end

---@diagnostic disable-next-line: undefined-field
local efsw = _G.efsw

---@type fun( file_path: string, game_path: string ): integer
local efsw_watch = efsw and efsw.Watch or debug.fempty

---@type fun( watch_id: integer )
local efsw_unwatch = efsw and efsw.Unwatch or debug.fempty

--- [SHARED AND MENU]
---
--- The filesystem library.
---
---@class dreamwork.std.fs
local fs = std.fs or {}
std.fs = fs

---@class dreamwork.std.File : dreamwork.std.Object
---@field __class dreamwork.std.FileClass
---@field name string The name of the file. **READ-ONLY**
---@field size integer The size of the file in bytes. **READ-ONLY**
---@field time integer The last modified time of the file. **READ-ONLY**
---@field path string The path to the file. **READ-ONLY**
---@field parent dreamwork.std.Directory | nil The parent directory. **READ-ONLY**
local File = class.base( "File", true )

---@class dreamwork.std.Directory : dreamwork.std.Object
---@field __class dreamwork.std.DirectoryClass
---@field name string The name of the directory. **READ-ONLY**
---@field size integer The size of the directory in bytes. **READ-ONLY**
---@field time integer The last modified time of the directory. **READ-ONLY**
---@field path string The full path of the directory. **READ-ONLY**
---@field writeable boolean If `true`, the directory is directly writeable.
---@field parent dreamwork.std.Directory | nil The parent directory. **READ-ONLY**
local Directory = class.base( "Directory", true )

---@type table<dreamwork.std.File | dreamwork.std.Directory, string>
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
        __newindex = function( self, object, name )
            for index = 1, string_len( name ), 1 do
                if invalid_characters[ string_byte( name, index, index ) ] then
                    error( string.format( "directory or file name contains invalid character \\%X at index %d in '%s'", string_byte( name, index, index ), index, name ), 2 )
                end
            end

            raw_set( self, object, name )
        end,
        __mode = "k"
    } )

end

---@type table<dreamwork.std.File | dreamwork.std.Directory, string>
local paths = {}

setmetatable( paths, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_path = "/" .. names[ object ]
        raw_set( self, object, object_path )
        return object_path
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, dreamwork.std.Directory>
local parents = {}
-- gc_setTableRules( parents, true, false )

---@type table<dreamwork.std.Directory, table<string | integer, dreamwork.std.File | dreamwork.std.Directory>>
local descendants = {}

setmetatable( descendants, {
    __index = function( self, object )
        ---@type table<string | integer, dreamwork.std.File | dreamwork.std.Directory>
        local directory_children = {}
        raw_set( self, object, directory_children )
        return directory_children
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.Directory, integer>
local descendant_counts = {}

setmetatable( descendant_counts, {
    __index = function( self, object )
        return 0
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local indexes = {}
gc_setTableRules( indexes, true, false )

---@type table<dreamwork.std.File | dreamwork.std.Directory, boolean>
local is_directory_object = {}
gc_setTableRules( is_directory_object, true, false )

---@type table<dreamwork.std.Directory, string>
local mount_points = {}
gc_setTableRules( mount_points, true, false )

---@type table<dreamwork.std.Directory, string>
local mount_paths = {}
gc_setTableRules( mount_paths, true, false )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local sizes = {}

setmetatable( sizes, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_size

        local mount_point = mount_points[ object ]
        if mount_point == nil or is_directory_object[ object ] then
            object_size = 0
        else
            object_size = file_Size( mount_paths[ object ] or "", mount_point ) or 0
        end

        raw_set( self, object, object_size )
        return object_size
    end,
    __mode = "k"
} )

---@type table<dreamwork.std.File | dreamwork.std.Directory, integer>
local times = {}

setmetatable( times, {
    ---@param object dreamwork.std.File | dreamwork.std.Directory
    __index = function( self, object )
        local object_time

        local mount_point = mount_points[ object ]
        if mount_point == nil then
            object_time = time_now()
        else
            object_time = file_Time( mount_paths[ object ] or "", mount_point )
        end

        raw_set( self, object, object_time )
        return object_time
    end,
    __mode = "k"
} )

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

--- [SHARED AND MENU]
---
--- Returns the data of a file by given path.
---
---@return string data The data of the file.
---@async
function File:read()

end

--- [SHARED AND MENU]
---
--- Replaces the data of a file.
---
---@param data string The new data of the file.
---@async
function File:write( data )

end

--- [SHARED AND MENU]
---
--- Appends data to the end of a file.
---
---@param data string The data to append.
---@async
function File:append( data )

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
---@param directory dreamwork.std.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function File:move( directory, name )

end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory dreamwork.std.Directory The directory to copy the file to.
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

---@param object dreamwork.std.File | dreamwork.std.Directory
---@param parent dreamwork.std.Directory | nil
local function update_path( object, parent )
    if parent == nil then
        paths[ object ] = "/" .. names[ object ]
    else

        local parent_path = paths[ parent ]

        local uint8_1, uint8_2 = string_byte( parent_path, 1, 2 )
        if uint8_1 == 0x2F --[[ '/' ]] and uint8_2 == nil then
            paths[ object ] = parent_path .. names[ object ]
        else
            paths[ object ] = parent_path .. "/" .. names[ object ]
        end

    end

    if is_directory_object[ object ] then
        ---@cast object dreamwork.std.Directory

        local descendant_list = descendants[ object ]
        for index = 1, descendant_counts[ object ], 1 do
            update_path( descendant_list[ index ], object )
        end
    end
end

---@param directory dreamwork.std.Directory
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

---@param directory dreamwork.std.Directory
---@param name string
local function rel_path( directory, name )
    local mount_path = mount_paths[ directory ]
    if mount_path == nil then
        return name
    else
        return mount_path .. "/" .. name
    end
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

---@class dreamwork.std.FileClass : dreamwork.std.File
---@field __base dreamwork.std.File
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.File
local FileClass = class.create( File )

---@class dreamwork.std.DirectoryClass : dreamwork.std.Directory
---@field __base dreamwork.std.Directory
---@overload fun( name: string, mount_point: string | nil, mount_path: string | nil ): dreamwork.std.Directory
local DirectoryClass = class.create( Directory )

---@param directory dreamwork.std.Directory
---@param new_time integer
local function update_time( directory, new_time )
    while directory ~= nil and new_time > times[ directory ] do
        times[ directory ] = new_time
        directory = parents[ directory ]
    end
end

---@param directory dreamwork.std.Directory
---@param byte_count integer
local function size_add( directory, byte_count )
    while directory ~= nil do
        sizes[ directory ] = sizes[ directory ] + byte_count
        directory = parents[ directory ]
    end
end

---@param directory dreamwork.std.Directory
---@param descendant dreamwork.std.File | dreamwork.std.Directory
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
    update_time( directory, times[ descendant ] )
    size_add( directory, sizes[ descendant ] )
end

---@param directory dreamwork.std.Directory
---@param name string
local function eject( directory, name )
    local descendants_table = descendants[ directory ]

    local descendant = descendants_table[ name ]
    if descendant == nil then
        return
    end

    size_add( directory, -sizes[ descendant ] )
    update_time( directory, time_now() )
    update_path( descendant, nil )

    descendants_table[ name ] = nil
    table_remove( descendants_table, indexes[ descendant ] )

    indexes[ descendant ] = nil

    descendant_counts[ directory ] = descendant_counts[ directory ] - 1

    parents[ descendant ] = nil
end

---@param wildcard string | nil
---@return dreamwork.std.File[], integer, dreamwork.std.Directory[], integer
function Directory:select( wildcard )
    local descendants_table = descendants[ self ]

    local directories, directory_count = {}, 0
    local files, file_count = {}, 0

    for index = 1, descendant_counts[ self ], 1 do
        ---@type dreamwork.std.File | dreamwork.std.Directory
        local object = descendants_table[ index ]
        if is_directory_object[ object ] then
            directory_count = directory_count + 1
            directories[ directory_count ] = object
        else
            file_count = file_count + 1
            files[ file_count ] = object
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
---@param callback nil | fun( directory: dreamwork.std.Directory, callback_value: any )
---@param callback_value any
function Directory:scan( deep_scan, full_update, callback, callback_value )
    local descendant_count = descendant_counts[ self ]
    local descendants_table = descendants[ self ]

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
                update_time( self, unix_time )

                sizes[ descendant ] = size
                size_add( self, size )
            end
        end

    end

    local mount_point = mount_points[ self ]
    if mount_point ~= nil then

        local mount_path = mount_paths[ self ]
        if mount_path == nil then

            local fs_files, fs_directories = file_Find( "*", mount_point )

            for i = 1, #fs_files, 1 do
                local file_name = fs_files[ i ]
                if descendants_table[ file_name ] == nil then
                    insert( self, FileClass( file_name, mount_point, file_name ) )
                end
            end

            for i = 1, #fs_directories, 1 do
                local directory_name = fs_directories[ i ]
                if descendants_table[ directory_name ] == nil then
                    insert( self, DirectoryClass( directory_name, mount_point, directory_name ) )
                end
            end

        else

            local fs_files, fs_directories = file_Find( mount_path .. "/*", mount_point )

             for i = 1, #fs_files, 1 do
                local file_name = fs_files[ i ]
                if descendants_table[ file_name ] == nil then
                    insert( self, FileClass( file_name, mount_point, mount_path .. "/" .. file_name ) )
                end
            end

            for i = 1, #fs_directories, 1 do
                local directory_name = fs_directories[ i ]
                if descendants_table[ directory_name ] == nil then
                    insert( self, DirectoryClass( directory_name, mount_point, mount_path .. "/" .. directory_name ) )
                end
            end

        end

    end

    if callback ~= nil then
        callback( self, callback_value )
    end

    if deep_scan then
        for i = 1, descendant_count, 1 do
            local directory = descendants_table[ i ]
            if is_directory_object[ directory ] then
                ---@cast directory dreamwork.std.Directory
                directory:scan( deep_scan, full_update, callback, callback_value )
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
            ---@cast self dreamwork.std.Directory

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
                ---@cast content_value dreamwork.std.File
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

---@param file_callback nil | fun( file: dreamwork.std.File )
---@param directory_callback nil | fun( directory: dreamwork.std.Directory )
function Directory:foreach( file_callback, directory_callback )
    local files, file_count, directories, directory_count = self:select()

    if file_callback == nil then
        if directory_callback == nil then
            return
        end
    else
        for index = 1, file_count, 1 do
            ---@type dreamwork.std.File
            ---@diagnostic disable-next-line: param-type-mismatch
            file_callback( files[ index ] )
        end
    end

    for index = 1, directory_count, 1 do
        ---@type dreamwork.std.Directory
        ---@diagnostic disable-next-line: assign-type-mismatch
        local directory = directories[ index ]

        if directory_callback ~= nil then
            directory_callback( directory )
        end

        directory:foreach( file_callback, directory_callback )
    end
end

---@param parent dreamwork.std.Directory
---@param name string
---@param forced? boolean
---@return dreamwork.std.Directory | nil new_directory
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
        ---@cast directory_object dreamwork.std.Directory
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
---@return dreamwork.std.Directory
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
---@return dreamwork.std.File | dreamwork.std.Directory object
---@return boolean is_directory
function Directory:touch( name )
    if string_byte( name, 1, 1 ) == nil then
        error( "file or directory name cannot be empty", 2 )
    end

    local object = descendants[ self ][ name ]

    if object == nil then
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

        object = FileClass( name, mount_point, mount_path )
        insert( self, object )
        return object, false
    end

    local mount_point = mount_points[ object ]
    if mount_point == nil or not writeable_mounts[ mount_point ] then
        error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory creation.", 2 )
    end

    if is_directory_object[ object ] then
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

        local new_time = file_Time( rel_path( self, name ), mount_point )
        update_time( self, new_time )
        times[ object ] = new_time

        return object, true
    end

    local mount_path = mount_paths[ object ]

    local handler = file_Open( mount_path, "wb", mount_point )
    if handler == nil then
        error( "Unknown filesystem error, handler is not available.", 2 )
    end

    FILE_Close( handler )

    local new_time = file_Time( mount_path, mount_point )
    update_time( self, new_time )
    times[ object ] = new_time

    return object, false
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
---@param directory dreamwork.std.Directory The directory to move the file to.
---@param name? string The new name of the file. If `nil`, the original name will be used.
---@async
function Directory:move( directory, name )

end

--- [SHARED AND MENU]
---
--- Copies a file to another directory.
---
---@param directory dreamwork.std.Directory The directory to copy the file to.
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

    local object = descendants[ self ][ name ]

    if object == nil then
        local mount_point = mount_points[ self ]
        if mount_point == nil or not deletable_mounts[ mount_point ] then
            error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory removal.", 2 )
        end

        local mount_path = rel_path( self, name )

        if file_Exists( mount_path, mount_point ) then
            if file_IsDir( mount_path, mount_point ) then
                if recursive then
                    local directory_object = DirectoryClass( name, mount_point, mount_path )
                    local files, file_count, directories, directory_count = directory_object:select()

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

    local mount_point = mount_points[ object ]
    if mount_point == nil or not deletable_mounts[ mount_point ] then
        error( "Path '" .. abs_path( self, name ) .. "' does not support file or directory removal.", 2 )
    end

    if is_directory_object[ object ] then
        ---@cast object dreamwork.std.Directory
        if recursive then
            local files, file_count, directories, directory_count = object:select()

            for i = 1, file_count, 1 do
                local file_object = files[ i ]
                file_Delete( mount_paths[ file_object ], mount_points[ file_object ] )
                eject( self, file_object.name )
            end

            for i = 1, directory_count, 1 do
                object:remove( directories[ i ].name, forced, recursive )
            end
        else

            local files, directories = file_Find( mount_points[ object ] .. "/*", mount_point )
            if ( #files + #directories ) ~= 0 then
                error( "Directory '" .. abs_path( self, name ) .. "' is not empty.", 2 )
            end

        end
    end

    file_Delete( mount_paths[ object ], mount_point )
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
        lines[ 1 ] = std.tostring( self )
        next_prefix = " "
    else
        lines[ 1 ] = prefix .. ( is_last and "╚═ " or "╠═ " ) .. std.tostring( self )

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
            ---@cast descendant dreamwork.std.Directory
            lines[ line_count ] = descendant:toStringTree( next_prefix, i == children_length )
        else
            ---@cast descendant dreamwork.std.File
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

-- std.setTimeout( function()
--     root:get( "workspace/lua/dreamwork" ):scan( true, true )
--     std.print( root:toStringTree())
-- end, 1 )

-- TODO: efsw support
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
--- Returns the file or directory by given path as a `dreamwork.std.File` or `dreamwork.std.Directory` object.
---
---@param path_to string The path to the file or directory.
---@return dreamwork.std.File | dreamwork.std.Directory | nil object The file or directory.
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

    ---@cast directory dreamwork.std.Directory
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

    ---@cast directory dreamwork.std.Directory
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
--- Checks if a file or directory is empty by given path.
---
---@param path_to string The path to the file or directory.
---@return boolean empty Returns `true` if the file or directory is empty, otherwise `false`.
---@return boolean is_directory Returns `true` if the object is a directory, otherwise `false`.
function fs.isEmpty( path_to, forced )
    local object, is_directory = root:get( prepare_path( path_to ) )
    if object == nil then
        if forced then
            return true, false
        else
            error( "Path '" .. path_to .. "' does not exist.", 2 )
        end
    elseif is_directory then
        ---@cast object dreamwork.std.Directory
        return object:isEmpty(), true
    else
        return object.size == 0, false
    end
end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer unix_time The last modified time of the file or directory.
function fs.time( file_path, forced )
    local object = root:get( prepare_path( file_path ) )
    if object == nil then
        if forced then
            return 0
        else
            error( "Path '" .. file_path .. "' does not exist.", 2 )
        end
    else
        return object.time
    end
end

--- [SHARED AND MENU]
---
--- Returns the size of a file or directory by given path.
---
---@param file_path string The path to the file or directory.
---@return integer size The size of the file or directory in bytes.
function fs.size( file_path, forced )
    local object = root:get( prepare_path( file_path ) )
    if object == nil then
        if forced then
            return 0
        else
            error( "Path '" .. file_path .. "' does not exist.", 2 )
        end
    else
        return object.size
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
---@return dreamwork.std.File[] files The list of files in the directory.
---@return integer file_count The number of files in the directory.
---@return dreamwork.std.Directory[] directories The list of directories in the directory.
---@return integer directory_count The number of directories in the directory.
function fs.select( directory_path, wildcard )
    local directory_object, is_directory = root:get( prepare_path( directory_path ) )
    if directory_object == nil or not is_directory then
        return {}, 0, {}, 0
    else
        ---@cast directory_object dreamwork.std.Directory
        return directory_object:select( wildcard )
    end
end

do

    local futures_yield = std.futures.yield

    ---@param file_object dreamwork.std.File
    ---@async
    local function iterate_file( file_object )
        return futures_yield( file_object.path, false )
    end

    ---@param directory_object dreamwork.std.Directory
    ---@async
    local function iterate_directory( directory_object )
        return futures_yield( directory_object.path, true )
    end

    ---@async
    function fs.iterator( directory_path )
        local directory_object, is_directory = root:get( prepare_path( directory_path ) )
        if directory_object ~= nil and is_directory then
            ---@cast directory_object dreamwork.std.Directory
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
