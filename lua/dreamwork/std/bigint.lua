--[[
    Lua 5.1 Bigint by soupstream
    https://github.com/soupstream/lua-5.1-bigint
    Re-writed by Unknown Developer
]]

local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local math = std.math
local table = std.table
local string = std.string

local select = std.select
local setmetatable = std.setmetatable

local table_reversed, table_unpack = table.reversed, table.unpack

local math_min, math_max = math.min, math.max
local math_floor, math_clamp = math.floor, math.clamp


--- [SHARED AND MENU]
---
--- The big integer object.
---
---@class dreamwork.std.BigInt : dreamwork.std.Object
---@field __class dreamwork.std.BigIntClass
---@operator add(any): dreamwork.std.BigInt
---@operator sub(any): dreamwork.std.BigInt
---@operator mul(any): dreamwork.std.BigInt
---@operator div(any): dreamwork.std.BigInt
---@operator mod(any): dreamwork.std.BigInt
---@operator pow(any): dreamwork.std.BigInt
---@operator concat(any): dreamwork.std.BigInt
---@operator unm: dreamwork.std.BigInt
---@field sign integer `-1` if negative, `0` if zero, `1` if positive.
---@field size integer The number of bytes that make up the big integer.
local BigInt = std.class.base( "BigInt" )

---@alias BigInt dreamwork.std.BigInt

---@return integer
---@protected
function BigInt:__len()
    return #self * 8
end

---@return boolean
---@protected
function BigInt:__tobool()
    return self[ 0 ] ~= 0
end

--- [SHARED AND MENU]
---
--- The big integer class.
---
---@class dreamwork.std.BigIntClass : dreamwork.std.BigInt
---@field __base dreamwork.std.BigInt
---@overload fun( value: string | number, base: number? ): dreamwork.std.BigInt
local BigIntClass = std.class.create( BigInt )
std.BigInt = BigIntClass

--- [SHARED AND MENU]
---
--- Makes a copy of the big integer.
---
---@param object dreamwork.std.BigInt
---@return dreamwork.std.BigInt
local function copy( object )
    local length = #object
    if length < 5 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ]
        }, BigInt )
    elseif length < 9 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ]
        }, BigInt )
    elseif length < 17 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ],
            object[ 9 ], object[ 10 ], object[ 11 ], object[ 12 ],
            object[ 13 ], object[ 14 ], object[ 15 ], object[ 16 ]
        }, BigInt )

    elseif length < 33 then
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            object[ 1 ], object[ 2 ], object[ 3 ], object[ 4 ],
            object[ 5 ], object[ 6 ], object[ 7 ], object[ 8 ],
            object[ 9 ], object[ 10 ], object[ 11 ], object[ 12 ],
            object[ 13 ], object[ 14 ], object[ 15 ], object[ 16 ],
            object[ 17 ], object[ 18 ], object[ 19 ], object[ 20 ],
            object[ 21 ], object[ 22 ], object[ 23 ], object[ 24 ],
            object[ 25 ], object[ 26 ], object[ 27 ], object[ 28 ],
            object[ 29 ], object[ 30 ], object[ 31 ], object[ 32 ]
        }, BigInt )
    elseif length > 8192 then
        local object_copy = { [ 0 ] = object[ 0 ] }
        for i = 1, length, 1 do
            object_copy[ i ] = object[ i ]
        end

        setmetatable( object_copy, BigInt )
        return object_copy
    else
        return setmetatable( {
            [ 0 ] = object[ 0 ],
            table_unpack( object, 1, length )
        }, BigInt )
    end
end


BigInt.copy = copy

local one = setmetatable( { [ 0 ] = 1, 1 }, BigInt )
local negaive_one = setmetatable( { [ 0 ] = -1, 1 }, BigInt )

--- [SHARED AND MENU]
---
--- Sets the big integer object to zero, removing all values.
---
---@param object dreamwork.std.BigInt
---@return dreamwork.std.BigInt
local function zero( object )
    object[ 0 ] = 0

    for i = 1, #object, 1 do
        object[ i ] = nil
    end

    return object
end

---@protected
function BigInt:__index( key )
    if key == "sign" then
        return self[ 0 ]
    elseif key == 0 then
        return 0
    elseif key == "size" then
        return #self
    end

    return BigInt[ key ]
end

do

    local raw_set = std.raw.set

    ---@protected
    function BigInt:__newindex( key, value )
        if key == "sign" then
            local sign = math_clamp( value, -1, 1 )

            if self[ 0 ] == 0 or sign == self[ 0 ] then
                return self
            elseif sign == 0 then
                zero( self )
                return self
            elseif sign == -1 or sign == 1 then
                self[ 0 ] = sign
                return self
            end

            error( "Invalid sign, how did you get here?", 2 )
        end

        raw_set( self, key, value )
    end

end

local tobigint

--- [SHARED AND MENU]
---
--- Performs an unsigned comparison between two big integers.
---
---@param object dreamwork.std.BigInt
---@param other dreamwork.std.BigInt
---@return integer
local function compare_unsigned( object, other )
    local object_size, other_size = #object, #other
    if object_size < other_size then
        return -1
    elseif object_size > other_size then
        return 1
    end

    for i = object_size, 1, -1 do
        if object[ i ] < other[ i ] then
            return -1
        elseif object[ i ] > other[ i ] then
            return 1
        end
    end

    return 0
end

--- [SHARED AND MENU]
---
--- Removes leading zeros from the big integer.
---
---@param object dreamwork.std.BigInt
local function rstrip( object )
    local i = #object
    while i ~= 0 and object[ i ] == 0 do
        object[ i ] = nil
        i = i - 1
    end

    if i == 0 then
        object[ 0 ] = 0
    end

    return object
end

BigInt.rstrip = rstrip

--- [SHARED AND MENU]
---
--- Sets a big integer object from a lua_number (must be an integer).
---
---@param object dreamwork.std.BigInt
---@param number integer The number to convert to a big integer.
---@return dreamwork.std.BigInt object
local function from_number( object, number )
    if number == 0 then
        object[ 0 ] = 0

        for i = 1, #object, 1 do
            object[ i ] = nil
        end

        return object
    elseif number < 0 then
        number = -number
        object[ 0 ] = -1
    elseif number > 0 then
        object[ 0 ] = 1
    end

    local index = 0
    while number > 0 do
        index = index + 1
        object[ index ] = number % 256
        number = math_floor( number * 0.00390625 )
    end

    return object
end

BigInt.fromNumber = from_number

--- [SHARED AND MENU]
---
--- Converts a lua_number (must be an integer) to a new big integer.
---@param value integer
---@return dreamwork.std.BigInt
function BigIntClass.fromNumber( value )
    return from_number( setmetatable( {}, BigInt ), value )
