---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local math = std.math
local math_ceil, math_min = math.ceil, math.min

local table = std.table
local table_concat, table_unpack = table.concat, table.unpack

local string = std.string
local string_format = string.format
local string_len, string_sub = string.len, string.sub
local string_char, string_byte = string.char, string.byte

local rbit = raw.bit
local rbit_band, rbit_bor = rbit.band, rbit.bor
local rbit_lshift, rbit_rshift = rbit.lshift, rbit.rshift

local class = std.class
local bytepack = std.bytepack

local pack = std.pack
local pack_readBit = pack.readBit
local pack_readInt = pack.readInt
local pack_readUInt = pack.readUInt
local pack_readBytes = pack.readBytes
local pack_readTerminatedString = pack.readTerminatedString

local error = std.error
local ffi = std.ffi

local tostring = std.tostring
local EndOfFileError = std.EndOfFileError


---@type integer
local CHUNK_SIZE = 4096

--- [SHARED AND MENU]
---
--- A cursor over an immutable binary string, reads values one after another from any bit position.
---
--- The cursor (`position`) is counted in bits from `0`, so fields don't have to be aligned to bytes,
--- methods that take `as_bytes` count in bytes instead.
---
--- Bits are read LSB-first, same as `pack` and Source's `bf_read`,
--- so data written by `BinaryWriter` or gmod `net.Write*` can be read back:
---
--- ```
--- local reader = BinaryReader( "\5\44\1" )
---
--- reader:readBit() --> 1
--- reader:readUInt( 7, true ) --> 2
--- reader:readUInt( 16, true ) --> 300
--- reader:isEndOfFile() --> true
--- ```
---
--- Multi-byte values are big endian by default, `is_little_endian` switches them to little endian,
--- see `pack.readUInt` for the exact bit layout of both.
---
--- All reads throw `EndOfFileError` when there is not enough data left,
--- the cursor is not moved in that case.
---
---@class dreamwork.std.BinaryReader : dreamwork.std.Object
---@field __class dreamwork.std.BinaryReaderClass
---@field position integer The cursor position in bits.
---@field data string The binary data.
---@field data_length integer The size of the data in bits.
---@operator len: integer
---@operator concat( any ): string
local BinaryReader = class.base( "BinaryReader", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `BinaryReader` instances.
---
--- Any value is converted to a string with `tostring`, so `BinaryReader( writer )` reads what the `BinaryWriter` wrote.
---
---@class dreamwork.std.BinaryReaderClass : dreamwork.std.BinaryReader
---@field __base dreamwork.std.BinaryReader
---@overload fun( data: any ): dreamwork.std.BinaryReader
local BinaryReaderClass = class.create( BinaryReader )
std.BinaryReader = BinaryReaderClass

---@return string
---@nodiscard
---@protected
function BinaryReader:__tostring()
    return self.data
end

---@return string
---@nodiscard
---@protected
function BinaryReader.__concat( a, b )
    if debug_getmetatable( a ) == BinaryReader then
        return a.data .. tostring( b )
    end

    return tostring( a ) .. b.data
end

---@return string
---@nodiscard
---@protected
function BinaryReader:__represent()
    return string_format( "BinaryReader: %p [%.3f/%d]", self, self.position * 0.125, rbit_rshift( self.data_length, 3 ) )
end

---@return integer
---@nodiscard
---@protected
function BinaryReader:__len()
    return rbit_rshift( self.data_length, 3 )
end

---@param data any
---@protected
function BinaryReader:__init( data )
    self:open( data )
end

--- [SHARED AND MENU]
---
--- Replaces the data of the reader and moves the cursor to the start.
---
---@param data any The data, converted to a string with `tostring`.
function BinaryReader:open( data )
    local str = tostring( data )
    self.data_length = string_len( str ) * 8
    self.position = 0
    self.data = str
end

--- Moves the cursor forward by `bit_count` bits, or throws `EndOfFileError` without moving it.
---
---@param reader dreamwork.std.BinaryReader
---@param bit_count integer
---@param stack_level integer
---@return integer position The position before the move.
local function advance( reader, bit_count, stack_level )
    local position = reader.position

    local new_position = position + bit_count
    if new_position > reader.data_length then
        error( EndOfFileError( rbit_rshift( position, 3 ), math_ceil( bit_count / 8 ) ), stack_level + 1 )
    end

    reader.position = new_position
    return position
end

---@param bytes integer[]
---@param byte_count integer
---@return string
local function bytesToString( bytes, byte_count )
    if byte_count <= CHUNK_SIZE then
        return string_char( table_unpack( bytes, 1, byte_count ) )
    end

    ---@type string[]
    local chunks = {}

    ---@type integer
    local chunk_count = 0

    for index = 1, byte_count, CHUNK_SIZE do
        chunk_count = chunk_count + 1
        chunks[ chunk_count ] = string_char( table_unpack( bytes, index, math_min( index + CHUNK_SIZE - 1, byte_count ) ) )
    end

    return table_concat( chunks, "", 1, chunk_count )
end

--- Reused output of `readUnaligned` for `readBytes`.
---
---@type integer[]
local buffer = {}

--- Shifts `byte_count` bytes from an unaligned `position` into `target` (`1`-indexed),
--- every source byte is read once and carried to the next output byte.
---
---@param target integer[] | ffi.cdata*
---@param data string
---@param position integer
---@param byte_count integer
local function readUnaligned( target, data, position, byte_count )
    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )
    local inverse_offset = 8 - bit_offset

    local low = string_byte( data, index, index )

    -- 4 source bytes per `string.byte` call, numeric `for` loops trace on their own (`while` here got blacklisted)
    local block_end = byte_count - (byte_count % 4)

    for i = 1, block_end, 4 do
        local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( data, index + i, index + i + 3 )

        target[ i ] = rbit_band( rbit_bor( rbit_rshift( low, bit_offset ), rbit_lshift( uint8_1, inverse_offset ) ), 0xFF )
        target[ i + 1 ] = rbit_band( rbit_bor( rbit_rshift( uint8_1, bit_offset ), rbit_lshift( uint8_2, inverse_offset ) ), 0xFF )
        target[ i + 2 ] = rbit_band( rbit_bor( rbit_rshift( uint8_2, bit_offset ), rbit_lshift( uint8_3, inverse_offset ) ), 0xFF )
        target[ i + 3 ] = rbit_band( rbit_bor( rbit_rshift( uint8_3, bit_offset ), rbit_lshift( uint8_4, inverse_offset ) ), 0xFF )

        low = uint8_4
    end

    for i = block_end + 1, byte_count, 1 do
        local high = string_byte( data, index + i, index + i )
        target[ i ] = rbit_band( rbit_bor( rbit_rshift( low, bit_offset ), rbit_lshift( high, inverse_offset ) ), 0xFF )
        low = high
    end
