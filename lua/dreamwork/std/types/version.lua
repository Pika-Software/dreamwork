---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc

local raw = std.raw
local raw_tonumber = raw.tonumber

local math = std.math
local math_min, math_max = math.min, math.max

local ascii = std.ascii
local ascii_isAlnum = ascii.isAlnum
local ascii_isDigit = ascii.isDigit

local string = std.string
local string_len, string_sub = string.len, string.sub
local string_char, string_byte = string.char, string.byte
local string_format, string_find = string.format, string.find

local rbit = raw.bit
local rbit_bor = rbit.bor
local rbit_lshift = rbit.lshift
local rbit_unsign = rbit.unsign

local class = std.class

local len = std.len
local error = std.error
local isString = std.isString


---@param str string
---@param start_position integer
---@param end_position integer
---@return boolean
local function is_numeric( str, start_position, end_position )
    for index = start_position, end_position, 1 do
        local uint8 = string_byte( str, index, index )
        if not ascii_isDigit( uint8 ) then
            return false
        end
    end

    return true
end

--- Validates dot-separated identifiers of pre-release or build metadata.
---
---@param str string
---@param is_pre_release boolean If `true`, numeric identifiers must not include leading zeroes.
---@return boolean is_valid
local function is_valid_identifiers( str, is_pre_release )
    local str_length = string_len( str )
    if str_length == 0 then
        return false
    end

    local identifier_start = 1

    for index = 1, str_length + 1, 1 do
        local uint8 = string_byte( str, index, index )
        if uint8 == nil or uint8 == 0x2E --[[ . ]] then
            if index == identifier_start then
                return false
            end

            if is_pre_release and index - identifier_start > 1 and string_byte( str, identifier_start, identifier_start ) == 0x30 --[[ 0 ]] and is_numeric( str, identifier_start, index - 1 ) then
                return false
            end

            identifier_start = index + 1
        elseif not (uint8 == 0x2D --[[ - ]] or ascii_isAlnum( uint8 )) then
            return false
        end
    end

    return true
end

--- Compares two byte ranges in ASCII order.
---
---@param str_a string
---@param start_a integer
---@param end_a integer
---@param str_b string
---@param start_b integer
---@param end_b integer
---@return integer
local function compare_bytes( str_a, start_a, end_a, str_b, start_b, end_b )
    local length_a, length_b = end_a - start_a, end_b - start_b

    for offset = 0, math_min( length_a, length_b ), 1 do
        local uint8_a = string_byte( str_a, start_a + offset, start_a + offset )
        local uint8_b = string_byte( str_b, start_b + offset, start_b + offset )

        if uint8_a ~= uint8_b then
            return uint8_a < uint8_b and -1 or 1
        end
    end

    if length_a == length_b then
        return 0
    elseif length_a < length_b then
        return -1
    end

    return 1
end

--- Compares two pre-release strings according to semver 2.0.0 §11.
---
---@param pre_release_a string
---@param pre_release_b string
---@return integer
local function compare_pre_releases( pre_release_a, pre_release_b )
    if pre_release_a == pre_release_b then
        return 0
    elseif pre_release_a == "" then
        return 1
    elseif pre_release_b == "" then
        return -1
    end

    local length_a, length_b = string_len( pre_release_a ), string_len( pre_release_b )
    local start_a, start_b = 1, 1

    while true do
        if start_a > length_a then
            return start_b > length_b and 0 or -1
        elseif start_b > length_b then
            return 1
        end

        local end_a = (string_find( pre_release_a, ".", start_a, true ) or (length_a + 1)) - 1
        local end_b = (string_find( pre_release_b, ".", start_b, true ) or (length_b + 1)) - 1

        local numeric_a = is_numeric( pre_release_a, start_a, end_a )
        local numeric_b = is_numeric( pre_release_b, start_b, end_b )

        local comparison

        if numeric_a then
            if not numeric_b then
                return -1
            end

            -- numeric identifiers have no leading zeroes, so the longer one is greater
            local size_a, size_b = end_a - start_a, end_b - start_b
            if size_a ~= size_b then
                return size_a < size_b and -1 or 1
            end

            comparison = compare_bytes( pre_release_a, start_a, end_a, pre_release_b, start_b, end_b )
        elseif numeric_b then
            return 1
        else
            comparison = compare_bytes( pre_release_a, start_a, end_a, pre_release_b, start_b, end_b )
        end

        if comparison ~= 0 then
            return comparison
        end

        start_a, start_b = end_a + 2, end_b + 2
    end
