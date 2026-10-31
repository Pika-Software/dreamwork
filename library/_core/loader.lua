---@meta _

--- The global environment of Lua.
---
---@type table
_G = nil

--- The registry of Lua.
---
---@type table
_R = nil

--- The version of the Lua interpreter.
---
---@type integer
LUA_VERSION = nil

--- Contains the version number of the Garrys Mod. For example: `201211` = `01.01.2012`
---
---@type integer
GAME_VERSION = nil

--- The branch the Garry's Mod is running on. This will be `unknown` on main branch.
---
---@type "x86-64" | "dev" | "prerelease" | "unknown" | string
GAME_BRANCH = nil

--- The realm the code is running on.
---
---@type "server" | "client" | "menu" | "unknown"
LUA_REALM = nil

--- `true` if code is running on the menu, `false` otherwise.
---
---@type boolean
LUA_MENU = nil

--- `true` if code is running on the client, `false` otherwise.
---
---@type boolean
LUA_CLIENT = nil

--- `true` if code is running on the client or menu, `false` otherwise.
---
---@type boolean
LUA_CLIENT_MENU = nil

--- `true` if code is running on the client or server, `false` otherwise.
---
---@type boolean
LUA_CLIENT_SERVER = nil

--- `true` if code is running on the server, `false` otherwise.
---
---@type boolean
LUA_SERVER = nil

--- A cached value of `developer` console variable.
---
---@type integer
DEVELOPER = nil

--- The time it takes to run one frame in seconds. **Client-only**
---
---@type number
FRAME_TIME = nil

--- The number of frames per second. **Client-only**
---
---@type number
FPS = nil

--- A sentinel symbol that represents an explicit "no value", compare it by identity.
---
---@type null
null = nil

--- [SHARED AND MENU]
---
--- Throws an error with the specified message and level.
---
---@param value? any The error value to throw.
---@param stack_level? integer The stack level to throw the error.
---@param dont_break? boolean If `true`, the error will not break the current stack.
function error(value, stack_level, dont_break) end

--- [SHARED AND MENU]
---
--- Returns the current environment in use by the function.
---
---@param location integer | function Can be a Lua `function` or a `number` that specifies the function at that stack level.
---@return table fenv Specified function environment.
---@nodiscard
function getfenv(location) end

--- [SHARED AND MENU]
---
--- Sets the environment of the specified function.
---
---@generic F: function
---@param location integer | F Can be a Lua `function` or a `number` that specifies the function at that stack level.
---@param env table The environment table to set.
---@return F location The function with the updated environment.
function setfenv(location, env) end

--- [SHARED AND MENU]
---
--- Checks whether the value is a `table`.
---
---@param value any The value to check.
---@return boolean is_table `true` if the value is a `table`, `false` otherwise.
---@nodiscard
function isTable(value) end

raw.getmetatable = debug.getmetatable

raw.setmetatable = debug.setmetatable

--- [SHARED AND MENU]
---
--- Returns the value of the given key in the metatable of the given value.
---
--- Returns `nil` if not found.
---
---@param value any The value to get the metatable from.
---@param key string The searchable key.
---@return any | nil value The value of the given key.
---@nodiscard
function debug.getmetavalue(value, key, allow_index) end

--- [SHARED AND MENU]
---
--- Receives a value of any type and converts it to a string in a human-readable format.
---
--- If the metatable of `v` has a `__tostring` field, then `tostring` calls the corresponding value with `v` as argument, and uses the result of the call as its result.
---
--- Otherwise, if the metatable of `v` has a `__name` field with a string value, `tostring` may use that string in its final result.
---
--- For complete control of how numbers are converted, use [string.format](http://www.lua.org/manual/5.4/manual.html#pdf-string.format).
---
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-tostring)
---
---@param value any The value to convert to a string.
---@return string str The string representation of `value`.
---@nodiscard
function tostring(value) end

