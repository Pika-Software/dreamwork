local std = dreamwork.std

---@class dreamwork.std.raw
local raw = std.raw
local raw_select = raw.select

local math = std.math
local math_floor = math.floor

local string = std.string
local string_format = string.format

local loadstring = std.loadstring
local pcall = std.pcall


--- [SHARED AND MENU]
---
--- Native **32-bit integer only** bit library.
---
---@class dreamwork.std.raw.bit
---@field operators boolean Whether the bit operators are available.
local rbit = raw.bit or {}
raw.bit = rbit

local operators = pcall( loadstring, "return ~0xFF", "bitwise.test", {} )
if operators then

    local fn = loadstring( [[
        local rbit = raw.bit
        local raw_select = raw.select

        -- no loops for up to 8 arguments: a loop in such a small shared function gets blacklisted
        -- by the JIT under real workloads, then every call of it runs interpreted (~33 ns instead of ~0.7 ns)
        function rbit.bor( x, a, b, c, d, e, f, g, ... )
            if a == nil then return x end
            x = x | a

            if b == nil then return x end
            x = x | b

            if c == nil then return x end
            x = x | c

            if d == nil then return x end
            x = x | d

            if e == nil then return x end
            x = x | e

            if f == nil then return x end
            x = x | f

            if g == nil then return x end
            x = x | g

            -- 9+ arguments, no caller passes that many
            for i = 1, raw_select( "#", ... ), 1 do
                x = x | raw_select( i, ... )
            end

            return x
        end

        function rbit.bxor( x, a, b, c, d, e, f, g, ... )
            if a == nil then return x end
            x = x ~ a

            if b == nil then return x end
            x = x ~ b

            if c == nil then return x end
            x = x ~ c

            if d == nil then return x end
            x = x ~ d

            if e == nil then return x end
            x = x ~ e

            if f == nil then return x end
            x = x ~ f

            if g == nil then return x end
            x = x ~ g

            -- 9+ arguments, no caller passes that many
            for i = 1, raw_select( "#", ... ), 1 do
                x = x ~ raw_select( i, ... )
            end

            return x
        end

        function rbit.band( x, a, b, c, d, e, f, g, ... )
            if a == nil then return x end
            x = x & a

            if b == nil then return x end
            x = x & b

            if c == nil then return x end
            x = x & c

            if d == nil then return x end
            x = x & d

            if e == nil then return x end
            x = x & e

            if f == nil then return x end
            x = x & f

            if g == nil then return x end
            x = x & g

            -- 9+ arguments, no caller passes that many
            for i = 1, raw_select( "#", ... ), 1 do
                x = x & raw_select( i, ... )
            end

            return x
        end

        function rbit.bnot( x )
            return ~x
        end

        function rbit.lshift( x, n )
            return x << n
        end

        function rbit.rshift( x, n )
            return x >> n
        end
    ]], "dreamwork.std.raw.bit", std )

    if fn == nil or not pcall( fn ) then
        operators = false
    end

end

rbit.operators = operators

if not operators then

    ---@class dreamwork.GModBitLib : bitlib
    ---@field bshift fun( x: integer, disp: integer ): integer
    ---@field brotate fun( x: integer, disp: integer ): integer
    ---@field btest fun( x: integer, ...: integer ): boolean
    ---@field extract fun( x: integer, field: integer, width?: integer ): integer
    ---@field replace fun( x: integer, extract: integer, field: integer, width?: integer ): integer
    ---@diagnostic disable-next-line: undefined-global, deprecated
    local glua_bit = bit or bit32

    rbit.bor = glua_bit.bor
    rbit.bxor = glua_bit.bxor

    rbit.band = glua_bit.band
    rbit.bnot = glua_bit.bnot

    rbit.lshift = glua_bit.lshift
    rbit.rshift = glua_bit.rshift

    rbit.lrotate = glua_bit.rol
    rbit.rrotate = glua_bit.ror

    rbit.bshift = glua_bit.bshift
    rbit.brotate = glua_bit.brotate

    rbit.arshift = glua_bit.arshift

    rbit.btest = glua_bit.btest
    rbit.extract = glua_bit.extract
    rbit.replace = glua_bit.replace

    rbit.bswap = glua_bit.bswap

    rbit.tobit = glua_bit.tobit
    rbit.tohex = glua_bit.tohex

