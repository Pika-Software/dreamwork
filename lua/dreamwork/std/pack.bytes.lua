local std = dreamwork.std
local math = std.math
local bit = std.bit

local math_ispositive = math.ispositive
local math_floor = math.floor

local bit_lshift, bit_rshift = bit.lshift, bit.rshift
local bit_band, bit_bor = bit.band, bit.bor

---@class dreamwork.std.pack
local pack = std.pack

-- TODO: ffi support?

--- [SHARED AND MENU]
---
--- Library that packs/unpacks types as bytes.
---
---@class dreamwork.std.pack.bytes
local bytepack = {}
pack.bytes = bytepack

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer from little endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The unsigned 2-byte integer.
local function readUInt16( uint8_1, uint8_2 )
    return bit_bor(
        bit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

bytepack.readUInt16 = readUInt16

--- [SHARED AND MENU]
---
--- Writes unsigned 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param value integer The unsigned 2-byte integer.
---@return integer uint8_1 The first byte.
---@return integer uint8_2 The second byte.
local function writeUInt16( value )
    return bit_band( value, 0xFF ),
        bit_band( bit_rshift( value, 8 ), 0xFF )
end

bytepack.writeUInt16 = writeUInt16

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
local function readUInt24( uint8_1, uint8_2, uint8_3 )
    return bit_bor(
        bit_lshift( uint8_3, 16 ),
        bit_lshift( uint8_2, 8 ),
        uint8_1
    )
end

bytepack.readUInt24 = readUInt24

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
local function writeUInt24( value )
    return bit_band( value, 0xFF ),
        bit_band( bit_rshift( value, 8 ), 0xFF ),
        bit_band( bit_rshift( value, 16 ), 0xFF )
end

bytepack.writeUInt24 = writeUInt24

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
local function readUInt32( uint8_1, uint8_2, uint8_3, uint8_4 )
    return ((uint8_4 * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

bytepack.readUInt32 = readUInt32

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
local function writeUInt32( value )
    return bit_band( value, 0xFF ),
        bit_band( bit_rshift( value, 8 ), 0xFF ),
        bit_band( bit_rshift( value, 16 ), 0xFF ),
        bit_band( bit_rshift( value, 24 ), 0xFF )
end

bytepack.writeUInt32 = writeUInt32

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
local function readUInt40( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
    return (((uint8_5 * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

bytepack.readUInt40 = readUInt40

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
local function writeUInt40( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100
end

bytepack.writeUInt40 = writeUInt40

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
local function readUInt48( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
    return ((((uint8_6 * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

bytepack.readUInt48 = readUInt48

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
local function writeUInt48( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100,
        math_floor( value / 0x10000000000 ) % 0x100
end

bytepack.writeUInt48 = writeUInt48

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
local function readUInt56( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
    return (((((uint8_7 * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

bytepack.readUInt56 = readUInt56

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
local function writeUInt56( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100,
        math_floor( value / 0x10000000000 ) % 0x100,
        math_floor( value / 0x1000000000000 ) % 0x100
end

bytepack.writeUInt56 = writeUInt56

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
local function readUInt64( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    return ((((((uint8_8 * 0x100 + uint8_7) * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
end

bytepack.readUInt64 = readUInt64

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
local function writeUInt64( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100,
        math_floor( value / 0x10000000000 ) % 0x100,
        math_floor( value / 0x1000000000000 ) % 0x100,
        0
end

bytepack.writeUInt64 = writeUInt64

do

    local math_clamp = math.clamp

    --- [SHARED AND MENU]
    ---
    --- Reads time in DOS format from little endian bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@return integer hours The number of hours.
    ---@return integer minutes The number of minutes.
    ---@return integer seconds The number of seconds, **will be rounded**.
    function bytepack.readTime( uint8_1, uint8_2 )
        local short = readUInt16( uint8_1, uint8_2 )

        return bit_rshift( bit_band( short, 0xF800 ), 11 ),
            bit_rshift( bit_band( short, 0x7E0 ), 5 ),
            bit_band( short, 0x1F ) * 2
    end

    --- [SHARED AND MENU]
    ---
    --- Writes time in DOS format as little endian bytes.
    ---
    ---@param hours? integer The number of hours.
    ---@param minutes? integer The number of minutes.
    ---@param seconds? integer The number of seconds, **will be rounded**.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    function bytepack.writeTime( hours, minutes, seconds )
        return writeUInt16( bit_bor(
        ---@cast hours integer
            bit_lshift( hours == nil and 0 or math_clamp( hours, 0, 24 ), 11 ),

            ---@cast minutes integer
            bit_lshift( minutes == nil and 0 or math_clamp( minutes, 0, 60 ), 5 ),

            ---@cast seconds integer
            seconds == nil and 0 or math_floor( math_clamp( seconds, 0, 60 ) * 0.5 )
        ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads date in DOS format from little endian bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@return integer day The day.
    ---@return integer month The month.
    ---@return integer year The year.
    function bytepack.readDate( uint8_1, uint8_2 )
        local short = readUInt16( uint8_1, uint8_2 )

        return bit_band( short, 0x1F ),
            bit_rshift( bit_band( short, 0x1E0 ), 5 ),
            bit_rshift( bit_band( short, 0xFE00 ), 9 ) + 1980
    end

    --- [SHARED AND MENU]
    ---
    --- Writes date in DOS format as little endian bytes.
    ---
    ---@param day? integer The day.
    ---@param month? integer The month.
    ---@param year? integer The year.
    ---@return integer uint8_1 The first byte.
    ---@return integer uint8_2 The second byte.
    function bytepack.writeDate( day, month, year )
        return writeUInt16( bit_bor(
        ---@cast day integer
            day == nil and 1 or math_clamp( day, 1, 31 ),

            ---@cast month integer
            bit_lshift( month == nil and 1 or math_clamp( month, 1, 12 ), 5 ),

            ---@cast year integer
            bit_lshift( year == nil and 0 or (math_clamp( year, 1980, 2107 ) - 1980), 9 )
        ) )
    end

end

--- [SHARED AND MENU]
---
--- Reads unsigned fixed-point number (**UQm.n**) as little endian bytes.
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
---@param n integer Number of fractional bits.
---@param uint8_1 integer The first byte.
---@param uint8_2? integer The second byte.
---@param uint8_3? integer The third byte.
---@param uint8_4? integer The fourth byte.
---@param uint8_5? integer The fifth byte.
---@param uint8_6? integer The sixth byte.
---@param uint8_7? integer The seventh byte.
---@param uint8_8? integer The eighth byte.
---@return number value The unsigned fixed-point number.
function bytepack.readUnsignedFixedPoint( n, uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    if uint8_1 == nil then
        return 0
    end

    local divisor = 2 ^ n

    if uint8_2 == nil then
        return uint8_1 / divisor
    elseif uint8_3 == nil then
        return readUInt16( uint8_1, uint8_2 ) / divisor
    elseif uint8_4 == nil then
        return readUInt24( uint8_1, uint8_2, uint8_3 ) / divisor
    elseif uint8_5 == nil then
        return readUInt32( uint8_1, uint8_2, uint8_3, uint8_4 ) / divisor
    elseif uint8_6 == nil then
        return readUInt40( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 ) / divisor
    elseif uint8_7 == nil then
        return readUInt48( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 ) / divisor
    elseif uint8_8 == nil then
        return readUInt56( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 ) / divisor
    else
        return readUInt64( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 ) / divisor
    end
end

--- [SHARED AND MENU]
---
--- Writes unsigned fixed-point number (**UQm.n**) as little endian bytes.
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
---@param value number The unsigned fixed-point number.
---@param m integer Number of integer bits (including sign bit).
---@param n integer Number of fractional bits.
---@return integer uint8_1 The first byte.
---@return integer? uint8_2 The second byte.
---@return integer? uint8_3 The third byte.
---@return integer? uint8_4 The fourth byte.
---@return integer? uint8_5 The fifth byte.
---@return integer? uint8_6 The sixth byte.
---@return integer? uint8_7 The seventh byte.
---@return integer? uint8_8 The eighth byte.
function bytepack.writeUnsignedFixedPoint( value, m, n )
    local byte_count = (m + n) * 0.125
    if byte_count % 1 ~= 0 then
        error( "invalid number of integer or fractional bits", 2 )
    end

    local unsigned_integer = value * (2 ^ n)

    if byte_count == 1 then
        return unsigned_integer
    elseif byte_count == 2 then
        return writeUInt16( unsigned_integer )
    elseif byte_count == 3 then
        return writeUInt24( unsigned_integer )
    elseif byte_count == 4 then
        return writeUInt32( unsigned_integer )
    elseif byte_count == 5 then
        return writeUInt40( unsigned_integer )
    elseif byte_count == 6 then
        return writeUInt48( unsigned_integer )
    elseif byte_count == 7 then
        return writeUInt56( unsigned_integer )
    else
        return writeUInt64( unsigned_integer )
    end
end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param uint8_1 integer The byte.
---@return integer value The signed 1-byte integer.
local function readInt8( uint8_1 )
    return uint8_1 - 0x80
end

bytepack.readInt8 = readInt8

--- [SHARED AND MENU]
---
--- Writes signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param value integer The signed 1-byte integer.
---@return integer uint8_1 The byte.
local function writeInt8( value )
    return value + 0x80
end

bytepack.writeInt8 = writeInt8

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer value The signed 2-byte integer.
local function readInt16( uint8_1, uint8_2 )
    return readUInt16( uint8_1, uint8_2 ) - 0x8000
end

bytepack.readInt16 = readInt16

--- [SHARED AND MENU]
---
--- Writes signed 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param value integer The signed 2-byte integer.
---@return integer uint8_1 The first byte.
---@return integer uint8_2 The second byte.
local function writeInt16( value )
    return writeUInt16( value + 0x8000 )
end

bytepack.writeInt16 = writeInt16

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
local function readInt24( uint8_1, uint8_2, uint8_3 )
    return readUInt24( uint8_1, uint8_2, uint8_3 ) - 0x800000
end

bytepack.readInt24 = readInt24

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
local function writeInt24( value )
    return writeUInt24( value + 0x800000 )
end

bytepack.writeInt24 = writeInt24

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
local function readInt32( uint8_1, uint8_2, uint8_3, uint8_4 )
    return readUInt32( uint8_1, uint8_2, uint8_3, uint8_4 ) - 0x80000000
end

bytepack.readInt32 = readInt32

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
local function writeInt32( value )
    return writeUInt32( value + 0x80000000 )
end

bytepack.writeInt32 = writeInt32

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
local function readInt40( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 )
    return readUInt40( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 ) - 0x8000000000
end

bytepack.readInt40 = readInt40

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
local function writeInt40( value )
    return writeUInt40( value + 0x8000000000 )
end

bytepack.writeInt40 = writeInt40

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
local function readInt48( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
    return readUInt48( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 ) - 0x800000000000
end

bytepack.readInt48 = readInt48

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
local function writeInt48( value )
    return writeUInt48( value + 0x800000000000 )
end

bytepack.writeInt48 = writeInt48

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
local function readInt56( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 )
    if uint8_1 < 0x80 then
        return (((((uint8_7 * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
    else
        return (((((((uint8_7 - 0xFF) * 0x100 + (uint8_6 - 0xFF)) * 0x100 + (uint8_5 - 0xFF)) * 0x100 + (uint8_4 - 0xFF)) * 0x100 + (uint8_3 - 0xFF)) * 0x100 + (uint8_2 - 0xFF)) * 0x100 + (uint8_1 - 0xFF)) - 1
    end
end

bytepack.readInt56 = readInt56

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
local function writeInt56( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100,
        math_floor( value / 0x10000000000 ) % 0x100,
        math_ispositive( value ) and 0 or 0xFF
end

bytepack.writeInt56 = writeInt56

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
local function readInt64( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    if uint8_1 < 0x80 then
        return ((((((uint8_8 * 0x100 + uint8_7) * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1
    else
        return ((((((((uint8_8 - 0xFF) * 0x100 + (uint8_7 - 0xFF)) * 0x100 + (uint8_6 - 0xFF)) * 0x100 + (uint8_5 - 0xFF)) * 0x100 + (uint8_4 - 0xFF)) * 0x100 + (uint8_3 - 0xFF)) * 0x100 + (uint8_2 - 0xFF)) * 0x100 + (uint8_1 - 0xFF)) - 1
    end
end

bytepack.readInt64 = readInt64

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
local function writeInt64( value )
    return value % 0x100,
        math_floor( value / 0x100 ) % 0x100,
        math_floor( value / 0x10000 ) % 0x100,
        math_floor( value / 0x1000000 ) % 0x100,
        math_floor( value / 0x100000000 ) % 0x100,
        math_floor( value / 0x10000000000 ) % 0x100,
        math_floor( value / 0x1000000000000 ) % 0x100,
        math_ispositive( value ) and 0 or 0xFF
end

bytepack.writeInt64 = writeInt64

--- [SHARED AND MENU]
---
--- Reads signed fixed-point number (**Qm.n**) as little endian bytes.
---
--- ### Commonly Used Qm.n Formats
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
---@param uint8_1 integer The first byte.
---@param uint8_2? integer The second byte.
---@param uint8_3? integer The third byte.
---@param uint8_4? integer The fourth byte.
---@param uint8_5? integer The fifth byte.
---@param uint8_6? integer The sixth byte.
---@param uint8_7? integer The seventh byte.
---@param uint8_8? integer The eighth byte.
---@return number value The signed fixed-point number.
function bytepack.readFixedPoint( n, uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    if uint8_1 == nil then
        return 0
    end

    local divisor = 2 ^ n

    if uint8_2 == nil then
        return readInt8( uint8_1 ) / divisor
    elseif uint8_3 == nil then
        return readInt16( uint8_1, uint8_2 ) / divisor
    elseif uint8_4 == nil then
        return readInt24( uint8_1, uint8_2, uint8_3 ) / divisor
    elseif uint8_5 == nil then
        return readInt32( uint8_1, uint8_2, uint8_3, uint8_4 ) / divisor
    elseif uint8_6 == nil then
        return readInt40( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5 ) / divisor
    elseif uint8_7 == nil then
        return readInt48( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 ) / divisor
    elseif uint8_8 == nil then
        return readInt56( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7 ) / divisor
    else
        return readInt64( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 ) / divisor
    end
end

--- [SHARED AND MENU]
---
--- Writes unsigned fixed-point number (**UQm.n**) as little endian bytes.
---
--- ### Commonly Used Qm.n Formats
--- | Format | Range                          | Precision (Step)        |
--- |:-------|:-------------------------------|:------------------------|
--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
---
---@param value number The unsigned fixed-point number.
---@param m integer Number of integer bits (including sign bit).
---@param n integer Number of fractional bits.
---@return integer uint8_1 The first byte.
---@return integer? uint8_2 The second byte.
---@return integer? uint8_3 The third byte.
---@return integer? uint8_4 The fourth byte.
---@return integer? uint8_5 The fifth byte.
---@return integer? uint8_6 The sixth byte.
---@return integer? uint8_7 The seventh byte.
---@return integer? uint8_8 The eighth byte.
function bytepack.writeFixedPoint( value, m, n )
    local byte_count = (m + n) * 0.125
    if byte_count % 1 ~= 0 then
        error( "invalid byte count", 2 )
    end

    local signed_integer = value * (2 ^ n)

    if byte_count == 1 then
        return writeInt8( signed_integer )
    elseif byte_count == 2 then
        return writeInt16( signed_integer )
    elseif byte_count == 3 then
        return writeInt24( signed_integer )
    elseif byte_count == 4 then
        return writeInt32( signed_integer )
    elseif byte_count == 5 then
        return writeInt40( signed_integer )
    elseif byte_count == 6 then
        return writeInt48( signed_integer )
    elseif byte_count == 7 then
        return writeInt56( signed_integer )
    else
        return writeInt64( signed_integer )
    end
end

local math_huge, math_tiny, math_nan = math.huge, math.tiny, math.nan
local math_frexp, math_ldexp = math.frexp, math.ldexp

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) float from little endian bytes.
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@param uint8_3 integer The third byte.
---@param uint8_4 integer The fourth byte.
---@return number value The signed 4-byte float.
function bytepack.readFloat( uint8_1, uint8_2, uint8_3, uint8_4 )
    local sign = uint8_4 > 0x7F
    local expo = (uint8_4 % 0x80) * 0x2 + math_floor( uint8_3 / 0x80 )
    local mant = ((uint8_3 % 0x80) * 0x100 + uint8_2) * 0x100 + uint8_1

    if mant == 0 and expo == 0 then
        if sign then
            return -0.0
        else
            return 0.0
        end
    elseif expo == 0xFF then
        if mant == 0 then
            if sign then
                return math_tiny
            else
                return math_huge
            end
        else
            return math_nan
        end
    end

    if sign then
        return -math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
    else
        return math_ldexp( 1.0 + mant / 0x800000, expo - 0x7F )
    end
end

--- [SHARED AND MENU]
---
--- Writes signed 4-byte (32 bit) float as little endian bytes.
---
---@param value number The signed 4-byte float.
---@return integer uint8_1 The first byte.
---@return integer uint8_2 The second byte.
---@return integer uint8_3 The third byte.
---@return integer uint8_4 The fourth byte.
function bytepack.writeFloat( value, big_endian )
    if value ~= value then
        return 255, 136, 0, 0
    end

    local sign = false
    if value < 0.0 then
        value = -value
        sign = true
    end

    local mant, expo = math_frexp( value )
    if mant == math_huge or expo > 0x80 then
        if sign then
            return 255, 128, 0, 0
        else
            return 127, 128, 0, 0
        end
    elseif (mant == 0.0 and expo == 0) or (expo < -0x7E) then
        if (1 / value) == math_huge then
            return 0, 0, 0, 0
        else
            return 128, 0, 0, 0
        end
    end

    mant = math_floor( (mant * 2.0 - 1.0) * math_ldexp( 0.5, 24 ) )
    expo = expo + 0x7E

    return mant % 0x100,
        math_floor( mant / 0x100 ) % 0x100,
        (expo % 0x2) * 0x80 + math_floor( mant / 0x10000 ),
        (sign and 0x80 or 0) + math_floor( expo / 0x2 )
end

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
function bytepack.readDouble( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    local sign = uint8_8 > 0x7F
    local expo = (uint8_8 % 0x80) * 0x10 + math_floor( uint8_7 / 0x10 )
    local mant = ((((((uint8_7 % 0x10) * 0x100 + uint8_6) * 0x100 + uint8_5) * 0x100 + uint8_4) * 0x100 + uint8_3) * 0x100 + uint8_2) * 0x100 + uint8_1

    if mant == 0 and expo == 0 then
        if sign then
            return -0.0
        else
            return 0.0
        end
    elseif expo == 0x7FF then
        if mant == 0 then
            if sign then
                return math_tiny
            else
                return math_huge
            end
        else
            return math_nan
        end
    end

    if sign then
        return -math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
    else
        return math_ldexp( 1.0 + mant / 4503599627370496.0, expo - 0x3FF )
    end
end

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
function bytepack.writeDouble( value )
    if value ~= value then -- NaN
        return 255, 248, 0, 0, 0, 0, 0, 0
    end

    local sign = false
    if value < 0.0 then
        value = -value
        sign = true
    end

    local mant, expo = math_frexp( value )
    if mant == math_huge or expo > 0x400 then -- inf
        if sign then
            return 255, 240, 0, 0, 0, 0, 0, 0
        else
            return 127, 240, 0, 0, 0, 0, 0, 0
        end
    elseif (mant == 0.0 and expo == 0) or (expo < -0x3FE) then -- zero
        if (1 / value) == math_huge then
            return 0, 0, 0, 0, 0, 0, 0, 0
        else
            return 128, 0, 0, 0, 0, 0, 0, 0
        end
    end

    mant = math_floor( (mant * 2.0 - 1.0) * math_ldexp( 0.5, 53 ) )
    expo = expo + 0x3FE

    return mant % 0x100,
        math_floor( mant / 0x100 ) % 0x100,
        math_floor( mant / 0x10000 ) % 0x100,
        math_floor( mant / 0x1000000 ) % 0x100,
        math_floor( mant / 0x100000000 ) % 0x100,
        math_floor( mant / 0x10000000000 ) % 0x100,
        (expo % 0x10) * 0x10 + math_floor( mant / 0x1000000000000 ),
        (sign and 0x80 or 0) + math_floor( expo / 0x10 )
end

do

    ---@type table<integer, integer>
    local decode_map = {
        [ 0x30 ] = 0x0,
        [ 0x31 ] = 0x1,
        [ 0x32 ] = 0x2,
        [ 0x33 ] = 0x3,
        [ 0x34 ] = 0x4,
        [ 0x35 ] = 0x5,
        [ 0x36 ] = 0x6,
        [ 0x37 ] = 0x7,
        [ 0x38 ] = 0x8,
        [ 0x39 ] = 0x9,
        [ 0x41 ] = 0xA,
        [ 0x42 ] = 0xB,
        [ 0x43 ] = 0xC,
        [ 0x44 ] = 0xD,
        [ 0x45 ] = 0xE,
        [ 0x46 ] = 0xF,
        [ 0x61 ] = 0xA,
        [ 0x62 ] = 0xB,
        [ 0x63 ] = 0xC,
        [ 0x64 ] = 0xD,
        [ 0x65 ] = 0xE,
        [ 0x66 ] = 0xF
    }

    do

        local raw_pairs = std.raw.pairs
        local uint8_cache = {}

        for i in raw_pairs( decode_map ) do
            for j in raw_pairs( decode_map ) do
                uint8_cache[ bit_lshift( i, 8 ) + j ] = bit_lshift( decode_map[ i ], 4 ) + decode_map[ j ]
            end
        end

        --- [SHARED AND MENU]
        ---
        --- Reads unsigned 1-byte (8 bit) integer from big endian hex bytes.
        ---
        ---@param uint8_1 integer The first byte.
        ---@param uint8_2 integer The second byte.
        ---@return integer | nil value The unsigned 1-byte integer or `nil` if bytes do not match the allowed ones.
        function bytepack.readHex8( uint8_1, uint8_2 )
            return uint8_cache[ bit_lshift( uint8_1, 8 ) + uint8_2 ]
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 2-byte (16 bit) integer from big endian hex bytes.
    ---
    ---@param uint8_1 integer The first byte.
    ---@param uint8_2 integer The second byte.
    ---@param uint8_3 integer The third byte.
    ---@param uint8_4 integer The fourth byte.
    ---@return integer value The unsigned 2-byte integer.
    function bytepack.readHex16( uint8_1, uint8_2, uint8_3, uint8_4 )
        return bit_bor(
            bit_lshift( decode_map[ uint8_1 ], 12 ),
            bit_lshift( decode_map[ uint8_2 ], 8 ),
            bit_lshift( decode_map[ uint8_3 ], 4 ),
            decode_map[ uint8_4 ]
        )
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
    ---@return integer value The unsigned 3-byte integer.
    function bytepack.readHex24( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6 )
        return bit_bor(
            bit_lshift( decode_map[ uint8_1 ], 20 ),
            bit_lshift( decode_map[ uint8_2 ], 16 ),
            bit_lshift( decode_map[ uint8_3 ], 12 ),
            bit_lshift( decode_map[ uint8_4 ], 8 ),
            bit_lshift( decode_map[ uint8_5 ], 4 ),
            decode_map[ uint8_6 ]
        )
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
    ---@return integer value The unsigned 4-byte integer.
    function bytepack.readHex32( uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
        return bit_bor(
            bit_lshift( decode_map[ uint8_1 ], 28 ),
            bit_lshift( decode_map[ uint8_2 ], 24 ),
            bit_lshift( decode_map[ uint8_3 ], 20 ),
            bit_lshift( decode_map[ uint8_4 ], 16 ),
            bit_lshift( decode_map[ uint8_5 ], 12 ),
            bit_lshift( decode_map[ uint8_6 ], 8 ),
            bit_lshift( decode_map[ uint8_7 ], 4 ),
            decode_map[ uint8_8 ]
        ) % 0xFFFFFFFF
    end

end

do

    ---@type table<integer, integer>
    local encode_map = {
        [ 0x0 ] = 0x30,
        [ 0x1 ] = 0x31,
        [ 0x2 ] = 0x32,
        [ 0x3 ] = 0x33,
        [ 0x4 ] = 0x34,
        [ 0x5 ] = 0x35,
        [ 0x6 ] = 0x36,
        [ 0x7 ] = 0x37,
        [ 0x8 ] = 0x38,
        [ 0x9 ] = 0x39,
        [ 0xA ] = 0x41,
        [ 0xB ] = 0x42,
        [ 0xC ] = 0x43,
        [ 0xD ] = 0x44,
        [ 0xE ] = 0x45,
        [ 0xF ] = 0x46
    }

    do

        local uint8_cache_1 = {}

        for uint8 = 0, 255, 1 do
            uint8_cache_1[ uint8 ] = encode_map[ bit_band( bit_rshift( uint8, 4 ), 0x0F ) ]
        end

        local uint8_cache_2 = {}

        for uint8 = 0, 255, 1 do
            uint8_cache_2[ uint8 ] = encode_map[ bit_band( uint8, 0x0F ) ]
        end

        --- [SHARED AND MENU]
        ---
        --- Encodes unsigned 1-byte (8 bit) integer to big endian hex bytes.
        ---
        --- Valid values without loss of precision: `0` - `255`
        ---
        ---@param uint8 integer The unsigned 1-byte integer.
        ---@return integer uint8_1 The first byte.
        ---@return integer uint8_2 The second byte.
        function bytepack.writeHex8( uint8 )
            return uint8_cache_1[ uint8 ], uint8_cache_2[ uint8 ]
        end

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
    function bytepack.writeHex16( uint16 )
        return encode_map[ bit_band( bit_rshift( uint16, 12 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint16, 8 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint16, 4 ), 0x0F ) ],
            encode_map[ bit_band( uint16, 0x0F ) ]
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
    function bytepack.writeHex24( uint24 )
        return encode_map[ bit_band( bit_rshift( uint24, 20 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint24, 16 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint24, 12 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint24, 8 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint24, 4 ), 0x0F ) ],
            encode_map[ bit_band( uint24, 0x0F ) ]
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
    function bytepack.writeHex32( uint32 )
        return encode_map[ bit_band( bit_rshift( uint32, 28 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 24 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 20 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 16 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 12 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 8 ), 0x0F ) ],
            encode_map[ bit_band( bit_rshift( uint32, 4 ), 0x0F ) ],
            encode_map[ bit_band( uint32, 0x0F ) ]
    end

end
