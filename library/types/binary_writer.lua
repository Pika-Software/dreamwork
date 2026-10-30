---@meta _

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
---@class BinaryWriter : Object
---@field __class BinaryWriterClass
---@field position integer The cursor position in bits.
---@field bytes BinaryWriter.Buffer The written bytes, `1`-indexed, a table may have gaps.
---@field capacity number The size of `bytes` in bits, `math.huge` for a table.
---@field has_gaps boolean `true` if a table has bytes that were never written.
---@field data_length integer The size of the data in bits.
---@operator len: integer
---@operator concat( any ): string
local __BinaryWriter = {}

--- [SHARED AND MENU]
---
--- The class used to create new `BinaryWriter` instances.
---
--- Optional data is converted to a string with `tostring`, the cursor is placed after it (append).
---
---@class BinaryWriterClass : BinaryWriter
---@field __base BinaryWriter
---@overload fun( data?: any ): BinaryWriter
BinaryWriter = {}

---@return string
---@nodiscard
---@protected
function __BinaryWriter:__tostring() end

---@return string
---@nodiscard
---@protected
function __BinaryWriter.__concat(a, b) end

---@return string
---@nodiscard
---@protected
function __BinaryWriter:__represent() end

---@return integer
---@nodiscard
---@protected
function __BinaryWriter:__len() end

---@alias BinaryWriter.Buffer integer[] | ffi.cdata*

---@param data? any
---@protected
function __BinaryWriter:__init(data) end

--- [SHARED AND MENU]
---
--- Joins everything written so far into a string.
---
--- The last byte is padded with `0` bits if the size isn't a whole number of bytes.
---
---@return string data The binary data.
---@nodiscard
function __BinaryWriter:compile() end

--- [SHARED AND MENU]
---
--- Replaces the data of the writer and moves the cursor to its end, so the next writes append.
---
--- Use `seek()` after it to overwrite the data from the start.
---
---@param data any The data, converted to a string with `tostring`.
function __BinaryWriter:open(data) end

--- [SHARED AND MENU]
---
--- Moves the cursor to the absolute position.
---
--- Positions after the end grow the data (zero-filled), negative positions count back from the end.
---
---@param position? integer The new position, `0` by default.
---@param as_bytes? boolean `true` if `position` is in bytes, `false` (bits) by default.
---@return integer position The new position in bits.
function __BinaryWriter:seek(position, as_bytes) end

--- [SHARED AND MENU]
---
--- Returns the cursor position.
---
---@param as_bytes? boolean `true` to return the number of whole bytes before the cursor, `false` (bits) by default.
---@return integer position The cursor position.
---@nodiscard
function __BinaryWriter:tell(as_bytes) end

--- [SHARED AND MENU]
---
--- Returns the size of the data.
---
---@param as_bytes? boolean `true` to return the size of the compiled string in bytes, `false` (bits) by default.
---@return integer size The size of the data.
---@nodiscard
function __BinaryWriter:size(as_bytes) end

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
function __BinaryWriter:skip(length, as_bytes) end

--- [SHARED AND MENU]
---
--- Moves the cursor forward to the next multiple of `bit_boundary`, padding with `0` bits.
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return integer position The new position in bits.
function __BinaryWriter:align(bit_boundary) end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at a multiple of `bit_boundary`.
---
---@param bit_boundary? integer The boundary in bits, `8` (byte) by default.
---@return boolean is_aligned `true` if the cursor is aligned.
---@nodiscard
function __BinaryWriter:isAligned(bit_boundary) end

--- [SHARED AND MENU]
---
--- Checks if the cursor is at the end of the data, so the next write appends.
---
---@return boolean is_eof `true` if there is no data after the cursor.
---@nodiscard
function __BinaryWriter:isEndOfFile() end

--- [SHARED AND MENU]
---
--- Returns the size of the data after the cursor, that the next writes overwrite.
---
---@param as_bytes? boolean `true` to return the number of whole bytes, `false` (bits) by default.
---@return integer remaining The size of the data after the cursor.
---@nodiscard
function __BinaryWriter:remaining(as_bytes) end

--- [SHARED AND MENU]
---
--- Writes one bit.
---
---@param value 0 | 1 | boolean The bit.
function __BinaryWriter:writeBit(value) end

--- [SHARED AND MENU]
---
--- Writes one bit as a boolean, same as `net.WriteBool`.
---
---@param value boolean The boolean.
function __BinaryWriter:writeBoolean(value) end

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
function __BinaryWriter:writeUInt(value, bit_count, is_little_endian) end

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
function __BinaryWriter:writeInt(value, bit_count, is_little_endian) end

--- [SHARED AND MENU]
---
--- Writes the string as is, the cursor doesn't have to be aligned.
---
---@param data string The bytes.
---@return integer byte_count The number of bytes written.
function __BinaryWriter:write(data) end

--- [SHARED AND MENU]
---
--- Writes bytes, the cursor doesn't have to be aligned.
---
---@param ... integer The bytes (`0` - `255`).
---@return integer byte_count The number of bytes written.
function __BinaryWriter:writeBytes(...) end

--- [SHARED AND MENU]
---
--- Writes the string of a fixed size, shorter data is padded with `\0` and longer data is cut, same as `pack.writeFixedString`.
---
---@param data string The string.
---@param byte_count integer The size of the string in bytes.
function __BinaryWriter:writeFixedString(data, byte_count) end

--- [SHARED AND MENU]
---
--- Writes the string followed by the `terminator` byte, read it back with `BinaryReader:readTerminatedString`.
---
--- Throws an error if the string contains the terminator.
---
---@param data string The string.
---@param terminator integer The terminator byte (`0` - `255`).
function __BinaryWriter:writeTerminatedString(data, terminator) end

--- [SHARED AND MENU]
---
--- Writes C-style string, the string followed by the null terminator (`\0`), same as `net.WriteString`.
---
--- Throws an error if the string contains `\0`.
---
---@param data string The string.
function __BinaryWriter:writeString(data) end

--- [SHARED AND MENU]
---
--- Writes the line, the string followed by `\n`.
---
--- Throws an error if the string contains `\n`.
---
---@param data string The line.
function __BinaryWriter:writeLine(data) end

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
function __BinaryWriter:writeCountedString(data, bit_count, is_little_endian) end

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
function __BinaryWriter:writeUnsignedFixedPoint(value, m, n, is_little_endian) end

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
function __BinaryWriter:writeFixedPoint(value, m, n, is_little_endian) end

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
function __BinaryWriter:writeFloat(value, is_little_endian) end

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
function __BinaryWriter:writeDouble(value, is_little_endian) end

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
function __BinaryWriter:writeTime(hours, minutes, seconds, is_little_endian) end

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
function __BinaryWriter:writeDate(day, month, year, is_little_endian) end

--- [SHARED AND MENU]
---
--- Writes the object with its `__serialize( writer, ... )` method,
--- read it back with `BinaryReader:readObject` or `BinaryReader:readClass`.
---
---@param obj Object The object.
---@param ... any The arguments passed to `__serialize`.
function __BinaryWriter:writeObject(obj, ...) end
