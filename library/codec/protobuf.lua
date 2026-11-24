---@meta _

---@class dreamwork
local dreamwork = {}

---@class BinaryReader
BinaryReader.__base = {}

---@class BinaryWriter
BinaryWriter.__base = {}

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
---@class protobuf
protobuf = {}

---@class protobuf.ScalarCodec
---@field wire integer The wire type.
---@field write fun( value: any )
---@field read fun(): any
---@field default any The default value, `nil` for 64-bit types (a new `{ 0, 0 }` every time).
---@field is_64 boolean

--- [SHARED AND MENU]
---
--- The enum type of a `.proto` file, found with `protobuf.Enum.find`.
---
---@class protobuf.Enum : Object
---@field __class protobuf.EnumClass
---@field name string The full name, e.g. `my_pkg.Color`. **Read-only.**
---@field file string The name of the file that declares it. **Read-only.**
---@field values table<string, integer> The numbers of the values by their names. **Read-only.**
---@field names table<integer, string> The names of the values by their numbers, the first name for aliases. **Read-only.**
local Enum = {}

---@return string
---@protected
function Enum:__tostring() end

--- [SHARED AND MENU]
---
--- The class of `protobuf.Enum` objects, they are created by `protobuf.parse` and `protobuf.load` only.
---
---@class protobuf.EnumClass : protobuf.Enum, Class
---@field __base protobuf.Enum
local EnumClass = {}

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
---@class protobuf.Type : Object
---@field __class protobuf.TypeClass
---@field name string The full name, e.g. `my_pkg.Item`. **Read-only.**
---@field file string The name of the file that declares it. **Read-only.**
---@field descriptor protobuf.MessageDescriptor The parsed declaration. **Read-only.**
---@field class Class | nil The class bound with `Type:bind`, decoded messages are its objects. **Read-only.**
---@field package scope protobuf.Scope
---@field package compiled boolean
---@field package fields protobuf.Field[]
---@field package field_count integer
---@field package by_number table<integer, protobuf.Field>
---@field package syntax "proto2" | "proto3"
---@field package special "nullable" | "unwrap" | "value" | nil
---@field package unwrap_name string | nil
---@field package unwrap_field protobuf.Field | nil
---@field package create ( fun(): any ) | nil
---@field package from_proto ( fun( obj: any, value: any ) ) | nil
local Type = {}

---@return string
---@protected
function Type:__tostring() end

--- [SHARED AND MENU]
---
--- The class of `protobuf.Type` objects, they are created by `protobuf.parse`, `protobuf.load`,
--- `protobuf.nullable`, `protobuf.list` and `protobuf.tree` only.
---
---@class protobuf.TypeClass : protobuf.Type, Class
---@field __base protobuf.Type
local TypeClass = {}

protobuf.Type = TypeClass

---@class protobuf.Field
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
---@class protobuf.File
---@field name string The file name, imports refer to it by this name.
---@field ["package"] string The protobuf package, `""` if the file has none.
---@field types table<string, protobuf.Type | protobuf.Enum> The declared messages and enums by their full names, nested ones included.
---@field descriptor protobuf.FileDescriptor The parsed file.

---@class protobuf.Scope
---@field files table<string, protobuf.File>
---@field types table<string, protobuf.Type | protobuf.Enum>
---@field owner dreamwork.sandbox.Owner | nil

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
---@return protobuf.File file The registered file.
function protobuf.parse(source, file_name) end

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
---@return protobuf.File file The registered file.
function protobuf.load(file_path) end

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
---@return protobuf.Type | protobuf.Enum | nil object The type, `nil` if it was not found.
---@nodiscard
function protobuf.find(name) end

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
---@return protobuf.Type | nil message_type The message type, `nil` if it was not found or the name is an enum.
---@nodiscard
function TypeClass.find(name) end

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
---@return protobuf.Enum | nil enum The enum, `nil` if it was not found or the name is a message type.
---@nodiscard
function EnumClass.find(name) end

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
function Type:encode(value) end

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
--- local position = Vector3Type:decode( data, Vector3 )
--- ```
---
---@param str string The encoded message.
---@param target any The class of the message or the object to read into.
---@return any message The decoded message.
---@nodiscard
function Type:decode(str, target) end

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
---@return protobuf.Type self The same type.
function Type:bind(cls, create) end

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
---@return protobuf.Type message_type The message type.
function TypeClass.bind(name, cls, create) end

--- [SHARED AND MENU]
---
--- Returns the descriptors of the fields in declaration order.
---
---@return protobuf.FieldDescriptor[] fields The field descriptors.
---@nodiscard
function Type:getFields() end

--- [SHARED AND MENU]
---
--- Returns the message type that holds the value or `nil`:
--- `message { oneof kind { google.protobuf.NullValue null = 1; T value = 2; } }`.
---
--- Its Lua value is the value itself, `nil` is written as `null`, so it keeps `nil` in `repeated` fields.
---
---@param element protobuf.Type | protobuf.Enum | Class | string The type of the value, a bound class or a type name.
---@return protobuf.Type nullable_type The message type.
---@nodiscard
function protobuf.nullable(element) end

--- [SHARED AND MENU]
---
--- Returns the message type of a list of values that can be `nil`:
--- `message { repeated Nullable<T> values = 1; }`.
---
--- Its Lua value is the array, the length is `list.n` or `#list`, decoded arrays have `n` set.
---
--- ```lua
--- writer:writeProto( queue, protobuf.list( Vector3 ) )
--- local queue = reader:readProto( Queue, protobuf.list( Vector3 ) )
--- ```
---
---@param element protobuf.Type | protobuf.Enum | Class | string The type of the values, a bound class or a type name.
---@return protobuf.Type list_type The message type.
---@nodiscard
function protobuf.list(element) end

--- [SHARED AND MENU]
---
--- Returns the message type of a tree node:
--- `message Tree { Nullable<T> value = 1; repeated Tree children = 2; }`.
---
--- Its Lua value is `{ value = any, children = { ... } }`, `Node` converts itself to it.
---
--- ```lua
--- writer:writeProto( root, protobuf.tree( Vector3 ) )
--- local root = reader:readProto( Node, protobuf.tree( Vector3 ) )
--- ```
---
---@param element protobuf.Type | protobuf.Enum | Class | string The type of the values, a bound class or a type name.
---@return protobuf.Type tree_type The message type.
---@nodiscard
function protobuf.tree(element) end

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
---@param proto_type protobuf.Type? The message type, the type of the object (`__proto`) by default.
---@return integer byte_count The number of bytes written.
function BinaryWriter.__base:writeProto(value, proto_type) end

--- [SHARED AND MENU]
---
--- Reads a length-prefixed protobuf message written by `BinaryWriter:writeProto`.
---
--- `target` is a class (a new object of it), an object (read into it) or a message type (a table or an object of the bound class).
---
--- ```lua
--- local position = reader:readProto( Vector3 )
--- local item = reader:readProto( protobuf.Type.find( "my_pkg.Item" ) )
--- local queue = reader:readProto( Queue, protobuf.list( Vector3 ) )
--- ```
---
---@param target any The class, the object or the message type.
---@param proto_type protobuf.Type? The message type, the type of the class or object (`__proto`) by default.
---@return any message The decoded message.
function BinaryReader.__base:readProto(target, proto_type) end

---@param name string
---@param cls any
---@param create ( fun(): any )?
function dreamwork.protobuf(name, cls, create) end