--- [SHARED AND MENU]
---
--- Returns the length of the given value.
---
---@param value any The value to get the length of.
---@return number length The length of the given value.
---@nodiscard
function len(value) end

--- [SHARED AND MENU]
---
--- Compares two values for equality.
---
--- Unlike Lua's `==` operator, this function invokes the `__eq` metamethod
--- from either operand if one is available. If neither operand defines
--- `__eq`, it falls back to the built-in equality operator.
---
---@param a any The first value to compare.
---@param b any The second value to compare.
---@return boolean is_equal `true` if the values are considered equal; otherwise `false`.
---@nodiscard
function equal(a, b) end

--- [SHARED AND MENU]
---
--- Compares two values, returning whether the first is less than the second.
---
--- Unlike Lua's `<` operator, this function invokes the `__lt` metamethod
--- from either operand if one is available. If neither operand defines
--- `__lt`, it falls back to the built-in less-than operator.
---
---@param a any The first value to compare.
---@param b any The second value to compare.
---@return boolean is_less_than `true` if `a` is less than `b`; otherwise `false`.
---@nodiscard
function lessThan(a, b) end

--- [SHARED AND MENU]
---
--- Compares two values, returning whether the first is less than or equal to the second.
---
--- Unlike Lua's `<=` operator, this function invokes the `__le` metamethod
--- from either operand if one is available. If neither operand defines
--- `__le`, it falls back to the built-in less-than-or-equal operator.
---
---@param a any The first value to compare.
---@param b any The second value to compare.
---@return boolean is_less_equal `true` if `a` is less than or equal to `b`; otherwise `false`.
---@nodiscard
function lessEqual(a, b) end

--- [SHARED AND MENU]
---
--- Returns binary size of the `value` as integer of bit/bytes.
---
---@param value any The value to get the size of.
---@param as_bytes? boolean Whether return size as bytes. By default: `false`
---@return integer | nil size The size of the `value`.
---@nodiscard
function sizeof(value, as_bytes) end

--- [SHARED AND MENU]
---
--- Returns the copy of the `value`.
---
---@generic T
---@param value T The value to copy.
---@return T copy The copy of the `value`.
---@nodiscard
function copy(value) end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__tonumber`, calls it with `e` and `base` as arguments and returns its result.
---
--- When called with no `base`, `tonumber` tries to convert its argument to a number. If the argument is already a number or a string convertible to a number, then `tonumber` returns this number; otherwise, it returns `fail`.
---
--- The conversion of strings can result in integers or floats, according to the lexical conventions of Lua (see [§3.1](command:extension.lua.doc?["en-us/51/manual.html/3.1"])). The string may have leading and trailing spaces and a sign.
---
---
--- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-tonumber"])
---
---@param e any The value to convert to a number.
---@param base? numberbase The number base, default is `10`.
---@return number | nil x The number value of `e`, or `nil` if `e` cannot be converted to a number.
---@nodiscard
function tonumber(e, base) end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__toboolean`, calls it with `e` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param e any The value to convert to a `boolean`.
---@return boolean | nil bool The boolean value of `e`, or `nil` if `e` cannot be converted to a boolean.
---@nodiscard
function toboolean(e) end

tobool = toboolean

--- [SHARED AND MENU]
---
--- If `value` has a metamethod `__tocolor`, calls it with `value` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param value any The value to convert to a `color`.
---@return Color | nil clr The color value of `value`, or `nil` if `value` cannot be converted to a color.
---@nodiscard
function tocolor(value) end

--- [SHARED AND MENU]
---
--- Checks if the value is valid.
---
---@param value any The value to check for validity.
---@return boolean is_valid `true` if object is still valid and should be kept alive, `false` otherwise.
---@nodiscard
function isValid(value) end

