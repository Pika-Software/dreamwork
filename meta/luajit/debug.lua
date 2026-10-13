---@meta debug

--- [SHARED AND MENU]
---
--- The debug library. Provides the functionality of the Lua debug interface: inspecting
--- the call stack, locals, upvalues and metatables, and installing hooks.
---
--- **NOTE**: Use with care. Several of these functions (`debug.setmetatable`,
--- `debug.setfenv`, `debug.setupvalue`, `debug.upvaluejoin`, ...) bypass the normal
--- language safeguards, such as `__metatable` protection and closure encapsulation, and
--- can easily break code that doesn't expect it.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug)
---
---@class debuglib
debug = {}


--- [SHARED AND MENU]
---
--- Enters an interactive mode with the user, running each string that the user enters.
---
--- Each line read from standard input is compiled and executed in turn. The mode ends when
--- the user enters a line containing only `cont`, or on end of input; the program then
--- resumes. Commands entered here aren't lexically nested inside any function, so they
--- have no direct access to local variables.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.debug)
---
function debug.debug() end

--- [SHARED AND MENU]
---
--- Returns the environment of object `o`.
---
--- The environment is the table used to resolve global names for a function, or the
--- environment table associated with a userdata or thread.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getfenv)
---
---@param o any The object to get the environment of.
---@return table env The environment table of `o`.
---@version 5.1
---@nodiscard
function debug.getfenv( o ) end

--- [SHARED AND MENU]
---
--- Returns the current hook settings of the thread, as three values: the current hook
--- function, the current hook mask, and the current hook count, as set by `debug.sethook`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.gethook)
---
---@param co? thread The thread to inspect. Defaults to the running thread.
---@return function hook The current hook function.
---@return string mask The current hook mask (any combination of `c`, `r` and `l`).
---@return integer count The current hook count (`0` if no count hook is set).
---@nodiscard
function debug.gethook( co ) end

--- [SHARED AND MENU]
---
--- Specifies what information to retrieve from `debug.getinfo`.
---
--- Each letter selects a group of fields to populate on the returned
--- `debuginfo` table; unrequested fields are left `nil`.
---
--- Multiple letters can be combined in a single string (e.g. `"nSl"`).
---
---@alias infowhat string
---|+"f" # Function value. Fills `func`.
---|+"l" # Current line. Fills `currentline`.
---|+"L" # Active lines. Fills `activelines`.
---|+"n" # Name info. Fills `name` and `namewhat`.
---|+"S" # Source info. Fills `source`, `short_src`, `linedefined`, `lastlinedefined`, and `what`.
---|+"u" # Upvalue/parameter info. Fills `nups`, `nparams`, and `isvararg`.
---|+">" # LuaJIT extension; causes this function to use the last argument to get the data from, instead of treating it as a stack level; the function value is popped/consumed in the process. No fields of its own — combine with other letters (e.g. `">S"`).

--- [SHARED AND MENU]
---
--- Contains information about a function, as returned by `debug.getinfo`.
---
--- Which fields are populated depends on the `what` option string passed to
--- `debug.getinfo` (see `infowhat`); fields that weren't requested are `nil`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#lua_Debug)
---
---@class debuginfo
---@field name             string | nil  The name of the function, if a reasonable name can be found. Only valid when `what` includes `"n"`.
---@field namewhat         string | nil  Explains the `name` field. Its value may be `"global"`, `"local"`, `"method"`, `"field"`, `"upvalue"`, or `""` (the empty string) when no other option applies.
---@field source           string | nil  The source of the chunk that created the function. If it starts with `@`, the function was defined in a file whose name follows the `@`. If it starts with `=`, the remainder describes the source in a user-dependent manner. Otherwise, the function was defined in a string equal to `source`.
---@field short_src        string | nil  A "printable" version of `source`, to be used in error messages.
---@field linedefined      integer | nil The line number where the definition of the function starts.
---@field lastlinedefined  integer | nil The line number where the definition of the function ends.
---@field what             "Lua" | "C" | "main" | nil  The type of the function: `"Lua"` if it's a normal Lua function, `"C"` if it's a C function, `"main"` if it's the main part of a chunk.
---@field currentline      integer | nil The current line where the given function is executing. -1 when no line information is available.
---@field nups             integer | nil The number of upvalues of the function.
---@field nparams          integer | nil The number of fixed parameters of the function (always 0 for C functions).
---@field isvararg         boolean | nil `true` if the function is a vararg function (always `true` for C functions).
---@field func             function | nil The function itself. Only valid when `what` includes `"f"`.
---@field activelines      table<integer, ( true | nil )> | nil A set whose keys are the line numbers with associated code (i.e. valid lines for breakpoints); each present key maps to `true`. Only valid when `what` includes `"L"`.

