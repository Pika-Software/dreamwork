local _G = _G

---@class dreamwork.std
local std = dreamwork.std

---@alias Gamemode dreamwork.std.Gamemode
---@class dreamwork.std.Gamemode : dreamwork.std.Object
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

dreamwork.engine.hookCatch( "dreamwork.GamemodeLoaded", function()
    -- -- https://github.com/Facepunch/garrysmod-requests/issues/2793
    -- local sv_defaultdeployspeed = console_Variable.get( "sv_defaultdeployspeed", "number" )
    -- if sv_defaultdeployspeed ~= nil and sv_defaultdeployspeed.value == 4 then
    --     sv_defaultdeployspeed.value = 1
    -- end

    -- -- draw everything manually, don't use this crap
    -- local mp_show_voice_icons = console_Variable.get( "mp_show_voice_icons", "boolean" )
    -- if mp_show_voice_icons ~= nil and mp_show_voice_icons.value then
    --     mp_show_voice_icons.value = false
    -- end
end )
