local std = dreamwork.std
local ffi = std.ffi

---@class dreamwork.std.crypto
local crypto = std.crypto

local error = std.error

local rbit = std.raw.bit
local rbit_lrotate = rbit.lrotate
local rbit_band, rbit_bor, rbit_bxor = rbit.band, rbit.bor, rbit.bxor
local rbit_lshift, rbit_rshift, rbit_tobit = rbit.lshift, rbit.rshift, rbit.tobit

local math = std.math
local math_max = math.max
local math_ceil = math.ceil

local table = std.table
local table_concat = table.concat

local string = std.string
local string_len = string.len
local string_rep = string.rep
local string_sub = string.sub
local string_char, string_byte = string.char, string.byte

-- the first four words of the state are "expand 32-byte k" in little endian

--- Applies the 20 ChaCha rounds ( 10 double rounds ) to the state.
---
--- Every word is an int32, see [RFC 8439, section 2.3](https://datatracker.ietf.org/doc/html/rfc8439#section-2.3).
---
---@return integer x0
---@return integer x1
---@return integer x2
---@return integer x3
---@return integer x4
---@return integer x5
---@return integer x6
---@return integer x7
---@return integer x8
---@return integer x9
---@return integer x10
---@return integer x11
---@return integer x12
---@return integer x13
---@return integer x14
---@return integer x15
local function permute( x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 )
    -- fully unrolled, a loop over the double rounds aborts its exit trace with "NYI: register coalescing too complex"
    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    -- column round
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 16 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 12 )
    x0 = rbit_tobit( x0 + x4 ); x12 = rbit_lrotate( rbit_bxor( x12, x0 ), 8 )
    x8 = rbit_tobit( x8 + x12 ); x4 = rbit_lrotate( rbit_bxor( x4, x8 ), 7 )

    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 16 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 12 )
    x1 = rbit_tobit( x1 + x5 ); x13 = rbit_lrotate( rbit_bxor( x13, x1 ), 8 )
    x9 = rbit_tobit( x9 + x13 ); x5 = rbit_lrotate( rbit_bxor( x5, x9 ), 7 )

    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 16 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 12 )
    x2 = rbit_tobit( x2 + x6 ); x14 = rbit_lrotate( rbit_bxor( x14, x2 ), 8 )
    x10 = rbit_tobit( x10 + x14 ); x6 = rbit_lrotate( rbit_bxor( x6, x10 ), 7 )

    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 16 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 12 )
    x3 = rbit_tobit( x3 + x7 ); x15 = rbit_lrotate( rbit_bxor( x15, x3 ), 8 )
    x11 = rbit_tobit( x11 + x15 ); x7 = rbit_lrotate( rbit_bxor( x7, x11 ), 7 )

    -- diagonal round
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 16 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 12 )
    x0 = rbit_tobit( x0 + x5 ); x15 = rbit_lrotate( rbit_bxor( x15, x0 ), 8 )
    x10 = rbit_tobit( x10 + x15 ); x5 = rbit_lrotate( rbit_bxor( x5, x10 ), 7 )

    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 16 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 12 )
    x1 = rbit_tobit( x1 + x6 ); x12 = rbit_lrotate( rbit_bxor( x12, x1 ), 8 )
    x11 = rbit_tobit( x11 + x12 ); x6 = rbit_lrotate( rbit_bxor( x6, x11 ), 7 )

    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 16 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 12 )
    x2 = rbit_tobit( x2 + x7 ); x13 = rbit_lrotate( rbit_bxor( x13, x2 ), 8 )
    x8 = rbit_tobit( x8 + x13 ); x7 = rbit_lrotate( rbit_bxor( x7, x8 ), 7 )

    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 16 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 12 )
    x3 = rbit_tobit( x3 + x4 ); x14 = rbit_lrotate( rbit_bxor( x14, x3 ), 8 )
    x9 = rbit_tobit( x9 + x14 ); x4 = rbit_lrotate( rbit_bxor( x4, x9 ), 7 )

    return x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15
end

--- Reads a little endian int32 word from the string.
---
---@param str string
---@param index integer The 1-based index of the first byte.
---@return integer word
local function readWord( str, index )
    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, index, index + 3 )
    return rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) )
end

--- XORs the string with the ChaCha20 keystream.
---
---@type fun( str: string, str_length: integer, k0: integer, k1: integer, k2: integer, k3: integer, k4: integer, k5: integer, k6: integer, k7: integer, counter: integer, n0: integer, n1: integer, n2: integer ): string
local xorStream

