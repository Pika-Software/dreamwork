---@meta _


--- [SHARED AND MENU]
---
--- Command-line arguments of Lua Standalone.
---
--- `arg[0]` is the script name, `arg[1]`, `arg[2]`, ... are the arguments passed to the
--- script, and negative indices hold the interpreter and its options (`arg[-1]` is the
--- interpreter itself). The same values are also passed to the main chunk as `...`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-arg)
---
---@type string[]
arg = {}

--- [SHARED AND MENU]
---
--- Raises an error if the value of its argument v is false (i.e., `nil` or `false`); otherwise, returns all its arguments. In case of error, `message` is the error object; when absent, it defaults to `"assertion failed!"`
---
--- Since all arguments are returned on success, it can wrap calls that return a value plus
--- an error message, e.g. `local file = assert( io.open( path ) )`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-assert)
---
---@generic T
---@param v? T The value to check.
---@param message? any The error object raised when `v` is falsy. Defaults to `"assertion failed!"`.
---@param ... any Extra values, returned unchanged after `v` and `message` when the assertion passes.
---@return T
---@return any ...
function assert( v, message, ... ) end

--- [SHARED AND MENU]
---
--- This function is a generic interface to the garbage collector. It performs different functions according to its first argument, opt:
---
--- * `"collect"`: performs a full garbage-collection cycle. This is the default option.
--- * `"stop"`: stops the garbage collector.
--- * `"restart"`: restarts the garbage collector.
--- * `"count"`: returns the total memory in use by Lua (in Kbytes).
--- * `"step"`: performs a garbage-collection step. The step "size" is controlled by arg (larger values mean more steps) in a non-specified way. If you want to control the step size you must experimentally tune the value of arg. Returns true if the step finished a collection cycle.
--- * `"setpause"`: sets arg as the new value for the pause of the collector (see [§2.10](http://www.lua.org/manual/5.1/manual.html#2.10)). Returns the previous value for pause.
--- * `"setstepmul"`: sets arg as the new value for the step multiplier of the collector (see [§2.10](http://www.lua.org/manual/5.1/manual.html#2.10)). Returns the previous value for step.
---
--- `"count"` returns a fractional number, so multiply by `1024` for bytes.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-collectgarbage)
---
---@overload fun( opt: "collect" )
---@overload fun( opt: "stop" )
---@overload fun( opt: "restart" )
---@overload fun( opt: "count" ): number
---@overload fun( opt: "step", arg: integer ): boolean
---@overload fun( opt: "setpause", arg: integer ): integer
---@overload fun( opt: "setstepmul", arg: integer ): integer
function collectgarbage( ... ) end

--- [SHARED AND MENU]
---
--- Opens the named file and executes its content as a Lua chunk. When called without arguments, `dofile` executes the content of the standard input (`stdin`). Returns all values returned by the chunk. In case of errors, `dofile` propagates the error to its caller. (That is, `dofile` does not run in protected mode.)
---
--- To load a file without running it, or to handle errors, use `loadfile` instead.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-dofile)
---
---@param filename? string The path of the Lua file to run. Reads from `stdin` when omitted.
---@return any ...
function dofile( filename ) end

--- [SHARED AND MENU]
---
--- Terminates the last protected function called and returns message as the error object.
---
--- Usually, `error` adds some information about the error position at the beginning of the message, if the message is a string.
---
--- The `level` argument specifies how to get the error position. With level `1` (the
--- default), the position is where the `error` function was called. Level `2` points the
--- error to where the function that called `error` was called, and so on. Passing `0`
--- avoids adding position information to the message.
---
--- This function never returns.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-error)
---
---@param message any The error object to raise.
---@param level?  integer Where to point the position information. Defaults to `1`; `0` adds none.
function error( message, level ) end

--- [SHARED AND MENU]
---
--- A global variable (not a function) that holds the global environment (see [§2.2](http://www.lua.org/manual/5.1/manual.html#2.2)). Lua itself does not use this variable; changing its value does not affect any environment, nor vice versa.
---
--- By default it contains a reference to itself (`_G._G == _G`).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-_G)
---
---@class _G
_G = {}

--- [SHARED AND MENU]
---
--- Returns the current environment in use by the function. `f` can be a Lua function or a number that specifies the function at that stack level.
---
--- Level `1` is the function calling `getfenv`. If the given function is not a Lua function, or if `f` is `0`, `getfenv` returns the global environment. The default for `f` is `1`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-getfenv)
---
---@param f? integer|async fun(...):... A Lua function, or a stack level (`1` = the caller). Defaults to `1`.
---@return table env The environment table of the function.
---@version 5.1
---@nodiscard
function getfenv( f ) end

--- [SHARED AND MENU]
---
--- If object does not have a metatable, returns nil.
---
--- Otherwise, if the object's metatable has a `__metatable` field, returns the associated value.
---
--- Otherwise, returns the metatable of the given object.
---
--- Use `debug.getmetatable` to get the real metatable regardless of a `__metatable` field.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-getmetatable)
---
---@param object any The value to get the metatable of.
---@return metatable | table | "ffi" | nil metatable The metatable (or its `__metatable` value), or `nil` if there is none.
---@nodiscard
function getmetatable( object ) end