end

---@param major_a integer
---@param minor_a integer
---@param patch_a integer
---@param pre_release_a string
---@param major_b integer
---@param minor_b integer
---@param patch_b integer
---@param pre_release_b string
---@return integer
local function compare_fields( major_a, minor_a, patch_a, pre_release_a, major_b, minor_b, patch_b, pre_release_b )
    if major_a ~= major_b then
        return (major_a < major_b) and -1 or 1
    elseif minor_a ~= minor_b then
        return (minor_a < minor_b) and -1 or 1
    elseif patch_a ~= patch_b then
        return (patch_a < patch_b) and -1 or 1
    end

    return compare_pre_releases( pre_release_a, pre_release_b )
end

--- [SHARED AND MENU]
---
--- A semantic version object.
---
--- See https://semver.org/
---
---@class dreamwork.std.Version : dreamwork.std.Object
---@field __class dreamwork.std.VersionClass
---@field major integer The major version number. (0-1023)
---@field minor integer The minor version number. (0-2047)
---@field patch integer The patch version number. (0-2047)
---@field pre_release string The pre-release identifiers, empty string if none.
---@field build string The build metadata, empty string if none.
local Version = class.base( "Version", false, nil )

---@param value integer
---@param max_value integer
---@return boolean
local function is_valid_number( value, max_value )
    return value >= 0 and value <= max_value and value % 1 == 0
end

---@param major integer | nil
---@param minor integer | nil
---@param patch integer | nil
---@param pre_release string | nil
---@param build string | nil
---@protected
function Version:__init( major, minor, patch, pre_release, build )
    if major == nil then
        major = 0
    elseif not is_valid_number( major, 0x3ff ) then
        error( "invalid major version, must be an integer in range 0-1023", 3 )
    end

    if minor == nil then
        minor = 0
    elseif not is_valid_number( minor, 0x7ff ) then
        error( "invalid minor version, must be an integer in range 0-2047", 3 )
    end

    if patch == nil then
        patch = 0
    elseif not is_valid_number( patch, 0x7ff ) then
        error( "invalid patch version, must be an integer in range 0-2047", 3 )
    end

    if pre_release == nil then
        pre_release = ""
    elseif pre_release ~= "" and not is_valid_identifiers( pre_release, true ) then
        error( "invalid pre-release version `" .. pre_release .. "`", 3 )
    end

    if build == nil then
        build = ""
    elseif build ~= "" and not is_valid_identifiers( build, false ) then
        error( "invalid build metadata `" .. build .. "`", 3 )
    end

    self.major = major
    self.minor = minor
    self.patch = patch
    self.pre_release = pre_release
    self.build = build
end

--- [SHARED AND MENU]
---
--- The class used to create new `Version` instances.
---
---@class dreamwork.std.VersionClass : dreamwork.std.Version
---@field __base dreamwork.std.Version
---@overload fun( major: integer?, minor: integer?, patch: integer?, pre_release: string?, build: string? ) : dreamwork.std.Version
local VersionClass = class.create( Version )
std.Version = VersionClass

---@type string[]
local part_names = { "major", "minor", "patch" }

---@param str string
---@param position integer
---@return integer | nil value
---@return integer position
local function read_number( str, position )
    local start_position = position

    while true do
        local uint8 = string_byte( str, position, position )
        if uint8 == nil or not ascii_isDigit( uint8 ) then
            break
        end

        position = position + 1
    end

    local digit_count = position - start_position
    if digit_count == 0 or digit_count > 9 or (digit_count > 1 and string_byte( str, start_position, start_position ) == 0x30 --[[ 0 ]]) then
        return nil, position
    end

    return raw_tonumber( string_sub( str, start_position, position - 1 ), 10 ), position
end