if ffi == nil or not ffi.abi( "le" ) then

    --- XORs one 64-byte block of the string with the keystream block of the given counter,
    --- the result is stored in `blocks` after `block_count`.
    ---
    ---@param blocks string[]
    ---@param block_count integer
    ---@param str string
    ---@param offset integer The 0-based byte offset of the block.
    ---@return integer block_count The new number of strings in `blocks`.
    local function xorBlock( blocks, block_count, str, offset, k0, k1, k2, k3, k4, k5, k6, k7, counter, n0, n1, n2 )
        local s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15 = permute( 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574, k0, k1, k2, k3, k4, k5, k6, k7, counter, n0, n1, n2 )
        s0, s1, s2, s3 = s0 + 0x61707865, s1 + 0x3320646e, s2 + 0x79622d32, s3 + 0x6b206574
        s4, s5, s6, s7, s8, s9, s10, s11 = s4 + k0, s5 + k1, s6 + k2, s7 + k3, s8 + k4, s9 + k5, s10 + k6, s11 + k7
        s12, s13, s14, s15 = s12 + counter, s13 + n0, s14 + n1, s15 + n2

        -- every word is built right after its bytes are read, otherwise 64 live bytes run JIT out of spill slots
        local uint8_1, uint8_2, uint8_3, uint8_4

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 1, offset + 4 )
        local w0 = rbit_bxor( s0, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 5, offset + 8 )
        local w1 = rbit_bxor( s1, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 9, offset + 12 )
        local w2 = rbit_bxor( s2, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 13, offset + 16 )
        local w3 = rbit_bxor( s3, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 17, offset + 20 )
        local w4 = rbit_bxor( s4, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 21, offset + 24 )
        local w5 = rbit_bxor( s5, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 25, offset + 28 )
        local w6 = rbit_bxor( s6, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 29, offset + 32 )
        local w7 = rbit_bxor( s7, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 33, offset + 36 )
        local w8 = rbit_bxor( s8, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 37, offset + 40 )
        local w9 = rbit_bxor( s9, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 41, offset + 44 )
        local w10 = rbit_bxor( s10, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 45, offset + 48 )
        local w11 = rbit_bxor( s11, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 49, offset + 52 )
        local w12 = rbit_bxor( s12, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 53, offset + 56 )
        local w13 = rbit_bxor( s13, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 57, offset + 60 )
        local w14 = rbit_bxor( s14, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, offset + 61, offset + 64 )
        local w15 = rbit_bxor( s15, rbit_bor( uint8_1, rbit_lshift( uint8_2, 8 ), rbit_lshift( uint8_3, 16 ), rbit_lshift( uint8_4, 24 ) ) )

        blocks[ block_count + 1 ] = string_char(
            rbit_band( w0, 0xFF ), rbit_band( rbit_rshift( w0, 8 ), 0xFF ), rbit_band( rbit_rshift( w0, 16 ), 0xFF ), rbit_rshift( w0, 24 ),
            rbit_band( w1, 0xFF ), rbit_band( rbit_rshift( w1, 8 ), 0xFF ), rbit_band( rbit_rshift( w1, 16 ), 0xFF ), rbit_rshift( w1, 24 ),
            rbit_band( w2, 0xFF ), rbit_band( rbit_rshift( w2, 8 ), 0xFF ), rbit_band( rbit_rshift( w2, 16 ), 0xFF ), rbit_rshift( w2, 24 ),
            rbit_band( w3, 0xFF ), rbit_band( rbit_rshift( w3, 8 ), 0xFF ), rbit_band( rbit_rshift( w3, 16 ), 0xFF ), rbit_rshift( w3, 24 ),
            rbit_band( w4, 0xFF ), rbit_band( rbit_rshift( w4, 8 ), 0xFF ), rbit_band( rbit_rshift( w4, 16 ), 0xFF ), rbit_rshift( w4, 24 ),
            rbit_band( w5, 0xFF ), rbit_band( rbit_rshift( w5, 8 ), 0xFF ), rbit_band( rbit_rshift( w5, 16 ), 0xFF ), rbit_rshift( w5, 24 ),
            rbit_band( w6, 0xFF ), rbit_band( rbit_rshift( w6, 8 ), 0xFF ), rbit_band( rbit_rshift( w6, 16 ), 0xFF ), rbit_rshift( w6, 24 ),
            rbit_band( w7, 0xFF ), rbit_band( rbit_rshift( w7, 8 ), 0xFF ), rbit_band( rbit_rshift( w7, 16 ), 0xFF ), rbit_rshift( w7, 24 ),
            rbit_band( w8, 0xFF ), rbit_band( rbit_rshift( w8, 8 ), 0xFF ), rbit_band( rbit_rshift( w8, 16 ), 0xFF ), rbit_rshift( w8, 24 ),
            rbit_band( w9, 0xFF ), rbit_band( rbit_rshift( w9, 8 ), 0xFF ), rbit_band( rbit_rshift( w9, 16 ), 0xFF ), rbit_rshift( w9, 24 ),
            rbit_band( w10, 0xFF ), rbit_band( rbit_rshift( w10, 8 ), 0xFF ), rbit_band( rbit_rshift( w10, 16 ), 0xFF ), rbit_rshift( w10, 24 ),
            rbit_band( w11, 0xFF ), rbit_band( rbit_rshift( w11, 8 ), 0xFF ), rbit_band( rbit_rshift( w11, 16 ), 0xFF ), rbit_rshift( w11, 24 ),
            rbit_band( w12, 0xFF ), rbit_band( rbit_rshift( w12, 8 ), 0xFF ), rbit_band( rbit_rshift( w12, 16 ), 0xFF ), rbit_rshift( w12, 24 ),
            rbit_band( w13, 0xFF ), rbit_band( rbit_rshift( w13, 8 ), 0xFF ), rbit_band( rbit_rshift( w13, 16 ), 0xFF ), rbit_rshift( w13, 24 ),
            rbit_band( w14, 0xFF ), rbit_band( rbit_rshift( w14, 8 ), 0xFF ), rbit_band( rbit_rshift( w14, 16 ), 0xFF ), rbit_rshift( w14, 24 ),
            rbit_band( w15, 0xFF ), rbit_band( rbit_rshift( w15, 8 ), 0xFF ), rbit_band( rbit_rshift( w15, 16 ), 0xFF ), rbit_rshift( w15, 24 )
        )

        return block_count + 1
    end

    function xorStream( str, str_length, k0, k1, k2, k3, k4, k5, k6, k7, counter, n0, n1, n2 )
        local blocks, block_count = {}, 0

        local offset = 0
        local last_offset = str_length - 64

        while offset <= last_offset do
            block_count = xorBlock( blocks, block_count, str, offset, k0, k1, k2, k3, k4, k5, k6, k7, rbit_tobit( counter ), n0, n1, n2 )
            counter = counter + 1
            offset = offset + 64
        end

        local tail_length = str_length - offset
        if tail_length == 0 then
            return table_concat( blocks, "", 1, block_count )
        end

        -- the tail is padded to a whole block, the result is cut to its length
        block_count = xorBlock( blocks, block_count, string_sub( str, offset + 1 ) .. string_rep( "\0", 64 - tail_length ), 0, k0, k1, k2, k3, k4, k5, k6, k7, rbit_tobit( counter ), n0, n1, n2 )
        blocks[ block_count ] = string_sub( blocks[ block_count ], 1, tail_length )

        return table_concat( blocks, "", 1, block_count )
    end

