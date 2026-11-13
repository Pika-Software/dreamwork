local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local math = std.math
local math_floor = math.floor
local math_min, math_max = math.min, math.max

local string = std.string
local string_match = string.match

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local class = std.class

local window = std.window

local error = std.error

local ValueError = std.ValueError
local Emitter = std.Emitter
local Future = std.Future


--- [CLIENT AND MENU]
---
--- Display length abbreviations resolved by `ViewportLayout` into floored CSS pixels.
---
--- Viewport units (`vmin`, `vw`, …) track `window` size. Absolute lengths
--- (`cm`, `pt`, …) use the CSS 96 DPI reference, not live DPI.
---
--- For non-display unit conversion (mass, temperature, …) use `unit`.
---
---@alias dreamwork.std.ViewportUnit
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

--- Resolvers from magnitude to CSS pixels (before flooring).
---
---@type table<dreamwork.std.ViewportUnit, fun( value: number ): number>
local display_units = {
    px = function( value )
        return value
    end,

    vmin = function( value )
        return math_min( window.width, window.height ) * 0.01 * value
    end,

    vmax = function( value )
        return math_max( window.width, window.height ) * 0.01 * value
    end,

    vw = function( value )
        return window.width * 0.01 * value
    end,

    vh = function( value )
        return window.height * 0.01 * value
    end,

    pw = function( value )
        return window.width * 0.01 * value
    end,

    ph = function( value )
        return window.height * 0.01 * value
    end,

    p = function( value )
        return (window.width + window.height) * 0.005 * value
    end,

    cm = function( value )
        return value * (96 / 2.54)
    end,

    mm = function( value )
        return value * (96 / 25.4)
    end,

    [ "in" ] = function( value )
        return value * 96
    end,

    pc = function( value )
        return value * 16
    end,

    pt = function( value )
        return value * (96 / 72)
    end,

    q = function( value )
        return value * (96 / 101.6)
    end
}

display_units.pmin = display_units.vmin
display_units.pmax = display_units.vmax

--- Resolves a display length string to floored CSS pixels.
---
--- On failure returns `0` and one of `"missing magnitude"`, `"missing unit type"`,
--- or `"unsupported unit"`.
---
---@param descriptor string The length quantity string (`"<number><ViewportUnit>"`).
---@return integer pixels The floored pixel length (`0` when `error_message` is set).
---@return string | nil error_message `nil` on success, otherwise a short failure reason.
local function descriptor_to_pixels( descriptor )
    local magnitude_str, unit_type = string_match( descriptor, "^([%+%-]?%d*%.?%d+)(.*)$" )
    if magnitude_str == nil then
        return 0, "missing magnitude"
    end

    if unit_type == nil or unit_type == "" then
        return 0, "missing unit type"
    end

    local resolver = display_units[ unit_type ]
    if resolver == nil then
        return 0, "unsupported unit"
    end

    return math_floor( resolver( raw_tonumber( magnitude_str, 10 ) or 0 ) ), nil
end

--- Shared cache of quantity descriptor -> floored CSS pixels.
---
--- Entries are recomputed on `OnScreenSizeChanged` so viewport units stay current.
---
---@type table<string, integer>
local pixel_cache = {}

--- Weak keys: each `ViewportLayout` -> its alias name -> original descriptor string.
---
---@type table<dreamwork.std.ViewportLayout, table<string, string>>
local layout_aliases = {}
gc_setTableRules( layout_aliases, true, false )

--- ViewportLayout `"resize"` handlers.
local events = Emitter( "ViewportLayout" )

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
---@class dreamwork.std.ViewportLayout : dreamwork.std.Object
---@field __class dreamwork.std.ViewportLayoutClass The class used to construct this object.
local ViewportLayout = class.base( "ViewportLayout", true )

--- Builds the alias table and seeds `pixel_cache` for each descriptor.
---
---@param definitions table<string, string> Alias name -> length quantity string (`"<number><ViewportUnit>"`).
---@protected
function ViewportLayout:__init( definitions )
    local aliases = {}
    layout_aliases[ self ] = aliases

    for alias, descriptor in raw_pairs( definitions ) do
        local pixels, error_message = descriptor_to_pixels( descriptor )
        if error_message ~= nil then
            error( ValueError( descriptor, error_message ), 2 )
        end

        aliases[ alias ] = descriptor
        pixel_cache[ descriptor ] = pixels
    end
end

--- Resolves a registered alias to floored pixels, or falls back to the prototype.
---
---@param key string The alias name, or a prototype field / method name.
---@return integer | any value Floored pixels for a known alias; otherwise the prototype value.
---@protected
function ViewportLayout:__index( key )
    local descriptor = layout_aliases[ self ][ key ]
    if descriptor ~= nil then
        return pixel_cache[ descriptor ] or 0
    end

    return raw_get( ViewportLayout, key )
end

--- [CLIENT AND MENU]
---
--- Attaches a handler that runs after this layout's pixel values are refreshed
--- on screen resize.
---
--- Attaching the same handler twice is a no-op, handlers run in protected mode.
---
---@param handler fun( layout: dreamwork.std.ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function ViewportLayout:attach( handler )
    events:attach( self, "resize", handler )
end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot resize handler that detaches itself before running.
---
---@param handler fun( layout: dreamwork.std.ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function ViewportLayout:once( handler )
    events:once( self, "resize", handler )
end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached resize handler.
---
---@param handler fun( layout: dreamwork.std.ViewportLayout, old_width: integer, old_height: integer, new_width: integer, new_height: integer ) | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function ViewportLayout:detach( handler )
    return events:detach( self, "resize", handler )
end

--- [CLIENT AND MENU]
---
--- Removes every resize handler attached to this layout.
---
function ViewportLayout:clear()
    events:clear( self )
end

--- [CLIENT AND MENU]
---
--- Waits for the next screen-size refresh of this layout.
---
---@return dreamwork.std.ViewportLayout layout
---@return integer old_width
---@return integer old_height
---@return integer new_width
---@return integer new_height
---@async
function ViewportLayout:await()
    -- five values, `Emitter:await` returns at most four
    local future = Future()

    events:once( self, "resize", function( ... )
        future:setResult( { ... } )
    end )

    local result = future:await()
    return result[ 1 ], result[ 2 ], result[ 3 ], result[ 4 ], result[ 5 ]
end

--- [CLIENT AND MENU]
---
--- The class used to create `ViewportLayout` instances and parse display lengths.
---
---@class dreamwork.std.ViewportLayoutClass : dreamwork.std.ViewportLayout, dreamwork.std.Class
---@field __base dreamwork.std.ViewportLayout The instance prototype shared by all `ViewportLayout` objects.
---@overload fun( definitions: table<string, string> ): table<string, integer>
local ViewportLayoutClass = class.create( ViewportLayout )
std.ViewportLayout = ViewportLayoutClass

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
function ViewportLayoutClass.parse( descriptor )
    local pixels, error_message = descriptor_to_pixels( descriptor )
    if error_message ~= nil then
        error( ValueError( descriptor, error_message ), 2 )
    end

    return pixels
end

engine_hook.catch( "OnScreenSizeChanged", "viewport.resolution", function( old_width, old_height, new_width, new_height )
    for descriptor in raw_pairs( pixel_cache ) do
        pixel_cache[ descriptor ] = descriptor_to_pixels( descriptor )
    end

    for layout in raw_pairs( layout_aliases ) do
        events:emit( layout, "resize", layout, old_width, old_height, new_width, new_height )
    end
end )