--- [SHARED AND MENU]
---
--- Returns a table with information about a function. You can give the
--- function directly, or you can give a number as the value of `location`, which
--- means the function running at level `location` of the call stack of the given
--- thread: level 0 is the current function (`getinfo` itself); level 1 is
--- the function that called `getinfo` (except for tail calls, which do not
--- count on the stack); and so on. If `location` is a number larger than the
--- number of active functions, then `getinfo` returns `nil`.
---
--- The parameter `what` (a string) controls which fields of the returned
--- table are filled in — see `infowhat` for the list of letters and what each one
--- populates. The default (when `what` is omitted) is to get all information, except the
--- table of active lines (equivalent to `"flnSu"`).
---
--- If the option `"f"` is given, then `func` is set with the function
--- itself. If the option `"L"` is given, then `activelines` is set with
--- the table of active lines.
---
--- If `what` contains the `">"` modifier, `location` is
--- consumed as the value to inspect and treated as if it were passed via
--- the trailing argument rather than as a stack level — this lets you
--- write `debug.getinfo(thread, level, ">S")`-style calls where the
--- object being inspected is taken from the end of the argument list. See
--- the `">"` entry in `infowhat` for details.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getinfo)
---
---@param thread thread The thread whose call stack to inspect. Defaults to the running thread when omitted (see the overloads).
---@param location integer | async fun(...): ... A function to inspect, or a call stack level (`0` = `getinfo` itself, `1` = the caller of `getinfo`, ...).
---@param what? infowhat Which groups of fields to fill in. Defaults to `"flnSu"`.
---@param f function? The function to inspect when `what` contains the `">"` modifier.
---@return debuginfo info The info for the given location, or `nil` if no info could be retrieved.
---@overload fun( location: function, what: infowhat?, f: function? ): debuginfo
---@overload fun( location: integer, what: infowhat?, f: function? ): debuginfo | nil
---@overload fun( thread: thread, location: function, what: infowhat?, f: function? ): debuginfo
---@overload fun( thread: thread, location: integer, what: infowhat?, f: function? ): debuginfo | nil
---@nodiscard
function debug.getinfo( thread, location, what, f ) end

--- [SHARED AND MENU]
---
--- Returns the name and the value of the local variable with index `index` of the function
--- at level `f` of the stack.
---
--- The first parameter or local variable has index `1`, and so on, until the last active
--- local variable. Returns `nil` if there is no local variable with the given index, and
--- raises an error when called with a level out of range (use `debug.getinfo` to check
--- whether the level is valid).
---
--- If `f` is a function rather than a stack level, only the names of the function's
--- parameters are returned (without values), on runtimes that support this form.
---
--- Variable names starting with `(` represent internal variables (loop control variables,
--- temporaries, and C function locals).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getlocal)
---
---@param thread  thread The thread whose stack to inspect. Defaults to the running thread when omitted (see the overloads).
---@param f       integer | async fun(...):... The stack level (`1` = the function that called `getlocal`) or function to inspect.
---@param index   integer The index of the local variable, starting at `1`.
---@return string name The name of the local variable.
---@return any    value The current value of the local variable.
---@overload fun( stack_level: integer, index: integer ): string, any
---@overload fun( thread: thread, stack_level: integer, index: integer ): string, any
---@overload fun(f: integer|async fun(...):..., index: integer):string, any
---@nodiscard
function debug.getlocal( thread, f, index ) end

