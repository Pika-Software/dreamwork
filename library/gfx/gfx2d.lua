---@meta _

--- [CLIENT AND MENU]
---
---
---
---@class gfx2d
gfx2d = {}

--- [CLIENT]
---
---
---
function gfx2d.start() end

---@class UnitResolver : Object
local __UnitResolver = {}

function __UnitResolver:__init(unit_str) end

---@class UnitResolverClass : UnitResolver
UnitResolver = {}

function UnitResolver.resolve(unit_str) end

---@class Font : Object
local __Font = {}

---@class FontClass : Font
Font = {}
