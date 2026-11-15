---@meta _

---@class garrysmod.serverlist
local glua_serverlist = {}

---@class server.Player
---@field name string The name of the player.
---@field score integer The score of the player.
---@field time number The time the player has been connected, in seconds.

--- [MENU]
---
--- The server browser library.
---
---@class server.browser
server.browser = {}

--- [MENU]
---
--- Starts a query of a server for its information/ping, without waiting for it.
---
--- Several requests can be awaited together with `futures.all`.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
---@return Future<server.Info> future The future of the server information.
function server.browser.requestPing(address, timeout) end

--- [MENU]
---
--- Queries a server for its information/ping.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
---@return server.Info info The server information.
---@async
function server.browser.ping(address, timeout) end

--- [MENU]
---
--- Starts a query of a server for its player list, without waiting for it.
---
--- Several requests can be awaited together with `futures.all`.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
---@return Future<server.Player[]> future The future of the player list.
function server.browser.requestPlayers(address, timeout) end

--- [MENU]
---
--- Queries a server for its player list.
---
---@param address string The address of the server. ( IP:Port like `127.0.0.1:27015` )
---@param timeout ( number | false )? The timeout in seconds, default is `30`, `false` to disable the timeout.
---@return server.Player[] players The players on the server.
---@async
function server.browser.getPlayers(address, timeout) end

--- [MENU]
---
--- Queries the master server for the server list.
---
---@param data server.QueryData The query data to send to the master server.
function server.browser.query(data) end

--- [MENU]
---
--- Checks if the server address is blacklisted by Garry's Mod.
---
---@type fun( address: string ): boolean
server.browser.isBlacklisted = nil

--- [MENU]
---
--- Checks if the given server address is in the player's favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
---@return boolean is_favorite `true` if the given server is in player favorites, `false` if not.
---@nodiscard
function server.browser.isFavorite(address) end

--- [MENU]
---
--- Adds the given server address to the player's favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
function server.browser.addFavorite(address) end

--- [MENU]
---
--- Removes the given server address from the player's favorites.
---
---@param address string? The address of the server, current server if `nil`. ( IP:Port like `127.0.0.1:27015` )
function server.browser.removeFavorite(address) end
