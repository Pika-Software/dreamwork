---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local LUA_CLIENT = std.LUA_CLIENT

local debug = std.debug
local debug_fempty = debug.fempty

--- [CLIENT AND MENU]
---
---
---
---@class dreamwork.std.gfx2d
local gfx2d = std.gfx2d or {}
std.gfx2d = gfx2d


if LUA_CLIENT then

    ---@type garrysmod.cam
    local glua_cam = dreamwork.engine.requireLibrary( "cam" )
    local cam_Start = glua_cam.Start or debug_fempty

    ---@type garrysmod.RenderCamData
    local view = {
        type = "2D"
    }

    --- [CLIENT]
    ---
    ---
    ---
    function gfx2d.start()
        cam_Start( view )
    end

    gfx2d.stop = glua_cam.End2D or debug_fempty

end

-- TODO: add 2d surface functions
--
-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/surface.lua
--
-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/cam.lua

-- if std.LUA_CLIENT then

--     local render_ReadPixel

--     ---@diagnostic disable-next-line: undefined-field
--     local glua_render = render
--     if glua_render ~= nil then
--         render_ReadPixel = glua_render.ReadPixel
--     end

--     if render_ReadPixel == nil then

--         function render_ReadPixel( x, y )
--             return 0, 0, 0, 255
--         end

--     end

--     --- [CLIENT]
--     ---
--     --- Creates a color object from screen coordinates by reading a pixel.
--     ---
--     --- Requires `render.CapturePixels` call before using.
--     ---
--     ---@see https://wiki.facepunch.com/gmod/render.ReadPixel
--     ---@param x integer The x coordinate.
--     ---@param y integer The y coordinate.
--     ---@param alpha integer? The alpha channel.
--     ---@return dreamwork.std.Color
--     local function fromScreen( x, y, alpha )
--         local r, g, b, a = render_ReadPixel( x, y )
--         return from_rgba( r, g, b, alpha or a )
--     end

-- end
