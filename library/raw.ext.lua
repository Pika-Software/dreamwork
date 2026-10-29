---@meta _

--- [SHARED AND MENU]
---
--- Native **32-bit integer only** bit library.
---
---@class raw.bit
---@field operators boolean Whether the bit operators are available.
raw.bit = {}

---@class dreamwork.GModBitLib : bitlib
---@field bshift fun( x: integer, disp: integer ): integer
---@field brotate fun( x: integer, disp: integer ): integer
---@field btest fun( x: integer, ...: integer ): boolean
---@field extract fun( x: integer, field: integer, width?: integer ): integer
---@field replace fun( x: integer, extract: integer, field: integer, width?: integer ): integer
local glua_bit = {}

--- [SHARED AND MENU]
---
--- Normalizes the specified value to a signed 32-bit integer by wrapping it
--- around modulo `2^32`, so values outside the range are not clamped.
---
--- ```lua
--- rbit.tobit( 0xFFFFFFFF ) -- -1
--- rbit.tobit( 2 ^ 32 + 5 ) -- 5
--- ```
---
---@param x (integer | ffi.cdata*) The value to be normalized.
---@return integer result The normalized value, in the range `-2147483648` to `2147483647`.
---@nodiscard
function raw.bit.tobit(x) end

--- [SHARED AND MENU]
---
--- Returns the lowercase hexadecimal representation of the number, zero-padded to `length` digits.
---
--- ```lua
--- rbit.tohex( 255 ) -- "000000ff"
--- rbit.tohex( 255, 2 ) -- "ff"
--- ```
---
---@param x (integer | ffi.cdata*) The value to be converted.
---@param length integer? The number of digits, must be positive. Defaults to `8`.
---@return string str The hexadecimal representation.
---@nodiscard
function raw.bit.tohex(x, length) end

--- [SHARED AND MENU]
---
--- Performs a bitwise AND operation on all the specified 32-bit integers.
---
---@generic T: integer | ffi.cdata*
---@param x T The first value.
---@param ... T Additional values to AND together with the first.
---@return T result The bitwise AND of all given values, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.band(x, ...) end

--- [SHARED AND MENU]
---
--- Performs a bitwise OR operation on all the specified 32-bit integers.
---
---@generic T: integer | ffi.cdata*
---@param x T The first value.
---@param ... T Additional values to OR together with the first.
---@return T result The bitwise OR of all given values, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.bor(x, ...) end

--- [SHARED AND MENU]
---
--- Performs a bitwise XOR (exclusive OR) operation on all the specified 32-bit integers.
---
---@generic T: integer | ffi.cdata*
---@param x T The first value.
---@param ... T Additional values to XOR together with the first.
---@return T result The bitwise XOR of all given values, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.bxor(x, ...) end

