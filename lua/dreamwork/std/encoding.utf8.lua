local std = _G.dreamwork.std
---@class dreamwork.std.encoding
local encoding = std.encoding

local string = std.string
local string_len, string_sub = string.len, string.sub
local string_char, string_byte = string.char, string.byte

local math = std.math
local math_min = math.min
local math_relative = math.relative

local bit = std.bit
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat

local select = std.select

--- [SHARED AND MENU]
---
--- The utf8 library is a standard Lua library which provides functions for the manipulation of UTF-8 strings.
---
--- In dreamwork utf8 library rewrited from zero and contains additional functions.
---
---@class dreamwork.std.encoding.utf8
---@field charpattern string This is NOT a function, it's a pattern (a string, not a function) which matches exactly one UTF-8 byte sequence, assuming that the subject is a valid UTF-8 string.
---@field limit integer The maximum number of characters that can be stored in a UTF-8 string.
local utf8 = encoding.utf8 or {}
encoding.utf8 = utf8

---@alias dreamwork.std.encoding.utf8.Codepoint integer
---@alias dreamwork.std.encoding.utf8.Sequence dreamwork.std.encoding.utf8.Codepoint[]

utf8.charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"
utf8.limit = 0x7FFFFFFF

---@param i integer
---@return boolean
local function isContinuation( i )
	return bit_band( i, 0xC0 ) == 0x80
end

---@type table<integer, integer | nil>
local uint8_to_length = {}

for uint8 = 0, 255, 1 do
	if uint8 < 0x80 then
		uint8_to_length[ uint8 ] = 1
	elseif bit_band( uint8, 0xE0 ) == 0xC0 then
		uint8_to_length[ uint8 ] = 2
	elseif bit_band( uint8, 0xF0 ) == 0xE0 then
		uint8_to_length[ uint8 ] = 3
	elseif bit_band( uint8, 0xF8 ) == 0xF0 then
		uint8_to_length[ uint8 ] = 4
	else
		uint8_to_length[ uint8 ] = 0
	end
end

local decode
do

	local cache = {}

	---@param utf8_string string
	---@param index integer
	---@param str_length integer
	---@param strict boolean
	---@param stack_level integer
	---@return dreamwork.std.encoding.utf8.Codepoint | nil
	---@return integer | nil
	function decode( utf8_string, index, str_length, strict, stack_level )
		if stack_level == nil then
			stack_level = 1
		end

		stack_level = stack_level + 1

		local uint8_1 = string_byte( utf8_string, index, index )
		if uint8_1 < 0x80 then
			return uint8_1, 1
		elseif uint8_1 < 0xC2 then
			if strict then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (reserved continuation)", 1, uint8_1, index )
			end

			return uint8_1, nil
		end

		local sequence_length = uint8_to_length[ uint8_1 ] or 0

		if sequence_length == 0 then
			if strict then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (out of UTF-8 range)", 1, uint8_1, index )
			end

			return uint8_1, nil
		end

		local cache_key = string_sub( utf8_string, index, index + ( sequence_length - 1 ) )

		local cached = cache[ cache_key ]
		if cached ~= nil then
			return cached, sequence_length
		end

		str_length = str_length + 1
		index = index + 1

		if index == str_length then
			if strict then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte at position %d (unexpected end of string)", 2, index )
			end

			return nil, 1
		end

		local uint8_2 = string_byte( utf8_string, index, index )

		if sequence_length == 2 then
			if strict and not isContinuation( uint8_2 ) then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (out of UTF-8 range)", sequence_length, uint8_2, index )
			end

			local utf8_codepoint = bit_bor(
				bit_lshift( bit_band( uint8_1, 0x1F ), 6 ),
				bit_band( uint8_2, 0x3F )
			)

			cache[ cache_key ] = utf8_codepoint
			return utf8_codepoint, 2
		end

		index = index + 1

		if index == str_length then
			if strict then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte at position %d (unexpected end of string)", 3, index )
			end

			return nil, 2
		end

		local uint8_3 = string_byte( utf8_string, index, index )

		if sequence_length == 3 then
			if strict then
				if not isContinuation( uint8_3 ) then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (out of UTF-8 range)", sequence_length, uint8_3, index )
				elseif uint8_1 == 0xE0 and uint8_2 < 0xA0 then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (overlong encoding)", sequence_length, uint8_3, index )
				elseif uint8_1 == 0xED and uint8_2 > 0x9F then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (UTF-16 surrogate code point)", sequence_length, uint8_3, index )
				end
			end

			local utf8_codepoint = bit_bor(
				bit_lshift( bit_band( uint8_1, 0x0F ), 12 ),
				bit_lshift( bit_band( uint8_2, 0x3F ), 6 ),
				bit_band( uint8_3, 0x3F )
			)

			cache[ cache_key ] = utf8_codepoint
			return utf8_codepoint, 3
		end

		index = index + 1

		if index == str_length then
			if strict then
				std.errorf( stack_level, false, "invalid %d-byte continuation byte at position %d (unexpected end of string)", sequence_length, index )
			end

			return nil, 3
		end

		local uint8_4 = string_byte( utf8_string, index, index )

		if sequence_length == 4 then
			if strict then
				if not isContinuation( uint8_4 ) then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (out of UTF-8 range)", sequence_length, uint8_4, index )
				elseif uint8_1 == 0xF0 and uint8_2 < 0x90 then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (overlong encoding)", sequence_length, uint8_4, index )
				elseif uint8_1 == 0xF4 and uint8_2 > 0x8F then
					std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (code point exceeds U+10FFFF)", sequence_length, uint8_4, index )
				end
			end

			local utf8_codepoint = bit_bor(
				bit_lshift( bit_band( uint8_1, 0x07 ), 18 ),
				bit_lshift( bit_band( uint8_2, 0x3F ), 12 ),
				bit_lshift( bit_band( uint8_3, 0x3F ), 6 ),
				bit_band( uint8_4, 0x3F )
			)

			cache[ cache_key ] = utf8_codepoint
			return utf8_codepoint, 4
		end

		if strict then
			std.errorf( stack_level, false, "invalid %d-byte continuation byte '0x%02X' at position %d (too large)", 1, uint8_1, index - 3 )
		end

		return nil, sequence_length
	end

end

