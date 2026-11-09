local vfs = dreamwork.vfs
local vfs_size = vfs.size
local vfs_isFile = vfs.isFile
local vfs_search = vfs.search
local vfs_foreach = vfs.foreach
local vfs_readFile = vfs.readFile
local vfs_moveFile = vfs.moveFile
local vfs_touchFile = vfs.touchFile
local vfs_writeFile = vfs.writeFile
local vfs_deleteFile = vfs.deleteFile
local vfs_appendFile = vfs.appendFile
local vfs_renameFile = vfs.renameFile
local vfs_isDirectory = vfs.isDirectory
local vfs_moveDirectory = vfs.moveDirectory
local vfs_touchDirectory = vfs.touchDirectory
local vfs_deleteDirectory = vfs.deleteDirectory
local vfs_renameDirectory = vfs.renameDirectory

---@class dreamwork.std
local std = dreamwork.std

local class = std.class
local class_new = class.new

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local path = std.path
local path_getFile = path.getFile
local path_normalize = path.normalize
local path_getDirectory = path.getDirectory

local raw = std.raw
local raw_index = raw.index
local raw_tostring = raw.tostring

local string = std.string
local string_format = string.format

local error = std.error


--- The absolute virtual paths of files and directories.
---
---@type table<dreamwork.std.fs.File | dreamwork.std.fs.Directory, string>
local paths = {}
gc_setTableRules( paths, true, false )

--- The names of files and directories.
---
---@type table<dreamwork.std.fs.File | dreamwork.std.fs.Directory, string>
local names = {}
gc_setTableRules( names, true, false )

--- The file objects by their paths, the same path gives the same object.
---
---@type table<string, dreamwork.std.fs.File>
local file_objects = {}
gc_setTableRules( file_objects, false, true )

--- The directory objects by their paths, the same path gives the same object.
---
---@type table<string, dreamwork.std.fs.Directory>
local directory_objects = {}
gc_setTableRules( directory_objects, false, true )

---@param directory_path string
---@param name string
---@return string
local function child_path( directory_path, name )
    if directory_path == "/" then
        return "/" .. name
    end

    return directory_path .. "/" .. name
end

---@param object dreamwork.std.fs.File | dreamwork.std.fs.Directory
---@param new_path string
---@param objects table<string, dreamwork.std.fs.File | dreamwork.std.fs.Directory>
local function set_path( object, new_path, objects )
    local old_path = paths[ object ]
    if old_path ~= nil and objects[ old_path ] == object then
        objects[ old_path ] = nil
    end

    paths[ object ] = new_path
    names[ object ] = path_getFile( new_path, true )
    objects[ new_path ] = object
end

---@param object dreamwork.std.fs.File | dreamwork.std.fs.Directory
---@param name string
---@return string
local function sibling_path( object, name )
    return child_path( path_getDirectory( paths[ object ], false ) or "/", name )
end

---@param object dreamwork.std.fs.File
---@param target_path string
---@param overwrite boolean?
---@param stack_level integer
---@async
local function move_file( object, target_path, overwrite, stack_level )
    target_path = path_normalize( target_path, false )
    vfs_moveFile( paths[ object ], target_path, overwrite, stack_level + 1 )
    set_path( object, target_path, file_objects )
end

---@param object dreamwork.std.fs.File
---@param name string
---@param overwrite boolean?
---@param stack_level integer
---@async
local function rename_file( object, name, overwrite, stack_level )
    vfs_renameFile( paths[ object ], name, overwrite, stack_level + 1 )
    set_path( object, sibling_path( object, name ), file_objects )
end

---@param object dreamwork.std.fs.Directory
---@param target_path string
---@param overwrite boolean?
---@param stack_level integer
---@async
local function move_directory( object, target_path, overwrite, stack_level )
    target_path = path_normalize( target_path, false )
    vfs_moveDirectory( paths[ object ], target_path, overwrite, stack_level + 1 )
    set_path( object, target_path, directory_objects )
end

