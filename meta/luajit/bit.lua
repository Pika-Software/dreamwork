---@meta bit

---@version JIT
---
--- [SHARED AND MENU]
---
--- The LuaJIT bit operations library.
---
--- All operations work on 32-bit integers: arguments are normalized with
--- `bit.tobit` and results are signed 32-bit numbers in the range
--- `-2147483648` to `2147483647`, so `0xFFFFFFFF` comes back as `-1`.
---
--- Every function also accepts 64-bit `int64_t`/`uint64_t` cdata;
--- if any argument is 64-bit, the operation is done in 64 bits and the result
--- is cdata of that type (`bit.tobit` and `bit.tohex` excepted).
---
--- [View documents](https://bitop.luajit.org/api.html)
---
---@class bitlib
bit = {}

--- [SHARED AND MENU]
---
--- Normalizes a number to the numeric range of the bit operations, i.e. wraps it
--- to a signed 32-bit integer.
---
--- Non-integer numbers are rounded to the nearest integer, ties to even.
--- 64-bit cdata is truncated to its lower 32 bits and returned as a number.
---
--- ```lua
--- bit.tobit( 0xFFFFFFFF ) -- -1
--- bit.tobit( 0xFFFFFFFF + 1 ) -- 0
--- bit.tobit( 2 ^ 32 + 5 ) -- 5
--- bit.tobit( 2.5 ) -- 2
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#tobit)
---
---@param x integer | ffi.cdata* The number to normalize.
---@return integer y The signed 32-bit integer.
---@nodiscard
function bit.tobit( x ) end

--- [SHARED AND MENU]
---
--- Converts a number to a hexadecimal string.
---
--- `n` is the number of least significant hex digits to return,
--- by default `8` for numbers and `16` for 64-bit cdata.
--- A negative `n` returns `|n|` uppercase digits instead of lowercase ones.
---
--- ```lua
--- bit.tohex( 1 ) -- "00000001"
--- bit.tohex( -1 ) -- "ffffffff"
--- bit.tohex( 0x87654321, 4 ) -- "4321"
--- bit.tohex( 255, -2 ) -- "FF"
--- bit.tohex( 1ULL ) -- "0000000000000001"
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#tohex)
---
---@param x integer | ffi.cdata* The number to convert.
---@param n? integer The number of hex digits, negative for uppercase.
---@return string hex The hexadecimal string.
---@nodiscard
function bit.tohex( x, n ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *not* of its argument.
---
--- ```lua
--- bit.bnot( 0 ) -- -1
--- bit.bnot( 0x12345678 ) -- -305419897 (0xEDCBA987)
--- bit.bnot( 0ULL ) -- 18446744073709551615ULL
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#bnot)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to invert.
---@return T y The inverted number.
---@nodiscard
function bit.bnot( x ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *or* of all its arguments.
---
--- ```lua
--- bit.bor( 1, 2, 4, 8 ) -- 15
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#bor)
---
---@generic T: integer | ffi.cdata*
---@param x T The first number.
---@param ... T The other numbers.
---@return T y The bitwise *or* of the numbers.
---@nodiscard
function bit.bor( x, ... ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *and* of all its arguments.
---
--- ```lua
--- bit.band( 0x12345678, 0xFF ) -- 120 (0x78)
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#band)
---
---@generic T: integer | ffi.cdata*
---@param x T The first number.
---@param ... T The other numbers.
---@return T y The bitwise *and* of the numbers.
---@nodiscard
function bit.band( x, ... ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *xor* of all its arguments.
---
--- ```lua
--- bit.bxor( 0xA5A5A5A5, 0xF0F0F0F0 ) -- 1431655765 (0x55555555)
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#bxor)
---
---@generic T: integer | ffi.cdata*
---@param x T The first number.
---@param ... T The other numbers.
---@return T y The bitwise *xor* of the numbers.
---@nodiscard
function bit.bxor( x, ... ) end

--- [SHARED AND MENU]
---
--- Returns `x` shifted left by `n` bits, filling the vacant bits with zeros.
---
--- Only the lower 5 bits of `n` are used (6 bits for 64-bit cdata),
--- so shifting by `32` is the same as shifting by `0`.
---
--- ```lua
--- bit.lshift( 1, 8 ) -- 256
--- bit.lshift( 1, 31 ) -- -2147483648
--- bit.lshift( 1, 33 ) -- 2
--- bit.lshift( 1ULL, 40 ) -- 1099511627776ULL
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#shift)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to shift.
---@param n integer The number of bits to shift by.
---@return T y The shifted number.
---@nodiscard
function bit.lshift( x, n ) end

--- [SHARED AND MENU]
---
--- Returns `x` logically shifted right by `n` bits, filling the vacant bits with zeros.
---
--- Only the lower 5 bits of `n` are used (6 bits for 64-bit cdata).
---
--- ```lua
--- bit.rshift( 256, 8 ) -- 1
--- bit.rshift( -256, 8 ) -- 16777215 (0x00FFFFFF)
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#shift)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to shift.
---@param n integer The number of bits to shift by.
---@return T y The shifted number.
---@nodiscard
function bit.rshift( x, n ) end

--- [SHARED AND MENU]
---
--- Returns `x` arithmetically shifted right by `n` bits, filling the vacant bits
--- with copies of the sign bit.
---
--- Only the lower 5 bits of `n` are used (6 bits for 64-bit cdata).
---
--- ```lua
--- bit.arshift( 256, 8 ) -- 1
--- bit.arshift( -256, 8 ) -- -1
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#shift)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to shift.
---@param n integer The number of bits to shift by.
---@return T y The shifted number.
---@nodiscard
function bit.arshift( x, n ) end

--- [SHARED AND MENU]
---
--- Returns `x` rotated left by `n` bits.
---
--- Only the lower 5 bits of `n` are used (6 bits for 64-bit cdata).
---
--- ```lua
--- bit.tohex( bit.rol( 0x12345678, 12 ) ) -- "45678123"
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#rotate)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to rotate.
---@param n integer The number of bits to rotate by.
---@return T y The rotated number.
---@nodiscard
function bit.rol( x, n ) end

--- [SHARED AND MENU]
---
--- Returns `x` rotated right by `n` bits.
---
--- Only the lower 5 bits of `n` are used (6 bits for 64-bit cdata).
---
--- ```lua
--- bit.tohex( bit.ror( 0x12345678, 12 ) ) -- "67812345"
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#rotate)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to rotate.
---@param n integer The number of bits to rotate by.
---@return T y The rotated number.
---@nodiscard
function bit.ror( x, n ) end

--- [SHARED AND MENU]
---
--- Swaps the bytes of `x`, converting between little-endian and big-endian.
---
--- ```lua
--- bit.tohex( bit.bswap( 0x12345678 ) ) -- "78563412"
--- bit.tohex( bit.bswap( 0x0102030405060708ULL ) ) -- "0807060504030201"
--- ```
---
--- [View documents](https://bitop.luajit.org/api.html#bswap)
---
---@generic T: integer | ffi.cdata*
---@param x T The number to swap.
---@return T y The byte-swapped number.
---@nodiscard
function bit.bswap( x ) end

return bit
