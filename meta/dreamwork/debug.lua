---@meta dreamwork.std.debug


--- [SHARED AND MENU]
---
--- Specifies what information to retrieve from `debug.getinfo`.
---
--- Each letter selects a group of fields to populate on the returned
--- `debuginfo` table; unrequested fields are left `nil`.
---
--- Multiple letters can be combined in a single string (e.g. `"nSl"`).
---
---@alias dreamwork.std.debug.InfoWhat string
---|+"f" # Function value. Fills `func`.
---|+"l" # Current line. Fills `currentline`.
---|+"L" # Active lines. Fills `activelines`.
---|+"n" # Name info. Fills `name` and `namewhat`.
---|+"S" # Source info. Fills `source`, `short_src`, `linedefined`, `lastlinedefined`, and `what`.
---|+"u" # Upvalue/parameter info. Fills `nups`, `nparams`, and `isvararg`.
---|+">" # LuaJIT extension; causes this function to use the last argument to get the data from, instead of treating it as a stack level; the function value is popped/consumed in the process. No fields of its own — combine with other letters (e.g. `">S"`).


--- [SHARED AND MENU]
---
--- Contains information about a function.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-debug.getinfo)
---
---@class dreamwork.std.debug.Info
---@field name             string | nil  The name of the function, if a reasonable name can be found. Only valid when `what` includes `"n"`.
---@field namewhat         string | nil  Explains the `name` field. Its value may be `"global"`, `"local"`, `"method"`, `"field"`, `"upvalue"`, or `""` (the empty string) when no other option applies.
---@field source           string | nil  The source of the chunk that created the function. If it starts with `@`, the function was defined in a file whose name follows the `@`. If it starts with `=`, the remainder describes the source in a user-dependent manner. Otherwise, the function was defined in a string equal to `source`.
---@field short_src        string | nil  A "printable" version of `source`, to be used in error messages.
---@field linedefined      integer | nil The line number where the definition of the function starts.
---@field lastlinedefined  integer | nil The line number where the definition of the function ends.
---@field what             "Lua" | "C" | nil  The type of the function: `"Lua"` if it's a normal Lua function, `"C"` if it's a C function, `"main"` if it's the main part of a chunk.
---@field currentline      integer | nil The current line where the given function is executing. -1 when no line information is available.
---@field nups             integer | nil The number of upvalues of the function.
---@field nparams          integer | nil The number of fixed parameters of the function (always 0 for C functions).
---@field isvararg         boolean | nil `true` if the function is a vararg function (always `true` for C functions).
---@field func             function | nil The function itself. Only valid when `what` includes `"f"`.
---@field activelines      table<integer, ( true | nil )> | nil A set whose keys are the line numbers with associated code (i.e. valid lines for breakpoints); each present key maps to `true`. Only valid when `what` includes `"L"`.


---@class getregistry
getregistry = {}

--- [SHARED AND MENU]
---
--- Returns the registry table.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-debug.getregistry)
---
---@return table
---@nodiscard
function getregistry.Get() end
