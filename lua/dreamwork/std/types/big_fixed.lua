---@class dreamwork.std
local std = dreamwork.std

local setmetatable = std.setmetatable
local tostring = std.tostring
local tonumber = std.tonumber

local isString = std.isString
local isNumber = std.isNumber

local raw = std.raw
local raw_equal = raw.equal

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_huge = math.huge
local math_floor = math.floor

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_format = string.format

local table = std.table
local table_concat = table.concat

local class = std.class

local BigIntegerClass = std.BigInteger
local toBigInteger = std.toBigInteger
local isBigInteger = std.isBigInteger

--- [SHARED AND MENU]
---
--- Represents an arbitrary-precision signed fixed-point decimal number.
---
--- A `BigFixed` object stores its value as a `BigInteger` mantissa together
--- with a `scale` (the number of digits kept after the decimal point).
--- The value represented is always `mantissa / 10^scale`.
---
--- Arithmetic between two `BigFixed` objects of different scales is always
--- performed at the wider (larger) of the two scales; multiplication and
--- division let you keep the receiver's scale (truncating, never rounding,
--- any extra digits produced by the operation).
---
---@class dreamwork.std.BigFixed : dreamwork.std.Object
---@field __class dreamwork.std.BigFixedClass
---@field mantissa dreamwork.std.BigInteger
---@field scale integer
---@operator add( any ): dreamwork.std.BigFixed
---@operator sub( any ): dreamwork.std.BigFixed
---@operator mul( any ): dreamwork.std.BigFixed
---@operator div( any ): dreamwork.std.BigFixed
---@operator unm: dreamwork.std.BigFixed
---@operator concat( any ): string
local BigFixed = class.base( "BigFixed", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `BigFixed` instances.
---
--- Arbitrary-precision fixed-point decimal type, backed by `BigInteger`.
---
---@class dreamwork.std.BigFixedClass : dreamwork.std.BigFixed
---@field __base dreamwork.std.BigFixed
---@field DEFAULT_SCALE integer
---@overload fun( value: ( dreamwork.std.BigFixed | dreamwork.std.BigInteger | string | number | nil ), scale: ( integer | nil ) ): dreamwork.std.BigFixed
local BigFixedClass = class.create( BigFixed )
std.BigFixed = BigFixedClass

--- The number of fractional decimal digits used when no explicit scale is given.
BigFixedClass.DEFAULT_SCALE = 18

--- [SHARED AND MENU]
---
--- Checks whether the value is a `BigFixed`.
---
---@param value any The value to check.
---@return boolean is_bigfixed `true` if the value is a `BigFixed`, `false` otherwise.
local function isBigFixed( value )
    return debug_getmetatable( value ) == BigFixed
end

std.isBigFixed = isBigFixed

--- powers of ten ( cached, read-only - never pass these to a mutating method )
---@type table<integer, dreamwork.std.BigInteger>
local pow10_cache = setmetatable( {
    [ 0 ] = toBigInteger( 1 )
}, {
    __index = function( self, n )
        local value = toBigInteger( 10 ):pow( n )
        self[ n ] = value
        return value
    end
} )

---@param n integer
---@return dreamwork.std.BigInteger
local function pow10( n )
    return pow10_cache[ n ]
end

--- [SHARED AND MENU]
---
--- Rescales a `BigFixed` object in place to the given number of fractional digits.
---
--- Growing the scale is exact ( zeros are appended ). Shrinking the scale
--- truncates the extra digits ( it does not round ).
---
---@param scale integer The new scale ( number of fractional digits ).
---@return dreamwork.std.BigFixed self
local function rescale( bigfixed, scale )
    local diff = scale - bigfixed.scale

    if diff > 0 then
        bigfixed.mantissa:mul( pow10( diff ) )
    elseif diff < 0 then
        bigfixed.mantissa:div( pow10( -diff ) )
    end

    bigfixed.scale = scale
    return bigfixed
end

function BigFixed:setScale( scale )
    return rescale( self, scale )
end

--- [SHARED AND MENU]
---
--- Returns the current scale ( number of fractional digits ) of the object.
---
---@return integer scale
function BigFixed:getScale()
    return self.scale
end

---@param bigfixed dreamwork.std.BigFixed
---@param str string
---@param scale integer
---@return dreamwork.std.BigFixed bigfixed
local function fromString( bigfixed, str, scale )
    local str_length = string_len( str )
    local position = 1

    local sign = false
    local first_byte = string_byte( str, 1 )

    if first_byte == 0x2d --[[ - ]] then
        sign = true
        position = 2
    elseif first_byte == 0x2b --[[ + ]] then
        position = 2
    end

    local dot_position = nil

    for i = position, str_length, 1 do
        if string_byte( str, i ) == 0x2e --[[ . ]] then
            dot_position = i
            break
        end
    end

    local integer_part, fractional_part

    if dot_position == nil then
        integer_part = string_sub( str, position, str_length )
        fractional_part = ""
    else
        integer_part = string_sub( str, position, dot_position - 1 )
        fractional_part = string_sub( str, dot_position + 1, str_length )
    end

    if integer_part == "" then
        integer_part = "0"
    end

    local fractional_length = string_len( fractional_part )

    if fractional_length > scale then
        fractional_part = string_sub( fractional_part, 1, scale ) -- truncate, no rounding
        fractional_length = scale
    end

    local mantissa = BigIntegerClass( integer_part .. fractional_part )

    if fractional_length < scale then
        mantissa:mul( pow10( scale - fractional_length ) )
    end

    if sign and not mantissa:isZero() then
        mantissa:negate()
    end

    bigfixed.mantissa = mantissa
    bigfixed.scale = scale

    return bigfixed
end

---@param bigfixed dreamwork.std.BigFixed
---@param value number
---@param scale integer
---@return dreamwork.std.BigFixed bigfixed
local function fromNumber( bigfixed, value, scale )
    if value ~= value or value == math_huge or value == -math_huge then
        error( "cannot convert NaN or infinity to a BigFixed", 4 )
    end

    -- fixed ( never scientific ) notation, so `fromString` can parse it directly
    return fromString( bigfixed, string_format( "%." .. (scale + 2) .. "f", value ), scale )
end

do

    ---@param value dreamwork.std.BigFixed | dreamwork.std.BigInteger | string | number | nil
    ---@param scale integer | nil
    ---@protected
    function BigFixed:__init( value, scale )
        if isBigFixed( value ) then
            ---@cast value dreamwork.std.BigFixed
            self.mantissa = value.mantissa:copy()
            self.scale = value.scale

            if scale ~= nil and scale ~= self.scale then
                rescale( self, scale )
            end

            return
        end

        scale = scale or BigFixedClass.DEFAULT_SCALE

        if value == nil then
            self.mantissa = toBigInteger( 0 )
            self.scale = scale
            return
        end

        if isBigInteger( value ) then
            ---@cast value dreamwork.std.BigInteger
            self.mantissa = value:copy()
            self.scale = 0
            rescale( self, scale )
            return
        end

        if isString( value ) then
            ---@cast value string
            fromString( self, value, scale )
            return
        end

        if isNumber( value ) then
            ---@cast value number
            fromNumber( self, value, scale )
            return
        end

        error( "given value cannot be converted to a BigFixed", 3 )
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a `BigFixed` object from the given value.
    ---
    --- If `value` is already a `BigFixed` at the requested scale, it is
    --- returned unchanged.
    ---
    ---@param value any The value to convert to a `BigFixed`.
    ---@param scale? integer The number of fractional digits to keep. Defaults to `BigFixed.DEFAULT_SCALE`.
    ---@return dreamwork.std.BigFixed obj
    function std.toBigFixed( value, scale )
        if isBigFixed( value ) and (scale == nil or scale == value.scale) then
            ---@cast value dreamwork.std.BigFixed
            return value
        end

        return BigFixedClass( value, scale )
    end

end

---
--- Converts an arithmetic operand into a read-only `BigFixed`.
---
--- Integers ( Lua or `BigInteger` ) become exact scale-0 values, so they
--- never widen the receiver's scale; other values are converted at `scale`.
---
--- The result may share its mantissa with `value`, never mutate it.
---
---@param value any
---@param scale integer
---@return dreamwork.std.BigFixed
local function toOperand( value, scale )
    if isBigFixed( value ) then
        ---@cast value dreamwork.std.BigFixed
        return value
    end

    if isBigInteger( value ) then
        return setmetatable( { mantissa = value, scale = 0 }, BigFixed )
    end

    if isNumber( value ) and math_floor( value ) == value and value ~= math_huge and value ~= -math_huge then
        return setmetatable( { mantissa = toBigInteger( value ), scale = 0 }, BigFixed )
    end

    return BigFixedClass( value, scale )
end

---
--- Converts the left operand of a binary metamethod into a fresh `BigFixed`
--- ( operands can come in any order, e.g. `2 * x`, then `self` is the number
--- and it is converted at the scale of the `BigFixed` on the right ).
---
---@param a any
---@param b dreamwork.std.BigFixed
---@return dreamwork.std.BigFixed
local function toLeft( a, b )
    if isBigFixed( a ) then
        ---@cast a dreamwork.std.BigFixed

        return setmetatable( {
            mantissa = a.mantissa:copy(),
            scale = a.scale,
        }, BigFixed )
    end

    return BigFixedClass( a, b.scale )
end

--- [SHARED AND MENU]
---
--- Checks if a big fixed object is zero.
---
---@return boolean is_zero
function BigFixed:isZero()
    return self.mantissa:isZero()
end

--- [SHARED AND MENU]
---
--- Checks if a big fixed object is negative.
---
---@return boolean is_negative
function BigFixed:isNegative()
    return self.mantissa.sign
end

---@protected
function BigFixed:__toboolean()
    return not self.mantissa:isZero()
end

--- [SHARED AND MENU]
---
--- Makes a copy of the `BigFixed` object.
---
---@return dreamwork.std.BigFixed new_obj
function BigFixed:copy()
    return setmetatable( {
        mantissa = self.mantissa:copy(),
        scale = self.scale
    }, BigFixed )
end

--- [SHARED AND MENU]
---
--- Negates a big fixed object.
---
---@return dreamwork.std.BigFixed self
function BigFixed:negate()
    self.mantissa:negate()
    return self
end

--- [SHARED AND MENU]
---
--- Makes a big fixed object absolute ( removes the sign ).
---
---@return dreamwork.std.BigFixed self
function BigFixed:abs()
    self.mantissa:abs()
    return self
end

local BigFixed_copy = BigFixed.copy
local BigFixed_negate = BigFixed.negate

---@return dreamwork.std.BigFixed new_obj
---@protected
function BigFixed:__unm()
    return BigFixed_negate( BigFixed_copy( self ) )
end

---@param a dreamwork.std.BigFixed
---@param b dreamwork.std.BigFixed
---@return `-1` | `0` | `1`
local function compare( a, b )
    local a_mantissa, b_mantissa = a.mantissa, b.mantissa

    if a.scale < b.scale then
        a_mantissa = a_mantissa:copy():mul( pow10( b.scale - a.scale ) )
    elseif b.scale < a.scale then
        b_mantissa = b_mantissa:copy():mul( pow10( a.scale - b.scale ) )
    end

    return a_mantissa:compare( b_mantissa )
end

--- [SHARED AND MENU]
---
--- Compares the `BigFixed` with the given value.
---
--- Unlike the `==`, `<` and `<=` operators, this also works with plain Lua numbers and strings.
---
---@param value any The value to compare with ( converted into `BigFixed` ).
---@return `-1` | `0` | `1` result `-1` if `self < value`, `0` if equal, `1` if `self > value`.
function BigFixed:compare( value )
    return compare( self, toOperand( value, BigFixedClass.DEFAULT_SCALE ) )
end

---@param value any
---@return boolean
---@protected
function BigFixed:__eq( value )
    local scale = BigFixedClass.DEFAULT_SCALE
    return compare( toOperand( self, scale ), toOperand( value, scale ) ) == 0
end

---@param value any
---@return boolean
---@protected
function BigFixed:__lt( value )
    local scale = BigFixedClass.DEFAULT_SCALE
    return compare( toOperand( self, scale ), toOperand( value, scale ) ) == -1
end

---@param value any
---@return boolean
---@protected
function BigFixed:__le( value )
    local scale = BigFixedClass.DEFAULT_SCALE
    return compare( toOperand( self, scale ), toOperand( value, scale ) ) <= 0
end

---@param self dreamwork.std.BigFixed
---@param value any
---@param subtract boolean
---@return dreamwork.std.BigFixed self
local function add( self, value, subtract )
    local b = toOperand( value, self.scale )

    local b_mantissa = b.mantissa
    if b.scale < self.scale then
        b_mantissa = b_mantissa:copy():mul( pow10( self.scale - b.scale ) )
    elseif b.scale > self.scale then
        rescale( self, b.scale )
    end

    if subtract then
        self.mantissa:sub( b_mantissa )
    else
        self.mantissa:add( b_mantissa )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Adds the given value to the current `BigFixed`, in place.
---
--- The result keeps the wider ( larger ) of the two scales; plain numbers,
--- strings and `BigInteger`s are converted at the receiver's scale.
---
---@param value any The second value to be converted into `BigFixed`.
---@return dreamwork.std.BigFixed self
function BigFixed:add( value )
    return add( self, value, false )
end

---@param value any
---@return dreamwork.std.BigFixed new_obj
---@protected
function BigFixed:__add( value )
    return add( toLeft( self, value ), value, false )
end

--- [SHARED AND MENU]
---
--- Subtracts the given value from the current `BigFixed`, in place.
---
---@param value any The second value to be converted into `BigFixed`.
---@return dreamwork.std.BigFixed self
function BigFixed:sub( value )
    return add( self, value, true )
end

BigFixed.subtract = BigFixed.sub

---@param value any
---@return dreamwork.std.BigFixed new_obj
---@protected
function BigFixed:__sub( value )
    return add( toLeft( self, value ), value, true )
end

--- [SHARED AND MENU]
---
--- Multiplies the current `BigFixed` by the given value, in place.
---
--- The result is truncated back down to the receiver's original scale
--- ( it is not rounded ).
---
---@param value any The second value to be converted into `BigFixed`.
---@return dreamwork.std.BigFixed self
function BigFixed:mul( value )
    local b = toOperand( value, self.scale )
    local result_scale = self.scale

    self.mantissa:mul( b.mantissa )
    self.scale = self.scale + b.scale

    if self.scale > result_scale then
        rescale( self, result_scale )
    end

    return self
end

local BigFixed_mul = BigFixed.mul

---@param value any
---@return dreamwork.std.BigFixed new_obj
---@protected
function BigFixed:__mul( value )
    return BigFixed_mul( toLeft( self, value ), value )
end

--- [SHARED AND MENU]
---
--- Divides the current `BigFixed` by the given value, in place.
---
--- The quotient is computed with ( and truncated to ) the receiver's
--- current scale.
---
---@param value any The value to divide by ( converted into `BigFixed` ).
---@return dreamwork.std.BigFixed self
function BigFixed:div( value )
    local b = toOperand( value, self.scale )

    local denominator = b.mantissa
    if denominator:isZero() then
        error( "attempt to divide by zero", 2 )
    end

    if raw_equal( denominator, self.mantissa ) then
        denominator = denominator:copy() -- self:div( self )
    end

    -- ( m1 / 10^s ) / ( m2 / 10^bs ) at scale s = m1 * 10^bs / m2
    local mantissa = self.mantissa

    if b.scale ~= 0 then
        mantissa:mul( pow10( b.scale ) )
    end

    mantissa:div( denominator )

    return self
end

local BigFixed_div = BigFixed.div

---@param value any
---@return dreamwork.std.BigFixed new_obj
---@protected
function BigFixed:__div( value )
    return BigFixed_div( toLeft( self, value ), value )
end

BigFixed.__idiv = BigFixed.__div

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a `BigInteger`, truncating the fractional part.
---
---@return dreamwork.std.BigInteger obj
function BigFixed:toBigInteger()
    if self.scale == 0 then
        return self.mantissa:copy()
    end

    return (self.mantissa:copy():div( pow10( self.scale ) ))
end

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a decimal string.
---
---@return string str
function BigFixed:toString()
    local mantissa = self.mantissa
    local scale = self.scale

    if scale == 0 then
        return mantissa:toString( 10 )
    end

    local digits = mantissa:copy():abs():toString( 10 )
    local digits_length = string_len( digits )

    if digits_length <= scale then
        local padding = {}

        for i = 1, (scale - digits_length) + 1, 1 do
            padding[ i ] = "0"
        end

        digits = table_concat( padding ) .. digits
        digits_length = string_len( digits )
    end

    local str = string_sub( digits, 1, digits_length - scale ) .. "." .. string_sub( digits, digits_length - scale + 1, digits_length )

    if mantissa.sign then
        return "-" .. str
    end

    return str
end

local BigFixed_toString = BigFixed.toString

---@return string
---@protected
function BigFixed:__tostring()
    return BigFixed_toString( self )
end

---@return string
---@protected
function BigFixed:__represent()
    return string_format( "BigFixed: %p [%s]", self, BigFixed_toString( self ) )
end

---@param value any
---@return string
---@protected
function BigFixed:__concat( value )
    if isBigFixed( self ) then
        return BigFixed_toString( self ) .. tostring( value )
    end

    return tostring( self ) .. BigFixed_toString( value )
end

--- [SHARED AND MENU]
---
--- Converts a `BigFixed` object to a Lua number ( precision loss is possible
--- for values that don't fit in a double ).
---
---@return number value
function BigFixed:toNumber()
    return tonumber( BigFixed_toString( self ) ) or 0
end

BigFixed.__tonumber = BigFixed.toNumber
