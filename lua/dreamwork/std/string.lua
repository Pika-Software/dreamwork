local glua_string = _G.string

---@class dreamwork.std
local std = dreamwork.std

local ascii = std.ascii
local ascii_isSpace = ascii.isSpace

local len = std.len
local isTable = std.isTable
local represent = std.represent

local raw = std.raw
local raw_tonumber = raw.tonumber

local math = std.math
local math_abs = math.abs
local math_floor = math.floor
local math_random = math.random
local math_relative = math.relative
local math_min, math_max = math.min, math.max

local table = std.table
local table_unpack = table.unpack
local table_concat = table.concat
local table_reversed = table.reversed


--- [SHARED AND MENU]
---
--- The string type is a sequence of characters.
---
--- The string library is a standard Lua library which provides functions for the manipulation of strings.
---
--- In dreamwork string library contains additional functions.
---
---@class dreamwork.std.string
---@field PatternBytes table<integer, string>
local string = {
    byte = glua_string.byte,
    char = glua_string.char,
    dump = glua_string.dump,
    find = glua_string.find,
    format = glua_string.format,
    ---@diagnostic disable-next-line: deprecated, undefined-field
    gmatch = glua_string.gmatch or glua_string.gfind,
    gsub = glua_string.gsub,
    len = glua_string.len,
    lower = glua_string.lower,
    match = glua_string.match,
    rep = glua_string.rep,
    reverse = glua_string.reverse,
    sub = glua_string.sub,
    upper = glua_string.upper,

    --- A table of bytes that map to pattern sequences.
    PatternBytes = {
        -- ()
        [ 0x28 ] = "%(",
        [ 0x29 ] = "%)",

        -- []
        [ 0x5B ] = "%[",
        [ 0x5D ] = "%]",

        -- .
        [ 0x2E ] = "%.",

        -- %
        [ 0x25 ] = "%%",

        -- +-
        [ 0x2B ] = "%+",
        [ 0x2D ] = "%-",

        -- *
        [ 0x2A ] = "%*",

        -- ?
        [ 0x3F ] = "%?",

        -- ^
        [ 0x5E ] = "%^",

        -- $
        [ 0x24 ] = "%$"
    }
}

std.string = string

local string_sub, string_rep, string_len = string.sub, string.rep, string.len
local string_match, string_find = string.match, string.find
local string_char, string_byte = string.char, string.byte

local pattern_bytes = string.PatternBytes

--- [SHARED AND MENU]
---
--- Creates a byte map — a lookup table from byte value to `true` — from a list of individual
--- byte strings and/or byte ranges, for fast `byte_map[ byte ]` membership checks (e.g. in
--- character-classification helpers like `ascii_isSpace`).
---
--- Each argument is either a single-character string (whose byte is added to the map) or a
--- `dreamwork.std.string.ByteMapRange` table with `leading_byte`/`trailing_byte` fields giving
--- an inclusive range of single-character strings to add, and an optional `step_size`
--- (defaults to `1`) to skip bytes within that range.
---
---@param ... string | dreamwork.std.string.ByteMapRange A list of bytes or byte ranges to include in the map.
---@return table<integer, boolean> byte_map A table mapping each included byte value to `true`.
function string.byteMap( ... )
    ---@type table<integer, boolean>
    local byte_map = {}

    for i = 1, select( "#", ... ), 1 do
        local value = select( i, ... )

        if isTable( value ) then
            for j = string_byte( value.leading_byte ), string_byte( value.trailing_byte ), (value.step_size or 1) do
                byte_map[ j ] = true
            end
        else
            byte_map[ string_byte( value, 1, 1 ) ] = true
        end
    end

    return byte_map
end

--- [SHARED AND MENU]
---
--- Finds the position of the first occurrence of the specified byte value within a string,
--- searching the given range.
---
--- Unlike `string.find`, this matches a raw byte value directly rather than a substring or
--- pattern, so it's a cheaper option when you only need to locate one specific byte.
---
---@param str string The string to search in.
---@param searchable_byte integer The byte value to search for.
---@param start_position? integer The position to start searching from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop searching at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return integer | nil index The index of the first matching byte within the range, or `nil` if not found.
function string.findByte( str, searchable_byte, start_position, end_position )
    local str_length = string_len( str )

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

    for index = start_position, end_position, 1 do
        if string_byte( str, index, index ) == searchable_byte then
            return index
        end
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Checks whether a string is empty, i.e. has no bytes at all.
---
---@param str string The string to check.
---@return boolean result `true` if `str` has zero length, `false` otherwise.
function string.isEmpty( str )
    return string_byte( str, 1, 1 ) == nil
end

--- [SHARED AND MENU]
---
--- Splits a string into fixed-size chunks of `size` bytes each, in order from the start of
--- the string. The final chunk may be shorter than `size` if the string's length isn't an
--- exact multiple of it.
---
--- `size` is clamped to `[1, string length]`, so it can never be `0` or negative, and a
--- `size` larger than the string just returns the whole string as a single chunk.
---
---@param str string The string to split.
---@param size? integer The size, in bytes, of each segment. Defaults to `1` (split into individual bytes). Clamped to `[1, #str]`.
---@return string[] segments The array of fixed-size segments.
---@return integer segment_count The number of segments.
function string.divide( str, size )
    local str_length = string_len( str )

    if size == nil then
        size = 1
    else
        size = math_max( math_min( size, str_length ), 1 )
    end

    local segments, segment_count = {}, 0
    size = size - 1

    for index = 1, str_length, size + 1 do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, index, math_min( index + size, str_length ) )
    end

    return segments, segment_count
end

--- [SHARED AND MENU]
---
--- Finds the first match of `searchable` within `str`, removes it from the string, and
--- returns both the remaining string and the matched text (or a capture of it, when
--- `searchable` is a pattern with captures).
---
--- If `searchable` is a pattern (`with_pattern == true`) and it contains a capture, the first
--- captured value is returned as `extracted` instead of the whole match; otherwise the whole
--- matched substring is returned. If no match is found, `str` is returned unchanged along
--- with `default`.
---
---@param str             string       The string to extract from.
---@param searchable      string       The substring or pattern to find and remove.
---@param start_position? integer      The position to start searching from. Defaults to `1` (the start of the string).
---@param default?        string | nil The value returned as `extracted` if no match is found. Defaults to `nil`.
---@param with_pattern?   boolean      When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
---@return string new_string The string with the matched portion removed, or `str` unchanged if nothing matched.
---@return string | nil extracted The matched text (or its first capture, for patterns with captures), or `default` if nothing matched.
function string.extract( str, searchable, start_position, default, with_pattern )
    local extraction_start, extraction_end, str_matched = string_find( str, searchable, start_position or 1, with_pattern ~= true )
    if extraction_start == nil then
        return str, default
    end

    return string_sub( str, 1, extraction_start - 1 ) .. string_sub( str, extraction_end + 1 ), str_matched or default
end

--- [SHARED AND MENU]
---
--- Inserts `value` into `str` at the given `index`, shifting everything from `index` onwards
--- to the right.
---
--- `index` defaults to the end of the string (i.e. appending), and negative values count
--- from the end of the string. An `index` of `0` inserts before the first character, and an
--- `index` beyond the string's length is clamped to appending at the end.
---
--- When called with only two arguments (`string.insert( str, value )`), `value` is simply
--- appended to the end of `str`.
---
---@param str string The string to insert into.
---@param index integer The position to insert at. Defaults to the end of the string; negative values count from the end.
---@param value string The string value to insert.
---@return string result The string with `value` inserted at the given position.
---@overload fun( str: string, value: string ): string
function string.insert( str, index, value )
    if value == nil then
        return str .. index
    end

    local str_length = string_len( str )

    if index == nil then
        index = str_length + 1
    elseif index < 0 then
        index = math_relative( index, str_length )
    else
        index = math_min( index, str_length + 1 )
    end

    if index == 0 then
        return value .. str
    elseif index == (str_length + 1) then
        return str .. value
    end

    return string_sub( str, 1, index - 1 ) .. value .. string_sub( str, index, str_length )
end

--- [SHARED AND MENU]
---
--- Removes the inclusive byte range `[start_position, end_position]` from a string, returning
--- what remains with the gap closed up.
---
--- If the range covers the entire string, an empty string is returned.
---
---@param str string The string to remove from.
---@param start_position integer The start position of the removal interval, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position integer The end position of the removal interval, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string new_string The string with the specified byte interval removed.
function string.remove( str, start_position, end_position )
    local str_length = string_len( str )

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

    if start_position == 1 and end_position == str_length then
        return ""
    end

    return string_sub( str, 1, start_position - 1 ) .. string_sub( str, end_position + 1, str_length )
end

--- [SHARED AND MENU]
---
--- Checks if the string starts with the prefix, optionally checking at a byte offset into
--- the string rather than from the very start.
---
---@param str string The string to check.
---@param prefix string The prefix to check for.
---@param offset? integer The number of bytes to skip from the start of `str` before checking. Defaults to `0`.
---@return boolean has_prefix `true` if the string starts with the prefix (at the given offset), `false` otherwise.
function string.hasPrefix( str, prefix, offset )
    return string_sub( str, (offset or 0) + 1, string_len( prefix ) ) == prefix
end

