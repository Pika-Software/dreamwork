---@meta _

--- A packed 32-bit RGBA color as an unsigned integer: `0xRRGGBBAA`
--- ( red in bits 24-31, green in 16-23, blue in 8-15, alpha in 0-7 ).
---
--- Always in the range [0, 0xFFFFFFFF], so hex literals like `0xFF8000FF` compare equal to built colors.
---
---@alias Color integer

--- [SHARED AND MENU]
---
--- The color library.
---
--- Packed `0xRRGGBBAA` integers for RGBA math and conversion
--- (see `Color`). Colors are plain integers, not tables.
---
--- Creating / unpacking:
--- * `fromRGBA`, `fromHex`, `fromHSL`, `fromHSV`, `fromHWB`, `fromCMYK`
--- * Matching `to*` functions, alpha is the last returned value
---
--- Channel ops (`add`, `sub`, `mul`, `div`, `lerp`, `invert`)
--- and HSL / HSV / HWB getters / setters return a new packed color.
--- Setters keep the alpha channel of the source color.
---
--- ```lua
--- local orange = color.fromRGBA( 255, 128, 0 )
--- local r, g, b, a = color.toRGBA( orange )
--- print( r .. ", " .. g .. ", " .. b .. ", " .. a ) -- 255, 128, 0, 255
--- print( orange == 0xFF8000FF ) -- true
--- ```
---
---@class color
color = {}

--- [SHARED AND MENU]
---
--- Converts RGBA components to a color value.
---
---@param red integer The 8-bit red channel, in the range [0, 255].
---@param green integer The 8-bit green channel, in the range [0, 255].
---@param blue integer The 8-bit blue channel, in the range [0, 255].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return Color color The color value.
---@nodiscard
function color.fromRGBA(red, green, blue, alpha) end

--- [SHARED AND MENU]
---
--- Converts a color value to RGBA components.
---
---@param color Color The color value to convert.
---@return integer red The 8-bit red channel, in the range [0, 255].
---@return integer green The 8-bit green channel, in the range [0, 255].
---@return integer blue The 8-bit blue channel, in the range [0, 255].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.toRGBA(color) end

--- [SHARED AND MENU]
---
--- Returns the color's alpha channel.
---
---@param color Color The color to get the alpha of.
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.getAlpha(color) end

--- [SHARED AND MENU]
---
--- Sets the color's alpha channel.
---
---@param color Color The color to set the alpha of.
---@param alpha integer The 8-bit alpha channel, in the range [0, 255].
---@return Color new_color The new color.
---@nodiscard
function color.setAlpha(color, alpha) end

--- [SHARED AND MENU]
---
--- Inverts the RGB channels of a color value, alpha is kept.
---
---@param color Color The color value to invert.
---@return Color The inverted color value.
---@nodiscard
function color.invert(color) end

--- [SHARED AND MENU]
---
--- Adds two colors channel by channel ( alpha included ), results are clamped to [0, 255].
---
---@param value1 Color The first color to add.
---@param value2 Color The second color to add.
---@return Color new_color The result of the addition.
---@nodiscard
function color.add(value1, value2) end

--- [SHARED AND MENU]
---
--- Subtracts two colors channel by channel ( alpha included ), results are clamped to [0, 255].
---
---@param value1 Color The first color to subtract.
---@param value2 Color The second color to subtract.
---@return Color new_color The result of the subtraction.
---@nodiscard
function color.sub(value1, value2) end

--- [SHARED AND MENU]
---
--- Multiplies two colors channel by channel ( alpha included ),
--- channels are fractions of `255`, so white is the identity.
---
---@param value1 Color The first color to multiply.
---@param value2 Color The second color to multiply.
---@return Color new_color The result of the multiplication.
---@nodiscard
function color.mul(value1, value2) end

--- [SHARED AND MENU]
---
--- Divides two colors channel by channel ( alpha included ),
--- channels are fractions of `255`, results are clamped to [0, 255] ( division by zero is `255` ).
---
---@param value1 Color The first color to divide.
---@param value2 Color The second color to divide.
---@return Color new_color The result of the division.
---@nodiscard
function color.div(value1, value2) end

--- [SHARED AND MENU]
---
--- Returns the color as a 4-byte binary string ( `R, G, B, A` ).
---
---@param color Color The color to convert.
---@return string binary_string The color as binary string.
---@nodiscard
function color.toString(color) end

--- [SHARED AND MENU]
---
--- Parses a color from a 4-byte binary string ( `R, G, B, A` ).
---
---@param str string The binary string to parse.
---@param start_position integer? The starting position in the string.
---@param str_length integer? The length of the string to parse.
---@return Color new_color The parsed color.
---@nodiscard
function color.fromString(str, start_position, str_length) end

--- [SHARED AND MENU]
---
--- Smoothing two colors by fraction, alpha included.
---
---@param frac number The interpolation factor.
---@param color Color The starting color.
---@param color2 Color The ending color.
---@return Color The interpolated color.
---@nodiscard
function color.lerp(frac, color, color2) end

--- [SHARED AND MENU]
---
--- Converts a color value to a hexadecimal string, `RRGGBBAA` without prefix.
---
---@param color Color The color to convert.
---@return string The hexadecimal representation of the color.
---@nodiscard
function color.toHex(color) end

