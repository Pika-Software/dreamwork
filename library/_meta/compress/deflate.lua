---@meta _


--- [SHARED AND MENU]
---
--- Options of `deflate.compress` and `zlib.compress`, every field is optional.
---
--- Strategies are the same as zlib's:
--- * `"default"` - LZ77 matches and the smallest of stored, fixed and dynamic Huffman blocks.
--- * `"filtered"` - drops matches shorter than 6 bytes, for data with small random changes like filtered images, levels `4` - `9` only.
--- * `"huffman_only"` - no matches, only Huffman coding of bytes.
--- * `"rle"` - only matches of the previous byte, fast and close to PNG-style run-length encoding.
--- * `"fixed"` - only fixed Huffman blocks, smaller and faster for very short data.
---
---@class deflate.Options
---@field level? integer The compression level ( 0 - 9 ), `0` stores the data without compression, `1` is the fastest, `9` gives the smallest output, `6` by default.
---@field strategy? "default" | "filtered" | "huffman_only" | "rle" | "fixed" The compression strategy, `"default"` by default.
---@field dictionary? string The preset dictionary, data that is likely to appear in the input, the last 32768 bytes of it are used, the same dictionary is required to decompress.
