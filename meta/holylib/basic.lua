---@meta holylib


---
--- Which HolyLib version this build is using.
---
---@type string
_HOLYLIB_VERSION = nil

---
--- Which workflow run this HolyLib build is from.
---
---@type integer
_HOLYLIB_RUN_NUMBER = nil

--- [SHARED AND MENU]
---
--- This library is exposed by the holylib module and provides a few different more generic functions.
---
---@class holylib
HolyLib = {}

--- [SHARED AND MENU]
---
--- Returns the Lua registry -> `debug.getregistry()` before it was nuked.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-debug.getregistry)
---
---@return table registry
---@nodiscard
function HolyLib.GetRegistry() end

--- [SHARED AND MENU]
---
--- Returns the found environment variable value **as string** or returns `nil`.
---
---@param key string
---@return string | nil value
function HolyLib.GetEnvironmentValue( key ) end

--- [SERVER]
---
--- Reconnects the given player without him losing his slot.
---
--- [View documents](https://holylib.raphaelit7.com/HolyLib.Reconnect)
---
---@param pl garrysmod.Player The player to reconnect.
---@return boolean success `true` if the client was successfully reconnected.
function HolyLib.Reconnect( pl ) end

--- [SERVER]
---
--- Disconnects the given player from the server.
---
--- Unlike Garry's Mod's version which internally calls the `kickid` command,
--- this directly calls the `Disconnect` function with no delay.
---
--- [View documents](https://holylib.raphaelit7.com/HolyLib.Disconnect)
---
---@param pl garrysmod.Player | integer The player to disconnect, or a user ID.
---@param reason string The reason to disconnect the client with.
---@param silent boolean? If `true`, silently closes the net channel and sends no disconnect to the client. Defaults to `false`.
---@param nogameevent boolean? If `true`, stops the `player_disconnect` game event from being created. Defaults to `false`.
---@return boolean success `true` if the client was successfully disconnected.
function HolyLib.Disconnect( pl, reason, silent, nogameevent ) end
