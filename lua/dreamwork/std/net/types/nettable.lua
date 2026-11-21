local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local dreamwork_sandbox = dreamwork.sandbox
local sandbox_owner = dreamwork_sandbox.owner
local sandbox_claim = dreamwork_sandbox.claim
local sandbox_prefix = dreamwork_sandbox.prefix

local engine_hook = dreamwork_engine.hook

---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_get = raw.get
local raw_equal = raw.equal
local raw_next = raw.next
local raw_type = raw.type
local raw_pairs = raw.pairs
local raw_index = raw.index

local debug = std.debug
local debug_getmetatable = debug.getmetatable
local debug_findmetatable = debug.findmetatable

local math = std.math
local math_floor = math.floor

local string = std.string
local string_sub = string.sub
local string_format = string.format

local table = std.table
local table_concat = table.concat

local pcall = std.pcall
local setmetatable = std.setmetatable

local class = std.class
local class_new = class.new

local isObject = std.isObject
local isVector3 = std.isVector3
local isAngle3 = std.isAngle3

local Vector3 = std.Vector3
local Angle3 = std.Angle3

local Emitter = std.Emitter
local Network = std.Network
local BinaryReader = std.BinaryReader
local BinaryWriter = std.BinaryWriter

local LUA_SERVER = std.LUA_SERVER


---@class garrysmod.ents
local glua_ents = dreamwork_engine.requireLibrary( "ents" )
local ents_GetByIndex = glua_ents.GetByIndex

---@diagnostic disable-next-line: undefined-global
local glua_Vector = Vector

---@diagnostic disable-next-line: undefined-global
local glua_Angle = Angle

---@diagnostic disable-next-line: undefined-global
local glua_Color = Color

---@diagnostic disable-next-line: undefined-global
local glua_NULL = NULL

--- The metatables of the engine entity classes.
---
---@type table<metatable, boolean>
local entity_metatables = {
    [ dreamwork_engine.Entity ] = true,
    [ dreamwork_engine.Player ] = true,
    [ dreamwork_engine.Weapon ] = true,
    [ dreamwork_engine.Vehicle ] = true,
    [ dreamwork_engine.NPC ] = true,
    [ dreamwork_engine.NextBot ] = true
}

local engine_Vector = dreamwork_engine.Vector
local engine_Angle = dreamwork_engine.Angle

--- The engine `Color` metatable, looked up on demand, the engine defines it in Lua.
---
---@type metatable | nil
local color_metatable


--[[

        NetTable Protocol ( one `std.Network` message each )

        op ( 8 bit ), table name ( string )
        |
        +-- SUBSCRIBE   client -> server
        +-- RESYNC      client -> server    asks for a new snapshot after a failed transfer
        +-- SNAPSHOT    server -> client    flags ( 8 bit ), entry count ( varint ), entries ( depth 1 )
        +-- DELTA       both ways           entry count ( varint ), entries

        Entry

        depth ( varint ), keys ( depth values ), value

    The value of an entry replaces the value at its path, `nil` removes it.

        Value

        tag ( 8 bit )
        |
        +-- NIL, FALSE, TRUE
        +-- UNSIGNED, NEGATIVE      varint ( absolute value )
        +-- DOUBLE                  64 bit
        +-- STRING                  length ( varint ), bytes
        +-- TABLE                   pair count ( varint ), key and value pairs
        +-- VECTOR, ANGLE           3 floats ( engine `Vector` and `Angle` )
        +-- VECTOR3, ANGLE3         3 doubles ( `std.Vector3` and `std.Angle3` )
        +-- COLOR                   4 bytes ( engine `Color` )
        +-- ENTITY                  index ( 16 bit ), `0xFFFF` is `NULL`
        +-- OBJECT                  class name ( string ), `__serialize` data ( string )

    Strings are prefixed with the length ( varint ).

        Synchronization

    Writes are collected per tick and only the changed paths are sent, with the current values,
    so a key written many times in one tick is sent once. Tables are merged into the existing
    nested tables, so assigning a whole table again only sends the keys that changed.

    The server is the authority: a client sends its writes to the server, the server checks them
    with `permit`, applies and broadcasts them ( back to the writer too, so everyone ends with the
    order of the server ). Denied writes are corrected by sending the server value to the writer.

    A client subscribes when it creates the table and receives a full snapshot, later transfers
    are queued behind it by `std.Network`, so the deltas always arrive after the snapshot.

--]]

local OP_SUBSCRIBE = 0
local OP_RESYNC = 1
local OP_SNAPSHOT = 2
local OP_DELTA = 3

local TAG_NIL = 0
local TAG_FALSE = 1
local TAG_TRUE = 2
local TAG_UNSIGNED = 3
local TAG_NEGATIVE = 4
local TAG_DOUBLE = 5
local TAG_STRING = 6
local TAG_TABLE = 7
local TAG_VECTOR = 8
local TAG_ANGLE = 9
local TAG_VECTOR3 = 10
local TAG_ANGLE3 = 11
local TAG_COLOR = 12
local TAG_ENTITY = 13
local TAG_OBJECT = 14

--- `SNAPSHOT` flag, the server accepts writes from the client.
local FLAG_WRITABLE = 1

---
--- the maximum path depth plus table nesting
---
---@type integer
local max_depth = 32

---
--- integers above it lose precision, they are sent as doubles
---
---@type integer
local max_safe_integer = 2 ^ 53

---
--- the entity index of `NULL`
---
---@type integer
local null_index = 0xFFFF

--- [SHARED]
---
--- A named table that is synchronized between the server and the clients,
--- built on top of `std.Network`.
---
--- Values are read and written like table fields, writes are collected and only the changed paths
--- are sent once per tick:
---
--- ```lua
--- local scores = std.NetTable( "scores" )
---
--- scores.round = 1
--- scores.teams = { red = { kills = 0 }, blue = { kills = 0 } }
---
--- scores.teams.red.kills = 5 -- sends only `teams.red.kills`
--- ```
---
--- Supported keys are strings, numbers and booleans, supported values are `nil`, booleans, numbers, strings,
--- tables of them, `std.Vector3`, `std.Angle3`, engine `Vector`, `Angle`, `Color` and entities,
--- and objects of the classes registered with `NetTable.register`.
---
--- Nested tables are copied into synchronized nodes, so modifying the original table later does nothing.
--- Objects are compared by reference, modifying an object in place is not seen, assign it again to send it.
---
--- Entities are sent by index, on the client they are resolved on every read,
--- so an entity that is not networked to the client yet is `NULL` until it is.
---
--- The server owns the data, it sends everything to the subscribed clients that pass `filter`.
--- Clients can only write if the server has set `permit`, their writes are checked by it on the server.
--- The client table is empty and read-only until the first snapshot arrives, see `NetTable:ready`.
---
--- Methods take priority over the values, use `NetTable:get` and `NetTable:set` for keys like `"attach"`.
---
---@class dreamwork.std.NetTable : dreamwork.std.Object
---@field __class dreamwork.std.NetTableClass
---@field [dreamwork.std.NetTable.Key] any The synchronized values.
local NetTable = class.base( "NetTable", true )