--- [SHARED AND MENU]
---
--- If `t` has a metamethod `__pairs`, calls it with t as argument and returns the first three results from the call.
---
--- Otherwise, returns three values: the [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) function, the table `t`, and `nil`, so that the construction
---
--- ```lua
---     for k,v in pairs(t) do body end
--- ```
---
--- will iterate over all key–value pairs of table `t`.
---
--- See function [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) for the caveats of modifying the table during its traversal.
---
---@generic K, V
---@param tbl table<K, V>
---@param key K | nil
---@return K, V
---@nodiscard
function next(tbl, key) end

--- [SHARED AND MENU]
---
--- If `t` has a metamethod `__pairs`, calls it with t as argument and returns the first three results from the call.
---
--- Otherwise, returns three values: the [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) function, the table `t`, and `nil`, so that the construction
--- ```lua
---     for k,v in pairs(t) do body end
--- ```
--- will iterate over all key–value pairs of table `t`.
---
--- See function [next](command:extension.lua.doc?["en-us/54/manual.html/pdf-next"]) for the caveats of modifying the table during its traversal.
---
---
--- [View documents](command:extension.lua.doc?["en-us/54/manual.html/pdf-pairs"])
---
---@generic K, V
---@param t table<K, V>
---@return fun( table: table<K, V>, index: ( K | nil ) ): K, V
---@return table<K, V>
---@nodiscard
function pairs(t) end

--- [SHARED AND MENU]
---
--- Returns the next value in the table `t`, with the given `index`.
---
---@param tbl table
---@param index integer
---@return integer | nil, any
---@nodiscard
function inext(tbl, index) end

--- [SHARED AND MENU]
---
--- Returns three values (an iterator function, the table `t`, and `0`) so that the construction
--- ```lua
---     for i,v in ipairs(t) do body end
--- ```
--- will iterate over the key–value pairs `(1,t[1]), (2,t[2]), ...`, up to the first absent index.
---
---
--- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-ipairs"])
---
---@generic V
---@param t V[]
---@return fun( table: V[], i: ( integer | nil ) ): integer, V
---@return V[]
---@return integer i
---@nodiscard
function ipairs(t) end

---@alias RangeIterator fun( break_point: integer, index: integer ): integer | nil

--- [SHARED AND MENU]
---
--- Creates a stateless numeric `for`-loop iterator that steps from `from` to `to`
--- (inclusive), incrementing (or decrementing) by `step` each iteration.
---
--- Intended to be used directly in a generic `for` loop,
--- e.g. `for i in range( 1, 10, 2 ) do ... end`.
---
---@param from integer The starting value of the range.
---@param to integer The ending value of the range (inclusive).
---@param step? integer The amount to step by each iteration. Defaults to `1`. Can be negative to count down.
---@return RangeIterator iterator The iterator function to be used with a generic `for` loop.
---@return integer to The final value, passed through as the loop's invariant state.
---@return integer start The initial value, passed to the iterator on the first call.
---@nodiscard
function range(from, to, step) end

--- [SHARED AND MENU]
---
--- The global environment table (outside of DreamWork).
---
---@type _G
global = nil

--- [SHARED AND MENU]
---
--- Returns the hash of the given value.
---
---@param value any The value to get the hash of.
---@return integer hash The hash of the given value.
---@nodiscard
function hash(value) end

--- [SHARED AND MENU]
---
--- Returns a hexadecimal string identifying the given value.
---
--- If `value`'s metatable defines a `__hash` metamethod, that function is called on `value`
--- and its integer result is formatted as hex. Otherwise the value's raw memory address is
--- used (via `%p`), which is stable for the lifetime of the value but has no meaning beyond
--- identifying it — this is mainly useful for tables, functions, threads, and userdata.
---
--- If `desired_length` is given, the resulting string is padded with leading zeros to reach
--- that length, or truncated from the left if it's already longer.
---
---@param value any The value to get a hexadecimal identifier for.
---@param desired_length? integer The exact length the returned string should be. If omitted, the natural length is used.
---@return string hex_str The hexadecimal identifier of `value`, optionally padded or truncated to `desired_length`.
---@nodiscard
function tohex(value, desired_length) end