--- [SHARED AND MENU]
---
--- Checks if the string ends with the suffix, optionally checking with a byte offset from
--- the end of the string rather than at the very end.
---
---@param str string The string to check.
---@param suffix string The suffix to check for.
---@param offset? integer The number of bytes to ignore at the end of `str` before checking. Defaults to `0`.
---@return boolean has_suffix `true` if the string ends with the suffix (at the given offset), `false` otherwise.
function string.hasSuffix( str, suffix, offset )
    return string_sub( str, -(string_len( suffix ) + (offset or 0)), string_len( str ) - (offset or 0) ) == suffix
end

--- [SHARED AND MENU]
---
--- Returns the index of the first occurrence of `searchable` within `str`, searching from
--- `position` onwards.
---
--- Returns `0` if `searchable` is `nil` or an empty string, and `-1` if `searchable` is not
--- found (including when `position` is already past the end of `str`) — so a non-negative
--- result other than `0` always indicates an actual match position, while `-1` specifically
--- means "not found" and `0` specifically means "nothing to search for".
---
---@param str           string  The string to search in.
---@param searchable    string  The substring or pattern to search for.
---@param position?     integer The position to start searching from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param with_pattern? boolean When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
---@return integer index The index of the first match, `0` if `searchable` is `nil` or empty, or `-1` if no match is found.
function string.indexOf( str, searchable, position, with_pattern )
    if searchable == nil or string_byte( searchable, 1, 1 ) == nil then
        return 0
    end

    local str_length = string_len( str )

    if position == nil then
        position = 1
    elseif position < 0 then
        position = math_relative( position, str_length )
    elseif position > str_length then
        return -1
    end

    return string_find( str, searchable, position, with_pattern ~= true ) or -1
end

--- [SHARED AND MENU]
---
--- Pads a string with a repeated padding string until it reaches `desired_length`
--- characters, on the left, the right, or both sides evenly.
---
--- If neither `left` nor `right` is `true`, or the string is already at least
--- `desired_length` characters long, `str` is returned unchanged.
---
--- When padding both sides, the missing length is split as evenly as possible between the
--- left and right; if it doesn't divide evenly by whole copies of `padding`, the shortfall is
--- made up with a partial copy of `padding`, with any extra leftover character going to the
--- right side.
---
--- This is the byte-length counterpart to `utf8.pad`, which measures and pads by character
--- count instead of raw byte length.
---
---@param str string The string to pad.
---@param desired_length integer The target length, in bytes, that the result should reach.
---@param padding? string The string to pad with, repeated as needed. Defaults to a single space.
---@param left? boolean Whether to add padding on the left side.
---@param right? boolean Whether to add padding on the right side.
---@return string padded_str The padded string, or `str` unchanged if no padding was needed or requested.
function string.pad( str, desired_length, padding, left, right )
    if not (left or right) then
        return str
    end

    local char_length
    if padding == nil then
        char_length = 1
        padding = " "
    else
        char_length = string_len( padding )
    end

    local missing_length = math_max( 0, desired_length - string_len( str ) )
    if missing_length == 0 then
        return str
    end

    if left and right then
        local half_reps = math_floor( (missing_length / char_length) * 0.5 )
        local padding_str = string_rep( padding, half_reps )

        local remainder = missing_length - ((half_reps * 2) * char_length)
        if remainder == 0 then
            return padding_str .. str .. padding_str
        end

        local half_remainder = math_floor( remainder * 0.5 )
        padding_str          = padding_str .. string_sub( padding, 1, half_remainder )
        remainder            = remainder - (half_remainder * 2)

        if remainder == 0 then
            return padding_str .. str .. padding_str
        end

        return padding_str .. str .. padding_str .. string_sub( padding, 1, remainder )
    end

    local full_reps = math_floor( missing_length / char_length )
    local remainder = missing_length - (full_reps * char_length)

    if left then
        local result = string_rep( padding, full_reps )

        if remainder ~= 0 then
            result = result .. string_sub( padding, 1, remainder )
        end

        return result .. str
    end

    if right then
        local result = str .. string_rep( padding, full_reps )

        if remainder ~= 0 then
            result = result .. string_sub( padding, 1, remainder )
        end

        return result
    end

    return str
end

do

    --- [SHARED AND MENU]
    ---
    --- Splits a string into an array of substrings around every occurrence of `searchable`
    --- within the given range. The matched delimiter itself is not included in any segment.
    ---
    --- If `searchable` is `nil` or an empty string, the string is instead split into one segment
    --- per byte (effectively `str_length` single-character segments), ignoring `with_pattern`,
    --- `start_position`, and `end_position` entirely.
    ---
    --- Consecutive delimiters, or a delimiter at the very start or end of the searched range,
    --- produce empty-string segments rather than being collapsed or skipped — the segment count
    --- is always exactly one more than the number of delimiter matches found. If `searchable`
    --- never occurs within the range, the whole range is returned as a single segment.
    ---
    --- `string.replace` is built directly on top of this function, rejoining the returned
    --- segments with a replacement string in place of `replaceable`.
    ---
    ---@param str             string  The string to split.
    ---@param searchable?     string  The substring or pattern to split by. If `nil` or empty, splits into individual bytes instead.
    ---@param with_pattern?   boolean When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
    ---@param start_position? integer The position to start splitting from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string). Ignored if `searchable` is `nil` or empty.
    ---@param end_position?   integer The position to stop splitting at, inclusive. Negative values count from the end of the string. Defaults to the end of the string. Ignored if `searchable` is `nil` or empty.
    ---@return string[] segments The resulting array of substrings.
    ---@return integer segment_count The number of entries in `segments`.
    local function split( str, searchable, with_pattern, start_position, end_position )
        local str_length = string_len( str )

        ---@type string[]
        local segments = {}

        if searchable == nil or string_byte( searchable, 1, 1 ) == nil then
            for index = 1, str_length, 1 do
                segments[ index ] = string_sub( str, index, index )
            end

            return segments, str_length
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

        with_pattern = with_pattern ~= true

        ---@type integer
        local segment_count = 0

        ::split_loop::

        local segment_start, segment_end = string_find( str, searchable, start_position, with_pattern )
        if segment_end == nil then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, start_position, end_position )
            return segments, segment_count
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, start_position, math_min( segment_start - 1, end_position ) )

        local split_position = segment_end + 1

        if split_position > end_position then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, split_position, end_position )

            return segments, segment_count
        end

        start_position = split_position

        ---@diagnostic disable-next-line: missing-return
        goto split_loop
    end

    string.split = split

    --- [SHARED AND MENU]
    ---
    --- Replaces all occurrences of `searchable` within `str` with `replaceable`.
    ---
    --- Implemented by splitting `str` around every match of `searchable` (within the given
    --- range) and rejoining the pieces with `replaceable` in between — so this behaves the same
    --- as `split( str, searchable, with_pattern, start_position, end_position )` followed by
    --- `table.concat( segments, replaceable )`. If `searchable` doesn't occur in `str` (or in the
    --- given range), the string is returned unchanged.
    ---
    ---@param str           string  The string we are seeking to replace an occurrence(s) in.
    ---@param searchable?   string  What we are seeking to replace, or the substring or pattern to split by.
    ---@param replaceable?  string  What to replace it with. If `nil`, occurrences are removed.
    ---@param with_pattern?   boolean When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
    ---@param start_position? integer The position to start replacing from, inclusive. Matches outside this range are left untouched.
    ---@param end_position?   integer The position to stop replacing at, inclusive. Matches outside this range are left untouched.
    ---@return string str_replaced The new string with the occurrences replaced.
    function string.replace( str, searchable, replaceable, with_pattern, start_position, end_position )
        local segments, segment_count = split( str, searchable, with_pattern, start_position, end_position )

        if segment_count == 0 then
            return str
        elseif segment_count == 1 then
            return segments[ 1 ]
        end

        if replaceable == nil then
            replaceable = ""
        end

        if segment_count == 2 then
            return segments[ 1 ] .. replaceable .. segments[ 2 ]
        end

        return table_concat( segments, replaceable, 1, segment_count )
    end

end

--- [SHARED AND MENU]
---
--- Returns the number of non-overlapping matches of a substring or pattern within a string.
---
--- Matching proceeds left to right, always resuming immediately after the end of the
--- previous match — so overlapping occurrences are not counted separately (e.g. counting
--- `"aa"` in `"aaaa"` returns `2`, not `3`).
---
--- If `searchable` is `nil` or an empty string, the length of `str` is returned instead of a
--- match count, since an empty pattern would otherwise match at every position.
---
---@param str           string  The string to count.
---@param searchable    string  The substring or pattern to count by.
---@param with_pattern? boolean When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
---@return integer match_count The number of non-overlapping matches, or `string.len( str )` if `searchable` is `nil` or empty.
function string.count( str, searchable, with_pattern )
    local str_length = string_len( str )
    if searchable == nil or string_byte( searchable, 1, 1 ) == nil then
        return str_length
    end

    with_pattern = with_pattern ~= true

    local index, length = 1, 0

    ::count_loop::

    local start_position, end_position = string_find( str, searchable, index, with_pattern )
    if start_position == nil or index > str_length then
        return length
    end

    index, length = end_position + 1, length + 1

    ---@diagnostic disable-next-line: missing-return
    goto count_loop
end