--- [SHARED AND MENU]
---
--- Returns the metatable of the given value, or `nil` if it doesn't have one.
---
--- Unlike the standard `getmetatable`, this ignores the `__metatable` field, so it can
--- reach metatables that are protected from normal code.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getmetatable)
---
---@param object any The value to get the metatable of.
---@return table metatable The metatable of `object`, or `nil` if it has none.
---@nodiscard
function debug.getmetatable( object ) end

--- [SHARED AND MENU]
---
--- Returns the registry table: a pre-defined table that can be used by C code to store
--- whatever Lua values it needs to keep.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getregistry)
---
---@return table registry The registry table.
---@nodiscard
function debug.getregistry() end

--- [SHARED AND MENU]
---
--- Returns the name and the value of the upvalue with index `up` of the function `f`.
---
--- Upvalues are numbered in the order they first appear in the function, starting at `1`.
--- Returns nothing if there is no upvalue with the given index. For C functions the name
--- is always an empty string.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getupvalue)
---
---@param f  async fun(...):... The function to inspect.
---@param up integer The index of the upvalue, starting at `1`.
---@return string name The name of the upvalue.
---@return any    value The current value of the upvalue.
---@nodiscard
function debug.getupvalue( f, up ) end

--- [SHARED AND MENU]
---
--- Returns the Lua value associated to the userdata `u`, or `nil` if `u` is not a userdata
--- or has no associated value.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getuservalue)
---
---@param u userdata The userdata to get the associated value of.
---@return any value The Lua value associated to `u`.
---@nodiscard
function debug.getuservalue( u ) end

--- [SHARED AND MENU]
---
--- ### **Deprecated in `Lua 5.4.2`**
---
--- Sets a new limit for the C stack. This limit controls how deeply nested calls can go in Lua, with the intent of avoiding a stack overflow.
---
--- In case of success, this function returns the old limit. In case of error, it returns `false`.
---
--- Only exists in Lua 5.4; it isn't available in Lua 5.1 or LuaJIT.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-debug.setcstacklimit)
---
---@deprecated
---@param limit integer The new C stack limit.
---@return integer|boolean old_limit The previous limit on success, or `false` on error.
function debug.setcstacklimit( limit ) end

--- [SHARED AND MENU]
---
--- Sets the environment of the given `object` to the given `table`, and returns `object`.
---
--- Raises an error if `object` is not a function, a thread or a userdata, since only
--- those carry an environment.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setfenv)
---
---@version 5.1
---@generic T
---@param object T The function, thread or userdata whose environment to replace.
---@param env    table The new environment table.
---@return T object The given `object`.
function debug.setfenv( object, env ) end

--- [SHARED AND MENU]
---
--- Selects which events trigger a hook installed with `debug.sethook`.
---
--- Letters can be combined (e.g. `"cr"`). A hook with an empty mask and a positive `count`
--- fires only on the count event.
---
---@alias hookmask string
---|+"c" # Calls hook when Lua calls a function.
---|+"r" # Calls hook when Lua returns from a function.
---|+"l" # Calls hook when Lua enters a new line of code.

--- [SHARED AND MENU]
---
--- Sets the given function as a hook.
---
--- The string `mask` and the number `count` describe when the hook will be called: see
--- `hookmask` for the events that can be selected. With a `count` other than zero, the
--- hook is also called after every `count` instructions.
---
--- When called with no arguments, `debug.sethook` turns the hook off.
---
--- When the hook is called, its first parameter is a string describing the event that
--- triggered it: `"call"`, `"return"`, `"tail return"`, `"line"` or `"count"`. For line
--- events, the second parameter is the new line number. Inside a hook, level `2` of
--- `debug.getinfo` is the function being hooked.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.sethook)
---
---@overload fun(hook: (async fun(...):...), mask: hookmask, count?: integer)
---@overload fun(thread: thread):...
---@overload fun(...):...
---@param thread thread The thread to set the hook on. Defaults to the running thread when omitted (see the overloads).
---@param hook   async fun(...):... The hook function, called with the event name (and the line number for line events).
---@param mask   hookmask Which events trigger the hook.
---@param count? integer Also call the hook after every `count` instructions, if not `0`.
function debug.sethook( thread, hook, mask, count ) end

