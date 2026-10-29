---@meta _

--- [SHARED AND MENU]
---
--- A library for compressing and decompressing data using the deflate algorithm and more.
---
---@class deflate
deflate = {}

--- [SHARED AND MENU]
---
--- A library for compressing and decompressing data using the zlib algorithm and more.
---
---@class zlib
zlib = {}

--- Create a preset dictionary.
---
--- This function is not fast, and the memory consumption of the produced
--- dictionary is about 50 times of the input string. Therefore, it is suggestted
--- to run this function only once in your program.
---
--- It is very important to know that if you do use a preset dictionary,
--- compressors and decompressors MUST USE THE SAME dictionary. That is,
--- dictionary must be created using the same string. If you update your program
--- with a new dictionary, people with the old version won't be able to transmit
--- data with people with the new version. Therefore, changing the dictionary must be very careful.
---
---
--- The parameters "strlen" and "adler32" add a layer of verification to ensure
--- the parameter "str" is not modified unintentionally during the program development.
---
---
---@usage local dict_str = "1234567890"
---
--- print(dict_str:len(), deflate.calculateAdler32(dict_str))
--- Hardcode the print result below to verify it to avoid acciently
--- modification of 'str' during the program development.
--- string length: 10, Adler-32: 187433486,
--- Don't calculate string length and its Adler-32 at run-time.
---
--- local dict = deflate.createDictionary(dict_str, 10, 187433486)
---
---@param str string The string used as the preset dictionary.
---
---You should put stuffs that frequently appears in the dictionary
---string and preferablely put more frequently appeared stuffs toward the end of the string.
---
---
--- Empty string and string longer than 32768 bytes are not allowed.
---@return table dict The dictionary used for preset dictionary compression and decompression.
---@nodiscard
---@raise error if 'strlen' does not match the length of 'str',
--- or if 'adler32' does not match the Adler-32 checksum of 'str'.
function deflate.createDictionary(str) end

--- The description to compression configuration table.
---
--- Any field can be nil to use its default.
---
--- Table with keys other than those below is an invalid table.
---@class compression_configs
---@field level number The compression level ranged from 0 to 9. 0 is no compression. 9 is the slowest but best compression. Use nil for default level.
---@field strategy string The compression strategy. "fixed" to only use fixed deflate compression block. "dynamic" to only use dynamic block. "huffman_only" to do no LZ77 compression. Only do huffman compression.

--- Compress using the raw deflate format.
---@param str string The data to be compressed.
---@param configs? table The configuration table to control the compression.
---@param dictionary? table The dictionary to use.
--- If nil, use the default configuration.
---@return string? result The compressed data.
---@return number bit_count The number of bits padded at the end of output.
---@nodiscard
--- 0 <= bits < 8
---
--- This means the most significant "bits" of the last byte of the returned
--- compressed data are padding bits and they don't affect decompression.
--- You don't need to use this value unless you want to do some postprocessing
--- to the compressed data.
---@see compression_configs
---@see deflate.decompress
function deflate.compress(str, configs, dictionary) end

--- Compress using the zlib format.
---@param str string the data to be compressed.
---@param configs? table The configuration table to control the compression. If `nil`, use the default configuration.
---@param dictionary? table A preset dictionary produced by deflate.createDictionary()
---@return string? result The compressed data.
---@return number bit_count The number of bits padded at the end of output.
---@nodiscard
--- Should always be 0.
--- Zlib formatted compressed data never has padding bits at the end.
---@see compression_configs
---@see zlib.compress
---@see zlib.decompress
function zlib.compress(str, configs, dictionary) end

--- Decompress a raw deflate compressed data.
---@param str string The data to be decompressed.
---@param dictionary? table The dictionary to be used.
---@return string | nil data If the decompression succeeds, return the decompressed data.
--- If the decompression fails, return nil. You should check if this return
--- value is non-nil to know if the decompression succeeds.
---@return number | nil byte_count If the decompression succeeds, return the number of
---@nodiscard
--- unprocessed bytes in the input compressed data. This return value is a
--- positive integer if the input data is a valid compressed data appended by an
--- arbitary non-empty string. This return value is 0 if the input data does not
--- contain any extra bytes.
---
--- If the decompression fails (The first return value of this function is nil),
--- this return value is undefined.
---@see deflate.compress
---@see deflate.decompress(str)
function deflate.decompress(str, dictionary) end

--- Decompress a zlib compressed data.
---@param str string The data to be decompressed
---@param dictionary? table The dictionary to be used
---@return string | nil data If the decompression succeeds, return the decompressed data.
--- If the decompression fails, return nil. You should check if this return
--- value is non-nil to know if the decompression succeeds.
---@return number | nil byte_count If the decompression succeeds, return the number of
---@nodiscard
--- unprocessed bytes in the input compressed data. This return value is a
--- positive integer if the input data is a valid compressed data appended by an
--- arbitary non-empty string. This return value is 0 if the input data does not
--- contain any extra bytes.
---
--- If the decompression fails (The first return value of this function is nil),
--- this return value is undefined.
---@see zlib.compress
---@see zlib.decompress(str)
function zlib.decompress(str, dictionary) end

