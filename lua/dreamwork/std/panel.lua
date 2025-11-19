local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local glua_vgui = _G.vgui

--[[

    https://wiki.facepunch.com/gmod/Global.DisableClipping

    https://wiki.facepunch.com/gmod/vgui

]]

---@class dreamwork.std.Panel : dreamwork.Object
---@field __class dreamwork.std.PanelClass
local Panel = std.class.base( "Panel" )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Panel dreamwork.std.Panel

---@protected
function Panel:__init()

    -- TODO

end

---@class dreamwork.std.PanelClass : dreamwork.std.Panel
---@field __base dreamwork.std.Panel
---@overload fun(): Panel
local PanelClass = std.class.create( Panel )
std.Panel = PanelClass

local transducers = dreamwork.transducers

do

    local vgui_GetWorldPanel = glua_vgui.GetWorldPanel

    function PanelClass.getMain()
        return transducers[ vgui_GetWorldPanel() ]
    end

end

do

    local vgui_GetHoveredPanel = glua_vgui.GetHoveredPanel

    function PanelClass.getHovered()
        return transducers[ vgui_GetHoveredPanel() ]
    end

end

if std.LUA_CLIENT then

    local GetHUDPanel = _G.GetHUDPanel

    function PanelClass.getHUD()
        return transducers[ GetHUDPanel() ]
    end

end

if std.LUA_MENU then

    local GetOverlayPanel = _G.GetOverlayPanel

    function PanelClass.getOverlay()
        return transducers[ GetOverlayPanel() ]
    end

end