--- [SHARED AND MENU]
---
--- A sentinel symbol that represents an explicit "no value".
---
--- Unlike `nil`, it can be stored in tables and passed around as a real value,
--- which makes it useful for telling "intentionally empty" apart from "missing".
---
--- It is a singleton, so compare it by identity: `value == null`.
---
---@class null : Symbol
null = {}

--- [SHARED AND MENU]
---
--- Checks if the value is an instance of the given parent.
---
---@param object any The object to check for being an instance of the given parent.
---@param ... any The parent classes/metatables to check against.
---@return boolean is_instance `true` if `object` is an instance of any of the given parent classes/metatables, `false` otherwise.
---@nodiscard
function isInstance(object, ...) end

--- [SHARED AND MENU]
---
--- Checks if the value is an instance of the given parent.
---
---@param object any The object to check for being an instance of the given parent.
---@param value any The parent class/metatable to check against.
---@return boolean is_instance `true` if `object` is an instance of the given parent class/metatable, `false` otherwise.
---@nodiscard
function is(object, value) end

--- `true` if the game is running on OSX.
---
---@type boolean
SYSTEM_OSX = nil

--- `true` if the game is running on Linux.
---
---@type boolean
SYSTEM_LINUX = nil

--- `true` if the game is running on Windows.
---
---@type boolean
SYSTEM_WINDOWS = nil

--- `true` if the game is running on 64-bit architecture.
---
---@type boolean
SYSTEM_X64 = nil

--- `true` if the game is running on 32-bit architecture.
---
---@type boolean
SYSTEM_X32 = nil

--- The short name of the currently running system with architecture.
---
---@type "osx64" | "osx" | "linux64" | "linux" | "win64" | "win32"
SYSTEM_NAME = nil

---@class Nil : metatable
Nil = {}

Nil.__type = "nil"

--- [SHARED AND MENU]
---
--- Checks whether the value type is `nil`.
---
---@param value any
---@return boolean is_nil
---@nodiscard
function isNil(value) end

---@class Boolean : metatable
Boolean = {}

Boolean.__type = "boolean"

--- [SHARED AND MENU]
---
--- Checks whether the value type is `boolean`.
---
---@param value any
---@return boolean is_bool
---@nodiscard
function isBoolean(value) end

---@class Number : metatable
Number = {}

Number.__type = "number"

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `number`.
---
---@param value any
---@return boolean is_number
---@nodiscard
function isNumber(value) end

---@class Integer : metatable
Integer = {}

Integer.__type = "integer"

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `integer`.
---
---@param value any
---@return boolean is_integer
---@nodiscard
function isInteger(value) end

---@class String : metatable
String = {}

String.__type = "string"

String.__tonumber = raw.tonumber

String.__div = string.divide

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `string`.
---
---@param value any
---@return boolean is_string
---@nodiscard
function isString(value) end

---@class Function : metatable
Function = {}

Function.__type = "function"

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `function`.
---
---@param value any
---@return boolean is_function
---@nodiscard
function isFunction(value) end

--- [SHARED AND MENU]
---
--- Checks if the value is callable, basically it's a function or a table with a callable `__call` metamethod.
---
---@param value any
---@return boolean is_callable
---@nodiscard
function isCallable(value) end

---@class Thread : metatable
Thread = {}

Thread.__type = "thread"

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `thread`.
---
---@param value any
---@return boolean is_thread
---@nodiscard
function isThread(value) end

--- [SHARED AND MENU]
---
--- Returns a string representing the name of the type of the passed object.
---
---@param value any The value to get the type of.
---@return type type_name The type name of the given value.
---@nodiscard
function type(value) end

--- [SHARED AND MENU]
---
--- Loads a string as a lua code chunk in the specified
--- environment and returns new function as a compile result.
---
---@param lua_code string The lua code chunk.
---@param chunk_name string | nil The lua code chunk name.
---@param env table | nil The environment of compiled function.
---@return function fn The compiled function.
---@nodiscard
function loadstring(lua_code, chunk_name, env) end

