---@class dreamwork.std
local std = _G.dreamwork.std

local string = std.string
local table = std.table

local string_sub, string_gsub = string.sub, string.gsub
local string_byteSplit = string.byteSplit
local string_byte = string.byte
local string_len = string.len

local table_insert, table_remove = table.insert, table.remove
local table_concat = table.concat

--- [SHARED AND MENU]
---
--- The file path library.
---
---@class dreamwork.std.path
---@field delimiter string The path delimiter.
---@field sep string The path separator.
local path = std.path or {}
std.path = path

path.delimiter = ":"
path.sep = "/"

--- [SHARED AND MENU]
---
--- Check to see if the file path is absolute.
---
---@param file_path string The file path.
---@return boolean is_abs `true` if the file path is absolute, `false` otherwise.
function path.isAbsolute( file_path )
    return string_byte( file_path, 1 ) == 0x2F --[[ / ]]
end

--- [SHARED AND MENU]
---
--- Check to see if the file path is relative.
---
---@param file_path string The file path.
---@return boolean is_rel `true` if the file path is relative, `false` otherwise.
function path.isRelative( file_path )
    return string_byte( file_path, 1 ) ~= 0x2F --[[ / ]]
end

local equals

if std.WINDOWS or std.OSX then

    local string_lower = string.lower

    --- [SHARED AND MENU]
    ---
    --- Check to see if the paths are equal.
    ---
    ---@param file_path1 string The first file path.
    ---@param file_path2 string The second file path.
    ---@return boolean is_equal `true` if the paths are equal, `false` otherwise.
    function equals( file_path1, file_path2 )
        return string_lower( file_path1 ) == string_lower( file_path2 )
    end

else

    --- [SHARED AND MENU]
    ---
    --- Check to see if the paths are equal.
    ---
    ---@param file_path1 string The first file path.
    ---@param file_path2 string The second file path.
    ---@return boolean is_equal `true` if the paths are equal, `false` otherwise.
    function equals( file_path1, file_path2 )
        return file_path1 == file_path2
    end

end

path.equals = equals

--- [SHARED AND MENU]
---
--- Get the name of the file path.
---
---@param file_path string The file path.
---@param keep_extension? boolean `true` to keep the extension, `false` otherwise
---@return string file_name The name of the file.
function path.getName( file_path, keep_extension )
    if keep_extension then
        for index = string_len( file_path ), 1, -1 do
            if string_byte( file_path, index ) == 0x2F --[[ / ]] then
                return string_sub( file_path, index + 1 )
            end
        end

        return file_path
    end

    local dot_position

    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2E --[[ . ]] then
            if dot_position == nil then
                dot_position = index
            end
        elseif byte == 0x2F --[[ / ]] then
            if dot_position == nil then
                return string_sub( file_path, index + 1 )
            else
                return string_sub( file_path, index + 1, dot_position - 1 )
            end
        end
    end

    if dot_position == nil then
        return file_path
    else
        return string_sub( file_path, 1, dot_position - 1 )
    end
end

