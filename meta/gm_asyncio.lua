---@meta gm_asyncio


--- [SHARED AND MENU]
---
--- Callback of `asyncio.AsyncWrite` and `asyncio.AsyncAppend`.
---
---@alias gm_asyncio.WriteCallback fun( file_name: string, game_path: "DATA", status: garrysmod.file.AsyncStatus )

--- [SHARED AND MENU]
---
--- Callback of `asyncio.AsyncRead`.
---
---@alias gm_asyncio.ReadCallback fun( file_name: string, game_path: string, status: garrysmod.file.AsyncStatus, data: string )

--- [SHARED AND MENU]
---
--- Asynchronous file I/O from the [gm_asyncio](https://github.com/Pika-Software/gm_asyncio) binary module.
---
--- Available after `require( "asyncio" )` (`gmsv_asyncio` / `gmcl_asyncio`). Unlike `file.AsyncRead`, it also works in the menu state, and it adds the missing asynchronous write and append.
---
--- Has the same limitations as `file.Write` and `file.Read`. The returned status only tells whether the operation was queued; the real result is the `status` given to the callback.
---
--- ```lua
--- asyncio.AsyncWrite( "example.txt", "Hello World!", function( file_name, game_path, status )
---     asyncio.AsyncRead( file_name, game_path, function( file_name, game_path, status, data )
---         print( status == FSASYNC_OK, data )
---     end )
--- end )
--- ```
---
---@class gm_asyncio
asyncio = {}

--- [SHARED AND MENU]
---
--- Asynchronously writes `content` to a file in the `DATA` folder, overwriting it.
---
---@param file_name string The path to the file, relative to `DATA`.
---@param content string The data to write.
---@param callback gm_asyncio.WriteCallback Called when the write completes.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, otherwise an `FSASYNC_ERR_*` value.
function asyncio.AsyncWrite( file_name, content, callback ) end

--- [SHARED AND MENU]
---
--- Same as `asyncio.AsyncWrite`, but appends to the file instead of overwriting it.
---
---@param file_name string The path to the file, relative to `DATA`.
---@param content string The data to append.
---@param callback gm_asyncio.WriteCallback Called when the append completes.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, otherwise an `FSASYNC_ERR_*` value.
function asyncio.AsyncAppend( file_name, content, callback ) end

--- [SHARED AND MENU]
---
--- Asynchronously reads a file from the given search path.
---
---@param file_name string The path to the file.
---@param game_path string The search path, e.g. `"GAME"` or `"DATA"`.
---@param callback gm_asyncio.ReadCallback Called when the read completes.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, otherwise an `FSASYNC_ERR_*` value.
function asyncio.AsyncRead( file_name, game_path, callback ) end
