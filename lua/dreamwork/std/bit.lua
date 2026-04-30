-- Based on https://gist.github.com/x4fx77x4f/5b97e803825d3dc16f6e9c5227ec6a04
local _G = _G

---@class dreamwork.std
local std = dreamwork.std
local math = std.math

--- [SHARED AND MENU]
---
--- The bit library.
---
---@class dreamwork.std.bit
local bit = std.bit or {}
std.bit = bit

if _G.bit ~= nil then

    local glua_bit = _G.bit

    bit.band = glua_bit.band
    bit.bor = glua_bit.bor

    bit.bnot = glua_bit.bnot
    bit.bxor = glua_bit.bxor

    bit.arshift = glua_bit.arshift
    bit.lshift = glua_bit.lshift
    bit.rshift = glua_bit.rshift

    bit.lrotate = glua_bit.rol
    bit.rrotate = glua_bit.ror

    bit.bswap = glua_bit.bswap

    bit.tobit = glua_bit.tobit
    bit.tohex = glua_bit.tohex

end

if bit.tohex == nil then

    local string_format = std.string.format

    --- [SHARED AND MENU]
    ---
    --- Returns the hexadecimal representation of the number with the specified digits.
    ---
    ---@param x integer The value to be converted.
    ---@param length integer? The number of digits. Defaults to 8.
    ---@return string str The hexadecimal representation.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.tohex( x, length )
        return string_format( "%0" .. (length or 8) .. "x", x )
    end

end

if bit.tobit == nil then

    --- [SHARED AND MENU]
    ---
    --- Normalizes the specified value and clamps it in the range of a signed 32bit integer.
    ---
    ---@param x integer The value to be normalized.
    ---@return integer result The normalized value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.tobit( x )
        x = x % 0x100000000

        if x < 0x80000000 then
            return x
        else
            return x - 0x100000000
        end
    end

end

local math_floor = math.floor
local bit_tobit = bit.tobit

if bit.arshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number `x` shifted `disp` bits to the right.
    ---
    --- The number `disp` may be any representable integer.
    ---
    --- Negative displacements shift to the left.
    ---
    --- This shift operation is what is called arithmetic shift.
    ---
    --- Vacant bits on the left are filled with copies of the higher bit of `x`; vacant bits on the right are filled with zeros.
    ---
    --- In particular, displacements with absolute values higher than 31 result in zero or `0xFFFFFFFF` (all original bits are shifted out).
    ---
    ---@param x integer The value to be manipulated.
    ---@param disp integer Amounts of bits to shift.
    ---@return integer result The arithmetically shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.arshift( x, disp )
        if x < 0x80000000 then
            return bit_tobit( math_floor( x / (2 ^ disp) ) )
        else
            return bit_tobit( -math_floor( x / (2 ^ disp) ) )
        end
    end

end

if bit.lshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number `x` shifted `disp` bits to the left.
    ---
    --- The number `disp` may be any representable integer.
    ---
    --- Negative displacements shift to the right.
    ---
    --- In any direction, vacant bits are filled with zeros.
    ---
    --- In particular, displacements with absolute values higher than 31 result in zero (all bits are shifted out).
    ---
    --- ```
    ---     0000 1111   15
    --- LSH 0000 0011   3
    --- _____________
    ---     0111 1000   120
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param disp integer Amounts of bits to shift left by.
    ---@return integer result The left shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.lshift( x, disp )
        if disp > 31 then
            return 0
        else
            return bit_tobit( x * (2 ^ disp) )
        end
    end

end

if bit.rshift == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number `x` shifted `disp` bits to the right.
    ---
    --- The number `disp` may be any representable integer.
    ---
    --- Negative displacements shift to the left. In any direction, vacant bits are filled with zeros.
    ---
    --- In particular, displacements with absolute values higher than 31 result in zero (all bits are shifted out).
    ---
    --- ```
    ---     0111 1000   120
    --- RSH 0000 0011   3
    --- _____________
    ---     0000 1111   15
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param disp integer Amounts of bits to shift right by.
    ---@return integer result The right shifted value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.rshift( x, disp )
        if disp > 31 then
            return 0
        else
            return bit_tobit( math_floor( x / (2 ^ disp) ) )
        end
    end

end

if bit.bswap == nil then

    --- [SHARED AND MENU]
    ---
    --- Swaps the byte order of a 32-bit integer.
    ---
    ---@param x integer The 32-bit integer to be byte-swapped.
    ---@return integer result The byte-swapped value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bswap( x )
        return bit_tobit( ((x % 0x100) * 0x1000000) + ((math_floor( x / 0x100 ) % 0x100) * 0x10000) + ((math_floor( x / 0x10000 ) % 0x100) * 0x100) + (math_floor( x / 0x1000000 ) % 0x100) )
    end

end

