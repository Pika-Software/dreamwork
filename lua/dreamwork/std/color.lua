local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local math, string, bit = std.math, std.string, std.bit
local isNumber, setmetatable = std.isNumber, std.setmetatable
local math_abs, math_min, math_max, math_floor = math.abs, math.min, math.max, math.floor
local string_char, string_byte, string_format, string_len = string.char, string.byte, string.format, string.len

local DIV255_CONST = 1 / 255

--- [SHARED AND MENU]
---
--- The color object.
---
---@class dreamwork.std.Color : dreamwork.std.Object
---@field __class dreamwork.std.ColorClass
---@field r integer A red channel of the color. [0, 255].
---@field g integer A green channel of the color. [0, 255].
---@field b integer A blue channel of the color. [0, 255].
---@field a integer An alpha channel of the color. [0, 255].
---@operator add(dreamwork.std.Color): dreamwork.std.Color
---@operator sub(dreamwork.std.Color): dreamwork.std.Color
---@operator mul(dreamwork.std.Color | integer): dreamwork.std.Color
---@operator div(dreamwork.std.Color | integer): dreamwork.std.Color
---@operator unm(): dreamwork.std.Color
local Color = std.Color and std.Color.__base or std.class.base( "Color" )

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Color dreamwork.std.Color

--- [SHARED AND MENU]
---
--- The color class.
---
---@class dreamwork.std.ColorClass : dreamwork.std.Color
---@field __base dreamwork.std.Color
---@overload fun( r: integer?, g: integer?, b: integer?, a: integer? ): dreamwork.std.Color
local ColorClass = std.Color or std.class.create( Color )
std.Color = ColorClass

