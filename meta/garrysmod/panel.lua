---@meta garrysmod.panel

--- Alignment of a panel's contents, laid out like the keys of a number pad.
--- Used by [Panel:SetContentAlignment](https://wiki.facepunch.com/gmod/Panel:SetContentAlignment).
---
--- These enumerations do not exist in game and are listed here only for reference.
---
--- See [Enums/ContentAlignment](https://wiki.facepunch.com/gmod/Enums/ContentAlignment).
---
---@alias garrysmod.Panel.ContentAlignment
---| 1 # `BOTTOM_LEFT` — bottom-left
---| 2 # `BOTTOM_CENTER` — bottom-center
---| 3 # `BOTTOM_RIGHT` — bottom-right
---| 4 # `MIDDLE_LEFT` — middle-left
---| 5 # `CENTER` — center
---| 6 # `MIDDLE_RIGHT` — middle-right
---| 7 # `TOP_LEFT` — top-left
---| 8 # `TOP_CENTER` — top-center
---| 9 # `TOP_RIGHT` — top-right

--- [CLIENT AND MENU]
---
--- This is the base panel for every other [VGUI](https://wiki.facepunch.com/gmod/vgui) panel.
---
--- It contains all of the basic methods, some of which may only work on certain VGUI elements.
--- See also [Panel Hooks](https://wiki.facepunch.com/gmod/PANEL_Hooks).
---
--- Open Source (Lua) extension methods are omitted; see `lua/includes/extensions/client/panel*.lua`.
---
---@class garrysmod.Panel : metatable
---@field PaintingDragging boolean Set to `true` by the dragndrop system when the panel is being drawn for the drag'n'drop.
local Panel = {}

--- [CLIENT AND MENU]
---
--- This function does nothing.
---
--- > DEPRECATED: Does nothing
---
function Panel:AddText() end

--- [CLIENT AND MENU]
---
--- Appends text to a [RichText](https://wiki.facepunch.com/gmod/RichText) element. This does not
--- automatically add a new line.
---
---@param txt string The text to append (add on).
function Panel:AppendText( txt ) end

--- [CLIENT AND MENU]
---
--- Appends text to a [RichText](https://wiki.facepunch.com/gmod/RichText) element (exactly like
--- [Panel:AppendText](https://wiki.facepunch.com/gmod/Panel:AppendText)), while also parsing and adding
--- valid URLs
--- ([Panel:InsertClickableTextStart](https://wiki.facepunch.com/gmod/Panel:InsertClickableTextStart)).
--- This does not automatically add a new line.
---
---@param txt string The text to append (add on).
function Panel:AppendTextWithURLs( txt ) end

--- [CLIENT AND MENU]
---
--- Returns the width and height of the space between the position of the panel (upper-left corner) and
--- the max bound of the children panels (farthest reaching lower-right corner).
---
---@return number width The children size width.
---@return number height The children size height.
function Panel:ChildrenSize() end

--- [CLIENT AND MENU]
---
--- Performs the CONTROL + C key combination effect ( Copy selection to clipboard ) on selected text in
--- a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) or
--- [RichText](https://wiki.facepunch.com/gmod/RichText) based element.
---
function Panel:CopySelected() end

--- [CLIENT AND MENU]
---
--- Returns the cursor position relative to the top left of the panel.
--- This is equivalent to calling [gui.MousePos](https://wiki.facepunch.com/gmod/gui.MousePos) and then
--- [Panel:ScreenToLocal](https://wiki.facepunch.com/gmod/Panel:ScreenToLocal).
---
--- > WARNING: This function uses a cached value for the screen position of the panel, computed at the
--- > end of the last VGUI Think/Layout pass. ie. inaccurate results may be returned if the panel or
--- > any of its ancestors have been repositioned outside of
--- > [PANEL:Think](https://wiki.facepunch.com/gmod/PANEL:Think) or
--- > [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout) within the last frame.
---
---@return number x X coordinate of the cursor, relative to the top left of the panel.
---@return number y Y coordinate of the cursor, relative to the top left of the panel.
function Panel:CursorPos() end

--- [CLIENT AND MENU]
---
--- Performs the CONTROL + X (delete text and copy it to clipboard buffer) action on selected text in a
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) or
--- [RichText](https://wiki.facepunch.com/gmod/RichText) based element.
---
function Panel:CutSelected() end

--- [CLIENT AND MENU]
---
--- Makes the panel "lock" the screen until it is removed. All input will be directed to the given
--- panel.
--- It will silently fail if used while cursor is not visible.
--- Call [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup) before calling this
--- function.
--- This must be called on a panel derived from
--- [EditablePanel](https://wiki.facepunch.com/gmod/EditablePanel).
---
function Panel:DoModal() end

--- [CLIENT AND MENU]
---
--- Sets the dock type for the panel, making the panel "dock" in a certain direction, modifying it's
--- position and size.
--- You can set the inner spacing of a panel's docking using
--- [Panel:DockPadding](https://wiki.facepunch.com/gmod/Panel:DockPadding), which will affect docked
--- child panels, and you can set the outer spacing of a panel's docking using
--- [Panel:DockMargin](https://wiki.facepunch.com/gmod/Panel:DockMargin), which affects how docked
--- siblings are positioned/sized.
--- You may need to use [Panel:SetZPos](https://wiki.facepunch.com/gmod/Panel:SetZPos) to ensure child
--- panels ([TextEntry](https://wiki.facepunch.com/gmod/TextEntry)) stay in a specific order.
---
--- > NOTE: After using this function, if you want to get the correct panel's bounds (position, size),
--- > use [Panel:InvalidateParent](https://wiki.facepunch.com/gmod/Panel:InvalidateParent) (use `true` as
--- > argument if you need to update immediately)
---
---@param dock_type integer Dock type using [Enums/DOCK](https://wiki.facepunch.com/gmod/Enums/DOCK).
function Panel:Dock( dock_type ) end

--- [CLIENT AND MENU]
---
--- Sets the dock margin of the panel.
--- The dock margin is the extra space that will be left around the edge when this element is docked
--- inside its parent element.
---
---@param margin_left number The left margin to the parent.
---@param margin_top number The top margin to the parent.
---@param margin_right number The right margin to the parent.
---@param margin_bottom number The bottom margin to the parent.
function Panel:DockMargin( margin_left, margin_top, margin_right, margin_bottom ) end

--- [CLIENT AND MENU]
---
--- Sets the dock padding of the panel.
--- The dock padding is the extra space that will be left around the edge when child elements are docked
--- inside this element.
---
---@param padding_left number The left padding to the parent.
---@param padding_top number The top padding to the parent.
---@param padding_right number The right padding to the parent.
---@param padding_bottom number The bottom padding to the parent.
function Panel:DockPadding( padding_left, padding_top, padding_right, padding_bottom ) end

--- [CLIENT AND MENU]
---
--- Draws a coloured rectangle to fill the panel object this method is called on. The colour is set
--- using [surface.SetDrawColor](https://wiki.facepunch.com/gmod/surface.SetDrawColor). This should only
--- be called within the object's [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint) or
--- [PANEL:PaintOver](https://wiki.facepunch.com/gmod/PANEL:PaintOver) hooks, as a shortcut for
--- [surface.DrawRect](https://wiki.facepunch.com/gmod/surface.DrawRect).
---
function Panel:DrawFilledRect() end

--- [CLIENT AND MENU]
---
--- Draws a hollow rectangle the size of the panel object this method is called on, with a border width
--- of 1 px. The border colour is set using
--- [surface.SetDrawColor](https://wiki.facepunch.com/gmod/surface.SetDrawColor). This should only be
--- called within the object's [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint) or
--- [PANEL:PaintOver](https://wiki.facepunch.com/gmod/PANEL:PaintOver) hooks, as a shortcut for
--- [surface.DrawOutlinedRect](https://wiki.facepunch.com/gmod/surface.DrawOutlinedRect).
---
function Panel:DrawOutlinedRect() end

--- [CLIENT AND MENU]
---
--- Used to draw the text in a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) within a VGUI
--- skin. This is usually called within the
--- [SKIN:PaintTextEntry](https://wiki.facepunch.com/gmod/SKIN:PaintTextEntry) skin hook.
---
--- > NOTE: Will silently fail if any of arguments are not given.
---
---@param text_col table The colour of the main text.
---@param highlight_col table The colour of the selection highlight (when selecting text).
---@param cursor_col table The colour of the text cursor (or caret).
function Panel:DrawTextEntryText( text_col, highlight_col, cursor_col ) end

--- [CLIENT AND MENU]
---
--- Draws a textured rectangle to fill the panel object this method is called on. The texture is set
--- using [surface.SetTexture](https://wiki.facepunch.com/gmod/surface.SetTexture) or
--- [surface.SetMaterial](https://wiki.facepunch.com/gmod/surface.SetMaterial). This should only be
--- called within the object's [PANEL:Paint](https://wiki.facepunch.com/gmod/PANEL:Paint) or
--- [PANEL:PaintOver](https://wiki.facepunch.com/gmod/PANEL:PaintOver) hooks, as a shortcut for
--- [surface.DrawTexturedRect](https://wiki.facepunch.com/gmod/surface.DrawTexturedRect).
---
function Panel:DrawTexturedRect() end

--- [CLIENT AND MENU]
---
--- Finds a panel in its children(and sub children) with the given name.
---
---@param panel_name string The name of the panel that should be found.
---@return garrysmod.Panel found_panel foundPanel
function Panel:Find( panel_name ) end

--- [CLIENT AND MENU]
---
--- Focuses the next panel in the focus queue.
---
function Panel:FocusNext() end

--- [CLIENT AND MENU]
---
--- Focuses the previous panel in the focus queue.
---
function Panel:FocusPrevious() end

--- [CLIENT AND MENU]
---
--- Returns the alpha multiplier for this panel.
---
---@return number alpha_mul alphaMul
function Panel:GetAlpha() end

--- [CLIENT AND MENU]
---
--- Returns the background color of a panel such as a
--- [RichText](https://wiki.facepunch.com/gmod/RichText), [Label](https://wiki.facepunch.com/gmod/Label)
--- or panel.
---
--- > NOTE: This doesn't apply to all VGUI elements and its function varies between them
---
---@return garrysmod.Color color The [Color](https://wiki.facepunch.com/gmod/Color).
function Panel:GetBGColor() end

--- [CLIENT AND MENU]
---
--- Returns the position and size of the panel.
--- This is equivalent to calling [Panel:GetPos](https://wiki.facepunch.com/gmod/Panel:GetPos) and
--- [Panel:GetSize](https://wiki.facepunch.com/gmod/Panel:GetSize) together.
---
---@return number value_1 The x coordinate of the panel, relative to its parent's top left.
---@return number value_2 The y coordinate of the panel, relative to its parent's top left.
---@return number value_3 The width of the panel.
---@return number value_4 The height of the panel.
function Panel:GetBounds() end

--- [CLIENT AND MENU]
---
--- Returns the position/offset of the caret (or text cursor) in a text-based panel object.
---
---@return number value The caret position/offset from the start of the text. A value of `0` means the caret sits before the first character.
function Panel:GetCaretPos() end

--- [CLIENT AND MENU]
---
--- Gets a child by its index. Typically used with
--- [Panel:ChildCount](https://wiki.facepunch.com/gmod/Panel:ChildCount).
---
---@param child_index number The index of the child to get.
--- > NOTE: This index starts at 0, except when you use this on a [Menu](https://wiki.facepunch.com/gmod/Menu).
---@return garrysmod.Panel value The child panel, or a `nil`
function Panel:GetChild( child_index ) end

--- [CLIENT AND MENU]
---
--- Returns a table with all the child panels of the panel.
---
---@return table all All direct children of this panel.
function Panel:GetChildren() end

--- [CLIENT AND MENU]
---
--- Returns the class name of the panel. This would be the class name of the base engine-level panel,
--- not Lua classname. The latter is stored usually in
--- [Panel:GetName](https://wiki.facepunch.com/gmod/Panel:GetName).
---
---@return string value The panel's class name.
function Panel:GetClassName() end

--- [CLIENT AND MENU]
---
--- Returns the alignment of the text of a [Label](https://wiki.facepunch.com/gmod/Label).
---
--- > NOTE: This function only works on [Label](https://wiki.facepunch.com/gmod/Label) panels and its
--- > derivatives.
---
---@return garrysmod.Panel.ContentAlignment alignment The direction of the content, based on the number pad.
function Panel:GetContentAlignment() end

--- [CLIENT AND MENU]
---
--- Gets the size of the content/children within a panel object.
--- Only works with [Label](https://wiki.facepunch.com/gmod/Label) derived panels by default such as
--- [Label](https://wiki.facepunch.com/gmod/Label).
--- Will also work on any panel that manually implements this method.
---
---@return number value_1 The content width of the object.
---@return number value_2 The content height of the object.
function Panel:GetContentSize() end

--- [CLIENT AND MENU]
---
--- Gets the name the panel uses to store cookies. This is set with
--- [Panel:SetCookieName](https://wiki.facepunch.com/gmod/Panel:SetCookieName).
---
---@return string value The name the panel uses when reading or writing cookies. The format used is as follows:
--- ```
--- panelCookieName.individualCookieName
--- ```
function Panel:GetCookieName() end

--- [CLIENT AND MENU]
---
--- Returns a dock enum for the panel's current docking type.
---
---@return number value The dock enum for the panel. See [Enums/DOCK](https://wiki.facepunch.com/gmod/Enums/DOCK).
function Panel:GetDock() end

--- [CLIENT AND MENU]
---
--- Returns the docked margins of the panel. (set by
--- [Panel:DockMargin](https://wiki.facepunch.com/gmod/Panel:DockMargin))
---
---@return number left Left margin.
---@return number top Top margin.
---@return number right Right margin.
---@return number bottom Bottom margin.
function Panel:GetDockMargin() end

--- [CLIENT AND MENU]
---
--- Returns the docked padding of the panel. (set by
--- [Panel:DockPadding](https://wiki.facepunch.com/gmod/Panel:DockPadding))
---
---@return number left Left padding.
---@return number top Top padding.
---@return number right Right padding.
---@return number bottom Bottom padding.
function Panel:GetDockPadding() end

--- [CLIENT AND MENU]
---
--- Returns the foreground color of the panel.
--- For a [Label](https://wiki.facepunch.com/gmod/Label) or
--- [RichText](https://wiki.facepunch.com/gmod/RichText), this is the color of its text.
---
--- > NOTE: This doesn't apply to all VGUI elements (such as
--- > [Label](https://wiki.facepunch.com/gmod/Label)) and its function varies between them
---
---@return garrysmod.Color color The [Color](https://wiki.facepunch.com/gmod/Color).
function Panel:GetFGColor() end

--- [CLIENT AND MENU]
---
--- Returns the name of the font that the panel renders its text with.
--- This is the same font name set with
--- [Panel:SetFontInternal](https://wiki.facepunch.com/gmod/Panel:SetFontInternal).
---
--- > NOTE: Only works on [Label](https://wiki.facepunch.com/gmod/Label) and
--- > [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) and their derived panels by default (such as
--- > [Label](https://wiki.facepunch.com/gmod/Label) and
--- > [TextEntry](https://wiki.facepunch.com/gmod/TextEntry)), and on any panel that manually
--- > implemented the [Panel:GetFont](https://wiki.facepunch.com/gmod/Panel:GetFont) method.
---
---@return string value The font name.
function Panel:GetFont() end

--- [CLIENT AND MENU]
---
--- Returns the height of a single line of a [RichText](https://wiki.facepunch.com/gmod/RichText) panel.
---
---@return number value The line height.
function Panel:GetLineHeight() end

--- [CLIENT AND MENU]
---
--- Returns the current maximum character count.
--- This function will only work on [RichText](https://wiki.facepunch.com/gmod/RichText) and
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) panels and their derivatives.
---
---@return number max_char The maximum amount of characters this panel is allowed to contain.
function Panel:GetMaximumCharCount() end

--- [CLIENT AND MENU]
---
--- Returns the internal name of the panel. Can be set via
--- [Panel:SetName](https://wiki.facepunch.com/gmod/Panel:SetName).
---
---@return string value The previously set internal name of the panel.
function Panel:GetName() end

--- [CLIENT AND MENU]
---
--- Returns the number of lines in a [RichText](https://wiki.facepunch.com/gmod/RichText) or a
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry).
--- You must wait a couple frames before calling this after using
--- [Panel:AppendText](https://wiki.facepunch.com/gmod/Panel:AppendText) or
--- [Panel:SetText](https://wiki.facepunch.com/gmod/Panel:SetText), otherwise it will return the number
--- of text lines before the text change.
---
---@return number value The number of lines.
function Panel:GetNumLines() end

--- [CLIENT AND MENU]
---
--- Returns the parent of the panel, returns nil if there is no parent.
---
---@return garrysmod.Panel value The parent of given panel
function Panel:GetParent() end

--- [CLIENT AND MENU]
---
--- Returns the position of the panel relative to its
--- [Panel:GetParent](https://wiki.facepunch.com/gmod/Panel:GetParent).
--- If you require the panel's position **and** size, consider using
--- [Panel:GetBounds](https://wiki.facepunch.com/gmod/Panel:GetBounds) instead.
--- If you need the position in screen space, see
--- [Panel:LocalToScreen](https://wiki.facepunch.com/gmod/Panel:LocalToScreen).
--- See also [Panel:GetX](https://wiki.facepunch.com/gmod/Panel:GetX) and
--- [Panel:GetY](https://wiki.facepunch.com/gmod/Panel:GetY).
---
---@return number x X coordinate, relative to this panels parents top left corner.
---@return number y Y coordinate, relative to this panels parents top left corner.
function Panel:GetPos() end

--- [CLIENT AND MENU]
---
--- Returns the vertical and horizontal start indexes of a
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry)'s visible text. This is useful when the panel
--- is scrolled.
---
---@return number horizontal_index The horizontal start index. (characters)
---@return number vertical_index The vertical start index. (lines)
function Panel:GetScrollStartIndexes() end

--- [CLIENT AND MENU]
---
--- Returns the currently selected range of text.
--- This function will only work on [RichText](https://wiki.facepunch.com/gmod/RichText) and
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) panels and their derivatives.
---
---@return number start The start of the range. If no text is selected it may be 0 and/or equal to the end range.
---@return number endrange The end of the range. If no text is selected it may be 0 and/or equal to the start range.
function Panel:GetSelectedTextRange() end

--- [CLIENT AND MENU]
---
--- Returns the size of the panel.
--- If you require both the panel's position and size, consider using
--- [Panel:GetBounds](https://wiki.facepunch.com/gmod/Panel:GetBounds) instead.
---
---@return number value_1 The panel's width. ([Panel:GetWide](https://wiki.facepunch.com/gmod/Panel:GetWide))
---@return number value_2 The panel's height ([Panel:GetTall](https://wiki.facepunch.com/gmod/Panel:GetTall))
function Panel:GetSize() end

--- [CLIENT AND MENU]
---
--- Returns the internal Lua table of the panel.
---
---@return table value A table containing all the members of given panel object.
function Panel:GetTable() end

--- [CLIENT AND MENU]
---
--- Returns the height of the panel.
--- See [Panel:GetWide](https://wiki.facepunch.com/gmod/Panel:GetWide) for the width of the panel. See
--- also [Panel:GetSize](https://wiki.facepunch.com/gmod/Panel:GetSize) for a function that returns
--- both.
---
---@return number height height
function Panel:GetTall() end

--- [CLIENT AND MENU]
---
--- Returns the panel's text (where applicable).
--- This method returns a maximum of 1023 bytes, except for
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry).
---
---@return string value The panel's text.
function Panel:GetText() end

--- [CLIENT AND MENU]
---
--- Gets the left and top text margins of a text-based panel object, such as a
--- [Button](https://wiki.facepunch.com/gmod/Button) or
--- [Label](https://wiki.facepunch.com/gmod/Label). This is set with
--- [Panel:SetTextInset](https://wiki.facepunch.com/gmod/Panel:SetTextInset).
---
---@return number value_1 The left margin of the text, in pixels.
---@return number value_2 The top margin of the text, in pixels.
function Panel:GetTextInset() end

--- [CLIENT AND MENU]
---
--- Gets the size of the text within a [Label](https://wiki.facepunch.com/gmod/Label) derived panel.
---
---@return number value_1 The width of the text.
---@return number value_2 The height of the text.
function Panel:GetTextSize() end

--- [CLIENT AND MENU]
---
--- Returns the value the panel holds.
--- In engine is only implemented for [CheckButton](https://wiki.facepunch.com/gmod/CheckButton),
--- [Label](https://wiki.facepunch.com/gmod/Label) and
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) as a string.
---
--- > NOTE: This function is limited to 8092 Bytes. If using
--- > [TextEntry](https://wiki.facepunch.com/gmod/TextEntry), use
--- > [Panel:GetText](https://wiki.facepunch.com/gmod/Panel:GetText) for unlimited bytes.
---
---@return any value The value the panel holds.
function Panel:GetValue() end

--- [CLIENT AND MENU]
---
--- Returns the width of the panel.
--- See [Panel:GetTall](https://wiki.facepunch.com/gmod/Panel:GetTall) for the height of the panel. See
--- also [Panel:GetSize](https://wiki.facepunch.com/gmod/Panel:GetSize) for a function that returns
--- both.
---
---@return number width width
function Panel:GetWide() end

--- [CLIENT AND MENU]
---
--- Returns the Z position of the panel.
---
---@return number value The Z order position of the panel.
function Panel:GetZPos() end

--- [CLIENT AND MENU]
---
--- Causes a [RichText](https://wiki.facepunch.com/gmod/RichText) element to scroll to the bottom of its
--- text.
---
function Panel:GotoTextEnd() end

--- [CLIENT AND MENU]
---
--- Causes a [RichText](https://wiki.facepunch.com/gmod/RichText) element to scroll to the top of its
--- text.
---
function Panel:GotoTextStart() end

--- [CLIENT AND MENU]
---
--- Returns whenever the panel has child panels.
---
---@return boolean has_childs hasChilds
function Panel:HasChildren() end

--- [CLIENT AND MENU]
---
--- Returns if the panel is focused.
---
---@return boolean has_focus hasFocus
function Panel:HasFocus() end

--- [CLIENT AND MENU]
---
--- Returns if the panel or any of its children(sub children and so on) has the focus.
---
---@return boolean has_hierarchical_focus hasHierarchicalFocus
function Panel:HasHierarchicalFocus() end

--- [CLIENT AND MENU]
---
--- Returns whether the panel is a descendent of the given panel.
---
---@param parent_panel garrysmod.Panel
---@return boolean value True if the panel is contained within parentPanel.
function Panel:HasParent( parent_panel ) end

--- [CLIENT AND MENU]
---
--- Marks the end of a clickable text segment in a [RichText](https://wiki.facepunch.com/gmod/RichText)
--- element, started with
--- [Panel:InsertClickableTextStart](https://wiki.facepunch.com/gmod/Panel:InsertClickableTextStart).
---
function Panel:InsertClickableTextEnd() end

--- [CLIENT AND MENU]
---
--- Starts the insertion of clickable text for a [RichText](https://wiki.facepunch.com/gmod/RichText)
--- element. Any text appended with [Panel:AppendText](https://wiki.facepunch.com/gmod/Panel:AppendText)
--- between this call and
--- [Panel:InsertClickableTextEnd](https://wiki.facepunch.com/gmod/Panel:InsertClickableTextEnd) will
--- become clickable text.
--- The hook [PANEL:OnTextClicked](https://wiki.facepunch.com/gmod/PANEL:OnTextClicked) is called when
--- the text is clicked.
---
--- > NOTE: The clickable text is a separate VGUI panel which will not inherit the current font from
--- > the `RichText`.
---
---@param signal_value string The text passed as the action signal's value.
function Panel:InsertClickableTextStart( signal_value ) end

--- [CLIENT AND MENU]
---
--- Inserts a color change in a [RichText](https://wiki.facepunch.com/gmod/RichText) element, which
--- affects the color of all text added with
--- [Panel:AppendText](https://wiki.facepunch.com/gmod/Panel:AppendText) until another color change is
--- applied.
---
---@param r number The red value `(0 - 255)`.
---@param g number The green value `(0 - 255)`.
---@param b number The blue value `(0 - 255)`.
---@param a number The alpha value `(0 - 255)`.
function Panel:InsertColorChange( r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Begins a text fade for a [RichText](https://wiki.facepunch.com/gmod/RichText) element where the last
--- appended text segment is fully faded out after a specific amount of time, at a specific speed.
--- The alpha of the text at any given time is determined by the text's base alpha * ((`sustain` -
--- [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)) / `length`) where
--- [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime) is added to `sustain` when this
--- method is called.
---
---@param sustain number The number of seconds the text remains visible.
---@param length number The number of seconds it takes the text to fade out.
--- If set **lower** than `sustain`, the text will not begin fading out until (`sustain` - `length`) seconds have passed.
--- If set **higher** than `sustain`, the text will begin fading out immediately at a fraction of the base alpha.
--- If set to **-1**, the text doesn't fade out.
function Panel:InsertFade( sustain, length ) end

--- [CLIENT AND MENU]
---
--- Causes the panel to re-layout in the next frame. During the layout process
--- [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout) will be called on the
--- target panel.
--- You should avoid calling this function every frame.
---
--- > BUG: Using this on a panel after clicking on a docked element will cause docked elements to
--- > reorient themselves incorrectly. This can be fixed by assigning a unique
--- > [Panel:SetZPos](https://wiki.facepunch.com/gmod/Panel:SetZPos) to each docked element. See [issue
--- > #2574](https://github.com/Facepunch/garrysmod-issues/issues/2574).
---
---@param layout_now boolean? If true the panel will re-layout instantly and not wait for the next frame. Defaults to `false`.
function Panel:InvalidateLayout( layout_now ) end

--- [CLIENT AND MENU]
---
--- Returns whether the the panel is enabled or disabled.
--- See [Panel:SetEnabled](https://wiki.facepunch.com/gmod/Panel:SetEnabled) for a function that makes
--- the panel enabled or disabled.
---
---@return boolean value Whether the panel is enabled or disabled.
function Panel:IsEnabled() end

--- [CLIENT AND MENU]
---
--- Returns true if the panel can receive keyboard input.
---
---@return boolean keyboard_input_enabled keyboardInputEnabled
function Panel:IsKeyboardInputEnabled() end

--- [CLIENT AND MENU]
---
--- Returns if the panel is going to be deleted in the next frame.
---
---@return boolean marked_for_deletion markedForDeletion
function Panel:IsMarkedForDeletion() end

--- [CLIENT AND MENU]
---
--- Returns whether the panel was made modal or not. See
--- [Panel:DoModal](https://wiki.facepunch.com/gmod/Panel:DoModal).
---
---@return boolean value True if the panel is modal.
function Panel:IsModal() end

--- [CLIENT AND MENU]
---
--- Returns true if the panel can receive mouse input.
---
---@return boolean mouse_input_enabled mouseInputEnabled
function Panel:IsMouseInputEnabled() end

--- [CLIENT AND MENU]
---
--- Determines whether or not a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) panel is in
--- multi-line mode. This is set with
--- [Panel:SetMultiline](https://wiki.facepunch.com/gmod/Panel:SetMultiline).
---
---@return boolean value Whether the object is in multi-line mode or not.
function Panel:IsMultiline() end

--- [CLIENT AND MENU]
---
--- Returns if the panel was made popup or not. See
--- [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup)
---
---@return boolean value `true` if the panel was made popup.
function Panel:IsPopup() end

--- [CLIENT AND MENU]
---
--- Returns if the panel is valid and not marked for deletion.
---
---@return boolean value True if the object is valid.
function Panel:IsValid() end

--- [CLIENT AND MENU]
---
--- Returns if the panel is visible. This will **NOT** take into account visibility of the parent.
---
---@return boolean value `true` if the panel ls visible, `false` otherwise.
function Panel:IsVisible() end

--- [CLIENT AND MENU]
---
--- Returns if a panel allows world clicking set by
--- [Panel:SetWorldClicker](https://wiki.facepunch.com/gmod/Panel:SetWorldClicker).
---
---@return boolean if_ If the panel allows world clicking.
function Panel:IsWorldClicker() end

--- [CLIENT AND MENU]
---
--- Remove the focus from the panel.
---
function Panel:KillFocus() end

--- [CLIENT AND MENU]
---
--- Similar to
--- [Panel:LoadControlsFromString](https://wiki.facepunch.com/gmod/Panel:LoadControlsFromString) but
--- loads controls from a file.
---
--- > DEPRECATED: No longer does anything.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param path string The path to load the controls from.
function Panel:LoadControlsFromFile( path ) end

--- [CLIENT AND MENU]
---
--- Loads controls(positions, etc) from given data. This is what the default options menu uses.
---
--- > DEPRECATED: No longer does anything.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param data string The data to load controls from. Format unknown.
function Panel:LoadControlsFromString( data ) end

--- [CLIENT AND MENU]
---
--- Sets a new image to be loaded by a [TGAImage](https://wiki.facepunch.com/gmod/TGAImage).
---
--- > DEPRECATED: An image panel should be used instead (with `.png`
--- > or `.jpg` images). `TGAImage` panel has no advantages.
---
---@param image_name string The file path.
---@param str_path string The PATH to search in. See [File Search Paths](https://wiki.facepunch.com/gmod/File_Search_Paths).
--- This isn't used internally.
function Panel:LoadTGAImage( image_name, str_path ) end

--- [CLIENT AND MENU]
---
--- Takes X and Y coordinates relative to the panel and returns their corresponding positions relative
--- to the screen.
--- See also [Panel:ScreenToLocal](https://wiki.facepunch.com/gmod/Panel:ScreenToLocal).
---
--- > WARNING: This function uses a cached value for the screen position of the panel, computed at the
--- > end of the last VGUI Think/Layout pass, so inaccurate results may be returned if the panel or any of
--- > its ancestors have been re-positioned outside of
--- > [PANEL:Think](https://wiki.facepunch.com/gmod/PANEL:Think) or
--- > [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout) within the last frame.
---
--- > NOTE: If the panel uses [Panel:Dock](https://wiki.facepunch.com/gmod/Panel:Dock), this function
--- > will return 0, 0 when the panel was created. The position will be updated in the next frame.
---
---@param pos_x number The X coordinate of the position on the panel to translate.
---@param pos_y number The Y coordinate of the position on the panel to translate.
---@return number value_1 The X coordinate relative to the screen.
---@return number value_2 The Y coordinate relative to the screen.
function Panel:LocalToScreen( pos_x, pos_y ) end

--- [CLIENT AND MENU]
---
--- Focuses the panel and enables it to receive input.
--- This automatically calls
--- [Panel:SetMouseInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetMouseInputEnabled) and
--- [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
--- and sets them to `true`.
---
--- > NOTE: Panels derived from [Panel](https://wiki.facepunch.com/gmod/Panel) will not work properly
--- > with this function. Due to this, any children will not be intractable with keyboard. Derive from
--- > [EditablePanel](https://wiki.facepunch.com/gmod/EditablePanel) instead. For non gui related mouse
--- > focus, you can use
--- > [gui.EnableScreenClicker](https://wiki.facepunch.com/gmod/gui.EnableScreenClicker).
---
function Panel:MakePopup() end

--- [CLIENT AND MENU]
---
--- Allows the panel to receive mouse input even if the mouse cursor is outside the bounds of the panel.
---
---@param do_capture boolean Set to true to enable, set to false to disable.
function Panel:MouseCapture( do_capture ) end

--- [CLIENT AND MENU]
---
--- Moves the panel object behind all other panels on screen. If the panel has been made a pop-up with
--- [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup), it will still draw in front of
--- any panels that haven't.
---
function Panel:MoveToBack() end

--- [CLIENT AND MENU]
---
--- Moves the panel in front of all other panels on screen. Unless the panel has been made a pop-up
--- using [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup), it will still draw behind
--- any that have.
---
function Panel:MoveToFront() end

--- [CLIENT AND MENU]
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param object_name string
function Panel:NewObject( object_name ) end

--- [CLIENT AND MENU]
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param object_name string
---@param callback_name string
function Panel:NewObjectCallback( object_name, callback_name ) end

--- [CLIENT AND MENU]
---
--- Sets whether this panel's drawings should be clipped within the parent panel's bounds.
--- See [render.SetScissorRect](https://wiki.facepunch.com/gmod/render.SetScissorRect) if you wish to
--- set the clipping rect instead.
---
--- > NOTE: This only disabled clipping for the Paint Related functions (as far as i can tell at the
--- > current moment, more testing should be done) so things like the text of a
--- > [Label](https://wiki.facepunch.com/gmod/Label) will still be clipped to the parent. To fully
--- > disable the clipping of any children see
--- > [Global.DisableClipping](https://wiki.facepunch.com/gmod/Global.DisableClipping).
---
---@param disable_clipping boolean Whether to disable clipping or not. `true` to disable clipping, `false` to enable clipping.
function Panel:NoClipping( disable_clipping ) end

--- [CLIENT AND MENU]
---
--- Paints a ghost copy of the panel at the given position.
---
--- > WARNING: This function sets Z pos of panel's children
--- > ([PANEL:SetZPos](https://wiki.facepunch.com/gmod/PANEL:SetZPos)). It also briefly unparents and
--- > reparents the panel.
---
---@param pos_x number The x coordinate to draw the panel from.
---@param pos_y number The y coordinate to draw the panel from.
function Panel:PaintAt( pos_x, pos_y ) end

--- [CLIENT AND MENU]
---
--- Paints the panel at its current position. To use this you must call
--- [Panel:SetPaintedManually](https://wiki.facepunch.com/gmod/Panel:SetPaintedManually)(true).
---
---@param unclamp boolean? If set, overrides panels' clipping so that it can render fully when its size is larger than the game's resolution. Defaults to `false`.
function Panel:PaintManual( unclamp ) end

--- [CLIENT]
---
--- Parents the panel to the HUD.
--- Makes it invisible on the escape-menu and disables controls.
---
function Panel:ParentToHUD() end

--- [CLIENT AND MENU]
---
--- Only works for TextEntries.
--- Pastes the contents of the clipboard into the TextEntry.
---
--- > DEPRECATED: Due to privacy concerns, this function has been disabled
---
--- > NOTE: Tab characters will be dropped from the pasted text
---
function Panel:Paste() end

--- [CLIENT AND MENU]
---
--- Installs Lua defined functions into the panel.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
function Panel:Prepare() end

--- [CLIENT]
---
--- Causes a [SpawnIcon](https://wiki.facepunch.com/gmod/SpawnIcon) to rebuild its model image.
---
function Panel:RebuildSpawnIcon() end

--- [CLIENT]
---
--- Re-renders a spawn icon with customized cam data.
--- [Global.PositionSpawnIcon](https://wiki.facepunch.com/gmod/Global.PositionSpawnIcon) can be used to
--- easily calculate the necessary camera parameters.
---
--- > NOTE: This function does **not** accept the standard
--- > [Structures/CamData](https://wiki.facepunch.com/gmod/Structures/CamData).
---
---@param data table A table containing the information needed to re-render the icon:
--- * [Vector](https://wiki.facepunch.com/gmod/Vector) cam_pos - The relative camera position the model is viewed from.
--- * [Angle](https://wiki.facepunch.com/gmod/Angle) cam_ang - The camera angle the model is viewed from.
--- * [number](https://wiki.facepunch.com/gmod/number) cam_fov - The camera's field of view (FOV).
--- * [Entity](https://wiki.facepunch.com/gmod/Entity) ent - The entity object of the model.
--- Optional keys:
--- * [table](https://wiki.facepunch.com/gmod/table) lightbox - (As of 2026.08.26) Sets the "lightbox" for the model render. Wants 6 vectors (start index = 1). See [render.SetModelLighting](https://wiki.facepunch.com/gmod/render.SetModelLighting).
--- * [table](https://wiki.facepunch.com/gmod/table) lights - (As of 2026.08.26) Sets the "dynamic lights" for the model render. Same format as [render.SetLocalModelLights](https://wiki.facepunch.com/gmod/render.SetLocalModelLights).
--- See the example below for how to retrieve these values.
function Panel:RebuildSpawnIconEx( data ) end

--- [CLIENT AND MENU]
---
--- Marks a panel for deletion so it will be deleted on the next frame.
--- This will not mark child panels for deletion this frame, but they will be marked and deleted in the
--- next frame.
--- See also [Panel:IsMarkedForDeletion](https://wiki.facepunch.com/gmod/Panel:IsMarkedForDeletion)
--- Will automatically call
--- [Panel:InvalidateParent](https://wiki.facepunch.com/gmod/Panel:InvalidateParent).
---
function Panel:Remove() end

--- [CLIENT AND MENU]
---
--- Attempts to obtain focus for this panel.
---
function Panel:RequestFocus() end

--- [CLIENT AND MENU]
---
--- Resets all text fades in a [RichText](https://wiki.facepunch.com/gmod/RichText) element made with
--- [Panel:InsertFade](https://wiki.facepunch.com/gmod/Panel:InsertFade).
---
---@param hold boolean True to reset fades, false otherwise.
---@param expired_only boolean Any value equating to `true` will reset fades only on text segments that are completely faded out.
---@param new_sustain number The new sustain value of each faded text segment. Set to -1 to keep the old sustain value.
function Panel:ResetAllFades( hold, expired_only, new_sustain ) end

--- [CLIENT AND MENU]
---
--- Translates global screen coordinate to coordinates relative to the panel.
--- See also [Panel:LocalToScreen](https://wiki.facepunch.com/gmod/Panel:LocalToScreen).
---
--- > WARNING: This function uses a cached value for the screen position of the panel, computed at the
--- > end of the last VGUI Think/Layout pass, so inaccurate results may be returned if the panel or any of
--- > its ancestors have been re-positioned outside of
--- > [PANEL:Think](https://wiki.facepunch.com/gmod/PANEL:Think) or
--- > [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout) within the last frame.
---
---@param screen_x number The x coordinate of the screen position to be translated.
---@param screen_y number The y coordinate of the screed position be to translated.
---@return number relativeposition Relativeposition X
---@return number relativeposition_2 Relativeposition Y
function Panel:ScreenToLocal( screen_x, screen_y ) end

--- [CLIENT AND MENU]
---
--- If called on a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry), clicking the text entry for
--- the first time will automatically select all of the text ready to be copied by the user.
---
function Panel:SelectAllOnFocus() end

--- [CLIENT AND MENU]
---
--- Selects all the text in a panel object. Will not select non-text items; for this, use
--- [Panel:SelectAll](https://wiki.facepunch.com/gmod/Panel:SelectAll).
---
--- > DEPRECATED: Duplicate of [Panel:SelectAll](https://wiki.facepunch.com/gmod/Panel:SelectAll).
---
---@param reset_cursor_pos boolean Reset cursor pos?
function Panel:SelectAllText( reset_cursor_pos ) end

--- [CLIENT AND MENU]
---
--- Deselects all items in a panel object. For text-based objects, this will deselect all text.
---
--- > NOTE: Only works on [RichText](https://wiki.facepunch.com/gmod/RichText) and
--- > [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) and their derived panels by default (such as
--- > [TextEntry](https://wiki.facepunch.com/gmod/TextEntry)), and on any panel that manually
--- > reimplemented this method.
---
function Panel:SelectNone() end

--- [CLIENT AND MENU]
---
--- Sets the achievement to be displayed by
--- [AchievementIcon](https://wiki.facepunch.com/gmod/AchievementIcon).
---
---@param id number Achievement number ID
function Panel:SetAchievement( id ) end

--- [CLIENT AND MENU]
---
--- Configures a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) to allow user to type characters
--- that are not included in the US-ASCII (7-bit ASCII) character set.
--- Characters not included in US-ASCII are multi-byte characters in UTF-8. They can be accented
--- characters, non-Latin characters and special characters.
---
---@param allowed boolean Set to true in order not to restrict input characters.
function Panel:SetAllowNonAsciiCharacters( allowed ) end

--- [CLIENT AND MENU]
---
--- Sets the alpha multiplier for the panel
---
---@param alpha number The alpha value in the range of 0-255.
function Panel:SetAlpha( alpha ) end

--- [CLIENT AND MENU]
---
--- Sets whenever the panel should be removed if the parent was removed.
---
---@param auto_delete boolean Whenever to delete if the parent was removed or not.
function Panel:SetAutoDelete( auto_delete ) end

--- [CLIENT AND MENU]
---
--- Sets the background color of the panel.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param r number The red channel of the color.
---@param g number The green channel of the color.
---@param b number The blue channel of the color.
---@param a number The alpha channel of the color.
function Panel:SetBGColorEx( r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Sets the position of the caret (or text cursor) in a text-based panel object.
---
---@param offset number Caret position/offset from the start of text. A value of `0` places the caret before the first character.
function Panel:SetCaretPos( offset ) end

--- [CLIENT AND MENU]
---
--- Sets this panel's convar. When the convar changes this panel will update automatically.
---
--- > WARNING: This function does not exist on all panels
---
--- > WARNING: This function cannot interact with serverside convars unless you are host
---
--- > NOTE: Blocked convars will not work with this, see [Blocked
--- > ConCommands](https://wiki.facepunch.com/gmod/Blocked_ConCommands)
---
---@param convar string The console variable to check.
function Panel:SetConVar( convar ) end

--- [CLIENT AND MENU]
---
--- Sets the alignment of the contents.
---
--- > NOTE: This function only works on [Label](https://wiki.facepunch.com/gmod/Label) panels and its
--- > derivatives.
---
--- > NOTE: This function doesnt work, if [Panel:SetWrap](https://wiki.facepunch.com/gmod/Panel:SetWrap)
--- > is true.
---
---@param alignment garrysmod.Panel.ContentAlignment The direction of the content, based on the number pad.
function Panel:SetContentAlignment( alignment ) end

--- [CLIENT AND MENU]
---
--- Sets the appearance of the cursor. You can find a list of all available cursors with image previews
--- [here](https://wiki.facepunch.com/gmod/Cursors).
---
---@param cursor string The cursor to be set. Can be one of the following:
--- * [arrow](https://wiki.facepunch.com/gmod/Cursors#:~:text=arrow)
--- * [beam](https://wiki.facepunch.com/gmod/Cursors#:~:text=beam)
--- * [hourglass](https://wiki.facepunch.com/gmod/Cursors#:~:text=hourglass)
--- * [waitarrow](https://wiki.facepunch.com/gmod/Cursors#:~:text=waitarrow)
--- * [crosshair](https://wiki.facepunch.com/gmod/Cursors#:~:text=crosshair)
--- * [up](https://wiki.facepunch.com/gmod/Cursors#:~:text=up)
--- * [sizenwse](https://wiki.facepunch.com/gmod/Cursors#:~:text=sizenwse)
--- * [sizenesw](https://wiki.facepunch.com/gmod/Cursors#:~:text=sizenesw)
--- * [sizewe](https://wiki.facepunch.com/gmod/Cursors#:~:text=sizewe)
--- * [sizens](https://wiki.facepunch.com/gmod/Cursors#:~:text=sizens)
--- * [sizeall](https://wiki.facepunch.com/gmod/Cursors#:~:text=sizeall)
--- * [no](https://wiki.facepunch.com/gmod/Cursors#:~:text=no)
--- * [hand](https://wiki.facepunch.com/gmod/Cursors#:~:text=hand)
--- * [blank](https://wiki.facepunch.com/gmod/Cursors#:~:text=blank)
--- Set to anything else to set it to "none", the default fallback. Do note that a value of "none" does not, as one might assume, result in no cursor being drawn - hiding the cursor requires a value of "blank" instead.
function Panel:SetCursor( cursor ) end

--- [CLIENT AND MENU]
---
--- Sets the visibility of the language selection box when typing in non-English mode.
--- See [Panel:SetDrawLanguageIDAtLeft](https://wiki.facepunch.com/gmod/Panel:SetDrawLanguageIDAtLeft)
--- for a function that changes the position of the language selection box.
---
---@param visible boolean true to make it visible, false to hide it.
function Panel:SetDrawLanguageID( visible ) end

--- [CLIENT AND MENU]
---
--- Sets where to draw the language selection box.
--- See [Panel:SetDrawLanguageID](https://wiki.facepunch.com/gmod/Panel:SetDrawLanguageID) for a
--- function that hides or shows the language selection box.
---
---@param left boolean true = left, false = right
function Panel:SetDrawLanguageIDAtLeft( left ) end

--- [CLIENT AND MENU]
---
--- Makes the panel render in front of all others, including the spawn menu and main menu.
--- Priority is given based on the last call, so of two panels that call this method, the second will
--- draw in front of the first.
---
--- > NOTE: This only makes the panel **draw** above other panels. If there's another panel that would
--- > have otherwise covered it, users will not be able to interact with it. Completely disregards
--- > [PANEL:ParentToHUD](https://wiki.facepunch.com/gmod/PANEL:ParentToHUD).
---
--- > WARNING: This does not work when using
--- > [PANEL:SetPaintedManually](https://wiki.facepunch.com/gmod/PANEL:SetPaintedManually) or
--- > [PANEL:PaintAt](https://wiki.facepunch.com/gmod/PANEL:PaintAt).
---
---@param draw_on_top boolean? Whether or not to draw the panel in front of all others. Defaults to `false`.
function Panel:SetDrawOnTop( draw_on_top ) end

--- [CLIENT AND MENU]
---
--- Sets the enabled state of a panel object that supports being disabled, such as a
--- [Button](https://wiki.facepunch.com/gmod/Button) or
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry).
--- Disabled panels cannot be interacted with, and have a different appearance to indicate this.
--- See [Panel:IsEnabled](https://wiki.facepunch.com/gmod/Panel:IsEnabled) for a function that retrieves
--- the "enabled" state of a panel.
---
---@param enable boolean Whether to enable or disable the panel object.
function Panel:SetEnabled( enable ) end

--- [CLIENT AND MENU]
---
--- Adds a shadow falling to the bottom right corner of the panel's text.
---
--- > NOTE: This works only on panels that derive from [Label](https://wiki.facepunch.com/gmod/Label).
---
---@param distance number The distance of the shadow from the panel.
---@param color garrysmod.Color The color of the shadow. Uses [Color](https://wiki.facepunch.com/gmod/Color).
function Panel:SetExpensiveShadow( distance, color ) end

--- [CLIENT AND MENU]
---
--- Sets the foreground color of the panel.
--- For labels, this is the color of their text.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param r number The red channel of the color.
---@param g number The green channel of the color.
---@param b number The blue channel of the color.
---@param a number The alpha channel of the color.
function Panel:SetFGColorEx( r, g, b, a ) end

--- [CLIENT AND MENU]
---
--- Sets the panel that owns this FocusNavGroup to be the root in the focus traversal hierarchy. This
--- function will only work on EditablePanel class panels and its derivatives.
---
--- > NOTE: Child panels that should be part of the tab navigation need
--- > [Panel:SetTabPosition](https://wiki.facepunch.com/gmod/Panel:SetTabPosition) called on them.
---
---@param state boolean
function Panel:SetFocusTopLevel( state ) end

--- [CLIENT AND MENU]
---
--- Enables or disables the keyboard input for the panel.
---
--- > DEPRECATED: Alias of
--- > [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
---
---@param keyboard_input boolean Whether to enable or disable keyboard input.
function Panel:SetKeyBoardInputEnabled( keyboard_input ) end

--- [CLIENT]
---
--- Allows or disallows the panel to receive keyboard focus and input. This is recursively applied to
--- all children.
---
---@param enable boolean Whether keyboard input should be enabled for this panel.
function Panel:SetKeyboardInputEnabled( enable ) end

--- [CLIENT AND MENU]
---
--- Sets the height of a single line of a [RichText](https://wiki.facepunch.com/gmod/RichText) panel.
---
---@param height number The new line height. Values below zero mean no override.
function Panel:SetLineHeight( height ) end

--- [CLIENT AND MENU]
---
--- Sets the maximum character count this panel should have.
--- This function will only work on [RichText](https://wiki.facepunch.com/gmod/RichText) and
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) panels and their derivatives.
---
---@param max_char number The new maximum amount of characters this panel is allowed to contain.
function Panel:SetMaximumCharCount( max_char ) end

--- [CLIENT AND MENU]
---
--- Sets the minimum dimensions of the panel or object.
--- You can restrict either or both values.
--- Calling the function without arguments will remove the minimum size.
---
---@param min_w number? The minimum width of the object. Defaults to `nil`.
---@param min_h number? The minimum height of the object. Defaults to `nil`.
function Panel:SetMinimumSize( min_w, min_h ) end

--- [CLIENT]
---
--- Sets the model to be displayed by [SpawnIcon](https://wiki.facepunch.com/gmod/SpawnIcon).
---
--- > NOTE: This must be called after setting size if you wish to use a different size spawnicon
---
---@param model_path string The path of the model to set
---@param skin number? The skin to set Defaults to `0`.
---@param bodygroups string? The body groups to set. Each single-digit number in the string represents a separate bodygroup, **This argument must be 9 characters in total**. Defaults to `nil`.
function Panel:SetModel( model_path, skin, bodygroups ) end

--- [CLIENT AND MENU]
---
--- Enables or disables the mouse input for the panel.
---
--- > NOTE: Panels parented to the context menu will not be clickable unless
--- > [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
--- > is enabled or [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup) has been called. If
--- > you want the panel to have mouse input but you do not want to prevent players from moving, set
--- > [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
--- > to false immediately after calling
--- > [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup).
---
---@param mouse_input boolean Whenever to enable or disable mouse input.
function Panel:SetMouseInputEnabled( mouse_input ) end

--- [CLIENT AND MENU]
---
--- Enables or disables the multi-line functionality of
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) panel and its derivatives.
---
---@param multiline boolean Whether to enable multiline or not.
function Panel:SetMultiline( multiline ) end

--- [CLIENT AND MENU]
---
--- Sets the internal name of the panel. Can be retrieved with
--- [Panel:GetName](https://wiki.facepunch.com/gmod/Panel:GetName).
---
---@param name string The new name of the panel.
function Panel:SetName( name ) end

--- [CLIENT AND MENU]
---
--- Sets whether the default background of the panel should be drawn or not. It's color is usually set
--- by [Panel:SetBGColor](https://wiki.facepunch.com/gmod/Panel:SetBGColor).
---
---@param paint_background boolean Whether to draw the background or not.
function Panel:SetPaintBackgroundEnabled( paint_background ) end

--- [CLIENT AND MENU]
---
--- Sets whether the default border of the panel should be drawn or not.
---
---@param paint_border boolean Whether to draw the border or not.
function Panel:SetPaintBorderEnabled( paint_border ) end

--- [CLIENT AND MENU]
---
--- Enables or disables painting of the panel manually with
--- [Panel:PaintManual](https://wiki.facepunch.com/gmod/Panel:PaintManual).
---
---@param painted_manually boolean True if the panel should be painted manually.
function Panel:SetPaintedManually( painted_manually ) end

--- [CLIENT AND MENU]
---
--- Sets the parent of the panel.
---
--- > NOTE: Panels parented to the context menu will not be clickable unless
--- > [Panel:SetMouseInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetMouseInputEnabled) and
--- > [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
--- > are both true or [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup) has been called.
--- > If you want the panel to have mouse input but you do not want to prevent players from moving, set
--- > [Panel:SetKeyboardInputEnabled](https://wiki.facepunch.com/gmod/Panel:SetKeyboardInputEnabled(lowercase))
--- > to false immediately after calling
--- > [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup).
---
---@param parent garrysmod.Panel The new parent of the panel.
function Panel:SetParent( parent ) end

--- [CLIENT]
---
--- Used by [AvatarImage](https://wiki.facepunch.com/gmod/AvatarImage) to load an avatar for given
--- player.
---
---@param player garrysmod.Player The player to use avatar of.
---@param size number? The size of the avatar to use. Acceptable sizes are `32`, `64`, `184`. Non matching sizes will be clamped down to the highest valid number. Defaults to `32`.
function Panel:SetPlayer( player, size ) end

--- [CLIENT AND MENU]
---
--- If this panel object has been made a popup with
--- [Panel:MakePopup](https://wiki.facepunch.com/gmod/Panel:MakePopup), this method will prevent it from
--- drawing in front of other panels when it receives input focus.
---
---@param stay_at_back boolean If `true`, the popup panel will not draw in front of others when it gets focus, for example when it is clicked.
function Panel:SetPopupStayAtBack( stay_at_back ) end

--- [CLIENT AND MENU]
---
--- Sets the position of the panel's top left corner.
--- This will trigger [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout). You
--- should avoid calling this function in
--- [PANEL:PerformLayout](https://wiki.facepunch.com/gmod/PANEL:PerformLayout) to avoid infinite loops.
--- See also [Panel:SetX](https://wiki.facepunch.com/gmod/Panel:SetX) and
--- [Panel:SetY](https://wiki.facepunch.com/gmod/Panel:SetY).
---
--- > NOTE: If you wish to position and re-size panels without much guesswork and have them look good on
--- > different screen resolutions, you may find [Panel:Dock](https://wiki.facepunch.com/gmod/Panel:Dock)
--- > useful
---
---@param pos_x number The x coordinate of the position.
---@param pos_y number The y coordinate of the position.
function Panel:SetPos( pos_x, pos_y ) end

--- [CLIENT AND MENU]
---
--- Sets whenever the panel should be rendered in a screenshot. (`jpeg` or `screenshot` commands, Camera
--- SWEP)
---
---@param render_in_screenshot boolean Whether to render in the screenshot or not.
function Panel:SetRenderInScreenshots( render_in_screenshot ) end

--- [CLIENT AND MENU]
---
--- Sets the size of the panel.
--- Calls [PANEL:OnSizeChanged](https://wiki.facepunch.com/gmod/PANEL:OnSizeChanged) and marks this
--- panel for layout ([Panel:InvalidateLayout](https://wiki.facepunch.com/gmod/Panel:InvalidateLayout)).
--- Automatically rounds the width and height down
--- See also [Panel:SetWidth](https://wiki.facepunch.com/gmod/Panel:SetWidth) and
--- [Panel:SetHeight](https://wiki.facepunch.com/gmod/Panel:SetHeight).
---
--- > NOTE: If you wish to position and re-size panels without much guesswork and have them look good on
--- > different screen resolutions, you may find [Panel:Dock](https://wiki.facepunch.com/gmod/Panel:Dock)
--- > useful
---
---@param width number The width of the panel.
---@param height number The height of the panel.
function Panel:SetSize( width, height ) end

--- [CLIENT]
---
--- Sets the `.png` image to be displayed on a [SpawnIcon](https://wiki.facepunch.com/gmod/SpawnIcon) or
--- the panel it is based on - [ModelImage](https://wiki.facepunch.com/gmod/ModelImage).
--- Only `.png` images can be used with this function.
---
---@param icon string A path to the .png material, for example one of the [Silkicons](https://wiki.facepunch.com/gmod/Silkicons) shipped with the game.
function Panel:SetSpawnIcon( icon ) end

--- [CLIENT]
---
--- Used by [AvatarImage](https://wiki.facepunch.com/gmod/AvatarImage) panels to load an avatar by its
--- 64-bit Steam ID (community ID).
---
---@param steamid string The 64bit SteamID of the player to load avatar of
---@param size number The size of the avatar to use. Acceptable sizes are 32, 64, 184.
function Panel:SetSteamID( steamid, size ) end

--- [CLIENT AND MENU]
---
--- When TAB is pressed, the next selectable panel in the number sequence is selected.
---
--- > NOTE: This function requires
--- > [Panel:SetFocusTopLevel](https://wiki.facepunch.com/gmod/Panel:SetFocusTopLevel) to be called on the
--- > parent panel for tab navigation to work.
---
---@param position number
function Panel:SetTabPosition( position ) end

--- [CLIENT AND MENU]
---
--- Sets height of a panel. An alias of
--- [Panel:SetHeight](https://wiki.facepunch.com/gmod/Panel:SetHeight).
---
---@param height number Desired height to set
function Panel:SetTall( height ) end

--- [CLIENT AND MENU]
---
--- Sets the text value of a panel object containing text, such as a
--- [Label](https://wiki.facepunch.com/gmod/Label),
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) or
--- [RichText](https://wiki.facepunch.com/gmod/RichText) and their derivatives, such as
--- [Label](https://wiki.facepunch.com/gmod/Label),
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry) or
--- [Button](https://wiki.facepunch.com/gmod/Button).
---
--- > WARNING: When used on a [Label](https://wiki.facepunch.com/gmod/Label) or its derivatives (
--- > [Label](https://wiki.facepunch.com/gmod/Label) and
--- > [Button](https://wiki.facepunch.com/gmod/Button) ), it will automatically call
--- > [Panel:InvalidateLayout](https://wiki.facepunch.com/gmod/Panel:InvalidateLayout), meaning that you
--- > should avoid running this function every frame on these panels to avoid unnecessary performance
--- > loss.
---
--- > WARNING: [Label](https://wiki.facepunch.com/gmod/Label) & its derivatives has hard length limit,
--- > maximum 1023 ascii characters.
---
---@param text string The text value to set.
function Panel:SetText( text ) end

--- [CLIENT AND MENU]
---
--- Makes [TextEntry](https://wiki.facepunch.com/gmod/TextEntry)'s text be replaced by `*` characters,
--- just like a password-entry text field would.
---
---@param arg boolean Whether to have the text be hidden.
function Panel:SetTextHidden( arg ) end

--- [CLIENT AND MENU]
---
--- Sets the left and top text margins of a text-based panel object, such as a
--- [Button](https://wiki.facepunch.com/gmod/Button) or
--- [Label](https://wiki.facepunch.com/gmod/Label).
---
---@param inset_x number The left margin for the text, in pixels. This will only affect centered text if the margin is greater than its x-coordinate.
---@param inset_y number The top margin for the text, in pixels.
function Panel:SetTextInset( inset_x, inset_y ) end

--- [CLIENT AND MENU]
---
--- Sets text selection colors of a [RichText](https://wiki.facepunch.com/gmod/RichText) element.
---
---@param text_color garrysmod.Color The [Color](https://wiki.facepunch.com/gmod/Color) to set for selected text.
---@param background_color garrysmod.Color The [Color](https://wiki.facepunch.com/gmod/Color) to set for selected text background.
function Panel:SetTextSelectionColors( text_color, background_color ) end

--- [CLIENT AND MENU]
---
--- Sets the height of a [RichText](https://wiki.facepunch.com/gmod/RichText) element to accommodate the
--- text inside.
---
--- > NOTE: This function internally relies on
--- > [Panel:GetNumLines](https://wiki.facepunch.com/gmod/Panel:GetNumLines), so it should be called at
--- > least a couple frames after modifying the text using
--- > [Panel:AppendText](https://wiki.facepunch.com/gmod/Panel:AppendText)
---
function Panel:SetToFullHeight() end

--- [CLIENT AND MENU]
---
--- Sets the URL of a link-based panel.
---
---@param url string The URL to set. It **must** begin with either `http://` or `https://`.
function Panel:SetURL( url ) end

--- [CLIENT AND MENU]
---
--- Sets the underlined font for use by clickable text in a
--- [RichText](https://wiki.facepunch.com/gmod/RichText). See also
--- [Panel:InsertClickableTextStart](https://wiki.facepunch.com/gmod/Panel:InsertClickableTextStart)
--- This function will only work on [RichText](https://wiki.facepunch.com/gmod/RichText) panels.
---
---@param font_name string The name of the font.
--- See [here](https://wiki.facepunch.com/gmod/Default_Fonts) for a list of existing fonts.
--- Alternatively, use [surface.CreateFont](https://wiki.facepunch.com/gmod/surface.CreateFont) to create your own custom font.
function Panel:SetUnderlineFont( font_name ) end

--- [CLIENT AND MENU]
---
--- Sets the visibility of the vertical scrollbar.
--- Works for [RichText](https://wiki.facepunch.com/gmod/RichText) and
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry).
---
---@param display boolean? True to display the vertical text scroll bar, false to hide it. Defaults to `false`.
function Panel:SetVerticalScrollbarEnabled( display ) end

--- [CLIENT AND MENU]
---
--- Sets the "visibility" of the panel.
---
---@param visible boolean The visibility of the panel.
function Panel:SetVisible( visible ) end

--- [CLIENT AND MENU]
---
--- Sets width of a panel. An alias of [Panel:SetWidth](https://wiki.facepunch.com/gmod/Panel:SetWidth).
---
---@param width number Desired width to set
function Panel:SetWide( width ) end

--- [CLIENT AND MENU]
---
--- This makes it so that when you're hovering over this panel you can "click" on the world. Your weapon
--- aim (and its viewmodel) will follow the cursor. This is primarily used for the Sandbox context menu.
---
---@param enable boolean Whether to enable or disable the feature for this panel.
function Panel:SetWorldClicker( enable ) end

--- [CLIENT AND MENU]
---
--- Sets whether text wrapping should be enabled or disabled on
--- [Label](https://wiki.facepunch.com/gmod/Label) panels.
---
--- Use a vertical auto-stretch approach to automatically correct vertical size;
--- [Panel:SizeToContents](https://wiki.facepunch.com/gmod/Panel:SizeToContents) will not set the
--- correct height.
---
---@param wrap boolean `True` to enable text wrapping, `false` otherwise.
function Panel:SetWrap( wrap ) end

--- [CLIENT AND MENU]
---
--- Sets the panels z position which determines the rendering order.
--- Panels with lower z positions appear behind panels with higher z positions.
--- This also controls in which order panels docked with
--- [Panel:Dock](https://wiki.facepunch.com/gmod/Panel:Dock) appears.
---
---@param z_index number The z position of the panel.
--- Can't be lower than -32768 or higher than 32767.
function Panel:SetZPos( z_index ) end

--- [CLIENT AND MENU]
---
--- Resizes the panel to fit the bounds of its children.
---
--- > NOTE: Your panel must have its layout updated
--- > ([Panel:InvalidateLayout](https://wiki.facepunch.com/gmod/Panel:InvalidateLayout)) for this function
--- > to work properly.
---
--- > NOTE: The sizeW and sizeH parameters are false by default. Therefore, calling this function with
--- > no arguments will result in a no-op.
---
---@param size_w boolean? Resize with width of the panel. Defaults to `false`.
---@param size_h boolean? Resize the height of the panel. Defaults to `false`.
function Panel:SizeToChildren( size_w, size_h ) end

--- [CLIENT AND MENU]
---
--- Resizes the panel so that its width and height fit all of the content inside.
---
--- > NOTE: Only works on [Label](https://wiki.facepunch.com/gmod/Label) derived panels such as
--- > [Label](https://wiki.facepunch.com/gmod/Label) by default, and on any panel that manually
--- > implemented the [Panel:SizeToContents](https://wiki.facepunch.com/gmod/Panel:SizeToContents) method,
--- > such as panel and
--- > [Image](https://wiki.facepunch.com/gmod/Image).
---
--- > WARNING: You must call this function **AFTER** setting text/font, adjusting child panels or
--- > otherwise altering the panel.
---
function Panel:SizeToContents() end

--- [CLIENT AND MENU]
---
--- Restores the last saved state (caret position and the text inside) of a
--- [TextEntry](https://wiki.facepunch.com/gmod/TextEntry). Should act identically to pressing CTRL+Z in
--- a [TextEntry](https://wiki.facepunch.com/gmod/TextEntry).
--- See also [Panel:SaveUndoState](https://wiki.facepunch.com/gmod/Panel:SaveUndoState).
---
function Panel:Undo() end

--- [CLIENT AND MENU]
---
--- Returns if a given panel is valid or not.
---
--- > DEPRECATED: Use [Panel:IsValid](https://wiki.facepunch.com/gmod/Panel:IsValid) instead.
---
---@return boolean value Whether the panel is valid or not, true being it is, false being it isn't.
function Panel:Valid() end

--- [CLIENT AND MENU]
---
--- The HTML control can be used to display web pages just like an internet browser.
---
--- For more information on Garry's Mod's web rendering, see
--- [HTML Web Engine](https://wiki.facepunch.com/gmod/HTML_Web_Engine) (Chromium Embedded Framework /
--- Awesomium).
---
--- Related panel classnames: [HTML](https://wiki.facepunch.com/gmod/HTML),
--- [Awesomium](https://wiki.facepunch.com/gmod/Awesomium) (deprecated alias of `HTML`), and `Chromium`
--- (CEF panel, same engine API as `HTML`).
---
--- Derives methods not listed here from [Panel](https://wiki.facepunch.com/gmod/Panel).
---
--- ## Blocked URL extensions
---
--- The URL cannot end in any of these extensions, e.g. `http://yourdomain.com/garry.exe`:
---
--- * `.exe`
--- * `.bat`
--- * `.dll`
--- * `.zip`
--- * `.mp3`
--- * `.swf`
---
---@class garrysmod.HTML : garrysmod.Panel
local HTML = {}

--- [CLIENT AND MENU]
---
--- Deprecated alias of [HTML](https://wiki.facepunch.com/gmod/HTML). Base panel for elements using the
--- Awesomium UI engine.
---
--- > **DEPRECATED**: You should be using [HTML](https://wiki.facepunch.com/gmod/HTML), which this is an
--- > alias of.
---
--- > **NOTE**: On the `x86-64` beta this panel isn't actually Awesomium, it's the same as `HTML`
--- > (`HtmlPanel`).
---
---@class garrysmod.Awesomium : garrysmod.HTML

--- [CLIENT AND MENU]
---
--- Chromium Embedded Framework (CEF) HTML panel classname (`"Chromium"`). Shares the same engine API as
--- [HTML](https://wiki.facepunch.com/gmod/HTML).
---
--- See [HTML Web Engine](https://wiki.facepunch.com/gmod/HTML_Web_Engine).
---
---@class garrysmod.Chromium : garrysmod.HTML

--- [CLIENT AND MENU]
---
--- Used to run commands within an HTML window.
---
--- > INTERNAL: This is used internally - although you're able to use it you probably shouldn't.
---
---@param cmd string The command to be run.
function HTML:Exec( cmd ) end

--- [CLIENT]
---
--- Returns the panel's HTML material. Only works with
--- [HTML](https://wiki.facepunch.com/gmod/HTML), `Chromium`, and
--- [Awesomium](https://wiki.facepunch.com/gmod/Awesomium) panels that have been fully loaded.
---
---@return garrysmod.Material value The HTML material used by the panel. Typically starts with `__vgui_texture_` followed by an incremental number.
function HTML:GetHTMLMaterial() end

--- [CLIENT AND MENU]
---
--- Goes back one page in the HTML panel's history if available.
---
function HTML:GoBack() end

--- [CLIENT AND MENU]
---
--- Goes forward one page in the HTML panel's history if available.
---
function HTML:GoForward() end

--- [CLIENT AND MENU]
---
--- Goes to the page in the HTML panel's history at the specified relative offset.
---
---@param offset number The offset in the panel's back/forward history, relative to the current page, that you would like to skip to. Because this is relative, 0 = current page while negative goes back and positive goes forward. For example, -2 will go back 2 pages in the history.
function HTML:GoToHistoryOffset( offset ) end

--- [CLIENT AND MENU]
---
--- Determines whether or not an [HTML](https://wiki.facepunch.com/gmod/HTML), `Chromium`, or
--- [Awesomium](https://wiki.facepunch.com/gmod/Awesomium) element is currently loading a page.
---
--- > NOTE: Before calling [HTML:SetHTML](https://wiki.facepunch.com/gmod/Panel:SetHTML) or
--- > [HTML:OpenURL](https://wiki.facepunch.com/gmod/Panel:OpenURL), the result seems to be `false` with
--- > the Awesomium web renderer and `true` for the Chromium web renderer. This difference can be used to
--- > determine the available HTML5 capabilities.
---
--- > NOTE: On Awesomium, the result remains `true` until the root document is loaded and when in-page
--- > content is loading (when adding pictures, frames, etc.). During this state, the HTML texture is not
--- > refreshed and the panel is not painted (it becomes invisible). On Chromium, the value is only
--- > `true` when the root document is not ready. The rendering is not suspended when in-page elements are
--- > loading.
---
---@return boolean value Whether or not the HTML / Chromium object is loading.
function HTML:IsLoading() end

--- [CLIENT AND MENU]
---
--- Instructs a HTML control to download and parse a HTML script using the passed URL.
---
--- This function can only be used on [HTML](https://wiki.facepunch.com/gmod/HTML), `Chromium`, and
--- [Awesomium](https://wiki.facepunch.com/gmod/Awesomium) panels and their derivatives.
---
---@param url string URL to open. It has to start or be one of the following:
--- * `http://`
--- * `https://`
--- * `asset://`
--- * `about:blank`
--- * `chrome://credits/`
function HTML:OpenURL( url ) end

--- [CLIENT AND MENU]
---
--- Refreshes the HTML panel's current page.
---
---@param ignore_cache boolean? If true, the refresh will ignore cached content similar to "ctrl+f5" in most browsers. Defaults to `false`.
function HTML:Refresh( ignore_cache ) end

--- [CLIENT AND MENU]
---
--- Executes a string as JavaScript code on a web document panel.
---
--- > NOTE: This function does **NOT** allow you to pass variables from JavaScript (JS) to Lua context.
--- > If you wish to pass/return values from JS to Lua, you need a separate JS↔Lua bridge.
---
--- > NOTE: The Awesomium web renderer automatically delays the code execution if the document is not
--- > ready, but the Chromium web renderer does not! This means that with Chromium, you cannot
--- > JavaScript run code immediatly after calling
--- > [HTML:SetHTML](https://wiki.facepunch.com/gmod/Panel:SetHTML) or
--- > [HTML:OpenURL](https://wiki.facepunch.com/gmod/Panel:OpenURL). You should wait for the events
--- > [HTML:OnDocumentReady](https://wiki.facepunch.com/gmod/HTML:OnDocumentReady) or
--- > [HTML:OnFinishLoadingDocument](https://wiki.facepunch.com/gmod/HTML:OnFinishLoadingDocument) to be
--- > triggered before proceeding, otherwise you may manipulate an empty / incomplete document.
---
---@param js string Specify JavaScript code to be executed.
function HTML:RunJavascript( js ) end

--- [CLIENT AND MENU]
---
--- Allows you to set HTML code within a panel.
---
---@param html string The HTML code to set.
function HTML:SetHTML( html ) end

--- [MENU]
---
--- Set to true to open links in an external browser. This only functions on the `x86-64` beta.
---
---@param open_externally boolean
function HTML:SetOpenLinksExternally( open_externally ) end

--- [CLIENT AND MENU]
---
--- Stops the loading of the [HTML](https://wiki.facepunch.com/gmod/HTML) / `Chromium` /
--- [Awesomium](https://wiki.facepunch.com/gmod/Awesomium) panel's current page.
---
function HTML:StopLoading() end

--- [CLIENT AND MENU]
---
--- Forcibly updates the panels' HTML Material, similar to when Paint is called on it.
--- This is only useful if the panel is not normally visible, i.e the panel exists purely for its HTML
--- Material.
---
--- > NOTE: Only works on with panels that have a HTML Material. See
--- > [HTML:GetHTMLMaterial](https://wiki.facepunch.com/gmod/Panel:GetHTMLMaterial) for more details.
---
--- > NOTE: A good place to call this is in the
--- > [GM:PreRender](https://wiki.facepunch.com/gmod/GM:PreRender) hook
---
function HTML:UpdateHTMLTexture() end

--- [CLIENT AND MENU]
---
--- Called when the page inside the HTML window runs the `console.log` javascript function.
---
--- On the x86-64 beta, it's called for all built-in `console.*` javascript functions.
---
--- Overwriting this function in any way will disable default behavior of printing the message to the
--- in-game console.
---
---@param msg string The message to be logged (or Lua code to be executed; see above).
---@param file string The message source file, if any.
---@param line_nr number The line number in the file the message was output from.
---@param severity string The severity of the message. Possible values are: `"log"`, `"warn"`, `"error"`, `"debug"`.
function HTML:ConsoleMessage( msg, file, line_nr, severity ) end

--- [CLIENT]
---
--- Called when this panel begins loading a page.
---
---@param url string The URL of the current page.
function HTML:OnBeginLoadingDocument( url ) end

--- [CLIENT]
---
--- Called by the engine when a callback function is called.
---
---@param library string Library name of the JS function that was called.
---@param name string Name of the JS function that was called.
---@param arguments table Table containing all arguments passed to the JS function.
---@return boolean suppress Return `true` to suppress default engine action.
function HTML:OnCallback( library, name, arguments ) end

--- [CLIENT]
---
--- Called when this panel's address changes.
---
---@param url string The URL of the new page.
function HTML:OnChangeAddressBar( url ) end

--- [CLIENT]
---
--- Called by HTML panels when the target URL of the frame has changed, this happens when you hover over
--- a link.
---
---@param url string New target URL.
function HTML:OnChangeTargetURL( url ) end

--- [CLIENT]
---
--- Called by HTML panels when the title of the loaded page has been changed.
---
---@param new_title string The new title of the page.
function HTML:OnChangeTitle( new_title ) end

--- [CLIENT]
---
--- Called by HTML panels when the page attempts to open a new child view (such as a popup or new tab).
---
---@param source_url string The URL of the page requesting to create a child.
---@param target_url string The URL of the requested child.
---@param is_popup boolean `true` if the requested view is a popup.
function HTML:OnChildViewCreated( source_url, target_url, is_popup ) end

--- [CLIENT]
---
--- Called by HTML panels when the panel's DOM has been set up. You can run JavaScript in here.
---
---@param url string The URL of the current page.
function HTML:OnDocumentReady( url ) end

--- [CLIENT]
---
--- Called when this panel successfully loads a page.
---
---@param url string The URL of the current page.
function HTML:OnFinishLoadingDocument( url ) end
