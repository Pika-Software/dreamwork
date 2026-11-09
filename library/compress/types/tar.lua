---@meta _

--- [SHARED AND MENU]
---
--- The tar (`.tar`) archive.
---
--- Parses POSIX ustar, pax and GNU archives (long names and base-256 numbers), gzip compressed archives are decompressed on parse.
---
--- Builds ustar archives, long paths and out of range values are written with pax headers.
---
--- ```lua
--- local tar = Tar()
--- tar:addDirectory( "docs" )
--- tar:addFile( "docs/readme.txt", "hello" )
---
--- local data = tar:compile()
--- print( Tar( data ):readFile( "docs/readme.txt" ) ) -- hello
--- ```
---
---@class Tar : Object
---@field __class TarClass
---@field files Tar.File[] The entries of the archive.
---@field file_count integer The number of entries.
---@field file_indexes table<string, integer> The indexes of entries in `files` by their paths.
---@field gzipped boolean `true` if the parsed archive was gzip compressed.
---@field data string | nil The parsed archive data, the content of not yet read entries.
local __Tar = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Tar` objects.
---
---@class TarClass : Tar, Class
---@field __base Tar
---@overload fun( data: string? ): Tar
Tar = {}

---@return string
---@nodiscard
---@protected
function __Tar:__represent() end

---@param data string?
---@protected
function __Tar:__init(data) end

--- [SHARED AND MENU]
---
--- Replaces the archive with the parsed `.tar` or `.tar.gz` data.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
---@param data string The `.tar` or `.tar.gz` data.
function __Tar:parse(data) end

--- [SHARED AND MENU]
---
--- Builds the `.tar` data of the archive.
---
--- Use `gzip.compress` on the result to get `.tar.gz`.
---
---@return string data The `.tar` data.
---@nodiscard
function __Tar:compile() end

--- [SHARED AND MENU]
---
--- Returns the entry of the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return Tar.File | nil file The entry, `nil` if there is no such entry.
---@nodiscard
function __Tar:getFile(file_path) end

--- [SHARED AND MENU]
---
--- Returns the content of the entry of the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return string | nil content The content, `nil` if there is no such entry.
---@nodiscard
function __Tar:readFile(file_path) end

--- [SHARED AND MENU]
---
--- Adds the regular file to the archive, replaces the existing entry with the same path.
---
---@param file_path string The path of the file inside of the archive, e.g. `docs/readme.txt`.
---@param content string The file content.
---@param mode integer? The permission bits, `420` (`0644`) by default.
---@return Tar.File file The added file.
function __Tar:addFile(file_path, content, mode) end

--- [SHARED AND MENU]
---
--- Adds the directory to the archive, replaces the existing entry with the same path.
---
---@param directory_path string The path of the directory inside of the archive, `/` is appended if missing.
---@param mode integer? The permission bits, `493` (`0755`) by default.
---@return Tar.File file The added directory.
function __Tar:addDirectory(directory_path, mode) end

--- [SHARED AND MENU]
---
--- Adds the symbolic link to the archive, replaces the existing entry with the same path.
---
---@param link_path string The path of the link inside of the archive.
---@param target string The path the link points to.
---@return Tar.File file The added link.
function __Tar:addSymlink(link_path, target) end

--- [SHARED AND MENU]
---
--- Removes the entry from the archive.
---
---@param file_path string The path of the entry inside of the archive.
---@return boolean removed `true` if the entry was removed, `false` if there is no such entry.
function __Tar:removeFile(file_path) end
