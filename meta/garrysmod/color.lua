---@meta garrysmod.color


--- Color object, used by drawing, rendering and many other functions.
---
---@class garrysmod.Color : metatable
---@field r integer The red component, from `0` to `255`.
---@field g integer The green component, from `0` to `255`.
---@field b integer The blue component, from `0` to `255`.
---@field a integer The alpha (opacity) component, from `0` to `255`.

--- [SHARED AND MENU]
---
--- Converts a `Color` into the HSL color space.
---
---@param color garrysmod.Color The color to convert.
---@return number hue The hue in degrees, from `0` to `360`.
---@return number saturation The saturation, from `0` to `1`.
---@return number lightness The lightness, from `0` to `1`.
function ColorToHSL( color ) end

--- [SHARED AND MENU]
---
--- Converts a `Color` into the HSV color space.
---
--- Example: `ColorToHSV( Color( 255, 255, 0 ) )` returns `60, 1, 1`.
---
---@param color garrysmod.Color The color to convert.
---@return number hue The hue in degrees, from `0` to `360`.
---@return number saturation The saturation, from `0` to `1`.
---@return number value The value (brightness), from `0` to `1`.
function ColorToHSV( color ) end

--- [CLIENT]
---
--- Returns a named color defined in `resource/ClientScheme.res`.
---
---@param name string The name of the color.
---@return garrysmod.Color | nil color The named color, or `nil` if it isn't found.
function NamedColor( name ) end