--- [SHARED AND MENU]
---
--- Converts a hexadecimal color string to color.
---
--- Formats ( `0x`, `#` or no prefix ):
---
--- `RGB` / `RGBA` ( every digit doubled, CSS style ) / `RRGGBB` / `RRGGBBAA`
---
--- Alpha is `255` when not given, invalid digit pairs are `0`.
---
---@param hex_str string The hexadecimal color string to convert.
---@return Color color The color value.
---@nodiscard
function color.fromHex(hex_str) end

--- [SHARED AND MENU]
---
--- Creates a color from HSL values (hue, saturation, lightness).
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return Color new_color The new color.
---@nodiscard
function color.fromHSL(hue, saturation, lightness, alpha) end

--- [SHARED AND MENU]
---
--- Converts a color to HSL values (hue, saturation, lightness).
---
---@param color Color The color to convert.
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number lightness The lightness as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.toHSL(color) end

--- [SHARED AND MENU]
---
--- Creates a color from HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return Color new_color The new color.
---@nodiscard
function color.fromHSV(hue, saturation, brightness, alpha) end

--- [SHARED AND MENU]
---
--- Returns the color as HSV values (hue, saturation, value).
---
---@param color Color The color to convert.
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number value The value as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.toHSV(color) end

--- [SHARED AND MENU]
---
--- Creates a color from HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return Color new_color The new color.
---@nodiscard
function color.fromHWB(hue, saturation, brightness, alpha) end

--- [SHARED AND MENU]
---
--- Returns the color as HWB values (hue, whiteness, blackness).
---
---@param color Color The color to convert to HWB.
---@return integer hue The hue in degrees [0, 360].
---@return number whiteness The whiteness as fraction [0, 1].
---@return number blackness The blackness as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.toHWB(color) end

--- [SHARED AND MENU]
---
--- Creates a color from CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return Color new_color The new color.
---@nodiscard
function color.fromCMYK(cyan, magenta, yellow, black, alpha) end

--- [SHARED AND MENU]
---
--- Returns the color as CMYK values (cyan, magenta, yellow, black).
---
---@param color Color The color to convert to CMYK.
---@return number cyan The cyan as fraction [0, 1].
---@return number magenta The magenta as fraction [0, 1].
---@return number yellow The yellow as fraction [0, 1].
---@return number black The black as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color.toCMYK(color) end

--- [SHARED AND MENU]
---
--- Returns the color's hue.
---
---@param color Color The color to get the hue of.
---@return integer hue The hue in degrees [0, 360].
---@nodiscard
function color.getHue(color) end

--- [SHARED AND MENU]
---
--- Sets the color's hue.
---
---@param color Color The color to set the hue of.
---@param hue integer The hue in degrees [0, 360].
---@return Color new_color The new color.
---@nodiscard
function color.setHue(color, hue) end

--- [SHARED AND MENU]
---
--- Returns the color's saturation.
---
---@param color Color The color to get the saturation of.
---@return number saturation The saturation as fraction [0, 1].
---@nodiscard
function color.getSaturation(color) end

--- [SHARED AND MENU]
---
--- Sets the color's saturation.
---
---@param color Color The color to set the saturation of.
---@param saturation number The saturation as fraction [0, 1].
---@return Color new_color The new color.
---@nodiscard
function color.setSaturation(color, saturation) end

--- [SHARED AND MENU]
---
--- Returns the color's brightness.
---
---@param color Color The color to get the brightness of.
---@return number brightness The brightness as fraction [0, 1].
---@nodiscard
function color.getBrightness(color) end

--- [SHARED AND MENU]
---
--- Sets the color's brightness.
---
---@param color Color The color to set the brightness of.
---@param brightness number The brightness as fraction [0, 1].
---@return Color new_color The new color.
---@nodiscard
function color.setBrightness(color, brightness) end

--- [SHARED AND MENU]
---
--- Returns the color's lightness.
---
---@param color Color The color to get the lightness of.
---@return number lightness The lightness as fraction [0, 1].
---@nodiscard
function color.getLightness(color) end

--- [SHARED AND MENU]
---
--- Sets the color's lightness.
---
---@param color Color The color to set the lightness of.
---@param lightness number The lightness as fraction [0, 1].
---@return Color new_color The new color.
---@nodiscard
function color.setLightness(color, lightness) end

--- [SHARED AND MENU]
---
--- Returns the color's whiteness.
---
---@param color Color The color to get the whiteness of.
---@return number whiteness The whiteness as fraction [0, 1].
---@nodiscard
function color.getWhiteness(color) end

--- [SHARED AND MENU]
---
--- Sets the color's whiteness.
---
---@param color Color The color to set the whiteness of.
---@param whiteness number The whiteness as fraction [0, 1].
---@return Color new_color The new color.
---@nodiscard
function color.setWhiteness(color, whiteness) end

--- [SHARED AND MENU]
---
--- Returns the color's blackness.
---
---@param color Color The color to get the blackness of.
---@return number blackness The blackness as fraction [0, 1].
---@nodiscard
function color.getBlackness(color) end

--- [SHARED AND MENU]
---
--- Sets the color's blackness.
---
---@param color Color The color to set the blackness of.
---@param blackness number The blackness as fraction [0, 1].
---@return Color new_color The new color.
---@nodiscard
function color.setBlackness(color, blackness) end

--- [SHARED AND MENU]
---
--- Returns the color's luminance.
---
---@param color Color The color to get the luminance of.
---@return number luminance The luminance as integer [0, 255].
---@nodiscard
function color.getLuminance(color) end
