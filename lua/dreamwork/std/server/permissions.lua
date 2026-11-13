local dreamwork_engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

---@class dreamwork.std.server
local server = std.server

---@type garrysmod.permissions
local glua_permissions = dreamwork_engine.requireLibrary( "permissions" )


--- [CLIENT AND MENU]
---
--- The permissions the player has granted to the current server.
---
---@class dreamwork.std.server.permissions
local permissions = {}
server.permissions = permissions

--- [CLIENT AND MENU]
---
--- Grants a permission to the current server.
---
---@type fun( permission: string, temporary: boolean )
permissions.grant = glua_permissions.Grant or debug_fempty

--- [CLIENT AND MENU]
---
--- Revokes a permission from the current server.
---
---@type fun( permission: string, address: string )
permissions.revoke = glua_permissions.Revoke or debug_fempty

--- [CLIENT AND MENU]
---
--- Checks if a permission is granted to the current server.
---
---@type fun( permission: string ): boolean
permissions.isGranted = glua_permissions.IsGranted or function() return false end

--- [CLIENT AND MENU]
---
--- Returns all known permissions.
---
---@type fun(): table<string, table>
permissions.getAll = glua_permissions.GetAll or function() return {} end