else

    local ffi_cast = ffi.cast
    local ffi_string = ffi.string

    local uint8_ptr_t = ffi.typeof( "const uint8_t *" )
    local int32_ptr_t = ffi.typeof( "const int32_t *" )
    local int32_mut_ptr_t = ffi.typeof( "int32_t *" )
    local uint8_array_t = ffi.typeof( "uint8_t[?]" )

    -- holds the keystream of the last partial block, bytes are read through a pointer in little endian order
    local keystream = ffi.new( "int32_t[16]" )
    local keystream_bytes = ffi_cast( uint8_ptr_t, keystream )

    -- Larger outputs get a temporary buffer, so memory isn't held after one big call
    local max_buffer_size = 0x100000

    local buffer_size = 256
    local buffer = uint8_array_t( buffer_size )

    ---@param size integer
    ---@return ffi.cdata*
    local function get_buffer( size )
        if size > buffer_size then
            if size > max_buffer_size then
                return uint8_array_t( size )
            end

            buffer_size = math_max( size, buffer_size * 2 )
            buffer = uint8_array_t( buffer_size )
        end

        return buffer
    end

    -- loops below do not allocate, so the GC cannot collect `str` while its data is read by pointer.

    function xorStream( str, str_length, k0, k1, k2, k3, k4, k5, k6, k7, counter, n0, n1, n2 )
        local output = get_buffer( str_length )

        local source = ffi_cast( int32_ptr_t, ffi_cast( uint8_ptr_t, str ) )
        local target = ffi_cast( int32_mut_ptr_t, output )

        local tail_length = str_length % 64
        local full_length = str_length - tail_length

        for index = 0, full_length / 4 - 16, 16 do
            local c = rbit_tobit( counter )
            local x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 = permute( 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574, k0, k1, k2, k3, k4, k5, k6, k7, c, n0, n1, n2 )

            target[ index ] = rbit_bxor( source[ index ], x0 + 0x61707865 )
            target[ index + 1 ] = rbit_bxor( source[ index + 1 ], x1 + 0x3320646e )
            target[ index + 2 ] = rbit_bxor( source[ index + 2 ], x2 + 0x79622d32 )
            target[ index + 3 ] = rbit_bxor( source[ index + 3 ], x3 + 0x6b206574 )
            target[ index + 4 ] = rbit_bxor( source[ index + 4 ], x4 + k0 )
            target[ index + 5 ] = rbit_bxor( source[ index + 5 ], x5 + k1 )
            target[ index + 6 ] = rbit_bxor( source[ index + 6 ], x6 + k2 )
            target[ index + 7 ] = rbit_bxor( source[ index + 7 ], x7 + k3 )
            target[ index + 8 ] = rbit_bxor( source[ index + 8 ], x8 + k4 )
            target[ index + 9 ] = rbit_bxor( source[ index + 9 ], x9 + k5 )
            target[ index + 10 ] = rbit_bxor( source[ index + 10 ], x10 + k6 )
            target[ index + 11 ] = rbit_bxor( source[ index + 11 ], x11 + k7 )
            target[ index + 12 ] = rbit_bxor( source[ index + 12 ], x12 + c )
            target[ index + 13 ] = rbit_bxor( source[ index + 13 ], x13 + n0 )
            target[ index + 14 ] = rbit_bxor( source[ index + 14 ], x14 + n1 )
            target[ index + 15 ] = rbit_bxor( source[ index + 15 ], x15 + n2 )

            counter = counter + 1
        end

        if tail_length ~= 0 then
            local c = rbit_tobit( counter )
            local x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 = permute( 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574, k0, k1, k2, k3, k4, k5, k6, k7, c, n0, n1, n2 )

            keystream[ 0 ] = x0 + 0x61707865
            keystream[ 1 ] = x1 + 0x3320646e
            keystream[ 2 ] = x2 + 0x79622d32
            keystream[ 3 ] = x3 + 0x6b206574
            keystream[ 4 ] = x4 + k0
            keystream[ 5 ] = x5 + k1
            keystream[ 6 ] = x6 + k2
            keystream[ 7 ] = x7 + k3
            keystream[ 8 ] = x8 + k4
            keystream[ 9 ] = x9 + k5
            keystream[ 10 ] = x10 + k6
            keystream[ 11 ] = x11 + k7
            keystream[ 12 ] = x12 + c
            keystream[ 13 ] = x13 + n0
            keystream[ 14 ] = x14 + n1
            keystream[ 15 ] = x15 + n2

            local source_bytes = ffi_cast( uint8_ptr_t, str )

            for index = full_length, str_length - 1, 1 do
                output[ index ] = rbit_bxor( source_bytes[ index ], keystream_bytes[ index - full_length ] )
            end
        end

        return ffi_string( output, str_length )
    end

