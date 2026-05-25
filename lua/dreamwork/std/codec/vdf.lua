local glua_util = util

---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---
---@class dreamwork.std.vdf
local vdf = std.vdf or {}
std.vdf = vdf

vdf.serialize = vdf.serialize or glua_util.TableToKeyValues
vdf.deserialize = vdf.deserialize or glua_util.KeyValuesToTable
