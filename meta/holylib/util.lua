---@meta holylib.util


---@class garrysmod.util
util = {}

--- [SHARED AND MENU]
---
--- Compresses the given data using [LZMA](https://en.wikipedia.org/wiki/LZMA) on a separate thread.
---
--- The number of threads used is controlled by the `holylib_util_compressthreads` convar.
---
---@param decompressed_data string The data to compress.
---@param callback fun( compressed_data: string | nil ) The function called with the compressed data, or `nil` on failure.
---@overload fun( decompressed_data: string, level: integer?, dictionary_size: integer?, callback: fun( compressed_data: string | nil ) )
function util.AsyncCompress( decompressed_data, callback ) end

--- [SHARED AND MENU]
---
--- Decompresses the given data using [LZMA](https://en.wikipedia.org/wiki/LZMA) on a separate thread.
---
--- The number of threads used is controlled by the `holylib_util_decompressthreads` convar.
---
---@param compressed_data string The data to decompress.
---@param callback fun( decompressed_data: string | nil ) The function called with the decompressed data, or `nil` on failure.
---@param ratio number? The maximum allowed compression ratio, used to protect against decompression bombs. Defaults to `0.98`.
function util.AsyncDecompress( compressed_data, callback, ratio ) end

--- [SHARED AND MENU]
---
--- Converts a table to a JSON string.
---
--- Unlike [util.TableToJSON](https://wiki.facepunch.com/gmod/util.TableToJSON), integers stay integers, sequential tables become JSON arrays, non-finite numbers become `null`, vectors become `"[x y z]"` and angles become `"{x y z}"`.
---
---@param tbl table The table to convert.
---@param pretty_print boolean? Format and indent the JSON with tabs.
---@param ignore_cycles boolean? If `true`, cyclic references are skipped instead of throwing an error.
---@return string json_str The JSON string.
function util.FancyTableToJSON( tbl, pretty_print, ignore_cycles ) end

--- [SHARED AND MENU]
---
--- Converts a JSON string to a Lua table.
---
--- Strings in `[x y z]` format are converted to vectors and strings in `{x y z}` format to angles.
---
--- Throws an error if the JSON string is invalid.
---
---@param json_str string The JSON string to convert.
---@param ignore_conversions boolean? If `true`, numeric-looking object keys stay strings.
---@return table tbl The converted table.
function util.FancyJSONToTable( json_str, ignore_conversions ) end

--- [SHARED AND MENU]
---
--- Compresses the given data using [LZ4](https://github.com/lz4/lz4).
---
---@param decompressed_data string The data to compress.
---@param acceleration integer? The acceleration level, higher is faster but compresses worse. Defaults to `1`.
---@return string | nil compressed_data The compressed data, or `nil` on failure.
function util.CompressLZ4( decompressed_data, acceleration ) end

--- [SHARED AND MENU]
---
--- Decompresses the given data using [LZ4](https://github.com/lz4/lz4).
---
---@param compressed_data string The data to decompress.
---@return string | nil decompressed_data The decompressed data, or `nil` on failure.
function util.DecompressLZ4( compressed_data ) end

--- [SHARED AND MENU]
---
--- Converts a table to a JSON string on a separate thread.
---
--- The table is copied and made read-only while the job runs.
---
--- Requires the HolyLib `luajit` module to be enabled, throws an error otherwise.
---
---@param tbl table The table to convert.
---@param callback fun( json_str: string ) The function called with the JSON string.
---@param pretty_print boolean? Format and indent the JSON.
function util.AsyncTableToJSON( tbl, callback, pretty_print ) end