--- [SHARED AND MENU]
---
--- Returns three values (an iterator function, the table `t`, and `0`) so that the construction
---
--- ```lua
---    for i,v in ipairs(t) do body end
--- ```
---
--- will iterate over the key–value pairs `(1,t[1]), (2,t[2]), ...`, up to the first absent index.
---
--- Because iteration stops at the first `nil`, tables with holes are only walked up to the
--- first gap. Use `pairs` to visit every key.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-ipairs)
---
---@generic T: table, V
---@param t T The table (array) to iterate over.
---@return fun(table: V[], i?: integer):integer, V
---@return T
---@return integer i
function ipairs( t ) end

---@alias loadmode
---| "b"  # Only binary chunks.
---| "t"  # Only text chunks.
---|>"bt" # Both binary and text.

--- [SHARED AND MENU]
---
--- Loads a chunk.
---
--- If `chunk` is a string, the chunk is this string. If `chunk` is a function, `load` calls it repeatedly to get the chunk pieces. Each call to `chunk` must return a string that concatenates with previous results. A return of an empty string, `nil`, or no value signals the end of the chunk.
---
--- If there are no syntactic errors, returns the compiled chunk as a function; otherwise, returns `nil` plus the error message. The chunk is only compiled, not run: call the returned function to execute it.
---
--- `chunkname` is used as the chunk name in error messages and debug information. `mode` controls whether the chunk may be text, binary, or both, and `env` sets the environment the chunk runs in.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-load)
---
---@param chunk      string | function The source string, or a function returning the source in pieces.
---@param chunkname? string The name of the chunk, used in error messages and debug info.
---@param mode?      loadmode Which kinds of chunks to accept. Defaults to `"bt"`.
---@param env?       table The environment for the loaded chunk.
---@return function? chunk The compiled chunk, or `nil` on a syntax error.
---@return string?   error_message The error message when compilation fails.
---@nodiscard
function load( chunk, chunkname, mode, env ) end

--- [SHARED AND MENU]
---
--- Loads a chunk from file `filename` or from the standard input, if no file name is given.
---
--- Like `load`, it only compiles the file and returns it as a function (or `nil` plus an error message, including when the file can't be opened). It does not run the chunk; use `dofile` to run a file directly.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-loadfile)
---
---@param filename? string The path of the file to load. Reads from `stdin` when omitted.
---@param mode?     loadmode Which kinds of chunks to accept. Defaults to `"bt"`.
---@param env?      table The environment for the loaded chunk.
---@return function? chunk The compiled chunk, or `nil` on failure.
---@return string?  error_message The error message when loading fails.
---@nodiscard
function loadfile( filename, mode, env ) end

--- [SHARED AND MENU]
---
--- Loads a chunk from the given string.
---
--- Similar to `load`, but only accepts a string. Returns the compiled chunk as a function, or `nil` plus an error message on a syntax error. The chunk is not run. If `chunkname` is omitted, the string itself is used as the chunk name. Deprecated in Lua 5.2 in favor of `load`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-loadstring)
---
---@param text       string The Lua source to compile.
---@param chunkname? string The name of the chunk, used in error messages and debug info.
---@return function? chunk The compiled chunk, or `nil` on a syntax error.
---@return string?   error_message The error message when compilation fails.
---@version 5.1
---@nodiscard
function loadstring( text, chunkname ) end