end

---@type fun( data: string, position: integer, byte_count: integer ): string
local readUnalignedString

if ffi == nil then

    function readUnalignedString( data, position, byte_count )
        readUnaligned( buffer, data, position, byte_count )
        return string_char( table_unpack( buffer, 1, byte_count ) )
    end

else

    local ffi_string = ffi.string

    -- one extra byte, so indices are `1`-based as in a table
    local output = ffi.new( "uint8_t[?]", CHUNK_SIZE + 1 )

    function readUnalignedString( data, position, byte_count )
        readUnaligned( output, data, position, byte_count )
        return ffi_string( output + 1, byte_count )
    end

end

---@param data string
---@param position integer
---@param byte_count integer
---@return string
local function readString( data, position, byte_count )
    if rbit_band( position, 7 ) == 0 then
        local byte_index = rbit_rshift( position, 3 )
        if byte_index == 0 and byte_count == string_len( data ) then
            return data
        end

        return string_sub( data, byte_index + 1, byte_index + byte_count )
    end

    if byte_count <= CHUNK_SIZE then
        return readUnalignedString( data, position, byte_count )
    end

    ---@type string[]
    local chunks = {}

    ---@type integer
    local chunk_count = 0

    repeat
        local chunk_size = math_min( byte_count, CHUNK_SIZE )
        chunk_count = chunk_count + 1
        chunks[ chunk_count ] = readUnalignedString( data, position, chunk_size )

        position = position + chunk_size * 8
        byte_count = byte_count - chunk_size
    until byte_count == 0

    return table_concat( chunks, "", 1, chunk_count )
