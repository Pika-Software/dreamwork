---@class dreamwork
local dreamwork = dreamwork

---@class dreamwork.std
local std = dreamwork.std

local dreamwork_sandbox = dreamwork.sandbox
local sandbox_owner = dreamwork_sandbox.owner
local sandbox_claim = dreamwork_sandbox.claim

local vfs = dreamwork.vfs
local vfs_readFile = vfs.readFile

local raw = std.raw
local raw_get = raw.get
local raw_set = raw.set
local raw_type = raw.type
local raw_pairs = raw.pairs

local debug = std.debug
local debug_getmetatable = debug.getmetatable

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local math = std.math
local math_floor = math.floor

local string = std.string
local string_byte, string_char = string.byte, string.char
local string_sub, string_format = string.sub, string.format
local string_hasPrefix = string.hasPrefix

local table = std.table
local table_concat = table.concat
local table_unpack, table_sort = table.unpack, table.sort

local bytepack = std.bytepack
local bytepack_readFloatLE = bytepack.readFloatLE
local bytepack_writeFloatLE = bytepack.writeFloatLE
local bytepack_readDoubleLE = bytepack.readDoubleLE
local bytepack_writeDoubleLE = bytepack.writeDoubleLE

local class = std.class
local class_new = class.new

local error = std.error
local pcall = std.pcall
local tostring = std.tostring
local DecodeError = std.DecodeError
local EncodeError = std.EncodeError

---@class dreamwork.std.BinaryReader
local BinaryReader = std.BinaryReader.__base

---@class dreamwork.std.BinaryWriter
local BinaryWriter = std.BinaryWriter.__base

--- [SHARED AND MENU]
---
--- Protocol Buffers, Google's binary format of typed messages with numbered fields.
---
--- Types are described by `.proto` files, parsed with `protobuf.parse` (text) or `protobuf.load` (file of a package),
--- and found by their full name with `protobuf.Type.find`, `protobuf.Enum.find` or `protobuf.find`, the data is the standard protobuf wire format.
---
--- ```lua
--- protobuf.parse( [[
---     syntax = "proto3";
---     package my_pkg;
---
---     message Item {
---         uint32 id = 1;
---         string name = 2;
---         dreamwork.Vector3 position = 3;
---     }
--- ]], "item.proto" )
---
--- local Item = protobuf.Type.find( "my_pkg.Item" )
---
--- local data = Item:encode( { id = 1, name = "crowbar", position = Vector3( 1, 2, 3 ) } )
--- local item = Item:decode( data ) --> { id = 1, name = "crowbar", position = Vector3( 1, 2, 3 ) }
--- ```
---
--- **Scopes**: files parsed or loaded by a package belong to the package, only the package sees their types
--- and they are dropped when it unloads. Files parsed outside of packages are global and seen by everyone,
--- the built-in ones are `google/protobuf/*.proto` (well-known types) and `dreamwork/*.proto` (dreamwork types),
--- packages can't register files with these prefixes.
---
--- **Lua values**:
--- * Messages are tables with the field names as keys, or objects of classes bound with `Type:bind`.
--- * 32-bit integers, floats and doubles are numbers, `bool` is a boolean, `string` and `bytes` are strings.
--- * 64-bit integers are `{ low, high }` tables of 32-bit halves, `high` is signed for signed types,
--- numbers are accepted when encoding.
--- * Enums are numbers, value names are accepted when encoding.
--- * `repeated` fields are arrays, `map<K, V>` fields are tables.
--- * Fields without a label in proto3 are decoded as their default value (`0`, `""`, `false`) when missing,
--- `optional`, `oneof` and message fields are `nil` when missing.
--- * `google.protobuf.Struct`, `Value` and `ListValue` are plain Lua tables and values,
--- `NullValue` and missing wrapper values (`google.protobuf.Int32Value`, ...) are `nil`.
---
--- Classes take part with `__proto` (the full name of their type) and two optional hooks,
--- `__toProto( self ): any` returns the value to encode in place of the object,
--- `__fromProto( self, value )` fills a new object from the decoded value.
---
---@class dreamwork.std.protobuf
local protobuf = std.protobuf or {}
std.protobuf = protobuf

dreamwork.load( "std/codec/protobuf/parser.lua" )

local parseSchema = protobuf.parseSchema

---@type table<string, boolean>
local scalar_types = {
    double = true,
    float = true,
    int32 = true,
    int64 = true,
    uint32 = true,
    uint64 = true,
    sint32 = true,
    sint64 = true,
    fixed32 = true,
    fixed64 = true,
    sfixed32 = true,
    sfixed64 = true,
    bool = true,
    string = true,
    bytes = true
}

local WIRE_VARINT = 0
local WIRE_I64 = 1
local WIRE_LEN = 2
local WIRE_START_GROUP = 3
local WIRE_END_GROUP = 4
local WIRE_I32 = 5

local UINT32 = 0x100000000
local INT32_MAX = 0x7FFFFFFF

-- Encoder
-- the output is a list of string parts joined once at the end, length prefixes of nested messages
-- are put into a reserved slot after the message is written

---@type string[]
local parts = {}

local part_count = 0

--- The number of bytes written so far.
local size = 0

---@param str string
local function put( str )
    part_count = part_count + 1
    parts[ part_count ] = str
    size = size + #str
end

--- Returns the varint bytes of the unsigned 32-bit integer.
---
---@param value integer
---@return string
local function varint32_string( value )
    if value < 0x80 then
        return string_char( value )
    elseif value < 0x4000 then
        return string_char( value % 0x80 + 0x80, math_floor( value / 0x80 ) )
    elseif value < 0x200000 then
        return string_char( value % 0x80 + 0x80, math_floor( value / 0x80 ) % 0x80 + 0x80, math_floor( value / 0x4000 ) )
    elseif value < 0x10000000 then
        return string_char( value % 0x80 + 0x80, math_floor( value / 0x80 ) % 0x80 + 0x80, math_floor( value / 0x4000 ) % 0x80 + 0x80, math_floor( value / 0x200000 ) )
    end

    return string_char( value % 0x80 + 0x80, math_floor( value / 0x80 ) % 0x80 + 0x80, math_floor( value / 0x4000 ) % 0x80 + 0x80, math_floor( value / 0x200000 ) % 0x80 + 0x80, math_floor( value / 0x10000000 ) )
end

---@type integer[]
local varint_scratch = {}

--- Returns the varint bytes of the unsigned 64-bit integer given as unsigned 32-bit halves.
---
---@param low integer
---@param high integer
---@return string
local function varint64_string( low, high )
    if high == 0 then
        return varint32_string( low )
    end

    -- bits 0-27 of the low half, then bits 28-31 of the low half with bits 0-2 of the high half
    varint_scratch[ 1 ] = low % 0x80 + 0x80
    varint_scratch[ 2 ] = math_floor( low / 0x80 ) % 0x80 + 0x80
    varint_scratch[ 3 ] = math_floor( low / 0x4000 ) % 0x80 + 0x80
    varint_scratch[ 4 ] = math_floor( low / 0x200000 ) % 0x80 + 0x80

    local byte = math_floor( low / 0x10000000 ) + (high % 8) * 0x10
    high = math_floor( high / 8 )

    local count = 5

    ::high_loop::

    if high == 0 then
        varint_scratch[ count ] = byte
        return string_char( table_unpack( varint_scratch, 1, count ) )
    end

    varint_scratch[ count ] = byte + 0x80
    count = count + 1

    byte = high % 0x80
    high = math_floor( high / 0x80 )

    ---@diagnostic disable-next-line: missing-return
    goto high_loop
end

--- Splits the 64-bit integer into unsigned 32-bit halves, `value` is a number or a `{ low, high }` table.
---
---@param value number | integer[]
---@return integer low
---@return integer high
local function split64( value )
    if raw_type( value ) == "number" then
        ---@cast value number
        local high = math_floor( value / UINT32 )
        return value - high * UINT32, high % UINT32
    end

    ---@cast value integer[]
    return value[ 1 ] % UINT32, value[ 2 ] % UINT32
end

---@param value number | integer[]
---@return boolean
local function is_zero64( value )
    if raw_type( value ) == "number" then
        return value == 0
    end

    ---@cast value integer[]
    return value[ 1 ] == 0 and value[ 2 ] == 0
end

---@param value integer
local function write_uint32( value )
    put( varint32_string( value ) )
end

---@param value integer
local function write_int32( value )
    if value < 0 then
        -- negative int32 values are sign-extended to 64 bits, 10 bytes
        put( varint64_string( value + UINT32, 0xFFFFFFFF ) )
    else
        put( varint32_string( value ) )
    end
end

---@param value integer
local function write_sint32( value )
    if value < 0 then
        put( varint32_string( -2 * value - 1 ) )
    else
        put( varint32_string( 2 * value ) )
    end
end

