---@class dreamwork.std
local std = _G.dreamwork.std

local raw = std.raw
local raw_tonumber = raw.tonumber

local gc_setTableRules = std.gc.setTableRules

local bit = std.bit
local bit_bor, bit_lshift = bit.bor, bit.lshift

local string = std.string
local string_byte = string.byte
local string_format = string.format

local math = std.math
local math_min = math.min
local math_max = math.max

---@type table<integer, table<string, dreamwork.std.Version>>
local registry = {}

std.setmetatable( registry, {
	__index = function( self, uint32 )
		local map = {}
		gc_setTableRules( map, false, true )
		self[ uint32 ] = map
		return map
	end
} )

---@type table<dreamwork.std.Version, integer>
local majors = {}
gc_setTableRules( majors, true, false )

---@type table<dreamwork.std.Version, integer>
local minors = {}
gc_setTableRules( minors, true, false )

---@type table<dreamwork.std.Version, integer>
local patches = {}
gc_setTableRules( patches, true, false )

---@type table<dreamwork.std.Version, string>
local pre_releases = {}
gc_setTableRules( pre_releases, true, false )

---@type table<dreamwork.std.Version, string>
local builds = {}
gc_setTableRules( builds, true, false )

---@type table<dreamwork.std.Version, string>
local pre_release_with_builds = {}
gc_setTableRules( pre_release_with_builds, true, false )

local operators = {}

---@param x integer
---@param y integer
---@param z integer
local function xyz_uint32( x, y, z )
	return bit_bor( bit_lshift( z, 21 ), bit_lshift( y, 10 ), x ) % 0x100000000
end

---@param pre_release? string
---@param build? string
---@return string
local function concat_pre_release_and_build( pre_release, build )
	if pre_release == nil then
		if build == nil then
			return ""
		else
			return "+" .. build
		end
	elseif build == nil then
		return "-" .. pre_release
	else
		return "-" .. pre_release .. "+" .. build
	end
end

---@class dreamwork.std.Version : dreamwork.std.Object
---@field __class dreamwork.std.VersionClass
---@field major integer The major version number. (0-1023)
---@field minor integer The minor version number. (0-2047)
---@field patch integer The patch version number. (0-2047)
local Version = std.class.base( "Version", true )

---@class dreamwork.std.VersionClass : dreamwork.std.Version
---@field __base dreamwork.std.Version
---@overload fun( major: integer, minor: integer, patch: integer, pre_release: string?, build: string? ) : dreamwork.std.Version
local VersionClass = std.class.create( Version )
std.Version = VersionClass

---@param major integer | nil
---@param minor integer | nil
---@param patch integer | nil
---@param pre_release string | nil
---@param build string | nil
---@return dreamwork.std.Version | nil
---@protected
function VersionClass:__new( major, minor, patch, pre_release, build )
	if major == nil then
		major = 0
	elseif major > 0x3ff then
		error( "major version is too large (max 1023)", 3 )
	end

	if minor == nil then
		minor = 1
	elseif minor > 0x7ff then
		error( "minor version is too large (max 2047)", 3 )
	end

	if patch == nil then
		patch = 0
	elseif patch > 0x7ff then
		error( "patch version is too large (max 2047)", 3 )
	end

	return registry[ xyz_uint32( major, minor, patch ) ][ concat_pre_release_and_build( pre_release, build ) ]
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
	end

	if minor == nil then
		minor = 1
	end

	if patch == nil then
		patch = 0
	end

	majors[ self ] = major
	minors[ self ] = minor
	patches[ self ] = patch

	builds[ self ] = build
	pre_releases[ self ] = pre_release

	local pre_release_and_build = concat_pre_release_and_build( pre_release, build )
	pre_release_with_builds[ self ] = pre_release_and_build

	registry[ xyz_uint32( major, minor, patch ) ][ pre_release_and_build ] = self
end

---@return string
---@protected
function Version:__tostring()
	return string_format( "%d.%d.%d%s", majors[ self ], minors[ self ], patches[ self ], pre_release_with_builds[ self ] )
end

---@return integer
---@protected
function Version:__tonumber()
	return xyz_uint32( majors[ self ], minors[ self ], patches[ self ] )
end