--- [SHARED AND MENU]
---
--- Get the directory of the file path.
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string | nil directory The directory of the file, or `nil` if the file path is invalid.
local function getDirectory( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            if not keep_trailing_slash then
                index = index - 1
            end

            return string_sub( file_path, 1, index )
        end
    end
end

path.getDirectory = getDirectory

--- [SHARED AND MENU]
---
--- Get the extension of the file path.
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the dot, `false` otherwise.
---@return string extension The extension of the file.
function path.getExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            break
        elseif byte == 0x2E --[[ . ]] then
            if not keep_dot then
                index = index + 1
            end

            return string_sub( file_path, index )
        end
    end

    return ""
end

--- [SHARED AND MENU]
---
--- Split a file path into a directory and a file name.
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string directory_path The directory from the file path.
---@return string file_name The file from the file path.
local function split( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            return string_sub( file_path, 1, keep_trailing_slash and index or ( index - 1 ) ), string_sub( file_path, index + 1 )
        end
    end

    return "", file_path
end

path.split = split

--- [SHARED AND MENU]
---
--- Split a file path into a file name and an extension.
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the extension dot, `false` otherwise.
---@return string file_name The file name from the file path.
---@return string extension The extension from the file path.
local function splitExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local byte = string_byte( file_path, index )
        if byte == 0x2F --[[ / ]] then
            return file_path, ""
        elseif byte == 0x2E --[[ . ]] then
            return string_sub( file_path, 1, index - 1 ), string_sub( file_path, keep_dot and index or ( index + 1 ) )
        end
    end

    return file_path, ""
end

path.splitExtension = splitExtension

--- [SHARED AND MENU]
---
--- Replaces the file name in the file path.
---
---@param file_path string The file path.
---@param file_name string The new file name.
---@return string new_file_path The new file path.
function path.replaceName( file_path, file_name )
    return split( file_path, true ) .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the directory in the file path.
---
---@param file_path string The file path.
---@param dir_name string The new directory.
---@return string new_file_path The new file path.
function path.replaceDirectory( file_path, dir_name )
    if string_byte( dir_name, string_len( dir_name ) ) ~= 0x2F --[[ / ]] then
        dir_name = dir_name .. "/"
    end

    local _, file_name = split( file_path, false )
    return dir_name .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the extension in the file path.
---
---@param file_path string The file path.
---@param ext_name string The new extension.
---@return string new_file_path The new file path.
function path.replaceExtension( file_path, ext_name )
    return splitExtension( file_path, false ) .. "." .. ext_name
end

--- [SHARED AND MENU]
---
--- Strips the trailing slash from the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripTrailingSlash( file_path )
    file_path = string_gsub( file_path, "[/\\]+$", "" )
    return file_path
end

--- [SHARED AND MENU]
---
--- Ensures the file path has a trailing slash.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.ensureTrailingSlash( file_path )
    if string_byte( file_path, string_len( file_path ) ) == 0x2F --[[ / ]] then
        return file_path
    else
        return file_path .. "/"
    end
end

--- [SHARED AND MENU]
---
--- Strips the leading slash from the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripLeadingSlash( file_path )
    file_path = string_gsub( file_path, "^[/\\]+", "" )
    return file_path
end

--- [SHARED AND MENU]
---
--- Ensures the file path has a leading slash.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.ensureLeadingSlash( file_path )
    if string_byte( file_path, 1 ) == 0x2F --[[ / ]] then
        return file_path
    else
        return "/" .. file_path
    end
end

--- [SHARED AND MENU]
---
--- Normalizes the slashes in the file path.
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.normalizeSlashes( file_path )
    file_path = string_gsub( file_path, "[/\\]+", "/" )
    return file_path
end

--- [SHARED AND MENU]
---
--- Parse a file path into [root, dir, basename, ext, name, abs] table.
---
---     ┌─────────────────────┬────────────┐
---     │          dir        │    base    │
---     ├──────┬              ├──────┬─────┤
---     │ root │              │ name │ ext │
---     "  /    home/user/dir/  file  .txt "
---     └──────┴──────────────┴──────┴─────┘
--- (All spaces in the "" line should be ignored. They are purely for formatting.)
---
---@param file_path string The file path.
---@return dreamwork.std.path.Data data The parsed file path data.
function path.parse( file_path )
    local is_abs = string_byte( file_path, 1 ) == 0x2F --[[ / ]]
    local directory, base = split( file_path, true )
    local name, ext = splitExtension( base, true )

    return { root = is_abs and "/" or "", dir = directory, base = base, ext = ext, name = name, abs = is_abs }
end

local getCurrentDirectory
do

    local debug = std.debug
    local debug_getfmain = debug.getfmain
    local debug_getfpath = debug.getfpath

    --- [SHARED AND MENU]
    ---
    --- Get the current file path.
    ---
    ---@param level? integer The stack level to get the file path from.
    ---@return string file_path
    function path.getCurrentFile( level )
        local fn = debug_getfmain( ( level or 1 ) + 1 )
        if fn == nil then
            return "/unknown.lua"
        end

        local fenv = getfenv( fn )
        if fenv ~= nil then
            local file_path = fenv.__filename
            if file_path ~= nil then
                return file_path
            end
        end

        return debug_getfpath( fn ) or "/unknown.lua"
    end

    --- [SHARED AND MENU]
    ---
    --- Get the current directory path.
    ---
    ---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
    ---@param level? integer The stack level to get the file path from.
    ---@return string directory_path
    function getCurrentDirectory( keep_trailing_slash, level )
        local fn = debug_getfmain( ( level or 1 ) + 1 )
        if fn == nil then
            return "/"
        end

        local fenv = getfenv( fn )
        if fenv ~= nil then
            local directory_path = fenv.__dirname
            if directory_path ~= nil then
                if keep_trailing_slash then
                    return directory_path .. "/"
                else
                    return directory_path
                end
            end
        end

        local file_path = debug_getfpath( fn )
        if file_path == nil then
            return "/"
        else
            return getDirectory( file_path, keep_trailing_slash ) or "/"
        end
    end

    path.getCurrentDirectory = getCurrentDirectory

end

--- [SHARED AND MENU]
---
--- Normalizes a file path by removing all "." and ".." parts.
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string new_file_path The normalized file path.
local function normalize( file_path, keep_trailing_slash )
    local file_path_length = string_len( file_path )

    if file_path_length == 0 then
        return "."
    end

    local has_trailing_slash = string_byte( file_path, file_path_length ) == 0x2F --[[ / ]]
    local is_abs = string_byte( file_path, 1 ) == 0x2F --[[ / ]]

    local segments, segment_count = string_byteSplit( file_path, 0x2F --[[ / ]], is_abs and 2 or 1, has_trailing_slash and ( file_path_length - 1 ) or file_path_length, file_path_length )
    local skip = 0

    for index = segment_count, 1, -1 do
        local uint8_1, uint8_2, uint8_3 = string_byte( segments[ index ], 1, 3 )
        if uint8_2 == nil and uint8_1 == 0x2E --[[ . ]] then
            table_remove( segments, index )
            segment_count = segment_count - 1
        elseif uint8_3 == nil and uint8_1 == 0x2E --[[ . ]] and uint8_2 == 0x2E --[[ . ]] then
            table_remove( segments, index )
            segment_count = segment_count - 1
            skip = skip + 1
        elseif skip > 0 then
            table_remove( segments, index )
            segment_count = segment_count - 1
            skip = skip - 1
        end
    end

    if not is_abs then
        while skip > 0 do
            table_insert( segments, 1, ".." )
            segment_count = segment_count + 1
            skip = skip - 1
        end
    end

    has_trailing_slash = has_trailing_slash and keep_trailing_slash == true

    if segment_count == 0 or ( segment_count == 1 and string_byte( segments[ 1 ], 1, 1 ) == nil ) then
        if has_trailing_slash then
            return "./"
        elseif is_abs then
            return "/"
        else
            return "."
        end
    end

    local normalized_path = table_concat( segments, "/", 1, segment_count )

    if has_trailing_slash and is_abs then
        return "/" .. normalized_path .. "/"
    elseif has_trailing_slash then
        return normalized_path .. "/"
    elseif is_abs then
        return "/" .. normalized_path
    else
        return normalized_path
    end
end

path.normalize = normalize

--- [SHARED AND MENU]
---
--- Resolve a file path.
---
---@param file_path string The file path.
---@return string abs_path The resolved file path.
function path.resolve( file_path )
    if string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]] then
        return normalize( file_path, false )
    else
        return normalize( getCurrentDirectory( true ) .. file_path, false )
    end
