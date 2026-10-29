---@class dreamwork.std
local std = dreamwork.std

local setmetatable = std.setmetatable
local tostring = std.tostring
local tonumber = std.tonumber

local isString = std.isString
local isNumber = std.isNumber

local ascii = std.ascii
local ascii_toInteger = ascii.toInteger

local raw = std.raw
local raw_equal = raw.equal
local raw_select = raw.select
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_bxor = rbit.bxor
local rbit_rshift = rbit.rshift
local rbit_band, rbit_bor = rbit.band, rbit.bor

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_log2 = math.log2
local math_frexp = math.frexp
local math_range = math.range
local math_isNegative = math.isNegative
local math_min, math_max = math.min, math.max
local math_floor, math_clamp = math.floor, math.clamp

local table = std.table
local table_concat = table.concat
local table_unpack = table.unpack

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_format = string.format

local class = std.class
local class_new = class.new

-- Values are stored as little-endian arrays of 16-bit limbs, `limbs[ 0 ]` is the limb count.
--
-- 16 bits is the sweet spot for doubles: a limb product is below 2^32, so
-- multiplication can sum ~2^21 products per column without any carry
-- handling and do a single carry pass at the end.

--- 2^16, the limb base.
local LIMB = 0x10000

--- 1 / 2^16, exact, so `x * LIMB_INV` is an exact division by the limb base.
local LIMB_INV = 1 / 0x10000

