---@meta garrysmod.serverlist


---@alias garrysmod.serverlist.QueryType
---| "internet"
---| "favorite"
---| "history"
---| "lan"


--- [MENU]
---
--- A player entry returned by `serverlist.PlayerList`.
---
---@class garrysmod.serverlist.Player
---@field name string The player name.
---@field score number The player's score.
---@field time number How long the player has been on the server, in seconds.


--- [MENU]
---
--- Callback used by `serverlist.Query` and `serverlist.PingServer` when a server responds.
---
--- Arguments match [ServerQueryData.Callback](https://wiki.facepunch.com/gmod/Structures/ServerQueryData).
--- Return `false` from a `serverlist.Query` callback to stop the query.
---
---@alias garrysmod.serverlist.ServerCallback fun( ping: number, name: string, desc: string, map: string, players: number, maxplayers: number, botplayers: number, pass: boolean, lastplayed: number, address: string, gamemode: string, workshopid: number, isanon: boolean, version: string, localization: string, gmcategory: string ): boolean?


--- [MENU]
---
--- Query options for `serverlist.Query`. See [ServerQueryData](https://wiki.facepunch.com/gmod/Structures/ServerQueryData).
---
---@class garrysmod.serverlist.QueryData
---@field GameDir string? The game directory to get the servers for. Default is `"garrysmod"`.
---@field Type garrysmod.serverlist.QueryType? Type of servers to retrieve: `"internet"`, `"favorite"`, `"history"` or `"lan"`.
---@field AppID number? Steam application ID to get the servers for. Default is `4000`.
---@field Callback garrysmod.serverlist.ServerCallback? Called when a new server is found and queried. Return `false` to stop the query.
---@field CallbackFailed fun( address: string )? Called if querying a server failed, with that server's IP address.
---@field Finished fun()? Called when the query is finished.


--- [MENU]
---
--- Menu-state library to query the master server list and individual game servers.
---
--- See [serverlist](https://wiki.facepunch.com/gmod/serverlist).
---
---@class garrysmod.serverlist
serverlist = {}

--- [MENU]
---
--- Adds or removes the current server the player is on from their favorites.
---
--- > **INTERNAL**: Used by the favorites UI; prefer `AddServerToFavorites` / `RemoveServerFromFavorites` with an address when possible.
---
---@param add_or_remove boolean `true` to add, `false` to remove.
function serverlist.AddCurrentServerToFavorites( add_or_remove ) end

--- [MENU]
---
--- Adds the given server address to the player's favorites.
---
---@param address string The server address, including the port, e.g. `"127.0.0.1:27015"`.
function serverlist.AddServerToFavorites( address ) end

--- [MENU]
---
--- Returns whether the current server address is in the player's favorites.
---
---@return boolean is_favorite `true` if the current server is favorited.
---@nodiscard
function serverlist.IsCurrentServerFavorite() end

--- [MENU]
---
--- Returns whether the given server address is in the player's favorites.
---
---@param address string The server address, including the port, e.g. `"127.0.0.1:27015"`.
---@return boolean is_favorite `true` if the address is favorited.
---@nodiscard
function serverlist.IsServerFavorite( address ) end

--- [MENU]
---
--- Queries a server for its information/ping.
---
--- The callback receives the same arguments as `serverlist.QueryData.Callback`
--- (see [ServerQueryData](https://wiki.facepunch.com/gmod/Structures/ServerQueryData)).
---
---@param ip string The IP address of the server, including the port.
---@param callback garrysmod.serverlist.ServerCallback The function called when the request finishes.
function serverlist.PingServer( ip, callback ) end

--- [MENU]
---
--- Queries a server for its player list.
---
---@param ip string The IP address of the server, including the port.
---@param callback fun( data: garrysmod.serverlist.Player[] | nil ) Called when the request finishes. `data` is the player list, or `nil` on failure.
function serverlist.PlayerList( ip, callback ) end

--- [MENU]
---
--- Queries the master server for a server list.
---
--- ```lua
--- serverlist.Query( {
---     Type = "internet",
---     GameDir = "garrysmod",
---     AppID = 4000,
---     Callback = function( ping, name, desc, map, players, maxplayers, botplayers, pass, lastplayed, address, gamemode, workshopid, isanon, version, localization, gmcategory )
---         print( name, address, ping )
---     end,
---     CallbackFailed = function( address )
---         print( "failed", address )
---     end,
---     Finished = function()
---         print( "done" )
---     end,
--- } )
--- ```
---
---@param data garrysmod.serverlist.QueryData What kind of servers to request.
function serverlist.Query( data ) end

--- [MENU]
---
--- Removes the given server address from the player's favorites.
---
---@param address string The server address, including the port, e.g. `"127.0.0.1:27015"`.
function serverlist.RemoveServerFromFavorites( address ) end
