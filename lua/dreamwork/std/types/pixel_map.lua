local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

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
local string_format = string.format

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local class = std.class

local window = std.window

local error = std.error
local type = std.type

local ValueError = std.ValueError
local Hook = std.Hook


--- [CLIENT AND MENU]
---
--- Display length abbreviations resolved by `PixelMap` into floored CSS pixels.
---
--- Viewport units (`vmin`, `vw`, …) track `window` size. Absolute lengths
--- (`cm`, `pt`, …) use the CSS 96 DPI reference, not live DPI.
---
--- For non-display unit conversion (mass, temperature, …) use `unit`.
---
---@alias dreamwork.std.PixelUnit
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
---@type table<dreamwork.std.PixelUnit, fun( value: number ): number>
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
---@param descriptor string The length quantity string (`"<number><PixelUnit>"`).
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

--- Weak keys: each `PixelMap` -> its alias name -> original descriptor string.
---
---@type table<dreamwork.std.PixelMap, table<string, string>>
local map_aliases = {}
gc_setTableRules( map_aliases, true, false )

--- Weak keys: each `PixelMap` -> its resize `Hook`.
---
---@type table<dreamwork.std.PixelMap, dreamwork.std.Hook>
local hooks = {}
gc_setTableRules( hooks, true, false )

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
---@class dreamwork.std.PixelMap : dreamwork.std.Object
---@field __class dreamwork.std.PixelMapClass The class used to construct this object.
local PixelMap = class.base( "PixelMap", true )

--- Builds the alias table and seeds `pixel_cache` for each descriptor.
---
---@param definitions table<string, string> Alias name -> length quantity string (`"<number><PixelUnit>"`).
---@protected
function PixelMap:__init( definitions )
    local aliases = {}
    map_aliases[ self ] = aliases
    hooks[ self ] = Hook( string_format( "%s: %p", type( self ), self ) )

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
function PixelMap:__index( key )
    local descriptor = map_aliases[ self ][ key ]
    if descriptor ~= nil then
        return pixel_cache[ descriptor ] or 0
    end

    return raw_get( PixelMap, key )
end

--- [CLIENT AND MENU]
---
--- Attaches a handler that runs after this map's pixel values are refreshed
--- on screen resize.
---
---@param handler fun( map: dreamwork.std.PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer )
function PixelMap:attach( handler )
    hooks[ self ]:attach( "peek", handler )
end

--- [CLIENT AND MENU]
---
--- Attaches a one-shot resize handler that detaches itself before running.
---
---@param handler fun( map: dreamwork.std.PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer )
function PixelMap:once( handler )
    hooks[ self ]:once( "peek", handler )
end

--- [CLIENT AND MENU]
---
--- Detaches a previously attached resize handler.
---
---@param handler fun( map: dreamwork.std.PixelMap, old_width: integer, old_height: integer, new_width: integer, new_height: integer )
function PixelMap:detach( handler )
    hooks[ self ]:detach( "peek", handler )
end

--- [CLIENT AND MENU]
---
--- Removes every resize handler attached to this map.
---
function PixelMap:clear()
    hooks[ self ]:clear()
end

--- [CLIENT AND MENU]
---
--- Waits for the next screen-size refresh of this map.
---
---@return dreamwork.std.PixelMap map
---@return integer old_width
---@return integer old_height
---@return integer new_width
---@return integer new_height
---@async
function PixelMap:await()
    return hooks[ self ]:await( "peek" )
end

--- [CLIENT AND MENU]
---
--- The class used to create `PixelMap` instances and parse display lengths.
---
---@class dreamwork.std.PixelMapClass : dreamwork.std.PixelMap, dreamwork.std.Class
---@field __base dreamwork.std.PixelMap The instance prototype shared by all `PixelMap` objects.
---@overload fun( definitions: table<string, string> ): table<string, integer>
local PixelMapClass = class.create( PixelMap )
std.PixelMap = PixelMapClass

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
function PixelMapClass.parse( descriptor )
    local pixels, error_message = descriptor_to_pixels( descriptor )
    if error_message ~= nil then
        error( ValueError( descriptor, error_message ), 2 )
    end

    return pixels
end

engine_hook.catch( "OnScreenSizeChanged", "dreamwork.PixelMap::Update", function( old_width, old_height, new_width, new_height )
    for descriptor in raw_pairs( pixel_cache ) do
        pixel_cache[ descriptor ] = descriptor_to_pixels( descriptor )
    end

    for pixel_map, hook in raw_pairs( hooks ) do
        exceptions_call( hook.call, hook, pixel_map, old_width, old_height, new_width, new_height )
    end
end )
