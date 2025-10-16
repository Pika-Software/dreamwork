-- Semver lua parser. Based on https://github.com/kikito/semver.lua
-- https://github.com/Pika-Software/gpm_legacy/blob/main/lua/dreamwork/sh_semver.lua

--[[

	Version Structure:
		[ 0 ] - full string
		[ 1 ] - major
		[ 2 ] - minor
		[ 3 ] - patch
		[ 4 ] - pre_release
		[ 5 ] - build

--]]

local _G = _G

---@class dreamwork.std
local std = _G.dreamwork.std

local table_sort = std.table.sort
local tostring, tonumber, raw_get = std.tostring, std.tonumber, std.raw.get

local bit_band, bit_bor, bit_lshift, bit_rshift
do
	local bit = std.bit
	bit_band, bit_bor, bit_lshift, bit_rshift = bit.band, bit.bor, bit.lshift, bit.rshift
end

local isString, isNumber = std.isString, std.isNumber
local math_isuint, math_max = std.math.isuint, std.math.max

local string = std.string
local string_match, string_gsub, string_find, string_sub = string.match, string.gsub, string.find, string.sub

-- TODO: update and replace trash keys

local smallerPreRelease
do

	local function compare( a, b )
		return a == b and 0 or a < b and -1 or 1
	end

	local function compareIDs( a, b )
		if a == b then
			return 0
		elseif not a then
			return -1
		elseif not b then
			return 1
		end

		local a_num, b_num = tonumber( a, 10 ), tonumber( b, 10 )
		if a_num and b_num then
			return compare( a_num, b_num )
		elseif a_num then
			return -1
		elseif b_num then
			return 1
		else
			return compare( a, b )
		end
	end

	local string_byteSplit = string.byteSplit

	function smallerPreRelease( first, second )
		if not first or first == second then
			return false
		elseif not second then
			return true
		end

		local fisrt, fcount = string_byteSplit( first, 0x2E --[[ . ]] )

		local scount
		second, scount = string_byteSplit( second, 0x2E --[[ . ]] )

		local comparison
		for index = 1, fcount do
			comparison = compareIDs( fisrt[ index ], second[ index ] )
			if comparison ~= 0 then
				return comparison == -1
			end
		end

		return fcount < scount
	end

end

---@param str? string
---@return string? pre_release
local function parse_pre_release( str, error_level )
	if str == nil or str == "" then return end

	local pre_release = string_match( str, "^-(%w[%.%w-]*)$" )
	if not pre_release or string_match( pre_release, "%.%." ) then
		if error_level == nil then error_level = 1 end
		error_level = error_level + 1

		error( "the pre-release '" .. str .. "' is not valid", error_level )
	end

	return pre_release
end

---@param str? string
---@return string? build
local function parse_build( str, error_level )
	if str == nil or str == "" then return end

	local build = string_match( str, "^%+(%w[%.%w-]*)$" )
	if not build or string_match( build, "%.%." ) then
		if error_level == nil then error_level = 1 end
		error_level = error_level + 1

		error( "the build '" .. str .. "' is not valid", error_level )
	end

	return build
end

local parse_pre_release_and_build
do

	local string_byte = string.byte

	---@param str? string
	---@return string? pre_release
	---@return string? build
	function parse_pre_release_and_build( str, error_level )
		if error_level == nil then error_level = 1 end
		if str == nil or str == "" then return end
		error_level = error_level + 1

		local pre_release, build = string_match( str, "^(%-[^+]+)(%+.+)$" )
		if pre_release == nil or build == nil then
			local byte = string_byte( str, 1 )
			if byte == 0x2D --[[ - ]] then
				pre_release = parse_pre_release( str, error_level )
			elseif byte == 0x2B --[[ + ]] then
				build = parse_build( str, error_level )
			else
				error( "the parameter '" .. str .. "' must begin with + or - to denote a pre-release or a build", error_level )
			end
		end

		return pre_release, build
	end

end

---@param major integer
---@param minor integer
---@param patch integer
---@param pre_release string?
---@param build string?
---@return string
local function numbersToString( major, minor, patch, pre_release, build )
	if pre_release and build then
		return major .. "." .. minor .. "." .. patch .. "-" .. pre_release .. "+" .. build
	elseif pre_release then
		return major .. "." .. minor .. "." .. patch .. "-" .. pre_release
	elseif build then
		return major .. "." .. minor .. "." .. patch .. "+" .. build
	else
		return major .. "." .. minor .. "." .. patch
	end