--- Parses a version string.
---
--- In `partial` mode minor and patch can be omitted and any number can be replaced with `x`, `X` or `*`,
--- missing or wildcard numbers are returned as `nil`.
---
---@param str string
---@param partial boolean
---@return string | nil error_message
---@return integer | nil major
---@return integer | nil minor
---@return integer | nil patch
---@return string | nil pre_release
---@return string | nil build
local function parse( str, partial )
    local position = 1

    if string_byte( str, 1, 1 ) == 0x76 --[[ v ]] then
        position = 2
    end

    local major, minor, patch
    local is_wildcard = false

    for part = 1, 3, 1 do
        local uint8 = string_byte( str, position, position )

        if partial and (uint8 == 0x78 --[[ x ]] or uint8 == 0x58 --[[ X ]] or uint8 == 0x2A --[[ * ]]) then
            is_wildcard = true
            position = position + 1
        else
            local value
            value, position = read_number( str, position )

            if value == nil then
                return "invalid " .. part_names[ part ] .. " version"
            end

            if not is_wildcard then
                if part == 1 then
                    major = value
                elseif part == 2 then
                    minor = value
                else
                    patch = value
                end
            end
        end

        if part ~= 3 then
            uint8 = string_byte( str, position, position )

            if uint8 == nil and partial then
                is_wildcard = true
                break
            elseif uint8 ~= 0x2E --[[ . ]] then
                return "missing " .. part_names[ part + 1 ] .. " version"
            end

            position = position + 1
        end
    end

    local pre_release, build = "", ""

    if not is_wildcard or string_byte( str, position, position ) ~= nil then
        local uint8 = string_byte( str, position, position )

        if uint8 == 0x2D --[[ - ]] then
            local build_position = string_find( str, "+", position + 1, true )
            pre_release = string_sub( str, position + 1, build_position and (build_position - 1) )

            if not is_valid_identifiers( pre_release, true ) then
                return "invalid pre-release version"
            end

            position = build_position or (string_len( str ) + 1)
            uint8 = string_byte( str, position, position )
        end

        if uint8 == 0x2B --[[ + ]] then
            build = string_sub( str, position + 1 )

            if not is_valid_identifiers( build, false ) then
                return "invalid build metadata"
            end
        elseif uint8 ~= nil then
            return "unexpected character `" .. string_sub( str, position, position ) .. "`"
        end

        if is_wildcard then
            -- pre-release and build are meaningless for wildcard versions
            pre_release, build = "", ""
        end
    end

    return nil, major, minor, patch, pre_release, build
end

--- [SHARED AND MENU]
---
--- Gets a version object from a version string.
---
--- The string must be a valid semantic version, an optional `v` prefix is allowed.
---
---@param str string The version string in the format `major.minor.patch[-pre_release][+build]`.
---@return dreamwork.std.Version version_obj The version object.
---@nodiscard
function VersionClass.fromString( str )
    local error_message, major, minor, patch, pre_release, build = parse( str, false )
    if error_message ~= nil then
        error( "invalid version string `" .. str .. "`: " .. error_message, 2 )
    end

    return VersionClass( major, minor, patch, pre_release, build )
end

--- [SHARED AND MENU]
---
--- Checks if the string is a valid semantic version.
---
---@param str string The version string.
---@return boolean is_valid `true` if the string is a valid version, `false` otherwise.
---@nodiscard
function VersionClass.isValid( str )
    local error_message, major, minor, patch = parse( str, false )
    return error_message == nil and major <= 0x3ff and minor <= 0x7ff and patch <= 0x7ff
end

do

    ---@param pre_release string
    ---@param build string
    ---@return string
    local function concat_pre_release_and_build( pre_release, build )
        if pre_release == "" then
            if build == "" then
                return ""
            end

            return "+" .. build
        elseif build == "" then
            return "-" .. pre_release
        end

        return "-" .. pre_release .. "+" .. build
    end

    ---@return string
    ---@protected
    function Version:__tostring()
        return string_format( "%d.%d.%d%s", self.major, self.minor, self.patch, concat_pre_release_and_build( self.pre_release, self.build ) )
    end

    ---@return string
    ---@protected
    function Version:__represent()
        return string_format( "Version: %p [%s]", self, self )
    end

end

