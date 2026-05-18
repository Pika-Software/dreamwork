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

    local cam_Start = cam.Start or debug_fempty

    ---@type RenderCamData
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

    gfx2d.stop = cam.End2D or debug_fempty

end

do

    ---@class dreamwork.std.UnitResolver : dreamwork.std.Object
    local UnitResolver = class.base( "UnitResolver", true )

    ---@type table<dreamwork.std.UnitResolver, table<string, string>>
    local internal_map = {}

    std.gc.setTableRules( internal_map, true, false )

    function UnitResolver:__init( unit_str )

    end

    ---@class dreamwork.std.UnitResolverClass : dreamwork.std.UnitResolver
    local UnitResolverClass = class.create( UnitResolver )
    std.UnitResolver = UnitResolverClass

    function UnitResolverClass.resolve( unit_str )

    end

end

---@class dreamwork.std.Font : dreamwork.std.Object
local Font = class.base( "Font", true )

-- TODO: font class

---@class dreamwork.std.FontClass : dreamwork.std.Font
local FontClass = class.create( Font )
std.Font = FontClass


-- TODO: add 2d surface functions
--
-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/surface.lua
--
-- ref: https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/cam.lua
