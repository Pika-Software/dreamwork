---@class dreamwork.std
local std = dreamwork.std

local len = std.len

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_char = string.char

local math = std.math
local math_min = math.min
local math_floor = math.floor
local math_range = math.range

local raw = std.raw

local rbit = raw.bit
local rbit_rshift = rbit.rshift

local table = std.table
local table_concat = table.concat

local utf8 = std.utf8
local utf8_pack = utf8.pack
local utf8_unpack = utf8.unpack

local ffi = std.ffi
local ffi_string, uint8_array_t

if ffi ~= nil then
    ffi_string, uint8_array_t = ffi.string, ffi.typeof( "uint8_t[?]" )
end

-- output units: bytes for the FFI buffer, one character strings for `table.concat`
local basic_units, digit_units = {}, {}

for codepoint = 0, 0x7F, 1 do
    basic_units[ codepoint ] = ffi_string == nil and string_char( codepoint ) or codepoint
end

for digit = 0, 0x23, 1 do
    local uint8 = digit < 26 and (digit + 0x61 --[[ "a" ]]) or (digit + 0x16 --[[ "0" - 26 ]])
    digit_units[ digit ] = ffi_string == nil and string_char( uint8 ) or uint8
end

-- checks for the case-insensitive `"xn--"` prefix at `position`
local function has_prefix( str, position )
    local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( str, position, position + 3 )
    return (uint8_1 == 0x78 --[[ "x" ]] or uint8_1 == 0x58 --[[ "X" ]]) and
        (uint8_2 == 0x6E --[[ "n" ]] or uint8_2 == 0x4E --[[ "N" ]]) and
        uint8_3 == 0x2D --[[ "-" ]] and uint8_4 == 0x2D --[[ "-" ]]
end

-- `true` if `str` has no bytes above 0x7F within the range
local function is_ascii( str, start_position, end_position )
    for position = start_position, end_position, 1 do
        if string_byte( str, position, position ) >= 0x80 then
            return false
        end
    end

    return true
end

-- `true` if `str` is ASCII-only and has no labels with the `"xn--"` prefix within the range
local function is_plain( str, start_position, end_position )
    local label_start = start_position

    for position = start_position, end_position, 1 do
        local uint8 = string_byte( str, position, position )
        if uint8 >= 0x80 then
            return false
        elseif uint8 == 0x2E --[[ "." ]] then
            label_start = position + 1
        elseif position == label_start and position + 3 <= end_position and has_prefix( str, position ) then
            return false
        end
    end

    return true
end

-- digit values of `[0-9A-Za-z]`, `nil` for invalid bytes
local digit_values = {}

for uint8 = 0x30, 0x39, 1 do
    digit_values[ uint8 ] = uint8 - 0x16
end

for uint8 = 0x41, 0x5A, 1 do
    digit_values[ uint8 ] = uint8 - 0x41
    digit_values[ uint8 + 0x20 ] = uint8 - 0x41
end

-- `punycode.pack` scratch space, reused between calls for labels
-- up to `scratch_limit` code points, so huge inputs are not kept alive
local scratch_limit = 0x100
local output_units, extended_codepoints, extended_deltas = {}, {}, {}

if ffi_string ~= nil then
    -- every delta takes at most 11 digits, the prefix and the delimiter take 5 bytes
    output_units = uint8_array_t( scratch_limit * 12 + 6 )
end

--- [SHARED AND MENU]
---
--- Punycode encoding/decoding library.
---
--- Punycode represents Unicode text using only the ASCII letters, digits and hyphen
--- (`[a-z0-9-]`), it is used by IDNA to store internationalized domain names in DNS, where
--- each encoded label is marked with the ACE prefix `"xn--"`.
---
--- * `punycode.pack` / `punycode.unpack` work on a single label given as code points.
--- * `punycode.encode` / `punycode.decode` work on a whole UTF-8 domain, label by label.
---
--- Only the Punycode transform itself is implemented, IDNA mapping and
--- normalization (lowercasing, NFC, disallowed characters) are left to the caller.
---
--- See https://en.wikipedia.org/wiki/Punycode
---
--- RFC 3492: https://datatracker.ietf.org/doc/html/rfc3492
---
---@class dreamwork.std.punycode
local punycode = {}
std.punycode = punycode