--- [SHARED]
---
--- The class of `NetTable`, call it to create or get a table.
---
---@class dreamwork.std.NetTableClass : dreamwork.std.NetTable, dreamwork.std.Class
---@field __base dreamwork.std.NetTable
---@overload fun( name: string ): dreamwork.std.NetTable
local NetTableClass = class.create( NetTable )
std.NetTable = NetTableClass

--- [SHARED]
---
--- A nested table of a `NetTable`, read and written like a table.
---
--- A node removed from its table is detached, its values stay readable,
--- but writes to it are not synchronized anymore.
---
---@class dreamwork.std.NetTable.Node : dreamwork.std.Object
---@field [dreamwork.std.NetTable.Key] any The synchronized values.
local Node = class.base( "NetTable.Node", true )

--- The supported key types.
---
---@alias dreamwork.std.NetTable.Key string | number | boolean

--- Called when a value is changed, by a local write or by the other side.
---
--- `path` is the list of keys from the table to the value, `value` is a `NetTable.Node` for tables.
--- `sender` is the writing client for client writes on the server, `nil` otherwise,
--- `is_remote` is `true` if the change came from the other side.
---
---@alias dreamwork.std.NetTable.ChangeFn fun( nettable: dreamwork.std.NetTable, path: dreamwork.std.NetTable.Key[], value: any, old_value: any, sender: dreamwork.std.Client | nil, is_remote: boolean )

--- Decides if the client receives the top-level key of the table.
---
---@alias dreamwork.std.NetTable.FilterFn fun( nettable: dreamwork.std.NetTable, client: dreamwork.std.Client, key: dreamwork.std.NetTable.Key ): boolean

--- Decides if the client can write the value at the path, `value` is a plain copy, tables are not nodes yet.
---
---@alias dreamwork.std.NetTable.PermitFn fun( nettable: dreamwork.std.NetTable, client: dreamwork.std.Client, path: dreamwork.std.NetTable.Key[], value: any ): boolean

--- An entity received by the client, resolved by index on every read.
---
---@class dreamwork.std.NetTable.EntityRef
---@field [1] integer The entity index.
local EntityRef = {}

--- The values of the tables and nodes.
---
---@type table<dreamwork.std.NetTable | dreamwork.std.NetTable.Node, table>
local node_values = {}
gc_setTableRules( node_values, true, false )

--- The parents of the nodes, `nil` for tables and detached nodes.
---
---@type table<dreamwork.std.NetTable.Node, dreamwork.std.NetTable | dreamwork.std.NetTable.Node>
local node_parents = {}
gc_setTableRules( node_parents, true, false )

--- The keys of the nodes in their parents.
---
---@type table<dreamwork.std.NetTable.Node, dreamwork.std.NetTable.Key>
local node_keys = {}
gc_setTableRules( node_keys, true, false )

--- The tables the nodes belong to, tables belong to themselves, `nil` for detached nodes.
---
---@type table<dreamwork.std.NetTable | dreamwork.std.NetTable.Node, dreamwork.std.NetTable>
local node_roots = {}
gc_setTableRules( node_roots, true, false )

--- The names of the tables.
---
---@type table<dreamwork.std.NetTable, string>
local names = {}

--- The tables by their names.
---
---@type table<string, dreamwork.std.NetTable>
local tables = {}

--- The changed keys of every node since the last flush.
---
---@type table<dreamwork.std.NetTable, table<dreamwork.std.NetTable | dreamwork.std.NetTable.Node, table<dreamwork.std.NetTable.Key, boolean>>>
local dirty = {}

--- The nodes created since the last flush, they are sent whole with their parent key.
---
---@type table<dreamwork.std.NetTable, table<dreamwork.std.NetTable.Node, boolean>>
local fresh = {}

--- The tables that have something to send.
---
---@type table<dreamwork.std.NetTable, boolean>
local dirty_roots = {}

--- The finish callbacks of the transfers of the tables.
---
---@type table<dreamwork.std.NetTable, dreamwork.std.Network.FinishFn>
local finish_callbacks = {}

--- The `filter` functions of the tables.
---
---@type table<dreamwork.std.NetTable, dreamwork.std.NetTable.FilterFn>
local filters = {}

--- The `permit` functions of the tables.
---
---@type table<dreamwork.std.NetTable, dreamwork.std.NetTable.PermitFn>
local permits = {}

--- The subscribed clients of the tables.
---
---@type table<dreamwork.std.NetTable, table<dreamwork.std.Client, boolean>>
local subscribers = {}

--- The clients waiting for a full snapshot.
---
---@type table<dreamwork.std.NetTable, table<dreamwork.std.Client, boolean>>
local stale = {}

--- The denied writes to correct, per client.
---
---@type table<dreamwork.std.NetTable, table<dreamwork.std.Client, table<dreamwork.std.NetTable | dreamwork.std.NetTable.Node, table<dreamwork.std.NetTable.Key, boolean>>>>
local corrections = {}

--- The clients that subscribed to tables the server has not created yet.
---
---@type table<string, table<dreamwork.std.Client, boolean>>
local pending = {}

--- `true` once the client has received the first snapshot.
---
---@type table<dreamwork.std.NetTable, boolean>
local ready_states = {}

--- `true` if the server accepts writes from the client.
---
---@type table<dreamwork.std.NetTable, boolean>
local writable_states = {}

--- The names of the registered classes by their bases.
---
---@type table<dreamwork.std.Object, string>
local registry_names = {}

--- The registered classes by their names.
---
---@type table<string, dreamwork.std.Class>
local registry_classes = {}

--- NetTable `"change"` and `"ready"` handlers.
local events = Emitter( "NetTable" )

local network = Network( "dreamwork.nettable", true )

if LUA_SERVER then
    network.limit = 4 * 1024 * 1024
end

--[[

    Values

--]]

---@param value any
---@return any
local function resolve_value( value )
    if raw_type( value ) == "table" and debug_getmetatable( value ) == EntityRef then
        return ents_GetByIndex( value[ 1 ] )
    end

    return value
end

---@param key any
---@return boolean
local function is_key( key )
    local key_type = raw_type( key )
    return key_type == "string" or key_type == "boolean" or (key_type == "number" and key == key)
end

---@param value any
---@return boolean
local function is_plain_table( value )
    return raw_type( value ) == "table" and debug_getmetatable( value ) == nil
end

