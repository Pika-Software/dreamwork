---@class dreamwork.std
local std = dreamwork.std

local ffi = std.ffi

local raw = std.raw
local raw_pairs = raw.pairs

local math = std.math
local math_clamp, math_floor = math.clamp, math.floor
local math_frexp, math_ldexp = math.frexp, math.ldexp
local math_huge, math_tiny, math_nan = math.huge, math.tiny, math.nan

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift, rbit_arshift = rbit.lshift, rbit.rshift, rbit.arshift

local error = std.error


--- [SHARED AND MENU]
---
--- Library that packs & unpacks types as bytes.
---
---@class dreamwork.std.bytepack
local bytepack = {}
std.bytepack = bytepack

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer from bytes.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param uint8_1 integer The byte.
---@return integer value The unsigned 1-byte integer.
---@nodiscard
function bytepack.readUInt8( uint8_1 )
    return uint8_1
end

--- [SHARED AND MENU]
---
--- Writes unsigned 1-byte (8 bit) integer as bytes.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param value integer The unsigned 1-byte integer.
---@return integer uint8_1 The byte.
---@nodiscard
function bytepack.writeUInt8( value )
    return rbit_band( value, 0xFF )
end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param uint8_1 integer The byte.
---@return integer value The signed 1-byte integer.
---@nodiscard
function bytepack.readInt8( uint8_1 )
    return rbit_arshift( rbit_lshift( uint8_1, 24 ), 24 )
end

--- [SHARED AND MENU]
---
--- Writes signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param value integer The signed 1-byte integer.
---@return integer uint8_1 The byte.
---@nodiscard
function bytepack.writeInt8( value )
    return rbit_band( value, 0xFF )
