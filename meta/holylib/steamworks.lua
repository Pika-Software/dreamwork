---@meta holylib.steamworks


---@class garrysmod.steamworks
steamworks = {}

--- [SERVER]
---
--- Starts / activates the Steam game server (`CSteam3Server::Activate`).
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.Activate)
---
---@return boolean success Always `true` if the call completed (throws if the engine symbols are missing).
function steamworks.Activate() end

--- [SERVER]
---
--- Activates the Steam game server the same way the engine does, via `SV_InitGameServerSteam`.
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.ForceActivate)
---
---@return boolean success Always `true` if the call completed (throws if the engine symbol is missing).
function steamworks.ForceActivate() end

--- [SERVER]
---
--- Marks the given client as fully authenticated even if Steam has not authenticated them.
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.ForceAuthenticate)
---
---@param user_id integer The client's user ID.
---@return boolean success `true` if the client was found and marked authenticated.
function steamworks.ForceAuthenticate( user_id ) end

--- [SERVER]
---
--- Returns the SteamID64 of the game server.
---
--- Throws if the Steam game server has not been created yet.
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.GetGameServerSteamID)
---
---@return string steam_id64 The game server's SteamID64.
---@nodiscard
function steamworks.GetGameServerSteamID() end

--- [SERVER]
---
--- Returns whether the Steam game server is connected / logged on.
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.IsConnected)
---
---@return boolean connected `true` if `SteamGameServer` exists and is logged on.
---@nodiscard
function steamworks.IsConnected() end

--- [SERVER]
---
--- Returns whether the Steam game server is VAC secure.
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.IsSecure)
---
---@return boolean secure `true` if `SteamGameServer` exists and reports VAC secure.
---@nodiscard
function steamworks.IsSecure() end

--- [SERVER]
---
--- Shuts down the Steam game server (`CSteam3Server::Shutdown`).
---
--- [View documents](https://holylib.raphaelit7.com/steamworks.Shutdown)
---
---@return boolean success Always `true` if the call completed (throws if the engine symbols are missing).
function steamworks.Shutdown() end