---@class String
local __String = {}

--- [SHARED AND MENU]
---
--- Returns a string representation of the given value.
---
---@param value any The value to get the string representation of.
---@return string str The string representation of the given value.
---@nodiscard
function represent(value) end

--- [SHARED AND MENU]
---
--- A table containing named colors.
---
--- Also takes colors from `resource/ClientScheme.res` if available. [CLIENT/MENU?]
---
--- If no color is found, a new empty color will be created and assigned to specified name.
---
--- Table key must be `string` or `integer`.
---
---@class color.Scheme
color.Scheme = {}

color.Scheme.white = 0xFFFFFF

color.Scheme.white_smoke = 0xF0F0F0

color.Scheme.black = 0x000000

color.Scheme.red = 0xFF0000

color.Scheme.mona_lisa = 0xFF8A80

color.Scheme.green = 0x00FF00

color.Scheme.blue = 0x0000FF

color.Scheme.spray = 0x7EC8E3

color.Scheme.robin_egg_blue = 0x7EC8E3

color.Scheme.yellow = 0xFFFF00

color.Scheme.sandstone = 0xC9B896

color.Scheme.cyan = 0x00FFFF

color.Scheme.magenta = 0xFF00FF

color.Scheme.gray = 0x808080

color.Scheme.dark_gray = 0xA9A9A9

color.Scheme.light_gray = 0xD0D0D0

color.Scheme.suva_gray = 0x8A8A8A

color.Scheme.turquoise = 0x40e0d0

color.Scheme.dark_turquoise = 0x00D0D0

--- [SHARED AND MENU]
---
--- Returns the value of the key in a table.
---
---@param tbl table The table.
---@param key any The key.
---@return any
---@nodiscard
function raw.index(tbl, key) end

--- [SHARED AND MENU]
---
--- Throws an error with the specified message and level.
---
--- An `Error` that already has a call stack is rethrown as is; if it was captured in another
--- thread (e.g. inside a resumed coroutine) the frames leading here are added below it.
--- Call `Error:reset` before throwing the same object again to capture a fresh stack.
---
---@param value? any The error value to throw.
---@param stack_level? integer The stack level to throw the error.
---@param dont_break? boolean If `true`, the error is displayed without breaking the current stack.
function error(value, stack_level, dont_break) end

--- [SHARED AND MENU]
---
--- Throws an error with the specified message and level.
---
---@param stack_level? integer The stack level to throw the error.
---@param dont_break? boolean If `true`, the error will not break the current stack.
---@param fmt string The error message to throw.
---@param ... any The error message arguments to format/interpolate.
function errorf(stack_level, dont_break, fmt, ...) end

--- [SHARED AND MENU]
---
--- Throws an error if the given expression is false.
---
---@param expression boolean The expression to check.
---@param fmt string The error message to throw.
---@param ... any The error message arguments to format/interpolate.
function assert(expression, fmt, ...) end

--- [SHARED AND MENU]
---
--- Checks that the local variable at the given stack `index` (in the calling function)
--- matches one of the expected types/classes given in `...`. If the value's type/instance
--- does not match any of the expected types, a `TypeError` is raised, otherwise the
--- function returns without doing anything.
---
---@param index integer The stack index of the local variable to check (as used by `debug.getlocal`).
---@param ... any The expected type names (strings) or class/type tables (with an optional `__type` field) to check the value against.
function checktype(index, ...) end

