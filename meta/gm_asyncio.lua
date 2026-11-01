---@meta gm_asyncio


--- [SHARED AND MENU]
---
--- Callback of `asyncio.AsyncWrite` and `asyncio.AsyncAppend`.
---
--- `file_name` is the normalized path (lowercased, `./` and `../` resolved, backslashes replaced), not the one that was passed.
---
---@alias gm_asyncio.WriteCallback fun( file_name: string, game_path: "DATA", status: garrysmod.file.AsyncStatus )

--- [SHARED AND MENU]
---
--- Callback of `asyncio.AsyncRead`.
---
--- `file_name` is the normalized path, `game_path` is the resolved search path (`"LUA"` becomes `lsv`, `lcl` or `LuaMenu`),
--- `data` is an empty string if the read failed.
---
---@alias gm_asyncio.ReadCallback fun( file_name: string, game_path: string, status: garrysmod.file.AsyncStatus, data: string )

--- [SHARED AND MENU]
---
--- Asynchronous file I/O from the [gm_asyncio](https://github.com/Pika-Software/gm_asyncio) binary module.
---
--- Available after `require( "asyncio" )` (`gmsv_asyncio` / `gmcl_asyncio`). Unlike `file.AsyncRead`, it also works in the menu state, and it adds the missing asynchronous write and append.
---
--- Every path is lowercased, `./` and `../` segments are resolved and backslashes are replaced with slashes.
--- Paths with `:` or `"`, absolute paths and paths going past the root are rejected right away with `FSASYNC_ERR_FILEOPEN`,
--- the callback is **never called** for them.
---
--- Jobs go through the engine's asynchronous file system queue and complete in order.
--- Callbacks are called from the `__ASYNCIO_THINK` timer, errors in them are reported with `ErrorNoHaltWithStack` and do not stop other callbacks.
---
--- ```lua
--- local status = asyncio.AsyncWrite( "example.txt", "Hello World!", function( file_name, game_path, status )
---     asyncio.AsyncRead( file_name, game_path, function( file_name, game_path, status, data )
---         print( status == FSASYNC_OK, data )
---     end )
--- end )
---
--- if status ~= FSASYNC_OK then
---     print( "rejected, the callback will not be called" )
--- end
--- ```
---
---@class gm_asyncio
asyncio = {}

--- [SHARED AND MENU]
---
--- Asynchronously writes `content` to a file in the `DATA` folder, overwriting it.
---
--- The extension must contain one of `txt`, `dat`, `json`, `xml`, `csv`, `jpg`, `jpeg`, `png`, `vtf`, `vmt`, `mp3`, `wav`, `ogg`, `vcd`, `dem`, `gma`, `mdl`, `phy`, `vvd`, `vtx` or `ani`.
---
--- Missing directories are not created, the callback gets `FSASYNC_ERR_FILEOPEN` then.
---
---@param file_name string The path to the file, relative to `DATA`.
---@param content string The data to write.
---@param callback? gm_asyncio.WriteCallback Called when the write completes. Without it, the write is fire-and-forget.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, `FSASYNC_ERR_FILEOPEN` if the path was rejected, otherwise an `FSASYNC_ERR_*` value from the engine.
function asyncio.AsyncWrite( file_name, content, callback ) end

--- [SHARED AND MENU]
---
--- Same as `asyncio.AsyncWrite`, but appends to the file instead of overwriting it, creating it if missing.
---
---@param file_name string The path to the file, relative to `DATA`.
---@param content string The data to append.
---@param callback? gm_asyncio.WriteCallback Called when the append completes. Without it, the append is fire-and-forget.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, `FSASYNC_ERR_FILEOPEN` if the path was rejected, otherwise an `FSASYNC_ERR_*` value from the engine.
function asyncio.AsyncAppend( file_name, content, callback ) end

--- [SHARED AND MENU]
---
--- Asynchronously reads a file from the given search path.
---
--- A missing file is not rejected right away, the callback gets `FSASYNC_ERR_FILEOPEN` and an empty string.
---
---@param file_name string The path to the file.
---@param game_path string The search path, e.g. `"GAME"`, `"DATA"` or `"LUA"`.
---@param callback? gm_asyncio.ReadCallback Called when the read completes.
---@return garrysmod.file.AsyncStatus status `FSASYNC_OK` if queued, `FSASYNC_ERR_FILEOPEN` if the path was rejected, otherwise an `FSASYNC_ERR_*` value from the engine.
function asyncio.AsyncRead( file_name, game_path, callback ) end