end

--- Reads the 32-byte key as 8 words.
---
---@param key string
---@return integer k0
---@return integer k1
---@return integer k2
---@return integer k3
---@return integer k4
---@return integer k5
---@return integer k6
---@return integer k7
local function readKey( key )
    if string_len( key ) ~= 32 then
        error( "key must be exactly 32 bytes long", 3 )
    end

    return readWord( key, 1 ), readWord( key, 5 ), readWord( key, 9 ), readWord( key, 13 ),
        readWord( key, 17 ), readWord( key, 21 ), readWord( key, 25 ), readWord( key, 29 )
end

--- Validates the initial block counter against the number of blocks the data needs.
---
---@param counter integer | nil
---@param data_length integer
---@return integer counter
local function checkCounter( counter, data_length )
    if counter == nil then
        return 0
    end

    if counter < 0 or counter > 0xFFFFFFFF or counter % 1 ~= 0 then
        error( "counter must be an integer in range [0, 0xFFFFFFFF]", 3 )
    end

    if counter + math_ceil( data_length / 64 ) > 0x100000000 then
        error( "data is too long, the block counter would overflow", 3 )
    end

    return counter
end

--- [SHARED AND MENU]
---
--- ChaCha20 stream cipher library, the IETF variant with a 96-bit nonce and a 32-bit block counter.
---
--- Encryption and decryption are the same operation, the data is XORed with the keystream.
---
--- A key and nonce pair must never be used twice, otherwise both plaintexts can be recovered.
--- If nonces are random, prefer `crypto.xchacha20`, its 192-bit nonce is safe to generate randomly.
---
--- ChaCha20 alone does not authenticate the data, use a MAC ( e.g. `crypto.hmac` ) over the ciphertext to detect tampering.
---
--- See [RFC 8439](https://datatracker.ietf.org/doc/html/rfc8439) for the algorithm.
---
---@class dreamwork.std.crypto.chacha20
local chacha20 = {}
crypto.chacha20 = chacha20

chacha20.key_size = 32
chacha20.nonce_size = 12
chacha20.block_size = 64

--- [SHARED AND MENU]
---
--- Encrypts or decrypts the data with ChaCha20.
---
--- The data can be processed in parts: each part except the last must be a multiple of 64 bytes long,
--- and `counter` of the next part is `counter + #part / 64`.
---
---@param data string The plaintext to encrypt or the ciphertext to decrypt.
---@param key string The 32-byte key.
---@param nonce string The 12-byte nonce.
---@param counter? integer The initial block counter, default is `0`.
---@return string result The ciphertext or plaintext, same length as `data`.
---@nodiscard
function chacha20.encrypt( data, key, nonce, counter )
    local k0, k1, k2, k3, k4, k5, k6, k7 = readKey( key )

    if string_len( nonce ) ~= 12 then
        error( "nonce must be exactly 12 bytes long", 2 )
    end

    local data_length = string_len( data )
    counter = checkCounter( counter, data_length )

    if data_length == 0 then
        return ""
    end

    return xorStream( data, data_length, k0, k1, k2, k3, k4, k5, k6, k7, counter, readWord( nonce, 1 ), readWord( nonce, 5 ), readWord( nonce, 9 ) )
end

chacha20.decrypt = chacha20.encrypt

local zero_block = string_rep( "\0", 64 )

--- [SHARED AND MENU]
---
--- Computes a single 64-byte ChaCha20 keystream block.
---
---@param key string The 32-byte key.
---@param nonce string The 12-byte nonce.
---@param counter? integer The block counter, default is `0`.
---@return string block The 64-byte keystream block.
---@nodiscard
function chacha20.block( key, nonce, counter )
    local k0, k1, k2, k3, k4, k5, k6, k7 = readKey( key )

    if string_len( nonce ) ~= 12 then
        error( "nonce must be exactly 12 bytes long", 2 )
    end

    return xorStream( zero_block, 64, k0, k1, k2, k3, k4, k5, k6, k7, checkCounter( counter, 64 ), readWord( nonce, 1 ), readWord( nonce, 5 ), readWord( nonce, 9 ) )
end

--- Derives the HChaCha20 subkey words from the key and the first 16 bytes of the nonce.
---
---@param key string
---@param nonce string
---@return integer k0
---@return integer k1
---@return integer k2
---@return integer k3
---@return integer k4
---@return integer k5
---@return integer k6
---@return integer k7
local function hchacha20( key, nonce )
    local k0, k1, k2, k3, k4, k5, k6, k7 = readKey( key )

    local x0, x1, x2, x3, _, _, _, _, _, _, _, _, x12, x13, x14, x15 = permute( 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574, k0, k1, k2, k3, k4, k5, k6, k7,
        readWord( nonce, 1 ), readWord( nonce, 5 ), readWord( nonce, 9 ), readWord( nonce, 13 ) )

    return x0, x1, x2, x3, x12, x13, x14, x15
end

--- [SHARED AND MENU]
---
--- XChaCha20 stream cipher library, ChaCha20 with a 192-bit nonce.
---
--- The nonce is large enough to be generated randomly for every message.
---
--- Encryption and decryption are the same operation, the data is XORed with the keystream.
---
--- XChaCha20 alone does not authenticate the data, use a MAC ( e.g. `crypto.hmac` ) over the ciphertext to detect tampering.
---
--- See [draft-irtf-cfrg-xchacha](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha) for the algorithm.
---
---@class dreamwork.std.crypto.xchacha20
local xchacha20 = {}
crypto.xchacha20 = xchacha20

xchacha20.key_size = 32
xchacha20.nonce_size = 24
xchacha20.block_size = 64

--- [SHARED AND MENU]
---
--- Derives a 32-byte subkey from the key and a 16-byte nonce with HChaCha20.
---
---@param key string The 32-byte key.
---@param nonce string The 16-byte nonce.
---@return string subkey The 32-byte subkey.
---@nodiscard
function xchacha20.hchacha20( key, nonce )
    if string_len( nonce ) ~= 16 then
        error( "nonce must be exactly 16 bytes long", 2 )
    end

    local k0, k1, k2, k3, k4, k5, k6, k7 = hchacha20( key, nonce )

    return string_char(
        rbit_band( k0, 0xFF ), rbit_band( rbit_rshift( k0, 8 ), 0xFF ), rbit_band( rbit_rshift( k0, 16 ), 0xFF ), rbit_rshift( k0, 24 ),
        rbit_band( k1, 0xFF ), rbit_band( rbit_rshift( k1, 8 ), 0xFF ), rbit_band( rbit_rshift( k1, 16 ), 0xFF ), rbit_rshift( k1, 24 ),
        rbit_band( k2, 0xFF ), rbit_band( rbit_rshift( k2, 8 ), 0xFF ), rbit_band( rbit_rshift( k2, 16 ), 0xFF ), rbit_rshift( k2, 24 ),
        rbit_band( k3, 0xFF ), rbit_band( rbit_rshift( k3, 8 ), 0xFF ), rbit_band( rbit_rshift( k3, 16 ), 0xFF ), rbit_rshift( k3, 24 ),
        rbit_band( k4, 0xFF ), rbit_band( rbit_rshift( k4, 8 ), 0xFF ), rbit_band( rbit_rshift( k4, 16 ), 0xFF ), rbit_rshift( k4, 24 ),
        rbit_band( k5, 0xFF ), rbit_band( rbit_rshift( k5, 8 ), 0xFF ), rbit_band( rbit_rshift( k5, 16 ), 0xFF ), rbit_rshift( k5, 24 ),
        rbit_band( k6, 0xFF ), rbit_band( rbit_rshift( k6, 8 ), 0xFF ), rbit_band( rbit_rshift( k6, 16 ), 0xFF ), rbit_rshift( k6, 24 ),
        rbit_band( k7, 0xFF ), rbit_band( rbit_rshift( k7, 8 ), 0xFF ), rbit_band( rbit_rshift( k7, 16 ), 0xFF ), rbit_rshift( k7, 24 )
    )
end

--- [SHARED AND MENU]
---
--- Encrypts or decrypts the data with XChaCha20.
---
--- The data can be processed in parts: each part except the last must be a multiple of 64 bytes long,
--- and `counter` of the next part is `counter + #part / 64`.
---
---@param data string The plaintext to encrypt or the ciphertext to decrypt.
---@param key string The 32-byte key.
---@param nonce string The 24-byte nonce.
---@param counter? integer The initial block counter, default is `0`.
---@return string result The ciphertext or plaintext, same length as `data`.
---@nodiscard
function xchacha20.encrypt( data, key, nonce, counter )
    if string_len( nonce ) ~= 24 then
        error( "nonce must be exactly 24 bytes long", 2 )
    end

    local k0, k1, k2, k3, k4, k5, k6, k7 = hchacha20( key, nonce )

    local data_length = string_len( data )
    counter = checkCounter( counter, data_length )

    if data_length == 0 then
        return ""
    end

    -- the ChaCha20 nonce is 4 zero bytes followed by the last 8 bytes of the XChaCha20 nonce
    return xorStream( data, data_length, k0, k1, k2, k3, k4, k5, k6, k7, counter, 0, readWord( nonce, 17 ), readWord( nonce, 21 ) )
end

xchacha20.decrypt = xchacha20.encrypt