if bit.bnot == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise negation of `x`.
    ---
    --- ```
    --- NOT 1111 0000   240
    --- _____________
    ---     0000 1111   15
    --- ```
    ---
    --- <br/>
    ---
    --- For any integer `x`, the following identity holds:
    ---
    --- ```lua
    --- assert( bit.bnot( x ) == ( -1 - x ) % 2 ^ 32 )
    --- ````
    ---
    ---@param x integer The value to be manipulated.
    ---@return integer result The bitwise `not` of the value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bnot( x )
        local result = 0

        for i = 0, 31, 1 do
            if x % 2 == 0 then
                result = result + 2 ^ i
            end

            x = math_floor( x * 0.5 )
        end

        return bit_tobit( result )
    end

end

if bit.band == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise AND of all provided numbers.
    ---
    --- Each bit is tested against the following truth table:
    ---
    --- | A | B | Output |
    --- |:-:|:-:|:------:|
    --- | 0 | 0 |   0    |
    --- | 1 | 0 |   0    |
    --- | 0 | 1 |   0    |
    --- | 1 | 1 |   1    |
    ---
    --- ```
    ---     1100 1110   222
    ---     0101 1000   88
    --- AND 0100 1001   73
    --- _____________
    ---     0100 1000   72
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param ... integer? Values bit and with.
    ---@return integer result The bitwise `and` result between all values.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.band( x, ... )
        local args = { x, ... }
        local result = 0xFFFFFFFF

        local bits = {}
        for i = 1, select( "#", x, ... ), 1 do
            local value = args[ i ]
            for j = 1, 32, 1 do
                if value % 2 == 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result - 2 ^ (j - 1)
                end

                value = math_floor( value * 0.5 )
            end
        end

        return bit_tobit( result )
    end

end

if bit.bor == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise OR of all provided numbers.
    ---
    --- Each bit is tested against the following truth table:
    ---
    --- | A | B | Output |
    --- |:-:|:-:|:------:|
    --- | 0 | 0 |   0    |
    --- | 1 | 0 |   1    |
    --- | 0 | 1 |   1    |
    --- | 1 | 1 |   1    |
    ---
    --- ```
    ---     0101 0001   81
    ---     0001 0101   21
    --- OR  0000 0101   5
    --- _____________
    ---     0101 0101   85
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param ... integer? Values bit or with.
    ---@return integer result The bitwise `or` result between all values.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bor( x, ... )
        local args = { x, ... }
        local result = 0
        local bits = {}

        for i = 1, select( "#", x, ... ), 1 do
            local value = args[ i ]
            for j = 1, 32, 1 do
                if value % 2 ~= 0 and bits[ j ] == nil then
                    bits[ j ] = true
                    result = result + 2 ^ (j - 1)
                end

                value = math_floor( value * 0.5 )
            end
        end

        return bit_tobit( result )
    end

end

if bit.bxor == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the bitwise XOR of all provided numbers.
    ---
    --- Each bit is tested against the following truth table:
    ---
    --- | A | B | Output |
    --- |:-:|:-:|:------:|
    --- | 0 | 0 |   0    |
    --- | 1 | 0 |   1    |
    --- | 0 | 1 |   1    |
    --- | 1 | 1 |   0    |
    ---
    --- <br/>
    ---
    --- ```
    ---     0101 0001   81
    ---     0001 0101   21
    --- XOR 0000 0101   5
    --- _____________
    ---     0100 0001   65
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param ... integer? Values bit xor with.
    ---@return integer result Result of bitwise `xor` operation.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.bxor( x, ... )
        local args = { x, ... }

        local bits = {}
        for i = 1, select( "#", x, ... ), 1 do
            local value = args[ i ]
            for _ = 1, 32, 1 do
                if value % 2 ~= 0 then
                    bits[ i ] = not bits[ i ]
                end

                value = math_floor( value * 0.5 )
            end
        end

        local output = 0
        for i = 1, 32, 1 do
            if bits[ i ] == true then
                output = output + 2 ^ (i - 1)
            end
        end

        return bit_tobit( output )
    end

end

local bit_lshift, bit_rshift = bit.lshift, bit.rshift
local bit_band, bit_bor = bit.band, bit.bor

if bit.lrotate == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number `x` rotated `disp` bits to the left.
    ---
    --- The number `disp` may be any representable integer.
    ---
    --- For any valid displacement, the following identity holds:
    ---
    --- ```lua
    --- assert( bit.lrotate( x, disp ) == bit.lrotate( x, disp % 32 ) )
    --- ```
    ---
    ---@param x integer The value to be manipulated.
    ---@param disp integer Amounts of bits to rotate left by.
    ---@return integer result The left rotated value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.lrotate( x, disp )
        return bit_bor( bit_lshift( x, disp ), bit_rshift( x, 32 - disp ) )
    end

end

if bit.rrotate == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number `x` rotated `disp` bits to the right.
    ---
    --- The number `disp` may be any representable integer.
    ---
    --- For any valid displacement, the following identity holds:
    ---
    --- ```lua
    --- assert( bit.rrotate( x, disp ) == bit.rrotate( x, disp % 32 ) )
    --- ```
    ---
    --- In particular, negative displacements rotate to the left.
    ---
    ---@param x integer The value to be manipulated.
    ---@param disp integer Amounts of bits to rotate right by.
    ---@return integer result The right rotated value.
    ---@diagnostic disable-next-line: duplicate-set-field
    function bit.rrotate( x, disp )
        return bit_bor( bit_rshift( x, disp ), bit_lshift( x, 32 - disp ) )
    end