--- [SHARED AND MENU]
---
--- Encodes a single label, given as Unicode code points, into Punycode.
---
--- A label made of basic (ASCII) code points only is returned as is, without
--- the `"xn--"` prefix or the trailing `"-"` delimiter, the way IDNA treats such labels.
---
--- Basic code points keep their case, the encoded digits are always lowercase.
---
--- ```lua
--- punycode.pack( { 0x6D, 0xFC, 0x6E, 0x63, 0x68, 0x65, 0x6E } ) -- "xn--mnchen-3ya"
--- punycode.pack( { 0x6D, 0xFC, 0x6E, 0x63, 0x68, 0x65, 0x6E }, nil, true ) -- "mnchen-3ya"
--- punycode.pack( { 0x61, 0x62, 0x63 } ) -- "abc"
--- ```
---
---@param codepoints integer[] The code points of the label to encode.
---@param codepoint_count? integer The number of code points to encode, defaults to the length of `codepoints`.
---@param ignore_prefix? boolean If `true`, the `"xn--"` prefix is not prepended to the result.
---@param lax? boolean If `true`, surrogates (U+D800 - U+DFFF) and code points above U+10FFFF are encoded as well instead of being rejected.
---@return string | nil punycode_str The Punycode string, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
---@nodiscard
local function punycode_pack( codepoints, codepoint_count, ignore_prefix, lax )
    if codepoint_count == nil then
        codepoint_count = len( codepoints )
    end

    local strict = lax ~= true

    local output, extended, deltas = output_units, extended_codepoints, extended_deltas

    if codepoint_count > scratch_limit then
        if ffi_string == nil then
            output = {}
        else
            output = uint8_array_t( codepoint_count * 12 + 6 )
        end

        extended, deltas = {}, {}
    end

    local first = 1
    local length = 4

    if ignore_prefix then
        first, length = 5, 4
    else
        output[ 1 ], output[ 2 ], output[ 3 ], output[ 4 ] = basic_units[ 0x78 ], basic_units[ 0x6E ], basic_units[ 0x2D ], basic_units[ 0x2D ]
    end

    -- non-basic code points, scanned for the next code point to insert
    local extended_count = 0

    for index = 1, codepoint_count, 1 do
        local codepoint = codepoints[ index ]
        if codepoint < 0x80 then
            if codepoint < 0 then
                return nil, "invalid code point exception occurred"
            end

            length = length + 1
            output[ length ] = basic_units[ codepoint ]
        elseif codepoint >= 0x7FFFFFFF or (strict and (codepoint > 0x10FFFF or (codepoint >= 0xD800 and codepoint <= 0xDFFF))) then
            return nil, "invalid code point exception occurred"
        else
            extended_count = extended_count + 1
            extended[ extended_count ] = codepoint
        end
    end

    local basic_length = codepoint_count - extended_count

    if extended_count ~= 0 then
        if basic_length ~= 0 then
            length = length + 1
            output[ length ] = basic_units[ 0x2D ]
        end

        -- First pass: find the delta of every non-basic code point in insertion order,
        -- deltas don't depend on the bias, so this loop stays free of inner loops.
        -- the smallest non-basic code point
        local upper_cp = 0x7FFFFFFF

        for i = 1, extended_count, 1 do
            upper_cp = math_min( upper_cp, extended[ i ] )
        end

        local lower_cp = 0x80
        local delta = 0

        local handled = basic_length

        while true do
            -- Increase `delta` enough to advance the decoder's <n,i> state to
            -- <m,0>, but guard against overflow.
            local handled_plus_one = handled + 1
            if (upper_cp - lower_cp) > math_floor( (0x7FFFFFFF - delta) / handled_plus_one ) then
                return nil, "overflow exception occurred"
            end

            delta = delta + (upper_cp - lower_cp) * handled_plus_one

            -- the next code point to insert is searched in the same pass,
            -- branchless since smaller and larger code points are interleaved randomly
            local next_cp = 0x7FFFFFFF

            for i = 1, codepoint_count, 1 do
                local codepoint = codepoints[ i ]
                if codepoint == upper_cp then
                    if delta > 0x7FFFFFFF then
                        return nil, "overflow exception occurred"
                    end

                    handled = handled + 1
                    deltas[ handled ] = delta
                    delta = 0
                else
                    -- `1` if `codepoint < upper_cp`, `0` otherwise
                    local is_lower = rbit_rshift( codepoint - upper_cp, 31 )
                    delta = delta + is_lower
                    next_cp = math_min( next_cp, codepoint + is_lower * 0x7FFFFFFF )
                end
            end

            if handled == codepoint_count then
                break
            end

            if delta >= 0x7FFFFFFF then
                return nil, "overflow exception occurred"
            end

            delta = delta + 1
            lower_cp = upper_cp + 1
            upper_cp = next_cp
        end

        -- Second pass: write every delta as a generalized variable-length integer.
        local bias = 0x48

        for index = basic_length + 1, codepoint_count, 1 do
            local q = deltas[ index ]
            local k = 0x24

            while true do
                local t

                if k <= bias then
                    t = 0x1
                elseif k >= (bias + 0x1A) then
                    t = 0x1A
                else
                    t = k - bias
                end

                if q < t then
                    break
                end

                local q_minus_t = q - t
                local base_minus_t = 0x24 - t

                length = length + 1
                output[ length ] = digit_units[ t + q_minus_t % base_minus_t ]

                q = math_floor( q_minus_t / base_minus_t )
                k = k + 0x24
            end

            length = length + 1
            output[ length ] = digit_units[ q ]

            -- adapt the bias
            delta = deltas[ index ]

            if index == basic_length + 1 then
                delta = math_floor( delta / 0x2BC )
            else
                delta = math_floor( delta * 0.5 )
            end

            delta = delta + math_floor( delta / index )
            k = 0

            while delta > 0x1C7 do
                delta = math_floor( delta / 0x23 )
                k = k + 0x24
            end

            bias = k + math_floor( 0x24 * delta / (delta + 0x26) )
        end
    elseif not ignore_prefix then
        -- basic labels are returned as is
        first = 5
    end

    if ffi_string == nil then
        return table_concat( output, "", first, length )
    end

    return ffi_string( output + first, length - first + 1 )
