---@meta _

--- [SHARED AND MENU]
---
--- The string type is a sequence of characters.
---
--- The string library is a standard Lua library which provides functions for the manipulation of strings.
---
--- In dreamwork string library contains additional functions.
---
---@class stringlib
---@field PatternBytes table<integer, string>
string = {}

--- A table of bytes that map to pattern sequences.
string.PatternBytes = {}

--- [SHARED AND MENU]
---
--- Creates a byte map — a lookup table from byte value to `true` — from a list of individual
--- byte strings and/or byte ranges, for fast `byte_map[ byte ]` membership checks (e.g. in
--- character-classification helpers like `ascii_isSpace`).
---
--- Each argument is either a single-character string (whose byte is added to the map) or a
--- `string.ByteMapRange` table with `leading_byte`/`trailing_byte` fields giving
--- an inclusive range of single-character strings to add, and an optional `step_size`
--- (defaults to `1`) to skip bytes within that range.
---
---@param ... string | string.ByteMapRange A list of bytes or byte ranges to include in the map.
---@return table<integer, boolean> byte_map A table mapping each included byte value to `true`.
---@nodiscard
function string.byteMap(...) end

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
---@nodiscard
function string.findByte(str, searchable_byte, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Checks whether a string is empty, i.e. has no bytes at all.
---
---@param str string The string to check.
---@return boolean result `true` if `str` has zero length, `false` otherwise.
---@nodiscard
function string.isEmpty(str) end

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
---@nodiscard
function string.divide(str, size) end

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
---@nodiscard
function string.extract(str, searchable, start_position, default, with_pattern) end

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
---@nodiscard
---@overload fun( str: string, value: string ): string
function string.insert(str, index, value) end

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
---@nodiscard
function string.remove(str, start_position, end_position) end

--- [SHARED AND MENU]
---
--- Checks if the string starts with the prefix, optionally checking at a byte offset into
--- the string rather than from the very start.
---
---@param str string The string to check.
---@param prefix string The prefix to check for.
---@param offset? integer The number of bytes to skip from the start of `str` before checking. Defaults to `0`.
---@return boolean has_prefix `true` if the string starts with the prefix (at the given offset), `false` otherwise.
---@nodiscard
function string.hasPrefix(str, prefix, offset) end

--- [SHARED AND MENU]
---
--- Checks if the string ends with the suffix, optionally checking with a byte offset from
--- the end of the string rather than at the very end.
---
---@param str string The string to check.
---@param suffix string The suffix to check for.
---@param offset? integer The number of bytes to ignore at the end of `str` before checking. Defaults to `0`.
---@return boolean has_suffix `true` if the string ends with the suffix (at the given offset), `false` otherwise.
---@nodiscard
function string.hasSuffix(str, suffix, offset) end

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
---@nodiscard
function string.indexOf(str, searchable, position, with_pattern) end

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
--- This is the byte-length counterpart to `unicode.pad`, which measures and pads by display
--- width (columns) instead of raw byte length.
---
---@param str string The string to pad.
---@param desired_length integer The target length, in bytes, that the result should reach.
---@param padding? string The string to pad with, repeated as needed. Defaults to a single space.
---@param left? boolean Whether to add padding on the left side.
---@param right? boolean Whether to add padding on the right side.
---@return string padded_str The padded string, or `str` unchanged if no padding was needed or requested.
---@nodiscard
function string.pad(str, desired_length, padding, left, right) end

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
---@nodiscard
function string.split(str, searchable, with_pattern, start_position, end_position) end

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
---@nodiscard
function string.replace(str, searchable, replaceable, with_pattern, start_position, end_position) end

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
---@nodiscard
function string.count(str, searchable, with_pattern) end

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
---@nodiscard
function string.countByte(str, counted_byte, reverse_direction, start_position, end_position) end

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
---@nodiscard
function string.countConsecutiveByte(str, counted_byte, reverse_direction, start_position, end_position) end

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
---@nodiscard
function string.trimByte(str, trailing_byte, left, right, start_position, end_position) end

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
---@nodiscard
function string.trimSpaces(str, left, right, start_position, end_position) end

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
---@nodiscard
function string.byteSplit(str, searchable_byte, start_position, end_position) end

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
---@nodiscard
function string.byteReplace(str, searchable_byte, replaceable, start_position, end_position) end

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
---@nodiscard
function string.contains(str, searchable, with_pattern, start_position) end

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
---@nodiscard
function string.containsByte(str, byte, start_position, end_position) end

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
---@nodiscard
function string.containsBytes(str, byte_map, start_position, end_position) end

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
---@nodiscard
function string.purge(str, byte, start_position, end_position) end

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
---@nodiscard
function string.toNumber(str, base, start_position, end_position) end

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
---@nodiscard
function string.isNumber(str, base, start_position, end_position) end

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
---@nodiscard
function string.isURL(str) end

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
---@nodiscard
function string.isBytecode(str, jit_version, start_position) end

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
---@nodiscard
function string.escapePattern(str, start_position, end_position) end

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
---@nodiscard
function string.trim(str, pattern_str, left, right) end

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
---@nodiscard
function string.random(length, lowercase, uppercase, numbers, symbols, extended_ascii) end

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
---@nodiscard
function string.interpolate(str, variables, start_position, end_position) end

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
---@nodiscard
function string.interpolateByte(str, interpolate_byte, variables, variable_count, start_position, end_position) end

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
---@nodiscard
function string.pack(bytes, byte_count) end

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
---@nodiscard
function string.unpack(str, start_position, end_position) end

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
---@nodiscard
function string.comma(str, separator, offset) end

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
---@nodiscard
function string.byteRep(rep_byte, repetitions) end

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
---@nodiscard
function string.quote(str, use_single) end

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
---@nodiscard
function string.unQuote(str, use_single) end

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
---@nodiscard
function string.bytePad(str, desired_length, padding_byte, left, right) end

--- [SHARED AND MENU]
---
--- Removes leading whitespace from the start of a single-line string (does not affect
--- subsequent lines if `str` contains embedded newlines — see `string.unindentLines` for
--- that).
---
--- If `size` is given, at most `size` leading whitespace bytes are removed; otherwise all
--- leading whitespace is removed, equivalent to `string.trimSpaces( str, true, false )`.
---
---@param str string The string to unindent.
---@param size? integer The maximum number of leading whitespace bytes to remove. Defaults to removing all of them.
---@return string unindented The string with leading whitespace removed.
---@nodiscard
function string.unIndent(str, size) end

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
---@nodiscard
function string.indent(str, size) end

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
---@nodiscard
function string.indentLines(str, size) end

--- [SHARED AND MENU]
---
--- Removes leading whitespace from every line of a string (via `string.unIndent`),
--- splitting on `\n` and rejoining the result the same way. The multi-line counterpart to
--- `string.unIndent`, which only strips the first line.
---
---@param str string The string to unindent.
---@param size? integer The maximum number of leading whitespace bytes to remove from each line. Defaults to removing all of them.
---@return string unindented The string with leading whitespace removed from every line.
---@nodiscard
function string.unindentLines(str, size) end

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
---@return string.Difference[] diff_ops The difference operations.
---@return integer diff_op_count The count of difference operations.
---@nodiscard
function string.diff(source, target) end