--- [SHARED AND MENU]
---
--- Validates a local variable of the calling function (typically one of its parameters)
--- against one or more validator functions, raising a `ValueError` on the first failure.
---
--- `index` is the index of the local variable in the function that called `checkvalue`,
--- as in `debug.getlocal`. Parameters come first, so `1` is the first parameter, `2` the
--- second, and so on. The variable's current value is read at call time, so reassigning
--- a parameter before the check changes what gets validated.
---
--- Each validator receives the value and must return `true` if it is valid, or `false`
--- plus an error message if it isn't. Validators run in the order given and checking stops
--- at the first failure. Only a strict `false` counts as a failure, so a validator that
--- returns `nil` (or nothing) is treated as passing.
---
--- On failure, the error is raised with level `2`, so it points at the function that
--- called `checkvalue` rather than at `checkvalue` itself.
---
--- ```lua
--- local function is_positive( value )
---     if value > 0 then
---         return true
---     end
---
---     return false, "must be positive"
--- end
---
--- local function set_speed( speed )
---     checkvalue( 1, is_positive )
---     -- ...
--- end
--- ```
---
---@param index integer The index of the calling function's local variable to validate (`1` = its first parameter/argument).
---@param ... ( fun( value: any ): true, nil ) | ( fun( value: any ): false, string ) The validators to run, in order. Each returns `true`, or `false` and an error message.
function checkvalue(index, ...) end

--- [SHARED AND MENU]
---
--- A single signature entry for `dispatch`: a list of argument types paired with the
--- function to call when a call's arguments match those types.
---
---@generic F: function
---@class OverloadInput<F>
---@field match string[] | string The Lua type name (or ordered list of type names, as returned by `type`) that a call's arguments must have for `fn` to be selected.
---@field fn F The function to call when the arguments match.

--- [SHARED AND MENU]
---
--- Builds a function that dispatches each call to one of several implementations, chosen by
--- the Lua types of the call's arguments. The multi-signature counterpart to `overload`,
--- which only supports a single alternative signature.
---
--- Each entry in `inputs` pairs a `match` signature (a type name, or an ordered list of type
--- names) with a `fn`. On every call, the entries are checked in order, and the first one
--- whose signature matches exactly (same argument count, same types in the same order) has
--- its `fn` called with the arguments. If nothing matches, `fallback_fn` is called instead;
--- if there is no `fallback_fn`, an error is raised at call time.
---
--- `inputs` is validated up front: every `fn` must be a function and every `match` must be
--- a string or a table, otherwise a `TypeError` is raised at definition time (level 2,
--- pointing at the caller of `dispatch`). A bare string `match` is shorthand for a
--- single-type list.
---
--- **NOTE**: `inputs` is modified in place. The entry count is cached in `inputs[0]`, each
--- `match` list gets its own count in `match[0]`, and string `match` values are replaced with
--- table equivalents. Don't reuse or edit the table after passing it in.
---
--- **NOTE**: a signature with no types can never match. Zero-argument calls always fall
--- through to `fallback_fn`.
---
--- ```lua
--- local describe = dispatch( {
---     { match = "string",             fn = function( str ) return "a string" end },
---     { match = { "number", "number" }, fn = function( a, b ) return "two numbers" end },
--- }, function( ... ) return "something else" end )
---
--- describe( "hi" )     --> "a string"
--- describe( 1, 2 )     --> "two numbers"
--- describe( 1 )        --> "something else"  (no signature matches: fallback_fn)
--- ```
---
---@generic F: function
---@param inputs OverloadInput<F>[] The signatures to dispatch between, checked in order (first match wins).
---@param fallback_fn? F The function called when no input matches. If omitted, a non-matching call raises an error.
---@return F fn_over A function that dispatches to the matching input's `fn`, or to `fallback_fn`.
---@nodiscard
function dispatch(inputs, fallback_fn) end

--- [SHARED AND MENU]
---
--- Creates a function that accepts a variable
--- number of arguments and returns them in
--- the order of the specified indices.
---
--- | `junction(...)` call | `fjn(...)` call | result `...` |
--- | ---------------------|-----------------|--------------|
--- | `junction(1)`        | `(A, B, C)`     | `A`          |
--- | `junction(2)`        | `(A, B, C)`     | `B`          |
--- | `junction(3)`        | `(A, B, C)`     | `C`          |
--- | `junction(2, 1)`     | `(A, B, C)`     | `B, A`       |
--- | `junction(3, 1, 2)`  | `(X, Y, Z)`     | `Z, X, Y`    |
---
---@param ... integer The indices of arguments to return.
---@return function fjn The created junction function.
---@nodiscard
function junction(...) end

