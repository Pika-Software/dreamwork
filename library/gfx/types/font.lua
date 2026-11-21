---@meta _

--- [CLIENT AND MENU]
---
--- An engine font whose size is a display length (`"2vmin"`, `"12pt"`, `"16px"`, …)
--- resolved by `ViewportLayout.parse` and recreated when the window is resized.
---
--- Every font parameter is a field, writing one recreates the engine font right away,
--- so each write costs a `surface.CreateFont` call.
---
--- `size` is the length descriptor, `size_px` is its resolved size. Writing `size_px`
--- overrides the size until the next screen size change, which re-resolves `size`.
---
--- Fonts created by a package get its id as the prefix, `{id}::{name}`. and stop being rebuilt when it unloads.
---
--- Creating a font with an already used name replaces the previous owner,
--- the old object stops being rebuilt but keeps the name. Writing a field
--- of the old object makes it the owner again.
---
--- Construction and `size` writes raise `ValueError` if the descriptor cannot be parsed.
---
--- ```lua
--- local title = Font( "my_addon.title", {
---     font = "Roboto",
---     size = "3vmin",
---     weight = 700
--- } )
---
--- print( title.size_px ) -- floored pixels for "3vmin"
---
--- title.weight = 800 -- recreated with the new weight
--- title.size_px = 32 -- 32px until the next screen size change
--- title.size = "4vmin" -- recreated from the new descriptor
--- ```
---
---@class Font : Object
---@field __class FontClass The class used to construct this object.
---@field name string The engine font name, usable with `surface.SetFont`, `draw.SimpleText`, panels, etc. Read-only.
---@field size string The size as a length quantity string (`"<number><ViewportUnit>"`).
---@field size_px integer The current size in pixels, writes last until the next screen size change.
---@field font string The font source, a font name or a `.ttf` file name in `resource/fonts`.
---@field weight integer The font boldness.
---@field blursize integer The strength of the font blurring, must be > 0 to apply.
---@field scanlines integer The "scanline" interval, must be > 1 to apply.
---@field extended boolean Allows characters outside of Latin-1.
---@field antialias boolean Smooths the font.
---@field underline boolean Adds an underline.
---@field italic boolean Makes the font italic.
---@field strikeout boolean Adds a strike through.
---@field symbol boolean Enables the use of symbolic fonts such as Webdings.
---@field rotary boolean Seems to add a line in the middle of each letter.
---@field shadow boolean Adds shadow casting to the font.
---@field additive boolean Additive rendering.
---@field outline boolean Adds a black outline.
local __Font = {}

---@param options Font.Options
---@protected
function __Font:__init(options) end

---@param key string The field name being read.
---@return any value
---@protected
function __Font:__index(key) end

---@param key string
---@param value any
---@protected
function __Font:__newindex(key, value) end

--- [CLIENT AND MENU]
---
--- The class used to create `Font` instances.
---
---@class FontClass : Font, Class
---@field __base Font The instance prototype shared by all `Font` objects.
---@overload fun( options: Font.Options ): Font
Font = {}