--- [SHARED AND MENU]
---
--- Returns the total number of occurrences of the specified byte within a string, scanning
--- the whole `[start_position, end_position]` range rather than stopping at the first
--- non-matching byte.
---
--- Unlike `string.countConsecutiveByte`, a non-matching byte doesn't end the count early —
--- every matching byte in the range is counted, regardless of what's in between.
---
--- Returns `0` if `str` is empty or `counted_byte` is `nil`.
---
---@param str string The string to count.
---@param counted_byte? integer The byte value to count occurrences of. If `nil`, `0` is returned.
---@param reverse_direction? boolean If `false`, scanning goes from `start_position` towards higher indices (left to right). If `true`, scanning goes from `start_position` towards lower indices (right to left). Defaults to `false`.
---@param start_position? integer The position to start counting from. Negative values count from the end of the string. Defaults to `1` when scanning forward, or the end of the string when scanning in reverse.
---@param end_position? integer The position to stop counting at, inclusive. Negative values count from the end of the string. Defaults to the end of the string when scanning forward, or `1` when scanning in reverse.
---@return integer byte_count The total number of occurrences of `counted_byte` within the range.
function string.countByte( str, counted_byte, reverse_direction, start_position, end_position )
    if counted_byte == nil or string_byte( str, 1, 1 ) == nil then
        return 0
    end

    local str_length = string_len( str )

    if start_position == nil then
        if reverse_direction then
            start_position = str_length
        else
            start_position = 1
        end
    elseif start_position < 0 then
        start_position = math_relative( start_position, str_length )
    else
        start_position = math_min( start_position, str_length )
    end

    if end_position == nil then
        if reverse_direction then
            end_position = 1
        else
            end_position = str_length
        end
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    local byte_count = 0

    if reverse_direction then
        if start_position < end_position then
            return byte_count
        end
    elseif start_position > end_position then
        return byte_count
    end

    ::byte_count_loop::

    if string_byte( str, start_position, start_position ) == counted_byte then
        byte_count = byte_count + 1
    end

    if start_position == end_position then
        return byte_count
    end

    if reverse_direction then
        start_position = start_position - 1
    else
        start_position = start_position + 1
    end

    ---@diagnostic disable-next-line: missing-return
    goto byte_count_loop
end

--- [SHARED AND MENU]
---
--- Returns the number of consecutive repetitions of the specified byte, starting from
--- `start_position` and scanning towards `end_position`, stopping as soon as a byte that
--- doesn't match `counted_byte` is encountered.
---
--- Note that this only counts a *run starting exactly at* `start_position` — it does not
--- search the range for the longest run of `counted_byte` anywhere within it. If the byte at
--- `start_position` doesn't match `counted_byte`, `0` is returned immediately.
---
--- Returns `0` if `str` is empty or `counted_byte` is `nil`.
---
---@param str string The string to count.
---@param counted_byte? integer The byte value to count consecutive repetitions of. If `nil`, `0` is returned.
---@param reverse_direction? boolean If `false`, scanning goes from `start_position` towards higher indices (left to right). If `true`, scanning goes from `start_position` towards lower indices (right to left). Defaults to `false`.
---@param start_position? integer The position to start counting from. Negative values count from the end of the string. Defaults to `1` when scanning forward, or the end of the string when scanning in reverse.
---@param end_position? integer The position to stop counting at, inclusive; counting stops early regardless if a non-matching byte is found first. Negative values count from the end of the string. Defaults to the end of the string when scanning forward, or `1` when scanning in reverse.
---@return integer byte_count The number of consecutive occurrences of `counted_byte` found, starting at `start_position`.
function string.countConsecutiveByte( str, counted_byte, reverse_direction, start_position, end_position )
    if counted_byte == nil or string_byte( str, 1, 1 ) == nil then
        return 0
    end

    local str_length = string_len( str )

    if start_position == nil then
        if reverse_direction then
            start_position = str_length
        else
            start_position = 1
        end
    elseif start_position < 0 then
        start_position = math_relative( start_position, str_length )
    else
        start_position = math_min( start_position, str_length )
    end

    if end_position == nil then
        if reverse_direction then
            end_position = 1
        else
            end_position = str_length
        end
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    local byte_count = 0

    if reverse_direction then
        if start_position < end_position then
            return byte_count
        end
    elseif start_position > end_position then
        return byte_count
    end

    ::byte_count_consecutive_loop::

    if string_byte( str, start_position, start_position ) == counted_byte then
        byte_count = byte_count + 1
    else
        return byte_count
    end

    if start_position == end_position then
        return byte_count
    end

    if reverse_direction then
        start_position = start_position - 1
    else
        start_position = start_position + 1
    end

    ---@diagnostic disable-next-line: missing-return
    goto byte_count_consecutive_loop
end

--- [SHARED AND MENU]
---
--- Removes leading and/or trailing occurrences of a single specific byte from a string,
--- within the given range.
---
--- Unlike `string.trim`, this matches one exact byte value rather than a Lua pattern or
--- character class — it's a cheaper, byte-level equivalent for the common case of trimming
--- a single fixed character (e.g. spaces, null bytes, a delimiter).
---
--- `left` and `right` both default to `true`; passing `false` for either one disables
--- trimming on that side while leaving the other side's default behavior unchanged.
---
--- If the entire range consists of `trailing_byte`, the result is an empty string.
---
---@param str string The string to trim.
---@param trailing_byte? integer The byte value to trim from the start and/or end. Defaults to `0x20` (space).
---@param left? boolean Whether to trim from the start of the string. Defaults to `true`.
---@param right? boolean Whether to trim from the end of the string. Defaults to `true`.
---@param start_position? integer The position to start trimming within, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop trimming within, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string trimmed_str The trimmed string.
---@return integer trimmed_length The length of the trimmed string.
function string.trimByte( str, trailing_byte, left, right, start_position, end_position )
    local str_length = string_len( str )

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

    if trailing_byte == nil then
        trailing_byte = 0x20 --[[ Space ]]
    end

    if left ~= false then
        while string_byte( str, start_position, start_position ) == trailing_byte do
            if start_position == end_position then
                return string_sub( str, end_position + 1, str_length ), str_length - end_position
            else
                start_position = start_position + 1
            end
        end
    end

    if right ~= false then
        while string_byte( str, end_position, end_position ) == trailing_byte do
            if end_position == 1 then
                return "", 0
            else
                end_position = end_position - 1
            end
        end
    end

    ---@cast start_position integer

    return string_sub( str, start_position, end_position ), end_position - start_position + 1
end

--- [SHARED AND MENU]
---
--- Removes leading and/or trailing whitespace characters from a string, within the given
--- range, and returns the trimmed string along with its length.
---
--- A byte counts as whitespace according to `ascii_isSpace` (space, tab, newline, and other
--- ASCII whitespace bytes), not just the literal space character — unlike `string.trimByte`,
--- which only matches one specific byte value.
---
--- `left` and `right` both default to `true`; passing `false` for either one disables
--- trimming on that side while leaving the other side's default behavior unchanged.
---
--- If the entire range consists of whitespace, the result is an empty string.
---
---@param str string The string to trim.
---@param left? boolean Whether to trim from the start of the string. Defaults to `true`.
---@param right? boolean Whether to trim from the end of the string. Defaults to `true`.
---@param start_position? integer The position to start trimming within, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop trimming within, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string trimmed_str The trimmed string.
---@return integer trimmed_length The length of the trimmed string.
function string.trimSpaces( str, left, right, start_position, end_position )
    local str_length = string_len( str )

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

    if left ~= false then
        while ascii_isSpace( string_byte( str, start_position, start_position ) ) do
            if start_position == end_position then
                return string_sub( str, end_position + 1, str_length ), str_length - end_position
            else
                start_position = start_position + 1
            end
        end
    end

    if right ~= false then
        while ascii_isSpace( string_byte( str, end_position, end_position ) ) do
            if end_position == 1 then
                return "", 0
            else
                end_position = end_position - 1
            end
        end
    end

    ---@cast start_position integer

    return string_sub( str, start_position, end_position ), end_position - start_position + 1
end

--- [SHARED AND MENU]
---
--- Splits a string into an array of substrings, breaking at every occurrence of the
--- specified byte within the given range. The delimiter byte itself is not included in any
--- of the resulting segments.
---
--- Consecutive delimiter bytes produce empty-string segments rather than being collapsed, so
--- e.g. splitting `"a,,b"` on `,` yields `{ "a", "", "b" }`.
---
---@param str string The string to split.
---@param searchable_byte? integer The byte value to split on. Defaults to `0x20` (space).
---@param start_position? integer The position to start splitting from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop splitting at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string[] segments The resulting array of substrings.
---@return integer segment_count The number of entries in `segments`.
local function byte_split( str, searchable_byte, start_position, end_position )
    if searchable_byte == nil then
        searchable_byte = 0x20 --[[ Space ]]
    end

    local str_length = string_len( str )

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

    local segments, segment_count = {}, 0

    if start_position > end_position then
        return segments, segment_count
    end

    local split_position = start_position - 1

    ::byte_split_loop::

    if string_byte( str, start_position, start_position ) == searchable_byte then
        if split_position ~= start_position then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, split_position + 1, start_position - 1 )
        end

        split_position = start_position
    end

    if start_position ~= end_position then
        start_position = start_position + 1
        goto byte_split_loop
    end

    segment_count = segment_count + 1
    segments[ segment_count ] = string_sub( str, split_position + 1, start_position )

    return segments, segment_count