--- [SHARED AND MENU]
---
--- Creates a color object from RGBA values.
---
---@param r integer? The 8-bit red channel.
---@param g integer? The 8-bit green channel.
---@param b integer? The 8-bit blue channel.
---@param a integer? The 8-bit alpha channel.
---@return dreamwork.std.Color color The color object.
local function from_rgba( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0

    return setmetatable( {
        r = r,
        g = g and math_min( math_max( g, 0 ), 255 ) or r,
        b = b and math_min( math_max( b, 0 ), 255 ) or r,
        a = a and math_min( math_max( a, 0 ), 255 ) or 255
    }, Color )
end

ColorClass.fromRGBA = from_rgba

---@protected
---@param r integer? The 8-bit red channel.
---@param g integer? The 8-bit green channel.
---@param b integer? The 8-bit blue channel.
---@param a integer? The 8-bit alpha channel.
---@return dreamwork.std.Color color The color object.
function Color:__new( r, g, b, a )
    return from_rgba( r, g, b, a )
end

---@protected
function Color:__tostring()
    return string_format( "Color: %p [%d, %d, %d, %d]", self, self.r, self.g, self.b, self.a )
end

---@param other dreamwork.std.Color
---@protected
function Color:__eq( other )
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

---@protected
function Color:__unm()
    return from_rgba(
        math_abs( 255 - self.r ),
        math_abs( 255 - self.g ),
        math_abs( 255 - self.b ),
        self.a
    )
end

---@protected
function Color:__tocolor()
    return self
end

--- [SHARED AND MENU]
---
--- Inverts current color.
---
---@return dreamwork.std.Color color The color object.
function Color:invert()
    self.r = math_min( math_max( math_abs( 255 - self.r ), 0 ), 255 )
    self.g = math_min( math_max( math_abs( 255 - self.g ), 0 ), 255 )
    self.b = math_min( math_max( math_abs( 255 - self.b ), 0 ), 255 )
    return self
end

---@param color dreamwork.std.Color
---@protected
function Color:__add( color )
    return from_rgba(
        self.r + color.r,
        self.g + color.g,
        self.b + color.b,
        self.a
    )
end

---@param color dreamwork.std.Color
---@protected
function Color:__sub( color )
    return from_rgba(
        self.r - color.r,
        self.g - color.g,
        self.b - color.b,
        self.a
    )
end

---@param other dreamwork.std.Color | integer
---@protected
function Color:__mul( other )
    if isNumber( other ) then
        ---@cast other integer
        return from_rgba(
            self.r * other,
            self.g * other,
            self.b * other,
            self.a
        )
    end

    ---@cast other dreamwork.std.Color
    return from_rgba(
        self.r * other.r,
        self.g * other.g,
        self.b * other.b,
        self.a
    )
end

---@param other dreamwork.std.Color | integer
---@protected
function Color:__div( other )
    if isNumber( other ) then
        ---@cast other integer
        local multiplier = 1 / other
        return from_rgba(
            self.r * multiplier,
            self.g * multiplier,
            self.b * multiplier,
            self.a
        )
    end

    ---@cast other dreamwork.std.Color
    return from_rgba(
        self.r / other.r,
        self.g / other.g,
        self.b / other.b,
        self.a
    )
end

---@param other dreamwork.std.Color
---@protected
function Color:__lt( other )
    return ( self.r + self.g + self.b + self.a ) < ( other.r + other.g + other.b + other.a )
end

---@param other dreamwork.std.Color
---@protected
function Color:__le( other )
    return ( self.r + self.g + self.b + self.a ) <= ( other.r + other.g + other.b + other.a )
end

---@param value dreamwork.std.Color
---@protected
function Color:__concat( value )
    return "#" .. self:toHex() .. tostring( value )
end

--- [SHARED AND MENU]
---
--- Unpacks the color as r, g, b, a values.
---
---@return integer r The 8-bit red channel.
---@return integer g The 8-bit green channel.
---@return integer b The 8-bit blue channel.
---@return integer a The 8-bit alpha channel.
function Color:unpack()
    return self.r, self.g, self.b, self.a
end

--- [SHARED AND MENU]
---
--- Makes a copy of the color.
---
---@return dreamwork.std.Color color The copy of the color.
function Color:copy()
    return setmetatable( {
        r = self.r,
        g = self.g,
        b = self.b,
        a = self.a
    }, Color )
end

--- [SHARED AND MENU]
---
--- Makes color a copy of the another color.
---
---@param color dreamwork.std.Color The color to copy.
---@return dreamwork.std.Color color The copy of the color.
function Color:copyFrom( color )
    self.r = color.r
    self.g = color.g
    self.b = color.b
    self.a = color.a or 255
    return self
end

--- [SHARED AND MENU]
---
--- Set the color as r, g, b, a values.
---
---@param r integer The 8-bit red channel.
---@param g integer The 8-bit green channel.
---@param b integer The 8-bit blue channel.
---@param a integer The 8-bit alpha channel.
---@return dreamwork.std.Color color The color object.
function Color:setUnpacked( r, g, b, a )
    r = r and math_min( math_max( r, 0 ), 255 ) or 0

    self.r = r
    self.g = g and math_min( math_max( g, 0 ), 255 ) or r
    self.b = b and math_min( math_max( b, 0 ), 255 ) or r
    self.a = a and math_min( math_max( a, 0 ), 255 ) or 255
    return self
end

--- [SHARED AND MENU]
---
--- Returns the color as hex string.
---
---@param with_alpha boolean? Whether to include alpha.
---@return string hex_str The hex string.
function Color:toHex( with_alpha, alpha_first )
    if with_alpha then
        if alpha_first then
            return string_format( "%02x%02x%02x%02x", self.a, self.r, self.g, self.b )
        else
            return string_format( "%02x%02x%02x%02x", self.r, self.g, self.b, self.a )
        end
    else
        return string_format( "%02x%02x%02x", self.r, self.g, self.b )
    end
end

do

    local bit_bor, bit_lshift = bit.bor, bit.lshift

    --- [SHARED AND MENU]
    ---
    --- Returns the color as 32-bit integer.
    ---
    ---@param with_alpha boolean? Whether to include alpha.
    ---@return integer uint32 The 32-bit integer.
    function Color:toUInt32( with_alpha )
        if with_alpha then
            return bit_bor( self.r, bit_lshift( self.g, 8 ), bit_lshift( self.b, 16 ), bit_lshift( self.a, 24 ) )
        else
            return bit_bor( self.r, bit_lshift( self.g, 8 ), bit_lshift( self.b, 16 ) )
        end
    end

end

--- [SHARED AND MENU]
---
--- Returns the color as binary string.
---
---@param with_alpha boolean? Whether to include alpha.
---@return string bin_str The binary string.
function Color:toBinary( with_alpha )
    return with_alpha and string_char( self.r, self.g, self.b, self.a ) or string_char( self.r, self.g, self.b )
end

--- [SHARED AND MENU]
---
--- Returns the color as HSL values (hue, saturation, lightness).
---
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number lightness The lightness as fraction [0, 1].
function Color:toHSL()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local min_value, max_value = math_min( red, green, blue ), math_max( red, green, blue )

    local lightness = ( max_value + min_value ) * 0.5

    local delta = max_value - min_value
    if delta ~= 0 then
        local saturation
        if lightness > 0.5 then
            saturation = delta / ( 2.0 - ( max_value - min_value ) )
        else
            saturation = delta / ( max_value + min_value )
        end

        local hue
        if max_value == red then
            hue = ( ( green - blue ) / delta ) % 6
        elseif max_value == green then
            hue = ( ( blue - red ) / delta ) + 2
        else
            hue = ( ( red - green ) / delta ) + 4
        end

        hue = hue * 60

        return hue < 0 and hue + 360 or hue, saturation, lightness
    end

    return 0, 0, lightness
end

--- [SHARED AND MENU]
---
--- Returns the color as HSV values (hue, saturation, value).
---
---@return integer hue The hue in degrees [0, 360].
---@return number saturation The saturation as fraction [0, 1].
---@return number value The value as fraction [0, 1].
function Color:toHSV()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
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
        hue = ( ( green - blue ) / delta ) % 6
    elseif max_value == green then
        hue = ( ( blue - red ) / delta ) + 2
    else
        hue = ( ( red - green ) / delta ) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue, saturation, max_value
end

--- [SHARED AND MENU]
---
--- Returns the color as HWB values (hue, whiteness, blackness).
---
---@return integer hue The hue in degrees [0, 360].
---@return number whiteness The whiteness as fraction [0, 1].
---@return number blackness The blackness as fraction [0, 1].
function Color:toHWB()
    local hue, saturation, brightness = self:toHSL()
    return hue, ( 1 - saturation ) * brightness, 1 - brightness
end

--- [SHARED AND MENU]
---
--- Returns the color as CMYK values (cyan, magenta, yellow, black).
---
---@return number cyan The cyan as fraction [0, 1].
---@return number magenta The magenta as fraction [0, 1].
---@return number yellow The yellow as fraction [0, 1].
---@return number black The black as fraction [0, 1].
function Color:toCMYK()
    local m = math_max( self.r, self.g, self.b )
    return ( m - self.r ) / m, ( m - self.g ) / m, ( m - self.b ) / m, math_min( self.r, self.g, self.b ) * DIV255_CONST
end

do

    local math_lerp = math.lerp

    --- [SHARED AND MENU]
    ---
    --- Smoothing a color object to another color object.
    ---
    ---@param color dreamwork.std.Color The color to lerp.
    ---@param frac number? The fraction to lerp [0, 1].
    ---@param with_alpha boolean? Whether to lerp alpha channel.
    ---@return dreamwork.std.Color
    function Color:lerp( color, frac, with_alpha )
        frac = frac and math_min( math_max( frac, 0 ), 1 ) or 0.5

        self.r = math_lerp( frac, self.r, color.r )
        self.g = math_lerp( frac, self.g, color.g )
        self.b = math_lerp( frac, self.b, color.b )

        if with_alpha then
            self.a = math_lerp( frac, self.a, color.a )
        end

        return self
    end

end

--- [SHARED AND MENU]
---
--- Creates a color object from lerp.
---
---@param color dreamwork.std.Color The "from" color.
---@param frac number? The fraction [0, 1].
---@param with_alpha boolean? Whether to lerp alpha channel.
---@return dreamwork.std.Color color The color object.
function Color:getLerped( color, frac, with_alpha )
    return self:copy():lerp( color, frac, with_alpha )
end

--- [SHARED AND MENU]
---
--- Returns the color's hue.
---
---@return integer hue The hue in degrees [0, 360].
function Color:getHue()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local max_value = math_max( red, green, blue )

    local delta = max_value - math_min( red, green, blue )
    if delta == 0 then
        return 0
    end

    local hue
    if max_value == red then
        hue = ( ( green - blue ) / delta ) % 6
    elseif max_value == green then
        hue = ( ( blue - red ) / delta ) + 2
    else
        hue = ( ( red - green ) / delta ) + 4
    end

    hue = hue * 60

    return hue < 0 and hue + 360 or hue
end

--- [SHARED AND MENU]
---
--- Sets the color's hue.
---
---@param hue integer The hue in degrees [0, 360].
---@return dreamwork.std.Color color The color object.
function Color:setHue( hue )
    local _, saturation, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's saturation.
---
---@return number saturation The saturation as fraction [0, 1].
function Color:getSaturation()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    local max_value = math_max( red, green, blue )
    return max_value == 0 and 0 or ( max_value - math_min( red, green, blue ) ) / max_value
end

--- [SHARED AND MENU]
---
--- Sets the color's saturation.
---
---@param saturation number The saturation as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:setSaturation( saturation )
    local hue, _, lightness = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's brightness.
---
---@return number brightness The brightness as fraction [0, 1].
function Color:getBrightness()
    return math_max( self.r, self.g, self.b ) * DIV255_CONST
end

--- [SHARED AND MENU]
---
--- Sets the color's brightness.
---
---@param brightness number The brightness as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:setBrightness( brightness )
    local hue, saturation, _ = self:toHSV()
    return self:fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's lightness.
---
---@return number lightness The lightness as fraction [0, 1].
function Color:getLightness()
    local red, green, blue = self.r * DIV255_CONST, self.g * DIV255_CONST, self.b * DIV255_CONST
    return ( math_max( red, green, blue ) + math_min( red, green, blue ) ) * 0.5
end

--- [SHARED AND MENU]
---
--- Sets the color's lightness.
---
---@param lightness number The lightness as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:setLightness( lightness )
    local hue, saturation, _ = self:toHSL()
    return self:fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Returns the color's whiteness.
---
---@return number whiteness The whiteness as fraction [0, 1].
function Color:getWhiteness()
    local _, saturation, brightness = self:toHSL()
    return ( 1 - saturation ) * brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's whiteness.
---
---@param whiteness number The whiteness as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:setWhiteness( whiteness )
    local hue, _, blackness = self:toHWB()
    return self:fromHWB( hue, whiteness, blackness )
end

--- [SHARED AND MENU]
---
--- Returns the color's blackness.
---
---@return number blackness The blackness as fraction [0, 1].
function Color:getBlackness()
    local _, __, brightness = self:toHSL()
    return 1 - brightness
end

--- [SHARED AND MENU]
---
--- Sets the color's blackness.
---
---@param blackness number The blackness as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:setBlackness( blackness )
    local hue, saturation, _ = self:toHSL()
    return self:fromHSL( hue, saturation, blackness )
end

do

    local math_ceil = math.ceil

    --- [SHARED AND MENU]
    ---
    --- Returns the color's luminance.
    ---
    ---@return number luminance The luminance as integer [0, 255].
    function Color:getLuminance()
        return math_ceil( self.r * 0.2126 + self.g * 0.7152 + self.b * 0.0722 )
    end

end

do

    local bytepack_readHex8 = std.pack.bytes.readHex8

    --- [SHARED AND MENU]
    ---
    --- Changes the color to hex string.
    ---
    --- Supports hex strings from `0` to `8` characters.
    ---
    ---@param hex string The hex string. If the first character is `#`, it will be ignored.
    ---@param alpha_first? boolean In specific cases alpha is first hex characters, so if this is `true`, alpha will be first.
    ---@return dreamwork.std.Color color The color object.
    function Color:fromHex( hex, alpha_first )
        local hex_length = string_len( hex )
        local index

        if string_byte( hex, 1 ) == 0x23 --[[ # ]] then
            hex_length = hex_length - 1
            index = 2
        else
            index = 1
        end

        if hex_length == 1 then
            local uint8_1 = string_byte( hex, index, index )
            self.r = bytepack_readHex8( uint8_1, uint8_1 ) or 0
            self.g = 0
            self.b = 0
            self.a = 255
        elseif hex_length == 2 then
            local uint8_1, uint8_2 = string_byte( hex, index, index + 1 )
            self.r = bytepack_readHex8( uint8_1, uint8_1 ) or 0
            self.g = bytepack_readHex8( uint8_2, uint8_2 ) or 0
            self.b = 0
            self.a = 255
        elseif hex_length == 3 then
            local uint8_1, uint8_2, uint8_3 = string_byte( hex, index, index + 2 )
            self.r = bytepack_readHex8( uint8_1, uint8_1 ) or 0
            self.g = bytepack_readHex8( uint8_2, uint8_2 ) or 0
            self.b = bytepack_readHex8( uint8_3, uint8_3 ) or 0
            self.a = 255
        elseif hex_length == 4 then
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( hex, index, index + 3 )
            self.r = bytepack_readHex8( uint8_1, uint8_1 ) or 0
            self.g = bytepack_readHex8( uint8_2, uint8_2 ) or 0
            self.b = bytepack_readHex8( uint8_3, uint8_3 ) or 0
            self.a = bytepack_readHex8( uint8_4, uint8_4 ) or 0
        elseif hex_length == 6 then
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 = string_byte( hex, index, index + 5 )
            self.r = bytepack_readHex8( uint8_1, uint8_2 ) or 0
            self.g = bytepack_readHex8( uint8_3, uint8_4 ) or 0
            self.b = bytepack_readHex8( uint8_5, uint8_6 ) or 0
            self.a = 255
        elseif hex_length == 8 then
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = string_byte( hex, index, index + 7 )
            self.r = bytepack_readHex8( uint8_1, uint8_2 ) or 0
            self.g = bytepack_readHex8( uint8_3, uint8_4 ) or 0
            self.b = bytepack_readHex8( uint8_5, uint8_6 ) or 0
            self.a = bytepack_readHex8( uint8_7, uint8_8 ) or 0
        end

        if alpha_first then
            self.a, self.r, self.g, self.b = self.r, self.g, self.b, self.a
        end

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a color object from hex string.
    ---
    ---@param hex string The hex string. If the first character is `#`, it will be ignored.
    ---@param alpha_first? boolean In specific cases alpha is first hex characters, so if this is `true`, alpha will be first.
    ---@return dreamwork.std.Color color The color object.
    function ColorClass.fromHex( hex, alpha_first )
        return from_rgba( 0, 0, 0, 255 ):fromHex( hex, alpha_first )
    end

end

do

    local bit_band, bit_rshift = bit.band, bit.rshift

    --- [SHARED AND MENU]
    ---
    --- Changes the color to 32-bit uint.
    ---
    ---@param uint32 integer The 32-bit uint.
    ---@param with_alpha boolean? Whether to include alpha.
    ---@return dreamwork.std.Color color The color object.
    function Color:fromUInt32( uint32, with_alpha )
        with_alpha = with_alpha == true

        self.r = bit_rshift( bit_band( uint32, 0xFF000000 ), with_alpha and 24 or 16 )
        self.g = bit_rshift( bit_band( uint32, 0x00FF0000 ), with_alpha and 16 or 8 )

        if with_alpha then
            self.b = bit_rshift( bit_band( uint32, 0x0000FF00 ), 8 )
        else
            self.b = bit_band( uint32, 0x0000FF00 )
        end

        if with_alpha then
            self.a = bit_band( uint32, 0x000000FF )
        else
            self.a = 255
        end

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a color object from 32-bit uint.
    ---
    ---@param uint32 integer The 32-bit uint.
    ---@param with_alpha boolean? Whether to include alpha.
    ---@return dreamwork.std.Color color The color object.
    function ColorClass.fromUInt32( uint32, with_alpha )
        return from_rgba( 0, 0, 0, 255 ):fromUInt32( uint32, with_alpha )
    end

end

--- [SHARED AND MENU]
---
--- Changes the color to binary string.
---
---@param binary string The binary string.
---@return dreamwork.std.Color color The color object.
function Color:fromBinary( binary )
    local length = string_len( binary )
    if length == 1 then
        self.r = string_byte( binary, 1 )
        self.g = 0
        self.b = 0
        self.a = 255
    elseif length == 2 then
        self.r = string_byte( binary, 1 )
        self.b = string_byte( binary, 2 )
        self.g = 0
        self.a = 255
    elseif length == 3 then
        self.r = string_byte( binary, 1 )
        self.g = string_byte( binary, 2 )
        self.b = string_byte( binary, 3 )
        self.a = 255
    else
        self.r = string_byte( binary, 1 )
        self.g = string_byte( binary, 2 )
        self.b = string_byte( binary, 3 )
        self.a = string_byte( binary, 4 )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from binary string.
---
---@param binary string The binary string.
---@return dreamwork.std.Color color The color object.
function ColorClass.fromBinary( binary )
    return from_rgba( 0, 0, 0, 255 ):fromBinary( binary )
end

--- [SHARED AND MENU]
---
--- Changes the color to HSL.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:fromHSL( hue, saturation, lightness )
    hue = hue % 360

    local c = ( 1 - math_abs( 2 * lightness - 1 ) ) * saturation
    local x = c * ( 1 - math_abs( ( hue / 60 ) % 2 - 1 ) )
    local m = lightness - ( c * 0.5 )

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

    self.r = math_floor( ( r + m ) * 255 )
    self.g = math_floor( ( g + m ) * 255 )
    self.b = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from HSL values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param lightness number The lightness [0, 1].
---@return dreamwork.std.Color color The color object.
function ColorClass.fromHSL( hue, saturation, lightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSL( hue, saturation, lightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:fromHSV( hue, saturation, brightness )
    hue = hue % 360

    local c = brightness * saturation
    local x = c * ( 1 - math_abs( ( hue / 60 ) % 2 - 1 ) )
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

    self.r = math_floor( ( r + m ) * 255 )
    self.g = math_floor( ( g + m ) * 255 )
    self.b = math_floor( ( b + m ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from HSV values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return dreamwork.std.Color color The color object.
function ColorClass.fromHSV( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHSV( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:fromHWB( hue, saturation, brightness )
    brightness = 1 - brightness
    return self:fromHSV( hue, ( brightness > 0 ) and ( 1 - ( saturation / brightness ) ) or 0, brightness )
end

--- [SHARED AND MENU]
---
--- Creates a color object from HWB values.
---
---@param hue integer The hue in degrees [0, 360].
---@param saturation number The saturation [0, 1].
---@param brightness number The brightness [0, 1].
---@return dreamwork.std.Color color The color object.
function ColorClass.fromHWB( hue, saturation, brightness )
    return from_rgba( 0, 0, 0, 255 ):fromHWB( hue, saturation, brightness )
end

--- [SHARED AND MENU]
---
--- Changes the color to CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function Color:fromCMYK( cyan, magenta, yellow, black )
    cyan, magenta, yellow, black = cyan * 0.01, magenta * 0.01, yellow * 0.01, black * 0.01

    local mk = 1 - black

    self.r = math_floor( ( ( 1 - cyan ) * mk ) * 255 )
    self.g = math_floor( ( ( 1 - magenta ) * mk ) * 255 )
    self.b = math_floor( ( ( 1 - yellow ) * mk ) * 255 )
    return self
end

--- [SHARED AND MENU]
---
--- Creates a color object from CMYK values.
---
---@param cyan number The cyan as fraction [0, 1].
---@param magenta number The magenta as fraction [0, 1].
---@param yellow number The yellow as fraction [0, 1].
---@param black number The black as fraction [0, 1].
---@return dreamwork.std.Color color The color object.
function ColorClass.fromCMYK( cyan, magenta, yellow, black )
    return from_rgba( 0, 0, 0, 255 ):fromCMYK( cyan, magenta, yellow, black )
end

if std.CLIENT then

    local render_ReadPixel

    ---@diagnostic disable-next-line: undefined-field
    local glua_render = _G.render
    if glua_render ~= nil then
        render_ReadPixel = glua_render.ReadPixel
    end

    if render_ReadPixel == nil then

        function render_ReadPixel( x, y )
            return 0, 0, 0, 255
        end

    end

    --- [CLIENT]
    ---
    --- Creates a color object from screen coordinates by reading a pixel.
    ---
    --- Requires `render.CapturePixels` call before using.
    ---
    ---@see https://wiki.facepunch.com/gmod/render.ReadPixel
    ---@param x integer The x coordinate.
    ---@param y integer The y coordinate.
    ---@param alpha integer? The alpha channel.
    ---@return dreamwork.std.Color
    function ColorClass.fromScreen( x, y, alpha )
        local r, g, b, a = render_ReadPixel( x, y )
        return from_rgba( r, g, b, alpha or a )
    end

end

do

    local debug_getmetatable = std.debug.getmetatable
    local isString = std.isString

    --- [SHARED AND MENU]
    ---
    --- Checks if the value is a color object.
    ---@param value any The value to check.
    ---@return boolean
    function std.isColor( value )
        return debug_getmetatable( value ) == Color
    end

    --- [SHARED AND MENU]
    ---
    --- A table containing named colors.
    ---
    --- Also takes colors from `resource/ClientScheme.res` if available. [CLIENT/MENU?]
    ---
    --- If no color is found, a new empty color will be created and assigned to specified name.
    ---
    --- Table key must be string or integer.
    ---
    ---@type table<string | integer, dreamwork.std.Color>
    local scheme = ColorClass.scheme or {}
    ColorClass.scheme = scheme

    local metatable = debug_getmetatable( scheme ) or {}

    ---@protected
    function metatable:__tostring()
        return string_format( "Color Scheme: %p", self )
    end

    setmetatable( scheme, metatable )

    ---@diagnostic disable-next-line: undefined-field
    local NamedColor = _G.NamedColor or std.debug.fempty

    ---@protected
    function metatable:__index( name )
        local color
        if isString( name ) then
            ---@diagnostic disable-next-line: redundant-parameter
            color = NamedColor( name )

            if color == nil then
                color = from_rgba( 255, 255, 255, 255 )
            else
                setmetatable( color, Color )
            end
        elseif isNumber( name ) then
            color = from_rgba( name, name, name, 255 )
        else
            error( "Color name must be string or integer!", 3 )
        end

        scheme[ name ] = color
        return color
    end

end
