---@meta _

---@class dreamwork.GModEngineLib
---@field ActiveGamemode fun(): string
---@field ServerFrameTime fun(): number
---@field GetIPAddress fun(): string
local glua_engine = {}

---@class dreamwork.GModGameLib
---@field SinglePlayer fun(): boolean
---@field IsDedicated fun(): boolean
---@field GetTimeScale fun(): number
---@field SetTimeScale fun(scale: number)
local glua_game = {}

--- [SHARED AND MENU]
---
--- The game's server library.
---
---@class server
---@field singleplayer boolean `true` if server is running in singleplayer mode, `false` otherwise. **READ-ONLY**
---@field dedicated boolean `true` if server is running as a dedicated server, `false` otherwise. **READ-ONLY**
---@field tickrate number The tickrate of the server in seconds. **READ-ONLY**
server = {}

--- [SHARED AND MENU]
---
--- Gets the name of the active gamemode.
---
---@return string name The name of the active gamemode.
---@nodiscard
function server.getGamemodeName() end

---@class dreamwork.GModGModLib
---@field GetGamemode fun(): table
local glua_gmod = {}

---@class dreamwork.GModGamemodeLib
---@field Get fun(name: string): table
local glua_gamemode = {}

--- [SHARED]
---
--- Returns the active gamemode object.
---
---@return boolean is_legacy `true` if the gamemode is a legacy gamemode, `false` otherwise.
---@return table | Gamemode gamemode The active gamemode object.
---@nodiscard
function server.getGamemode() end

--- [SHARED]
---
--- Sets the active gamemode object.
---
---@param gm Gamemode The new active gamemode object.
function server.setGamemode(gm) end

--- [SHARED AND MENU]
---
--- Returns the title of the gamemode in the server browser.
---
---@return string title The title of the gamemode.
---@nodiscard
function server.getGamemodeTitle() end

---@type fun(): number
server.getUptime = nil

--- [CLIENT]
---
--- Called once every processed server frame during lag.
---
server.Tick = nil

---@class dreamwork.GModPermissionsLib
---@field Grant fun()
---@field Revoke fun()
---@field IsGranted fun()
---@field GetAll fun()
local glua_permissions = {}

--- [MENU]
---
--- Called when the server details are received from the server.
---
server.Details = nil

--- [SHARED AND MENU]
---
--- Returns the IP of the server.
---
---@return string ip The IP of the server.
---@nodiscard
function server.getIP() end

--- [SHARED AND MENU]
---
--- Returns the port of the server.
---
---@return string port The port of the server.
---@nodiscard
function server.getPort() end

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

--- [SERVER]
---
--- Gets the time scale of the game.
---
---@return number timescale The current time scale of the game.
---@nodiscard
function server.getTimeScale() end

--- [SHARED]
---
--- Checks if cheats are enabled.
---
---@return boolean enabled `true` if cheats are enabled, `false` if not.
---@nodiscard
function server.isCheatsEnabled() end

--- [SHARED]
---
--- Enables or disables cheats.
---
--- It gives all players access to commmands that would normally be abused or misused by players.
---
---@param bool boolean `true` to enable cheats, `false` to disable them.
function server.setCheatsEnabled(bool) end

--- [SHARED]
---
--- Checks if the server allows clients to run `lua_openscript_cl` and `lua_run_cl`.
---
---@return boolean allowed `true` if the server allows clients to run lua_openscript_cl and lua_run_cl, `false` if not.
---@nodiscard
function server.isUserScriptsAllowed() end

--- [SERVER]
---
--- Shutdown the engine immediately.
---
function server.kill() end

--- [SERVER]
---
--- Sends a message to all players on the server.
---
--- This message will be displayed in the console, chat or HUD.
---
---@param message string The message to print.
---@param in_chat? boolean `true` to print the message in chat, `false` to print it in the console only.
---@param in_hud? boolean `true` to print the message in the HUD (center of the screen), `false` to not print it.
function server.message(message, in_chat, in_hud) end

---@type fun( message: string )
server.log = nil

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
---@return boolean allowed Whether the server allows downloads.
---@nodiscard
function server.isDowloadAllowed() end

--- [SERVER]
---
--- Allow clients to download files from the server.
---
---@param allowed boolean Whether the server allows downloads.
function server.allowDownload(allowed) end