end

local from_string
do

    local string_byte = string.byte
    local string_len = string.len

    do

        local string_reverse, string_rep = string.reverse, string.rep

        do

            local string_format = string.format
            local table_concat = table.concat

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a hex string.
            ---@param object dreamwork.std.BigInt
            ---@param no_prefix? boolean If `true`, the string will not have a prefix. Defaults to `false`.
            ---@return string hex_str The hex string representation of the big integer.
            local function toHex( object, no_prefix )
                if no_prefix == nil then
                    no_prefix = false
                end

                local sign = object[ 0 ]
                if sign == 0 then
                    return no_prefix and "0" or "0x0"
                end

                local byte_count = #object
                local str = string_reverse( string_format( "%x" .. string_rep( "%02x", byte_count - 1 ), table_unpack( object, 1, byte_count ) ) )

                if not no_prefix then
                    str = "0x" .. str
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toHex = toHex

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a binary [01] string.
            ---
            ---@param object dreamwork.std.BigInt
            ---@param no_prefix? boolean If `true`, the string will not have a prefix. Defaults to `true`.
            ---@return string str The binary string representation of the big integer.
            local function toBinaryString( object, no_prefix )
                if no_prefix == nil then
                    no_prefix = true
                end

                local sign = object[ 0 ]
                if sign == 0 then
                    if no_prefix then
                        return "0"
                    end

                    return "0b0"
                end

                local byte_count = #object
                local result = {}

                for i = 1, byte_count, 1 do
                    local byte_value = object[ i ]

                    local from = ( i - 1 ) * 8 + 1
                    for j = from, from + 7, 1 do
                        if byte_value == 0 then
                            -- if i == byte_count then
                            --     break
                            -- end

                            result[ j ] = 0
                        else
                            result[ j ] = byte_value % 2
                            byte_value = math_floor( byte_value * 0.5 )
                        end
                    end
                end

                local str = string_reverse( table_concat( result ) )

                if not no_prefix then
                    str = "0b" .. str
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toBinaryString = toBinaryString

            local digits = {
                "0", "1", "2",
                "3", "4", "5",
                "6", "7", "8",
                "9", "a", "b",
                "c", "d", "e",
                "f", "g", "h",
                "i", "j", "k",
                "l", "m", "n",
                "o", "p", "q",
                "r", "s", "t",
                "u", "v", "w",
                "x", "y", "z"
            }

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a string in the specified (or not) base.
            ---
            ---@param object dreamwork.std.BigInt
            ---@param base integer The base used in the string. Can be any integer between 2 and 36, inclusive.
            ---@param no_prefix? boolean If `true`, the string will not have a prefix, used for binary and hex.
            ---@return string str The string representation of the big integer
            local function toString( object, base, no_prefix )
                if base == nil then
                    base = 10
                else
                    base = math_clamp( base, 2, 36 )
                end

                if base == 2 then
                    return toBinaryString( object, no_prefix )
                elseif base == 16 then
                    return toHex( object, no_prefix )
                end

                local sign = object[ 0 ]
                if sign == 0 then
                    return "0"
                end

                local result = {}

                local j, carry = 1, 0
                for i = #object, 1, -1 do
                    -- multiply by 256
                    j, carry = 1, 0
                    while result[ j ] ~= nil or carry ~= 0 do
                        local product = ( result[ j ] or 0 ) * 256 + carry
                        result[ j ] = product % base
                        j, carry = j + 1, math_floor( product / base )
                    end

                    -- add byte
                    j, carry = 1, object[ i ]
                    while carry ~= 0 do
                        local sum = ( result[ j ] or 0 ) + carry
                        result[ j ] = sum % base
                        j, carry = j + 1, math_floor( sum / base )
                    end
                end

                local length = #result
                for i = 1, length, 1 do
                    result[ i ] = digits[ result[ i ] + 1 ]
                end

                local str
                if length == 0 then
                    str = "0"
                else
                    str = string_reverse( table_concat( result, "", 1, length ) )
                end

                if sign == -1 then
                    str = "-" .. str
                end

                return str
            end

            BigInt.toString = toString
            BigInt.__tostring = toString

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a decimal string.
            ---
            ---@return string
            function BigInt:toDecimal()
                return toString( self, 10 )
            end

        end

        do

            --- [SHARED AND MENU]
            ---
            --- Sets a big integer object from an byte array and a sign.
            ---
            ---@param object dreamwork.std.BigInt The big integer object to set.
            ---@param bytes dreamwork.std.pack.bytes.Sequence The byte array.
            ---@param byte_count integer The number of bytes.
            ---@param signed boolean If `true`, the big integer object will be signed.
            ---@param big_endian boolean If `true`, the big integer object will be in bit endian.
            ---@return dreamwork.std.BigInt object The big integer object.
            local function fromBytes( object, bytes, byte_count, signed, big_endian )
                local is_zero = true

                for i = big_endian and byte_count or 1, big_endian and 1 or byte_count, big_endian and -1 or 1 do
                    local byte = bytes[ i ]
                    if byte ~= 0 then
                        is_zero = false
                    end

                    object[ i ] = byte
                end

                if is_zero then
                    object[ 0 ] = 0
                else
                    object[ 0 ] = 1

                    if signed then
                        object:toSigned( byte_count )
                    end
                end

                return object
            end

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from an byte array and a sign.
            ---
            ---@param bytes dreamwork.std.pack.bytes.Sequence The byte array.
            ---@param byte_count? integer The number of bytes.
            ---@param signed? boolean If `true`, the big integer object will be signed.
            ---@param big_endian? boolean If `true`, the big integer object will be in bit endian.
            ---@return dreamwork.std.BigInt object The big integer object.
            function BigIntClass.fromBytes( bytes, byte_count, signed, big_endian )
                return fromBytes( setmetatable( {}, BigInt ), bytes, byte_count or #bytes, signed == true, big_endian == true )
            end

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from an byte array and a sign.
            ---
            ---@param bytes dreamwork.std.pack.bytes.Sequence The byte array.
            ---@param byte_count? integer The number of bytes.
            ---@param signed? boolean If `true`, the big integer object will be signed.
            ---@param big_endian? boolean If `true`, the big integer object will be in bit endian.
            ---@return dreamwork.std.BigInt object The big integer object.
            function BigInt:fromBytes( bytes, byte_count, signed, big_endian )
                return fromBytes( self, bytes, byte_count or #bytes, signed == true, big_endian == true )
            end

            --- [SHARED AND MENU]
            ---
            --- Sets a big integer object from a binary data string.
            ---
            ---@param object dreamwork.std.BigInt The big integer object to set.
            ---@param str string The binary data string.
            ---@param byte_count integer The number of bytes.
            ---@param big_endian boolean If `true`, the big integer object will be in big endian.
            ---@param signed boolean If `true`, the big integer object will be signed.
            ---@param start_position? integer The start position in the binary data string.
            ---@return dreamwork.std.BigInt object The big integer object.
            local function fromBinary( object, str, byte_count, big_endian, start_position, signed )
                return fromBytes( object, { string_byte( str, start_position, ( start_position + byte_count ) - 1 ) }, byte_count, signed == true, big_endian == true )
            end

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from a binary data string.
            ---
            ---@param str string The binary data string.
            ---@param byte_count? integer The number of bytes.
            ---@param big_endian? boolean If `true`, the big integer object will be in big endian.
            ---@param start_position? integer The start position in the binary data string.
            ---@param signed? boolean If `true`, the big integer object will be signed.
            ---@return dreamwork.std.BigInt object The big integer object.
            function BigIntClass.fromBinary( str, byte_count, big_endian, start_position, signed )
                return fromBinary( setmetatable( {}, BigInt ), str, byte_count or string_len( str ), big_endian == true, start_position or 1, signed == true )
            end

            --- [SHARED AND MENU]
            ---
            --- Creates a new big integer object from a binary data string.
            ---
            ---@param str string The binary data string.
            ---@param byte_count? integer The number of bytes.
            ---@param big_endian? boolean If `true`, the big integer object will be in big endian.
            ---@param start_position? integer The start position in the binary data string.
            ---@param signed? boolean If `true`, the big integer object will be signed.
            ---@return dreamwork.std.BigInt object The big integer object.
            function BigInt:fromBinary( str, byte_count, big_endian, start_position, signed )
                return fromBinary( self, str, byte_count or string_len( str ), big_endian == true, start_position or 1, signed == true )
            end

        end

        do

            local string_char = string.char

            --- [SHARED AND MENU]
            ---
            --- Converts the big integer to a binary string [01].
            ---
            ---@param size? integer The size of the binary string.
            ---@param big_endian? boolean If `true`, the binary string will be in big endian.
            ---@return string binary_str The binary string representation of the big integer.
            ---@return integer binary_length The length of the binary string.
            function BigInt:toBinary( size, big_endian )
                local byte_count = #self
                if byte_count == 0 then
                    size = size or byte_count or 1
                    return string_rep( "\0", size ), size
                elseif size == nil then
                    size = byte_count
                elseif size < 1 then
                    return "", 0
                end

                local str_size = math_min( size, byte_count )
                local str = string_char( table_unpack( self, 1, str_size ) )

                if str_size ~= size then
                    str = str .. string_rep( "\0", size - str_size )
                end

                if big_endian then
                    return string_reverse( str ), size
                else
                    return str, size
                end
            end

            ---@param writer dreamwork.std.pack.Writer
            ---@protected
            function BigInt:__serialize( writer )
                writer:writeCountedString( string_char( self[ 0 ], table_unpack( self, 1, #self ) ), 16, false )
            end

        end

    end

    ---@param reader dreamwork.std.pack.Reader
    function BigInt:__deserialize( reader )
        local binary_str, binary_length, err_msg = reader:readCountedString( 16, false )

        if binary_str == nil then
            error( "Big integer serialization failed: " .. err_msg, 3 )
        end

        for i = 1, binary_length, 1 do
            self[ i - 1 ] = string_byte( binary_str, i, i )
        end
    end

    local string_sub = string.sub
    local tonumber = std.tonumber

    --- [SHARED AND MENU]
    ---
    --- Sets a big integer object from a decimal string with an optional base.
    ---
    ---@param object dreamwork.std.BigInt
    ---@param str string
    ---@param base? integer
    ---@return dreamwork.std.BigInt
    function from_string( object, str, base )
        local digits_start, digits_end = 1, string_len( str )

        if string_byte( str, digits_start ) == 0x2d then -- "-"
            digits_start = digits_start + 1
            object[ 0 ] = -1
        else
            object[ 0 ] = 1
        end

        if string_byte( str, digits_start ) == 0x30 then -- "0"
            digits_start = digits_start + 1

            local prefix = string_byte( str, digits_start )
            if ( base == nil or base == 16 ) and prefix == 0x78 then      -- "x"
                base = 16
                digits_start = digits_start + 1
            elseif ( base == nil or base == 2 ) and prefix == 0x62 then   -- "b"
                base = 2
                digits_start = digits_start + 1
            end
        end

        while string_byte( str, digits_start ) == 0x30 do -- "0"
            digits_start = digits_start + 1
        end

        if digits_start > digits_end then
            object[ 0 ] = 0
            return object
        end

        base = math_clamp( base or 10, 2, 36 )
        if base == 2 or base == 16 then
            -- fast bin/hex parser
            local width = base == 16 and 2 or 8

            local i = 1
            for j = digits_end, digits_start, -width do
                if j - width + 1 <= digits_start then
                    object[ i ] = tonumber( string_sub( str, digits_start, j ), base )
                else
                    object[ i ] = tonumber( string_sub( str, j - width + 1, j ), base )
                end

                i = i + 1
            end

            return object
        end

        -- general parser
        local j, carry = 1, 0
        for i = digits_start, digits_end, 1 do
            -- multiply by base
            j, carry = 1, 0
            while object[ j ] ~= nil or carry ~= 0 do
                local product = ( object[ j ] or 0 ) * base + carry
                object[ j ] = product % 256
                carry = math_floor( product * 0.00390625 )
                j = j + 1
            end

            -- add digit
            j, carry = 1, tonumber( string_sub( str, i, i ), base ) or 0
            while carry ~= 0 do
                local sum = ( object[ j ] or 0 ) + carry
                object[ j ] = sum % 256
                carry = math_floor( sum * 0.00390625 )
                j = j + 1
            end
        end

        return object
    end

    BigInt.fromString = from_string

    --- [SHARED AND MENU]
    ---
    --- Creates a big integer object from a decimal string with an optional base.
    ---
    ---@param value string
    ---@param base? integer
    ---@return dreamwork.std.BigInt
    function BigIntClass.fromString( value, base )
        return from_string( setmetatable( {}, BigInt ), value, base )
    end

    do

        local isString, isNumber = std.isString, std.isNumber
        local debug_getmetatable = std.debug.getmetatable

        --- [SHARED AND MENU]
        ---
        --- Converts a given value to a big integer object.
        ---
        ---@param value any
        ---@param base? integer
        ---@return dreamwork.std.BigInt
        function tobigint( value, base )
            if debug_getmetatable( value ) == BigInt then
                return value
            elseif isString( value ) then
                return from_string( setmetatable( {}, BigInt ), value, base )
            elseif isNumber( value ) then
                return from_number( setmetatable( {}, BigInt ), value )
            end

            local number = tonumber( value, base )
            if number == nil then
                error( "Failed to convert value to big integer.", 2 )
            end

            return from_number( setmetatable( {}, BigInt ), number )
        end

        ---@param value any
        ---@param base? integer
        ---@return dreamwork.std.BigInt
        ---@protected
        function BigIntClass:__new( value, base )
            return tobigint( value, base )
        end

    end

end

local toInteger
do

    local max_number

    -- determine the max accurate integer supported by this build of Lua
    if 0x1000000 == 0x1000001 then
        max_number = from_string( setmetatable( { [ 0 ] = 0 }, BigInt ), "0xffffff" )
    else
        max_number = from_string( setmetatable( { [ 0 ] = 0 }, BigInt ), "0x1FFFFFFFFFFFFF" )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a big integer object to a lua_number (always an integer).
    ---
    ---@param object dreamwork.std.BigInt The big integer object to convert.
    ---@return integer number The number that the big integer object represents.
    function toInteger( object )
        if compare_unsigned( object, max_number ) == 1 then
            error( "Big integer is too large to be converted to Lua number.", 2 )
        end

        local result = 0
        for i = #object, 1, -1 do
            result = ( result * 256 ) + object[ i ]
        end

        return result * object[ 0 ]
    end

    BigInt.toInteger = toInteger
    BigInt.__tonumber = toInteger

end

do

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is even.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to check.
    ---@return boolean result `true` if the big integer object is even, `false` otherwise.
    local function is_even( object )
        return object[ 0 ] == 0 or object[ 1 ] % 2 == 0
    end

    BigInt.isEven = is_even

    --- [SHARED AND MENU]
    ---
    --- Checks if a big integer object is odd.
    ---
    ---@return boolean `true` if the big integer object is odd, `false` otherwise.
    function BigInt:isOdd()
        return not is_even( self )
    end

end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is zero.
---
---@return boolean `true` if the big integer object is zero, `false` otherwise.
function BigInt:isZero()
    return self[ 0 ] == 0
end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is one.
---
---@return boolean `true` if the big integer object is one, `false` otherwise.
local function is_one( object )
    return object[ 2 ] == nil and object[ 1 ] == 1
end

BigInt.isOne = is_one

--- [SHARED AND MENU]
---
--- Negates a big integer object.
---
---@param object dreamwork.std.BigInt The big integer object to negate.
---@return dreamwork.std.BigInt object The negated big integer object.
local function negate( object )
    local sign = object[ 0 ]
    if sign ~= 0 then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.negate = negate

---@protected
function BigInt:__unm()
    return negate( copy( self ) )
end

--- [SHARED AND MENU]
---
--- Makes a big integer object absolute (simply removes the sign).
---
---@param object dreamwork.std.BigInt The big integer object to make absolute.
---@return dreamwork.std.BigInt object The absolute big integer object.
local function abs( object )
    if object[ 0 ] < 0 then
        object[ 0 ] = 1
    end

    return object
end

BigInt.abs = abs

local bit_lshift
do

    local bit_rshift

    --- [SHARED AND MENU]
    ---
    --- Shifts a big integer object to the left by a given number of bits (positive or negative).
    ---
    ---@param object dreamwork.std.BigInt The big integer object to shift.
    ---@param shift integer The number of bits to shift by.
    ---@return dreamwork.std.BigInt object The shifted big integer object.
    function bit_lshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bit_rshift( object, -shift )
        end

        -- shift whole bytes
        local shift_bytes, byte_count = math_floor( shift * 0.125 ), #object

        for i = byte_count + 1, byte_count + shift_bytes, 1 do
            object[ i ] = 0
        end

        for i = byte_count + shift_bytes, shift_bytes + 1, -1 do
            object[ i ] = object[ i - shift_bytes ]
        end

        for i = shift_bytes, 1, -1 do
            object[ i ] = 0
        end

        byte_count = byte_count + shift_bytes

        -- shift bits
        local shift_bits = shift % 8
        if shift_bits == 0 then
            return object
        end

        local shift_size, unshift_size = 2 ^ shift_bits, 2 ^ ( 8 - shift_bits )

        for i = byte_count, shift_bytes + 1, -1 do
            local overflow = math_floor( object[ i ] / unshift_size )
            object[ i ] = ( object[ i ] * shift_size ) % 256

            if overflow ~= 0 then
                object[ i + 1 ] = ( object[ i + 1 ] or 0 ) + overflow
            end
        end

        return object
    end

    BigInt.lshift = bit_lshift

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of shifting a given big integer object to the left by a given number of bits.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to shift.
    ---@param shift integer The number of bits to shift by.
    ---@return dreamwork.std.BigInt object The shifted big integer object.
    function BigIntClass.lshift( object, shift )
        return bit_lshift( copy( object ), shift )
    end

    --- [SHARED AND MENU]
    ---
    --- Shifts a big integer object to the right by a given number of bits (positive or negative).
    ---
    ---@param object dreamwork.std.BigInt The big integer object to shift.
    ---@param shift integer The number of bits to shift by.
    ---@return dreamwork.std.BigInt object The shifted big integer object.
    function bit_rshift( object, shift )
        if object[ 0 ] == 0 or shift == 0 then
            return object
        elseif shift < 0 then
            return bit_lshift( object, -shift )
        end

        -- shift whole bytes
        local shift_bytes, byte_count = math_floor( shift * 0.125 ), #object
        if shift_bytes >= byte_count then
            zero( object )
            return object
        end

        for i = shift_bytes + 1, byte_count, 1 do
            object[ i - shift_bytes ] = object[ i ]
        end

        for i = byte_count - shift_bytes + 1, byte_count, 1 do
            object[ i ] = nil
        end

        byte_count = byte_count - shift_bytes

        -- shift bits
        local shift_bits = shift % 8
        if shift_bits == 0 then
            return object
        end

        local shift_size, unshift_size = 2 ^ shift_bits, 2 ^ ( 8 - shift_bits )

        for i = 1, byte_count, 1 do
            local overflow = object[ i ] % shift_size
            object[ i ] = math_floor( object[ i ] / shift_size )

            if i ~= 1 then
                object[ i - 1 ] = object[ i - 1 ] + overflow * unshift_size
            end
        end

        -- strip zero
        if object[ byte_count ] == 0 then
            object[ byte_count ] = nil

            if byte_count == 1 then
                object[ 0 ] = 0
            end
        end

        return object
    end

    BigInt.rshift = bit_rshift

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of shifting a given big integer object to the right by a given number of bits.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to shift.
    ---@param shift integer The number of bits to shift by.
    ---@return dreamwork.std.BigInt object The shifted big integer object.
    function BigIntClass.rshift( object, shift )
        return bit_rshift( copy( object ), shift )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise OR operation between two big integer objects.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param value any The value to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    local function bor( object, value )
        local other = tobigint( value )
        ---@cast other dreamwork.std.BigInt

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            return abs( other )
        elseif compare_unsigned( object, other ) == 0 then
            return object
        end

        for i = 1, math_max( #object, #other ), 1 do
            local bit_number = 1
            local result = 0

            local byte_value1 = object[ i ]
            local byte_value1_copy = byte_value1

            if byte_value1 == nil then
                byte_value1 = 0
            end

            local byte_value2 = other[ i ] or 0

            for _ = 1, 8, 1 do
                if ( byte_value1 % 2 ) >= 1 or ( byte_value2 % 2 ) >= 1 then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            if result ~= byte_value1_copy then
                object[ i ] = result
            end
        end

        return object
    end

    BigInt.bor = bor

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise OR operation between two big integer objects.
    ---
    ---@param value dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param ... any The values to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    function BigIntClass.bor( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            object = bor( object, args[ i ] )
        end

        return object
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise AND operation between two big integer objects.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param value any The value to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    local function band( object, value )
        local other = tobigint( value )
        ---@cast other dreamwork.std.BigInt

        if object[ 0 ] == 0 then
            return object
        elseif other[ 0 ] == 0 then
            return abs( other )
        elseif compare_unsigned( object, other ) == 0 then
            return object
        end

        local changed = false

        for i = 1, math_max( #object, #other ), 1 do
            local bit_number = 1
            local result = 0

            local byte_value1 = object[ i ] or 0
            local byte_value2 = other[ i ] or 0
            local byte_value1_copy = byte_value1

            for _ = 1, 8, 1 do
                if ( byte_value1 % 2 ) >= 1 and ( byte_value2 % 2 ) >= 1 then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            if result ~= byte_value1_copy then
                object[ i ] = result
                changed = true
            end
        end

        if changed then
            rstrip( object )
        end

        return object
    end

    BigInt.band = band

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise AND operation between two big integer objects.
    ---
    ---@param value dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param ... any The values to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    function BigIntClass.band( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            band( object, args[ i ] )
        end

        return object
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise XOR operation between two big integer objects.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param value any The value to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    local function bxor( object, value )
        local other = tobigint( value )
        ---@cast other dreamwork.std.BigInt

        if other[ 0 ] == 0 then
            return object
        elseif object[ 0 ] == 0 then
            abs( other )
            return other
        elseif compare_unsigned( object, other ) == 0 then
            zero( object )
            return object
        end

        for i = 1, math_max( #object, #other ), 1 do
            local byte_value1, byte_value2 = object[ i ] or 0, other[ i ] or 0
            local bit_number = 1
            local result = 0

            for _ = 1, 8, 1 do
                if ( ( byte_value1 % 2 ) >= 1 ) ~= ( ( byte_value2 % 2 ) >= 1 ) then
                    result = result + bit_number
                end

                byte_value1, byte_value2 = byte_value1 * 0.5, byte_value2 * 0.5
                bit_number = bit_number * 2
            end

            object[ i ] = result
        end

        rstrip( object )
        return object
    end

    BigInt.bxor = bxor

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise XOR operation between two big integer objects.
    ---
    ---@param value dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param ... any The values to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    function BigIntClass.bxor( value, ... )
        local object = copy( value )
        local args = { ... }

        for i = 1, select( '#', ... ), 1 do
            bxor( object, args[ i ] )
        end

        return object
    end

end

local bnot
do

    --- [SHARED AND MENU]
    ---
    --- Performs a bitwise NOT operation on a big integer object.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param value integer The value to perform the operation on.
    ---@return dreamwork.std.BigInt object The result of the operation.
    function bnot( object, value )
        if object[ 0 ] == 0 then
            object[ 0 ], object[ 1 ] = 1, 0xff
            return object
        end

        local byte_count = #object

        for i = 1, byte_count, 1 do
            local bit_number = 1
            local result = 0

            local byte_value = object[ i ]
            for _ = 1, 8, 1 do
                if ( byte_value % 2 ) < 1 then
                    result = result + bit_number
                end

                byte_value = byte_value * 0.5
                bit_number = bit_number * 2
            end

            object[ i ] = result
        end

        for i = byte_count + 1, math_max( value or byte_count, 1 ), 1 do
            object[ i ] = 0xff
        end

        rstrip( object )
        return object
    end

    BigInt.bnot = bnot

    --- [SHARED AND MENU]
    ---
    --- Creates a new big integer object that is the result of a bitwise NOT operation on a big integer object.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to perform the operation on.
    ---@param size integer The size of the new big integer object.
    ---@return dreamwork.std.BigInt object The result of the operation.
    function BigIntClass.bnot( object, size )
        return bnot( copy( object ), size )
    end

end

--- [SHARED AND MENU]
---
--- Returns the value of a given bit in a big integer object.
---
---@param index integer The index of the bit to get.
---@return boolean | nil bit The value of the bit or `nil` if the index is invalid.
function BigInt:getBit( index )
    index = math_max( index, 1 )
    if index < 1 then
        return nil
    elseif self[ 0 ] == 0 then
        return false
    end

    index = index - 1

    local byte_value = self[ math_floor( index / 8 ) + 1 ]
    if byte_value == nil or byte_value == 0 then
        return false
    else
        return math_floor( byte_value / ( 2 ^ ( index % 8 ) ) ) % 2 == 1
    end
end

--- [SHARED AND MENU]
---
--- Sets `true` of one or more bits in a big integer object.
---
---@param ... integer The indices of the bits to set.
---@return dreamwork.std.BigInt object The big integer object.
function BigInt:setBits( ... )
    local arg_count = select( "#", ... )
    if arg_count == 0 then
        return self
    end

    local args = { ... }
    local changed = false
    local byte_count = #self

    for i = 1, arg_count, 1 do
        local selected_bit = math_max( args[ i ], 1 ) - 1

        local byte_number = math_floor( selected_bit / 8 ) + 1
        if byte_number > byte_count then
            for j = byte_count + 1, byte_number, 1 do
                self[ j ] = 0
            end

            changed = true
            byte_count = byte_number
        end

        local bit_number = 2 ^ ( selected_bit % 8 )
        local byte_value = self[ byte_number ]

        if ( byte_value / bit_number ) % 2 < 1 then
            self[ byte_number ] = byte_value + bit_number
        end
    end

    if changed and self[ 0 ] == 0 then
        self[ 0 ] = 1
    end

    return self
end

--- [SHARED AND MENU]
---
--- Unsets `false` of one or more bits in a big integer object.
---
---@param ... integer The indices of the bits to unset.
---@return dreamwork.std.BigInt object The big integer object.
function BigInt:unsetBits( ... )
    if self[ 0 ] == 0 then
        return self
    end

    local arg_count = select( "#", ... )
    if arg_count == 0 then
        return self
    end

    local changed = false
    local args = { ... }

    for i = 1, arg_count, 1 do
        local selected_bit = math_max( args[ i ], 1 ) - 1
        local byte_number = math_floor( selected_bit / 8 ) + 1

        local byte_value = self[ byte_number ]
        if byte_value ~= nil then
            local bit_number = 2 ^ ( selected_bit % 8 )
            if ( byte_value / bit_number ) % 2 >= 1 then
                self[ byte_number ] = byte_value - bit_number
                changed = true
            end
        end
    end

    if changed then
        rstrip( self )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Adds big integer to a big integer object.
---@param object dreamwork.std.BigInt The big integer object to add to.
---@param other dreamwork.std.BigInt The value to add.
---@return dreamwork.std.BigInt object The result of the operation.
local function add( object, other )
    -- addition of 0
    if other[ 0 ] == 0 then
        return object
    elseif object[ 0 ] == 0 then
        return other
    end

    -- determine sign, operation, and order of operands
    local subtract, swap_order, change_sign = false, false,false

    if object[ 0 ] == other[ 0 ] then
        if #object < #other then
            swap_order = true
        end
    else
        local compare_result = compare_unsigned( object, other )
        if compare_result == 0 then
            zero( object )
            return object
        elseif compare_result == -1 then
            swap_order, change_sign = true, true
        end

        subtract = true
    end

    -- perform operation
    local object1, object2

    if swap_order then
        object1, object2 = other, object
    else
        object1, object2 = object, other
    end

    local object1_size, object2_size = #object1, #object2
    local carry = 0

    for i = 1, object1_size, 1 do
        local total

        if subtract then
            total = ( object1[ i ] or 0 ) - ( object2[ i ] or 0 ) + carry
        else
            total = ( object1[ i ] or 0 ) + ( object2[ i ] or 0 ) + carry
        end

        if not subtract and total >= 256 then
            object[ i ], carry = total - 256, 1
        elseif subtract and total < 0 then
            object[ i ], carry = total + 256, -1
        else
            object[ i ], carry = total, 0
        end

        -- end loop as soon as possible
        if i >= object2_size and carry == 0 then
            if swap_order then
                -- just need to copy remaining bytes
                for j = i + 1, object1_size, 1 do
                    object[ j ] = object1[ j ]
                end
            end

            break
        end
    end

    if carry > 0 then
        object[ object1_size + 1 ] = carry
    end

    if subtract then
        rstrip( object )
    end

    if change_sign then
        object[ 0 ] = -object[ 0 ]
    end

    return object
end

BigInt.add = add

---@param value any
---@return dreamwork.std.BigInt
---@protected
function BigInt:__add( value )
    return add( copy( self ), tobigint( value ) )
end

--- [SHARED AND MENU]
---
--- Subtracts big integer from a big integer object.
---
---@param object dreamwork.std.BigInt The big integer object to subtract from.
---@param other dreamwork.std.BigInt The value to subtract.
---@return dreamwork.std.BigInt object The result of the operation.
local function sub( object, other )
    return add( object, negate( other ) )
end

BigInt.sub = sub

---@param value any
---@return dreamwork.std.BigInt
---@protected
function BigInt:__sub( value )
    return sub( copy( self ), tobigint( value ) )
end

--- [SHARED AND MENU]
---
--- Multiplies big integer with a big integer object.
---
---@param object dreamwork.std.BigInt The big integer object to multiply.
---@param other dreamwork.std.BigInt The value to multiply.
---@return dreamwork.std.BigInt object The result of the operation.
local function mul( object, other )
    -- multiplication by 0
    if object[ 0 ] == 0 then
        return object
    elseif other[ 0 ] == 0 then
        object[ 0 ] = 0

        for i = 1, #object, 1 do
            object[ i ] = nil
        end

        return object
    end

    -- multiplication by 1
    if is_one( object ) then
        local other_copy = copy( other )
        if object[ 0 ] == -1 then
            negate( other_copy )
        end

        return other_copy
    end

    if is_one( other ) then
        if other[ 0 ] == -1 then
            negate( object )
        end

        return object
    end

    -- general multiplication
    local object1, object2 = object, other
    local object1_size, object2_size = #object1, #object2

    if object2_size > object1_size then
        -- swap order so that number with more object1 comes first
        object1, object2, object1_size, object2_size = other, object, object2_size, object1_size
    end

    local result = {}
    local carry = 0

    for i = 1, object2_size, 1 do
        if object2[ i ] == 0 then
            if result[ i ] == nil then
                result[ i ] = 0
            end
        else

            -- multiply each byte
            local j = 1
            while j <= object1_size do
                local ri = i + j - 1
                local product = object1[ j ] * object2[ i ] + carry + ( result[ ri ] or 0 )

                -- add product to result
                result[ ri ] = product % 256
                carry = math_floor( product * 0.00390625 )
                j = j + 1
            end

            -- finish adding carry
            while carry ~= 0 do
                local ri = i + j - 1
                local sum = ( result[ ri ] or 0 ) + carry

                result[ ri ] = sum % 256
                carry = math_floor( sum * 0.00390625 )
                j = j + 1
            end

        end
    end

    object[ 0 ] = object[ 0 ] * other[ 0 ]

    for i = 1, #result, 1 do
        object[ i ] = result[ i ]
    end

    return object
end

BigInt.mul = mul

---@param value any
---@return dreamwork.std.BigInt
---@protected
function BigInt:__mul( value )
    return mul( copy( self ), tobigint( value ) )
end

local full_div
do

    --- [SHARED AND MENU]
    ---
    --- Divides big integer by a big integer object and returns the quotient and remainder.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to divide.
    ---@param other dreamwork.std.BigInt The value to divide by.
    ---@param ignore_remainder? boolean Whether to ignore the remainder.
    ---@return dreamwork.std.BigInt quotient The quotient of the division.
    ---@return dreamwork.std.BigInt remainder The remainder of the division.
    function full_div( object, other, ignore_remainder )
        -- division of/by 0
        if object[ 0 ] == 0 then
            return object, object
        elseif other[ 0 ] == 0 then
            return other, other
        end

        -- division by 1
        if is_one( other ) then
            if other[ 0 ] == -1 then
                negate( object )
            end

            return object, setmetatable( { [ 0 ] = 0 }, BigInt )
        end

        -- division by bigger number or object
        local compare_result = compare_unsigned( object, other )
        if compare_result == -1 then
            if object[ 0 ] == other[ 0 ] then
                return setmetatable( { [ 0 ] = 0 }, BigInt ), object
            elseif ignore_remainder then
                return setmetatable( { [ 0 ] = 0 }, BigInt ), object
            end

            return setmetatable( { [ 0 ] = 0 }, BigInt ), add( object, other )
        elseif compare_result == 0 then
            if object[ 0 ] == other[ 0 ] then
                return setmetatable( { [ 0 ] = 1, 1 }, BigInt ), setmetatable( { [ 0 ] = 0 }, BigInt )
            end

            return setmetatable( { [ 0 ] = -1, 1 }, BigInt ), setmetatable( { [ 0 ] = 0 }, BigInt )
        end

        -- general division
        local object_copy, other_copy = copy( object ), copy( other )
        local object_size, other_size = #object_copy, #other_copy

        local result = {}
        local ri = 1

        local di = object_size - other_size + 1
        while di >= 1 do
            local factor = 0
            repeat

                -- check if divisor is smaller
                local found_factor = false

                local size = other_size
                if di + size <= object_size and object_copy[ di + size ] ~= 0 then
                    size = size + 1
                end

                for i = size, 1, -1 do
                    local byte_value1 = object_copy[ di + i - 1 ] or 0
                    local byte_value2 = other_copy[ i ] or 0
                    if byte_value2 < byte_value1 then
                        found_factor = false
                        break
                    elseif byte_value2 > byte_value1 then
                        found_factor = true
                        break
                    end
                end

                -- subtract divisor
                if not found_factor then
                    factor = factor + 1
                    local carry = 0
                    local i = 1

                    while i <= size or carry ~= 0 do
                        local j = di + i - 1
                        local diff = ( object_copy[ j ] or 0 ) - ( other_copy[ i ] or 0 ) + carry
                        if diff < 0 then
                            carry = -1
                            diff = diff + 256
                        else
                            carry = 0
                        end

                        object_copy[ j ] = diff
                        i = i + 1
                    end
                end
            until found_factor

            -- set digit
            result[ ri ] = factor
            ri = ri + 1

            di = di - 1
        end

        local object_sign, other_sign = object_copy[ 0 ], other_copy[ 0 ]

        rstrip( object_copy )

        -- if remainder is negative, add divisor to make it positive
        if not ignore_remainder and object_sign == -other_sign and object_copy[ 0 ] ~= 0 then
            add( object_copy, other_copy )
        end

        other_copy[ 0 ] = object_sign * other_sign

        local reversed, length = table_reversed( result )

        for index = 1, length, 1 do
            other_copy[ index ] = reversed[ index ]
        end

        rstrip( other_copy )

        if object_copy[ 0 ] ~= 0 and other_sign == -1 then
            object_copy[ 0 ] = -1
        end

        return other_copy, object_copy
    end

    --- [SHARED AND MENU]
    ---
    --- Divides big integer by a big integer object.
    ---
    ---@param object dreamwork.std.BigInt The big integer to divide.
    ---@param other dreamwork.std.BigInt The value to divide by.
    ---@return dreamwork.std.BigInt quotient The quotient of the division.
    local function div( object, other )
        ---@diagnostic disable-next-line: redundant-return-value
        return full_div( object, other, true ), nil
    end

    BigInt.div = div

    ---@param value any
    ---@return dreamwork.std.BigInt
    ---@protected
    function BigInt:__div( value )
        return div( self, tobigint( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the remainder from dividing two big integers.
    ---
    ---@param object dreamwork.std.BigInt The big integer to divide.
    ---@param other dreamwork.std.BigInt The value to divide by.
    ---@return dreamwork.std.BigInt remainder The remainder of the division.
    local function mod( object, other )
        local _, remainder = full_div( object, other, false )
        return remainder
    end

    BigInt.mod = mod

    ---@param value any
    ---@return dreamwork.std.BigInt
    ---@protected
    function BigInt:__mod( value )
        return mod( self, tobigint( value ) )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the log2 of a big integer object. ( calculate log2 by finding highest 1 bit )
    ---
    ---@return dreamwork.std.BigInt | nil result The log2 of the big integer object.
    function BigInt:log2()
        if self[ 0 ] == 0 then return nil end

        local byte_count = #self
        local byte_number = ( byte_count - 1 ) * 8

        local byte = self[ byte_count ]

        while byte >= 1 do
            byte_number = byte_number + 1
            byte = byte * 0.5
        end

        return from_number( setmetatable( {}, BigInt ), byte_number - 1 )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the log2 of a big integer object. ( return log2 if it's an integer, else `nil` )
    ---
    ---@param object dreamwork.std.BigInt The big integer object to check.
    ---@return integer | nil result The log2 of the big integer object.
    local function log2( object )
        if object[ 0 ] == 0 then return nil end

        local index, power = 1, 0
        local failed = false

        while object[ index ] ~= nil do
            local byte_value = object[ index ]
            for _ = 1, 8, 1 do
                if byte_value % 2 == 0 then
                    if not failed then
                        power = power + 1
                    end
                elseif failed then
                    return nil
                else
                    failed = true
                end

                byte_value = byte_value * 0.5
            end

            index = index + 1
        end

        return power
    end

    --- [SHARED AND MENU]
    ---
    --- Raises a big integer object to a power.
    ---
    ---@param object dreamwork.std.BigInt The big integer object to raise.
    ---@param other dreamwork.std.BigInt The value to raise to.
    ---@return dreamwork.std.BigInt object The result of the operation.
    local function pow( object, other )
        if other[ 0 ] == 0 then
            return setmetatable( { [ 0 ] = 1, 1 }, BigInt )
        elseif other[ 0 ] == -1 then
            zero( object )
            return object
        elseif is_one( other ) then
            return object
        end

        local sign = object[ 0 ]
        if sign == -1 and other[ 1 ] % 2 == 0 then
            sign = 1
        end

        -- fast exponent if self is a power of 2
        local power = log2( object )
        if power ~= nil then
            -- assumes other isn't so big that precision becomes an issue
            local object_copy = copy( object )
            bit_lshift( object_copy, ( toInteger( object_copy ) - 1 ) * power )
            object_copy.sign = sign
            return object_copy
        end

        -- multiply by self repeatedly
        local other_copy = copy( other )

        abs( other_copy )
        add( other_copy, negaive_one )

        local object_copy = copy( object )

        while other_copy[ 0 ] ~= 0 do
            mul( object_copy, object )
            add( other_copy, negaive_one )
        end

        object_copy[ 0 ] = sign
        return object_copy
    end

    BigInt.pow = pow

    ---@param value any
    ---@return dreamwork.std.BigInt
    ---@protected
    function BigInt:__pow( value )
        return pow( copy( self ), tobigint( value ) )
    end

end

--- [SHARED AND MENU]
---
--- Convert 2's complement unsigned number to signed.
---
---@param byte_amt integer The number of bytes to use.
---@return dreamwork.std.BigInt signed The 2's complement number.
function BigInt:toSigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        error( "Two's complement overflow.", 2 )
    end

    if self[ 0 ] == 1 and ( self[ size ] or 0 ) > 0x7f then
        bnot( self, size )
        add( self, one )
        self[ 0 ] = -1
    end

    return self
end

--- [SHARED AND MENU]
---
--- Convert 2's complement signed number to unsigned.
---
---@param byte_amt integer The number of bytes to use.
---@return dreamwork.std.BigInt unsigned The 2's complement number.
function BigInt:toUnsigned( byte_amt )
    local byte_count = #self

    local size = math_max( byte_amt or byte_count, 1 )
    if byte_count > size then
        error( "Two's complement overflow.", 2 )
    end

    if self[ 0 ] == -1 then
        self[ 0 ] = 1
        bnot( self, size )
        add( self, one )
    end

    return self
end

do

    --- [SHARED AND MENU]
    ---
    --- Compares big integer objects.
    ---
    ---@param a dreamwork.std.BigInt The big integer object to compare.
    ---@param value any The value to compare to.
    ---@return integer result The result of the comparison.
    local function compare( a, value )
        local b = tobigint( value )
        ---@cast b dreamwork.std.BigInt

        if a[ 0 ] > b[ 0 ] then
            return 1
        elseif a[ 0 ] < b[ 0 ] then
            return -1
        end

        local compare_result = compare_unsigned( a, b )
        if compare_result == 0 then
            return 0
        elseif a[ 0 ] == 1 then
            return compare_result
        elseif a[ 0 ] == -1 then
            return -compare_result
        else
            return 0
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if two big integer objects are equal.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the big integer objects are equal, `false` otherwise.
    function BigInt:eq( other )
        return compare( self, other ) == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if two big integer objects are not equal.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the big integer objects are not equal, `false` otherwise.
    function BigInt:ne( other )
        return compare( self, other ) ~= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is less than another.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the first big integer object is less than the second, `false` otherwise.
    function BigInt:lt( other )
        return compare( self, other ) == -1
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is less than or equal to another.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the first big integer object is less than or equal to the second, `false` otherwise.
    function BigInt:le( other )
        return compare( self, other ) <= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is greater than another.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the first big integer object is greater than the second, `false` otherwise.
    function BigInt:gt( other )
        return compare( self, other ) == 1
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if one big integer object is greater than or equal to another.
    ---
    ---@param other dreamwork.std.BigInt The big integer object to compare.
    ---@return boolean result `true` if the first big integer object is greater than or equal to the second, `false` otherwise.
    function BigInt:ge( other )
        return compare( self, other ) >= 0
    end

    BigInt.__eq = BigInt.eq
    BigInt.__lt = BigInt.lt
    BigInt.__le = BigInt.le

    do

        --- [SHARED AND MENU]
        ---
        --- Returns the greatest common divisor (GCD) of two big integer objects.
        ---
        ---@param a dreamwork.std.BigInt The first big integer object.
        ---@param b dreamwork.std.BigInt The second big integer object.
        ---@return dreamwork.std.BigInt gcd The greatest common divisor.
        local function gcd( a, b )
            a = abs( copy( a ) )
            b = abs( copy( b ) )

            while b[ 0 ] ~= 0 do
                local temp = b
                b = a % b
                a = temp
            end

            return a
        end

        BigInt.gcd = gcd

        --- [SHARED AND MENU]
        ---
        --- Returns the least common multiple (LCM) of two big integer objects.
        ---
        ---@param a dreamwork.std.BigInt The first big integer object.
        ---@param b dreamwork.std.BigInt The second big integer object.
        ---@return dreamwork.std.BigInt lcm The least common multiple.
        function BigInt.lcm( a, b )
            local temp = copy( a )
            mul( temp, b )

            ---@diagnostic disable-next-line: redundant-return-value
            return full_div( temp, gcd( a, b ), true ), nil
        end

        --- [SHARED AND MENU]
        ---
        --- Returns whether two big integer objects are coprime.
        ---
        ---@param a dreamwork.std.BigInt The first big integer object.
        ---@param b dreamwork.std.BigInt The second big integer object.
        ---@return boolean result `true` if the big integer objects are coprime, `false` otherwise.
        local function coprime( a, b )
            return compare( gcd( a, b ), one ) == 0
        end

        BigInt.coprime = coprime

        --- [SHARED AND MENU]
        ---
        --- Returns the modular inverse using the extended Euclidean algorithm.
        ---
        --- Returns x such that (a * x) % m == 1
        ---
        ---@param m dreamwork.std.BigInt The big integer object to use for the modulus.
        ---@return dreamwork.std.BigInt result The result of the operation.
        function BigInt:modinv( m )
            local m0 = m

            local x0 = setmetatable( { [ 0 ] = 0 }, BigInt )
            local x1 = setmetatable( { [ 0 ] = 1, 1 }, BigInt )

            local a = copy( self )

            while compare( a, one ) == 1 do
                local t = m
                local q

                q, m = full_div( a, m, false )
                a = t

                t = x0
                x0 = x1 - mul( q, x0 )
                x1 = t
            end

            if x1[ 0 ] == -1 then
                add( x1, m0 )
            end

            return x1
        end

        local two = setmetatable( { [ 0 ] = 1, 2 }, BigInt )

        --- [SHARED AND MENU]
        ---
        --- Modular exponentiation: (base ^ exponent) % modulus
        ---
        ---@param base dreamwork.std.BigInt The big integer object to use for the base.
        ---@param exponent dreamwork.std.BigInt The big integer object to use for the exponent.
        ---@param modulus dreamwork.std.BigInt The big integer object to use for the modulus.
        ---@return dreamwork.std.BigInt result The result of the operation.
        function BigInt.powmod( base, exponent, modulus )
            local result = setmetatable( { [ 0 ] = 1, 1 }, BigInt )
            local _

            _, base = full_div( base, modulus, false )

            while exponent[ 0 ] ~= 0 do
                local remainder

                exponent, remainder = full_div( exponent, two, false )

                if remainder[ 0 ] == 1 and remainder[ 1 ] == 1 then
                    _, result = full_div( mul( result, base ), modulus, false )
                end

                _, base = full_div( mul( base, base ), modulus, false )
            end

            return result
        end

    end

end

do

    local toString = BigInt.toString
    local tostring = std.tostring

    ---@protected
    function BigInt:__concat( other )
        return toString( self, 10 ) .. tostring( other )
    end

end