end

punycode.pack = punycode_pack

-- `punycode.unpack` over the bytes from `start_position` to `end_position`
local function unpack_range( punycode_str, start_position, end_position, ignore_prefix, lax )
    if start_position > end_position then
        return {}, 0
    end

    -- position of the byte before the encoded data
    local offset = start_position - 1

    if not ignore_prefix then
        if (end_position - start_position) >= 3 and has_prefix( punycode_str, start_position ) then
            offset = offset + 4
        else
            return utf8_unpack( punycode_str, start_position, end_position, lax )
        end
    end

    local str_length = end_position

    local strict = lax ~= true

    -- basic code points are everything before the last delimiter
    local basic = 0

    for j = str_length, offset + 1, -1 do
        if string_byte( punycode_str, j, j ) == 0x2D --[[ "-" ]] then
            basic = j - offset - 1
            break
        end
    end

    local codepoints, codepoint_count = {}, basic

    for j = 1, basic, 1 do
        local uint8 = string_byte( punycode_str, offset + j, offset + j )
        if strict and uint8 >= 0x80 then
            return nil, nil, "not basic exception occurred"
        end

        codepoints[ j ] = uint8
    end

    -- position of the last consumed byte
    local index = offset

    if basic ~= 0 then
        index = index + basic + 1
    end

    local unicode_init = 0x80
    local delta_init = 0
    local bias = 0x48

    while index < str_length do
        local oldi = delta_init
        local w = 1
        local k = 0x24

        ::punycode_decode_loop::

        if index >= str_length then
            return nil, nil, "invalid input exception occurred"
        end

        index = index + 1

        local digit = digit_values[ string_byte( punycode_str, index, index ) ]
        if digit == nil then
            return nil, nil, "invalid input exception occurred"
        end

        if digit > math_floor( (0x7FFFFFFF - delta_init) / w ) then
            return nil, nil, "overflow exception occurred"
        end

        delta_init = delta_init + digit * w

        local t

        if k > bias then
            if k < (bias + 0x1A) then
                t = k - bias
            else
                t = 0x1A
            end
        else
            t = 0x1
        end

        if digit >= t then
            local base_minus_t = 0x24 - t

            if w > math_floor( 0x7FFFFFFF / base_minus_t ) then
                return nil, nil, "overflow exception occurred"
            end

            w = w * base_minus_t
            k = k + 0x24

            goto punycode_decode_loop
        end

        local out = codepoint_count + 1
        local delta = delta_init - oldi

        if oldi == 0 then
            delta = math_floor( delta / 0x2BC )
        else
            delta = math_floor( delta * 0.5 )
        end

        delta = delta + math_floor( delta / out )
        k = 0

        while delta > 0x1C7 do
            delta = math_floor( delta / 0x23 )
            k = k + 0x24
        end

        bias = k + math_floor( 0x24 * delta / (delta + 0x26) )

        -- `delta_init` was supposed to wrap around from `out` to `0`,
        -- incrementing `unicode_init` each time, so we'll fix that now:
        local i_div_out = math_floor( delta_init / out )

        if i_div_out > (0x7FFFFFFF - unicode_init) then
            return nil, nil, "overflow exception occurred"
        end

        unicode_init = unicode_init + i_div_out
        delta_init = delta_init % out

        if strict and (unicode_init > 0x10FFFF or (unicode_init >= 0xD800 and unicode_init <= 0xDFFF)) then
            return nil, nil, "invalid code point exception occurred"
        end

        -- insert `unicode_init` at the 0-based position `delta_init`
        for temp = codepoint_count, delta_init + 1, -1 do
            codepoints[ temp + 1 ] = codepoints[ temp ]
        end

        delta_init = delta_init + 1
        codepoints[ delta_init ] = unicode_init
        codepoint_count = out
    end

    return codepoints, codepoint_count
