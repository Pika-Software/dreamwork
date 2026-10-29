---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_len, string_rep = string.len, string.rep
local string_sub, string_find = string.sub, string.find
local string_byte, string_char = string.byte, string.char

local table_unpack = std.table.unpack

local bytepack = std.bytepack

local raw = std.raw

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local EndOfFileError = std.EndOfFileError
local error = std.error


--- [SHARED AND MENU]
---
--- Library that packs & unpacks types as strings, same as `bytepack` does with bytes.
---
--- Functions with a size in their name (`readUInt16BE`, `writeFloatLE`, `readNullTerminatedString`, ...)
--- read from a `1`-based byte `index` of the string, same as `string.byte`, and write a new string:
---
--- ```
--- local data = pack.writeUInt16BE( 300 ) .. pack.writeFloatLE( 1.5 ) --> "\1\44\0\0\192\63"
---
--- pack.readUInt16BE( data, 1 ) --> 300
--- pack.readFloatLE( data, 3 ) --> 1.5
--- ```
---
--- Bit functions (`readBit`, `readBoolean`, `readBytes`, `readUInt`, `readInt`, `readFixedPoint`, `readUnsignedFixedPoint`)
--- read from a `0`-based `bit_position` instead, so they also read fields that are not aligned to bytes.
---
--- Bits are stored LSB-first (bit `0` of the data is the lowest bit of the first byte),
--- and little endian integers are stored lowest bit first, same as Source's `bf_write`/`bf_read`,
--- so data is compatible with gmod `net.Write*`/`net.Read*`.
---
--- All reads throw `EndOfFileError` when the string is too short.
---
--- `stack_level` of local functions is the level relative to their caller,
--- public functions that tail call them pass `1` (tail calls drop the frame), others pass `2`.
---
---@class dreamwork.std.pack
local pack = {}
std.pack = pack