end

if bit.countlz == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number of consecutive zero bits in the 32-bit representation of the provided number starting from the left-most (most significant) bit.
    ---
    --- Returns 32 if the provided number is zero.
    ---
    ---@param x integer The value to be manipulated.
    ---@return integer count The number of leading zeros.
    function bit.countlz( x )
        if x == 0 then
            return 32
        end

        local n = 0

        for i = 31, 0, -1 do
            if bit_band( bit_rshift( x, i ), 1 ) ~= 0 then
                break
            end

            n = n + 1
        end

        return n
    end

end

if bit.countrz == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the number of consecutive zero bits in the 32-bit representation of the provided number starting from the right-most (least significant) bit.
    ---
    --- Returns 32 if the provided number is zero.
    ---
    ---@param x integer The value to be manipulated.
    ---@return integer count The number of leading zeros.
    function bit.countrz( x )
        if x == 0 then
            return 32
        end

        local count = 0

        while bit_band( x, 1 ) == 0 do
            x = bit_rshift( x, 1 )
            count = count + 1
        end

        return count
    end

end

if bit.extract == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the unsigned number formed by the bits `field` to `field + width - 1` from `n`.
    ---
    --- Bits are numbered from 0 (least significant) to 31 (most significant).
    ---
    --- All accessed bits must be in the range [0, 31].
    ---
    --- The default for `width` is 1.
    ---
    ---@param x integer The value to be manipulated.
    ---@param field integer The starting bit.
    ---@param width integer? The number of bits to extract.
    ---@return integer result The extracted value.
    function bit.extract( x, field, width )
        return bit_band( bit_rshift( x, field ), 2 ^ (width or 1) - 1 )
    end

end

if bit.replace == nil then

    local bit_bnot = bit.bnot

    --- [SHARED AND MENU]
    ---
    --- Returns a copy of `n` with the bits `field` to `field + width - 1` replaced by the value `v`.
    ---
    --- See `bit.extract( value, field, width )` for details about `field` and `width`.
    ---
    ---@param x integer The value to be manipulated.
    ---@param extract integer The value to be extracted.
    ---@param field integer The starting bit.
    ---@param width integer? The number of bits to extract, default is 1.
    ---@return integer result The modified value.
    function bit.replace( x, extract, field, width )
        local mask = 2 ^ (width or 1) - 1
        return bit_band( x, bit_bnot( bit_lshift( mask, field ) ) ) + bit_lshift( bit_band( extract, mask ), field )
    end

end

if bit.btest == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns a boolean signalling whether the bitwise and of its operands is different from zero.
    ---
    ---@param x integer The value to be tested.
    ---@param ... integer? The values to be tested.
    ---@return boolean result `true` if all values are `true`, `false` otherwise.
    function bit.btest( x, ... )
        return bit_band( x, ... ) ~= 0
    end

end

if bit.byteswap == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the given number with the order of the bytes swapped.
    ---
    ---@param x integer The value to be manipulated.
    ---@return integer result The swapped value.
    function bit.byteswap( x )
        return bit_bor(
            bit_lshift( bit_band( x, 0xFF ), 24 ),
            bit_lshift( bit_band( bit_rshift( x, 8 ), 0xFF ), 16 ),
            bit_lshift( bit_band( bit_rshift( x, 16 ), 0xFF ), 8 ),
            bit_rshift( x, 24 )
        )
    end

end

--- [SHARED AND MENU]
---
--- Reverses the bits of the specified value.
---
---@param x integer The value to be reversed.
---@param bits integer The number of bits to reverse.
---@return integer result The reversed value.
function bit.reverse( x, bits )
    local result = 0

    for i = 0, bits - 1, 1 do
        if bit_band( x, bit_lshift( 1, i ) ) ~= 0 then
            result = bit_bor( result, bit_lshift( 1, bits - (i + 1) ) )
        end
    end

    return result
end

local bit_bxor = bit.bxor

--- [SHARED AND MENU]
---
--- Returns the result of a ternary operation.
---
---@param a integer Bitmask: condition bits (non-zero means select from `b`).
---@param b integer Value to select if bit in `a` is 1.
---@param c integer Value to select if bit in `a` is 0.
---@return integer result Result of bitwise ternary: (a ? b : c).
function bit.ternary( a, b, c )
    return bit_bxor( c, bit_band( a, bit_bxor( b, c ) ) )
end

--- [SHARED AND MENU]
---
--- Returns the result of a majority operation.
---
---@param a integer First input integer.
---@param b integer Second input integer.
---@param c integer Third input integer.
---@return integer result Result of Bitwise majority: for each bit, result is 1 if at least two of a, b, c have 1.
function bit.majority( a, b, c )
    return bit_bor( bit_band( a, bit_bor( b, c ) ), bit_band( b, c ) )
end
