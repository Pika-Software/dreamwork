local std = _G.dreamwork.std

---@class dreamwork.std.crypto
local crypto = std.crypto

local hmac = crypto.hmac
local hmac_key = hmac.key
local hmac_padding = hmac.padding
local hmac_compute = hmac.compute

local pack_writeUInt32 = std.pack.writeUInt32
local base16_encode = std.encoding.base16.encode

local string = std.string
local string_len, string_sub = string.len, string.sub
local string_char, string_byte = string.char, string.byte

local bit_bxor = std.bit.bxor

local table_concat, table_unpack = std.table.concat, std.table.unpack
local isfunction = std.isfunction
local math_ceil = std.math.ceil

local std_hash = std.hash

--- [SHARED AND MENU]
---
--- Derives a password using the pbkdf2 algorithm.
---
--- See https://en.wikipedia.org/wiki/PBKDF2 for the algorithm.
---
---@param options dreamwork.std.crypto.pbkdf2.Options
---@return string pbkdf2_hash The derived password as a hex string.
function crypto.pbkdf2( options )
    local pbkdf2_iterations = options.iterations or 4096
    local pbkdf2_length = options.length or 16
    local pbkdf2_password = options.password
    local pbkdf2_salt = options.salt

    local hash_name = options.hash
    if hash_name == nil then
        error( "hash name not specified", 2 )
    end

    local hash_class = std_hash[ hash_name ]
    if hash_class == nil or isfunction( hash_class ) then
        std.errorf( 2, false, "hash.%sClass not found.", hash_name )
    end

    ---@cast hash_class dreamwork.std.hash.MD5Class

    local digest_size = hash_class.digest_size
    local block_size = hash_class.block_size
    local digest_fn = hash_class.digest

    local hmac_outer, hmac_inner = hmac_padding( hmac_key( pbkdf2_password, digest_fn, block_size ), block_size )
    local block_count = math_ceil( pbkdf2_length / digest_size )
    local blocks = {}

    for block = 1, block_count, 1 do
        local u = hmac_compute( digest_fn, hmac_outer, hmac_inner, pbkdf2_salt .. pack_writeUInt32( block, true ), false )
        local t = { string_byte( u, 1, digest_size ) }

        for _ = 2, pbkdf2_iterations, 1 do
            u = hmac_compute( digest_fn, hmac_outer, hmac_inner, u, false )

            for j = 1, digest_size, 1 do
                t[ j ] = bit_bxor( t[ j ], string_byte( u, j ) )
            end
        end

        blocks[ block ] = string_char( table_unpack( t, 1, digest_size ) )
    end

    local pbkdf2_hash = base16_encode( table_concat( blocks, "", 1, block_count ) )

    if string_len( pbkdf2_hash ) ~= pbkdf2_length then
        pbkdf2_hash = string_sub( pbkdf2_hash, 1, pbkdf2_length )
    end

    return pbkdf2_hash
end