end

--- [SHARED AND MENU]
---
--- Moves the cursor to the absolute position, clamped to the data.
---
--- ```
--- reader:seek() --> 0, the start
--- reader:seek( 4, true ) --> 32, the 5th byte
--- reader:seek( -1, true ) --> the last byte
--- ```
---
---@param position? integer The new position, negative positions count back from the end, `0` by default.
---@param as_bytes? boolean `true` if `position` is in bytes, `false` (bits) by default.
---@return integer position The new position in bits.
function BinaryReader:seek( position, as_bytes )
    if position == nil then
        position = 0
    elseif as_bytes then
        position = position * 8
    end

    local data_length = self.data_length

    if position < 0 then
        position = data_length + position

        if position < 0 then
            position = 0
        end
    elseif position > data_length then
        position = data_length
    end

    self.position = position
    return position
end

--- [SHARED AND MENU]
---
--- Returns the cursor position.
---
---@param as_bytes? boolean `true` to return the number of whole bytes before the cursor, `false` (bits) by default.
---@return integer position The cursor position.
---@nodiscard
function BinaryReader:tell( as_bytes )
    if as_bytes then
        return rbit_rshift( self.position, 3 )
    end

    return self.position
end

--- [SHARED AND MENU]
---
--- Returns the size of the data.
---
---@param as_bytes? boolean `true` to return the size in bytes, `false` (bits) by default.
---@return integer size The size of the data.
---@nodiscard
function BinaryReader:size( as_bytes )
    if as_bytes then
        return rbit_rshift( self.data_length, 3 )
    end

    return self.data_length
end

--- [SHARED AND MENU]
---
--- Moves the cursor relative to its position, clamped to the data.
---
---@param length? integer The distance to move, negative to move back, `1` by default.
---@param as_bytes? boolean `true` if `length` is in bytes, `false` (bits) by default.
---@return integer position The new position in bits.
function BinaryReader:skip( length, as_bytes )
    if length == nil then
        length = 1
    elseif as_bytes then
        length = length * 8
    end

    local position = self.position + length

    if position < 0 then
        position = 0
    elseif position > self.data_length then
        position = self.data_length
    end

    self.position = position
    return position
end

--- [SHARED AND MENU]
---
--- Moves the cursor forward to the next multiple of `bit_boundary`, clamped to the data.
---
--- ```
--- reader:seek( 3 )
--- reader:align() --> 8
--- ```
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return integer position The new position in bits.
function BinaryReader:align( bit_boundary )
    local position = self.position

    local remainder = position % (bit_boundary or 8)
    if remainder == 0 then
        return position
    end

    position = math_min( position + ((bit_boundary or 8) - remainder), self.data_length )
    self.position = position
    return position
end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at a multiple of `bit_boundary`.
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return boolean is_aligned `true` if the cursor is aligned.
---@nodiscard
function BinaryReader:isAligned( bit_boundary )
    return (self.position % (bit_boundary or 8)) == 0
end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at the end of the data.
---
---@return boolean is_eof `true` if there is nothing left to read.
---@nodiscard
function BinaryReader:isEndOfFile()
    return self.position >= self.data_length
end

--- [SHARED AND MENU]
---
--- Returns the size of the data after the cursor.
---
---@param as_bytes? boolean `true` to return the number of whole bytes left, `false` (bits) by default.
---@return integer remaining The size of the data left to read.
---@nodiscard
function BinaryReader:remaining( as_bytes )
    local bits_left = self.data_length - self.position

    if as_bytes then
        return rbit_rshift( bits_left, 3 )
    end

    return bits_left
end

--- [SHARED AND MENU]
---
--- Reads one bit.
---
---@return 0 | 1 value The bit.
---@nodiscard
function BinaryReader:readBit()
    return pack_readBit( self.data, advance( self, 1, 2 ) )
