local glua_math = math

---@class dreamwork.std
local std = dreamwork.std

local len = std.len

local debug = std.debug
local debug_getmetavalue = debug.getmetavalue

--- [SHARED AND MENU]
---
--- The powerful math library.
---
---@class dreamwork.std.math
---@field e number A variable containing the mathematical constant e. [`2.7182818284590`]
---@field ln2 number A variable containing the mathematical constant natural logarithm of 2. [`0.69314718055995`]
---@field nan number A variable containing number "not a number". [`nan`]
---@field pi number A variable containing the mathematical *π* constant. [`3.1415926535898`]
---@field huge number A variable that effectively represents infinity, in the sense that in any numerical comparison every number will be less than this. [`inf`]
---@field tiny number A variable that effectively represents negative infinity, in the sense that in any numerical comparison every number will be greater than this. [`-inf`]
---@field ln10 number A variable containing the mathematical constant natural logarithm of 10. (2.3025850929940)
---@field log10e number A variable containing the mathematical constant logarithm of 10 to the base e. (0.43429448190325)
---@field log2e number A variable containing the mathematical constant logarithm of 2 to the base e. (1.4426950408889)
---@field sqrt2 number A variable containing the mathematical constant square root of 2. (1.4142135623731)
---@field sqrt1_2 number A variable containing the mathematical constant square root of 1/2. (0.70710678118655)
---@field randomseed number A variable containing the current random seed and can be changed to set a new seed.
local math = {
    pi = glua_math.pi or 3.1415926535898,
    huge = glua_math.huge or (1 / 0),
    nan = 0 / 0,

    abs = glua_math.abs,
    exp = glua_math.exp,
    fmod = glua_math.fmod,
    modf = glua_math.modf,
    sqrt = glua_math.sqrt,

    sin = glua_math.sin,
    asin = glua_math.asin,
    sinh = glua_math.sinh,

    cos = glua_math.cos,
    acos = glua_math.acos,
    cosh = glua_math.cosh,

    tan = glua_math.tan,
    atan2 = glua_math.atan2,
    atan51 = glua_math.atan,
    tanh = glua_math.tanh,

    min = glua_math.min,
    max = glua_math.max,

    ceil = glua_math.ceil,
    floor = glua_math.floor,

    log = glua_math.log,
    log10 = glua_math.log10,

    deg = glua_math.deg,
    rad = glua_math.rad,

    random = glua_math.random,

    frexp = glua_math.frexp,
    ldexp = glua_math.ldexp,
}

std.math = math

local math_sqrt, math_log = math.sqrt, math.log
local math_min, math_max = math.min, math.max
local math_floor = math.floor
local math_abs = math.abs

local math_huge = math.huge
local math_pi = math.pi

local math_tiny = -math_huge
math.tiny = math_tiny

-- constants
do

    local e = math.exp( 1 )
    math.e = e

    math.ln2 = math_log( 2 )
    math.ln10 = math_log( 10.0 )
    math.log10e = math_log( e, 10.0 )
    math.log2e = math_log( e, 2.0 )
    math.sqrt2 = math_sqrt( 2.0 )
    math.sqrt1_2 = math_sqrt( 0.5 )

end

do

    local math_atan51 = math.atan51

    --- [SHARED AND MENU]
    ---
    --- Returns the cotangent of the given angle.
    ---
    ---@param x number The angle in radians.
    ---@return number cotangent The cotangent of the given angle.
    function math.cot( x )
        return 1 / math_atan51( x )
    end

end

if math.atan == nil then

    local math_atan51 = math.atan51

    --- [SHARED AND MENU]
    ---
    --- Returns the arc tangent of y/x.
    ---
    ---@param y number The y coordinate.
    ---@param x number The x coordinate.
    ---@return number arc_tan The arc tangent of y/x.
    function math.atan( y, x )
        if x == nil then
            return math_atan51( y )
        elseif y == 0 then
            return 0.0
        elseif x == 0 then
            return math_pi * 0.5
        end

        return math_atan51( y / x )
    end