---@param object dreamwork.std.fs.Directory
---@param name string
---@param overwrite boolean?
---@param stack_level integer
---@async
local function rename_directory( object, name, overwrite, stack_level )
    vfs_renameDirectory( paths[ object ], name, overwrite, stack_level + 1 )
    set_path( object, sibling_path( object, name ), directory_objects )
end

--- [SHARED AND MENU]
---
--- The file object.
---
--- A thin handle over a `vfs` path, the file is not opened or cached,
--- every call goes to `vfs`, so the object can exist before its file.
---
--- Fields `path`, `name` and `content` are backed by `vfs`, assigning them moves, renames or writes the file,
--- reading and writing are asynchronous inside of a coroutine and synchronous outside of it.
---
--- ```lua
--- local file = File( "/garrysmod/data/test.txt" )
--- file.content = "hello" -- write
--- print( file.content, file.size ) -- "hello" 5
--- file.name = "renamed.txt" -- rename
--- file.path = "/garrysmod/data/other/test.txt" -- move
--- ```
---
---@class dreamwork.std.fs.File : dreamwork.std.Object
---@field __class dreamwork.std.fs.FileClass
---@field path string The absolute virtual path of the file, assigning moves the file without overwriting, the target directory must exist.
---@field name string The name of the file with its extension, assigning renames the file without overwriting.
---@field content string The file data, reading reads the whole file, assigning replaces it.
---@field size integer The size of the file in bytes, `0` if the file does not exist. **Read-only.**
---@field parent dreamwork.std.fs.Directory The directory the file is in, assigning moves the file into the directory without overwriting.
local File = class.base( "File", true )

---@class dreamwork.std.fs.FileClass : dreamwork.std.fs.File, dreamwork.std.Class
---@field __base dreamwork.std.fs.File
---@overload fun( file_path: string, touch: boolean? ): dreamwork.std.fs.File
local FileClass = class.create( File )
std.File = FileClass

--- [SHARED AND MENU]
---
--- The directory object.
---
--- A thin handle over a `vfs` path, every call goes to `vfs`,
--- so the object can exist before its directory.
---
--- Moving and renaming are asynchronous inside of a coroutine and synchronous outside of it.
---
--- ```lua
--- local directory = Directory( "/garrysmod/data/test", true )
--- local files, file_count = directory:search( "*.txt" )
--- ```
---
---@class dreamwork.std.fs.Directory : dreamwork.std.Object
---@field __class dreamwork.std.fs.DirectoryClass
---@field path string The absolute virtual path of the directory, assigning moves the directory without overwriting, the target directory must exist.
---@field name string The name of the directory, empty for the root, assigning renames the directory without overwriting.
---@field size integer The total size of everything in the directory in bytes, walked recursively, `0` if the directory does not exist. **Read-only.**
---@field parent dreamwork.std.fs.Directory The parent directory, the root returns itself, assigning moves the directory into the directory without overwriting.
local Directory = class.base( "Directory", true )

---@class dreamwork.std.fs.DirectoryClass : dreamwork.std.fs.Directory, dreamwork.std.Class
---@field __base dreamwork.std.fs.Directory
---@overload fun( directory_path: string, touch: boolean? ): dreamwork.std.fs.Directory
local DirectoryClass = class.create( Directory )
std.Directory = DirectoryClass

---@param directory_path string
---@param wildcard string?
---@param stack_level integer
---@return dreamwork.std.fs.File[] files
---@return integer file_count
---@return dreamwork.std.fs.Directory[] directories
---@return integer directory_count
local function search_directory( directory_path, wildcard, stack_level )
    local file_names, file_count, directory_names, directory_count = vfs_search( directory_path, wildcard, stack_level + 1 )

    ---@type dreamwork.std.fs.File[]
    local files = {}

    ---@type dreamwork.std.fs.Directory[]
    local directories = {}

    for index = 1, file_count, 1 do
        files[ index ] = FileClass( child_path( directory_path, file_names[ index ] ) )
    end

    for index = 1, directory_count, 1 do
        directories[ index ] = DirectoryClass( child_path( directory_path, directory_names[ index ] ) )
    end

    return files, file_count, directories, directory_count
