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

if glua_render == nil then
    return
end

render.SupportsPixelShadersV1 = ( glua_render.SupportsPixelShaders_1_4 or std.debug.fempty )() == true
render.SupportsPixelShadersV2 = ( glua_render.SupportsPixelShaders_2_0 or std.debug.fempty )() == true
render.SupportsVertexShaders = ( glua_render.SupportsVertexShaders_2_0 or std.debug.fempty )() == true

local directx_level = ( ( glua_render.GetDXLevel() or std.debug.fempty ) or 80 ) * 0.1
render.SupportedDirectX = directx_level
render.SupportsHDR = directx_level >= 8