end

if math.frexp == nil then

    local math_ln2 = math.ln2

    --- [SHARED AND MENU]
    ---
    --- Returns `m` and `e` such that `x = m2e`, `e` is an integer and the absolute value of `m` is in the range ((0.5, 1) (or zero when x is zero).
    ---
    --- Used to split the number value into a normalized fraction and an exponent.
    --- Two values are returned: the first is a multiplier in the range
    --- `1/2` (inclusive) to `1` (exclusive) and the second is an integer exponent.
    ---
    --- The result is such that `x = m*2^e`.
    ---
    ---@param x number The number to split.
    ---@return number m The normalized fraction.
    ---@return number e The exponent.
    ---@diagnostic disable-next-line: duplicate-set-field
    function math.frexp( x )
        if x == 0 then
            return 0.0, 0.0
        end

        local exponent = math_floor( math_log( math_abs( x ) ) / math_ln2 )
        if exponent > 0.0 then
            x = x * (2.0 ^ -exponent)
        else
            x = x / (2.0 ^ exponent)
        end

        if math_abs( x ) >= 1.0 then
            return x / 2.0, exponent + 1
        else
            return x, exponent
        end
    end

end

if math.ldexp == nil then

    --- [SHARED AND MENU]
    ---
    --- Takes a normalised number and returns the floating point representation.
    ---
    --- Effectively it returns the result of `normalizedFraction * 2.0 ^ exponent`.
    ---
    ---@see dreamwork.std.math.frexp opposite function
    ---@param x number The base value.
    ---@param exponent number The exponent.
    ---@return number float The floating point representation.
    ---@diagnostic disable-next-line: duplicate-set-field
    function math.ldexp( x, exponent )
        return x * 2.0 ^ exponent
    end

end

if std.debug.getmetatable( math ) == nil then

    local math_randomseed = glua_math.randomseed
    local raw_set = std.raw.set

    local seed = 0

    std.setmetatable( math, {
        __index = function( _, key )
            if key == "randomseed" then
                return seed
            end
        end,
        __newindex = function( self, key, value )
            if key == "randomseed" then
                math_randomseed( value )
                seed = value
            else
                raw_set( self, key, value )
            end
        end
    } )

end

--- [SHARED AND MENU]
---
--- Checks if a number is a byte (8-bit).
---
---@param x number The number to check.
---@param signed boolean `true` if the number is signed, otherwise `false`.
---@return boolean is_byte `true` if the number is an integer, otherwise `false`.
function math.isByte( x, signed )
    if (x % 1) ~= 0 then
        return false
    elseif signed then
        return x >= -128 and x <= 127
    else
        return x >= 0 and x <= 255
    end
end

--- [SHARED AND MENU]
---
--- Checks if a number is a short integer (16-bit).
---
---@param x number The number to check.
---@param signed boolean `true` if the number is signed, otherwise `false`.
---@return boolean is_short `true` if the number is an integer, otherwise `false`.
function math.isShort( x, signed )
    if (x % 1) ~= 0 then
        return false
    elseif signed then
        return x >= -32768 and x <= 32767
    else
        return x >= 0 and x <= 65535
    end
end

--- [SHARED AND MENU]
---
--- Checks if a number is a long integer (32-bit).
---
---@param x number The number to check.
---@param signed boolean `true` if the number is signed, otherwise `false`.
---@return boolean is_long `true` if the number is an integer, otherwise `false`.
function math.isLong( x, signed )
    if (x % 1) ~= 0 then
        return false
    elseif signed then
        return x >= -2147483648 and x <= 2147483647
    else
        return x >= 0 and x <= 4294967295
    end
end

--- [SHARED AND MENU]
---
--- Checks if a number is an unsigned integer.
---
---@param x number The number to check.
---@return boolean is_uint `true` if the number is an integer, otherwise `false`.
function math.isUInt( x )
    return x >= 0 and (x % 1) == 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is an signed integer.
---
---@param x number The number to check.
---@return boolean is_int `true` if the number is an integer, otherwise `false`.
function math.isInt( x )
    return (x % 1) == 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is a float (32-bit).
---
---@param x number The number to check.
---@return boolean is_float `true` if the number is a float, otherwise `false`.
function math.isFloat( x )
    return (x % 1) ~= 0 and x >= 1.175494351E-38 and x <= 3.402823466E+38
end

--- [SHARED AND MENU]
---
--- Checks if a number is a double.
---
---@param x number The number to check.
---@return boolean is_double `true` if the number is a double, otherwise `false`.
function math.isDouble( x )
    return (x % 1) ~= 0 and (x < 1.175494351E-38 or x > 3.402823466E+38)
end

--- [SHARED AND MENU]
---
--- Checks if a number is positive or negative infinity.
---
---@param x number The number to check.
---@return boolean is_inf `true` if the number is positive or negative infinity, otherwise `false`.
function math.isInf( x )
    return x == math_huge or x == math_tiny
end

--- [SHARED AND MENU]
---
--- Checks if a number is NaN.
---
---@param x number The number to check.
---@return boolean is_nan `true` if the number is NaN, otherwise `false`.
function math.isNaN( x )
    return x ~= x
end

--- [SHARED AND MENU]
---
--- Checks if a number is finite.
---
---@param x number The number to check.
---@return boolean is_finite `true` if the number is finite, otherwise `false`.
function math.isFinite( x )
    return x ~= math_huge and x ~= math_tiny and x == x
end

--- [SHARED AND MENU]
---
--- Checks if a number is divisible by another number without remainder.
---
---@param a number The first number to check.
---@param b number The second number to check.
---@return boolean is_divideable `true` if the first number is divisible by the second number, otherwise `false`.
function math.isDivideable( a, b )
    return (a % b) == 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is even.
---
---@param x number The number to check.
---@return boolean is_even `true` if the number is even, otherwise `false`.
function math.isEven( x )
    return x == 0 or (x % 2) == 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is odd.
---
---@param x number The number to check.
---@return boolean is_odd `true` if the number is odd, otherwise `false`.
function math.isOdd( x )
    return x ~= 0 and (x % 2) ~= 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is positive.
---
---@param x number The number to check.
---@return boolean is_positive `true` if the number is positive, otherwise `false`.
function math.isPositive( x )
    return (1 / x) > 0
end

--- [SHARED AND MENU]
---
--- Checks if a number is negative.
---
---@param x number The number to check.
---@return boolean is_negative `true` if the number is negative, otherwise `false`.
function math.isNegative( x )
    return (1 / x) < 0
end

do

    local math_frexp = math.frexp

    --- [SHARED AND MENU]
    ---
    --- Check if a value is a power-of-two.
    ---
    ---@param x number The number to check.
    ---@return boolean is_pot `true` if a number is a valid power-of-two, otherwise `false`.
    function math.isPowerOfTwo( x )
        return math_frexp( x ) == 0.5
    end

end

--- [SHARED AND MENU]
---
--- Rounds the given value to the nearest whole number or to the given decimal places.
---
---@param number number The number to round.
---@param decimals? integer The number of decimal places to round to.
---@return number rounded The rounded number.
function math.round( number, decimals )
    if decimals == nil then
        return math_floor( number + 0.5 )
    end

    local multiplier = 10 ^ decimals
    return math_floor( (number * multiplier) + 0.5 ) / multiplier
end

--- [SHARED AND MENU]
---
--- Returns the smallest integer greater than or equal to the given number.
---
---@param number number The number to round.
---@param step number The step size to round to.
---@return number snapped The rounded number.
function math.snap( number, step )
    return math_floor( (number / step) + 0.5 ) * step
end

do

    local math_modf = math.modf

    --- [SHARED AND MENU]
    ---
    --- Returns the integer part of the given number.
    ---
    ---@param x number The number to truncate.
    ---@return integer truncated The integer part of the number.
    function math.trunc( x )
        return (math_modf( x ))
    end

end

--- [SHARED AND MENU]
---
--- Wraps a number to keep it within a specific minimum and maximum range.
---
---@param value number The number to wrap.
---@param min number The lower limit of the wrap range.
---@param max number The upper limit of the wrap range.
---@return number wrapped The number wrapped within [min, max).
function math.wrap( value, min, max )
    return ((value - min) % (max - min)) + min
end

--- [SHARED AND MENU]
---
--- Returns the natural logarithm of the given number.
---
---@param x number The number to calculate the logarithm of.
---@return number log The natural logarithm of the number.
function math.log1p( x )
    return math_log( x + 1 )
end

do

    local math_ln2 = math.ln2

    --- [SHARED AND MENU]
    ---
    --- Returns the base 2 logarithm of the given number.
    ---
    ---@param x number The number to calculate the logarithm of.
    ---@return number log2 The base 2 logarithm of the number.
    function math.log2( x )
        return math_log( x ) / math_ln2
    end

end

do

    local math_random = math.random

    --- [SHARED AND MENU]
    ---
    --- Returns a random floating point number in the range [a, b).
    ---
    ---@param a number The minimum value.
    ---@param b number The maximum value.
    ---@return number float The random floating point number.
    function math.randomf( a, b )
        return a + (b - a) * math_random()
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the square root of the sum of squares of its arguments.
    ---
    ---@param numbers number[] The numbers to calculate the square root of.
    ---@param number_count integer? The number of numbers to calculate the square root of.
    ---@return number value The square root of the sum of squares of its arguments.
    function math.hypot( numbers, number_count )
        local number = 0
        for index = 1, (number_count or len( numbers )), 1 do
            number = number + (numbers[ index ] ^ 2)
        end

        return math_sqrt( number )
    end

end

do

    local one_third = 1 / 3

    --- [SHARED AND MENU]
    ---
    --- Returns the cube root of the given number.
    ---
    ---@param x number The number to calculate the cube root of.
    ---@return number cube The cube root of the number.
    function math.cbrt( x )
        return x ^ one_third
    end

end

--- [SHARED AND MENU]
---
--- Returns the root of a given number with a given base.
---
---@param a number The number to calculate the root of.
---@param b number The base of the root.
---@return number root The root of the number.
function math.root( a, b )
    return a ^ (1 / b)
end

--- [SHARED AND MENU]
---
--- Gradually approaches the target value by the specified amount.
---
---@param current number The current value.
---@param target number The target value.
---@param change number The amount that the current value is allowed to change by to approach the target.
---@return number approached The approached value.
function math.approach( current, target, change )
    local diff = target - current
    if diff < 0 then
        return current - math_min( -diff, change )
    else
        return current + math_min( diff, change )
    end
end

--- [SHARED AND MENU]
---
--- Clamps a number between a minimum and maximum value.
---
---@param number number The number to clamp.
---@param min number The minimum value.
---@param max number The maximum value.
---@return number clamped The clamped number.
function math.clamp( number, min, max )
    return math_min( math_max( number, min ), max )
end

--- [SHARED AND MENU]
---
--- Performs a linear interpolation from the start number to the end number.
---
---@param fraction number The fraction of the way between the start and end numbers.
---@param from number The start number.
---@param to number The end number.
---@return number lerped The interpolated value.
function math.lerp( fraction, from, to )
    return from + (to - from) * fraction
end

--- [SHARED AND MENU]
---
--- Performs an inverse linear interpolation from the start number to the end number.
---
---@param result number The interpolated value.
---@param from number The start number.
---@param to number The end number.
---@return number lerped The fraction of the way between the start and end numbers.
function math.ilerp( result, from, to )
    return (result - from) / (to - from)
end

--- [SHARED AND MENU]
---
--- Performs a smooth interpolation from the start number to the end number.
---
---@param previous number The previous value.
---@param next number The next value.
---@param alpha number The amount of smoothing.
---@return number value The interpolated value.
function math.smooth( previous, next, alpha )
    return alpha * next + (1 - alpha) * previous
end

--- [SHARED AND MENU]
---
--- Remaps a number from one range to another.
---
---@param number number The number to remap.
---@param inMin number The minimum value of the input range.
---@param inMax number The maximum value of the input range.
---@param outMin number The minimum value of the output range.
---@param outMax number The maximum value of the output range.
---@return number value The remapped value.
function math.remap( number, inMin, inMax, outMin, outMax )
    return outMin + (outMax - outMin) * (number - inMin) / (inMax - inMin)
end

--- [SHARED AND MENU]
---
--- Checks if a number is in a range.
---
---@param number number The number to check.
---@param from number The minimum value of the range.
---@param to number The maximum value of the range.
---@return boolean in_range `true` if the number is in the range, otherwise `false`.
function math.inRange( number, from, to )
    return number >= from and number <= to
end

do

    local math_atan = math.atan
    local math_deg = math.deg

    --- [SHARED AND MENU]
    ---
    --- Calculates the angle between two points.
    ---
    ---@param x1 number The x coordinate of the first point.
    ---@param y1 number The y coordinate of the first point.
    ---@param x2 number The x coordinate of the second point.
    ---@param y2 number The y coordinate of the second point.
    ---@return number angle The angle between the two points.
    function math.angle( x1, y1, x2, y2 )
        return math_deg( math_atan( y2 - y1, x2 - x1 ) )
    end

end

--- [SHARED AND MENU]
---
--- Returns the normalised angle between two points.
---
---@param angle number The angle to normalise.
---@return number normalised The normalised angle.
local function angleNormalize( angle )
    return ((angle + 180) % 360) - 180
end

math.angleNormalize = angleNormalize

--- [SHARED AND MENU]
---
--- Returns the difference between two angles.
---
---@param a number The first angle.
---@param b number The second angle.
---@return number diff The difference between the angles.
function math.angleDifference( a, b )
    local diff = angleNormalize( a - b )
    if diff < 180 then
        return diff
    end

    return diff - 360
end

--- [SHARED AND MENU]
---
--- Calculates the magnitude (distance) between two points.
---
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number magnitude The magnitude between the two points.
local function magnitude( x1, y1, x2, y2 )
    return math_sqrt( ((x2 - x1) ^ 2) + ((y2 - y1) ^ 2) )
end

math.magnitude = magnitude

--- [SHARED AND MENU]
---
--- Calculates the direction between two points.
---
---@param x1 number The x coordinate of the first point.
---@param y1 number The y coordinate of the first point.
---@param x2 number The x coordinate of the second point.
---@param y2 number The y coordinate of the second point.
---@return number x The x coordinate of the direction.
---@return number y The y coordinate of the direction.
function math.direction( x1, y1, x2, y2 )
    local diff = magnitude( x1, y1, x2, y2 )
    if diff == 0 then
        return 0, 0
    end

    return (x2 - x1) / diff, (y2 - y1) / diff
end

--- [SHARED AND MENU]
---
--- Calculates the euclidean modulus.
---
---@param numerator number The numerator.
---@param denominator number The denominator.
---@return number mod The euclidean modulus.
function math.euclideanMod( numerator, denominator )
    local result = numerator % denominator
    if result < 0 then
        return result + denominator
    else
        return result
    end
end

--- [SHARED AND MENU]
---
--- Check if value is equal or greater than threshold.
---
--- **NOTE**: This is useful to mitigate [accuracy issues in floating point numbers](https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems).
---
--- Examples:
--- ```lua
--- local a = 10
--- local b = 13.3
---
--- if math.threshold( a - b, 4 ) then
---     print( "yes" )
--- else
---     print( "no" )
--- end
---
--- -- print: `no` because difference between a and b is not so far from 4
--- ```
---
---@param x number The number to check.
---@param threshold number? The maximum difference between numbers at which they are considered equal; by default `1e-8`.
---@return boolean is_greater_equal `true` if the numbers are equal or greater, otherwise `false`.
function math.threshold( x, threshold )
    return math_abs( x ) >= (threshold or 1e-8)
end

--- [SHARED AND MENU]
---
--- Check if value is equal or less than threshold.
---
--- **NOTE**: This is useful to mitigate [accuracy issues in floating point numbers](https://en.wikipedia.org/wiki/Floating-point_arithmetic#Accuracy_problems).
---
--- Examples:
--- ```lua
--- local a = 10
--- local b = 13.3
---
--- if math.tolerance( a - b, 4 ) then
---     print( "yes" )
--- else
---     print( "no" )
--- end
---
--- -- print: `yes` because difference between a and b is near of 4
--- ```
---
---@param x number The number to check.
---@param threshold number? The maximum difference between numbers at which they are considered equal; by default `1e-8`.
---@return boolean is_nearly_equal `true` if the numbers are equal or less, otherwise `false`.
function math.tolerance( x, threshold )
    return math_abs( x ) <= (threshold or 1e-8)
end

--- [SHARED AND MENU]
---
--- Returns `x` if its absolute value is equal to or greater than `size`, otherwise returns `0`.
---
---@param x number The number to check.
---@param size number The minimum allowed absolute value before snapping to 0.
---@return number result The original number, or 0.
function math.lower( x, size )
    return (math_abs( x ) < size) and 0 or x
end

--- [SHARED AND MENU]
---
--- Returns `x` if its absolute value is equal to or less than `size`, otherwise returns `0`.
---
--- Useful for ignoring extreme spikes or outliers in values.
---
---@param x number The number to check.
---@param size number The maximum allowed absolute value before snapping to 0.
---@return number result The original number, or 0.
function math.upper( x, size )
    return (math_abs( x ) > size) and 0 or x
end

--- [SHARED AND MENU]
---
--- Returns x with the same sign as y.
---
---@generic T : number | integer
---@param x T The number to copy the sign of.
---@param y number The number to get the sign from.
---@return T number The number with the sign of y.
function math.copySign( x, y )
    -- return ( ( x > 0 and y > 0 ) or ( x < 0 and y < 0 ) ) and x or -x -- x2 faster but miss -0 cases
    return ((1 / x) > 0) == ((1 / y) > 0) and x or -x
end

--- [SHARED AND MENU]
---
--- Converts an integer with a sign to an unsigned integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@param bit_count integer The bit count of the unsigned integer.
---@return T unsigned The unsigned integer.
function math.toUInt( x, bit_count )
    return x % (2 ^ bit_count)
end

--- [SHARED AND MENU]
---
--- Converts an signed integer with a sign to an integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@param bit_count integer The bit count of the signed integer.
---@return T signed The integer with a sign.
function math.toInt( x, bit_count )
    local uint_limit = 2 ^ bit_count
    x = x % uint_limit

    if x < (2 ^ (bit_count - 1)) then
        return x
    else
        return x - uint_limit
    end
end

--- [SHARED AND MENU]
---
--- Converts a number to a 32-bit unsigned integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@return T unsigned The 32-bit unsigned integer.
function math.toUInt32( x )
    return x % 0x100000000
end

--- [SHARED AND MENU]
---
--- Converts a number to a 32-bit signed integer.
---
---@generic T : number | integer
---@param x T The number to convert.
---@return T signed The 32-bit signed integer.
function math.toInt32( x )
    x = x % 0x100000000

    if x < 0x80000000 then
        return x
    else
        return x - 0x100000000
    end
end

--- [SHARED AND MENU]
---
--- Converts a number to a float32.
---
---@param number number The number to convert.
---@return number float The float32 number.
function math.toFloat32( number )
    return math_floor( (number * 1e+06) + 0.5 ) * 1e-06
end

--- [SHARED AND MENU]
---
--- Returns a function that bucketizes a number.
---
---@generic T : number | integer
---@param y T The bucket size.
---@return fun( x: number ): T bucketizer The bucketizer function.
function math.bucketize( y )
    local div = 1 / y
    return function( x )
        return math_floor( x * div ) * y
    end
end

--- [SHARED AND MENU]
---
--- Translate a relative position, negative means back from end.
---
---@param position integer The position to check.
---@param length integer The length to check.
---@param fallback? integer The fallback position.
---@return integer relative The relative position.
function math.relative( position, length, fallback )
    if (0 - position) > length then
        return fallback or 1
    else
        return length + position + 1
    end
end

do

    local math_log10 = math.log10

    --- [SHARED AND MENU]
    ---
    --- Returns the length of the integer.
    ---
    ---@param x integer The integer to check.
    ---@return integer length The length of the integer.
    function math.len( x )
        if x == 0 then
            return 1
        end

        return math_floor( math_log10( math_abs( x ) ) ) + 1
    end

end

--- [SHARED AND MENU]
---
--- Returns the floor division of two numbers.
---
---@generic T: number | any
---@param a T The first number.
---@param b T The second number.
---@return T x The floor division of the two numbers.
function math.fdiv( a, b )
    local fn = debug_getmetavalue( a, "__idiv" )
    if fn == nil then
        return math_floor( a / b )
    else
        return fn( a, b )
    end
end

-- Source code of functions
-- https://github.com/Facepunch/garrysmod/pull/1755
-- https://web.archive.org/web/20201212082306/https://easings.net/
-- https://web.archive.org/web/20201218211606/https://raw.githubusercontent.com/ai/easings.net/master/src/easings.yml

do

    local math_cos = math.cos
    local math_sin = math.sin

    local c1 = 1.70158
    local c3 = c1 + 1
    local c2 = c1 * 1.525
    local c4 = (2 * math_pi) / 3
    local c5 = (2 * math_pi) / 4.5
    local n1 = 7.5625
    local d1 = 2.75

    --- [SHARED AND MENU]
    ---
    --- The math easing functions.
    ---
    ---@class dreamwork.std.math.ease
    local ease = {}
    math.ease = ease

    --- [SHARED AND MENU]
    ---
    --- Eases in using `math.sin`.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.sineIn( fraction )
        return 1 - math_cos( (fraction * math_pi) * 0.5 )
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out using `math.sin`.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.sineOut( fraction )
        return math_sin( (fraction * math_pi) * 0.5 )
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out using `math.sin`.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.sineInOut( fraction )
        return -(math_cos( math_pi * fraction ) - 1) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in by squaring the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quadIn( fraction )
        return fraction ^ 2
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out by squaring the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quadOut( fraction )
        return 1 - (1 - fraction) * (1 - fraction)
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out by squaring the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quadInOut( fraction )
        return fraction < 0.5 and 2 * fraction ^ 2
            or 1 - ((-2 * fraction + 2) ^ 2) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in by cubing the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.cubicIn( fraction )
        return fraction ^ 3
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out by cubing the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.cubicOut( fraction )
        return 1 - ((1 - fraction) ^ 3)
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out by cubing the fraction.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.cubicInOut( fraction )
        return fraction < 0.5 and 4 * fraction ^ 3
            or 1 - ((-2 * fraction + 2) ^ 3) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in by raising the fraction to the power of 4.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quartIn( fraction )
        return fraction ^ 4
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out by raising the fraction to the power of 4.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quartOut( fraction )
        return 1 - ((1 - fraction) ^ 4)
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out by raising the fraction to the power of 4.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quartInOut( fraction )
        return fraction < 0.5 and 8 * fraction ^ 4
            or 1 - ((-2 * fraction + 2) ^ 4) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in by raising the fraction to the power of 5.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quintIn( fraction )
        return fraction ^ 5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out by raising the fraction to the power of 5.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quintOut( fraction )
        return 1 - ((1 - fraction) ^ 5)
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out by raising the fraction to the power of 5.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.quintInOut( fraction )
        return fraction < 0.5 and 16 * fraction ^ 5
            or 1 - ((-2 * fraction + 2) ^ 5) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in using an exponential equation with a base of 2 and where the fraction is used in the exponent.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.expoIn( fraction )
        return fraction == 0 and 0 or (2 ^ (10 * fraction - 10))
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.expoOut( fraction )
        return fraction == 1 and 1 or 1 - (2 ^ (-10 * fraction))
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.expoInOut( fraction )
        return fraction == 0 and 0
            or fraction == 1 and 1
            or fraction < 0.5 and (2 ^ (20 * fraction - 10)) * 0.5 or (2 - (2 ^ (-20 * fraction + 10))) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in using a circular function.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.circIn( fraction )
        return 1 - math_sqrt( 1 - (fraction ^ 2) )
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out using a circular function.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.circOut( fraction )
        return math_sqrt( 1 - ((fraction - 1) ^ 2) )
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out using a circular function.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.circInOut( fraction )
        return fraction < 0.5 and (1 - math_sqrt( 1 - ((2 * fraction) ^ 2) )) * 0.5
            or (math_sqrt( 1 - ((-2 * fraction + 2) ^ 2) ) + 1) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in by reversing the direction of the ease slightly before returning.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.backIn( fraction )
        return c3 * fraction ^ 3 - c1 * fraction ^ 2
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out by reversing the direction of the ease slightly before finishing.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.backOut( fraction )
        return 1 + c3 * ((fraction - 1) ^ 3) + c1 * ((fraction - 1) ^ 2)
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out by reversing the direction of the ease slightly before returning on both ends.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.backInOut( fraction )
        return fraction < 0.5 and (((2 * fraction) ^ 2) * ((c2 + 1) * 2 * fraction - c2)) * 0.5
            or (((2 * fraction - 2) ^ 2) * ((c2 + 1) * (fraction * 2 - 2) + c2) + 2) * 0.5
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in like a rubber band.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.elasticIn( fraction )
        return fraction == 0 and 0
            or fraction == 1 and 1
            or -(2 ^ (10 * fraction - 10)) * math_sin( (fraction * 10 - 10.75) * c4 )
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out like a rubber band.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.elasticOut( fraction )
        return fraction == 0 and 0 or fraction == 1 and 1
            or (2 ^ (-10 * fraction)) * math_sin( (fraction * 10 - 0.75) * c4 ) + 1
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in and out like a rubber band.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.elasticInOut( fraction )
        return fraction == 0 and 0 or fraction == 1 and 1
            or fraction < 0.5 and -((2 ^ (20 * fraction - 10)) * math_sin( (20 * fraction - 11.125) * c5 )) * 0.5
            or ((2 ^ (-20 * fraction + 10)) * math_sin( (20 * fraction - 11.125) * c5 )) * 0.5 + 1
    end

    --- [SHARED AND MENU]
    ---
    --- Eases out like a bouncy ball.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    local function ease_bounceOut( fraction )
        if (fraction < 1 / d1) then
            return n1 * fraction ^ 2
        elseif (fraction < 2 / d1) then
            fraction = fraction - (1.5 / d1)
            return n1 * fraction ^ 2 + 0.75
        elseif (fraction < 2.5 / d1) then
            fraction = fraction - (2.25 / d1)
            return n1 * fraction ^ 2 + 0.9375
        else
            fraction = fraction - (2.625 / d1)
            return n1 * fraction ^ 2 + 0.984375
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Eases in like a bouncy ball.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.bounceIn( fraction )
        return 1 - ease_bounceOut( 1 - fraction )
    end

    ease.bounceOut = ease_bounceOut

    --- [SHARED AND MENU]
    ---
    --- Eases in and out like a bouncy ball.
    ---
    ---@param fraction number Fraction of the progress to ease, from 0 to 1.
    ---@return number eased The eased number.
    function ease.bounceInOut( fraction )
        return fraction < 0.5 and (1 - ease_bounceOut( 1 - 2 * fraction )) * 0.5
            or (1 + ease_bounceOut( 2 * fraction - 1 )) * 0.5
    end

end
