---@meta gm_efsw


--- [SHARED AND MENU]
---
--- Action reported to `GM:FileWatchEvent`.
---
---@alias gm_efsw.Action
---| 1 # File was added.
---| 2 # File was deleted.
---| 3 # File was modified.

--- [SHARED AND MENU]
---
--- Error code returned by `efsw.Watch` on failure.
---
---@alias gm_efsw.Error
---| -1 # File not found.
---| -2 # File not readable.
---| -3 # File out of scope.
---| -4 # File is remote.
---| -5 # File is already watched.
---| -6 # Unspecified error.

--- [SHARED AND MENU]
---
--- File system watcher from the [gm_efsw](https://github.com/Pika-Software/gm_efsw) binary module, based on [efsw](https://github.com/SpartanJ/efsw).
---
--- Available after `require( "efsw" )`. Changes are reported through the `GM:FileWatchEvent` hook.
---
--- ```lua
--- local watch_id = efsw.Watch( "lua/autorun/test.lua", "GAME" )
--- hook.Add( "FileWatchEvent", "example", function( action, id, file_name )
---     if id == watch_id and action == efsw.ACTION_MODIFIED then print( file_name ) end
--- end )
--- ```
---
---@class gm_efsw
---@field ACTION_ADD 1 File was added.
---@field ACTION_DELETE 2 File was deleted.
---@field ACTION_MODIFIED 3 File was modified.
---@field ERROR_FILE_NOT_FOUND -1 File not found.
---@field ERROR_FILE_NOT_READABLE -2 File not readable.
---@field ERROR_FILE_OUT_OF_SCOPE -3 File out of scope.
---@field ERROR_FILE_REMOTE -4 File is remote.
---@field ERROR_FILE_REPEATED -5 File is already watched.
---@field ERROR_UNSPECIFIED -6 Unspecified error.
efsw = {}

--- [SHARED AND MENU]
---
--- Starts watching a file or directory.
---
---@param file_name string The path to watch.
---@param game_path string The search path, e.g. `"GAME"` or `"DATA"`.
---@return integer watch_id The watch ID, or a negative `efsw.ERROR_*` value on failure.
function efsw.Watch( file_name, game_path ) end

--- [SHARED AND MENU]
---
--- Stops watching the file associated with the given ID.
---
---@param watch_id integer The ID returned by `efsw.Watch`.
function efsw.Unwatch( watch_id ) end
