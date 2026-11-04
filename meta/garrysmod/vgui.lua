---@meta garrysmod.vgui


--- [CLIENT AND MENU]
---
--- The vgui library allows you to script and create your own panels using Valve's Graphical User
--- Interface (VGUI) system.
---
--- For an alphabetically ordered list of VGUI panels, see
--- [VGUI Element List](https://wiki.facepunch.com/gmod/VGUI_Element_List).
---
--- Open Source (Lua) helpers are omitted except `vgui.Create` / `vgui.CreateX`.
---
---@class garrysmod.vgui
vgui = {}

--- [CLIENT AND MENU]
---
--- Creates a panel by the specified classname.
---
--- > NOTE: Custom VGUI elements are not loaded instantly. Use
--- > [GM:OnGamemodeLoaded](https://wiki.facepunch.com/gmod/GM:OnGamemodeLoaded) to create them on
--- > startup.
---
---@param classname string Classname of the panel to create.
--- Default panel classnames can be found on the [VGUI Element List](https://wiki.facepunch.com/gmod/VGUI_Element_List).
--- New panels can be registered via [vgui.Register](https://wiki.facepunch.com/gmod/vgui.Register)
---@param parent garrysmod.Panel? Panel to parent to. Defaults to `nil`.
---@param name string? Custom name of the created panel for scripting/debugging purposes. Can be retrieved with [Panel:GetName](https://wiki.facepunch.com/gmod/Panel:GetName). Defaults to `nil`.
---@return garrysmod.Panel | nil panel The created panel, or `nil` if creation failed for whatever reason.
function vgui.Create( classname, parent, name ) end

--- [CLIENT AND MENU]
---
--- Creates an engine panel.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param class string Class of the panel to create.
---@param parent garrysmod.Panel? If specified, parents created panel to given one. Defaults to `nil`.
---@param name string? Name of the created panel. Defaults to `nil`.
---@return garrysmod.Panel created Created panel.
function vgui.CreateX( class, parent, name ) end

--- [CLIENT AND MENU]
---
--- Returns whenever the cursor is currently active and visible.
---
---@return boolean value Whether the cursor is visible or not.
function vgui.CursorVisible() end

--- [CLIENT AND MENU]
---
--- Returns whether the currently focused panel is a child of the given one.
---
---@param parent garrysmod.Panel The parent panel to check the currently focused one against. This doesn't need to be a direct parent (focused panel can be a child of a child and so on).
---@return boolean value Whether or not the focused panel is a child of the passed one.
function vgui.FocusedHasParent( parent ) end

--- [CLIENT AND MENU]
---
--- Returns all Lua-created panels.
---
--- Used internally for [PANEL:PreAutoRefresh](https://wiki.facepunch.com/gmod/PANEL:PreAutoRefresh) and
--- [PANEL:PostAutoRefresh](https://wiki.facepunch.com/gmod/PANEL:PostAutoRefresh).
---
---@return garrysmod.Panel[] panels List of all Lua created panels.
function vgui.GetAll() end

--- [CLIENT AND MENU]
---
--- Returns the panel the cursor is hovering above.
---
--- > WARNING: This returns a cached value that is only updated after rendering and `before` the next
--- > VGUI Think/Layout pass.
---
--- ie. it lags one frame behind panel layout and is completely unhelpful for
--- [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint) if your panels are moving around under
--- the mouse a lot every frame.
---
---@return garrysmod.Panel value The panel that the user is currently hovering over with their cursor.
function vgui.GetHoveredPanel() end

--- [CLIENT AND MENU]
---
--- Returns the panel which is currently receiving keyboard input.
---
---@return garrysmod.Panel value The panel with keyboard focus
function vgui.GetKeyboardFocus() end

--- [CLIENT AND MENU]
---
--- Returns the global world panel which is the parent to all others, except for the HUD panel.
---
--- See also [Global.GetHUDPanel](https://wiki.facepunch.com/gmod/Global.GetHUDPanel).
---
---@return garrysmod.Panel value The world panel
function vgui.GetWorldPanel() end

--- [CLIENT AND MENU]
---
--- Returns whenever the cursor is hovering the world panel.
---
---@return boolean is_hovering_world Whether the cursor is hovering the world panel.
function vgui.IsHoveringWorld() end