---@param value number | integer[]
local function write_uint64( value )
    put( varint64_string( split64( value ) ) )
end

---@param value number | integer[]
local function write_sint64( value )
    local low, high = split64( value )

    -- (n << 1) ~ (n >> 63) on the halves, xor with all ones is `0xFFFFFFFF - x`
    local zigzag_low = (low * 2) % UINT32
    local zigzag_high = (high * 2) % UINT32 + math_floor( low / 0x80000000 )

    if high > INT32_MAX then
        zigzag_low = 0xFFFFFFFF - zigzag_low
        zigzag_high = 0xFFFFFFFF - zigzag_high
    end

    put( varint64_string( zigzag_low, zigzag_high ) )
end

---@param value boolean
local function write_bool( value )
    put( string_char( value and 1 or 0 ) )
end

---@param value integer
local function write_fixed32( value )
    value = value % UINT32
    put( string_char( value % 0x100, math_floor( value / 0x100 ) % 0x100, math_floor( value / 0x10000 ) % 0x100, math_floor( value / 0x1000000 ) ) )
end

---@param value number | integer[]
local function write_fixed64( value )
    local low, high = split64( value )
    put( string_char(
        low % 0x100, math_floor( low / 0x100 ) % 0x100, math_floor( low / 0x10000 ) % 0x100, math_floor( low / 0x1000000 ),
        high % 0x100, math_floor( high / 0x100 ) % 0x100, math_floor( high / 0x10000 ) % 0x100, math_floor( high / 0x1000000 )
    ) )
end

---@param value number
local function write_float( value )
    put( string_char( bytepack_writeFloatLE( value ) ) )
end

---@param value number
local function write_double( value )
    put( string_char( bytepack_writeDoubleLE( value ) ) )
end

