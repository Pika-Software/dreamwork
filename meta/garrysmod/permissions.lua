---@meta garrysmod.permissions


--- Permission names that can be granted to a server.
---
---@alias garrysmod.PermissionName
---| `"connect"`
---| `"voicerecord"`

--- Permanent and temporary permissions granted per server IP.
---
--- Permanent permissions are stored in `settings/permissions.bin`.
---
---@class garrysmod.ServerPermissions
---@field permanent table<string, garrysmod.PermissionName> Permanent permissions keyed by server IP.
---@field temporary table<string, garrysmod.PermissionName> Temporary permissions keyed by server IP, valid for the current game session.

--- [CLIENT AND MENU]
---
--- Used to ask player for various potentially dangerous permissions.
---
---@class garrysmod.permissions
permissions = {}

--- [CLIENT]
---
--- Requests the player to connect to a specified server. The player will be prompted with a confirmation window.
---
---@param address string The address to ask to connect to. If a port is not given, the default `:27015` port will be added.
function permissions.AskToConnect( address ) end

--- [MENU]
---
--- Connects player to the server. This is what `permissions.AskToConnect` uses internally.
---
---@param ip string IP address to connect.
function permissions.Connect( ip ) end

--- [CLIENT]
---
--- Activates player's microphone as if they pressed the speak button themself. The player will be prompted with a confirmation window which grants permission temporarily/permanently (depending on checkbox state) for the connected server (revokable).
---
--- This is used for TTT's traitor voice channel.
---
---@param enable boolean Enable or disable voice activity. `true` will run `+voicerecord` command, anything else `-voicerecord`.
function permissions.EnableVoiceChat( enable ) end

--- [MENU]
---
--- Returns all permissions per server. Permanent permissions are stored in `settings/permissions.bin`.
---
---@return garrysmod.ServerPermissions permissions A table of permanent and temporary permissions granted for servers.
function permissions.GetAll() end

--- [MENU]
---
--- Grants permission to the current connected server.
---
---@param permission garrysmod.PermissionName Permission to grant for the server the player is currently connected.
---@param temporary boolean `true` if the permission should be granted temporary.
function permissions.Grant( permission, temporary ) end

--- [CLIENT AND MENU]
---
--- Returns whether the player has granted the current server a specific permission.
---
---@param permission garrysmod.PermissionName The permission to poll. Currently only `"connect"` and `"voicerecord"` are valid.
---@return boolean is_granted Whether the permission is granted or not.
function permissions.IsGranted( permission ) end

--- [MENU]
---
--- Revokes permission from the server.
---
---@param permission garrysmod.PermissionName Permission to revoke from the server.
---@param ip string IP of the server.
function permissions.Revoke( permission, ip ) end
