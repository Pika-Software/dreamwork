---@meta _

--- [SHARED AND MENU]
---
--- Library that packs & unpacks bits in integers and bytes.
---
--- Bit positions are `0`-indexed and counted from the least significant bit,
--- so position `0` is the lowest bit (`0x01`) and position `7` is the highest bit of a byte (`0x80`),
--- same as `bit.extract` and `pack`.
---
--- Field functions (`get`, `set`, `toggle`, `readUInt`, `readInt`, `write`)
--- work on any integer up to 32 bits, not only on bytes, because they are made of 32-bit shifts:
--- `readUInt( x, position, bit_count )` shifts the field to the top of 32 bits (bits above it fall off),
--- then shifts it down to bit `0` (bits below it fall off).
---
--- So fields that cross byte boundaries are read and written by joining bytes into an integer with `bytepack` first:
---
--- ```
--- -- [15] flag_a [14] flag_b [13..0] int14
--- local x = bytepack.readUInt16BE( uint8_1, uint8_2 )
---
--- local flag_a = bitpack.get( x, 15 )
--- local flag_b = bitpack.get( x, 14 )
--- local value = bitpack.readInt( x, 0, 14 )
---
--- x = bitpack.write( x, 0, 14, value - 1 )
--- uint8_1, uint8_2 = bytepack.writeUInt16BE( x )
--- ```
---
--- Integers are taken modulo `2 ^ 32`, a field must fit in them (`position + bit_count <= 32`),
--- and results with bit `31` set are negative (signed 32-bit), except `readUInt`.
---
--- Byte functions (`reverse`, `count`, `findFirst`, `findLast`, `rotate`, `swapNibbles`,
--- `pack`, `unpack`, `toString`, `fromString`) work on the lowest 8 bits only.
---
--- Bit sequences are tables of booleans, stored LSB-first by default
--- (`bits[ 1 ]` is bit `0` of the first byte), or MSB-first when `msb_first` is `true`
--- (`bits[ 1 ]` is bit `7` of the first byte, the order bits are usually written in).
---
---@class bitpack
bitpack = {}

--- [SHARED AND MENU]
---
--- Checks if the bit at the given position of the integer is set.
---
--- ```
--- get( 0b00000100, 2 ) --> true
--- get( 0x8000, 15 ) --> true
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position integer The bit position (`0` - `31`).
---@return boolean is_set `true` if the bit is `1`, `false` if it is `0`.
---@nodiscard
function bitpack.get(x, position) end

--- [SHARED AND MENU]
---
--- Sets the bit at the given position of the integer.
---
--- ```
--- set( 0b00000000, 2, true ) --> 0b00000100
--- set( 0b11111111, 0, false ) --> 0b11111110
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position integer The bit position (`0` - `31`).
---@param value? boolean | 0 | 1 The new value of the bit, `true` by default.
---@return integer x The changed integer.
---@nodiscard
function bitpack.set(x, position, value) end

--- [SHARED AND MENU]
---
--- Flips the bit at the given position of the integer.
---
--- ```
--- toggle( 0b00000101, 2 ) --> 0b00000001
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position integer The bit position (`0` - `31`).
---@return integer x The changed integer.
---@nodiscard
function bitpack.toggle(x, position) end

--- [SHARED AND MENU]
---
--- Reads unsigned integer from the bit field of the integer.
---
--- ```
--- readUInt( 0b01101100, 2, 4 ) --> 0b1011 ( 11 )
--- readUInt( 0xBB2E, 0, 14 ) --> 15150
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position? integer The position of the lowest bit of the field (`0` - `31`), `0` by default.
---@param bit_count? integer The size of the field in bits (`1` - `32`), `1` by default.
---@return integer value The unsigned integer.
---@nodiscard
function bitpack.readUInt(x, position, bit_count) end

