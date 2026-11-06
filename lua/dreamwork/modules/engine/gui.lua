local glua_ScrW, glua_ScrH = ScrW, ScrH
local glua_OpenFolder      = OpenFolder

---@class dreamwork.engine
local dreamwork_engine     = dreamwork.engine
local engine_Panel         = dreamwork_engine.Panel


---@type garrysmod.vgui
local glua_vgui   = dreamwork_engine.requireLibrary( "vgui" )
local vgui_Create = glua_vgui.CreateX or glua_vgui.Create

local std         = dreamwork.std

local error       = std.error


--- [CLIENT AND MENU]
---
--- The engine's GUI library.
---
---@class dreamwork.engine.gui
local gui = {}
dreamwork_engine.gui = gui


gui.getWidth  = glua_ScrW or function() return 0 end
gui.getHeight = glua_ScrH or function() return 0 end


---@alias dreamwork.engine.gui.panelCreate
---| fun( classname: "HTML", parent: garrysmod.Panel?, name: string? ): ( garrysmod.HTML | nil )
---| fun( classname: "Awesomium", parent: garrysmod.Panel?, name: string? ): ( garrysmod.Awesomium | nil )
---| fun( classname: "Chromium", parent: garrysmod.Panel?, name: string? ): ( garrysmod.Chromium | nil )
---| fun( classname: string, parent: garrysmod.Panel?, name: string? ): ( garrysmod.Panel | nil )

---@type dreamwork.engine.gui.panelCreate
gui.panelCreate = vgui_Create or function()
    error( "panel creation is not available", 2 )
end

---@type fun( panel: garrysmod.Panel )
gui.panelDestroy = engine_Panel.Remove or function()
    error( "panel destroy is not available", 2 )
end

---@type fun( panel: garrysmod.Panel ): boolean
gui.panelIsValid = engine_Panel.IsValid or function()
    return false
end

---@type fun( path: string )
gui.openFolder = glua_OpenFolder or function()
    error( "folder opening is not available", 2 )
end
