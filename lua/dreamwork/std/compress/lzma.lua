local dreamwork_engine = dreamwork.engine

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_fempty = debug.fempty

local math = std.math
local math_floor = math.floor

local coroutine = std.coroutine
local coroutine_isyieldable = coroutine.isyieldable

local string = std.string
local string_byte = string.byte
local string_format = string.format

local bytepack = std.bytepack
local bytepack_readUInt32LE = bytepack.readUInt32LE

local pack = std.pack
local pack_readUInt32LE = pack.readUInt32LE

local Future = std.Future


---@type garrysmod.util
local glua_util = dreamwork_engine.requireLibrary( "util" )

local util_Compress = glua_util.Compress or debug_fempty
local util_Decompress = glua_util.Decompress or debug_fempty
local util_AsyncCompress = glua_util.AsyncCompress
local util_AsyncDecompress = glua_util.AsyncDecompress


--- [SHARED AND MENU]
---
--- The lzma library, compresses and decompresses strings in the format used by `util.Compress`.
---
--- The format is the 5 bytes of lzma properties, the decompressed size as 8 bytes in little endian and the raw lzma stream.
---
--- When HolyLib is installed and the call is made from a coroutine, the work is done on a separate thread
--- with `util.AsyncCompress` / `util.AsyncDecompress` and the coroutine waits for the result, otherwise the call is synchronous.
---
---@class dreamwork.std.lzma
---@field PROPS_SIZE integer The size of the lzma properties in bytes.
local lzma = { PROPS_SIZE = 5 }
std.lzma = lzma

--- [SHARED AND MENU]
---
--- Returns the decompressed size stored in the header of the lzma data.
---
--- Only the low 32 bits of the 64-bit size field are read.
---
--- Throws an error if the data is shorter than 9 bytes.
---
---@param str string The lzma data.
---@return integer size The decompressed size in bytes.
---@nodiscard
function lzma.size( str )
    return pack_readUInt32LE( str, 6 )
end

--- [SHARED AND MENU]
---
--- Checks if the string starts with a valid lzma header, the same check HolyLib and the engine do before decompressing.
---
--- The data must be longer than the 13 bytes of the header, the properties byte must be below `225` ( `( pb * 5 + lp ) * 9 + lc` )
--- and the dictionary size must be at least 4096 bytes.
---
--- The stream itself is not checked, so `lzma.decompress` can still fail on a valid header.
---
---@param compressed_data string The lzma data.
---@return boolean is_valid `true` if the header is valid, `false` otherwise.
---@return nil | string err_msg The reason why the header is invalid.
---@nodiscard
local function validate( compressed_data )
    local length = #compressed_data
    if length <= 13 then
        return false, string_format( "data is too short, expected more than 13 bytes, got %d", length )
    end

    local properties, dictionary_1, dictionary_2, dictionary_3, dictionary_4 = string_byte( compressed_data, 1, 5 )
    if properties >= 225 then
        return false, string_format( "invalid properties byte 0x%02X, expected below 0xE1", properties )
    end

    local dictionary_size = bytepack_readUInt32LE( dictionary_1, dictionary_2, dictionary_3, dictionary_4 )
    if dictionary_size < 4096 then
        return false, string_format( "invalid dictionary size %d, expected at least 4096", dictionary_size )
    end

    return true
end

lzma.validate = validate

--- [SHARED AND MENU]
---
--- Compresses a string into lzma data.
---
--- Runs on a separate thread when HolyLib is installed and the call is made from a coroutine,
--- synchronously with `util.Compress` otherwise.
---
--- Throws an error if the compression fails.
---
---@param data string The string to compress.
---@param level integer? The compression level from `0` to `9`, `5` by default, only used by HolyLib.
---@param dictionary_size integer? The dictionary size in bytes, `65536` by default, only used by HolyLib.
---@return string compressed_data The compressed data.
---@nodiscard
---@async
function lzma.compress( data, level, dictionary_size )
    local compressed_data
    if util_AsyncCompress == nil or not coroutine_isyieldable() then
        compressed_data = util_Compress( data )
    else
        ---@type dreamwork.std.Future<( string | nil )>
        local f = Future()

        util_AsyncCompress( data, level or 5, dictionary_size or 65536, function( result )
            f:setResult( result )
        end )

        compressed_data = f:await()
    end

    if compressed_data == nil then
        error( string_format( "lzma compression of %d bytes failed", #data ), 2 )
    end

    return compressed_data
end

--- [SHARED AND MENU]
---
--- Decompresses lzma data.
---
--- Runs on a separate thread when HolyLib is installed and the call is made from a coroutine,
--- synchronously with `util.Decompress` otherwise.
---
--- `ratio` protects against decompression bombs, the data is rejected if
--- `decompressed_size // compressed_size` is greater than `1 / ( 1 - ratio )`,
--- `0.98` allows less than 50 times the compressed size ( floating point makes the limit `49.99...` ), `nil` or `1` and more disables the check.
---
--- Throws an error on an invalid header ( see `lzma.validate` ), malformed or truncated data, a `ratio` of `0` or less, or if the ratio is exceeded;
--- call via `pcall()` when processing untrusted input.
---
---@param compressed_data string The lzma data to decompress.
---@param ratio number? The maximum allowed compression ratio, no limit by default.
---@return string decompressed_data The decompressed string.
---@nodiscard
---@async
function lzma.decompress( compressed_data, ratio )
    local is_valid, err_msg = validate( compressed_data )
    if not is_valid then
        error( "corrupt lzma data: " .. err_msg, 2 )
    end

    local decompressed_size = bytepack_readUInt32LE( string_byte( compressed_data, 6, 9 ) )

    -- the engine returns garbage instead of an empty string for streams of 0 bytes
    if decompressed_size == 0 then
        return ""
    end

    local length = #compressed_data

    if ratio ~= nil then
        if ratio <= 0 then
            error( string_format( "lzma ratio must be greater than 0, got %s", ratio ), 2 )
        end

        if ratio < 1 then
            local max_ratio = 1 / (1 - ratio)
            local data_ratio = math_floor( decompressed_size / length )

            if data_ratio > max_ratio then
                error( string_format( "lzma data exceeds the allowed compression ratio, %d bytes decompress into %d bytes ( %dx, ratio %s allows up to %dx )", length, decompressed_size, data_ratio, ratio, math_floor( max_ratio ) ), 2 )
            end
        end
    end

    local decompressed_data
    if util_AsyncDecompress == nil or not coroutine_isyieldable() then
        decompressed_data = util_Decompress( compressed_data, decompressed_size )
    else
        ---@type dreamwork.std.Future<( string | nil )>
        local f = Future()

        -- header and ratio are already checked
        util_AsyncDecompress( compressed_data, function( result )
            f:setResult( result )
        end, 1 )

        decompressed_data = f:await()
    end

    if decompressed_data == nil then
        error( string_format( "corrupt lzma data: the stream of %d bytes could not be decoded into %d bytes", length - 13, decompressed_size ), 2 )
    end

    return decompressed_data
end
