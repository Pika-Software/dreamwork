local holylib = HolyLib or {}
local error = error

---@diagnostic disable-next-line: undefined-global
local dofile = include or dofile
if dofile == nil then
    error( "`dofile` not found, dreamwork cannot be loaded!" )
end

if dreamwork == nil then

    --- [SHARED AND MENU]
    ---
    --- Lua runtime and package manager.
    ---
    ---@class dreamwork
    ---@field Version string Package manager version in semver format.
    ---@field Prefix string Package manager unique prefix.
    ---@field std dreamwork.std Standard runtime environment.
    ---@diagnostic disable-next-line: missing-fields
    dreamwork = { std = {} }
    dreamwork.Version = "0.1.0"
    dreamwork.Prefix = "dreamwork@" .. dreamwork.Version

end

dreamwork.dofile = dofile

---@class dreamwork.std
---@field _G table The global environment of Lua.
---@field _R table The registry of Lua.
---@field LUA_VERSION integer The version of the Lua interpreter.
---@field GAME_VERSION integer Contains the version number of the Garrys Mod. For example: `201211` = `01.01.2012`
---@field GAME_BRANCH "x86-64" | "dev" | "prerelease" | "unknown" | string The branch the Garry's Mod is running on. This will be `unknown` on main branch.
---@field LUA_REALM "server" | "client" | "menu" | "unknown" The realm the code is running on.
---@field LUA_MENU boolean `true` if code is running on the menu, `false` otherwise.
---@field LUA_CLIENT boolean `true` if code is running on the client, `false` otherwise.
---@field LUA_CLIENT_MENU boolean `true` if code is running on the client or menu, `false` otherwise.
---@field LUA_CLIENT_SERVER boolean `true` if code is running on the client or server, `false` otherwise.
---@field LUA_SERVER boolean `true` if code is running on the server, `false` otherwise.
---@field DEVELOPER integer A cached value of `developer` console variable.
---@field FRAME_TIME number The time it takes to run one frame in seconds. **Client-only**
---@field FPS number The number of frames per second. **Client-only**
local std = dreamwork.std

---@diagnostic disable-next-line: assign-type-mismatch, undefined-global
std.GAME_VERSION = VERSION or 0

---@diagnostic disable-next-line: undefined-global
std.GAME_BRANCH = BRANCH or "unknown"

---@diagnostic disable-next-line: undefined-global
local LUA_MENU = MENU_DLL == true
std.LUA_MENU = LUA_MENU

---@diagnostic disable-next-line: undefined-global
local LUA_CLIENT = CLIENT == true and not LUA_MENU
std.LUA_CLIENT = LUA_CLIENT

---@diagnostic disable-next-line: undefined-global
local LUA_SERVER = SERVER == true and not LUA_MENU
std.LUA_SERVER = LUA_SERVER

local LUA_CLIENT_MENU = LUA_CLIENT or LUA_MENU
std.LUA_CLIENT_MENU = LUA_CLIENT_MENU

local LUA_MENU_SERVER = LUA_SERVER or LUA_MENU
std.LUA_MENU_SERVER = LUA_MENU_SERVER

local LUA_CLIENT_SERVER = LUA_CLIENT or LUA_SERVER
std.LUA_CLIENT_SERVER = LUA_CLIENT_SERVER

if LUA_SERVER then
    std.LUA_REALM = "server"
elseif LUA_CLIENT then
    std.LUA_REALM = "client"
elseif LUA_MENU then
    std.LUA_REALM = "menu"
else
    std.LUA_REALM = "unknown"
end

std.getmetatable = getmetatable
std.setmetatable = setmetatable

std.xpcall = xpcall
std.pcall = pcall

local setmetatable = std.setmetatable
local xpcall = std.xpcall
local pcall = std.pcall

-- raw data library
dofile( "dreamwork/std/raw.lua" )

---@class dreamwork.std.raw
local raw = std.raw
local raw_get = raw.get
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_select = raw.select
local raw_tonumber = raw.tonumber

--- [SHARED AND MENU]
---
--- Throws an error with the specified message and level.
---
---@param value? any The error value to throw.
---@param stack_level? integer The stack level to throw the error.
---@param dont_break? boolean If `true`, the error will not break the current stack.
function std.error( value, stack_level, dont_break )
    ---@diagnostic disable-next-line: redundant-parameter
    return error( value, stack_level, dont_break )
end

-- debug library
dofile( "dreamwork/std/debug.lua" )

---@class dreamwork.std.debug
local debug = std.debug
local debug_fempty = debug.fempty

---@type fun( lua_path: string )
---@diagnostic disable-next-line: undefined-global
local sendfile = LUA_SERVER and AddCSLuaFile or debug_fempty
dreamwork.sendfile = sendfile

sendfile( "dreamwork/loader.lua" )
sendfile( "dreamwork/std/raw.lua" )
sendfile( "dreamwork/std/debug.lua" )

-- garbage collector
dofile( "dreamwork/std/gc.lua" )
sendfile( "dreamwork/std/gc.lua" )

local gc = std.gc
local startup_memory = gc.getMemory()

std.getfenv = getfenv or debug.getfenv

if std.getfenv == nil then

    local debug_getupvalue = debug.getupvalue
    local debug_getf = debug.getf
    local raw_type = raw.type

    ---@diagnostic disable-next-line: undefined-global
    local _G = _G or _ENV

    --- [SHARED AND MENU]
    ---
    --- Returns the current environment in use by the function.
    ---
    ---@param location integer | function Can be a Lua `function` or a `number` that specifies the function at that stack level.
    ---@return table fenv Specified function environment.
    ---@nodiscard
    ---@diagnostic disable-next-line: duplicate-set-field
    function std.getfenv( location )
        ---@type function | nil
        local func

        local location_type = raw_type( location )
        if location_type == "function" then
            ---@cast location function
            func = location
        elseif location_type == "number" then
            func = debug_getf( (location or 1) + 1 )
            if func == nil then
                return _G
            end
        else
            return _G
        end

        ---@type integer
        local index = 1

        ::fenv_search_loop::

        local name, value = debug_getupvalue( func, index )

        if name == nil then
            return _G
        elseif name == "_ENV" then
            return value
        end

        index = index + 1

        ---@diagnostic disable-next-line: missing-return
        goto fenv_search_loop
    end

end

std.setfenv = setfenv or debug.setfenv

if std.setfenv == nil then

    local debug_getupvalue = debug.getupvalue
    local debug_setupvalue = debug.setupvalue
    local debug_getf = debug.getf
    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Sets the environment of the specified function.
    ---
    ---@generic F: function
    ---@param location integer | F Can be a Lua `function` or a `number` that specifies the function at that stack level.
    ---@param env table The environment table to set.
    ---@return F location The function with the updated environment.
    ---@diagnostic disable-next-line: duplicate-set-field
    std.setfenv = setfenv or debug.setfenv or function( location, env )
        local func

        if location == nil or raw_type( location ) == "number" then
            func = debug_getf( (location or 1) + 1 )
            if func == nil then
                error( "environment was corrupted; setfenv failed", 2 )
            end
        end

        local index = 1

        ::fenv_setup_loop::

        local name = debug_getupvalue( func, index )
        if name == "_ENV" then
            debug_setupvalue( func, index, env )
        elseif name ~= nil then
            goto fenv_setup_loop
        end

        index = index + 1
        return location
    end

end

---@type fun( value: any ): boolean
---@diagnostic disable-next-line: undefined-global
local isTable = istable

if isTable == nil then

    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Checks whether the value is a `table`.
    ---
    ---@param value any The value to check.
    ---@return boolean is_table `true` if the value is a `table`, `false` otherwise.
    ---@nodiscard
    function isTable( value )
        return raw_type( value ) == "table"
    end

end

std.isTable = isTable

-- jit library
dofile( "dreamwork/std/jit.lua" )
sendfile( "dreamwork/std/jit.lua" )

local jit = std.jit

---@class dreamwork.std.ffi
local ffi = std.ffi

-- we need more sugar!!1
local debug_getmetatable = debug.getmetatable
raw.getmetatable = debug_getmetatable
raw.setmetatable = debug.setmetatable

---@class dreamwork.meta
local dreamwork_meta = debug_getmetatable( dreamwork )
if dreamwork_meta == nil then
    local hidden_functions = {}
    gc.setTableRules( hidden_functions, true, false )

    ---@class dreamwork.meta : metatable
    ---@field hidden_error_frames table<function, (true | nil)> Functions whose frames never appear in an error call stack.
    dreamwork_meta = {
        hidden_error_frames = hidden_functions
    }

    debug.setmetatable( dreamwork, dreamwork_meta )
end

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
function debug.getmetavalue( value, key, allow_index )
    local metatable = debug_getmetatable( value )
    if metatable == nil then
        return nil
    elseif allow_index then
        return metatable[ key ]
    end

    return raw_get( metatable, key )
end

local debug_getmetavalue = debug.getmetavalue

do

    local raw_tostring = raw.tostring

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
    function std.tostring( value )
        return debug_getmetavalue( value, "__name" ) or raw_tostring( value )
    end

end

local tostring = std.tostring

--- [SHARED AND MENU]
---
--- Returns the length of the given value.
---
---@param value any The value to get the length of.
---@return number length The length of the given value.
---@nodiscard
function std.len( value )
    ---@type nil | fun( value: any ): number
    local fn = debug_getmetavalue( value, "__len" )
    if fn == nil then
        return #value
    end

    return fn( value )
end

--
-- ONLY REASON WHY CODE BELOW EXISTS
-- IS THAT FACEPUNCH IS BUNCH
-- OF MOTHERF1CKERS
--
-- 🤡 issue exists more than 10 years 🤡
--
-- -DLUAJIT_ENABLE_LUA52COMPAT
--

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
function std.equal( a, b )
    ---@type nil | fun( a: any, b: any ): boolean
    local a__eq = debug_getmetavalue( a, "__eq" )
    if a__eq == nil then
        ---@type nil | fun( b: any, a: any ): boolean
        local b__eq = debug_getmetavalue( b, "__eq" )
        if b__eq == nil then
            return a == b
        end

        return b__eq( b, a )
    end

    return a__eq( a, b )
end

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
function std.lessThan( a, b )
    ---@type nil | fun( a: any, b: any ): boolean
    local a__lt = debug_getmetavalue( a, "__lt" )
    if a__lt == nil then
        ---@type nil | fun( b: any, a: any ): boolean
        local b__le = debug_getmetavalue( b, "__le" )
        if b__le == nil then
            return a < b
        end

        return not b__le( b, a )
    end

    return a__lt( a, b )
end

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
function std.lessEqual( a, b )
    ---@type nil | fun( a: any, b: any ): boolean
    local a__le = debug_getmetavalue( a, "__le" )
    if a__le == nil then
        ---@type nil | fun( b: any, a: any ): boolean
        local b__lt = debug_getmetavalue( b, "__lt" )
        if b__lt == nil then
            return a <= b
        end

        return not b__lt( b, a )
    end

    return a__le( a, b )
end

--- [SHARED AND MENU]
---
--- Returns binary size of the `value` as integer of bit/bytes.
---
---@param value any The value to get the size of.
---@param as_bytes? boolean Whether return size as bytes. By default: `false`
---@return integer | nil size The size of the `value`.
---@nodiscard
function std.sizeof( value, as_bytes )
    ---@type nil | fun( value: any, as_bytes: boolean ): integer
    local fn = debug_getmetavalue( value, "__sizeof" )
    if fn == nil then
        return nil
    end

    return fn( value, as_bytes == true )
end

--- [SHARED AND MENU]
---
--- Returns the copy of the `value`.
---
---@generic T
---@param value T The value to copy.
---@return T copy The copy of the `value`.
---@nodiscard
function std.copy( value )
    local fn = debug_getmetavalue( value, "__copy" )
    if fn == nil then
        return nil
    end

    return fn( value )
