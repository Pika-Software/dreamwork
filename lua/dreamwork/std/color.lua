---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_format = string.format
local string_byte, string_char = string.byte, string.char

local bit = std.bit
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local math = std.math
local math_abs = math.abs
local math_lerp = math.lerp
local math_min, math_max = math.min, math.max
local math_ceil, math_floor = math.ceil, math.floor

local bytepack = std.bytepack
local bytepack_readHex8 = bytepack.readHex8

local error = std.error


local DIV255_CONST = 1 / 255


--- A packed 32-bit RGBA color as an unsigned integer: `0xRRGGBBAA`
--- ( red in bits 24-31, green in 16-23, blue in 8-15, alpha in 0-7 ).
---
--- Always in the range [0, 0xFFFFFFFF], so hex literals like `0xFF8000FF` compare equal to built colors.
---
---@alias dreamwork.std.Color integer

--- [SHARED AND MENU]
---
--- The color library.
---
--- Packed `0xRRGGBBAA` integers for RGBA math and conversion
--- (see `dreamwork.std.Color`). Colors are plain integers, not tables.
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
---@class dreamwork.std.color
local color_lib = {}
std.color = color_lib

--- [SHARED AND MENU]
---
--- Converts RGBA components to a color value.
---
---@param red integer The 8-bit red channel, in the range [0, 255].
---@param green integer The 8-bit green channel, in the range [0, 255].
---@param blue integer The 8-bit blue channel, in the range [0, 255].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return dreamwork.std.Color color The color value.
---@nodiscard
local function fromRGBA( red, green, blue, alpha )
    return (bit_band( red, 0xFF ) * 0x1000000) + bit_bor(
        bit_lshift( bit_band( green, 0xFF ), 16 ),
        bit_lshift( bit_band( blue, 0xFF ), 8 ),
        alpha ~= nil and bit_band( alpha, 0xFF ) or 0xFF
    )
end

color_lib.fromRGBA = fromRGBA

--- [SHARED AND MENU]
---
--- Converts a color value to RGBA components.
---
---@param color dreamwork.std.Color The color value to convert.
---@return integer red The 8-bit red channel, in the range [0, 255].
---@return integer green The 8-bit green channel, in the range [0, 255].
---@return integer blue The 8-bit blue channel, in the range [0, 255].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
local function toRGBA( color )
    return bit_rshift( color, 24 ),
        bit_band( bit_rshift( color, 16 ), 0xFF ),
        bit_band( bit_rshift( color, 8 ), 0xFF ),
        bit_band( color, 0xFF )
end

color_lib.toRGBA = toRGBA

--- [SHARED AND MENU]
---
--- Returns the color's alpha channel.
---
---@param color dreamwork.std.Color The color to get the alpha of.
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color_lib.getAlpha( color )
    return bit_band( color, 0xFF )
end

--- [SHARED AND MENU]
---
--- Sets the color's alpha channel.
---
---@param color dreamwork.std.Color The color to set the alpha of.
---@param alpha integer The 8-bit alpha channel, in the range [0, 255].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setAlpha( color, alpha )
    return (color - bit_band( color, 0xFF )) + bit_band( alpha, 0xFF )
end

--- [SHARED AND MENU]
---
--- Inverts the RGB channels of a color value, alpha is kept.
---
---@param color dreamwork.std.Color The color value to invert.
---@return dreamwork.std.Color The inverted color value.
---@nodiscard
function color_lib.invert( color )
    local r, g, b, a = toRGBA( color )
    return fromRGBA( 255 - r, 255 - g, 255 - b, a )
end

--- [SHARED AND MENU]
---
--- Adds two colors channel by channel ( alpha included ), results are clamped to [0, 255].
---
---@param value1 dreamwork.std.Color The first color to add.
---@param value2 dreamwork.std.Color The second color to add.
---@return dreamwork.std.Color new_color The result of the addition.
---@nodiscard
function color_lib.add( value1, value2 )
    local r1, g1, b1, a1 = toRGBA( value1 )
    local r2, g2, b2, a2 = toRGBA( value2 )

    return fromRGBA(
        math_min( r1 + r2, 255 ),
        math_min( g1 + g2, 255 ),
        math_min( b1 + b2, 255 ),
        math_min( a1 + a2, 255 )
    )
end