end

string.byteSplit = byte_split

--- [SHARED AND MENU]
---
--- Replaces all occurrences of the specified byte within `str` with `replaceable`, within
--- the given range.
---
--- Implemented by splitting `str` around every occurrence of `searchable_byte` (via
--- `byte_split`) and rejoining the pieces with `replaceable` in between — the byte-level
--- counterpart to `string.replace`, which matches a substring or pattern instead of a single
--- byte value. If `searchable_byte` is `nil`, this falls back to `byte_split`'s default of
--- splitting on space (`0x20`).
---
---@param str              string  The string we are seeking to replace an occurrence(s) in.
---@param searchable_byte? integer The byte value to find and replace. Defaults to `0x20` (space).
---@param replaceable?     string  What to replace each occurrence with. If `nil`, occurrences are removed.
---@param start_position?  integer The position to start replacing from, inclusive. Matches outside this range are left untouched.
---@param end_position?    integer The position to stop replacing at, inclusive. Matches outside this range are left untouched.
---@return string str_replaced The new string with the occurrences replaced.
function string.byteReplace( str, searchable_byte, replaceable, start_position, end_position )
    local segments, segment_count = byte_split( str, searchable_byte, start_position, end_position )

    if segment_count == 0 then
        return str
    elseif segment_count == 1 then
        return segments[ 1 ]
    end

    if replaceable == nil then
        replaceable = ""
    end

    if segment_count == 2 then
        return segments[ 1 ] .. replaceable .. segments[ 2 ]
    end

    return table_concat( segments, replaceable, 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Checks if `str` contains `searchable`.
---
--- Wraps `string.find` and returns `true` if a match is found at or after
--- `start_position`. By default the search is treated as a plain substring
--- match; pass `with_pattern = true` to interpret `searchable` as a Lua
--- pattern instead.
---
---@param str             string  The string to search in.
---@param searchable      string  The substring or pattern to search for.
---@param with_pattern?   boolean When `true`, `searchable` is interpreted as a Lua pattern. Defaults to `false` (plain match).
---@param start_position? integer The byte position to start searching from. Defaults to `1`. Negative values count from the end of the string.
---@return boolean found `true` if `searchable` was found within `str`, `false` otherwise.
function string.contains( str, searchable, with_pattern, start_position )
    return string_find( str, searchable, start_position, with_pattern ~= true ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks whether a string contains the specified single byte value, within the given range.
---
--- The single-byte counterpart to `string.containsBytes`, which checks for membership in a
--- whole byte map instead of one exact value.
---
---@param str string The string to check.
---@param byte integer The byte value to check for.
---@param start_position? integer The position to start checking from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop checking at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return boolean has_byte `true` if `byte` occurs anywhere within the range, `false` otherwise.
function string.containsByte( str, byte, start_position, end_position )
    local str_length = string_len( str )

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

    local step = (start_position < end_position) and 1 or -1

    for index = start_position, end_position, step do
        if string_byte( str, index, index ) == byte then return true end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Checks whether a string contains at least one byte that's a member of the given byte map,
--- within the given range.
---
--- `byte_map` is a lookup table of the kind produced by `string.byteMap` — a table mapping
--- byte values to `true` — so this is effectively "does any byte in this range belong to the
--- given character class".
---
---@param str string The string to check.
---@param byte_map table<integer, boolean> A byte map, as produced by `string.byteMap`, giving the set of bytes to look for.
---@param start_position? integer The position to start checking from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop checking at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return boolean has_byte `true` if any byte in the range is present in `byte_map`, `false` otherwise.
function string.containsBytes( str, byte_map, start_position, end_position )
    local str_length = string_len( str )

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

    for index = start_position, end_position, ((start_position < end_position) and 1 or -1) do
        if byte_map[ string_byte( str, index, index ) ] then
            return true
        end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Removes every occurrence of the specified byte from a string, within the given range.
---
--- Implemented by splitting `str` around every occurrence of `byte` (via `byte_split`) and
--- rejoining the pieces with nothing in between — equivalent to
--- `string.byteReplace( str, byte, "", start_position, end_position )`, but without the
--- overhead of an optional replacement argument.
---
---@param str string The string to purge.
---@param byte integer The byte value to remove.
---@param start_position? integer The position to start purging from, inclusive. Bytes outside this range are left untouched.
---@param end_position? integer The position to stop purging at, inclusive. Bytes outside this range are left untouched.
---@return string str_purged The string with every occurrence of `byte` removed.
function string.purge( str, byte, start_position, end_position )
    local segments, segment_count = byte_split( str, byte, start_position, end_position )
    return table_concat( segments, "", 1, segment_count )
end

do

    --- [SHARED AND MENU]
    ---
    --- Converts a string, or a sub-range of it, to a number, with automatic base detection when
    --- `base` is omitted.
    ---
    --- If `base` is `nil`, the start of the (sub)string is inspected to guess the base: a `0x`/
    --- `0X` prefix selects base `16`, a leading `0` followed by another digit selects base `8`,
    --- and anything else defaults to base `10`. A bare `"0x"`/`"0X"` prefix with nothing after it
    --- is treated as a literal `0` rather than being passed through to the underlying conversion.
    ---
    --- If neither `start_position` nor `end_position` is given, the whole string is converted
    --- directly; otherwise the selected sub-range is extracted first (via `string.sub` semantics)
    --- and that substring is converted instead.
    ---
    ---@param str string The string to convert.
    ---@param base? integer The numeric base to interpret `str` in. If omitted, the base is auto-detected from the string's prefix (`0x`/`0X` → 16, leading `0` → 8, otherwise 10).
    ---@param start_position? integer The position to start converting from. Defaults to `1` (the start of the string).
    ---@param end_position? integer The position to stop converting at. Defaults to the end of the string.
    ---@return number | nil num The converted number, or `nil` if the (sub)string is not a valid number in the given base.
    local function toNumber( str, base, start_position, end_position )
        if base == nil then
            local uint8_1, uint8_2, uint8_3 = string_byte( str, (start_position or 1), (start_position or 1) + 2 )
            if uint8_1 == 0x30 --[[ 0 ]] and (uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]]) then
                if uint8_3 == nil then
                    return 0
                end

                base = 16
            elseif uint8_1 == 0x30 --[[ 0 ]] and uint8_2 ~= nil then
                base = 8
            else
                base = 10
            end
        elseif base == 16 then
            local uint8_1, uint8_2, uint8_3 = string_byte( str, (start_position or 1), (start_position or 1) + 2 )
            if uint8_1 == 0x30 --[[ 0 ]] and (uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]]) and uint8_3 == nil then
                return 0
            end
        end

        if start_position == nil and end_position == nil then
            return raw_tonumber( str, base )
        end

        return raw_tonumber( string_sub( str, start_position or 1, end_position ), base )
    end

    string.toNumber = toNumber

    --- [SHARED AND MENU]
    ---
    --- Checks whether a string (or a sub-range of it) can be parsed as a valid number, using the
    --- same base auto-detection and sub-range rules as `toNumber`/`string.toNumber`.
    ---
    --- Equivalent to `string.toNumber( str, base, start_position, end_position ) ~= nil`, but
    --- without needing to hold on to the converted value when only the validity check matters.
    ---
    ---@param str string The string to check.
    ---@param base? integer The numeric base to check `str` in. If omitted, the base is auto-detected from the string's prefix (`0x`/`0X` → 16, leading `0` → 8, otherwise 10).
    ---@param start_position? integer The position to start checking from. Defaults to `1` (the start of the string).
    ---@param end_position? integer The position to stop checking at. Defaults to the end of the string.
    ---@return boolean is_number `true` if the (sub)string is a valid number in the given base, `false` otherwise.
    function string.isNumber( str, base, start_position, end_position )
        return toNumber( str, base, start_position, end_position ) ~= nil
    end

end

--- [SHARED AND MENU]
---
--- Checks whether a string looks like a well-formed URL, matched against a strict pattern
--- rather than resolved or validated against any real scheme or host.
---
--- Specifically requires: a scheme starting with a lowercase letter and continuing with
--- lowercase letters, `+`, `-`, or `.` (e.g. `http`, `git+ssh`), followed by a `:`, followed
--- by the rest of the URL — which may be empty, but must not contain whitespace or control
--- characters (bytes `0x00`–`0x20`), bytes above `0x7E` (`0x7F`–`0xFF`), or the characters
--- `"`, `<`, `>`, `^`, `` ` ``, `{`, `|`, or `}`.
---
--- This is a syntactic sanity check, not a full RFC 3986 validator — it doesn't verify that
--- the scheme is a known/registered one, or inspect the structure of the authority, path,
--- query, or fragment beyond the character restrictions above.
---
---@param str string The string to check.
---@return boolean result `true` if `str` matches the expected URL shape, `false` otherwise.
function string.isURL( str )
    return string_match( str, "^%l[%l+-.]+%:[^%z\x01-\x20\x7F-\xFF\"<>^`:{-}]*$" ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks whether a string starts with a LuaJIT bytecode header for the given JIT version.
