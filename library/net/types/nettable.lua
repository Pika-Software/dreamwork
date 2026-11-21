---@meta _

---@class garrysmod.ents
local glua_ents = {}

--- [SHARED]
---
--- A named table that is synchronized between the server and the clients,
--- built on top of `Network`.
---
--- Values are read and written like table fields, writes are collected and only the changed paths
--- are sent once per tick:
---
--- ```lua
--- local scores = NetTable( "scores" )
---
--- scores.round = 1
--- scores.teams = { red = { kills = 0 }, blue = { kills = 0 } }
---
--- scores.teams.red.kills = 5 -- sends only `teams.red.kills`
--- ```
---
--- Supported keys are strings, numbers and booleans, supported values are `nil`, booleans, numbers, strings,
--- tables of them, `Vector3`, `Angle3`, engine `Vector`, `Angle`, `Color` and entities,
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
---@class NetTable : Object
---@field __class NetTableClass
---@field [NetTable.Key] any The synchronized values.
local __NetTable = {}

--- [SHARED]
---
--- The class of `NetTable`, call it to create or get a table.
---
---@class NetTableClass : NetTable, Class
---@field __base NetTable
---@overload fun( name: string ): NetTable
NetTable = {}

--- [SHARED]
---
--- A nested table of a `NetTable`, read and written like a table.
---
--- A node removed from its table is detached, its values stay readable,
--- but writes to it are not synchronized anymore.
---
---@class NetTable.Node : Object
---@field [NetTable.Key] any The synchronized values.
local Node = {}

--- The supported key types.
---
---@alias NetTable.Key string | number | boolean

--- Called when a value is changed, by a local write or by the other side.
---
--- `path` is the list of keys from the table to the value, `value` is a `NetTable.Node` for tables.
--- `sender` is the writing client for client writes on the server, `nil` otherwise,
--- `is_remote` is `true` if the change came from the other side.
---
---@alias NetTable.ChangeFn fun( nettable: NetTable, path: NetTable.Key[], value: any, old_value: any, sender: Client | nil, is_remote: boolean )

--- Decides if the client receives the top-level key of the table.
---
---@alias NetTable.FilterFn fun( nettable: NetTable, client: Client, key: NetTable.Key ): boolean

--- Decides if the client can write the value at the path, `value` is a plain copy, tables are not nodes yet.
---
---@alias NetTable.PermitFn fun( nettable: NetTable, client: Client, path: NetTable.Key[], value: any ): boolean

--- An entity received by the client, resolved by index on every read.
---
---@class NetTable.EntityRef
---@field [1] integer The entity index.
local EntityRef = {}

---@param key any
---@protected
function Node:__index(key) end

---@param key any
---@param value any
---@protected
function Node:__newindex(key, value) end

---@return integer
---@protected
function Node:__len() end

---@protected
function Node:__pairs() end

---@return string
---@protected
function Node:__tostring() end

---@param name string The name of the table.
---@return NetTable | nil object The existing table with this name.
---@protected
function NetTable:__new(name) end

---@return string
---@protected
function __NetTable:__represent() end

---@param name string The name of the table, must be the same on the server and the client.
---@protected
function __NetTable:__init(name) end

---@param key any
---@protected
function __NetTable:__index(key) end

---@param key any
---@param value any
---@protected
function __NetTable:__newindex(key, value) end

---@return integer
---@protected
function __NetTable:__len() end

---@protected
function __NetTable:__pairs() end

--- [SHARED]
---
--- Returns the value of the key, for keys that are shadowed by methods.
---
---@param key NetTable.Key The key.
---@return any value The value, a `NetTable.Node` for tables.
---@nodiscard
function __NetTable:get(key) end

--- [SHARED]
---
--- Sets the value of the key, for keys that are shadowed by methods.
---
---@param key NetTable.Key The key.
---@param value any The value, `nil` removes the key.
function __NetTable:set(key, value) end

--- [SHARED]
---
--- Returns the name of the table.
---
---@return string name The name.
---@nodiscard
function __NetTable:getName() end

