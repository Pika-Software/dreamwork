---@meta _

---@class Gamemode : Object
---@field __class GamemodeClass
---@field name string
local __Gamemode = {}

---@protected
function __Gamemode:__init() end

---@class GamemodeClass : Gamemode
---@field __base Gamemode
---@overload fun(): Gamemode
Gamemode = {}