--- [SHARED AND MENU]
---
--- Performs a bitwise NOT (one's complement) operation on the specified 32-bit integer.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be inverted.
---@return T result The bitwise complement of the given value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.bnot(x) end

--- [SHARED AND MENU]
---
--- Performs a logical left shift of the specified 32-bit integer by the given number of bits.
--- Bits shifted out of the top are discarded and zero bits are shifted in from the bottom.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be shifted.
---@param disp integer The number of bits to shift left by.
---@return T result The shifted value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.lshift(x, disp) end

--- [SHARED AND MENU]
---
--- Performs a logical right shift of the specified 32-bit integer by the given number of bits.
--- Bits shifted out of the bottom are discarded and zero bits are shifted in from the top,
--- regardless of the sign of the value.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be shifted.
---@param disp integer The number of bits to shift right by.
---@return T result The shifted value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.rshift(x, disp) end

--- [SHARED AND MENU]
---
--- Performs a logical bit shift of the specified 32-bit integer.
--- A positive displacement shifts left, a negative displacement shifts right.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be shifted.
---@param disp integer The number of bits to shift by. Positive shifts left, negative shifts right.
---@return T result The shifted value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.bshift(x, disp) end

--- [SHARED AND MENU]
---
--- Performs an arithmetic right shift of the specified 32-bit integer by the given number of bits.
--- Bits shifted out of the bottom are discarded and the sign bit is copied into the vacated
--- high-order bits, preserving the sign of the value.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be shifted.
---@param disp integer The number of bits to shift right by.
---@return T result The shifted value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.arshift(x, disp) end

--- [SHARED AND MENU]
---
--- Rotates the bits of the specified 32-bit integer to the left by the given number of bits.
--- Bits shifted out of the top are wrapped around and shifted in at the bottom.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be rotated.
---@param disp integer The number of bits to rotate left by.
---@return T result The rotated value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.lrotate(x, disp) end

--- [SHARED AND MENU]
---
--- Rotates the bits of the specified 32-bit integer to the right by the given number of bits.
--- Bits shifted out of the bottom are wrapped around and shifted in at the top.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be rotated.
---@param disp integer The number of bits to rotate right by.
---@return T result The rotated value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.rrotate(x, disp) end

--- [SHARED AND MENU]
---
--- Rotates the bits of the specified 32-bit integer.
--- A positive displacement rotates left, a negative displacement rotates right.
---
---@generic T: integer | ffi.cdata*
---@param x T The value to be rotated.
---@param disp integer The number of bits to rotate by. Positive rotates left, negative rotates right.
---@return T result The rotated value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.brotate(x, disp) end

--- [SHARED AND MENU]
---
--- Performs a bitwise AND operation on all the specified 32-bit integers and returns whether
--- the result is non-zero.
---
---@generic T: integer | ffi.cdata*
---@param x T The first value.
---@param ... T Additional values to AND together with the first.
---@return boolean result `true` if the bitwise AND of all given values is non-zero, `false` otherwise.
---@nodiscard
function raw.bit.btest(x, ...) end

--- [SHARED AND MENU]
---
--- Extracts a bit field of the given width from the specified 32-bit integer, starting at
--- the given bit position (0-indexed, counted from the least significant bit).
---
--- ```lua
--- rbit.extract( 0xB4, 2, 3 ) -- 5 (0b10110100 -> 0b101)
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The value to extract the bit field from.
---@param field integer The starting bit position of the field (0-indexed).
---@param width integer? The number of bits in the field. Defaults to `1`.
---@return T result The extracted bit field, right-aligned as an unsigned integer.
---@nodiscard
function raw.bit.extract(x, field, width) end

--- [SHARED AND MENU]
---
--- Replaces a bit field of the given width in the specified 32-bit integer, starting at the
--- given bit position (0-indexed, counted from the least significant bit), with the bits
--- taken from `extract`.
---
---@generic T: integer | ffi.cdata*
---@param x T The value whose bit field is to be replaced.
---@param extract T The value providing the replacement bits (only the lowest `width` bits are used).
---@param field integer The starting bit position of the field to replace (0-indexed).
---@param width integer? The number of bits in the field. Defaults to `1`.
---@return T result The value of `x` with the specified bit field replaced.
---@nodiscard
function raw.bit.replace(x, extract, field, width) end

--- [SHARED AND MENU]
---
--- Swaps the byte order (endianness) of the specified 32-bit integer, reversing the order
--- of its four constituent bytes.
---
---@generic T: integer | ffi.cdata*
---@param x T The value whose byte order is to be swapped.
---@return T result The byte-swapped value, normalized to a signed 32-bit integer.
---@nodiscard
function raw.bit.bswap(x) end

--- [SHARED AND MENU]
---
--- Reverses the order of the lowest `bit_count` bits of `x`, so the least significant bit
--- becomes the most significant bit (within that range) and vice versa.
---
--- ```lua
--- rbit.reverse( 0x58, 7 ) -- 13 (0b1011000 -> 0b0001101)
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The value whose bits are to be reversed.
---@param bit_count integer? The number of low-order bits to reverse. Defaults to `32`.
---@return T result The value of `x` with its bits reversed.
---@nodiscard
function raw.bit.reverse(x, bit_count) end

--- [SHARED AND MENU]
---
--- Converts an unsigned `bit_count`-bit integer to its signed (two's complement) value,
--- the inverse of `rbit.unsign`.
---
--- Every positive `x` has `2 ^ bit_count` subtracted from it, so only pass values that have
--- the sign bit set; zero and negative values are returned unchanged.
---
--- ```lua
--- rbit.sign( 0xFFFFFFFF ) -- -1
--- rbit.sign( 0xFF, 8 ) -- -1
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The unsigned integer to convert.
---@param bit_count? integer The bit width of the integer, `32` by default.
---@return T result The signed value of the integer.
---@nodiscard
function raw.bit.sign(x, bit_count) end

--- [SHARED AND MENU]
---
--- Converts a signed `bit_count`-bit integer to its unsigned value, the inverse of `rbit.sign`.
---
--- Negative values have `2 ^ bit_count` added to them; zero and positive values are returned unchanged.
---
--- ```lua
--- rbit.unsign( -1 ) -- 4294967295
--- rbit.unsign( -1, 8 ) -- 255
--- ```
---
---@generic T: integer | ffi.cdata*
---@param x T The signed integer to convert.
---@param bit_count? integer The bit width of the integer, `32` by default.
---@return T result The unsigned value of the integer.
---@nodiscard
function raw.bit.unsign(x, bit_count) end
