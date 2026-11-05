---@meta garrysmod.file


---@alias garrysmod.file.AsyncStatus
---| -8 # file name is not part of the file system; please try another one
---| -7 # please retry later (network problems, etc)
---| -6 # hard subsystem failure
---| -5 # read parameters are invalid for unbuffered I/O
---| -4 # read error on file
---| -3 # write error on file
---| -2 # write parameters are invalid for unbuffered I/O
---| -1 # file could not be opened (bad path, not exist, etc)
---|  0 # successfully completed
---|  1 # has been properly queued and awaiting for service
---|  2 # is being accessed
---|  3 # has been interrupted by caller
---|  4 # has not yet been queued

---@alias garrysmod.file.AsyncWriteCallback
---| fun( relative_path: string, mount: string, status: garrysmod.file.AsyncStatus )

---@alias garrysmod.file.AsyncReadCallback
---| fun( relative_path: string, mount: string, status: garrysmod.file.AsyncStatus, data: string? )

---@alias garrysmod.file.AccessType
---| "rb" # read-only, binary
---| "wb" # write-only, binary
---| "ab" # append-only, binary

---@alias garrysmod.file.SortingType
---| "nameasc" # sort by name, ascending
---| "namedesc" # sort by name, descending
---| "dateasc" # sort by modification time, ascending
---| "datedesc" # sort by modification time, descending


--- [SHARED AND MENU]
---
--- The file object returned by `file.Open`.
---
--- Remember to call `File:Close` when you are done with it.
---
---@class garrysmod.File
local File = {}

--- [SHARED AND MENU]
---
--- Dumps the file changes to disk and closes the file handle which makes the handle useless.
---
function File:Close() end

--- [SHARED AND MENU]
---
--- Returns whether the file object has reached the end of the file or not.
---
---@return boolean is_eof `true` if the end of the file was reached.
function File:EndOfFile() end

--- [SHARED AND MENU]
---
--- Dumps the file changes to disk without closing the handle.
---
function File:Flush() end

--- [SHARED AND MENU]
---
--- Reads the specified amount of chars (bytes) and returns them as a binary string.
---
---@param length integer? The number of bytes to read. If omitted, reads the whole file.
---@return string data The data that was read.
function File:Read( length ) end

--- [SHARED AND MENU]
---
--- Reads one byte of the file and returns whether it was not `0`.
---
---@return boolean value
function File:ReadBool() end

--- [SHARED AND MENU]
---
--- Reads one unsigned 8-bit integer from the file.
---
---@return integer value
function File:ReadByte() end

--- [SHARED AND MENU]
---
--- Reads an 8 byte (double precision) floating point number from the file.
---
---@return number value
function File:ReadDouble() end

--- [SHARED AND MENU]
---
--- Reads a 4 byte (single precision) floating point number from the file.
---
---@return number value
function File:ReadFloat() end

--- [SHARED AND MENU]
---
--- Reads until the next line break and returns the line without the line break.
---
---@return string line
function File:ReadLine() end

--- [SHARED AND MENU]
---
--- Reads a signed 32-bit integer from the file.
---
---@return integer value
function File:ReadLong() end

--- [SHARED AND MENU]
---
--- Reads a signed 16-bit integer from the file.
---
---@return integer value
function File:ReadShort() end

--- [SHARED AND MENU]
---
--- Reads an unsigned 64-bit integer from the file, returned as a string.
---
---@return string value
function File:ReadUInt64() end

--- [SHARED AND MENU]
---
--- Reads an unsigned 32-bit integer from the file.
---
---@return integer value
function File:ReadULong() end

--- [SHARED AND MENU]
---
--- Reads an unsigned 16-bit integer from the file.
---
---@return integer value
function File:ReadUShort() end

--- [SHARED AND MENU]
---
--- Sets the file pointer to the specified position (in bytes).
---
---@param position integer The position of the file pointer, in bytes.
function File:Seek( position ) end

--- [SHARED AND MENU]
---
--- Returns the size of the file in bytes.
---
---@return integer size
function File:Size() end

--- [SHARED AND MENU]
---
--- Moves the file pointer by the specified amount of bytes.
---
---@param amount integer The number of bytes to skip, may be negative.
---@return integer skipped The number of bytes actually skipped.
function File:Skip( amount ) end

--- [SHARED AND MENU]
---
--- Returns the current position of the file pointer, in bytes.
---
---@return integer position
function File:Tell() end

--- [SHARED AND MENU]
---
--- Writes the given string to the file.
---
---@param data string The binary data to write.
function File:Write( data ) end

--- [SHARED AND MENU]
---
--- Writes a boolean as one byte to the file.
---
---@param value boolean
function File:WriteBool( value ) end

