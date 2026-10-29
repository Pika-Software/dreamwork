---@meta garrysmod.cvars


--- [SHARED AND MENU]
---
--- The cvars library allows you to control what happens when a cvar (console variable) is changed.
---
---@class garrysmod.cvars
cvars = {}

--- [SHARED AND MENU]
---
--- Called by the engine when a convar value changes.
---
---@param name string
---@param old_value string
---@param new_value string
function cvars.OnConVarChanged( name, old_value, new_value ) end
