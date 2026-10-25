---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_getfmain = debug.getfmain
local debug_getfsource = debug.getfsource

local string = std.string
local string_len = string.len
local pattern_bytes = string.PatternBytes
local string_byteSplit = string.byteSplit
local string_sub, string_gsub = string.sub, string.gsub
local string_char, string_byte = string.char, string.byte

local table = std.table
local table_concat = table.concat

local len = std.len
local getfenv = std.getfenv
local isFunction = std.isFunction


--- [SHARED AND MENU]
---
--- The file path library.
---
--- Works with POSIX-style paths: `/` is the only separator and a path is absolute
--- when it starts with `/`. Backslashes are ordinary bytes, except in
--- `stripTrailingSlash`, `stripLeadingSlash` and `normalizeSlashes`, which also treat
--- `\` as a separator.
---
--- Nothing here touches the file system; all functions work on the strings only.
---
---@class dreamwork.std.path
---@field delimiter string The delimiter between paths in a path list, always `":"`.
---@field sep string The path segment separator, always `"/"`.
local path = {}
std.path = path

path.delimiter = ":"
path.sep = "/"

--- [SHARED AND MENU]
---
--- Checks if the file path is absolute, i.e. starts with `/`.
---
--- ```lua
--- path.isAbsolute( "/game/lua/init.lua" ) -- true
--- path.isAbsolute( "lua/init.lua" ) -- false
--- ```
---
---@param file_path string The file path.
---@return boolean is_abs `true` if the file path is absolute, `false` otherwise.
function path.isAbsolute( file_path )
    return string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]]
end

--- [SHARED AND MENU]
---
--- Checks if the file path is relative, i.e. does not start with `/`.
---
--- An empty string is relative.
---
--- ```lua
--- path.isRelative( "lua/init.lua" ) -- true
--- path.isRelative( "/game/lua/init.lua" ) -- false
--- ```
---
---@param file_path string The file path.
---@return boolean is_rel `true` if the file path is relative, `false` otherwise.
function path.isRelative( file_path )
    return string_byte( file_path, 1, 1 ) ~= 0x2F --[[ / ]]
end

local equals

if std.SYSTEM_WINDOWS or std.SYSTEM_OSX then

    local string_lower = string.lower

    --- [SHARED AND MENU]
    ---
    --- Checks if the file paths are equal.
    ---
    --- **Linux**
    ---
    --- The comparison is case-sensitive, because this system uses a
    --- case-sensitive file system. The paths are not normalized, use
    --- `path.normalize` or `path.resolve` first if needed.
    ---
    --- ```lua
    --- path.equals( "lua/init.lua", "lua/init.lua" ) -- true
    --- path.equals( "lua/./init.lua", "lua/init.lua" ) -- false
    --- ```
    ---
    --- **Windows/macOS**
    ---
    --- The comparison is ASCII case-insensitive, because this system
    --- uses a case-insensitive file system. The paths are not normalized, use
    --- `path.normalize` or `path.resolve` first if needed.
    ---
    --- ```lua
    --- path.equals( "lua/Init.lua", "lua/init.lua" ) -- true
    --- path.equals( "lua/./init.lua", "lua/init.lua" ) -- false
    --- ```
    ---
    ---@param file_path1 string The first file path.
    ---@param file_path2 string The second file path.
    ---@return boolean is_equal `true` if the paths are equal, `false` otherwise.
    function equals( file_path1, file_path2 )
        return string_lower( file_path1 ) == string_lower( file_path2 )
    end

else

    ---@param file_path1 string
    ---@param file_path2 string
    ---@return boolean is_equal
    function equals( file_path1, file_path2 )
        return file_path1 == file_path2
    end

end

path.equals = equals

--- [SHARED AND MENU]
---
--- Returns the file name, the part after the last `/`, without its extension by default.
---
--- Only the last extension is removed, and a leading dot is part of the name,
--- so dotfiles like `.bashrc` have no extension.
---
--- ```lua
--- path.getFile( "/game/lua/init.lua" ) -- "init"
--- path.getFile( "/game/lua/init.lua", true ) -- "init.lua"
--- path.getFile( "archive.tar.gz" ) -- "archive.tar"
--- path.getFile( "/home/.bashrc" ) -- ".bashrc"
--- path.getFile( "/game/lua/" ) -- ""
--- ```
---
---@param file_path string The file path.
---@param keep_extension? boolean `true` to keep the extension, `false` otherwise.
---@return string file_name The name of the file.
function path.getFile( file_path, keep_extension )
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
        local uint8 = string_byte( file_path, index )
        if uint8 == 0x2E --[[ . ]] then
            -- a leading dot belongs to the name (e.g. `.bashrc`)
            if dot_position == nil and index ~= 1 and string_byte( file_path, index - 1 ) ~= 0x2F --[[ / ]] then
                dot_position = index
            end
        elseif uint8 == 0x2F --[[ / ]] then
            if dot_position == nil then
                return string_sub( file_path, index + 1 )
            end

            return string_sub( file_path, index + 1, dot_position - 1 )
        end
    end

    if dot_position == nil then
        return file_path
    end

    return string_sub( file_path, 1, dot_position - 1 )
end

--- [SHARED AND MENU]
---
--- Returns the directory, the part before the last `/`.
---
--- The root directory is always returned as `"/"`, even if `keep_trailing_slash` is not `true`.
---
--- ```lua
--- path.getDirectory( "/game/lua/init.lua" ) -- "/game/lua"
--- path.getDirectory( "/game/lua/init.lua", true ) -- "/game/lua/"
--- path.getDirectory( "/init.lua" ) -- "/"
--- path.getDirectory( "init.lua" ) -- nil
--- ```
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string | nil directory The directory of the file, or `nil` if the file path has no `/`.
local function getDirectory( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            -- the root directory keeps its slash
            if not keep_trailing_slash and index ~= 1 then
                index = index - 1
            end

            return string_sub( file_path, 1, index )
        end
    end

    return nil
end

path.getDirectory = getDirectory

--- [SHARED AND MENU]
---
--- Returns the extension of the file name, the part after its last dot.
---
--- A leading dot is part of the name, so dotfiles like `.bashrc` have no extension.
---
--- ```lua
--- path.getExtension( "/game/lua/init.lua" ) -- "lua"
--- path.getExtension( "/game/lua/init.lua", true ) -- ".lua"
--- path.getExtension( "archive.tar.gz" ) -- "gz"
--- path.getExtension( "/home/.bashrc" ) -- ""
--- path.getExtension( "/data.d/file" ) -- ""
--- ```
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the dot, `false` otherwise.
---@return string extension The extension of the file, or an empty string if there is none.
function path.getExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local uint8 = string_byte( file_path, index )
        if uint8 == 0x2F --[[ / ]] then
            break
        elseif uint8 == 0x2E --[[ . ]] then
            -- a leading dot belongs to the name (e.g. `.bashrc`)
            if index == 1 or string_byte( file_path, index - 1 ) == 0x2F --[[ / ]] then
                break
            end

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
--- Splits a file path at the last `/` into a directory and a file name.
---
--- The root directory is always returned as `"/"`, even if `keep_trailing_slash` is not `true`.
---
--- ```lua
--- path.split( "/game/lua/init.lua" ) -- "/game/lua", "init.lua"
--- path.split( "/game/lua/init.lua", true ) -- "/game/lua/", "init.lua"
--- path.split( "/init.lua" ) -- "/", "init.lua"
--- path.split( "init.lua" ) -- "", "init.lua"
--- ```
---
---@param file_path string The file path.
---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
---@return string directory_path The directory from the file path, or an empty string if the file path has no `/`.
---@return string file_name The file name with extension from the file path.
local function split( file_path, keep_trailing_slash )
    for index = string_len( file_path ), 1, -1 do
        if string_byte( file_path, index ) == 0x2F --[[ / ]] then
            -- the root directory keeps its slash
            return string_sub( file_path, 1, (keep_trailing_slash or index == 1) and index or (index - 1) ), string_sub( file_path, index + 1 )
        end
    end

    return "", file_path
end

path.split = split

--- [SHARED AND MENU]
---
--- Splits a file path at the last dot of the file name into the path without
--- the extension and the extension.
---
--- A leading dot is part of the name, so dotfiles like `.bashrc` have no extension.
---
--- ```lua
--- path.splitExtension( "/game/lua/init.lua" ) -- "/game/lua/init", "lua"
--- path.splitExtension( "/game/lua/init.lua", true ) -- "/game/lua/init", ".lua"
--- path.splitExtension( "/home/.bashrc" ) -- "/home/.bashrc", ""
--- ```
---
---@param file_path string The file path.
---@param keep_dot? boolean `true` to keep the extension dot, `false` otherwise.
---@return string file_path_without_extension The file path without the extension.
---@return string extension The extension, or an empty string if there is none.
local function splitExtension( file_path, keep_dot )
    for index = string_len( file_path ), 1, -1 do
        local uint8 = string_byte( file_path, index )
        if uint8 == 0x2F --[[ / ]] then
            return file_path, ""
        elseif uint8 == 0x2E --[[ . ]] then
            -- a leading dot belongs to the name (e.g. `.bashrc`)
            if index == 1 or string_byte( file_path, index - 1 ) == 0x2F --[[ / ]] then
                return file_path, ""
            end

            return string_sub( file_path, 1, index - 1 ), string_sub( file_path, keep_dot and index or (index + 1) )
        end
    end

    return file_path, ""
end

path.splitExtension = splitExtension

--- [SHARED AND MENU]
---
--- Replaces the file name (with extension), the part after the last `/`.
---
--- ```lua
--- path.replaceName( "/game/lua/init.lua", "shared.lua" ) -- "/game/lua/shared.lua"
--- path.replaceName( "init.lua", "shared.lua" ) -- "shared.lua"
--- ```
---
---@param file_path string The file path.
---@param file_name string The new file name, including its extension.
---@return string new_file_path The new file path.
function path.replaceName( file_path, file_name )
    return split( file_path, true ) .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the directory, the part before the last `/`, and keeps the file name.
---
--- A `/` is added between the directory and the file name if needed.
--- An empty directory leaves only the file name.
---
--- ```lua
--- path.replaceDirectory( "/game/lua/init.lua", "/data/cache" ) -- "/data/cache/init.lua"
--- path.replaceDirectory( "/game/lua/init.lua", "/data/cache/" ) -- "/data/cache/init.lua"
--- path.replaceDirectory( "/game/lua/init.lua", "" ) -- "init.lua"
--- ```
---
---@param file_path string The file path.
---@param dir_name string The new directory, with or without a trailing slash.
---@return string new_file_path The new file path.
function path.replaceDirectory( file_path, dir_name )
    local _, file_name = split( file_path, false )

    local dir_length = string_len( dir_name )
    if dir_length == 0 then
        return file_name
    elseif string_byte( dir_name, dir_length, dir_length ) ~= 0x2F --[[ / ]] then
        return dir_name .. "/" .. file_name
    end

    return dir_name .. file_name
end

--- [SHARED AND MENU]
---
--- Replaces the extension of the file name, or adds one if there is none.
---
--- ```lua
--- path.replaceExtension( "/game/lua/init.lua", "txt" ) -- "/game/lua/init.txt"
--- path.replaceExtension( "archive.tar.gz", "zip" ) -- "archive.tar.zip"
--- path.replaceExtension( "/home/.bashrc", "bak" ) -- "/home/.bashrc.bak"
--- ```
---
---@param file_path string The file path.
---@param ext_name string The new extension, without the leading dot.
---@return string new_file_path The new file path.
function path.replaceExtension( file_path, ext_name )
    return splitExtension( file_path, false ) .. "." .. ext_name
end

--- [SHARED AND MENU]
---
--- Removes all trailing slashes (`/` and `\`) from the file path.
---
--- The first byte is never removed, so the root directory stays `"/"`.
---
--- ```lua
--- path.stripTrailingSlash( "/game/lua/" ) -- "/game/lua"
--- path.stripTrailingSlash( "lua\\//" ) -- "lua"
--- path.stripTrailingSlash( "/" ) -- "/"
--- ```
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripTrailingSlash( file_path )
    local file_path_length = string_len( file_path )
    local index = file_path_length

    -- the first byte is never stripped, so the root directory stays `/`
    while index > 1 do
        local uint8 = string_byte( file_path, index, index )
        if uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] then
            index = index - 1
        else
            break
        end
    end

    if index == file_path_length then
        return file_path
    end

    return string_sub( file_path, 1, index )
end

--- [SHARED AND MENU]
---
--- Adds a trailing `/` to the file path if it does not end with one.
---
--- ```lua
--- path.ensureTrailingSlash( "/game/lua" ) -- "/game/lua/"
--- path.ensureTrailingSlash( "/game/lua/" ) -- "/game/lua/"
--- ```
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
--- Removes all leading slashes (`/` and `\`) from the file path,
--- which makes an absolute path relative.
---
--- ```lua
--- path.stripLeadingSlash( "/game/lua" ) -- "game/lua"
--- path.stripLeadingSlash( "\\/game/lua" ) -- "game/lua"
--- path.stripLeadingSlash( "/" ) -- ""
--- ```
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.stripLeadingSlash( file_path )
    local index = 1

    while true do
        local uint8 = string_byte( file_path, index, index )
        if uint8 == 0x2F --[[ / ]] or uint8 == 0x5C --[[ \ ]] then
            index = index + 1
        else
            break
        end
    end

    if index == 1 then
        return file_path
    end

    return string_sub( file_path, index )
end

--- [SHARED AND MENU]
---
--- Adds a leading `/` to the file path if it does not start with one,
--- which makes a relative path absolute.
---
--- ```lua
--- path.ensureLeadingSlash( "game/lua" ) -- "/game/lua"
--- path.ensureLeadingSlash( "/game/lua" ) -- "/game/lua"
--- ```
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
--- Replaces every run of slashes (`/` and `\`) with a single `/`.
---
--- Useful for paths that came from Windows. Unlike `path.normalize`,
--- `.` and `..` segments are left as is.
---
--- ```lua
--- path.normalizeSlashes( "garrysmod\\lua//init.lua" ) -- "garrysmod/lua/init.lua"
--- path.normalizeSlashes( "a\\..\\b" ) -- "a/../b"
--- ```
---
---@param file_path string The file path.
---@return string new_file_path The new file path.
function path.normalizeSlashes( file_path )
    return (string_gsub( file_path, "[/\\]+", "/" ))
end

--- [SHARED AND MENU]
---
--- Parses a file path into a table of its parts.
---
---     ┌─────────────────────┬────────────┐
---     │          dir        │    base    │
---     ├──────┬              ├──────┬─────┤
---     │ root │              │ name │ ext │
---     "  /    home/user/dir/  file  .txt "
---     └──────┴──────────────┴──────┴─────┘
--- (All spaces in the "" line should be ignored. They are purely for formatting.)
---
--- `dir` keeps its trailing slash and `ext` keeps its dot, so `dir .. name .. ext`
--- is always the original path. The path is not normalized.
---
--- ```lua
--- local data = path.parse( "/home/user/dir/file.txt" )
--- -- data.root = "/", data.dir = "/home/user/dir/", data.base = "file.txt"
--- -- data.name = "file", data.ext = ".txt", data.abs = true
--- ```
---
---@param file_path string The file path.
---@return dreamwork.std.path.ParsedData data The parsed file path data.
function path.parse( file_path )
    local is_abs = string_byte( file_path, 1 ) == 0x2F --[[ / ]]
    local directory, base = split( file_path, true )
    local name, ext = splitExtension( base, true )

    return { root = is_abs and "/" or "", dir = directory, base = base, ext = ext, name = name, abs = is_abs }
end

local normalize
do

    -- reused segment stack, stale entries past `segment_count` are ignored by `table.concat`
    local segments = {}

    --- [SHARED AND MENU]
    ---
    --- Normalizes a file path: collapses repeated slashes, removes `.` segments
    --- and resolves `..` segments against the segments before them.
    ---
    --- `..` segments that can't be resolved stay at the start of a relative path,
    --- and are dropped from an absolute path, since nothing is above the root.
    --- An empty result becomes `"."` (or `"/"` for absolute paths).
    ---
    --- Already normalized paths are returned as is, without creating a new string.
    ---
    --- ```lua
    --- path.normalize( "/game//lua/./x/../init.lua" ) -- "/game/lua/init.lua"
    --- path.normalize( "lua/../../init.lua" ) -- "../init.lua"
    --- path.normalize( "/../init.lua" ) -- "/init.lua"
    --- path.normalize( "lua/.." ) -- "."
    --- path.normalize( "lua/x/" ) -- "lua/x"
    --- path.normalize( "lua/x/", true ) -- "lua/x/"
    --- ```
    ---
    ---@param file_path string The file path.
    ---@param keep_trailing_slash? boolean `true` to keep the trailing slash, `false` otherwise.
    ---@return string new_file_path The normalized file path.
    function normalize( file_path, keep_trailing_slash )
        local file_path_length = string_len( file_path )
        if file_path_length == 0 then
            return "."
        end

        local is_abs = string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]]
        local has_trailing_slash = string_byte( file_path, file_path_length, file_path_length ) == 0x2F --[[ / ]]

        -- `parent_count` is the number of leading ".." segments that can't be popped
        local segment_count, parent_count = 0, 0
        local is_modified = false
        local position = 1

        while position <= file_path_length do
            local slash_start = position

            while string_byte( file_path, position, position ) == 0x2F --[[ / ]] do
                position = position + 1
            end

            if position - slash_start > 1 then
                is_modified = true
            end

            if position > file_path_length then
                break
            end

            local segment_start = position

            repeat
                position = position + 1
            until position > file_path_length or string_byte( file_path, position, position ) == 0x2F --[[ / ]]

            local segment_length = position - segment_start
            local uint8_1, uint8_2 = string_byte( file_path, segment_start, segment_start + 1 )

            if segment_length == 1 and uint8_1 == 0x2E --[[ . ]] then
                is_modified = true
            elseif segment_length == 2 and uint8_1 == 0x2E --[[ . ]] and uint8_2 == 0x2E --[[ . ]] then
                if segment_count > parent_count then
                    is_modified = true
                    segment_count = segment_count - 1
                elseif is_abs then
                    is_modified = true
                else
                    segment_count = segment_count + 1
                    parent_count = parent_count + 1
                    segments[ segment_count ] = ".."
                end
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( file_path, segment_start, position - 1 )
            end
        end

        has_trailing_slash = has_trailing_slash and keep_trailing_slash == true

        if segment_count == 0 then
            if is_abs then
                return "/"
            elseif has_trailing_slash then
                return "./"
            end

            return "."
        end

        if not is_modified and (has_trailing_slash or string_byte( file_path, file_path_length, file_path_length ) ~= 0x2F --[[ / ]]) then
            return file_path
        end

        local normalized_path = table_concat( segments, "/", 1, segment_count )

        if has_trailing_slash and is_abs then
            return "/" .. normalized_path .. "/"
        elseif has_trailing_slash then
            return normalized_path .. "/"
        elseif is_abs then
            return "/" .. normalized_path
        end

        return normalized_path
    end

end

path.normalize = normalize

do

    --- [SHARED AND MENU]
    ---
    --- Returns the path of the file that a function was loaded from.
    ---
    --- With a stack level, the `__file` object in the function's environment is used first
    --- (set for files loaded by dreamwork), then the source of the main chunk on the stack.
    --- With a function, its source is used.
    ---
    --- If the file can't be found, `"/game/lua/unknown.lua"` is returned.
    ---
    --- ```lua
    --- -- in /game/lua/autorun/init.lua
    --- path.get() -- "/game/lua/autorun/init.lua"
    --- ```
    ---
    ---@param f? function | integer The function, or the stack level, where `1` (default) is the function calling `get`.
    ---@return string file_path The absolute path of the file.
    local function get( f )
        local fn
        if isFunction( f ) then
            ---@cast f function
            fn = f
        else
            if f == nil then
                f = 2
            else
                f = f + 1
            end

            ---@type table | nil
            local env = getfenv( f )
            if env ~= nil then
                ---@type dreamwork.std.fs.File | nil
                local file_path = env.__file
                if file_path ~= nil then
                    return file_path.path
                end
            end

            fn = debug_getfmain( f )
        end

        if fn ~= nil then
            local file_path = debug_getfsource( fn )
            if file_path ~= nil then
                return file_path
            end
        end

        return "/game/lua/unknown.lua"
    end

    path.get = get

    --- [SHARED AND MENU]
    ---
    --- Resolves a file path to an absolute, normalized file path.
    ---
    --- Absolute paths are only normalized. Relative paths are resolved against the
    --- directory of the file that calls `resolve` (see `path.get`), similar to `require`.
    ---
    --- ```lua
    --- -- in /game/lua/autorun/init.lua
    --- path.resolve( "client.lua" ) -- "/game/lua/autorun/client.lua"
    --- path.resolve( "../shared/util.lua" ) -- "/game/lua/shared/util.lua"
    --- path.resolve( "/data/./x.txt" ) -- "/data/x.txt"
    --- ```
    ---
    ---@param file_path string The file path.
    ---@param stack_level? integer The stack level of the file to resolve against, where `1` (default) is the function calling `resolve`.
    ---@return string abs_path The resolved file path.
    local function resolve( file_path, stack_level )
        if string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]] then
            return normalize( file_path, false )
        end

        if stack_level == nil then
            stack_level = 2
        else
            stack_level = stack_level + 1
        end

        return normalize( (getDirectory( get( stack_level ), true ) or "/") .. file_path, false )
    end

    path.resolve = resolve

    do

        local math_min = std.math.min

        --- [SHARED AND MENU]
        ---
        --- Returns the relative path from the `from` directory to `to`.
        ---
        --- Both paths are resolved with `path.resolve` first, so relative paths are
        --- relative to the calling file. Segments are compared with `path.equals`.
        ---
        --- If both resolve to the same path, `"."` is returned.
        ---
        --- ```lua
        --- path.relative( "/game/lua/autorun", "/game/lua/shared/util.lua" ) -- "../shared/util.lua"
        --- path.relative( "/game/lua", "/game/lua/autorun/init.lua" ) -- "autorun/init.lua"
        --- path.relative( "/game/lua/autorun", "/game" ) -- "../.."
        --- path.relative( "/game/lua", "/game/lua/" ) -- "."
        --- ```
        ---
        ---@param from string The directory to get the relative path from.
        ---@param to string The path to get the relative path to.
        ---@param stack_level? integer The stack level of the file to resolve relative paths against, where `1` (default) is the function calling `relative`.
        ---@return string relative_path The relative path.
        function path.relative( from, to, stack_level )
            if stack_level == nil then
                stack_level = 2
            else
                stack_level = stack_level + 1
            end

            local from_path, to_path = resolve( from, stack_level ), resolve( to, stack_level )

            if equals( from_path, to_path ) then
                return "."
            end

            -- both paths are absolute and normalized, so skipping the leading slash leaves no empty parts ( "/" has none )
            local from_parts, from_part_count = string_byteSplit( from_path, 0x2F --[[ / ]], 2 )
            local to_parts, to_part_count = string_byteSplit( to_path, 0x2F --[[ / ]], 2 )

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

end

--- [SHARED AND MENU]
---
--- Joins the file paths with `/` and normalizes the result (see `path.normalize`).
---
--- Empty paths are skipped, and a leading `/` is kept only on the first path,
--- so the result is absolute only if the first non-empty path is.
--- The `segments` table is not modified.
---
--- ```lua
--- path.join( { "/game", "lua/", "autorun/init.lua" } ) -- "/game/lua/autorun/init.lua"
--- path.join( { "/game/lua", "../data", "x.txt" } ) -- "/game/data/x.txt"
--- path.join( { "lua", "/autorun" } ) -- "lua/autorun"
--- path.join( {} ) -- "."
--- ```
---
---@param segments string[] The file paths to join.
---@param segment_count? integer The number of file paths to join, defaults to the length of `segments`.
---@return string file_path The joined file path.
function path.join( segments, segment_count )
    if segment_count == nil then
        segment_count = len( segments )
    end

    -- empty segments are skipped, repeated slashes are collapsed by `normalize`
    local parts, part_count = {}, 0

    for index = 1, segment_count, 1 do
        local segment = segments[ index ]
        if string_byte( segment, 1, 1 ) ~= nil then
            part_count = part_count + 1
            parts[ part_count ] = segment
        end
    end

    if part_count == 0 then
        return "."
    end

    return normalize( table_concat( parts, "/", 1, part_count ), false )
end

do

    --- Lua pattern that never matches anything (used for empty bracket expressions like `[z-a]`).
    local never_match = "[^%z\1-\255]"

    --- Converts a bracket expression (starting at the `[` byte) into a Lua character class.
    ---
    ---@param str string The wildcard string.
    ---@param position integer The position of the `[` byte.
    ---@param str_length integer The length of the wildcard string.
    ---@return string | nil class The Lua character class, or `nil` if the bracket is not closed.
    ---@return integer next_position The position after the closing `]`.
    local function wildcard_class( str, position, str_length )
        local index = position + 1
        local is_negated = false

        local uint8_1 = string_byte( str, index, index )
        if uint8_1 == 0x21 --[[ ! ]] or uint8_1 == 0x5E --[[ ^ ]] then
            is_negated = true
            index = index + 1
        end

        local class_start = index

        -- `]` right after `[` or `[!` is a member, not the end
        if string_byte( str, index, index ) == 0x5D --[[ ] ]] then
            index = index + 1
        end

        while index <= str_length and string_byte( str, index, index ) ~= 0x5D --[[ ] ]] do
            index = index + 1
        end

        if index > str_length then
            return nil, position + 1
        end

        local class_end = index - 1

        -- negated classes never match `/`, the same as `?` and `*`
        local segments, segment_count = { is_negated and "[^/" or "[" }, 1

        index = class_start

        while index <= class_end do
            uint8_1 = string_byte( str, index, index )

            if index + 2 <= class_end and string_byte( str, index + 1, index + 1 ) == 0x2D --[[ - ]] then
                local uint8_2 = string_byte( str, index + 2, index + 2 )

                if uint8_1 <= uint8_2 then
                    if uint8_1 ~= 0x00 and pattern_bytes[ uint8_1 ] == nil and pattern_bytes[ uint8_2 ] == nil then
                        segment_count = segment_count + 1
                        segments[ segment_count ] = string_char( uint8_1, 0x2D --[[ - ]], uint8_2 )
                    else
                        -- Lua can't use escaped bytes as range ends, so the range is expanded
                        for uint8 = uint8_1, uint8_2, 1 do
                            segment_count = segment_count + 1
                            segments[ segment_count ] = uint8 == 0x00 and "%z" or pattern_bytes[ uint8 ] or string_char( uint8 )
                        end
                    end
                end

                index = index + 3
            else
                segment_count = segment_count + 1
                segments[ segment_count ] = uint8_1 == 0x00 and "%z" or pattern_bytes[ uint8_1 ] or string_char( uint8_1 )
                index = index + 1
            end
        end

        if segment_count == 1 then
            return is_negated and "[^/]" or never_match, class_end + 2
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = "]"

        return table_concat( segments, "", 1, segment_count ), class_end + 2
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a wildcard (glob) string to a Lua pattern.
    ---
    --- Supported syntax:
    --- * `?` - any single byte except `/`.
    --- * `*` - any sequence of bytes except `/`.
    --- * `**` - any sequence of bytes, `**/` also matches zero directories.
    --- * `[abc]`, `[a-z]` - one byte from the set.
    --- * `[!a-z]`, `[^a-z]` - one byte not in the set, never `/`.
    --- * `\x` - the literal byte `x`, e.g. `\*` or `\[`.
    ---
    --- A `]` right after `[` or `[!` is a member of the set, e.g. `[]]`.
    --- A `[` without a closing `]` is a literal `[`. Other bytes match themselves,
    --- Lua pattern magic characters are escaped. Brace expansion (`{a,b}`) is not supported.
    ---
    --- The pattern always has to match up to the end of the string. By default it also
    --- has to match from the start; with `anchor_to_slash` it can start at the beginning
    --- or right after any `/`, so it matches the last segments of a full path.
    ---
    --- ```lua
    --- path.wildcard( "*.lua" ) -- "^[^/]*%.lua$"
    --- path.wildcard( "**/init.lua" ) -- "^.*%f[^%z/]init%.lua$"
    --- string.match( "init.lua", path.wildcard( "*.lua" ) ) -- "init.lua"
    --- string.match( "lua/init.lua", path.wildcard( "*.lua" ) ) -- nil
    --- string.match( "/game/lua/init.lua", path.wildcard( "*.lua", true ) ) -- "init.lua"
    --- string.match( "x2.txt", path.wildcard( "x[0-9].txt" ) ) -- "x2.txt"
    --- ```
    ---
    ---@param wildcard_str string The path wildcard string.
    ---@param anchor_to_slash? boolean If `true`, the pattern can match after any `/` instead of only at the start of the string.
    ---@return string pattern_str The Lua pattern that represents the wildcard string.
    function path.wildcard( wildcard_str, anchor_to_slash )
        local str_length = string_len( wildcard_str )

        local segments, segment_count = { anchor_to_slash and "%f[^%z/]" or "^" }, 1

        -- start of the pending run of bytes that need no escaping
        local literal_start = 1
        local position = 1

        while position <= str_length do
            local uint8_1 = string_byte( wildcard_str, position, position )
            local segment, next_position

            if uint8_1 == 0x3F --[[ ? ]] then
                segment, next_position = "[^/]", position + 1
            elseif uint8_1 == 0x2A --[[ * ]] then
                if string_byte( wildcard_str, position + 1, position + 1 ) ~= 0x2A --[[ * ]] then
                    segment, next_position = "[^/]*", position + 1
                elseif string_byte( wildcard_str, position + 2, position + 2 ) == 0x2F --[[ / ]] then
                    segment, next_position = ".*%f[^%z/]", position + 3
                else
                    segment, next_position = ".*", position + 2
                end
            elseif uint8_1 == 0x5B --[[ [ ]] then
                segment, next_position = wildcard_class( wildcard_str, position, str_length )
                if segment == nil then
                    segment = "%["
                end
            elseif uint8_1 == 0x5C --[[ \ ]] then
                if position == str_length then
                    segment, next_position = "\\", position + 1
                else
                    local uint8_2 = string_byte( wildcard_str, position + 1, position + 1 )
                    segment, next_position = uint8_2 == 0x00 and "%z" or pattern_bytes[ uint8_2 ] or string_char( uint8_2 ), position + 2
                end
            else
                segment, next_position = pattern_bytes[ uint8_1 ], position + 1
            end

            if segment ~= nil then
                if literal_start ~= position then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = string_sub( wildcard_str, literal_start, position - 1 )
                end

                segment_count = segment_count + 1
                segments[ segment_count ] = segment

                literal_start = next_position
            end

            position = next_position
        end

        if literal_start <= str_length then
            segment_count = segment_count + 1
            segments[ segment_count ] = string_sub( wildcard_str, literal_start, str_length )
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = "$"

        return table_concat( segments, "", 1, segment_count )
    end

end