--- [SHARED AND MENU]
---
--- Writes an unsigned 8-bit integer to the file.
---
---@param value integer
function File:WriteByte( value ) end

--- [SHARED AND MENU]
---
--- Writes an 8 byte (double precision) floating point number to the file.
---
---@param value number
function File:WriteDouble( value ) end

--- [SHARED AND MENU]
---
--- Writes a 4 byte (single precision) floating point number to the file.
---
---@param value number
function File:WriteFloat( value ) end

--- [SHARED AND MENU]
---
--- Writes a signed 32-bit integer to the file.
---
---@param value integer
function File:WriteLong( value ) end

--- [SHARED AND MENU]
---
--- Writes a signed 16-bit integer to the file.
---
---@param value integer
function File:WriteShort( value ) end

--- [SHARED AND MENU]
---
--- Writes an unsigned 64-bit integer (given as a string) to the file.
---
---@param value string
function File:WriteUInt64( value ) end

--- [SHARED AND MENU]
---
--- Writes an unsigned 32-bit integer to the file.
---
---@param value integer
function File:WriteULong( value ) end

--- [SHARED AND MENU]
---
--- Writes an unsigned 16-bit integer to the file.
---
---@param value integer
function File:WriteUShort( value ) end

--- [SHARED AND MENU]
---
--- The file library provides access to the game's virtual filesystem.
---
--- Writing is only possible inside the `DATA` mount, and relative paths
--- are resolved against the mount given in the `mount` argument
--- (`"GAME"`, `"DATA"`, `"LUA"`, `"MOD"`, `"WORKSHOP"`, etc.).
---
---@class garrysmod.file
file = {}

--- [SHARED AND MENU]
---
--- Attempts to asynchronously read a file, the callback is called when the operation completes.
---
---@param relative_path string The path to the file, relative to the mount.
---@param mount string The mount to read from, e.g. `"GAME"` or `"DATA"`.
---@param callback garrysmod.file.AsyncReadCallback The function called when the read completes.
---@param sync_read boolean? If `true`, the read is performed synchronously.
---@return garrysmod.file.AsyncStatus status The status of the request, `0` on success.
function file.AsyncRead( relative_path, mount, callback, sync_read ) end

--- [SHARED AND MENU]
---
--- Creates a directory (and missing parent directories) inside the `DATA` mount.
---
---@param relative_path string The directory path, relative to `data/`.
function file.CreateDir( relative_path ) end

--- [SHARED AND MENU]
---
--- Deletes a file or an empty directory.
---
---@param relative_path string The path to delete.
---@param mount string The mount to delete from, usually `"DATA"`.
---@return boolean success `true` if the file was deleted.
function file.Delete( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns whether a file or directory exists.
---
---@param relative_path string The path to check, relative to the mount.
---@param mount string The mount to check.
---@return boolean exists `true` if the file or directory exists.
function file.Exists( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns a list of files and directories matching the wildcard.
---
---@param wildcard string The wildcard to search for, e.g. `"lua/*.lua"`.
---@param mount string The mount to search in.
---@param sorting_mode garrysmod.file.SortingType The sorting mode of the results.
---@return string[] | nil files The matching file names.
---@return string[] | nil directories The matching directory names.
function file.Find( wildcard, mount, sorting_mode ) end

--- [SHARED AND MENU]
---
--- Returns whether the given path is a directory.
---
---@param relative_path string The path to check, relative to the mount.
---@param mount string The mount to check.
---@return boolean is_directory `true` if the path is a directory.
function file.IsDir( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Opens a file and returns a file object, or `nil` if it could not be opened.
---
---@param relative_path string The path to the file, relative to the mount.
---@param mode garrysmod.file.AccessType The access mode.
---@param mount string The mount to open the file in.
---@return garrysmod.File | nil handle The file object, or `nil` on failure.
function file.Open( relative_path, mode, mount ) end

--- [SHARED AND MENU]
---
--- Renames a file inside the `DATA` mount.
---
---@param relative_path string The current path.
---@param new_path string The new path.
---@return boolean success `true` if the file was renamed.
function file.Rename( relative_path, new_path ) end

--- [SHARED AND MENU]
---
--- Returns the size of a file in bytes, or `-1` if it does not exist.
---
---@param relative_path string The path to the file.
---@param mount string The mount of the file.
---@return -1 | integer size The size in bytes, `-1` if the file was not found.
function file.Size( relative_path, mount ) end

--- [SHARED AND MENU]
---
--- Returns the last modified time of a file as a Unix timestamp.
---
---@param relative_path string The path to the file.
---@param mount string The mount of the file.
---@return 0 | 1 | integer timestamp The Unix timestamp, `0` or `1` if the file was not found.
function file.Time( relative_path, mount ) end
