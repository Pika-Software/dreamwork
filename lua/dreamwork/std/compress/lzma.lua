local dreamwork_engine = dreamwork.engine

---@type garrysmod.util
local glua_util = dreamwork_engine.requireLibrary( "util" )
local util_AsyncCompress = glua_util.AsyncCompress
local util_AsyncDecompress = glua_util.AsyncDecompress

---@class dreamwork.std
local std = dreamwork.std

local pack = std.pack
local pack_readUInt32LE = pack.readUInt32LE


--- [SHARED AND MENU]
---
--- The lzma format is a lossless data compression algorithm that is used to compress large files.
---
---@class dreamwork.std.lzma
---@field PROPS_SIZE number The size of the lzma properties in bytes.
local lzma = { PROPS_SIZE = 5 }
std.lzma = lzma

lzma.compress = glua_util.Compress or function() return nil end
lzma.decompress = glua_util.Decompress or function() return nil end

--- [SHARED AND MENU]
---
--- Returns the decompressed size of the given string.
---
---@param str string Compressed string.
---@return integer size The decompressed size in bytes.
---@nodiscard
function lzma.size( str )
    return pack_readUInt32LE( str, 6 )
end

-- Fallbacks for servers without HolyLib, both run on the next tick and report callback errors like HolyLib does.
if util_AsyncCompress == nil then
    local lzma_compress = lzma.compress
    local setTimeout = std.setTimeout

    ---@param decompressed_data string
    ---@param callback fun( compressed_data: string | nil )
    local function compress_job( decompressed_data, callback )
        callback( lzma_compress( decompressed_data ) )
    end

    -- `level` and `dictionary_size` are ignored, native `util.Compress` has no such options.
    function util_AsyncCompress( decompressed_data, level, dictionary_size, callback )
        setTimeout( compress_job, 0, decompressed_data, callback or level )
    end
end

lzma.asyncCompress = util_AsyncCompress

if util_AsyncDecompress == nil then
    local lzma_decompress = lzma.decompress
    local lzma_size = lzma.size
    local setTimeout = std.setTimeout
    local math_floor = std.math.floor

    -- Mirrors `Bootil::Compression::LZMA::Extract` checks.
    ---@param compressed_data string
    ---@param callback fun( decompressed_data: string | nil )
    ---@param ratio number
    local function decompress_job( compressed_data, callback, ratio )
        local length = #compressed_data
        if ratio <= 0 or length <= 13 then
            callback( nil )
            return
        end

        local size = lzma_size( compressed_data )
        if ratio < 1 and math_floor( size / length ) > 1 / (1 - ratio) then
            callback( nil )
            return
        end

        callback( lzma_decompress( compressed_data, size ) )
    end

    function util_AsyncDecompress( compressed_data, callback, ratio )
        setTimeout( decompress_job, 0, compressed_data, callback, ratio or 0.98 )
    end
end

lzma.asyncDecompress = util_AsyncDecompress
