---@class dreamwork.std
local std = dreamwork.std

local debug_getmetatable = std.debug.getmetatable

local math = std.math
local math_huge = math.huge
local math_min, math_max = math.min, math.max
local math_floor, math_ldexp = math.floor, math.ldexp

local table = std.table
local table_concat, table_unpack = table.concat, table.unpack

local string = std.string
local string_len, string_find, string_format = string.len, string.find, string.format
local string_byte, string_char, string_sub, string_rep = string.byte, string.char, string.sub, string.rep

local rbit = std.raw.bit
local rbit_band, rbit_bor, rbit_bnot = rbit.band, rbit.bor, rbit.bnot
local rbit_lshift, rbit_rshift, rbit_bswap = rbit.lshift, rbit.rshift, rbit.bswap

local class = std.class

local bytepack = std.bytepack

local bitpack = std.bitpack
local bitpack_write = bitpack.write

local ffi = std.ffi

local error = std.error
local tostring = std.tostring


---@type integer
local CHUNK_SIZE = 4096

--- [SHARED AND MENU]
---
--- A growable binary buffer, writes values one after another at any bit position.
---
--- The exact inverse of `BinaryReader`: the same bit layout (LSB-first, as `pack` and Source's `bf_write`),
--- the same cursor counted in bits from `0`, and big endian by default:
---
--- ```
--- local writer = BinaryWriter()
--- writer:writeBit( 1 )
--- writer:writeUInt( 2, 7, true )
--- writer:writeUInt( 300, 16, true )
--- writer:compile() --> "\5\44\1"
--- ```
---
--- Lua strings can't be changed in place, so bytes are kept in a buffer (`bytes`) until `compile` (or `tostring`) joins them,
--- the buffer is a growable FFI `uint8_t` array when FFI is available, or a table otherwise.
---
--- Writing overwrites the data under the cursor, bits next to a field in the same byte are kept.
--- The size grows to the furthest position written or moved to (`seek`, `skip`, `align`),
--- bytes that were never written are `0` in the result.
---
--- Integers are written as their lowest `bit_count` bits, the same way as `bitpack.write`,
--- so `writeUInt` and `writeInt` accept both unsigned and negative values and never throw on overflow.
---
---@class dreamwork.std.BinaryWriter : dreamwork.std.Object
---@field __class dreamwork.std.BinaryWriterClass
---@field position integer The cursor position in bits.
---@field bytes dreamwork.std.BinaryWriter.Buffer The written bytes, `1`-indexed, a table may have gaps.
---@field capacity number The size of `bytes` in bits, `math.huge` for a table.
---@field has_gaps boolean `true` if a table has bytes that were never written.
---@field data_length integer The size of the data in bits.
---@operator len: integer
---@operator concat( any ): string
local BinaryWriter = class.base( "BinaryWriter", false, nil )

--- [SHARED AND MENU]
---
--- The class used to create new `BinaryWriter` instances.
---
--- Optional data is converted to a string with `tostring`, the cursor is placed after it (append).
---
---@class dreamwork.std.BinaryWriterClass : dreamwork.std.BinaryWriter
---@field __base dreamwork.std.BinaryWriter
---@overload fun( data?: any ): dreamwork.std.BinaryWriter
local BinaryWriterClass = class.create( BinaryWriter )
std.BinaryWriter = BinaryWriterClass

---@return string
---@nodiscard
---@protected
function BinaryWriter:__tostring()
    return self:compile()
end

---@return string
---@nodiscard
---@protected
function BinaryWriter.__concat( a, b )
    if debug_getmetatable( a ) == BinaryWriter then
        return a:compile() .. tostring( b )
    end

    return tostring( a ) .. b:compile()
end

---@return string
---@nodiscard
---@protected
function BinaryWriter:__represent()
    return string_format( "BinaryWriter: %p [%.3f/%.3f]", self, self.position * 0.125, self.data_length * 0.125 )
end

---@return integer
---@nodiscard
---@protected
function BinaryWriter:__len()
    return rbit_rshift( self.data_length + 7, 3 )
end

---@type integer
local MIN_CAPACITY = 256

---@alias dreamwork.std.BinaryWriter.Buffer integer[] | ffi.cdata*

---@type fun( byte_count: integer ): dreamwork.std.BinaryWriter.Buffer, number
local allocate

---@type fun( writer: dreamwork.std.BinaryWriter, byte_count: integer ): string
local bufferToString

---@type fun( str: string, length: integer ): dreamwork.std.BinaryWriter.Buffer, number
local stringToBuffer

--- Makes room for `end_position` bits.
---
---@type fun( writer: dreamwork.std.BinaryWriter, end_position: integer ): dreamwork.std.BinaryWriter.Buffer
local reserve

if ffi == nil then

    -- tables grow on their own
    function reserve( writer )
        return writer.bytes
    end

    function allocate()
        return {}, math_huge
    end

    function bufferToString( writer, byte_count )
        local bytes = writer.bytes

        -- `string.char` doesn't accept `nil`
        if writer.has_gaps then
            for index = 1, byte_count, 1 do
                if bytes[ index ] == nil then
                    bytes[ index ] = 0
                end
            end

            writer.has_gaps = false
        end

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

    function stringToBuffer( str, length )
        ---@type integer[]
        local bytes = {}

        for index = 1, length, 1 do
            bytes[ index ] = string_byte( str, index, index )
        end

        return bytes, math_huge
    end

else

    local ffi_new, ffi_copy, ffi_string = ffi.new, ffi.copy, ffi.string

    -- one extra byte in front, so indices are `1`-based as in a table,
    -- and 3 after, `writeBits` writes 4-byte windows that may end past the field
    function allocate( byte_count )
        local capacity = math_max( byte_count, MIN_CAPACITY )
        return ffi_new( "uint8_t[?]", capacity + 4 ), capacity * 8
    end

    function bufferToString( writer, byte_count )
        return ffi_string( writer.bytes + 1, byte_count )
    end

    function stringToBuffer( str, length )
        local bytes, capacity = allocate( length )
        ffi_copy( bytes + 1, str, length )
        return bytes, capacity
    end

    function reserve( writer, end_position )
        if end_position <= writer.capacity then
            return writer.bytes
        end

        -- at least double, so appends are amortized `O( 1 )`
        local old_bytes, old_count = writer.bytes, writer.capacity / 8
        local bytes, capacity = allocate( math_max( rbit_rshift( end_position + 7, 3 ), old_count * 2 ) )

        ffi_copy( bytes, old_bytes, old_count + 1 )

        writer.bytes, writer.capacity = bytes, capacity
        return bytes
    end

end

--- Moves the cursor after a write, the size is updated without a branch:
--- the JIT records the growing case first, so a branch would side exit on every overwrite.
---
---@param writer dreamwork.std.BinaryWriter
---@param position integer
local function moveTo( writer, position )
    writer.position = position
    writer.data_length = math_max( position, writer.data_length )
end

--- Moves the cursor without writing, the bytes it skips past the end are zeros.
---
---@param writer dreamwork.std.BinaryWriter
---@param position integer
local function moveCursor( writer, position )
    if position > writer.data_length then
        reserve( writer, position )
        writer.data_length = position
        writer.has_gaps = true
    end

    writer.position = position
end

---@param data? any
---@protected
function BinaryWriter:__init( data )
    if data == nil then
        self.data_length = 0
        self.position = 0
        self.has_gaps = false
        self.bytes, self.capacity = allocate( 0 )
    else
        self:open( data )
    end
end

--- [SHARED AND MENU]
---
--- Joins everything written so far into a string.
---
--- The last byte is padded with `0` bits if the size isn't a whole number of bytes.
---
---@return string data The binary data.
---@nodiscard
function BinaryWriter:compile()
    local byte_count = rbit_rshift( self.data_length + 7, 3 )
    if byte_count == 0 then
        return ""
    end

    return bufferToString( self, byte_count )
end

--- [SHARED AND MENU]
---
--- Replaces the data of the writer and moves the cursor to its end, so the next writes append.
---
--- Use `seek()` after it to overwrite the data from the start.
---
---@param data any The data, converted to a string with `tostring`.
function BinaryWriter:open( data )
    local str = tostring( data )
    local length = string_len( str )

    self.data_length = length * 8
    self.position = length * 8
    self.has_gaps = false
    self.bytes, self.capacity = stringToBuffer( str, length )
end

--- [SHARED AND MENU]
---
--- Moves the cursor to the absolute position.
---
--- Positions after the end grow the data (zero-filled), negative positions count back from the end.
---
---@param position? integer The new position, `0` by default.
---@param as_bytes? boolean `true` if `position` is in bytes, `false` (bits) by default.
---@return integer position The new position in bits.
function BinaryWriter:seek( position, as_bytes )
    if position == nil then
        position = 0
    elseif as_bytes then
        position = position * 8
    end

    if position < 0 then
        position = self.data_length + position

        if position < 0 then
            position = 0
        end
    end

    moveCursor( self, position )
    return position
end

--- [SHARED AND MENU]
---
--- Returns the cursor position.
---
---@param as_bytes? boolean `true` to return the number of whole bytes before the cursor, `false` (bits) by default.
---@return integer position The cursor position.
---@nodiscard
function BinaryWriter:tell( as_bytes )
    if as_bytes then
        return rbit_rshift( self.position, 3 )
    end

    return self.position
end

--- [SHARED AND MENU]
---
--- Returns the size of the data.
---
---@param as_bytes? boolean `true` to return the size of the compiled string in bytes, `false` (bits) by default.
---@return integer size The size of the data.
---@nodiscard
function BinaryWriter:size( as_bytes )
    if as_bytes then
        return rbit_rshift( self.data_length + 7, 3 )
    end

    return self.data_length
end

--- [SHARED AND MENU]
---
--- Moves the cursor relative to its position, moving after the end grows the data (zero-filled).
---
--- ```
--- local length_position = writer:tell()
--- writer:skip( 4, true ) -- reserve 4 bytes for the length
--- writer:write( payload )
---
--- local end_position = writer:tell()
--- writer:seek( length_position )
--- writer:writeUInt( #payload, 32 )
--- writer:seek( end_position )
--- ```
---
---@param length? integer The distance to move, negative to move back, `1` by default.
---@param as_bytes? boolean `true` if `length` is in bytes, `false` (bits) by default.
---@return integer position The new position in bits.
function BinaryWriter:skip( length, as_bytes )
    if length == nil then
        length = 1
    elseif as_bytes then
        length = length * 8
    end

    local position = self.position + length
    if position < 0 then
        position = 0
    end

    moveCursor( self, position )
    return position
end

--- [SHARED AND MENU]
---
--- Moves the cursor forward to the next multiple of `bit_boundary`, padding with `0` bits.
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return integer position The new position in bits.
function BinaryWriter:align( bit_boundary )
    local position = self.position

    local remainder = position % (bit_boundary or 8)
    if remainder == 0 then
        return position
    end

    position = position + ((bit_boundary or 8) - remainder)
    moveCursor( self, position )
    return position
end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at a multiple of `bit_boundary`.
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return boolean is_aligned `true` if the cursor is aligned.
---@nodiscard
function BinaryWriter:isAligned( bit_boundary )
    return (self.position % (bit_boundary or 8)) == 0
end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at the end of the data, so the next write appends.
---
---@return boolean is_eof `true` if there is no data after the cursor.
---@nodiscard
function BinaryWriter:isEndOfFile()
    return self.position >= self.data_length
end

--- [SHARED AND MENU]
---
--- Returns the size of the data after the cursor, that the next writes overwrite.
---
---@param as_bytes? boolean `true` to return the number of whole bytes, `false` (bits) by default.
---@return integer remaining The size of the data after the cursor.
---@nodiscard
function BinaryWriter:remaining( as_bytes )
    local bits_left = self.data_length - self.position

    if as_bytes then
        return rbit_rshift( bits_left, 3 )
    end

    return bits_left
end

-- helpers below are loop-free on purpose: a shared helper with an inner loop
-- gets blacklisted by the JIT and drags every caller into the interpreter

--- Writes one byte at any bit position.
---
---@param bytes integer[]
---@param position integer
---@param byte integer
local function writeByte( bytes, position, byte )
    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )

    if bit_offset == 0 then
        bytes[ index ] = rbit_band( byte, 0xFF )
    else
        bytes[ index ] = bitpack_write( bytes[ index ] or 0, bit_offset, 8 - bit_offset, byte )
        bytes[ index + 1 ] = bitpack_write( bytes[ index + 1 ] or 0, 0, bit_offset, rbit_rshift( byte, 8 - bit_offset ) )
    end