--- Returns the tag of the value, `nil` if it is not supported.
---
---@param value any
---@return integer | nil
local function value_tag( value )
    local value_type = raw_type( value )

    if value_type == "nil" then
        return TAG_NIL
    elseif value_type == "boolean" then
        return value and TAG_TRUE or TAG_FALSE
    elseif value_type == "number" then
        -- `inf % 1` and `nan % 1` are `nan`, `-0` must stay a double
        if (value % 1) == 0 and value <= max_safe_integer and value >= -max_safe_integer and (value ~= 0 or (1 / value) > 0) then
            return value < 0 and TAG_NEGATIVE or TAG_UNSIGNED
        end

        return TAG_DOUBLE
    elseif value_type == "string" then
        return TAG_STRING
    elseif value_type == "Vector" then
        return TAG_VECTOR
    elseif value_type == "Angle" then
        return TAG_ANGLE
    elseif value_type == "cdata" then
        if isVector3( value ) then
            return TAG_VECTOR3
        elseif isAngle3( value ) then
            return TAG_ANGLE3
        end

        return nil
    elseif value_type ~= "table" and value_type ~= "userdata" then
        -- `raw.type` names patched engine types ( cdata vectors ), `debug.getmetatable` refuses them
        return nil
    end

    local metatable = debug_getmetatable( value )

    if metatable == nil then
        return value_type == "table" and TAG_TABLE or nil
    elseif metatable == Node or metatable == NetTable then
        return TAG_TABLE
    elseif metatable == EntityRef or entity_metatables[ metatable ] then
        return TAG_ENTITY
    elseif metatable == engine_Vector then
        return TAG_VECTOR
    elseif metatable == engine_Angle then
        return TAG_ANGLE
    elseif isVector3( value ) then
        return TAG_VECTOR3
    elseif isAngle3( value ) then
        return TAG_ANGLE3
    elseif registry_names[ metatable ] ~= nil then
        return TAG_OBJECT
    end

    if color_metatable == nil then
        color_metatable = debug_findmetatable( "Color" )
    end

    if metatable == color_metatable then
        return TAG_COLOR
    end

    return nil
end

--- Returns the error message if the value can't be stored at the depth.
---
---@param value any
---@param depth integer
---@param visited table<table, boolean> | nil
---@return string | nil
local function validate( value, depth, visited )
    local tag = value_tag( value )
    if tag == nil then
        return string_format( "NetTable can't store values of type '%s'.", raw_type( value ) )
    end

    if tag ~= TAG_TABLE then
        return nil
    end

    if depth >= max_depth then
        return string_format( "NetTable nesting is too deep, the limit is %d.", max_depth )
    end

    -- nodes are valid already, their depth is checked against their own path
    if node_values[ value ] ~= nil then
        return nil
    end

    if visited == nil then
        visited = {}
    elseif visited[ value ] then
        return "NetTable can't store tables with cyclic references."
    end

    visited[ value ] = true

    for key, item in raw_pairs( value ) do
        if not is_key( key ) then
            return string_format( "NetTable keys must be strings, numbers or booleans, got '%s'.", raw_type( key ) )
        end

        local message = validate( item, depth + 1, visited )
        if message ~= nil then
            return message
        end
    end

    visited[ value ] = nil
    return nil
end

--[[

    Encoding

--]]

---@param writer dreamwork.std.BinaryWriter
---@param value integer
local function write_varint( writer, value )
    ::varint_writer::

    if value >= 0x80 then
        writer:writeUInt( (value % 0x80) + 0x80, 8 )
        value = math_floor( value / 0x80 )
        goto varint_writer
    end

    writer:writeUInt( value, 8 )
end

---@param reader dreamwork.std.BinaryReader
---@return integer
local function read_varint( reader )
    local value, scale, length = 0, 1, 0

    ::varint_reader::

    local byte = reader:readUInt( 8 )
    length = length + 1

    if byte >= 0x80 then
        if length == 8 then
            error( "varint is too long", 0 )
        end

        value = value + (byte - 0x80) * scale
        scale = scale * 0x80
        goto varint_reader
    end

    return value + byte * scale
end

--- Reads a count that is followed by at least one byte per element.
---
---@param reader dreamwork.std.BinaryReader
---@return integer
local function read_count( reader )
    local count = read_varint( reader )
    if count > reader:remaining( true ) then
        error( "count is out of range", 0 )
    end

    return count
end