end

--- [SHARED AND MENU]
---
--- Reads one bit as a boolean, same as `net.ReadBool`.
---
---@return boolean value `true` if the bit is `1`.
---@nodiscard
function BinaryReader:readBoolean()
    return pack_readBit( self.data, advance( self, 1, 2 ) ) == 1
end

--- [SHARED AND MENU]
---
--- Reads unsigned integer of any size, see `pack.readUInt`.
---
--- #### Unsigned Integers limits for bit count
--- | Bit count | Max Value (`2^n - 1`)      |
--- |:----------|:---------------------------|
--- | 1         | 1                          |
--- | 2         | 3                          |
--- | 3         | 7                          |
--- | 4         | 15                         |
--- | 5         | 31                         |
--- | 6         | 63                         |
--- | 7         | 127                        |
--- | 8         | 255                        |
--- | 9         | 511                        |
--- | 10        | 1,023                      |
--- | 11        | 2,047                      |
--- | 12        | 4,095                      |
--- | 13        | 8,191                      |
--- | 14        | 16,383                     |
--- | 15        | 32,767                     |
--- | 16        | 65,535                     |
--- | 17        | 131,071                    |
--- | 18        | 262,143                    |
--- | 19        | 524,287                    |
--- | 20        | 1,048,575                  |
--- | 21        | 2,097,151                  |
--- | 22        | 4,194,303                  |
--- | 23        | 8,388,607                  |
--- | 24        | 16,777,215                 |
--- | 25        | 33,554,431                 |
--- | 26        | 67,108,863                 |
--- | 27        | 134,217,727                |
--- | 28        | 268,435,455                |
--- | 29        | 536,870,911                |
--- | 30        | 1,073,741,823              |
--- | 31        | 2,147,483,647              |
--- | 32        | 4,294,967,295              |
--- | 40        | 1,099,511,627,775          |
--- | 48        | 281,474,976,710,655        |
--- | 64        | 18,446,744,073,709,551,615 |
---
--- Valid values without loss of precision: `0` - `9007199254740991` (53 bits),
--- all values above will have problems when working with them.
---
--- ```
--- reader:readUInt( 8 ) -- byte
--- reader:readUInt( 32, true ) -- same as `net.ReadUInt( 32 )`
--- ```
---
---@param bit_count integer The size of the integer in bits (`1` - `64`), `0` reads nothing and returns `0`.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
---@return integer value The unsigned integer.
---@nodiscard
function BinaryReader:readUInt( bit_count, is_little_endian )
    if bit_count > 64 then
        error( "unsupported bit count: " .. bit_count .. " (max 64)", 2 )
    elseif bit_count < 1 then
        return 0
    end

    return pack_readUInt( self.data, advance( self, bit_count, 2 ), bit_count, is_little_endian )
end