--- [SHARED AND MENU]
---
--- Wraps `main_fn` so that calls whose arguments match a specific type signature are routed
--- to `overload_fn` instead, while every other call falls through to `main_fn` unchanged.
---
--- `match` describes the signature to intercept, as the exact list of Lua type names
--- (as returned by `type`, e.g. `"string"`, `"number"`, `"table"`) the arguments must have,
--- in order. A call goes to `overload_fn` only if the number of arguments equals the number
--- of entries in `match` *and* every argument's type matches its entry; any extra or missing
--- arguments, or any type mismatch, calls `main_fn` instead. Trailing `nil` arguments count
--- toward the argument total, and are matched as `"nil"`.
---
--- A single type may be given as a bare string rather than a one-element array. An empty
--- `match` array has nothing to intercept, so `main_fn` is returned as-is without wrapping.
---
--- ```lua
--- local describe = overload(
---     function( ... ) return "generic" end,
---     { "string", "number" },
---     function( str, num ) return "string + number" end
--- )
---
--- describe( "a", 1 )   --> "string + number"  (types and count match: overload_fn)
--- describe( "a" )      --> "generic"           (argument count differs: main_fn)
--- describe( 1, "a" )   --> "generic"           (order matters, types differ: main_fn)
--- ```
---
---@generic F: function
---@param main_fn F The default function, called for any arguments that don't match `match`.
---@param match string[] | string The Lua type name (or ordered list of type names) the arguments must have for `overload_fn` to be used.
---@param overload_fn function The function called instead of `main_fn` when the arguments match `match`.
---@return F overloaded_fn A function that dispatches to `overload_fn` or `main_fn` depending on its arguments. If `match` is an empty array, this is `main_fn` itself.
---@nodiscard
function overload(main_fn, match, overload_fn) end

--- [SHARED AND MENU]
---
--- Prints the given arguments to the console.
---
---@param ... any The arguments to print.
function print(...) end

--- [SHARED AND MENU]
---
--- Prints a formatted string to the console.
---
--- Basically the same as `print( string.format( fmt, ... ) )`
---
---@param fmt string The format string.
---@param ... any The arguments to format/interpolate.
function printf(fmt, ...) end

--- [SHARED AND MENU]
---
--- Prints the contents of a table to the engine console as a colorized, indented,
--- pseudo-Lua literal, recursing into any nested tables.
---
--- String keys are printed as escaped bare keys, non-string keys are printed as `[ key ]`,
--- and values are rendered with `represent`.
---
--- Nested tables are expanded as `{ ... }` blocks and indented one level deeper for each
--- level of nesting; if a nested table has already been visited higher up the current
--- branch (a cycle back to an ancestor, including `tbl` itself), it is printed inline
--- followed by a `-- RECURSION` comment instead of being expanded again.
---
--- If expanding a nested table would exceed `max_depth`, it is likewise printed inline
--- followed by a `-- TOO DEEP` comment instead of being walked further.
---
---@param tbl table The table to print the contents of.
---@param max_depth integer | nil The maximum depth of nested tables to recurse into. Defaults to `8`.
function printTable(tbl, max_depth) end

--- [SHARED AND MENU]
---
--- Calls the `fn` function after `delay` seconds.
---
--- **Usage example:**
---
--- ```lua
--- setTimeout( function()
---     print( "Hello, world!" )
--- end, 5 ) -- Calls the function after 5 seconds.
--- ```
---
---@param fn function The callback function.
---@param delay? number The delay in seconds, default is `0`.
---@param ... any Additional arguments to pass to the callback function.
---@return integer timeout_id The identifier of the timeout, used to cancel it with `clearTimeout`.
function setTimeout(fn, delay, ...) end

