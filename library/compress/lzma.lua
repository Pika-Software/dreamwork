---@meta _

--- [SHARED AND MENU]
---
--- The lzma library, compresses and decompresses strings in the format used by `util.Compress`.
---
--- The format is the 5 bytes of lzma properties, the decompressed size as 8 bytes in little endian and the raw lzma stream.
---
--- When HolyLib is installed and the call is made from a coroutine, the work is done on a separate thread
--- with `util.AsyncCompress` / `util.AsyncDecompress` and the coroutine waits for the result, otherwise the call is synchronous.
---
---@class lzma
---@field PROPS_SIZE integer The size of the lzma properties in bytes.
lzma = {}

lzma.PROPS_SIZE = 5

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
function lzma.size(str) end

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
function lzma.validate(compressed_data) end

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
function lzma.compress(data, level, dictionary_size) end

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
function lzma.decompress(compressed_data, ratio) end