--- [SHARED AND MENU]
---
--- Reads signed (two's complement) integer of any size, see `pack.readInt`.
---
--- #### Signed Integers limits for bit count
--- | Bit count | Min Value (`-2^(n-1)`)     | Max Value (`2^(n-1) - 1`) |
--- |:----------|:---------------------------|:--------------------------|
--- | 1         | -1                         | 0                         |
--- | 2         | -2                         | 1                         |
--- | 3         | -4                         | 3                         |
--- | 4         | -8                         | 7                         |
--- | 5         | -16                        | 15                        |
--- | 6         | -32                        | 31                        |
--- | 7         | -64                        | 63                        |
--- | 8         | -128                       | 127                       |
--- | 9         | -256                       | 255                       |
--- | 10        | -512                       | 511                       |
--- | 11        | -1,024                     | 1,023                     |
--- | 12        | -2,048                     | 2,047                     |
--- | 13        | -4,096                     | 4,095                     |
--- | 14        | -8,192                     | 8,191                     |
--- | 15        | -16,384                    | 16,383                    |
--- | 16        | -32,768                    | 32,767                    |
--- | 17        | -65,536                    | 65,535                    |
--- | 18        | -131,072                   | 131,071                   |
--- | 19        | -262,144                   | 262,143                   |
--- | 20        | -524,288                   | 524,287                   |
--- | 21        | -1,048,576                 | 1,048,575                 |
--- | 22        | -2,097,152                 | 2,097,151                 |
--- | 23        | -4,194,304                 | 4,194,303                 |
--- | 24        | -8,388,608                 | 8,388,607                 |
--- | 25        | -16,777,216                | 16,777,215                |
--- | 26        | -33,554,432                | 33,554,431                |
--- | 27        | -67,108,864                | 67,108,863                |
--- | 28        | -134,217,728               | 134,217,727               |
--- | 29        | -268,435,456               | 268,435,455               |
--- | 30        | -536,870,912               | 536,870,911               |
--- | 31        | -1,073,741,824             | 1,073,741,823             |
--- | 32        | -2,147,483,648             | 2,147,483,647             |
--- | 40        | -549,755,813,888           | 549,755,813,887           |
--- | 48        | -140,737,488,355,328       | 140,737,488,355,327       |
--- | 64        | -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807 |
---
--- Valid values without loss of precision: `-9007199254740991` - `9007199254740991` (53 bits),
--- all values above will have problems when working with them.
---
---@param bit_count integer The size of the integer in bits (`1` - `64`), `0` reads nothing and returns `0`.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
---@return integer value The signed integer.
---@nodiscard
function BinaryReader:readInt( bit_count, is_little_endian )
    if bit_count > 64 then
        error( "unsupported bit count: " .. bit_count .. " (max 64)", 2 )
    elseif bit_count < 1 then
        return 0
    end

    return pack_readInt( self.data, advance( self, bit_count, 2 ), bit_count, is_little_endian )
end

--- [SHARED AND MENU]
---
--- Reads bytes, the cursor doesn't have to be aligned.
---
--- Every byte is a separate return value, so use `read` for large amounts of data.
---
---@param byte_count? integer The number of bytes, all whole bytes left by default.
---@return integer ... The bytes.
---@nodiscard
function BinaryReader:readBytes( byte_count )
    if byte_count == nil then
        byte_count = rbit_rshift( self.data_length - self.position, 3 )
    end

    if byte_count < 1 then
        return
    end

    local data = self.data
    local position = advance( self, byte_count * 8, 2 )

    if byte_count > CHUNK_SIZE or rbit_band( position, 7 ) == 0 then
        return pack_readBytes( data, position, byte_count )
    end

    readUnaligned( buffer, data, position, byte_count )
    return table_unpack( buffer, 1, byte_count )
end

--- [SHARED AND MENU]
---
--- Reads bytes as a string, the cursor doesn't have to be aligned.
---
---@param byte_count? integer The number of bytes, all whole bytes left by default.
---@return string data The bytes.
---@nodiscard
function BinaryReader:read( byte_count )
    if byte_count == nil then
        byte_count = rbit_rshift( self.data_length - self.position, 3 )
    end

    if byte_count < 1 then
        return ""
    end

    return readString( self.data, advance( self, byte_count * 8, 2 ), byte_count )
end

--- [SHARED AND MENU]
---
--- Reads the string of a fixed size, same as `read`, but `byte_count` is required.
---
---@param byte_count integer The size of the string in bytes.
---@return string data The string.
---@nodiscard
function BinaryReader:readFixedString( byte_count )
    if byte_count < 1 then
        return ""
    end

    return self:read( byte_count )
end

---@param reader dreamwork.std.BinaryReader
---@param terminator integer
---@param stack_level integer
---@return string data
---@return boolean terminated
local function readTerminated( reader, terminator, stack_level )
    local position, data_length = reader.position, reader.data_length
    if position + 8 > data_length then
        error( EndOfFileError( rbit_rshift( position, 3 ), 1 ), stack_level + 1 )
    end

    local data = reader.data

    if rbit_band( position, 7 ) == 0 then
        local str, size, terminated = pack_readTerminatedString( data, rbit_rshift( position, 3 ) + 1, terminator )
        reader.position = position + size * 8
        return str, terminated
    end

    -- unaligned: the terminator can't be searched for, so shift and compare byte by byte
    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )
    local inverse_offset = 8 - bit_offset

    -- the last source byte that completes an output byte
    local last_index = rbit_rshift( data_length, 3 )

    ---@type integer[]
    local bytes = {}

    ---@type integer
    local byte_count = 0

    local low = string_byte( data, index, index )

    while index < last_index do
        index = index + 1

        local high = string_byte( data, index, index )
        local byte = rbit_band( rbit_bor( rbit_rshift( low, bit_offset ), rbit_lshift( high, inverse_offset ) ), 0xFF )
        low = high

        if byte == terminator then
            reader.position = position + (byte_count + 1) * 8
            return bytesToString( bytes, byte_count ), true
        end

        byte_count = byte_count + 1
        bytes[ byte_count ] = byte
    end

    reader.position = position + byte_count * 8
    return bytesToString( bytes, byte_count ), false