end

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The signed 2-byte integer.
---@nodiscard
function bytepack.readInt16BE( uint8_1, uint8_2 )
    return rbit_bor(
        rbit_arshift( rbit_lshift( uint8_1, 24 ), 16 ),
        uint8_2
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The unsigned 2-byte integer.
---@nodiscard
function bytepack.readUInt16BE( uint8_1, uint8_2 )
    return rbit_bor( rbit_lshift( uint8_1, 8 ), uint8_2 )
end

-- U/Int16 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 2-byte (16 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param value integer The signed 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@nodiscard
    local function bytepack_writeInt16BE( value )
        return rbit_band( rbit_rshift( value, 8 ), 0xFF ),
            rbit_band( value, 0xFF )
    end

    bytepack.writeInt16BE = bytepack_writeInt16BE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 2-byte (16 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param value integer The unsigned 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@nodiscard
    function bytepack.writeUInt16BE( value )
        return bytepack_writeInt16BE( value )
    end

end

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The signed 2-byte integer.
---@nodiscard
function bytepack.readInt16LE( uint8_1, uint8_2 )
    return rbit_bor(
        rbit_arshift( rbit_lshift( uint8_2, 24 ), 16 ),
        uint8_1
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer from little endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The unsigned 2-byte integer.
---@nodiscard
function bytepack.readUInt16LE( uint8_1, uint8_2 )
    return rbit_bor(
        rbit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

-- U/Int16 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 2-byte (16 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param value integer The signed 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@nodiscard
    local function bytepack_writeInt16LE( value )
        return rbit_band( value, 0xFF ),
            rbit_band( rbit_rshift( value, 8 ), 0xFF )
    end

    bytepack.writeInt16LE = bytepack_writeInt16LE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 2-byte (16 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param value integer The unsigned 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@nodiscard
    function bytepack.writeUInt16LE( value )
        return bytepack_writeInt16LE( value )
    end

end

--- [SHARED AND MENU]
---
--- Reads signed 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@return integer value The signed 3-byte integer.
---@nodiscard
function bytepack.readInt24BE( uint8_1, uint8_2, uint8_3 )
    return rbit_bor(
        rbit_arshift( rbit_lshift( uint8_1, 24 ), 8 ),
        rbit_lshift( uint8_2, 8 ),
        uint8_3
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 3-byte (24 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@return integer value The unsigned 3-byte integer.
---@nodiscard
function bytepack.readUInt24BE( uint8_1, uint8_2, uint8_3 )
    return rbit_bor(
        rbit_lshift( uint8_1, 16 ),
        rbit_lshift( uint8_2, 8 ),
        uint8_3
    )
end

-- U/Int24 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 3-byte (24 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param value integer The signed 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@nodiscard
    local function bytepack_writeInt24BE( value )
        return rbit_band( rbit_rshift( value, 16 ), 0xFF ),
            rbit_band( rbit_rshift( value, 8 ), 0xFF ),
            rbit_band( value, 0xFF )
    end

    bytepack.writeInt24BE = bytepack_writeInt24BE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 3-byte (24 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param value integer The unsigned 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@nodiscard
    function bytepack.writeUInt24BE( value )
        return bytepack_writeInt24BE( value )
    end

end

--- [SHARED AND MENU]
---
--- Reads signed 3-byte (24 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@return integer value The signed 3-byte integer.
---@nodiscard
function bytepack.readInt24LE( uint8_1, uint8_2, uint8_3 )
    return rbit_bor(
        rbit_arshift( rbit_lshift( uint8_3, 24 ), 8 ),
        rbit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 3-byte (24 bit) integer from little endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@return integer value The unsigned 3-byte integer.
---@nodiscard
function bytepack.readUInt24LE( uint8_1, uint8_2, uint8_3 )
    return rbit_bor(
        rbit_lshift( uint8_3, 16 ),
        rbit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

-- U/Int24 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 3-byte (24 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param value integer The signed 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@nodiscard
    local function bytepack_writeInt24LE( value )
        return rbit_band( value, 0xFF ),
            rbit_band( rbit_rshift( value, 8 ), 0xFF ),
            rbit_band( rbit_rshift( value, 16 ), 0xFF )
    end

    bytepack.writeInt24LE = bytepack_writeInt24LE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 3-byte (24 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param value integer The unsigned 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@nodiscard
    function bytepack.writeUInt24LE( value )
        return bytepack_writeInt24LE( value )
    end

end

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@param uint8_4 integer The fourth byte.
---@return integer value The signed 4-byte integer.
---@nodiscard
function bytepack.readInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 )
    return rbit_bor(
        rbit_lshift( uint8_1, 24 ),
        rbit_lshift( uint8_2, 16 ),
        rbit_lshift( uint8_3, 8 ),
        uint8_4
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 4-byte (32 bit) integer from big endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@param uint8_4 integer The fourth byte.
---@return integer value The unsigned 4-byte integer.
---@nodiscard
function bytepack.readUInt32BE( uint8_1, uint8_2, uint8_3, uint8_4 )
    return ((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4
end

-- U/Int32 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 4-byte (32 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param value integer The signed 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    local function bytepack_writeInt32BE( value )
        return rbit_band( rbit_rshift( value, 24 ), 0xFF ),
            rbit_band( rbit_rshift( value, 16 ), 0xFF ),
            rbit_band( rbit_rshift( value, 8 ), 0xFF ),
            rbit_band( value, 0xFF )
    end

    bytepack.writeInt32BE = bytepack_writeInt32BE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 4-byte (32 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param value integer The unsigned 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    function bytepack.writeUInt32BE( value )
        return bytepack_writeInt32BE( value )
    end

end

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) integer from little endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@param uint8_4 integer The fourth byte.
---@return integer value The signed 4-byte integer.
---@nodiscard
function bytepack.readInt32LE( uint8_1, uint8_2, uint8_3, uint8_4 )
    return rbit_bor(
        rbit_lshift( uint8_4, 24 ),
        rbit_lshift( uint8_3, 16 ),
        rbit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 4-byte (32 bit) integer from little endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@param uint8_4 integer The fourth byte.
---@return integer value The unsigned 4-byte integer.
---@nodiscard
function bytepack.readUInt32LE( uint8_1, uint8_2, uint8_3, uint8_4 )
    return ((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

-- U/Int32 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes signed 4-byte (32 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param value integer The signed 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    local function bytepack_writeInt32LE( value )
        return rbit_band( value, 0xFF ),
            rbit_band( rbit_rshift( value, 8 ), 0xFF ),
            rbit_band( rbit_rshift( value, 16 ), 0xFF ),
            rbit_band( rbit_rshift( value, 24 ), 0xFF )
    end

    bytepack.writeInt32LE = bytepack_writeInt32LE

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 4-byte (32 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param value integer The unsigned 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    function bytepack.writeUInt32LE( value )
        return bytepack_writeInt32LE( value )
    end

end

-- U/Int40 Read [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 5-byte (40 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@return integer value The unsigned 5-byte integer.
    ---@nodiscard
    local function bytepack_readUInt40BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
        return (((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100 + uint8_5
    end

    bytepack.readUInt40BE = bytepack_readUInt40BE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 5-byte (40 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@return integer value The signed 5-byte integer.
    ---@nodiscard
    function bytepack.readInt40BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
        -- signed high byte ( sign extended ) * 2^32 + unsigned low half
        return rbit_arshift( rbit_lshift( uint8_1, 24 ), 24 ) * 0x100000000 + (((uint8_2 * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100 + uint8_5)
    end

end

-- U/Int40 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 5-byte (40 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`.
    ---
    ---@param value integer The unsigned 5-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@nodiscard
    local function bytepack_writeUInt40BE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( low, 0xFF )
    end

    bytepack.writeUInt40BE = bytepack_writeUInt40BE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 5-byte (40 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param value integer The signed 5-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@nodiscard
    function bytepack.writeInt40BE( value )
        return bytepack_writeUInt40BE( value )
    end

end

-- U/Int40 Read [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 5-byte (40 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@return integer value The unsigned 5-byte integer.
    ---@nodiscard
    local function bytepack_readUInt40LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
        return (((uint8_5 * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
    end

    bytepack.readUInt40LE = bytepack_readUInt40LE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 5-byte (40 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@return integer value The signed 5-byte integer.
    ---@nodiscard
    function bytepack.readInt40LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
        -- signed high byte ( sign extended ) * 2^32 + unsigned low half
        return rbit_arshift( rbit_lshift( uint8_5, 24 ), 24 ) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

end

-- U/Int40 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 5-byte (40 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`.
    ---
    ---@param value integer The unsigned 5-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@nodiscard
    local function bytepack_writeUInt40LE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( low, 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( high, 0xFF )
    end

    bytepack.writeUInt40LE = bytepack_writeUInt40LE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 5-byte (40 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param value integer The signed 5-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@nodiscard
    function bytepack.writeInt40LE( value )
        return bytepack_writeUInt40LE( value )
    end

end

-- U/Int48 Read [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 6-byte (48 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@return integer value The unsigned 6-byte integer.
    ---@nodiscard
    local function bytepack_readUInt48BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        return ((((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100 + uint8_5) * 0x100 + uint8_6
    end

    bytepack.readUInt48BE = bytepack_readUInt48BE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 6-byte (48 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@return integer value The signed 6-byte integer.
    ---@nodiscard
    function bytepack.readInt48BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        -- signed high half ( sign extended ) * 2^32 + unsigned low half
        return rbit_bor(
            rbit_arshift( rbit_lshift( uint8_1, 24 ), 16 ),
            uint8_2
        ) * 0x100000000 + (((uint8_3 * 0x100 + uint8_4) * 0x100 + uint8_5) * 0x100 + uint8_6)
    end

end

-- U/Int48 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 6-byte (48 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param value integer The unsigned 6-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    local function bytepack_writeUInt48BE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( rbit_rshift( high, 8 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( low, 0xFF )
    end

    bytepack.writeUInt48BE = bytepack_writeUInt48BE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 6-byte (48 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param value integer The signed 6-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    function bytepack.writeInt48BE( value )
        return bytepack_writeUInt48BE( value )
    end

end


-- U/Int48 Read [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 6-byte (48 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@return integer value The unsigned 6-byte integer.
    ---@nodiscard
    local function bytepack_readUInt48LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        return ((((uint8_6 * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
    end

    bytepack.readUInt48LE = bytepack_readUInt48LE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 6-byte (48 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@return integer value The signed 6-byte integer.
    ---@nodiscard
    function bytepack.readInt48LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        -- signed high half ( sign extended ) * 2^32 + unsigned low half
        return rbit_bor(
            rbit_arshift( rbit_lshift( uint8_6, 24 ), 16 ),
            uint8_5
        ) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

end

-- U/Int48 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 6-byte (48 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param value integer The unsigned 6-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    local function bytepack_writeUInt48LE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( low, 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( high, 8 ), 0xFF )
    end

    bytepack.writeUInt48LE = bytepack_writeUInt48LE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 6-byte (48 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param value integer The signed 6-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    function bytepack.writeInt48LE( value )
        return bytepack_writeUInt48LE( value )
    end

end

-- U/Int56 Read [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 7-byte (56 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@return integer value The unsigned 7-byte integer.
    ---@nodiscard
    function bytepack.readUInt56BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
        return ((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100000000 + (((uint8_4 * 0x100 + uint8_5) * 0x100 + uint8_6) * 0x100 + uint8_7)
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 7-byte (56 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@return integer value The signed 7-byte integer.
    ---@nodiscard
    function bytepack.readInt56BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
        -- signed high half ( sign extended ) * 2^32 + unsigned low half
        return rbit_bor(
            rbit_arshift( rbit_lshift( uint8_1, 24 ), 8 ),
            rbit_lshift( uint8_2, 8 ),
            uint8_3
        ) * 0x100000000 + (((uint8_4 * 0x100 + uint8_5) * 0x100 + uint8_6) * 0x100 + uint8_7)
    end

end

-- U/Int56 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 7-byte (56 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 7-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@nodiscard
    function bytepack.writeUInt56BE( value )
        return math_floor( value / 0x1000000000000 ) % 0x100,
            math_floor( value / 0x10000000000 ) % 0x100,
            math_floor( value / 0x100000000 ) % 0x100,
            math_floor( value / 0x1000000 ) % 0x100,
            math_floor( value / 0x10000 ) % 0x100,
            math_floor( value / 0x100 ) % 0x100,
            value % 0x100
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 7-byte (56 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param value integer The signed 7-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@nodiscard
    function bytepack.writeInt56BE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( rbit_rshift( high, 16 ), 0xFF ),
            rbit_band( rbit_rshift( high, 8 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( low, 0xFF )
    end

end

-- U/Int56 Read [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 7-byte (56 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@return integer value The unsigned 7-byte integer.
    ---@nodiscard
    function bytepack.readUInt56LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
        return ((uint8_7 * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 7-byte (56 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@return integer value The signed 7-byte integer.
    ---@nodiscard
    function bytepack.readInt56LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
        -- signed high half ( sign extended ) * 2^32 + unsigned low half
        return rbit_bor(
            rbit_arshift( rbit_lshift( uint8_7, 24 ), 8 ),
            rbit_lshift( uint8_6, 8 ),
            uint8_5
        ) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

end

-- U/Int56 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 7-byte (56 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 7-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@nodiscard
    function bytepack.writeUInt56LE( value )
        return value % 0x100,
            math_floor( value / 0x100 ) % 0x100,
            math_floor( value / 0x10000 ) % 0x100,
            math_floor( value / 0x1000000 ) % 0x100,
            math_floor( value / 0x100000000 ) % 0x100,
            math_floor( value / 0x10000000000 ) % 0x100,
            math_floor( value / 0x1000000000000 ) % 0x100
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 7-byte (56 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param value integer The signed 7-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@nodiscard
    function bytepack.writeInt56LE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( low, 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( high, 8 ), 0xFF ),
            rbit_band( rbit_rshift( high, 16 ), 0xFF )
    end

end

-- U/Int64 Read [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 8-byte (64 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@param uint8_8 integer The eighth byte.
    ---@return integer value The unsigned 8-byte integer.
    ---@nodiscard
    function bytepack.readUInt64BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        return (((uint8_1 * 0x100 + uint8_2) * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100000000 + (((uint8_5 * 0x100 + uint8_6) * 0x100 + uint8_7) * 0x100 + uint8_8)
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 8-byte (64 bit) integer from big endian bytes.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@param uint8_8 integer The eighth byte.
    ---@return integer value The signed 8-byte integer.
    ---@nodiscard
    function bytepack.readInt64BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        -- signed high half * 2^32 + unsigned low half
        return rbit_bor(
            rbit_lshift( uint8_1, 24 ),
            rbit_lshift( uint8_2, 16 ),
            rbit_lshift( uint8_3, 8 ),
            uint8_4
        ) * 0x100000000 + (((uint8_5 * 0x100 + uint8_6) * 0x100 + uint8_7) * 0x100 + uint8_8)
    end

end

-- U/Int64 Write [BE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 8-byte (64 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 8-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeUInt64BE( value )
        return math_floor( value / 0x100000000000000 ) % 0x100,
            math_floor( value / 0x1000000000000 ) % 0x100,
            math_floor( value / 0x10000000000 ) % 0x100,
            math_floor( value / 0x100000000 ) % 0x100,
            math_floor( value / 0x1000000 ) % 0x100,
            math_floor( value / 0x10000 ) % 0x100,
            math_floor( value / 0x100 ) % 0x100,
            value % 0x100
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 8-byte (64 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The signed 8-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeInt64BE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - (high * 0x100000000)

        return rbit_band( rbit_rshift( high, 24 ), 0xFF ),
            rbit_band( rbit_rshift( high, 16 ), 0xFF ),
            rbit_band( rbit_rshift( high, 8 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( low, 0xFF )
    end

end

-- U/Int64 Read [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 8-byte (64 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@param uint8_8 integer The eighth byte.
    ---@return integer value The unsigned 8-byte integer.
    ---@nodiscard
    function bytepack.readUInt64LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        return (((uint8_8 * 0x100 + uint8_7) * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 8-byte (64 bit) integer from little endian bytes.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@param uint8_8 integer The eighth byte.
    ---@return integer value The signed 8-byte integer.
    ---@nodiscard
    function bytepack.readInt64LE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        -- signed high half * 2^32 + unsigned low half
        return rbit_bor(
            rbit_lshift( uint8_8, 24 ),
            rbit_lshift( uint8_7, 16 ),
            rbit_lshift( uint8_6, 8 ),
            uint8_5
        ) * 0x100000000 + (((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1)
    end

end


-- U/Int64 Write [LE]
do

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 8-byte (64 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 8-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeUInt64LE( value )
        return value % 0x100,
            math_floor( value / 0x100 ) % 0x100,
            math_floor( value / 0x10000 ) % 0x100,
            math_floor( value / 0x1000000 ) % 0x100,
            math_floor( value / 0x100000000 ) % 0x100,
            math_floor( value / 0x10000000000 ) % 0x100,
            math_floor( value / 0x1000000000000 ) % 0x100,
            math_floor( value / 0x100000000000000 ) % 0x100
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 8-byte (64 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The signed 8-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeInt64LE( value )
        -- exact split into two's complement halves, `high` is negative for negative values
        local high = math_floor( value / 0x100000000 )
        local low = value - high * 0x100000000

        return rbit_band( low, 0xFF ),
            rbit_band( rbit_rshift( low, 8 ), 0xFF ),
            rbit_band( rbit_rshift( low, 16 ), 0xFF ),
            rbit_band( rbit_rshift( low, 24 ), 0xFF ),
            rbit_band( high, 0xFF ),
            rbit_band( rbit_rshift( high, 8 ), 0xFF ),
            rbit_band( rbit_rshift( high, 16 ), 0xFF ),
            rbit_band( rbit_rshift( high, 24 ), 0xFF )
    end

end

if ffi == nil then

    -- Float Read [BE/LE]
    do

        --- [SHARED AND MENU]
        ---
        --- Reads signed 4-byte (32 bit) float from big endian bytes.
        ---
        ---@param uint8_1 integer The first byte.
        ---@param uint8_2 integer The second byte.
        ---@param uint8_3 integer The third byte.
        ---@param uint8_4 integer The fourth byte.
        ---@return number value The signed 4-byte float.
        ---@nodiscard
        local function bytepack_readFloatBE( uint8_1, uint8_2, uint8_3, uint8_4 )
            local sign = uint8_1 > 0x7F
            local expo = (uint8_1 % 0x80) * 0x2 + math_floor( uint8_2 / 0x80 )
            local mant = ((uint8_2 % 0x80) * 0x100 + uint8_3) * 0x100 + uint8_4

            local value
            if expo == 0 then -- zero or subnormal
                value = math_ldexp( mant, -149 )
            elseif expo == 0xFF then
                if mant ~= 0 then
                    return math_nan
                end

                value = math_huge
            else
                value = math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
            end

            if sign then
                return -value
            end

            return value
        end

        bytepack.readFloatBE = bytepack_readFloatBE

        --- [SHARED AND MENU]
        ---
        --- Reads signed 4-byte (32 bit) float from little endian bytes.
        ---
        ---@param uint8_1 integer The first byte.
        ---@param uint8_2 integer The second byte.
        ---@param uint8_3 integer The third byte.
        ---@param uint8_4 integer The fourth byte.
        ---@return number value The signed 4-byte float.
        ---@nodiscard
        function bytepack.readFloatLE( uint8_1, uint8_2, uint8_3, uint8_4 )
            return bytepack_readFloatBE( uint8_4, uint8_3, uint8_2, uint8_1 )
        end

    end

    -- Float Write [BE/LE]
    do

        --- [SHARED AND MENU]
        ---
        --- Writes signed 4-byte (32 bit) float as big endian bytes.
        ---
        ---@param value number The signed 4-byte float.
        ---@return integer uint8_1 The first byte.
        ---@return integer uint8_2 The second byte.
        ---@return integer uint8_3 The third byte.
        ---@return integer uint8_4 The fourth byte.
        ---@nodiscard
        local function bytepack_writeFloatBE( value )
            if value ~= value then -- NaN
                return 0xFF, 0xC0, 0, 0
            end

            local sign = 0
            if value < 0.0 or (value == 0.0 and (1 / value) < 0.0) then
                value = -value
                sign = 0x80
            end

            if value == math_huge then -- inf
                return sign + 0x7F, 0x80, 0, 0
            elseif value == 0.0 then   -- zero
                return sign, 0, 0, 0
            end

            local mant, expo = math_frexp( value )
            expo = expo + 0x7E

            if expo > 0 then
                mant = (mant * 2.0 - 1.0) * 0x800000
            else -- subnormal
                mant = math_ldexp( mant, expo + 23 )
                expo = 0
            end

            -- round half to even, carry goes into the exponent
            local fraction = math_floor( mant )
            local remainder = mant - fraction

            if remainder > 0.5 or (remainder == 0.5 and fraction % 2 == 1) then
                fraction = fraction + 1
            end

            local bits = expo * 0x800000 + fraction
            if bits >= 0x7F800000 then -- overflow to inf
                return sign + 0x7F, 0x80, 0, 0
            end

            return sign + math_floor( bits / 0x1000000 ),
                math_floor( bits / 0x10000 ) % 0x100,
                math_floor( bits / 0x100 ) % 0x100,
                bits % 0x100
        end

        bytepack.writeFloatBE = bytepack_writeFloatBE

        --- [SHARED AND MENU]
        ---
        --- Writes signed 4-byte (32 bit) float as little endian bytes.
        ---
        ---@param value number The signed 4-byte float.
        ---@return integer uint8_1 The first byte.
        ---@return integer uint8_2 The second byte.
        ---@return integer uint8_3 The third byte.
        ---@return integer uint8_4 The fourth byte.
        ---@nodiscard
        function bytepack.writeFloatLE( value )
            local uint8_1, uint8_2, uint8_3, uint8_4 = bytepack_writeFloatBE( value )
            return uint8_4, uint8_3, uint8_2, uint8_1
        end

    end

    -- Double Read [BE/LE]
    do

        --- [SHARED AND MENU]
        ---
        --- Reads signed 8-byte (64 bit) float (double) from big endian bytes.
        ---
        ---@param uint8_1 integer The first byte.
        ---@param uint8_2 integer The second byte.
        ---@param uint8_3 integer The third byte.
        ---@param uint8_4 integer The fourth byte.
        ---@param uint8_5 integer The fifth byte.
        ---@param uint8_6 integer The sixth byte.
        ---@param uint8_7 integer The seventh byte.
        ---@param uint8_8 integer The eighth byte.
        ---@return number value The signed 8-byte float.
        ---@nodiscard
        local function bytepack_readDoubleBE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            local sign = uint8_1 > 0x7F
            local expo = (uint8_1 % 0x80) * 0x10 + math_floor( uint8_2 / 0x10 )
            local mant = ((((((uint8_2 % 0x10) * 0x100 + uint8_3) * 0x100 + uint8_4) * 0x100 + uint8_5) * 0x100 + uint8_6) * 0x100 + uint8_7) * 0x100 + uint8_8

            local value
            if expo == 0 then -- zero or subnormal
                value = math_ldexp( mant, -1074 )
            elseif expo == 0x7FF then
                if mant ~= 0 then
                    return math_nan
                end

                value = math_huge
            else
                value = math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
            end

            if sign then
                return -value
            end

            return value
        end

        bytepack.readDoubleBE = bytepack_readDoubleBE

        --- [SHARED AND MENU]
        ---
        --- Reads signed 8-byte (64 bit) float (double) from little endian bytes.
        ---
        ---@param uint8_1 integer The first byte.
        ---@param uint8_2 integer The second byte.
        ---@param uint8_3 integer The third byte.
        ---@param uint8_4 integer The fourth byte.
        ---@param uint8_5 integer The fifth byte.
        ---@param uint8_6 integer The sixth byte.
        ---@param uint8_7 integer The seventh byte.
        ---@param uint8_8 integer The eighth byte.
        ---@return number value The signed 8-byte float.
        ---@nodiscard
        function bytepack.readDoubleLE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            return bytepack_readDoubleBE( uint8_8, uint8_7, uint8_6, uint8_5, uint8_4, uint8_3, uint8_2, uint8_1 )
        end

    end

    -- Double Write [BE/LE]
    do

        --- [SHARED AND MENU]
        ---
        --- Writes signed 8-byte (64 bit) float (double) as big endian bytes.
        ---
        ---@param value number The signed 8-byte float.
        ---@return integer uint8_1 The first byte.
        ---@return integer uint8_2 The second byte.
        ---@return integer uint8_3 The third byte.
        ---@return integer uint8_4 The fourth byte.
        ---@return integer uint8_5 The fifth byte.
        ---@return integer uint8_6 The sixth byte.
        ---@return integer uint8_7 The seventh byte.
        ---@return integer uint8_8 The eighth byte.
        ---@nodiscard
        local function bytepack_writeDoubleBE( value )
            if value ~= value then -- NaN
                return 0xFF, 0xF8, 0, 0, 0, 0, 0, 0
            end

            local sign = 0
            if value < 0.0 or (value == 0.0 and (1 / value) < 0.0) then
                value = -value
                sign = 0x80
            end

            if value == math_huge then -- inf
                return sign + 0x7F, 0xF0, 0, 0, 0, 0, 0, 0
            elseif value == 0.0 then   -- zero
                return sign, 0, 0, 0, 0, 0, 0, 0
            end

            local mant, expo = math_frexp( value )
            expo = expo + 0x3FE

            if expo > 0 then
                mant = (mant * 2.0 - 1.0) * 0x10000000000000
            else -- subnormal
                mant = math_ldexp( mant, expo + 52 )
                expo = 0
            end

            return sign + math_floor( expo / 0x10 ),
                (expo % 0x10) * 0x10 + math_floor( mant / 0x1000000000000 ),
                math_floor( mant / 0x10000000000 ) % 0x100,
                math_floor( mant / 0x100000000 ) % 0x100,
                math_floor( mant / 0x1000000 ) % 0x100,
                math_floor( mant / 0x10000 ) % 0x100,
                math_floor( mant / 0x100 ) % 0x100,
                mant % 0x100
        end

        bytepack.writeDoubleBE = bytepack_writeDoubleBE

        --- [SHARED AND MENU]
        ---
        --- Writes signed 8-byte (64 bit) float (double) as little endian bytes.
        ---
        ---@param value number The signed 8-byte float.
        ---@return integer uint8_1 The first byte.
        ---@return integer uint8_2 The second byte.
        ---@return integer uint8_3 The third byte.
        ---@return integer uint8_4 The fourth byte.
        ---@return integer uint8_5 The fifth byte.
        ---@return integer uint8_6 The sixth byte.
        ---@return integer uint8_7 The seventh byte.
        ---@return integer uint8_8 The eighth byte.
        ---@nodiscard
        function bytepack.writeDoubleLE( value )
            local uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 = bytepack_writeDoubleBE( value )
            return uint8_8, uint8_7, uint8_6, uint8_5, uint8_4, uint8_3, uint8_2, uint8_1
        end

    end

else

    ---@class dreamwork.std.bytepack.FFIUnion : ffi.cdata*
    ---@field bytes integer[]
    ---@field u32 integer
    ---@field f32 number
    ---@field f64 number

    ---@type dreamwork.std.bytepack.FFIUnion
    ---@diagnostic disable-next-line: assign-type-mismatch
    local union = ffi.new( "union { uint8_t bytes[ 8 ]; uint32_t u32; float f32; double f64; }" )

    local is_little_endian = ffi.abi( "le" )

    -- Float Read/Write [BE/LE]
    do

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@return number
        ---@nodiscard
        local function bytepack_readFloatBE( uint8_1, uint8_2, uint8_3, uint8_4 )
            -- never load inf/NaN bit patterns from cdata, NaN payloads are not canonicalized
            if uint8_1 % 0x80 == 0x7F and uint8_2 >= 0x80 then
                if uint8_2 ~= 0x80 or uint8_3 ~= 0 or uint8_4 ~= 0 then
                    return math_nan
                elseif uint8_1 > 0x7F then
                    return math_tiny
                end

                return math_huge
            end

            -- `u32` is a native integer, so this is endianness independent
            union.u32 = rbit_bor( rbit_lshift( uint8_1, 24 ), rbit_lshift( uint8_2, 16 ), rbit_lshift( uint8_3, 8 ), uint8_4 )
            return union.f32
        end

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@return number
        ---@nodiscard
        local function bytepack_readFloatLE( uint8_1, uint8_2, uint8_3, uint8_4 )
            return bytepack_readFloatBE( uint8_4, uint8_3, uint8_2, uint8_1 )
        end

        ---@param value number
        ---@return integer, integer, integer, integer
        local function writeFloat_native( value )
            union.f32 = value

            local bytes = union.bytes
            return bytes[ 0 ], bytes[ 1 ], bytes[ 2 ], bytes[ 3 ]
        end

        ---@param value number
        ---@return integer, integer, integer, integer
        local function writeFloat_swapped( value )
            union.f32 = value

            local bytes = union.bytes
            return bytes[ 3 ], bytes[ 2 ], bytes[ 1 ], bytes[ 0 ]
        end

        local bytepack_writeFloatLE, bytepack_writeFloatBE

        if is_little_endian then
            bytepack_writeFloatLE, bytepack_writeFloatBE = writeFloat_native, writeFloat_swapped
        else
            bytepack_writeFloatLE, bytepack_writeFloatBE = writeFloat_swapped, writeFloat_native
        end

        bytepack.readFloatBE = bytepack_readFloatBE
        bytepack.readFloatLE = bytepack_readFloatLE

        bytepack.writeFloatBE = bytepack_writeFloatBE
        bytepack.writeFloatLE = bytepack_writeFloatLE

    end

    -- Double Read/Write [BE/LE]
    do

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@param uint8_5 integer
        ---@param uint8_6 integer
        ---@param uint8_7 integer
        ---@param uint8_8 integer
        ---@return number
        local function readDouble_native( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            local bytes = union.bytes
            bytes[ 0 ], bytes[ 1 ], bytes[ 2 ], bytes[ 3 ], bytes[ 4 ], bytes[ 5 ], bytes[ 6 ], bytes[ 7 ] = uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8
            return union.f64
        end

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@param uint8_5 integer
        ---@param uint8_6 integer
        ---@param uint8_7 integer
        ---@param uint8_8 integer
        ---@return number
        local function readDouble_swapped( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            local bytes = union.bytes
            bytes[ 0 ], bytes[ 1 ], bytes[ 2 ], bytes[ 3 ], bytes[ 4 ], bytes[ 5 ], bytes[ 6 ], bytes[ 7 ] = uint8_8, uint8_7, uint8_6, uint8_5, uint8_4, uint8_3, uint8_2, uint8_1
            return union.f64
        end

        local readDoubleBE_unchecked = is_little_endian and readDouble_swapped or readDouble_native
        local readDoubleLE_unchecked = is_little_endian and readDouble_native or readDouble_swapped

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@param uint8_5 integer
        ---@param uint8_6 integer
        ---@param uint8_7 integer
        ---@param uint8_8 integer
        ---@return number
        ---@nodiscard
        local function bytepack_readDoubleBE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            -- never load inf/NaN bit patterns from cdata, NaN payloads are not canonicalized
            if uint8_1 % 0x80 == 0x7F and uint8_2 >= 0xF0 then
                if uint8_2 ~= 0xF0 or uint8_3 ~= 0 or uint8_4 ~= 0 or uint8_5 ~= 0 or uint8_6 ~= 0 or uint8_7 ~= 0 or uint8_8 ~= 0 then
                    return math_nan
                elseif uint8_1 > 0x7F then
                    return math_tiny
                end

                return math_huge
            end

            return readDoubleBE_unchecked( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        end

        ---@param uint8_1 integer
        ---@param uint8_2 integer
        ---@param uint8_3 integer
        ---@param uint8_4 integer
        ---@param uint8_5 integer
        ---@param uint8_6 integer
        ---@param uint8_7 integer
        ---@param uint8_8 integer
        ---@return number
        ---@nodiscard
        local function bytepack_readDoubleLE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
            -- never load inf/NaN bit patterns from cdata, NaN payloads are not canonicalized
            if uint8_8 % 0x80 == 0x7F and uint8_7 >= 0xF0 then
                if uint8_7 ~= 0xF0 or uint8_6 ~= 0 or uint8_5 ~= 0 or uint8_4 ~= 0 or uint8_3 ~= 0 or uint8_2 ~= 0 or uint8_1 ~= 0 then
                    return math_nan
                elseif uint8_8 > 0x7F then
                    return math_tiny
                end

                return math_huge
            end

            return readDoubleLE_unchecked( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        end

        ---@param value number
        ---@return integer, integer, integer, integer, integer, integer, integer, integer
        local function writeDouble_native( value )
            union.f64 = value

            local bytes = union.bytes
            return bytes[ 0 ], bytes[ 1 ], bytes[ 2 ], bytes[ 3 ], bytes[ 4 ], bytes[ 5 ], bytes[ 6 ], bytes[ 7 ]
        end

        ---@param value number
        ---@return integer, integer, integer, integer, integer, integer, integer, integer
        local function writeDouble_swapped( value )
            union.f64 = value

            local bytes = union.bytes
            return bytes[ 7 ], bytes[ 6 ], bytes[ 5 ], bytes[ 4 ], bytes[ 3 ], bytes[ 2 ], bytes[ 1 ], bytes[ 0 ]
        end

        bytepack.readDoubleLE = bytepack_readDoubleLE
        bytepack.readDoubleBE = bytepack_readDoubleBE

        bytepack.writeDoubleLE = is_little_endian and writeDouble_native or writeDouble_swapped
        bytepack.writeDoubleBE = is_little_endian and writeDouble_swapped or writeDouble_native

    end

end

--- [SHARED AND MENU]
---
--- Reads `hours`, `minutes` and `seconds` from single `Short` number ( UInt16 ).
---
---@param uint16 integer The uint16 to read from.
---@return integer hours The number of hours.
---@return integer minutes The number of minutes.
---@return integer seconds The number of seconds, **will be rounded**.
---@nodiscard
function bytepack.readTime( uint16 )
    return rbit_rshift( rbit_band( uint16, 0xF800 ), 11 ),
        rbit_rshift( rbit_band( uint16, 0x7E0 ), 5 ),
        rbit_band( uint16, 0x1F ) * 2
end

--- [SHARED AND MENU]
---
--- Writes time in DOS format as single `Short` number ( UInt16 ).
---
--- Values are clamped to the valid DOS ranges: hours `0` - `23`, minutes `0` - `59`, seconds `0` - `59`.
---
---@param hours? integer The number of hours.
---@param minutes? integer The number of minutes.
---@param seconds? integer The number of seconds, **will be rounded**.
---@return integer uint16 The uint16 to read from.
---@nodiscard
function bytepack.writeTime( hours, minutes, seconds )
    if hours == nil then
        hours = 0
    else
        hours = math_clamp( hours, 0, 23 )
    end

    if minutes == nil then
        minutes = 0
    else
        minutes = math_clamp( minutes, 0, 59 )
    end

    if seconds == nil then
        seconds = 0
    else
        seconds = math_floor( math_clamp( seconds, 0, 59 ) * 0.5 )
    end

    return rbit_bor(
        rbit_lshift( hours, 11 ),
        rbit_lshift( minutes, 5 ),
        seconds
    )
end

--- [SHARED AND MENU]
---
--- Reads date in DOS format from single `Short` number ( UInt16 ).
---
---@param uint16 integer The uint16 to read from.
---@return integer day The day.
---@return integer month The month.
---@return integer year The year.
---@nodiscard
function bytepack.readDate( uint16 )
    return rbit_band( uint16, 0x1F ),
        rbit_rshift( rbit_band( uint16, 0x1E0 ), 5 ),
        rbit_rshift( rbit_band( uint16, 0xFE00 ), 9 ) + 1980
end

--- [SHARED AND MENU]
---
--- Writes date in DOS format as single `Short` number ( UInt16 ).
---
---@param day? integer The day.
---@param month? integer The month.
---@param year? integer The year.
---@return integer uint16 The uint16 to read from.
---@nodiscard
function bytepack.writeDate( day, month, year )
    if day == nil then
        day = 1
    else
        day = math_clamp( day, 1, 31 )
    end

    if month == nil then
        month = 1
    else
        month = math_clamp( month, 1, 12 )
    end

    if year == nil then
        year = 0
    else
        year = math_clamp( year, 1980, 2107 ) - 1980
    end

    return rbit_bor( day,
        rbit_lshift( month, 5 ),
        rbit_lshift( year, 9 )
    )
end

--- [SHARED AND MENU]
---
--- Reads fixed-point number (**UQm.n**) from specified integer with `n` bits.
---
--- ### Commonly Used UQm.n Formats (**unsigned**)
--- | Format  | Range                          | Precision (Step)        |
--- |:--------|:-------------------------------|:------------------------|
--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
---
--- ### Commonly Used Qm.n Formats (**signed**)
--- | Format | Range                          | Precision (Step)        |
--- |:-------|:-------------------------------|:------------------------|
--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
---
---@param n integer Number of fractional bits.
---@param integer integer The integer number to read from.
---@return number value The unsigned fixed-point number.
---@nodiscard
function bytepack.readFixedPoint( n, integer )
    return math_ldexp( integer, -n )
end

--- [SHARED AND MENU]
---
--- Writes fixed-point number (**UQm.n** or **Qm.n**) as integer with `n` fractional bits.
---
--- The value is rounded to the nearest representable step.
---
--- ### Commonly Used UQm.n Formats
--- | Format  | Range                          | Precision (Step)        |
--- |:--------|:-------------------------------|:------------------------|
--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
---
--- ### Commonly Used Qm.n Formats (**signed**)
--- | Format | Range                          | Precision (Step)        |
--- |:-------|:-------------------------------|:------------------------|
--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
---
---@param value number The fixed-point number.
---@param m integer Number of integer bits (including sign bit).
---@param n integer Number of fractional bits.
---@return integer integer The integer number to read from.
---@nodiscard
function bytepack.writeFixedPoint( value, m, n )
    local byte_count = (m + n) * 0.125
    if byte_count % 1 ~= 0 then
        error( "invalid count of integer/fractional bits", 2 )
    end

    return math_floor( math_ldexp( value, n ) + 0.5 )
end

-- HEX Read [BE/LE]
do

    ---@type table<integer, integer>
    local decode_map = {
        -- digits
        [ 0x30 ] = 0x0, --[[ 0 ]]
        [ 0x31 ] = 0x1, --[[ 1 ]]
        [ 0x32 ] = 0x2, --[[ 2 ]]
        [ 0x33 ] = 0x3, --[[ 3 ]]
        [ 0x34 ] = 0x4, --[[ 4 ]]
        [ 0x35 ] = 0x5, --[[ 5 ]]
        [ 0x36 ] = 0x6, --[[ 6 ]]
        [ 0x37 ] = 0x7, --[[ 7 ]]
        [ 0x38 ] = 0x8, --[[ 8 ]]
        [ 0x39 ] = 0x9, --[[ 9 ]]

        -- upper-case letters
        [ 0x41 ] = 0xA, --[[ A ]]
        [ 0x42 ] = 0xB, --[[ B ]]
        [ 0x43 ] = 0xC, --[[ C ]]
        [ 0x44 ] = 0xD, --[[ D ]]
        [ 0x45 ] = 0xE, --[[ E ]]
        [ 0x46 ] = 0xF, --[[ F ]]

        -- lower-case letters
        [ 0x61 ] = 0xA, --[[ a ]]
        [ 0x62 ] = 0xB, --[[ b ]]
        [ 0x63 ] = 0xC, --[[ c ]]
        [ 0x64 ] = 0xD, --[[ d ]]
        [ 0x65 ] = 0xE, --[[ e ]]
        [ 0x66 ] = 0xF, --[[ f ]]
    }

    --- Maps two hex characters ( `uint8_1 << 8 | uint8_2` ) to the decoded byte.
    ---
    ---@type table<integer, integer>
    local uint8_cache = {}

    for i in raw_pairs( decode_map ) do
        for j in raw_pairs( decode_map ) do
            uint8_cache[ rbit_lshift( i, 8 ) + j ] = rbit_lshift( decode_map[ i ], 4 ) + decode_map[ j ]
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 1-byte (8 bit) integer from big endian hex bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@return integer | nil value The unsigned 1-byte integer or `nil` if bytes do not match the allowed ones.
    ---@nodiscard
    function bytepack.readHex8( uint8_1, uint8_2 )
        return uint8_cache[ rbit_lshift( uint8_1, 8 ) + uint8_2 ]
    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 2-byte (16 bit) integer from big endian hex bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@return integer | nil value The unsigned 2-byte integer or `nil` if bytes do not match the allowed ones.
    ---@nodiscard
    function bytepack.readHex16BE( uint8_1, uint8_2, uint8_3, uint8_4 )
        local byte_1 = uint8_cache[ rbit_lshift( uint8_1, 8 ) + uint8_2 ]
        local byte_2 = uint8_cache[ rbit_lshift( uint8_3, 8 ) + uint8_4 ]

        if byte_1 == nil or byte_2 == nil then
            return nil
        end

        return rbit_bor( rbit_lshift( byte_1, 8 ), byte_2 )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 3-byte (24 bit) integer from big endian hex bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@return integer | nil value The unsigned 3-byte integer or `nil` if bytes do not match the allowed ones.
    ---@nodiscard
    function bytepack.readHex24BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        local byte_1 = uint8_cache[ rbit_lshift( uint8_1, 8 ) + uint8_2 ]
        local byte_2 = uint8_cache[ rbit_lshift( uint8_3, 8 ) + uint8_4 ]
        local byte_3 = uint8_cache[ rbit_lshift( uint8_5, 8 ) + uint8_6 ]

        if byte_1 == nil or byte_2 == nil or byte_3 == nil then
            return nil
        end

        return rbit_bor( rbit_lshift( byte_1, 16 ), rbit_lshift( byte_2, 8 ), byte_3 )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 4-byte (32 bit) integer from big endian hex bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@param uint8_5 integer The fifth byte.
    ---@param uint8_6 integer The sixth byte.
    ---@param uint8_7 integer The seventh byte.
    ---@param uint8_8 integer The eighth byte.
    ---@return integer | nil value The unsigned 4-byte integer or `nil` if bytes do not match the allowed ones.
    ---@nodiscard
    function bytepack.readHex32BE( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        local byte_1 = uint8_cache[ rbit_lshift( uint8_1, 8 ) + uint8_2 ]
        local byte_2 = uint8_cache[ rbit_lshift( uint8_3, 8 ) + uint8_4 ]
        local byte_3 = uint8_cache[ rbit_lshift( uint8_5, 8 ) + uint8_6 ]
        local byte_4 = uint8_cache[ rbit_lshift( uint8_7, 8 ) + uint8_8 ]

        if byte_1 == nil or byte_2 == nil or byte_3 == nil or byte_4 == nil then
            return nil
        end

        -- the top byte is the only one that can set bit 31, so it is added arithmetically
        return byte_1 * 0x1000000 + rbit_bor( rbit_lshift( byte_2, 16 ), rbit_lshift( byte_3, 8 ), byte_4 )
    end

end

-- HEX Write [BE/LE]
do

    ---@type table<integer, integer>
    local encode_map = {
        -- digits
        [ 0x0 ] = 0x30, --[[ 0 ]]
        [ 0x1 ] = 0x31, --[[ 1 ]]
        [ 0x2 ] = 0x32, --[[ 2 ]]
        [ 0x3 ] = 0x33, --[[ 3 ]]
        [ 0x4 ] = 0x34, --[[ 4 ]]
        [ 0x5 ] = 0x35, --[[ 5 ]]
        [ 0x6 ] = 0x36, --[[ 6 ]]
        [ 0x7 ] = 0x37, --[[ 7 ]]
        [ 0x8 ] = 0x38, --[[ 8 ]]
        [ 0x9 ] = 0x39, --[[ 9 ]]

        -- upper-case letters
        [ 0xA ] = 0x41, --[[ A ]]
        [ 0xB ] = 0x42, --[[ B ]]
        [ 0xC ] = 0x43, --[[ C ]]
        [ 0xD ] = 0x44, --[[ D ]]
        [ 0xE ] = 0x45, --[[ E ]]
        [ 0xF ] = 0x46, --[[ F ]]
    }

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 1-byte (8 bit) integer to big endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `255`
    ---
    ---@param uint8 integer The unsigned 1-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@nodiscard
    function bytepack.writeHex8( uint8 )
        return encode_map[ rbit_band( rbit_rshift( uint8, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint8, 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 2-byte (16 bit) integer to big endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param uint16 integer The unsigned 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    function bytepack.writeHex16BE( uint16 )
        return encode_map[ rbit_band( rbit_rshift( uint16, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint16, 8 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint16, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint16, 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 2-byte (16 bit) integer to little endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param uint16 integer The unsigned 2-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@nodiscard
    function bytepack.writeHex16LE( uint16 )
        return encode_map[ rbit_band( rbit_rshift( uint16, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint16, 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint16, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint16, 8 ), 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 3-byte (24 bit) integer to big endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param uint24 integer The unsigned 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    function bytepack.writeHex24BE( uint24 )
        return encode_map[ rbit_band( rbit_rshift( uint24, 20 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 16 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 8 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint24, 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 3-byte (24 bit) integer to little endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param uint24 integer The unsigned 3-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@nodiscard
    function bytepack.writeHex24LE( uint24 )
        return encode_map[ rbit_band( rbit_rshift( uint24, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint24, 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 8 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 20 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint24, 16 ), 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 4-byte (32 bit) integer to big endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param uint32 integer The unsigned 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeHex32BE( uint32 )
        return encode_map[ rbit_band( rbit_rshift( uint32, 28 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 24 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 20 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 16 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 8 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint32, 0x0F ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Encodes unsigned 4-byte (32 bit) integer to little endian hex bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param uint32 integer The unsigned 4-byte integer.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    ---@return integer uint8_3 The third byte.
    ---@return integer uint8_4 The fourth byte.
    ---@return integer uint8_5 The fifth byte.
    ---@return integer uint8_6 The sixth byte.
    ---@return integer uint8_7 The seventh byte.
    ---@return integer uint8_8 The eighth byte.
    ---@nodiscard
    function bytepack.writeHex32LE( uint32 )
        return encode_map[ rbit_band( rbit_rshift( uint32, 4 ), 0x0F ) ],
            encode_map[ rbit_band( uint32, 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 12 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 8 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 20 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 16 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 28 ), 0x0F ) ],
            encode_map[ rbit_band( rbit_rshift( uint32, 24 ), 0x0F ) ]
    end

end
