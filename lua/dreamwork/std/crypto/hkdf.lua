local std = dreamwork.std

local error = std.error

local math = std.math
local math_ceil = math.ceil

local table = std.table
local table_concat = table.concat

local string = std.string
local string_sub = string.sub
local string_rep = string.rep
local string_char = string.char

---@class dreamwork.std.crypto
local crypto = std.crypto

local hmac = crypto.hmac
local hmac_normalizeKey = hmac.normalizeKey
local hmac_pads = hmac.pads
local hmac_digestWithPads = hmac.digestWithPads


--- [SHARED AND MENU]
---
--- HMAC-based Extract-and-Expand Key Derivation Function library.
---
--- Can be called directly as `crypto.hkdf( options )`, see `hkdf.derive`.
---
--- See [RFC 5869](https://datatracker.ietf.org/doc/html/rfc5869) for the algorithm.
---
---@class dreamwork.std.crypto.hkdf
---@overload fun( options: dreamwork.std.hkdf.Options ): string
local hkdf = {}
crypto.hkdf = hkdf

--- [SHARED AND MENU]
---
--- HKDF-Extract step, computes a pseudorandom key (PRK) from the input keying material.
---
---@param hash dreamwork.std.crypto.HashClass The hash class to use, e.g. `std.crypto.SHA256`.
---@param key string The input keying material (IKM).
---@param salt? string The optional salt, default is a string of `digest_size` zero bytes.
---@return string prk The pseudorandom key as a binary string of `digest_size` bytes.
---@nodiscard
local function extract( hash, key, salt )
    if salt == nil or salt == "" then
        salt = string_rep( "\0", hash.digest_size )
    end

    local digest_fn, block_size = hash.digest, hash.block_size
    local outer, inner = hmac_pads( hmac_normalizeKey( salt, digest_fn, block_size ), block_size )
    return hmac_digestWithPads( key, outer, inner, digest_fn )
end

hkdf.extract = extract

--- [SHARED AND MENU]
---
--- HKDF-Expand step, expands the pseudorandom key into the output keying material (OKM).
---
---@param hash dreamwork.std.crypto.HashClass The hash class to use, e.g. `std.crypto.SHA256`.
---@param prk string The pseudorandom key, usually the result of `hkdf.extract`.
---@param info? string The optional context and application specific information, default is an empty string.
---@param length? integer The length of the output keying material in bytes, default is `digest_size`, must not exceed `255 * digest_size`.
---@return string okm The output keying material as a binary string of `length` bytes.
---@nodiscard
local function expand( hash, prk, info, length )
    local digest_size = hash.digest_size
    if length == nil then
        length = digest_size
    end

    if info == nil then
        info = ""
    end

    local block_count = math_ceil( length / digest_size )
    if block_count > 255 then
        error( "hkdf length must not exceed " .. (255 * digest_size) .. " bytes", 2 )
    end

    local block_size = hash.block_size
    local digest_fn = hash.digest

    local outer, inner = hmac_pads( hmac_normalizeKey( prk, digest_fn, block_size ), block_size )

    local blocks = {}
    local t = ""

    for block = 1, block_count, 1 do
        t = hmac_digestWithPads( t .. info .. string_char( block ), outer, inner, digest_fn )
        blocks[ block ] = t
    end

    return string_sub( table_concat( blocks, "", 1, block_count ), 1, length )
end

hkdf.expand = expand

--- [SHARED AND MENU]
---
--- Derives a key using the hkdf algorithm, extract and expand in one step.
---
---@param options dreamwork.std.hkdf.Options
---@return string hkdf_str The derived key as a binary string of `length` bytes.
---@nodiscard
function hkdf.derive( options )
    local hkdf_hash = options.hash
    return expand( hkdf_hash, extract( hkdf_hash, options.key, options.salt ), options.info, options.length )
end