---@return integer
---@protected
function Version:__tonumber()
    return rbit_unsign( rbit_bor( rbit_lshift( self.major, 22 ), rbit_lshift( self.minor, 11 ), self.patch ), 32 )
end

---@return integer
---@protected
function Version:__sizeof( as_bytes )
    return as_bytes and 4 or 32
end

--- [SHARED AND MENU]
---
--- Creates a copy of the version.
---
---@param self dreamwork.std.Version The version.
---@return dreamwork.std.Version version_obj The new version.
---@nodiscard
local function Version_copy( self )
    return VersionClass( self.major, self.minor, self.patch, self.pre_release, self.build )
end

Version.copy = Version_copy

---@return dreamwork.std.Version
---@protected
function Version:__copy()
    return Version_copy( self )
end

--- Adds `value` to a string of ASCII digits, the result is clamped to `0`.
---
--- Works on the digits directly, so identifiers longer than the float precision are not rounded.
---
---@param str string
---@param start_position integer
---@param end_position integer
---@param value integer
---@return string
local function digits_add( str, start_position, end_position, value )
    local result, carry = "", value
    local index = end_position

    while index >= start_position and carry ~= 0 do
        local digit = (string_byte( str, index, index ) - 0x30) + carry
        carry = (digit - digit % 10) / 10
        result = string_char( 0x30 + digit % 10 ) .. result
        index = index - 1
    end

    if carry < 0 then
        return "0"
    end

    result = string_sub( str, start_position, index ) .. result

    if carry ~= 0 then
        result = string_format( "%d", carry ) .. result
    end

    local first_non_zero = string_find( result, "[^0]" )
    if first_non_zero == nil then
        return "0"
    end

    return string_sub( result, first_non_zero )
end

--- Adds `value` to the last numeric identifier of the pre-release.
---
--- If there is no numeric identifier, `.0` is treated as `-1` ( `alpha` + 1 = `alpha.0` ),
--- negative values leave such pre-release unchanged since there is nothing lower to step down to.
---
---@param pre_release string
---@param value integer
---@return string
local function pre_release_add( pre_release, value )
    local pre_release_length = string_len( pre_release )

    local identifier_start = pre_release_length
    while identifier_start ~= 0 and string_byte( pre_release, identifier_start, identifier_start ) ~= 0x2E --[[ . ]] do
        identifier_start = identifier_start - 1
    end

    if pre_release_length ~= 0 and is_numeric( pre_release, identifier_start + 1, pre_release_length ) then
        return string_sub( pre_release, 1, identifier_start ) .. digits_add( pre_release, identifier_start + 1, pre_release_length, value )
    elseif value <= 0 then
        return pre_release
    elseif pre_release_length == 0 then
        return string_format( "%d", value - 1 )
    end

    return string_format( "%s.%d", pre_release, value - 1 )
end

--- [SHARED AND MENU]
---
--- Adds a version to the current version.
---
---@param self dreamwork.std.Version The version.
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@param pre_release integer | nil The value to add to the last numeric pre-release identifier.
---@return dreamwork.std.Version version_obj The current version.
---@nodiscard
local function Version_add( self, major, minor, patch, pre_release )
    if major ~= nil then
        self.major = math_max( math_min( self.major + major, 0x3ff ), 0 )
    end

    if minor ~= nil then
        self.minor = math_max( math_min( self.minor + minor, 0x7ff ), 0 )
    end

    if patch ~= nil then
        self.patch = math_max( math_min( self.patch + patch, 0x7ff ), 0 )
    end

    if pre_release ~= nil then
        self.pre_release = pre_release_add( self.pre_release, pre_release )
    end

    return self
end

Version.add = Version_add

---@param version_obj dreamwork.std.Version
---@return dreamwork.std.Version
---@protected
function Version:__add( version_obj )
    return Version_add( Version_copy( self ), version_obj.major, version_obj.minor, version_obj.patch )
end

--- [SHARED AND MENU]
---
--- Subtracts a version from the current version.
---
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@param pre_release integer | nil The value to subtract from the last numeric pre-release identifier.
---@return dreamwork.std.Version version_obj The current version.
---@nodiscard
function Version:sub( major, minor, patch, pre_release )
    return Version_add( self, major and -major, minor and -minor, patch and -patch, pre_release and -pre_release )
