---@meta _

--- [SHARED AND MENU]
---
--- The game's server library.
---
---@class server
---@field singleplayer boolean `true` if server is running in singleplayer mode, `false` otherwise. **READ-ONLY**
---@field dedicated boolean `true` if server is running as a dedicated server, `false` otherwise. **READ-ONLY**
---@field tickrate number The configured number of server ticks per second, see `TPS` for the measured one. **READ-ONLY**
---@field slots integer The maximum number of players the server can hold. **READ-ONLY**
---@field gamemode string The name of the active gamemode, `"base"` if unknown. **READ-ONLY**
---@field ipv4 integer The public IPv4 address of the server as an unsigned 32-bit integer, `0x7F000001` ( 127.0.0.1 ) for local servers. **READ-ONLY**
---@field port integer The public UDP port of the server, `27015` by default. **READ-ONLY**
---@field address string The public address of the server in the `ip:port` format. **READ-ONLY**
server = {}

--- [SHARED AND MENU]
---
--- Returns the current server time, it is predicted on the client.
---
--- Falls back to `dreamwork.getUpTime` when `CurTime` is not available.
---
---@return number time The server time in seconds.
---@nodiscard
function server.getTime() end

--- [SHARED AND MENU]
---
--- Gets the name of the server.
---
---@return string hostname The name of the server.
---@nodiscard
function server.getName() end

--- [SERVER]
---
--- Sets the name of the server.
---
---@param name string The name to set.
function server.setName(name) end

--- [SHARED]
---
--- Checks if cheats are enabled.
---
---@return boolean enabled `true` if cheats are enabled, `false` if not.
---@nodiscard
function server.isCheatsEnabled() end

--- [SHARED]
---
--- Checks if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`.
---
---@return boolean allowed `true` if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`, `false` if not.
---@nodiscard
function server.isUserScriptsAllowed() end

--- [SERVER]
---
--- Shuts down the server immediately.
---
function server.kill() end

--- [SERVER]
---
--- Sends a message to all players on the server.
---
--- This message will be displayed in the console, chat or HUD.
---
---@param message string The message to print.
---@param in_chat boolean? `true` to print the message in chat ( and console ), `false` to print it in the console only.
---@param in_hud boolean? `true` to print the message in the HUD (center of the screen), `false` to not print it.
function server.message(message, in_chat, in_hud) end

--- [SERVER]
---
--- Enables or disables cheats.
---
--- It gives all players access to commands that would normally be abused or misused by players.
---
---@param enabled boolean `true` to enable cheats, `false` to disable them.
function server.setCheatsEnabled(enabled) end

--- [SERVER]
---
--- Allows or disallows clients to run `lua_openscript_cl` and `lua_run_cl`.
---
---@param allowed boolean `true` to allow clients to run `lua_openscript_cl` and `lua_run_cl`, `false` to disallow them.
function server.setUserScriptsAllowed(allowed) end

--- [SERVER]
---
--- Gets the download URL of the server.
---
---@return string url The download URL.
---@nodiscard
function server.getDownloadURL() end

--- [SERVER]
---
--- Sets the download URL of the server.
---
---@param url string The download URL to set.
function server.setDownloadURL(url) end

--- [SERVER]
---
--- Checks if the server allows downloads.
---
---@return boolean allowed `true` if clients can download files from the server, `false` if not.
---@nodiscard
function server.isDownloadAllowed() end

--- [SERVER]
---
--- Allows or disallows clients to download files from the server.
---
---@param allowed boolean `true` to allow downloads, `false` to disallow them.
function server.setDownloadAllowed(allowed) end

--- [SERVER]
---
--- Checks if the server allows uploads.
---
---@return boolean allowed `true` if clients can upload customization files ( sprays ) to the server, `false` if not.
---@nodiscard
function server.isUploadAllowed() end

--- [SERVER]
---
--- Allows or disallows clients to upload customization files to the server.
---
---@param allowed boolean `true` to allow uploads, `false` to disallow them.
function server.setUploadAllowed(allowed) end

--- [SERVER]
---
--- Checks if close captions are allowed in multiplayer.
---
---@return boolean allowed `true` if close captions are allowed, `false` otherwise.
---@nodiscard
function server.isCloseCaptionsAllowed() end

--- [SERVER]
---
--- Allows or disallows close captions in multiplayer (for dedicated servers).
---
---@param allowed boolean `true` to allow close captions, `false` to disallow them.
function server.setCloseCaptionsAllowed(allowed) end

--- [SERVER]
---
--- Checks if the server is hidden from the master server.
---
---@return boolean hidden `true` if the server is hidden, `false` if not.
---@nodiscard
function server.isHidden() end

--- [SERVER]
---
--- Hides/unhides the server from the master server.
---
---@param hidden boolean `true` to hide the server, `false` to unhide it.
function server.setHidden(hidden) end

--- [SERVER]
---
--- Gets the number of player slots shown in the server browser.
---
--- Values below `1` mean that the real `server.slots` count is shown.
---
---@return integer slots The number of visible slots.
---@nodiscard
function server.getVisibleSlots() end

--- [SERVER]
---
--- Sets the number of player slots shown in the server browser.
---
--- Does not limit how many players can join, use it to reserve slots ( e.g. for admins ).
---
---@param slots integer The number of visible slots, clamped between `1` and `server.slots`.
---@return integer slots The number of visible slots that was set.
function server.setVisibleSlots(slots) end

---@alias server.Region
---| "us-east"
---| "us-west"
---| "south-america"
---| "europe"
---| "asia"
---| "australia"
---| "middle-east"
---| "africa"
---| "world"

--- [SERVER]
---
--- Gets the region the server browser reports this server in.
---
---@return server.Region region The region of the world, `"world"` by default.
---@nodiscard
function server.getRegion() end

--- [SERVER]
---
--- Sets the region the server browser reports this server in.
---
---@param region server.Region The region of the world, unknown regions are reported as `"world"`.
function server.setRegion(region) end

--- [CLIENT]
---
--- Returns an estimate of the server's performance, equivalent to calling `FrameTime` on the server.
---
---@return number frame_time The server frame time in seconds.
---@return number deviation The standard deviation of the server frame time.
---@nodiscard
function server.getFrameTime() end

--- [MENU]
---
--- Called when the server details are received while connecting to a server.
---
--- Arguments: `details: table` with `server_name: string`, `loading_url: string`, `map_name: string`, `max_players: integer`, `player_steamid64: string` and `gamemode_name: string` keys.
---
server.Details = nil