---
--- Verifies that the first three bytes at `start_position` match the LuaJIT bytecode magic
--- signature `\x1BLJ` (`ESC`, `L`, `J`), and that the fourth byte equals `jit_version` — this
--- is the same version byte exposed as `jit.version_byte` (e.g. `0x01` for LuaJIT 2.0,
--- `0x02` for LuaJIT 2.1), which lets a loader reject bytecode compiled for a different
--- LuaJIT version before attempting to load it.
---
--- This only checks the header; it doesn't validate the rest of the chunk as well-formed
--- bytecode.
---
---@param str string The string to check.
---@param jit_version `0x01` | `0x02` | integer The expected LuaJIT bytecode version byte to match against (see `jit.version_byte`).
---@param start_position? integer The position in `str` where the bytecode header is expected to start. Defaults to `1` (the start of the string).
---@return boolean result `true` if `str` starts with a matching LuaJIT bytecode header at `start_position`, `false` otherwise.
function string.isBytecode( str, jit_version, start_position )
    if start_position == nil then
        start_position = 1
    end

    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, start_position, start_position + 3 )
    return uint8_1 == 0x1B and uint8_2 == 0x4C and uint8_3 == 0x4A and uint8_4 == jit_version
end

--- [SHARED AND MENU]
---
--- Escapes a string so it can be safely embedded in a Lua pattern and matched literally,
--- rather than having its characters interpreted as pattern syntax.
---
--- Within the given range, every byte that has a special meaning in Lua patterns (the magic
--- characters, listed in `pattern_bytes`) is prefixed with `%`; the null byte (`0x00`) is
--- specifically escaped as `%z`, since patterns can't contain a literal embedded null. All
--- other bytes, and anything outside `start_position`/`end_position`, are left untouched.
---
--- This is the pattern-syntax counterpart to `string.escape`, which escapes for display/
--- string-literal purposes rather than for safe use inside a pattern.
---
---@param str string The string to escape.
---@param start_position? integer The position to start escaping from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop escaping at, inclusive. Negative values count from the end of the string. Defaults to the end of the string.
---@return string escaped_str The string with pattern-magic characters escaped for literal matching.
function string.escapePattern( str, start_position, end_position )
    local str_length = string_len( str )

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

    local escape_position = start_position - 1
    local segments, segment_count = {}, 0

    ::escape_pattern_loop::

    local uint8_1 = string_byte( str, start_position, start_position )
    local replacement

    if uint8_1 == 0x0 then
        replacement = "%z"
    else
        replacement = pattern_bytes[ uint8_1 ]
    end

    if replacement ~= nil then
        if escape_position ~= start_position then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, escape_position + 1, start_position - 1 ) .. replacement
        end

        escape_position = start_position
    end

    if start_position ~= end_position then
        start_position = start_position + 1
        goto escape_pattern_loop
    end

    if escape_position ~= start_position then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, escape_position + 1, start_position )
    end

    if segment_count == 0 then
        return str
    elseif segment_count == 1 then
        return segments[ 1 ]
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Removes leading and/or trailing matches of a character set from a string.
---
--- `pattern_str` is treated as a *set of characters* to trim, not a general Lua pattern:
--- a single character is escaped via `pattern_bytes` (if needed) and matched literally; a
--- multi-character string that isn't already a `%`-class (like `%s`) is wrapped as a
--- character class (`[...]`), so e.g. `"-_"` trims any run of `-` and `_` characters, not the
--- literal substring `"-_"`. Defaults to `%s` (whitespace) when omitted.
---
--- `left` and `right` both default to `true`; passing `false` for either one disables
--- trimming on that side while leaving the other side's default behavior unchanged, so only
--- an explicit `false` turns a side off.
---
---@param str string The string to trim.
---@param pattern_str? string The set of characters to trim, as a single character, a `%`-class, or a run of characters to treat as a class. Defaults to `%s` (whitespace).
---@param left? boolean Whether to trim from the start of the string. Defaults to `true`.
---@param right? boolean Whether to trim from the end of the string. Defaults to `true`.
---@return string trimmed_str The trimmed string.
function string.trim( str, pattern_str, left, right )
    if pattern_str == nil then
        pattern_str = "%s"
    else
        local uint8_1, uint8_2, uint8_3 = string_byte( pattern_str, 1, 3 )

        if uint8_1 == nil then
            pattern_str = "%s"
        elseif uint8_2 == nil then
            pattern_str = pattern_bytes[ uint8_1 ] or pattern_str
        elseif uint8_3 ~= nil or uint8_1 ~= 0x25 --[[ % ]] then
            pattern_str = "[" .. pattern_str .. "]"
        end
    end

    if left ~= false then
        if right ~= false then
            return string_match( str, "^" .. pattern_str .. "*(.-)" .. pattern_str .. "*$" ) or str
        end

        return string_match( str, "^" .. pattern_str .. "*(.+)$" ) or str
    elseif right ~= false then
        return string_match( str, "^(.-)" .. pattern_str .. "*$" ) or str
    end

    return str
end

do

    local numberic_alphabet = { [ 0 ] = 10, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39 }
    local lowercase_alphabet = { [ 0 ] = 26, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x6C, 0x6D, 0x6E, 0x6F, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A }
    local uppercase_alphabet = { [ 0 ] = 26, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A }
    local symbol_alphabet = { [ 0 ] = 32, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x7B, 0x7C, 0x7D, 0x7E }
    local extended_alphabet = { [ 0 ] = 128, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F, 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xDB, 0xDC, 0xDD, 0xDE, 0xDF, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF }

    --- [SHARED AND MENU]
    ---
    --- Generates a random string by repeatedly picking a random character pool and then a random
    --- character from it.
    ---
    --- Can be used to generate a password/key/secret.
    ---
    --- `lowercase` and `numbers` are included by default; `uppercase`, `symbols`, and
    --- `extended_ascii` are opt-in. At each position, one of the enabled pools is chosen at
    --- random with equal probability per *pool*, not per character — so if one pool is much
    --- larger than another (e.g. `extended_ascii` vs `numbers`), characters from the smaller pool
    --- still appear just as often on average, rather than being proportionally under-represented.
    ---
    --- The length of the string is 8 by default. Passing `0` returns an empty string without
    --- requiring any pool to be enabled.
    ---
    ---@param length? integer The length of the string, defaults to 8.
    ---@param lowercase? boolean Whether to include lowercase letters (`a`-`z`). Defaults to `true`.
    ---@param uppercase? boolean Whether to include uppercase letters (`A`-`Z`). Defaults to `false`.
    ---@param numbers? boolean Whether to include digits (`0`-`9`). Defaults to `true`.
    ---@param symbols? boolean Whether to include symbol/punctuation characters. Defaults to `false`.
    ---@param extended_ascii? boolean Whether to include extended (non-ASCII, above `0x7F`) characters. Defaults to `false`.
    ---@return string result A randomly generated string of the requested length, drawn from the enabled character pools.
    function string.random( length, lowercase, uppercase, numbers, symbols, extended_ascii )
        if length == nil then
            length = 8
        elseif length == 0 then
            return ""
        end

        ---@type integer[][]
        local alphabets = {}

        ---@type integer
        local alphabet_count = 0

        if lowercase ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = lowercase_alphabet
        end

        if uppercase then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = uppercase_alphabet
        end

        if numbers ~= false then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = numberic_alphabet
        end

        if symbols then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = symbol_alphabet
        end

        if extended_ascii then
            alphabet_count = alphabet_count + 1
            alphabets[ alphabet_count ] = extended_alphabet
        end

        ---@type integer[]
        local chars = {}

        for index = 1, length, 1 do
            local alphabet = alphabets[ math_random( 1, alphabet_count ) ]
            chars[ index ] = alphabet[ math_random( 1, alphabet[ 0 ] ) ]
        end

        return string_char( table_unpack( chars, 1, length ) )
    end

end

