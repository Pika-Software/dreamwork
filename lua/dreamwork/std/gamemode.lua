local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

---@alias Gamemode dreamwork.std.Gamemode
---@class dreamwork.std.Gamemode : dreamwork.Object
---@field __class dreamwork.std.GamemodeClass
---@field name string
local Gamemode = std.class.base( "Gamemode" )

---@protected
function Gamemode:__init()

end

---@class dreamwork.std.GamemodeClass : dreamwork.std.Gamemode
---@field __base dreamwork.std.Gamemode
---@overload fun(): Gamemode
local GamemodeClass = std.class.create( Gamemode )
std.Gamemode = GamemodeClass

-- TODO: make gamemode class and gamemode handler
