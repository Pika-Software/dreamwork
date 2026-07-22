---@class dreamwork.std
local std = dreamwork.std

local table = std.table
local table_concat = table.concat

local string = std.string
local string_sub = string.sub
local string_len = string.len
local string_char, string_byte = string.char, string.byte

--- [SHARED AND MENU]
---
--- Lempel–Ziv–Welch (LZW) is a universal lossless compression algorithm created by Abraham Lempel, Jacob Ziv, and Terry Welch.
---
--- [Source Code](https://github.com/Rochet2/lualzw)
---
--- Author: [Rochet2](https://github.com/Rochet2)
---
--- Edited by Unknown Developer
---
---@class dreamwork.std.lzw
local lzw = {}
std.lzw = lzw

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
---@param forced? boolean If `true`, compression will ignore the excess length of compressed data relative to uncompressed data. By default: `true`
---@return string | nil compressed_data The compressed string or `nil` if the compression fails.
---@return nil | string error_message The error message or `nil` if the compression succeeds.
function lzw.compress( raw_data, forced )
    local data_length = string_len( raw_data )
    if data_length == 0 then
        return nil, "compressed string cannot be empty"
    elseif data_length == 1 then
        return nil, "compressed string cannot be so short"
    end

    forced = forced ~= false

    ---@type string[]
    local parts = {}

    ---@type integer
    local part_count = 0

    ---@type integer | nil
    local parts_length

    if not forced then
        parts_length = 1
    end

    ---@type table<string, string>
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

    if forced then
        part_count = part_count + 1
        parts[ part_count ] = basedictcompress[ word ] or dictionary[ word ]
    else
        local str = basedictcompress[ word ] or dictionary[ word ]
        parts_length = parts_length + string_len( str )

        if data_length < parts_length then
            return nil, "compressed data length exceeds uncompressed"
        elseif data_length == parts_length then
            return nil, "compressed data length equal to uncompressed"
        end

        part_count = part_count + 1
        parts[ part_count ] = str
    end

    if part_count == 1 then
        return parts[ 1 ]
    elseif part_count == 2 then
        return parts[ 1 ] .. parts[ 2 ]
    else
        return table_concat( parts, "", 1, part_count )
    end
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
    elseif data_length % 2 ~= 0 then
        return nil, "corrupt compressed data: odd length"
    end

    ---@type string[]
    local parts = {}

    ---@type integer
    local part_count = 0

    local last = string_sub( encoded_data, 1, 2 )

    ---@type table<string, string>
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