end

--- [SHARED AND MENU]
---
---
---@param major integer | string The major version number.
---@param minor? integer The minor version number.
---@param patch? integer The patch version number.
---@param pre_release? string | integer The pre-release version number.
---@param build? string The build version number.
---@return integer major The major version.
---@return integer minor The minor version.
---@return integer patch The patch version.
---@return string pre_release The pre-release version.
---@return string build The build version.
local function parse( major, minor, patch, pre_release, build, error_level )
	if error_level == nil then error_level = 1 end
	error_level = error_level + 1

	if major == nil then
		error( "at least one parameter is needed", error_level )
	end

	if isNumber( major ) then
		---@cast major number

		if not math_isuint( major ) then
			error( "major version must be unsigned integer", error_level )
		end

		---@cast major integer

		if minor == nil then
			minor = 0
		elseif not ( isNumber( minor ) and math_isuint( minor ) ) then
			error( "minor version must be unsigned integer number", error_level )
			error( "minor version must be a number", error_level )
		end

		---@cast minor integer

		if patch == nil then
			patch = 0
		elseif not ( isNumber( patch ) and math_isuint( patch ) ) then
			error( "patch version must be unsigned integer number", error_level )
		end

		---@cast patch integer

		if isString( build ) then
			---@cast build string

			if isString( pre_release ) then
				---@cast pre_release string
				pre_release = parse_pre_release( pre_release, error_level )
			end

			build = parse_build( build )
		elseif isNumber( pre_release ) then
			---@cast pre_release number

			pre_release, build = parse_pre_release_and_build( tostring( pre_release ), error_level )
			---@cast pre_release string?
			---@cast build string?
		end
	else
		local extra
		major, minor, patch, extra = string_match( tostring( major ), "^(%d+)%.?(%d*)%.?(%d*)(.-)$" )

		if major == nil then
			error( "the major version is missing", 2 )
		end

		major = tonumber( major, 10 )
		---@cast major integer

		if minor == nil or minor == "" then
			minor = 0
		else
			minor = tonumber( minor, 10 )
		end

		---@cast minor integer

		if patch == nil or patch == "" then
			patch = 0
		else
			patch = tonumber( patch, 10 )
		end

		---@cast patch integer

		pre_release, build = parse_pre_release_and_build( extra, error_level )
		---@cast pre_release string?
	end

	if major > 0x3ff or minor > 0x7ff or patch > 0x7ff then
		error( "version is too large (max 1023.2047.2047)", 2 )
	elseif major < 0 or minor < 0 or patch < 0 then
		error( "version is too small (min 0.0.0)", 2 )
	end

	return major, minor, patch, pre_release or "", build or ""
end

local VersionClass

--- [SHARED AND MENU]
---
--- The Version object.
---@alias Version dreamwork.std.Version
---@class dreamwork.std.Version : dreamwork.std.Object
---@field __class dreamwork.std.VersionClass
local Version = std.class.base( "Version" )

--- [SHARED AND MENU]
---
--- Returns the next major version.
---@return dreamwork.std.Version object The next major version.
local function nextMajor( self )
	return VersionClass( self[ 1 ] + 1, 0, 0 )
end

Version.nextMajor = nextMajor

--- [SHARED AND MENU]
---
--- Returns the next minor version.
---@return dreamwork.std.Version object The next minor version.
local function nextMinor( self )
	return VersionClass( self[ 1 ], self[ 2 ] + 1, 0 )
end

Version.nextMinor = nextMinor

--- [SHARED AND MENU]
---
--- Returns the next patch version.
---@return dreamwork.std.Version object The next patch version.
local function nextPatch( self )
	return VersionClass( self[ 1 ], self[ 2 ], self[ 3 ] + 1 )
end

Version.nextPatch = nextPatch

---@protected
function Version:__tonumber()
	local major = tonumber( self[ 1 ], 10 )
	if major > 0x3ff then
		error( "major version is too large (max 1023)", 2 )
	end

	local minor = tonumber( self[ 2 ], 10 )
	if minor > 0x7ff then
		error( "minor version is too large (max 2047)", 2 )
	end

	local patch = tonumber( self[ 3 ], 10 )
	if patch > 0x7ff then
		error( "patch version is too large (max 2047)", 2 )
	end

	return bit_bor( bit_lshift( patch, 21 ), bit_lshift( minor, 10 ), major )
