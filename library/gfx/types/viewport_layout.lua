---@meta _

--- [CLIENT AND MENU]
---
--- Display length abbreviations resolved by `ViewportLayout` into floored CSS pixels.
---
--- Viewport units (`vmin`, `vw`, …) track `window` size. Absolute lengths
--- (`cm`, `pt`, …) use the CSS 96 DPI reference, not live DPI.
---
--- For non-display unit conversion (mass, temperature, …) use `unit`.
---
---@alias ViewportUnit
---| "px" # Absolute pixels (identity).
---| "vmin" # `1%` of `min(window.width, window.height)`.
---| "vmax" # `1%` of `max(window.width, window.height)`.
---| "vw" # `1%` of `window.width`.
---| "vh" # `1%` of `window.height`.
---| "pw" # Alias of `vw`.
---| "ph" # Alias of `vh`.
---| "p" # Mean of `1%` width and `1%` height (`(width + height) * 0.005`).
---| "pmin" # Alias of `vmin`.
---| "pmax" # Alias of `vmax`.
---| "cm" # Centimeters at 96 DPI (`96 / 2.54` px).
---| "mm" # Millimeters at 96 DPI (`96 / 25.4` px).
---| "in" # Inches at 96 DPI (`96` px).
---| "pc" # Picas at 96 DPI (`16` px; `1/6` in).
---| "pt" # Points at 96 DPI (`96 / 72` px; `1/72` in).
---| "q" # Quarter-millimeters at 96 DPI (`96 / 101.6` px).

--- [CLIENT AND MENU]
---
--- A named set of CSS / viewport length descriptors that resolve to floored
--- pixels and refresh when the window is resized.
---
--- Indexing a registered alias (`hud.hex`) returns the cached integer pixel
--- length. Unknown keys fall through to the class prototype.
---
--- Handlers attached with `:attach` / `:once` run after the shared pixel cache
--- is recomputed on `OnScreenSizeChanged`.
---
--- Construction raises `ValueError` if any descriptor cannot be parsed.
---
--- ```lua
--- local hud = ViewportLayout( {
---     hex = "1vmin",
---     t = "2vmin",
---     h = "10cm",
---     me = "12mm",
---     d = "120px"
--- } )
---
--- print( hud.hex ) -- floored pixels for "1vmin"
---
--- hud:attach( function( layout, old_width, old_height, new_width, new_height )
---     print( layout.hex ) -- refreshed after resize
--- end )
--- ```
---
---@class ViewportLayout : Object
---@field __class ViewportLayoutClass The class used to construct this object.
local __ViewportLayout = {}

--- Builds the alias table and seeds `pixel_cache` for each descriptor.
---
---@param definitions table<string, string> Alias name -> length quantity string (`"<number><ViewportUnit>"`).
---@protected
function __ViewportLayout:__init(definitions) end

--- Resolves a registered alias to floored pixels, or falls back to the prototype.
---
---@param key string The alias name, or a prototype field / method name.
---@return integer | any value Floored pixels for a known alias; otherwise the prototype value.
---@protected
function __ViewportLayout:__index(key) end

--- [CLIENT AND MENU]
---
--- Attaches a handler that runs after this layout's pixel values are refreshed
--- on screen resize.
---
--- Attaching the same handler twice is a no-op, handlers run in protected mode.
---
---@param handler fun( layout: ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The callback or callable object.
function __ViewportLayout:attach(handler) end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot resize handler that detaches itself before running.
---
---@param handler fun( layout: ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The callback or callable object.
function __ViewportLayout:once(handler) end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached resize handler.
---
---@param handler fun( layout: ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __ViewportLayout:detach(handler) end

--- [CLIENT AND MENU]
---
--- Removes every resize handler attached to this layout.
---
function __ViewportLayout:clear() end

--- [CLIENT AND MENU]
---
--- Waits for the next screen-size refresh of this layout.
---
---@return ViewportLayout layout
---@return integer old_width
---@return integer old_height
---@return integer new_width
---@return integer new_height
---@async
function __ViewportLayout:await() end

--- [CLIENT AND MENU]
---
--- The class used to create `ViewportLayout` instances and parse display lengths.
---
---@class ViewportLayoutClass : ViewportLayout, Class
---@field __base ViewportLayout The instance prototype shared by all `ViewportLayout` objects.
---@overload fun( definitions: table<string, string> ): table<string, integer>
ViewportLayout = {}

--- [CLIENT AND MENU]
---
--- Parses a display length string into floored CSS pixels.
---
--- Raises `ValueError` with `"missing magnitude"`, `"missing unit type"`, or
--- `"unsupported unit"` when the descriptor cannot be parsed.
---
--- ```lua
--- ViewportLayout.parse( "120px" ) -- 120
--- ViewportLayout.parse( "10cm" )  -- floored CSS pixels at 96 DPI
--- ViewportLayout.parse( "1vmin" ) -- floored pixels from current window size
--- ```
---
---@param descriptor string The length quantity string to parse (`"<number><ViewportUnit>"`).
---@return integer pixels The floored pixel length.
---@nodiscard
function ViewportLayout.parse(descriptor) end