--- [SHARED AND MENU]
---
--- Represents an arbitrary-precision signed integer.
---
--- A `BigInteger` object can represent any integer value that fits in
--- available memory. It supports arithmetic, comparison, conversion,
--- and bitwise operations while preserving exact integer precision.
---
---@class dreamwork.std.BigInteger : dreamwork.std.Object
---@field __class dreamwork.std.BigIntegerClass
---@field limbs integer[] The magnitude as little-endian 16-bit limbs, `limbs[ 0 ]` is the limb count.
---@field sign boolean
---@operator add( any ): dreamwork.std.BigInteger
---@operator sub( any ): dreamwork.std.BigInteger
---@operator mul( any ): dreamwork.std.BigInteger
---@operator div( any ): dreamwork.std.BigInteger
---@operator idiv( any ): dreamwork.std.BigInteger
---@operator pow( integer ): dreamwork.std.BigInteger
---@operator unm: dreamwork.std.BigInteger
---@operator bnot: dreamwork.std.BigInteger
---@operator band( any ): dreamwork.std.BigInteger
---@operator bor( any ): dreamwork.std.BigInteger
---@operator bxor( any ): dreamwork.std.BigInteger
---@operator shl( integer ): dreamwork.std.BigInteger
---@operator shr( integer ): dreamwork.std.BigInteger
---@operator len: integer
---@operator concat( any ): string
local BigInteger = class.base( "BigInteger", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `BigInteger` instances.
---
--- Arbitrary-precision signed integer type.
---
--- Unlike Lua's built-in integers, `BigInteger` values are limited only by
--- available memory, allowing calculations on integers of virtually
--- unlimited size without overflow.
---
--- Supports the standard arithmetic, comparison, and bitwise operators
--- through metamethods.
---
---@class dreamwork.std.BigIntegerClass : dreamwork.std.BigInteger
---@field __base dreamwork.std.BigInteger
---@overload fun( value: ( dreamwork.std.BigInteger | string | integer | nil ), base: ( integer | nil ) ): dreamwork.std.BigInteger
local BigIntegerClass = class.create( BigInteger )
std.BigInteger = BigIntegerClass

--- [SHARED AND MENU]
---
--- Checks whether the value is a `BigInteger`.
---
---@param value any The value to check.
---@return boolean is_bigint `true` if the value is a `BigInteger`, `false` otherwise.
---@nodiscard
local function isBigInteger( value )
    return debug_getmetatable( value ) == BigInteger
end

std.isBigInteger = isBigInteger

do

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is zero/empty.
    ---
    ---@return boolean is_zero `true` if the big integer object is zero/empty, `false` otherwise.
    ---@nodiscard
    function BigInteger:isZero()
        return self.limbs[ 0 ] == 0
    end

    local BigInteger_isZero = BigInteger.isZero
    BigInteger.isEmpty = BigInteger_isZero

    ---@return boolean
    ---@protected
    function BigInteger:__toboolean()
        return not BigInteger_isZero( self )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is even.
    ---
    ---@return boolean result `true` if the big integer object is even, `false` otherwise.
    ---@nodiscard
    function BigInteger:isEven()
        local limbs = self.limbs
        return limbs[ 0 ] == 0 or (limbs[ 1 ] % 2) == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is odd.
    ---
    ---@return boolean `true` if the big integer object is odd, `false` otherwise.
    ---@nodiscard
    function BigInteger:isOdd()
        return not self:isEven()
    end

end

--- [SHARED AND MENU]
---
--- Negates a big integer object.
---
---@return dreamwork.std.BigInteger self The negated big integer object.
function BigInteger:negate()
    self.sign = not self.sign
    return self
end

---
--- Returns the number of bytes needed to store the magnitude.
---
---@param limbs integer[]
---@return integer byte_count
local function limbs_byte_count( limbs )
    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        return 0
    end

    if limbs[ limb_count ] < 0x100 then
        return limb_count * 2 - 1
    end

    return limb_count * 2
end

---@return integer
---@protected
function BigInteger:__len()
    return limbs_byte_count( self.limbs )
end

---@param as_bytes boolean
---@return integer
---@protected
function BigInteger:__sizeof( as_bytes )
    if as_bytes then
        return limbs_byte_count( self.limbs )
    else
        return limbs_byte_count( self.limbs ) * 8
    end
end

---@param limbs integer[]
---@param limb_count integer | nil
---@return integer[]
local function limbs_copy( limbs, limb_count )
    if limb_count == nil then
        limb_count = limbs[ 0 ]
    end

    if limb_count == 0 then
        return {
            [ 0 ] = 0,
        }
    end

    -- 1-4 limbs
    if limb_count < 5 then
        return {
            [ 0 ] = limb_count,
            limbs[ 1 ],
            limbs[ 2 ],
            limbs[ 3 ],
            limbs[ 4 ]
        }
    end

    -- 5-8 limbs
    if limb_count < 9 then
        return {
            [ 0 ] = limb_count,
            limbs[ 1 ],
            limbs[ 2 ],
            limbs[ 3 ],
            limbs[ 4 ],
            limbs[ 5 ],
            limbs[ 6 ],
            limbs[ 7 ],
            limbs[ 8 ]
        }
    end

    -- 9-16 limbs
    if limb_count < 17 then
        return {
            [ 0 ] = limb_count,
            limbs[ 1 ],
            limbs[ 2 ],
            limbs[ 3 ],
            limbs[ 4 ],
            limbs[ 5 ],
            limbs[ 6 ],
            limbs[ 7 ],
            limbs[ 8 ],
            limbs[ 9 ],
            limbs[ 10 ],
            limbs[ 11 ],
            limbs[ 12 ],
            limbs[ 13 ],
            limbs[ 14 ],
            limbs[ 15 ],
            limbs[ 16 ]
        }
    end

    -- more that 4096 limbs (wow, that's too much i guess)
    if limb_count > 4096 then
        -- actuall limit is 7997, but i dont sure
        local copy = {
            [ 0 ] = limb_count,
        }

        for i = 1, limb_count, 1 do
            copy[ i ] = limbs[ i ]
        end

        return copy
    end

    return {
        [ 0 ] = limb_count,
        table_unpack( limbs, 1, limb_count )
    }
end

---@param a_limbs integer[]
---@param a_limb_count integer
---@param b_limbs integer[]
---@param b_limb_count integer
---@return `-1` | `0` | `1`
local function limbs_unsigned_compare( a_limbs, a_limb_count, b_limbs, b_limb_count )
    if a_limb_count < b_limb_count then
        return -1
    elseif a_limb_count > b_limb_count then
        return 1
    end

    for i = a_limb_count, 1, -1 do
        if a_limbs[ i ] < b_limbs[ i ] then
            return -1
        elseif a_limbs[ i ] > b_limbs[ i ] then
            return 1
        end
    end

    return 0
end

---@param a dreamwork.std.BigInteger
---@param b dreamwork.std.BigInteger
---@return `-1` | `0` | `1`
local function compare( a, b )
    local a_limbs, b_limbs = a.limbs, b.limbs
    local a_limb_count, b_limb_count = a_limbs[ 0 ], b_limbs[ 0 ]

    -- -0 == 0, like in Lua
    if a_limb_count == 0 and b_limb_count == 0 then
        return 0
    end

    if a.sign then
        if not b.sign then
            return -1
        end
    elseif b.sign then
        return 1
    end

    -- both negative: the larger magnitude is the smaller value
    if a.sign then
        return limbs_unsigned_compare( b_limbs, b_limb_count, a_limbs, a_limb_count )
    end

    return limbs_unsigned_compare( a_limbs, a_limb_count, b_limbs, b_limb_count )
end

---
--- Writes `limbs` (magnitude, `limb_count` long) into `out` as a two's-complement
--- limb string of exactly `target_len` limbs (little-endian), sign-extended.
---
---@param limbs integer[]
---@param limb_count integer
---@param is_negative boolean
---@param target_len integer
---@param out integer[]
local function twos_complement_extend( limbs, limb_count, is_negative, target_len, out )
    if is_negative then
        local carry = 1

        for i = 1, target_len do
            local summary

            if i > limb_count then
                summary = 0xFFFF + carry
            else
                summary = (0xFFFF - limbs[ i ]) + carry
            end

            if summary > 0xFFFF then
                out[ i ] = summary - 0x10000
                carry = 1
            else
                out[ i ] = summary
                carry = 0
            end
        end

        return
    end

    limb_count = math_min( limb_count, target_len )

    for i = 1, limb_count, 1 do
        out[ i ] = limbs[ i ]
    end

    for i = limb_count + 1, target_len, 1 do
        out[ i ] = 0
    end
end

---@param limbs integer[]
---@param limb_count integer
---@return integer limb_count
local function limbs_rstrip( limbs, limb_count )
    if limb_count == 0 then
        limbs[ 0 ] = 0
        return limb_count
    end

    ::big_integer_rstrip_loop::

    if limbs[ limb_count ] == 0 then
        limbs[ limb_count ] = nil
        limb_count = limb_count - 1

        if limb_count ~= 0 then
            goto big_integer_rstrip_loop
        end
    end

    limbs[ 0 ] = limb_count
    return limb_count
end

---
--- Converts a `target_len` limb two-complement value (in place, in `limbs`)
--- back to sign-magnitude
---
---@param limbs integer[]
---@param target_len integer
---@return integer, boolean
local function twos_complement_to_magnitude( limbs, target_len )
    local is_negative = rbit_band( limbs[ target_len ], 0x8000 ) ~= 0
    if is_negative then
        local carry = 1

        for i = 1, target_len, 1 do
            local summary = (0xFFFF - limbs[ i ]) + carry
            if summary > 0xFFFF then
                summary, carry = summary - 0x10000, 1
            else
                carry = 0
            end

            limbs[ i ] = summary
        end
    end

    return limbs_rstrip( limbs, target_len ), is_negative
end

---@param limbs integer[]
---@param limb_count integer | nil
---@return integer | nil
local function limbs_power_of_two( limbs, limb_count )
    if limb_count == nil then
        limb_count = limbs[ 0 ]
    end

    if limb_count == 0 then
        return nil
    end

    local power = 0
    local index = 1

    -- skip zero/empty limbs
    while index <= limb_count and limbs[ index ] == 0 do
        index, power = index + 1, power + 16
    end

    -- top-limb analysis
    local value = limbs[ index ]
    local found_bit = false

    for _ = 1, 16, 1 do
        if rbit_band( value, 1 ) == 1 then
            if found_bit then
                return nil -- second set bit within this limb
            end

            found_bit = true
        elseif not found_bit then
            power = power + 1
        end

        value = rbit_rshift( value, 1 )
    end

    -- remaining limbs must be zero/empty
    for i = index + 1, limb_count, 1 do
        if limbs[ i ] ~= 0 then
            return nil
        end
    end

    return power
end

---
--- `limbs = limbs * factor + addend` in place; returns the new length.
---
--- `factor` and `addend` must be below 2^36, so every step stays below 2^53.
---
---@param limbs integer[]
---@param limb_count integer
---@param factor integer
---@param addend integer
---@return integer limb_count
local function limbs_mul_add( limbs, limb_count, factor, addend )
    local carry = addend

    for i = 1, limb_count, 1 do
        local value = limbs[ i ] * factor + carry
        carry = math_floor( value * LIMB_INV )
        limbs[ i ] = value - carry * LIMB
    end

    while carry ~= 0 do
        local high = math_floor( carry * LIMB_INV )
        limb_count = limb_count + 1
        limbs[ limb_count ] = carry - high * LIMB
        carry = high
    end

    return limb_count
end

--- [SHARED AND MENU]
---
--- Sets a `BigInteger` object from Lua integer.
---
---@param value integer The number to convert.
---@return dreamwork.std.BigInteger self
function BigInteger:fromInteger( value )
    if math_isNegative( value ) then
        self.sign = true
        value = -value
    else
        self.sign = false
    end

    ---@type integer[]
    local limbs = {}

    ---@type integer
    local limb_count = 0

    while value > 0 do
        local high = math_floor( value * LIMB_INV )
        limb_count = limb_count + 1
        limbs[ limb_count ] = value - high * LIMB
        value = high
    end

    limbs[ 0 ] = limb_count
    self.limbs = limbs

    return self
end

---@type table<integer, integer>
local max_chunk_multipliers = {}

---@type table<integer, integer>
local chunk_sizes, chunk_bases = {}, {}

-- digits are processed in chunks: `chunk_bases[ base ]` is the largest
-- power of `base` ( `chunk_sizes[ base ]` digits ) that stays below 2^36
for base = 2, 36, 1 do
    local size, power = 1, base

    while power * base <= 0x1000000000 do
        size, power = size + 1, power * base
    end

    chunk_sizes[ base ], chunk_bases[ base ] = size, power
    max_chunk_multipliers[ base ] = power / base
end

do

    --- [SHARED AND MENU]
    ---
    --- Sets a `BigInteger` object from a decimal string.
    ---
    ---@param str string The string representation of the big integer.
    ---@param base? integer The numerical base of the digits in the input value. Can be any integer between 2 and 36, inclusive. By default: `10`
    ---@param start_position? integer The start position to read from.
    ---@param end_position? integer The end position to read to.
    ---@return dreamwork.std.BigInteger self
    function BigInteger:fromString( str, base, start_position, end_position )
        local str_length = string_len( str )

        local start_index, end_index = math_range( str_length, start_position, end_position )

        if string_byte( str, start_index ) == 0x2d then -- "-"
            start_index = start_index + 1
            self.sign = true
        else
            self.sign = false
        end

        if string_byte( str, start_index ) == 0x30 --[[ 0 ]] then
            start_index = start_index + 1

            local prefix = string_byte( str, start_index )
            if (base == nil or base == 16) and prefix == 0x78 --[[ x ]] then
                start_index = start_index + 1
                base = 16
            elseif (base == nil or base == 2) and prefix == 0x62 --[[ b ]] then
                start_index = start_index + 1
                base = 2
            end
        end

        while string_byte( str, start_index ) == 0x30 --[[ 0 ]] do
            start_index = start_index + 1
        end

        ---@type integer[]
        local limbs = {}

        ---@type integer
        local limb_count = 0

        base = math_clamp( base or 10, 2, 36 )
        self.limbs = limbs

        if start_index > end_index then
            limbs[ 0 ] = 0
            self.sign = false
            return self
        end

        if base == 2 or base == 16 then
            -- drop everything from the first non-digit, like the generic parser does
            for i = start_index, end_index, 1 do
                local digit = ascii_toInteger( string_byte( str, i ) )
                if digit == nil or digit >= base then
                    end_index = i - 1
                    break
                end
            end

            -- fast bin/hex parser
            local width = base == 16 and 4 or 16

            for j = end_index, start_index, -width do
                limb_count = limb_count + 1

                local chunk_start = j - width + 1
                if chunk_start > start_index then
                    limbs[ limb_count ] = raw_tonumber( string_sub( str, chunk_start, j ), base )
                else
                    limbs[ limb_count ] = raw_tonumber( string_sub( str, start_index, j ), base )
                end
            end

            limbs[ 0 ] = limb_count

            return self
        end

        -- generic parser: `limbs = limbs * base^n + chunk` for every n-digit chunk
        local max_multiplier = max_chunk_multipliers[ base ]
        local chunk, multiplier = 0, 1

        for i = start_index, end_index, 1 do
            local digit = ascii_toInteger( string_byte( str, i ) )
            if digit == nil or digit >= base then
                break -- drop floats and not a number parts
            end

            if multiplier > max_multiplier then
                limb_count = limbs_mul_add( limbs, limb_count, multiplier, chunk )
                chunk, multiplier = 0, 1
            end

            chunk, multiplier = chunk * base + digit, multiplier * base
        end

        if multiplier ~= 1 then
            limb_count = limbs_mul_add( limbs, limb_count, multiplier, chunk )
        end

        limbs[ 0 ] = limb_count

        return self
    end

end

do

    local BigInteger_fromInteger = BigInteger.fromInteger
    local BigInteger_fromString = BigInteger.fromString

    ---@param obj dreamwork.std.BigInteger
    ---@param value any
    ---@param base integer | nil
    ---@param stack_level integer
    local function fromAny( obj, value, base, stack_level )
        if isString( value ) then
            ---@cast value string
            BigInteger_fromString( obj, value, base )
            return
        end

        ---@type integer | nil
        local number_value

        if isNumber( value ) then
            ---@cast value number
            number_value = value
        else
            ---@cast value any
            number_value = tonumber( value, base )
            if number_value == nil then
                error( "given value cannot be converted to a number", stack_level + 1 )
            end
        end

        ---@cast number_value number

        BigInteger_fromInteger( obj, math_floor( number_value ) )
    end

    ---@param value dreamwork.std.BigInteger | string | integer | nil
    ---@param base integer | nil
    ---@protected
    function BigInteger:__init( value, base )
        if isBigInteger( value ) then
            ---@cast value dreamwork.std.BigInteger
            self.limbs = limbs_copy( value.limbs )
            self.sign = value.sign
            return
        end

        self.limbs = { [ 0 ] = 0 }
        self.sign = false

        if value ~= nil then
            ---@cast value string | integer
            fromAny( self, value, base, 3 )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a `BigInteger` object from the given value.
    ---
    --- If `value` is already a `BigInteger`, it is returned unchanged.
    ---
    ---@param value any The value to convert to a `BigInteger`.
    ---@param base? integer The numeric base used when parsing string values. Must be between `2` and `36` (inclusive). Defaults to `10`.
    ---@return dreamwork.std.BigInteger obj
    ---@nodiscard
    function std.toBigInteger( value, base )
        if isBigInteger( value ) then
            ---@cast value dreamwork.std.BigInteger
            return value
        end

        local obj = class_new( BigInteger )
        obj.limbs = { [ 0 ] = 0 }
        obj.sign = false

        fromAny( obj, value, base, 2 )
        return obj
    end

    std.toBigInt = std.toBigInteger

end

--- [SHARED AND MENU]
---
--- Replaces the contents of this `BigInteger` with the given bytes.
---
--- The bytes are interpreted in big-endian order (most significant byte first).
--- If `signed` is `true`, the resulting value is interpreted as a signed
--- two's-complement integer.
---
---@param signed boolean Whether the byte sequence represents a signed integer.
---@param ... integer The bytes to store, each in the range `0`–`255`.
---@return dreamwork.std.BigInteger self
function BigInteger:fromBytes( signed, ... )
    local byte_count = raw_select( "#", ... )

    ---@type integer[]
    local bytes = { ... }

    ---@type integer[]
    local limbs = {}

    ---@type integer
    local limb_count = 0

    -- big-endian byte pairs -> little-endian limbs
    for i = byte_count, 1, -2 do
        limb_count = limb_count + 1

        if i == 1 then
            limbs[ limb_count ] = bytes[ 1 ]
        else
            limbs[ limb_count ] = bytes[ i - 1 ] * 0x100 + bytes[ i ]
        end
    end

    limbs_rstrip( limbs, limb_count )

    self.limbs = limbs
    self.sign = false

    if signed then
        self:toSigned( byte_count )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Creates a new `BigInteger` from the given bytes.
---
--- The bytes are interpreted in big-endian order (most significant byte first).
--- If `signed` is `true`, the resulting value is interpreted as a signed
--- two's-complement integer.
---
---@param signed boolean Whether the byte sequence represents a signed integer.
---@param ... integer The bytes of the integer, each in the range `0`–`255`.
---@return dreamwork.std.BigInteger new_obj
---@nodiscard
function BigIntegerClass.fromBytes( signed, ... )
    ---@type dreamwork.std.BigInteger
    local obj = setmetatable( {
        limbs = { [ 0 ] = 0 },
        sign = false
    }, BigInteger )

    return obj:fromBytes( signed, ... )
end

local toBigInteger = std.toBigInteger

--- [SHARED AND MENU]
---
--- Compares the `BigInteger` with the given value.
---
--- Unlike the `==`, `<` and `<=` operators, this also works with plain Lua numbers and strings.
---
---@param value any The value to compare with (will be converted into `BigInteger`).
---@return `-1` | `0` | `1` result `-1` if `self < value`, `0` if equal, `1` if `self > value`.
---@nodiscard
function BigInteger:compare( value )
    return compare( self, toBigInteger( value ) )
end

-- operands can come in any order ( e.g. `5 < x` ), so both are converted

---@param value any
---@return boolean
---@protected
function BigInteger:__eq( value )
    return compare( toBigInteger( self ), toBigInteger( value ) ) == 0
end

---@param value any
---@return boolean
---@protected
function BigInteger:__lt( value )
    return compare( toBigInteger( self ), toBigInteger( value ) ) == -1
end

---@param value any
---@return boolean
---@protected
function BigInteger:__le( value )
    return compare( toBigInteger( self ), toBigInteger( value ) ) <= 0
end

--- [SHARED AND MENU]
---
--- Makes a copy of the `BigInteger` object.
---
---@return dreamwork.std.BigInteger new_obj
---@nodiscard
function BigInteger:copy()
    return setmetatable( {
        limbs = limbs_copy( self.limbs ),
        sign = self.sign
    }, BigInteger )
end

--- [SHARED AND MENU]
---
--- Converts a big integer object to a lua_number (always an integer).
---
---@return integer value The number that the big integer object represents.
---@nodiscard
function BigInteger:toInteger()
    local limbs = self.limbs

    ---@type integer
    local integer = 0

    for i = limbs[ 0 ], 1, -1 do
        integer = (integer * LIMB) + limbs[ i ]
    end

    if self.sign then
        return -integer
    end

    return integer
end

BigInteger.__tonumber = BigInteger.toInteger

do

    ---@type string[]
    local digits = {
        [ 0 ] = "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    }

    --- [SHARED AND MENU]
    ---
    --- Converts the big integer to a string in the specified (or not) base.
    ---
    ---@param base? integer The numerical base of the digits in the input value. Can be any integer between 2 and 36, inclusive. By default: `10`
    ---@return string str The string representation of the big integer.
    ---@nodiscard
    function BigInteger:toString( base )
        if base == nil then
            base = 10
        else
            base = math_clamp( base, 2, 36 )
        end

        if base == 2 then
            return self:toBinaryString()
        elseif base == 16 then
            return self:toHexString()
        end

        local limbs = self.limbs

        ---@type integer
        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            if self.sign then
                return "-0"
            end

            return "0"
        end

        local chunk_size, chunk_base = chunk_sizes[ base ], chunk_bases[ base ]

        -- `chunks` holds the value in base `chunk_base`, least significant first
        ---@type integer[]
        local chunks = {}

        ---@type integer
        local chunk_count = 0

        for i = limb_count, 1, -1 do
            -- chunks = (chunks * 2^16) + limbs[i], done in one pass
            local carry = limbs[ i ]

            for j = 1, chunk_count, 1 do
                local value = chunks[ j ] * LIMB + carry
                carry = math_floor( value / chunk_base )

                local chunk = value - carry * chunk_base
                if chunk < 0 then -- correct a rounded-up quotient
                    carry, chunk = carry - 1, chunk + chunk_base
                end

                chunks[ j ] = chunk
            end

            while carry ~= 0 do
                local high = math_floor( carry / chunk_base )
                chunk_count = chunk_count + 1
                chunks[ chunk_count ] = carry - high * chunk_base
                carry = high
            end
        end

        ---@type string[]
        local symbols = {}

        ---@type integer
        local symbol_count = 0

        -- most significant chunk, unpadded
        local value = chunks[ chunk_count ]

        repeat
            local high = math_floor( value / base )
            symbol_count = symbol_count + 1
            symbols[ symbol_count ] = digits[ value - high * base ]
            value = high
        until value == 0

        -- digits came out least significant first
        for i = 1, math_floor( symbol_count * 0.5 ), 1 do
            local j = (symbol_count - i) + 1
            symbols[ i ], symbols[ j ] = symbols[ j ], symbols[ i ]
        end

        -- the rest, zero-padded to `chunk_size` digits
        for i = chunk_count - 1, 1, -1 do
            value = chunks[ i ]

            for j = symbol_count + chunk_size, symbol_count + 1, -1 do
                local high = math_floor( value / base )
                symbols[ j ] = digits[ value - high * base ]
                value = high
            end

            symbol_count = symbol_count + chunk_size
        end

        local str = table_concat( symbols, "", 1, symbol_count )

        if self.sign then
            return "-" .. str
        end

        return str
    end

end

do

    ---@type table<integer, string>
    local hex_pairs = {}

    for i = 0, 0xFF, 1 do
        hex_pairs[ i ] = string_format( "%02X", i )
    end

    ---@param self dreamwork.std.BigInteger
    ---@return string
    ---@nodiscard
    ---@protected
    local function toHex( self )
        local limbs = self.limbs

        ---@type integer
        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            return "0"
        end

        ---@type string[]
        local result = {
            string_format( "%X", limbs[ limb_count ] ) -- MSB, unpadded
        }

        local result_size = 1

        for i = limb_count - 1, 1, -1 do
            local limb = limbs[ i ]
            local high = math_floor( limb * 0.00390625 ) -- /256

            result[ result_size + 1 ] = hex_pairs[ high ]
            result[ result_size + 2 ] = hex_pairs[ limb - high * 0x100 ]
            result_size = result_size + 2
        end

        return table_concat( result, "", 1, result_size )
    end

    BigInteger.__tohex = toHex

    --- [SHARED AND MENU]
    ---
    --- Converts the big integer into a hex string.
    ---
    ---@return string hex_str The hex string representation of the big integer.
    ---@nodiscard
    function BigInteger:toHexString()
        if self.sign then
            return "-0x" .. toHex( self )
        end

        return "0x" .. toHex( self )
    end

end

do

    ---@type table<integer, string>
    local bit_octets = {}

    for i = 0, 0xFF, 1 do
        local bits = {}

        for j = 8, 1, -1 do
            bits[ j ] = rbit_band( rbit_rshift( i, 8 - j ), 1 )
        end

        bit_octets[ i ] = table_concat( bits )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts the big integer to a binary [01] string.
    ---
    --- The output is zero-padded to a whole number of bytes.
    ---
    ---@return string str The binary string representation of the big integer.
    ---@nodiscard
    function BigInteger:toBinaryString()
        local limbs = self.limbs

        ---@type integer
        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            if self.sign then
                return "-0b0"
            end

            return "0b0"
        end

        ---@type string[]
        local result = {}

        ---@type integer
        local result_size = 0

        for i = limb_count, 1, -1 do
            local limb = limbs[ i ]
            local high = math_floor( limb * 0.00390625 ) -- /256

            -- the top limb may only use its low byte
            if i ~= limb_count or high ~= 0 then
                result_size = result_size + 1
                result[ result_size ] = bit_octets[ high ]
            end

            result_size = result_size + 1
            result[ result_size ] = bit_octets[ limb - high * 0x100 ]
        end

        local str = table_concat( result, "", 1, result_size )

        if self.sign then
            return "-0b" .. str
        end

        return "0b" .. str
    end

end

do

    local BigInteger_toString = BigInteger.toString

    ---@return string
    ---@protected
    function BigInteger:__tostring()
        return BigInteger_toString( self, 10 )
    end

    ---@return string
    ---@protected
    function BigInteger:__represent()
        return string_format( "BigInteger: %p [%s]", self, self:toHexString() )
    end

    ---@param value any
    ---@return string
    ---@protected
    function BigInteger:__concat( value )
        if isBigInteger( self ) then
            return BigInteger_toString( self, 10 ) .. tostring( value )
        end

        return tostring( self ) .. BigInteger_toString( value, 10 )
    end

end

-- ---@param writer dreamwork.std.BinaryWriter
-- function BigInteger:__serialize( writer )
--     local limbs = self.limbs
--     local limb_count = limbs[ 0 ]
--     writer:writeBoolean( self.sign )
--     writer:writeCountedString( ... big-endian bytes of `limbs[ 1 .. limb_count ]` ..., 48 )
-- end

-- ---@param reader dreamwork.std.BinaryReader
-- function BigInteger:__deserialize( reader )
--     local sign = reader:readBoolean()
--     local bytes, byte_count = reader:readCountedString( 48 )
--     self:fromBytes( false, string_byte( bytes, 1, byte_count ) )
--     self.sign = sign
-- end

local BigInteger_negate = BigInteger.negate
local BigInteger_copy = BigInteger.copy

---@return dreamwork.std.BigInteger new_obj The new negated big integer object.
---@protected
function BigInteger:__unm()
    return BigInteger_negate( BigInteger_copy( self ) )
end

--- [SHARED AND MENU]
---
--- Makes a big integer object absolute (simply removes the sign).
---
---@return dreamwork.std.BigInteger self The absolute big integer object.
function BigInteger:abs()
    self.sign = false
    return self
end

---
--- Adds `b` with the sign overridden by `b_sign` to `self`, in place.
---
--- `b` itself is never modified, so `b` may be `self`.
---
---@param self dreamwork.std.BigInteger
---@param b dreamwork.std.BigInteger
---@param b_sign boolean
---@return dreamwork.std.BigInteger self
local function add_signed( self, b, b_sign )
    -- b is empty/zero
    local b_limbs = b.limbs

    local b_limb_count = b_limbs[ 0 ]
    if b_limb_count == 0 then
        return self
    end

    -- a is empty/zero
    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        self.limbs = limbs_copy( b_limbs, b_limb_count )
        self.sign = b_sign
        return self
    end

    -- determine sign, operation, and order of operands
    local subtract, swap_order, change_sign = false, false, false

    if self.sign == b_sign then
        if limb_count < b_limb_count then
            swap_order = true
        end
    else

        local compare_result = limbs_unsigned_compare( limbs, limb_count, b_limbs, b_limb_count )
        if compare_result == 0 then
            self.limbs = { [ 0 ] = 0 }
            self.sign = false
            return self
        end

        if compare_result == -1 then
            swap_order, change_sign = true, true
        end

        subtract = true

    end

    local limbs1, limbs1_count
    local limbs2, limbs2_count

    if swap_order then
        limbs1, limbs1_count = b_limbs, b_limb_count
        limbs2, limbs2_count = limbs, limb_count
    else
        limbs1, limbs1_count = limbs, limb_count
        limbs2, limbs2_count = b_limbs, b_limb_count
    end

    ---@type integer
    local carry = 0

    if subtract then
        -- 1. Subtraction Phase (Up to the size of the smaller magnitude)
        for i = 1, limbs2_count, 1 do
            local total = (limbs1[ i ] - limbs2[ i ]) + carry
            if total < 0 then
                limbs[ i ], carry = total + 0x10000, -1
            else
                limbs[ i ], carry = total, 0
            end
        end

        -- 2. Subtraction Phase (Propagate carry into the remaining larger magnitude)
        for i = limbs2_count + 1, limbs1_count, 1 do
            if carry == 0 then
                -- No carry left, safely break and copy remainder if needed
                if swap_order then
                    for j = i, limbs1_count do
                        limbs[ j ] = limbs1[ j ]
                    end
                end

                break
            end

            local total = limbs1[ i ] + carry
            if total < 0 then
                limbs[ i ], carry = total + 0x10000, -1
            else
                limbs[ i ], carry = total, 0
            end
        end

        if limbs_rstrip( limbs, limbs1_count ) == 0 then
            self.sign = false
            return self
        end
    else
        -- 1. Addition Phase (Up to the size of the smaller number)
        for i = 1, limbs2_count do
            local total = (limbs1[ i ] + limbs2[ i ]) + carry
            if total >= 0x10000 then
                limbs[ i ], carry = total - 0x10000, 1
            else
                limbs[ i ], carry = total, 0
            end
        end

        -- 2. Addition Phase (Propagate carry into the remainder of the larger number)
        for i = limbs2_count + 1, limbs1_count do
            if carry == 0 then
                -- No carry left, safely break and copy remainder if needed
                if swap_order then
                    for j = i, limbs1_count do
                        limbs[ j ] = limbs1[ j ]
                    end
                end

                break
            end

            local total = limbs1[ i ] + carry
            if total >= 0x10000 then
                limbs[ i ], carry = total - 0x10000, 1
            else
                limbs[ i ], carry = total, 0
            end
        end

        -- Handle final overflow carry at the highest end
        if carry > 0 then
            limbs1_count = limbs1_count + 1
            limbs[ limbs1_count ] = carry
        end

        -- Crucial: Save the new total length!
        limbs[ 0 ] = limbs1_count
    end

    -- Apply inverted sign if self < b during subtraction
    if change_sign then
        BigInteger_negate( self )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Summarizes the current `BigInteger` with the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return dreamwork.std.BigInteger object The result of the operation.
function BigInteger:add( value )
    local b = toBigInteger( value )
    return add_signed( self, b, b.sign )
end

-- metamethod operands can come in any order ( e.g. `5 + x` ),
-- so the left one is always converted into a fresh `BigInteger`

---@param value any
---@return dreamwork.std.BigInteger new_object
---@protected
function BigInteger:__add( value )
    local b = toBigInteger( value )
    return add_signed( BigIntegerClass( self ), b, b.sign )
end

--- [SHARED AND MENU]
---
--- Subtract the current `BigInteger` by the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return dreamwork.std.BigInteger object The result of the operation.
function BigInteger:sub( value )
    local b = toBigInteger( value )
    return add_signed( self, b, not b.sign )
end

---@param value any
---@return dreamwork.std.BigInteger new_object
---@protected
function BigInteger:__sub( value )
    local b = toBigInteger( value )
    return add_signed( BigIntegerClass( self ), b, not b.sign )
end

--- [SHARED AND MENU]
---
--- Multiplies the current `BigInteger` by the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return dreamwork.std.BigInteger object The result of the operation.
function BigInteger:mul( value )
    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        return self -- self is zero
    end

    local b = toBigInteger( value )

    local b_limbs = b.limbs

    local b_limb_count = b_limbs[ 0 ]

    if b_limb_count == 0 then
        self.limbs = { [ 0 ] = 0 }
        self.sign = false
        return self -- b is zero
    end

    if b_limb_count == 1 and b_limbs[ 1 ] == 1 then
        if b.sign then
            self:negate()
        end

        return self -- b is +-1
    end

    if limb_count == 1 and limbs[ 1 ] == 1 then
        self.limbs = limbs_copy( b_limbs, b_limb_count )

        local is_negative = self.sign
        self.sign = b.sign

        if is_negative then
            self:negate()
        end

        return self -- self is +-1
    end

    -- capture the correct sign BEFORE any mutation
    local is_negative = self.sign ~= b.sign

    local result_count = limb_count + b_limb_count

    -- column sums are accumulated without carries ( each product is below 2^32,
    -- so a column can take ~2^21 of them before leaving the exact double range )
    -- and normalized in a single pass at the end
    ---@type integer[]
    local result = {}

    for i = 1, result_count, 1 do
        result[ i ] = 0
    end

    if b_limbs == limbs then
        -- squaring ( self:mul( self ), pow ): every cross product appears twice
        for i = 1, limb_count, 1 do
            local x = limbs[ i ]
            if x ~= 0 then
                local k = i + i - 1
                result[ k ] = result[ k ] + x * x

                local x2 = x + x
                for j = i + 1, limb_count, 1 do
                    k = i + j - 1
                    result[ k ] = result[ k ] + x2 * limbs[ j ]
                end
            end
        end
    else
        for i = 1, limb_count, 1 do
            local x = limbs[ i ]
            if x ~= 0 then
                for j = 1, b_limb_count, 1 do
                    local k = i + j - 1
                    result[ k ] = result[ k ] + x * b_limbs[ j ]
                end
            end
        end
    end

    local carry = 0

    for i = 1, result_count, 1 do
        local value = result[ i ] + carry
        carry = math_floor( value * LIMB_INV )
        result[ i ] = value - carry * LIMB
    end

    -- self.limbs is only replaced here, AFTER all reads from
    -- `limbs` / `b_limbs` ( which may be the same table ) are complete
    self.limbs = result
    self.sign = limbs_rstrip( result, result_count ) ~= 0 and is_negative

    return self
end

local BigInteger_mul = BigInteger.mul

---@param value any
---@return dreamwork.std.BigInteger new_object
---@protected
function BigInteger:__mul( value )
    local b = BigIntegerClass( self )

    -- `x * x`: multiply the copy by itself to take the squaring path
    if raw_equal( self, value ) then
        return BigInteger_mul( b, b )
    end

    return BigInteger_mul( b, value )
end

--- [SHARED AND MENU]
---
--- Shifts a big integer object to the left by a given number of bits (positive or negative).
---
---@param shift integer The number of bits to shift by.
---@return dreamwork.std.BigInteger object The shifted big integer object.
function BigInteger:lshift( shift )
    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 or shift == 0 then
        return self
    end

    if shift < 0 then
        return self:rshift( -shift )
    end

    -- shift whole limbs
    local shift_limbs = math_floor( shift * 0.0625 )
    local shift_bits = shift % 16

    -- shift whole limbs up, fill vacated low limbs with 0
    if shift_limbs ~= 0 then
        for i = limb_count, 1, -1 do
            limbs[ i + shift_limbs ] = limbs[ i ]
        end

        for i = 1, shift_limbs do
            limbs[ i ] = 0
        end

        limb_count = limb_count + shift_limbs
    end

    -- shift remaining bits, carrying overflow upward
    if shift_bits ~= 0 then
        local shift_size = 2 ^ shift_bits
        local overflow = 0

        for i = shift_limbs + 1, limb_count do
            local value = (limbs[ i ] * shift_size) + overflow
            overflow = math_floor( value * LIMB_INV )
            limbs[ i ] = value - overflow * LIMB
        end

        if overflow ~= 0 then
            limb_count = limb_count + 1
            limbs[ limb_count ] = overflow
        end
    end

    limbs[ 0 ] = limb_count

    return self
end

--- [SHARED AND MENU]
---
--- Checks if `BigInteger` is a power of two.
---
---@return boolean is_pot `true` if a number is a valid power-of-two, otherwise `false`.
---@nodiscard
function BigInteger:isPowerOfTwo()
    return limbs_power_of_two( self.limbs ) ~= nil
end

do

    local BigInteger_lshift = BigInteger.lshift

    ---@param shift integer
    ---@return dreamwork.std.BigInteger new_object
    ---@protected
    function BigInteger:__shl( shift )
        return BigInteger_lshift( BigInteger_copy( self ), shift )
    end

    --- [SHARED AND MENU]
    ---
    --- Raises a big integer object to a power.
    ---
    ---@param value integer The value to raise to.
    ---@return dreamwork.std.BigInteger self The result of the operation.
    function BigInteger:pow( value )
        if value == 0 then
            self.limbs = { [ 0 ] = 1, 1 }
            self.sign = false
            return self
        elseif value == 1 then
            return self
        end

        local limbs = self.limbs

        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            return self
        end

        if value < 0 then
            error( "negative exponent is not supported", 2 )
        end

        if self.sign and (value % 2) == 0 then
            self.sign = false
        end

        -- fast path: self's magnitude is an exact power of two
        local power = limbs_power_of_two( limbs, limb_count )
        if power ~= nil then
            BigInteger_lshift( self, power * (value - 1) )
            self.sign = self.sign and (value % 2) == 1
            return self
        end

        -- general case: exponentiation by squaring
        local base = BigInteger_copy( self )
        local result = toBigInteger( 1 )

        while value ~= 0 do
            if (value % 2) == 1 then
                BigInteger_mul( result, base )
            end

            value = math_floor( value * 0.5 )

            if value ~= 0 then
                BigInteger_mul( base, base )
            end
        end

        self.limbs = result.limbs
        self.sign = result.sign
        return self
    end

end

do

    local BigInteger_pow = BigInteger.pow

    ---@param value integer | dreamwork.std.BigInteger
    ---@return dreamwork.std.BigInteger new_object
    ---@protected
    function BigInteger:__pow( value )
        if isBigInteger( value ) then
            ---@cast value dreamwork.std.BigInteger
            value = value:toInteger()
        end

        ---@cast value integer

        return BigInteger_pow( BigIntegerClass( self ), value )
    end

end

do

    ---
    ---  multiplies a limb array in place by a small scalar (below 2^16); returns new length
    ---
    ---@param limbs integer[]
    ---@param limb_count integer
    ---@param factor integer
    ---@return integer limb_count
    local function limbs_mul_small( limbs, limb_count, factor )
        local carry = 0

        for i = 1, limb_count, 1 do
            local product = limbs[ i ] * factor + carry
            carry = math_floor( product * LIMB_INV )
            limbs[ i ] = product - carry * LIMB
        end

        if carry ~= 0 then
            limb_count = limb_count + 1
            limbs[ limb_count ] = carry
        end

        return limb_count
    end

    ---
    ---  divides a limb array in place by a small scalar (1 to 2^16-1), MSB to LSB; returns new length
    ---
    ---@param limbs integer[]
    ---@param limb_count integer
    ---@param divisor integer
    ---@return integer limb_count
    ---@return integer remainder
    local function limbs_div_small( limbs, limb_count, divisor )
        local remainder = 0

        for i = limb_count, 1, -1 do
            local current = (remainder * LIMB) + limbs[ i ]
            local quotient = math_floor( current / divisor )
            limbs[ i ] = quotient
            remainder = current - quotient * divisor
        end

        return limbs_rstrip( limbs, limb_count ), remainder
    end

    --- [SHARED AND MENU]
    ---
    --- Divides the current `BigInteger` with the specified value.
    ---
    ---@param value any The second value to divide by (will be converted into `BigInteger`).
    ---@return dreamwork.std.BigInteger quotient The quotient.
    ---@return dreamwork.std.BigInteger remainder The remainder.
    function BigInteger:div( value )
        local limbs = self.limbs
        local limb_count = limbs[ 0 ]

        local b = toBigInteger( value )

        local b_limbs = b.limbs
        local b_limb_count = b_limbs[ 0 ]

        if b_limb_count == 0 then
            error( "attempt to divide by zero", 2 )
        end

        if limb_count == 0 then
            self.sign = false

            return self,
                setmetatable( { -- 0
                    limbs = { [ 0 ] = 0 },
                    sign = false
                }, BigInteger )
        end

        local is_negative = self.sign ~= b.sign

        if b_limb_count == 1 and b_limbs[ 1 ] == 1 then
            self.sign = is_negative

            return self,
                setmetatable( { -- 0
                    limbs = { [ 0 ] = 0 },
                    sign = false
                }, BigInteger )
        end

        local compare_result = limbs_unsigned_compare( limbs, limb_count, b_limbs, b_limb_count )

        if compare_result == -1 then
            local remainder = BigInteger_copy( self )

            self.limbs = { [ 0 ] = 0 }
            self.sign = false

            return self, remainder
        end

        if compare_result == 0 then
            self.limbs = { [ 0 ] = 1, 1 }
            self.sign = is_negative

            return self,
                setmetatable( { -- 0
                    limbs = { [ 0 ] = 0 },
                    sign = false
                }, BigInteger )
        end

        -- the remainder keeps the dividend's sign ( truncated division )
        local remainder_sign = self.sign

        -- single-limb divisor: plain short division
        if b_limb_count == 1 then
            local quotient = limbs_copy( limbs, limb_count )
            local quotient_count, remainder = limbs_div_small( quotient, limb_count, b_limbs[ 1 ] )

            self.limbs = quotient
            self.sign = quotient_count ~= 0 and is_negative

            return self,
                setmetatable( {
                    limbs = remainder == 0 and { [ 0 ] = 0 } or { [ 0 ] = 1, remainder },
                    sign = remainder ~= 0 and remainder_sign
                }, BigInteger )
        end

        -- Knuth's algorithm D

        -- normalize: shift both operands so the divisor's top limb has its high bit set
        local factor = 1
        local top = b_limbs[ b_limb_count ]

        while top < 0x8000 do
            top, factor = top * 2, factor * 2
        end

        local divisor = limbs_copy( b_limbs, b_limb_count )
        local remainder = limbs_copy( limbs, limb_count )
        local remainder_count = limb_count

        if factor ~= 1 then
            limbs_mul_small( divisor, b_limb_count, factor ) -- can't grow, by construction
            remainder_count = limbs_mul_small( remainder, limb_count, factor )
        end

        -- the top digit window reads one limb past the dividend, make it an explicit zero
        if remainder_count == limb_count then
            remainder[ limb_count + 1 ] = 0
        end

        -- read after normalization: the lower limbs shift bits into the top one
        local divisor_top, divisor_next = divisor[ b_limb_count ], divisor[ b_limb_count - 1 ]
        local digit_count = (limb_count - b_limb_count) + 1

        ---@type integer[]
        local quotient = {}

        for j = digit_count, 1, -1 do
            local top_index = j + b_limb_count

            -- estimate the quotient digit from the top two limbs, then refine it
            -- with the second divisor limb; it is then at most one too large
            local numerator = remainder[ top_index ] * LIMB + remainder[ top_index - 1 ]

            local q = math_floor( numerator / divisor_top )
            if q > 0xFFFF then
                q = 0xFFFF
            end

            local r = numerator - q * divisor_top

            while r < LIMB and q * divisor_next > r * LIMB + remainder[ top_index - 2 ] do
                q, r = q - 1, r + divisor_top
            end

            if q ~= 0 then
                -- remainder[ j .. top_index ] -= q * divisor, with a signed ( <= 0 ) carry:
                -- one floor per limb and no branches, every step stays within +-2^33
                local carry = 0

                for i = 1, b_limb_count, 1 do
                    local index = j + i - 1
                    local difference = remainder[ index ] - q * divisor[ i ] + carry
                    carry = math_floor( difference * LIMB_INV )
                    remainder[ index ] = difference - carry * LIMB
                end

                local top = remainder[ top_index ] + carry

                if top < 0 then
                    -- the estimate was one too large ( rare ): add the divisor back
                    q = q - 1
                    carry = 0

                    for i = 1, b_limb_count, 1 do
                        local index = j + i - 1
                        local sum = remainder[ index ] + divisor[ i ] + carry

                        if sum >= LIMB then
                            remainder[ index ], carry = sum - LIMB, 1
                        else
                            remainder[ index ], carry = sum, 0
                        end
                    end

                    top = top + carry
                end

                remainder[ top_index ] = top
            end

            quotient[ j ] = q
        end

        -- the remainder fits in the low `b_limb_count` limbs, everything above is zero
        for i = b_limb_count + 1, limb_count + 1, 1 do
            remainder[ i ] = nil
        end

        -- undo normalization on the remainder
        if factor ~= 1 then
            remainder_count = limbs_div_small( remainder, b_limb_count, factor )
        else
            remainder_count = limbs_rstrip( remainder, b_limb_count )
        end

        self.limbs = quotient
        self.sign = limbs_rstrip( quotient, digit_count ) ~= 0 and is_negative

        return self,
            setmetatable( {
                limbs = remainder,
                sign = remainder_count ~= 0 and remainder_sign
            }, BigInteger )
    end

    local BigInteger_div = BigInteger.div

    ---@param value any
    ---@return dreamwork.std.BigInteger quotient
    ---@protected
    function BigInteger:__div( value )
        return (BigInteger_div( BigIntegerClass( self ), value ))
    end

    BigInteger.__idiv = BigInteger.__div

    --- [SHARED AND MENU]
    ---
    --- Calculates modulus (remainder after division);
    ---
    --- Handles Lua-to-BigInteger conversions and non-positive cases correctly.
    ---
    ---@param value any The value to divide by.
    ---@return dreamwork.std.BigInteger remainder The remainder (same sign as self, or zero).
    ---@nodiscard
    function BigInteger:mod( value )
        return raw_select( 2, BigInteger_div( BigIntegerClass( self ), value ) )
    end

    ---@param value any
    ---@return dreamwork.std.BigInteger remainder
    ---@protected
    function BigInteger:__mod( value )
        return raw_select( 2, BigInteger_div( BigIntegerClass( self ), value ) )
    end

end

--- [SHARED AND MENU]
---
--- Returns the log2 of a big integer object.
---
---@return number result The base-2 logarithm of the big integer object. NaN for negative values, -inf for zero.
---@nodiscard
function BigInteger:log2()
    if self.sign then
        return math.nan
    end

    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        return math.tiny
    end

    -- 4 limbs keep at least 49 significant bits, more than a double can hold
    local take = math_min( 4, limb_count )

    local value = 0
    for i = limb_count, limb_count - take + 1, -1 do
        value = (value * LIMB) + limbs[ i ]
    end

    local mantissa, exponent = math_frexp( value )
    return math_log2( mantissa ) + exponent + (limb_count - take) * 16
end

--- [SHARED AND MENU]
---
--- Shifts a big integer object to the right by a given number of bits (positive or negative).
---
---@param shift integer The number of bits to shift by.
---@return dreamwork.std.BigInteger object The shifted big integer object.
function BigInteger:rshift( shift )
    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 or shift == 0 then
        return self
    end

    if shift < 0 then
        return self:lshift( -shift )
    end

    -- shift whole limbs
    local shift_limbs = math_floor( shift * 0.0625 )
    if shift_limbs >= limb_count then
        self.limbs = { [ 0 ] = 0 } -- keeps the sign, same as a partial shift down to zero
        return self
    end

    -- shift whole limbs down
    if shift_limbs ~= 0 then
        for i = shift_limbs + 1, limb_count, 1 do
            limbs[ i - shift_limbs ] = limbs[ i ]
        end

        for i = limb_count - shift_limbs + 1, limb_count, 1 do
            limbs[ i ] = nil
        end

        limb_count = limb_count - shift_limbs
    end

    -- shift remaining bits, pulling the low bits of the next limb down
    local shift_bits = shift % 16

    if shift_bits ~= 0 then
        local shift_size, unshift_size = 2 ^ shift_bits, 2 ^ (16 - shift_bits)

        for i = 1, limb_count, 1 do
            local value = limbs[ i ]
            local low = math_floor( value / shift_size )

            if i == limb_count then
                limbs[ i ] = low
            else
                local next_value = limbs[ i + 1 ]
                limbs[ i ] = low + (next_value - math_floor( next_value / shift_size ) * shift_size) * unshift_size
            end
        end
    end

    limbs_rstrip( limbs, limb_count )
    return self
end

do

    local BigInteger_rshift = BigInteger.rshift

    ---@param shift integer
    ---@return dreamwork.std.BigInteger new_object
    ---@protected
    function BigInteger:__shr( shift )
        return BigInteger_rshift( BigInteger_copy( self ), shift )
    end

end

---@type integer[]
local a_buffer = {}

---@type integer[]
local b_buffer = {}

--- [SHARED AND MENU]
---
--- Performs a bitwise OR operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return dreamwork.std.BigInteger object The result of the operation.
function BigInteger:bor( value )
    local b = toBigInteger( value )

    local b_limbs = b.limbs

    local b_limb_count = b_limbs[ 0 ]
    if b_limb_count == 0 then
        return self
    end

    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        self.limbs = limbs_copy( b_limbs, b_limb_count )
        self.sign = b.sign
        return self
    end

    local target_len = math_max( limb_count, b_limb_count ) + 1

    twos_complement_extend( limbs, limb_count, self.sign, target_len, a_buffer )
    twos_complement_extend( b_limbs, b_limb_count, b.sign, target_len, b_buffer )

    for i = 1, target_len, 1 do
        limbs[ i ] = rbit_bor( a_buffer[ i ], b_buffer[ i ] )
    end

    local result_len, is_negative = twos_complement_to_magnitude( limbs, target_len )
    self.sign = result_len ~= 0 and is_negative

    return self
end

do

    local BigInteger_bor = BigInteger.bor

    ---@param ... any
    ---@return dreamwork.std.BigInteger new_object
    ---@protected
    function BigInteger:__bor( ... )
        local object = BigIntegerClass( self )

        for i = 1, raw_select( "#", ... ), 1 do
            BigInteger_bor( object, (raw_select( i, ... )) )
        end

        return object
    end

end

--- [SHARED AND MENU]
---
--- Performs a bitwise AND operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return dreamwork.std.BigInteger new_object The result of the operation.
function BigInteger:band( value )
    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        return self
    end

    local b = toBigInteger( value )
    local b_limbs = b.limbs

    local b_limb_count = b_limbs[ 0 ]
    if b_limb_count == 0 then
        self.limbs = { [ 0 ] = 0 }
        self.sign = false
        return self
    end

    ---@type integer
    local target_len = math_max( limb_count, b_limb_count ) + 1

    twos_complement_extend( limbs, limb_count, self.sign, target_len, a_buffer )
    twos_complement_extend( b_limbs, b_limb_count, b.sign, target_len, b_buffer )

    for i = 1, target_len, 1 do
        limbs[ i ] = rbit_band( a_buffer[ i ], b_buffer[ i ] )
    end

    local result_len, is_negative = twos_complement_to_magnitude( limbs, target_len )
    self.sign = result_len ~= 0 and is_negative

    return self
end

do

    local BigInteger_band = BigInteger.band

    ---@param ... any
    ---@return dreamwork.std.BigInteger new_object
    ---@protected
    function BigInteger:__band( ... )
        local object = BigIntegerClass( self )

        for i = 1, raw_select( "#", ... ), 1 do
            BigInteger_band( object, (raw_select( i, ... )) )
        end

        return object
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise NOT operation on a big integer object.
    ---
    ---@return dreamwork.std.BigInteger object The result of the operation.
    function BigInteger:bnot()
        local limbs = self.limbs

        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            self.limbs = { [ 0 ] = 1, 1 }
            self.sign = true
            return self
        end

        local target_len = limb_count + 1 -- extra pad limb to capture the sign flip correctly
        twos_complement_extend( limbs, limb_count, self.sign, target_len, a_buffer )

        for i = 1, target_len, 1 do
            limbs[ i ] = 0xFFFF - a_buffer[ i ]
        end

        local result_len, is_negative = twos_complement_to_magnitude( limbs, target_len )
        self.sign = result_len ~= 0 and is_negative

        return self
    end

    local BigInteger_bnot = BigInteger.bnot

    ---@return dreamwork.std.BigInteger
    ---@protected
    function BigInteger:__bnot()
        return BigInteger_bnot( BigInteger_copy( self ) )
    end

    ---
    --- Returns the limb count and the top limb's mask/sign bit for a `byte_width` wide integer.
    ---
    ---@param byte_width integer
    ---@return integer width The number of limbs.
    ---@return integer top_mask The mask of the bits used in the top limb.
    ---@return integer sign_bit The sign bit within the top limb.
    local function limb_width( byte_width )
        if (byte_width % 2) == 0 then
            return byte_width * 0.5, 0xFFFF, 0x8000
        end

        return (byte_width + 1) * 0.5, 0xFF, 0x80
    end

    --- [SHARED AND MENU]
    ---
    --- Converts unsigned `BigInteger` to signed one.
    ---
    ---@param byte_width integer The byte width to interpret the raw magnitude at (e.g. 1 for int8, 4 for int32).
    ---@return dreamwork.std.BigInteger object Self, reinterpreted as a signed integer of the given byte width.
    function BigInteger:toSigned( byte_width )
        local limbs = self.limbs

        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            return self
        end

        local width, top_mask, sign_bit = limb_width( byte_width )

        -- truncate the raw value to exactly `byte_width` bytes
        if limb_count >= width then
            for i = width + 1, limb_count, 1 do
                limbs[ i ] = nil
            end

            limbs[ width ] = rbit_band( limbs[ width ], top_mask )
            limb_count = limbs_rstrip( limbs, width )

            if limb_count == 0 then
                self.sign = false
                return self
            end
        end

        if limb_count < width or rbit_band( limbs[ width ], sign_bit ) == 0 then
            return self -- non-negative at this width
        end

        -- top bit set at byte_width: negative. Raw flip+increment over exactly byte_width bytes.
        for i = 1, width, 1 do
            limbs[ i ] = 0xFFFF - limbs[ i ]
        end

        limbs[ width ] = rbit_band( limbs[ width ], top_mask )

        for i = 1, width, 1 do
            local total = limbs[ i ] + 1
            if total < 0x10000 then
                limbs[ i ] = total
                break -- carry consumed
            end

            limbs[ i ] = 0
        end

        self.sign = limbs_rstrip( limbs, width ) ~= 0

        return self
    end

    --- [SHARED AND MENU]
    ---
    --- Converts signed `BigInteger` to unsigned one.
    ---
    ---@param byte_width integer The byte width to encode as (e.g. 1 for uint8, 4 for uint32).
    ---@return dreamwork.std.BigInteger self
    function BigInteger:toUnsigned( byte_width )
        local limbs = self.limbs

        local limb_count = limbs[ 0 ]
        if limb_count == 0 then
            return self
        end

        if not self.sign and limbs_byte_count( limbs ) <= byte_width then
            return self
        end

        local width, top_mask = limb_width( byte_width )

        twos_complement_extend( limbs, limb_count, self.sign, width, limbs )

        for i = width + 1, limb_count, 1 do
            limbs[ i ] = nil
        end

        limbs[ width ] = rbit_band( limbs[ width ], top_mask )
        limbs_rstrip( limbs, width )
        self.sign = false

        return self
    end

end

--- [SHARED AND MENU]
---
--- Performs a bitwise XOR operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return dreamwork.std.BigInteger object The result of the operation.
function BigInteger:bxor( value )
    local b = toBigInteger( value )

    local b_limbs = b.limbs

    local b_limb_count = b_limbs[ 0 ]
    if b_limb_count == 0 then
        return self
    end

    local limbs = self.limbs

    local limb_count = limbs[ 0 ]
    if limb_count == 0 then
        self.limbs = limbs_copy( b_limbs, b_limb_count )
        self.sign = b.sign
        return self
    end

    local target_len = math_max( limb_count, b_limb_count ) + 1

    twos_complement_extend( limbs, limb_count, self.sign, target_len, a_buffer )
    twos_complement_extend( b_limbs, b_limb_count, b.sign, target_len, b_buffer )

    for i = 1, target_len do
        limbs[ i ] = rbit_bxor( a_buffer[ i ], b_buffer[ i ] )
    end

    local result_len, is_negative = twos_complement_to_magnitude( limbs, target_len )
    self.sign = result_len ~= 0 and is_negative

    return self
end

do

    local BigInteger_bxor = BigInteger.bxor

    ---@param value any
    ---@return dreamwork.std.BigInteger
    ---@protected
    function BigInteger:__bxor( value )
        return BigInteger_bxor( BigIntegerClass( self ), value )
    end

end