end

do

	local key2index = {
		name = 0,
		major = 1,
		minor = 2,
		patch = 3,
		prerelease = 4,
		build = 5
	}

	---@protected
	function Version:__index( key )
		local index = key2index[ key ]
		if index == nil then
			return raw_get( Version, key )
		else
			return raw_get( self, index )
		end
	end

	Version.__newindex = std.debug.fempty

end

---@protected
function Version:__tostring()
	return self[ 0 ]
end

---@protected
function Version:__eq( other )
	return self[ 0 ] == other[ 0 ]
end

---@protected
function Version:__lt( other )
	if self[ 1 ] ~= other[ 1 ] then
		return self[ 1 ] < other[ 1 ]
	elseif self[ 2 ] ~= other[ 2 ] then
		return self[ 2 ] < other[ 2 ]
	elseif self[ 3 ] ~= other[ 3 ] then
		return self[ 3 ] < other[ 3 ]
	else
		return smallerPreRelease( self[ 4 ], other[ 4 ] )
	end
end

---@protected
function Version:__le( other )
	return self == other or self < other
end

---@protected
function Version:__pow( other )
	if self[ 1 ] == 0 then
		return self == other
	else
		return self[ 1 ] == other[ 1 ] and self[ 2 ] <= other[ 2 ]
	end
end

do

	local string_byteCount, string_trim = string.byteCount, string.trim

	local operators = {
		-- primitive operators
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#ranges
		["<"] = function( self, sv ) return self < sv end,
		[">"] = function( self, sv, xrange )
			if xrange > 0 then
				if xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self >= sv
			else
				return self > sv
			end
		end,
		["<="] = function( self, sv, xrange )
			if xrange > 0 then
				if xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self < sv
			else
				return self <= sv
			end
		end,
		[">="] = function( self, sv ) return self >= sv end,
		["="] = function( self, sv, xrange )
			if xrange > 0 then
				if self < sv then
					return false
				elseif xrange == 1 then
					sv = nextMinor( sv )
				elseif xrange == 2 then
					sv = nextMajor( sv )
				end

				return self < sv
			else
				return self == sv
			end
		end,

		-- Caret Ranges ^1.2.3 ^0.2.5 ^0.0.4
		-- Allows changes that do not modify the left-most non-zero digit in the [major, minor, patch] tuple.
		-- In other words, this allows patch and minor updates for versions 1.0.0 and above, patch updates for
		-- versions 0.X >=0.1.0, and no updates for versions 0.0.X.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#caret-ranges-123-025-004
		["^"] = function( self, sv, xrange )
			if sv[ 1 ] == 0 and xrange < 2 then
				if sv[ 2 ] == 0 and xrange < 1 then
					return self[ 1 ] == 0 and self[ 2 ] == 0 and self >= sv and self < nextPatch( sv )
				else
					return self[ 1 ] == 0 and self >= sv and self < nextMinor( sv )
				end
			else
				return self[ 1 ] == sv[ 1 ] and self >= sv and self < nextMajor( sv )
			end
		end,

		-- Tilde Ranges ~1.2.3 ~1.2 ~1
		-- Allows patch-level changes if a minor version is specified on the comparator. Allows minor-level changes if not.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#tilde-ranges-123-12-1
		["~"] = function( self, sv, xrange )
			if self < sv then
				return false
			elseif xrange == 2 then
				return self < nextMajor( sv )
			else
				return self < nextMinor( sv )
			end
		end
	}

	-- TODO: implement separated __mod aka :select or :match ...

	---@protected
	function Version:__mod( str )
		-- spaces clean up
		str = string_trim( string_gsub( str, "%s+", " " ), "%s", 0 )

		-- version range := comparator sets
		if string_find( str, "||", 1, true ) then
			local pointer = 1
			while true do
				local position = string_find( str, "||", pointer, true )
				if self % string_sub( str, pointer, position and ( position - 1 ) ) then
					return true
				elseif position == nil then
					return false
				else
					pointer = position + 2
				end
			end
		end

		-- comparator set := comparators
		if string_find( str, " ", 1, true ) then
			local pos, part
			local start = 1
			while true do
				pos = string_find( str, " ", start, true )
				part = string_sub( str, start, pos and ( pos - 1 ) )

				-- Hyphen Ranges: X.Y.Z - A.B.C
				-- https://docs.npmjs.com/cli/v6/using-npm/semver#hyphen-ranges-xyz---abc
				if pos ~= nil and string_sub( str, pos, pos + 2 ) == " - " then
					if not ( self % ( ">=" .. part ) ) then
						return false
					end

					start = pos + 3
					pos = string_find( str, " ", start, true )
					part = string_sub( str, start, pos and ( pos - 1 ) )

					if not ( self % ( "<=" .. part ) ) then
						return false
					end
				elseif not ( self % part ) then
					return false
				end

				if pos == nil then
					return true
				end

				start = pos + 1
			end

			return true
		end

		-- comparators := operator + version
		str = string_gsub( string_gsub( str, "^=", "" ), "^v", "" )

		-- X-Ranges *
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		-- TODO: replace with byte analysis
		if str == "" or str == "*" then
			return self % ">=0.0.0"
		end

		local pos = string_find( str, "%d" )
		if pos == nil then
			error( "Version range must starts with number: " .. str, 2 )
		end

		---@cast pos integer

		-- X-Ranges 1.2.x 1.X 1.2.*
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		local operator
		if pos == 1 then
			operator = "="
		else
			operator = string_sub( str, 1, pos - 1 )
		end

		local name = string_gsub( string_sub( str, pos ), "%.[xX*]", "" )

		local xrange = math_max( 2 - string_byteCount( name, 0x2E --[[ . ]] ), 0 )
		for _ = 1, xrange do
			name = name .. ".0"
		end

		local fn = operators[ operator ]
		if fn == nil then
			error( "Invaild operator: '" .. operator .. "'", 2 )
		else
			return fn( self, VersionClass( name ), xrange )
		end
	end

