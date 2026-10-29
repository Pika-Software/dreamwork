---@meta _

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
---@class path
---@field delimiter string The delimiter between paths in a path list, always `":"`.
---@field sep string The path segment separator, always `"/"`.
path = {}

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
---@nodiscard
function path.isAbsolute(file_path) end

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
---@nodiscard
function path.isRelative(file_path) end

---@param file_path1 string
---@param file_path2 string
---@return boolean is_equal
---@nodiscard
function path.equals(file_path1, file_path2) end

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
---@nodiscard
function path.getFile(file_path, keep_extension) end

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
---@nodiscard
function path.getDirectory(file_path, keep_trailing_slash) end

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
---@nodiscard
function path.getExtension(file_path, keep_dot) end

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
---@nodiscard
function path.split(file_path, keep_trailing_slash) end

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
---@nodiscard
function path.splitExtension(file_path, keep_dot) end

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
---@nodiscard
function path.replaceName(file_path, file_name) end

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
---@nodiscard
function path.replaceDirectory(file_path, dir_name) end

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
---@nodiscard
function path.replaceExtension(file_path, ext_name) end

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
---@nodiscard
function path.stripTrailingSlash(file_path) end

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
---@nodiscard
function path.ensureTrailingSlash(file_path) end

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
---@nodiscard
function path.stripLeadingSlash(file_path) end

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
---@nodiscard
function path.ensureLeadingSlash(file_path) end

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
---@nodiscard
function path.normalizeSlashes(file_path) end

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
---@return path.ParsedData data The parsed file path data.
---@nodiscard
function path.parse(file_path) end

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
---@nodiscard
function path.normalize(file_path, keep_trailing_slash) end

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
---@nodiscard
function path.get(f) end

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
---@nodiscard
function path.resolve(file_path, stack_level) end

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
---@nodiscard
function path.relative(from, to, stack_level) end

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
---@nodiscard
function path.join(segments, segment_count) end

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
---@nodiscard
function path.wildcard(wildcard_str, anchor_to_slash) end