--- [SHARED AND MENU]
---
--- Creates a new userdata with no data and, optionally, a metatable. An undocumented function that exists in Lua 5.1 and LuaJIT.
---
--- * If `proxy` is `true`, the new userdata gets a fresh, empty metatable (reachable through `getmetatable`) that you can fill in.
--- * If `proxy` is another userdata created by `newproxy`, the new userdata shares its metatable.
--- * If `proxy` is `false` or `nil`, the new userdata has no metatable.
---
--- Mostly used to attach a `__gc` finalizer to a table-like object in Lua 5.1, where `__gc` on tables is not honored.
---
---@param proxy boolean|table|userdata `true` for a new metatable, a proxy userdata to share its metatable, or `false`/`nil` for none.
---@return userdata proxy The new userdata.
---@version 5.1
---@nodiscard
function newproxy( proxy ) end

--- [SHARED AND MENU]
---
--- Creates a module.
---
--- If there is a table in `package.loaded[name]`, it is the module. Otherwise, a new table is created, set as the value of the global `name` and of `package.loaded[name]`, and it becomes the environment of the calling function, so global declarations inside the file go into the module.
---
--- Each extra argument is an option function (such as `package.seeall`) called with the module as its argument. Deprecated in Lua 5.2.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-module)
---
---@param name string The name of the module.
---@param ...  any Option functions applied to the module, e.g. `package.seeall`.
---@version 5.1
function module( name, ... ) end

--- [SHARED AND MENU]
---
--- Allows a program to traverse all fields of a table. Its first argument is a table and its second argument is an index in this table. A call to `next` returns the next index of the table and its associated value. When called with `nil` as its second argument, `next` returns an initial index and its associated value. When called with the last index, or with `nil` in an empty table, `next` returns `nil`. If the second argument is absent, then it is interpreted as `nil`. In particular, you can use `next(t)` to check whether a table is empty.
---
--- The order in which the indices are enumerated is not specified, *even for numeric indices*. (To traverse a table in numerical order, use a numerical `for`.)
---
--- The behavior of `next` is undefined if, during the traversal, you assign any value to a non-existent field in the table. You may however modify existing fields. In particular, you may set existing fields to nil.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-next)
---
---@generic K, V
---@param table table<K, V> The table to traverse.
---@param index? K The previous key, or `nil` to start from the beginning.
---@return K? key The next key, or `nil` when the traversal is finished.
---@return V? value The value stored at `key`.
---@nodiscard
function next( table, index ) end

--- [SHARED AND MENU]
---
--- If `t` has a metamethod `__pairs`, calls it with t as argument and returns the first three results from the call.
---
--- Otherwise, returns three values: the [next](http://www.lua.org/manual/5.1/manual.html#pdf-next) function, the table `t`, and `nil`, so that the construction
---
--- ```lua
---    for k,v in pairs(t) do body end
--- ```
---
--- will iterate over all key–value pairs of table `t`.
---
--- See function [next](http://www.lua.org/manual/5.1/manual.html#pdf-next) for the caveats of modifying the table during its traversal.
---
--- **NOTE**: the `__pairs` metamethod comes from Lua 5.2. Plain Lua 5.1 ignores it, and LuaJIT only honors it when built with 5.2 compatibility.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-pairs)
---
---@generic T: table, K, V
---@param t T The table to iterate over.
---@return fun(table: table<K, V>, index?: K):K, V
---@return T
function pairs( t ) end

--- [SHARED AND MENU]
---
--- Calls the function `f` with the given arguments in *protected mode*. This means that any error inside `f` is not propagated; instead, `pcall` catches the error and returns a status code. Its first result is the status code (a boolean), which is true if the call succeeds without errors. In such case, `pcall` also returns all results from the call, after this first result. In case of any error, `pcall` returns `false` plus the error object.
---
--- The stack has already unwound by the time `pcall` returns, so a traceback can't be taken afterwards. Use `xpcall` with a message handler when you need one.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-pcall)
---
---@generic T: any, A: any
---@param f     async fun( ...: A ): ...: T The function to call in protected mode.
---@param ...   A The arguments passed to `f`.
---@return boolean success `true` if `f` ran without errors.
---@return T | string result The first result of `f`, or the error object when `success` is `false`.
---@return T ...
function pcall( f, arg1, ... ) end

--- [SHARED AND MENU]
---
--- Receives any number of arguments and prints their values to `stdout`, converting each argument to a string following the same rules of [tostring](http://www.lua.org/manual/5.1/manual.html#pdf-tostring).
---
--- The function print is not intended for formatted output, but only as a quick way to show a value, for instance for debugging. For complete control over the output, use [string.format](http://www.lua.org/manual/5.1/manual.html#pdf-string.format) and [io.write](http://www.lua.org/manual/5.1/manual.html#pdf-io.write).
---
--- Arguments are separated by tabs and the output ends with a newline.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-print)
---
---@param ... any The values to print.
function print( ... ) end

--- [SHARED AND MENU]
---
--- Checks whether v1 is equal to v2, without invoking the `__eq` metamethod.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawequal)
---
---@param v1 any The first value.
---@param v2 any The second value.
---@return boolean equal `true` if the two values are primitively equal.
---@nodiscard
function rawequal( v1, v2 ) end

--- [SHARED AND MENU]
---
--- Gets the real value of `table[index]`, without invoking the `__index` metamethod.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawget)
---
---@param table table The table to read from.
---@param index any The key to look up.
---@return any value The value stored at `index`, or `nil` if the key is absent.
---@nodiscard
function rawget( table, index ) end