end

if rbit.tobit == nil then

    --- [SHARED AND MENU]
    ---
    --- Normalizes the specified value to a signed 32-bit integer by wrapping it
    --- around modulo `2^32`, so values outside the range are not clamped.
    ---
    --- ```lua
    --- rbit.tobit( 0xFFFFFFFF ) -- -1
    --- rbit.tobit( 2 ^ 32 + 5 ) -- 5
    --- ```
    ---
    ---@param x (integer | ffi.cdata*) The value to be normalized.
    ---@return integer result The normalized value, in the range `-2147483648` to `2147483647`.
    ---@nodiscard
    function rbit.tobit( x )
        x = x % 0x100000000
        return (x < 0x80000000) and x or (x - 0x100000000)
    end

end

local rbit_tobit = rbit.tobit

if rbit.tohex == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the lowercase hexadecimal representation of the number, zero-padded to `length` digits.
    ---
    --- ```lua
    --- rbit.tohex( 255 ) -- "000000ff"
    --- rbit.tohex( 255, 2 ) -- "ff"
    --- ```
    ---
    ---@param x (integer | ffi.cdata*) The value to be converted.
    ---@param length integer? The number of digits, must be positive. Defaults to `8`.
    ---@return string str The hexadecimal representation.
    ---@nodiscard
    function rbit.tohex( x, length )
        return string_format( "%0" .. (length or 8) .. "x", x )
    end

end

if rbit.band == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise AND operation on all the specified 32-bit integers.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The first value.
    ---@param ... T Additional values to AND together with the first.
    ---@return T result The bitwise AND of all given values, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.band( x, ... )
        ---@type boolean[]
        local bits = {}

        ---@type integer
        local result = 0xFFFFFFFF

        for i = 1, raw_select( "#", x, ... ), 1 do
            local value = raw_select( i, x, ... )
            for j = 1, 32, 1 do
                if value % 2 == 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result - (2 ^ (j - 1))
                end

                value = math_floor( value * 0.5 )
            end
        end

        return rbit_tobit( result )
    end

end

local rbit_band = rbit.band

if rbit.bor == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise OR operation on all the specified 32-bit integers.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The first value.
    ---@param ... T Additional values to OR together with the first.
    ---@return T result The bitwise OR of all given values, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.bor( x, ... )
        ---@type boolean[]
        local bits = {}

        ---@type integer
        local result = 0

        for i = 1, raw_select( "#", x, ... ), 1 do
            local value = raw_select( i, x, ... )
            for j = 1, 32, 1 do
                if value % 2 ~= 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result + 2 ^ (j - 1)
                end

                value = math_floor( value * 0.5 )
            end
        end

        return rbit_tobit( result )
    end

end

local rbit_bor = rbit.bor

if rbit.bxor == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise XOR (exclusive OR) operation on all the specified 32-bit integers.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The first value.
    ---@param ... T Additional values to XOR together with the first.
    ---@return T result The bitwise XOR of all given values, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.bxor( x, ... )
        ---@type boolean[]
        local bits = {}

        for i = 1, raw_select( "#", x, ... ), 1 do
            local value = raw_select( i, x, ... )
            for _ = 1, 32, 1 do
                if value % 2 ~= 0 then
                    bits[ i ] = not bits[ i ]
                end

                value = math_floor( value * 0.5 )
            end
        end

        ---@type integer
        local result = 0

        for i = 1, 32, 1 do
            if bits[ i ] then
                result = result + (2 ^ (i - 1))
            end
        end

        return rbit_tobit( result )
    end

