---@meta _

--- [CLIENT AND MENU]
---
--- The permissions the player has granted to the current server.
---
---@class server.permissions
server.permissions = {}

--- [CLIENT AND MENU]
---
--- Grants a permission to the current server.
---
---@type fun( permission: string, temporary: boolean )
server.permissions.grant = nil

--- [CLIENT AND MENU]
---
--- Revokes a permission from the current server.
---
---@type fun( permission: string, address: string )
server.permissions.revoke = nil

--- [CLIENT AND MENU]
---
--- Checks if a permission is granted to the current server.
---
---@type fun( permission: string ): boolean
server.permissions.isGranted = nil

--- [CLIENT AND MENU]
---
--- Returns all known permissions.
---
---@type fun(): table<string, table>
server.permissions.getAll = nil