--- [SHARED AND MENU]
---
--- Returns the length of the object `v`, without invoking the `__len` metamethod.
---
--- **NOTE**: `rawlen` comes from Lua 5.2 and isn't present in plain Lua 5.1.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawlen)
---
---@param v table|string The table or string to measure.
---@return integer len The raw length of `v`.
---@nodiscard
function rawlen( v ) end

--- [SHARED AND MENU]
---
--- Sets the real value of `table[index]` to `value`, without using the `__newindex` metavalue. `table` must be a table, `index` any value different from `nil` and `NaN`, and `value` any Lua value.
---
--- This function returns `table`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-rawset)
---
---@param table table The table to modify.
---@param index any The key to set (not `nil` or `NaN`).
---@param value any The value to store.
---@return table table The given `table`.
function rawset( table, index, value ) end

--- [SHARED AND MENU]
---
--- If `index` is a number, returns all arguments after argument number `index`;
---
--- a negative number indexes from the end (`-1` is the last argument).
---
--- Otherwise, `index` must be the string `"#"`, and `select` returns the total number of extra arguments it received.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-select)
---
---@generic T: any
---@param index integer The position to start from, or `"#"` to get the argument count.
---@param ... T The arguments to select from.
---@return T ...
---@overload fun( parameter: "#", ...: T ): integer
---@overload fun( parameter: integer, ...: T ): ...: T
---@nodiscard
function select( index, ... ) end

--- [SHARED AND MENU]
---
--- Sets the environment to be used by the given function.
---
--- `f` can be a Lua function or a number that specifies the function at that stack level: level `1` is the function calling `setfenv`. `setfenv` returns the given function.
---
--- As a special case, when `f` is `0`, `setfenv` changes the environment of the running thread, and returns no values in that case.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-setfenv)
---
---@param f ( async fun( ...: any ): ...: any ) | integer A Lua function, or a stack level (`1` = the caller, `0` = the running thread).
---@param table table The new environment table.
---@return function f The given function.
---@version 5.1
function setfenv( f, table ) end