end

--- [SHARED AND MENU]
---
--- Decodes a single Punycode label into Unicode code points.
---
--- Unless `ignore_prefix` is `true`, the label must start with the `"xn--"` prefix
--- (case-insensitive), a label without it is treated as plain UTF-8 and returned as is.
---
--- Encoded digits are case-insensitive, basic code points are copied without case changes.
---
--- ```lua
--- punycode.unpack( "xn--mnchen-3ya" ) -- { 0x6D, 0xFC, 0x6E, 0x63, 0x68, 0x65, 0x6E }, 7
--- punycode.unpack( "mnchen-3ya", true ) -- { 0x6D, 0xFC, 0x6E, 0x63, 0x68, 0x65, 0x6E }, 7
--- punycode.unpack( "xn--b" ) -- nil, nil, "invalid input exception occurred"
--- ```
---
--- Invalid UTF-8 in a label without the prefix raises an error, unless `lax` is `true`.
---
---@param punycode_str string The Punycode label to decode.
---@param ignore_prefix? boolean If `true`, `punycode_str` is decoded as Punycode without looking for the `"xn--"` prefix.
---@param lax? boolean If `true`, non-ASCII bytes before the delimiter, surrogates and code points above U+10FFFF are accepted instead of being rejected.
---@return integer[] | nil codepoints The decoded code points, `nil` if an error occurred.
---@return integer | nil codepoint_count The number of decoded code points, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
---@nodiscard
function punycode.unpack( punycode_str, ignore_prefix, lax )
    return unpack_range( punycode_str, 1, string_len( punycode_str ), ignore_prefix, lax )
end

