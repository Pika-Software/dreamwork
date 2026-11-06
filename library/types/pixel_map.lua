---@meta _

--- [CLIENT AND MENU]
---
--- Display length abbreviations resolved by `PixelMap` into floored CSS pixels.
---
--- Viewport units (`vmin`, `vw`, …) track `window` size. Absolute lengths
--- (`cm`, `pt`, …) use the CSS 96 DPI reference, not live DPI.
---
--- For non-display unit conversion (mass, temperature, …) use `unit`.
---
---@alias PixelUnit
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
--- A named map of CSS / viewport length descriptors that resolve to floored
--- pixels and refresh when the window is resized.
---
--- Indexing a registered alias (`sizes.hex`) returns the cached integer pixel
--- length. Unknown keys fall through to the class prototype.
---
--- Handlers attached with `:attach` / `:once` run after the shared pixel cache
--- is recomputed on `OnScreenSizeChanged`.
---
--- Construction raises `ValueError` if any descriptor cannot be parsed.
---
--- ```lua
--- local sizes = PixelMap( {
---     hex = "1vmin",
---     t = "2vmin",
---     h = "10cm",
---     me = "12mm",
---     d = "120px"
--- } )
---
--- print( sizes.hex ) -- floored pixels for "1vmin"
---
--- sizes:attach( function( map, old_width, old_height, new_width, new_height )
---     print( map.hex ) -- refreshed after resize
--- end )
--- ```
---
---@class PixelMap : Object
---@field __class PixelMapClass The class used to construct this object.
local __PixelMap = {}

--- Builds the alias table and seeds `pixel_cache` for each descriptor.
---
---@param definitions table<string, string> Alias name -> length quantity string (`"<number><PixelUnit>"`).
---@protected
function __PixelMap:__init(definitions) end

--- Resolves a registered alias to floored pixels, or falls back to the prototype.
---
---@param key string The alias name, or a prototype field / method name.
---@return integer | any value Floored pixels for a known alias; otherwise the prototype value.
---@protected
function __PixelMap:__index(key) end

--- [CLIENT AND MENU]
---
--- Attaches a handler that runs after this map's pixel values are refreshed
--- on screen resize.
---
--- Attaching the same handler twice is a no-op, handlers run in protected mode.
---
---@param handler fun( map: PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The callback or callable object.
function __PixelMap:attach(handler) end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot resize handler that detaches itself before running.
---
---@param handler fun( map: PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The callback or callable object.
function __PixelMap:once(handler) end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached resize handler.
---
---@param handler fun( map: PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __PixelMap:detach(handler) end

--- [CLIENT AND MENU]
---
--- Removes every resize handler attached to this map.
---
function __PixelMap:clear() end

--- [CLIENT AND MENU]
---
--- Waits for the next screen-size refresh of this map.
---
---@return PixelMap map
---@return integer old_width
---@return integer old_height
---@return integer new_width
---@return integer new_height
---@async
function __PixelMap:await() end

--- [CLIENT AND MENU]
---
--- The class used to create `PixelMap` instances and parse display lengths.
---
---@class PixelMapClass : PixelMap, Class
---@field __base PixelMap The instance prototype shared by all `PixelMap` objects.
---@overload fun( definitions: table<string, string> ): table<string, integer>
PixelMap = {}

--- [CLIENT AND MENU]
---
--- Parses a display length string into floored CSS pixels.
---
--- Raises `ValueError` with `"missing magnitude"`, `"missing unit type"`, or
--- `"unsupported unit"` when the descriptor cannot be parsed.
---
--- ```lua
--- PixelMap.parse( "120px" ) -- 120
--- PixelMap.parse( "10cm" )  -- floored CSS pixels at 96 DPI
--- PixelMap.parse( "1vmin" ) -- floored pixels from current window size
--- ```
---
---@param descriptor string The length quantity string to parse (`"<number><PixelUnit>"`).
---@return integer pixels The floored pixel length.
---@nodiscard
function PixelMap.parse(descriptor) end
