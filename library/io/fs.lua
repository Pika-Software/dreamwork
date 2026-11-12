---@meta _

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
---@class File : Object
---@field __class FileClass
---@field path string The absolute virtual path of the file, assigning moves the file without overwriting, the target directory must exist.
---@field name string The name of the file with its extension, assigning renames the file without overwriting.
---@field content string The file data, reading reads the whole file, assigning replaces it.
---@field size integer The size of the file in bytes, `0` if the file does not exist. **Read-only.**
---@field parent Directory The directory the file is in, assigning moves the file into the directory without overwriting.
local __File = {}

---@class FileClass : File, Class
---@field __base File
---@overload fun( file_path: string, touch: boolean? ): File
File = {}

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
---@class Directory : Object
---@field __class DirectoryClass
---@field path string The absolute virtual path of the directory, assigning moves the directory without overwriting, the target directory must exist.
---@field name string The name of the directory, empty for the root, assigning renames the directory without overwriting.
---@field size integer The total size of everything in the directory in bytes, walked recursively, `0` if the directory does not exist. **Read-only.**
---@field parent Directory The parent directory, the root returns itself, assigning moves the directory into the directory without overwriting.
local __Directory = {}

---@class DirectoryClass : Directory, Class
---@field __base Directory
---@overload fun( directory_path: string, touch: boolean? ): Directory
Directory = {}

---@param file_path string The absolute path to the file.
---@param touch boolean? If `true`, the file is created or touched right away, otherwise it waits for `write`, `append` or `touch`.
---@return File object
---@protected
function File:__new(file_path, touch) end

---@param key string The field name being read.
---@return any value
---@protected
function __File:__index(key) end

---@param key string
---@param value any
---@protected
function __File:__newindex(key, value) end

---@protected
---@return string
function __File:__represent() end

---@return boolean is_valid `true` if the file exists, `false` otherwise.
---@protected
function __File:__isvalid() end

--- [SHARED AND MENU]
---
--- Checks if the file exists.
---
---@return boolean exists `true` if the file exists, `false` otherwise.
---@nodiscard
function __File:exists() end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates an empty file with missing directories, or updates the modification time keeping its content.
---
function __File:touch() end

--- [SHARED AND MENU]
---
--- Reads the whole file, asynchronously inside of a coroutine.
---
---@return string data The file data.
---@nodiscard
---@async
function __File:read() end

--- [SHARED AND MENU]
---
--- Replaces the file data, the file and missing directories are created, asynchronously inside of a coroutine.
---
---@param data string The new data.
---@async
function __File:write(data) end

--- [SHARED AND MENU]
---
--- Appends data to the end of the file, the file and missing directories are created, asynchronously inside of a coroutine.
---
---@param data string The data to append.
---@async
function __File:append(data) end

--- [SHARED AND MENU]
---
--- Deletes the file, the object stays usable and `write` or `touch` creates it again.
---
---@param force boolean? If `true`, a missing file or a failed deletion are ignored instead of raising errors.
---@return boolean deleted `true` if the file was deleted, can be `false` only when `force` is `true`.
function __File:delete(force) end

--- [SHARED AND MENU]
---
--- Moves the file, the target directory must exist, asynchronously inside of a coroutine.
---
--- The object follows the file, its `path` and `name` are updated.
---
---@param target_path string The new absolute path of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@async
function __File:move(target_path, overwrite) end

--- [SHARED AND MENU]
---
--- Renames the file, it stays in its directory, asynchronously inside of a coroutine.
---
--- The object follows the file, its `path` and `name` are updated.
---
---@param name string The new name of the file.
---@param overwrite boolean? If `true`, the existing file is replaced, otherwise the target must not exist.
---@async
function __File:rename(name, overwrite) end

---@param directory_path string The absolute path to the directory.
---@param touch boolean? If `true`, the directory is created or touched right away, otherwise it waits for `touch` or a write inside of it.
---@return Directory object
---@protected
function Directory:__new(directory_path, touch) end

---@param key string The field name being read.
---@return any value
---@protected
function __Directory:__index(key) end

---@param key string
---@param value any
---@protected
function __Directory:__newindex(key, value) end

---@protected
---@return string
function __Directory:__represent() end

---@return boolean is_valid `true` if the directory exists, `false` otherwise.
---@protected
function __Directory:__isvalid() end

--- [SHARED AND MENU]
---
--- Checks if the directory exists.
---
---@return boolean exists `true` if the directory exists, `false` otherwise.
---@nodiscard
function __Directory:exists() end

--- [SHARED AND MENU]
---
--- Returns the file object for a name inside of the directory, the file does not have to exist.
---
---@param name string The name of the file.
---@return File file The file object.
---@nodiscard
function __Directory:getFile(name) end

--- [SHARED AND MENU]
---
--- Returns the directory object for a name inside of the directory, the directory does not have to exist.
---
---@param name string The name of the directory.
---@return Directory directory The directory object.
---@nodiscard
function __Directory:getDirectory(name) end

--- [SHARED AND MENU]
---
--- Lists files and directories in the directory by wildcard, subdirectories are not searched.
---
--- ```lua
--- local files, file_count, directories, directory_count = directory:search( "*.txt" )
--- ```
---
---@param wildcard string? The wildcard names must match, see `path.wildcard`, `*` by default.
---@return File[] files The found files.
---@return integer file_count The number of the found files.
---@return Directory[] directories The found directories.
---@return integer directory_count The number of the found directories.
---@nodiscard
function __Directory:search(wildcard) end

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
---@return fun(): File | nil iterator The iterator that returns the file objects.
---@nodiscard
function __Directory:files(recursive) end

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
---@return fun(): Directory | nil iterator The iterator that returns the directory objects.
---@nodiscard
function __Directory:directories(recursive) end

--- [SHARED AND MENU]
---
--- Like Linux `touch`: creates the directory with missing parent directories, or updates its modification time.
---
function __Directory:touch() end

--- [SHARED AND MENU]
---
--- Deletes the directory, the object stays usable and `touch` creates it again.
---
---@param recursive boolean? If `true`, the directory is deleted with everything in it, otherwise it must be empty.
---@param force boolean? If `true`, the directory is deleted with everything in it, a missing directory or a failed deletion are ignored instead of raising errors.
---@return boolean deleted `true` if the directory was deleted, can be `false` only when `force` is `true`.
function __Directory:delete(recursive, force) end

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
function __Directory:move(target_path, overwrite) end

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
function __Directory:rename(name, overwrite) end

--- [SHARED AND MENU]
---
--- Checks if a file exists.
---
---@param file_path string The absolute path to the file.
---@return boolean exists `true` if the file exists, `false` otherwise.
---@nodiscard
function File.exists(file_path) end

--- [SHARED AND MENU]
---
--- Checks if a directory exists.
---
---@param directory_path string The absolute path to the directory.
---@return boolean exists `true` if the directory exists, `false` otherwise.
---@nodiscard
function Directory.exists(directory_path) end

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
---@return File[] files The found files.
---@return integer file_count The number of the found files.
---@return Directory[] directories The found directories.
---@return integer directory_count The number of the found directories.
---@nodiscard
function Directory.search(directory_path, wildcard) end
