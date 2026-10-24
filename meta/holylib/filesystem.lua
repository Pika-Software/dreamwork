---@meta holylib.filesystem


--- [SHARED AND MENU]
---
--- This library contains additional functions and replacements for the [file](https://wiki.facepunch.com/gmod/file) library, built directly on the engine filesystem.
---
--- Functions that change files or search paths are protected by HolyLib's unsafe code check.
---
---@class holylib.filesystem
filesystem = {}

--- [SHARED AND MENU]
---
--- Reads the given file asynchronously.
---
--- The callback is called from the Lua think hook once the read is finished.
---
---@param relative_path string The path of the file to read.
---@param mount string The mount (game path) to search the file in. See [File Search Paths](https://wiki.facepunch.com/gmod/File_Search_Paths).
---@param callback garrysmod.file.AsyncReadCallback The function called with `( file_name, mount, status, content )` when the read is finished.
---@param sync boolean? If `true`, the read is done synchronously.
---@return garrysmod.file.AsyncStatus status The [FSASYNC](https://wiki.facepunch.com/gmod/Enums/FSASYNC) status of the queued read.
function filesystem.AsyncRead( relative_path, mount, callback, sync ) end

--- [SHARED AND MENU]
---
--- Creates a directory and all of its missing parent directories.
---
--- If unsafe code is disabled, the mount is always `DATA`.
---
---@param relative_path string The path of the directory to create.
---@param mount string? The mount to create the directory in. Defaults to `DATA`.
function filesystem.CreateDir( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Deletes the given file.
---
--- If unsafe code is disabled, the mount is always `DATA`.
---
---@param relative_path string The path of the file to delete.
---@param mount string? The mount to delete the file from. Defaults to `DATA`.
function filesystem.Delete( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns whether the given file or directory exists.
---
---@param relative_path string The path of the file or directory.
---@param mount string The mount to search in.
---@return boolean exists `true` if the file or directory exists.
function filesystem.Exists( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the files and directories matching the given wildcard.
---
---@param wildcard string The wildcard to search for, e.g. `models/*.mdl`.
---@param mount string The mount to search in.
---@param sorting_mode garrysmod.file.SortingType? The sorting mode, `namedesc`, `dateasc` or `datedesc`. Any other value sorts by name ascending.
---@return string[] files The found files.
---@return string[] directories The found directories.
function filesystem.Find( wildcard, mount, sorting_mode ) end

--- [SHARED AND MENU]
---
--- Returns whether the given path is a directory.
---
---@param relative_path string The path to check.
---@param mount string The mount to search in.
---@return boolean is_dir `true` if the path is a directory.
function filesystem.IsDir( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Opens the given file.
---
---@param relative_path string The path of the file to open.
---@param mode garrysmod.file.AccessType The file access mode, e.g. `rb` or `wb`.
---@param mount string? The mount to open the file in. Defaults to `GAME`.
---@return garrysmod.File | nil file The opened file object, or `nil` on failure.
function filesystem.Open( relative_path, mode, mount ) end

--- [SHARED AND MENU]
---
--- Renames or moves the given file.
---
--- If unsafe code is disabled, the mount is always `DATA`.
---
---@param relative_path string The current path of the file.
---@param new_path string The new path of the file.
---@param mount string? The mount the file is in. Defaults to `DATA`.
---@return boolean success `true` if the file was renamed.
function filesystem.Rename( relative_path, new_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the size of the given file.
---
---@param relative_path string The path of the file.
---@param mount string? The mount to search in. Defaults to `GAME`.
---@return -1 | integer size The size of the file in bytes, or `-1` if the file doesn't exist.
function filesystem.Size( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the last modification time of the given file.
---
---@param relative_path string The path of the file.
---@param mount string? The mount to search in. Defaults to `GAME`.
---@return 0 | integer unix_time The last modification time as a Unix timestamp, or `0` if the file doesn't exist.
function filesystem.Time( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the creation time of the given file.
---
---@param relative_path string The path of the file.
---@param mount string? The mount to search in. Defaults to `GAME`.
---@return 0 | integer unix_time The creation time as a Unix timestamp, or `0` if the path can't be resolved.
function filesystem.TimeCreated( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the last access time of the given file.
---
---@param relative_path string The path of the file.
---@param mount string? The mount to search in. Defaults to `GAME`.
---@return 0 | integer unix_time The last access time as a Unix timestamp, or `0` if the path can't be resolved.
function filesystem.TimeAccessed( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Adds a search path (a folder on disk) to the given mount.
---
--- Must be called from the main thread.
---
---@param system_path string The full path of the folder on disk.
---@param mount string The mount to add the search path to.
---@param add_to_head boolean? If `true`, the search path is added to the front, so it takes priority over the existing ones.
function filesystem.AddSearchPath( system_path, mount, add_to_head ) end

--- [SHARED AND MENU]
---
--- Removes a search path from the given mount.
---
--- Must be called from the main thread.
---
---@param system_path string The full path of the folder on disk.
---@param mount string The mount to remove the search path from.
---@return boolean success `true` if the search path was removed.
function filesystem.RemoveSearchPath( system_path, mount ) end

--- [SHARED AND MENU]
---
--- Removes all search paths of the given mount.
---
--- Must be called from the main thread.
---
---@param mount string The mount to remove all search paths from.
function filesystem.RemoveSearchPaths( mount ) end

--- [SHARED AND MENU]
---
--- Removes all search paths of all mounts.
---
--- Must be called from the main thread.
---
function filesystem.RemoveAllSearchPaths() end

--- [SHARED AND MENU]
---
--- Converts a relative path to a full path on disk.
---
--- The result is not checked, if the conversion fails, the input path is usually returned.
---
---@param relative_path string The relative path to convert.
---@param mount string The mount the file is in.
---@return string system_path The full path on disk.
function filesystem.RelativePathToFullPath( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Converts a full path on disk to a relative path.
---
---@param system_path string The full path on disk to convert.
---@param mount string? The mount to resolve the path against. If `nil`, all mounts are checked.
---@return string | nil relative_path The relative path, or `nil` if the conversion fails.
function filesystem.FullPathToRelativePath( system_path, mount ) end