--- [SHARED AND MENU]
---
--- Interpolates a string with the given arguments, replacing `{...}` placeholders with
--- values from `variables`, within the given range.
---
--- The arguments are replaced in the string using the following format:
---
--- `{1}`, `{2}`, `{3}`, `{4}`, `{5}`, `{6}`, `{7}`, `{8}`, `{9}`
---
--- It's also supports named arguments:
---
--- `{key}`, `{my_val}`, `{something}` and etc.
---
--- In both cases the text between the braces is used as a literal string key into
--- `variables` (so `{1}` looks up `variables["1"]`, not `variables[1]`) — keep that in mind
--- when passing a positional/array-style table, since Lua treats numeric and string keys as
--- distinct.
---
--- A backslash (`\`) escapes the character immediately following it, both inside and outside
--- of `{...}`, so e.g. `\{` or `\}` can be used to include a literal brace without it being
--- treated as a placeholder delimiter.
---
--- A placeholder is only replaced if its key exists in `variables` with a non-`nil` value;
--- otherwise the placeholder (including its braces) is left in the output unchanged. The same
--- applies to an empty placeholder (`{}`) and to an unterminated `{` with no matching `}`
--- before `end_position` — both are left as literal text rather than erroring.
---
---@see string.format
---
---@param str string The string to interpolate.
---@param variables string[] | table<string, string> The replacement values, keyed by the literal text inside each `{...}` placeholder (as a string key, even for numeric-looking placeholders like `{1}`).
---@param start_position? integer The position to start interpolating from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string). Text before this position is copied through unchanged.
---@param end_position? integer The position to stop interpolating at, inclusive. Negative values count from the end of the string. Defaults to the end of the string. Text after this position is copied through unchanged.
---@return string str The interpolated string.
function string.interpolate( str, variables, start_position, end_position )
    local str_length = string_len( str )

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

    ---@type integer
    local break_position = start_position

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    if start_position ~= 1 then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, 1, start_position - 1 )
    end

    repeat

        local uint8_1 = string_byte( str, start_position, start_position )

        if uint8_1 == 0x7B --[[ { ]] then
            ---@type integer
            local index_start = start_position + 1
            if index_start >= end_position then
                break
            end

            ---@type integer
            local index = index_start

            repeat

                local uint8_2 = string_byte( str, index, index )

                if uint8_2 == 0x7D --[[ } ]] then
                    local index_end = index - 1
                    start_position = index + 1

                    if index_start > index_end then
                        break
                    end

                    local arg_value = variables[ string_sub( str, index_start, index_end ) ]
                    if arg_value ~= nil then
                        if break_position ~= start_position then
                            segment_count = segment_count + 1
                            segments[ segment_count ] = string_sub( str, break_position, index_start - 2 )
                        end

                        break_position = start_position

                        segment_count = segment_count + 1
                        segments[ segment_count ] = arg_value
                    end

                    break
                elseif uint8_2 == 0x5C --[[ \ ]] then
                    index = index + 2
                else
                    index = index + 1
                end

            until index_start >= end_position

            if start_position <= index_start then
                start_position = index_start
            end
        elseif uint8_1 == 0x5C --[[ \ ]] then
            start_position = start_position + 2
        else
            start_position = start_position + 1
        end

    until start_position > end_position

    if break_position ~= start_position then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, break_position, end_position )
    end

    if end_position ~= str_length then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, end_position + 1, str_length )
    end

    if segment_count == 0 then
        return ""
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Replaces occurrences of a specific byte in the string with values from `variables`, in
--- the order they're found — the first occurrence of `interpolate_byte` is replaced with
--- `variables[1]`, the second with `variables[2]`, and so on.
---
--- Unlike `string.interpolate`, which matches named/numbered `{...}` placeholders, this
--- matches a single repeated placeholder byte (similar to `%s`-style sequential substitution,
--- but using one literal byte as the marker instead of a format specifier). It also has no
--- escape syntax — every occurrence of `interpolate_byte` within the range is treated as a
--- placeholder, with no way to include a literal copy of that byte.
---
--- Substitution stops once every entry in `variables` (up to `variable_count`) has been used;
--- any further occurrences of `interpolate_byte` beyond that point are left untouched in the
--- output. If `variable_count` is `0` (or `variables` is empty), the string is returned
--- unchanged without scanning it at all.
---
---@param str string The string to interpolate.
---@param interpolate_byte integer The byte value that acts as a placeholder marker.
---@param variables string[] The replacement values, used in order of occurrence within the string.
---@param variable_count? integer The number of entries in `variables` to use. Defaults to `#variables` (via `len`); pass this to skip that calculation when the count is already known.
---@param start_position? integer The position to start interpolating from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string). Text before this position is copied through unchanged.
---@param end_position? integer The position to stop interpolating at, inclusive. Negative values count from the end of the string. Defaults to the end of the string. Text after this position is copied through unchanged.
---@return string str The interpolated string.
function string.interpolateByte( str, interpolate_byte, variables, variable_count, start_position, end_position )
    local str_length = string_len( str )
    if str_length == 0 then
        return str
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

    if start_position > end_position then
        return str
    end

    if variable_count == nil then
        variable_count = len( variables )
    end

    if variable_count == 0 then
        return str
    end

    ---@type string[]
    local segments = {}

    ---@type integer
    local segment_count = 0

    if start_position ~= 1 then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, 1, start_position - 1 )
    end

    local break_point = start_position - 1
    local index = 0

    ::byte_interpolate_loop::

    if string_byte( str, start_position, start_position ) == interpolate_byte then
        if break_point ~= start_position then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( str, break_point + 1, start_position - 1 )
        end

        index = index + 1
        segment_count = segment_count + 1
        segments[ segment_count ] = variables[ index ]

        break_point = start_position
    end

    if start_position ~= end_position and index ~= variable_count then
        start_position = start_position + 1
        goto byte_interpolate_loop
    end

    if break_point ~= end_position then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, break_point + 1, end_position )
    end

    if end_position ~= str_length then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, end_position + 1, str_length )
    end

    if segment_count == 0 then
        return ""
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Packs a sequence of bytes into a string, the inverse of `string.unpack`.
---
--- Equivalent to `string.char( table.unpack( bytes, 1, byte_count ) )`, but built with
--- `string_char` calls batched 32 bytes at a time for performance rather than unpacking the
--- whole array (and hitting Lua's C-stack argument limit) in one call.
---
---@param bytes integer[] The sequence of bytes to pack, each an integer in the range `0`-`255`.
---@param byte_count? integer The number of bytes, from the start of `bytes`, to pack. Defaults to `len( bytes )` (the whole array).
---@return string str The packed byte string.
function string.pack( bytes, byte_count )
    if byte_count == nil then
        byte_count = len( bytes )
    end

    if byte_count == 0 then
        return ""
    end

    local segments, segment_count = {}, 0
    local remaining = byte_count % 32

    local split_position = byte_count - remaining

    for i = 0, split_position - 1, 32 do
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char(
            bytes[ i + 1 ], bytes[ i + 2 ], bytes[ i + 3 ], bytes[ i + 4 ],
            bytes[ i + 5 ], bytes[ i + 6 ], bytes[ i + 7 ], bytes[ i + 8 ],
            bytes[ i + 9 ], bytes[ i + 10 ], bytes[ i + 11 ], bytes[ i + 12 ],
            bytes[ i + 13 ], bytes[ i + 14 ], bytes[ i + 15 ], bytes[ i + 16 ],
            bytes[ i + 17 ], bytes[ i + 18 ], bytes[ i + 19 ], bytes[ i + 20 ],
            bytes[ i + 21 ], bytes[ i + 22 ], bytes[ i + 23 ], bytes[ i + 24 ],
            bytes[ i + 25 ], bytes[ i + 26 ], bytes[ i + 27 ], bytes[ i + 28 ],
            bytes[ i + 29 ], bytes[ i + 30 ], bytes[ i + 31 ], bytes[ i + 32 ]
        )
    end

    if remaining ~= 0 then
        segment_count = segment_count + 1
        segments[ segment_count ] = string_char( table_unpack( bytes, split_position + 1, byte_count ) )
    end

    return table_concat( segments, "", 1, segment_count )
end

--- [SHARED AND MENU]
---
--- Unpacks a string into a sequence of bytes, the inverse of `string.pack`.
---
--- Equivalent to `{ string.byte( str, start_position, end_position ) }` over the given range,
--- but built with `string_byte` calls batched 32 bytes at a time for performance.
---
---@param str string The string to unpack.
---@param start_position? integer The position to start unpacking from, inclusive. Negative values count from the end of the string. Defaults to `1` (the start of the string).
---@param end_position? integer The position to stop unpacking at, inclusive. Negative values count from the end of the string. Defaults to the end of the string (`string.len( str )`).
---@return integer[] bytes The unpacked bytes, one entry per byte in the range.
---@return integer byte_count The number of bytes unpacked (i.e. `#bytes`).
function string.unpack( str, start_position, end_position )
    local str_length = string_len( str )
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

    if start_position > end_position then
        return {}, 0
    end

    local segments = {}

    local total = end_position - start_position + 1
    local remaining = total % 32

    local split_position = total - remaining

    for i = start_position, split_position - 1, 32 do
        segments[ i ], segments[ i + 1 ], segments[ i + 2 ], segments[ i + 3 ],
        segments[ i + 4 ], segments[ i + 5 ], segments[ i + 6 ], segments[ i + 7 ],
        segments[ i + 8 ], segments[ i + 9 ], segments[ i + 10 ], segments[ i + 11 ],
        segments[ i + 12 ], segments[ i + 13 ], segments[ i + 14 ], segments[ i + 15 ],
        segments[ i + 16 ], segments[ i + 17 ], segments[ i + 18 ], segments[ i + 19 ],
        segments[ i + 20 ], segments[ i + 21 ], segments[ i + 22 ], segments[ i + 23 ],
        segments[ i + 24 ], segments[ i + 25 ], segments[ i + 26 ], segments[ i + 27 ],
        segments[ i + 28 ], segments[ i + 29 ], segments[ i + 30 ], segments[ i + 31 ] = string_byte( str, i, i + 31 )
    end

    if remaining ~= 0 then
        split_position = split_position + 1

        segments[ split_position ], segments[ split_position + 1 ], segments[ split_position + 2 ], segments[ split_position + 3 ],
        segments[ split_position + 4 ], segments[ split_position + 5 ], segments[ split_position + 6 ], segments[ split_position + 7 ],
        segments[ split_position + 8 ], segments[ split_position + 9 ], segments[ split_position + 10 ], segments[ split_position + 11 ],
        segments[ split_position + 12 ], segments[ split_position + 13 ], segments[ split_position + 14 ], segments[ split_position + 15 ],
        segments[ split_position + 16 ], segments[ split_position + 17 ], segments[ split_position + 18 ], segments[ split_position + 19 ],
        segments[ split_position + 20 ], segments[ split_position + 21 ], segments[ split_position + 22 ], segments[ split_position + 23 ],
        segments[ split_position + 24 ], segments[ split_position + 25 ], segments[ split_position + 26 ], segments[ split_position + 27 ],
        segments[ split_position + 28 ], segments[ split_position + 29 ], segments[ split_position + 30 ] = string_byte( str, split_position, split_position + 30 )
    end

    return segments, total
end

--- [SHARED AND MENU]
---
--- Inserts a separator (e.g. a comma) every `offset` characters, counting from the right end
--- of the string — the typical "thousands separator" formatting for large numbers
--- (e.g. `"1234567"` → `"1,234,567"`).
---
--- Operates purely on the string as a sequence of characters, with no awareness of numeric
--- structure: it doesn't special-case a leading sign, a decimal point, or non-digit
--- characters, so calling it on something that isn't a plain digit string (e.g. one that
--- already contains a `.` or `-`) will insert separators through those characters too, based
--- purely on position from the right.
---
--- `offset` is normalized to a non-negative integer (`math_abs` + `math_floor`); an `offset`
--- of `0` returns `str` unchanged, since no grouping width is meaningful.
---
---@param str string The string to format.
---@param separator? string The separator string to insert between groups. Defaults to `","`.
---@param offset? integer The number of characters per group, counted from the right. Defaults to `3`. Normalized to a non-negative integer; `0` returns `str` unchanged.
---@return string str The string with separators inserted every `offset` characters from the right.
function string.comma( str, separator, offset )
    local str_length = string_len( str )
    if str_length == 0 then return str end

    if separator == nil then
        separator = ","
    end

    if offset == nil then
        offset = 3
    else
        offset = math_max( 0, math_floor( math_abs( offset ) ) )
        if offset == 0 then return str end
    end

    for i = str_length - offset, 1, -offset do
        str = string_sub( str, 1, i ) .. separator .. string_sub( str, i + 1 )
    end

    return str