-- U/Int8
do

    local bytepack_readUInt8 = bytepack.readUInt8
    local bytepack_writeUInt8 = bytepack.writeUInt8
    local bytepack_readInt8 = bytepack.readInt8
    local bytepack_writeInt8 = bytepack.writeInt8

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 1-byte (8 bit) integer from the string.
    ---
    --- Valid values without loss of precision: `0` - `255`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 1-byte integer.
    ---@nodiscard
    function pack.readUInt8( str, index )
        if index == nil then
            index = 1
        end

        if index > string_len( str ) then
            error( EndOfFileError( index - 1, 1 ), 2 )
        end

        return bytepack_readUInt8( string_byte( str, index, index ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 1-byte (8 bit) integer as a string.
    ---
    --- Valid values without loss of precision: `0` - `255`
    ---
    ---@param value integer The unsigned 1-byte integer.
    ---@return string data The 1-byte string.
    ---@nodiscard
    function pack.writeUInt8( value )
        return string_char( bytepack_writeUInt8( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 1-byte (8 bit) integer from the string.
    ---
    --- Valid values without loss of precision: `-128` - `127`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 1-byte integer.
    ---@nodiscard
    function pack.readInt8( str, index )
        if index == nil then
            index = 1
        end

        if index > string_len( str ) then
            error( EndOfFileError( index - 1, 1 ), 2 )
        end

        return bytepack_readInt8( string_byte( str, index, index ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 1-byte (8 bit) integer as a string.
    ---
    --- Valid values without loss of precision: `-128` - `127`
    ---
    ---@param value integer The signed 1-byte integer.
    ---@return string data The 1-byte string.
    ---@nodiscard
    function pack.writeInt8( value )
        return string_char( bytepack_writeInt8( value ) )
    end

end

-- U/Int16 [BE]
do

    local bytepack_readUInt16BE = bytepack.readUInt16BE
    local bytepack_writeUInt16BE = bytepack.writeUInt16BE
    local bytepack_readInt16BE = bytepack.readInt16BE
    local bytepack_writeInt16BE = bytepack.writeInt16BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 2-byte (16 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 2-byte integer.
    ---@nodiscard
    function pack.readUInt16BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readUInt16BE( string_byte( str, index, index + 1 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 2-byte (16 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param value integer The unsigned 2-byte integer.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeUInt16BE( value )
        return string_char( bytepack_writeUInt16BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 2-byte (16 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 2-byte integer.
    ---@nodiscard
    function pack.readInt16BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readInt16BE( string_byte( str, index, index + 1 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 2-byte (16 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param value integer The signed 2-byte integer.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeInt16BE( value )
        return string_char( bytepack_writeInt16BE( value ) )
    end

end

-- U/Int16 [LE]
do

    local bytepack_readUInt16LE = bytepack.readUInt16LE
    local bytepack_writeUInt16LE = bytepack.writeUInt16LE
    local bytepack_readInt16LE = bytepack.readInt16LE
    local bytepack_writeInt16LE = bytepack.writeInt16LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 2-byte (16 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 2-byte integer.
    ---@nodiscard
    function pack.readUInt16LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readUInt16LE( string_byte( str, index, index + 1 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 2-byte (16 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `65535`
    ---
    ---@param value integer The unsigned 2-byte integer.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeUInt16LE( value )
        return string_char( bytepack_writeUInt16LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 2-byte (16 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 2-byte integer.
    ---@nodiscard
    function pack.readInt16LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readInt16LE( string_byte( str, index, index + 1 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 2-byte (16 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-32768` - `32767`
    ---
    ---@param value integer The signed 2-byte integer.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeInt16LE( value )
        return string_char( bytepack_writeInt16LE( value ) )
    end

end

-- U/Int24 [BE]
do

    local bytepack_readUInt24BE = bytepack.readUInt24BE
    local bytepack_writeUInt24BE = bytepack.writeUInt24BE
    local bytepack_readInt24BE = bytepack.readInt24BE
    local bytepack_writeInt24BE = bytepack.writeInt24BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 3-byte (24 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 3-byte integer.
    ---@nodiscard
    function pack.readUInt24BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 2 > string_len( str ) then
            error( EndOfFileError( index - 1, 3 ), 2 )
        end

        return bytepack_readUInt24BE( string_byte( str, index, index + 2 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 3-byte (24 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param value integer The unsigned 3-byte integer.
    ---@return string data The 3-byte string.
    ---@nodiscard
    function pack.writeUInt24BE( value )
        return string_char( bytepack_writeUInt24BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 3-byte (24 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 3-byte integer.
    ---@nodiscard
    function pack.readInt24BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 2 > string_len( str ) then
            error( EndOfFileError( index - 1, 3 ), 2 )
        end

        return bytepack_readInt24BE( string_byte( str, index, index + 2 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 3-byte (24 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param value integer The signed 3-byte integer.
    ---@return string data The 3-byte string.
    ---@nodiscard
    function pack.writeInt24BE( value )
        return string_char( bytepack_writeInt24BE( value ) )
    end

end

-- U/Int24 [LE]
do

    local bytepack_readUInt24LE = bytepack.readUInt24LE
    local bytepack_writeUInt24LE = bytepack.writeUInt24LE
    local bytepack_readInt24LE = bytepack.readInt24LE
    local bytepack_writeInt24LE = bytepack.writeInt24LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 3-byte (24 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 3-byte integer.
    ---@nodiscard
    function pack.readUInt24LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 2 > string_len( str ) then
            error( EndOfFileError( index - 1, 3 ), 2 )
        end

        return bytepack_readUInt24LE( string_byte( str, index, index + 2 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 3-byte (24 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `16777215`
    ---
    ---@param value integer The unsigned 3-byte integer.
    ---@return string data The 3-byte string.
    ---@nodiscard
    function pack.writeUInt24LE( value )
        return string_char( bytepack_writeUInt24LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 3-byte (24 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 3-byte integer.
    ---@nodiscard
    function pack.readInt24LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 2 > string_len( str ) then
            error( EndOfFileError( index - 1, 3 ), 2 )
        end

        return bytepack_readInt24LE( string_byte( str, index, index + 2 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 3-byte (24 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-8388608` - `8388607`
    ---
    ---@param value integer The signed 3-byte integer.
    ---@return string data The 3-byte string.
    ---@nodiscard
    function pack.writeInt24LE( value )
        return string_char( bytepack_writeInt24LE( value ) )
    end

end

-- U/Int32 [BE]
do

    local bytepack_readUInt32BE = bytepack.readUInt32BE
    local bytepack_writeUInt32BE = bytepack.writeUInt32BE
    local bytepack_readInt32BE = bytepack.readInt32BE
    local bytepack_writeInt32BE = bytepack.writeInt32BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 4-byte (32 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 4-byte integer.
    ---@nodiscard
    function pack.readUInt32BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readUInt32BE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 4-byte (32 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param value integer The unsigned 4-byte integer.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeUInt32BE( value )
        return string_char( bytepack_writeUInt32BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 4-byte (32 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 4-byte integer.
    ---@nodiscard
    function pack.readInt32BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readInt32BE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 4-byte (32 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param value integer The signed 4-byte integer.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeInt32BE( value )
        return string_char( bytepack_writeInt32BE( value ) )
    end

end

-- U/Int32 [LE]
do

    local bytepack_readUInt32LE = bytepack.readUInt32LE
    local bytepack_writeUInt32LE = bytepack.writeUInt32LE
    local bytepack_readInt32LE = bytepack.readInt32LE
    local bytepack_writeInt32LE = bytepack.writeInt32LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 4-byte (32 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 4-byte integer.
    ---@nodiscard
    function pack.readUInt32LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readUInt32LE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 4-byte (32 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `4294967295`
    ---
    ---@param value integer The unsigned 4-byte integer.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeUInt32LE( value )
        return string_char( bytepack_writeUInt32LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 4-byte (32 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 4-byte integer.
    ---@nodiscard
    function pack.readInt32LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readInt32LE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 4-byte (32 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-2147483648` - `2147483647`
    ---
    ---@param value integer The signed 4-byte integer.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeInt32LE( value )
        return string_char( bytepack_writeInt32LE( value ) )
    end

end

-- U/Int40 [BE]
do

    local bytepack_readUInt40BE = bytepack.readUInt40BE
    local bytepack_writeUInt40BE = bytepack.writeUInt40BE
    local bytepack_readInt40BE = bytepack.readInt40BE
    local bytepack_writeInt40BE = bytepack.writeInt40BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 5-byte (40 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 5-byte integer.
    ---@nodiscard
    function pack.readUInt40BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 4 > string_len( str ) then
            error( EndOfFileError( index - 1, 5 ), 2 )
        end

        return bytepack_readUInt40BE( string_byte( str, index, index + 4 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 5-byte (40 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`.
    ---
    ---@param value integer The unsigned 5-byte integer.
    ---@return string data The 5-byte string.
    ---@nodiscard
    function pack.writeUInt40BE( value )
        return string_char( bytepack_writeUInt40BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 5-byte (40 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 5-byte integer.
    ---@nodiscard
    function pack.readInt40BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 4 > string_len( str ) then
            error( EndOfFileError( index - 1, 5 ), 2 )
        end

        return bytepack_readInt40BE( string_byte( str, index, index + 4 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 5-byte (40 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param value integer The signed 5-byte integer.
    ---@return string data The 5-byte string.
    ---@nodiscard
    function pack.writeInt40BE( value )
        return string_char( bytepack_writeInt40BE( value ) )
    end

end

-- U/Int40 [LE]
do

    local bytepack_readUInt40LE = bytepack.readUInt40LE
    local bytepack_writeUInt40LE = bytepack.writeUInt40LE
    local bytepack_readInt40LE = bytepack.readInt40LE
    local bytepack_writeInt40LE = bytepack.writeInt40LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 5-byte (40 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 5-byte integer.
    ---@nodiscard
    function pack.readUInt40LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 4 > string_len( str ) then
            error( EndOfFileError( index - 1, 5 ), 2 )
        end

        return bytepack_readUInt40LE( string_byte( str, index, index + 4 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 5-byte (40 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `1099511627775`.
    ---
    ---@param value integer The unsigned 5-byte integer.
    ---@return string data The 5-byte string.
    ---@nodiscard
    function pack.writeUInt40LE( value )
        return string_char( bytepack_writeUInt40LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 5-byte (40 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 5-byte integer.
    ---@nodiscard
    function pack.readInt40LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 4 > string_len( str ) then
            error( EndOfFileError( index - 1, 5 ), 2 )
        end

        return bytepack_readInt40LE( string_byte( str, index, index + 4 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 5-byte (40 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-549755813888` - `549755813887`
    ---
    ---@param value integer The signed 5-byte integer.
    ---@return string data The 5-byte string.
    ---@nodiscard
    function pack.writeInt40LE( value )
        return string_char( bytepack_writeInt40LE( value ) )
    end

end

-- U/Int48 [BE]
do

    local bytepack_readUInt48BE = bytepack.readUInt48BE
    local bytepack_writeUInt48BE = bytepack.writeUInt48BE
    local bytepack_readInt48BE = bytepack.readInt48BE
    local bytepack_writeInt48BE = bytepack.writeInt48BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 6-byte (48 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 6-byte integer.
    ---@nodiscard
    function pack.readUInt48BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 5 > string_len( str ) then
            error( EndOfFileError( index - 1, 6 ), 2 )
        end

        return bytepack_readUInt48BE( string_byte( str, index, index + 5 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 6-byte (48 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param value integer The unsigned 6-byte integer.
    ---@return string data The 6-byte string.
    ---@nodiscard
    function pack.writeUInt48BE( value )
        return string_char( bytepack_writeUInt48BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 6-byte (48 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 6-byte integer.
    ---@nodiscard
    function pack.readInt48BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 5 > string_len( str ) then
            error( EndOfFileError( index - 1, 6 ), 2 )
        end

        return bytepack_readInt48BE( string_byte( str, index, index + 5 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 6-byte (48 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param value integer The signed 6-byte integer.
    ---@return string data The 6-byte string.
    ---@nodiscard
    function pack.writeInt48BE( value )
        return string_char( bytepack_writeInt48BE( value ) )
    end

end

-- U/Int48 [LE]
do

    local bytepack_readUInt48LE = bytepack.readUInt48LE
    local bytepack_writeUInt48LE = bytepack.writeUInt48LE
    local bytepack_readInt48LE = bytepack.readInt48LE
    local bytepack_writeInt48LE = bytepack.writeInt48LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 6-byte (48 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 6-byte integer.
    ---@nodiscard
    function pack.readUInt48LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 5 > string_len( str ) then
            error( EndOfFileError( index - 1, 6 ), 2 )
        end

        return bytepack_readUInt48LE( string_byte( str, index, index + 5 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 6-byte (48 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `281474976710655`
    ---
    ---@param value integer The unsigned 6-byte integer.
    ---@return string data The 6-byte string.
    ---@nodiscard
    function pack.writeUInt48LE( value )
        return string_char( bytepack_writeUInt48LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 6-byte (48 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 6-byte integer.
    ---@nodiscard
    function pack.readInt48LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 5 > string_len( str ) then
            error( EndOfFileError( index - 1, 6 ), 2 )
        end

        return bytepack_readInt48LE( string_byte( str, index, index + 5 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 6-byte (48 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-140737488355328` - `140737488355327`
    ---
    ---@param value integer The signed 6-byte integer.
    ---@return string data The 6-byte string.
    ---@nodiscard
    function pack.writeInt48LE( value )
        return string_char( bytepack_writeInt48LE( value ) )
    end

end

-- U/Int56 [BE]
do

    local bytepack_readUInt56BE = bytepack.readUInt56BE
    local bytepack_writeUInt56BE = bytepack.writeUInt56BE
    local bytepack_readInt56BE = bytepack.readInt56BE
    local bytepack_writeInt56BE = bytepack.writeInt56BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 7-byte (56 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 7-byte integer.
    ---@nodiscard
    function pack.readUInt56BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 6 > string_len( str ) then
            error( EndOfFileError( index - 1, 7 ), 2 )
        end

        return bytepack_readUInt56BE( string_byte( str, index, index + 6 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 7-byte (56 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 7-byte integer.
    ---@return string data The 7-byte string.
    ---@nodiscard
    function pack.writeUInt56BE( value )
        return string_char( bytepack_writeUInt56BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 7-byte (56 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 7-byte integer.
    ---@nodiscard
    function pack.readInt56BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 6 > string_len( str ) then
            error( EndOfFileError( index - 1, 7 ), 2 )
        end

        return bytepack_readInt56BE( string_byte( str, index, index + 6 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 7-byte (56 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param value integer The signed 7-byte integer.
    ---@return string data The 7-byte string.
    ---@nodiscard
    function pack.writeInt56BE( value )
        return string_char( bytepack_writeInt56BE( value ) )
    end

end

-- U/Int56 [LE]
do

    local bytepack_readUInt56LE = bytepack.readUInt56LE
    local bytepack_writeUInt56LE = bytepack.writeUInt56LE
    local bytepack_readInt56LE = bytepack.readInt56LE
    local bytepack_writeInt56LE = bytepack.writeInt56LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 7-byte (56 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 7-byte integer.
    ---@nodiscard
    function pack.readUInt56LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 6 > string_len( str ) then
            error( EndOfFileError( index - 1, 7 ), 2 )
        end

        return bytepack_readUInt56LE( string_byte( str, index, index + 6 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 7-byte (56 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 7-byte integer.
    ---@return string data The 7-byte string.
    ---@nodiscard
    function pack.writeUInt56LE( value )
        return string_char( bytepack_writeUInt56LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 7-byte (56 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 7-byte integer.
    ---@nodiscard
    function pack.readInt56LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 6 > string_len( str ) then
            error( EndOfFileError( index - 1, 7 ), 2 )
        end

        return bytepack_readInt56LE( string_byte( str, index, index + 6 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes signed 7-byte (56 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
    ---
    ---@param value integer The signed 7-byte integer.
    ---@return string data The 7-byte string.
    ---@nodiscard
    function pack.writeInt56LE( value )
        return string_char( bytepack_writeInt56LE( value ) )
    end

end

-- U/Int64 [BE]
do

    local bytepack_readUInt64BE = bytepack.readUInt64BE
    local bytepack_writeUInt64BE = bytepack.writeUInt64BE
    local bytepack_readInt64BE = bytepack.readInt64BE
    local bytepack_writeInt64BE = bytepack.writeInt64BE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 8-byte (64 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 8-byte integer.
    ---@nodiscard
    function pack.readUInt64BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readUInt64BE( string_byte( str, index, index + 7 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 8-byte (64 bit) integer as big endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 8-byte integer.
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeUInt64BE( value )
        return string_char( bytepack_writeUInt64BE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 8-byte (64 bit) integer from big endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 8-byte integer.
    ---@nodiscard
    function pack.readInt64BE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readInt64BE( string_byte( str, index, index + 7 ) )
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
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeInt64BE( value )
        return string_char( bytepack_writeInt64BE( value ) )
    end

end

-- U/Int64 [LE]
do

    local bytepack_readUInt64LE = bytepack.readUInt64LE
    local bytepack_writeUInt64LE = bytepack.writeUInt64LE
    local bytepack_readInt64LE = bytepack.readInt64LE
    local bytepack_writeInt64LE = bytepack.writeInt64LE

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned 8-byte (64 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The unsigned 8-byte integer.
    ---@nodiscard
    function pack.readUInt64LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readUInt64LE( string_byte( str, index, index + 7 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes unsigned 8-byte (64 bit) integer as little endian bytes.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param value integer The unsigned 8-byte integer.
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeUInt64LE( value )
        return string_char( bytepack_writeUInt64LE( value ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed 8-byte (64 bit) integer from little endian bytes of the string.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991`
    ---
    --- All values above will have problems when working with them.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer value The signed 8-byte integer.
    ---@nodiscard
    function pack.readInt64LE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readInt64LE( string_byte( str, index, index + 7 ) )
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
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeInt64LE( value )
        return string_char( bytepack_writeInt64LE( value ) )
    end

end

-- Float [BE]
do

    local bytepack_readFloatBE = bytepack.readFloatBE
    local bytepack_writeFloatBE = bytepack.writeFloatBE

    --- [SHARED AND MENU]
    ---
    --- Reads single precision (4-byte, 32 bit) floating point number from big endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return number value The floating point number.
    ---@nodiscard
    function pack.readFloatBE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readFloatBE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes single precision (4-byte, 32 bit) floating point number as big endian bytes.
    ---
    ---@param value number The floating point number.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeFloatBE( value )
        return string_char( bytepack_writeFloatBE( value ) )
    end

end

-- Float [LE]
do

    local bytepack_readFloatLE = bytepack.readFloatLE
    local bytepack_writeFloatLE = bytepack.writeFloatLE

    --- [SHARED AND MENU]
    ---
    --- Reads single precision (4-byte, 32 bit) floating point number from little endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return number value The floating point number.
    ---@nodiscard
    function pack.readFloatLE( str, index )
        if index == nil then
            index = 1
        end

        if index + 3 > string_len( str ) then
            error( EndOfFileError( index - 1, 4 ), 2 )
        end

        return bytepack_readFloatLE( string_byte( str, index, index + 3 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes single precision (4-byte, 32 bit) floating point number as little endian bytes.
    ---
    ---@param value number The floating point number.
    ---@return string data The 4-byte string.
    ---@nodiscard
    function pack.writeFloatLE( value )
        return string_char( bytepack_writeFloatLE( value ) )
    end

end

-- Double [BE]
do

    local bytepack_readDoubleBE = bytepack.readDoubleBE
    local bytepack_writeDoubleBE = bytepack.writeDoubleBE

    --- [SHARED AND MENU]
    ---
    --- Reads double precision (8-byte, 64 bit) floating point number from big endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return number value The floating point number.
    ---@nodiscard
    function pack.readDoubleBE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readDoubleBE( string_byte( str, index, index + 7 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes double precision (8-byte, 64 bit) floating point number as big endian bytes.
    ---
    ---@param value number The floating point number.
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeDoubleBE( value )
        return string_char( bytepack_writeDoubleBE( value ) )
    end

end

-- Double [LE]
do

    local bytepack_readDoubleLE = bytepack.readDoubleLE
    local bytepack_writeDoubleLE = bytepack.writeDoubleLE

    --- [SHARED AND MENU]
    ---
    --- Reads double precision (8-byte, 64 bit) floating point number from little endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return number value The floating point number.
    ---@nodiscard
    function pack.readDoubleLE( str, index )
        if index == nil then
            index = 1
        end

        if index + 7 > string_len( str ) then
            error( EndOfFileError( index - 1, 8 ), 2 )
        end

        return bytepack_readDoubleLE( string_byte( str, index, index + 7 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes double precision (8-byte, 64 bit) floating point number as little endian bytes.
    ---
    ---@param value number The floating point number.
    ---@return string data The 8-byte string.
    ---@nodiscard
    function pack.writeDoubleLE( value )
        return string_char( bytepack_writeDoubleLE( value ) )
    end

end

-- Time & Date [BE/LE]
do

    local bytepack_readTime, bytepack_writeTime = bytepack.readTime, bytepack.writeTime
    local bytepack_readDate, bytepack_writeDate = bytepack.readDate, bytepack.writeDate

    local bytepack_readUInt16BE, bytepack_writeUInt16BE = bytepack.readUInt16BE, bytepack.writeUInt16BE
    local bytepack_readUInt16LE, bytepack_writeUInt16LE = bytepack.readUInt16LE, bytepack.writeUInt16LE

    --- [SHARED AND MENU]
    ---
    --- Reads 2-byte (16 bit) DOS time from big endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer hours The number of hours.
    ---@return integer minutes The number of minutes.
    ---@return integer seconds The number of seconds, **will be rounded**.
    ---@nodiscard
    function pack.readTimeBE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readTime( bytepack_readUInt16BE( string_byte( str, index, index + 1 ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads 2-byte (16 bit) DOS time from little endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer hours The number of hours.
    ---@return integer minutes The number of minutes.
    ---@return integer seconds The number of seconds, **will be rounded**.
    ---@nodiscard
    function pack.readTimeLE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readTime( bytepack_readUInt16LE( string_byte( str, index, index + 1 ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes 2-byte (16 bit) DOS time as big endian bytes.
    ---
    ---@param hours? integer The number of hours.
    ---@param minutes? integer The number of minutes.
    ---@param seconds? integer The number of seconds, **will be rounded**.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeTimeBE( hours, minutes, seconds )
        return string_char( bytepack_writeUInt16BE( bytepack_writeTime( hours, minutes, seconds ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes 2-byte (16 bit) DOS time as little endian bytes.
    ---
    ---@param hours? integer The number of hours.
    ---@param minutes? integer The number of minutes.
    ---@param seconds? integer The number of seconds, **will be rounded**.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeTimeLE( hours, minutes, seconds )
        return string_char( bytepack_writeUInt16LE( bytepack_writeTime( hours, minutes, seconds ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads 2-byte (16 bit) DOS date from big endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer day The day.
    ---@return integer month The month.
    ---@return integer year The year.
    ---@nodiscard
    function pack.readDateBE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readDate( bytepack_readUInt16BE( string_byte( str, index, index + 1 ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads 2-byte (16 bit) DOS date from little endian bytes of the string.
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte (`1`-based), `1` by default.
    ---@return integer day The day.
    ---@return integer month The month.
    ---@return integer year The year.
    ---@nodiscard
    function pack.readDateLE( str, index )
        if index == nil then
            index = 1
        end

        if index + 1 > string_len( str ) then
            error( EndOfFileError( index - 1, 2 ), 2 )
        end

        return bytepack_readDate( bytepack_readUInt16LE( string_byte( str, index, index + 1 ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes 2-byte (16 bit) DOS date as big endian bytes.
    ---
    ---@param day? integer The day.
    ---@param month? integer The month.
    ---@param year? integer The year.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeDateBE( day, month, year )
        return string_char( bytepack_writeUInt16BE( bytepack_writeDate( day, month, year ) ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes 2-byte (16 bit) DOS date as little endian bytes.
    ---
    ---@param day? integer The day.
    ---@param month? integer The month.
    ---@param year? integer The year.
    ---@return string data The 2-byte string.
    ---@nodiscard
    function pack.writeDateLE( day, month, year )
        return string_char( bytepack_writeUInt16LE( bytepack_writeDate( day, month, year ) ) )
    end

end

--- [SHARED AND MENU]
---
--- Reads the string of a fixed size.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@param length? integer The size of the string in bytes, the rest of the data by default.
---@return string data The string.
---@nodiscard
function pack.readFixedString( str, index, length )
    if index == nil then
        index = 1
    end

    local str_length = string_len( str )

    if length == nil then
        length = str_length - index + 1

        if length < 0 then
            error( EndOfFileError( index - 1, 0 ), 2 )
        end
    elseif (index + length - 1) > str_length then
        error( EndOfFileError( index - 1, length ), 2 )
    end

    if index == 1 and length == str_length then
        return str
    end

    return string_sub( str, index, index + length - 1 )
end

--- [SHARED AND MENU]
---
--- Writes the string of a fixed size,
--- shorter data is padded with `\0` and longer data is cut.
---
--- ```
--- writeFixedString( "abc", 5 ) --> "abc\0\0"
--- writeFixedString( "abcdef", 5 ) --> "abcde"
--- ```
---
---@param data string The string to write.
---@param length integer The size of the string in bytes.
---@return string data The `length`-byte string.
---@nodiscard
function pack.writeFixedString( data, length )
    local data_length = string_len( data )
    if data_length == length then
        return data
    elseif data_length > length then
        return string_sub( data, 1, length )
    end

    return data .. string_rep( "\0", length - data_length )
end

---@param str string
---@param index integer
---@param terminator integer
---@param stack_level integer
---@return string data
---@return integer data_length
---@return boolean terminated
local function readTerminated( str, index, terminator, stack_level )
    local str_length = string_len( str )
    if index > str_length then
        error( EndOfFileError( index - 1, 1 ), stack_level + 1 )
    end

    local terminator_index = string_find( str, string_char( terminator ), index, true )
    if terminator_index == nil then
        return string_sub( str, index, str_length ), str_length - index + 1, false
    end

    return string_sub( str, index, terminator_index - 1 ), terminator_index - index + 1, true
end

---@param data string
---@param terminator integer
---@param stack_level integer
---@return string data
local function writeTerminated( data, terminator, stack_level )
    local terminator_char = string_char( terminator )

    if string_find( data, terminator_char, 1, true ) ~= nil then
        error( "data contains the terminator byte " .. terminator, stack_level + 1 )
    end

    return data .. terminator_char
end

--- [SHARED AND MENU]
---
--- Reads bytes until the `terminator` byte, or the rest of the data if there is no terminator.
---
--- ```
--- readTerminatedString( "key=value", 1, 0x3D ) --> "key", 4, true
--- ```
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@param terminator integer The terminator byte (`0` - `255`).
---@return string data The bytes before the terminator.
---@return integer data_length The number of bytes read, including the terminator if it was found.
---@return boolean terminated `true` if the terminator was found.
---@nodiscard
function pack.readTerminatedString( str, index, terminator )
    return readTerminated( str, index or 1, terminator, 1 )
end

--- [SHARED AND MENU]
---
--- Writes the string followed by the `terminator` byte.
---
--- Throws an error if the string contains the terminator.
---
---@param data string The string to write.
---@param terminator integer The terminator byte (`0` - `255`).
---@return string data The terminated string.
---@nodiscard
function pack.writeTerminatedString( data, terminator )
    return writeTerminated( data, terminator, 1 )
end

--- [SHARED AND MENU]
---
--- Reads C-style string, the null terminator (`\0`) is required.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return string data The bytes before the null terminator.
---@return integer data_length The number of bytes read, including the null terminator.
---@nodiscard
function pack.readNullTerminatedString( str, index )
    if index == nil then
        index = 1
    end

    local data, data_length, terminated = readTerminated( str, index, 0x00, 2 )
    if not terminated then
        error( EndOfFileError( index - 1 + data_length, 1 ), 2 )
    end

    return data, data_length
end

--- [SHARED AND MENU]
---
--- Writes C-style string, the string followed by the null terminator (`\0`).
---
--- Throws an error if the string contains `\0`.
---
---@param data string The string to write.
---@return string data The null terminated string.
---@nodiscard
function pack.writeNullTerminatedString( data )
    return writeTerminated( data, 0x00, 1 )
end

--- [SHARED AND MENU]
---
--- Reads the line terminated by `\n` (a trailing `\r` is removed),
--- or the rest of the data if there is no `\n`.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return string line The line without `\r\n` or `\n`.
---@return integer data_length The number of bytes read, including `\r\n` or `\n`.
---@nodiscard
function pack.readLineTerminatedString( str, index )
    local line, data_length = readTerminated( str, index or 1, 0x0A --[[ \n ]], 2 )

    if string_byte( line, -1 ) == 0x0D --[[ \r ]] then
        line = string_sub( line, 1, -2 )
    end

    return line, data_length
end

--- [SHARED AND MENU]
---
--- Writes the line, the string followed by `\n`.
---
--- Throws an error if the string contains `\n`.
---
---@param data string The string to write.
---@return string data The line.
---@nodiscard
function pack.writeLineTerminatedString( data )
    return writeTerminated( data, 0x0A --[[ \n ]], 1 )
end

-- Counted strings
do

    ---@type table<integer, fun( ... ): integer>
    local read_uint_be = {
        [ 1 ] = bytepack.readUInt8,
        [ 2 ] = bytepack.readUInt16BE,
        [ 3 ] = bytepack.readUInt24BE,
        [ 4 ] = bytepack.readUInt32BE,
        [ 5 ] = bytepack.readUInt40BE,
        [ 6 ] = bytepack.readUInt48BE,
        [ 7 ] = bytepack.readUInt56BE,
        [ 8 ] = bytepack.readUInt64BE
    }

    ---@type table<integer, fun( ... ): integer>
    local read_uint_le = {
        [ 1 ] = bytepack.readUInt8,
        [ 2 ] = bytepack.readUInt16LE,
        [ 3 ] = bytepack.readUInt24LE,
        [ 4 ] = bytepack.readUInt32LE,
        [ 5 ] = bytepack.readUInt40LE,
        [ 6 ] = bytepack.readUInt48LE,
        [ 7 ] = bytepack.readUInt56LE,
        [ 8 ] = bytepack.readUInt64LE
    }

    ---@type table<integer, fun( value: integer ): integer, ...>
    local write_uint_be = {
        [ 1 ] = bytepack.writeUInt8,
        [ 2 ] = bytepack.writeUInt16BE,
        [ 3 ] = bytepack.writeUInt24BE,
        [ 4 ] = bytepack.writeUInt32BE,
        [ 5 ] = bytepack.writeUInt40BE,
        [ 6 ] = bytepack.writeUInt48BE,
        [ 7 ] = bytepack.writeUInt56BE,
        [ 8 ] = bytepack.writeUInt64BE
    }

    ---@type table<integer, fun( value: integer ): integer, ...>
    local write_uint_le = {
        [ 1 ] = bytepack.writeUInt8,
        [ 2 ] = bytepack.writeUInt16LE,
        [ 3 ] = bytepack.writeUInt24LE,
        [ 4 ] = bytepack.writeUInt32LE,
        [ 5 ] = bytepack.writeUInt40LE,
        [ 6 ] = bytepack.writeUInt48LE,
        [ 7 ] = bytepack.writeUInt56LE,
        [ 8 ] = bytepack.writeUInt64LE
    }

    --- [SHARED AND MENU]
    ---
    --- Reads the string prefixed with its length.
    ---
    --- ```
    --- readCountedString( "\3abc", 1, 1 ) --> "abc", 4
    --- ```
    ---
    ---@param str string The string to read from.
    ---@param index? integer The index of the first byte of the length (`1`-based), `1` by default.
    ---@param length_size integer The size of the length in bytes (`1` - `8`).
    ---@param is_little_endian? boolean `true` if the length is little endian, `false` by default.
    ---@return string data The string.
    ---@return integer data_length The number of bytes read, including the length.
    ---@nodiscard
    function pack.readCountedString( str, index, length_size, is_little_endian )
        if index == nil then
            index = 1
        end

        local str_length = string_len( str )

        local data_index = index + length_size
        if (data_index - 1) > str_length then
            error( EndOfFileError( index - 1, length_size ), 2 )
        end

        local length = (is_little_endian and read_uint_le or read_uint_be)[ length_size ]( string_byte( str, index, data_index - 1 ) )
        if (data_index + length - 1) > str_length then
            error( EndOfFileError( data_index - 1, length ), 2 )
        end

        return string_sub( str, data_index, data_index + length - 1 ), length_size + length
    end

    --- [SHARED AND MENU]
    ---
    --- Writes the string prefixed with its length.
    ---
    --- Throws an error if the string is too long for the length size.
    ---
    --- ```
    --- writeCountedString( "abc", 1 ) --> "\3abc"
    --- ```
    ---
    ---@param data string The string to write.
    ---@param length_size integer The size of the length in bytes (`1` - `8`).
    ---@param is_little_endian? boolean `true` to write the length as little endian, `false` by default.
    ---@return string data The counted string.
    ---@nodiscard
    function pack.writeCountedString( data, length_size, is_little_endian )
        local data_length = string_len( data )

        if length_size < 7 and data_length >= (2 ^ (length_size * 8)) then
            error( "data is too long for the " .. length_size .. "-byte length: " .. data_length .. " bytes", 2 )
        end

        return string_char( (is_little_endian and write_uint_le or write_uint_be)[ length_size ]( data_length ) ) .. data
    end

end

-- Bit reading
do

    local math_ceil = std.math.ceil

    ---@type table<integer, fun( ... ): integer>
    local read_uint_be = {
        [ 2 ] = bytepack.readUInt16BE,
        [ 3 ] = bytepack.readUInt24BE,
        [ 4 ] = bytepack.readUInt32BE,
        [ 5 ] = bytepack.readUInt40BE,
        [ 6 ] = bytepack.readUInt48BE,
        [ 7 ] = bytepack.readUInt56BE,
        [ 8 ] = bytepack.readUInt64BE
    }

    ---@type table<integer, fun( ... ): integer>
    local read_uint_le = {
        [ 2 ] = bytepack.readUInt16LE,
        [ 3 ] = bytepack.readUInt24LE,
        [ 4 ] = bytepack.readUInt32LE,
        [ 5 ] = bytepack.readUInt40LE,
        [ 6 ] = bytepack.readUInt48LE,
        [ 7 ] = bytepack.readUInt56LE,
        [ 8 ] = bytepack.readUInt64LE
    }

    ---@param str string
    ---@param bit_position integer
    ---@param stack_level integer
    ---@return 0 | 1
    local function readBit( str, bit_position, stack_level )
        if bit_position >= (string_len( str ) * 8) then
            error( EndOfFileError( rbit_rshift( bit_position, 3 ), 1 ), stack_level + 1 )
        end

        return rbit_band(
            rbit_rshift(
                string_byte( str, rbit_rshift( bit_position, 3 ) + 1 ),
                rbit_band( bit_position, 7 )
            ), 1 )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads one bit from the string.
    ---
    --- ```
    --- readBit( "\5", 2 ) --> 1
    --- ```
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the bit (`0`-based), `0` by default.
    ---@return 0 | 1 value The bit.
    ---@nodiscard
    function pack.readBit( str, bit_position )
        return readBit( str, bit_position or 0, 1 )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads one bit from the string as a boolean, same as `net.ReadBool`.
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the bit (`0`-based), `0` by default.
    ---@return boolean value `true` if the bit is `1`.
    ---@nodiscard
    function pack.readBoolean( str, bit_position )
        return readBit( str, bit_position or 0, 2 ) == 1
    end

    pack.readBool = pack.readBoolean

    --- Reads 8 bits as a byte, no bounds checks.
    ---
    ---@param str string
    ---@param bit_position integer
    ---@return integer
    local function readByte( str, bit_position )
        local byte_index = rbit_rshift( bit_position, 3 ) + 1
        local bit_offset = rbit_band( bit_position, 7 )

        if bit_offset == 0 then
            return string_byte( str, byte_index, byte_index )
        end

        -- unaligned: the byte straddles two source bytes (the second one is guaranteed by the caller)
        local low, high = string_byte( str, byte_index, byte_index + 1 )

        return rbit_band(
            rbit_bor(
                rbit_rshift( low, bit_offset ),
                rbit_lshift( high, 8 - bit_offset )
            ), 0xFF )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads bytes from any bit position of the string.
    ---
    --- ```
    --- readBytes( "\16\32", 4, 1 ) --> 0x01
    --- ```
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the first bit (`0`-based), `0` by default.
    ---@param byte_count integer The number of bytes to read.
    ---@return integer ... The bytes.
    ---@nodiscard
    function pack.readBytes( str, bit_position, byte_count )
        if byte_count < 1 then
            return
        end

        if bit_position == nil then
            bit_position = 0
        end

        local available = (string_len( str ) * 8) - bit_position
        if available < (byte_count * 8) then
            error( EndOfFileError( rbit_rshift( bit_position, 3 ), byte_count ), 2 )
        end

        if byte_count == 1 then
            return readByte( str, bit_position )
        end

        local byte_index = rbit_rshift( bit_position, 3 ) + 1
        local bit_offset = rbit_band( bit_position, 7 )

        if bit_offset == 0 then
            return string_byte( str, byte_index, byte_index + byte_count - 1 )
        end

        -- unaligned: every output byte straddles two source bytes,
        -- so `byte_count + 1` source bytes are needed (guaranteed by the check above)
        local source = { string_byte( str, byte_index, byte_index + byte_count ) }
        local inverse_offset = 8 - bit_offset

        ---@type integer[]
        local bytes = {}

        for i = 1, byte_count, 1 do
            bytes[ i ] = rbit_band(
                rbit_bor(
                    rbit_rshift( source[ i ], bit_offset ),
                    rbit_lshift( source[ i + 1 ], inverse_offset )
                ), 0xFF )
        end

        return table_unpack( bytes, 1, byte_count )
    end

    --- Reads `bit_count` bits as a little endian unsigned integer, exact up to 53 bits, no bounds checks.
    ---
    ---@param str string
    ---@param bit_position integer
    ---@param bit_count integer
    ---@return integer
    local function readBitsLE( str, bit_position, bit_count )
        local bit_offset = rbit_band( bit_position, 7 )
        local first_index = rbit_rshift( bit_position, 3 ) + 1

        local last_bit = (bit_position + bit_count) - 1
        local last_index = rbit_rshift( last_bit, 3 ) + 1

        -- drop the unused high bits of the last byte, so the value never exceeds `2 ^ bit_count`
        local value = rbit_band(
            string_byte( str, last_index ),
            rbit_rshift( 0xFF, 7 - rbit_band( last_bit, 7 ) )
        )

        if first_index == last_index then
            return rbit_rshift( value, bit_offset )
        end

        for index = last_index - 1, first_index + 1, -1 do
            value = (value * 0x100) + string_byte( str, index, index )
        end

        -- and the unused low bits of the first byte
        return (value * (2 ^ (8 - bit_offset))) + rbit_rshift( string_byte( str, first_index, first_index ), bit_offset )
    end

    ---@param str string
    ---@param bit_position integer
    ---@param bit_count integer
    ---@param is_little_endian boolean
    ---@param stack_level integer
    ---@return integer
    local function readUInt( str, bit_position, bit_count, is_little_endian, stack_level )
        if bit_count < 1 then
            return 0
        elseif bit_count > 64 then
            error( "unsupported bit count: " .. bit_count .. " (max 64)", stack_level + 1 )
        elseif bit_count == 1 then
            return readBit( str, bit_position, stack_level ) -- tail call
        end

        if (bit_position + bit_count) > (string_len( str ) * 8) then
            error( EndOfFileError( rbit_rshift( bit_position, 3 ), math_ceil( bit_count / 8 ) ), stack_level + 1 )
        end

        local full_bytes = rbit_rshift( bit_count, 3 )
        local remaining_bits = rbit_band( bit_count, 7 )

        if remaining_bits == 0 and rbit_band( bit_position, 7 ) == 0 then
            local byte_index = rbit_rshift( bit_position, 3 ) + 1

            if full_bytes == 1 then
                return string_byte( str, byte_index, byte_index )
            end

            return (is_little_endian and read_uint_le or read_uint_be)[ full_bytes ]( string_byte( str, byte_index, (byte_index + full_bytes) - 1 ) )
        end

        if is_little_endian then
            -- bit `k` of the value is bit `bit_position + k` of the data (gmod `net.ReadUInt`)
            if bit_count > 53 then
                -- split to keep the intermediate value exact
                return (readBitsLE( str, bit_position + 32, bit_count - 32 ) * 0x100000000) + readBitsLE( str, bit_position, 32 )
            end

            return readBitsLE( str, bit_position, bit_count )
        end

        -- big endian: the partial (most significant) chunk goes first, then whole bytes from most to least significant
        ---@type integer
        local value = 0

        if remaining_bits ~= 0 then
            value = readBitsLE( str, bit_position, remaining_bits )
            bit_position = bit_position + remaining_bits
        end

        for _ = 1, full_bytes, 1 do
            value = value * 0x100 + readByte( str, bit_position )
            bit_position = bit_position + 8
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned integer of any size from any bit position of the string.
    ---
    --- Little endian integers are read lowest bit first, same as `net.ReadUInt`.
    ---
    --- Big endian integers are read as the highest `bit_count % 8` bits first,
    --- then whole bytes from the most significant to the least significant.
    ---
    --- Valid values without loss of precision: `0` - `9007199254740991` (53 bits)
    ---
    --- ```
    --- readUInt( "\44\1", 0, 16, true ) --> 300
    --- readUInt( "\5", 1, 2, true ) --> 2
    --- ```
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the first bit (`0`-based), `0` by default.
    ---@param bit_count integer The size of the integer in bits (`1` - `64`).
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return integer value The unsigned integer.
    ---@nodiscard
    function pack.readUInt( str, bit_position, bit_count, is_little_endian )
        return readUInt( str, bit_position or 0, bit_count, is_little_endian == true, 1 )
    end

    ---@param str string
    ---@param bit_position integer
    ---@param bit_count integer
    ---@param is_little_endian boolean
    ---@param stack_level integer
    ---@return integer
    local function readInt( str, bit_position, bit_count, is_little_endian, stack_level )
        local value = readUInt( str, bit_position, bit_count, is_little_endian, stack_level + 1 )
        if value < (2 ^ (bit_count - 1)) then
            return value
        end

        return value - (2 ^ bit_count)
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed (two's complement) integer of any size from any bit position of the string.
    ---
    --- Byte order is the same as in `readUInt`.
    ---
    --- Valid values without loss of precision: `-9007199254740991` - `9007199254740991` (53 bits)
    ---
    --- ```
    --- readInt( "\255\255", 0, 16, true ) --> -1
    --- ```
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the first bit (`0`-based), `0` by default.
    ---@param bit_count integer The size of the integer in bits (`1` - `64`).
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return integer value The signed integer.
    ---@nodiscard
    function pack.readInt( str, bit_position, bit_count, is_little_endian )
        return readInt( str, bit_position or 0, bit_count, is_little_endian == true, 1 )
    end

    local bytepack_readFixedPoint = bytepack.readFixedPoint

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned fixed-point number (`m` integer bits and `n` fractional bits) from any bit position of the string.
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the first bit (`0`-based), `0` by default.
    ---@param m integer The number of integer bits.
    ---@param n integer The number of fractional bits.
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return number value The unsigned fixed-point number.
    ---@nodiscard
    function pack.readUnsignedFixedPoint( str, bit_position, m, n, is_little_endian )
        return bytepack_readFixedPoint( n, readUInt( str, bit_position or 0, m + n, is_little_endian == true, 2 ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed fixed-point number (`m` integer bits including the sign bit and `n` fractional bits)
    --- from any bit position of the string.
    ---
    ---@param str string The string to read from.
    ---@param bit_position? integer The position of the first bit (`0`-based), `0` by default.
    ---@param m integer The number of integer bits, including the sign bit.
    ---@param n integer The number of fractional bits.
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return number value The signed fixed-point number.
    ---@nodiscard
    function pack.readFixedPoint( str, bit_position, m, n, is_little_endian )
        return bytepack_readFixedPoint( n, readInt( str, bit_position or 0, m + n, is_little_endian == true, 2 ) )
    end

end