end

do

	local debug_getmetatable = std.debug.getmetatable
	local setmetatable = std.setmetatable

	---@type table<string, dreamwork.std.Version>
	local versions = {}

	std.debug.gc.setTableRules( versions, false, true )

	---@protected
	function Version:__new( major, minor, patch, pre_release, build )
		if debug_getmetatable( major ) == Version then return major end

		major, minor, patch, pre_release, build = parse( major, minor, patch, pre_release, build )

		local name = numbersToString( major, minor, patch, pre_release, build )
		---@cast name string

		local object = versions[ name ]
		if object == nil then
			---@diagnostic disable-next-line: missing-fields
			object = {
				[ 0 ] = name,
				[ 1 ] = major,
				[ 2 ] = minor,
				[ 3 ] = patch,
				[ 4 ] = pre_release,
				[ 5 ] = build
			}

			setmetatable( object, Version )
			versions[ name ] = object
		end

		return object
	end

end

--- [SHARED AND MENU]
---
--- Version class.
---
---@class dreamwork.std.VersionClass : dreamwork.std.Version
---@field __base dreamwork.std.Version
---@overload fun( major: string | number | Version, minor: number?, patch: number?, pre_release: string?, build: string? ) : dreamwork.std.Version
VersionClass = std.class.create( Version )
std.Version = VersionClass

--- [SHARED AND MENU]
---
--- Converts `major`, `minor`, `patch`, `pre_release`, and `build` to a string.
---@param major number The major version.
---@param minor? number The minor version.
---@param patch? number The patch version.
---@param pre_release? string The pre-release version.
---@param build? string The build version.
---@return string version The version string.
function VersionClass.asString( major, minor, patch, pre_release, build )
	return numbersToString( parse( major, minor, patch, pre_release, build ) )
end

--- [SHARED AND MENU]
---
--- Creates a Version object from an unsigned long.
---@param uint integer The unsigned long.
---@return dreamwork.std.Version object The Version object.
function VersionClass.fromULong( uint )
	return VersionClass( bit_band( uint, 0x3ff ), bit_band( bit_rshift( uint, 10 ), 0x7ff ), bit_band( bit_rshift( uint, 21 ), 0x7ff ) )
end

do

	local function sort_fn( a, b ) return a > b end

	--- [SHARED AND MENU]
	---
	--- Selects the first version in `tbl` that matches `target`.
	---@param target string The version selector.
	---@param tbl table<string | dreamwork.std.Version> The table to search.
	---@return dreamwork.std.Version? version The first version that matches `target`.
	---@return integer index The index of the version in `tbl`.
	function VersionClass.select( target, tbl )
		table_sort( tbl, sort_fn )

		for index = 1, #tbl, 1 do
			local version = VersionClass( tbl[ index ] )
			if version % target then return version, index end
		end

		return nil, -1
	end

end