---@param writer dreamwork.std.BinaryWriter
---@param str string
local function write_string( writer, str )
    write_varint( writer, #str )
    writer:write( str )
end

---@param reader dreamwork.std.BinaryReader
---@return string
local function read_string( reader )
    local length = read_varint( reader )
    if length > reader:remaining( true ) then
        error( "string length is out of range", 0 )
    end

    return reader:read( length )
end

--- Returns the index the entity is sent as, `null_index` for `NULL` and clientside entities.
---
---@param entity garrysmod.Entity | dreamwork.std.NetTable.EntityRef
---@return integer
local function entity_index( entity )
    if raw_type( entity ) == "table" then
        return entity[ 1 ]
    end

    if entity:IsValid() then
        local index = entity:EntIndex()
        return index < 0 and null_index or index
    elseif entity ~= glua_NULL and entity:IsWorld() then
        return 0
    end

    return null_index
end

--- Checks if the objects are different instances with the same value, they are not sent again then.
---
--- The same instance is never equal, it can be modified in place and assigned again to send it.
---
---@param old any
---@param value any
---@return boolean
local function value_equal( old, value )
    if old == nil or raw_equal( old, value ) then
        return false
    end

    local tag = value_tag( value )
    if tag ~= value_tag( old ) then
        return false
    elseif tag == TAG_ENTITY then
        return entity_index( old ) == entity_index( value )
    elseif tag == TAG_VECTOR or tag == TAG_ANGLE or tag == TAG_VECTOR3 or tag == TAG_ANGLE3 or tag == TAG_COLOR then
        return old == value
    end

    return false
end

---@type fun( writer: dreamwork.std.BinaryWriter, value: any )
local write_value

function write_value( writer, value )
    local tag = value_tag( value )
    ---@cast tag integer

    writer:writeUInt( tag, 8 )

    if tag == TAG_UNSIGNED then
        write_varint( writer, value )
    elseif tag == TAG_NEGATIVE then
        write_varint( writer, -value )
    elseif tag == TAG_DOUBLE then
        writer:writeDouble( value )
    elseif tag == TAG_STRING then
        write_string( writer, value )
    elseif tag == TAG_TABLE then
        local values = node_values[ value ] or value
        local count = 0

        for _ in raw_pairs( values ) do
            count = count + 1
        end

        write_varint( writer, count )

        for key, item in raw_pairs( values ) do
            write_value( writer, key )
            write_value( writer, item )
        end
    elseif tag == TAG_VECTOR or tag == TAG_ANGLE then
        local x, y, z = value:Unpack()
        writer:writeFloat( x )
        writer:writeFloat( y )
        writer:writeFloat( z )
    elseif tag == TAG_VECTOR3 then
        writer:writeDouble( value.x )
        writer:writeDouble( value.y )
        writer:writeDouble( value.z )
    elseif tag == TAG_ANGLE3 then
        writer:writeDouble( value.pitch )
        writer:writeDouble( value.yaw )
        writer:writeDouble( value.roll )
    elseif tag == TAG_COLOR then
        writer:writeUInt( value.r, 8 )
        writer:writeUInt( value.g, 8 )
        writer:writeUInt( value.b, 8 )
        writer:writeUInt( value.a, 8 )
    elseif tag == TAG_ENTITY then
        writer:writeUInt( entity_index( value ), 16 )
    elseif tag == TAG_OBJECT then
        local object_writer = BinaryWriter()
        object_writer:writeObject( value )

        write_string( writer, registry_names[ debug_getmetatable( value ) ] )
        write_string( writer, object_writer:compile() )
    end
end

---@type fun( reader: dreamwork.std.BinaryReader, tag: integer, depth: integer ): any
local read_tagged

---@param reader dreamwork.std.BinaryReader
---@param depth integer
---@return any
local function read_value( reader, depth )
    return read_tagged( reader, reader:readUInt( 8 ), depth )
end

---@param reader dreamwork.std.BinaryReader
---@return dreamwork.std.NetTable.Key
local function read_key( reader )
    local tag = reader:readUInt( 8 )
    if tag == TAG_NIL or tag > TAG_STRING then
        error( string_format( "invalid key tag %d", tag ), 0 )
    end

    local key = read_tagged( reader, tag, 0 )
    if key ~= key then
        error( "key is nan", 0 )
    end

    return key
end

function read_tagged( reader, tag, depth )
    if tag == TAG_NIL then
        return nil
    elseif tag == TAG_FALSE then
        return false
    elseif tag == TAG_TRUE then
        return true
    elseif tag == TAG_UNSIGNED then
        return read_varint( reader )
    elseif tag == TAG_NEGATIVE then
        return -read_varint( reader )
    elseif tag == TAG_DOUBLE then
        return reader:readDouble()
    elseif tag == TAG_STRING then
        return read_string( reader )
    elseif tag == TAG_TABLE then
        if depth >= max_depth then
            error( "table nesting is too deep", 0 )
        end

        local tbl = {}

        for _ = 1, read_count( reader ), 1 do
            local key = read_key( reader )
            tbl[ key ] = read_value( reader, depth + 1 )
        end

        return tbl
    elseif tag == TAG_VECTOR then
        local x = reader:readFloat()
        local y = reader:readFloat()
        return glua_Vector( x, y, reader:readFloat() )
    elseif tag == TAG_ANGLE then
        local pitch = reader:readFloat()
        local yaw = reader:readFloat()
        return glua_Angle( pitch, yaw, reader:readFloat() )
    elseif tag == TAG_VECTOR3 then
        local x = reader:readDouble()
        local y = reader:readDouble()
        return Vector3( x, y, reader:readDouble() )
    elseif tag == TAG_ANGLE3 then
        local pitch = reader:readDouble()
        local yaw = reader:readDouble()
        return Angle3( pitch, yaw, reader:readDouble() )
    elseif tag == TAG_COLOR then
        local r = reader:readUInt( 8 )
        local g = reader:readUInt( 8 )
        local b = reader:readUInt( 8 )
        return glua_Color( r, g, b, reader:readUInt( 8 ) )
    elseif tag == TAG_ENTITY then
        local index = reader:readUInt( 16 )
        if index == null_index then
            return glua_NULL
        elseif LUA_SERVER then
            return ents_GetByIndex( index )
        end

        return setmetatable( { index }, EntityRef )
    elseif tag == TAG_OBJECT then
        local name = read_string( reader )

        local cls = registry_classes[ name ]
        if cls == nil then
            error( string_format( "unknown class '%s'", name ), 0 )
        end

        return BinaryReader( read_string( reader ) ):readClass( cls )
    end

    error( string_format( "unknown value tag %d", tag ), 0 )
end

--[[

    Nodes

--]]

---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@return integer
local function node_depth( node )
    local depth = 0

    ::depth_counter::

    local parent = node_parents[ node ]
    if parent ~= nil then
        depth = depth + 1
        node = parent
        goto depth_counter
    end

    return depth
end

--- Returns the keys from the table to the key of the node.
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key dreamwork.std.NetTable.Key
---@return dreamwork.std.NetTable.Key[] path
---@return integer depth
local function node_path( node, key )
    local depth = node_depth( node ) + 1
    local path = { [ depth ] = key }

    for i = depth - 1, 1, -1 do
        path[ i ] = node_keys[ node ]
        node = node_parents[ node ]
    end

    return path, depth
end

--- Detaches the node and its children from their table.
---
---@param node dreamwork.std.NetTable.Node
local function node_detach( node )
    node_parents[ node ] = nil
    node_keys[ node ] = nil
    node_roots[ node ] = nil

    for _, value in raw_pairs( node_values[ node ] ) do
        if node_values[ value ] ~= nil then
            node_detach( value )
        end
    end
end

--- Returns a plain deep copy of the node.
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param resolve boolean `true` to resolve the entity references.
---@return table
local function node_copy( node, resolve )
    local copy = {}

    for key, value in raw_pairs( node_values[ node ] ) do
        if node_values[ value ] ~= nil then
            value = node_copy( value, resolve )
        elseif resolve then
            value = resolve_value( value )
        end

        copy[ key ] = value
    end

    return copy
end

--- Creates a node with the values of the plain table or node.
---
---@param root dreamwork.std.NetTable | nil
---@param parent dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key dreamwork.std.NetTable.Key
---@param source table
---@param mark boolean
---@return dreamwork.std.NetTable.Node
local function node_build( root, parent, key, source, mark )
    ---@type dreamwork.std.NetTable.Node
    local node = class_new( Node )

    local values = {}
    node_values[ node ] = values
    node_parents[ node ] = parent
    node_keys[ node ] = key
    node_roots[ node ] = root

    if mark and root ~= nil then
        fresh[ root ][ node ] = true
    end

    for item_key, item in raw_pairs( source ) do
        local item_source = node_values[ item ]
        if item_source ~= nil then
            item = node_build( root, node, item_key, item_source, mark )
        elseif is_plain_table( item ) then
            item = node_build( root, node, item_key, item, mark )
        end

        values[ item_key ] = item
    end

    return node
end

---@param root dreamwork.std.NetTable
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key dreamwork.std.NetTable.Key
local function mark_dirty( root, node, key )
    local nodes = dirty[ root ]

    local keys = nodes[ node ]
    if keys == nil then
        keys = {}
        nodes[ node ] = keys
    end

    keys[ key ] = true
    dirty_roots[ root ] = true
end

---@type fun( node: dreamwork.std.NetTable | dreamwork.std.NetTable.Node, source: table, mark: boolean, sender: dreamwork.std.Client | nil, is_remote: boolean )
local node_merge

--- Stores the validated value, tables are merged into the existing node.
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key dreamwork.std.NetTable.Key
---@param value any
---@param mark boolean `true` to send the change.
---@param sender dreamwork.std.Client | nil
---@param is_remote boolean
local function node_store( node, key, value, mark, sender, is_remote )
    local values = node_values[ node ]
    local old = values[ key ]
    local root = node_roots[ node ]

    local source = node_values[ value ]
    if source ~= nil or is_plain_table( value ) then
        if node_values[ old ] ~= nil then
            if source ~= nil then
                if value == old then return end

                -- the source can be the parent or a child of the target
                value = node_copy( value, false )
            end

            node_merge( old, value, mark, sender, is_remote )
            return
        end

        value = node_build( root, node, key, source or value, mark )
    else
        local value_type = raw_type( value )
        if (value_type == "string" or value_type == "number" or value_type == "boolean" or value_type == "nil") then
            if old == value then return end
        elseif value_equal( old, value ) then
            return
        end
    end

    if node_values[ old ] ~= nil then
        node_detach( old )
    end

    values[ key ] = value

    if root == nil then return end

    if mark then
        mark_dirty( root, node, key )
    end

    if events:count( root, "change" ) ~= 0 then
        events:emit( root, "change", root, (node_path( node, key )), resolve_value( value ), resolve_value( old ), sender, is_remote )
    end
end

function node_merge( node, source, mark, sender, is_remote )
    local values = node_values[ node ]

    ---@type dreamwork.std.NetTable.Key[] | nil
    local removed
    local removed_count = 0

    for key in raw_pairs( values ) do
        if source[ key ] == nil then
            removed_count = removed_count + 1

            if removed == nil then
                removed = { key }
            else
                removed[ removed_count ] = key
            end
        end
    end

    for i = 1, removed_count, 1 do
        ---@diagnostic disable-next-line: need-check-nil
        node_store( node, removed[ i ], nil, mark, sender, is_remote )
    end

    for key, item in raw_pairs( source ) do
        node_store( node, key, item, mark, sender, is_remote )
    end
end

--- Validates and stores a local write.
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key any
---@param value any
local function local_set( node, key, value )
    local root = node_roots[ node ]

    if root ~= nil and not LUA_SERVER then
        if not ready_states[ root ] then
            error( string_format( "NetTable '%s' is not synchronized yet, wait for `NetTable:ready`.", names[ root ] ), 3 )
        elseif not writable_states[ root ] then
            error( string_format( "NetTable '%s' is read-only on the client, the server has no `permit` for it.", names[ root ] ), 3 )
        end
    end

    if not is_key( key ) then
        error( string_format( "NetTable keys must be strings, numbers or booleans, got '%s'.", raw_type( key ) ), 3 )
    end

    local message = validate( value, node_depth( node ) + 1, nil )
    if message ~= nil then
        error( message, 3 )
    end

    node_store( node, key, value, true, nil, false )
end

--- Returns the parent node of the last key of the path,
--- or the deepest existing node and the index of the first missing key.
---
---@param root dreamwork.std.NetTable
---@param path dreamwork.std.NetTable.Key[]
---@param depth integer
---@return dreamwork.std.NetTable | dreamwork.std.NetTable.Node node
---@return integer index
local function path_resolve( root, path, depth )
    ---@type dreamwork.std.NetTable | dreamwork.std.NetTable.Node
    local node = root

    for i = 1, depth - 1, 1 do
        local child = node_values[ node ][ path[ i ] ]
        if node_values[ child ] == nil then
            return node, i
        end

        node = child
    end

    return node, depth
end

---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@param key dreamwork.std.NetTable.Key | nil
---@return dreamwork.std.NetTable.Key | nil
---@return any
local function node_next( node, key )
    local next_key, value = raw_next( node_values[ node ], key )
    return next_key, resolve_value( value )
end

---@param key any
---@protected
function Node:__index( key )
    return resolve_value( node_values[ self ][ key ] )
end

---@param key any
---@param value any
---@protected
function Node:__newindex( key, value )
    local_set( self, key, value )
end

---@return integer
---@protected
function Node:__len()
    return #node_values[ self ]
end

---@protected
function Node:__pairs()
    return node_next
end

---@return string
---@protected
function Node:__tostring()
    local root = node_roots[ self ]
    if root == nil then
        return string_format( "NetTable.Node: %p [detached]", self )
    end

    return string_format( "NetTable.Node: %p [%s]", self, names[ root ] )
end

--[[

    Transport

--]]

--- Encodes the entries of the changed keys, the entry `i` is `data[ stops[ i - 1 ] + 1, stops[ i ] ]`.
---
---@param root dreamwork.std.NetTable
---@param nodes table<dreamwork.std.NetTable | dreamwork.std.NetTable.Node, table<dreamwork.std.NetTable.Key, boolean>>
---@return string data
---@return integer[] stops
---@return dreamwork.std.NetTable.Key[] top_keys
---@return integer count
local function encode_dirty( root, nodes )
    local writer = BinaryWriter()
    local fresh_nodes = fresh[ root ]

    local stops, top_keys, count = {}, {}, 0

    for node, keys in raw_pairs( nodes ) do
        -- detached nodes are gone, fresh ones are sent whole by their parent
        if node_roots[ node ] == root and not fresh_nodes[ node ] then
            local values = node_values[ node ]

            for key in raw_pairs( keys ) do
                local path, depth = node_path( node, key )

                write_varint( writer, depth )

                for i = 1, depth, 1 do
                    write_value( writer, path[ i ] )
                end

                write_value( writer, values[ key ] )

                count = count + 1
                stops[ count ] = writer:tell( true )
                top_keys[ count ] = path[ 1 ]
            end
        end
    end

    return writer:compile(), stops, top_keys, count
end

--- Encodes every top-level key of the table, same layout as `encode_dirty`.
---
---@param root dreamwork.std.NetTable
---@return string data
---@return integer[] stops
---@return dreamwork.std.NetTable.Key[] top_keys
---@return integer count
local function encode_snapshot( root )
    local writer = BinaryWriter()
    local stops, top_keys, count = {}, {}, 0

    for key, value in raw_pairs( node_values[ root ] ) do
        write_varint( writer, 1 )
        write_value( writer, key )
        write_value( writer, value )

        count = count + 1
        stops[ count ] = writer:tell( true )
        top_keys[ count ] = key
    end

    return writer:compile(), stops, top_keys, count
end

--- Builds the message with the selected entries, all of them if `indices` is `nil`.
---
---@param op integer
---@param name string
---@param flags integer
---@param data string
---@param stops integer[]
---@param count integer
---@param indices integer[] | nil
---@param selected integer
---@return string
local function payload_build( op, name, flags, data, stops, count, indices, selected )
    local header = BinaryWriter()
    header:writeUInt( op, 8 )
    write_string( header, name )

    if op == OP_SNAPSHOT then
        header:writeUInt( flags, 8 )
    end

    write_varint( header, selected )

    if indices == nil or selected == count then
        return header:compile() .. data
    end

    local parts = { header:compile() }

    for i = 1, selected, 1 do
        local index = indices[ i ]
        parts[ i + 1 ] = string_sub( data, (stops[ index - 1 ] or 0) + 1, stops[ index ] )
    end

    return table_concat( parts, "", 1, selected + 1 )
end

---@param op integer
---@param name string
local function send_control( op, name )
    local writer = BinaryWriter()
    writer:writeUInt( op, 8 )
    write_string( writer, name )
    network:send( writer:compile() )
end

---@type fun( root: dreamwork.std.NetTable )
local flush

--- Initializes the realm specific state of a new table.
---
---@type fun( root: dreamwork.std.NetTable, name: string )
local init_realm

if LUA_SERVER then

    --- Sends the entries to the clients, grouped by what `filter` lets them see.
    ---
    ---@param root dreamwork.std.NetTable
    ---@param op integer
    ---@param data string
    ---@param stops integer[]
    ---@param top_keys dreamwork.std.NetTable.Key[]
    ---@param count integer
    ---@param clients dreamwork.std.Client[]
    ---@param client_count integer
    local function server_send( root, op, data, stops, top_keys, count, clients, client_count )
        local name = names[ root ]
        local flags = permits[ root ] == nil and 0 or FLAG_WRITABLE
        local callback = finish_callbacks[ root ]

        local filter = filters[ root ]
        if filter == nil then
            if count ~= 0 or op == OP_SNAPSHOT then
                network:send( payload_build( op, name, flags, data, stops, count, nil, count ), clients, callback )
            end

            return
        end

        ---@type table<string, { indices: integer[], selected: integer, clients: dreamwork.std.Client[] }>
        local groups = {}

        for i = 1, client_count, 1 do
            local client = clients[ i ]

            ---@type table<dreamwork.std.NetTable.Key, boolean>
            local verdicts = {}

            local indices, selected = {}, 0

            for index = 1, count, 1 do
                local key = top_keys[ index ]

                local verdict = verdicts[ key ]
                if verdict == nil then
                    local success, result = pcall( filter, root, client, key )
                    if not success then
                        dreamwork_Logger:error( "Filter of NetTable '%s' failed: %s", name, result )
                    end

                    verdict = success and result == true
                    verdicts[ key ] = verdict
                end

                if verdict then
                    selected = selected + 1
                    indices[ selected ] = index
                end
            end

            -- the snapshot is sent even when empty, it makes the client ready
            if selected ~= 0 or op == OP_SNAPSHOT then
                local signature = table_concat( indices, ",", 1, selected )

                local group = groups[ signature ]
                if group == nil then
                    group = { indices = indices, selected = selected, clients = { client } }
                    groups[ signature ] = group
                else
                    local group_clients = group.clients
                    group_clients[ #group_clients + 1 ] = client
                end
            end
        end

        for _, group in raw_pairs( groups ) do
            network:send( payload_build( op, name, flags, data, stops, count, group.indices, group.selected ), group.clients, callback )
        end
    end

    function flush( root )
        local nodes = dirty[ root ]
        dirty[ root ] = {}

        local stale_clients = stale[ root ]
        stale[ root ] = {}

        local client_corrections = corrections[ root ]
        corrections[ root ] = {}

        local clients = subscribers[ root ]

        local delta_clients, delta_count = {}, 0
        local snapshot_clients, snapshot_count = {}, 0

        for client in raw_pairs( clients ) do
            if not client.is_connected then
                clients[ client ] = nil
            elseif stale_clients[ client ] then
                snapshot_count = snapshot_count + 1
                snapshot_clients[ snapshot_count ] = client
            else
                delta_count = delta_count + 1
                delta_clients[ delta_count ] = client
            end
        end

        if delta_count ~= 0 and raw_next( nodes ) ~= nil then
            local data, stops, top_keys, count = encode_dirty( root, nodes )
            server_send( root, OP_DELTA, data, stops, top_keys, count, delta_clients, delta_count )
        end

        for client, correction_nodes in raw_pairs( client_corrections ) do
            if clients[ client ] and not stale_clients[ client ] and client.is_connected then
                local data, stops, top_keys, count = encode_dirty( root, correction_nodes )
                server_send( root, OP_DELTA, data, stops, top_keys, count, { client }, 1 )
            end
        end

        fresh[ root ] = {}

        if snapshot_count ~= 0 then
            local data, stops, top_keys, count = encode_snapshot( root )
            server_send( root, OP_SNAPSHOT, data, stops, top_keys, count, snapshot_clients, snapshot_count )
        end
    end

    ---@param root dreamwork.std.NetTable
    ---@param client dreamwork.std.Client
    local function subscribe( root, client )
        subscribers[ root ][ client ] = true
        stale[ root ][ client ] = true
        dirty_roots[ root ] = true
    end

    --- Sends the server value back to the client.
    ---
    ---@param root dreamwork.std.NetTable
    ---@param client dreamwork.std.Client
    ---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node
    ---@param key dreamwork.std.NetTable.Key
    local function correct( root, client, node, key )
        local client_corrections = corrections[ root ]

        local nodes = client_corrections[ client ]
        if nodes == nil then
            nodes = {}
            client_corrections[ client ] = nodes
        end

        local keys = nodes[ node ]
        if keys == nil then
            keys = {}
            nodes[ node ] = keys
        end

        keys[ key ] = true
        dirty_roots[ root ] = true
    end

    ---@param reader dreamwork.std.BinaryReader
    ---@param sender dreamwork.std.Client
    local function receive( reader, sender )
        local op = reader:readUInt( 8 )
        local name = read_string( reader )
        local root = tables[ name ]

        if op == OP_SUBSCRIBE then
            if root ~= nil then
                subscribe( root, sender )
                return
            end

            local clients = pending[ name ]
            if clients == nil then
                clients = {}
                gc_setTableRules( clients, true, false )
                pending[ name ] = clients
            end

            clients[ sender ] = true
            return
        end

        if root == nil or not subscribers[ root ][ sender ] then return end

        if op == OP_RESYNC then
            stale[ root ][ sender ] = true
            dirty_roots[ root ] = true
            return
        elseif op ~= OP_DELTA then
            return
        end

        local permit = permits[ root ]
        if permit == nil then
            dreamwork_Logger:debug( "%s [%d] tried to write to the read-only NetTable '%s'.", sender.name or "unknown", sender.user_id, name )
            return
        end

        for _ = 1, read_count( reader ), 1 do
            local depth = read_varint( reader )
            if depth < 1 or depth > max_depth then
                error( "invalid path depth", 0 )
            end

            local path = {}

            for i = 1, depth, 1 do
                path[ i ] = read_key( reader )
            end

            local value = read_value( reader, depth )
            local node, index = path_resolve( root, path, depth )

            local allowed = false

            if index == depth then
                local success, result = pcall( permit, root, sender, path, value )
                if success then
                    allowed = result == true
                else
                    dreamwork_Logger:error( "Permit of NetTable '%s' failed: %s", name, result )
                end
            end

            if allowed then
                node_store( node, path[ depth ], value, true, sender, true )
            else
                correct( root, sender, node, path[ index ] )
            end
        end
    end

    network:clear()

    network:attach( function( _, reader, sender )
        ---@cast sender dreamwork.std.Client
        local success, message = pcall( receive, reader, sender )
        if not success then
            dreamwork_Logger:warn( "Malformed NetTable message from %s [%d]: %s", sender.name or "unknown", sender.user_id, message )
        end
    end )

    ---@param root dreamwork.std.NetTable
    ---@return dreamwork.std.Network.FinishFn
    local function finish_callback( root )
        return function( _, success, peer )
            if not success and peer ~= nil and peer.is_connected and subscribers[ root ][ peer ] then
                stale[ root ][ peer ] = true
                dirty_roots[ root ] = true
            end
        end
    end

    function init_realm( root, name )
        subscribers[ root ] = {}
        stale[ root ] = {}
        corrections[ root ] = {}
        finish_callbacks[ root ] = finish_callback( root )

        local clients = pending[ name ]
        if clients == nil then return end

        pending[ name ] = nil

        for client in raw_pairs( clients ) do
            if client.is_connected then
                subscribe( root, client )
            end
        end
    end

else

    function flush( root )
        local nodes = dirty[ root ]
        dirty[ root ] = {}

        local data, stops, _, count = encode_dirty( root, nodes )
        fresh[ root ] = {}

        if count ~= 0 then
            network:send( payload_build( OP_DELTA, names[ root ], 0, data, stops, count, nil, count ), nil, finish_callbacks[ root ] )
        end
    end

    ---@param reader dreamwork.std.BinaryReader
    ---@param depth integer
    ---@return dreamwork.std.NetTable.Key[] path
    ---@return any value
    local function read_entry( reader, depth )
        local path = {}

        for i = 1, depth, 1 do
            path[ i ] = read_key( reader )
        end

        return path, read_value( reader, depth )
    end

    ---@param reader dreamwork.std.BinaryReader
    local function receive( reader )
        local op = reader:readUInt( 8 )

        local root = tables[ read_string( reader ) ]
        if root == nil then return end

        if op == OP_SNAPSHOT then
            local flags = reader:readUInt( 8 )
            local source = {}

            for _ = 1, read_count( reader ), 1 do
                if read_varint( reader ) ~= 1 then
                    error( "invalid snapshot entry", 0 )
                end

                local path, value = read_entry( reader, 1 )
                source[ path[ 1 ] ] = value
            end

            writable_states[ root ] = flags % 2 == FLAG_WRITABLE
            node_merge( root, source, false, nil, true )

            if not ready_states[ root ] then
                ready_states[ root ] = true
                events:emit( root, "ready", root )
            end
        elseif op == OP_DELTA then
            local nodes = dirty[ root ]
            local fresh_nodes = fresh[ root ]

            for _ = 1, read_count( reader ), 1 do
                local depth = read_varint( reader )
                if depth < 1 or depth > max_depth then
                    error( "invalid path depth", 0 )
                end

                local path, value = read_entry( reader, depth )
                local node, index = path_resolve( root, path, depth )

                -- unsent local writes win, the server gets them next and sends them back
                if index == depth and not fresh_nodes[ node ] then
                    local keys = nodes[ node ]
                    if keys == nil or not keys[ path[ depth ] ] then
                        node_store( node, path[ depth ], value, false, nil, true )
                    end
                end
            end
        end
    end

    network:clear()

    network:attach( function( _, reader )
        local success, message = pcall( receive, reader )
        if not success then
            dreamwork_Logger:warn( "Malformed NetTable message from the server: %s", message )
        end
    end )

    ---@param root dreamwork.std.NetTable
    ---@return dreamwork.std.Network.FinishFn
    local function finish_callback( root )
        return function( _, success )
            if not success then
                -- the writes are lost, the server state replaces them
                send_control( OP_RESYNC, names[ root ] )
            end
        end
    end

    function init_realm( root, name )
        ready_states[ root ] = false
        writable_states[ root ] = false
        finish_callbacks[ root ] = finish_callback( root )
        send_control( OP_SUBSCRIBE, name )
    end

end

do

    ---@type dreamwork.std.NetTable[]
    local flush_list = {}

    engine_hook.catch( "Tick", "net.nettable.class", function()
        local count = 0

        for root in raw_pairs( dirty_roots ) do
            dirty_roots[ root ] = nil
            count = count + 1
            flush_list[ count ] = root
        end

        for i = 1, count, 1 do
            local root = flush_list[ i ]
            flush_list[ i ] = nil

            local success, message = pcall( flush, root )
            if not success then
                dreamwork_Logger:error( "Synchronization of NetTable '%s' failed: %s", names[ root ], message )
            end
        end
    end )

end

--[[

    NetTable

--]]

do

    ---@param name string The name of the table.
    ---@return dreamwork.std.NetTable | nil object The existing table with this name.
    ---@protected
    function NetTableClass:__new( name )
        local owner = sandbox_owner( 2 )
        if owner ~= nil then
            name = sandbox_prefix( owner, name )
        end

        return tables[ name ]
    end

    ---@return string
    ---@protected
    function NetTable:__represent()
        return string_format( "NetTable: %p [%s]", self, names[ self ] )
    end

    ---@param name string The name of the table, must be the same on the server and the client.
    ---@protected
    function NetTable:__init( name )
        local owner = sandbox_owner( 2 )
        if owner ~= nil then
            name = sandbox_prefix( owner, name )
            sandbox_claim( owner, self, NetTable.clear )
        end

        names[ self ] = name
        tables[ name ] = self

        node_values[ self ] = {}
        node_roots[ self ] = self

        dirty[ self ] = {}
        fresh[ self ] = {}

        init_realm( self, name )
    end

    ---@param key any
    ---@protected
    function NetTable:__index( key )
        local method = raw_index( NetTable, key )
        if method ~= nil then
            return method
        end

        return resolve_value( node_values[ self ][ key ] )
    end

    ---@param key any
    ---@param value any
    ---@protected
    function NetTable:__newindex( key, value )
        local_set( self, key, value )
    end

    ---@return integer
    ---@protected
    function NetTable:__len()
        return #node_values[ self ]
    end

    ---@protected
    function NetTable:__pairs()
        return node_next
    end

end

--- [SHARED]
---
--- Returns the value of the key, for keys that are shadowed by methods.
---
---@param key dreamwork.std.NetTable.Key The key.
---@return any value The value, a `NetTable.Node` for tables.
---@nodiscard
function NetTable:get( key )
    return resolve_value( node_values[ self ][ key ] )
end

--- [SHARED]
---
--- Sets the value of the key, for keys that are shadowed by methods.
---
---@param key dreamwork.std.NetTable.Key The key.
---@param value any The value, `nil` removes the key.
function NetTable:set( key, value )
    local_set( self, key, value )
end

--- [SHARED]
---
--- Returns the name of the table.
---
---@return string name The name.
---@nodiscard
function NetTable:getName()
    return names[ self ]
end

--- [SHARED]
---
--- Checks if the table has received the first snapshot, always `true` on the server.
---
---@return boolean is_ready `true` if the table is synchronized.
---@nodiscard
function NetTable:isReady()
    return LUA_SERVER or ready_states[ self ]
end

--- [SHARED]
---
--- Checks if the table can be written, always `true` on the server.
---
---@return boolean is_writable `true` if the server accepts writes from this client.
---@nodiscard
function NetTable:isWritable()
    return LUA_SERVER or (ready_states[ self ] and writable_states[ self ])
end

--- [SHARED]
---
--- Calls the handler once the table has received the first snapshot,
--- right away if it already has and always on the server.
---
---@param handler fun( nettable: dreamwork.std.NetTable ) | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function NetTable:ready( handler )
    if LUA_SERVER or ready_states[ self ] then
        handler( self )
    else
        events:once( self, "ready", handler )
    end
end

--- [SHARED]
---
--- Attaches a handler that is called when a value is changed, locally or by the other side.
---
--- Tables merged into existing ones call it for every changed key.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler dreamwork.std.NetTable.ChangeFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function NetTable:attach( handler )
    events:attach( self, "change", handler )
end

--- [SHARED]
---
--- Attaches a change handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler dreamwork.std.NetTable.ChangeFn | dreamwork.std.Hook | dreamwork.std.Event The callback or callable object.
function NetTable:once( handler )
    events:once( self, "change", handler )
end

--- [SHARED]
---
--- Detaches a previously attached change handler.
---
---@param handler dreamwork.std.NetTable.ChangeFn | dreamwork.std.Hook | dreamwork.std.Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function NetTable:detach( handler )
    return events:detach( self, "change", handler )
end

--- [SHARED]
---
--- Removes every change handler.
---
function NetTable:clear()
    events:clear( self, "change" )
end

--- [SHARED]
---
--- Waits for the next change.
---
---@return dreamwork.std.NetTable nettable The table.
---@return dreamwork.std.NetTable.Key[] path The keys from the table to the value.
---@return any value The new value.
---@return any old_value The old value.
---@return dreamwork.std.Client | nil sender The writing client for client writes on the server.
---@return boolean is_remote `true` if the change came from the other side.
---@async
function NetTable:await()
    return events:await( self, "change" )
end

if LUA_SERVER then

    --- [SERVER]
    ---
    --- Sends the full table to the clients again, for example when the result of `filter` has changed for them.
    ---
    ---@param target ( dreamwork.std.Client | dreamwork.std.Client[] )? The client(s), all subscribed clients by default.
    function NetTable:sync( target )
        local clients = subscribers[ self ]
        local stale_clients = stale[ self ]

        if target == nil then
            for client in raw_pairs( clients ) do
                stale_clients[ client ] = true
            end
        elseif not isObject( target ) then
            ---@cast target dreamwork.std.Client[]
            for i = 1, #target, 1 do
                local client = target[ i ]
                if clients[ client ] then
                    stale_clients[ client ] = true
                end
            end
        elseif clients[ target ] then
            stale_clients[ target ] = true
        end

        dirty_roots[ self ] = true
    end

    --- [SERVER]
    ---
    --- Sets the function that decides which top-level keys a client receives, everything by default.
    ---
    --- The function is called once per client and changed key, the table is synchronized again after the change.
    --- If the result changes for other reasons, call `NetTable:sync` for the affected clients.
    ---
    ---@param fn dreamwork.std.NetTable.FilterFn | nil The filter, `nil` to send everything.
    function NetTable:setFilter( fn )
        filters[ self ] = fn
        self:sync()
    end

    --- [SERVER]
    ---
    --- Sets the function that decides if a client can write a value, the clients can't write without it.
    ---
    --- Denied writes are reverted on the writing client.
    ---
    ---@param fn dreamwork.std.NetTable.PermitFn | nil The permit, `nil` to make the table read-only for the clients.
    function NetTable:setPermit( fn )
        local was_writable = permits[ self ] ~= nil
        permits[ self ] = fn

        if was_writable ~= (fn ~= nil) then
            self:sync()
        end
    end

end

--- [SHARED]
---
--- Returns the iterator over the values of the table or node, like `pairs`.
---
--- ```lua
--- for key, value in std.NetTable.pairs( scores.teams ) do
---     print( key, value )
--- end
--- ```
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node The table or node.
---@return fun( node: dreamwork.std.NetTable | dreamwork.std.NetTable.Node, key: dreamwork.std.NetTable.Key | nil ): dreamwork.std.NetTable.Key | nil, any
---@return dreamwork.std.NetTable | dreamwork.std.NetTable.Node
---@nodiscard
function NetTableClass.pairs( node )
    return node_next, node
end

--- [SHARED]
---
--- Returns a plain deep copy of the table or node.
---
---@param node dreamwork.std.NetTable | dreamwork.std.NetTable.Node The table or node.
---@return table copy The copy.
---@nodiscard
function NetTableClass.toTable( node )
    return node_copy( node, true )
end

--- [SHARED]
---
--- Checks if the value is a `NetTable` or a `NetTable.Node`.
---
---@param value any The value.
---@return boolean is_node `true` if the value is a table or node.
---@nodiscard
function NetTableClass.isNode( value )
    return node_values[ value ] ~= nil
end

--- [SHARED]
---
--- Registers the class so its objects can be stored in tables, it must be registered on both sides.
---
--- The class needs the `__serialize` and `__deserialize` methods, see `BinaryWriter:writeObject`.
--- Only objects whose metatable is the class base are recognized ( not FFI objects ).
---
---@param cls dreamwork.std.Class The class.
---@param name string? The name used on the network, the class name by default.
function NetTableClass.register( cls, name )
    local base = raw_get( cls, "__base" )

    if name == nil then
        name = raw_get( base, "__type" )
    end

    registry_names[ base ] = name
    registry_classes[ name ] = cls
end