end

--- [SHARED AND MENU]
---
--- Returns a string that is the concatenation of `repetitions` copies of the byte `rep_byte`.
---
--- Equivalent to `string.rep( string.char( rep_byte ), repetitions )`, but avoids building
--- and concatenating an intermediate one-byte string on every repetition. Repetition counts
--- from `1` to `8` are special-cased as direct `string_char` calls (the fastest path); any
--- other count falls back to filling an array and unpacking it in one `string_char` call.
---
---@param rep_byte integer The byte value to repeat (`0`-`255`).
---@param repetitions? integer The number of times to repeat the byte. Defaults to `1`.
---@return string rep_str The byte repeated `repetitions` times, as a string.
function string.byteRep( rep_byte, repetitions )
    if repetitions == nil then
        repetitions = 1
    end

    if repetitions == 1 then
        return string_char( rep_byte )
    elseif repetitions == 2 then
        return string_char( rep_byte, rep_byte )
    elseif repetitions == 3 then
        return string_char( rep_byte, rep_byte, rep_byte )
    elseif repetitions == 4 then
        return string_char( rep_byte, rep_byte, rep_byte, rep_byte )
    elseif repetitions == 5 then
        return string_char( rep_byte, rep_byte, rep_byte, rep_byte, rep_byte )
    elseif repetitions == 6 then
        return string_char( rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte )
    elseif repetitions == 7 then
        return string_char( rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte )
    elseif repetitions == 8 then
        return string_char( rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte, rep_byte )
    end

    ---@type integer[]
    local bytes = {}

    for i = 1, repetitions, 1 do
        bytes[ i ] = rep_byte
    end

    return string_char( table_unpack( bytes, 1, repetitions ) )
end

do

    local string_replace = string.replace

    --- [SHARED AND MENU]
    ---
    --- Wraps a string in quotes, escaping any quote characters of the same kind already inside
    --- it so the result is a syntactically valid quoted literal.
    ---
    --- Only the quote character itself is escaped — other characters that would normally need
    --- escaping in a string literal (backslashes, newlines, etc.) are left untouched, so this is
    --- not a full string-literal encoder, just a quote-wrapping helper.
    ---
    --- Inverse of `string.unQuote`.
    ---
    ---@param str string The string to quote.
    ---@param use_single? boolean When `true`, wraps in single quotes (`'`) and escapes any `'` inside `str`. When `false`/omitted, wraps in double quotes (`"`) and escapes any `"` inside `str`.
    ---@return string result The quoted string.
    function string.quote( str, use_single )
        if use_single then
            return "'" .. string_replace( str, "'", "\\'" ) .. "'"
        end

        return '"' .. string_replace( str, '"', '\\"' ) .. '"'
    end

    --- [SHARED AND MENU]
    ---
    --- Removes a surrounding pair of quotes from a string and unescapes any escaped quote
    --- characters of the same kind inside it. Inverse of `string.quote`.
    ---
    --- If `str` isn't wrapped in the expected quote character at both ends, it's returned
    --- unchanged (aside from unescaping) rather than erroring — so this is safe to call on a
    --- string that may or may not actually be quoted.
    ---
    ---@param str string The string to unquote.
    ---@param use_single? boolean When `true`, expects and strips single quotes (`'`) and unescapes `\'` inside `str`. When `false`/omitted, expects and strips double quotes (`"`) and unescapes `\"` inside `str`.
    ---@return string result The unquoted string, or `str` unchanged (with unescaping still applied) if it wasn't wrapped in the expected quote character.
    function string.unQuote( str, use_single )
        if use_single then
            return string_replace( string_match( str, "^'(.*)'$" ) or str, "\\'", "'" )
        end

        return string_replace( string_match( str, "^\"(.*)\"$" ) or str, '\\"', '"' )
    end

end

do

    local string_trimSpaces = string.trimSpaces
    local string_byteRep = string.byteRep

    --- [SHARED AND MENU]
    ---
    --- Pads a string with a single repeated byte until it reaches `desired_length` characters,
    --- on the left, the right, or both sides evenly.
    ---
    --- Unlike `string.pad`, which pads with an arbitrary (possibly multi-byte) padding string,
    --- this pads with one fixed byte value, which avoids the chunk-size arithmetic `string.pad`
    --- needs and is a cheaper option when a single repeated byte is all that's needed.
    ---
    --- If neither `left` nor `right` is `true`, or `str` is already at least `desired_length`
    --- characters long, `str` is returned unchanged. When padding both sides and the missing
    --- length is odd, the extra byte goes to the right side.
    ---
    ---@param str string The string to pad.
    ---@param desired_length integer The target length, in bytes, that the result should reach.
    ---@param padding_byte? integer The byte value to pad with. Defaults to `0x20` (space).
    ---@param left? boolean Whether to add padding on the left side.
    ---@param right? boolean Whether to add padding on the right side.
    ---@return string padded_str The padded string, or `str` unchanged if no padding was needed or requested.
    function string.bytePad( str, desired_length, padding_byte, left, right )
        local missing_length = math_max( 0, desired_length - string_len( str ) )
        if missing_length == 0 then
            return str
        end

        if padding_byte == nil then
            padding_byte = 0x20 --[[ space ]]
        end

        if left then
            if right then
                local missing_length_half = math_floor( missing_length * 0.5 )
                return string_byteRep( padding_byte, missing_length_half ) .. str .. string_byteRep( padding_byte, missing_length_half + (missing_length - (missing_length_half * 2)) )
            end

            return string_byteRep( padding_byte, missing_length ) .. str
        end

        if right then
            return str .. string_byteRep( padding_byte, missing_length )
        end

        return str
    end

    --- [SHARED AND MENU]
    ---
    --- Removes leading whitespace from the start of a single-line string (does not affect
    --- subsequent lines if `str` contains embedded newlines — see `string.unindentLines` for
    --- that). Equivalent to `string.trimSpaces( str, true, false )`.
    ---
    ---@param str string The string to unindent.
    ---@return string unindented The string with leading whitespace removed.
    local function unIndent( str )
        return (string_trimSpaces( str, true, false ))
    end

    string.unIndent = unIndent

    --- [SHARED AND MENU]
    ---
    --- Sets a string's leading indentation to exactly `size` spaces, replacing any existing
    --- leading whitespace rather than adding to it.
    ---
    --- Operates on `str` as a single line — any existing leading whitespace is stripped (via
    --- `unIndent`) and then `size` spaces are prepended; embedded newlines are not treated
    --- specially, so only the very start of `str` is affected. See `string.indentLines` for
    --- per-line indentation of multi-line text.
    ---
    ---@param str string The string to indent.
    ---@param size integer The number of spaces the result should start with.
    ---@return string indented The string with its leading whitespace replaced by `size` spaces.
    function string_indent( str, size )
        return string_byteRep( 0x20, size ) .. unIndent( str )
    end

    string.indent = string_indent

    --- [SHARED AND MENU]
    ---
    --- Indents every line of a string by setting each line's leading whitespace to exactly
    --- `size` spaces (via `string.indent`), splitting on `\n` and rejoining the result the same
    --- way.
    ---
    --- Like `string.indent`, this replaces each line's existing leading whitespace rather than
    --- adding to it.
    ---
    ---@param str string The string to indent.
    ---@param size integer The number of spaces each line should start with.
    ---@return string indented The string with every line re-indented to `size` spaces.
    function string.indentLines( str, size )
        local lines, line_count = byte_split( str, 0x0A )

        if line_count == 0 then
            return ""
        elseif line_count == 1 then
            return string_indent( str, size )
        end

        ---@type string[]
        local output = {}

        for i = 1, line_count, 1 do
            output[ i ] = string_indent( lines[ i ], size )
        end

        return table_concat( output, "\n", 1, line_count )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes leading whitespace from every line of a string (via `string.unIndent`),
    --- splitting on `\n` and rejoining the result the same way. The multi-line counterpart to
    --- `string.unIndent`, which only strips the first line.
    ---
    ---@param str string The string to unindent.
    ---@return string unindented The string with leading whitespace removed from every line.
    function string.unindentLines( str )
        local lines, line_count = byte_split( str, 0x0A )

        if line_count == 0 then
            return ""
        elseif line_count == 1 then
            return unIndent( str )
        end

        ---@type string[]
        local output = {}

        for i = 1, line_count, 1 do
            output[ i ] = unIndent( lines[ i ] )
        end

        return table_concat( output, "\n", 1, line_count )
    end

