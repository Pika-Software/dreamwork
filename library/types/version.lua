---@meta _

--- [SHARED AND MENU]
---
--- A semantic version object.
---
--- See https://semver.org/
---
---@class Version : Object
---@field __class VersionClass
---@field major integer The major version number. (0-1023)
---@field minor integer The minor version number. (0-2047)
---@field patch integer The patch version number. (0-2047)
---@field pre_release string The pre-release identifiers, empty string if none.
---@field build string The build metadata, empty string if none.
local __Version = {}

---@param major integer | nil
---@param minor integer | nil
---@param patch integer | nil
---@param pre_release string | nil
---@param build string | nil
---@protected
function __Version:__init(major, minor, patch, pre_release, build) end

--- [SHARED AND MENU]
---
--- The class used to create new `Version` instances.
---
---@class VersionClass : Version
---@field __base Version
---@overload fun( major: integer?, minor: integer?, patch: integer?, pre_release: string?, build: string? ) : Version
Version = {}

--- [SHARED AND MENU]
---
--- Gets a version object from a version string.
---
--- The string must be a valid semantic version, an optional `v` prefix is allowed.
---
---@param str string The version string in the format `major.minor.patch[-pre_release][+build]`.
---@return Version version_obj The version object.
---@nodiscard
function Version.fromString(str) end

--- [SHARED AND MENU]
---
--- Checks if the string is a valid semantic version.
---
---@param str string The version string.
---@return boolean is_valid `true` if the string is a valid version, `false` otherwise.
---@nodiscard
function Version.isValid(str) end

---@return string
---@protected
function __Version:__tostring() end

---@return string
---@protected
function __Version:__represent() end

---@return integer
---@protected
function __Version:__tonumber() end

---@return integer
---@protected
function __Version:__sizeof(as_bytes) end

--- [SHARED AND MENU]
---
--- Creates a copy of the version.
---
---@param self Version The version.
---@return Version version_obj The new version.
---@nodiscard
function __Version.copy(self) end

---@return Version
---@protected
function __Version:__copy() end

--- [SHARED AND MENU]
---
--- Adds a version to the current version.
---
---@param self Version The version.
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@param pre_release integer | nil The value to add to the last numeric pre-release identifier.
---@return Version version_obj The current version.
---@nodiscard
function __Version.add(self, major, minor, patch, pre_release) end

---@param version_obj Version
---@return Version
---@protected
function __Version:__add(version_obj) end

--- [SHARED AND MENU]
---
--- Subtracts a version from the current version.
---
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@param pre_release integer | nil The value to subtract from the last numeric pre-release identifier.
---@return Version version_obj The current version.
---@nodiscard
function __Version:sub(major, minor, patch, pre_release) end

---@param version_obj Version
---@return Version
---@protected
function __Version:__sub(version_obj) end

--- [SHARED AND MENU]
---
--- Compares two versions by precedence, build metadata is ignored.
---
---@param version_obj Version The version to compare with.
---@return integer comparison `-1` if the current version is lower, `1` if higher, `0` if equal.
---@nodiscard
function __Version:compare(version_obj) end

---@param a Version
---@param b Version
---@return boolean
---@protected
function __Version.__eq(a, b) end

---@param a Version
---@param b Version
---@return boolean
---@protected
function __Version.__lt(a, b) end

---@param a Version
---@param b Version
---@return boolean
---@protected
function __Version.__le(a, b) end

---@alias Version.Comparator { [1]: string, [2]: integer, [3]: integer, [4]: integer, [5]: string }

--- [SHARED AND MENU]
---
--- Checks if the version satisfies the range selector.
---
--- Supports npm-style ranges: `1.2.3`, `>=1.2.3 <2.0.0`, `1.2.x`, `~1.2.3`, `^1.2.3`, `1.2.3 - 2.3.4`, `1.x || >=2.5.0`.
---
---@param selector string The range selector.
---@return boolean is_matched `true` if the version satisfies the range, `false` otherwise.
---@nodiscard
function __Version:match(selector) end

--- `version % selector` and `selector % version`.
---
---@param a Version | string
---@param b Version | string
---@return boolean is_matched
---@nodiscard
---@protected
function __Version.__mod(a, b) end

--- [SHARED AND MENU]
---
--- Checks if the version is caret-compatible ( `^` ) with another version.
---
---@param version_obj Version
---@return boolean
---@protected
function __Version:__pow(version_obj) end

--- [SHARED AND MENU]
---
--- Returns the first version that satisfies the range selector.
---
---@param versions Version[] The versions to search.
---@param selector string The range selector.
---@return Version | nil matched_version The matched version, or `nil` if not found.
---@return integer version_position The position of the matched version, or `-1` if not found.
---@nodiscard
function Version.select(versions, selector) end