--- Create a custom codec with encoder and decoder.
---
--- This codec is used to convert an input string to make it not contain some specific bytes.
---
--- This created codec and the parameters of this function do NOT take
--- localization into account. One byte (0-255) in the string is exactly one character (0-255).
---
--- Credits to LibCompress.
--- The code has been rewritten by the author of deflate.
---
---@param reserved_chars string The created encoder will ensure encoded
--- data does not contain any single character in reserved_chars. This parameter should be non-empty.
---
---@param escape_chars string The escape character(s) used in the created codec.
--- The codec converts any character included in reserved\_chars /
--- escape\_chars / map\_chars to (one escape char + one character not in
--- reserved\_chars / escape\_chars / map\_chars).
--- You usually only need to provide a length-1 string for this parameter.
--- Length-2 string is only needed when
--- reserved\_chars + escape\_chars + map\_chars is longer than 127.
--- This parameter should be non-empty.
---@param map_chars string The created encoder will map every
--- reserved\_chars:sub(i, i) (1 <= i <= #map\_chars) to map\_chars:sub(i, i).
--- This parameter CAN be empty string.
---@return table? codec  If the codec cannot be created, return nil.
---
--- If the codec can be created according to the given
--- parameters, return the codec, which is a encode/decode table.
--- The table contains two functions:
---
--- t:encode(str) returns the encoded string.
---
--- t:decode(str) returns the decoded string if succeeds. nil if fails.
---@return string? message  If the codec is successfully created, return nil.
---@nodiscard
--- If not, return a string that describes the reason why the codec cannot be created.
---
---@usage
--- Create an encoder/decoder that maps all "\000" to "\003",
--- and escape "\001" (and "\002" and "\003") properly
--- local codec = deflate.createCodec("\000\001", "\002", "\003")
---
--- local encoded = codec:encode(SOME_STRING)
--- "encoded" does not contain "\000" or "\001"
--- local decoded = codec:decode(encoded)
--- assert(decoded == SOME_STRING)
function deflate.createCodec(reserved_chars, escape_chars, map_chars) end

--- encode the string to make it ready to be transmitted in World of Warcraft addon channel.
---
---
--- The encoded string is guaranteed to contain no NULL ("\000") character.
---@param str string The string to be encoded.
---@return string result The encoded string.
---@nodiscard
---@see deflate.decodeForWoWAddonChannel
function deflate.encodeForWoWAddonChannel(str) end

--- Decode the string produced by deflate.encodeForWoWAddonChannel
---@param str string The string to be decoded.
---@return string | nil result The decoded string if succeeds. nil if fails.
---@nodiscard
---@see deflate.encodeForWoWAddonChannel
function deflate.decodeForWoWAddonChannel(str) end

--- encode the string to make it ready to be transmitted in World of Warcraft chat channel.
---
--- See also https://wow.gamepedia.com/ValidChatMessageCharacters
---@param str string The string to be encoded.
---@return string The encoded string.
---@nodiscard
---@see deflate.decodeForWoWChatChannel
function deflate.encodeForWoWChatChannel(str) end

--- Decode the string produced by deflate.encodeForWoWChatChannel.
---@param str string The string to be decoded.
---@return string | nil result The decoded string if succeeds. nil if fails.
---@nodiscard
---@see deflate.encodeForWoWChatChannel
function deflate.decodeForWoWChatChannel(str) end

--- Clear the cache of the World of Warcraft addon channel codec.
function deflate.clearWoWCache() end

--- encode the string to make it printable.
---
---
--- Credit to WeakAuras2, this function is equivalant to the implementation it is using right now.
---
--- The code has been rewritten by the author of deflate.
---
--- The encoded string will be 25% larger than the origin string. However, every
--- single byte of the encoded string will be one of 64 printable ASCII
--- characters, which are can be easier copied, pasted and displayed.
--- (26 lowercase letters, 26 uppercase letters, 10 numbers digits, left parenthese, or right parenthese)
---@param str string The string to be encoded.
---@return string result The encoded string.
---@nodiscard
function deflate.encodeForPrint(str) end

--- Decode the printable string produced by deflate.encodeForPrint.
--- "str" will have its prefixed and trailing control characters or space
--- removed before it is decoded, so it is easier to use if "str" comes form
--- user copy and paste with some prefixed or trailing spaces.
--- Then decode fails if the string contains any characters cant be produced by deflate.encodeForPrint.
--- That means, decode fails if the string contains a
--- characters NOT one of 26 lowercase letters, 26 uppercase letters,
--- 10 numbers digits, left parenthese, or right parenthese.
---@param str string The string to be decoded
---@return string | nil result The decoded string if succeeds. nil if fails.
---@nodiscard
function deflate.decodeForPrint(str) end
