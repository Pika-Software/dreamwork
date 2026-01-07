--[[

    Based on https://github.com/nmap/nmap/blob/master/nselib/punycode.lua <3

--]]

local std = _G.dreamwork.std
---@class dreamwork.std.encoding
local encoding = std.encoding

local string = std.string
local string_len = string.len
local string_byte = string.byte
local string_char = string.char

local math_floor = std.math.floor

local table = std.table
local table_concat = table.concat
local table_insert = table.insert

local utf8 = std.encoding.utf8
local utf8_unpack = utf8.unpack
local utf8_pack = utf8.pack

--- [SHARED AND MENU]
---
--- Punycode encoding/decoding library.
---
--- See https://en.wikipedia.org/wiki/Punycode
---
--- RFC 3492: https://datatracker.ietf.org/doc/html/rfc3492
---
---@class dreamwork.std.encoding.punycode
local punycode = encoding.punycode or {}
encoding.punycode = punycode

-- TODO: rewrite with by byte analysis

--- [SHARED AND MENU]
---
--- Encodes a UTF-8 string into Punycode.
---
---@param codepoints dreamwork.std.encoding.utf8.Sequence The code points to encode.
---@param codepoint_count? integer The number of code points to encode.
---@param ignore_prefix? boolean If `true`, the prefix `"xn--"` will be ignored.
---@param lax? boolean `true` if lax mode should be used in UTF-8 encoding/decoding.
---@return string | nil punycode_str The Punycode string, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
local function pack( codepoints, codepoint_count, ignore_prefix, lax )
    if codepoint_count == nil then
        codepoint_count = #codepoints
    end

    local segments, segment_count = {}, 0

    for index = 1, codepoint_count, 1 do
        local codepoint = codepoints[ index ]
        if codepoint < 0x80 then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_char( codepoint )
        end
    end

    if segment_count == codepoint_count then
        return utf8_pack( codepoints, codepoint_count, lax )
    end

    local basic_length = segment_count
    if basic_length ~= 0 then
        segment_count = segment_count + 1
        segments[ segment_count ] = "-"
    end

    if not ignore_prefix then
        table_insert( segments, 1, "xn--" )
        segment_count = segment_count + 1
    end

    local lower_cp = 0x80
    local bias = 0x48
    local delta = 0

    local handled = basic_length

    while handled < codepoint_count do
        local upper_cp = 0x7FFFFFFF

        for i = 1, codepoint_count, 1 do
            local codepoint = codepoints[ i ]
            if codepoint >= lower_cp and codepoint < upper_cp then
                upper_cp = codepoint
            end
        end

        -- Increase `delta` enough to advance the decoder's <n,i> state to
        -- <m,0>, but guard against overflow.
        local handled_plus_one = handled + 1
        if ( upper_cp - lower_cp ) > math_floor( ( 0x7FFFFFFF - delta ) / handled_plus_one ) then
            return nil, "overflow exception occurred"
        end

        delta = delta + ( upper_cp - lower_cp ) * handled_plus_one
        lower_cp = upper_cp

        for i = 1, codepoint_count, 1 do
            local codepoint = codepoints[ i ]
            if codepoint < lower_cp then
                delta = delta + 1

                if delta > 0x7FFFFFFF then
                    return nil, "overflow exception occurred"
                end
            elseif codepoint == lower_cp then
                -- Represent delta as a generalized variable-length integer.
                local q = delta
                local k = 0x24

                while true do
                    local t

                    if k <= bias then
                        t = 0x1
                    elseif k >= ( bias + 0x1A ) then
                        t = 0x1A
                    else
                        t = k - bias
                    end

                    if q < t then
                        break
                    end

                    local q_minus_t = q - t
                    local base_minus_t = 0x24 - t

                    local digit = t + q_minus_t % base_minus_t

                    if digit < 26 then
                        digit = digit + 75
                    end

                    digit = digit + 22

                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_char( digit )

                    q = math_floor( q_minus_t / base_minus_t )
                    k = k + 0x24
                end

                local digit = q

                if digit < 26 then
                    digit = digit + 75
                end

                digit = digit + 22

                segment_count = segment_count + 1
                segments[ segment_count ] = string_char( digit )

                if handled == basic_length then
                    delta = math_floor( delta / 0x2BC )
                else
                    delta = math_floor( delta * 0.5 )
                end

                delta = delta + math_floor( delta / handled_plus_one )
                k = 0

                while delta > 0x1C7 do
                    delta = math_floor( delta / 0x23 )
                    k = k + 0x24
                end

                bias = k + math_floor( 0x24 * delta / ( delta + 0x26 ) )
                handled = handled + 1
                delta = 0
            end
        end

        delta = delta + 1
        lower_cp = lower_cp + 1
    end

    return table_concat( segments, "", 1, segment_count )
end

punycode.pack = pack

