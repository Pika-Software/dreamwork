---@meta _

--- [SHARED AND MENU]
---
--- Represents an arbitrary-precision signed integer.
---
--- A `BigInteger` object can represent any integer value that fits in
--- available memory. It supports arithmetic, comparison, conversion,
--- and bitwise operations while preserving exact integer precision.
---
---@class BigInteger : Object
---@field __class BigIntegerClass
---@field limbs integer[] The magnitude as little-endian 16-bit limbs, `limbs[ 0 ]` is the limb count.
---@field sign boolean
---@operator add( any ): BigInteger
---@operator sub( any ): BigInteger
---@operator mul( any ): BigInteger
---@operator div( any ): BigInteger
---@operator idiv( any ): BigInteger
---@operator pow( integer ): BigInteger
---@operator unm: BigInteger
---@operator bnot: BigInteger
---@operator band( any ): BigInteger
---@operator bor( any ): BigInteger
---@operator bxor( any ): BigInteger
---@operator shl( integer ): BigInteger
---@operator shr( integer ): BigInteger
---@operator len: integer
---@operator concat( any ): string
local __BigInteger = {}

--- [SHARED AND MENU]
---
--- The class used to create new `BigInteger` instances.
---
--- Arbitrary-precision signed integer type.
---
--- Unlike Lua's built-in integers, `BigInteger` values are limited only by
--- available memory, allowing calculations on integers of virtually
--- unlimited size without overflow.
---
--- Supports the standard arithmetic, comparison, and bitwise operators
--- through metamethods.
---
---@class BigIntegerClass : BigInteger
---@field __base BigInteger
---@overload fun( value: ( BigInteger | string | integer | nil ), base: ( integer | nil ) ): BigInteger
BigInteger = {}

--- [SHARED AND MENU]
---
--- Checks whether the value is a `BigInteger`.
---
---@param value any The value to check.
---@return boolean is_bigint `true` if the value is a `BigInteger`, `false` otherwise.
---@nodiscard
function isBigInteger(value) end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is zero/empty.
---
---@return boolean is_zero `true` if the big integer object is zero/empty, `false` otherwise.
---@nodiscard
function __BigInteger:isZero() end

__BigInteger.isEmpty = __BigInteger

---@return boolean
---@protected
function __BigInteger:__toboolean() end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is even.
---
---@return boolean result `true` if the big integer object is even, `false` otherwise.
---@nodiscard
function __BigInteger:isEven() end

--- [SHARED AND MENU]
---
--- Checks if a big integer object is odd.
---
---@return boolean `true` if the big integer object is odd, `false` otherwise.
---@nodiscard
function __BigInteger:isOdd() end

--- [SHARED AND MENU]
---
--- Negates a big integer object.
---
---@return BigInteger self The negated big integer object.
function __BigInteger:negate() end

---@return integer
---@protected
function __BigInteger:__len() end

---@param as_bytes boolean
---@return integer
---@protected
function __BigInteger:__sizeof(as_bytes) end

--- [SHARED AND MENU]
---
--- Sets a `BigInteger` object from Lua integer.
---
---@param value integer The number to convert.
---@return BigInteger self
function __BigInteger:fromInteger(value) end

--- [SHARED AND MENU]
---
--- Sets a `BigInteger` object from a decimal string.
---
---@param str string The string representation of the big integer.
---@param base? integer The numerical base of the digits in the input value. Can be any integer between 2 and 36, inclusive. By default: `10`
---@param start_position? integer The start position to read from.
---@param end_position? integer The end position to read to.
---@return BigInteger self
function __BigInteger:fromString(str, base, start_position, end_position) end

---@param value BigInteger | string | integer | nil
---@param base integer | nil
---@protected
function __BigInteger:__init(value, base) end

--- [SHARED AND MENU]
---
--- Creates a `BigInteger` object from the given value.
---
--- If `value` is already a `BigInteger`, it is returned unchanged.
---
---@param value any The value to convert to a `BigInteger`.
---@param base? integer The numeric base used when parsing string values. Must be between `2` and `36` (inclusive). Defaults to `10`.
---@return BigInteger obj
---@nodiscard
function toBigInteger(value, base) end

toBigInt = toBigInteger

