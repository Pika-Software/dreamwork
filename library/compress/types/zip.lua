---@meta _

--- [SHARED AND MENU]
---
--- The zip (`.zip`) archive.
---
--- Parses stored, deflated and LZMA files (ZIP64 too), builds archives with deflated or LZMA files,
--- the files of a parsed archive are copied without recompression.
---
--- ```lua
--- local zip = Zip()
--- zip:addFile( "docs/readme.txt", "hello" )
---
--- local data = zip:compile()
--- print( Zip( data ):readFile( "docs/readme.txt" ) ) -- hello
--- ```
---
---@class Zip : Object
---@field __class ZipClass
---@field comment string The comment of the archive.
---@field files Zip.File[] The files of the archive.
---@field file_count integer The number of files.
---@field file_indexes table<string, integer> The indexes of files in `files` by their paths.
---@field data string | nil The parsed archive data, the content of not yet read files.
local __Zip = {}

--- [SHARED AND MENU]
---
--- The class used to create new `Zip` objects.
---
---@class ZipClass : Zip, Class
---@field __base Zip
---@overload fun( data: string? ): Zip
Zip = {}

--- `PK\3\4` as little endian uint32.
---
---@type integer
Zip.Signature = nil

---@return string
---@nodiscard
---@protected
function __Zip:__represent() end

---@param data string?
---@protected
function __Zip:__init(data) end

--- [SHARED AND MENU]
---
--- Replaces the archive with the parsed `.zip` data.
---
--- File contents are not copied, they are read from the data on demand by `readFile`.
---
--- Multi-disk archives are not supported.
---
---@param data string The `.zip` data.
function __Zip:parse(data) end

--- [SHARED AND MENU]
---
--- Builds the `.zip` data of the archive.
---
--- Files are written with the extended timestamp, ZIP64 records are added only for more than `65534` files.
---
---@return string data The `.zip` data.
---@nodiscard
function __Zip:compile() end

--- [SHARED AND MENU]
---
--- Returns the file of the archive.
---
---@param file_path string The path of the file inside of the archive.
---@return Zip.File | nil file The file, `nil` if there is no such file.
---@nodiscard
function __Zip:getFile(file_path) end

--- [SHARED AND MENU]
---
--- Returns the uncompressed content of the file of the archive.
---
--- Throws an error if the file is encrypted, uses an unsupported compression method or its data is malformed.
---
---@param file_path string The path of the file inside of the archive.
---@return string | nil content The file content, `nil` if there is no such file.
---@nodiscard
function __Zip:readFile(file_path) end

--- [SHARED AND MENU]
---
--- Adds the file to the archive, replaces the existing file with the same path.
---
--- The content is compressed right away, it is stored as is if compression doesn't make it smaller.
---
--- LZMA uses `lzma.compress`, so it runs on a separate thread when HolyLib is installed and the call is made from a coroutine.
---
--- Throws an error if `method` is not `STORED`, `DEFLATE` or `LZMA`.
---
---@param file_path string The path of the file inside of the archive, e.g. `docs/readme.txt`.
---@param content string The file content.
---@param level integer? The compression level ( 0 - 9 ), `0` stores the content without compression, `6` by default for deflate, `5` for LZMA.
---@param method Zip.Method? The compression method, `0` (stored), `8` (deflate) or `14` (LZMA), `8` by default.
---@return Zip.File file The added file.
---@async
function __Zip:addFile(file_path, content, level, method) end

--- [SHARED AND MENU]
---
--- Adds the directory to the archive, replaces the existing entry with the same path.
---
--- Directories don't have to be added for their files, but some tools show empty directories only this way.
---
---@param directory_path string The path of the directory inside of the archive, `/` is appended if missing.
---@return Zip.File file The added directory entry.
function __Zip:addDirectory(directory_path) end

--- [SHARED AND MENU]
---
--- Removes the file from the archive.
---
---@param file_path string The path of the file inside of the archive.
---@return boolean removed `true` if the file was removed, `false` if there is no such file.
function __Zip:removeFile(file_path) end

--- [SHARED AND MENU]
---
--- Decompresses all files and checks their CRC-32 checksums.
---
--- Encrypted files and files with unsupported compression methods are reported as damaged.
---
---@return boolean is_valid `true` if all files are fine.
---@return string | nil file_path The path of the first damaged file.
---@nodiscard
function __Zip:verify() end