end

--- Writes the lowest `bit_count` bits of `value`, lowest bit first.
---
---@param bytes integer[]
---@param position integer
---@param value integer
---@param bit_count integer `1` - `32`
local function writeBits( bytes, position, value, bit_count )
    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )

    -- whole aligned bytes: plain stores, the branches only depend on the call site
    if rbit_band( bit_count, 7 ) == 0 and bit_offset == 0 then
        bytes[ index ] = rbit_band( value, 0xFF )

        if bit_count > 8 then
            bytes[ index + 1 ] = rbit_band( rbit_rshift( value, 8 ), 0xFF )

            if bit_count > 16 then
                bytes[ index + 2 ] = rbit_band( rbit_rshift( value, 16 ), 0xFF )

                if bit_count > 24 then
                    bytes[ index + 3 ] = rbit_band( rbit_rshift( value, 24 ), 0xFF )
                end
            end
        end

        return
    end

    -- fields within 4 bytes (always up to 25 bits): replace them in one 32-bit window without branches,
    -- the bytes of the window after the field are written back unchanged
    if bit_offset + bit_count <= 32 then
        local window = rbit_bor(
            bytes[ index ] or 0,
            rbit_lshift( bytes[ index + 1 ] or 0, 8 ),
            rbit_lshift( bytes[ index + 2 ] or 0, 16 ),
            rbit_lshift( bytes[ index + 3 ] or 0, 24 )
        )

        local mask = rbit_lshift( rbit_rshift( 0xFFFFFFFF, 32 - bit_count ), bit_offset )
        window = rbit_bor( rbit_band( window, rbit_bnot( mask ) ), rbit_band( rbit_lshift( value, bit_offset ), mask ) )

        bytes[ index ] = rbit_band( window, 0xFF )
        bytes[ index + 1 ] = rbit_band( rbit_rshift( window, 8 ), 0xFF )
        bytes[ index + 2 ] = rbit_band( rbit_rshift( window, 16 ), 0xFF )
        bytes[ index + 3 ] = rbit_rshift( window, 24 )
        return
    end

    -- the number of bits after the first byte
    local left = bit_offset + bit_count - 8

    if left <= 0 then
        bytes[ index ] = bitpack_write( bytes[ index ] or 0, bit_offset, bit_count, value )
        return
    end

    if bit_offset == 0 then
        bytes[ index ] = rbit_band( value, 0xFF )
    else
        bytes[ index ] = bitpack_write( bytes[ index ] or 0, bit_offset, 8 - bit_offset, value )
    end

    value = rbit_rshift( value, 8 - bit_offset )
    index = index + 1

    -- up to 3 whole bytes in the middle (31 bits after the first byte at most)
    if left > 8 then
        bytes[ index ] = rbit_band( value, 0xFF )
        value, left, index = rbit_rshift( value, 8 ), left - 8, index + 1

        if left > 8 then
            bytes[ index ] = rbit_band( value, 0xFF )
            value, left, index = rbit_rshift( value, 8 ), left - 8, index + 1

            if left > 8 then
                bytes[ index ] = rbit_band( value, 0xFF )
                value, left, index = rbit_rshift( value, 8 ), left - 8, index + 1
            end
        end
    end

    if left == 8 then
        bytes[ index ] = rbit_band( value, 0xFF )
    else
        bytes[ index ] = bitpack_write( bytes[ index ] or 0, 0, left, value )
    end
