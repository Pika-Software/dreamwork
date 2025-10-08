local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local glua_render = _G.render

--- [CLIENT AND MENU]
---
--- The game's render library.
---@class dreamwork.std.render
local render = std.render or {}
std.render = render

-- TODO: add render/draw/surface functions

if std.CLIENT then
    --- [CLIENT]
    ---
    --- Various fog rendering functions
    ---@class dreamwork.std.render.fog
    render.fog = render.fog or {}
    render.fog.getMode = render.fog.getMode or glua_render.GetFogMode
    render.fog.setMode = render.fog.setMode or glua_render.FogMode
    render.fog.getColor = render.fog.getColor or glua_render.GetFogColor
    render.fog.setColor = render.fog.setColor or glua_render.FogColor
    render.fog.getDistances = render.fog.getDistances or glua_render.GetFogDistances
    render.fog.setStartDistance = render.fog.setStartDistance or glua_render.FogStart
    render.fog.setEndDistance = render.fog.setEndDistance or glua_render.FogEnd
    render.fog.getMaxDensity = render.fog.getMaxDensity or glua_render.GetFogMaxDensity
    render.fog.setMaxDensity = render.fog.setMaxDensity or glua_render.FogMaxDensity
    render.fog.setZ = render.fog.setZ or glua_render.SetFogZ
end