end

--- [SHARED AND MENU]
---
--- Reads bytes until the `terminator` byte, or all whole bytes left if there is no terminator.
---
--- The terminator is read too, but isn't a part of the string.
---
--- ```
--- local reader = BinaryReader( "key=value" )
--- reader:readTerminatedString( 0x3D ) --> "key", true
--- reader:readTerminatedString( 0x3D ) --> "value", false
--- ```
---
---@param terminator integer The terminator byte (`0` - `255`).
---@return string data The bytes before the terminator.
---@return boolean terminated `true` if the terminator was found.
---@nodiscard
function BinaryReader:readTerminatedString( terminator )
    return readTerminated( self, terminator, 2 )
end

--- [SHARED AND MENU]
---
--- Reads C-style string, the bytes until the null terminator (`\0`),
--- or all whole bytes left if there is no terminator, same as `net.ReadString`.
---
---@return string data The bytes before the null terminator.
---@nodiscard
function BinaryReader:readString()
    return (readTerminated( self, 0x00, 2 ))
end

--- [SHARED AND MENU]
---
--- Reads the line terminated by `\n` (a trailing `\r` is removed), or all whole bytes left if there is no `\n`.
---
---@return string line The line without `\r\n` or `\n`.
---@nodiscard
function BinaryReader:readLine()
    local line = readTerminated( self, 0x0A --[[ \n ]], 2 )

    local line_length = string_len( line )
    if line_length ~= 0 and string_byte( line, line_length, line_length ) == 0x0D --[[ \r ]] then
        return string_sub( line, 1, line_length - 1 )
    end

    return line
end

--- [SHARED AND MENU]
---
--- Reads the string prefixed with its length, written by `BinaryWriter:writeCountedString`.
---
--- Throws `EndOfFileError` if the string is cut, the cursor stays after the length in that case.
---
---@param bit_count integer The size of the length in bits (`1` - `64`).
---@param is_little_endian? boolean `true` if the length is little endian, `false` by default.
---@return string data The string.
---@return integer data_length The size of the string in bytes.
---@nodiscard
function BinaryReader:readCountedString( bit_count, is_little_endian )
    local data = self.data
    local byte_count = pack_readUInt( data, advance( self, bit_count, 2 ), bit_count, is_little_endian )
    if byte_count == 0 then
        return "", 0
    end

    return readString( data, advance( self, byte_count * 8, 2 ), byte_count ), byte_count
end

