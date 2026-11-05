local glua_ScrW, glua_ScrH = ScrW, ScrH

---@class dreamwork.engine
local dreamwork_engine     = dreamwork.engine
local engine_Panel         = dreamwork_engine.Panel


---@type garrysmod.vgui
local glua_vgui    = dreamwork_engine.requireLibrary( "vgui" )
local vgui_Create  = glua_vgui.CreateX or glua_vgui.Create

local std          = dreamwork.std

local debug        = std.debug
local debug_fempty = debug.fempty

local error        = std.error


--- [CLIENT AND MENU]
---
--- The engine's GUI library.
---
---@class dreamwork.engine.gui
local gui = {}
dreamwork_engine.gui = gui


gui.getWidth  = glua_ScrW or function() return 0 end
gui.getHeight = glua_ScrH or function() return 0 end


gui.panelCreate  = vgui_Create or function()
    error( "panel creation is not available", 2 )
end

gui.panelDestroy = engine_Panel.Remove or function()
    error( "panel destroy is not available", 2 )
end

gui.panelIsValid = engine_Panel.IsValid or function()
    return false
end