end

if rbit.bnot == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise NOT (one's complement) operation on the specified 32-bit integer.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value to be inverted.
    ---@return T result The bitwise complement of the given value, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.bnot( x )
        ---@type integer
        local result = 0

        for i = 0, 31, 1 do
            if (x % 2) == 0 then
                result = result + (2 ^ i)
            end

            x = math_floor( x * 0.5 )
        end

        return rbit_tobit( result )
    end

end

local rbit_bnot = rbit.bnot

if rbit.lshift == nil then

    local rbit_bshift = rbit.bshift
    if rbit_bshift == nil then

        --- [SHARED AND MENU]
        ---
        --- Performs a logical left shift of the specified 32-bit integer by the given number of bits.
        --- Bits shifted out of the top are discarded and zero bits are shifted in from the bottom.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be shifted.
        ---@param disp integer The number of bits to shift left by.
        ---@return T result The shifted value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.lshift( x, disp )
            return rbit_tobit( x * (2 ^ disp) )
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Performs a logical left shift of the specified 32-bit integer by the given number of bits.
        --- Bits shifted out of the top are discarded and zero bits are shifted in from the bottom.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be shifted.
        ---@param disp integer The number of bits to shift left by.
        ---@return T result The shifted value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.lshift( x, disp )
            return rbit_bshift( x, disp )
        end

    end

end

local rbit_lshift = rbit.lshift

if rbit.rshift == nil then

    local rbit_bshift = rbit.bshift
    if rbit_bshift == nil then

        --- [SHARED AND MENU]
        ---
        --- Performs a logical right shift of the specified 32-bit integer by the given number of bits.
        --- Bits shifted out of the bottom are discarded and zero bits are shifted in from the top,
        --- regardless of the sign of the value.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be shifted.
        ---@param disp integer The number of bits to shift right by.
        ---@return T result The shifted value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.rshift( x, disp )
            return rbit_tobit( math_floor( x / (2 ^ disp) ) )
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Performs a logical right shift of the specified 32-bit integer by the given number of bits.
        --- Bits shifted out of the bottom are discarded and zero bits are shifted in from the top,
        --- regardless of the sign of the value.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be shifted.
        ---@param disp integer The number of bits to shift right by.
        ---@return T result The shifted value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.rshift( x, disp )
            return rbit_bshift( x, -disp )
        end

    end

end

local rbit_rshift = rbit.rshift

if rbit.bshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a logical bit shift of the specified 32-bit integer.
    --- A positive displacement shifts left, a negative displacement shifts right.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value to be shifted.
    ---@param disp integer The number of bits to shift by. Positive shifts left, negative shifts right.
    ---@return T result The shifted value, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.bshift( x, disp )
        if disp > 0 then
            return rbit_lshift( x, disp )
        end

        return rbit_rshift( x, -disp )
    end

end

if rbit.arshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs an arithmetic right shift of the specified 32-bit integer by the given number of bits.
    --- Bits shifted out of the bottom are discarded and the sign bit is copied into the vacated
    --- high-order bits, preserving the sign of the value.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value to be shifted.
    ---@param disp integer The number of bits to shift right by.
    ---@return T result The shifted value, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.arshift( x, disp )
        if x < 0x80000000 then
            return rbit_tobit( math_floor( x / (2 ^ disp) ) )
        end

        return rbit_tobit( -math_floor( x / (2 ^ disp) ) )
    end

end

if rbit.lrotate == nil then

    local rbit_brotate = rbit.brotate
    if rbit_brotate == nil then

        --- [SHARED AND MENU]
        ---
        --- Rotates the bits of the specified 32-bit integer to the left by the given number of bits.
        --- Bits shifted out of the top are wrapped around and shifted in at the bottom.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be rotated.
        ---@param disp integer The number of bits to rotate left by.
        ---@return T result The rotated value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.lrotate( x, disp )
            return rbit_bor( rbit_lshift( x, disp ), rbit_rshift( x, 32 - disp ) )
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Rotates the bits of the specified 32-bit integer to the left by the given number of bits.
        --- Bits shifted out of the top are wrapped around and shifted in at the bottom.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be rotated.
        ---@param disp integer The number of bits to rotate left by.
        ---@return T result The rotated value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.lrotate( x, disp )
            return rbit_brotate( x, disp )
        end

    end

end

local rbit_lrotate = rbit.lrotate

if rbit.rrotate == nil then

    local rbit_brotate = rbit.brotate
    if rbit_brotate == nil then

        --- [SHARED AND MENU]
        ---
        --- Rotates the bits of the specified 32-bit integer to the right by the given number of bits.
        --- Bits shifted out of the bottom are wrapped around and shifted in at the top.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be rotated.
        ---@param disp integer The number of bits to rotate right by.
        ---@return T result The rotated value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.rrotate( x, disp )
            return rbit_bor( rbit_rshift( x, disp ), rbit_lshift( x, 32 - disp ) )
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Rotates the bits of the specified 32-bit integer to the right by the given number of bits.
        --- Bits shifted out of the bottom are wrapped around and shifted in at the top.
        ---
        ---@generic T: integer | ffi.cdata*
        ---@param x T The value to be rotated.
        ---@param disp integer The number of bits to rotate right by.
        ---@return T result The rotated value, normalized to a signed 32-bit integer.
        ---@nodiscard
        function rbit.rrotate( x, disp )
            return rbit_brotate( x, -disp )
        end

    end

end

local rbit_rrotate = rbit.rrotate

if rbit.brotate == nil then

    --- [SHARED AND MENU]
    ---
    --- Rotates the bits of the specified 32-bit integer.
    --- A positive displacement rotates left, a negative displacement rotates right.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value to be rotated.
    ---@param disp integer The number of bits to rotate by. Positive rotates left, negative rotates right.
    ---@return T result The rotated value, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.brotate( x, disp )
        if disp > 0 then
            return rbit_lrotate( x, disp )
        end

        return rbit_rrotate( x, -disp )
    end

end

if rbit.btest == nil then

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise AND operation on all the specified 32-bit integers and returns whether
    --- the result is non-zero.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The first value.
    ---@param ... T Additional values to AND together with the first.
    ---@return boolean result `true` if the bitwise AND of all given values is non-zero, `false` otherwise.
    ---@nodiscard
    function rbit.btest( x, ... )
        return rbit_band( x, ... ) ~= 0
    end

end

if rbit.extract == nil then

    --- [SHARED AND MENU]
    ---
    --- Extracts a bit field of the given width from the specified 32-bit integer, starting at
    --- the given bit position (0-indexed, counted from the least significant bit).
    ---
    --- ```lua
    --- rbit.extract( 0xB4, 2, 3 ) -- 5 (0b10110100 -> 0b101)
    --- ```
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value to extract the bit field from.
    ---@param field integer The starting bit position of the field (0-indexed).
    ---@param width integer? The number of bits in the field. Defaults to `1`.
    ---@return T result The extracted bit field, right-aligned as an unsigned integer.
    ---@nodiscard
    function rbit.extract( x, field, width )
        return rbit_band( rbit_rshift( x, field ), 2 ^ (width or 1) - 1 )
    end

end

if rbit.replace == nil then

    --- [SHARED AND MENU]
    ---
    --- Replaces a bit field of the given width in the specified 32-bit integer, starting at the
    --- given bit position (0-indexed, counted from the least significant bit), with the bits
    --- taken from `extract`.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value whose bit field is to be replaced.
    ---@param extract T The value providing the replacement bits (only the lowest `width` bits are used).
    ---@param field integer The starting bit position of the field to replace (0-indexed).
    ---@param width integer? The number of bits in the field. Defaults to `1`.
    ---@return T result The value of `x` with the specified bit field replaced.
    ---@nodiscard
    function rbit.replace( x, extract, field, width )
        local mask = 2 ^ (width or 1) - 1
        return rbit_band( x, rbit_bnot( rbit_lshift( mask, field ) ) ) +
            rbit_lshift( rbit_band( extract, mask ), field )
    end

end

if rbit.bswap == nil then

    --- [SHARED AND MENU]
    ---
    --- Swaps the byte order (endianness) of the specified 32-bit integer, reversing the order
    --- of its four constituent bytes.
    ---
    ---@generic T: integer | ffi.cdata*
    ---@param x T The value whose byte order is to be swapped.
    ---@return T result The byte-swapped value, normalized to a signed 32-bit integer.
    ---@nodiscard
    function rbit.bswap( x )
        return rbit_bor(
            rbit_lshift( rbit_band( x, 0xFF ), 24 ),
            rbit_lshift( rbit_band( x, 0xFF00 ), 8 ),
            rbit_rshift( rbit_band( x, 0xFF0000 ), 8 ),
            rbit_rshift( x, 24 )
        )
    end

end

--- [SHARED AND MENU]
---
--- Reverses the order of the lowest `bit_count` bits of `x`, so the least significant bit
--- becomes the most significant bit (within that range) and vice versa.
---
--- ```lua
--- rbit.reverse( 0x58, 7 ) -- 13 (0b1011000 -> 0b0001101)
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The value whose bits are to be reversed.
---@param bit_count integer? The number of low-order bits to reverse. Defaults to `32`.
---@return T result The value of `x` with its bits reversed.
---@nodiscard
function rbit.reverse( x, bit_count )
    ---@type integer
    local result = rbit_band( x, 1 )
    x = rbit_rshift( x, 1 )

    for i = 2, (bit_count or 32), 1 do
        result = rbit_bor( rbit_lshift( result, 1 ), rbit_band( x, 1 ) )
        x = rbit_rshift( x, 1 )
    end

    return result
end

--- [SHARED AND MENU]
---
--- Converts an unsigned `bit_count`-bit integer to its signed (two's complement) value,
--- the inverse of `rbit.unsign`.
---
--- Every positive `x` has `2 ^ bit_count` subtracted from it, so only pass values that have
--- the sign bit set; zero and negative values are returned unchanged.
---
--- ```lua
--- rbit.sign( 0xFFFFFFFF ) -- -1
--- rbit.sign( 0xFF, 8 ) -- -1
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The unsigned integer to convert.
---@param bit_count? integer The bit width of the integer, `32` by default.
---@return T result The signed value of the integer.
---@nodiscard
function rbit.sign( x, bit_count )
    if x > 0 then
        if bit_count == nil or bit_count == 32 then
            return x - 0x100000000
        elseif bit_count == 24 then
            return x - 0x1000000
        elseif bit_count == 16 then
            return x - 0x10000
        elseif bit_count == 8 then
            return x - 0x100
        end

        return x - (2 ^ bit_count)
    end

    return x
end

--- [SHARED AND MENU]
---
--- Converts a signed `bit_count`-bit integer to its unsigned value, the inverse of `rbit.sign`.
---
--- Negative values have `2 ^ bit_count` added to them; zero and positive values are returned unchanged.
---
--- ```lua
--- rbit.unsign( -1 ) -- 4294967295
--- rbit.unsign( -1, 8 ) -- 255
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The signed integer to convert.
---@param bit_count? integer The bit width of the integer, `32` by default.
---@return T result The unsigned value of the integer.
---@nodiscard
function rbit.unsign( x, bit_count )
    if x < 0 then
        if bit_count == nil or bit_count == 32 then
            return x + 0x100000000
        elseif bit_count == 24 then
            return x + 0x1000000
        elseif bit_count == 16 then
            return x + 0x10000
        elseif bit_count == 8 then
            return x + 0x100
        end

        return x + (2 ^ bit_count)
    end

    return x
end