end

--- Writes up to 32 bits as big endian, the inverse of `pack.readUInt`:
--- the highest `bit_count % 8` bits first, then whole bytes from the most significant.
---
---@param bytes integer[]
---@param position integer
---@param value integer
---@param bit_count integer `1` - `32`
local function writeBitsBE( bytes, position, value, bit_count )
    local byte_count = rbit_rshift( bit_count, 3 )

    if byte_count ~= 0 then
        local remaining_bits = rbit_band( bit_count, 7 )

        -- the same field as little endian: the highest `remaining_bits` go first,
        -- then the whole bytes in the reversed order
        value = rbit_bor(
            rbit_band( rbit_rshift( value, byte_count * 8 ), rbit_lshift( 1, remaining_bits ) - 1 ),
            rbit_lshift( rbit_rshift( rbit_bswap( value ), 32 - byte_count * 8 ), remaining_bits )
        )
    end

    writeBits( bytes, position, value, bit_count )
end

---@param writer dreamwork.std.BinaryWriter
---@param value integer
---@param bit_count integer
---@param is_little_endian? boolean
---@param stack_level integer
local function writeInteger( writer, value, bit_count, is_little_endian, stack_level )
    if bit_count > 64 then
        error( "unsupported bit count: " .. bit_count .. " (max 64)", stack_level + 1 )
    elseif bit_count < 1 then
        return
    end

    local position = writer.position
    local bytes = reserve( writer, position + bit_count )

    if bit_count > 32 then
        -- split into 32-bit halves, `%` keeps the low half non-negative for negative values
        local low = value % 0x100000000
        local high = (value - low) / 0x100000000

        if is_little_endian then
            writeBits( bytes, position, low, 32 )
            writeBits( bytes, position + 32, high, bit_count - 32 )
        else
            writeBitsBE( bytes, position, high, bit_count - 32 )
            writeBitsBE( bytes, position + (bit_count - 32), low, 32 )
        end
    elseif is_little_endian then
        writeBits( bytes, position, value, bit_count )
    else
        writeBitsBE( bytes, position, value, bit_count )
    end

    moveTo( writer, position + bit_count )