--- [SHARED AND MENU]
---
--- Subtracts two colors channel by channel ( alpha included ), results are clamped to [0, 255].
---
---@param value1 dreamwork.std.Color The first color to subtract.
---@param value2 dreamwork.std.Color The second color to subtract.
---@return dreamwork.std.Color new_color The result of the subtraction.
---@nodiscard
function color_lib.sub( value1, value2 )
    local r1, g1, b1, a1 = toRGBA( value1 )
    local r2, g2, b2, a2 = toRGBA( value2 )

    return fromRGBA(
        math_max( r1 - r2, 0 ),
        math_max( g1 - g2, 0 ),
        math_max( b1 - b2, 0 ),
        math_max( a1 - a2, 0 )
    )
end

--- [SHARED AND MENU]
---
--- Multiplies two colors channel by channel ( alpha included ),
--- channels are fractions of `255`, so white is the identity.
---
---@param value1 dreamwork.std.Color The first color to multiply.
---@param value2 dreamwork.std.Color The second color to multiply.
---@return dreamwork.std.Color new_color The result of the multiplication.
---@nodiscard
function color_lib.mul( value1, value2 )
    local r1, g1, b1, a1 = toRGBA( value1 )
    local r2, g2, b2, a2 = toRGBA( value2 )

    return fromRGBA(
        math_ceil( r1 * r2 * DIV255_CONST ),
        math_ceil( g1 * g2 * DIV255_CONST ),
        math_ceil( b1 * b2 * DIV255_CONST ),
        math_ceil( a1 * a2 * DIV255_CONST )
    )
end

--- [SHARED AND MENU]
---
--- Divides two colors channel by channel ( alpha included ),
--- channels are fractions of `255`, results are clamped to [0, 255] ( division by zero is `255` ).
---
---@param value1 dreamwork.std.Color The first color to divide.
---@param value2 dreamwork.std.Color The second color to divide.
---@return dreamwork.std.Color new_color The result of the division.
---@nodiscard
function color_lib.div( value1, value2 )
    local r1, g1, b1, a1 = toRGBA( value1 )
    local r2, g2, b2, a2 = toRGBA( value2 )

    -- `x / 0` is `inf` ( or `nan` for `0 / 0` ), `math.min` maps both to `255`
    return fromRGBA(
        math_ceil( math_min( r1 * 255 / r2, 255 ) ),
        math_ceil( math_min( g1 * 255 / g2, 255 ) ),
        math_ceil( math_min( b1 * 255 / b2, 255 ) ),
        math_ceil( math_min( a1 * 255 / a2, 255 ) )
    )
end

--- [SHARED AND MENU]
---
--- Returns the color as a 4-byte binary string ( `R, G, B, A` ).
---
---@param color dreamwork.std.Color The color to convert.
---@return string binary_string The color as binary string.
---@nodiscard
function color_lib.toString( color )
    return string_char( toRGBA( color ) )
end

--- [SHARED AND MENU]
---
--- Parses a color from a 4-byte binary string ( `R, G, B, A` ).
---
---@param str string The binary string to parse.
---@param start_position integer? The starting position in the string.
---@param str_length integer? The length of the string to parse.
---@return dreamwork.std.Color new_color The parsed color.
---@nodiscard
function color_lib.fromString( str, start_position, str_length )
    if start_position == nil then
        start_position = 1
    end

    if str_length == nil then
        str_length = #str
    end

    if (str_length - start_position + 1) < 4 then
        error( "not enough bytes in string to parse color", 2 )
    end

    return fromRGBA( string_byte( str, start_position, start_position + 3 ) )
end

--- [SHARED AND MENU]
---
--- Smoothing two colors by fraction, alpha included.
---
---@param frac number The interpolation factor.
---@param color dreamwork.std.Color The starting color.
---@param color2 dreamwork.std.Color The ending color.
---@return dreamwork.std.Color The interpolated color.
---@nodiscard
function color_lib.lerp( frac, color, color2 )
    local r, g, b, a = toRGBA( color )
    local r2, g2, b2, a2 = toRGBA( color2 )

    return fromRGBA(
        math_lerp( frac, r, r2 ),
        math_lerp( frac, g, g2 ),
        math_lerp( frac, b, b2 ),
        math_lerp( frac, a, a2 )
    )
end