local unpack
do

    local string_sub = string.sub

    --- [SHARED AND MENU]
    ---
    --- Unpacks a Punycode string.
    ---
    ---@param punycode_str string The Punycode string to unpack.
    ---@param ignore_prefix? boolean If `true`, the prefix `"xn--"` will be ignored.
    ---@param lax? boolean `true` if lax mode should be used in UTF-8 encoding/decoding.
    ---@return dreamwork.std.encoding.utf8.Sequence | nil codepoints The codepoints of the unpacked string, `nil` if an error occurred.
    ---@return integer | nil codepoint_count The number of codepoints in the string, `nil` if an error occurred.
    ---@return nil | string err_msg The error message, `nil` if no error occurred.
    function unpack( punycode_str, ignore_prefix, lax )
        if not ignore_prefix then
            local uint8_1, uint8_2, uint8_3, uint8_4 = string_byte( punycode_str, 1, 4 )
            if uint8_1 == nil then
                return nil, nil, "punycode string cannot be empty"
            end

            if uint8_1 == 0x78 --[[ "x" ]] and uint8_2 == 0x6E --[[ "n" ]] and uint8_3 == 0x2D --[[ "-" ]] and uint8_4 == 0x2D --[[ "-" ]] then
                punycode_str = string_sub( punycode_str, 5 )
            else
                return utf8_unpack( punycode_str, 1, string_len( punycode_str ), lax )
            end
        end

        local punycode_str_length = string_len( punycode_str )

        local basic = 0

        for j = 1, punycode_str_length do
            if string_byte( punycode_str, j, j ) == 0x2D --[[ "-" ]] then
                basic = j - 1
            end
        end

        local codepoints, codepoint_count = {}, 0

        for j = 1, basic, 1 do
            local uint8 = string_byte( punycode_str, j, j )
            if uint8 < 0x80 then
                codepoint_count = codepoint_count + 1
                codepoints[ codepoint_count ] = uint8
            else
                return nil, nil, "not basic exception occurred"
            end
        end

        local index

        if basic == 0 then
            index = 0
        else
            index = basic + 1
        end

        local unicode_init = 0x80
        local delta_init = 0
        local bias = 0x48

        while index < punycode_str_length do
            local oldi = delta_init
            local w = 1
            local k = 0x24

            while true do
                if index >= punycode_str_length then
                    return nil, nil, "invalid input exception occurred"
                end

                index = index + 1

                local digit = string_byte( punycode_str, index, index )

                if digit < 0x3A then
                    digit = digit - 0x16
                elseif digit < 0x5B then
                    digit = digit - 0x41
                elseif digit < 0x7B then
                    digit = digit - 0x61
                else
                    digit = 0x24
                end

                if digit >= 0x24 or digit > math_floor( ( 0x7FFFFFFF - delta_init ) / w ) then
                    return nil, nil, "overflow exception occurred"
                end

                delta_init = delta_init + digit * w

                local t
                if k > bias then
                    if k < ( bias + 0x1A ) then
                        t = k - bias
                    else
                        t = 0x1A
                    end
                else
                    t = 0x1
                end

                if digit < t then
                    break
                end

                local base_minus_t = 0x24 - t

                if w > math_floor( 0x7FFFFFFF / base_minus_t ) then
                    return nil, nil, "overflow exception occurred"
                end

                w = w * base_minus_t
                k = k + 0x24
            end

            codepoint_count = #codepoints

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

            bias = k + math_floor( 0x24 * delta / ( delta + 0x26 ) )

            -- `delta_init` was supposed to wrap around from `out` to `0`,
            -- incrementing `unicode_init` each time, so we'll fix that now:
            local i_div_out = math_floor( delta_init / out )

            if i_div_out > ( 0x7FFFFFFF - unicode_init ) then
                return nil, nil, "overflow exception occurred"
            end

            unicode_init = unicode_init + i_div_out
            delta_init = delta_init % out

            for temp = codepoint_count, delta_init, -1 do
                codepoints[ temp + 1 ] = codepoints[ temp ]
            end

            delta_init = delta_init + 1
            codepoints[ delta_init ] = unicode_init
        end

        return codepoints, #codepoints
    end

end

punycode.unpack = unpack

--- [SHARED AND MENU]
---
--- Encodes a string into a Punycode string.
---
---@param str string The string to encode.
---@param ignore_prefix? boolean If `true`, the prefix `"xn--"` will be ignored.
---@param start_position? integer The position to start from in bytes.
---@param end_position? integer The position to end at in bytes.
---@param lax? boolean `true` if lax mode should be used in UTF-8 encoding/decoding.
---@return string | nil punycode_str The Punycode string, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
function punycode.encode( str, ignore_prefix, start_position, end_position, lax )
    local codepoints, codepoint_count = utf8_unpack( str, start_position, end_position, lax )
    return pack( codepoints, codepoint_count, ignore_prefix, lax )
end

--- [SHARED AND MENU]
---
--- Decodes a Punycode string into a string.
---
---@param punycode_str string The Punycode string to decode.
---@param ignore_prefix? boolean If `true`, the prefix `"xn--"` will be ignored.
---@param lax? boolean `true` if lax mode should be used in UTF-8 encoding/decoding.
---@return string | nil str The decoded string, `nil` if an error occurred.
---@return nil | string err_msg The error message, `nil` if no error occurred.
function punycode.decode( punycode_str, ignore_prefix, lax )
    local codepoints, codepoint_count, err_msg = unpack( punycode_str, ignore_prefix, lax )
    if codepoints == nil then
        return nil, err_msg
    else
        return utf8_pack( codepoints, codepoint_count, lax )
    end
end