end

--- [SHARED AND MENU]
---
--- Writes one bit.
---
---@param value 0 | 1 | boolean The bit.
function BinaryWriter:writeBit( value )
    local position = self.position
    local bytes = reserve( self, position + 1 )

    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )

    -- branchless, random bits would side exit on every other call
    if value == true then
        value = 1
    elseif value == false then
        value = 0
    end

    ---@cast value integer

    ---@cast value 0 | 1

    bytes[ index ] = rbit_bor( rbit_band( bytes[ index ] or 0, rbit_bnot( rbit_lshift( 1, bit_offset ) ) ), rbit_lshift( rbit_band( value, 1 ), bit_offset ) )
    moveTo( self, position + 1 )
end

--- [SHARED AND MENU]
---
--- Writes one bit as a boolean, same as `net.WriteBool`.
---
---@param value boolean The boolean.
function BinaryWriter:writeBoolean( value )
    local position = self.position
    local bytes = reserve( self, position + 1 )

    local index = rbit_rshift( position, 3 ) + 1
    local bit_offset = rbit_band( position, 7 )

    bytes[ index ] = rbit_bor( rbit_band( bytes[ index ] or 0, rbit_bnot( rbit_lshift( 1, bit_offset ) ) ), rbit_lshift( value == true and 1 or 0, bit_offset ) )
    moveTo( self, position + 1 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned integer of any size, read it back with `BinaryReader:readUInt`.
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
--- writer:writeUInt( 0xFF, 8 ) -- byte
--- writer:writeUInt( 300, 32, true ) -- same as `net.WriteUInt( 300, 32 )`
--- ```
---
---@param value integer The unsigned integer, only the lowest `bit_count` bits are written.
---@param bit_count integer The size of the integer in bits (`1` - `64`), `0` writes nothing.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
function BinaryWriter:writeUInt( value, bit_count, is_little_endian )
    writeInteger( self, value, bit_count, is_little_endian, 2 )
end

--- [SHARED AND MENU]
---
--- Writes signed (two's complement) integer of any size, read it back with `BinaryReader:readInt`.
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
---@param value integer The signed integer, only the lowest `bit_count` bits are written.
---@param bit_count integer The size of the integer in bits (`1` - `64`), `0` writes nothing.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
function BinaryWriter:writeInt( value, bit_count, is_little_endian )
    writeInteger( self, value, bit_count, is_little_endian, 2 )
end

---@param writer dreamwork.std.BinaryWriter
---@param data string
---@param data_length integer
local function writeString( writer, data, data_length )
    if data_length == 0 then
        return
    end

    local position = writer.position
    local bytes = reserve( writer, position + data_length * 8 )

    if rbit_band( position, 7 ) == 0 then
        local byte_index = rbit_rshift( position, 3 )

        for index = 1, data_length - 3, 4 do
            bytes[ byte_index + 1 ], bytes[ byte_index + 2 ], bytes[ byte_index + 3 ], bytes[ byte_index + 4 ] = string_byte( data, index, index + 3 )
            byte_index = byte_index + 4
        end

        for index = data_length - (data_length % 4) + 1, data_length, 1 do
            byte_index = byte_index + 1
            bytes[ byte_index ] = string_byte( data, index, index )
        end
    else
        local byte_index = rbit_rshift( position, 3 ) + 1
        local bit_offset = rbit_band( position, 7 )
        local inverse_offset = 8 - bit_offset

        -- the high bits of every byte are carried into the low bits of the next one,
        -- starting with the bits before the cursor
        local carry = rbit_band( bytes[ byte_index ] or 0, rbit_rshift( 0xFF, inverse_offset ) )

        for index = 1, data_length, 1 do
            local byte = string_byte( data, index, index )
            bytes[ byte_index ] = rbit_band( rbit_bor( carry, rbit_lshift( byte, bit_offset ) ), 0xFF )
            carry = rbit_rshift( byte, inverse_offset )
            byte_index = byte_index + 1
        end

        -- keep the bits after the string in the last byte
        bytes[ byte_index ] = rbit_bor( rbit_band( bytes[ byte_index ] or 0, rbit_band( rbit_lshift( 0xFF, bit_offset ), 0xFF ) ), carry )
    end

    moveTo( writer, position + data_length * 8 )
end

--- [SHARED AND MENU]
---
--- Writes the string as is, the cursor doesn't have to be aligned.
---
---@param data string The bytes.
---@return integer byte_count The number of bytes written.
function BinaryWriter:write( data )
    local data_length = string_len( data )
    writeString( self, data, data_length )
    return data_length
end

--- [SHARED AND MENU]
---
--- Writes bytes, the cursor doesn't have to be aligned.
---
---@param ... integer The bytes (`0` - `255`).
---@return integer byte_count The number of bytes written.
function BinaryWriter:writeBytes( ... )
    local byte_count = select( "#", ... )
    if byte_count == 0 then
        return 0
    end

    local position = self.position
    local bytes = reserve( self, position + byte_count * 8 )

    -- `select` instead of `{ ... }`, the table never lets the caller's trace settle
    if rbit_band( position, 7 ) == 0 then
        local byte_index = rbit_rshift( position, 3 )

        for index = 1, byte_count, 1 do
            bytes[ byte_index + index ] = rbit_band( (select( index, ... )), 0xFF )
        end
    else
        for index = 1, byte_count, 1 do
            writeByte( bytes, position + (index - 1) * 8, (select( index, ... )) )
        end
    end

    moveTo( self, position + byte_count * 8 )
    return byte_count
end

--- [SHARED AND MENU]
---
--- Writes the string of a fixed size, shorter data is padded with `\0` and longer data is cut, same as `pack.writeFixedString`.
---
---@param data string The string.
---@param byte_count integer The size of the string in bytes.
function BinaryWriter:writeFixedString( data, byte_count )
    local data_length = string_len( data )

    if data_length > byte_count then
        writeString( self, string_sub( data, 1, byte_count ), byte_count )
    elseif data_length < byte_count then
        writeString( self, data .. string_rep( "\0", byte_count - data_length ), byte_count )
    else
        writeString( self, data, data_length )
    end
end

---@param writer dreamwork.std.BinaryWriter
---@param data string
---@param terminator integer
---@param stack_level integer
local function writeTerminated( writer, data, terminator, stack_level )
    local terminator_char = string_char( terminator )

    if string_find( data, terminator_char, 1, true ) ~= nil then
        error( "data contains the terminator byte " .. terminator, stack_level + 1 )
    end

    writeString( writer, data .. terminator_char, string_len( data ) + 1 )
end

--- [SHARED AND MENU]
---
--- Writes the string followed by the `terminator` byte, read it back with `BinaryReader:readTerminatedString`.
---
--- Throws an error if the string contains the terminator.
---
---@param data string The string.
---@param terminator integer The terminator byte (`0` - `255`).
function BinaryWriter:writeTerminatedString( data, terminator )
    writeTerminated( self, data, terminator, 2 )
end

--- [SHARED AND MENU]
---
--- Writes C-style string, the string followed by the null terminator (`\0`), same as `net.WriteString`.
---
--- Throws an error if the string contains `\0`.
---
---@param data string The string.
function BinaryWriter:writeString( data )
    writeTerminated( self, data, 0x00, 2 )
end

--- [SHARED AND MENU]
---
--- Writes the line, the string followed by `\n`.
---
--- Throws an error if the string contains `\n`.
---
---@param data string The line.
function BinaryWriter:writeLine( data )
    writeTerminated( self, data, 0x0A --[[ \n ]], 2 )
end

--- [SHARED AND MENU]
---
--- Writes the string prefixed with its length, read it back with `BinaryReader:readCountedString`.
---
--- Throws an error if the string is too long for the length size.
---
--- ```
--- writer:writeCountedString( "abc", 8 ) --> "\3abc"
--- ```
---
---@param data string The string.
---@param bit_count integer The size of the length in bits (`1` - `64`).
---@param is_little_endian? boolean `true` to write the length as little endian, `false` by default.
---@return integer byte_count The size of the string in bytes.
function BinaryWriter:writeCountedString( data, bit_count, is_little_endian )
    local data_length = string_len( data )

    if bit_count < 53 and data_length >= (2 ^ bit_count) then
        error( "data is too long for the " .. bit_count .. "-bit length: " .. data_length .. " bytes", 2 )
    end

    writeInteger( self, data_length, bit_count, is_little_endian, 2 )
    writeString( self, data, data_length )
    return data_length
end

--- [SHARED AND MENU]
---
--- Writes unsigned fixed-point number (**UQm.n**), rounded to the nearest step.
---
--- Unlike `bytepack.writeFixedPoint`, `m + n` doesn't have to be a whole number of bytes.
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
---@param value number The unsigned fixed-point number.
---@param m integer The number of integer bits.
---@param n integer The number of fractional bits.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
function BinaryWriter:writeUnsignedFixedPoint( value, m, n, is_little_endian )
    writeInteger( self, math_floor( math_ldexp( value, n ) + 0.5 ), m + n, is_little_endian, 2 )
end

--- [SHARED AND MENU]
---
--- Writes signed fixed-point number (**Qm.n**), rounded to the nearest step.
---
--- Unlike `bytepack.writeFixedPoint`, `m + n` doesn't have to be a whole number of bytes.
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
---@param value number The signed fixed-point number.
---@param m integer The number of integer bits, including the sign bit.
---@param n integer The number of fractional bits.
---@param is_little_endian? boolean `true` for little endian, `false` by default.
function BinaryWriter:writeFixedPoint( value, m, n, is_little_endian )
    writeInteger( self, math_floor( math_ldexp( value, n ) + 0.5 ), m + n, is_little_endian, 2 )
end

---@param writer dreamwork.std.BinaryWriter
---@param uint8_1 integer
---@param uint8_2 integer
---@param uint8_3 integer
---@param uint8_4 integer
local function write4( writer, uint8_1, uint8_2, uint8_3, uint8_4 )
    local position = writer.position
    local bytes = reserve( writer, position + 32 )

    if rbit_band( position, 7 ) == 0 then
        local index = rbit_rshift( position, 3 )
        bytes[ index + 1 ], bytes[ index + 2 ], bytes[ index + 3 ], bytes[ index + 4 ] = uint8_1, uint8_2, uint8_3, uint8_4
    else
        writeByte( bytes, position, uint8_1 )
        writeByte( bytes, position + 8, uint8_2 )
        writeByte( bytes, position + 16, uint8_3 )
        writeByte( bytes, position + 24, uint8_4 )
    end

    moveTo( writer, position + 32 )
end

---@param writer dreamwork.std.BinaryWriter
---@param uint8_1 integer
---@param uint8_2 integer
---@param uint8_3 integer
---@param uint8_4 integer
---@param uint8_5 integer
---@param uint8_6 integer
---@param uint8_7 integer
---@param uint8_8 integer
local function write8( writer, uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8 )
    local position = writer.position
    local bytes = reserve( writer, position + 64 )

    if rbit_band( position, 7 ) == 0 then
        local index = rbit_rshift( position, 3 )
        bytes[ index + 1 ], bytes[ index + 2 ], bytes[ index + 3 ], bytes[ index + 4 ] = uint8_1, uint8_2, uint8_3, uint8_4
        bytes[ index + 5 ], bytes[ index + 6 ], bytes[ index + 7 ], bytes[ index + 8 ] = uint8_5, uint8_6, uint8_7, uint8_8
    else
        writeByte( bytes, position, uint8_1 )
        writeByte( bytes, position + 8, uint8_2 )
        writeByte( bytes, position + 16, uint8_3 )
        writeByte( bytes, position + 24, uint8_4 )
        writeByte( bytes, position + 32, uint8_5 )
        writeByte( bytes, position + 40, uint8_6 )
        writeByte( bytes, position + 48, uint8_7 )
        writeByte( bytes, position + 56, uint8_8 )
    end

    moveTo( writer, position + 64 )
end

do

    local bytepack_writeFloatBE = bytepack.writeFloatBE
    local bytepack_writeFloatLE = bytepack.writeFloatLE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 4-byte (32 bit) float, the cursor doesn't have to be aligned.
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
    ---@param value number The float, precision is reduced to float.
    ---@param is_little_endian? boolean `true` for little endian (as `net.WriteFloat`), `false` by default.
    function BinaryWriter:writeFloat( value, is_little_endian )
        write4( self, (is_little_endian and bytepack_writeFloatLE or bytepack_writeFloatBE)( value ) )
    end

end

do

    local bytepack_writeDoubleBE = bytepack.writeDoubleBE
    local bytepack_writeDoubleLE = bytepack.writeDoubleLE

    --- [SHARED AND MENU]
    ---
    --- Writes signed 8-byte (64 bit) float, the cursor doesn't have to be aligned.
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
    ---@param value number The double.
    ---@param is_little_endian? boolean `true` for little endian (as `net.WriteDouble`), `false` by default.
    function BinaryWriter:writeDouble( value, is_little_endian )
        write8( self, (is_little_endian and bytepack_writeDoubleLE or bytepack_writeDoubleBE)( value ) )
    end

end

do

    local bytepack_writeTime = bytepack.writeTime

    --- [SHARED AND MENU]
    ---
    --- Writes time in DOS format (16 bits), see `bytepack.writeTime`.
    ---
    --- ### DOS time layout
    --- | Bits    | Field       | Range                           |
    --- |:--------|:------------|:--------------------------------|
    --- | 15 - 11 | hours       | `0` - `23`                      |
    --- | 10 - 5  | minutes     | `0` - `59`                      |
    --- | 4 - 0   | seconds / 2 | `0` - `29` (`0` - `58` seconds) |
    ---
    ---@param hours? integer The number of hours.
    ---@param minutes? integer The number of minutes.
    ---@param seconds? integer The number of seconds, rounded down to even.
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    function BinaryWriter:writeTime( hours, minutes, seconds, is_little_endian )
        writeInteger( self, bytepack_writeTime( hours, minutes, seconds ), 16, is_little_endian, 2 )
    end

end

do

    local bytepack_writeDate = bytepack.writeDate

    --- [SHARED AND MENU]
    ---
    --- Writes date in DOS format (16 bits), see `bytepack.writeDate`.
    ---
    --- ### DOS date layout
    --- | Bits   | Field       | Range                         |
    --- |:-------|:------------|:------------------------------|
    --- | 15 - 9 | year - 1980 | `0` - `127` (`1980` - `2107`) |
    --- | 8 - 5  | month       | `1` - `12`                    |
    --- | 4 - 0  | day         | `1` - `31`                    |
    ---
    ---@param day? integer The day.
    ---@param month? integer The month.
    ---@param year? integer The year (`1980` - `2107`).
    ---@param is_little_endian? boolean `true` for little endian, `false` by default.
    function BinaryWriter:writeDate( day, month, year, is_little_endian )
        writeInteger( self, bytepack_writeDate( day, month, year ), 16, is_little_endian, 2 )
    end

end

--- [SHARED AND MENU]
---
--- Writes the object with its `__serialize( writer, ... )` method,
--- read it back with `BinaryReader:readObject` or `BinaryReader:readClass`.
---
---@param obj dreamwork.std.Object The object.
---@param ... any The arguments passed to `__serialize`.
function BinaryWriter:writeObject( obj, ... )
    ---@type nil | fun( obj: dreamwork.std.Object, writer: dreamwork.std.BinaryWriter, ...: any )
    local fn = obj.__serialize
    if fn == nil then
        error( "missing '__serialize' method", 2 )
    end

    fn( obj, self, ... )
end
