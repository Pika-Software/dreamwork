---@meta _

--- [SHARED AND MENU]
---
--- The file inside of the addon.
---
--- `content` is `nil` for files of a parsed addon until it is read with `Addon:readFile`,
--- the data stays in the addon string at `offset`.
---
---@class Addon.File
---@field path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@field size integer The size of the file in bytes.
---@field checksum integer The CRC-32 checksum of the file content, `0` if there is no checksum.
---@field content string | nil The file content, `nil` if it is still in the addon data.
---@field offset integer | nil The `1`-based position of the file content in the addon data.

--- [SHARED AND MENU]
---
--- The Garry's Mod addon (`.gma`) archive.
---
--- Parses and builds the same format as `gmad`, legacy LZMA compressed addons are decompressed on parse.
---
--- ```lua
--- local addon = Addon()
--- addon.title = "My Addon"
--- addon.type = "tool"
--- addon.tags = { "fun", "build" }
--- addon:addFile( "lua/autorun/test.lua", "print( 'hello' )" )
---
--- local data = addon:compile()
--- print( Addon( data ):readFile( "lua/autorun/test.lua" ) ) -- print( 'hello' )
--- ```
---
---@class Addon : Object
---@field __class AddonClass
---@field format_version integer The version of the `.gma` format, `3` by default.
---@field steamid steam.Identifier The Steam ID of the author, all zero bytes by default (`gmad` doesn't set it).
---@field timestamp integer The Unix timestamp of the creation in seconds.
---@field required_content string[] The content required by the addon, unused by the game.
---@field title string The title of the addon.
---@field description string The description of the addon.
---@field type string The type of the addon, one of `AddonClass.Types`.
---@field tags string[] The tags of the addon, from `1` to `3` of `AddonClass.Tags`.
---@field author string The author of the addon, unused by the game.
---@field version integer The version of the addon, unused by the game.
---@field files Addon.File[] The files of the addon.
---@field file_count integer The number of files.
---@field size integer The size of the addon data in bytes without the trailing checksum, `0` until parsed or compiled.
---@field checksum integer The CRC-32 checksum of the addon data, `0` until parsed or compiled.
---@field legacy boolean `true` if the parsed addon was LZMA compressed.
---@field data string | nil The parsed addon data, the content of not yet read files.
---@field file_indexes table<string, integer> The indexes of files in `files` by their paths.
local __Addon = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Addon` objects.
---
---@class AddonClass : Addon, Class
---@field __base Addon
---@overload fun( data: string? ): Addon
Addon = {}

--- `GMAD` as little endian uint32.
---
---@type integer
Addon.Signature = nil

--- The latest supported format version.
---
---@type integer
Addon.Version = nil

--- [SHARED AND MENU]
---
--- Checks if the type is allowed by `gmad`.
---
---@param type_name string The addon type, e.g. `tool`.
---@return boolean is_valid `true` if the type is allowed.
---@nodiscard
function Addon.isValidType(type_name) end

--- [SHARED AND MENU]
---
--- Checks if the tag is allowed by `gmad`.
---
---@param tag_name string The addon tag, e.g. `fun`.
---@return boolean is_valid `true` if the tag is allowed.
---@nodiscard
function Addon.isValidTag(tag_name) end

--- [SHARED AND MENU]
---
--- Checks if the file path is allowed by the `gmad` whitelist.
---
---@param file_path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@return boolean is_allowed `true` if the path is allowed.
---@nodiscard
function Addon.isAllowedPath(file_path) end

---@return string
---@nodiscard
---@protected
function __Addon:__represent() end

---@param data string?
---@protected
function __Addon:__init(data) end

--- [SHARED AND MENU]
---
--- Replaces the addon with the parsed `.gma` data.
---
--- Legacy LZMA compressed addons are decompressed first.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
---@param data string The `.gma` data.
function __Addon:parse(data) end

--- [SHARED AND MENU]
---
--- Builds the `.gma` data of the addon, same as `gmad create`.
---
--- Updates `size` and `checksum` of the addon.
---
--- Doesn't check `type`, `tags` and file paths, use `validate` for that.
---
---@return string data The `.gma` data.
---@nodiscard
function __Addon:compile() end

--- [SHARED AND MENU]
---
--- Returns the file of the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return Addon.File | nil file The file, `nil` if there is no such file.
---@nodiscard
function __Addon:getFile(file_path) end

--- [SHARED AND MENU]
---
--- Returns the content of the file of the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return string | nil content The file content, `nil` if there is no such file.
---@nodiscard
function __Addon:readFile(file_path) end

--- [SHARED AND MENU]
---
--- Adds the file to the addon, replaces the existing file with the same path.
---
--- The path is lowercased, same as `gmad` does.
---
---@param file_path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@param content string The file content.
---@return Addon.File file The added file.
function __Addon:addFile(file_path, content) end

--- [SHARED AND MENU]
---
--- Removes the file from the addon.
---
---@param file_path string The path of the file inside of the addon.
---@return boolean removed `true` if the file was removed, `false` if there is no such file.
function __Addon:removeFile(file_path) end

--- [SHARED AND MENU]
---
--- Checks the CRC-32 checksums of the parsed addon data and all files.
---
--- Zero checksums are skipped, same as `gmad`.
---
---@return boolean is_valid `true` if all checksums match.
---@return string | nil file_path The path of the first damaged file, `nil` if the addon data itself is damaged.
---@nodiscard
function __Addon:verify() end

--- [SHARED AND MENU]
---
--- Checks the addon against the `gmad` rules:
--- an allowed type, `1` - `3` unique allowed tags and whitelisted file paths.
---
---@return boolean is_valid `true` if the addon follows the rules.
---@return string | nil reason The reason why the addon is invalid.
---@nodiscard
function __Addon:validate() end
