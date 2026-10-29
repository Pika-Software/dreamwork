---@meta _

--- [SHARED AND MENU]
---
--- Library that packs & unpacks types as bytes.
---
---@class bytepack
bytepack = {}

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer from bytes.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param uint8_1 integer The byte.
---@return integer value The unsigned 1-byte integer.
---@nodiscard
function bytepack.readUInt8(uint8_1) end

--- [SHARED AND MENU]
---
--- Writes unsigned 1-byte (8 bit) integer as bytes.
---
--- Valid values without loss of precision: `0` - `255`
---
---@param value integer The unsigned 1-byte integer.
---@return integer uint8_1 The byte.
---@nodiscard
function bytepack.writeUInt8(value) end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param uint8_1 integer The byte.
---@return integer value The signed 1-byte integer.
---@nodiscard
function bytepack.readInt8(uint8_1) end

--- [SHARED AND MENU]
---
--- Writes signed 1-byte (8 bit) integer as little endian bytes.
---
--- Valid values without loss of precision: `-128` - `127`
---
---@param value integer The signed 1-byte integer.
---@return integer uint8_1 The byte.
---@nodiscard
function bytepack.writeInt8(value) end

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
function bytepack.readInt16BE(uint8_1, uint8_2) end

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
function bytepack.readUInt16BE(uint8_1, uint8_2) end

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
function bytepack.writeInt16BE(value) end

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
function bytepack.writeUInt16BE(value) end

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
function bytepack.readInt16LE(uint8_1, uint8_2) end

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
function bytepack.readUInt16LE(uint8_1, uint8_2) end

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
function bytepack.writeInt16LE(value) end

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
function bytepack.writeUInt16LE(value) end

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
function bytepack.readInt24BE(uint8_1, uint8_2, uint8_3) end

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
function bytepack.readUInt24BE(uint8_1, uint8_2, uint8_3) end

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
function bytepack.writeInt24BE(value) end

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
function bytepack.writeUInt24BE(value) end

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
function bytepack.readInt24LE(uint8_1, uint8_2, uint8_3) end

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
function bytepack.readUInt24LE(uint8_1, uint8_2, uint8_3) end

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
function bytepack.writeInt24LE(value) end

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
function bytepack.writeUInt24LE(value) end

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
function bytepack.readInt32BE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.readUInt32BE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.writeInt32BE(value) end

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
function bytepack.writeUInt32BE(value) end

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
function bytepack.readInt32LE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.readUInt32LE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.writeInt32LE(value) end

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
function bytepack.writeUInt32LE(value) end

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
function bytepack.readUInt40BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5) end

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
function bytepack.readInt40BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5) end

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
function bytepack.writeUInt40BE(value) end

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
function bytepack.writeInt40BE(value) end

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
function bytepack.readUInt40LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5) end

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
function bytepack.readInt40LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5) end

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
function bytepack.writeUInt40LE(value) end

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
function bytepack.writeInt40LE(value) end

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
function bytepack.readUInt48BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6) end

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
function bytepack.readInt48BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6) end

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
function bytepack.writeUInt48BE(value) end

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
function bytepack.writeInt48BE(value) end

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
function bytepack.readUInt48LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6) end

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
function bytepack.readInt48LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6) end

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
function bytepack.writeUInt48LE(value) end

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
function bytepack.writeInt48LE(value) end

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
function bytepack.readUInt56BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7) end

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
function bytepack.readInt56BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7) end

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
function bytepack.writeUInt56BE(value) end

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
function bytepack.writeInt56BE(value) end

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
function bytepack.readUInt56LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7) end

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
function bytepack.readInt56LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7) end

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
function bytepack.writeUInt56LE(value) end

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
function bytepack.writeInt56LE(value) end

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
function bytepack.readUInt64BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.readInt64BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.writeUInt64BE(value) end

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
function bytepack.writeInt64BE(value) end

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
function bytepack.readUInt64LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.readInt64LE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.writeUInt64LE(value) end

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
function bytepack.writeInt64LE(value) end

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
function bytepack.readFloatBE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.readFloatLE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.writeFloatBE(value) end

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
function bytepack.writeFloatLE(value) end

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
function bytepack.readDoubleBE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.readDoubleLE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.writeDoubleBE(value) end

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
function bytepack.writeDoubleLE(value) end

---@class bytepack.FFIUnion : ffi.cdata*
---@field bytes integer[]
---@field u32 integer
---@field f32 number
---@field f64 number

---@param uint8_1 integer
---@param uint8_2 integer
---@param uint8_3 integer
---@param uint8_4 integer
---@return number
---@nodiscard
function bytepack.readFloatBE(uint8_1, uint8_2, uint8_3, uint8_4) end

---@param uint8_1 integer
---@param uint8_2 integer
---@param uint8_3 integer
---@param uint8_4 integer
---@return number
---@nodiscard
function bytepack.readFloatLE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.readDoubleLE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.readDoubleBE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

--- [SHARED AND MENU]
---
--- Reads `hours`, `minutes` and `seconds` from single `Short` number ( UInt16 ).
---
---@param uint16 integer The uint16 to read from.
---@return integer hours The number of hours.
---@return integer minutes The number of minutes.
---@return integer seconds The number of seconds, **will be rounded**.
---@nodiscard
function bytepack.readTime(uint16) end

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
function bytepack.writeTime(hours, minutes, seconds) end

--- [SHARED AND MENU]
---
--- Reads date in DOS format from single `Short` number ( UInt16 ).
---
---@param uint16 integer The uint16 to read from.
---@return integer day The day.
---@return integer month The month.
---@return integer year The year.
---@nodiscard
function bytepack.readDate(uint16) end

--- [SHARED AND MENU]
---
--- Writes date in DOS format as single `Short` number ( UInt16 ).
---
---@param day? integer The day.
---@param month? integer The month.
---@param year? integer The year.
---@return integer uint16 The uint16 to read from.
---@nodiscard
function bytepack.writeDate(day, month, year) end

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
function bytepack.readFixedPoint(n, integer) end

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
function bytepack.writeFixedPoint(value, m, n) end

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer from big endian hex bytes.
---
---@param uint8_1 integer The first byte.
---@param uint8_2 integer The second byte.
---@return integer | nil value The unsigned 1-byte integer or `nil` if bytes do not match the allowed ones.
---@nodiscard
function bytepack.readHex8(uint8_1, uint8_2) end

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
function bytepack.readHex16BE(uint8_1, uint8_2, uint8_3, uint8_4) end

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
function bytepack.readHex24BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6) end

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
function bytepack.readHex32BE(uint8_1, uint8_2, uint8_3, uint8_4, uint8_5, uint8_6, uint8_7, uint8_8) end

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
function bytepack.writeHex8(uint8) end

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
function bytepack.writeHex16BE(uint16) end

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
function bytepack.writeHex16LE(uint16) end

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
function bytepack.writeHex24BE(uint24) end

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
function bytepack.writeHex24LE(uint24) end

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
function bytepack.writeHex32BE(uint32) end

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
function bytepack.writeHex32LE(uint32) end