do

	local raw_index = raw.index

	---@param key string
	---@return any
	---@protected
	function Version:__index( key )
		if key == "major" then
			return majors[ self ]
		elseif key == "minor" then
			return minors[ self ]
		elseif key == "patch" then
			return patches[ self ]
		elseif key == "pre_release" then
			return pre_releases[ self ]
		elseif key == "build" then
			return builds[ self ]
		else
			return raw_index( Version, key )
		end
	end

end

--- [SHARED AND MENU]
---
--- Adds a version to the current version.
---
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@return dreamwork.std.Version version_obj The new version.
function Version:add( major, minor, patch )
	return VersionClass(
		math_min( majors[ self ] + ( major or 0 ), 0x3ff ),
		math_min( minors[ self ] + ( minor or 0 ), 0x7ff ),
		math_min( patches[ self ] + ( patch or 0 ), 0x7ff )
	)
end

--- [SHARED AND MENU]
---
--- Subtracts a version from the current version.
---
---@param major integer | nil The major version.
---@param minor integer | nil The minor version.
---@param patch integer | nil The patch version.
---@return dreamwork.std.Version version_obj The new version.
function Version:subtract( major, minor, patch )
	return VersionClass(
		math_max( majors[ self ] - ( major or 0 ), 0 ),
		math_max( minors[ self ] - ( minor or 0 ), 0 ),
		math_max( patches[ self ] - ( patch or 0 ), 0 )
	)
end

local fromString
do

	local string_match = string.match

	--- [SHARED AND MENU]
	---
	--- Gets a version object from a version string.
	---
	---@param version_str string The version string in the format `major.minor.patch[-pre_release][+build]`.
	---@return dreamwork.std.Version version_obj The version object.
	function fromString( version_str )
		local major_str, minor_str, patch_str, extra_str = string_match( version_str, "^(%d+)%.?(%d*)%.?(%d*)(.-)$" )
		local pre_release_str, build_str

		if extra_str ~= nil then
			pre_release_str, build_str = string_match( extra_str, "^%-([^+]+)%+(.+)$" )
			if pre_release_str == nil or build_str == nil then
				local uint8_1 = string_byte( extra_str, 1, 1 )
				if uint8_1 == 0x2D --[[ - ]] then
					pre_release_str = string_match( extra_str, "^-(%w[%.%w-]*)$" )
				elseif uint8_1 == 0x2B --[[ + ]] then
					build_str = string_match( extra_str, "^%+(%w[%.%w-]*)$" )
				end
			end
		end

		return VersionClass(
			raw_tonumber( major_str, 10 ) or 0,
			raw_tonumber( minor_str, 10 ) or 0,
			raw_tonumber( patch_str, 10 ) or 0,
			pre_release_str,
			build_str
		)
	end

	VersionClass.fromString = fromString

end

