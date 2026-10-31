---@meta gm_async_write


--- [SHARED AND MENU]
---
--- Callback of `file.AsyncWrite` and `file.AsyncAppend`.
---
---@alias gm_async_write.Callback fun( path: string, status: garrysmod.file.AsyncStatus )

--- [SHARED AND MENU]
---
--- Adds `file.AsyncWrite` to the `file` library, from the [gm_async_write](https://github.com/WilliamVenner/gm_async_write) binary module.
---
--- Available after `require( "async_write" )`. Modeled on `file.AsyncRead`, but may not be 1:1 with a future native implementation.
---
--- ```lua
--- file.AsyncWrite( "hello.txt", "Hello", function( path, status )
---     print( path, status == FSASYNC_OK )
--- end )
--- ```
---
---@param path string The path to the file, relative to `DATA`.
---@param data string The data to write, replacing the file contents.
---@param callback gm_async_write.Callback Called when the write completes; `status` is `FSASYNC_OK`, `FSASYNC_ERR_FILEOPEN` or `FSASYNC_ERR_FAILURE`.
---@return garrysmod.file.AsyncStatus status The status of the queued write.
function file.AsyncWrite( path, data, callback ) end

--- [SHARED AND MENU]
---
--- Adds `file.AsyncAppend` to the `file` library. Same as `file.AsyncWrite`, but appends to the file.
---
---@param path string The path to the file, relative to `DATA`.
---@param data string The data to append.
---@param callback gm_async_write.Callback Called when the append completes.
---@return garrysmod.file.AsyncStatus status The status of the queued append.
function file.AsyncAppend( path, data, callback ) end