--- [SHARED AND MENU]
---
--- Encodes a UTF-8 domain name into its ASCII (Punycode) form.
---
--- The string is split on `"."` and every label containing non-ASCII characters is
--- encoded with `punycode.pack`, ASCII-only labels and empty labels are left untouched.
---
--- ```lua
--- punycode.encode( "münchen.de" ) -- "xn--mnchen-3ya.de"
--- punycode.encode( "bücher.example.рф" ) -- "xn--bcher-kva.example.xn--p1ai"
--- punycode.encode( "münchen.de", true ) -- "mnchen-3ya.de"
--- ```
---
--- Invalid UTF-8 raises an error, unless `lax` is `true`.
---
---@param str string The UTF-8 domain name to encode.
---@param ignore_prefix? boolean If `true`, encoded labels are not prefixed with `"xn--"`.
---@param start_position? integer The position to start from in bytes, negative values count from the end.
---@param end_position? integer The position to end at in bytes, negative values count from the end.
---@param lax? boolean If `true`, invalid UTF-8 sequences become U+FFFD and surrogates are encoded as well instead of being rejected.
---@return string | nil punycode_str The encoded domain name, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
---@nodiscard
function punycode.encode( str, ignore_prefix, start_position, end_position, lax )
    local start_index, end_index = math_range( string_len( str ), start_position, end_position )
    if start_index > end_index then
        return "", nil
    end

    -- ASCII-only domains are returned as is
    if is_ascii( str, start_index, end_index ) then
        return string_sub( str, start_index, end_index ), nil
    end

    local labels, label_count = {}, 0
    local label_start, label_ascii = start_index, true

    for position = start_index, end_index + 1, 1 do
        local uint8 = position <= end_index and string_byte( str, position, position ) or 0x2E --[[ "." ]]

        if uint8 == 0x2E --[[ "." ]] then
            label_count = label_count + 1

            -- ASCII-only labels are kept as is
            if label_ascii then
                labels[ label_count ] = string_sub( str, label_start, position - 1 )
            else
                local codepoints, codepoint_count = utf8_unpack( str, label_start, position - 1, lax )

                local punycode_str, err_msg = punycode_pack( codepoints, codepoint_count, ignore_prefix, lax )
                if punycode_str == nil then
                    return nil, err_msg
                end

                labels[ label_count ] = punycode_str
            end

            label_start, label_ascii = position + 1, true
        elseif uint8 >= 0x80 then
            label_ascii = false
        end
    end

    if label_count == 2 then
        return labels[ 1 ] .. "." .. labels[ 2 ], nil
    else
        return table_concat( labels, ".", 1, label_count ), nil
    end
end

--- [SHARED AND MENU]
---
--- Decodes an ASCII (Punycode) domain name into UTF-8.
---
--- The string is split on `"."` and every label starting with `"xn--"` (case-insensitive)
--- is decoded with `punycode.unpack`, other labels are left untouched.
---
--- ```lua
--- punycode.decode( "xn--mnchen-3ya.de" ) -- "münchen.de"
--- punycode.decode( "mnchen-3ya", true ) -- "münchen"
--- punycode.decode( "xn--b.de" ) -- nil, "invalid input exception occurred"
--- ```
---
--- Invalid UTF-8 in labels without the prefix raises an error, unless `lax` is `true`.
---
---@param punycode_str string The domain name to decode.
---@param ignore_prefix? boolean If `true`, every label is decoded as Punycode without looking for the `"xn--"` prefix.
---@param start_position? integer The position to start from in bytes, negative values count from the end.
---@param end_position? integer The position to end at in bytes, negative values count from the end.
---@param lax? boolean If `true`, malformed labels are decoded leniently and invalid code points become U+FFFD instead of being rejected.
---@return string | nil str The decoded UTF-8 domain name, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
---@nodiscard
function punycode.decode( punycode_str, ignore_prefix, start_position, end_position, lax )
    local start_index, end_index = math_range( string_len( punycode_str ), start_position, end_position )
    if start_index > end_index then
        return "", nil
    end

    -- ASCII-only domains without encoded labels are returned as is
    if not ignore_prefix and is_plain( punycode_str, start_index, end_index ) then
        return string_sub( punycode_str, start_index, end_index ), nil
    end

    local labels, label_count = {}, 0
    local label_start, label_plain = start_index, not ignore_prefix

    for position = start_index, end_index + 1, 1 do
        local uint8 = position <= end_index and string_byte( punycode_str, position, position ) or 0x2E --[[ "." ]]

        if uint8 == 0x2E --[[ "." ]] then
            label_count = label_count + 1

            -- ASCII-only labels without the prefix are kept as is
            if label_plain then
                labels[ label_count ] = string_sub( punycode_str, label_start, position - 1 )
            else
                local codepoints, codepoint_count, err_msg = unpack_range( punycode_str, label_start, position - 1, ignore_prefix, lax )
                if codepoints == nil then
                    return nil, err_msg
                end

                labels[ label_count ] = utf8_pack( codepoints, codepoint_count, lax )
            end

            label_start, label_plain = position + 1, not ignore_prefix
        elseif uint8 >= 0x80 then
            label_plain = false
        elseif position == label_start and position + 3 <= end_index and has_prefix( punycode_str, position ) then
            label_plain = false
        end
    end

    if label_count == 2 then
        return labels[ 1 ] .. "." .. labels[ 2 ], nil
    end

    return table_concat( labels, ".", 1, label_count ), nil
end