do

	local string_byteSplit = string.byteSplit

	local function compare_values( value_1, value_2 )
		if value_1 == value_2 then
			return 0
		elseif value_1 < value_2 then
			return -1
		else
			return 1
		end
	end

	local function compare_segments( segment_1, segment_2 )
		if segment_1 == segment_2 then
			return 0
		elseif segment_1 == nil then
			return -1
		elseif segment_2 == nil then
			return 1
		end

		local value_1 = raw_tonumber( segment_1, 16 )
		local value_2 = raw_tonumber( segment_2, 16 )

		if value_1 == nil then
			if value_2 == nil then
				return compare_values( segment_1, segment_2 )
			else
				return 1
			end
		elseif value_2 == nil then
			return -1
		else
			return compare_values( value_1, value_2 )
		end
	end

	local function pre_release_lt( pre_release_1, pre_release_2 )
		if pre_release_1 == nil or pre_release_1 == pre_release_2 then
			return false
		elseif pre_release_2 == nil then
			return true
		end

		local segments_1, segment_count_1 = string_byteSplit( pre_release_1, 0x2E --[[ . ]] )
		local segments_2, segment_count_2 = string_byteSplit( pre_release_2, 0x2E --[[ . ]] )

		for index = 1, segment_count_1, 1 do
			local comparison = compare_segments( segments_1[ index ], segments_2[ index ] )
			if comparison ~= 0 then
				return comparison == -1
			end
		end

		return segment_count_1 < segment_count_2
	end

	---@param version_1 dreamwork.std.Version
	---@param version_2 dreamwork.std.Version
	---@return boolean
	---@protected
	local function lt( version_1, version_2 )
		local major_1 = majors[ version_1 ]
		local major_2 = majors[ version_2 ]

		if major_1 ~= major_2 then
			return major_1 < major_2
		end

		local minor_1 = minors[ version_1 ]
		local minor_2 = minors[ version_2 ]

		if minor_1 ~= minor_2 then
			return minor_1 < minor_2
		end

		local patch_1 = patches[ version_1 ]
		local patch_2 = patches[ version_2 ]

		if patch_1 ~= patch_2 then
			return patch_1 < patch_2
		end

		return pre_release_lt( pre_releases[ version_1 ], pre_releases[ version_2 ] )
	end

	Version.__lt = lt

	--[[

		Primitive operators ( =, <, >, <=, >= )
			more info: https://docs.npmjs.com/cli/v6/using-npm/semver#ranges

	--]]

	---@param version_1 dreamwork.std.Version
	---@param version_2 dreamwork.std.Version
	---@param x_range integer
	---@return boolean
	operators[ "=" ] = function( version_1, version_2, x_range )
		if x_range == 0 then
			return version_1 == version_2
		elseif lt( version_1, version_2 ) then
			return false
		elseif x_range == 1 then
			return lt( version_1, version_2:add( 0, 1, 0 ) )
		elseif x_range == 2 then
			return lt( version_1, version_2:add( 1, 0, 0 ) )
		else
			return true
		end
	end

	---@param version_obj dreamwork.std.Version
	---@return boolean
	---@protected
	function Version:__le( version_obj )
		return self == version_obj or lt( self, version_obj )
	end

	operators[ "<" ] = lt

	---@param version_1 dreamwork.std.Version
	---@param version_2 dreamwork.std.Version
	---@param x_range integer
	---@return boolean
	operators[ "<=" ] = function( version_1, version_2, x_range )
		if x_range == 0 then
			return version_1 == version_2 or lt( version_1, version_2 )
		end

		---@type dreamwork.std.Version
		local version_2_up

		if x_range == 1 then
			version_2_up = version_2:add( 0, 1, 0 )
		elseif x_range == 2 then
			version_2_up = version_2:add( 1, 0, 0 )
		else
			version_2_up = version_2
		end

		return lt( version_1, version_2_up )
	end

	-- Tilde Ranges ~1.2.3 ~1.2 ~1
	-- Allows patch-level changes if a minor version is specified on the comparator. Allows minor-level changes if not.
	-- https://docs.npmjs.com/cli/v6/using-npm/semver#tilde-ranges-123-12-1
	operators[ "~" ] = function( version_1, version_2, x_range )
		if lt( version_1, version_2 ) then
			return false
		elseif x_range == 2 then
			return version_1 < version_2:add( 1, 0, 0 )
		else
			return version_1 < version_2:add( 0, 1, 0 )
		end
	end

	---@param version_1 dreamwork.std.Version
	---@param version_2 dreamwork.std.Version
	---@param x_range integer
	---@return boolean
	operators[ ">" ] = function( version_1, version_2, x_range )
		if x_range == 0 then
			return not lt( version_1, version_2 )
		end

		---@type dreamwork.std.Version
		local version_2_up

		if x_range == 1 then
			version_2_up = version_2:add( 0, 1, 0 )
		elseif x_range == 2 then
			version_2_up = version_2:add( 1, 0, 0 )
		else
			version_2_up = version_2
		end

		return version_1 == version_2_up or not lt( version_1, version_2_up )
	end

	operators[ ">=" ] = function( version_1, version_2 )
		return version_1 == version_2 or not lt( version_1, version_2 )
	end

	-- Caret Ranges ^1.2.3 ^0.2.5 ^0.0.4
	-- Allows changes that do not modify the left-most non-zero digit in the [major, minor, patch] tuple.
	-- In other words, this allows patch and minor updates for versions 1.0.0 and above, patch updates for
	-- versions 0.X >=0.1.0, and no updates for versions 0.0.X.
	-- https://docs.npmjs.com/cli/v6/using-npm/semver#caret-ranges-123-025-004
	---@param version_1 dreamwork.std.Version
	---@param version_2 dreamwork.std.Version
	---@param x_range integer
	---@return boolean
	local function caret_ranges( version_1, version_2, x_range )
		if version_1 ~= version_2 and lt( version_1, version_2 ) then
			return false
		end

		local major_2 = majors[ version_2 ]

		if major_2 == 0 and ( x_range == 0 or x_range == 1 ) then
			if majors[ version_1 ] ~= 0 then
				return false
			end

			if minors[ version_2 ] == 0 and x_range == 0 then
				return minors[ version_1 ] == 0 and lt( version_1, version_2:add( 0, 0, 1 ) )
			end

			return lt( version_1, version_2:add( 0, 1, 0 ) )
		end

		return majors[ version_1 ] == major_2 and lt( version_1, version_2:add( 1, 0, 0 ) )
	end

	operators[ "^" ] = caret_ranges

	---@param version_obj dreamwork.std.Version
	---@return boolean
	---@protected
	function Version:__pow( version_obj )
		return caret_ranges( self, version_obj, 0 )
	end

