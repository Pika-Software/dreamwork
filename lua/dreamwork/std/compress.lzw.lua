--[[
    Original library was made by Rochet2
    https://github.com/Rochet2/lualzw

    Edit by Unknown Developer
]]

local std = dreamwork.std
local string = std.string

local string_char, string_byte = string.char, string.byte
local string_sub = string.sub
local string_len = string.len

local table_concat = std.table.concat

---@class dreamwork.std.compress
local compress = std.compress

--- [SHARED AND MENU]
---
--- A lzw library.
---
---@class dreamwork.std.compress.lzw
local lzw = compress.lzw or {}
compress.lzw = lzw

local basedictcompress = {}
local basedictdecompress = {}

for i = 0, 255 do
    local ic, iic = string_char( i ), string_char( i, 0 )
    basedictcompress[ ic ], basedictdecompress[ iic ] = iic, ic
end

--- [SHARED AND MENU]
---
--- Compresses a string using LZW compression.
---
---@param raw_data string The string to compress.
---@param forced? boolean If `true`, compression will ignore the excess length of compressed data relative to uncompressed data.
---@return string | nil compressed_data The compressed string or `nil` if the compression fails.
---@return nil | string error_message The error message or `nil` if the compression succeeds.
function lzw.compress( raw_data, forced )
    local data_length = string_len( raw_data )
    if data_length == 0 then
        return nil, "compressed string cannot be empty"
    elseif data_length == 1 then
        return nil, "compressed string cannot be so short"
    end

    local parts, part_count = {}, 0
    forced = forced == true

    local parts_length
    if not forced then
        parts_length = 1
    end

    local dictionary = {}
    local a, b = 0, 1
    local word = ""

    for i = 1, data_length, 1 do
        local char = string_sub( raw_data, i, i )

        local new_word = word .. char
        if basedictcompress[ new_word ] or dictionary[ new_word ] then
            word = new_word
        else
            local str = basedictcompress[ word ] or dictionary[ word ]
            if str == nil then
                return nil, "algorithm error, could not fetch word"
            end

            if not forced then
                parts_length = parts_length + string_len( str )

                if data_length <= parts_length then
                    return nil, "compressed data length exceeds uncompressed"
                end
            end

            part_count = part_count + 1
            parts[ part_count ] = str

            word = char

            if a >= 256 then
                a, b = 0, b + 1
                if b >= 256 then
                    dictionary, b = {}, 1
                end
            end

            dictionary[ new_word ] = string_char( a, b )
            a = a + 1
        end
    end

    local str = basedictcompress[ word ] or dictionary[ word ]

    if not forced then
        parts_length = parts_length + string_len( str )

        if data_length < parts_length then
            return nil, "compressed data length exceeds uncompressed"
        elseif data_length == parts_length then
            return nil, "compressed data length equal to uncompressed"
        end
    end

    part_count = part_count + 1
    parts[ part_count ] = str

    return table_concat( parts, "", 1, part_count )
end

--- [SHARED AND MENU]
---
--- Decompresses a string using LZW compression.
---
---@param encoded_data string The string to decompress.
---@return string | nil decompressed_data The decompressed string or `nil` if the decompression fails.
---@return nil | string error_message The error message or `nil` if the decompression succeeds.
function lzw.decompress( encoded_data )
    if string_byte( encoded_data, 1, 1 ) == nil then
        return nil, "compressed string cannot be empty"
    end

    local data_length = string_len( encoded_data )
    if data_length < 2 then
        return nil, "compressed string cannot be so short"
    end

    local parts, part_count = {}, 0
    local last = string_sub( encoded_data, 1, 2 )

    local dictionary = {}
    local a, b = 0, 1

    part_count = part_count + 1
    parts[ part_count ] = basedictdecompress[ last ] or dictionary[ last ]

    for i = 3, data_length, 2 do
        local code = string_sub( encoded_data, i, i + 1 )

        local last_string = basedictdecompress[ last ] or dictionary[ last ]
        if last_string == nil then
            return nil, "could not find last from dictionary. Invalid input?"
        end

        last = code
        local str

        local new_string = basedictdecompress[ code ] or dictionary[ code ]
        if new_string == nil then
            str = last_string .. string_sub( last_string, 1, 1 )
            part_count = part_count + 1
            parts[ part_count ] = str
        else
            part_count = part_count + 1
            parts[ part_count ] = new_string
            str = last_string .. string_sub( new_string, 1, 1 )
        end

        if a >= 256 then
            a, b = 0, b + 1

            if b >= 256 then
                dictionary, b = {}, 1
            end
        end

        dictionary[ string_char( a, b ) ] = str
        a = a + 1
    end

    return table_concat( parts, "", 1, part_count )
end
