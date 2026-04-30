---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_format = string.format
local math_random = std.math.random

local bit_band, bit_bor = std.bit.band, std.bit.bor

--- [SHARED AND MENU]
---
--- The UUID generation library.
---
---@class dreamwork.std.uuid
local uuid = std.uuid or {}
std.uuid = uuid

do

    local string_len = string.len
    local string_byte = string.byte
    local string_gsub = string.gsub

    local base16_decode = std.encoding.base16.decode

    do

        local MD5_digest = std.hash.MD5.digest

        --- [SHARED AND MENU]
        ---
        --- Generates a UUID version 3 (name-based, MD5).
        ---
        --- UUID v3 is generated based on a namespace and a name using MD5 hashing.
        ---
        ---@param namespace string The namespace UUID (must be a valid UUID string).
        ---@param name string The name to hash within the namespace.
        ---@return string uuid_str A UUID v3 string.
        function uuid.v3( namespace, name )
            local uuid_str = string_gsub( namespace, "-", "" )

            local uuid_str_length = string_len( uuid_str )
            if uuid_str_length ~= 32 then
                error( "invalid namespace UUID format", 2 )
            end

            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16 = string_byte( MD5_digest( base16_decode( uuid_str, 1, uuid_str_length ) .. name, false ), 1, 16 )

            return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, bit_bor( bit_band( uint8_7, 0x0F ), 0x30 ),
                uint8_8, bit_bor( bit_band( uint8_9, 0x3F ), 0x80 ),
                uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16
            )
        end

    end

    do

        local SHA1_digest = std.hash.SHA1.digest

        --- [SHARED AND MENU]
        ---
        --- Generates a UUID version 5 (name-based, SHA-1).
        ---
        --- UUID v5 is similar to v3, but uses SHA-1 instead of MD5 for hashing.
        ---
        ---@param namespace string The namespace UUID (must be a valid UUID string).
        ---@param name string The name to hash within the namespace.
        ---@return string uuid_str A UUID v5 string.
        function uuid.v5( namespace, name )
            local uuid_str = string_gsub( namespace, "-", "" )

            local uuid_str_length = string_len( uuid_str )
            if uuid_str_length ~= 32 then
                error( "invalid namespace UUID format", 2 )
            end

            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16 = string_byte( SHA1_digest( base16_decode( uuid_str, 1, uuid_str_length ) .. name, false ), 1, 16 )

            return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, bit_bor( bit_band( uint8_7, 0x0F ), 0x50 ),
                uint8_8, bit_bor( bit_band( uint8_9, 0x3F ), 0x80 ),
                uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16
            )
        end

    end

end

--- [SHARED AND MENU]
---
--- Generates a UUID version 4 (random).
---
--- UUID v4 is generated using random or pseudo-random numbers.
--- No input is needed; output is a fully random UUID.
---
---@return string uuid_str A UUID v4 string.
function uuid.v4()
    return string_format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),

        math_random( 0, 255 ),
        math_random( 0, 255 ),
        bit_bor( bit_band( math_random( 0, 255 ), 0x0F ), 0x40 ),
        math_random( 0, 255 ),

        bit_bor( bit_band( math_random( 0, 255 ), 0x3F ), 0x80 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),

        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 ),
        math_random( 0, 255 )
    )
end

do

    local time_now = std.time.now

    local BigInt = std.BigInt
    local BigInt_fromNumber = BigInt.fromNumber
    local BigInt_band, BigInt_rshift = BigInt.band, BigInt.rshift

    local bint = BigInt.__base
    local bint_band = bint.band
    local bint_toHex = bint.toHex

    local bigint_0xFF = BigInt_fromNumber( 0xFF )

    --- [SHARED AND MENU]
    ---
    --- Generates a UUID version 7 (time-ordered).
    ---
    --- UUID v7 is a 128-bit based on a timestamp unique identifier,
    --- like it's older siblings, such as the widely used UUIDv4.
    ---
    --- But unlike v4, UUIDv7 is time-sortable
    --- with 1 ms precision.
    ---
    --- By combining the timestamp and
    --- the random parts, UUIDv7 becomes an
    --- excellent choice for record identifiers
    --- in databases, including distributed ones.
    ---
    ---@param timestamp? dreamwork.std.BigInt The UNIX-64 timestamp to use.
    ---@return string uuid_str A UUID v7 string.
    function uuid.v7( timestamp )
        if timestamp == nil then
            timestamp = BigInt_fromNumber( time_now( "ms", false ) )
        end

        return string_format( "0%s%s%s%s-%s%s-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
            bint_toHex( bint_band( BigInt_rshift( timestamp, 40 ), bigint_0xFF ), true ),
            bint_toHex( bint_band( BigInt_rshift( timestamp, 32 ), bigint_0xFF ), true ),
            bint_toHex( bint_band( BigInt_rshift( timestamp, 24 ), bigint_0xFF ), true ),
            bint_toHex( bint_band( BigInt_rshift( timestamp, 16 ), bigint_0xFF ), true ),

            bint_toHex( bint_band( BigInt_rshift( timestamp, 8 ), bigint_0xFF ), true ),
            bint_toHex( BigInt_band( timestamp, bigint_0xFF ), true ),
            bit_bor( bit_band( math_random( 0, 255 ), 0x0F ), 0x70 ),
            math_random( 0, 255 ),

            bit_bor( bit_band( math_random( 0, 255 ), 0x3F ), 0x80 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),

            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 ),
            math_random( 0, 255 )
        )
    end

end

--- [SHARED AND MENU]
---
--- Returns a UUID v8 string from the given bytes.
---
--- UUIDv8 is a flexible version allowing custom data alongside version and variant bits.
---
---@param uint8_1? integer Unsigned byte (0..255)
---@param uint8_2? integer Unsigned byte (0..255)
---@param uint8_3? integer Unsigned byte (0..255)
---@param uint8_4? integer Unsigned byte (0..255)
---@param uint8_5? integer Unsigned byte (0..255)
---@param uint8_6? integer Unsigned byte (0..255)
---@param uint8_7? integer Unsigned byte (0..15)
---@param uint8_8? integer Unsigned byte (0..255)
---@param uint8_9? integer Unsigned byte (0..63)
---@param uint8_10? integer Unsigned byte (0..255)
---@param uint8_11? integer Unsigned byte (0..255)
---@param uint8_12? integer Unsigned byte (0..255)
---@param uint8_13? integer Unsigned byte (0..255)
---@param uint8_14? integer Unsigned byte (0..255)
---@param uint8_15? integer Unsigned byte (0..255)
---@param uint8_16? integer Unsigned byte (0..255)
---@return string uuid_str A UUID v8 string.
function uuid.v8( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8, uint8_9, uint8_10, uint8_11, uint8_12, uint8_13, uint8_14, uint8_15, uint8_16 )
    return string_format(
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        uint8_1 or 0, uint8_2 or 0, uint8_3 or 0, uint8_4 or 0, uint8_5 or 0, uint8_6 or 0,
        bit_bor( bit_band( uint8_7 or 0, 0x0F ), 0x80 ), uint8_8 or 0,
        bit_bor( bit_band( uint8_9 or 0, 0x3F ), 0x80 ), uint8_10 or 0,
        uint8_11 or 0, uint8_12 or 0, uint8_13 or 0, uint8_14 or 0, uint8_15 or 0, uint8_16 or 0
    )
end