do

    local bytepack_readFixedPoint = bytepack.readFixedPoint

    --- [SHARED AND MENU]
    ---
    --- Reads unsigned fixed-point number (**UQm.n**), see `bytepack.readFixedPoint`.
    ---
    --- ### Commonly Used UQm.n Formats (**unsigned**)
    --- | Format  | Range                    | Precision (Step)         |
    --- |:--------|:-------------------------|:-------------------------|
    --- | UQ8.8   | `0` - `255.996`          | `0.00390625` (1/256)     |
    --- | UQ10.6  | `0` - `1023.984375`      | `0.015625` (1/64)        |
    --- | UQ12.4  | `0` - `4095.9375`        | `0.0625` (1/16)          |
    --- | UQ16.16 | `0` - `65535.99998`      | `0.0000152588` (1/65536) |
    --- | UQ24.8  | `0` - `16777215.996`     | `0.00390625` (1/256)     |
    --- | UQ32.16 | `0` - `4294967295.99998` | `0.0000152588` (1/65536) |
    ---
    --- `m + n` is the size of the field in bits (`1` - `64`), so the range is limited to 53 bits.
    ---
    --- ```
    --- reader:readUnsignedFixedPoint( 8, 8 ) -- UQ8.8, 16 bits
    --- ```
    ---
    ---@param m integer The number of integer bits.
    ---@param n integer The number of fractional bits.
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return number value The unsigned fixed-point number.
    ---@nodiscard
    function BinaryReader:readUnsignedFixedPoint( m, n, is_little_endian )
        local bit_count = m + n
        return bytepack_readFixedPoint( n, pack_readUInt( self.data, advance( self, bit_count, 2 ), bit_count, is_little_endian ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Reads signed fixed-point number (**Qm.n**), see `bytepack.readFixedPoint`.
    ---
    --- ### Commonly Used Qm.n Formats (**signed**)
    --- | Format | Range                                | Precision (Step)         |
    --- |:-------|:-------------------------------------|:-------------------------|
    --- | Q8.8   | `-128.0` - `127.996`                 | `0.00390625` (1/256)     |
    --- | Q10.6  | `-512.0` - `511.984375`              | `0.015625` (1/64)        |
    --- | Q12.4  | `-2048.0` - `2047.9375`              | `0.0625` (1/16)          |
    --- | Q16.16 | `-32768.0` - `32767.99998`           | `0.0000152588` (1/65536) |
    --- | Q24.8  | `-8388608.0` - `8388607.996`         | `0.00390625` (1/256)     |
    --- | Q32.16 | `-2147483648.0` - `2147483647.99998` | `0.0000152588` (1/65536) |
    ---
    --- `m + n` is the size of the field in bits (`1` - `64`), so the range is limited to 53 bits.
    ---
    ---@param m integer The number of integer bits, including the sign bit.
    ---@param n integer The number of fractional bits.
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return number value The signed fixed-point number.
    ---@nodiscard
    function BinaryReader:readFixedPoint( m, n, is_little_endian )
        local bit_count = m + n
        return bytepack_readFixedPoint( n, pack_readInt( self.data, advance( self, bit_count, 2 ), bit_count, is_little_endian ) )
    end

end

do

    local bytepack_readFloatBE = bytepack.readFloatBE
    local bytepack_readFloatLE = bytepack.readFloatLE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 4-byte (32 bit) float, the cursor doesn't have to be aligned.
    ---
    --- ### IEEE 754 layout
    --- | Bits    | Field              | Notes                                   |
    --- |:--------|:-------------------|:----------------------------------------|
    --- | 31      | sign               | `1` is negative                         |
    --- | 30 - 23 | exponent (8 bits)  | biased by `127`, `255` is `inf` / `nan` |
    --- | 22 - 0  | mantissa (23 bits) | ~6-9 significant decimal digits         |
    ---
    --- Range: `1.1754944e-38` - `3.4028235e38` (normal), integers are exact up to `16777216`.
    ---
    ---@param is_little_endian? boolean `true` for little endian (as `net.ReadFloat`), `false` by default.
    ---@return number value The float.
    ---@nodiscard
    function BinaryReader:readFloat( is_little_endian )
        return (is_little_endian and bytepack_readFloatLE or bytepack_readFloatBE)( pack_readBytes( self.data, advance( self, 32, 2 ), 4 ) )
    end

end

do

    local bytepack_readDoubleBE = bytepack.readDoubleBE
    local bytepack_readDoubleLE = bytepack.readDoubleLE

    --- [SHARED AND MENU]
    ---
    --- Reads signed 8-byte (64 bit) float, the cursor doesn't have to be aligned.
    ---
    --- ### IEEE 754 layout
    --- | Bits    | Field              | Notes                                     |
    --- |:--------|:-------------------|:------------------------------------------|
    --- | 63      | sign               | `1` is negative                           |
    --- | 62 - 52 | exponent (11 bits) | biased by `1023`, `2047` is `inf` / `nan` |
    --- | 51 - 0  | mantissa (52 bits) | ~15-17 significant decimal digits         |
    ---
    --- Range: `2.2250738585072014e-308` - `1.7976931348623157e308` (normal), Lua numbers are doubles, so nothing is lost.
    ---
    ---@param is_little_endian? boolean `true` for little endian (as `net.ReadDouble`), `false` by default.
    ---@return number value The double.
    ---@nodiscard
    function BinaryReader:readDouble( is_little_endian )
        return (is_little_endian and bytepack_readDoubleLE or bytepack_readDoubleBE)( pack_readBytes( self.data, advance( self, 64, 2 ), 8 ) )
    end

end

do

    local bytepack_readTime = bytepack.readTime

    --- [SHARED AND MENU]
    ---
    --- Reads time in DOS format (16 bits), see `bytepack.readTime`.
    ---
    --- ### DOS time layout
    --- | Bits    | Field       | Range                           |
    --- |:--------|:------------|:--------------------------------|
    --- | 15 - 11 | hours       | `0` - `23`                      |
    --- | 10 - 5  | minutes     | `0` - `59`                      |
    --- | 4 - 0   | seconds / 2 | `0` - `29` (`0` - `58` seconds) |
    ---
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return integer hours The number of hours.
    ---@return integer minutes The number of minutes.
    ---@return integer seconds The number of seconds, always even.
    ---@nodiscard
    function BinaryReader:readTime( is_little_endian )
        return bytepack_readTime( pack_readUInt( self.data, advance( self, 16, 2 ), 16, is_little_endian ) )
    end

end

do

    local bytepack_readDate = bytepack.readDate

    --- [SHARED AND MENU]
    ---
    --- Reads date in DOS format (16 bits), see `bytepack.readDate`.
    ---
    --- ### DOS date layout
    --- | Bits   | Field       | Range                         |
    --- |:-------|:------------|:------------------------------|
    --- | 15 - 9 | year - 1980 | `0` - `127` (`1980` - `2107`) |
    --- | 8 - 5  | month       | `1` - `12`                    |
    --- | 4 - 0  | day         | `1` - `31`                    |
    ---
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    ---@return integer day The day.
    ---@return integer month The month.
    ---@return integer year The year.
    ---@nodiscard
    function BinaryReader:readDate( is_little_endian )
        return bytepack_readDate( pack_readUInt( self.data, advance( self, 16, 2 ), 16, is_little_endian ) )
    end

end

--- [SHARED AND MENU]
---
--- Reads the object in place with its `__deserialize( reader, ... )` method.
---
---@generic T: dreamwork.std.Object
---@param obj T The object to read into.
---@param ... any The arguments passed to `__deserialize`.
---@return T obj The same object.
function BinaryReader:readObject( obj, ... )
    ---@type nil | fun( obj: dreamwork.std.Object, reader: dreamwork.std.BinaryReader, ...: any )
    local fn = obj.__deserialize
    if fn == nil then
        error( "missing '__deserialize' method", 2 )
    end

    fn( obj, self, ... )
    return obj
end

--- [SHARED AND MENU]
---
--- Creates a new instance of the class without calling `__init`,
--- and reads it with its `__deserialize( reader, ... )` method.
---
--- ```
--- local vector = reader:readClass( Vector2 )
--- ```
---
---@generic T: dreamwork.std.Object
---@param cls T | dreamwork.std.Class | dreamwork.std.Object | any The class to create.
---@param ... any The arguments passed to `__deserialize`.
---@return T obj The new object.
---@nodiscard
function BinaryReader:readClass( cls, ... )
    ---@type nil | dreamwork.std.Object
    local base = raw_get( cls, "__base" )
    if base == nil then
        error( "missing '__base' metavalue", 2 )
    end

    ---@type nil | fun( obj: dreamwork.std.Object, reader: dreamwork.std.BinaryReader, ...: any )
    local fn = base.__deserialize
    if fn == nil then
        error( "missing '__deserialize' method", 2 )
    end

    local obj = class.new( base )
    fn( obj, self, ... )
    return obj
end
