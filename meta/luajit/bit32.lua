---@diagnostic disable: deprecated
---@meta bit32

---@version 5.2
---
--- [SHARED AND MENU]
---
--- The Lua 5.2 bitwise operations library.
---
--- All operations work on unsigned 32-bit integers: arguments are taken modulo `2^32`
--- and results are in the range `0` to `4294967295`, so `-1` comes back as `0xFFFFFFFF`.
---
--- Displacements may be negative and shift or rotate in the opposite direction.
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#6.7)
---
---@class bit32lib
bit32 = {}

--- [SHARED AND MENU]
---
--- Returns `x` arithmetically shifted right by `disp` bits, filling the vacant bits
--- on the left with copies of the highest bit of `x`.
---
--- A negative `disp` shifts left, filling the vacant bits on the right with zeros.
--- Displacements of 32 or more give `0xFFFFFFFF` when the highest bit is set, `0` otherwise.
---
--- ```lua
--- bit32.arshift( 256, 8 ) -- 1
--- bit32.arshift( -256, 8 ) -- 4294967295 (0xFFFFFFFF)
--- bit32.arshift( 0xF0000000, 4 ) -- 4278190080 (0xFF000000)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.arshift)
---
---@param x integer The number to shift.
---@param disp integer The number of bits to shift right by, negative to shift left.
---@return integer y The shifted number.
---@nodiscard
function bit32.arshift( x, disp ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *and* of all its arguments.
---
--- Without arguments returns `0xFFFFFFFF`.
---
--- ```lua
--- bit32.band( 0x12345678, 0xFF ) -- 120 (0x78)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.band)
---
---@param ... integer The numbers.
---@return integer y The bitwise *and* of the numbers.
---@nodiscard
function bit32.band( ... ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *not* of `x`, i.e. `(-1 - x) % 2^32`.
---
--- ```lua
--- bit32.bnot( 0 ) -- 4294967295 (0xFFFFFFFF)
--- bit32.bnot( 0xFF ) -- 4294967040 (0xFFFFFF00)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.bnot)
---
---@param x integer The number to invert.
---@return integer y The inverted number.
---@nodiscard
function bit32.bnot( x ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *or* of all its arguments.
---
--- Without arguments returns `0`.
---
--- ```lua
--- bit32.bor( 1, 2, 4, 8 ) -- 15
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.bor)
---
---@param ... integer The numbers.
---@return integer y The bitwise *or* of the numbers.
---@nodiscard
function bit32.bor( ... ) end

--- [SHARED AND MENU]
---
--- Checks if the bitwise *and* of all its arguments is not zero,
--- i.e. whether all the numbers have at least one bit in common.
---
--- Without arguments returns `true`.
---
--- ```lua
--- bit32.btest( 6, 3 ) -- true
--- bit32.btest( 4, 3 ) -- false
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.btest)
---
---@param ... integer The numbers.
---@return boolean is_set `true` if the bitwise *and* of the numbers is not zero, `false` otherwise.
---@nodiscard
function bit32.btest( ... ) end

--- [SHARED AND MENU]
---
--- Returns the bitwise *exclusive or* of all its arguments.
---
--- Without arguments returns `0`.
---
--- ```lua
--- bit32.bxor( 0xA5A5A5A5, 0xF0F0F0F0 ) -- 1431655765 (0x55555555)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.bxor)
---
---@param ... integer The numbers.
---@return integer y The bitwise *exclusive or* of the numbers.
---@nodiscard
function bit32.bxor( ... ) end

--- [SHARED AND MENU]
---
--- Returns the unsigned number formed by the bits `field` to `field + width - 1` of `n`.
---
--- Bits are numbered from `0` (least significant) to `31` (most significant),
--- and all accessed bits must be in this range, otherwise an error is raised.
---
--- ```lua
--- bit32.extract( 0xB4, 2, 3 ) -- 5 (0b10110100 -> 0b101)
--- bit32.extract( 0x80000000, 31 ) -- 1
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.extract)
---
---@param n integer The number to extract the bits from.
---@param field integer The position of the first bit, `0` to `31`.
---@param width? integer The number of bits, `1` by default.
---@return integer y The extracted bits.
---@nodiscard
function bit32.extract( n, field, width ) end

--- [SHARED AND MENU]
---
--- Returns a copy of `n` with the bits `field` to `field + width - 1` replaced by
--- the lowest `width` bits of `v`.
---
--- Bits are numbered as in `bit32.extract`, and the same range rules apply.
---
--- ```lua
--- bit32.replace( 0xFF, 0, 4, 4 ) -- 15 (0x0F)
--- bit32.replace( 0, 1, 31 ) -- 2147483648 (0x80000000)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.replace)
---
---@param n integer The number to replace the bits in.
---@param v integer The number providing the replacement bits.
---@param field integer The position of the first bit, `0` to `31`.
---@param width? integer The number of bits, `1` by default.
---@return integer y The number with the bits replaced.
---@nodiscard
function bit32.replace( n, v, field, width ) end

--- [SHARED AND MENU]
---
--- Returns `x` rotated left by `disp` bits.
---
--- A negative `disp` rotates right. Only `disp % 32` matters.
---
--- ```lua
--- bit32.lrotate( 0x12345678, 12 ) -- 1164411171 (0x45678123)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.lrotate)
---
---@param x integer The number to rotate.
---@param disp integer The number of bits to rotate left by, negative to rotate right.
---@return integer y The rotated number.
---@nodiscard
function bit32.lrotate( x, disp ) end

--- [SHARED AND MENU]
---
--- Returns `x` shifted left by `disp` bits, filling the vacant bits with zeros.
---
--- A negative `disp` shifts right. Displacements of 32 or more give `0`.
---
--- ```lua
--- bit32.lshift( 1, 8 ) -- 256
--- bit32.lshift( 1, 31 ) -- 2147483648
--- bit32.lshift( 1, 32 ) -- 0
--- bit32.lshift( 256, -8 ) -- 1
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.lshift)
---
---@param x integer The number to shift.
---@param disp integer The number of bits to shift left by, negative to shift right.
---@return integer y The shifted number.
---@nodiscard
function bit32.lshift( x, disp ) end

--- [SHARED AND MENU]
---
--- Returns `x` rotated right by `disp` bits.
---
--- A negative `disp` rotates left. Only `disp % 32` matters.
---
--- ```lua
--- bit32.rrotate( 0x12345678, 12 ) -- 1736516421 (0x67812345)
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.rrotate)
---
---@param x integer The number to rotate.
---@param disp integer The number of bits to rotate right by, negative to rotate left.
---@return integer y The rotated number.
---@nodiscard
function bit32.rrotate( x, disp ) end

--- [SHARED AND MENU]
---
--- Returns `x` logically shifted right by `disp` bits, filling the vacant bits with zeros.
---
--- A negative `disp` shifts left. Displacements of 32 or more give `0`.
---
--- ```lua
--- bit32.rshift( 256, 8 ) -- 1
--- bit32.rshift( -1, 28 ) -- 15
--- ```
---
--- [View documents](https://www.lua.org/manual/5.2/manual.html#pdf-bit32.rshift)
---
---@param x integer The number to shift.
---@param disp integer The number of bits to shift right by, negative to shift left.
---@return integer y The shifted number.
---@nodiscard
function bit32.rshift( x, disp ) end

return bit32
