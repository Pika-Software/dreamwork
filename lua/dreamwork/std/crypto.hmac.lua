local std = _G.dreamwork.std
local string = std.string

---@class dreamwork.std.crypto
local crypto = std.crypto

--- [SHARED AND MENU]
---
--- A hmac library.
---
---@class dreamwork.std.crypto.hmac
local hmac = crypto.hmac or {}
crypto.hmac = hmac

local key_normalize
do

    local string_len, string_rep = string.len, string.rep

    --- [SHARED AND MENU]
    ---
    --- Normalizes the key to the block size of the hash function.
    ---
    ---@param key string The key to normalize.
    ---@param hash_fn function
    ---@param block_size integer The block size of the hash function.
    ---@return string hmac_key The normalized key.
    function key_normalize( key, hash_fn, block_size )
        local key_length = string_len( key )
        if key_length > block_size then
            return key_normalize( hash_fn( key ), hash_fn, block_size )
        elseif key_length < block_size then
            return key .. string_rep( "\0", block_size - key_length )
        else
            return key
        end
    end

    hmac.key = key_normalize

end

local key_padding
do

    local string_byte, string_char = string.byte, string.char
    local table_unpack = std.table.unpack
    local bit_bxor = std.bit.bxor

    --- [SHARED AND MENU]
    ---
    --- Computes the key padding.
    ---
    --- This function will NOT check
    --- if the padding's entered into
    --- it is correct.
    ---
    --- See https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation for the algorithm.
    ---
    ---@param key string The normalized by given block size key.
    ---@param block_size integer The block size of the hash function.
    ---@param outer? string The known outer padding.
    ---@param inner? string The known inner padding.
    ---@return string outer The outer padding.
    ---@return string inner The inner padding.
    function key_padding( key, block_size, outer, inner )
        if outer == nil and inner == nil then
            local outer_tbl, inner_tbl = {}, {}

            for i = 1, block_size, 1 do
                local byte = string_byte( key, i )
                outer_tbl[ i ] = bit_bxor( byte, 0x5c )
                inner_tbl[ i ] = bit_bxor( byte, 0x36 )
            end

            return string_char( table_unpack( outer_tbl, 1, block_size ) ), string_char( table_unpack( inner_tbl, 1, block_size ) )
        elseif outer == nil then
            ---@cast inner string
            local outer_tbl = {}

            for i = 1, block_size, 1 do
                outer_tbl[ i ] = bit_bxor( string_byte( key, i ), 0x5c )
            end

            return string_char( table_unpack( outer_tbl, 1, block_size ) ), inner
        elseif inner == nil then
            ---@cast outer string
            local inner_tbl = {}

            for i = 1, block_size, 1 do
                inner_tbl[ i ] = bit_bxor( string_byte( key, i ), 0x36 )
            end

            return outer, string_char( table_unpack( inner_tbl, 1, block_size ) )
        else
            ---@cast inner string
            ---@cast outer string
            return outer, inner
        end
    end

    hmac.padding = key_padding

end

---@alias dreamwork.std.crypto.hmac.Hash fun( message: string, as_hex?: boolean ): string

--- [SHARED AND MENU]
---
--- Computes hmac and returns the result using the given hash function.
---
---@param hash_fn dreamwork.std.crypto.hmac.Hash The hash function to use.
---@param outer string The outer hmac padding.
---@param inner string The inner hmac padding.
---@param msg string The message to compute hmac for.
---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
---@return string hmac_str The binary hmac string of the message.
function hmac.compute( hash_fn, outer, inner, msg, as_hex )
    return hash_fn( outer .. hash_fn( inner .. msg, false ), as_hex )
end

do

    --- [SHARED AND MENU]
    ---
    --- Computes hmac and returns the result using the given hash function.
    ---
    ---@param msg string The message to compute hmac for.
    ---@param key string The key to use.
    ---@param hash_fn dreamwork.std.crypto.hmac.Hash The hash function to use.
    ---@param block_size integer The block size of the hash function.
    ---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
    ---@return string str_result The hmac string of the message.
    local function hash( msg, key, hash_fn, block_size, as_hex )
        local outer, inner = key_padding( key_normalize( key, hash_fn, block_size ), block_size )
        return hash_fn( outer .. hash_fn( inner .. msg, false ), as_hex )
    end

    hmac.hash = hash

    local std_hash = std.hash

    --- [SHARED AND MENU]
    ---
    --- Returns a function that computes hmac using the given hash function and block length.
    ---
    ---@param hash_name string The name of the hash function to use.
    ---@return fun( message: string, key: string, as_hex?: boolean ): string
    function hmac.preset( hash_name )
        local hash_class = std_hash[ hash_name ]
        if hash_class == nil then
            std.errorf( 2, false, "hash.%sClass not found.", hash_name )
        end

        ---@cast hash_class dreamwork.std.hash.MD5Class

        local digest_fn = hash_class.digest
        local block_size = hash_class.block_size

        ---@param message string The message to compute hmac for.
        ---@param key string The key to use.
        ---@param as_hex? boolean `true` if the result should be a hex string, `false` otherwise.
        ---@return string str_result The hmac string of the message.
        return function( message, key, as_hex )
            return hash( message, key, digest_fn, block_size, as_hex )
        end
    end

end

--- [SHARED AND MENU]
---
--- Computes a hmac using the MD5 hashing.
---
hmac.md5 = hmac.preset( "MD5" )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-1 hashing.
---
hmac.sha1 = hmac.preset( "SHA1" )

--- [SHARED AND MENU]
---
--- Computes a hmac using the SHA-256 hashing.
---
hmac.sha256 = hmac.preset( "SHA256" )
