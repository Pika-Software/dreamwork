local std = dreamwork.std

---@class dreamwork.std.hash
local hash = std.hash

local string = std.string
local string_len = string.len
local string_byte = string.byte

local bit = std.bit
local bit_bxor = bit.bxor
local bit_lshift = bit.lshift

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-0) [deprecated] hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function hash.fnv0( str )
    local hash_int = 0

    for index = 1, string_len( str ), 1 do
        hash_int = hash_int + bit_lshift( hash_int, 1 ) + bit_lshift( hash_int, 4 ) + bit_lshift( hash_int, 7 ) + bit_lshift( hash_int, 8 ) + bit_lshift( hash_int, 24 )
        hash_int = bit_bxor( hash_int, string_byte( str, index, index ) )
    end

    return hash_int % 0xFFFFFFFF
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1) hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function hash.fnv1( str )
    local hash_int = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash_int = hash_int + bit_lshift( hash_int, 1 ) + bit_lshift( hash_int, 4 ) + bit_lshift( hash_int, 7 ) + bit_lshift( hash_int, 8 ) + bit_lshift( hash_int, 24 )
        hash_int = bit_bxor( hash_int, string_byte( str, index, index ) )
    end

    return hash_int % 0xFFFFFFFF
end

--- [SHARED AND MENU]
---
--- Returns the Fowler-Noll-Vo (FNV-1a) hash of the string.
---
--- See https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function for the definition of the Fowler-Noll-Vo hash.
---
---@param str string The string used to calculate the Fowler-Noll-Vo hash.
---@return integer hash_int The Fowler-Noll-Vo hash, which is greater or equal to 0, and less than 2^32 (0x100000000).
function hash.fnv1a( str )
    local hash_int = 0x811c9dc5

    for index = 1, string_len( str ), 1 do
        hash_int = bit_bxor( hash_int, string_byte( str, index, index ) )
        hash_int = hash_int + bit_lshift( hash_int, 1 ) + bit_lshift( hash_int, 4 ) + bit_lshift( hash_int, 7 ) + bit_lshift( hash_int, 8 ) + bit_lshift( hash_int, 24 )
    end

    return hash_int % 0xFFFFFFFF
end