local encode
do

	---@type table<dreamwork.std.encoding.utf8.Codepoint, string>
	local cache = {}

	---@param utf8_codepoint dreamwork.std.encoding.utf8.Codepoint
	---@param strict boolean
	---@param stack_level? integer
	---@return string utf8_sequence
	function encode( utf8_codepoint, strict, stack_level )
		local utf8_sequence = cache[ utf8_codepoint ]
		if utf8_sequence ~= nil then
			return utf8_sequence
		end

		if utf8_codepoint < 0x80 then
			utf8_sequence = string_char( utf8_codepoint )
		elseif utf8_codepoint < 0x800 then
			utf8_sequence = string_char(
				bit_bor( 0xC0, bit_band( bit_rshift( utf8_codepoint, 6 ), 0x1F ) ),
				bit_bor( 0x80, bit_band( utf8_codepoint, 0x3F ) )
			)
		elseif utf8_codepoint < 0x10000 then
			utf8_sequence = string_char(
				bit_bor( 0xE0, bit_band( bit_rshift( utf8_codepoint, 12 ), 0x0F ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 6 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( utf8_codepoint, 0x3F ) )
			)
		elseif utf8_codepoint < 0x200000 then
			utf8_sequence = string_char(
				bit_bor( 0xF0, bit_band( bit_rshift( utf8_codepoint, 18 ), 0x07 ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 12 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 6 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( utf8_codepoint, 0x3F ) )
			)
		elseif utf8_codepoint < 0x4000000 then
			utf8_sequence = string_char(
				bit_bor( 0xF8, bit_band( bit_rshift( utf8_codepoint, 24 ), 0x03 ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 18 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 12 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( bit_rshift( utf8_codepoint, 6 ), 0x3F ) ),
				bit_bor( 0x80, bit_band( utf8_codepoint, 0x3F ) )
			)
		elseif strict then
			std.errorf( ( stack_level or 1 ) + 1, false, "invalid UTF-8 code point 0x%08X (code point exceeds U+10FFFF)", utf8_codepoint )
		else
			return ""
		end

		---@cast utf8_sequence string

		cache[ utf8_codepoint ] = utf8_sequence
		return utf8_sequence
	end

end

---@param utf8_string string
---@param index integer
---@param str_length integer
---@param strict boolean
---@return integer sequence_length
---@return nil | integer error_position
local function seqlen( utf8_string, index, str_length, strict )
	local uint8_1 = string_byte( utf8_string, index, index )
	local sequence_length = uint8_to_length[ uint8_1 ] or 0

	if sequence_length == 0 then
		if strict then
			if uint8_1 < 0xC2 then
				return 0, index
			else
				return 0, index
			end
		else
			return 1, nil
		end
	elseif not strict then
		return sequence_length, nil
	end

	if sequence_length == 1 then
		return 1, nil
	end

	if index == str_length then
		return 0, index
	end

	index = index + 1

	local uint8_2 = string_byte( utf8_string, index, index )

	if sequence_length == 2 then
		if isContinuation( uint8_2 ) then
			return 2, nil
		else
			return 0, index
		end
	end

	if index == str_length then
		return 0, index
	end

	index = index + 1

	local uint8_3 = string_byte( utf8_string, index, index )

	if sequence_length == 3 then
		if not isContinuation( uint8_3 ) then
			return 0, index
		elseif uint8_1 == 0xE0 and uint8_2 < 0xA0 then
			return 0, index
		elseif uint8_1 == 0xED and uint8_2 > 0x9F then
			return 0, index
		else
			return 3, nil
		end
	end

	if index == str_length then
		return 0, index
	end

	index = index + 1

	local uint8_4 = string_byte( utf8_string, index, index )

	if uint8_4 == 4 then
		if not isContinuation( uint8_4 ) then
			return 0, index
		elseif uint8_1 == 0xF0 and uint8_2 < 0x90 then
			return 0, index
		elseif uint8_1 == 0xF4 and uint8_2 > 0x8F then
			return 0, index
		else
			return 4, nil
		end
	end

	return 0, index - 3
end

--- [SHARED AND MENU]
---
--- Returns the length of the string in UTF-8 code units.
---
---@param utf8_string string The UTF-8/16/32 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer | nil sequence_length The length of the string in UTF-8 code units.
---@return nil | integer error_position The position of the error in bytes.
local function len( utf8_string, start_position, end_position, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return 0
	end

	if start_position == nil then
		start_position = 1
	elseif start_position < 0 then
		start_position = math_relative( start_position, str_length )
	else
		start_position = math_min( start_position, str_length )
	end

	if end_position == nil then
		end_position = str_length
	elseif end_position < 0 then
		end_position = math_relative( end_position, str_length )
	else
		end_position = math_min( end_position, str_length )
	end

	local utf8_codepoint_count = 0
	lax = lax ~= true

	repeat
		local sequence_length, error_position = seqlen( utf8_string, start_position, end_position, lax )
		if sequence_length == 0 then
			return nil, error_position
		else
			start_position = start_position + sequence_length
			utf8_codepoint_count = utf8_codepoint_count + 1
		end
	until start_position > end_position

	return utf8_codepoint_count, nil
end

utf8.len = len

--- [SHARED AND MENU]
---
--- Returns a table of UTF-8 code points and the length of the string in UTF-8 code units.
---
---@param utf8_string string The UTF-8/16/32 string to get the length of.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return dreamwork.std.encoding.utf8.Sequence utf8_codepoints A table of UTF-8 code points.
---@return integer utf8_codepoint_count The length of the string in UTF-8 code units.
local function unpack( utf8_string, start_position, end_position, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return {}, 0
	end

	if start_position == nil then
		start_position = 1
	elseif start_position < 0 then
		start_position = math_relative( start_position, str_length )
	else
		start_position = math_min( start_position, str_length )
	end

	if end_position == nil then
		end_position = str_length
	elseif end_position < 0 then
		end_position = math_relative( end_position, str_length )
	else
		end_position = math_min( end_position, str_length )
	end

	local utf8_codepoint_count = 0
	lax = lax ~= true

	---@type dreamwork.std.encoding.utf8.Sequence
	local utf8_codepoints = {}

	repeat
		local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_position, end_position, lax, 2 )
		start_position = start_position + ( utf8_sequence_length or 1 )

		utf8_codepoint_count = utf8_codepoint_count + 1
		utf8_codepoints[ utf8_codepoint_count ] = utf8_codepoint or 0xFFFD
	until start_position > end_position

	return utf8_codepoints, utf8_codepoint_count
end

utf8.unpack = unpack

--- [SHARED AND MENU]
---
--- Returns a substring of the string in UTF-8 code units.
---
---@param utf8_string string The UTF-8/16/32 string to get the substring of.
---@param start_position? integer The position to start from in UTF-8 code units.
---@param end_position? integer The position to end at in UTF-8 code units.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string utf8_sub The substring of the string in UTF-8 code units.
function utf8.sub( utf8_string, start_position, end_position, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return utf8_string
	end

	---@type integer | nil
	local sequence_length

	if start_position == nil then
		start_position = 1
	elseif start_position < 0 then
		local error_position
		sequence_length, error_position = len( utf8_string, 1, str_length, lax )

		if sequence_length == nil then
			std.errorf( 2, false, "invalid UTF-8 sequence byte '0x%02X' at position %d", string_byte( utf8_string, error_position, error_position ), error_position )
		end

        if ( 0 - start_position ) > sequence_length then
            return ""
        else
            start_position = sequence_length + start_position + 1
        end
	end

	if end_position ~= nil and end_position < 0 then
		if sequence_length == nil then
			local error_position
			sequence_length, error_position = len( utf8_string, 1, str_length, lax )

			if sequence_length == nil then
				std.errorf( 2, false, "invalid UTF-8 sequence byte '0x%02X' at position %d", string_byte( utf8_string, error_position, error_position ), error_position )
			end
		end

		if ( 0 - end_position ) > sequence_length then
			return ""
		else
            end_position = sequence_length + end_position + 1
        end
	end

	local utf8_start = 0
	lax = lax ~= true

	local utf8_codepoint_count = 0
	local index = 1

	repeat
		local utf8_sequence_length, error_position = seqlen( utf8_string, index, str_length, lax )

		if lax then
			if utf8_sequence_length == 0 then
				if error_position == index then
					std.errorf( 2, false, "invalid UTF-8 sequence byte '0x%02X' at position %d", string_byte( utf8_string, index, index ), index )
				else
					std.errorf( 2, false, "Corrupt UTF-8 sequence byte '0x%02X' in position %d-%d", string_byte( utf8_string, index, index ), index, error_position )
				end
			end
		elseif utf8_sequence_length == 0 then
			utf8_sequence_length = 1
		end

		utf8_codepoint_count = utf8_codepoint_count + 1

		if utf8_codepoint_count == start_position then
			utf8_start = index
		end

		if utf8_codepoint_count == end_position then
			return string_sub( utf8_string, utf8_start, index + ( utf8_sequence_length - 1 ) )
		end

		index = index + utf8_sequence_length
	until index >= str_length

	return string_sub( utf8_string, utf8_start, str_length )
end

--- [SHARED AND MENU]
---
--- Decodes a UTF-8 string into a sequence of code points.
---
--- This functions similarly to `string.byte`
---
---@param utf8_string string The UTF-8 string to decode.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return dreamwork.std.encoding.utf8.Codepoint ... The code points of the UTF-8 string.
function utf8.codepoint( utf8_string, start_position, end_position, lax )
	local utf8_codepoints, utf8_codepoint_count = unpack( utf8_string, start_position, end_position, lax )
	return table_unpack( utf8_codepoints, 1, utf8_codepoint_count )
end

do

	---@param utf8_string string
	---@param index integer
	---@return integer | nil
	---@return dreamwork.std.encoding.utf8.Codepoint | nil
	local function utf8_iterator( utf8_string, index )
		---@type integer
		local str_length = string_len( utf8_string )

		if index > str_length then
			return nil, nil
		end

		local utf8_codepoint, utf8_sequence_length = decode( utf8_string, index, str_length, false, 2 )
		return index + ( utf8_sequence_length or 1 ), utf8_codepoint or 0xFFFD
	end

	---@param utf8_string string
	---@param index integer
	---@return integer | nil
	---@return dreamwork.std.encoding.utf8.Codepoint | nil
	local function utf8_strict_iterator( utf8_string, index )
		---@type integer
		local str_length = string_len( utf8_string )

		if index > str_length then
			return nil, nil
		end

		local utf8_codepoint, utf8_sequence_length = decode( utf8_string, index, str_length, true, 2 )

		if utf8_codepoint == nil or utf8_codepoint > 0x10FFFF then
			std.errorf( 2, false, "invalid UTF-8 code point '0x%08X' at position %d", utf8_codepoint, index )
		elseif utf8_sequence_length == nil then
			std.errorf( 2, false, "invalid UTF-8 sequence '0x%02X' at position %d", string_byte( utf8_string, index, index ), index )
		end

		return index + utf8_sequence_length, utf8_codepoint
	end


	--- [SHARED AND MENU]
	---
	--- Returns an iterator function that iterates over the code points of a UTF-8 string.
	---
	---@param utf8_string string The UTF-8 string to iterate over.
	---@param lax? boolean Whether to lax the UTF-8 validity check.
	---@return ( fun( utf8_string: string, index: integer ): integer | nil, dreamwork.std.encoding.utf8.Codepoint | nil ), string, integer
	function utf8.codes( utf8_string, lax )
		return lax ~= true and utf8_strict_iterator or utf8_iterator, utf8_string, 1
	end

end

--- [SHARED AND MENU]
---
--- Encodes a sequence of code points into a UTF-8 string.
---
---@param utf8_codepoints dreamwork.std.encoding.utf8.Sequence The code points to encode.
---@param utf8_codepoint_count? integer The number of code points to encode.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string utf8_string The UTF-8 string.
local function pack( utf8_codepoints, utf8_codepoint_count, lax )
	if utf8_codepoint_count == nil then
		utf8_codepoint_count = #utf8_codepoints
	end

	if utf8_codepoint_count == 0 then
		return ""
	end

	---@type string[]
	local utf8_sequences = {}
	lax = lax ~= true

	for i = 1, utf8_codepoint_count, 1 do
		utf8_sequences[ i ] = encode( utf8_codepoints[ i ], lax, 2 )
	end

	return table_concat( utf8_sequences, "", 1, utf8_codepoint_count )
end

utf8.pack = pack

--- [SHARED AND MENU]
---
--- Encodes a sequence of code points into a UTF-8 string.
---
--- This functions similarly to `string.char`
---
---@param ... dreamwork.std.encoding.utf8.Codepoint The code points to encode.
---@return string utf8_string The UTF-8 string.
function utf8.char( a, b, ... )
	if b == nil then
		return encode( a, true, 2 )
	else
		return pack( { a, b, ... }, select( "#", a, b, ... ), true )
	end
end

--- [SHARED AND MENU]
---
--- Returns the byte position of a code point in UTF-8 string.
---
---@param utf8_string string The UTF-8 string to search in.
---@param index integer The code point to search for in the UTF-8 units.
---@param offset? integer The position to start from in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return integer | nil index The position of the code point in bytes or `nil` if not found.
function utf8.offset( utf8_string, index, offset, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return nil
	end

	if offset == nil then
		offset = 1
	elseif offset < 0 then
		offset = math_relative( offset, str_length )
	else
		offset = math_min( offset, str_length )
	end

	if index < 0 then
		local sequence_length, error_position = len( utf8_string, offset, str_length, lax )

		if sequence_length == nil then
			std.errorf( 2, false, "invalid UTF-8 sequence byte '0x%02X' at position %d", string_byte( utf8_string, error_position, error_position ), error_position )
		end

		if ( 0 - index ) > sequence_length then
			index = 1
        else
			index = sequence_length + index + 1
        end
	end

	local utf8_codepoint_count = 1

	repeat
		if utf8_codepoint_count == index then
			return offset
		else
			offset = offset + seqlen( utf8_string, offset, str_length, false )
			utf8_codepoint_count = utf8_codepoint_count + 1
		end
	until offset >= str_length

	return nil
end

do

	local table_reversed = table.reversed

	--- [SHARED AND MENU]
	---
	--- Returns the reverse of a UTF-8 string.
	---
	--- This functions similarly to `string.reverse`
	---
	---@param utf8_string string The UTF-8 string to reverse.
	---@param start_position? integer The position to start from in bytes.
	---@param end_position? integer The position to end at in bytes.
	---@param lax? boolean Whether to lax the UTF-8 validity check.
	---@return string utf8_reversed The reversed UTF-8 string.
	function utf8.reverse( utf8_string, start_position, end_position, lax )
		local utf8_codepoints, utf8_codepoint_count = unpack( utf8_string, start_position, end_position, lax )
		return pack( table_reversed( utf8_codepoints, utf8_codepoint_count ), utf8_codepoint_count, lax )
	end

end

do

	local default_replacement_str = encode( 0xFFFD, false, 2 )

	--- [SHARED AND MENU]
	---
	--- Normalizes a UTF-8 string.
	---
	--- This function will remove all invalid UTF-8 code points.
	---
	---@param utf8_string string The UTF-8 string to normalize.
	---@param replacement_str? string The string to replace invalid UTF-8 code points with, by default `0xFFFD`.
	---@param start_position? integer The position to start from in bytes.
	---@param end_position? integer The position to end at in bytes.
	---@return string utf8_normalized The normalized UTF-8 string.
	function utf8.normalize( utf8_string, replacement_str, start_position, end_position )
		---@type integer
		local str_length = string_len( utf8_string )

		if str_length == 0 then
			return utf8_string
		end

		if start_position == nil then
			start_position = 1
		elseif start_position < 0 then
			start_position = math_relative( start_position, str_length )
		else
			start_position = math_min( start_position, str_length )
		end

		if end_position == nil then
			end_position = str_length
		elseif end_position < 0 then
			end_position = math_relative( end_position, str_length )
		else
			end_position = math_min( end_position, str_length )
		end

		if replacement_str == nil then
			replacement_str = default_replacement_str
		end

		---@type integer
		local utf8_sequence_count = 0

		---@type string[]
		local utf8_sequences = {}

		repeat
			local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_position, end_position, false, 2 )
			start_position = start_position + ( utf8_sequence_length or 1 )

			utf8_sequence_count = utf8_sequence_count + 1

			if utf8_codepoint == nil or utf8_sequence_length == nil then
				utf8_sequences[ utf8_sequence_count ] = replacement_str
			else
				utf8_sequences[ utf8_sequence_count ] = encode( utf8_codepoint, false, 2 )
			end
		until start_position > end_position

		return table_concat( utf8_sequences, "", 1, utf8_sequence_count )
	end

end

---@type table<dreamwork.std.encoding.utf8.Codepoint, string>
local lower2upper = {
	[ 0x61 ] = "A",
	[ 0x62 ] = "B",
	[ 0x63 ] = "C",
	[ 0x64 ] = "D",
	[ 0x65 ] = "E",
	[ 0x66 ] = "F",
	[ 0x67 ] = "G",
	[ 0x68 ] = "H",
	[ 0x69 ] = "I",
	[ 0x6A ] = "J",
	[ 0x6B ] = "K",
	[ 0x6C ] = "L",
	[ 0x6D ] = "M",
	[ 0x6E ] = "N",
	[ 0x6F ] = "O",
	[ 0x70 ] = "P",
	[ 0x71 ] = "Q",
	[ 0x72 ] = "R",
	[ 0x73 ] = "S",
	[ 0x74 ] = "T",
	[ 0x75 ] = "U",
	[ 0x76 ] = "V",
	[ 0x77 ] = "W",
	[ 0x78 ] = "X",
	[ 0x79 ] = "Y",
	[ 0x7A ] = "Z",
	[ 0xB5 ] = "Μ",
	[ 0xE0 ] = "À",
	[ 0xE1 ] = "Á",
	[ 0xE2 ] = "Â",
	[ 0xE3 ] = "Ã",
	[ 0xE4 ] = "Ä",
	[ 0xE5 ] = "Å",
	[ 0xE6 ] = "Æ",
	[ 0xE7 ] = "Ç",
	[ 0xE8 ] = "È",
	[ 0xE9 ] = "É",
	[ 0xEA ] = "Ê",
	[ 0xEB ] = "Ë",
	[ 0xEC ] = "Ì",
	[ 0xED ] = "Í",
	[ 0xEE ] = "Î",
	[ 0xEF ] = "Ï",
	[ 0xF0 ] = "Ð",
	[ 0xF1 ] = "Ñ",
	[ 0xF2 ] = "Ò",
	[ 0xF3 ] = "Ó",
	[ 0xF4 ] = "Ô",
	[ 0xF5 ] = "Õ",
	[ 0xF6 ] = "Ö",
	[ 0xF8 ] = "Ø",
	[ 0xF9 ] = "Ù",
	[ 0xFA ] = "Ú",
	[ 0xFB ] = "Û",
	[ 0xFC ] = "Ü",
	[ 0xFD ] = "Ý",
	[ 0xFE ] = "Þ",
	[ 0xFF ] = "Ÿ",
	[ 0x101 ] = "Ā",
	[ 0x103 ] = "Ă",
	[ 0x105 ] = "Ą",
	[ 0x107 ] = "Ć",
	[ 0x109 ] = "Ĉ",
	[ 0x10B ] = "Ċ",
	[ 0x10D ] = "Č",
	[ 0x10F ] = "Ď",
	[ 0x111 ] = "Đ",
	[ 0x113 ] = "Ē",
	[ 0x115 ] = "Ĕ",
	[ 0x117 ] = "Ė",
	[ 0x119 ] = "Ę",
	[ 0x11B ] = "Ě",
	[ 0x11D ] = "Ĝ",
	[ 0x11F ] = "Ğ",
	[ 0x121 ] = "Ġ",
	[ 0x123 ] = "Ģ",
	[ 0x125 ] = "Ĥ",
	[ 0x127 ] = "Ħ",
	[ 0x129 ] = "Ĩ",
	[ 0x12B ] = "Ī",
	[ 0x12D ] = "Ĭ",
	[ 0x12F ] = "Į",
	[ 0x131 ] = "I",
	[ 0x133 ] = "Ĳ",
	[ 0x135 ] = "Ĵ",
	[ 0x137 ] = "Ķ",
	[ 0x13A ] = "Ĺ",
	[ 0x13C ] = "Ļ",
	[ 0x13E ] = "Ľ",
	[ 0x140 ] = "Ŀ",
	[ 0x142 ] = "Ł",
	[ 0x144 ] = "Ń",
	[ 0x146 ] = "Ņ",
	[ 0x148 ] = "Ň",
	[ 0x14B ] = "Ŋ",
	[ 0x14D ] = "Ō",
	[ 0x14F ] = "Ŏ",
	[ 0x151 ] = "Ő",
	[ 0x153 ] = "Œ",
	[ 0x155 ] = "Ŕ",
	[ 0x157 ] = "Ŗ",
	[ 0x159 ] = "Ř",
	[ 0x15B ] = "Ś",
	[ 0x15D ] = "Ŝ",
	[ 0x15F ] = "Ş",
	[ 0x161 ] = "Š",
	[ 0x163 ] = "Ţ",
	[ 0x165 ] = "Ť",
	[ 0x167 ] = "Ŧ",
	[ 0x169 ] = "Ũ",
	[ 0x16B ] = "Ū",
	[ 0x16D ] = "Ŭ",
	[ 0x16F ] = "Ů",
	[ 0x171 ] = "Ű",
	[ 0x173 ] = "Ų",
	[ 0x175 ] = "Ŵ",
	[ 0x177 ] = "Ŷ",
	[ 0x17A ] = "Ź",
	[ 0x17C ] = "Ż",
	[ 0x17E ] = "Ž",
	[ 0x17F ] = "S",
	[ 0x180 ] = "Ƀ",
	[ 0x183 ] = "Ƃ",
	[ 0x185 ] = "Ƅ",
	[ 0x188 ] = "Ƈ",
	[ 0x18C ] = "Ƌ",
	[ 0x192 ] = "Ƒ",
	[ 0x195 ] = "Ƕ",
	[ 0x199 ] = "Ƙ",
	[ 0x19A ] = "Ƚ",
	[ 0x19E ] = "Ƞ",
	[ 0x1A1 ] = "Ơ",
	[ 0x1A3 ] = "Ƣ",
	[ 0x1A5 ] = "Ƥ",
	[ 0x1A8 ] = "Ƨ",
	[ 0x1AD ] = "Ƭ",
	[ 0x1B0 ] = "Ư",
	[ 0x1B4 ] = "Ƴ",
	[ 0x1B6 ] = "Ƶ",
	[ 0x1B9 ] = "Ƹ",
	[ 0x1BD ] = "Ƽ",
	[ 0x1BF ] = "Ƿ",
	[ 0x1C5 ] = "Ǆ",
	[ 0x1C6 ] = "Ǆ",
	[ 0x1C8 ] = "Ǉ",
	[ 0x1C9 ] = "Ǉ",
	[ 0x1CB ] = "Ǌ",
	[ 0x1CC ] = "Ǌ",
	[ 0x1CE ] = "Ǎ",
	[ 0x1D0 ] = "Ǐ",
	[ 0x1D2 ] = "Ǒ",
	[ 0x1D4 ] = "Ǔ",
	[ 0x1D6 ] = "Ǖ",
	[ 0x1D8 ] = "Ǘ",
	[ 0x1DA ] = "Ǚ",
	[ 0x1DC ] = "Ǜ",
	[ 0x1DD ] = "Ǝ",
	[ 0x1DF ] = "Ǟ",
	[ 0x1E1 ] = "Ǡ",
	[ 0x1E3 ] = "Ǣ",
	[ 0x1E5 ] = "Ǥ",
	[ 0x1E7 ] = "Ǧ",
	[ 0x1E9 ] = "Ǩ",
	[ 0x1EB ] = "Ǫ",
	[ 0x1ED ] = "Ǭ",
	[ 0x1EF ] = "Ǯ",
	[ 0x1F2 ] = "Ǳ",
	[ 0x1F3 ] = "Ǳ",
	[ 0x1F5 ] = "Ǵ",
	[ 0x1F9 ] = "Ǹ",
	[ 0x1FB ] = "Ǻ",
	[ 0x1FD ] = "Ǽ",
	[ 0x1FF ] = "Ǿ",
	[ 0x201 ] = "Ȁ",
	[ 0x203 ] = "Ȃ",
	[ 0x205 ] = "Ȅ",
	[ 0x207 ] = "Ȇ",
	[ 0x209 ] = "Ȉ",
	[ 0x20B ] = "Ȋ",
	[ 0x20D ] = "Ȍ",
	[ 0x20F ] = "Ȏ",
	[ 0x211 ] = "Ȑ",
	[ 0x213 ] = "Ȓ",
	[ 0x215 ] = "Ȕ",
	[ 0x217 ] = "Ȗ",
	[ 0x219 ] = "Ș",
	[ 0x21B ] = "Ț",
	[ 0x21D ] = "Ȝ",
	[ 0x21F ] = "Ȟ",
	[ 0x223 ] = "Ȣ",
	[ 0x225 ] = "Ȥ",
	[ 0x227 ] = "Ȧ",
	[ 0x229 ] = "Ȩ",
	[ 0x22B ] = "Ȫ",
	[ 0x22D ] = "Ȭ",
	[ 0x22F ] = "Ȯ",
	[ 0x231 ] = "Ȱ",
	[ 0x233 ] = "Ȳ",
	[ 0x23C ] = "Ȼ",
	[ 0x242 ] = "Ɂ",
	[ 0x247 ] = "Ɇ",
	[ 0x249 ] = "Ɉ",
	[ 0x24B ] = "Ɋ",
	[ 0x24D ] = "Ɍ",
	[ 0x24F ] = "Ɏ",
	[ 0x253 ] = "Ɓ",
	[ 0x254 ] = "Ɔ",
	[ 0x256 ] = "Ɖ",
	[ 0x257 ] = "Ɗ",
	[ 0x259 ] = "Ə",
	[ 0x25B ] = "Ɛ",
	[ 0x260 ] = "Ɠ",
	[ 0x263 ] = "Ɣ",
	[ 0x268 ] = "Ɨ",
	[ 0x269 ] = "Ɩ",
	[ 0x26B ] = "Ɫ",
	[ 0x26F ] = "Ɯ",
	[ 0x272 ] = "Ɲ",
	[ 0x275 ] = "Ɵ",
	[ 0x27D ] = "Ɽ",
	[ 0x280 ] = "Ʀ",
	[ 0x283 ] = "Ʃ",
	[ 0x288 ] = "Ʈ",
	[ 0x289 ] = "Ʉ",
	[ 0x28A ] = "Ʊ",
	[ 0x28B ] = "Ʋ",
	[ 0x28C ] = "Ʌ",
	[ 0x292 ] = "Ʒ",
	[ 0x345 ] = "Ι",
	[ 0x37B ] = "Ͻ",
	[ 0x37C ] = "Ͼ",
	[ 0x37D ] = "Ͽ",
	[ 0x3AC ] = "Ά",
	[ 0x3AD ] = "Έ",
	[ 0x3AE ] = "Ή",
	[ 0x3AF ] = "Ί",
	[ 0x3B1 ] = "Α",
	[ 0x3B2 ] = "Β",
	[ 0x3B3 ] = "Γ",
	[ 0x3B4 ] = "Δ",
	[ 0x3B5 ] = "Ε",
	[ 0x3B6 ] = "Ζ",
	[ 0x3B7 ] = "Η",
	[ 0x3B8 ] = "Θ",
	[ 0x3B9 ] = "Ι",
	[ 0x3BA ] = "Κ",
	[ 0x3BB ] = "Λ",
	[ 0x3BC ] = "Μ",
	[ 0x3BD ] = "Ν",
	[ 0x3BE ] = "Ξ",
	[ 0x3BF ] = "Ο",
	[ 0x3C0 ] = "Π",
	[ 0x3C1 ] = "Ρ",
	[ 0x3C2 ] = "Σ",
	[ 0x3C3 ] = "Σ",
	[ 0x3C4 ] = "Τ",
	[ 0x3C5 ] = "Υ",
	[ 0x3C6 ] = "Φ",
	[ 0x3C7 ] = "Χ",
	[ 0x3C8 ] = "Ψ",
	[ 0x3C9 ] = "Ω",
	[ 0x3CA ] = "Ϊ",
	[ 0x3CB ] = "Ϋ",
	[ 0x3CC ] = "Ό",
	[ 0x3CD ] = "Ύ",
	[ 0x3CE ] = "Ώ",
	[ 0x3D0 ] = "Β",
	[ 0x3D1 ] = "Θ",
	[ 0x3D5 ] = "Φ",
	[ 0x3D6 ] = "Π",
	[ 0x3D9 ] = "Ϙ",
	[ 0x3DB ] = "Ϛ",
	[ 0x3DD ] = "Ϝ",
	[ 0x3DF ] = "Ϟ",
	[ 0x3E1 ] = "Ϡ",
	[ 0x3E3 ] = "Ϣ",
	[ 0x3E5 ] = "Ϥ",
	[ 0x3E7 ] = "Ϧ",
	[ 0x3E9 ] = "Ϩ",
	[ 0x3EB ] = "Ϫ",
	[ 0x3ED ] = "Ϭ",
	[ 0x3EF ] = "Ϯ",
	[ 0x3F0 ] = "Κ",
	[ 0x3F1 ] = "Ρ",
	[ 0x3F2 ] = "Ϲ",
	[ 0x3F5 ] = "Ε",
	[ 0x3F8 ] = "Ϸ",
	[ 0x3FB ] = "Ϻ",
	[ 0x430 ] = "А",
	[ 0x431 ] = "Б",
	[ 0x432 ] = "В",
	[ 0x433 ] = "Г",
	[ 0x434 ] = "Д",
	[ 0x435 ] = "Е",
	[ 0x436 ] = "Ж",
	[ 0x437 ] = "З",
	[ 0x438 ] = "И",
	[ 0x439 ] = "Й",
	[ 0x43A ] = "К",
	[ 0x43B ] = "Л",
	[ 0x43C ] = "М",
	[ 0x43D ] = "Н",
	[ 0x43E ] = "О",
	[ 0x43F ] = "П",
	[ 0x440 ] = "Р",
	[ 0x441 ] = "С",
	[ 0x442 ] = "Т",
	[ 0x443 ] = "У",
	[ 0x444 ] = "Ф",
	[ 0x445 ] = "Х",
	[ 0x446 ] = "Ц",
	[ 0x447 ] = "Ч",
	[ 0x448 ] = "Ш",
	[ 0x449 ] = "Щ",
	[ 0x44A ] = "Ъ",
	[ 0x44B ] = "Ы",
	[ 0x44C ] = "Ь",
	[ 0x44D ] = "Э",
	[ 0x44E ] = "Ю",
	[ 0x44F ] = "Я",
	[ 0x450 ] = "Ѐ",
	[ 0x451 ] = "Ё",
	[ 0x452 ] = "Ђ",
	[ 0x453 ] = "Ѓ",
	[ 0x454 ] = "Є",
	[ 0x455 ] = "Ѕ",
	[ 0x456 ] = "І",
	[ 0x457 ] = "Ї",
	[ 0x458 ] = "Ј",
	[ 0x459 ] = "Љ",
	[ 0x45A ] = "Њ",
	[ 0x45B ] = "Ћ",
	[ 0x45C ] = "Ќ",
	[ 0x45D ] = "Ѝ",
	[ 0x45E ] = "Ў",
	[ 0x45F ] = "Џ",
	[ 0x461 ] = "Ѡ",
	[ 0x463 ] = "Ѣ",
	[ 0x465 ] = "Ѥ",
	[ 0x467 ] = "Ѧ",
	[ 0x469 ] = "Ѩ",
	[ 0x46B ] = "Ѫ",
	[ 0x46D ] = "Ѭ",
	[ 0x46F ] = "Ѯ",
	[ 0x471 ] = "Ѱ",
	[ 0x473 ] = "Ѳ",
	[ 0x475 ] = "Ѵ",
	[ 0x477 ] = "Ѷ",
	[ 0x479 ] = "Ѹ",
	[ 0x47B ] = "Ѻ",
	[ 0x47D ] = "Ѽ",
	[ 0x47F ] = "Ѿ",
	[ 0x481 ] = "Ҁ",
	[ 0x48B ] = "Ҋ",
	[ 0x48D ] = "Ҍ",
	[ 0x48F ] = "Ҏ",
	[ 0x491 ] = "Ґ",
	[ 0x493 ] = "Ғ",
	[ 0x495 ] = "Ҕ",
	[ 0x497 ] = "Җ",
	[ 0x499 ] = "Ҙ",
	[ 0x49B ] = "Қ",
	[ 0x49D ] = "Ҝ",
	[ 0x49F ] = "Ҟ",
	[ 0x4A1 ] = "Ҡ",
	[ 0x4A3 ] = "Ң",
	[ 0x4A5 ] = "Ҥ",
	[ 0x4A7 ] = "Ҧ",
	[ 0x4A9 ] = "Ҩ",
	[ 0x4AB ] = "Ҫ",
	[ 0x4AD ] = "Ҭ",
	[ 0x4AF ] = "Ү",
	[ 0x4B1 ] = "Ұ",
	[ 0x4B3 ] = "Ҳ",
	[ 0x4B5 ] = "Ҵ",
	[ 0x4B7 ] = "Ҷ",
	[ 0x4B9 ] = "Ҹ",
	[ 0x4BB ] = "Һ",
	[ 0x4BD ] = "Ҽ",
	[ 0x4BF ] = "Ҿ",
	[ 0x4C2 ] = "Ӂ",
	[ 0x4C4 ] = "Ӄ",
	[ 0x4C6 ] = "Ӆ",
	[ 0x4C8 ] = "Ӈ",
	[ 0x4CA ] = "Ӊ",
	[ 0x4CC ] = "Ӌ",
	[ 0x4CE ] = "Ӎ",
	[ 0x4CF ] = "Ӏ",
	[ 0x4D1 ] = "Ӑ",
	[ 0x4D3 ] = "Ӓ",
	[ 0x4D5 ] = "Ӕ",
	[ 0x4D7 ] = "Ӗ",
	[ 0x4D9 ] = "Ә",
	[ 0x4DB ] = "Ӛ",
	[ 0x4DD ] = "Ӝ",
	[ 0x4DF ] = "Ӟ",
	[ 0x4E1 ] = "Ӡ",
	[ 0x4E3 ] = "Ӣ",
	[ 0x4E5 ] = "Ӥ",
	[ 0x4E7 ] = "Ӧ",
	[ 0x4E9 ] = "Ө",
	[ 0x4EB ] = "Ӫ",
	[ 0x4ED ] = "Ӭ",
	[ 0x4EF ] = "Ӯ",
	[ 0x4F1 ] = "Ӱ",
	[ 0x4F3 ] = "Ӳ",
	[ 0x4F5 ] = "Ӵ",
	[ 0x4F7 ] = "Ӷ",
	[ 0x4F9 ] = "Ӹ",
	[ 0x4FB ] = "Ӻ",
	[ 0x4FD ] = "Ӽ",
	[ 0x4FF ] = "Ӿ",
	[ 0x501 ] = "Ԁ",
	[ 0x503 ] = "Ԃ",
	[ 0x505 ] = "Ԅ",
	[ 0x507 ] = "Ԇ",
	[ 0x509 ] = "Ԉ",
	[ 0x50B ] = "Ԋ",
	[ 0x50D ] = "Ԍ",
	[ 0x50F ] = "Ԏ",
	[ 0x511 ] = "Ԑ",
	[ 0x513 ] = "Ԓ",
	[ 0x561 ] = "Ա",
	[ 0x562 ] = "Բ",
	[ 0x563 ] = "Գ",
	[ 0x564 ] = "Դ",
	[ 0x565 ] = "Ե",
	[ 0x566 ] = "Զ",
	[ 0x567 ] = "Է",
	[ 0x568 ] = "Ը",
	[ 0x569 ] = "Թ",
	[ 0x56A ] = "Ժ",
	[ 0x56B ] = "Ի",
	[ 0x56C ] = "Լ",
	[ 0x56D ] = "Խ",
	[ 0x56E ] = "Ծ",
	[ 0x56F ] = "Կ",
	[ 0x570 ] = "Հ",
	[ 0x571 ] = "Ձ",
	[ 0x572 ] = "Ղ",
	[ 0x573 ] = "Ճ",
	[ 0x574 ] = "Մ",
	[ 0x575 ] = "Յ",
	[ 0x576 ] = "Ն",
	[ 0x577 ] = "Շ",
	[ 0x578 ] = "Ո",
	[ 0x579 ] = "Չ",
	[ 0x57A ] = "Պ",
	[ 0x57B ] = "Ջ",
	[ 0x57C ] = "Ռ",
	[ 0x57D ] = "Ս",
	[ 0x57E ] = "Վ",
	[ 0x57F ] = "Տ",
	[ 0x580 ] = "Ր",
	[ 0x581 ] = "Ց",
	[ 0x582 ] = "Ւ",
	[ 0x583 ] = "Փ",
	[ 0x584 ] = "Ք",
	[ 0x585 ] = "Օ",
	[ 0x586 ] = "Ֆ",
	[ 0x1D7D ] = "Ᵽ",
	[ 0x1E01 ] = "Ḁ",
	[ 0x1E03 ] = "Ḃ",
	[ 0x1E05 ] = "Ḅ",
	[ 0x1E07 ] = "Ḇ",
	[ 0x1E09 ] = "Ḉ",
	[ 0x1E0B ] = "Ḋ",
	[ 0x1E0D ] = "Ḍ",
	[ 0x1E0F ] = "Ḏ",
	[ 0x1E11 ] = "Ḑ",
	[ 0x1E13 ] = "Ḓ",
	[ 0x1E15 ] = "Ḕ",
	[ 0x1E17 ] = "Ḗ",
	[ 0x1E19 ] = "Ḙ",
	[ 0x1E1B ] = "Ḛ",
	[ 0x1E1D ] = "Ḝ",
	[ 0x1E1F ] = "Ḟ",
	[ 0x1E21 ] = "Ḡ",
	[ 0x1E23 ] = "Ḣ",
	[ 0x1E25 ] = "Ḥ",
	[ 0x1E27 ] = "Ḧ",
	[ 0x1E29 ] = "Ḩ",
	[ 0x1E2B ] = "Ḫ",
	[ 0x1E2D ] = "Ḭ",
	[ 0x1E2F ] = "Ḯ",
	[ 0x1E31 ] = "Ḱ",
	[ 0x1E33 ] = "Ḳ",
	[ 0x1E35 ] = "Ḵ",
	[ 0x1E37 ] = "Ḷ",
	[ 0x1E39 ] = "Ḹ",
	[ 0x1E3B ] = "Ḻ",
	[ 0x1E3D ] = "Ḽ",
	[ 0x1E3F ] = "Ḿ",
	[ 0x1E41 ] = "Ṁ",
	[ 0x1E43 ] = "Ṃ",
	[ 0x1E45 ] = "Ṅ",
	[ 0x1E47 ] = "Ṇ",
	[ 0x1E49 ] = "Ṉ",
	[ 0x1E4B ] = "Ṋ",
	[ 0x1E4D ] = "Ṍ",
	[ 0x1E4F ] = "Ṏ",
	[ 0x1E51 ] = "Ṑ",
	[ 0x1E53 ] = "Ṓ",
	[ 0x1E55 ] = "Ṕ",
	[ 0x1E57 ] = "Ṗ",
	[ 0x1E59 ] = "Ṙ",
	[ 0x1E5B ] = "Ṛ",
	[ 0x1E5D ] = "Ṝ",
	[ 0x1E5F ] = "Ṟ",
	[ 0x1E61 ] = "Ṡ",
	[ 0x1E63 ] = "Ṣ",
	[ 0x1E65 ] = "Ṥ",
	[ 0x1E67 ] = "Ṧ",
	[ 0x1E69 ] = "Ṩ",
	[ 0x1E6B ] = "Ṫ",
	[ 0x1E6D ] = "Ṭ",
	[ 0x1E6F ] = "Ṯ",
	[ 0x1E71 ] = "Ṱ",
	[ 0x1E73 ] = "Ṳ",
	[ 0x1E75 ] = "Ṵ",
	[ 0x1E77 ] = "Ṷ",
	[ 0x1E79 ] = "Ṹ",
	[ 0x1E7B ] = "Ṻ",
	[ 0x1E7D ] = "Ṽ",
	[ 0x1E7F ] = "Ṿ",
	[ 0x1E81 ] = "Ẁ",
	[ 0x1E83 ] = "Ẃ",
	[ 0x1E85 ] = "Ẅ",
	[ 0x1E87 ] = "Ẇ",
	[ 0x1E89 ] = "Ẉ",
	[ 0x1E8B ] = "Ẋ",
	[ 0x1E8D ] = "Ẍ",
	[ 0x1E8F ] = "Ẏ",
	[ 0x1E91 ] = "Ẑ",
	[ 0x1E93 ] = "Ẓ",
	[ 0x1E95 ] = "Ẕ",
	[ 0x1E9B ] = "Ṡ",
	[ 0x1EA1 ] = "Ạ",
	[ 0x1EA3 ] = "Ả",
	[ 0x1EA5 ] = "Ấ",
	[ 0x1EA7 ] = "Ầ",
	[ 0x1EA9 ] = "Ẩ",
	[ 0x1EAB ] = "Ẫ",
	[ 0x1EAD ] = "Ậ",
	[ 0x1EAF ] = "Ắ",
	[ 0x1EB1 ] = "Ằ",
	[ 0x1EB3 ] = "Ẳ",
	[ 0x1EB5 ] = "Ẵ",
	[ 0x1EB7 ] = "Ặ",
	[ 0x1EB9 ] = "Ẹ",
	[ 0x1EBB ] = "Ẻ",
	[ 0x1EBD ] = "Ẽ",
	[ 0x1EBF ] = "Ế",
	[ 0x1EC1 ] = "Ề",
	[ 0x1EC3 ] = "Ể",
	[ 0x1EC5 ] = "Ễ",
	[ 0x1EC7 ] = "Ệ",
	[ 0x1EC9 ] = "Ỉ",
	[ 0x1ECB ] = "Ị",
	[ 0x1ECD ] = "Ọ",
	[ 0x1ECF ] = "Ỏ",
	[ 0x1ED1 ] = "Ố",
	[ 0x1ED3 ] = "Ồ",
	[ 0x1ED5 ] = "Ổ",
	[ 0x1ED7 ] = "Ỗ",
	[ 0x1ED9 ] = "Ộ",
	[ 0x1EDB ] = "Ớ",
	[ 0x1EDD ] = "Ờ",
	[ 0x1EDF ] = "Ở",
	[ 0x1EE1 ] = "Ỡ",
	[ 0x1EE3 ] = "Ợ",
	[ 0x1EE5 ] = "Ụ",
	[ 0x1EE7 ] = "Ủ",
	[ 0x1EE9 ] = "Ứ",
	[ 0x1EEB ] = "Ừ",
	[ 0x1EED ] = "Ử",
	[ 0x1EEF ] = "Ữ",
	[ 0x1EF1 ] = "Ự",
	[ 0x1EF3 ] = "Ỳ",
	[ 0x1EF5 ] = "Ỵ",
	[ 0x1EF7 ] = "Ỷ",
	[ 0x1EF9 ] = "Ỹ",
	[ 0x1F00 ] = "Ἀ",
	[ 0x1F01 ] = "Ἁ",
	[ 0x1F02 ] = "Ἂ",
	[ 0x1F03 ] = "Ἃ",
	[ 0x1F04 ] = "Ἄ",
	[ 0x1F05 ] = "Ἅ",
	[ 0x1F06 ] = "Ἆ",
	[ 0x1F07 ] = "Ἇ",
	[ 0x1F10 ] = "Ἐ",
	[ 0x1F11 ] = "Ἑ",
	[ 0x1F12 ] = "Ἒ",
	[ 0x1F13 ] = "Ἓ",
	[ 0x1F14 ] = "Ἔ",
	[ 0x1F15 ] = "Ἕ",
	[ 0x1F20 ] = "Ἠ",
	[ 0x1F21 ] = "Ἡ",
	[ 0x1F22 ] = "Ἢ",
	[ 0x1F23 ] = "Ἣ",
	[ 0x1F24 ] = "Ἤ",
	[ 0x1F25 ] = "Ἥ",
	[ 0x1F26 ] = "Ἦ",
	[ 0x1F27 ] = "Ἧ",
	[ 0x1F30 ] = "Ἰ",
	[ 0x1F31 ] = "Ἱ",
	[ 0x1F32 ] = "Ἲ",
	[ 0x1F33 ] = "Ἳ",
	[ 0x1F34 ] = "Ἴ",
	[ 0x1F35 ] = "Ἵ",
	[ 0x1F36 ] = "Ἶ",
	[ 0x1F37 ] = "Ἷ",
	[ 0x1F40 ] = "Ὀ",
	[ 0x1F41 ] = "Ὁ",
	[ 0x1F42 ] = "Ὂ",
	[ 0x1F43 ] = "Ὃ",
	[ 0x1F44 ] = "Ὄ",
	[ 0x1F45 ] = "Ὅ",
	[ 0x1F51 ] = "Ὑ",
	[ 0x1F53 ] = "Ὓ",
	[ 0x1F55 ] = "Ὕ",
	[ 0x1F57 ] = "Ὗ",
	[ 0x1F60 ] = "Ὠ",
	[ 0x1F61 ] = "Ὡ",
	[ 0x1F62 ] = "Ὢ",
	[ 0x1F63 ] = "Ὣ",
	[ 0x1F64 ] = "Ὤ",
	[ 0x1F65 ] = "Ὥ",
	[ 0x1F66 ] = "Ὦ",
	[ 0x1F67 ] = "Ὧ",
	[ 0x1F70 ] = "Ὰ",
	[ 0x1F71 ] = "Ά",
	[ 0x1F72 ] = "Ὲ",
	[ 0x1F73 ] = "Έ",
	[ 0x1F74 ] = "Ὴ",
	[ 0x1F75 ] = "Ή",
	[ 0x1F76 ] = "Ὶ",
	[ 0x1F77 ] = "Ί",
	[ 0x1F78 ] = "Ὸ",
	[ 0x1F79 ] = "Ό",
	[ 0x1F7A ] = "Ὺ",
	[ 0x1F7B ] = "Ύ",
	[ 0x1F7C ] = "Ὼ",
	[ 0x1F7D ] = "Ώ",
	[ 0x1F80 ] = "ᾈ",
	[ 0x1F81 ] = "ᾉ",
	[ 0x1F82 ] = "ᾊ",
	[ 0x1F83 ] = "ᾋ",
	[ 0x1F84 ] = "ᾌ",
	[ 0x1F85 ] = "ᾍ",
	[ 0x1F86 ] = "ᾎ",
	[ 0x1F87 ] = "ᾏ",
	[ 0x1F90 ] = "ᾘ",
	[ 0x1F91 ] = "ᾙ",
	[ 0x1F92 ] = "ᾚ",
	[ 0x1F93 ] = "ᾛ",
	[ 0x1F94 ] = "ᾜ",
	[ 0x1F95 ] = "ᾝ",
	[ 0x1F96 ] = "ᾞ",
	[ 0x1F97 ] = "ᾟ",
	[ 0x1FA0 ] = "ᾨ",
	[ 0x1FA1 ] = "ᾩ",
	[ 0x1FA2 ] = "ᾪ",
	[ 0x1FA3 ] = "ᾫ",
	[ 0x1FA4 ] = "ᾬ",
	[ 0x1FA5 ] = "ᾭ",
	[ 0x1FA6 ] = "ᾮ",
	[ 0x1FA7 ] = "ᾯ",
	[ 0x1FB0 ] = "Ᾰ",
	[ 0x1FB1 ] = "Ᾱ",
	[ 0x1FB3 ] = "ᾼ",
	[ 0x1FBE ] = "Ι",
	[ 0x1FC3 ] = "ῌ",
	[ 0x1FD0 ] = "Ῐ",
	[ 0x1FD1 ] = "Ῑ",
	[ 0x1FE0 ] = "Ῠ",
	[ 0x1FE1 ] = "Ῡ",
	[ 0x1FE5 ] = "Ῥ",
	[ 0x1FF3 ] = "ῼ",
	[ 0x214E ] = "Ⅎ",
	[ 0x2170 ] = "Ⅰ",
	[ 0x2171 ] = "Ⅱ",
	[ 0x2172 ] = "Ⅲ",
	[ 0x2173 ] = "Ⅳ",
	[ 0x2174 ] = "Ⅴ",
	[ 0x2175 ] = "Ⅵ",
	[ 0x2176 ] = "Ⅶ",
	[ 0x2177 ] = "Ⅷ",
	[ 0x2178 ] = "Ⅸ",
	[ 0x2179 ] = "Ⅹ",
	[ 0x217A ] = "Ⅺ",
	[ 0x217B ] = "Ⅻ",
	[ 0x217C ] = "Ⅼ",
	[ 0x217D ] = "Ⅽ",
	[ 0x217E ] = "Ⅾ",
	[ 0x217F ] = "Ⅿ",
	[ 0x2184 ] = "Ↄ",
	[ 0x24D0 ] = "Ⓐ",
	[ 0x24D1 ] = "Ⓑ",
	[ 0x24D2 ] = "Ⓒ",
	[ 0x24D3 ] = "Ⓓ",
	[ 0x24D4 ] = "Ⓔ",
	[ 0x24D5 ] = "Ⓕ",
	[ 0x24D6 ] = "Ⓖ",
	[ 0x24D7 ] = "Ⓗ",
	[ 0x24D8 ] = "Ⓘ",
	[ 0x24D9 ] = "Ⓙ",
	[ 0x24DA ] = "Ⓚ",
	[ 0x24DB ] = "Ⓛ",
	[ 0x24DC ] = "Ⓜ",
	[ 0x24DD ] = "Ⓝ",
	[ 0x24DE ] = "Ⓞ",
	[ 0x24DF ] = "Ⓟ",
	[ 0x24E0 ] = "Ⓠ",
	[ 0x24E1 ] = "Ⓡ",
	[ 0x24E2 ] = "Ⓢ",
	[ 0x24E3 ] = "Ⓣ",
	[ 0x24E4 ] = "Ⓤ",
	[ 0x24E5 ] = "Ⓥ",
	[ 0x24E6 ] = "Ⓦ",
	[ 0x24E7 ] = "Ⓧ",
	[ 0x24E8 ] = "Ⓨ",
	[ 0x24E9 ] = "Ⓩ",
	[ 0x2C30 ] = "Ⰰ",
	[ 0x2C31 ] = "Ⰱ",
	[ 0x2C32 ] = "Ⰲ",
	[ 0x2C33 ] = "Ⰳ",
	[ 0x2C34 ] = "Ⰴ",
	[ 0x2C35 ] = "Ⰵ",
	[ 0x2C36 ] = "Ⰶ",
	[ 0x2C37 ] = "Ⰷ",
	[ 0x2C38 ] = "Ⰸ",
	[ 0x2C39 ] = "Ⰹ",
	[ 0x2C3A ] = "Ⰺ",
	[ 0x2C3B ] = "Ⰻ",
	[ 0x2C3C ] = "Ⰼ",
	[ 0x2C3D ] = "Ⰽ",
	[ 0x2C3E ] = "Ⰾ",
	[ 0x2C3F ] = "Ⰿ",
	[ 0x2C40 ] = "Ⱀ",
	[ 0x2C41 ] = "Ⱁ",
	[ 0x2C42 ] = "Ⱂ",
	[ 0x2C43 ] = "Ⱃ",
	[ 0x2C44 ] = "Ⱄ",
	[ 0x2C45 ] = "Ⱅ",
	[ 0x2C46 ] = "Ⱆ",
	[ 0x2C47 ] = "Ⱇ",
	[ 0x2C48 ] = "Ⱈ",
	[ 0x2C49 ] = "Ⱉ",
	[ 0x2C4A ] = "Ⱊ",
	[ 0x2C4B ] = "Ⱋ",
	[ 0x2C4C ] = "Ⱌ",
	[ 0x2C4D ] = "Ⱍ",
	[ 0x2C4E ] = "Ⱎ",
	[ 0x2C4F ] = "Ⱏ",
	[ 0x2C50 ] = "Ⱐ",
	[ 0x2C51 ] = "Ⱑ",
	[ 0x2C52 ] = "Ⱒ",
	[ 0x2C53 ] = "Ⱓ",
	[ 0x2C54 ] = "Ⱔ",
	[ 0x2C55 ] = "Ⱕ",
	[ 0x2C56 ] = "Ⱖ",
	[ 0x2C57 ] = "Ⱗ",
	[ 0x2C58 ] = "Ⱘ",
	[ 0x2C59 ] = "Ⱙ",
	[ 0x2C5A ] = "Ⱚ",
	[ 0x2C5B ] = "Ⱛ",
	[ 0x2C5C ] = "Ⱜ",
	[ 0x2C5D ] = "Ⱝ",
	[ 0x2C5E ] = "Ⱞ",
	[ 0x2C61 ] = "Ⱡ",
	[ 0x2C65 ] = "Ⱥ",
	[ 0x2C66 ] = "Ⱦ",
	[ 0x2C68 ] = "Ⱨ",
	[ 0x2C6A ] = "Ⱪ",
	[ 0x2C6C ] = "Ⱬ",
	[ 0x2C76 ] = "Ⱶ",
	[ 0x2C81 ] = "Ⲁ",
	[ 0x2C83 ] = "Ⲃ",
	[ 0x2C85 ] = "Ⲅ",
	[ 0x2C87 ] = "Ⲇ",
	[ 0x2C89 ] = "Ⲉ",
	[ 0x2C8B ] = "Ⲋ",
	[ 0x2C8D ] = "Ⲍ",
	[ 0x2C8F ] = "Ⲏ",
	[ 0x2C91 ] = "Ⲑ",
	[ 0x2C93 ] = "Ⲓ",
	[ 0x2C95 ] = "Ⲕ",
	[ 0x2C97 ] = "Ⲗ",
	[ 0x2C99 ] = "Ⲙ",
	[ 0x2C9B ] = "Ⲛ",
	[ 0x2C9D ] = "Ⲝ",
	[ 0x2C9F ] = "Ⲟ",
	[ 0x2CA1 ] = "Ⲡ",
	[ 0x2CA3 ] = "Ⲣ",
	[ 0x2CA5 ] = "Ⲥ",
	[ 0x2CA7 ] = "Ⲧ",
	[ 0x2CA9 ] = "Ⲩ",
	[ 0x2CAB ] = "Ⲫ",
	[ 0x2CAD ] = "Ⲭ",
	[ 0x2CAF ] = "Ⲯ",
	[ 0x2CB1 ] = "Ⲱ",
	[ 0x2CB3 ] = "Ⲳ",
	[ 0x2CB5 ] = "Ⲵ",
	[ 0x2CB7 ] = "Ⲷ",
	[ 0x2CB9 ] = "Ⲹ",
	[ 0x2CBB ] = "Ⲻ",
	[ 0x2CBD ] = "Ⲽ",
	[ 0x2CBF ] = "Ⲿ",
	[ 0x2CC1 ] = "Ⳁ",
	[ 0x2CC3 ] = "Ⳃ",
	[ 0x2CC5 ] = "Ⳅ",
	[ 0x2CC7 ] = "Ⳇ",
	[ 0x2CC9 ] = "Ⳉ",
	[ 0x2CCB ] = "Ⳋ",
	[ 0x2CCD ] = "Ⳍ",
	[ 0x2CCF ] = "Ⳏ",
	[ 0x2CD1 ] = "Ⳑ",
	[ 0x2CD3 ] = "Ⳓ",
	[ 0x2CD5 ] = "Ⳕ",
	[ 0x2CD7 ] = "Ⳗ",
	[ 0x2CD9 ] = "Ⳙ",
	[ 0x2CDB ] = "Ⳛ",
	[ 0x2CDD ] = "Ⳝ",
	[ 0x2CDF ] = "Ⳟ",
	[ 0x2CE1 ] = "Ⳡ",
	[ 0x2CE3 ] = "Ⳣ",
	[ 0x2D00 ] = "Ⴀ",
	[ 0x2D01 ] = "Ⴁ",
	[ 0x2D02 ] = "Ⴂ",
	[ 0x2D03 ] = "Ⴃ",
	[ 0x2D04 ] = "Ⴄ",
	[ 0x2D05 ] = "Ⴅ",
	[ 0x2D06 ] = "Ⴆ",
	[ 0x2D07 ] = "Ⴇ",
	[ 0x2D08 ] = "Ⴈ",
	[ 0x2D09 ] = "Ⴉ",
	[ 0x2D0A ] = "Ⴊ",
	[ 0x2D0B ] = "Ⴋ",
	[ 0x2D0C ] = "Ⴌ",
	[ 0x2D0D ] = "Ⴍ",
	[ 0x2D0E ] = "Ⴎ",
	[ 0x2D0F ] = "Ⴏ",
	[ 0x2D10 ] = "Ⴐ",
	[ 0x2D11 ] = "Ⴑ",
	[ 0x2D12 ] = "Ⴒ",
	[ 0x2D13 ] = "Ⴓ",
	[ 0x2D14 ] = "Ⴔ",
	[ 0x2D15 ] = "Ⴕ",
	[ 0x2D16 ] = "Ⴖ",
	[ 0x2D17 ] = "Ⴗ",
	[ 0x2D18 ] = "Ⴘ",
	[ 0x2D19 ] = "Ⴙ",
	[ 0x2D1A ] = "Ⴚ",
	[ 0x2D1B ] = "Ⴛ",
	[ 0x2D1C ] = "Ⴜ",
	[ 0x2D1D ] = "Ⴝ",
	[ 0x2D1E ] = "Ⴞ",
	[ 0x2D1F ] = "Ⴟ",
	[ 0x2D20 ] = "Ⴠ",
	[ 0x2D21 ] = "Ⴡ",
	[ 0x2D22 ] = "Ⴢ",
	[ 0x2D23 ] = "Ⴣ",
	[ 0x2D24 ] = "Ⴤ",
	[ 0x2D25 ] = "Ⴥ",
	[ 0xFF41 ] = "Ａ",
	[ 0xFF42 ] = "Ｂ",
	[ 0xFF43 ] = "Ｃ",
	[ 0xFF44 ] = "Ｄ",
	[ 0xFF45 ] = "Ｅ",
	[ 0xFF46 ] = "Ｆ",
	[ 0xFF47 ] = "Ｇ",
	[ 0xFF48 ] = "Ｈ",
	[ 0xFF49 ] = "Ｉ",
	[ 0xFF4A ] = "Ｊ",
	[ 0xFF4B ] = "Ｋ",
	[ 0xFF4C ] = "Ｌ",
	[ 0xFF4D ] = "Ｍ",
	[ 0xFF4E ] = "Ｎ",
	[ 0xFF4F ] = "Ｏ",
	[ 0xFF50 ] = "Ｐ",
	[ 0xFF51 ] = "Ｑ",
	[ 0xFF52 ] = "Ｒ",
	[ 0xFF53 ] = "Ｓ",
	[ 0xFF54 ] = "Ｔ",
	[ 0xFF55 ] = "Ｕ",
	[ 0xFF56 ] = "Ｖ",
	[ 0xFF57 ] = "Ｗ",
	[ 0xFF58 ] = "Ｘ",
	[ 0xFF59 ] = "Ｙ",
	[ 0xFF5A ] = "Ｚ",
	[ 0x10428 ] = "𐐀",
	[ 0x10429 ] = "𐐁",
	[ 0x1042A ] = "𐐂",
	[ 0x1042B ] = "𐐃",
	[ 0x1042C ] = "𐐄",
	[ 0x1042D ] = "𐐅",
	[ 0x1042E ] = "𐐆",
	[ 0x1042F ] = "𐐇",
	[ 0x10430 ] = "𐐈",
	[ 0x10431 ] = "𐐉",
	[ 0x10432 ] = "𐐊",
	[ 0x10433 ] = "𐐋",
	[ 0x10434 ] = "𐐌",
	[ 0x10435 ] = "𐐍",
	[ 0x10436 ] = "𐐎",
	[ 0x10437 ] = "𐐏",
	[ 0x10438 ] = "𐐐",
	[ 0x10439 ] = "𐐑",
	[ 0x1043A ] = "𐐒",
	[ 0x1043B ] = "𐐓",
	[ 0x1043C ] = "𐐔",
	[ 0x1043D ] = "𐐕",
	[ 0x1043E ] = "𐐖",
	[ 0x1043F ] = "𐐗",
	[ 0x10440 ] = "𐐘",
	[ 0x10441 ] = "𐐙",
	[ 0x10442 ] = "𐐚",
	[ 0x10443 ] = "𐐛",
	[ 0x10444 ] = "𐐜",
	[ 0x10445 ] = "𐐝",
	[ 0x10446 ] = "𐐞",
	[ 0x10447 ] = "𐐟",
	[ 0x10448 ] = "𐐠",
	[ 0x10449 ] = "𐐡",
	[ 0x1044A ] = "𐐢",
	[ 0x1044B ] = "𐐣",
	[ 0x1044C ] = "𐐤",
	[ 0x1044D ] = "𐐥",
	[ 0x1044E ] = "𐐦",
	[ 0x1044F ] = "𐐧"
}

---@type table<dreamwork.std.encoding.utf8.Codepoint, string>
local upper2lower = {
	[ 0x41 ] = "a",
	[ 0x42 ] = "b",
	[ 0x43 ] = "c",
	[ 0x44 ] = "d",
	[ 0x45 ] = "e",
	[ 0x46 ] = "f",
	[ 0x47 ] = "g",
	[ 0x48 ] = "h",
	[ 0x49 ] = "i",
	[ 0x4A ] = "j",
	[ 0x4B ] = "k",
	[ 0x4C ] = "l",
	[ 0x4D ] = "m",
	[ 0x4E ] = "n",
	[ 0x4F ] = "o",
	[ 0x50 ] = "p",
	[ 0x51 ] = "q",
	[ 0x52 ] = "r",
	[ 0x53 ] = "s",
	[ 0x54 ] = "t",
	[ 0x55 ] = "u",
	[ 0x56 ] = "v",
	[ 0x57 ] = "w",
	[ 0x58 ] = "x",
	[ 0x59 ] = "y",
	[ 0x5A ] = "z",
	[ 0xC0 ] = "à",
	[ 0xC1 ] = "á",
	[ 0xC2 ] = "â",
	[ 0xC3 ] = "ã",
	[ 0xC4 ] = "ä",
	[ 0xC5 ] = "å",
	[ 0xC6 ] = "æ",
	[ 0xC7 ] = "ç",
	[ 0xC8 ] = "è",
	[ 0xC9 ] = "é",
	[ 0xCA ] = "ê",
	[ 0xCB ] = "ë",
	[ 0xCC ] = "ì",
	[ 0xCD ] = "í",
	[ 0xCE ] = "î",
	[ 0xCF ] = "ï",
	[ 0xD0 ] = "ð",
	[ 0xD1 ] = "ñ",
	[ 0xD2 ] = "ò",
	[ 0xD3 ] = "ó",
	[ 0xD4 ] = "ô",
	[ 0xD5 ] = "õ",
	[ 0xD6 ] = "ö",
	[ 0xD8 ] = "ø",
	[ 0xD9 ] = "ù",
	[ 0xDA ] = "ú",
	[ 0xDB ] = "û",
	[ 0xDC ] = "ü",
	[ 0xDD ] = "ý",
	[ 0xDE ] = "þ",
	[ 0x100 ] = "ā",
	[ 0x102 ] = "ă",
	[ 0x104 ] = "ą",
	[ 0x106 ] = "ć",
	[ 0x108 ] = "ĉ",
	[ 0x10A ] = "ċ",
	[ 0x10C ] = "č",
	[ 0x10E ] = "ď",
	[ 0x110 ] = "đ",
	[ 0x112 ] = "ē",
	[ 0x114 ] = "ĕ",
	[ 0x116 ] = "ė",
	[ 0x118 ] = "ę",
	[ 0x11A ] = "ě",
	[ 0x11C ] = "ĝ",
	[ 0x11E ] = "ğ",
	[ 0x120 ] = "ġ",
	[ 0x122 ] = "ģ",
	[ 0x124 ] = "ĥ",
	[ 0x126 ] = "ħ",
	[ 0x128 ] = "ĩ",
	[ 0x12A ] = "ī",
	[ 0x12C ] = "ĭ",
	[ 0x12E ] = "į",
	[ 0x132 ] = "ĳ",
	[ 0x134 ] = "ĵ",
	[ 0x136 ] = "ķ",
	[ 0x139 ] = "ĺ",
	[ 0x13B ] = "ļ",
	[ 0x13D ] = "ľ",
	[ 0x13F ] = "ŀ",
	[ 0x141 ] = "ł",
	[ 0x143 ] = "ń",
	[ 0x145 ] = "ņ",
	[ 0x147 ] = "ň",
	[ 0x14A ] = "ŋ",
	[ 0x14C ] = "ō",
	[ 0x14E ] = "ŏ",
	[ 0x150 ] = "ő",
	[ 0x152 ] = "œ",
	[ 0x154 ] = "ŕ",
	[ 0x156 ] = "ŗ",
	[ 0x158 ] = "ř",
	[ 0x15A ] = "ś",
	[ 0x15C ] = "ŝ",
	[ 0x15E ] = "ş",
	[ 0x160 ] = "š",
	[ 0x162 ] = "ţ",
	[ 0x164 ] = "ť",
	[ 0x166 ] = "ŧ",
	[ 0x168 ] = "ũ",
	[ 0x16A ] = "ū",
	[ 0x16C ] = "ŭ",
	[ 0x16E ] = "ů",
	[ 0x170 ] = "ű",
	[ 0x172 ] = "ų",
	[ 0x174 ] = "ŵ",
	[ 0x176 ] = "ŷ",
	[ 0x178 ] = "ÿ",
	[ 0x179 ] = "ź",
	[ 0x17B ] = "ż",
	[ 0x17D ] = "ž",
	[ 0x181 ] = "ɓ",
	[ 0x182 ] = "ƃ",
	[ 0x184 ] = "ƅ",
	[ 0x186 ] = "ɔ",
	[ 0x187 ] = "ƈ",
	[ 0x189 ] = "ɖ",
	[ 0x18A ] = "ɗ",
	[ 0x18B ] = "ƌ",
	[ 0x18E ] = "ǝ",
	[ 0x18F ] = "ə",
	[ 0x190 ] = "ɛ",
	[ 0x191 ] = "ƒ",
	[ 0x193 ] = "ɠ",
	[ 0x194 ] = "ɣ",
	[ 0x196 ] = "ɩ",
	[ 0x197 ] = "ɨ",
	[ 0x198 ] = "ƙ",
	[ 0x19C ] = "ɯ",
	[ 0x19D ] = "ɲ",
	[ 0x19F ] = "ɵ",
	[ 0x1A0 ] = "ơ",
	[ 0x1A2 ] = "ƣ",
	[ 0x1A4 ] = "ƥ",
	[ 0x1A6 ] = "ʀ",
	[ 0x1A7 ] = "ƨ",
	[ 0x1A9 ] = "ʃ",
	[ 0x1AC ] = "ƭ",
	[ 0x1AE ] = "ʈ",
	[ 0x1AF ] = "ư",
	[ 0x1B1 ] = "ʊ",
	[ 0x1B2 ] = "ʋ",
	[ 0x1B3 ] = "ƴ",
	[ 0x1B5 ] = "ƶ",
	[ 0x1B7 ] = "ʒ",
	[ 0x1B8 ] = "ƹ",
	[ 0x1BC ] = "ƽ",
	[ 0x1C4 ] = "ǅ",
	[ 0x1C7 ] = "ǈ",
	[ 0x1CA ] = "ǌ",
	[ 0x1CD ] = "ǎ",
	[ 0x1CF ] = "ǐ",
	[ 0x1D1 ] = "ǒ",
	[ 0x1D3 ] = "ǔ",
	[ 0x1D5 ] = "ǖ",
	[ 0x1D7 ] = "ǘ",
	[ 0x1D9 ] = "ǚ",
	[ 0x1DB ] = "ǜ",
	[ 0x1DE ] = "ǟ",
	[ 0x1E0 ] = "ǡ",
	[ 0x1E2 ] = "ǣ",
	[ 0x1E4 ] = "ǥ",
	[ 0x1E6 ] = "ǧ",
	[ 0x1E8 ] = "ǩ",
	[ 0x1EA ] = "ǫ",
	[ 0x1EC ] = "ǭ",
	[ 0x1EE ] = "ǯ",
	[ 0x1F1 ] = "ǳ",
	[ 0x1F4 ] = "ǵ",
	[ 0x1F6 ] = "ƕ",
	[ 0x1F7 ] = "ƿ",
	[ 0x1F8 ] = "ǹ",
	[ 0x1FA ] = "ǻ",
	[ 0x1FC ] = "ǽ",
	[ 0x1FE ] = "ǿ",
	[ 0x200 ] = "ȁ",
	[ 0x202 ] = "ȃ",
	[ 0x204 ] = "ȅ",
	[ 0x206 ] = "ȇ",
	[ 0x208 ] = "ȉ",
	[ 0x20A ] = "ȋ",
	[ 0x20C ] = "ȍ",
	[ 0x20E ] = "ȏ",
	[ 0x210 ] = "ȑ",
	[ 0x212 ] = "ȓ",
	[ 0x214 ] = "ȕ",
	[ 0x216 ] = "ȗ",
	[ 0x218 ] = "ș",
	[ 0x21A ] = "ț",
	[ 0x21C ] = "ȝ",
	[ 0x21E ] = "ȟ",
	[ 0x220 ] = "ƞ",
	[ 0x222 ] = "ȣ",
	[ 0x224 ] = "ȥ",
	[ 0x226 ] = "ȧ",
	[ 0x228 ] = "ȩ",
	[ 0x22A ] = "ȫ",
	[ 0x22C ] = "ȭ",
	[ 0x22E ] = "ȯ",
	[ 0x230 ] = "ȱ",
	[ 0x232 ] = "ȳ",
	[ 0x23A ] = "ⱥ",
	[ 0x23B ] = "ȼ",
	[ 0x23D ] = "ƚ",
	[ 0x23E ] = "ⱦ",
	[ 0x241 ] = "ɂ",
	[ 0x243 ] = "ƀ",
	[ 0x244 ] = "ʉ",
	[ 0x245 ] = "ʌ",
	[ 0x246 ] = "ɇ",
	[ 0x248 ] = "ɉ",
	[ 0x24A ] = "ɋ",
	[ 0x24C ] = "ɍ",
	[ 0x24E ] = "ɏ",
	[ 0x386 ] = "ά",
	[ 0x388 ] = "έ",
	[ 0x389 ] = "ή",
	[ 0x38A ] = "ί",
	[ 0x38C ] = "ό",
	[ 0x38E ] = "ύ",
	[ 0x38F ] = "ώ",
	[ 0x391 ] = "α",
	[ 0x392 ] = "ϐ",
	[ 0x393 ] = "γ",
	[ 0x394 ] = "δ",
	[ 0x395 ] = "ε",
	[ 0x396 ] = "ζ",
	[ 0x397 ] = "η",
	[ 0x398 ] = "θ",
	[ 0x399 ] = "ͅ",
	[ 0x39A ] = "ϰ",
	[ 0x39B ] = "λ",
	[ 0x39C ] = "μ",
	[ 0x39D ] = "ν",
	[ 0x39E ] = "ξ",
	[ 0x39F ] = "ο",
	[ 0x3A0 ] = "π",
	[ 0x3A1 ] = "ϱ",
	[ 0x3A3 ] = "ς",
	[ 0x3A4 ] = "τ",
	[ 0x3A5 ] = "υ",
	[ 0x3A6 ] = "ϕ",
	[ 0x3A7 ] = "χ",
	[ 0x3A8 ] = "ψ",
	[ 0x3A9 ] = "ω",
	[ 0x3AA ] = "ϊ",
	[ 0x3AB ] = "ϋ",
	[ 0x3D8 ] = "ϙ",
	[ 0x3DA ] = "ϛ",
	[ 0x3DC ] = "ϝ",
	[ 0x3DE ] = "ϟ",
	[ 0x3E0 ] = "ϡ",
	[ 0x3E2 ] = "ϣ",
	[ 0x3E4 ] = "ϥ",
	[ 0x3E6 ] = "ϧ",
	[ 0x3E8 ] = "ϩ",
	[ 0x3EA ] = "ϫ",
	[ 0x3EC ] = "ϭ",
	[ 0x3EE ] = "ϯ",
	[ 0x3F7 ] = "ϸ",
	[ 0x3F9 ] = "ϲ",
	[ 0x3FA ] = "ϻ",
	[ 0x3FD ] = "ͻ",
	[ 0x3FE ] = "ͼ",
	[ 0x3FF ] = "ͽ",
	[ 0x400 ] = "ѐ",
	[ 0x401 ] = "ё",
	[ 0x402 ] = "ђ",
	[ 0x403 ] = "ѓ",
	[ 0x404 ] = "є",
	[ 0x405 ] = "ѕ",
	[ 0x406 ] = "і",
	[ 0x407 ] = "ї",
	[ 0x408 ] = "ј",
	[ 0x409 ] = "љ",
	[ 0x40A ] = "њ",
	[ 0x40B ] = "ћ",
	[ 0x40C ] = "ќ",
	[ 0x40D ] = "ѝ",
	[ 0x40E ] = "ў",
	[ 0x40F ] = "џ",
	[ 0x410 ] = "а",
	[ 0x411 ] = "б",
	[ 0x412 ] = "в",
	[ 0x413 ] = "г",
	[ 0x414 ] = "д",
	[ 0x415 ] = "е",
	[ 0x416 ] = "ж",
	[ 0x417 ] = "з",
	[ 0x418 ] = "и",
	[ 0x419 ] = "й",
	[ 0x41A ] = "к",
	[ 0x41B ] = "л",
	[ 0x41C ] = "м",
	[ 0x41D ] = "н",
	[ 0x41E ] = "о",
	[ 0x41F ] = "п",
	[ 0x420 ] = "р",
	[ 0x421 ] = "с",
	[ 0x422 ] = "т",
	[ 0x423 ] = "у",
	[ 0x424 ] = "ф",
	[ 0x425 ] = "х",
	[ 0x426 ] = "ц",
	[ 0x427 ] = "ч",
	[ 0x428 ] = "ш",
	[ 0x429 ] = "щ",
	[ 0x42A ] = "ъ",
	[ 0x42B ] = "ы",
	[ 0x42C ] = "ь",
	[ 0x42D ] = "э",
	[ 0x42E ] = "ю",
	[ 0x42F ] = "я",
	[ 0x460 ] = "ѡ",
	[ 0x462 ] = "ѣ",
	[ 0x464 ] = "ѥ",
	[ 0x466 ] = "ѧ",
	[ 0x468 ] = "ѩ",
	[ 0x46A ] = "ѫ",
	[ 0x46C ] = "ѭ",
	[ 0x46E ] = "ѯ",
	[ 0x470 ] = "ѱ",
	[ 0x472 ] = "ѳ",
	[ 0x474 ] = "ѵ",
	[ 0x476 ] = "ѷ",
	[ 0x478 ] = "ѹ",
	[ 0x47A ] = "ѻ",
	[ 0x47C ] = "ѽ",
	[ 0x47E ] = "ѿ",
	[ 0x480 ] = "ҁ",
	[ 0x48A ] = "ҋ",
	[ 0x48C ] = "ҍ",
	[ 0x48E ] = "ҏ",
	[ 0x490 ] = "ґ",
	[ 0x492 ] = "ғ",
	[ 0x494 ] = "ҕ",
	[ 0x496 ] = "җ",
	[ 0x498 ] = "ҙ",
	[ 0x49A ] = "қ",
	[ 0x49C ] = "ҝ",
	[ 0x49E ] = "ҟ",
	[ 0x4A0 ] = "ҡ",
	[ 0x4A2 ] = "ң",
	[ 0x4A4 ] = "ҥ",
	[ 0x4A6 ] = "ҧ",
	[ 0x4A8 ] = "ҩ",
	[ 0x4AA ] = "ҫ",
	[ 0x4AC ] = "ҭ",
	[ 0x4AE ] = "ү",
	[ 0x4B0 ] = "ұ",
	[ 0x4B2 ] = "ҳ",
	[ 0x4B4 ] = "ҵ",
	[ 0x4B6 ] = "ҷ",
	[ 0x4B8 ] = "ҹ",
	[ 0x4BA ] = "һ",
	[ 0x4BC ] = "ҽ",
	[ 0x4BE ] = "ҿ",
	[ 0x4C0 ] = "ӏ",
	[ 0x4C1 ] = "ӂ",
	[ 0x4C3 ] = "ӄ",
	[ 0x4C5 ] = "ӆ",
	[ 0x4C7 ] = "ӈ",
	[ 0x4C9 ] = "ӊ",
	[ 0x4CB ] = "ӌ",
	[ 0x4CD ] = "ӎ",
	[ 0x4D0 ] = "ӑ",
	[ 0x4D2 ] = "ӓ",
	[ 0x4D4 ] = "ӕ",
	[ 0x4D6 ] = "ӗ",
	[ 0x4D8 ] = "ә",
	[ 0x4DA ] = "ӛ",
	[ 0x4DC ] = "ӝ",
	[ 0x4DE ] = "ӟ",
	[ 0x4E0 ] = "ӡ",
	[ 0x4E2 ] = "ӣ",
	[ 0x4E4 ] = "ӥ",
	[ 0x4E6 ] = "ӧ",
	[ 0x4E8 ] = "ө",
	[ 0x4EA ] = "ӫ",
	[ 0x4EC ] = "ӭ",
	[ 0x4EE ] = "ӯ",
	[ 0x4F0 ] = "ӱ",
	[ 0x4F2 ] = "ӳ",
	[ 0x4F4 ] = "ӵ",
	[ 0x4F6 ] = "ӷ",
	[ 0x4F8 ] = "ӹ",
	[ 0x4FA ] = "ӻ",
	[ 0x4FC ] = "ӽ",
	[ 0x4FE ] = "ӿ",
	[ 0x500 ] = "ԁ",
	[ 0x502 ] = "ԃ",
	[ 0x504 ] = "ԅ",
	[ 0x506 ] = "ԇ",
	[ 0x508 ] = "ԉ",
	[ 0x50A ] = "ԋ",
	[ 0x50C ] = "ԍ",
	[ 0x50E ] = "ԏ",
	[ 0x510 ] = "ԑ",
	[ 0x512 ] = "ԓ",
	[ 0x531 ] = "ա",
	[ 0x532 ] = "բ",
	[ 0x533 ] = "գ",
	[ 0x534 ] = "դ",
	[ 0x535 ] = "ե",
	[ 0x536 ] = "զ",
	[ 0x537 ] = "է",
	[ 0x538 ] = "ը",
	[ 0x539 ] = "թ",
	[ 0x53A ] = "ժ",
	[ 0x53B ] = "ի",
	[ 0x53C ] = "լ",
	[ 0x53D ] = "խ",
	[ 0x53E ] = "ծ",
	[ 0x53F ] = "կ",
	[ 0x540 ] = "հ",
	[ 0x541 ] = "ձ",
	[ 0x542 ] = "ղ",
	[ 0x543 ] = "ճ",
	[ 0x544 ] = "մ",
	[ 0x545 ] = "յ",
	[ 0x546 ] = "ն",
	[ 0x547 ] = "շ",
	[ 0x548 ] = "ո",
	[ 0x549 ] = "չ",
	[ 0x54A ] = "պ",
	[ 0x54B ] = "ջ",
	[ 0x54C ] = "ռ",
	[ 0x54D ] = "ս",
	[ 0x54E ] = "վ",
	[ 0x54F ] = "տ",
	[ 0x550 ] = "ր",
	[ 0x551 ] = "ց",
	[ 0x552 ] = "ւ",
	[ 0x553 ] = "փ",
	[ 0x554 ] = "ք",
	[ 0x555 ] = "օ",
	[ 0x556 ] = "ֆ",
	[ 0x10A0 ] = "ⴀ",
	[ 0x10A1 ] = "ⴁ",
	[ 0x10A2 ] = "ⴂ",
	[ 0x10A3 ] = "ⴃ",
	[ 0x10A4 ] = "ⴄ",
	[ 0x10A5 ] = "ⴅ",
	[ 0x10A6 ] = "ⴆ",
	[ 0x10A7 ] = "ⴇ",
	[ 0x10A8 ] = "ⴈ",
	[ 0x10A9 ] = "ⴉ",
	[ 0x10AA ] = "ⴊ",
	[ 0x10AB ] = "ⴋ",
	[ 0x10AC ] = "ⴌ",
	[ 0x10AD ] = "ⴍ",
	[ 0x10AE ] = "ⴎ",
	[ 0x10AF ] = "ⴏ",
	[ 0x10B0 ] = "ⴐ",
	[ 0x10B1 ] = "ⴑ",
	[ 0x10B2 ] = "ⴒ",
	[ 0x10B3 ] = "ⴓ",
	[ 0x10B4 ] = "ⴔ",
	[ 0x10B5 ] = "ⴕ",
	[ 0x10B6 ] = "ⴖ",
	[ 0x10B7 ] = "ⴗ",
	[ 0x10B8 ] = "ⴘ",
	[ 0x10B9 ] = "ⴙ",
	[ 0x10BA ] = "ⴚ",
	[ 0x10BB ] = "ⴛ",
	[ 0x10BC ] = "ⴜ",
	[ 0x10BD ] = "ⴝ",
	[ 0x10BE ] = "ⴞ",
	[ 0x10BF ] = "ⴟ",
	[ 0x10C0 ] = "ⴠ",
	[ 0x10C1 ] = "ⴡ",
	[ 0x10C2 ] = "ⴢ",
	[ 0x10C3 ] = "ⴣ",
	[ 0x10C4 ] = "ⴤ",
	[ 0x10C5 ] = "ⴥ",
	[ 0x1E00 ] = "ḁ",
	[ 0x1E02 ] = "ḃ",
	[ 0x1E04 ] = "ḅ",
	[ 0x1E06 ] = "ḇ",
	[ 0x1E08 ] = "ḉ",
	[ 0x1E0A ] = "ḋ",
	[ 0x1E0C ] = "ḍ",
	[ 0x1E0E ] = "ḏ",
	[ 0x1E10 ] = "ḑ",
	[ 0x1E12 ] = "ḓ",
	[ 0x1E14 ] = "ḕ",
	[ 0x1E16 ] = "ḗ",
	[ 0x1E18 ] = "ḙ",
	[ 0x1E1A ] = "ḛ",
	[ 0x1E1C ] = "ḝ",
	[ 0x1E1E ] = "ḟ",
	[ 0x1E20 ] = "ḡ",
	[ 0x1E22 ] = "ḣ",
	[ 0x1E24 ] = "ḥ",
	[ 0x1E26 ] = "ḧ",
	[ 0x1E28 ] = "ḩ",
	[ 0x1E2A ] = "ḫ",
	[ 0x1E2C ] = "ḭ",
	[ 0x1E2E ] = "ḯ",
	[ 0x1E30 ] = "ḱ",
	[ 0x1E32 ] = "ḳ",
	[ 0x1E34 ] = "ḵ",
	[ 0x1E36 ] = "ḷ",
	[ 0x1E38 ] = "ḹ",
	[ 0x1E3A ] = "ḻ",
	[ 0x1E3C ] = "ḽ",
	[ 0x1E3E ] = "ḿ",
	[ 0x1E40 ] = "ṁ",
	[ 0x1E42 ] = "ṃ",
	[ 0x1E44 ] = "ṅ",
	[ 0x1E46 ] = "ṇ",
	[ 0x1E48 ] = "ṉ",
	[ 0x1E4A ] = "ṋ",
	[ 0x1E4C ] = "ṍ",
	[ 0x1E4E ] = "ṏ",
	[ 0x1E50 ] = "ṑ",
	[ 0x1E52 ] = "ṓ",
	[ 0x1E54 ] = "ṕ",
	[ 0x1E56 ] = "ṗ",
	[ 0x1E58 ] = "ṙ",
	[ 0x1E5A ] = "ṛ",
	[ 0x1E5C ] = "ṝ",
	[ 0x1E5E ] = "ṟ",
	[ 0x1E60 ] = "ẛ",
	[ 0x1E62 ] = "ṣ",
	[ 0x1E64 ] = "ṥ",
	[ 0x1E66 ] = "ṧ",
	[ 0x1E68 ] = "ṩ",
	[ 0x1E6A ] = "ṫ",
	[ 0x1E6C ] = "ṭ",
	[ 0x1E6E ] = "ṯ",
	[ 0x1E70 ] = "ṱ",
	[ 0x1E72 ] = "ṳ",
	[ 0x1E74 ] = "ṵ",
	[ 0x1E76 ] = "ṷ",
	[ 0x1E78 ] = "ṹ",
	[ 0x1E7A ] = "ṻ",
	[ 0x1E7C ] = "ṽ",
	[ 0x1E7E ] = "ṿ",
	[ 0x1E80 ] = "ẁ",
	[ 0x1E82 ] = "ẃ",
	[ 0x1E84 ] = "ẅ",
	[ 0x1E86 ] = "ẇ",
	[ 0x1E88 ] = "ẉ",
	[ 0x1E8A ] = "ẋ",
	[ 0x1E8C ] = "ẍ",
	[ 0x1E8E ] = "ẏ",
	[ 0x1E90 ] = "ẑ",
	[ 0x1E92 ] = "ẓ",
	[ 0x1E94 ] = "ẕ",
	[ 0x1EA0 ] = "ạ",
	[ 0x1EA2 ] = "ả",
	[ 0x1EA4 ] = "ấ",
	[ 0x1EA6 ] = "ầ",
	[ 0x1EA8 ] = "ẩ",
	[ 0x1EAA ] = "ẫ",
	[ 0x1EAC ] = "ậ",
	[ 0x1EAE ] = "ắ",
	[ 0x1EB0 ] = "ằ",
	[ 0x1EB2 ] = "ẳ",
	[ 0x1EB4 ] = "ẵ",
	[ 0x1EB6 ] = "ặ",
	[ 0x1EB8 ] = "ẹ",
	[ 0x1EBA ] = "ẻ",
	[ 0x1EBC ] = "ẽ",
	[ 0x1EBE ] = "ế",
	[ 0x1EC0 ] = "ề",
	[ 0x1EC2 ] = "ể",
	[ 0x1EC4 ] = "ễ",
	[ 0x1EC6 ] = "ệ",
	[ 0x1EC8 ] = "ỉ",
	[ 0x1ECA ] = "ị",
	[ 0x1ECC ] = "ọ",
	[ 0x1ECE ] = "ỏ",
	[ 0x1ED0 ] = "ố",
	[ 0x1ED2 ] = "ồ",
	[ 0x1ED4 ] = "ổ",
	[ 0x1ED6 ] = "ỗ",
	[ 0x1ED8 ] = "ộ",
	[ 0x1EDA ] = "ớ",
	[ 0x1EDC ] = "ờ",
	[ 0x1EDE ] = "ở",
	[ 0x1EE0 ] = "ỡ",
	[ 0x1EE2 ] = "ợ",
	[ 0x1EE4 ] = "ụ",
	[ 0x1EE6 ] = "ủ",
	[ 0x1EE8 ] = "ứ",
	[ 0x1EEA ] = "ừ",
	[ 0x1EEC ] = "ử",
	[ 0x1EEE ] = "ữ",
	[ 0x1EF0 ] = "ự",
	[ 0x1EF2 ] = "ỳ",
	[ 0x1EF4 ] = "ỵ",
	[ 0x1EF6 ] = "ỷ",
	[ 0x1EF8 ] = "ỹ",
	[ 0x1F08 ] = "ἀ",
	[ 0x1F09 ] = "ἁ",
	[ 0x1F0A ] = "ἂ",
	[ 0x1F0B ] = "ἃ",
	[ 0x1F0C ] = "ἄ",
	[ 0x1F0D ] = "ἅ",
	[ 0x1F0E ] = "ἆ",
	[ 0x1F0F ] = "ἇ",
	[ 0x1F18 ] = "ἐ",
	[ 0x1F19 ] = "ἑ",
	[ 0x1F1A ] = "ἒ",
	[ 0x1F1B ] = "ἓ",
	[ 0x1F1C ] = "ἔ",
	[ 0x1F1D ] = "ἕ",
	[ 0x1F28 ] = "ἠ",
	[ 0x1F29 ] = "ἡ",
	[ 0x1F2A ] = "ἢ",
	[ 0x1F2B ] = "ἣ",
	[ 0x1F2C ] = "ἤ",
	[ 0x1F2D ] = "ἥ",
	[ 0x1F2E ] = "ἦ",
	[ 0x1F2F ] = "ἧ",
	[ 0x1F38 ] = "ἰ",
	[ 0x1F39 ] = "ἱ",
	[ 0x1F3A ] = "ἲ",
	[ 0x1F3B ] = "ἳ",
	[ 0x1F3C ] = "ἴ",
	[ 0x1F3D ] = "ἵ",
	[ 0x1F3E ] = "ἶ",
	[ 0x1F3F ] = "ἷ",
	[ 0x1F48 ] = "ὀ",
	[ 0x1F49 ] = "ὁ",
	[ 0x1F4A ] = "ὂ",
	[ 0x1F4B ] = "ὃ",
	[ 0x1F4C ] = "ὄ",
	[ 0x1F4D ] = "ὅ",
	[ 0x1F59 ] = "ὑ",
	[ 0x1F5B ] = "ὓ",
	[ 0x1F5D ] = "ὕ",
	[ 0x1F5F ] = "ὗ",
	[ 0x1F68 ] = "ὠ",
	[ 0x1F69 ] = "ὡ",
	[ 0x1F6A ] = "ὢ",
	[ 0x1F6B ] = "ὣ",
	[ 0x1F6C ] = "ὤ",
	[ 0x1F6D ] = "ὥ",
	[ 0x1F6E ] = "ὦ",
	[ 0x1F6F ] = "ὧ",
	[ 0x1F88 ] = "ᾀ",
	[ 0x1F89 ] = "ᾁ",
	[ 0x1F8A ] = "ᾂ",
	[ 0x1F8B ] = "ᾃ",
	[ 0x1F8C ] = "ᾄ",
	[ 0x1F8D ] = "ᾅ",
	[ 0x1F8E ] = "ᾆ",
	[ 0x1F8F ] = "ᾇ",
	[ 0x1F98 ] = "ᾐ",
	[ 0x1F99 ] = "ᾑ",
	[ 0x1F9A ] = "ᾒ",
	[ 0x1F9B ] = "ᾓ",
	[ 0x1F9C ] = "ᾔ",
	[ 0x1F9D ] = "ᾕ",
	[ 0x1F9E ] = "ᾖ",
	[ 0x1F9F ] = "ᾗ",
	[ 0x1FA8 ] = "ᾠ",
	[ 0x1FA9 ] = "ᾡ",
	[ 0x1FAA ] = "ᾢ",
	[ 0x1FAB ] = "ᾣ",
	[ 0x1FAC ] = "ᾤ",
	[ 0x1FAD ] = "ᾥ",
	[ 0x1FAE ] = "ᾦ",
	[ 0x1FAF ] = "ᾧ",
	[ 0x1FB8 ] = "ᾰ",
	[ 0x1FB9 ] = "ᾱ",
	[ 0x1FBA ] = "ὰ",
	[ 0x1FBB ] = "ά",
	[ 0x1FBC ] = "ᾳ",
	[ 0x1FC8 ] = "ὲ",
	[ 0x1FC9 ] = "έ",
	[ 0x1FCA ] = "ὴ",
	[ 0x1FCB ] = "ή",
	[ 0x1FCC ] = "ῃ",
	[ 0x1FD8 ] = "ῐ",
	[ 0x1FD9 ] = "ῑ",
	[ 0x1FDA ] = "ὶ",
	[ 0x1FDB ] = "ί",
	[ 0x1FE8 ] = "ῠ",
	[ 0x1FE9 ] = "ῡ",
	[ 0x1FEA ] = "ὺ",
	[ 0x1FEB ] = "ύ",
	[ 0x1FEC ] = "ῥ",
	[ 0x1FF8 ] = "ὸ",
	[ 0x1FF9 ] = "ό",
	[ 0x1FFA ] = "ὼ",
	[ 0x1FFB ] = "ώ",
	[ 0x1FFC ] = "ῳ",
	[ 0x2132 ] = "ⅎ",
	[ 0x2160 ] = "ⅰ",
	[ 0x2161 ] = "ⅱ",
	[ 0x2162 ] = "ⅲ",
	[ 0x2163 ] = "ⅳ",
	[ 0x2164 ] = "ⅴ",
	[ 0x2165 ] = "ⅵ",
	[ 0x2166 ] = "ⅶ",
	[ 0x2167 ] = "ⅷ",
	[ 0x2168 ] = "ⅸ",
	[ 0x2169 ] = "ⅹ",
	[ 0x216A ] = "ⅺ",
	[ 0x216B ] = "ⅻ",
	[ 0x216C ] = "ⅼ",
	[ 0x216D ] = "ⅽ",
	[ 0x216E ] = "ⅾ",
	[ 0x216F ] = "ⅿ",
	[ 0x2183 ] = "ↄ",
	[ 0x24B6 ] = "ⓐ",
	[ 0x24B7 ] = "ⓑ",
	[ 0x24B8 ] = "ⓒ",
	[ 0x24B9 ] = "ⓓ",
	[ 0x24BA ] = "ⓔ",
	[ 0x24BB ] = "ⓕ",
	[ 0x24BC ] = "ⓖ",
	[ 0x24BD ] = "ⓗ",
	[ 0x24BE ] = "ⓘ",
	[ 0x24BF ] = "ⓙ",
	[ 0x24C0 ] = "ⓚ",
	[ 0x24C1 ] = "ⓛ",
	[ 0x24C2 ] = "ⓜ",
	[ 0x24C3 ] = "ⓝ",
	[ 0x24C4 ] = "ⓞ",
	[ 0x24C5 ] = "ⓟ",
	[ 0x24C6 ] = "ⓠ",
	[ 0x24C7 ] = "ⓡ",
	[ 0x24C8 ] = "ⓢ",
	[ 0x24C9 ] = "ⓣ",
	[ 0x24CA ] = "ⓤ",
	[ 0x24CB ] = "ⓥ",
	[ 0x24CC ] = "ⓦ",
	[ 0x24CD ] = "ⓧ",
	[ 0x24CE ] = "ⓨ",
	[ 0x24CF ] = "ⓩ",
	[ 0x2C00 ] = "ⰰ",
	[ 0x2C01 ] = "ⰱ",
	[ 0x2C02 ] = "ⰲ",
	[ 0x2C03 ] = "ⰳ",
	[ 0x2C04 ] = "ⰴ",
	[ 0x2C05 ] = "ⰵ",
	[ 0x2C06 ] = "ⰶ",
	[ 0x2C07 ] = "ⰷ",
	[ 0x2C08 ] = "ⰸ",
	[ 0x2C09 ] = "ⰹ",
	[ 0x2C0A ] = "ⰺ",
	[ 0x2C0B ] = "ⰻ",
	[ 0x2C0C ] = "ⰼ",
	[ 0x2C0D ] = "ⰽ",
	[ 0x2C0E ] = "ⰾ",
	[ 0x2C0F ] = "ⰿ",
	[ 0x2C10 ] = "ⱀ",
	[ 0x2C11 ] = "ⱁ",
	[ 0x2C12 ] = "ⱂ",
	[ 0x2C13 ] = "ⱃ",
	[ 0x2C14 ] = "ⱄ",
	[ 0x2C15 ] = "ⱅ",
	[ 0x2C16 ] = "ⱆ",
	[ 0x2C17 ] = "ⱇ",
	[ 0x2C18 ] = "ⱈ",
	[ 0x2C19 ] = "ⱉ",
	[ 0x2C1A ] = "ⱊ",
	[ 0x2C1B ] = "ⱋ",
	[ 0x2C1C ] = "ⱌ",
	[ 0x2C1D ] = "ⱍ",
	[ 0x2C1E ] = "ⱎ",
	[ 0x2C1F ] = "ⱏ",
	[ 0x2C20 ] = "ⱐ",
	[ 0x2C21 ] = "ⱑ",
	[ 0x2C22 ] = "ⱒ",
	[ 0x2C23 ] = "ⱓ",
	[ 0x2C24 ] = "ⱔ",
	[ 0x2C25 ] = "ⱕ",
	[ 0x2C26 ] = "ⱖ",
	[ 0x2C27 ] = "ⱗ",
	[ 0x2C28 ] = "ⱘ",
	[ 0x2C29 ] = "ⱙ",
	[ 0x2C2A ] = "ⱚ",
	[ 0x2C2B ] = "ⱛ",
	[ 0x2C2C ] = "ⱜ",
	[ 0x2C2D ] = "ⱝ",
	[ 0x2C2E ] = "ⱞ",
	[ 0x2C60 ] = "ⱡ",
	[ 0x2C62 ] = "ɫ",
	[ 0x2C63 ] = "ᵽ",
	[ 0x2C64 ] = "ɽ",
	[ 0x2C67 ] = "ⱨ",
	[ 0x2C69 ] = "ⱪ",
	[ 0x2C6B ] = "ⱬ",
	[ 0x2C75 ] = "ⱶ",
	[ 0x2C80 ] = "ⲁ",
	[ 0x2C82 ] = "ⲃ",
	[ 0x2C84 ] = "ⲅ",
	[ 0x2C86 ] = "ⲇ",
	[ 0x2C88 ] = "ⲉ",
	[ 0x2C8A ] = "ⲋ",
	[ 0x2C8C ] = "ⲍ",
	[ 0x2C8E ] = "ⲏ",
	[ 0x2C90 ] = "ⲑ",
	[ 0x2C92 ] = "ⲓ",
	[ 0x2C94 ] = "ⲕ",
	[ 0x2C96 ] = "ⲗ",
	[ 0x2C98 ] = "ⲙ",
	[ 0x2C9A ] = "ⲛ",
	[ 0x2C9C ] = "ⲝ",
	[ 0x2C9E ] = "ⲟ",
	[ 0x2CA0 ] = "ⲡ",
	[ 0x2CA2 ] = "ⲣ",
	[ 0x2CA4 ] = "ⲥ",
	[ 0x2CA6 ] = "ⲧ",
	[ 0x2CA8 ] = "ⲩ",
	[ 0x2CAA ] = "ⲫ",
	[ 0x2CAC ] = "ⲭ",
	[ 0x2CAE ] = "ⲯ",
	[ 0x2CB0 ] = "ⲱ",
	[ 0x2CB2 ] = "ⲳ",
	[ 0x2CB4 ] = "ⲵ",
	[ 0x2CB6 ] = "ⲷ",
	[ 0x2CB8 ] = "ⲹ",
	[ 0x2CBA ] = "ⲻ",
	[ 0x2CBC ] = "ⲽ",
	[ 0x2CBE ] = "ⲿ",
	[ 0x2CC0 ] = "ⳁ",
	[ 0x2CC2 ] = "ⳃ",
	[ 0x2CC4 ] = "ⳅ",
	[ 0x2CC6 ] = "ⳇ",
	[ 0x2CC8 ] = "ⳉ",
	[ 0x2CCA ] = "ⳋ",
	[ 0x2CCC ] = "ⳍ",
	[ 0x2CCE ] = "ⳏ",
	[ 0x2CD0 ] = "ⳑ",
	[ 0x2CD2 ] = "ⳓ",
	[ 0x2CD4 ] = "ⳕ",
	[ 0x2CD6 ] = "ⳗ",
	[ 0x2CD8 ] = "ⳙ",
	[ 0x2CDA ] = "ⳛ",
	[ 0x2CDC ] = "ⳝ",
	[ 0x2CDE ] = "ⳟ",
	[ 0x2CE0 ] = "ⳡ",
	[ 0x2CE2 ] = "ⳣ",
	[ 0xFF21 ] = "ａ",
	[ 0xFF22 ] = "ｂ",
	[ 0xFF23 ] = "ｃ",
	[ 0xFF24 ] = "ｄ",
	[ 0xFF25 ] = "ｅ",
	[ 0xFF26 ] = "ｆ",
	[ 0xFF27 ] = "ｇ",
	[ 0xFF28 ] = "ｈ",
	[ 0xFF29 ] = "ｉ",
	[ 0xFF2A ] = "ｊ",
	[ 0xFF2B ] = "ｋ",
	[ 0xFF2C ] = "ｌ",
	[ 0xFF2D ] = "ｍ",
	[ 0xFF2E ] = "ｎ",
	[ 0xFF2F ] = "ｏ",
	[ 0xFF30 ] = "ｐ",
	[ 0xFF31 ] = "ｑ",
	[ 0xFF32 ] = "ｒ",
	[ 0xFF33 ] = "ｓ",
	[ 0xFF34 ] = "ｔ",
	[ 0xFF35 ] = "ｕ",
	[ 0xFF36 ] = "ｖ",
	[ 0xFF37 ] = "ｗ",
	[ 0xFF38 ] = "ｘ",
	[ 0xFF39 ] = "ｙ",
	[ 0xFF3A ] = "ｚ",
	[ 0x10400 ] = "𐐨",
	[ 0x10401 ] = "𐐩",
	[ 0x10402 ] = "𐐪",
	[ 0x10403 ] = "𐐫",
	[ 0x10404 ] = "𐐬",
	[ 0x10405 ] = "𐐭",
	[ 0x10406 ] = "𐐮",
	[ 0x10407 ] = "𐐯",
	[ 0x10408 ] = "𐐰",
	[ 0x10409 ] = "𐐱",
	[ 0x1040A ] = "𐐲",
	[ 0x1040B ] = "𐐳",
	[ 0x1040C ] = "𐐴",
	[ 0x1040D ] = "𐐵",
	[ 0x1040E ] = "𐐶",
	[ 0x1040F ] = "𐐷",
	[ 0x10410 ] = "𐐸",
	[ 0x10411 ] = "𐐹",
	[ 0x10412 ] = "𐐺",
	[ 0x10413 ] = "𐐻",
	[ 0x10414 ] = "𐐼",
	[ 0x10415 ] = "𐐽",
	[ 0x10416 ] = "𐐾",
	[ 0x10417 ] = "𐐿",
	[ 0x10418 ] = "𐑀",
	[ 0x10419 ] = "𐑁",
	[ 0x1041A ] = "𐑂",
	[ 0x1041B ] = "𐑃",
	[ 0x1041C ] = "𐑄",
	[ 0x1041D ] = "𐑅",
	[ 0x1041E ] = "𐑆",
	[ 0x1041F ] = "𐑇",
	[ 0x10420 ] = "𐑈",
	[ 0x10421 ] = "𐑉",
	[ 0x10422 ] = "𐑊",
	[ 0x10423 ] = "𐑋",
	[ 0x10424 ] = "𐑌",
	[ 0x10425 ] = "𐑍",
	[ 0x10426 ] = "𐑎",
	[ 0x10427 ] = "𐑏",
}

--- [SHARED AND MENU]
---
--- Converts a UTF-8 string characters to lowercase.
---
---@param utf8_string string The UTF-8 string to convert.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string lowercase_utf8_str The lowercase UTF-8 string.
function utf8.lower( utf8_string, start_position, end_position, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return utf8_string
	end

	if start_position == nil then
		start_position = 1
	elseif start_position < 0 then
		start_position = math_relative( start_position, str_length )
	else
		start_position = math_min( start_position, str_length )
	end

	if end_position == nil then
		end_position = str_length
	elseif end_position < 0 then
		end_position = math_relative( end_position, str_length )
	else
		end_position = math_min( end_position, str_length )
	end

	local utf8_sequence_count = 0
	lax = lax ~= true

	---@type string[]
	local utf8_sequences = {}

	repeat
		local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_position, end_position, lax, 2 )

		if utf8_sequence_length == nil then
			utf8_sequence_length = 1
		end

		---@type string | nil
		local sequence_str

		if utf8_codepoint ~= nil then
			sequence_str = upper2lower[ utf8_codepoint ]
		end

		if sequence_str == nil then
			sequence_str = string_sub( utf8_string, start_position, start_position + ( utf8_sequence_length - 1 ) )
		end

		utf8_sequence_count = utf8_sequence_count + 1
		utf8_sequences[ utf8_sequence_count ] = sequence_str

		start_position = start_position + utf8_sequence_length
	until start_position >= end_position

	return table_concat( utf8_sequences, "", 1, utf8_sequence_count )
end

--- [SHARED AND MENU]
---
--- Converts a UTF-8 string characters to uppercase.
---
---@param utf8_string string The UTF-8 string to convert.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean Whether to lax the UTF-8 validity check.
---@return string uppercase_utf8_str The uppercase UTF-8 string.
function utf8.upper( utf8_string, start_position, end_position, lax )
	---@type integer
	local str_length = string_len( utf8_string )

	if str_length == 0 then
		return utf8_string
	end

	if start_position == nil then
		start_position = 1
	elseif start_position < 0 then
		start_position = math_relative( start_position, str_length )
	else
		start_position = math_min( start_position, str_length )
	end

	if end_position == nil then
		end_position = str_length
	elseif end_position < 0 then
		end_position = math_relative( end_position, str_length )
	else
		end_position = math_min( end_position, str_length )
	end

	local utf8_sequence_count = 0

	lax = lax ~= true

	---@type string[]
	local utf8_sequences = {}

	repeat
		local utf8_codepoint, utf8_sequence_length = decode( utf8_string, start_position, end_position, lax, 2 )

		if utf8_sequence_length == nil then
			utf8_sequence_length = 1
		end

		---@type string | nil
		local sequence_str

		if utf8_codepoint ~= nil then
			sequence_str = lower2upper[ utf8_codepoint ]
		end

		if sequence_str == nil then
			sequence_str = string_sub( utf8_string, start_position, start_position + ( utf8_sequence_length - 1 ) )
		end

		utf8_sequence_count = utf8_sequence_count + 1
		utf8_sequences[ utf8_sequence_count ] = sequence_str

		start_position = start_position + utf8_sequence_length
	until start_position >= end_position

	return table_concat( utf8_sequences, "", 1, utf8_sequence_count )
end