--- [SHARED AND MENU]
---
--- Replaces the contents of this `BigInteger` with the given bytes.
---
--- The bytes are interpreted in big-endian order (most significant byte first).
--- If `signed` is `true`, the resulting value is interpreted as a signed
--- two's-complement integer.
---
---@param signed boolean Whether the byte sequence represents a signed integer.
---@param ... integer The bytes to store, each in the range `0`–`255`.
---@return BigInteger self
function __BigInteger:fromBytes(signed, ...) end

--- [SHARED AND MENU]
---
--- Creates a new `BigInteger` from the given bytes.
---
--- The bytes are interpreted in big-endian order (most significant byte first).
--- If `signed` is `true`, the resulting value is interpreted as a signed
--- two's-complement integer.
---
---@param signed boolean Whether the byte sequence represents a signed integer.
---@param ... integer The bytes of the integer, each in the range `0`–`255`.
---@return BigInteger new_obj
---@nodiscard
function BigInteger.fromBytes(signed, ...) end

--- [SHARED AND MENU]
---
--- Compares the `BigInteger` with the given value.
---
--- Unlike the `==`, `<` and `<=` operators, this also works with plain Lua numbers and strings.
---
---@param value any The value to compare with (will be converted into `BigInteger`).
---@return `-1` | `0` | `1` result `-1` if `self < value`, `0` if equal, `1` if `self > value`.
---@nodiscard
function __BigInteger:compare(value) end

---@param value any
---@return boolean
---@protected
function __BigInteger:__eq(value) end

---@param value any
---@return boolean
---@protected
function __BigInteger:__lt(value) end

---@param value any
---@return boolean
---@protected
function __BigInteger:__le(value) end

--- [SHARED AND MENU]
---
--- Makes a copy of the `BigInteger` object.
---
---@return BigInteger new_obj
---@nodiscard
function __BigInteger:copy() end

--- [SHARED AND MENU]
---
--- Converts a big integer object to a lua_number (always an integer).
---
---@return integer value The number that the big integer object represents.
---@nodiscard
function __BigInteger:toInteger() end

--- [SHARED AND MENU]
---
--- Converts the big integer to a string in the specified (or not) base.
---
---@param base? integer The numerical base of the digits in the input value. Can be any integer between 2 and 36, inclusive. By default: `10`
---@return string str The string representation of the big integer.
---@nodiscard
function __BigInteger:toString(base) end

---@param self BigInteger
---@return string
---@nodiscard
---@protected
function __BigInteger.__tohex(self) end

--- [SHARED AND MENU]
---
--- Converts the big integer into a hex string.
---
---@return string hex_str The hex string representation of the big integer.
---@nodiscard
function __BigInteger:toHexString() end

--- [SHARED AND MENU]
---
--- Converts the big integer to a binary [01] string.
---
--- The output is zero-padded to a whole number of bytes.
---
---@return string str The binary string representation of the big integer.
---@nodiscard
function __BigInteger:toBinaryString() end

---@return string
---@protected
function __BigInteger:__tostring() end

---@return string
---@protected
function __BigInteger:__represent() end

---@param value any
---@return string
---@protected
function __BigInteger:__concat(value) end

---@return BigInteger new_obj The new negated big integer object.
---@protected
function __BigInteger:__unm() end

--- [SHARED AND MENU]
---
--- Makes a big integer object absolute (simply removes the sign).
---
---@return BigInteger self The absolute big integer object.
function __BigInteger:abs() end

--- [SHARED AND MENU]
---
--- Summarizes the current `BigInteger` with the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return BigInteger object The result of the operation.
function __BigInteger:add(value) end

---@param value any
---@return BigInteger new_object
---@protected
function __BigInteger:__add(value) end

--- [SHARED AND MENU]
---
--- Subtract the current `BigInteger` by the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return BigInteger object The result of the operation.
function __BigInteger:sub(value) end

---@param value any
---@return BigInteger new_object
---@protected
function __BigInteger:__sub(value) end

--- [SHARED AND MENU]
---
--- Multiplies the current `BigInteger` by the specified value.
---
---@param value any The second value to be converted into `BigInteger`.
---@return BigInteger object The result of the operation.
function __BigInteger:mul(value) end

