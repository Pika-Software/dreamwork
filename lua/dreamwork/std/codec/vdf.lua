---@class dreamwork.GModUtilLibrary
---@field TableToKeyValues fun( tbl: table, rootKey: string? ): string
---@field KeyValuesToTable fun( keyValues: string, usesEscapeSequences: boolean?, preserveKeyCase: boolean? ): table
---@field KeyValuesToTablePreserveOrder fun( keyValues: string, usesEscapeSequences: boolean?, preserveKeyCase: boolean? ): table
---@diagnostic disable-next-line: undefined-global
local glua_util = util

---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---
---@class dreamwork.std.vdf
local vdf = {}
std.vdf = vdf

-- TODO: fallback to custom implementation

vdf.serialize = glua_util.TableToKeyValues
vdf.deserialize = glua_util.KeyValuesToTablePreserveOrder
