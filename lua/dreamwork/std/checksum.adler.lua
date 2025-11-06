local std = _G.dreamwork.std
---@class dreamwork.std.checksum
local checksum = std.checksum

local string = std.string
local string_len = string.len
local string_byte = string.byte

--- [SHARED AND MENU]
---
--- Calculate the Adler-32 checksum of the string.
---
--- See RFC1950 Page 9 https://tools.ietf.org/html/rfc1950 for the definition of Adler-32 checksum.
---
---@param str string The string used to calculate the Adler-32 checksum.
---@return integer checksum The Adler-32 checksum, which is greater or equal to 0, and less than 2^32 (0x100000000).
function checksum.adler32( str )
    local str_length = string_len( str )
    local index = str_length % 16
    local a, b = 1, 0

    if index ~= 0 then
        if index == 1 then
            a = ( a + string_byte( str, 1, index ) ) % 65521
            b = ( b + a ) % 65521
        elseif index == 2 then
            local x1, x2 = string_byte( str, 1, index )
            b = ( b + 2 * a + 2 * x1 + x2 ) % 65521
            a = ( a + x1 + x2 ) % 65521
        elseif index == 3 then
            local x1, x2, x3 = string_byte( str, 1, index )
            b = ( b + 3 * a + 3 * x1 + 2 * x2 + x3 ) % 65521
            a = ( a + x1 + x2 + x3 ) % 65521
        elseif index == 4 then
            local x1, x2, x3, x4 = string_byte( str, 1, index )
            b = ( b + 4 * a + 4 * x1 + 3 * x2 + 2 * x3 + x4 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 ) % 65521
        elseif index == 5 then
            local x1, x2, x3, x4, x5 = string_byte( str, 1, index )
            b = ( b + 5 * a + 5 * x1 + 4 * x2 + 3 * x3 + 2 * x4 + x5 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 ) % 65521
        elseif index == 6 then
            local x1, x2, x3, x4, x5, x6 = string_byte( str, 1, index )
            b = ( b + 6 * a + 6 * x1 + 5 * x2 + 4 * x3 + 3 * x4 + 2 * x5 + x6 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 ) % 65521
        elseif index == 7 then
            local x1, x2, x3, x4, x5, x6, x7 = string_byte( str, 1, index )
            b = ( b + 7 * a + 7 * x1 + 6 * x2 + 5 * x3 + 4 * x4 + 3 * x5 + 2 * x6 + x7 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 ) % 65521
        elseif index == 8 then
            local x1, x2, x3, x4, x5, x6, x7, x8 = string_byte( str, 1, index )
            b = ( b + 8 * a + 8 * x1 + 7 * x2 + 6 * x3 + 5 * x4 + 4 * x5 + 3 * x6 + 2 * x7 + x8 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 ) % 65521
        elseif index == 9 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9 = string_byte( str, 1, index )
            b = ( b + 9 * a + 9 * x1 + 8 * x2 + 7 * x3 + 6 * x4 + 5 * x5 + 4 * x6 + 3 * x7 + 2 * x8 + x9 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 ) % 65521
        elseif index == 10 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10 = string_byte( str, 1, index )
            b = ( b + 10 * a + 10 * x1 + 9 * x2 + 8 * x3 + 7 * x4 + 6 * x5 + 5 * x6 + 4 * x7 + 3 * x8 + 2 * x9 + x10 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 ) % 65521
        elseif index == 11 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11 = string_byte( str, 1, index )
            b = ( b + 11 * a + 11 * x1 + 10 * x2 + 9 * x3 + 8 * x4 + 7 * x5 + 6 * x6 + 5 * x7 + 4 * x8 + 3 * x9 + 2 * x10 + x11 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 ) % 65521
        elseif index == 12 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12 = string_byte( str, 1, index )
            b = ( b + 12 * a + 12 * x1 + 11 * x2 + 10 * x3 + 9 * x4 + 8 * x5 + 7 * x6 + 6 * x7 + 5 * x8 + 4 * x9 + 3 * x10 + 2 * x11 + x12 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 ) % 65521
        elseif index == 13 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13 = string_byte( str, 1, index )
            b = ( b + 13 * a + 13 * x1 + 12 * x2 + 11 * x3 + 10 * x4 + 9 * x5 + 8 * x6 + 7 * x7 + 6 * x8 + 5 * x9 + 4 * x10 + 3 * x11 + 2 * x12 + x13 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 ) % 65521
        elseif index == 14 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14 = string_byte( str, 1, index )
            b = ( b + 14 * a + 14 * x1 + 13 * x2 + 12 * x3 + 11 * x4 + 10 * x5 + 9 * x6 + 8 * x7 + 7 * x8 + 6 * x9 + 5 * x10 + 4 * x11 + 3 * x12 + 2 * x13 + x14 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 ) % 65521
        elseif index == 15 then
            local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 = string_byte( str, 1, index )
            b = ( b + 15 * a + 15 * x1 + 14 * x2 + 13 * x3 + 12 * x4 + 11 * x5 + 10 * x6 + 9 * x7 + 8 * x8 + 7 * x9 + 6 * x10 + 5 * x11 + 4 * x12 + 3 * x13 + 2 * x14 + x15 ) % 65521
            a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15 ) % 65521
        end
    end

    index = index + 1

    while ( index <= str_length - 15 ) do
        local x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16 = string_byte( str, index, index + 15 )
        b = ( b + 16 * a + 16 * x1 + 15 * x2 + 14 * x3 + 13 * x4 + 12 * x5 + 11 * x6 + 10 * x7 + 9 * x8 + 8 * x9 + 7 * x10 + 6 * x11 + 5 * x12 + 4 * x13 + 3 * x14 + 2 * x15 + x16 ) % 65521
        a = ( a + x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13 + x14 + x15 + x16 ) % 65521
        index = index + 16
    end

    return ( b * 0x10000 + a ) % 0x100000000
end