--- [SHARED]
---
--- Checks if the table has received the first snapshot, always `true` on the server.
---
---@return boolean is_ready `true` if the table is synchronized.
---@nodiscard
function __NetTable:isReady() end

--- [SHARED]
---
--- Checks if the table can be written, always `true` on the server.
---
---@return boolean is_writable `true` if the server accepts writes from this client.
---@nodiscard
function __NetTable:isWritable() end

--- [SHARED]
---
--- Calls the handler once the table has received the first snapshot,
--- right away if it already has and always on the server.
---
---@param handler fun( nettable: NetTable ) | Hook | Event The callback or callable object.
function __NetTable:ready(handler) end

--- [SHARED]
---
--- Attaches a handler that is called when a value is changed, locally or by the other side.
---
--- Tables merged into existing ones call it for every changed key.
---
--- If the handler is already attached, it will not be attached twice.
---
---@param handler NetTable.ChangeFn | Hook | Event The callback or callable object.
function __NetTable:attach(handler) end

--- [SHARED]
---
--- Attaches a change handler that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler NetTable.ChangeFn | Hook | Event The callback or callable object.
function __NetTable:once(handler) end

--- [SHARED]
---
--- Detaches a previously attached change handler.
---
---@param handler NetTable.ChangeFn | Hook | Event The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __NetTable:detach(handler) end

--- [SHARED]
---
--- Removes every change handler.
---
function __NetTable:clear() end

--- [SHARED]
---
--- Waits for the next change.
---
---@return NetTable nettable The table.
---@return NetTable.Key[] path The keys from the table to the value.
---@return any value The new value.
---@return any old_value The old value.
---@return Client | nil sender The writing client for client writes on the server.
---@return boolean is_remote `true` if the change came from the other side.
---@async
function __NetTable:await() end

--- [SERVER]
---
--- Sends the full table to the clients again, for example when the result of `filter` has changed for them.
---
---@param target ( Client | Client[] )? The client(s), all subscribed clients by default.
function __NetTable:sync(target) end

--- [SERVER]
---
--- Sets the function that decides which top-level keys a client receives, everything by default.
---
--- The function is called once per client and changed key, the table is synchronized again after the change.
--- If the result changes for other reasons, call `NetTable:sync` for the affected clients.
---
---@param fn NetTable.FilterFn | nil The filter, `nil` to send everything.
function __NetTable:setFilter(fn) end

--- [SERVER]
---
--- Sets the function that decides if a client can write a value, the clients can't write without it.
---
--- Denied writes are reverted on the writing client.
---
---@param fn NetTable.PermitFn | nil The permit, `nil` to make the table read-only for the clients.
function __NetTable:setPermit(fn) end

--- [SHARED]
---
--- Returns the iterator over the values of the table or node, like `pairs`.
---
--- ```lua
--- for key, value in NetTable.pairs( scores.teams ) do
---     print( key, value )
--- end
--- ```
---
---@param node NetTable | NetTable.Node The table or node.
---@return fun( node: NetTable | NetTable.Node, key: NetTable.Key | nil ): NetTable.Key | nil, any
---@return NetTable | NetTable.Node
---@nodiscard
function NetTable.pairs(node) end

--- [SHARED]
---
--- Returns a plain deep copy of the table or node.
---
---@param node NetTable | NetTable.Node The table or node.
---@return table copy The copy.
---@nodiscard
function NetTable.toTable(node) end

--- [SHARED]
---
--- Checks if the value is a `NetTable` or a `NetTable.Node`.
---
---@param value any The value.
---@return boolean is_node `true` if the value is a table or node.
---@nodiscard
function NetTable.isNode(value) end

--- [SHARED]
---
--- Registers the class so its objects can be stored in tables, it must be registered on both sides.
---
--- The class needs the `__serialize` and `__deserialize` methods, see `BinaryWriter:writeObject`.
--- Only objects whose metatable is the class base are recognized ( not FFI objects ).
---
---@param cls Class The class.
---@param name string? The name used on the network, the class name by default.
function NetTable.register(cls, name) end