end

do

    local string_byteTrim = string.byteTrim

    --- [SHARED AND MENU]
    ---
    --- Join the file paths into a single file path and normalize it.
    ---
    ---@param ... string The file paths.
    ---@return string file_path The joined file path.
    function path.join( ... )
        local arg_count = select( "#", ... )
        local args = { ... }

        for index = 1, arg_count, 1 do
            local value = args[ index ]
            if value and value ~= "" then
                args[ index ] = value
            else
                args[ index ] = ""
            end
        end

        for index = 1, arg_count, 1 do
            local value = args[ index ]
            if index > 1 then
                -- TODO: recheck direction
                value = string_byteTrim( value, 0x2F, false )
            end

            if index < arg_count then
                -- TODO: recheck direction
                value = string_byteTrim( value, 0x2F, true )
            end

            args[ index ] = value
        end

        return normalize( table_concat( args, "/", 1, arg_count ) )
    end

end

do

    local math_min = std.math.min

    --- [SHARED AND MENU]
    ---
    --- Get the relative path from one file path to another.
    ---
    ---@param from string The from file path.
    ---@param to string The to file path.
    ---@return string relative_path The relative path.
    function path.relative( from, to )
        local from_path, to_path = normalize( from ), normalize( to )

        if equals( from_path, to_path ) then
            return "."
        end

        local from_parts, from_part_count = string_byteSplit( from_path, 0x2F --[[ / ]] )
        local to_parts, to_part_count = string_byteSplit( to_path, 0x2F --[[ / ]] )
        local equal_count = 0

        for index = 1, math_min( from_part_count, to_part_count ), 1 do
            if equals( from_parts[ index ], to_parts[ index ] ) then
                equal_count = equal_count + 1
            else
                break
            end
        end

        local result_parts, result_part_count = {}, 0
        for _ = equal_count + 1, from_part_count, 1 do
            result_part_count = result_part_count + 1
            result_parts[ result_part_count ] = ".."
        end

        for index = equal_count + 1, to_part_count, 1 do
            result_part_count = result_part_count + 1
            result_parts[ result_part_count ] = to_parts[ index ]
        end

        if result_part_count == 0 then
            return "."
        else
            return table_concat( result_parts, "/", 1, result_part_count )
        end
    end

end