end

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
function std.tonumber( e, base )
    local fn = debug_getmetavalue( e, "__tonumber" )
    if fn == nil then
        return nil
    end

    return fn( e, base or 10 )
end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__toboolean`, calls it with `e` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param e any The value to convert to a `boolean`.
---@return boolean | nil bool The boolean value of `e`, or `nil` if `e` cannot be converted to a boolean.
---@nodiscard
function std.toboolean( e )
    local fn = debug_getmetavalue( e, "__toboolean" )
    if fn == nil then
        return nil
    end

    return fn( e )
end

-- Alias for lazy developers
std.tobool = std.toboolean

--- [SHARED AND MENU]
---
--- If `value` has a metamethod `__tocolor`, calls it with `value` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param value any The value to convert to a `color`.
---@return dreamwork.std.Color | nil clr The color value of `value`, or `nil` if `value` cannot be converted to a color.
---@nodiscard
function std.tocolor( value )
    ---@type fun(value: any): dreamwork.std.Color | nil
    local fn = debug_getmetavalue( value, "__tocolor" )
    if fn == nil then
        return nil
    end

    return fn( value )
end

--- [SHARED AND MENU]
---
--- Checks if the value is valid.
---
---@param value any The value to check for validity.
---@return boolean is_valid `true` if object is still valid and should be kept alive, `false` otherwise.
---@nodiscard
function std.isValid( value )
    local fn = debug_getmetavalue( value, "__isvalid" )
    if fn == nil then
        return false
    end

    return fn( value )
end

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
function std.next( tbl, key )
    return (debug_getmetavalue( tbl, "__pairs" ) or raw_next)( tbl, key )
end

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
function std.pairs( t )
    local next_fn = debug_getmetavalue( t, "__pairs" )
    if next_fn == nil then
        return raw_pairs( t )
    end

    return next_fn( t, nil ), t
end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the next value in the table `t`, with the given `index`.
    ---
    ---@param tbl table
    ---@param index integer
    ---@return integer | nil, any
    ---@nodiscard
    local function inext( tbl, index )
        index = index + 1

        local value = tbl[ index ]
        if value == nil then
            return nil, nil
        end

        return index, value
    end

    std.inext = inext

    local raw_ipairs = raw.ipairs

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
    function std.ipairs( t )
        if debug_getmetavalue( t, "__index" ) == nil then
            return raw_ipairs( t )
        end

        return inext, t, 0
    end

end

-- math library
dofile( "dreamwork/std/math.lua" )
sendfile( "dreamwork/std/math.lua" )

---@class dreamwork.std.math
local math = std.math
local math_floor = math.floor
local math_min, math_max = math.min, math.max

do

    ---@alias dreamwork.std.RangeIterator fun( break_point: integer, index: integer ): integer | nil

    ---@type table<integer, dreamwork.std.RangeIterator>
    local range_iterators = {
        [ 0 ] = debug_fempty
    }

    setmetatable( range_iterators, {
        ---@param self table<integer, dreamwork.std.RangeIterator>
        ---@param step_size integer
        ---@return dreamwork.std.RangeIterator
        __index = function( self, step_size )
            local math_fn = (step_size < 0) and math_max or math_min

            local function fn( break_point, index )
                local next_index = math_fn( index + step_size, break_point )
                if next_index == break_point then return nil end

                return next_index
            end

            self[ step_size ] = fn
            return fn
        end
    } )

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
    ---@return dreamwork.std.RangeIterator iterator The iterator function to be used with a generic `for` loop.
    ---@return integer to The final value, passed through as the loop's invariant state.
    ---@return integer start The initial value, passed to the iterator on the first call.
    ---@nodiscard
    function std.range( from, to, step )
        return range_iterators[ step or 1 ], to, from - (step or 1)
    end

end

--- [SHARED AND MENU]
---
--- The global environment table (outside of DreamWork).
---
---@type _G
---@diagnostic disable-next-line: undefined-global
std.global = std.getfenv( 1 ) or _G or _ENV

-- os library
dofile( "dreamwork/std/os.lua" )
sendfile( "dreamwork/std/os.lua" )

---@class dreamwork.std.os
local os = std.os

--- [SHARED AND MENU]
---
--- Returns a highly accurate amount of seconds since Lua/Engine started.
---
---@type fun(): number
dreamwork.getUpTime = SysTime or os.clock

local dreamwork_getUpTime = dreamwork.getUpTime
dreamwork.InitTime = dreamwork_getUpTime()

-- detour library
dofile( "dreamwork/detour.lua" )
sendfile( "dreamwork/detour.lua" )

-- table library
dofile( "dreamwork/std/table.lua" )
sendfile( "dreamwork/std/table.lua" )

-- vararg library
dofile( "dreamwork/std/vararg.lua" )
sendfile( "dreamwork/std/vararg.lua" )

---@class dreamwork.std.table
local table = std.table
local table_concat = table.concat
local table_unpack = table.unpack

-- ascii library
dofile( "dreamwork/std/ascii.lua" )
sendfile( "dreamwork/std/ascii.lua" )

-- string library
dofile( "dreamwork/std/string.lua" )
sendfile( "dreamwork/std/string.lua" )

---@class dreamwork.std.string
local string = std.string
local string_match = string.match
local string_format = string.format
local string_sub, string_len = string.sub, string.len
local string_char, string_byte = string.char, string.byte

std.LUA_VERSION = raw_tonumber( string_match( _VERSION or "0", "Lua ([%d.]+)" ) or 0, 10 ) or 0

---@return string
---@protected
function dreamwork_meta:__represent()
    return string_format( "%s: %p [%s]", dreamwork.Prefix, self, std.jit.version or string_format( "Lua %s", std.LUA_VERSION ) )
end

do

    local string_toNumber = string.toNumber

    --- [SHARED AND MENU]
    ---
    --- Returns the hash of the given value.
    ---
    ---@param value any The value to get the hash of.
    ---@return integer hash The hash of the given value.
    ---@nodiscard
    function std.hash( value )
        ---@type fun( value: any ): integer
        local fn = debug_getmetavalue( value, "__hash" )
        if fn == nil then
            return string_toNumber( string_format( "%p", value ), 16 ) or 0
        end

        return fn( value )
    end

end

do

    local string_byteRep = string.byteRep

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
    function std.tohex( value, desired_length )
        local hex_str

        ---@type fun( value: any ): string
        local tohex_fn = debug_getmetavalue( value, "__tohex" )
        if tohex_fn == nil then
            ---@type fun( value: any ): integer
            local hash_fn = debug_getmetavalue( value, "__hash" )
            if hash_fn == nil then
                hex_str = string_sub( string_format( "%p", value ), 3 )
            else
                hex_str = string_format( "%x", hash_fn( value ) )
            end
        else
            hex_str = tohex_fn( value )
        end

        if desired_length ~= nil then
            local length = string_len( hex_str )
            if length < desired_length then
                return string_byteRep( 0x30, desired_length - length ) .. string_sub( hex_str, 1, length )
            elseif length > desired_length then
                return string_sub( hex_str, 1, desired_length )
            end
        end

        return hex_str
    end

end

-- symbols
dofile( "dreamwork/std/types/symbol.lua" )
sendfile( "dreamwork/std/types/symbol.lua" )

-- class library
dofile( "dreamwork/std/class.lua" )
sendfile( "dreamwork/std/class.lua" )

do

    local isInherited = std.class.isInherited
    local isClass = std.isClass

    --- [SHARED AND MENU]
    ---
    --- Checks if the value is an instance of the given parent.
    ---
    ---@param object any The object to check for being an instance of the given parent.
    ---@param ... any The parent classes/metatables to check against.
    ---@return boolean is_instance `true` if `object` is an instance of any of the given parent classes/metatables, `false` otherwise.
    ---@nodiscard
    function std.isInstance( object, ... )
        local metatable = debug_getmetatable( object )

        for i = 1, raw_select( "#", ... ) do
            local parent = raw_select( i, ... )
            if isClass( parent ) then
                if isInherited( object, parent ) then
                    return true
                end
            elseif metatable == parent then
                return true
            end
        end

        return false
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the value is an instance of the given parent.
    ---
    ---@param object any The object to check for being an instance of the given parent.
    ---@param value any The parent class/metatable to check against.
    ---@return boolean is_instance `true` if `object` is an instance of the given parent class/metatable, `false` otherwise.
    ---@nodiscard
    function std.is( object, value )
        if isClass( value ) then
            if isInherited( object, value ) then
                return true
            end
        elseif debug_getmetatable( object ) == value then
            return true
        end

        return false
    end

end

-- coroutine library
dofile( "dreamwork/std/coroutine.lua" )
sendfile( "dreamwork/std/coroutine.lua" )

-- stack class
dofile( "dreamwork/std/types/stack.lua" )
sendfile( "dreamwork/std/types/stack.lua" )

-- queue class
dofile( "dreamwork/std/types/queue.lua" )
sendfile( "dreamwork/std/types/queue.lua" )

-- node class
dofile( "dreamwork/std/types/node.lua" )
sendfile( "dreamwork/std/types/node.lua" )

do

    ---@class dreamwork.std
    ---@field SYSTEM_OSX boolean `true` if the game is running on OSX.
    ---@field SYSTEM_LINUX boolean `true` if the game is running on Linux.
    ---@field SYSTEM_WINDOWS boolean `true` if the game is running on Windows.
    ---@field SYSTEM_X64 boolean `true` if the game is running on 64-bit architecture.
    ---@field SYSTEM_X32 boolean `true` if the game is running on 32-bit architecture.
    ---@field SYSTEM_NAME "osx64" | "osx" | "linux64" | "linux" | "win64" | "win32" The short name of the currently running system with architecture.

    local jit_os = string.lower( jit.os )

    local SYSTEM_OSX = jit_os == "osx"
    std.SYSTEM_OSX = SYSTEM_OSX

    local SYSTEM_LINUX = jit_os == "linux"
    std.SYSTEM_LINUX = SYSTEM_LINUX

    local SYSTEM_WINDOWS = jit_os == "windows"
    std.SYSTEM_WINDOWS = SYSTEM_WINDOWS

    local SYSTEM_X64 = string.match( jit.arch, "64" ) ~= nil
    std.SYSTEM_X64 = SYSTEM_X64

    local SYSTEM_X32 = not SYSTEM_X64
    std.SYSTEM_X32 = SYSTEM_X32

    std.SYSTEM_NAME = ({ "osx64", "osx", "linux64", "linux", "win64", "win32" })[ (SYSTEM_WINDOWS and 4 or 0) + (SYSTEM_LINUX and 2 or 0) + (SYSTEM_X32 and 1 or 0) + 1 ]

end

do

    local debug_registermetatable = debug.registermetatable
    local debug_setmetatable = debug.setmetatable

    -- nil ( 0 )
    do

        ---@class dreamwork.std.Nil : metatable
        local Nil = debug_getmetatable( nil )

        if Nil == nil then
            Nil = {}
            debug_setmetatable( nil, Nil )
        end

        debug_registermetatable( "nil", Nil )

        Nil.__type = "nil"
        std.Nil = Nil

        ---@private
        function Nil.__toboolean()
            return false
        end

        ---@private
        function Nil.__tonumber()
            return 0
        end

        Nil.__len = Nil.__tonumber

        ---@param value nil
        ---@return string
        ---@private
        function Nil.__represent( value )
            return "nil: 0x00000000"
        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is `nil`.
        ---
        ---@param value any
        ---@return boolean is_nil
        ---@nodiscard
        function std.isNil( value )
            return value == nil
        end

    end

    -- boolean ( 1 )
    do

        ---@class dreamwork.std.Boolean : metatable
        local Boolean = debug_getmetatable( false )

        if Boolean == nil then
            Boolean = {}
            debug_setmetatable( false, Boolean )
        end

        debug_registermetatable( "boolean", Boolean )

        Boolean.__type = "boolean"
        std.Boolean = Boolean

        ---@param value boolean
        ---@private
        function Boolean.__toboolean( value )
            return value
        end

        ---@param value boolean
        ---@private
        function Boolean.__tonumber( value )
            return value == true and 1 or 0
        end

        ---@param value boolean
        ---@private
        function Boolean.__hash( value )
            return value == true and 1 or 0
        end

        ---@private
        function Boolean.__len()
            return 1
        end

        ---@param value boolean
        ---@return string
        ---@private
        function Boolean.__represent( value )
            return string_format( "boolean: 0x00000000 [%s]", value )
        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is `boolean`.
        ---
        ---@param value any
        ---@return boolean is_bool
        ---@nodiscard
        function std.isBoolean( value )
            return value == true or value == false
        end

    end

    -- number ( 3 )
    do

        ---@class dreamwork.std.Number : metatable
        local Number = debug_getmetatable( 0 )

        if Number == nil then
            Number = {}
            debug_setmetatable( 0, Number )
        end

        debug_registermetatable( "number", Number )

        Number.__type = "number"
        std.Number = Number

        ---@param value number
        ---@private
        function Number.__toboolean( value )
            return value ~= 0
        end

        ---@param value number
        ---@private
        function Number.__tonumber( value )
            return value
        end

        ---@param value number
        ---@private
        function Number.__hash( value )
            return value
        end

        ---@return string
        ---@private
        function Number:__represent()
            return string_format( "%s: 0x00000000 [%g]", (self % 1) == 0 and "integer" or "number", self, self )
        end

        do

            local math_ceil, math_log, math_isFinite = math.ceil, math.log, math.isFinite
            local math_ln2 = math.ln2

            ---@param value number
            ---@private
            function Number.__len( value )
                if math_isFinite( value ) then
                    if (value % 1) == 0 then
                        return math_ceil( (
                            math_ceil( math_log( value + 1 ) / math_ln2 ) +
                            (((1 / value) > 0) and 1 or 0)
                        ) / 8 )
                    elseif value >= 1.175494351E-38 and value <= 3.402823466E+38 then
                        return 4
                    end

                    return 8
                end

                return 0
            end

        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `number`.
        ---
        ---@param value any
        ---@return boolean is_number
        ---@nodiscard
        function std.isNumber( value )
            return debug_getmetatable( value ) == Number
        end

        ---@class dreamwork.std.Integer : metatable
        local Integer = debug.initmetatable( "Integer" )
        Integer.__type = "integer"
        std.Integer = Integer

        setmetatable( Integer, {
            ---@param value number
            __eq = function( _, value )
                return (value % 1) == 0
            end
        } )

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `integer`.
        ---
        ---@param value any
        ---@return boolean is_integer
        ---@nodiscard
        function std.isInteger( value )
            return debug_getmetatable( value ) == Number and (value % 1) == 0
        end

    end

    -- string ( 4 )
    do

        ---@class dreamwork.std.String : metatable
        local String = debug_getmetatable( "" )

        if String == nil then
            String = {}
            debug_setmetatable( "", String )
        end

        debug_registermetatable( "string", String )

        String.__type = "string"
        std.String = String

        ---@param value string
        ---@return boolean
        ---@private
        function String.__toboolean( value )
            return value ~= "" and value ~= "0" and value ~= "false"
        end

        String.__tonumber = raw_tonumber
        String.__div = string.divide
        String.__len = string_len

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `string`.
        ---
        ---@param value any
        ---@return boolean is_string
        ---@nodiscard
        function std.isString( value )
            return debug_getmetatable( value ) == String
        end

    end

    -- table ( 5 )

    -- function ( 6 )
    do

        ---@class dreamwork.std.Function : metatable
        local Function = debug_getmetatable( debug_fempty )

        if Function == nil then
            Function = {}
            debug_setmetatable( debug_fempty, Function )
        end

        debug_registermetatable( "function", Function )

        Function.__type = "function"
        std.Function = Function

        ---@param value function
        ---@return string
        ---@private
        function Function.__represent( value )
            return string_format( "function: %p", value )
        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `function`.
        ---
        ---@param value any
        ---@return boolean is_function
        ---@nodiscard
        function std.isFunction( value )
            return debug_getmetatable( value ) == Function
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value is callable, basically it's a function or a table with a callable `__call` metamethod.
        ---
        ---@param value any
        ---@return boolean is_callable
        ---@nodiscard
        function std.isCallable( value )
            local metatable = debug_getmetatable( value )
            return metatable ~= nil and (metatable == Function or debug_getmetatable( metatable.__call ) == Function)
        end

    end

    -- thread ( 8 )
    do

        local object = std.coroutine.create( debug_fempty )

        ---@class dreamwork.std.Thread : metatable
        local Thread = debug_getmetatable( object )

        if Thread == nil then
            Thread = {}
            debug_setmetatable( object, Thread )
        end

        debug_registermetatable( "thread", Thread )

        Thread.__type = "thread"
        std.Thread = Thread

        ---@param value thread
        ---@return string
        ---@private
        function Thread.__represent( value )
            return string_format( "thread: %p", value )
        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `thread`.
        ---
        ---@param value any
        ---@return boolean is_thread
        ---@nodiscard
        function std.isThread( value )
            return debug_getmetatable( value ) == Thread
        end

    end

end

local isFunction = std.isFunction
local isString = std.isString
local isNumber = std.isNumber

do

    local raw_type = raw.type

    if ffi == nil then

        --- [SHARED AND MENU]
        ---
        --- Returns a string representing the name of the type of the passed object.
        ---
        ---@param value any The value to get the type of.
        ---@return type type_name The type name of the given value.
        ---@nodiscard
        function std.type( value )
            if isNumber( value ) and (value % 1) == 0 then
                return "integer"
            end

            return debug_getmetavalue( value, "__type" ) or
                raw_type( value )
        end

    else

        function std.type( value )
            local name = raw_type( value )
            if name == "number" then
                if value % 1 == 0 then
                    return "integer"
                end

                return name
            end

            ---@type metatable | nil
            local metatable = debug_getmetatable( value )
            if metatable == nil then
                return name
            end

            return raw_get( metatable, "__type" ) or name
        end

    end

end

do

    local CompileString = CompileString

    local getfenv = std.getfenv
    local setfenv = std.setfenv

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
    function std.loadstring( lua_code, chunk_name, env )
        local fn = CompileString( lua_code, chunk_name or "=(loadstring)", false )
        if fn == nil then
            error( "lua code compilation failed", 2 )
        end

        if isString( fn ) then
            ---@cast fn string
            error( fn, 2 )
        end

        ---@cast fn function

        setfenv( fn, env or getfenv( 2 ) )
        return fn
    end

end

-- raw library ( extension )
dofile( "dreamwork/std/raw.ext.lua" )
sendfile( "dreamwork/std/raw.ext.lua" )

-- bit library
dofile( "dreamwork/std/bit.lua" )
sendfile( "dreamwork/std/bit.lua" )

-- bitpack library
dofile( "dreamwork/std/codec/bitpack.lua" )
sendfile( "dreamwork/std/codec/bitpack.lua" )

-- bytepack library
dofile( "dreamwork/std/codec/bytepack.lua" )
sendfile( "dreamwork/std/codec/bytepack.lua" )

-- string library ( extension )
dofile( "dreamwork/std/string.ext.lua" )
sendfile( "dreamwork/std/string.ext.lua" )

-- table library ( extension )
dofile( "dreamwork/std/table.ext.lua" )
sendfile( "dreamwork/std/table.ext.lua" )

-- ipv4 library
dofile( "dreamwork/std/ipv4.lua" )
sendfile( "dreamwork/std/ipv4.lua" )

-- ipv6 class
dofile( "dreamwork/std/ipv6.lua" )
sendfile( "dreamwork/std/ipv6.lua" )

-- version class
dofile( "dreamwork/std/types/version.lua" )
sendfile( "dreamwork/std/types/version.lua" )

-- crc checksum clases
dofile( "dreamwork/std/checksum/crc.lua" )
sendfile( "dreamwork/std/checksum/crc.lua" )

-- adler checksum classes
dofile( "dreamwork/std/checksum/adler.lua" )
sendfile( "dreamwork/std/checksum/adler.lua" )

-- fletcher checksum library
dofile( "dreamwork/std/checksum/fletcher.lua" )
sendfile( "dreamwork/std/checksum/fletcher.lua" )

-- base16 encoding library
dofile( "dreamwork/std/codec/base16.lua" )
sendfile( "dreamwork/std/codec/base16.lua" )

-- base32 encoding library
dofile( "dreamwork/std/codec/base32.lua" )
sendfile( "dreamwork/std/codec/base32.lua" )

-- base64 encoding library
dofile( "dreamwork/std/codec/base64.lua" )
sendfile( "dreamwork/std/codec/base64.lua" )

-- utf8 encoding library
dofile( "dreamwork/std/codec/utf8.lua" )
sendfile( "dreamwork/std/codec/utf8.lua" )

-- utf16 encoding library
dofile( "dreamwork/std/codec/utf16.lua" )
sendfile( "dreamwork/std/codec/utf16.lua" )

-- utf32 encoding library
dofile( "dreamwork/std/codec/utf32.lua" )
sendfile( "dreamwork/std/codec/utf32.lua" )

-- unicode encoding library
dofile( "dreamwork/std/codec/unicode.lua" )
sendfile( "dreamwork/std/codec/unicode.lua" )

-- percent encoding library
dofile( "dreamwork/std/codec/percent.lua" )
sendfile( "dreamwork/std/codec/percent.lua" )

-- punycode encoding library
dofile( "dreamwork/std/codec/punycode.lua" )
sendfile( "dreamwork/std/codec/punycode.lua" )

-- debug stack class
dofile( "dreamwork/std/types/debug_stack.lua" )
sendfile( "dreamwork/std/types/debug_stack.lua" )

do

    local string_escape = string.escape

    ---@class dreamwork.std.String
    local String = debug.findmetatable( "string" )

    ---@param value string
    ---@return string
    ---@private
    function String.__represent( value )
        return string_format( "string: %p [%s][%d]", value, string_escape( value, false ), string_len( value ) )
    end

end

local type = std.type
local len = std.len

--- [SHARED AND MENU]
---
--- Returns a string representation of the given value.
---
---@param value any The value to get the string representation of.
---@return string str The string representation of the given value.
---@nodiscard
function std.represent( value )
    local name = type( value )
    if name ~= "cdata" then
        ---@type fun( value: any ): string
        local fn = debug_getmetavalue( value, "__represent" )
        if fn ~= nil then
            return fn( value )
        end
    end

    return string_format( "%s: %p", name, value )
end

local represent = std.represent

-- path library
dofile( "dreamwork/std/path.lua" )
sendfile( "dreamwork/std/path.lua" )

-- color library
dofile( "dreamwork/std/color.lua" )
sendfile( "dreamwork/std/color.lua" )

---@class dreamwork.std.color
local color_lib = std.color

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
---@class dreamwork.std.color.Scheme
local color_scheme = color_lib.Scheme or {}
color_lib.Scheme = color_scheme

do

    local color_fromRGB = color_lib.fromRGB

    do

        local Scheme = std.getmetatable( color_scheme ) or {}
        setmetatable( color_scheme, Scheme )

        ---@protected
        function Scheme:__tostring()
            return string_format( "ColorScheme: %p", self )
        end

        ---@diagnostic disable-next-line: undefined-global
        local NamedColor = NamedColor or debug_fempty

        local tmp = { r = 255, g = 255, b = 255, a = 255 }

        ---@param name string | integer
        ---@protected
        function Scheme:__index( name )
            local color

            if isString( name ) then
                ---@cast name string
                ---@diagnostic disable-next-line: redundant-parameter
                local engine_color = NamedColor( name ) or tmp
                color = color_fromRGB( engine_color.r, engine_color.g, engine_color.b )
            elseif isNumber( name ) then
                ---@cast name integer
                color = color_fromRGB( name, name, name )
            else
                error( "color name must be string or integer to resolve color.", 3 )
            end

            self[ name ] = color
            return color
        end

    end

    -- Basic Colors
    color_scheme.white = 0xFFFFFF
    color_scheme.white_smoke = 0xF0F0F0

    color_scheme.black = 0x000000

    color_scheme.red = 0xFF0000
    color_scheme.mona_lisa = 0xFF8A80

    color_scheme.green = 0x00FF00

    color_scheme.blue = 0x0000FF
    color_scheme.spray = 0x7EC8E3
    color_scheme.robin_egg_blue = 0x7EC8E3

    color_scheme.yellow = 0xFFFF00
    color_scheme.sandstone = 0xC9B896

    color_scheme.cyan = 0x00FFFF
    color_scheme.magenta = 0xFF00FF

    color_scheme.gray = 0x808080
    color_scheme.dark_gray = 0xA9A9A9
    color_scheme.light_gray = 0xD0D0D0
    color_scheme.suva_gray = 0x8A8A8A

    color_scheme.turquoise = 0x40e0d0
    color_scheme.dark_turquoise = 0x00D0D0

    -- Garry's Mod
    -- Thank you code_gs <3
    -- https://discord.com/channels/565105920414318602/565108080300261398/905385921283756062
    color_scheme.server_message = color_lib.fromRGB( 156, 241, 255 )
    color_scheme.server_error = color_lib.fromRGB( 136, 221, 255 )

    color_scheme.client_message = color_lib.fromRGB( 255, 241, 122 )
    color_scheme.client_error = color_lib.fromRGB( 255, 221, 102 )

    color_scheme.menu_message = color_lib.fromRGB( 100, 220, 100 )
    color_scheme.menu_error = color_lib.fromRGB( 120, 220, 100 )

    -- DreamWork
    color_scheme.dreamwork_main = color_lib.fromRGB( 180, 180, 255 )

    color_scheme.dreamwork_info = color_lib.fromRGB( 70, 135, 255 )
    color_scheme.dreamwork_warn = color_lib.fromRGB( 255, 130, 90 )
    color_scheme.dreamwork_error = color_lib.fromRGB( 250, 55, 40 )
    color_scheme.dreamwork_debug = color_lib.fromRGB( 0, 200, 150 )

    color_scheme.dreamwork_menu = color_lib.fromRGB( 75, 175, 80 )
    color_scheme.dreamwork_client = color_lib.fromRGB( 225, 170, 10 )
    color_scheme.dreamwork_server = color_lib.fromRGB( 5, 170, 250 )

    -- Dynamic
    if LUA_CLIENT then
        color_scheme.realm = color_scheme.dreamwork_client
        color_scheme.message = color_scheme.client_message
        color_scheme.error = color_scheme.client_error
    elseif LUA_MENU then
        color_scheme.realm = color_scheme.dreamwork_menu
        color_scheme.message = color_scheme.menu_message
        color_scheme.error = color_scheme.menu_error
    else
        color_scheme.realm = color_scheme.dreamwork_server
        color_scheme.message = color_scheme.server_message
        color_scheme.error = color_scheme.server_error
    end

end

do

    local string_hasPrefix = string.hasPrefix

    --- [SHARED AND MENU]
    ---
    --- Returns the value of the key in a table.
    ---
    ---@param tbl table The table.
    ---@param key any The key.
    ---@return any
    ---@nodiscard
    function raw.index( tbl, key )
        if isString( key ) then
            ---@cast key string
            if string_hasPrefix( key, "__" ) then
                return nil
            end
        end

        return raw_get( tbl, key )
    end

end

-- BigInteger class
dofile( "dreamwork/std/types/big_integer.lua" )
sendfile( "dreamwork/std/types/big_integer.lua" )

-- BigFixed class
dofile( "dreamwork/std/types/big_fixed.lua" )
sendfile( "dreamwork/std/types/big_fixed.lua" )

-- engine submodule
dofile( "dreamwork/engine.lua" )
sendfile( "dreamwork/engine.lua" )

-- time library
dofile( "dreamwork/std/time.lua" )
sendfile( "dreamwork/std/time.lua" )

local time = std.time

if math.randomseed == 0 then
    math.randomseed = time.now( "ms", false )
end

-- coroutine library ( extension )
dofile( "dreamwork/std/coroutine.ext.lua" )
sendfile( "dreamwork/std/coroutine.ext.lua" )

do

    local time_transform = time.transform
    local jit_flush = jit.flush

    ---@param seconds number
    ---@return string
    local function format_duration( seconds )
        local unit
        if seconds < 1e-6 then
            unit = "ns"
        elseif seconds < 1e-3 then
            unit = "us"
        elseif seconds < 1 then
            unit = "ms"
        else
            unit = "s"
        end

        return string_format( "%.2f %s", time_transform( seconds, "s", unit, true ), unit )
    end

    --- keeps results observable, so the JIT can't eliminate pure work
    local sink = {}

    ---@param fn function
    ---@param iterations integer
    ---@return number seconds
    local function run( fn, iterations )
        local start = dreamwork_getUpTime()

        for _ = 1, iterations do
            sink[ 1 ] = fn()
        end

        return dreamwork_getUpTime() - start
    end

    --- [SHARED AND MENU]
    ---
    --- Runs a benchmark on the given function, measuring the time it takes to execute a specified number of iterations.
    ---
    --- Flushes all JIT traces before running, so results don't depend on previously benchmarked functions.
    ---
    ---@param name string The name of the benchmark.
    ---@param fn function The function to benchmark.
    ---@param iterations? integer The number of iterations per round, `1000` by default.
    ---@param rounds? integer The number of timed rounds, `5` by default.
    ---@return number best The best time per iteration in seconds.
    ---@return number mean The mean time per iteration in seconds.
    ---@return number allocated The bytes allocated per iteration.
    function dreamwork.bench( name, fn, iterations, rounds )
        if iterations == nil then
            iterations = 1000
        end

        if rounds == nil then
            rounds = 5
        end

        -- the `run` loop trace is specialized to the function it was recorded with
        jit_flush()

        -- enough calls for LuaJIT to record and compile the hot loop (hotloop = 56)
        run( fn, math_max( math_floor( iterations / 10 ), 200 ) )

        -- allocation pass, gc is stopped only for a short bounded run
        local sample = math_min( iterations, 1000 )

        gc.collect()
        gc.stop()

        local memory_before = gc.getMemory()
        local success, err_msg = pcall( run, fn, sample )
        local allocated = (gc.getMemory() - memory_before) * 1024 / sample

        gc.restart()

        if not success then
            sink[ 1 ] = nil
            error( err_msg, 2 )
        end

        local best, total = math.huge, 0

        for _ = 1, rounds do
            gc.collect()

            local took = run( fn, iterations )
            total = total + took

            if took < best then
                best = took
            end
        end

        sink[ 1 ] = nil

        best = best / iterations
        local mean = total / (iterations * rounds)

        raw.print( string_format(
            "[DW] Benchmark `%s`\n" ..
            "    rounds      %d x %d\n" ..
            "    best        %s/op\n" ..
            "    mean        %s/op\n" ..
            "    throughput  %.0f op/s\n" ..
            "    allocated   %.1f B/op\n" ..
            "    total       %s",
            name, rounds, iterations, format_duration( best ), format_duration( mean ), 1 / best, allocated, format_duration( total )
        ) )

        return best, mean, allocated
    end

end

-- error class
dofile( "dreamwork/std/types/error.lua" )
sendfile( "dreamwork/std/types/error.lua" )

-- pack library
dofile( "dreamwork/std/codec/pack.lua" )
sendfile( "dreamwork/std/codec/pack.lua" )

-- ByteReader class
dofile( "dreamwork/std/types/binary_reader.lua" )
sendfile( "dreamwork/std/types/binary_reader.lua" )

-- ByteWriter class
dofile( "dreamwork/std/types/binary_writer.lua" )
sendfile( "dreamwork/std/types/binary_writer.lua" )

local engine = dreamwork.engine

do

    local coroutine_running = coroutine.running
    local debug_calledby = debug.calledby
    local debug_getinfo = debug.getinfo
    local debug_Stack = debug.Stack
    local isError = std.isError

    local RuntimeError = std.RuntimeError

    --- Message handed back to the engine once dreamwork has displayed the error itself.
    local ERROR_SENTINEL = "The original error message was caught by dreamwork, see above for details about the error."

    local hidden_functions = dreamwork_meta.hidden_error_frames

    --- [SHARED AND MENU]
    ---
    --- Hides the given function from error call stacks.
    ---
    --- Use it for internal dispatchers and wrappers (hook runners, timer callers, ...)
    --- whose frames carry no useful information for whoever reads the error.
    ---
    ---@param fn function The function to hide.
    function dreamwork.hideErrorFrame( fn )
        hidden_functions[ fn ] = true
    end

    --- Level passed to the last `_G.error` call, read by `capture_stack` only when
    --- the original `error` is the frame that raised the error.
    ---
    ---@type integer
    local pending_level = 1

    ---@param value any
    ---@param stack_level integer | nil
    _G.error = dreamwork.detour.attach( function( fn, value, stack_level )
        pending_level = stack_level or 1
        return fn( value, stack_level )
    end, error )

    local glua_error = dreamwork.detour.shadow( error ) or error

    --- [SHARED AND MENU]
    ---
    --- Checks whether the frame belongs to a hidden function and is left out of error call stacks.
    ---
    --- Pass it to `debug.Stack:filter` to clean up a stack captured by hand.
    ---
    ---@param frame dreamwork.std.debug.StackLevel The frame to check.
    ---@return boolean is_hidden
    ---@nodiscard
    local function is_hidden_frame( frame )
        return hidden_functions[ frame.func ] ~= nil
    end

    dreamwork.isErrorFrameHidden = is_hidden_frame

    --- Captures the call stack of an error into `stack`.
    ---
    --- The walk starts at the caller of `capture_stack` and skips leading C frames
    --- (the C function that raised the error: `error`, `assert`, `string.rep`, ...) and
    --- hidden frames (`std.error`, error handlers, ...), so the innermost frame is always
    --- the Lua code that raised the error, no matter how many handlers or tail calls sit in between.
    ---
    --- Then `skip` more frames are skipped to honour the error level, and everything from there
    --- to the bottom of the current thread is captured, except hidden frames (`pcall`, `xpcall`, ...),
    --- other C frames such as `table.sort` stay in the stack.
    ---
    ---@param stack dreamwork.std.debug.Stack
    ---@param skip integer
    local function capture_stack( stack, skip )
        local level = 2

        while true do
            local info = debug_getinfo( level, "Sf" )
            if info == nil then return end

            local fn = info.func
            if fn == glua_error then
                -- raised by a plain `error( value, level )`, so honour its level
                skip = math_max( 0, pending_level - 1 )
                pending_level = 1
            elseif info.what ~= "C" and hidden_functions[ fn ] == nil then
                break
            end

            level = level + 1
        end

        while skip > 0 do
            local info = debug_getinfo( level + 1, "Sf" )
            if info == nil then break end

            level = level + 1

            if hidden_functions[ info.func ] == nil then
                skip = skip - 1
            end
        end

        stack:capture( level )
        stack:filter( is_hidden_frame )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts any error value into an `Error` and captures its call stack if it has none yet.
    ---
    --- Can be passed to `xpcall` directly as a message handler.
    ---
    ---@param error_value any The error value to convert.
    ---@param error_class? dreamwork.std.ErrorClass The class used to wrap values that are not errors, called with the message only. Defaults to `RuntimeError`.
    ---@return dreamwork.std.Error error_object
    ---@nodiscard
    local function to_error( error_value, error_class )
        ---@type dreamwork.std.Error
        local error_object

        if error_class == nil then
            ---@diagnostic disable-next-line: cast-local-type
            error_class = RuntimeError
        end

        if isError( error_value ) then
            ---@cast error_value dreamwork.std.Error
            error_object = error_value

            if not error_object:isEmpty() then
                return error_object
            end
        elseif error_value == nil then
            error_object = error_class( "unknown error" )
        elseif isString( error_value ) then
            ---@cast error_value string
            error_object = error_class( string_match( error_value, "^[^\n]-:%d+: (.*)$" ) or error_value )
        else
            error_object = error_class( tostring( error_value ) )
        end

        local stack = debug_Stack()
        error_object.stack = stack
        capture_stack( stack, 0 )

        return error_object
    end

    dreamwork.toError = to_error

    --- [SHARED AND MENU]
    ---
    --- `xpcall` message handler for errors that are going to be rethrown.
    ---
    --- Works like `dreamwork.toError`, but values that are neither errors nor strings
    --- (signals like `ACTION_CANCEL`) are returned as is, so rethrowing them keeps their identity,
    --- the same way `std.error` throws them.
    ---
    ---@param error_value any The error value to handle.
    ---@return dreamwork.std.Error | any error_object
    ---@nodiscard
    local function catch_error( error_value )
        if error_value == nil or isString( error_value ) or isError( error_value ) then
            return to_error( error_value )
        end

        return error_value
    end

    dreamwork.catchError = catch_error

    --- Passes the error to the `dreamwork.lua.error` handlers, which display it.
    ---
    ---@param error_object dreamwork.std.Error
    ---@return any result
    local function report( error_object )
        return engine.hookCall( "dreamwork.lua.error", error_object )
    end

    --- [SHARED AND MENU]
    ---
    --- `xpcall` message handler that converts the error into an `Error`, displays it and returns it.
    ---
    ---@param error_value any The error value to handle.
    ---@return dreamwork.std.Error error_object
    local function error_handler( error_value )
        local error_object = to_error( error_value )
        report( error_object )
        return error_object
    end

    dreamwork.errorHandler = error_handler

    -- below gmod specific error output function, that get message/value from engine and return new message (possibly can be string only)
    local function engine_error_handler( error_value )
        if error_value == ERROR_SENTINEL then
            return error_value
        end

        local result = report( to_error( error_value ) )
        if isString( result ) then
            return result
        end

        return tostring( error_value )
    end

    std._R[ 1 ] = engine_error_handler
    hidden_functions[ engine_error_handler ] = true

    ---@param error_value any
    local function display_error( error_value )
        if not isError( error_value ) then
            error_value = to_error( error_value )
        end

        error_value:display()
    end

    hidden_functions[ display_error ] = true

    ---@param value any
    ---@return string
    local function safe_tostring( value )
        local success, str = pcall( raw.tostring, value )
        return success and str or "<value that cannot be converted to string>"
    end

    engine.hookCatch( "dreamwork.lua.error", "console.display", function( error_value )
        -- this runs inside error handlers, where a second error would replace the original one,
        -- so the conversion is protected as well, not only the display
        local success, display_failure = pcall( display_error, error_value )
        if not success then
            raw.print( "[dreamwork] failed to display an error: " .. safe_tostring( display_failure ) )
            raw.print( "[dreamwork] original error: " .. safe_tostring( error_value ) )
        end

        return ERROR_SENTINEL
    end, 1000 )

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
    local function std_error( value, stack_level, dont_break )
        ---@type dreamwork.std.Error
        local error_object

        if isError( value ) then
            ---@cast value dreamwork.std.Error
            error_object = value
        elseif value == nil then
            error_object = RuntimeError( "unknown error" )
        elseif isString( value ) then
            ---@cast value string
            error_object = RuntimeError( value )
        elseif not dont_break and (coroutine_running() ~= nil or debug_calledby( 2, pcall, xpcall )) then
            return glua_error( value, 0 )
        else
            error_object = RuntimeError( tostring( value ) )
        end

        local skip = math_max( 0, (stack_level or 1) - 1 )

        local stack = error_object.stack
        if stack == nil then
            stack = debug_Stack()
            error_object.stack = stack
            capture_stack( stack, skip )
        elseif stack.size == 0 then
            capture_stack( stack, skip )
        elseif stack[ 1 ].thread ~= coroutine_running() then
            local outer_stack = debug_Stack()
            capture_stack( outer_stack, skip )

            for i = 1, stack.size, 1 do
                outer_stack:push( stack[ i ] )
            end

            error_object.stack = outer_stack
        end

        if dont_break then
            report( error_object )
            return
        end

        if coroutine_running() ~= nil or debug_calledby( 2, pcall, xpcall ) then
            return glua_error( error_object, 0 )
        end

        report( error_object )
        return glua_error( ERROR_SENTINEL, 0 )
    end

    std.error = std_error
    error = std_error

    --- [SHARED AND MENU]
    ---
    --- Throws an error with the specified message and level.
    ---
    ---@param stack_level? integer The stack level to throw the error.
    ---@param dont_break? boolean If `true`, the error will not break the current stack.
    ---@param fmt string The error message to throw.
    ---@param ... any The error message arguments to format/interpolate.
    function std.errorf( stack_level, dont_break, fmt, ... )
        return std_error( string_format( fmt, ... ), stack_level, dont_break )
    end

    --- [SHARED AND MENU]
    ---
    --- Throws an error if the given expression is false.
    ---
    ---@param expression boolean The expression to check.
    ---@param fmt string The error message to throw.
    ---@param ... any The error message arguments to format/interpolate.
    function std.assert( expression, fmt, ... )
        if expression then return end

        return std_error( string_format( fmt, ... ), 1, false )
    end

    hidden_functions[ std.errorf ] = true
    hidden_functions[ std.assert ] = true

    hidden_functions[ to_error ] = true
    hidden_functions[ catch_error ] = true
    hidden_functions[ std_error ] = true
    hidden_functions[ error_handler ] = true

    -- protected calls sit between two Lua frames and carry nothing useful
    hidden_functions[ pcall ] = true
    hidden_functions[ xpcall ] = true

    ---@diagnostic disable-next-line: undefined-global
    local glua_ProtectedCall = ProtectedCall
    if glua_ProtectedCall ~= nil then
        hidden_functions[ glua_ProtectedCall ] = true
    end

    -- raisers are already skipped at the top of the stack, listed so they never show up anywhere else
    hidden_functions[ glua_error ] = true
    hidden_functions[ raw.assert ] = true

end

do

    local debug_getlocal = debug.getlocal
    local debug_getinfo = debug.getinfo

    local equal = std.equal
    local is = std.is

    local ValueError = std.ValueError
    local TypeError = std.TypeError

    --- [SHARED AND MENU]
    ---
    --- Checks that the local variable at the given stack `index` (in the calling function)
    --- matches one of the expected types/classes given in `...`. If the value's type/instance
    --- does not match any of the expected types, a `TypeError` is raised, otherwise the
    --- function returns without doing anything.
    ---
    ---@param index integer The stack index of the local variable to check (as used by `debug.getlocal`).
    ---@param ... any The expected type names (strings) or class/type tables (with an optional `__type` field) to check the value against.
    function std.checktype( index, ... )
        local value_name, value = debug_getlocal( 2, index )
        local value_type = type( value )

        local type_count = raw_select( "#", ... )

        for i = 1, type_count, 1 do
            local expected = raw_select( i, ... )
            if isString( expected ) then
                if expected == value_type then return end
            elseif equal( expected, value ) or is( value, expected ) then
                return
            end
        end

        ---@type string
        local expected_names

        for i = 1, type_count, 1 do
            local expected = raw_select( i, ... )
            if isString( expected ) then
                expected_name = expected
            elseif isTable( expected ) then
                expected_name = expected.__type or represent( expected )
            else
                expected_name = represent( expected )
            end

            if i == 1 then
                expected_names = expected_name
            else
                expected_names = expected_names .. ", " .. expected_name
            end
        end

        return error( TypeError( index, value, expected_names, value_name, debug_getinfo( 2, "n" ).name ), 2 )
    end

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
    ---     std.checkvalue( 1, is_positive )
    ---     -- ...
    --- end
    --- ```
    ---
    ---@param index integer The index of the calling function's local variable to validate (`1` = its first parameter/argument).
    ---@param ... ( fun( value: any ): true, nil ) | ( fun( value: any ): false, string ) The validators to run, in order. Each returns `true`, or `false` and an error message.
    function std.checkvalue( index, ... )
        local _, value = debug_getlocal( 2, index )

        for i = 1, raw_select( "#", ... ), 1 do
            local is_valid, error_msg = raw_select( i, ... )( value )
            if is_valid == false then
                return error( ValueError( value, error_msg ), 2 )
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- A single signature entry for `dispatch`: a list of argument types paired with the
    --- function to call when a call's arguments match those types.
    ---
    ---@generic F: function
    ---@class dreamwork.std.OverloadInput<F>
    ---@field match string[] | string The Lua type name (or ordered list of type names, as returned by `type`) that a call's arguments must have for `fn` to be selected.
    ---@field fn F The function to call when the arguments match.

    ---@generic F: function
    ---@param inputs dreamwork.std.OverloadInput[]
    ---@param ... any
    ---@return function | nil
    local function input_select( inputs, ... )
        local arg_count = raw_select( "#", ... )

        ---@type string[]
        local arg_types = {}

        for i = 1, arg_count, 1 do
            arg_types[ i ] = type( raw_select( i, ... ) )
        end

        for i = 1, inputs[ 0 ], 1 do
            local input = inputs[ i ]
            local match = input.match

            if arg_count == match[ 0 ] then
                for j = 1, arg_count, 1 do
                    if match[ j ] ~= arg_types[ j ] then
                        break
                    end

                    if j == arg_count then
                        return input.fn
                    end
                end
            end
        end

        return nil
    end

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
    --- local describe = std.dispatch( {
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
    ---@param inputs dreamwork.std.OverloadInput<F>[] The signatures to dispatch between, checked in order (first match wins).
    ---@param fallback_fn? F The function called when no input matches. If omitted, a non-matching call raises an error.
    ---@return F fn_over A function that dispatches to the matching input's `fn`, or to `fallback_fn`.
    ---@nodiscard
    function std.dispatch( inputs, fallback_fn )
        local input_count = len( inputs )
        inputs[ 0 ] = input_count

        for i = 1, input_count, 1 do
            local input = inputs[ i ]
            if not isFunction( input.fn ) then
                error( TypeError( i, input.fn, "function", "fn", "dispatch" ), 2 )
            end

            local input_match = input.match
            if input_match == nil then
                error( TypeError( i, input.fn, "string, string[]", "match", "dispatch" ), 2 )
            elseif isString( input_match ) then
                ---@cast input_match string
                input.match = { [ 0 ] = 1, input_match }
            else
                input_match[ 0 ] = len( input_match )
            end
        end

        return function( ... )
            local fn = input_select( inputs, ... )
            if fn == nil then
                if fallback_fn == nil then
                    error( "dispatch: no input matches and no fallback function", 2 )
                end

                return fallback_fn( ... )
            end

            return fn( ... )
        end
    end

    do

        local loadstring = std.loadstring

        local empty_env = {}

        setmetatable( empty_env, {
            __index = debug_fempty,
            __newindex = debug_fempty
        } )

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
        function std.junction( ... )
            local out_arg_count = raw_select( '#', ... )
            local out_args = { ... }

            local in_arg_count = 0

            for i = 1, out_arg_count, 1 do
                local value = out_args[ i ]
                if isNumber( value ) and (value % 1) == 0 then
                    out_args[ i ] = math_floor( value )
                    in_arg_count = math_max( in_arg_count, value )
                else
                    error( TypeError( i, value, "integer", "1", "junction" ), 2 )
                end
            end

            local locals, local_count = {}, 0

            for i = 1, in_arg_count, 1 do
                local_count = local_count + 1
                locals[ local_count ] = "a" .. i
            end

            local returns, return_count = {}, 0

            for i = 1, out_arg_count, 1 do
                return_count = return_count + 1
                returns[ return_count ] = "a" .. out_args[ i ]
            end

            local fn, err_msg = loadstring( "local " .. table_concat( locals, ",", 1, local_count ) .. " = ...\r\nreturn " .. table_concat( returns, ",", 1, return_count ), "junction", empty_env )
            if fn == nil then
                error( err_msg, 2 )
            end

            return fn
        end

    end

end

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
--- local describe = std.overload(
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
function std.overload( main_fn, match, overload_fn )
    local required_args = 0

    if isString( match ) then
        ---@cast match string
        required_args = 1
    else

        ---@cast match string[]

        required_args = len( match )

        if required_args == 1 then
            match = match[ 1 ]
        end

    end

    if required_args == 0 then
        return main_fn
    elseif required_args == 1 then
        ---@cast match string

        return function( ... )
            local arg_count = raw_select( "#", ... )
            if arg_count ~= 1 then
                return main_fn( ... )
            end

            if match == type( raw_select( 1, ... ) ) then
                return overload_fn( ... )
            end

            return main_fn( ... )
        end
    end

    return function( ... )
        local arg_count = raw_select( "#", ... )
        if arg_count == required_args then
            for i = 1, arg_count, 1 do
                local match_type, value_type = match[ i ], type( raw_select( i, ... ) )
                if (match_type == "number" and not (value_type == "number" or value_type == "integer")) or match_type ~= value_type then
                    return main_fn( ... )
                end
            end

            return overload_fn( ... )
        end

        return main_fn( ... )
    end
end

do

    local engine_consoleMessageColored = engine.consoleMessageColored
    local engine_consoleMessage        = engine.consoleMessage


    local string_gmatch = string.gmatch
    local string_escape = string.escape
    local string_indent = string.indent
    local string_gsub   = string.gsub
    local string_find   = string.find

    local Stack         = std.Stack


    local COLOR_SUVA_GRAY  = color_scheme.suva_gray
    local COLOR_SANDSTONE  = color_scheme.sandstone
    local COLOR_LIGHT_GRAY = color_scheme.light_gray

    --- [SHARED AND MENU]
    ---
    --- Prints the given arguments to the console.
    ---
    ---@param ... any The arguments to print.
    ---@diagnostic disable-next-line: duplicate-set-field
    function std.print( ... )
        local arg_count = raw_select( "#", ... )
        if arg_count == 0 then
            engine_consoleMessage( "\n" )
            return
        end

        if arg_count == 1 then
            engine_consoleMessage( represent( ... ) .. "\n" )
            return
        end

        ---@type string[]
        local values = {}

        for i = 1, arg_count, 1 do
            values[ i ] = represent( raw_select( i, ... ) )
        end

        engine_consoleMessage( table_concat( values, "\t", 1, arg_count ) .. "\n" )
    end

    --- [SHARED AND MENU]
    ---
    --- Prints a formatted string to the console.
    ---
    --- Basically the same as `print( string.format( fmt, ... ) )`
    ---
    ---@param fmt string The format string.
    ---@param ... any The arguments to format/interpolate.
    function std.printf( fmt, ... )
        if string_find( fmt, "%%[-+ #0]*%d*%.?%d*r" ) == nil then
            return engine_consoleMessage( string_format( fmt, ... ) .. "\n" )
        end

        local arg_count = raw_select( "#", ... )
        local args = { ... }
        local index = 1

        for key in string_gmatch( fmt, "%%[-+ #0]*%d*%.?%d*(%l)" ) do
            if index > arg_count then
                break
            elseif string_byte( key, 1, 1 ) == 0x72 --[[ r ]] then
                args[ index ] = represent( args[ index ] )
            end

            index = index + 1
        end

        return engine_consoleMessage( string_format( string_gsub( fmt, "%%r", "%%s" ), table_unpack( args, 1, arg_count ) ) .. "\n" )
    end

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
    function std.printTable( tbl, max_depth )
        if max_depth == nil then
            max_depth = 8
        end

        local output_size = 0
        local depth = 1

        ---@type ( string | dreamwork.std.Color )[]
        local output = {}

        ---@type table<table, table>
        local parents = {}

        --- last key returned by raw_next for each table on the stack
        ---@type table<table, any>
        local iter_state = {}

        ---@type dreamwork.std.Stack<table>
        local stack = Stack()

        ---@type table | nil
        local current = tbl
        stack:push( tbl )

        ---@cast current table

        ::print_table_loop::

        local prev_key = iter_state[ current ]
        local key, value = raw_next( current, prev_key )
        iter_state[ current ] = key

        if key == nil then
            -- only strip a trailing comma if this table actually had entries
            if prev_key ~= nil and output_size > 0 then
                output[ output_size - 1 ] = string_sub( output[ output_size - 1 ], 1, -3 ) .. "\n"
            end

            parents[ current ] = nil
            stack:pop()

            current = stack:peek()
            depth = depth - 1

            if current == nil then
                goto print_table_loop_finish
            end

            output[ output_size + 1 ] = string_indent( "},\n", depth * 2 )
            output[ output_size + 2 ] = COLOR_SUVA_GRAY

            output_size = output_size + 2

            goto print_table_loop
        end

        if isString( key ) then
            output[ output_size + 1 ] = string_indent( "[ \"" .. string_escape( key, true ) .. "\" ]", depth * 2 )
        elseif isNumber( key ) then
            output[ output_size + 1 ] = string_indent( string_format( "[ %g ]", key ), depth * 2 )
        else
            output[ output_size + 1 ] = string_indent( string_format( "[ %s ]", represent( key ) ), depth * 2 )
        end

        output[ output_size + 2 ] = COLOR_LIGHT_GRAY

        output[ output_size + 3 ] = " = "
        output[ output_size + 4 ] = COLOR_SUVA_GRAY

        output_size = output_size + 4

        if isTable( value ) then
            if value == tbl or parents[ value ] ~= nil then
                output[ output_size + 1 ] = represent( value )
                output[ output_size + 2 ] = COLOR_SANDSTONE

                output[ output_size + 3 ] = ",  "
                output[ output_size + 4 ] = COLOR_SUVA_GRAY

                output[ output_size + 5 ] = "-- RECURSION\n"
                output[ output_size + 6 ] = COLOR_SUVA_GRAY

                output_size = output_size + 6
            elseif (depth + 2) > max_depth then
                output[ output_size + 1 ] = represent( value )
                output[ output_size + 2 ] = COLOR_SANDSTONE

                output[ output_size + 3 ] = ",  "
                output[ output_size + 4 ] = COLOR_SUVA_GRAY

                output[ output_size + 5 ] = "-- TOO DEEP\n"
                output[ output_size + 6 ] = COLOR_SUVA_GRAY

                output_size = output_size + 6
            else
                output[ output_size + 1 ] = "{  -- " .. represent( value ) .. "\n"
                output[ output_size + 2 ] = COLOR_SUVA_GRAY

                output_size = output_size + 2
                depth = depth + 1

                parents[ value ] = current
                stack:push( value )
                current = value
            end
        else
            output[ output_size + 1 ] = represent( value )
            output[ output_size + 2 ] = COLOR_SANDSTONE

            output[ output_size + 3 ] = ",\n"
            output[ output_size + 4 ] = COLOR_SUVA_GRAY

            output_size = output_size + 4
        end

        goto print_table_loop

        ::print_table_loop_finish::

        engine_consoleMessageColored( "{\n", COLOR_SUVA_GRAY )

        for i = 1, output_size, 2 do
            ---@diagnostic disable-next-line: param-type-mismatch
            engine_consoleMessageColored( output[ i ], output[ i + 1 ] )
        end

        engine_consoleMessageColored( "}\n", COLOR_SUVA_GRAY )
    end

end

-- engine timers
dofile( "dreamwork/engine.timer.lua" )
sendfile( "dreamwork/engine.timer.lua" )

do

    local dreamwork_errorHandler = dreamwork.errorHandler
    local timer                  = engine.timer

    do

        ---@type table<integer, function>
        local timeouts          = {}

        ---@type table<integer, any[]>
        local timeout_arguments = {}

        local timeout_count     = 0

        ---@param timeout_id integer
        local function timeout_call( timeout_id )
            local fn = timeouts[ timeout_id ]
            if fn == nil then
                -- cleared
                return
            end

            local args = timeout_arguments[ timeout_id ]

            timeouts[ timeout_id ] = nil
            timeout_arguments[ timeout_id ] = nil

            if args == nil then
                xpcall( fn, dreamwork_errorHandler )
            else
                xpcall( fn, dreamwork_errorHandler, table_unpack( args, 1, args[ 0 ] ) )
            end
        end

        dreamwork.hideErrorFrame( timeout_call )

        --- [SHARED AND MENU]
        ---
        --- Calls the `fn` function after `delay` seconds.
        ---
        --- **Usage example:**
        ---
        --- ```lua
        --- std.setTimeout( function()
        ---     print( "Hello, world!" )
        --- end, 5 ) -- Calls the function after 5 seconds.
        --- ```
        ---
        ---@param fn function The callback function.
        ---@param delay? number The delay in seconds, default is `0`.
        ---@param ... any Additional arguments to pass to the callback function.
        ---@return integer timeout_id The identifier of the timeout, used to cancel it with `std.clearTimeout`.
        function std.setTimeout( fn, delay, ... )
            timeout_count = timeout_count + 1

            local timeout_id = timeout_count
            timeouts[ timeout_id ] = fn

            local arg_count = raw_select( "#", ... )
            if arg_count ~= 0 then
                timeout_arguments[ timeout_id ] = { [ 0 ] = arg_count, ... }
            end

            timer.simple( delay or 0, function()
                return timeout_call( timeout_id )
            end )

            return timeout_id
        end

        --- [SHARED AND MENU]
        ---
        --- Cancels a timeout created by `std.setTimeout`, so its callback will not be called.
        ---
        --- **Usage example:**
        ---
        --- ```lua
        --- local timeout_id = std.setTimeout( function()
        ---     print( "This will never be printed." )
        --- end, 5 )
        ---
        --- std.clearTimeout( timeout_id )
        --- ```
        ---
        ---@param timeout_id integer The identifier of the timeout returned by `std.setTimeout`.
        ---@return boolean is_cleared Returns `true` if the timeout was found and cancelled, otherwise `false`.
        function std.clearTimeout( timeout_id )
            local fn = timeouts[ timeout_id ]
            if fn == nil then
                return false
            end

            timeout_arguments[ timeout_id ] = nil
            timeouts[ timeout_id ] = nil

            return true
        end

    end

    do

        local interval_count = 0

        --- [SHARED AND MENU]
        ---
        --- Calls the `fn` function every `delay` seconds, until the interval is cancelled with `std.clearInterval`.
        ---
        --- **Usage example:**
        ---
        --- ```lua
        --- local interval_id = std.setInterval( function()
        ---     print( "Hello, world!" )
        --- end, 1 ) -- Calls the function every second.
        ---
        --- std.setTimeout( function()
        ---     std.clearInterval( interval_id )
        --- end, 5 ) -- Stops it after 5 seconds.
        --- ```
        ---
        ---@param fn function The callback function.
        ---@param delay? number The delay between calls in seconds, default is `1`.
        ---@param ... any Additional arguments to pass to the callback function.
        ---@return integer interval_id The identifier of the interval, used to cancel it with `std.clearInterval`.
        function std.setInterval( fn, delay, ... )
            interval_count = interval_count + 1

            local arg_count = raw_select( "#", ... )
            if arg_count ~= 0 then
                local args = { ... }
                local callback = fn

                function fn()
                    return callback( table_unpack( args, 1, arg_count ) )
                end
            end

            local name = string_format( "dreamwork.interval.%d", interval_count )
            timer.create( name, delay or 1, 0, fn )
            timer.start( name )

            return interval_count
        end

        --- [SHARED AND MENU]
        ---
        --- Cancels an interval created by `std.setInterval`, so its callback will not be called anymore.
        ---
        --- **Usage example:**
        ---
        --- ```lua
        --- local interval_id = std.setInterval( function()
        ---     print( "Hello, world!" )
        --- end, 1 )
        ---
        --- std.clearInterval( interval_id )
        --- ```
        ---
        ---@param interval_id integer The identifier of the interval returned by `std.setInterval`.
        ---@return boolean is_cleared Returns `true` if the interval was found and cancelled, otherwise `false`.
        function std.clearInterval( interval_id )
            return timer.remove( string_format( "dreamwork.interval.%d", interval_id ) )
        end

    end

end

-- futures library
dofile( "dreamwork/std/futures.lua" )
sendfile( "dreamwork/std/futures.lua" )

do

    local futures = std.futures
    local futures_sleep = futures.sleep
    local futures_running = futures.running

    --- [SHARED AND MENU]
    ---
    --- Puts current thread to sleep for given amount of seconds.
    ---
    --- **CAUTION**: This function could pause the main thread.
    ---
    ---@see dreamwork.std.futures.sleep
    ---@param seconds number
    function std.sleep( seconds )
        if futures_running() == nil then -- main thread
            local deadline = dreamwork_getUpTime() + seconds
            while dreamwork_getUpTime() < deadline do end

            return
        end

        futures_sleep( seconds ) -- second thread
    end

end

-- json encoding library
dofile( "dreamwork/std/codec/json.lua" )
sendfile( "dreamwork/std/codec/json.lua" )

-- xml encoding library
dofile( "dreamwork/std/codec/xml.lua" )
sendfile( "dreamwork/std/codec/xml.lua" )

-- vdf encoding library
dofile( "dreamwork/std/codec/vdf.lua" )
sendfile( "dreamwork/std/codec/vdf.lua" )

-- url class
dofile( "dreamwork/std/types/url.lua" )
sendfile( "dreamwork/std/types/url.lua" )

--- [SHARED AND MENU]
---
--- A collection of cryptographic utilities.
---
---@class dreamwork.std.crypto
std.crypto = std.crypto or {}

-- md5 hash library
dofile( "dreamwork/std/crypto/md5.lua" )
sendfile( "dreamwork/std/crypto/md5.lua" )

-- sha1 hash library
dofile( "dreamwork/std/crypto/sha1.lua" )
sendfile( "dreamwork/std/crypto/sha1.lua" )

-- sha256 hash library
dofile( "dreamwork/std/crypto/sha256.lua" )
sendfile( "dreamwork/std/crypto/sha256.lua" )

-- sha512 hash library
dofile( "dreamwork/std/crypto/sha512.lua" )
sendfile( "dreamwork/std/crypto/sha512.lua" )

-- sha384 hash library
dofile( "dreamwork/std/crypto/sha384.lua" )
sendfile( "dreamwork/std/crypto/sha384.lua" )

-- hmac library
dofile( "dreamwork/std/crypto/hmac.lua" )
sendfile( "dreamwork/std/crypto/hmac.lua" )

-- pbkdf2 library
dofile( "dreamwork/std/crypto/pbkdf2.lua" )
sendfile( "dreamwork/std/crypto/pbkdf2.lua" )

-- hkdf library
dofile( "dreamwork/std/crypto/hkdf.lua" )
sendfile( "dreamwork/std/crypto/hkdf.lua" )

-- chacha20 and xchacha20 stream ciphers
dofile( "dreamwork/std/crypto/chacha20.lua" )
sendfile( "dreamwork/std/crypto/chacha20.lua" )

-- cryptographically secure random
dofile( "dreamwork/std/crypto/random.lua" )
sendfile( "dreamwork/std/crypto/random.lua" )

-- uuid library
dofile( "dreamwork/std/uuid.lua" )
sendfile( "dreamwork/std/uuid.lua" )

-- mixin
dofile( "dreamwork/std/types/mixin.lua" )
sendfile( "dreamwork/std/types/mixin.lua" )

-- hook class
dofile( "dreamwork/std/types/hook.lua" )
sendfile( "dreamwork/std/types/hook.lua" )

-- timer class
dofile( "dreamwork/std/types/timer.lua" )
sendfile( "dreamwork/std/types/timer.lua" )

if dreamwork.TickTimer0_05 == nil then
    local timer = std.Timer( 0.05, 0, dreamwork.Prefix .. "::TickTimer0_05" )
    dreamwork.TickTimer0_05 = timer
    timer:start()
end

if dreamwork.TickTimer0_1 == nil then
    local timer = std.Timer( 0.1, 0, dreamwork.Prefix .. "::TickTimer0_1" )
    dreamwork.TickTimer0_1 = timer
    timer:start()
end

if dreamwork.TickTimer0_25 == nil then
    local timer = std.Timer( 0.25, 0, dreamwork.Prefix .. "::TickTimer0_25" )
    dreamwork.TickTimer0_25 = timer
    timer:start()
end

if dreamwork.TickTimer1 == nil then
    local timer = std.Timer( 1, 0, dreamwork.Prefix .. "::TickTimer1" )
    dreamwork.TickTimer1 = timer
    timer:start()
end

do

    ---@class dreamwork.std
    ---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
    ---@field SYSTEM_HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
    ---@field SYSTEM_BATTERY_LEVEL garrysmod.system.BatteryPower The battery level, from `0` to `100`.

    local glua_system = system or {}

    std.SYSTEM_COUNTRY = string.lower( (glua_system.GetCountry or debug_fempty)() or "eu" )

    std.SYSTEM_HAS_BATTERY = false
    std.SYSTEM_BATTERY_LEVEL = 100

    local system_BatteryPower = glua_system.BatteryPower
    if system_BatteryPower ~= nil then

        ---@type number
        local previous_value

        dreamwork.TickTimer1:attach( function()
            local value = system_BatteryPower() or 255
            if previous_value == value then return end

            previous_value = value

            if value == 255 then
                std.SYSTEM_HAS_BATTERY = false
                std.SYSTEM_BATTERY_LEVEL = 100
                return
            end

            if value == 0 then
                std.SYSTEM_HAS_BATTERY = true
                std.SYSTEM_BATTERY_LEVEL = 0
                return
            end

            std.SYSTEM_HAS_BATTERY = true
            std.SYSTEM_BATTERY_LEVEL = math_floor( value / 100 )
        end )

    end

    if LUA_CLIENT_MENU then
        dofile( "dreamwork/std/gfx/window.lua" )
    end

    sendfile( "dreamwork/std/gfx/window.lua" )

end

-- 2d vector class
dofile( "dreamwork/std/types/vector2.lua" )
sendfile( "dreamwork/std/types/vector2.lua" )

-- 3d vector class
dofile( "dreamwork/std/types/vector3.lua" )
sendfile( "dreamwork/std/types/vector3.lua" )

-- 3d angle class
dofile( "dreamwork/std/types/angle3.lua" )
sendfile( "dreamwork/std/types/angle3.lua" )

-- quaternion class
dofile( "dreamwork/std/types/quaternion.lua" )
sendfile( "dreamwork/std/types/quaternion.lua" )

-- valve matrix class
dofile( "dreamwork/std/types/vmatrix.lua" )
sendfile( "dreamwork/std/types/vmatrix.lua" )

-- engine console library
dofile( "dreamwork/std/io/console.lua" )
sendfile( "dreamwork/std/io/console.lua" )

local console = std.console

if os.exit == nil then

    --- [SHARED AND MENU]
    ---
    --- Calls the ISO C function exit to terminate the host program.
    ---
    function os.exit()
        console.Command.run( "_restart" )
    end

end

local developer = console.Variable.get( "developer", "integer" )
if developer == nil then
    std.DEVELOPER = 1
else
    developer:attach( function( value )
        std.DEVELOPER = value
    end )

    std.DEVELOPER = developer.value
end

local logger = console.Logger( {
    color = color_scheme.dreamwork_main,
    title = dreamwork.Prefix,
    interpolation = false
} )

dreamwork.Logger = logger

-- file system library
dofile( "std/io/fs.lua" )
sendfile( "std/io/fs.lua" )

-- lzw compression library
dofile( "dreamwork/std/compress/lzw.lua" )
sendfile( "dreamwork/std/compress/lzw.lua" )

-- lz4 compression library
dofile( "dreamwork/std/compress/lz4.lua" )
sendfile( "dreamwork/std/compress/lz4.lua" )

-- deflate compression library
dofile( "dreamwork/std/compress/deflate.lua" )
sendfile( "dreamwork/std/compress/deflate.lua" )

-- lzma compression library
dofile( "dreamwork/std/compress/lzma.lua" )
sendfile( "dreamwork/std/compress/lzma.lua" )

-- sqlite library
dofile( "std/db/sqlite.lua" )
sendfile( "std/db/sqlite.lua" )

-- Welcome message
do

    local variables = {}

    local cvar = console.Variable.get( LUA_SERVER and "hostname" or "name", "string" )
    if cvar ~= nil then
        local value = cvar.value
        if not string.isEmpty( value ) and value ~= "unnamed" then
            variables.username = value
        end
    end

    if variables.username == nil then
        variables.username = std.DEVELOPER ~= 0 and "develoer" or "stranger"
    end

    local splashes = {
        "We'll Sandblast these walls and paint them again ♪",
        ";fix these broken wings, then show me how to fly ♪",
        "And I feel like I could spread my wings and fly ♪",
        "They'll wait for me to fall under the pressure ♪",
        "nf2ca53pnz2caytfebzw6idfmfzxsidun4qho2lo * 0.5",
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "Woah-oh-oh, tell me where you wanna go ♪",
        "Let's write our names here in the sky ♪",
        "We will have a great Future together.",
        "Millions of pieces without a tether ♪",
        "It always seems time is on the side ♪",
        "Why are we always looking for more ♪",
        "Never forget to finish your Task's!",
        "They'll wait for me to give it up ♪",
        "I don't care who I'm meant to be ♪",
        "Take it in and breathe the light ♪",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "I'm tired of these darker days ♪",
        "Don't worry, {username} :>",
        "Big Brother is watching you",
        "As we build it once agai1n ♪",
        "I'm turning the lights on ♪",
        "I'm calling out for help ♪",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, {username}!",
        "Dream + Framework = <3",
        "We need more packages!",
        "Pew-pew-pew-pew-pew! ♪",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Let the sun arise ♪",
        "Looking For More ♪",
        "I'm watching you.",
        "Faster than ever.",
        "Love Wins Again ♪",
        "Made with love <3",
        "I burn my sky ♪",
        "Blazing fast ☄",
        "Ancient Tech ♪",
        "Here For You ♪",
        "Good Enough ♪",
        "Manifest It ♪",
        "MAKE A MOVE ♪",
        "v" .. dreamwork.Version,
        "Hello World!",
        "all_the_same",
        "Star Glide ♪",
        "Once Again ♪",
        "Without Us ♪",
        "Data Loss ♪",
        "Sandblast ♪",
        "Now on LLS!",
        "That's me!",
        "I see you.",
        "Light Up ♪",
        "Majesty ♪",
        "Eat Me ♪",
        "FLY ♪",
        "𓆤"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, there are over " .. (count - 1) .. " splashes here!"

    local scheme

    if std.SYSTEM_WINDOWS --[[ ha-ha microslop ]] and false --[[proton is broken]] then
        scheme = {
            "       / *    .      +                                                         ⣀⣀⣤⠤⢤⣀⠀ ",
            "  .   /                        /  '           '                         ⢀⣠⠴⠒⢋⣉⣀⣠⣄⣀⣈⡇   ",
            "     *   .         '          /           *                   ⠀⠀⠀⠀⣠⣴⣾⣯⠴⠚⠉⠉⠀⠀⠀⠀⣤⠏⣿      ",
            "   *    * %s                                                 ⠀⣠⣴⡿⠿⢛⠁⠁⣸⠀⠀⠀⠀⠀⣤⣾⠵⠚⠁      ",
            "'                +   +                    _|_     '    *  ⠀⣠⣴⠿⠋⠁⠀⠀⠀⠀⠘⣿⠀⣀⡠⠞⠛⠁⠂⠁⠀⠀      ",
            "       .                             .      |         ⠀⠀⣀⣴⠟⠋⠁⠀⠀⠀⠀⠐⠠⡤⣾⣙⣶⡶⠃⠀⠀⠀⠀⠀⠀⠀       ",
            "⠉                ____    o  +   .    +                ⣤⢾⣋⠉        __ ⡴⢿⢛⠃              ",
            "⠄       o       / __ \\_____ __  __ _ _ __ _____     ⣴⡼⢏⠑__  _____/ /__ ⢿               ",
            "⠂⠂      .      / / / /⠁⠁⠁//_ \\/ _` | '_ ` _ \\ \\ /\\ / / _  \\/ ___/ //_/                 ",
            "⠁   +       ⣀⣴/ /_/ / /⠞⠁/ __/ (_) | | | | | \\ V  V / (_) / /  / ,<                    ",
            "         ⣠⢴⣿⠟/_____/_/  ⠞\\___|\\__,_|_| |_| |_|\\_/\\_/ \\___/_/  /_/|_|                   ",
            "⠀⠀⠀⠀⠀⢀⡴⢏⡵⠛⠀⠀⠀⠀⠀⠀⠀⣀⣴⠞⠛                                                                  ",
            "⠀⠀⠀⣀⣼⠛⣲⡏⠁⠀⠀⠀⠀⠀⢀⣠⡾⠋⠉⠁⠁⠁        .-.    o  +   .    |                                     ",
            "⠀⠀⡴⠟⠀⢰⡯⠄⠀⠀⠀⠀⣠⢴⠟⠉ ⠁              ) )             --o--                                  ",
            "⠀⡾⠁⠁⠀⠘⠧⠤⢤⣤⠶⠏⠙⠁    *     *       '-´   ⠁   ⠁    ⠁  |                                    ",
            "⠘⣇⠂⢀⣀⣀⠤⠞⠋                                                                              ",
            "⠀⠈⠉⠉⠉     .      +                      *   '      '        +                          ",
            "╭────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       ",
            "┊  GitHub: https://github.com/Pika-Software                                            ",
            "┊  Discord: https://discord.gg/Gzak99XGvv                                              ",
            "┊  Website: https://p1ka.eu                                                            ",
            "┊  Developers: Pika Software                                                           ",
            "┊  License: MIT                                                                        ",
            "╰────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       "
        }
    else
        scheme = {
            "               /          .      +           /                                    ",
            "          .   *                             /  '           '     .                ",
            "   .             .             '           /           *                `         ",
            "                     +                    *        *                         .    ",
            "     '              /                                 _|_     '    *              ",
            "           ,       +            .            .         |              +     |     ",
            "            '       \\            \\                       .     '          --o--   ",
            "  `      * .         +            \\          ,                         '    |     ",
            "             ____                  \\        __        __            __            ",
            "    .       / __ \\ ____ __   __ __  __ ____\\  \\      /  /___  _____/ /__ ` .     .",
            "   /   .   / / / / __// _ \\ /  _` || '_ ` _ \\  \\ __ /  / _  \\/ ___/ //_/  `     / ",
            "  /   /   / /_/ / /  /  __//  (_) || | | | | \\  V  V  / (_) / /  / ,<\\         /  ",
            " *   *   /_____/_/   \\ ___|\\ __/__||_| |_| |_|\\ _/\\_/ \\ ___/_/  /_/|_|        /   ",
            "  ,                 .      +              \\                 '                *    ",
            "       +         \\  %s                                                  `          ",
            "  .               \\              *           \\               *              ,     ",
            "     .-.    `      *                          *        |         '                ",
            "      ) )               *     '                      --o--         ,   +          ",
            "     '-´                           *                   |                          ",
            "         '        +           *           *   '               +                   ",
            "|>|================================================= ` .                          ",
            "|=| -  GitHub:   https://github.com/Pika-Software  /  `                           ",
            "|<| - Discord:   https://discord.gg/Gzak99XGvv    /                               ",
            "|=| - Website:   https://p1ka.eu                 /                                ",
            "|<| - DevTeam:   Pika Software                  /                                 ",
            "|=| - License:   MIT                           /                                  ",
            "|>|___________________________________________/                                   "
        }
    end

    local welcome_art = string.gsub( table_concat( scheme, "\n", 1 ), "%%s" .. string.rep( " ", 50 - 1 ), "%%s" )
    local splash = string.interpolate( splashes[ math.random( 1, count ) ], variables )

    console.write( color_scheme.realm, string_format( "\n" .. welcome_art .. "\n\n", std.unicode.pad( splash, 50, " ", true, true ) ) )

end

if isFunction( holylib.GetRegistry ) then
    -- https://github.com/RaphaelIT7/gmod-holylib
    debug.setregistry( holylib.GetRegistry() )
    logger:info( "`holylib` was connected, enjoy full access to `debug.getregistry`." )
elseif std.loadbinary( "getregistry" ) and getregistry ~= nil then
    -- https://github.com/wrefgtzweve/gm_getregistry
    debug.setregistry( (getregistry.Get or debug.getregistry)() )
    logger:info( "`gm_getregistry` was loaded & connected, enjoy full access to `debug.getregistry`." )
end

if ffi ~= nil then
    if not ffi.SANDBOXED then
        logger:warn( "FFI is in unsafe mode, raw memory access is enabled and FFI fast paths are used." )
    elseif ffi.string ~= nil then
        logger:warn( "FFI is in safe mode (sandboxed), `ffi.C` and `ffi.load` are disabled, raw memory functions are emulated with `string.buffer`." )
    else
        logger:warn( "FFI is in safe mode (sandboxed), raw memory access is disabled and FFI fast paths fall back to pure Lua." )
    end
end

do

    ---@type fun( bytecode: string ): function | nil
    local load_bytecode

    local load = load or loadstring
    if load ~= nil and jit.isFFI( load ) then
        function load_bytecode( bytecode )
            return load( bytecode, "=(load)", "b" )
        end

        logger:debug( "Native bytecode compilation is available, skipping custom implementation." )
    end

    -- https://github.com/willox/gmbc
    if load_bytecode == nil then
        if std.loadbinary( "gmbc" ) then
            logger:info( "'gmbc' was loaded & connected as LuaJIT bytecode compiler." )
            load_bytecode = gmbc_load_bytecode
        else
            function load_bytecode()
                return error( "bytecode compilation not available.", 1 )
            end

            logger:warn( "'gmbc' is missing, bytecode compilation not available." )
        end
    end

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
    function std.loadbytecode( bytecode, env )
        local success, result = pcall( load_bytecode, bytecode )
        if success and result ~= nil then
            ---@cast result function
            setfenv( result, env or getfenv( 2 ) )
            return result, nil
        end

        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast result string | nil
        return nil, result or "unknown error"
    end

end

---@param game_info dreamwork.engine.GameInfo
---@param is_mounted boolean
engine.hookCatch( "dreamwork.game.mount", "logs", function( game_info, is_mounted )
    logger:debug( "Game '%s' (AppID: %d) was %s.", game_info.folder, game_info.depot, is_mounted and "mounted" or "unmounted" )
end )

---@param addon_info dreamwork.engine.AddonInfo
---@param is_mounted boolean
engine.hookCatch( "dreamwork.addon.mount", "logs", function( addon_info, is_mounted )
    logger:debug( "Addon '%s' (%d) was %s.", addon_info.title, addon_info.index, is_mounted and "mounted" or "unmounted" )
end )

do

    local changes_timeout = std.Timer( 0.5, 1, dreamwork.Prefix .. "::ContentWatcher" )

    local function perform_synchronization()
        logger:debug( "Game content change triggered, synchronization..." )
        time.tick( "ms", false )

        local game_changes, addon_changes = engine.hookCall( "dreamwork.content.update" )

        if game_changes == 0 and addon_changes == 0 then
            logger:debug( "No changes found, skipped." )
        else
            logger:debug( "Synchronization finished with %d game(s) and %d addon(s) in %d ms.", game_changes, addon_changes, time.tick( "ms", false ) )
        end
    end

    changes_timeout:attach( perform_synchronization )
    perform_synchronization()

    engine.hookCatch( "GameContentChanged", "dreamwork.content.update", function()
        changes_timeout:start()
    end, -1000 )

end

logger:info( "%d game(s) and %d add-on(s) mounted to game.", engine.GameCount, engine.AddonCount )

std.FRAME_TIME = 1 / 60
std.FPS = 60

---@diagnostic disable-next-line: undefined-global
if LUA_CLIENT and CurTime ~= nil then

    ---@diagnostic disable-next-line: undefined-global
    local CurTime = CurTime

    local last_call = CurTime()

    engine.hookCatch( "PreRender", "dreamwork.frame_counter", function()
        local elapsed_time = CurTime()

        local frame_time = elapsed_time - last_call
        last_call = elapsed_time

        std.FRAME_TIME = frame_time
        std.FPS = 1 / frame_time
    end, 1000 )

end

--- [SHARED AND MENU]
---
---
---
---@param package_name string
---@param package_version string
---@return any
function std.import( package_name, package_version )
    -- TODO: implement
end

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
function std.dofile( file_path, ... )
    -- TODO: reimplement
end

--- [SHARED AND MENU]
---
--- Loads the given module, returns any value returned by the searcher(`true` when `nil`). Besides that value, also returns as a second result the loader data returned by the searcher, which indicates how `require` found the module. (For instance, if the module came from a file, this loader data is the file path.)
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-require)
---
---@param modname string
---@param ... any
---@return ...
function std.require( modname, ... )
    -- TODO: reimplement
end

local total_memory = gc.getMemory()
logger:info( "Start-up time: %.2f ms, memory used during startup: %.02f MB.", (dreamwork_getUpTime() - dreamwork.InitTime) * 1000, (total_memory - startup_memory) / 1024 )

-- Memory clean-up
time.tick( "ms" )
gc.collect()

local cleanup_memory = gc.getMemory()
logger:info( "Clean-up finished, took %.2f ms, cleaned up %.02f MB of garbage, total memory used by LuaJIT: %.02f MB.", time.tick( "ms" ), (total_memory - cleanup_memory) / 1024, cleanup_memory / 1024 )

-- TODO: Globally replace all versions, steamids, url, etc. with their classes in dreamwork, e.g. std.URL, steam.Identifier

-- TODO: few ideas from https://gitlab.com/DBotThePony/DLib/-/blob/develop/lua_src/dlib/extensions/extensions.lua?ref_type=heads

-- TODO: enums https://gitlab.com/DBotThePony/DLib/-/blob/develop/lua_src/dlib/enums/sdk.lua?ref_type=heads maybe maybe https://gitlab.com/DBotThePony/DLib/-/blob/develop/lua_src/dlib/enums/gmod.lua?ref_type=heads