--- [SHARED AND MENU]
---
--- Assigns the `value` to the local variable with index `index` of the function at `level`
--- of the stack, and returns the name of the variable.
---
--- Returns `nil` if there is no local variable with the given index, and raises an error
--- when called with a `level` out of range. See `debug.getlocal` for how locals are
--- indexed.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setlocal)
---
---@overload fun(level: integer, index: integer, value: any):string
---@param thread thread The thread whose stack to modify. Defaults to the running thread when omitted (see the overload).
---@param level  integer The stack level of the function (`1` = the function that called `setlocal`).
---@param index  integer The index of the local variable, starting at `1`.
---@param value  any The new value of the local variable.
---@return string name The name of the local variable, or `nil` if there is none at `index`.
function debug.setlocal( thread, level, index, value ) end

--- [SHARED AND MENU]
---
--- Sets the metatable for the given value to the given table (which can be `nil`), and
--- returns `value`.
---
--- Unlike the standard `setmetatable`, this works on values of any type (numbers, strings,
--- functions, ...), not just tables, and ignores the `__metatable` field. For non-table
--- types the metatable is shared by every value of that type.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setmetatable)
---
---@generic T
---@param value T The value to set the metatable of.
---@param meta? table The new metatable, or `nil` to remove it.
---@return T value The given `value`.
function debug.setmetatable( value, meta ) end

--- [SHARED AND MENU]
---
--- Assigns the `value` to the upvalue with index `up` of the function `f`, and returns the
--- name of the upvalue.
---
--- Returns nothing if there is no upvalue with the given index. See `debug.getupvalue`
--- for how upvalues are indexed.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setupvalue)
---
---@param f     async fun(...):... The function to modify.
---@param up    integer The index of the upvalue, starting at `1`.
---@param value any The new value of the upvalue.
---@return string name The name of the upvalue.
function debug.setupvalue( f, up, value ) end

--- [SHARED AND MENU]
---
--- Sets the given value as the Lua value associated to the given userdata, and returns
--- `udata`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setuservalue)
---
---@param udata userdata The userdata to attach the value to.
---@param value any The value to associate with `udata`.
---@return userdata udata The given `udata`.
function debug.setuservalue( udata, value ) end

--- [SHARED AND MENU]
---
--- Returns a string with a traceback of the call stack. The optional message string is appended at the beginning of the traceback.
---
--- If `message` is present but is neither a string nor `nil`, this function returns
--- `message` without further processing. The optional `level` number tells at which level
--- to start the traceback (default is `1`, the function calling `traceback`).
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.traceback)
---
---@overload fun(message?: any, level?: integer): string
---@param thread   thread The thread to produce a traceback of. Defaults to the running thread when omitted (see the overload).
---@param message? any A message to prepend to the traceback.
---@param level?   integer The stack level to start the traceback at. Defaults to `1`.
---@return string  message The traceback string, or `message` unchanged if it isn't a string or `nil`.
---@nodiscard
function debug.traceback( thread, message, level ) end

--- [SHARED AND MENU]
---
--- Returns a unique identifier (as a light userdata) for the upvalue numbered `n` from the given function.
---
--- Two closures that share an upvalue return the same identifier for it, so this can be
--- used to check whether upvalues are shared, which `debug.getupvalue` alone can't tell
--- you. See `debug.upvaluejoin` for making closures share one.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.upvalueid)
---
---@param f async fun(...):... The function that owns the upvalue.
---@param n integer The index of the upvalue, starting at `1`.
---@return lightuserdata id A unique identifier for the upvalue.
---@version >5.2, JIT
---@nodiscard
function debug.upvalueid( f, n ) end

--- [SHARED AND MENU]
---
--- Make the `n1`-th upvalue of the Lua closure `f1` refer to the `n2`-th upvalue of the Lua closure `f2`.
---
--- After the call, both closures read and write the same variable. Only works on Lua
--- closures, not C functions.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.upvaluejoin)
---
---@param f1 async fun(...):... The closure whose upvalue is re-pointed.
---@param n1 integer The index of the upvalue in `f1`, starting at `1`.
---@param f2 async fun(...):... The closure whose upvalue is shared.
---@param n2 integer The index of the upvalue in `f2`, starting at `1`.
---@version >5.2, JIT
function debug.upvaluejoin( f1, n1, f2, n2 ) end

return debug