end

---@param version_obj dreamwork.std.Version
---@return dreamwork.std.Version
---@protected
function Version:__sub( version_obj )
    return Version_add( Version_copy( self ), -version_obj.major, -version_obj.minor, -version_obj.patch )
end

--- [SHARED AND MENU]
---
--- Compares two versions by precedence, build metadata is ignored.
---
---@param version_obj dreamwork.std.Version The version to compare with.
---@return integer comparison `-1` if the current version is lower, `1` if higher, `0` if equal.
---@nodiscard
function Version:compare( version_obj )
    return compare_fields(
        self.major, self.minor, self.patch, self.pre_release,
        version_obj.major, version_obj.minor, version_obj.patch, version_obj.pre_release
    )
end

---@param a dreamwork.std.Version
---@param b dreamwork.std.Version
---@return boolean
---@protected
function Version.__eq( a, b )
    return a.major == b.major and
        a.minor == b.minor and
        a.patch == b.patch and
        a.pre_release == b.pre_release
end

---@param a dreamwork.std.Version
---@param b dreamwork.std.Version
---@return boolean
---@protected
function Version.__lt( a, b )
    return compare_fields( a.major, a.minor, a.patch, a.pre_release, b.major, b.minor, b.patch, b.pre_release ) < 0
end

---@param a dreamwork.std.Version
---@param b dreamwork.std.Version
---@return boolean
---@protected
function Version.__le( a, b )
    return compare_fields( a.major, a.minor, a.patch, a.pre_release, b.major, b.minor, b.patch, b.pre_release ) <= 0
end

--[[

    Ranges
        more info: https://docs.npmjs.com/cli/v6/using-npm/semver#ranges

    Every range is compiled into a list of comparator sets,
    each comparator set is a list of primitive comparators ( <, <=, >, >=, = ).

--]]

---@alias dreamwork.std.Version.Comparator { [1]: string, [2]: integer, [3]: integer, [4]: integer, [5]: string }

---@type dreamwork.std.Version.Comparator
local comparator_any = { "*", 0, 0, 0, "" }

---@type dreamwork.std.Version.Comparator
local comparator_none = { "<", 0, 0, 0, "0" }