--- [SERVER]
---
--- Checks if the server allows uploads.
---
---@return boolean allowed Whether the server allows uploads.
---@nodiscard
function server.isUploadAllowed() end

--- [SERVER]
---
--- Allow clients to upload customizations files to the server.
---
---@param allow boolean Whether the server allows uploads.
function server.allowUpload(allow) end

---@alias SERVER_REGION
---| number # The region of the world to report this server in.
---| `0`	US - East
---| `1`	US - West
---| `2`	South America
---| `3`	Europe
---| `4`	Asia
---| `5`	Australia
---| `6`	Middle East
---| `7`	Africa
---| `255`	World (default)

--- [SERVER]
---
--- Gets the console_Variable requested by the server browser to determine in which part of the world the server is located.
---
---@return SERVER_REGION region_id The region of the world to report this server in.
---@nodiscard
function server.getRegion() end

--- [SERVER]
---
--- Sets the console_Variable requested by the server browser to determine in which part of the world the server is located.
---
---@param region_id SERVER_REGION The region of the world to report this server in.
function server.setRegion(region_id) end

--- [SERVER]
---
--- Checks if the server is hidden from the master server.
---@return boolean hidden `true` if the server is hidden, `false` if not.
---@nodiscard
function server.isHidden() end

--- [SERVER]
---
--- Hides/unhides the server from the master server.
---
---@param hide boolean `true` to hide the server, `false` to unhide it.
function server.setHidden(hide) end

--- [SERVER]
---
--- Allow clients to run `lua_openscript_cl` and `lua_run_cl`.
---
---@param allow boolean `true` to allow clients to run lua_openscript_cl and lua_run_cl, `false` to disallow them.
function server.allowUserScripts(allow) end

--- [SERVER]
---
--- Returns whether or not close captions are allowed in multiplayer.
---
---@return boolean result `true` if close captions are allowed, `false` otherwise.
---@nodiscard
function server.isCloseCaptionsAllowed() end

--- [SERVER]
---
--- Allow/disallow closecaptions in multiplayer (for dedicated servers).
---
---@param enable boolean `true` to enable close captions, `false` to disable them.
function server.allowCloseCaptions(enable) end

--- [SERVER]
---
--- Sets the title of the gamemode in the server browser.
---
---@param str string The title to set.
function server.setGamemodeTitile(str) end

---@class dreamwork.GModServerListLib
---@field PingServer fun( ip: string, callback: fun( server_ping: number, server_name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, server_address: string, gamemode_name: string, gamemode_workshopid: number, is_anonymous_server: boolean, gmod_version: string, server_localization: string, gamemode_category: string ) )
---@field PlayerList fun( ip: string, callback: fun( players: { time: number, name: string, score: string }[] ) )
---@field AddCurrentServerToFavorites fun()
---@field IsCurrentServerFavorite fun(): boolean
---@field AddServerToFavorites fun( ip: string )
---@field RemoveServerFromFavorites fun( ip: string )
---@field IsServerFavorite fun( ip: string ): boolean
---@field Query fun( data: { GameDir: string, Type: string, AppID: integer, Callback: fun( server_ping: number, server_name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, server_address: string, gamemode_name: string, gamemode_workshopid: number, is_anonymous_server: boolean, gmod_version: string, server_localization: string, gamemode_category: string ), CallbackFailed: fun( reason: string ), Finished: fun() } )
local glua_serverlist = {}

--- [MENU]
---
--- Queries a server for its information/ping.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout number? The timeout in seconds. Set to `false` to disable the timeout.
---@return server.Info info The server information.
---@nodiscard
---@async
function server.ping(address, timeout) end

--- [MENU]
---
--- Queries a server for it's player list.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout number? The timeout in seconds. Set to `false` to disable the timeout.
---@async
function server.getPlayers(address, timeout) end

--- [MENU]
---
--- Queries the master server for server list.
---
---@param data server.QueryData The query data to send to the master server.
function server.getAll(data) end

---@type fun( ip: string ): boolean
server.isInBlacklist = nil

--- [MENU]
---
--- Returns true if the given server address is in their favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
---@return boolean is_favorite `true` if the given server is in player favorites, `false` if not.
---@nodiscard
function server.isInFavorites(address) end

--- [MENU]
---
--- Adds the given server address to their favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
function server.addToFavorites(address) end

--- [MENU]
---
--- Removes the given server address from their favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
function server.removeFromFavorites(address) end
