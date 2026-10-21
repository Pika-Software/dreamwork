---@meta holylib.cvar


--- [SHARED AND MENU]
---
--- This library adds a few ConVar related functions.
---
---@class holylib.cvar
cvar = {}

--- [SHARED AND MENU]
---
--- Searches for any given convar name without restrictions.
---
---@param name string
---@return garrysmod.console.Variable
function cvar.Find( name ) end

--- [SHARED AND MENU]
---
--- Returns a table containing all registered ConVars.
---
---@return garrysmod.console.Variable[] list A sequential table containing all convars.
function cvar.GetAll() end

--- [SHARED AND MENU]
---
--- Sets the value of the given ConVar even if it's blocked behind cheats.
---
---@param name string
---@param value string
---@return boolean success `true` if the value was successfully set.
function cvar.SetValue( name, value ) end

--- [SHARED AND MENU]
---
--- Unregisters the given convar / concommand.
---
---@param name string
function cvar.Unregister( name ) end