end

---@param directory_path string
---@param recursive boolean?
---@param directories boolean `true` to return directories, `false` to return files.
---@param stack_level integer
---@return fun(): dreamwork.std.fs.File | dreamwork.std.fs.Directory | nil
local function iterate_directory( directory_path, recursive, directories, stack_level )
    local cls = directories and DirectoryClass or FileClass

    if recursive then
        local foreach = vfs_foreach( directory_path, stack_level + 1 )

        return function()
            ::entry_lookup::

            local entry_path, is_directory = foreach()
            if entry_path == nil then
                return nil
            end

            if is_directory ~= directories then
                goto entry_lookup
            end

            return cls( entry_path )
        end
    end

    local entry_names, count, directory_names, directory_count = vfs_search( directory_path, nil, stack_level + 1 )
    if directories then
        entry_names, count = directory_names, directory_count
    end

    local index = 0

    return function()
        if index == count then
            return nil
        end

        index = index + 1
        return cls( child_path( directory_path, entry_names[ index ] ) )
    end
end

---@param object dreamwork.std.fs.File | dreamwork.std.fs.Directory
---@return dreamwork.std.fs.Directory
local function get_parent( object )
    local object_path = paths[ object ]

    local parent_path = path_getDirectory( object_path, false )
    if parent_path == nil or parent_path == object_path then
        ---@cast object dreamwork.std.fs.Directory
        return object
    end

    return DirectoryClass( parent_path )
end

---@param file_path string The absolute path to the file.
---@param touch boolean? If `true`, the file is created or touched right away, otherwise it waits for `write`, `append` or `touch`.
---@return dreamwork.std.fs.File object
---@protected
function FileClass:__new( file_path, touch )
    file_path = path_normalize( file_path, false )

    local object = file_objects[ file_path ]
    if object == nil then
        object = class_new( File )
        set_path( object, file_path, file_objects )
    end

    if touch then
        vfs_touchFile( file_path, 3 )
    end

    return object
end

---@param key string The field name being read.
---@return any value
---@protected
function File:__index( key )
    if key == "path" then
        return paths[ self ]
    elseif key == "name" then
        return names[ self ]
    elseif key == "parent" then
        return get_parent( self )
    elseif key == "content" then
        return vfs_readFile( paths[ self ], 2 )
    elseif key == "size" then
        return vfs_size( paths[ self ], 2 )
    end

    return raw_index( File, key )
end

---@param key string
---@param value any
---@protected
function File:__newindex( key, value )
    if key == "content" then
        vfs_writeFile( paths[ self ], value, 2 )
    elseif key == "name" then
        rename_file( self, value, false, 2 )
    elseif key == "path" then
        move_file( self, value, false, 2 )
    elseif key == "parent" then
        move_file( self, child_path( paths[ value ], names[ self ] ), false, 2 )
    else
        error( string_format( "attempt to modify read-only File property '%s'", raw_tostring( key ) ), 2 )
    end
end

---@protected
---@return string
function File:__represent()
    return string_format( "File: %p [%s]", self, paths[ self ] )
end