---@param value string
local function write_bytes( value )
    put( varint32_string( #value ) )
    put( value )
end

--- Reserves the slot of a length prefix, returns the slot and the size before the content.
---
---@return integer slot
---@return integer start
local function begin_length()
    part_count = part_count + 1
    parts[ part_count ] = ""
    return part_count, size
end

---@param slot integer
---@param start integer
local function end_length( slot, start )
    local prefix = varint32_string( size - start )
    parts[ slot ] = prefix
    size = size + #prefix
end

-- Decoder

---@type string
local data = ""

--- The position of the next byte (`1`-based).
local position = 1

--- The position of the last byte of the current message.
local limit = 0

---@param message string
local function decode_error( message )
    error( DecodeError( message, position ), 0 )
end

---@return integer value The low 32 bits of the varint.
local function read_varint32()
    local index = position
    if index > limit then
        decode_error( "unexpected end of data" )
    end

    local byte = string_byte( data, index )
    if byte < 0x80 then
        position = index + 1
        return byte
    end

    local result = byte - 0x80
    local multiplier = 0x80

    for byte_index = 1, 9, 1 do
        index = index + 1
        if index > limit then
            decode_error( "unexpected end of data" )
        end

        byte = string_byte( data, index )

        if byte < 0x80 then
            if byte_index < 5 then
                result = result + byte * multiplier
            end

            position = index + 1
            return result % UINT32
        end

        if byte_index < 5 then
            result = result + (byte - 0x80) * multiplier
            multiplier = multiplier * 0x80
        end
    end

    decode_error( "malformed varint" )
    return 0
end

---@type number[]
local high_multipliers = { [ 5 ] = 8, [ 6 ] = 0x400, [ 7 ] = 0x20000, [ 8 ] = 0x1000000, [ 9 ] = 0x80000000 }

---@type number[]
local low_multipliers = { [ 0 ] = 1, [ 1 ] = 0x80, [ 2 ] = 0x4000, [ 3 ] = 0x200000 }

---@return integer low The unsigned low half.
---@return integer high The unsigned high half.
local function read_varint64()
    local index = position
    local low, high = 0, 0

    for byte_index = 0, 9, 1 do
        if index > limit then
            decode_error( "unexpected end of data" )
        end

        local byte = string_byte( data, index )
        index = index + 1

        local bits = byte % 0x80

        if byte_index < 4 then
            low = low + bits * low_multipliers[ byte_index ]
        elseif byte_index == 4 then
            low = low + (bits % 0x10) * 0x10000000
            high = math_floor( bits / 0x10 )
        else
            high = high + bits * high_multipliers[ byte_index ]
        end

        if byte < 0x80 then
            position = index
            return low, high % UINT32
        end
    end

    decode_error( "malformed varint" )
    return 0, 0
end

---@param byte_count integer
---@return integer start
local function advance( byte_count )
    local start = position
    local next_position = start + byte_count

    if next_position - 1 > limit then
        decode_error( "unexpected end of data" )
    end

    position = next_position
    return start
end

---@return integer
local function read_uint32()
    return read_varint32()
end

---@return integer
local function read_int32()
    local value = read_varint32()

    if value > INT32_MAX then
        return value - UINT32
    end

    return value
end

---@return integer
local function read_sint32()
    local value = read_varint32()

    if value % 2 == 0 then
        return value / 2
    end

    return -(value + 1) / 2
end

---@return boolean
local function read_bool()
    local low, high = read_varint64()
    return low ~= 0 or high ~= 0
end

---@return integer[]
local function read_uint64()
    local low, high = read_varint64()
    return { low, high }
end

---@return integer[]
local function read_int64()
    local low, high = read_varint64()

    if high > INT32_MAX then
        high = high - UINT32
    end

    return { low, high }
end

---@return integer[]
local function read_sint64()
    local low, high = read_varint64()

    local is_negative = low % 2 == 1

    -- n >> 1 on the halves, then xor with all ones for odd values
    low = math_floor( low / 2 ) + (high % 2) * 0x80000000
    high = math_floor( high / 2 )

    if is_negative then
        low = 0xFFFFFFFF - low
        high = 0xFFFFFFFF - high
    end

    if high > INT32_MAX then
        high = high - UINT32
    end

    return { low, high }
end

---@return integer
local function read_fixed32()
    local index = advance( 4 )
    local byte1, byte2, byte3, byte4 = string_byte( data, index, index + 3 )
    return byte1 + byte2 * 0x100 + byte3 * 0x10000 + byte4 * 0x1000000
end

---@return integer
local function read_sfixed32()
    local value = read_fixed32()

    if value > INT32_MAX then
        return value - UINT32
    end

    return value
end

---@return integer[]
local function read_fixed64()
    local low = read_fixed32()
    return { low, read_fixed32() }
end

---@return integer[]
local function read_sfixed64()
    local low = read_fixed32()
    return { low, read_sfixed32() }
end

---@return number
local function read_float()
    local index = advance( 4 )
    return bytepack_readFloatLE( string_byte( data, index, index + 3 ) )
end

---@return number
local function read_double()
    local index = advance( 8 )
    return bytepack_readDoubleLE( string_byte( data, index, index + 7 ) )
end

---@return string
local function read_bytes()
    local length = read_varint32()
    local index = advance( length )
    return string_sub( data, index, index + length - 1 )
end

--- Skips the value of an unknown field.
---
---@param wire_type integer
---@param number integer
local function skip_field( wire_type, number )
    if wire_type == WIRE_VARINT then
        read_varint64()
    elseif wire_type == WIRE_I64 then
        advance( 8 )
    elseif wire_type == WIRE_LEN then
        advance( read_varint32() )
    elseif wire_type == WIRE_I32 then
        advance( 4 )
    elseif wire_type == WIRE_START_GROUP then
        ::group_loop::

        local tag = read_varint32()
        local tag_wire_type = tag % 8

        if tag_wire_type == WIRE_END_GROUP then
            if math_floor( tag / 8 ) ~= number then
                decode_error( "mismatched end group" )
            end

            return
        end

        skip_field( tag_wire_type, math_floor( tag / 8 ) )
        goto group_loop
    else
        decode_error( "invalid wire type " .. wire_type )
    end
end

---@class dreamwork.std.protobuf.ScalarCodec
---@field wire integer The wire type.
---@field write fun( value: any )
---@field read fun(): any
---@field default any The default value, `nil` for 64-bit types (a new `{ 0, 0 }` every time).
---@field is_64 boolean

---@type table<string, dreamwork.std.protobuf.ScalarCodec>
local scalar_codecs = {
    double = { wire = WIRE_I64, write = write_double, read = read_double, default = 0, is_64 = false },
    float = { wire = WIRE_I32, write = write_float, read = read_float, default = 0, is_64 = false },
    int32 = { wire = WIRE_VARINT, write = write_int32, read = read_int32, default = 0, is_64 = false },
    uint32 = { wire = WIRE_VARINT, write = write_uint32, read = read_uint32, default = 0, is_64 = false },
    sint32 = { wire = WIRE_VARINT, write = write_sint32, read = read_sint32, default = 0, is_64 = false },
    fixed32 = { wire = WIRE_I32, write = write_fixed32, read = read_fixed32, default = 0, is_64 = false },
    sfixed32 = { wire = WIRE_I32, write = write_fixed32, read = read_sfixed32, default = 0, is_64 = false },
    int64 = { wire = WIRE_VARINT, write = write_uint64, read = read_int64, is_64 = true },
    uint64 = { wire = WIRE_VARINT, write = write_uint64, read = read_uint64, is_64 = true },
    sint64 = { wire = WIRE_VARINT, write = write_sint64, read = read_sint64, is_64 = true },
    fixed64 = { wire = WIRE_I64, write = write_fixed64, read = read_fixed64, is_64 = true },
    sfixed64 = { wire = WIRE_I64, write = write_fixed64, read = read_sfixed64, is_64 = true },
    bool = { wire = WIRE_VARINT, write = write_bool, read = read_bool, default = false, is_64 = false },
    string = { wire = WIRE_LEN, write = write_bytes, read = read_bytes, default = "", is_64 = false },
    bytes = { wire = WIRE_LEN, write = write_bytes, read = read_bytes, default = "", is_64 = false }
}

-- Types

--- [SHARED AND MENU]
---
--- The enum type of a `.proto` file, found with `protobuf.Enum.find`.
---
---@class dreamwork.std.protobuf.Enum : dreamwork.std.Object
---@field __class dreamwork.std.protobuf.EnumClass
---@field name string The full name, e.g. `my_pkg.Color`. **Read-only.**
---@field file string The name of the file that declares it. **Read-only.**
---@field values table<string, integer> The numbers of the values by their names. **Read-only.**
---@field names table<integer, string> The names of the values by their numbers, the first name for aliases. **Read-only.**
local Enum = class.base( "protobuf.Enum", false, nil )

---@return string
---@protected
function Enum:__tostring()
    return string_format( "protobuf.Enum: %p [%s]", self, self.name )
end

--- [SHARED AND MENU]
---
--- The class of `protobuf.Enum` objects, they are created by `protobuf.parse` and `protobuf.load` only.
---
---@class dreamwork.std.protobuf.EnumClass : dreamwork.std.protobuf.Enum, dreamwork.std.Class
---@field __base dreamwork.std.protobuf.Enum
local EnumClass = class.create( Enum )
protobuf.Enum = EnumClass

--- [SHARED AND MENU]
---
--- The message type of a `.proto` file, found with `protobuf.Type.find`.
---
--- ```lua
--- local Item = protobuf.Type.find( "my_pkg.Item" )
---
--- local data = Item:encode( { id = 1, name = "crowbar" } )
--- local item = Item:decode( data )
--- ```
---
---@class dreamwork.std.protobuf.Type : dreamwork.std.Object
---@field __class dreamwork.std.protobuf.TypeClass
---@field name string The full name, e.g. `my_pkg.Item`. **Read-only.**
---@field file string The name of the file that declares it. **Read-only.**
---@field descriptor dreamwork.std.protobuf.MessageDescriptor The parsed declaration. **Read-only.**
---@field class dreamwork.std.Class | nil The class bound with `Type:bind`, decoded messages are its objects. **Read-only.**
---@field package scope dreamwork.std.protobuf.Scope
---@field package compiled boolean
---@field package fields dreamwork.std.protobuf.Field[]
---@field package field_count integer
---@field package by_number table<integer, dreamwork.std.protobuf.Field>
---@field package syntax "proto2" | "proto3"
---@field package special "nullable" | "unwrap" | "value" | nil
---@field package unwrap_name string | nil
---@field package unwrap_field dreamwork.std.protobuf.Field | nil
---@field package create ( fun(): any ) | nil
---@field package from_proto ( fun( obj: any, value: any ) ) | nil
local Type = class.base( "protobuf.Type", false, nil )

---@return string
---@protected
function Type:__tostring()
    return string_format( "protobuf.Type: %p [%s]", self, self.name )
end

--- [SHARED AND MENU]
---
--- The class of `protobuf.Type` objects, they are created by `protobuf.parse`, `protobuf.load`,
--- `protobuf.nullable`, `protobuf.list` and `protobuf.tree` only.
---
---@class dreamwork.std.protobuf.TypeClass : dreamwork.std.protobuf.Type, dreamwork.std.Class
---@field __base dreamwork.std.protobuf.Type
local TypeClass = class.create( Type )
protobuf.Type = TypeClass

---@class dreamwork.std.protobuf.Field
---@field name string
---@field number integer
---@field wire integer The wire type of one value.
---@field packable boolean `true` if packed (`LEN`) data is accepted.
---@field encode fun( value: any ) Writes the tag and the value, `value` is not `nil`.
---@field read fun( target: table ) Reads one value of `wire` type into the target.
---@field read_packed ( fun( target: table ) ) | nil Reads packed values into the target.
---@field reset_value any
---@field reset_kind integer `RESET_*`

--- [SHARED AND MENU]
---
--- The `.proto` file registered with `protobuf.parse` or `protobuf.load`.
---
---@class dreamwork.std.protobuf.File
---@field name string The file name, imports refer to it by this name.
---@field ["package"] string The protobuf package, `""` if the file has none.
---@field types table<string, dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum> The declared messages and enums by their full names, nested ones included.
---@field descriptor dreamwork.std.protobuf.FileDescriptor The parsed file.

---@class dreamwork.std.protobuf.Scope
---@field files table<string, dreamwork.std.protobuf.File>
---@field types table<string, dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum>
---@field owner dreamwork.sandbox.Owner | nil

---@type dreamwork.std.protobuf.Scope
local global_scope = {
    files = {},
    types = {}
}

local global_types = global_scope.types
local global_files = global_scope.files

---@type table<dreamwork.sandbox.Owner, dreamwork.std.protobuf.Scope>
local package_scopes = {}

---@param scope dreamwork.std.protobuf.Scope
local function release_scope( scope )
    package_scopes[ scope.owner ] = nil
end

---@param owner dreamwork.sandbox.Owner | nil
---@return dreamwork.std.protobuf.Scope
local function get_scope( owner )
    if owner == nil then
        return global_scope
    end

    local scope = package_scopes[ owner ]
    if scope == nil then
        scope = {
            files = {},
            types = {},
            owner = owner
        }

        package_scopes[ owner ] = scope
        sandbox_claim( owner, scope, release_scope )
    end

    return scope
end

---@param scope dreamwork.std.protobuf.Scope
---@param full_name string
---@return dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | nil
local function scope_lookup( scope, full_name )
    return scope.types[ full_name ] or global_types[ full_name ]
end

--- Resolves the type name relative to the full name of the message it is used in, the protobuf way:
--- `Inner` used in `pkg.Outer` is looked up as `pkg.Outer.Inner`, `pkg.Inner` and `Inner`.
---
---@param scope dreamwork.std.protobuf.Scope
---@param type_name string
---@param relative_to string
---@return dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | nil
local function resolve_name( scope, type_name, relative_to )
    if string_byte( type_name, 1 ) == 0x2E --[[ . ]] then
        return scope_lookup( scope, string_sub( type_name, 2 ) )
    end

    local prefix = relative_to

    ::resolve_loop::

    local result
    if prefix == "" then
        result = scope_lookup( scope, type_name )
    else
        result = scope_lookup( scope, prefix .. "." .. type_name )
    end

    if result ~= nil or prefix == "" then
        return result
    end

    -- drop the last component of the prefix
    local last_dot = nil

    for index = #prefix, 1, -1 do
        if string_byte( prefix, index ) == 0x2E then
            last_dot = index
            break
        end
    end

    if last_dot == nil then
        prefix = ""
    else
        prefix = string_sub( prefix, 1, last_dot - 1 )
    end

    goto resolve_loop
end

-- Compiler

local RESET_NONE = 0
local RESET_VALUE = 1
local RESET_TABLE = 2
local RESET_INT64 = 3

local compile_type

local encode_body
local decode_message

---@param message_type dreamwork.std.protobuf.Type
---@param value any
local function encode_nested( message_type, value )
    local slot, start = begin_length()
    encode_body( message_type, value )
    end_length( slot, start )
end

---@param message_type dreamwork.std.protobuf.Type
---@return any
local function decode_nested( message_type )
    local length = read_varint32()
    local end_position = position + length - 1

    if end_position > limit then
        decode_error( "unexpected end of data" )
    end

    local saved_limit = limit
    limit = end_position

    local value = decode_message( message_type )

    limit = saved_limit
    return value
end

--- `debug.getmetatable` of gmod rejects cdata, so only tables are checked.
---
---@param value any
---@return boolean
local function is_type( value )
    return raw_type( value ) == "table" and debug_getmetatable( value ) == Type
end

---@param field_type dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | string
---@return boolean
local function is_nullable_type( field_type )
    if not is_type( field_type ) then
        return false
    end

    ---@cast field_type dreamwork.std.protobuf.Type
    local special = field_type.special
    return special == "nullable" or special == "value"
end

--- Returns the scalar codec of the field type, enums are `int32` with names accepted when encoding.
---
---@param field_type dreamwork.std.protobuf.Enum | string
---@return dreamwork.std.protobuf.ScalarCodec
local function get_codec( field_type )
    if raw_type( field_type ) == "string" then
        ---@cast field_type string
        return scalar_codecs[ field_type ]
    end

    ---@cast field_type dreamwork.std.protobuf.Enum

    local values, enum_name = field_type.values, field_type.name

    ---@param value integer | string
    local function write_enum( value )
        if raw_type( value ) == "string" then
            ---@cast value string

            ---@type integer
            local number = values[ value ]
            if number == nil then
                error( EncodeError( string_format( "unknown value '%s' of enum '%s'", value, enum_name ), value ), 0 )
            end

            value = number
        end

        ---@cast value integer

        write_int32( value )
    end

    return { wire = WIRE_VARINT, write = write_enum, read = read_int32, default = 0, is_64 = false }
end

--- Creates the encode/decode functions of the field.
---
---@param message_type dreamwork.std.protobuf.Type
---@param descriptor dreamwork.std.protobuf.FieldDescriptor
---@param syntax "proto2" | "proto3"
---@return dreamwork.std.protobuf.Field
local function compile_field( message_type, descriptor, syntax )
    local name, number = descriptor.name, descriptor.number

    ---@type dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | string | nil
    local field_type = descriptor.resolved

    if field_type == nil then
        local type_name = descriptor.type_name

        if scalar_types[ type_name ] then
            field_type = type_name
        else
            field_type = resolve_name( message_type.scope, type_name, descriptor.scope )
            if field_type == nil then
                error( string_format( "unknown type '%s' of field '%s.%s'", type_name, message_type.name, name ), 0 )
            end
        end
    end

    local is_repeated = descriptor.label == "repeated"
    local is_message = is_type( field_type )

    -- proto3 fields without a label have no presence, defaults are not written
    local has_presence = syntax == "proto2" or descriptor.label == "optional" or descriptor.oneof ~= nil or is_message

    ---@type dreamwork.std.protobuf.Field
    ---@diagnostic disable-next-line: missing-fields
    local field = {
        name = name,
        number = number
    }

    -- the other members of the oneof are cleared when this one is read
    ---@type string[] | nil
    local siblings = nil

    local oneof = descriptor.oneof
    if oneof ~= nil then
        siblings = {}

        local field_descriptors = message_type.descriptor.fields
        for index = 1, #field_descriptors, 1 do
            local other = field_descriptors[ index ]
            if other.oneof == oneof and other.name ~= name then
                siblings[ #siblings + 1 ] = other.name
            end
        end

        if #siblings == 0 then
            siblings = nil
        end
    end

    if is_message then
        ---@cast field_type dreamwork.std.protobuf.Type

        local tag = varint32_string( number * 8 + WIRE_LEN )
        field.wire = WIRE_LEN
        field.packable = false

        local entry_descriptor = field_type.descriptor
        if entry_descriptor ~= nil and entry_descriptor.map_entry then
            -- map<K, V>: repeated entries of { key = 1, value = 2 }
            compile_type( field_type )

            local key_field = field_type.by_number[ 1 ]
            local value_field = field_type.by_number[ 2 ]

            local key_encode, value_encode = key_field.encode, value_field.encode
            local key_read, value_read = key_field.read, value_field.read

            field.reset_kind = RESET_TABLE

            ---@param map table
            function field.encode( map )
                for key, value in raw_pairs( map ) do
                    put( tag )

                    local slot, start = begin_length()

                    -- keys and values are always written, defaults included
                    key_encode( key )
                    if value ~= nil then
                        value_encode( value )
                    end

                    end_length( slot, start )
                end
            end

            ---@param target table
            function field.read( target )
                local map = target[ name ]
                if map == nil then
                    map = {}
                    target[ name ] = map
                end

                local length = read_varint32()
                local end_position = position + length - 1

                if end_position > limit then
                    decode_error( "unexpected end of data" )
                end

                local saved_limit = limit
                limit = end_position

                local key, value = key_field.reset_value, value_field.reset_value
                if key_field.reset_kind == RESET_INT64 then
                    key = { 0, 0 }
                end

                if value_field.reset_kind == RESET_INT64 then
                    value = { 0, 0 }
                end

                local entry = { key = key, value = value }

                ::entry_loop::

                if position <= end_position then
                    local entry_tag = read_varint32()
                    local entry_number = math_floor( entry_tag / 8 )
                    local entry_wire_type = entry_tag % 8

                    if entry_number == 1 and entry_wire_type == key_field.wire then
                        key_read( entry )
                    elseif entry_number == 2 and entry_wire_type == value_field.wire then
                        value_read( entry )
                    else
                        skip_field( entry_wire_type, entry_number )
                    end

                    goto entry_loop
                end

                limit = saved_limit

                key, value = entry.key, entry.value

                if raw_type( key ) == "string" or raw_type( key ) == "number" or raw_type( key ) == "boolean" then
                    map[ key ] = value
                else
                    -- 64-bit keys are `{ low, high }` tables, the number is used if it is exact
                    ---@cast key integer[]
                    local low, high = key[ 1 ], key[ 2 ]
                    if high >= -0x200000 and high < 0x200000 then
                        map[ high * UINT32 + low ] = value
                    else
                        map[ key ] = value
                    end
                end
            end

            return field
        end

        local is_nullable = is_nullable_type( field_type )

        if is_repeated then
            field.reset_kind = RESET_TABLE

            ---@param list table
            function field.encode( list )
                local count = list.n or #list

                for index = 1, count, 1 do
                    local value = list[ index ]
                    if value == nil and not is_nullable then
                        error( EncodeError( string_format( "field '%s' has nil at index %d", name, index ), list ), 0 )
                    end

                    put( tag )
                    encode_nested( field_type, value )
                end
            end

            if is_nullable then
                ---@param target table
                function field.read( target )
                    local list = target[ name ]
                    if list == nil then
                        list = {}
                        target[ name ] = list
                    end

                    local count = (list.n or 0) + 1
                    list[ count ] = decode_nested( field_type )
                    list.n = count
                end
            else
                ---@param target table
                function field.read( target )
                    local list = target[ name ]
                    if list == nil then
                        list = {}
                        target[ name ] = list
                    end

                    list[ #list + 1 ] = decode_nested( field_type )
                end
            end
        else
            field.reset_kind = RESET_NONE

            ---@param value any
            function field.encode( value )
                put( tag )
                encode_nested( field_type, value )
            end

            ---@param target table
            function field.read( target )
                if siblings ~= nil then
                    for index = 1, #siblings, 1 do
                        target[ siblings[ index ] ] = nil
                    end
                end

                target[ name ] = decode_nested( field_type )
            end
        end

        return field
    end

    ---@cast field_type dreamwork.std.protobuf.Enum | string
    local codec = get_codec( field_type )
    local wire, write, read = codec.wire, codec.write, codec.read

    local tag = varint32_string( number * 8 + wire )
    field.wire = wire

    if is_repeated then
        field.reset_kind = RESET_TABLE

        local is_packable = wire ~= WIRE_LEN
        field.packable = is_packable

        local is_packed = is_packable and descriptor.packed ~= false and (descriptor.packed == true or syntax == "proto3")

        if is_packed then
            local packed_tag = varint32_string( number * 8 + WIRE_LEN )

            ---@param list table
            function field.encode( list )
                local count = #list
                if count == 0 then
                    return
                end

                put( packed_tag )
                local slot, start = begin_length()

                for index = 1, count, 1 do
                    write( list[ index ] )
                end

                end_length( slot, start )
            end
        else
            ---@param list table
            function field.encode( list )
                for index = 1, #list, 1 do
                    put( tag )
                    write( list[ index ] )
                end
            end
        end

        ---@param target table
        function field.read( target )
            local list = target[ name ]
            if list == nil then
                list = {}
                target[ name ] = list
            end

            list[ #list + 1 ] = read()
        end

        if is_packable then
            ---@param target table
            function field.read_packed( target )
                local list = target[ name ]
                if list == nil then
                    list = {}
                    target[ name ] = list
                end

                local length = read_varint32()
                local end_position = position + length - 1

                if end_position > limit then
                    decode_error( "unexpected end of data" )
                end

                local count = #list

                ::packed_loop::

                if position <= end_position then
                    count = count + 1
                    list[ count ] = read()
                    goto packed_loop
                end

                if position ~= end_position + 1 then
                    decode_error( "packed field overruns its length" )
                end
            end
        end

        return field
    end

    field.packable = false

    if has_presence then
        local default = descriptor.default

        if default ~= nil then
            if raw_type( field_type ) ~= "string" and raw_type( default ) == "string" then
                ---@cast field_type dreamwork.std.protobuf.Enum
                default = field_type.values[ default ]
            end

            field.reset_kind = RESET_VALUE
            field.reset_value = default
        else
            field.reset_kind = RESET_NONE
        end

        ---@param value any
        function field.encode( value )
            put( tag )
            write( value )
        end
    else
        if codec.is_64 then
            field.reset_kind = RESET_INT64

            ---@param value number | integer[]
            function field.encode( value )
                if not is_zero64( value ) then
                    put( tag )
                    write( value )
                end
            end
        else
            local default = codec.default

            field.reset_kind = RESET_VALUE
            field.reset_value = default

            ---@param value any
            function field.encode( value )
                if value ~= default then
                    put( tag )
                    write( value )
                end
            end
        end
    end

    if siblings == nil then
        ---@param target table
        function field.read( target )
            target[ name ] = read()
        end
    else
        ---@param target table
        function field.read( target )
            for index = 1, #siblings, 1 do
                target[ siblings[ index ] ] = nil
            end

            target[ name ] = read()
        end
    end

    return field
end

---@param message_type dreamwork.std.protobuf.Type
function compile_type( message_type )
    if message_type.compiled then
        return
    end

    -- set first, recursive types refer to themselves
    message_type.compiled = true

    local descriptor = message_type.descriptor
    local field_descriptors = descriptor.fields

    ---@type dreamwork.std.protobuf.Field[]
    local fields = {}

    ---@type table<integer, dreamwork.std.protobuf.Field>
    local by_number = {}

    local syntax = message_type.syntax

    local success, result = pcall( function()
        for index = 1, #field_descriptors, 1 do
            local field = compile_field( message_type, field_descriptors[ index ], syntax )
            fields[ index ] = field

            if by_number[ field.number ] ~= nil then
                error( string_format( "field number %d is used twice in '%s'", field.number, message_type.name ), 0 )
            end

            by_number[ field.number ] = field
        end

        return nil
    end )

    if not success then
        message_type.compiled = false
        error( result, 0 )
    end

    -- encoded in field number order, like protoc
    table_sort( fields, function( a, b )
        return a.number < b.number
    end )

    message_type.fields = fields
    message_type.field_count = #fields
    message_type.by_number = by_number

    local unwrap_name = message_type.unwrap_name
    if unwrap_name ~= nil then
        for index = 1, #fields, 1 do
            if fields[ index ].name == unwrap_name then
                message_type.unwrap_field = fields[ index ]
            end
        end
    end
end

--- Sets the initial values of the fields, defaults for fields without presence and new tables for repeated and map fields.
---
---@param message_type dreamwork.std.protobuf.Type
---@param target table
---@param is_new boolean `false` if the target is reused, fields with presence are cleared.
local function reset_fields( message_type, target, is_new )
    local fields = message_type.fields

    for index = 1, message_type.field_count, 1 do
        local field = fields[ index ]
        local kind = field.reset_kind

        if kind == RESET_VALUE then
            target[ field.name ] = field.reset_value
        elseif kind == RESET_TABLE then
            target[ field.name ] = {}
        elseif kind == RESET_INT64 then
            target[ field.name ] = { 0, 0 }
        elseif not is_new then
            target[ field.name ] = nil
        end
    end
end

--- Reads the fields until the end of the current message.
---
---@param message_type dreamwork.std.protobuf.Type
---@param target table
local function decode_fields( message_type, target )
    local by_number = message_type.by_number

    ::field_loop::

    if position > limit then
        return
    end

    local tag = read_varint32()
    local number = math_floor( tag / 8 )
    local wire_type = tag % 8

    if number == 0 then
        decode_error( "invalid field number 0" )
    end

    local field = by_number[ number ]

    if field == nil then
        skip_field( wire_type, number )
    elseif wire_type == field.wire then
        field.read( target )
    elseif wire_type == WIRE_LEN and field.packable then
        ---@diagnostic disable-next-line: need-check-nil
        field.read_packed( target )
    else
        decode_error( string_format( "wrong wire type %d of field '%s'", wire_type, field.name ) )
    end

    goto field_loop
end

---@param message_type dreamwork.std.protobuf.Type
---@return any
local function decode_special( message_type )
    local special = message_type.special

    ---@type table
    local temporary = {}
    reset_fields( message_type, temporary, true )
    decode_fields( message_type, temporary )

    if special == "unwrap" then
        ---@diagnostic disable-next-line: need-check-nil
        return temporary[ message_type.unwrap_field.name ]
    elseif special == "nullable" then
        return temporary.value
    end

    -- google.protobuf.Value, `null_value` is `nil`
    local value = temporary.number_value
    if value ~= nil then
        return value
    end

    value = temporary.string_value
    if value ~= nil then
        return value
    end

    value = temporary.bool_value
    if value ~= nil then
        return value
    end

    value = temporary.struct_value
    if value ~= nil then
        return value
    end

    return temporary.list_value
end

---@param message_type dreamwork.std.protobuf.Type
---@return any
function decode_message( message_type )
    if not message_type.compiled then
        compile_type( message_type )
    end

    local create = message_type.create

    if create == nil then
        if message_type.special ~= nil then
            return decode_special( message_type )
        end

        ---@type table
        local message = {}
        reset_fields( message_type, message, true )
        decode_fields( message_type, message )
        return message
    end

    local obj = create()

    local from_proto = message_type.from_proto
    if from_proto == nil then
        reset_fields( message_type, obj, true )
        decode_fields( message_type, obj )
        return obj
    end

    local value
    if message_type.special ~= nil then
        value = decode_special( message_type )
    else
        value = {}
        reset_fields( message_type, value, true )
        decode_fields( message_type, value )
    end

    from_proto( obj, value )
    return obj
end

---@param message_type dreamwork.std.protobuf.Type
---@param value any
local function encode_special( message_type, value )
    local special = message_type.special

    if special == "unwrap" then
        if value ~= nil then
            ---@diagnostic disable-next-line: need-check-nil
            message_type.unwrap_field.encode( value )
        end

        return
    elseif special == "nullable" then
        if value == nil then
            -- `null = 1`, `NULL_VALUE` is `0`
            put( "\8\0" )
        else
            message_type.by_number[ 2 ].encode( value )
        end

        return
    end

    -- google.protobuf.Value
    local by_number = message_type.by_number

    if value == nil then
        put( "\8\0" )
    elseif raw_type( value ) == "number" then
        by_number[ 2 ].encode( value )
    elseif raw_type( value ) == "string" then
        by_number[ 3 ].encode( value )
    elseif raw_type( value ) == "boolean" then
        by_number[ 4 ].encode( value )
    elseif raw_type( value ) == "table" then
        if (value[ 1 ] ~= nil or value.n ~= nil) then
            by_number[ 6 ].encode( value )
        else
            by_number[ 5 ].encode( value )
        end
    else
        error( EncodeError( string_format( "'%s' can not be encoded as google.protobuf.Value", raw_type( value ) ), value ), 0 )
    end
end

---@param message_type dreamwork.std.protobuf.Type
---@param value any
function encode_body( message_type, value )
    if not message_type.compiled then
        compile_type( message_type )
    end

    local value_type = raw_type( value )

    if value_type == "table" or value_type == "userdata" or value_type == "cdata" then
        local to_proto = value.__toProto
        if to_proto ~= nil then
            value = to_proto( value )
        end
    end

    if message_type.special ~= nil then
        encode_special( message_type, value )
        return
    end

    local fields = message_type.fields

    for index = 1, message_type.field_count, 1 do
        local field = fields[ index ]

        local field_value = value[ field.name ]
        if field_value ~= nil then
            field.encode( field_value )
        end
    end
end

-- Registration

---@type table<string, true>
local reserved_prefixes = {
    [ "google/protobuf/" ] = true,
    [ "dreamwork/" ] = true
}

---@param file_name string
---@return boolean
local function is_reserved( file_name )
    for prefix in raw_pairs( reserved_prefixes ) do
        if string_hasPrefix( file_name, prefix ) then
            return true
        end
    end

    return false
end

local load_file

--- The files whose imports are being loaded, to report import cycles.
---
---@type table<string, boolean>
local importing = {}

--- Registers the types of the parsed file in the scope.
---
---@param scope dreamwork.std.protobuf.Scope
---@param descriptor dreamwork.std.protobuf.FileDescriptor
---@param file_name string
---@return dreamwork.std.protobuf.File
local function register_file( scope, descriptor, file_name )
    local imports = descriptor.imports

    importing[ file_name ] = true

    for index = 1, #imports, 1 do
        local import_path = imports[ index ].path

        if scope.files[ import_path ] == nil and global_files[ import_path ] == nil then
            local owner = scope.owner

            if owner == nil or is_reserved( import_path ) then
                error( string_format( "%s: import '%s' was not found, parse it first", file_name, import_path ), 0 )
            end

            if importing[ import_path ] then
                importing[ file_name ] = nil
                error( string_format( "%s: import cycle with '%s'", file_name, import_path ), 0 )
            end

            ---@cast owner dreamwork.sandbox.Owner
            local success, message = pcall( load_file, scope, import_path, owner.root .. "/" .. import_path )
            if not success then
                importing[ file_name ] = nil
                error( message, 0 )
            end
        end
    end

    importing[ file_name ] = nil

    local old_file = scope.files[ file_name ]
    if old_file ~= nil then
        -- parsing the same file again replaces its types
        for full_name in raw_pairs( old_file.types ) do
            scope.types[ full_name ] = nil
        end
    end

    ---@type table<string, dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum>
    local file_types = {}

    local syntax = descriptor.syntax
    local scope_types = scope.types

    ---@param full_name string
    ---@param object dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum
    local function add_type( full_name, object )
        if file_types[ full_name ] ~= nil or scope_types[ full_name ] ~= nil or (scope ~= global_scope and global_types[ full_name ] ~= nil) then
            error( string_format( "%s: '%s' is already defined", file_name, full_name ), 0 )
        end

        file_types[ full_name ] = object
    end

    ---@param enum_descriptor dreamwork.std.protobuf.EnumDescriptor
    local function add_enum( enum_descriptor )
        ---@type dreamwork.std.protobuf.Enum
        local enum = class_new( Enum )
        enum.name = enum_descriptor.full_name
        enum.file = file_name

        local values, names = {}, {}

        local enum_values = enum_descriptor.values
        for index = 1, #enum_values, 1 do
            local enum_value = enum_values[ index ]
            values[ enum_value.name ] = enum_value.number

            if names[ enum_value.number ] == nil then
                names[ enum_value.number ] = enum_value.name
            end
        end

        enum.values, enum.names = values, names
        add_type( enum.name, enum )
    end

    local add_message

    ---@param message_descriptor dreamwork.std.protobuf.MessageDescriptor
    function add_message( message_descriptor )
        ---@type dreamwork.std.protobuf.Type
        local message_type = class_new( Type )
        message_type.name = message_descriptor.full_name
        message_type.file = file_name
        message_type.descriptor = message_descriptor
        message_type.syntax = syntax
        message_type.scope = scope
        message_type.compiled = false

        add_type( message_type.name, message_type )

        local nested_messages = message_descriptor.messages
        for index = 1, #nested_messages, 1 do
            add_message( nested_messages[ index ] )
        end

        local nested_enums = message_descriptor.enums
        for index = 1, #nested_enums, 1 do
            add_enum( nested_enums[ index ] )
        end
    end

    local messages = descriptor.messages
    for index = 1, #messages, 1 do
        add_message( messages[ index ] )
    end

    local enums = descriptor.enums
    for index = 1, #enums, 1 do
        add_enum( enums[ index ] )
    end

    for full_name, object in raw_pairs( file_types ) do
        scope_types[ full_name ] = object
    end

    ---@type dreamwork.std.protobuf.File
    local file = {
        name = file_name,
        package = descriptor.package,
        types = file_types,
        descriptor = descriptor
    }

    scope.files[ file_name ] = file
    return file
end

---@param scope dreamwork.std.protobuf.Scope
---@param file_name string
---@param file_path string
---@return dreamwork.std.protobuf.File
function load_file( scope, file_name, file_path )
    local file = scope.files[ file_name ]
    if file ~= nil then
        return file
    end

    local source = vfs_readFile( file_path, true )
    return register_file( scope, parseSchema( source, file_name ), file_name )
end

--- [SHARED AND MENU]
---
--- Parses the text of a `.proto` file and registers its types.
---
--- Inside of a package the types belong to the package, imports that are not registered yet
--- are loaded from the files of the package (`import "proto/items.proto"`).
--- Outside of packages the types are global, imports must be registered before.
---
--- Parsing a file with the same name again replaces its types.
---
--- ```lua
--- protobuf.parse( [[
---     syntax = "proto3";
---     package my_pkg;
---
---     import "dreamwork/math.proto";
---
---     message Spawn {
---         string model = 1;
---         dreamwork.Vector3 position = 2;
---     }
--- ]], "spawn.proto" )
--- ```
---
---@param source string The text of the `.proto` file.
---@param file_name string? The name of the file, imports refer to it by this name, `"<string>"` by default.
---@return dreamwork.std.protobuf.File file The registered file.
function protobuf.parse( source, file_name )
    if file_name == nil then
        file_name = "<string>"
    end

    local owner = sandbox_owner( 2 )
    if owner ~= nil and is_reserved( file_name ) then
        error( string_format( "file name '%s' is reserved for built-in files", file_name ), 2 )
    end

    local scope = get_scope( owner )

    local success, descriptor = pcall( parseSchema, source, file_name )
    if not success then
        error( descriptor, 2 )
    end

    local file_obj
    success, file_obj = pcall( register_file, scope, descriptor, file_name )
    if not success then
        error( file_obj, 2 )
    end

    return file_obj
end

--- [SHARED AND MENU]
---
--- Loads a `.proto` file of the package and registers its types for the package, imports are loaded the same way.
---
--- The path is relative to the root of the package, the file name of the registered file is that path,
--- so other files import it with `import "proto/items.proto";`.
--- A file that is already loaded is returned as is.
---
--- Clients need the file too: add it to `client_files` of `package.json`.
---
--- ```lua
--- protobuf.load( "proto/items.proto" )
---
--- local Item = protobuf.Type.find( "my_pkg.Item" )
--- ```
---
---@param file_path string The path of the file relative to the root of the package, or an absolute path outside of packages.
---@return dreamwork.std.protobuf.File file The registered file.
function protobuf.load( file_path )
    local owner = sandbox_owner( 2 )
    local scope = get_scope( owner )

    local full_path = file_path
    if owner ~= nil then
        if string_byte( file_path, 1 ) == 0x2F --[[ / ]] then
            error( "packages load files by paths relative to their root", 2 )
        end

        full_path = owner.root .. "/" .. file_path
    end

    local success, result = pcall( load_file, scope, file_path, full_path )
    if not success then
        error( result, 2 )
    end

    return result
end

--- Returns the message type or the enum by its full name, the types of the package of the caller first.
---
---@param name string
---@param stack_level integer The level of the caller of the public function, `1` is `find_object` itself.
---@return dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | nil
local function find_object( name, stack_level )
    if string_byte( name, 1 ) == 0x2E --[[ . ]] then
        name = string_sub( name, 2 )
    end

    local owner = sandbox_owner( stack_level )
    if owner ~= nil then
        local scope = package_scopes[ owner ]
        if scope ~= nil then
            local object = scope.types[ name ]
            if object ~= nil then
                return object
            end
        end
    end

    return global_types[ name ]
end

--- [SHARED AND MENU]
---
--- Returns the message type or the enum by its full name,
--- the types of the calling package are searched first, then the global ones.
---
--- Use `protobuf.Type.find` or `protobuf.Enum.find` when only one kind is expected.
---
--- ```lua
--- local object = protobuf.find( "dreamwork.Vector3" )
--- ```
---
---@param name string The full name, e.g. `my_pkg.Item`, a leading `.` is allowed.
---@return dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | nil object The type, `nil` if it was not found.
---@nodiscard
function protobuf.find( name )
    -- not a tail call, `find_object` looks up the package of the caller by the stack level
    local object = find_object( name, 3 )
    return object
end

--- [SHARED AND MENU]
---
--- Returns the message type by its full name,
--- the types of the calling package are searched first, then the global ones.
---
--- ```lua
--- local Item = protobuf.Type.find( "my_pkg.Item" )
--- ```
---
---@param name string The full name, e.g. `my_pkg.Item`, a leading `.` is allowed.
---@return dreamwork.std.protobuf.Type | nil message_type The message type, `nil` if it was not found or the name is an enum.
---@nodiscard
function TypeClass.find( name )
    local object = find_object( name, 3 )
    if is_type( object ) then
        ---@cast object dreamwork.std.protobuf.Type
        return object
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Returns the enum by its full name,
--- the types of the calling package are searched first, then the global ones.
---
--- ```lua
--- local Rarity = protobuf.Enum.find( "my_pkg.Rarity" )
--- print( Rarity.values.EPIC ) -- 2
--- ```
---
---@param name string The full name, e.g. `my_pkg.Rarity`, a leading `.` is allowed.
---@return dreamwork.std.protobuf.Enum | nil enum The enum, `nil` if it was not found or the name is a message type.
---@nodiscard
function EnumClass.find( name )
    local object = find_object( name, 3 )
    if raw_type( object ) == "table" and debug_getmetatable( object ) == Enum then
        ---@cast object dreamwork.std.protobuf.Enum
        return object
    end

    return nil
end

--- Returns the type of the value from its `__proto` field.
---
---@param value any
---@return dreamwork.std.protobuf.Type | nil
local function type_of( value )
    local value_type = raw_type( value )
    if value_type ~= "table" and value_type ~= "userdata" and value_type ~= "cdata" then
        return nil
    end

    local proto = value.__proto
    if raw_type( proto ) == "string" then
        ---@cast proto string
        proto = global_types[ proto ]
    end

    if is_type( proto ) then
        ---@cast proto dreamwork.std.protobuf.Type
        return proto
    end

    return nil
end

--- Encodes the value with the encoder state saved, so hooks can encode too.
---
---@param message_type dreamwork.std.protobuf.Type
---@param value any
---@return string
local function encode( message_type, value )
    local saved_parts, saved_count, saved_size = parts, part_count, size
    parts, part_count, size = {}, 0, 0

    encode_body( message_type, value )
    local result = table_concat( parts, "", 1, part_count )

    parts, part_count, size = saved_parts, saved_count, saved_size
    return result
end

--- Decodes the message from the whole string with the decoder state saved.
---
---@param message_type dreamwork.std.protobuf.Type
---@param str string
---@param target any
---@return any
local function decode( message_type, str, target )
    local saved_data, saved_position, saved_limit = data, position, limit
    data, position, limit = str, 1, #str

    if not message_type.compiled then
        compile_type( message_type )
    end

    local result

    if target == nil then
        result = decode_message( message_type )
    else
        ---@type ( fun( obj: any, value: any ) ) | nil
        local from_proto

        if raw_type( target ) == "table" and raw_get( target, "__base" ) ~= nil then
            -- a class, the object is created without `__init`
            local base = raw_get( target, "__base" )

            if message_type.class == target and message_type.create ~= nil then
                target = message_type.create()
            else
                target = class_new( base )
            end

            from_proto = base.__fromProto
        else
            from_proto = target.__fromProto
        end

        if from_proto == nil then
            if message_type.special ~= nil then
                error( string_format( "'%s' is not a message with fields, decode it without a target", message_type.name ), 0 )
            end

            reset_fields( message_type, target, false )
            decode_fields( message_type, target )
        else
            local value
            if message_type.special ~= nil then
                value = decode_special( message_type )
            else
                value = {}
                reset_fields( message_type, value, true )
                decode_fields( message_type, value )
            end

            from_proto( target, value )
        end

        result = target
    end

    data, position, limit = saved_data, saved_position, saved_limit
    return result
end

--- [SHARED AND MENU]
---
--- Encodes the value as the message.
---
--- ```lua
--- local data = Item:encode( { id = 1, name = "crowbar" } )
--- ```
---
---@param value any The message table, an object of a bound class, or any object with `__toProto`.
---@return string data The encoded message.
---@nodiscard
function Type:encode( value )
    local success, result = pcall( encode, self, value )
    if not success then
        -- the encoder state is lost on errors, start over with new parts
        parts, part_count, size = {}, 0, 0
        error( result, 2 )
    end

    return result
end

--- [SHARED AND MENU]
---
--- Decodes the message.
---
--- Without `target` the message is an object of the bound class (see `Type:bind`) or a table.
--- With a class the message is a new object of the class (created without `__init`),
--- with an object or a table the message is read into it, fields that are missing in the data are reset.
---
--- ```lua
--- local item = Item:decode( data )
--- local position = Vector3Type:decode( data, std.Vector3 )
--- ```
---
---@param str string The encoded message.
---@param target any The class of the message or the object to read into.
---@return any message The decoded message.
---@nodiscard
function Type:decode( str, target )
    local success, result = pcall( decode, self, str, target )
    if not success then
        data, position, limit = "", 1, 0
        error( result, 2 )
    end

    return result
end

---@param message_type dreamwork.std.protobuf.Type
---@param cls any
---@param create ( fun(): any )?
---@param stack_level integer
local function bind_class( message_type, cls, create, stack_level )
    local base = raw_get( cls, "__base" )

    if create == nil then
        function create()
            return class_new( base )
        end
    end

    -- ffi metatypes can't be changed, they declare `__proto = "full.Name"` themselves
    local proto = raw_get( base, "__proto" )
    if proto == nil then
        raw_set( base, "__proto", message_type )
    elseif proto ~= message_type and proto ~= message_type.name then
        error( string_format( "class already has the protobuf type '%s'", tostring( proto ) ), stack_level + 1 )
    end

    message_type.class = cls
    message_type.create = create
    message_type.from_proto = base.__fromProto
end

--- [SHARED AND MENU]
---
--- Binds the class to the message type: decoded messages become objects of the class
--- and `writer:writeProto( obj )` finds the type of its objects.
---
--- Fields of the message are read from and written to the fields of the object with the same names,
--- the class can convert itself with the `__toProto( self ): any` and `__fromProto( self, value )` hooks instead.
---
--- ```lua
--- local Item = protobuf.Type.find( "my_pkg.Item" )
--- Item:bind( ItemClass )
---
--- local item = Item:decode( data ) -- ItemClass object
--- ```
---
---@param cls any The class.
---@param create ( fun(): any )? Creates a new object of the class, `class.new( cls.__base )` (without `__init`) by default.
---@return dreamwork.std.protobuf.Type self The same type.
function Type:bind( cls, create )
    bind_class( self, cls, create, 2 )
    return self
end

--- [SHARED AND MENU]
---
--- Finds the message type by its full name and binds the class to it, a short form of
--- `protobuf.Type.find( name ):bind( cls, create )`, see `Type:bind`.
---
--- The types of the calling package are searched first, then the global ones.
---
--- ```lua
--- protobuf.Type.bind( "my_pkg.Item", ItemClass )
--- ```
---
---@param name string The full name of the message type, e.g. `my_pkg.Item`, a leading `.` is allowed.
---@param cls any The class.
---@param create ( fun(): any )? Creates a new object of the class, `class.new( cls.__base )` (without `__init`) by default.
---@return dreamwork.std.protobuf.Type message_type The message type.
function TypeClass.bind( name, cls, create )
    local object = find_object( name, 3 )
    if not is_type( object ) then
        error( string_format( "message type '%s' was not found", name ), 2 )
    end

    ---@cast object dreamwork.std.protobuf.Type
    bind_class( object, cls, create, 2 )
    return object
end

--- [SHARED AND MENU]
---
--- Returns the descriptors of the fields in declaration order.
---
---@return dreamwork.std.protobuf.FieldDescriptor[] fields The field descriptors.
---@nodiscard
function Type:getFields()
    return self.descriptor.fields
end

-- Generic types

---@type table<any, dreamwork.std.protobuf.Type>
local nullable_types = {}

---@type table<any, dreamwork.std.protobuf.Type>
local list_types = {}

---@type table<any, dreamwork.std.protobuf.Type>
local tree_types = {}

gc_setTableRules( nullable_types, true, false )
gc_setTableRules( list_types, true, false )
gc_setTableRules( tree_types, true, false )

---@param element any
---@return dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | string
local function element_type( element )
    if raw_type( element ) == "string" then
        ---@cast element string
        if scalar_types[ element ] then
            return element
        end

        local object = global_types[ element ]
        if object == nil then
            error( string_format( "unknown type '%s'", element ), 3 )
        end

        return object
    end

    if raw_type( element ) == "table" then
        local metatable = debug_getmetatable( element )
        if metatable == Type or metatable == Enum then
            return element
        end
    end

    -- a class
    local base = raw_get( element, "__base" )
    local proto = base and raw_get( base, "__proto" ) or nil

    if raw_type( proto ) == "string" then
        proto = global_types[ proto ]
    end

    if proto == nil then
        error( "class has no protobuf type, bind it with `Type:bind` first", 3 )
    end

    return proto
end

---@param element dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | string
---@return string
local function element_name( element )
    if raw_type( element ) == "string" then
        ---@cast element string
        return element
    end

    ---@cast element dreamwork.std.protobuf.Type
    return element.name
end

---@param name string
---@param fields dreamwork.std.protobuf.FieldDescriptor[]
---@param oneofs string[]
---@return dreamwork.std.protobuf.Type
local function synthetic_type( name, fields, oneofs )
    ---@type dreamwork.std.protobuf.Type
    local message_type = class_new( Type )
    message_type.name = name
    message_type.file = "<generated>"
    message_type.descriptor = {
        name = name,
        full_name = name,
        fields = fields,
        oneofs = oneofs,
        messages = {},
        enums = {},
        map_entry = false
    }

    message_type.syntax = "proto3"
    message_type.scope = global_scope
    message_type.compiled = false

    return message_type
end

local null_value_type

--- [SHARED AND MENU]
---
--- Returns the message type that holds the value or `nil`:
--- `message { oneof kind { google.protobuf.NullValue null = 1; T value = 2; } }`.
---
--- Its Lua value is the value itself, `nil` is written as `null`, so it keeps `nil` in `repeated` fields.
---
---@param element dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | dreamwork.std.Class | string The type of the value, a bound class or a type name.
---@return dreamwork.std.protobuf.Type nullable_type The message type.
---@nodiscard
function protobuf.nullable( element )
    local value_type = element_type( element )

    local nullable_type = nullable_types[ value_type ]
    if nullable_type == nil then
        nullable_type = synthetic_type( "dreamwork.Nullable<" .. element_name( value_type ) .. ">", {
            { name = "null",  number = 1, type_name = "google.protobuf.NullValue", resolved = null_value_type, scope = "", oneof = 1 },
            { name = "value", number = 2, type_name = element_name( value_type ),  resolved = value_type,      scope = "", oneof = 1 }
        }, { "kind" } )

        nullable_type.special = "nullable"
        nullable_types[ value_type ] = nullable_type
    end

    return nullable_type
end

--- [SHARED AND MENU]
---
--- Returns the message type of a list of values that can be `nil`:
--- `message { repeated Nullable<T> values = 1; }`.
---
--- Its Lua value is the array, the length is `list.n` or `#list`, decoded arrays have `n` set.
---
--- ```lua
--- writer:writeProto( queue, protobuf.list( std.Vector3 ) )
--- local queue = reader:readProto( std.Queue, protobuf.list( std.Vector3 ) )
--- ```
---
---@param element dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | dreamwork.std.Class | string The type of the values, a bound class or a type name.
---@return dreamwork.std.protobuf.Type list_type The message type.
---@nodiscard
function protobuf.list( element )
    local value_type = element_type( element )

    local list_type = list_types[ value_type ]
    if list_type == nil then
        local nullable_type = protobuf.nullable( value_type )

        list_type = synthetic_type( "dreamwork.List<" .. element_name( value_type ) .. ">", {
            { name = "values", number = 1, label = "repeated", type_name = nullable_type.name, resolved = nullable_type, scope = "" }
        }, {} )

        list_type.special = "unwrap"
        list_type.unwrap_name = "values"
        list_types[ value_type ] = list_type
    end

    return list_type
end

--- [SHARED AND MENU]
---
--- Returns the message type of a tree node:
--- `message Tree { Nullable<T> value = 1; repeated Tree children = 2; }`.
---
--- Its Lua value is `{ value = any, children = { ... } }`, `std.Node` converts itself to it.
---
--- ```lua
--- writer:writeProto( root, protobuf.tree( std.Vector3 ) )
--- local root = reader:readProto( std.Node, protobuf.tree( std.Vector3 ) )
--- ```
---
---@param element dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | dreamwork.std.Class | string The type of the values, a bound class or a type name.
---@return dreamwork.std.protobuf.Type tree_type The message type.
---@nodiscard
function protobuf.tree( element )
    local value_type = element_type( element )

    local tree_type = tree_types[ value_type ]
    if tree_type == nil then
        local nullable_type = protobuf.nullable( value_type )
        local children = { name = "children", number = 2, label = "repeated", type_name = "", scope = "" }

        tree_type = synthetic_type( "dreamwork.Tree<" .. element_name( value_type ) .. ">", {
            { name = "value", number = 1, type_name = nullable_type.name, resolved = nullable_type, scope = "" },
            children
        }, {} )

        children.type_name = tree_type.name
        children.resolved = tree_type

        tree_types[ value_type ] = tree_type
    end

    return tree_type
end

-- BinaryWriter / BinaryReader

---@param value any
---@param proto_type dreamwork.std.protobuf.Type | nil
---@return dreamwork.std.protobuf.Type
local function writer_type( value, proto_type )
    if proto_type == nil then
        proto_type = type_of( value )
        if proto_type == nil then
            error( "value has no protobuf type, pass it as the second argument", 3 )
        end
    end

    ---@cast proto_type dreamwork.std.protobuf.Type
    return proto_type
end

--- [SHARED AND MENU]
---
--- Writes the value as a length-prefixed protobuf message (varint length, then the message),
--- the cursor doesn't have to be aligned.
---
--- ```lua
--- writer:writeProto( Vector3( 1, 2, 3 ) )
--- writer:writeProto( { id = 1 }, protobuf.Type.find( "my_pkg.Item" ) )
--- ```
---
---@param value any The object of a bound class, or any value with `proto_type`.
---@param proto_type dreamwork.std.protobuf.Type? The message type, the type of the object (`__proto`) by default.
---@return integer byte_count The number of bytes written.
function BinaryWriter:writeProto( value, proto_type )
    proto_type = writer_type( value, proto_type )

    local success, result = pcall( encode, proto_type, value )
    if not success then
        parts, part_count, size = {}, 0, 0
        error( result, 2 )
    end

    local prefix = varint32_string( #result )
    self:write( prefix )
    self:write( result )

    return #prefix + #result
end

--- [SHARED AND MENU]
---
--- Reads a length-prefixed protobuf message written by `BinaryWriter:writeProto`.
---
--- `target` is a class (a new object of it), an object (read into it) or a message type (a table or an object of the bound class).
---
--- ```lua
--- local position = reader:readProto( std.Vector3 )
--- local item = reader:readProto( protobuf.Type.find( "my_pkg.Item" ) )
--- local queue = reader:readProto( std.Queue, protobuf.list( std.Vector3 ) )
--- ```
---
---@param target any The class, the object or the message type.
---@param proto_type dreamwork.std.protobuf.Type? The message type, the type of the class or object (`__proto`) by default.
---@return any message The decoded message.
function BinaryReader:readProto( target, proto_type )
    if is_type( target ) then
        proto_type, target = target, nil
    elseif proto_type == nil then
        if raw_type( target ) == "table" and raw_get( target, "__base" ) ~= nil then
            proto_type = type_of( raw_get( target, "__base" ) )
        else
            proto_type = type_of( target )
        end

        if proto_type == nil then
            error( "target has no protobuf type, pass it as the second argument", 2 )
        end
    end

    local length, shift = 0, 1

    for _ = 1, 5, 1 do
        local byte = self:readUInt( 8 )
        length = length + (byte % 0x80) * shift

        if byte < 0x80 then
            ---@cast proto_type dreamwork.std.protobuf.Type
            local success, result = pcall( decode, proto_type, self:read( length ), target )
            if not success then
                data, position, limit = "", 1, 0
                error( result, 2 )
            end

            return result
        end

        shift = shift * 0x80
    end

    error( DecodeError( "malformed message length" ), 2 )
end

dreamwork.load( "std/codec/protobuf/schemas.lua" )

null_value_type = global_types[ "google.protobuf.NullValue" ]

-- Lua mappings of the well-known types
do

    ---@param name string
    ---@param special "nullable" | "unwrap" | "value"
    ---@param unwrap_name string?
    local function set_special( name, special, unwrap_name )
        local message_type = global_types[ name ]
        ---@cast message_type dreamwork.std.protobuf.Type

        message_type.special = special
        message_type.unwrap_name = unwrap_name
    end

    set_special( "google.protobuf.Value", "value" )
    set_special( "google.protobuf.Struct", "unwrap", "fields" )
    set_special( "google.protobuf.ListValue", "unwrap", "values" )

    for _, name in raw_pairs( { "Double", "Float", "Int64", "UInt64", "Int32", "UInt32", "Bool", "String", "Bytes" } ) do
        set_special( "google.protobuf." .. name .. "Value", "unwrap", "value" )
    end

end

-- dreamwork types, ffi classes declare `__proto` themselves
do

    ---@param name string
    ---@param cls any
    ---@param create ( fun(): any )?
    function dreamwork.protobuf( name, cls, create )
        ---@cast cls dreamwork.std.Class

        local message_type = global_types[ name ]
        ---@cast message_type dreamwork.std.protobuf.Type

        message_type:bind( cls, create )
    end

    local Vector2, Vector3 = std.Vector2, std.Vector3
    local Angle3, Quaternion, VMatrix = std.Angle3, std.Quaternion, std.VMatrix

    -- constructors give ffi objects when ffi is available, `class.new` would give tables
    dreamwork.protobuf( "dreamwork.Vector2", Vector2, function() return Vector2() end )
    dreamwork.protobuf( "dreamwork.Vector3", Vector3, function() return Vector3() end )
    dreamwork.protobuf( "dreamwork.Angle3", Angle3, function() return Angle3() end )
    dreamwork.protobuf( "dreamwork.Quaternion", Quaternion, function() return Quaternion() end )
    dreamwork.protobuf( "dreamwork.VMatrix", VMatrix, function() return VMatrix() end )

    dreamwork.protobuf( "dreamwork.BigInteger", std.BigInteger )
    dreamwork.protobuf( "dreamwork.Version", std.Version )

    local fluent = std.fluent

    dreamwork.protobuf( "dreamwork.FluentNumber", fluent.Number )
    dreamwork.protobuf( "dreamwork.FluentDateTime", fluent.DateTime )

end