--- [SHARED AND MENU]
---
--- Reads signed (two's complement) integer from the bit field of the integer.
---
--- ```
--- readInt( 0b01101100, 2, 4 ) --> -5
--- readInt( 0xBB2E, 0, 14 ) --> -1234
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position? integer The position of the lowest bit of the field (`0` - `31`), `0` by default.
---@param bit_count? integer The size of the field in bits (`1` - `32`), `1` by default.
---@return integer value The signed integer.
---@nodiscard
function bitpack.readInt(x, position, bit_count) end

--- [SHARED AND MENU]
---
--- Writes unsigned or signed (two's complement) integer into the bit field of the integer,
--- bits outside of the field are left unchanged.
---
--- Only the lowest `bit_count` bits of the value are written,
--- for negative values these bits already are their two's complement,
--- so the same field can be read back with `readUInt` or `readInt`.
---
--- ```
--- write( 0b00000011, 2, 4, 11 ) --> 0b00101111
--- write( 0b00000011, 2, 4, -5 ) --> 0b00101111
--- write( 0x8000, 0, 14, -1234 ) --> 0xBB2E
--- ```
---
---@param x integer The integer (up to 32 bits).
---@param position integer The position of the lowest bit of the field (`0` - `31`).
---@param bit_count integer The size of the field in bits (`1` - `32`).
---@param value integer The unsigned or signed integer.
---@return integer x The changed integer.
---@nodiscard
function bitpack.write(x, position, bit_count, value) end

--- [SHARED AND MENU]
---
--- Reverses the order of bits in the byte.
---
--- ```
--- reverse( 0b00000110 ) --> 0b01100000
--- ```
---
---@param byte integer The byte.
---@return integer byte The reversed byte.
---@nodiscard
function bitpack.reverse(byte) end

--- [SHARED AND MENU]
---
--- Counts set bits in the byte (population count).
---
--- ```
--- count( 0b01101100 ) --> 4
--- ```
---
---@param byte integer The byte.
---@return integer count The number of `1` bits (`0` - `8`).
---@nodiscard
function bitpack.count(byte) end

--- [SHARED AND MENU]
---
--- Finds the position of the lowest set bit in the byte.
---
--- ```
--- findFirst( 0b01101100 ) --> 2
--- findFirst( 0 ) --> nil
--- ```
---
---@param byte integer The byte.
---@return integer | nil position The bit position (`0` - `7`), or `nil` if the byte is `0`.
---@nodiscard
function bitpack.findFirst(byte) end

--- [SHARED AND MENU]
---
--- Finds the position of the highest set bit in the byte.
---
--- ```
--- findLast( 0b01101100 ) --> 6
--- findLast( 0 ) --> nil
--- ```
---
---@param byte integer The byte.
---@return integer | nil position The bit position (`0` - `7`), or `nil` if the byte is `0`.
---@nodiscard
function bitpack.findLast(byte) end

--- [SHARED AND MENU]
---
--- Rotates bits of the byte, bits shifted out of one end come back on the other.
---
--- ```
--- rotate( 0b10000001, 1 ) --> 0b00000011
--- rotate( 0b10000001, -1 ) --> 0b11000000
--- ```
---
---@param byte integer The byte.
---@param shift integer The number of bits to rotate by, positive to the left (towards the highest bit), negative to the right.
---@return integer byte The rotated byte.
---@nodiscard
function bitpack.rotate(byte, shift) end

--- [SHARED AND MENU]
---
--- Swaps the lower and upper 4 bits (nibbles) of the byte.
---
--- ```
--- swapNibbles( 0xA5 ) --> 0x5A
--- ```
---
---@param byte integer The byte.
---@return integer byte The swapped byte.
---@nodiscard
function bitpack.swapNibbles(byte) end

--- [SHARED AND MENU]
---
--- Unpacks the byte as 8 booleans, from the lowest bit to the highest.
---
--- ```
--- unpack( 0b00000101 ) --> true, false, true, false, false, false, false, false
--- ```
---
---@param byte integer The byte.
---@return boolean bit0
---@return boolean bit1
---@return boolean bit2
---@return boolean bit3
---@return boolean bit4
---@return boolean bit5
---@return boolean bit6
---@return boolean bit7
---@nodiscard
function bitpack.unpack(byte) end

--- [SHARED AND MENU]
---
--- Packs up to 8 booleans into the byte, from the lowest bit to the highest, `nil` is `false`.
---
--- ```
--- pack( true, false, true ) --> 0b00000101
--- ```
---
---@param bit0? boolean
---@param bit1? boolean
---@param bit2? boolean
---@param bit3? boolean
---@param bit4? boolean
---@param bit5? boolean
---@param bit6? boolean
---@param bit7? boolean
---@return integer byte The byte.
---@nodiscard
function bitpack.pack(bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7) end

--- [SHARED AND MENU]
---
--- Unpacks the sequence of bytes into the sequence of bits (booleans).
---
---@param bytes integer[] The sequence of bytes.
---@param byte_count? integer The number of bytes.
---@param msb_first? boolean `true` to store the highest bit of each byte first, `false` by default.
---@return boolean[] bits The sequence of bits.
---@return integer bit_count The number of bits.
---@nodiscard
function bitpack.toTable(bytes, byte_count, msb_first) end

--- [SHARED AND MENU]
---
--- Packs the sequence of bits (booleans) into the sequence of bytes,
--- unused bits of the last byte are `0`.
---
---@param bits boolean[] The sequence of bits.
---@param bit_count? integer The number of bits.
---@param msb_first? boolean `true` if the highest bit of each byte is stored first, `false` by default.
---@return integer[] bytes The sequence of bytes.
---@return integer byte_count The number of bytes.
---@nodiscard
function bitpack.fromTable(bits, bit_count, msb_first) end

--- [SHARED AND MENU]
---
--- Converts the byte to a string of `0`s and `1`s, from the highest bit to the lowest.
---
--- ```
--- toString( 5 ) --> "00000101"
--- toString( 5, 4 ) --> "0101"
--- ```
---
---@param byte integer The byte.
---@param bit_count? integer The number of the lowest bits to convert (`1` - `8`), `8` by default.
---@return string str The string of `0`s and `1`s.
---@nodiscard
function bitpack.toString(byte, bit_count) end

--- [SHARED AND MENU]
---
--- Reads the byte from a string of `0`s and `1`s, from the highest bit to the lowest.
---
--- ```
--- fromString( "00000101" ) --> 5
--- fromString( "101" ) --> 5
--- fromString( "2" ) --> nil
--- ```
---
---@param str string The string of `0`s and `1`s, up to 8 characters.
---@return integer | nil byte The byte, or `nil` if the string is empty, too long or has other characters.
---@nodiscard
function bitpack.fromString(str) end
