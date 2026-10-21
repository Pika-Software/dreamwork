---@meta holylib

--- [SHARED AND MENU]
---
--- This library is exposed by the holylib module and provides a few different more generic functions.
---
---@class holylib
HolyLib = {}

--- [SHARED AND MENU]
---
--- Returns the Lua registry -> debug.getregistry() before it was nuked.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-debug.getregistry)
---
---@return table registry
---@nodiscard
function HolyLib.GetRegistry() end
