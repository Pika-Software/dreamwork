---@meta _

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
---@class pack
pack = {}

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
function pack.readUInt8(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 1-byte (8 bit) integer as a string.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param value integer The unsigned 1-byte integer.
---@return string data The 1-byte string.
---@nodiscard
function pack.writeUInt8(value) end

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
function pack.readInt8(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 1-byte (8 bit) integer as a string.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param value integer The signed 1-byte integer.
---@return string data The 1-byte string.
---@nodiscard
function pack.writeInt8(value) end

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
function pack.readUInt16BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param value integer The unsigned 2-byte integer.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeUInt16BE(value) end

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
function pack.readInt16BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 2-byte (16 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param value integer The signed 2-byte integer.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeInt16BE(value) end

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
function pack.readUInt16LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `65535`
---
---@param value integer The unsigned 2-byte integer.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeUInt16LE(value) end

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
function pack.readInt16LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 2-byte (16 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-32768` - `32767`
---
---@param value integer The signed 2-byte integer.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeInt16LE(value) end

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
function pack.readUInt24BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param value integer The unsigned 3-byte integer.
---@return string data The 3-byte string.
---@nodiscard
function pack.writeUInt24BE(value) end

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
function pack.readInt24BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 3-byte (24 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param value integer The signed 3-byte integer.
---@return string data The 3-byte string.
---@nodiscard
function pack.writeInt24BE(value) end

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
function pack.readUInt24LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 3-byte (24 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `16777215`
---
---@param value integer The unsigned 3-byte integer.
---@return string data The 3-byte string.
---@nodiscard
function pack.writeUInt24LE(value) end

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
function pack.readInt24LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 3-byte (24 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-8388608` - `8388607`
---
---@param value integer The signed 3-byte integer.
---@return string data The 3-byte string.
---@nodiscard
function pack.writeInt24LE(value) end

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
function pack.readUInt32BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 4-byte (32 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param value integer The unsigned 4-byte integer.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeUInt32BE(value) end

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
function pack.readInt32BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 4-byte (32 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param value integer The signed 4-byte integer.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeInt32BE(value) end

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
function pack.readUInt32LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 4-byte (32 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `4294967295`
---
---@param value integer The unsigned 4-byte integer.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeUInt32LE(value) end

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
function pack.readInt32LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 4-byte (32 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-2147483648` - `2147483647`
---
---@param value integer The signed 4-byte integer.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeInt32LE(value) end

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
function pack.readUInt40BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 5-byte (40 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `1099511627775`.
---
---@param value integer The unsigned 5-byte integer.
---@return string data The 5-byte string.
---@nodiscard
function pack.writeUInt40BE(value) end

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
function pack.readInt40BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 5-byte (40 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-549755813888` - `549755813887`
---
---@param value integer The signed 5-byte integer.
---@return string data The 5-byte string.
---@nodiscard
function pack.writeInt40BE(value) end

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
function pack.readUInt40LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 5-byte (40 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `1099511627775`.
---
---@param value integer The unsigned 5-byte integer.
---@return string data The 5-byte string.
---@nodiscard
function pack.writeUInt40LE(value) end

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
function pack.readInt40LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 5-byte (40 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-549755813888` - `549755813887`
---
---@param value integer The signed 5-byte integer.
---@return string data The 5-byte string.
---@nodiscard
function pack.writeInt40LE(value) end

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
function pack.readUInt48BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 6-byte (48 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `0` - `281474976710655`
---
---@param value integer The unsigned 6-byte integer.
---@return string data The 6-byte string.
---@nodiscard
function pack.writeUInt48BE(value) end

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
function pack.readInt48BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 6-byte (48 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
---
---@param value integer The signed 6-byte integer.
---@return string data The 6-byte string.
---@nodiscard
function pack.writeInt48BE(value) end

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
function pack.readUInt48LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes unsigned 6-byte (48 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `0` - `281474976710655`
---
---@param value integer The unsigned 6-byte integer.
---@return string data The 6-byte string.
---@nodiscard
function pack.writeUInt48LE(value) end

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
function pack.readInt48LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 6-byte (48 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-140737488355328` - `140737488355327`
---
---@param value integer The signed 6-byte integer.
---@return string data The 6-byte string.
---@nodiscard
function pack.writeInt48LE(value) end

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
function pack.readUInt56BE(str, index) end

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
function pack.writeUInt56BE(value) end

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
function pack.readInt56BE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 7-byte (56 bit) integer as big endian bytes.
---
--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
---
---@param value integer The signed 7-byte integer.
---@return string data The 7-byte string.
---@nodiscard
function pack.writeInt56BE(value) end

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
function pack.readUInt56LE(str, index) end

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
function pack.writeUInt56LE(value) end

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
function pack.readInt56LE(str, index) end

--- [SHARED AND MENU]
---
--- Writes signed 7-byte (56 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-36028797018963968` - `36028797018963967`
---
---@param value integer The signed 7-byte integer.
---@return string data The 7-byte string.
---@nodiscard
function pack.writeInt56LE(value) end

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
function pack.readUInt64BE(str, index) end

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
function pack.writeUInt64BE(value) end

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
function pack.readInt64BE(str, index) end

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
function pack.writeInt64BE(value) end

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
function pack.readUInt64LE(str, index) end

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
function pack.writeUInt64LE(value) end

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
function pack.readInt64LE(str, index) end

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
function pack.writeInt64LE(value) end

--- [SHARED AND MENU]
---
--- Reads single precision (4-byte, 32 bit) floating point number from big endian bytes of the string.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return number value The floating point number.
---@nodiscard
function pack.readFloatBE(str, index) end

--- [SHARED AND MENU]
---
--- Writes single precision (4-byte, 32 bit) floating point number as big endian bytes.
---
---@param value number The floating point number.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeFloatBE(value) end

--- [SHARED AND MENU]
---
--- Reads single precision (4-byte, 32 bit) floating point number from little endian bytes of the string.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return number value The floating point number.
---@nodiscard
function pack.readFloatLE(str, index) end

--- [SHARED AND MENU]
---
--- Writes single precision (4-byte, 32 bit) floating point number as little endian bytes.
---
---@param value number The floating point number.
---@return string data The 4-byte string.
---@nodiscard
function pack.writeFloatLE(value) end

--- [SHARED AND MENU]
---
--- Reads double precision (8-byte, 64 bit) floating point number from big endian bytes of the string.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return number value The floating point number.
---@nodiscard
function pack.readDoubleBE(str, index) end

--- [SHARED AND MENU]
---
--- Writes double precision (8-byte, 64 bit) floating point number as big endian bytes.
---
---@param value number The floating point number.
---@return string data The 8-byte string.
---@nodiscard
function pack.writeDoubleBE(value) end

--- [SHARED AND MENU]
---
--- Reads double precision (8-byte, 64 bit) floating point number from little endian bytes of the string.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return number value The floating point number.
---@nodiscard
function pack.readDoubleLE(str, index) end

--- [SHARED AND MENU]
---
--- Writes double precision (8-byte, 64 bit) floating point number as little endian bytes.
---
---@param value number The floating point number.
---@return string data The 8-byte string.
---@nodiscard
function pack.writeDoubleLE(value) end

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
function pack.readTimeBE(str, index) end

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
function pack.readTimeLE(str, index) end

--- [SHARED AND MENU]
---
--- Writes 2-byte (16 bit) DOS time as big endian bytes.
---
---@param hours? integer The number of hours.
---@param minutes? integer The number of minutes.
---@param seconds? integer The number of seconds, **will be rounded**.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeTimeBE(hours, minutes, seconds) end

--- [SHARED AND MENU]
---
--- Writes 2-byte (16 bit) DOS time as little endian bytes.
---
---@param hours? integer The number of hours.
---@param minutes? integer The number of minutes.
---@param seconds? integer The number of seconds, **will be rounded**.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeTimeLE(hours, minutes, seconds) end

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
function pack.readDateBE(str, index) end

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
function pack.readDateLE(str, index) end

--- [SHARED AND MENU]
---
--- Writes 2-byte (16 bit) DOS date as big endian bytes.
---
---@param day? integer The day.
---@param month? integer The month.
---@param year? integer The year.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeDateBE(day, month, year) end

--- [SHARED AND MENU]
---
--- Writes 2-byte (16 bit) DOS date as little endian bytes.
---
---@param day? integer The day.
---@param month? integer The month.
---@param year? integer The year.
---@return string data The 2-byte string.
---@nodiscard
function pack.writeDateLE(day, month, year) end

--- [SHARED AND MENU]
---
--- Reads the string of a fixed size.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@param length? integer The size of the string in bytes, the rest of the data by default.
---@return string data The string.
---@nodiscard
function pack.readFixedString(str, index, length) end

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
function pack.writeFixedString(data, length) end

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
function pack.readTerminatedString(str, index, terminator) end

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
function pack.writeTerminatedString(data, terminator) end

--- [SHARED AND MENU]
---
--- Reads C-style string, the null terminator (`\0`) is required.
---
---@param str string The string to read from.
---@param index? integer The index of the first byte (`1`-based), `1` by default.
---@return string data The bytes before the null terminator.
---@return integer data_length The number of bytes read, including the null terminator.
---@nodiscard
function pack.readNullTerminatedString(str, index) end

--- [SHARED AND MENU]
---
--- Writes C-style string, the string followed by the null terminator (`\0`).
---
--- Throws an error if the string contains `\0`.
---
---@param data string The string to write.
---@return string data The null terminated string.
---@nodiscard
function pack.writeNullTerminatedString(data) end

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
function pack.readLineTerminatedString(str, index) end

--- [SHARED AND MENU]
---
--- Writes the line, the string followed by `\n`.
---
--- Throws an error if the string contains `\n`.
---
---@param data string The string to write.
---@return string data The line.
---@nodiscard
function pack.writeLineTerminatedString(data) end

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
function pack.readCountedString(str, index, length_size, is_little_endian) end

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
function pack.writeCountedString(data, length_size, is_little_endian) end

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
function pack.readBit(str, bit_position) end

--- [SHARED AND MENU]
---
--- Reads one bit from the string as a boolean, same as `net.ReadBool`.
---
---@param str string The string to read from.
---@param bit_position? integer The position of the bit (`0`-based), `0` by default.
---@return boolean value `true` if the bit is `1`.
---@nodiscard
function pack.readBoolean(str, bit_position) end

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
function pack.readBytes(str, bit_position, byte_count) end

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
function pack.readUInt(str, bit_position, bit_count, is_little_endian) end

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
function pack.readInt(str, bit_position, bit_count, is_little_endian) end

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
function pack.readUnsignedFixedPoint(str, bit_position, m, n, is_little_endian) end

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
function pack.readFixedPoint(str, bit_position, m, n, is_little_endian) end