---@param value any
---@return BigInteger new_object
---@protected
function __BigInteger:__mul(value) end

--- [SHARED AND MENU]
---
--- Shifts a big integer object to the left by a given number of bits (positive or negative).
---
---@param shift integer The number of bits to shift by.
---@return BigInteger object The shifted big integer object.
function __BigInteger:lshift(shift) end

--- [SHARED AND MENU]
---
--- Checks if `BigInteger` is a power of two.
---
---@return boolean is_pot `true` if a number is a valid power-of-two, otherwise `false`.
---@nodiscard
function __BigInteger:isPowerOfTwo() end

---@param shift integer
---@return BigInteger new_object
---@protected
function __BigInteger:__shl(shift) end

--- [SHARED AND MENU]
---
--- Raises a big integer object to a power.
---
---@param value integer The value to raise to.
---@return BigInteger self The result of the operation.
function __BigInteger:pow(value) end

---@param value integer | BigInteger
---@return BigInteger new_object
---@protected
function __BigInteger:__pow(value) end

--- [SHARED AND MENU]
---
--- Divides the current `BigInteger` with the specified value.
---
---@param value any The second value to divide by (will be converted into `BigInteger`).
---@return BigInteger quotient The quotient.
---@return BigInteger remainder The remainder.
function __BigInteger:div(value) end

---@param value any
---@return BigInteger quotient
---@protected
function __BigInteger:__div(value) end

--- [SHARED AND MENU]
---
--- Calculates modulus (remainder after division);
---
--- Handles Lua-to-BigInteger conversions and non-positive cases correctly.
---
---@param value any The value to divide by.
---@return BigInteger remainder The remainder (same sign as self, or zero).
---@nodiscard
function __BigInteger:mod(value) end

---@param value any
---@return BigInteger remainder
---@protected
function __BigInteger:__mod(value) end

--- [SHARED AND MENU]
---
--- Returns the log2 of a big integer object.
---
---@return number result The base-2 logarithm of the big integer object. NaN for negative values, -inf for zero.
---@nodiscard
function __BigInteger:log2() end

--- [SHARED AND MENU]
---
--- Shifts a big integer object to the right by a given number of bits (positive or negative).
---
---@param shift integer The number of bits to shift by.
---@return BigInteger object The shifted big integer object.
function __BigInteger:rshift(shift) end

---@param shift integer
---@return BigInteger new_object
---@protected
function __BigInteger:__shr(shift) end

--- [SHARED AND MENU]
---
--- Performs a bitwise OR operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return BigInteger object The result of the operation.
function __BigInteger:bor(value) end

---@param ... any
---@return BigInteger new_object
---@protected
function __BigInteger:__bor(...) end

--- [SHARED AND MENU]
---
--- Performs a bitwise AND operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return BigInteger new_object The result of the operation.
function __BigInteger:band(value) end

---@param ... any
---@return BigInteger new_object
---@protected
function __BigInteger:__band(...) end

--- [SHARED AND MENU]
---
--- Performs a bitwise NOT operation on a big integer object.
---
---@return BigInteger object The result of the operation.
function __BigInteger:bnot() end

---@return BigInteger
---@protected
function __BigInteger:__bnot() end

--- [SHARED AND MENU]
---
--- Converts unsigned `BigInteger` to signed one.
---
---@param byte_width integer The byte width to interpret the raw magnitude at (e.g. 1 for int8, 4 for int32).
---@return BigInteger object Self, reinterpreted as a signed integer of the given byte width.
function __BigInteger:toSigned(byte_width) end

--- [SHARED AND MENU]
---
--- Converts signed `BigInteger` to unsigned one.
---
---@param byte_width integer The byte width to encode as (e.g. 1 for uint8, 4 for uint32).
---@return BigInteger self
function __BigInteger:toUnsigned(byte_width) end

--- [SHARED AND MENU]
---
--- Performs a bitwise XOR operation between two big integer objects.
---
---@param value any The value to perform the operation on.
---@return BigInteger object The result of the operation.
function __BigInteger:bxor(value) end

---@param value any
---@return BigInteger
---@protected
function __BigInteger:__bxor(value) end
