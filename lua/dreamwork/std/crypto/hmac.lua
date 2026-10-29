---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.crypto
local crypto = std.crypto

local error = std.error

local table = std.table
local table_unpack = table.unpack

local string = std.string
local string_len = string.len
local string_rep = string.rep
local string_byte, string_char = string.byte, string.char

local bit = std.bit
local bit_bxor = bit.bxor

--- [SHARED AND MENU]
---
--- Hash-based Message Authentication Code library.
---
--- See [RFC 2104](https://datatracker.ietf.org/doc/html/rfc2104) for the algorithm.
---
--- [About HMAC](https://en.wikipedia.org/wiki/HMAC)
---@class dreamwork.std.crypto.hmac
local hmac = {}
crypto.hmac = hmac

--- [SHARED AND MENU]
---
--- Normalizes the key to the block size of the hash function.
---
--- Keys longer than `block_size` are hashed first, shorter keys are padded with zero bytes.
---
---@param key string The key to normalize.
---@param digest_fn fun( data: string ): string The hash function to use.
---@param block_size integer The block size of the hash function.
---@return string normalized_key The key of exactly `block_size` bytes.
---@nodiscard
local function normalizeKey( key, digest_fn, block_size )
    local key_length = string_len( key )
    if key_length > block_size then
        return normalizeKey( digest_fn( key ), digest_fn, block_size )
    elseif key_length < block_size then
        return key .. string_rep( "\0", block_size - key_length )
    else
        return key
    end
end

hmac.normalizeKey = normalizeKey

--- [SHARED AND MENU]
---
--- Computes the outer and inner pads of the key, `key ⊕ opad` and `key ⊕ ipad`.
---
--- The pads can be computed once and reused with `hmac.digestWithPads` for many messages under the same key.
---
---@param key string The key normalized by `hmac.normalizeKey`, must be exactly `block_size` bytes.
---@param block_size integer The block size of the hash function.
---@return string outer The outer pad.
---@return string inner The inner pad.
---@nodiscard
local function pads( key, block_size )
    if string_len( key ) ~= block_size then
        error( "hmac key must be exactly " .. block_size .. " bytes, use `hmac.normalizeKey` first", 2 )
    end

    local outer_tbl, inner_tbl = {}, {}

    for i = 1, block_size, 1 do
        local byte = string_byte( key, i )
        outer_tbl[ i ] = bit_bxor( byte, 0x5c )
        inner_tbl[ i ] = bit_bxor( byte, 0x36 )
    end

    return string_char( table_unpack( outer_tbl, 1, block_size ) ), string_char( table_unpack( inner_tbl, 1, block_size ) )
end

hmac.pads = pads

--- [SHARED AND MENU]
---
--- Computes hmac of the message using precomputed pads from `hmac.pads`.
---
---@param message string The message to compute hmac for.
---@param outer string The outer pad.
---@param inner string The inner pad.
---@param digest_fn fun( data: string, as_hex?: boolean ): string The hash function to use.
---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
---@return string hmac_str The hmac string of the message.
---@nodiscard
function hmac.digestWithPads( message, outer, inner, digest_fn, as_hex )
    return digest_fn( outer .. digest_fn( inner .. message ), as_hex )
end

--- [SHARED AND MENU]
---
--- Computes hmac of the message using the given hash function.
---
---@param message string The message to compute hmac for.
---@param key string The key to use.
---@param digest_fn fun( data: string, as_hex?: boolean ): string The hash function to use.
---@param block_size integer The block size of the hash function.
---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
---@return string hmac_str The hmac string of the message.
---@nodiscard
local function digest( message, key, digest_fn, block_size, as_hex )
    local outer, inner = pads( normalizeKey( key, digest_fn, block_size ), block_size )
    return digest_fn( outer .. digest_fn( inner .. message ), as_hex )
end

hmac.digest = digest

--- [SHARED AND MENU]
---
--- Returns a function that computes hmac using the given hash class.
---
---@param hash dreamwork.std.crypto.HashClass The hash class to use, e.g. `std.crypto.SHA256`.
---@return fun( message: string, key: string, as_hex?: boolean ): string
---@nodiscard
function hmac.preset( hash )
    local digest_fn, block_size = hash.digest, hash.block_size

    ---@param message string The message to compute hmac for.
    ---@param key string The key to use.
    ---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
    ---@return string hmac_str The hmac string of the message.
    return function( message, key, as_hex )
        return digest( message, key, digest_fn, block_size, as_hex )
    end
end

--- [SHARED AND MENU]
---
--- Computes a hmac using the MD5 hashing.
---
hmac.md5 = hmac.preset( crypto.MD5 )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-1 hashing.
---
hmac.sha1 = hmac.preset( crypto.SHA1 )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-256 hashing.
---
hmac.sha256 = hmac.preset( crypto.SHA256 )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-384 hashing.
---
hmac.sha384 = hmac.preset( crypto.SHA384 )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-512 hashing.
---
hmac.sha512 = hmac.preset( crypto.SHA512 )