end

do

	local string_sub, string_gsub = string.sub, string.gsub
	local string_byteCount = string.byteCount
	local string_trim = string.trim
	local string_find = string.find

	-- TODO: rewrite match function ( replace patterns with byte analysis )

	---@param version_obj dreamwork.std.Version
	---@param semver_selector string
	---@return boolean
	local function match( version_obj, semver_selector )
		-- normalize
		semver_selector = string_trim( string_gsub( semver_selector, "%s+", " " ), "%s" )

		-- version range := comparator sets
		if string_find( semver_selector, "||", 1, true ) then
			local pointer = 1
			while true do
				local position = string_find( semver_selector, "||", pointer, true )
				if version_obj % string_sub( semver_selector, pointer, position and ( position - 1 ) ) then
					return true
				elseif position == nil then
					return false
				else
					pointer = position + 2
				end
			end
		end

		-- comparator set := comparators
		if string_find( semver_selector, " ", 1, true ) then
			local start = 1
			local position
			local part

			while true do
				position = string_find( semver_selector, " ", start, true )
				part = string_sub( semver_selector, start, position and ( position - 1 ) )

				-- Hyphen Ranges: X.Y.Z - A.B.C
				-- https://docs.npmjs.com/cli/v6/using-npm/semver#hyphen-ranges-xyz---abc
				if position ~= nil and string_sub( semver_selector, position, position + 2 ) == " - " then
					if not ( version_obj % ( ">=" .. part ) ) then
						return false
					end

					start = position + 3
					position = string_find( semver_selector, " ", start, true )
					part = string_sub( semver_selector, start, position and ( position - 1 ) )

					if not ( version_obj % ( "<=" .. part ) ) then
						return false
					end
				elseif not ( version_obj % part ) then
					return false
				end

				if position == nil then
					return true
				end

				start = position + 1
			end

			return true
		end

		-- comparators := operator + version
		semver_selector = string_gsub( string_gsub( semver_selector, "^=", "" ), "^v", "" )

		-- X-Ranges *
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		-- TODO: replace with byte analysis
		if semver_selector == "" or semver_selector == "*" then
			return version_obj % ">=0.0.0"
		end

		local position = string_find( semver_selector, "%d" )
		if position == nil then
			error( "Version range must starts with number: " .. semver_selector, 2 )
		end

		---@cast position integer

		-- X-Ranges 1.2.x 1.X 1.2.*
		-- Any of X, x, or * may be used to 'stand in' for one of the numeric values in the [major, minor, patch] tuple.
		-- https://docs.npmjs.com/cli/v6/using-npm/semver#x-ranges-12x-1x-12-
		local operator

		if position == 1 then
			operator = "="
		else
			operator = string_sub( semver_selector, 1, position - 1 )
		end

		local name = string_gsub( string_sub( semver_selector, position ), "%.[xX*]", "" )

		local x_range = math_max( 2 - string_byteCount( name, 0x2E --[[ . ]] ), 0 )

		for _ = 1, x_range do
			name = name .. ".0"
		end

		local operator_fn = operators[ operator ]
		if operator_fn == nil then
			error( "Invaild operator: '" .. operator .. "'", 2 )
		end

		---@cast operator_fn fun( version_1: dreamwork.std.Version, version_2: dreamwork.std.Version, x_range: integer ): boolean

		return operator_fn( version_obj, fromString( name ), x_range )
	end

	Version.match = match
	Version.__mod = match

	local len = std.len

	---@param semver_selector string
	---@param versions dreamwork.std.Version[]
	---@return dreamwork.std.Version? matched_version
	---@return integer version_position
	function VersionClass.select( versions, semver_selector )
		for index = 1, len( versions ), 1 do
			local version = versions[ index ]
			if match( version, semver_selector ) then
				return version, index
			end
		end

		return nil, -1
	end

end