--- [SHARED AND MENU]
---
--- Cancels a timeout created by `setTimeout`, so its callback will not be called.
---
--- **Usage example:**
---
--- ```lua
--- local timeout_id = setTimeout( function()
---     print( "This will never be printed." )
--- end, 5 )
---
--- clearTimeout( timeout_id )
--- ```
---
---@param timeout_id integer The identifier of the timeout returned by `setTimeout`.
---@return boolean is_cleared Returns `true` if the timeout was found and cancelled, otherwise `false`.
function clearTimeout(timeout_id) end

--- [SHARED AND MENU]
---
--- Calls the `fn` function every `delay` seconds, until the interval is cancelled with `clearInterval`.
---
--- **Usage example:**
---
--- ```lua
--- local interval_id = setInterval( function()
---     print( "Hello, world!" )
--- end, 1 ) -- Calls the function every second.
---
--- setTimeout( function()
---     clearInterval( interval_id )
--- end, 5 ) -- Stops it after 5 seconds.
--- ```
---
---@param fn function The callback function.
---@param delay? number The delay between calls in seconds, default is `1`.
---@param ... any Additional arguments to pass to the callback function.
---@return integer interval_id The identifier of the interval, used to cancel it with `clearInterval`.
function setInterval(fn, delay, ...) end

--- [SHARED AND MENU]
---
--- Cancels an interval created by `setInterval`, so its callback will not be called anymore.
---
--- **Usage example:**
---
--- ```lua
--- local interval_id = setInterval( function()
---     print( "Hello, world!" )
--- end, 1 )
---
--- clearInterval( interval_id )
--- ```
---
---@param interval_id integer The identifier of the interval returned by `setInterval`.
---@return boolean is_cleared Returns `true` if the interval was found and cancelled, otherwise `false`.
function clearInterval(interval_id) end

--- [SHARED AND MENU]
---
--- Puts current thread to sleep for given amount of seconds.
---
--- **CAUTION**: This function could pause the main thread.
---
---@see futures.sleep
---@param seconds number
function sleep(seconds) end

--- [SHARED AND MENU]
---
--- A collection of cryptographic utilities.
---
---@class crypto
crypto = {}

--- The country code of the operating system. (ISO 3166-1 alpha-2)
---
---@type string
SYSTEM_COUNTRY = nil

--- `true` if the operating system has a battery, `false` if not.
---
---@type boolean
SYSTEM_HAS_BATTERY = nil

--- The battery level, from `0` to `100`.
---
---@type garrysmod.system.BatteryPower
SYSTEM_BATTERY_LEVEL = nil

--- [SHARED AND MENU]
---
--- Calls the ISO C function exit to terminate the host program.
---
function os.exit() end

--- [SHARED AND MENU]
---
--- Loads a string as
--- a bytecode chunk in the specified environment
--- and returns function as a compile result.
---
---@param bytecode string The luajit bytecode chunk.
---@param env table | nil The environment of compiled function.
---@return function | nil fn The compiled function.
---@return string | nil msg The error message.
---@nodiscard
function loadbytecode(bytecode, env) end

--- [SHARED AND MENU]
---
---
---
---@param package_name string
---@param package_version string
---@return any
function import(package_name, package_version) end

--- [SHARED AND MENU]
---
--- Opens the named file and executes its content as a Lua chunk.
---
--- When called without arguments, `dofile` executes the content of the standard input (`stdin`).
---
--- Returns all values returned by the chunk. In case of errors, `dofile` propagates the error to its caller. (That is, `dofile` does not run in protected mode.)
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-dofile)
---
---@param file_path string
---@param ... any
---@return any ...
function dofile(file_path, ...) end

--- [SHARED AND MENU]
---
--- Loads the given module, returns any value returned by the searcher(`true` when `nil`). Besides that value, also returns as a second result the loader data returned by the searcher, which indicates how `require` found the module. (For instance, if the module came from a file, this loader data is the file path.)
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-require)
---
---@param modname string
---@param ... any
---@return ...
function require(modname, ...) end