--- [SHARED AND MENU]
---
--- Converts a color value to a hexadecimal string, `RRGGBBAA` without prefix.
---
---@param color dreamwork.std.Color The color to convert.
---@return string The hexadecimal representation of the color.
---@nodiscard
local function toHex( color )
    return string_format( "%02x%02x%02x%02x", toRGBA( color ) )
end

color_lib.toHex = toHex

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
---@return dreamwork.std.Color color The color value.
---@nodiscard
local function fromHex( hex_str )
    local start_position = 1

    local uint8_1, uint8_2 = string_byte( hex_str, 1, 2 )
    if uint8_1 == 0x23 --[[ # ]] then
        start_position = 2
    elseif uint8_1 == 0x30 --[[ 0 ]] and (uint8_2 == 0x58 --[[ X ]] or uint8_2 == 0x78 --[[ x ]]) then
        start_position = 3
    end

    local digit_count = #hex_str - start_position + 1
    local d1, d2, d3, d4, d5, d6, d7, d8 = string_byte( hex_str, start_position, start_position + 7 )

    if digit_count == 3 then
        return fromRGBA(
            bytepack_readHex8( d1, d1 ) or 0,
            bytepack_readHex8( d2, d2 ) or 0,
            bytepack_readHex8( d3, d3 ) or 0,
            0xFF
        )
    elseif digit_count == 4 then
        return fromRGBA(
            bytepack_readHex8( d1, d1 ) or 0,
            bytepack_readHex8( d2, d2 ) or 0,
            bytepack_readHex8( d3, d3 ) or 0,
            bytepack_readHex8( d4, d4 ) or 0
        )
    end

    -- `RRGGBB` / `RRGGBBAA`, missing digits are `0`
    return fromRGBA(
        bytepack_readHex8( d1 or 0x30, d2 or 0x30 ) or 0,
        bytepack_readHex8( d3 or 0x30, d4 or 0x30 ) or 0,
        bytepack_readHex8( d5 or 0x30, d6 or 0x30 ) or 0,
        d7 == nil and 0xFF or (bytepack_readHex8( d7, d8 or 0x30 ) or 0)
    )
end

color_lib.fromHex = fromHex

--- [SHARED AND MENU]
---
--- Creates a color from HSL values (hue, saturation, lightness).
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
local function fromHSL( hue, saturation, lightness, alpha )
    hue = hue % 360

    local c = (1 - math_abs( 2 * lightness - 1 )) * saturation
    local x = c * (1 - math_abs( (hue / 60) % 2 - 1 ))
    local m = lightness - (c * 0.5)

    local r, g, b
    if hue < 60 then
        r, g, b = c, x, 0
    elseif hue < 120 then
        r, g, b = x, c, 0
    elseif hue < 180 then
        r, g, b = 0, c, x
    elseif hue < 240 then
        r, g, b = 0, x, c
    elseif hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return fromRGBA(
        math_floor( (r + m) * 255 ),
        math_floor( (g + m) * 255 ),
        math_floor( (b + m) * 255 ),
        alpha
    )
end

color_lib.fromHSL = fromHSL

--- [SHARED AND MENU]
---
--- Converts a color to HSL values (hue, saturation, lightness).
---
---@param color dreamwork.std.Color The color to convert.
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number lightness The lightness as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
local function toHSL( color )
    local red, green, blue, alpha = toRGBA( color )
    red, green, blue = red * DIV255_CONST, green * DIV255_CONST, blue * DIV255_CONST

    local min_value, max_value = math_min( red, green, blue ), math_max( red, green, blue )

    local lightness = (max_value + min_value) * 0.5

    local delta = max_value - min_value
    if delta ~= 0 then
        local saturation
        if lightness > 0.5 then
            saturation = delta / (2.0 - (max_value - min_value))
        else
            saturation = delta / (max_value + min_value)
        end

        local hue
        if max_value == red then
            hue = ((green - blue) / delta) % 6
        elseif max_value == green then
            hue = ((blue - red) / delta) + 2
        else
            hue = ((red - green) / delta) + 4
        end

        hue = hue * 60

        return hue < 0 and hue + 360 or hue, saturation, lightness, alpha
    end

    return 0, 0, lightness, alpha
end

color_lib.toHSL = toHSL

--- [SHARED AND MENU]
---
--- Creates a color from HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
local function fromHSV( hue, saturation, brightness, alpha )
    hue = hue % 360

    local c = brightness * saturation
    local x = c * (1 - math_abs( (hue / 60) % 2 - 1 ))
    local m = brightness - c

    local r, g, b
    if hue < 60 then
        r, g, b = c, x, 0
    elseif hue < 120 then
        r, g, b = x, c, 0
    elseif hue < 180 then
        r, g, b = 0, c, x
    elseif hue < 240 then
        r, g, b = 0, x, c
    elseif hue < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return fromRGBA(
        math_floor( (r + m) * 255 ),
        math_floor( (g + m) * 255 ),
        math_floor( (b + m) * 255 ),
        alpha
    )
end

color_lib.fromHSV = fromHSV

--- [SHARED AND MENU]
---
--- Returns the color as HSV values (hue, saturation, value).
---
---@param color dreamwork.std.Color The color to convert.
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number value The value as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
local function toHSV( color )
    local red, green, blue, alpha = toRGBA( color )
    red, green, blue = red * DIV255_CONST, green * DIV255_CONST, blue * DIV255_CONST

    local min_value, max_value = math_min( red, green, blue ), math_max( red, green, blue )
    local delta = max_value - min_value

    local saturation
    if max_value == 0 then
        saturation = 0
    else
        saturation = delta / max_value
    end

    local hue
    if delta == 0 then
        hue = 0
    elseif max_value == red then
        hue = ((green - blue) / delta) % 6
    elseif max_value == green then
        hue = ((blue - red) / delta) + 2
    else
        hue = ((red - green) / delta) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue, saturation, max_value, alpha
end

color_lib.toHSV = toHSV

--- [SHARED AND MENU]
---
--- Creates a color from HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
local function fromHWB( hue, saturation, brightness, alpha )
    brightness = 1 - brightness
    return fromHSV( hue, (brightness > 0) and (1 - (saturation / brightness)) or 0, brightness, alpha )
end

color_lib.fromHWB = fromHWB

--- [SHARED AND MENU]
---
--- Returns the color as HWB values (hue, whiteness, blackness).
---
---@param color dreamwork.std.Color The color to convert to HWB.
---@return integer hue The hue in degrees [0, 360].
---@return number whiteness The whiteness as fraction [0, 1].
---@return number blackness The blackness as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
local function toHWB( color )
    local hue, saturation, brightness, alpha = toHSL( color )
    return hue, (1 - saturation) * brightness, 1 - brightness, alpha
end

color_lib.toHWB = toHWB

--- [SHARED AND MENU]
---
--- Creates a color from CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@param alpha integer? The 8-bit alpha channel, in the range [0, 255], `255` by default.
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.fromCMYK( cyan, magenta, yellow, black, alpha )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black

    return fromRGBA(
        math_floor( ((1 - cyan) * mk) * 255 ),
        math_floor( ((1 - magenta) * mk) * 255 ),
        math_floor( ((1 - yellow) * mk) * 255 ),
        alpha
    )
end

--- [SHARED AND MENU]
---
--- Returns the color as CMYK values (cyan, magenta, yellow, black).
---
---@param color dreamwork.std.Color The color to convert to CMYK.
---@return number cyan The cyan as fraction [0, 1].
---@return number magenta The magenta as fraction [0, 1].
---@return number yellow The yellow as fraction [0, 1].
---@return number black The black as fraction [0, 1].
---@return integer alpha The 8-bit alpha channel, in the range [0, 255].
---@nodiscard
function color_lib.toCMYK( color )
    local red, green, blue, alpha = toRGBA( color )
    local m = math_max( red, green, blue )
    return (m - red) / m, (m - green) / m, (m - blue) / m, math_min( red, green, blue ) * DIV255_CONST, alpha
end

--- [SHARED AND MENU]
---
--- Returns the color's hue.
---
---@param color dreamwork.std.Color The color to get the hue of.
---@return integer hue The hue in degrees [0, 360].
---@nodiscard
function color_lib.getHue( color )
    local red, green, blue = toRGBA( color )
    red, green, blue = red * DIV255_CONST, green * DIV255_CONST, blue * DIV255_CONST

    local max_value = math_max( red, green, blue )
    local delta = max_value - math_min( red, green, blue )

    if delta == 0 then
        return 0
    end

    local hue
    if max_value == red then
        hue = ((green - blue) / delta) % 6
    elseif max_value == green then
        hue = ((blue - red) / delta) + 2
    else
        hue = ((red - green) / delta) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue
end

--- [SHARED AND MENU]
---
--- Sets the color's hue.
---
---@param color dreamwork.std.Color The color to set the hue of.
---@param hue integer The hue in degrees [0, 360].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setHue( color, hue )
    local _, saturation, lightness, alpha = toHSL( color )
    return fromHSL( hue, saturation, lightness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's saturation.
---
---@param color dreamwork.std.Color The color to get the saturation of.
---@return number saturation The saturation as fraction [0, 1].
---@nodiscard
function color_lib.getSaturation( color )
    local red, green, blue = toRGBA( color )
    red, green, blue = red * DIV255_CONST, green * DIV255_CONST, blue * DIV255_CONST

    local max_value = math_max( red, green, blue )
    return max_value == 0 and 0 or (max_value - math_min( red, green, blue )) / max_value
end

--- [SHARED AND MENU]
---
--- Sets the color's saturation.
---
---@param color dreamwork.std.Color The color to set the saturation of.
---@param saturation number The saturation as fraction [0, 1].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setSaturation( color, saturation )
    local hue, _, lightness, alpha = toHSL( color )
    return fromHSL( hue, saturation, lightness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's brightness.
---
---@param color dreamwork.std.Color The color to get the brightness of.
---@return number brightness The brightness as fraction [0, 1].
---@nodiscard
function color_lib.getBrightness( color )
    local red, green, blue = toRGBA( color )
    return math_max( red, green, blue ) * DIV255_CONST
end

--- [SHARED AND MENU]
---
--- Sets the color's brightness.
---
---@param color dreamwork.std.Color The color to set the brightness of.
---@param brightness number The brightness as fraction [0, 1].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setBrightness( color, brightness )
    local hue, saturation, _, alpha = toHSV( color )
    return fromHSV( hue, saturation, brightness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's lightness.
---
---@param color dreamwork.std.Color The color to get the lightness of.
---@return number lightness The lightness as fraction [0, 1].
---@nodiscard
function color_lib.getLightness( color )
    local red, green, blue = toRGBA( color )
    red, green, blue = red * DIV255_CONST, green * DIV255_CONST, blue * DIV255_CONST

    return (math_max( red, green, blue ) + math_min( red, green, blue )) * 0.5
end

--- [SHARED AND MENU]
---
--- Sets the color's lightness.
---
---@param color dreamwork.std.Color The color to set the lightness of.
---@param lightness number The lightness as fraction [0, 1].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setLightness( color, lightness )
    local hue, saturation, _, alpha = toHSL( color )
    return fromHSL( hue, saturation, lightness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's whiteness.
---
---@param color dreamwork.std.Color The color to get the whiteness of.
---@return number whiteness The whiteness as fraction [0, 1].
---@nodiscard
function color_lib.getWhiteness( color )
    local _, saturation, brightness = toHSL( color )
    return (1 - saturation) * brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's whiteness.
---
---@param color dreamwork.std.Color The color to set the whiteness of.
---@param whiteness number The whiteness as fraction [0, 1].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setWhiteness( color, whiteness )
    local hue, _, blackness, alpha = toHWB( color )
    return fromHWB( hue, whiteness, blackness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's blackness.
---
---@param color dreamwork.std.Color The color to get the blackness of.
---@return number blackness The blackness as fraction [0, 1].
---@nodiscard
function color_lib.getBlackness( color )
    local _, __, brightness = toHSL( color )
    return 1 - brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's blackness.
---
---@param color dreamwork.std.Color The color to set the blackness of.
---@param blackness number The blackness as fraction [0, 1].
---@return dreamwork.std.Color new_color The new color.
---@nodiscard
function color_lib.setBlackness( color, blackness )
    local hue, saturation, _, alpha = toHSL( color )
    return fromHSL( hue, saturation, blackness, alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's luminance.
---
---@param color dreamwork.std.Color The color to get the luminance of.
---@return number luminance The luminance as integer [0, 255].
---@nodiscard
function color_lib.getLuminance( color )
    local red, green, blue = toRGBA( color )
    return math_ceil( red * 0.2126 + green * 0.7152 + blue * 0.0722 )
end