---@param set dreamwork.std.Version.Comparator[]
---@param operator string
---@param major integer
---@param minor integer
---@param patch integer
---@param pre_release string | nil
local function push( set, operator, major, minor, patch, pre_release )
    set[ #set + 1 ] = { operator, major, minor, patch, pre_release or "" }
end

--- Keys are operator bytes, two-byte operators are packed as `( byte1 << 8 ) | byte2`.
---
---@type table<integer, fun( set: dreamwork.std.Version.Comparator[], major: ( integer | nil ), minor: ( integer | nil ), patch: ( integer | nil ), pre_release: ( string | nil ) )>
local desugars = {}

-- Primitive operators and X-Ranges 1.2.x 1.X 1.2.* *
-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
do

    ---@param operator string
    local function x_range( operator )
        return function( set, major, minor, patch, pre_release )
            if patch ~= nil then
                push( set, operator, major, minor, patch, pre_release )
            elseif major == nil then
                set[ #set + 1 ] = (operator == "<" or operator == ">") and comparator_none or comparator_any
            elseif operator == ">" then
                if minor == nil then
                    push( set, ">=", major + 1, 0, 0 )
                else
                    push( set, ">=", major, minor + 1, 0 )
                end
            elseif operator == ">=" then
                push( set, ">=", major, minor or 0, 0 )
            elseif operator == "<" then
                push( set, "<", major, minor or 0, 0, "0" )
            elseif minor == nil then
                if operator == "=" then
                    push( set, ">=", major, 0, 0 )
                end

                push( set, "<", major + 1, 0, 0, "0" )
            else
                if operator == "=" then
                    push( set, ">=", major, minor, 0 )
                end

                push( set, "<", major, minor + 1, 0, "0" )
            end
        end
    end

    desugars[ 0x3D --[[ = ]] ] = x_range( "=" )
    desugars[ 0x3C --[[ < ]] ] = x_range( "<" )
    desugars[ 0x3C3D --[[ <= ]] ] = x_range( "<=" )
    desugars[ 0x3E --[[ > ]] ] = x_range( ">" )
    desugars[ 0x3E3D --[[ >= ]] ] = x_range( ">=" )

end



do

    -- Tilde Ranges ~1.2.3 ~1.2 ~1
    -- Allows patch-level changes if a minor version is specified on the comparator. Allows minor-level changes if not.
    -- https://docs.npmjs.com/cli/v6/using-npm/semver#tilde-ranges-123-12-1
    local function tilde( set, major, minor, patch, pre_release )
        if major == nil then
            set[ #set + 1 ] = comparator_any
        elseif minor == nil then
            push( set, ">=", major, 0, 0 )
            push( set, "<", major + 1, 0, 0, "0" )
        else
            push( set, ">=", major, minor, patch or 0, pre_release )
            push( set, "<", major, minor + 1, 0, "0" )
        end
    end

    desugars[ 0x7E --[[ ~ ]] ] = tilde
    desugars[ 0x7E3E --[[ ~> ]] ] = tilde

end

-- Caret Ranges ^1.2.3 ^0.2.5 ^0.0.4
-- Allows changes that do not modify the left-most non-zero digit in the [major, minor, patch] tuple.
-- In other words, this allows patch and minor updates for versions 1.0.0 and above, patch updates for
-- versions 0.X >=0.1.0, and no updates for versions 0.0.X.
-- https://docs.npmjs.com/cli/v6/using-npm/semver#caret-ranges-123-025-004
desugars[ 0x5E --[[ ^ ]] ] = function( set, major, minor, patch, pre_release )
    if major == nil then
        set[ #set + 1 ] = comparator_any
    elseif minor == nil then
        push( set, ">=", major, 0, 0 )
        push( set, "<", major + 1, 0, 0, "0" )
    elseif patch == nil then
        push( set, ">=", major, minor, 0 )

        if major == 0 then
            push( set, "<", 0, minor + 1, 0, "0" )
        else
            push( set, "<", major + 1, 0, 0, "0" )
        end
    else
        push( set, ">=", major, minor, patch, pre_release )

        if major ~= 0 then
            push( set, "<", major + 1, 0, 0, "0" )
        elseif minor ~= 0 then
            push( set, "<", 0, minor + 1, 0, "0" )
        else
            push( set, "<", 0, 0, patch + 1, "0" )
        end
    end
end

-- Hyphen Ranges X.Y.Z - A.B.C
-- https://docs.npmjs.com/cli/v6/using-npm/semver#hyphen-ranges-xyz---abc
---@param set dreamwork.std.Version.Comparator[]
---@param from string
---@param to string
---@return string | nil error_message
local function hyphen_range( set, from, to )
    local error_message, major, minor, patch, pre_release = parse( from, true )
    if error_message ~= nil then
        return error_message
    end

    if major ~= nil then
        push( set, ">=", major, minor or 0, patch or 0, pre_release )
    end

    error_message, major, minor, patch, pre_release = parse( to, true )
    if error_message ~= nil then
        return error_message
    end

    if major == nil then
        if set[ 1 ] == nil then
            set[ 1 ] = comparator_any
        end
    elseif minor == nil then
        push( set, "<", major + 1, 0, 0, "0" )
    elseif patch == nil then
        push( set, "<", major, minor + 1, 0, "0" )
    else
        push( set, "<=", major, minor, patch, pre_release )
    end

    return nil
end

---@param uint8 integer | nil
---@return boolean
local function is_operator_byte( uint8 )
    return uint8 == 0x3C --[[ < ]] or uint8 == 0x3E --[[ > ]] or uint8 == 0x3D --[[ = ]] or uint8 == 0x7E --[[ ~ ]] or uint8 == 0x5E --[[ ^ ]]
end

---@param str string
---@return string[] words
---@return integer word_count
local function split_words( str )
    local words, word_count = {}, 0
    local position, str_length = 1, string_len( str )

    while position <= str_length do
        local word_start, word_end = string_find( str, "[^%s]+", position )
        if word_start == nil then
            break
        end

        word_count = word_count + 1
        words[ word_count ] = string_sub( str, word_start, word_end )
        position = word_end + 1
    end

    return words, word_count
end

---@param str string
---@return dreamwork.std.Version.Comparator[] | nil set
---@return string | nil error_message
local function compile_set( str )
    local words, word_count = split_words( str )
    local index = 1

    ---@type dreamwork.std.Version.Comparator[]
    local set = {}

    while index <= word_count do
        local word = words[ index ]

        if words[ index + 1 ] == "-" then
            local to = words[ index + 2 ]
            if to == nil or is_operator_byte( string_byte( word, 1, 1 ) ) or is_operator_byte( string_byte( to, 1, 1 ) ) then
                return nil, "invalid hyphen range"
            end

            ---@type dreamwork.std.Version.Comparator[]
            local hyphen_set = {}

            local error_message = hyphen_range( hyphen_set, word, to )
            if error_message ~= nil then
                return nil, error_message
            end

            for i = 1, #hyphen_set, 1 do
                set[ #set + 1 ] = hyphen_set[ i ]
            end

            index = index + 3
        else
            local operator_end = 0
            while is_operator_byte( string_byte( word, operator_end + 1, operator_end + 1 ) ) do
                operator_end = operator_end + 1
            end

            local operator_key

            if operator_end == 0 then
                operator_key = 0x3D --[[ = ]]
            elseif operator_end == 1 then
                operator_key = string_byte( word, 1, 1 )
            elseif operator_end == 2 then
                local uint8_1, uint8_2 = string_byte( word, 1, 2 )
                operator_key = rbit_bor( rbit_lshift( uint8_1, 8 ), uint8_2 )
            end

            local desugar_fn = operator_key and desugars[ operator_key ]
            if desugar_fn == nil then
                return nil, "invalid operator `" .. string_sub( word, 1, operator_end ) .. "`"
            end

            local version_str = string_sub( word, operator_end + 1 )

            -- operator separated from version by whitespace: `>= 1.2.3`
            if version_str == "" and operator_end ~= 0 then
                index = index + 1
                version_str = words[ index ]

                if version_str == nil then
                    return nil, "missing version after operator `" .. string_sub( word, 1, operator_end ) .. "`"
                end
            end

            local error_message, major, minor, patch, pre_release = parse( version_str, true )
            if error_message ~= nil then
                return nil, error_message
            end

            desugar_fn( set, major, minor, patch, pre_release )

            index = index + 1
        end
    end

    if set[ 1 ] == nil then
        set[ 1 ] = comparator_any
    end

    return set
end

---@type table<string, dreamwork.std.Version.Comparator[][]>
local range_cache = {}
gc.setTableRules( range_cache, false, true )

---@param selector string
---@return dreamwork.std.Version.Comparator[][] | nil sets
---@return string | nil error_message
local function compile_range( selector )
    local sets = range_cache[ selector ]
    if sets ~= nil then
        return sets
    end

    sets = {}

    local set_count = 0
    local position = 1

    while true do
        local or_position = string_find( selector, "||", position, true )

        local set, error_message = compile_set( string_sub( selector, position, or_position and (or_position - 1) ) )
        if set == nil then
            return nil, error_message
        end

        set_count = set_count + 1
        sets[ set_count ] = set

        if or_position == nil then
            break
        end

        position = or_position + 2
    end

    range_cache[ selector ] = sets
    return sets
end

---@param version_obj dreamwork.std.Version
---@param comparator dreamwork.std.Version.Comparator
---@return boolean
local function test_comparator( version_obj, comparator )
    local operator = comparator[ 1 ]
    if operator == "*" then
        return true
    end

    local comparison = compare_fields(
        version_obj.major, version_obj.minor, version_obj.patch, version_obj.pre_release,
        comparator[ 2 ], comparator[ 3 ], comparator[ 4 ], comparator[ 5 ]
    )

    if operator == "<" then
        return comparison < 0
    elseif operator == "<=" then
        return comparison <= 0
    elseif operator == ">" then
        return comparison > 0
    elseif operator == ">=" then
        return comparison >= 0
    end

    return comparison == 0
end

---@param version_obj dreamwork.std.Version
---@param set dreamwork.std.Version.Comparator[]
---@return boolean
local function test_set( version_obj, set )
    local comparator_count = #set

    for index = 1, comparator_count, 1 do
        if not test_comparator( version_obj, set[ index ] ) then
            return false
        end
    end

    if version_obj.pre_release == "" then
        return true
    end

    -- pre-release versions only match if at least one comparator
    -- with the same [major, minor, patch] tuple also has a pre-release
    local major, minor, patch = version_obj.major, version_obj.minor, version_obj.patch

    for index = 1, comparator_count, 1 do
        local comparator = set[ index ]
        if comparator[ 1 ] ~= "*" and comparator[ 5 ] ~= "" and comparator[ 2 ] == major and comparator[ 3 ] == minor and comparator[ 4 ] == patch then
            return true
        end
    end

    return false
end

---@param version_obj dreamwork.std.Version
---@param sets dreamwork.std.Version.Comparator[][]
---@return boolean
local function test_sets( version_obj, sets )
    for index = 1, #sets, 1 do
        if test_set( version_obj, sets[ index ] ) then
            return true
        end
    end

    return false
end

--- [SHARED AND MENU]
---
--- Checks if the version satisfies the range selector.
---
--- Supports npm-style ranges: `1.2.3`, `>=1.2.3 <2.0.0`, `1.2.x`, `~1.2.3`, `^1.2.3`, `1.2.3 - 2.3.4`, `1.x || >=2.5.0`.
---
---@param selector string The range selector.
---@return boolean is_matched `true` if the version satisfies the range, `false` otherwise.
---@nodiscard
function Version:match( selector )
    local sets, error_message = compile_range( selector )
    if sets == nil then
        error( "invalid version range `" .. selector .. "`: " .. error_message, 2 )
    end

    return test_sets( self, sets )
end

local Version_match = Version.match

--- `version % selector` and `selector % version`.
---
---@param a dreamwork.std.Version | string
---@param b dreamwork.std.Version | string
---@return boolean is_matched
---@nodiscard
---@protected
function Version.__mod( a, b )
    if isString( a ) then
        ---@cast a string
        ---@cast b dreamwork.std.Version
        return Version_match( b, a )
    end

    ---@cast a dreamwork.std.Version
    ---@cast b string
    return Version_match( a, b )
end

--- [SHARED AND MENU]
---
--- Checks if the version is caret-compatible ( `^` ) with another version.
---
---@param version_obj dreamwork.std.Version
---@return boolean
---@protected
function Version:__pow( version_obj )
    local major, minor, patch, pre_release = version_obj.major, version_obj.minor, version_obj.patch, version_obj.pre_release
    local self_major, self_minor, self_patch, self_pre_release = self.major, self.minor, self.patch, self.pre_release

    -- same as the `^` desugar ( >=lower <upper-0 ) and `test_set`, without allocating a comparator set
    if compare_fields( self_major, self_minor, self_patch, self_pre_release, major, minor, patch, pre_release ) < 0 then
        return false
    end

    local upper
    if major ~= 0 then
        upper = compare_fields( self_major, self_minor, self_patch, self_pre_release, major + 1, 0, 0, "0" )
    elseif minor ~= 0 then
        upper = compare_fields( self_major, self_minor, self_patch, self_pre_release, 0, minor + 1, 0, "0" )
    else
        upper = compare_fields( self_major, self_minor, self_patch, self_pre_release, 0, 0, patch + 1, "0" )
    end

    if upper >= 0 then
        return false
    end

    return self_pre_release == "" or (pre_release ~= "" and self_major == major and self_minor == minor and self_patch == patch)
end

--- [SHARED AND MENU]
---
--- Returns the first version that satisfies the range selector.
---
---@param versions dreamwork.std.Version[] The versions to search.
---@param selector string The range selector.
---@return dreamwork.std.Version | nil matched_version The matched version, or `nil` if not found.
---@return integer version_position The position of the matched version, or `-1` if not found.
---@nodiscard
function VersionClass.select( versions, selector )
    local sets, error_message = compile_range( selector )
    if sets == nil then
        error( "invalid version range `" .. selector .. "`: " .. error_message, 2 )
    end

    for index = 1, len( versions ), 1 do
        local version_obj = versions[ index ]
        if test_sets( version_obj, sets ) then
            return version_obj, index
        end
    end

    return nil, -1
end