end

do

    ---@param diff_ops dreamwork.std.string.Difference[]
    ---@param diff_op_count integer
    ---@param type dreamwork.std.string.DifferenceType
    ---@param source string
    ---@param position integer
    ---@return integer diff_op_count
    local function prepend_diff_op( diff_ops, diff_op_count, type, source, position )
        local data = diff_ops[ diff_op_count ]
        if data == nil then
            diff_op_count = diff_op_count + 1
            diff_ops[ diff_op_count ] = {
                type = type,
                source = source,
                start_position = position,
                end_position = position
            }

            return diff_op_count
        end

        if data.type == type and data.source == source then
            data.start_position = math_min( data.start_position or position, position )
            data.end_position = math_max( data.end_position or position, position )
            return diff_op_count
        end

        diff_op_count = diff_op_count + 1
        diff_ops[ diff_op_count ] = {
            start_position = position,
            end_position = position,
            source = source,
            type = type
        }

        return diff_op_count
    end


    --- [SHARED AND MENU]
    ---
    --- Computes a Myers diff between two strings.
    ---
    --- The result is a list of edit operations that transform `source` into `target`.
    --- Operations are returned in order from the start of the strings to the end, and runs
    --- of the same kind are merged, so the result is as compact as possible while still being
    --- a minimal edit script (in terms of number of inserted/removed characters) between the
    --- two strings.
    ---
    --- Common prefixes and suffixes shared by `source` and `target` are detected and emitted
    --- as `0` (equal) operations directly, without going through the general diff algorithm;
    --- the remaining differing middle section, if any, is solved using an O(ND) Myers
    --- shortest-edit-script search to find the minimal set of insertions and removals.
    ---
    ---@param source string The source string.
    ---@param target string The target string.
    ---@return dreamwork.std.string.Difference[] diff_ops The difference operations.
    ---@return integer diff_op_count The count of difference operations.
    function string.diff( source, target )
        -- if both strings is same
        if source == target then
            return {
                {
                    type = 0,
                    source = source,
                    start_position = 1,
                    end_position = string_len( source )
                }
            }, 1
        end

        local source_length, target_length = string_len( source ), string_len( target )

        -- if string source is empty
        if source_length == 0 then
            return {
                {
                    type = 1,
                    source = target,
                    start_position = 1,
                    end_position = string_len( target )
                }
            }, 1
        end

        -- if string target is empty
        if target_length == 0 then
            return {
                {
                    type = 2,
                    source = source,
                    start_position = 1,
                    end_position = source_length
                }
            }, 1
        end

        local abs_limit = math_min( source_length, target_length )

        local prefix_length = 0

        while prefix_length ~= abs_limit and string_byte( source, prefix_length + 1 ) == string_byte( target, prefix_length + 1 ) do
            prefix_length = prefix_length + 1
        end

        local suffix_limit = abs_limit - prefix_length
        local suffix_length = 0

        while suffix_length ~= suffix_limit and string_byte( source, source_length - suffix_length ) == string_byte( target, target_length - suffix_length ) do
            suffix_length = suffix_length + 1
        end

        ---@type dreamwork.std.string.Difference[]
        local diff_ops = {}

        ---@type integer
        local diff_op_count = 0

        if suffix_length ~= 0 then
            diff_op_count = diff_op_count + 1
            diff_ops[ diff_op_count ] = {
                type = 0,
                source = source,
                start_position = source_length - suffix_length + 1,
                end_position = source_length
            }
        end

        ---@type integer
        local mid_source_length = source_length - prefix_length - suffix_length

        ---@type integer
        local mid_target_length = target_length - prefix_length - suffix_length

        if mid_source_length == 0 and mid_target_length == 0 then
            -- `source` equals `target` after trimming, nothing but prefix/suffix, just append prefix after that, if it exists of course
            if prefix_length ~= 0 then
                diff_op_count = diff_op_count + 1
                diff_ops[ diff_op_count ] = {
                    type = 0,
                    source = source,
                    start_position = 1,
                    end_position = prefix_length
                }
            end

            return diff_ops, diff_op_count
        elseif mid_source_length == 0 then
            -- `source` is empty after trimming, so lets append the whole target

            diff_op_count = diff_op_count + 1
            diff_ops[ diff_op_count ] = {
                type = 1,
                source = target,
                start_position = prefix_length + 1,
                end_position = target_length - suffix_length
            }
        elseif mid_target_length == 0 then
            -- same case as with `source`, but right now `target` is empty so we append `source` and stops here
            diff_op_count = diff_op_count + 1
            diff_ops[ diff_op_count ] = {
                type = 2,
                source = source,
                start_position = prefix_length + 1,
                end_position = source_length - suffix_length
            }
        else

            local max_distance = mid_source_length + mid_target_length
            local offset = max_distance

            ---@type table<integer, integer[]>
            local snapshots = {}

            local buffer_min, buffer_max = offset + 1, offset + 1

            local buffer = {
                [ offset + 1 ] = 0,
            }

            ---@type integer
            local snapshot_count = 0

            for distance = 0, max_distance, 1 do
                ---@type integer[]
                local snapshot = {}

                for index = buffer_min, buffer_max, 1 do
                    snapshot[ index ] = buffer[ index ]
                end

                snapshots[ distance + 1 ] = snapshot

                for k = -distance, distance, 2 do
                    local index = offset + k

                    local x
                    if k == -distance then
                        x = buffer[ index + 1 ]
                    elseif k == distance then
                        x = buffer[ index - 1 ] + 1
                    else
                        x = math_max(
                            buffer[ index - 1 ] + 1,
                            buffer[ index + 1 ]
                        )
                    end

                    local y = x - k

                    ::diff_bytes_loop::

                    if x < mid_source_length and y < mid_target_length then
                        x, y = x + 1, y + 1

                        local source_byte = string_byte( source, prefix_length + x )
                        if source_byte ~= nil and source_byte == string_byte( target, prefix_length + y ) then
                            goto diff_bytes_loop
                        else
                            x, y = x - 1, y - 1
                        end
                    end

                    buffer[ index ] = x

                    if x >= mid_source_length and y >= mid_target_length then
                        snapshot_count = distance
                        goto diff_trace_done
                    end

                    buffer_min, buffer_max = math_min( buffer_min, index ), math_max( buffer_max, index )
                end
            end

            ::diff_trace_done::

            ---@type dreamwork.std.string.Difference[]
            local mid_diff_ops = {}

            ---@type integer
            local mid_diff_op_count = 0

            local x, y = mid_source_length, mid_target_length

            for i = snapshot_count, 0, -1 do
                local snapshot = snapshots[ i + 1 ]
                local k = x - y

                local index = offset + k

                local previous_k
                if k == -i then
                    previous_k = k + 1
                elseif k == i then
                    previous_k = k - 1
                elseif (snapshot[ index - 1 ] or 0) < (snapshot[ index + 1 ] or 0) then
                    previous_k = k + 1
                else
                    previous_k = k - 1
                end

                local previous_x = snapshot[ offset + previous_k ] or 0
                local previous_y = previous_x - previous_k

                while x > previous_x and y > previous_y do
                    mid_diff_op_count = prepend_diff_op( mid_diff_ops, mid_diff_op_count, 0, source, prefix_length + x )
                    x, y = x - 1, y - 1
                end

                if i ~= 0 then
                    if x == previous_x then
                        mid_diff_op_count = prepend_diff_op( mid_diff_ops, mid_diff_op_count, 1, target, prefix_length + y )
                        y = y - 1
                    else
                        mid_diff_op_count = prepend_diff_op( mid_diff_ops, mid_diff_op_count, 2, source, prefix_length + x )
                        x = x - 1
                    end
                end
            end

            for i = 1, mid_diff_op_count, 1 do
                diff_ops[ diff_op_count + i ] = mid_diff_ops[ i ]
            end

            diff_op_count = diff_op_count + mid_diff_op_count

        end

        if prefix_length ~= 0 then
            diff_op_count = diff_op_count + 1
            diff_ops[ diff_op_count ] = {
                type = 0,
                source = source,
                start_position = 1,
                end_position = prefix_length
            }
        end

        return table_reversed( diff_ops, diff_op_count )
    end

end