---@return boolean is_valid `true` if the file exists, `false` otherwise.
---@protected
function File:__isvalid()
    return vfs_isFile( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Checks if the file exists.
---
---@return boolean exists `true` if the file exists, `false` otherwise.
---@nodiscard
function File:exists()
    return vfs_isFile( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates an empty file with missing directories, or updates the modification time keeping its content.
---
function File:touch()
    vfs_touchFile( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Reads the whole file, asynchronously inside of a coroutine.
---
---@return string data The file data.
---@nodiscard
---@async
function File:read()
    return vfs_readFile( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Replaces the file data, the file and missing directories are created, asynchronously inside of a coroutine.
---
---@param data string The new data.
---@async
function File:write( data )
    vfs_writeFile( paths[ self ], data, 2 )
end

--- [SHARED AND MENU]
---
--- Appends data to the end of the file, the file and missing directories are created, asynchronously inside of a coroutine.
---
---@param data string The data to append.
---@async
function File:append( data )
    vfs_appendFile( paths[ self ], data, 2 )
end

--- [SHARED AND MENU]
---
--- Deletes the file, the object stays usable and `write` or `touch` creates it again.
---
function File:delete()
    vfs_deleteFile( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Moves the file, the target directory must exist, asynchronously inside of a coroutine.
---
--- The object follows the file, its `path` and `name` are updated.
---
---@param target_path string The new absolute path of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@async
function File:move( target_path, overwrite )
    move_file( self, target_path, overwrite, 2 )
end

--- [SHARED AND MENU]
---
--- Renames the file, it stays in its directory, asynchronously inside of a coroutine.
---
--- The object follows the file, its `path` and `name` are updated.
---
---@param name string The new name of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@async
function File:rename( name, overwrite )
    rename_file( self, name, overwrite, 2 )
end

---@param directory_path string The absolute path to the directory.
---@param touch boolean? If `true`, the directory is created or touched right away, otherwise it waits for `touch` or a write inside of it.
---@return dreamwork.std.fs.Directory object
---@protected
function DirectoryClass:__new( directory_path, touch )
    directory_path = path_normalize( directory_path, false )

    local object = directory_objects[ directory_path ]
    if object == nil then
        object = class_new( Directory )
        set_path( object, directory_path, directory_objects )
    end

    if touch then
        vfs_touchDirectory( directory_path, 3 )
    end

    return object
end

---@param key string The field name being read.
---@return any value
---@protected
function Directory:__index( key )
    if key == "path" then
        return paths[ self ]
    elseif key == "name" then
        return names[ self ]
    elseif key == "parent" then
        return get_parent( self )
    elseif key == "size" then
        return vfs_size( paths[ self ], 2 )
    end

    return raw_index( Directory, key )
end

---@param key string
---@param value any
---@protected
function Directory:__newindex( key, value )
    if key == "name" then
        rename_directory( self, value, false, 2 )
    elseif key == "path" then
        move_directory( self, value, false, 2 )
    elseif key == "parent" then
        move_directory( self, child_path( paths[ value ], names[ self ] ), false, 2 )
    else
        error( string_format( "attempt to modify read-only Directory property '%s'", raw_tostring( key ) ), 2 )
    end
end

---@protected
---@return string
function Directory:__represent()
    return string_format( "Directory: %p [%s]", self, paths[ self ] )
end

---@return boolean is_valid `true` if the directory exists, `false` otherwise.
---@protected
function Directory:__isvalid()
    return vfs_isDirectory( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Checks if the directory exists.
---
---@return boolean exists `true` if the directory exists, `false` otherwise.
---@nodiscard
function Directory:exists()
    return vfs_isDirectory( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Returns the file object for a name inside of the directory, the file does not have to exist.
---
---@param name string The name of the file.
---@return dreamwork.std.fs.File file The file object.
---@nodiscard
function Directory:getFile( name )
    return FileClass( child_path( paths[ self ], name ) )
end

--- [SHARED AND MENU]
---
--- Returns the directory object for a name inside of the directory, the directory does not have to exist.
---
---@param name string The name of the directory.
---@return dreamwork.std.fs.Directory directory The directory object.
---@nodiscard
function Directory:getDirectory( name )
    return DirectoryClass( child_path( paths[ self ], name ) )
end

--- [SHARED AND MENU]
---
--- Lists files and directories in the directory by wildcard, subdirectories are not searched.
---
--- ```lua
--- local files, file_count, directories, directory_count = directory:search( "*.txt" )
--- ```
---
---@param wildcard string? The wildcard names must match, see `path.wildcard`, `*` by default.
---@return dreamwork.std.fs.File[] files The found files.
---@return integer file_count The number of the found files.
---@return dreamwork.std.fs.Directory[] directories The found directories.
---@return integer directory_count The number of the found directories.
---@nodiscard
function Directory:search( wildcard )
    return search_directory( paths[ self ], wildcard, 2 )
end

--- [SHARED AND MENU]
---
--- Returns the iterator over the files inside of the directory.
---
--- With `recursive`, files of subdirectories are returned too, each directory is listed when the loop gets to it,
--- so changes made inside of the loop are seen.
---
--- ```lua
--- for file in directory:files( true ) do
---     print( file.path )
--- end
--- ```
---
---@param recursive boolean? If `true`, files of subdirectories are returned too, `false` by default.
---@return fun(): dreamwork.std.fs.File | nil iterator The iterator that returns the file objects.
---@nodiscard
function Directory:files( recursive )
    ---@diagnostic disable-next-line: return-type-mismatch
    return iterate_directory( paths[ self ], recursive, false, 2 )
end

--- [SHARED AND MENU]
---
--- Returns the iterator over the directories inside of the directory.
---
--- With `recursive`, directories of subdirectories are returned too, each directory is listed when the loop gets to it,
--- so changes made inside of the loop are seen.
---
--- ```lua
--- for directory in directory:directories( true ) do
---     print( directory.path )
--- end
--- ```
---
---@param recursive boolean? If `true`, directories of subdirectories are returned too, `false` by default.
---@return fun(): dreamwork.std.fs.Directory | nil iterator The iterator that returns the directory objects.
---@nodiscard
function Directory:directories( recursive )
    ---@diagnostic disable-next-line: return-type-mismatch
    return iterate_directory( paths[ self ], recursive, true, 2 )
end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates the directory with missing parent directories, or updates its modification time.
---
function Directory:touch()
    vfs_touchDirectory( paths[ self ], 2 )
end

--- [SHARED AND MENU]
---
--- Deletes the directory, the object stays usable and `touch` creates it again.
---
---@param recursive boolean? If `true`, the directory is deleted with everything in it, otherwise it must be empty.
function Directory:delete( recursive )
    vfs_deleteDirectory( paths[ self ], recursive, 2 )
end

--- [SHARED AND MENU]
---
--- Moves the directory with everything in it, the target directory must exist, asynchronously inside of a coroutine.
---
--- The object follows the directory, its `path` and `name` are updated,
--- objects of files and directories inside of it keep their old paths.
---
---@param target_path string The new absolute path of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@async
function Directory:move( target_path, overwrite )
    move_directory( self, target_path, overwrite, 2 )
end

--- [SHARED AND MENU]
---
--- Renames the directory, it stays in its parent directory, asynchronously inside of a coroutine.
---
--- The object follows the directory, its `path` and `name` are updated,
--- objects of files and directories inside of it keep their old paths.
---
---@param name string The new name of the directory.
---@param overwrite boolean? If `true`, existing files are overwritten and directories are merged, otherwise the target must not exist.
---@async
function Directory:rename( name, overwrite )
    rename_directory( self, name, overwrite, 2 )
end

--- [SHARED AND MENU]
---
--- Checks if a file exists.
---
---@param file_path string The absolute path to the file.
---@return boolean exists `true` if the file exists, `false` otherwise.
---@nodiscard
function FileClass.exists( file_path )
    return vfs_isFile( file_path, 2 )
end

--- [SHARED AND MENU]
---
--- Checks if a directory exists.
---
---@param directory_path string The absolute path to the directory.
---@return boolean exists `true` if the directory exists, `false` otherwise.
---@nodiscard
function DirectoryClass.exists( directory_path )
    return vfs_isDirectory( directory_path, 2 )
end

--- [SHARED AND MENU]
---
--- Lists files and directories in a directory by wildcard, subdirectories are not searched.
---
--- ```lua
--- local files, file_count, directories, directory_count = Directory.search( "/garrysmod/data", "*.txt" )
--- ```
---
---@param directory_path string The absolute path to the directory.
---@param wildcard string? The wildcard names must match, see `path.wildcard`, `*` by default.
---@return dreamwork.std.fs.File[] files The found files.
---@return integer file_count The number of the found files.
---@return dreamwork.std.fs.Directory[] directories The found directories.
---@return integer directory_count The number of the found directories.
---@nodiscard
function DirectoryClass.search( directory_path, wildcard )
    return search_directory( path_normalize( directory_path, false ), wildcard, 2 )
end
