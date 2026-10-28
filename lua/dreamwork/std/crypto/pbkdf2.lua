local std = dreamwork.std

local math = std.math
local math_ceil = math.ceil

local table = std.table
local table_concat, table_unpack = table.concat, table.unpack

local string = std.string
local string_sub = string.sub
local string_char = string.char
local string_byte = string.byte

local bit = std.bit
local bit_bxor = bit.bxor

local bytepack = std.bytepack
local bytepack_writeUInt32BE = bytepack.writeUInt32BE

---@class dreamwork.std.crypto
local crypto = std.crypto

local hmac = crypto.hmac
local hmac_key = hmac.key
local hmac_padding = hmac.padding
local hmac_compute = hmac.compute

--- [SHARED AND MENU]
---
--- Derives a password using the pbkdf2 algorithm.
---
--- See [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) for the algorithm.
---
---@param options dreamwork.std.pbkdf2.Options
---@return string pbkdf2_str The derived key as a binary string of `length` bytes.
---@nodiscard
function crypto.pbkdf2( options )
    local pbkdf2_iterations = options.iterations or 4096
    local pbkdf2_length = options.length or 16
    local pbkdf2_password = options.password
    local pbkdf2_salt = options.salt
    local pbkdf2_hash = options.hash

    local digest_size = pbkdf2_hash.digest_size
    local block_size = pbkdf2_hash.block_size
    local digest_fn = pbkdf2_hash.digest

    local hmac_outer, hmac_inner = hmac_padding( hmac_key( pbkdf2_password, digest_fn, block_size ), block_size )
    local block_count = math_ceil( pbkdf2_length / digest_size )
    local blocks = {}

    for block = 1, block_count, 1 do
        local u = hmac_compute( digest_fn, hmac_outer, hmac_inner, pbkdf2_salt .. string_char( bytepack_writeUInt32BE( block ) ), false )
        local t = { string_byte( u, 1, digest_size ) }

        for _ = 2, pbkdf2_iterations, 1 do
            u = hmac_compute( digest_fn, hmac_outer, hmac_inner, u, false )

            for j = 1, digest_size, 1 do
                t[ j ] = bit_bxor( t[ j ], string_byte( u, j ) )
            end
        end

        blocks[ block ] = string_char( table_unpack( t, 1, digest_size ) )
    end

    return string_sub( table_concat( blocks, "", 1, block_count ), 1, pbkdf2_length )
end