do

    --- [SHARED AND MENU]
    ---
    --- Lists every metafield recognized by Lua itself (`__index`, `__add`, `__call`, ...)
    --- along with the extra ones dreamwork's standard library looks for (`__type`,
    --- `__represent`, `__copy`, `__hash`, ...). All of them are optional; define only the
    --- ones an object needs.
    ---
    ---@class metatable<K, V>
    local metatable = {}

    ---
    --- Human-readable type name.
    ---
    --- Changes the behavior of `type( value )` and `tostring( value )`.
    ---
    ---@type string?
    metatable.__type = nil

    ---
    --- Legacy type name, read from the metatables of engine-provided userdata by some
    --- systems.
    ---
    --- Kept for compatibility; use `__type` instead.
    ---
    --- **DO NOT USE THIS**
    ---
    ---@type string?
    metatable.MetaName = nil

    ---
    --- Legacy numeric type identifier, read from the metatables of engine-provided
    --- userdata by some systems.
    ---
    --- Kept for compatibility; use `__type` instead.
    ---
    --- **DO NOT USE THIS**
    ---
    ---@type integer?
    metatable.MetaID = nil

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
    metatable.__mode = nil

    ---
    --- Protects the metatable, changing the behavior of `getmetatable( value )`.
    ---
    --- If object does not have a metatable, returns nil.
    ---
    --- Otherwise, if the object's metatable has a `__metatable` field, returns the associated value.
    ---
    --- Otherwise, returns the metatable of the given object.
    ---
    --- `setmetatable` also raises an error on objects whose metatable defines this field.
    --- `debug.getmetatable` and `debug.setmetatable` ignore it.
    ---
    ---@type any
    metatable.__metatable = nil

    ---
    --- A name for the object's type, as a string.
    ---
    --- Used internally (for example by `luaL_newmetatable` for userdata) and in error
    --- messages, and by `tostring( value )` when the `__tostring` metamethod is missing.
    ---
    --- See [`luaL_newmetatable`](https://www.lua.org/manual/5.4/manual.html#luaL_newmetatable)
    ---
    ---@type string | nil
    metatable.__name = nil

    ---
    --- Converts the object into a string.
    ---
    --- If the metatable of `v` has a `__tostring` field,
    --- then tostring calls the corresponding value with `v` as the argument,
    --- and uses the result of the call as its result.
    ---
    --- Otherwise, if the metatable of `v` has a `__name` field with a string value,
    --- tostring may use that string in its final result.
    ---
    ---@type fun( self: any ): string
    metatable.__tostring = nil

    ---
    --- Converts the object into a number.
    ---
    --- `base` is the numeric base requested by the caller, as in `tonumber( value, base )`.
    ---
    ---@type fun( self: any, base: integer ): number | integer
    metatable.__tonumber = nil

    ---
    --- Converts the object into a boolean value.
    ---
    ---@type fun( self: any ): boolean
    metatable.__toboolean = nil

    ---
    --- Converts the object into a color.
    ---
    ---@type fun( self: any ): dreamwork.std.Color
    metatable.__tocolor = nil

    ---
    --- Converts the object into a hexadecimal string.
    ---
    --- Unlike `__hash`, which `std.tohex` uses to build an identifier, this is meant to
    --- return the object's own hexadecimal representation.
    ---
    ---@type fun( self: any ): string
    metatable.__tohex = nil

    ---
    --- Returns a developer-oriented representation of the object.
    ---
    --- This is used by the `represent( value )` function and in the debugger.
    ---
    --- Also this affects `print`-like functions.
    ---
    ---@type fun( self: any ): string
    metatable.__represent = nil

    ---
    --- Called when the the garbage collector detects that the corresponding table or userdata is dead.
    ---
    --- **Important:** In Garry's Mod this metamethod is **not called** for tables, only used for `userdata`.
    ---
    --- See [§2.5.3](https://www.lua.org/manual/5.4/manual.html#2.5.3)
    ---
    ---@type fun( self: any )
    metatable.__gc = nil

    ---
    --- Called when a variable is closed.
    ---
    --- Only exists in Lua 5.4 (to-be-closed variables); it is never called in Lua 5.1 or LuaJIT.
    ---
    --- See [§3.3.8](https://www.lua.org/manual/5.4/manual.html#3.3.8)
    ---
    ---@type fun( self: any, errobj: any ): any
    metatable.__close = nil

    ---
    --- The addition `+` operation.
    ---
    --- `a + b = result`
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__add = nil

    ---
    --- The subtraction `-` operation.
    ---
    --- `a - b = result`
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__sub = nil

    ---
    --- The multiplication `*` operation.
    ---
    --- `a * b = result`
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__mul = nil

    ---
    --- The division `/` operation.
    ---
    --- `a / b = result`
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__div = nil

    ---
    --- The negation/unary `-` operation.
    ---
    --- `-a = result`
    ---
    --- This is equivalent to `a * -1`.
    ---
    ---@generic T
    ---@type fun( self: T ): T
    metatable.__unm = nil

    ---
    --- The modulo `%` operation.
    ---
    --- `a % b = result`
    ---
    --- This is a floored modulo: the result takes the sign of `b`, which differs from
    --- `math.fmod( a, b )`, where the result takes the sign of `a`.
    ---
    --- It is unrelated to `math.modf( a )`, which splits a number into its integral and
    --- fractional parts.
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__mod = nil

    ---
    --- The exponentiation `^` operation.
    ---
    --- `a ^ b = result`
    ---
    --- This is equivalent to `math.pow( a, b )`.
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__pow = nil

    ---
    --- The floor division `//` operation.
    ---
    --- Used by `math.fdiv( a, b )` function.
    ---
    --- The `//` operator itself doesn't exist in Lua 5.1 or LuaJIT, so there this is only
    --- reached through that function.
    ---
    ---@generic T
    ---@type fun( self: T, other: any ): T
    metatable.__idiv = nil

    ---
    --- The bitwise AND `&` operation.
    ---
    --- Used by `bit.band( a, b )` function.
    ---
    --- Lua 5.1 and LuaJIT have no `&` operator, so this is only reached through `bit.band`,
    --- which looks it up on the first argument before falling back to the raw bit operation.
    ---
    ---@generic T
    ---@type fun( self: T, ...: any ): T
    metatable.__band = nil

    ---
    --- The bitwise OR `|` operation.
    ---
    --- Used by `bit.bor( a, b )` function.
    ---
    --- Like `__band`, only reached through the `bit` function on Lua 5.1 and LuaJIT.
    ---
    ---@generic T
    ---@type fun( self: T, ...: any ): T
    metatable.__bor = nil

    ---
    --- The bitwise XOR `~` operation.
    ---
    --- Used by `bit.bxor( a, b )` function.
    ---
    --- Like `__band`, only reached through the `bit` function on Lua 5.1 and LuaJIT.
    ---
    ---@generic T
    ---@type fun( self: T, ...: any ): T
    metatable.__bxor = nil

    ---
    --- The bitwise NOT `~` operation.
    ---
    --- Used by `bit.bnot( a )` function.
    ---
    --- Like `__band`, only reached through the `bit` function on Lua 5.1 and LuaJIT.
    ---
    ---@generic T
    ---@type fun( self: T ): T
    metatable.__bnot = nil

    ---
    --- The left shift `<<` operation.
    ---
    --- Used by `bit.lshift( a, b )` function.
    ---
    --- Like `__band`, only reached through the `bit` function on Lua 5.1 and LuaJIT.
    ---
    ---@generic T
    ---@type fun( self: T, bit_count: integer ): T
    metatable.__shl = nil

    ---
    --- The right shift `>>` operation.
    ---
    --- Used by `bit.rshift( a, b )` function.
    ---
    --- Like `__band`, only reached through the `bit` function on Lua 5.1 and LuaJIT.
    ---
    ---@generic T
    ---@type fun( self: T, bit_count: integer ): T
    metatable.__shr = nil

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
    metatable.__shar = nil

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
    metatable.__brol = nil

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
    metatable.__bror = nil

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
    metatable.__bswp = nil

    ---
    --- The concatenation `..` operation.
    ---
    --- Behavior similar to calculation operators,
    --- except that Lua will try a metamethod if
    --- any operand is neither a string nor a number
    --- (which is always coercible to a string).
    ---
    ---@type fun( self: any, other: any ): string
    metatable.__concat = nil

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
    --- **NOTE**: plain Lua 5.1 only calls this for userdata, never for tables, so `#t` on a
    --- table ignores it there. `len( value )` is the portable way to honor it.
    ---
    --- See [§3.4.7](https://www.lua.org/manual/5.4/manual.html#3.4.7)
    ---
    ---@type fun( self: any ): integer
    metatable.__len = nil

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
    --- In Lua 5.1, the metamethod is only used when both operands have the same `__eq`
    --- function.
    ---
    ---@type fun( self: any, other: any ): boolean
    metatable.__eq = nil

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
    metatable.__lt = nil

    ---
    --- The less equal `<=` operation.
    ---
    --- Behavior similar to the less than operation.
    ---
    --- If this metamethod is absent, Lua 5.1 falls back to `not ( b < a )` using `__lt`.
    ---
    ---@type fun( self: any, other: any ): boolean
    metatable.__le = nil

    ---
    --- The indexing access operation `table[key]`.
    ---
    --- This event happens when `table` is not a table or when `key` is not present in `table`.
    ---
    --- The metavalue is looked up in the metatable of `table`.
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
    metatable.__index = nil

    ---
    --- The indexing assignment `table[key] = value`.
    ---
    --- Like the index event, this event happens when `table` is not a table or when `key` is not present in `table`.
    ---
    --- The metavalue is looked up in the metatable of `table`.
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
    metatable.__newindex = nil

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
    metatable.__call = nil

    ---
    --- Affects iteration when using the `pairs()` function, letting you define a custom iterator function (see [`pairs()`](https://www.lua.org/manual/5.4/manual.html#pdf-pairs), [`next()`](https://www.lua.org/manual/5.4/manual.html#pdf-next)).
    ---
    --- Plain Lua 5.1 ignores this field, and LuaJIT only honors it when built with Lua 5.2
    --- compatibility.
    ---
    ---@generic K, V
    ---@type fun( self: table<K, V> ): fun( tbl: table<K, V>, key: ( K | nil ) ): ( K | nil ), ( V | nil )
    metatable.__pairs = nil

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
    metatable.__copy = nil

    ---
    --- Serializes the object into a writer.
    ---
    --- Writes the object's state into `writer`; any extra arguments come from the caller of
    --- the serializer. The counterpart of `__deserialize`.
    ---
    ---@type fun( self: any, writer: dreamwork.std.BinaryWriter, ...: any? )
    metatable.__serialize = nil

    ---
    --- Deserializes the object from a reader.
    ---
    --- Reads the object's state back from `reader`, mirroring what `__serialize` wrote.
    ---
    ---@type fun( self: any, reader: dreamwork.std.BinaryReader, ...: any? )
    metatable.__deserialize = nil

    ---
    --- Checks whether the object is valid, for example that it hasn't been removed or
    --- destroyed.
    ---
    ---@type fun( self: any ): boolean
    metatable.__isvalid = nil

    ---
    --- Returns a stable hash value for the object.
    ---
    --- `std.tohex( value )` uses it to build the value's identifier: the returned integer is
    --- formatted as hexadecimal, instead of falling back to the value's memory address.
    ---
    ---@type fun( self: any ): integer
    metatable.__hash = nil

    ---
    --- Returns binary size of the `object` as integer of bit/bytes.
    ---
    --- Returns the size in bytes when `as_bytes` is `true`, or in bits when it is `false`.
    ---
    ---@type fun( self: any, as_bytes: boolean ): integer
    metatable.__sizeof = nil

end

--- [SHARED AND MENU]
---
--- Sets the metatable for the given table.
---
--- If `metatable` is `nil`, removes the metatable of the given table.
---
--- If the original metatable has a `__metatable` field, raises an error.
---
--- This function returns `table`.
---
--- To change the metatable of other types from Lua code, you must use the debug library ([§6.10](http://www.lua.org/manual/5.4/manual.html#6.10)).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-setmetatable)
---
---@generic K, V
---@param tbl table<K, V> The table to set the metatable of.
---@param metatable? metatable<K, V> The new metatable, or `nil` to remove it.
---@return metatable<K, V> table The given `table`.
function setmetatable( tbl, metatable ) end

--- [SHARED AND MENU]
---
--- Tries to convert its argument to a number. If the argument is already a number or a string convertible to a number, then `tonumber` returns this number; otherwise, it returns `nil`.
---
--- Without `base`, the string may have leading and trailing spaces and a sign, and follows the lexical conventions of Lua (see [§2.1](http://www.lua.org/manual/5.1/manual.html#2.1)), so decimal fractions, exponents and hexadecimal (`0x`) are accepted.
---
--- With `base` (from `2` to `36`), the string must be an integer numeral in that base, where the letters `A`-`Z` (case-insensitive) stand for the digits `10` to `35`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-tonumber)
---
---@param e any The value to convert.
---@return number? number The converted number, or `nil` if it can't be converted.
---@overload fun( e: string, base: numberbase ): integer?
---@nodiscard
function tonumber( e ) end

--- [SHARED AND MENU]
---
--- Receives a value of any type and converts it to a string in a human-readable format.
---
--- If the metatable of `v` has a `__tostring` field, then `tostring` calls the corresponding value with `v` as argument, and uses the result of the call as its result. Otherwise, if the metatable of `v` has a `__name` field with a string value, `tostring` may use that string in its final result.
---
--- For complete control of how numbers are converted, use [string.format](http://www.lua.org/manual/5.1/manual.html#pdf-string.format).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-tostring)
---
---@param v any The value to convert.
---@return string str The string representation of `v`.
---@nodiscard
function tostring( v ) end

---@alias type
---| "nil"
---| "number"
---| "integer"
---| "string"
---| "boolean"
---| "table"
---| "function"
---| "thread"
---| "userdata"
---| "cdata"
---| "ffi"
---| string

--- [SHARED AND MENU]
---
--- Returns the type of its only argument, coded as a string. The possible results of this function are `"nil"` (a string, not the value `nil`), `"number"`, `"string"`, `"boolean"`, `"table"`, `"function"`, `"thread"`, and `"userdata"`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-type)
---
---@param v any The value to get the type of.
---@return type type The name of the value's type.
---@nodiscard
function type( v ) end

--- [SHARED AND MENU]
---
--- A global variable (not a function) that holds a string containing the running Lua version.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-_VERSION)
---
_VERSION = "Lua 5.1"

--- [SHARED AND MENU]
---
--- Emits a warning with a message composed by the concatenation of all its arguments (which should be strings).
---
--- Only exists in Lua 5.4; it isn't available in Lua 5.1 or LuaJIT.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-warn)
---
---@param message string The first part of the warning message.
---@param ...     any Further parts, concatenated onto the message.
---@version >5.4
function warn( message, ... ) end

--- [SHARED AND MENU]
---
--- Calls function `f` with the given arguments in protected mode with a new message handler.
---
--- Works like `pcall`, but if an error occurs, `msgh` is called with the original error object *at the point of the error*, before the stack unwinds. That makes it the place to take a traceback, e.g. `xpcall( f, debug.traceback )`. The value `msgh` returns is what `xpcall` returns as the error.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-xpcall)
---
---@param f     async fun(...):... The function to call in protected mode.
---@param msgh  function The message handler, called with the error object when an error occurs.
---@param arg1? any The first argument passed to `f`. Extra arguments need LuaJIT or Lua 5.2+.
---@param ...   any Further arguments passed to `f`.
---@return boolean success `true` if `f` ran without errors.
---@return any result The first result of `f`, or the value returned by `msgh` on error.
---@return any ...
function xpcall( f, msgh, arg1, ... ) end

--- [SHARED AND MENU]
---
--- Returns the elements from the given `list`. This function is equivalent to
---
--- ```lua
---    return list[i], list[i+1], ···, list[j]
--- ```
---
--- By default, `i` is `1` and `j` is the length of the list, as defined by the length operator. In Lua 5.2 and later this function moved to `table.unpack`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-unpack)
---
---@generic T1, T2, T3, T4, T5, T6, T7, T8, T9, T10
---@param list {
--- [1]?: T1,
--- [2]?: T2,
--- [3]?: T3,
--- [4]?: T4,
--- [5]?: T5,
--- [6]?: T6,
--- [7]?: T7,
--- [8]?: T8,
--- [9]?: T9,
--- [10]?: T10,
---}
---@param i?   integer The index of the first element to return. Defaults to `1`.
---@param j?   integer The index of the last element to return. Defaults to `#list`.
---@return T1, T2, T3, T4, T5, T6, T7, T8, T9, T10
---@version 5.1
---@nodiscard
function unpack( list, i, j ) end

--- [SHARED AND MENU]
---
--- Returns all the elements of `list` from index `1` to its length, as separate values. Shorthand for calling `unpack` without the `i` and `j` arguments.
---
---@generic T1, T2, T3, T4, T5, T6, T7, T8, T9
---@param list {[1]: T1, [2]: T2, [3]: T3, [4]: T4, [5]: T5, [6]: T6, [7]: T7, [8]: T8, [9]: T9 } The array to unpack.
---@return T1, T2, T3, T4, T5, T6, T7, T8, T9
---@version 5.1
---@nodiscard
function unpack( list ) end
