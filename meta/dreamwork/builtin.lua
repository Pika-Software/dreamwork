---@meta _


---@alias bool boolean


--- [SHARED AND MENU]
---
--- Dreamwork powered metatables.
---
---@class dreamwork.std.Metatable<K, V>
local Metatable = {}

---
--- Human-readable type name.
---
--- Changes the behavior of `type( value )` and `tostring( value )`.
---
---@type string?
Metatable.__type = nil

---
--- Legacy type name used by some systems.
---
--- **DO NOT USE THIS**
---
---@type string?
Metatable.MetaName = nil

---
--- Legacy numeric type identifier.
---
--- **DO NOT USE THIS**
---
---@type integer?
Metatable.MetaID = nil

---
--- Controls how "weak" a table is.
---
--- If present, must be one of the following strings:
--- - `"k"`, for a table with weak keys;
--- - `"v"`, for a table with weak values;
--- - `"kv"`, for a table with both weak keys and values.
---
--- A table with weak keys and strong values is also called an ephemeron table.
---
--- In an ephemeron table, a value is considered reachable only if its key is reachable.
---
--- In particular, if the only reference to a key comes through its value, the pair is removed.
---
--- See [§2.5.4](https://www.lua.org/manual/5.4/manual.html#2.5.4)
---
---@type "k" | "v" | "kv" | nil
Metatable.__mode = nil

---
--- Changes the behavior of `getmetatable( value )`.
---
--- If object does not have a Metatable, returns nil.
---
--- Otherwise, if the object's Metatable has a `__metatable` field, returns the associated value.
---
--- Otherwise, returns the Metatable of the given object.
---
---@type any
Metatable.__metatable = nil

---
--- Used very rarely internally and by `tostring( value )` if the `__tostring` metamethod is missing.
---
--- See [`luaL_newmetatable`](https://www.lua.org/manual/5.4/manual.html#luaL_newmetatable)
---
---@type string | nil
Metatable.__name = nil

---
--- If the Metatable of `v` has a `__tostring` field,
--- then tostring calls the corresponding value with `v` as the argument,
--- and uses the result of the call as its result.
---
--- Otherwise, if the Metatable of `v` has a `__name` field with a string value,
--- tostring may use that string in its final result.
---
---@type fun( self: any ): string
Metatable.__tostring = nil

---
--- Converts the object into a number.
---
---@type fun( self: any, base: integer ): number | integer
Metatable.__tonumber = nil

---
--- Converts the object into a boolean value.
---
---@type fun( self: any ): boolean
Metatable.__toboolean = nil

---
--- Converts the object into a color.
---
---@type fun( self: any ): dreamwork.std.Color
Metatable.__tocolor = nil

---
--- Converts the object into a hexadecimal string.
---
---
---@type fun( self: any ): string
Metatable.__tohex = nil

---
--- Returns a developer-oriented representation of the object.
---
--- This is used by the `represent( value )` function and in the debugger.
---
--- Also this affects `print`-like functions.
---
---@type fun( self: any ): string
Metatable.__represent = nil

---
--- Called when the the garbage collector detects that the corresponding table or userdata is dead.
---
--- **Important:** In ~~LuaJIT~~ garrysmod this metamethod is **not called** for tables, only used for `userdata`.
---
--- See [§2.5.3](https://www.lua.org/manual/5.4/manual.html#2.5.3)
---
---@type fun( self: any )
Metatable.__gc = nil

---
--- Called when a variable is closed.
---
--- See [§3.3.8](https://www.lua.org/manual/5.4/manual.html#3.3.8)
---
---@type fun( self: any, errobj: any ): any
Metatable.__close = nil

---
--- The addition `+` operation.
---
--- `a + b = result`
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__add = nil

---
--- The subtraction `-` operation.
---
--- `a - b = result`
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__sub = nil

---
--- The multiplication `*` operation.
---
--- `a * b = result`
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__mul = nil

---
--- The division `/` operation.
---
--- `a / b = result`
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__div = nil

---
--- The negation/unary `-` operation.
---
--- `-a = result`
---
--- This is equivalent to `a * -1`.
---
---@generic T
---@type fun( self: T ): T
Metatable.__unm = nil

---
--- The modulo `%` operation.
---
--- `a % b = result`
---
--- This is equivalent to `math.mod( a, b )`.
---
--- Note that this is different from `math.modf( a )`, which returns the remainder and fractional part of a number.
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__mod = nil

---
--- The exponentiation `^` operation.
---
--- `a ^ b = result`
---
--- This is equivalent to `math.pow( a, b )`.
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__pow = nil

---
--- The floor division `//` operation.
---
--- Used by `math.fdiv( a, b )` function.
---
---@generic T
---@type fun( self: T, other: any ): T
Metatable.__idiv = nil

---
--- The bitwise AND `&` operation.
---
--- Used by `bit.band( a, b )` function.
---
---@generic T
---@type fun( self: T, ...: any ): T
Metatable.__band = nil

---
--- The bitwise OR `|` operation.
---
--- Used by `bit.bor( a, b )` function.
---
---@generic T
---@type fun( self: T, ...: any ): T
Metatable.__bor = nil

---
--- The bitwise XOR `~` operation.
---
--- Used by `bit.bxor( a, b )` function.
---
---@generic T
---@type fun( self: T, ...: any ): T
Metatable.__bxor = nil

---
--- The bitwise NOT `~` operation.
---
--- Used by `bit.bnot( a )` function.
---
---@generic T
---@type fun( self: T ): T
Metatable.__bnot = nil

---
--- The left shift `<<` operation.
---
--- Used by `bit.lshift( a, b )` function.
---
---@generic T
---@type fun( self: T, bit_count: integer ): T
Metatable.__shl = nil

---
--- The right shift `>>` operation.
---
--- Used by `bit.rshift( a, b )` function.
---
---@generic T
---@type fun( self: T, bit_count: integer ): T
Metatable.__shr = nil

---
--- The arithmetic right shift operation.
---
--- Like `__shr`, but the vacated high-order bits are filled with copies of the sign bit
--- instead of zeros, so the sign of the value is preserved.
---
--- Used by `bit.arshift( a, b )` function.
---
---@generic T
---@type fun( self: T, bit_count: integer ): T
Metatable.__shar = nil

---
--- The bit rotate left operation.
---
--- Rotates bits to the left; bits shifted out of the top are wrapped around and shifted
--- back in at the bottom, so no bits are lost.
---
--- Used by `bit.rol( a, b )` function.
---
---@generic T
---@type fun( self: T, bit_count: integer ): T
Metatable.__brol = nil

---
--- The bit rotate right operation.
---
--- Rotates bits to the right; bits shifted out of the bottom are wrapped around and shifted
--- back in at the top, so no bits are lost.
---
--- Used by `bit.ror( a, b )` function.
---
---@generic T
---@type fun( self: T, bit_count: integer ): T
Metatable.__bror = nil

---
--- The byte swap operation.
---
--- Reverses the byte order (endianness) of a 32-bit integer, swapping its four
--- constituent bytes end-to-end.
---
--- Used by `bit.bswap( a )` function.
---
---@generic T
---@type fun( self: T ): T
Metatable.__bswp = nil

---
--- The concatenation `..` operation.
---
--- Behavior similar to calculation operators,
--- except that Lua will try a metamethod if
--- any operand is neither a string nor a number
--- (which is always coercible to a string).
---
---@type fun( self: any, other: any ): string
Metatable.__concat = nil

---
--- The length `#` operation.
---
--- Used by `len( value )` function.
---
--- If the object is not a string, Lua will try its metamethod.
---
--- If there is a metamethod,
--- Lua calls it with the object as argument,
--- and the result of the call (always adjusted to one value) is the result of the operation.
---
--- If there is no metamethod but the object is a table,
--- then Lua uses the table length operation.
---
--- Otherwise, Lua raises an error.
---
--- See [§3.4.7](https://www.lua.org/manual/5.4/manual.html#3.4.7)
---
---@type fun( self: any ): integer
Metatable.__len = nil

---
--- The equal `==` operation.
---
--- Behavior similar to calculation operators,
--- except that Lua will try a metamethod only
--- when the values being compared are either
--- both tables or both full userdata and
--- they are not primitively equal.
---
--- The result of the call is always converted to a `boolean`.
---
---@type fun( self: any, other: any ): boolean
Metatable.__eq = nil

---
--- The less than `<` operation.
---
--- Behavior similar to calculation operators,
--- except that Lua will try a metamethod only
--- when the values being compared are neither
--- both numbers nor both strings.
---
--- Moreover, the result of the call is always converted to a boolean.
---
---@type fun( self: any, other: any ): boolean
Metatable.__lt = nil

---
--- The less equal `<=` operation.
---
--- Behavior similar to the less than operation.
---
---@type fun( self: any, other: any ): boolean
Metatable.__le = nil

---
--- The indexing access operation `table[key]`.
---
--- This event happens when `table` is not a table or when `key` is not present in `table`.
---
--- The metavalue is looked up in the Metatable of `table`.
---
--- The metavalue for this event can be either a function, a table, or any value with an `__index` metavalue.
---
--- If it is a function, it is called with `table` and `key` as arguments, and the result of the call (adjusted to one value) is the result of the operation.
---
--- Otherwise, the final result is the result of indexing this metavalue with `key`.
---
--- This indexing is regular, not raw, and therefore can trigger another `__index` metavalue.
---
--- **Examples**:
--- ```lua
--- local data = {foo = 'bar'}
--- local proxy = setmetatable({}, {__index = data})
---
--- print(proxy.foo) --> 'bar'
--- ```
--- ```lua
--- local tab = setmetatable({count = 0}, {
---   __index = function(self, _k)
---     self.count = self.count + 1
---     return self.count
---   end
--- })
---
--- print(tab.indextest) --> 1
--- print(tab.indextestagain) --> 2
--- print(tab.asdfasdf) --> 3
--- print(tab[1234]) --> 4
--- ```
---
---@generic K, V
---@type table<K, V> | ( fun( self: table<K, V>, key: K ): ( V | nil ) )
Metatable.__index = nil

---
--- The indexing assignment `table[key] = value`.
---
--- Like the index event, this event happens when `table` is not a table or when `key` is not present in `table`.
---
--- The metavalue is looked up in the Metatable of `table`.
---
--- Like with indexing, the metavalue for this event can be either a function, a table, or any value with an `__newindex` metavalue.
---
--- If it is a function, it is called with `table`, `key`, and `value` as arguments.
---
--- Otherwise, Lua repeats the indexing assignment over this metavalue with the same key and value.
---
--- This assignment is regular, not raw, and therefore can trigger another `__newindex` metavalue.
---
--- Whenever a `__newindex` metavalue is invoked, Lua does not perform the primitive assignment.
---
--- If needed, the metamethod itself can call rawset to do the assignment.
---
--- **Examples:**
---
--- ```lua
--- local t = setmetatable({}, {
---   __newindex = function(t, key, value)
---     if type(value) == 'number' then
---       rawset(t, key, value * value)
---     else
---       rawset(t, key, value)
---     end
---   end
--- })
---
--- t.foo = 'foo'
--- t.bar = 4
--- t.la = 10
--- print(t.foo) --> 'foo'
--- print(t.bar) --> 16
--- print(t.la) --> 100
--- ```
---
---@generic K, V
---@type table<K, V> | ( fun( self: table<K, V>, key: K, value: V ) )
Metatable.__newindex = nil

---
--- The call operation `func(args)`.
---
--- This event happens when Lua tries to call a non-function value (that is, `func` is not a function).
---
--- Instead of use `isFunction( value )` you can use `isCallable( value )` that checks  if a value is callable.
---
--- The metamethod is looked up in `func`.
---
--- If present, the metamethod is called with `func` as its first argument, followed by the arguments of the original call (`args`).
---
--- All results of the call are the results of the operation.
---
--- This is the only metamethod that allows multiple results.
---
--- **Examples:**
---
--- ```lua
--- local t = setmetatable({}, {
---   __call = function(t, ...)
---     print('Called with:', ...)
---   end
--- })
---
--- t(1, 2, 3) --> 'Called with: 1 2 3'
--- ```
---
---@type fun( self: any, ...: any ): any
Metatable.__call = nil

---
--- Affects iteration when using the `pairs()` function, letting you define a custom iterator function (see [`pairs()`](https://www.lua.org/manual/5.4/manual.html#pdf-pairs), [`next()`](https://www.lua.org/manual/5.4/manual.html#pdf-next)).
---
---@generic K, V
---@type fun( self: table<K, V> ): fun( tbl: table<K, V>, key: ( K | nil ) ): ( K | nil ), ( V | nil )
Metatable.__pairs = nil

---
--- Creates a copy of the given object.
---
--- This is used by the `copy( value )` function.
--- If not defined, a shallow copy will be created using the default Lua copying mechanism.
---
--- If you want to create a deep copy, you will need to implement this metamethod yourself.
---
---@generic T
---@type fun( self: T ): T
Metatable.__copy = nil

---
--- Serializes the object into a writer.
---
---@type fun( self: any, writer: dreamwork.std.BinaryWriter, ...: any? )
Metatable.__serialize = nil

---
--- Deserializes the object from a reader.
---
---@type fun( self: any, reader: dreamwork.std.BinaryReader, ...: any? )
Metatable.__deserialize = nil

---
--- Checks whether the object is valid.
---
---@type fun( self: any ): boolean
Metatable.__isvalid = nil

---
--- Returns a stable hash value for the object.
---
---@type fun( self: any ): integer
Metatable.__hash = nil

---
--- Returns binary size of the `object` as integer of bit/bytes.
---
---@type fun( self: any, as_bytes: boolean ): integer
Metatable.__sizeof = nil
