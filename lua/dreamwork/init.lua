local version = "0.1.0"

---@class _G
local _G = _G

---@class dreamwork
---@field VERSION string Package manager version in semver format.
---@field PREFIX string Package manager unique prefix.
---@field StartTime number Time point when package manager was started in seconds.
local dreamwork = _G.dreamwork
if dreamwork == nil then
    ---@class dreamwork
    dreamwork = {}
    _G.dreamwork = dreamwork
end

-- TODO: globally replace all versions, steamids, url, etc. with their classes in dreamwork, e.g. std.URL, steam.Identifier
-- TODO: add https://eprosync.github.io/interstellar-docs/ support

--- [SHARED AND MENU]
---
--- dreamwork standard environment
---
---@class dreamwork.std
---@field LUA_VERSION string The version of the Lua interpreter.
---@field LUA_MENU boolean `true` if code is running on the menu, `false` otherwise.
---@field LUA_CLIENT boolean `true` if code is running on the client, `false` otherwise.
---@field LUA_CLIENT_MENU boolean `true` if code is running on the client or menu, `false` otherwise.
---@field LUA_CLIENT_SERVER boolean `true` if code is running on the client or server, `false` otherwise.
---@field LUA_SERVER boolean `true` if code is running on the server, `false` otherwise.
---@field GAME_VERSION integer Contains the version number of the game. For example: `201211` = `01.01.2012`
---@field GAME_BRANCH string The branch the game is running on. This will be `unknown` on main branch.
---@field SYSTEM_ENDIANNESS boolean `true` if the operating system is big endianness, `false` if little endianness.
---@field SYSTEM_COUNTRY string The country code of the operating system. (ISO 3166-1 alpha-2)
---@field SYSTEM_HAS_BATTERY boolean `true` if the operating system has a battery, `false` if not.
---@field SYSTEM_BATTERY_LEVEL integer The battery level, from `0` to `100`.
---@field OSX boolean `true` if the game is running on OSX.
---@field LINUX boolean `true` if the game is running on Linux.
---@field WINDOWS boolean `true` if the game is running on Windows.
---@field x64 boolean `true` if the game is running on 64-bit architecture.
---@field x32 boolean `true` if the game is running on 32-bit architecture.
---@field x86 boolean `true` if the game is running on 32-bit architecture.
---@field DEVELOPER integer A cached value of `developer` console variable.
---@field FRAME_TIME number The time it takes to run one frame in seconds. **Client-only**
---@field FPS number The number of frames per second. **Client-only**
local std = dreamwork.std
if std == nil then
    ---@class dreamwork.std
    std = {}
    dreamwork.std = std
end

std.LUA_VERSION = _G._VERSION or "unknown"

---@diagnostic disable-next-line: assign-type-mismatch
std.GAME_VERSION = _G.VERSION or 0
std.GAME_BRANCH = _G.BRANCH or "unknown"

local LUA_MENU = _G.MENU_DLL == true
std.LUA_MENU = LUA_MENU

local LUA_CLIENT = _G.CLIENT == true and not LUA_MENU
std.LUA_CLIENT = LUA_CLIENT

local LUA_SERVER = _G.SERVER == true and not LUA_MENU
std.LUA_SERVER = LUA_SERVER

local LUA_CLIENT_MENU = LUA_CLIENT or LUA_MENU
std.LUA_CLIENT_MENU = LUA_CLIENT_MENU

local LUA_MENU_SERVER = LUA_SERVER or LUA_MENU
std.LUA_MENU_SERVER = LUA_MENU_SERVER

local LUA_CLIENT_SERVER = LUA_CLIENT or LUA_SERVER
std.LUA_CLIENT_SERVER = LUA_CLIENT_SERVER

---@diagnostic disable-next-line: undefined-field
local dofile = _G.include or _G.dofile
local error = _G.error

if dofile == nil then
    error( "Functions `dofile` & `include` not found, dreamwork cannot be loaded!" )
end

---@diagnostic disable-next-line: undefined-field
local os_clock = _G.SysTime

if os_clock == nil then
    local os = _G.os
    if os ~= nil then
        os_clock = os.clock or os.time
    end

    if os_clock == nil then
        error( "Functions `os.clock` or `os.time` not found, dreamwork cannot be loaded!" )
    end
end

dreamwork.StartTime = os_clock()

dreamwork.VERSION = version
dreamwork.PREFIX = "dreamwork@" .. version

dofile( "detour.lua" )

--- [SHARED AND MENU]
---
--- Library containing functions for working with raw data. (ignoring metatables)
---@class dreamwork.std.raw
local raw = std.raw or {}
std.raw = raw

raw.tonumber = _G.tonumber
raw.error = error

raw.ipairs = _G.ipairs
raw.pairs = _G.pairs

raw.equal = _G.rawequal

local raw_get = _G.rawget
raw.get = raw_get

raw.set = _G.rawset
raw.len = _G.rawlen

if raw.len == nil then

    function raw.len( value )
        return #value
    end

end

do

    local dummy_table = {}

    raw.inext = raw.ipairs( dummy_table )
    raw.next = _G.next or raw.pairs( dummy_table )

    dummy_table = nil

end

std.assert = _G.assert

local print = _G.print
std.print = print

local select = _G.select
std.select = select

local tostring = _G.tostring
std.tostring = tostring

std.getmetatable = _G.getmetatable
std.setmetatable = _G.setmetatable

std.getfenv = _G.getfenv -- removed in Lua 5.2
std.setfenv = _G.setfenv -- removed in Lua 5.2

std.xpcall = _G.xpcall
std.pcall = _G.pcall

-- client-side files
if LUA_SERVER then

    ---@diagnostic disable-next-line: undefined-field
    local AddCSLuaFile = _G.AddCSLuaFile

    ---@diagnostic disable-next-line: undefined-field
    local file_Find = _G.file.Find

    if AddCSLuaFile ~= nil and file_Find ~= nil then

        local dreamwork_files = file_Find( "dreamwork/*", "lsv" )

        for i = 1, #dreamwork_files, 1 do
            AddCSLuaFile( dreamwork_files[ i ] )
        end

        local std_files = file_Find( "dreamwork/std/*", "lsv" )

        for i = 1, #std_files, 1 do
            AddCSLuaFile( "std/" .. std_files[ i ] )
        end

        local loader_files = file_Find( "dreamwork/loader/*", "lsv" )

        for i = 1, #loader_files, 1 do
            AddCSLuaFile( "loader/" .. loader_files[ i ] )
        end

        local plugins = file_Find( "dreamwork/plugins/*", "lsv" )

        for i = 1, #plugins, 1 do
            AddCSLuaFile( "plugins/" .. plugins[ i ] )
        end

    end

end

dofile( "std/debug.lua" )
dofile( "std/debug.gc.lua" )
dofile( "std/debug.jit.lua" )

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getinfo = debug.getinfo
local debug_getmetatable = debug.getmetatable
local debug_getmetavalue = debug.getmetavalue

local setmetatable = std.setmetatable

std.OSX = std.JIT_OS == "OSX"
std.LINUX = std.JIT_OS == "Linux"
std.WINDOWS = std.JIT_OS == "Windows"

std.x64 = string.match( std.JIT_ARCH, "64" ) ~= nil
std.x32 = not std.x64
std.x86 = std.x32

---@class dreamwork.transducers
local transducers = dreamwork.transducers
if transducers == nil then

    --- [SHARED AND MENU]
    ---
    --- The magical table that transform glua objects into dreamwork objects.
    ---
    ---@class dreamwork.transducers : table
    transducers = {}

    setmetatable( transducers, {
        __index = function( self, value )
            local metatable = debug_getmetatable( value )
            if metatable == nil then
                return value
            end

            local fn = raw_get( self, metatable )
            if fn == nil then
                return value
            else
                return fn( value )
            end
        end
    } )

    dreamwork.transducers = transducers

end

--- [SHARED AND MENU]
---
--- Returns the length of the given value.
---
---@param value any The value to get the length of.
---@return integer length The length of the given value.
function std.len( value )
    ---@type nil | fun( value: any ): integer
    local fn = debug_getmetavalue( value, "__len" )
    if fn == nil then
        return #value
    else
        return fn( value )
    end
end

do

    local raw_next = raw.next

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
    ---@param tbl table
    ---@param key any
    ---@return any, any
    function std.next( tbl, key )
        return ( debug_getmetavalue( tbl, "__pairs" ) or raw_next )( tbl, key )
    end

end

do

    local raw_pairs = raw.pairs

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
    ---@generic T: table, K, V
    ---@param t T
    ---@return fun( table: table<K, V>, index?: K ):K, V
    ---@return T
    function std.pairs( t )
        local next_fn = debug_getmetavalue( t, "__pairs" )
        if next_fn == nil then
            return raw_pairs( t )
        else
            return next_fn( t, nil ), t
        end
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- Returns the next value in the table `t`, with the given `index`.
    ---
    ---@param tbl table
    ---@param index integer
    ---@return integer | nil, any
    local function inext( tbl, index )
        index = index + 1

        local value = tbl[ index ]
        if value == nil then
            return nil, nil
        else
            return index, value
        end
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
    ---@generic T: table, V
    ---@param t T
    ---@return fun( table: V[], i?: integer ): integer, V
    ---@return T
    ---@return integer i
    function std.ipairs( t )
        if debug_getmetavalue( t, "__index" ) == nil then
            return raw_ipairs( t )
        else
            return inext, t, 0
        end
    end

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
---@param base? integer The number base, default is `10`.
---@return number | nil x The number value of `e`, or `nil` if `e` cannot be converted to a number.
function std.tonumber( e, base )
    local fn = debug_getmetavalue( e, "__tonumber" )
    if fn == nil then
        return nil
    else
        return fn( e, base or 10 )
    end
end

--- [SHARED AND MENU]
---
--- If `e` has a metamethod `__toboolean`, calls it with `e` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param e any
---@return boolean?
function std.toboolean( e )
    if e == nil or e == false then
        return false
    end

    local fn = debug_getmetavalue( e, "__toboolean" )
    if fn == nil then
        return nil
    else
        return fn( e )
    end
end

-- Alias for lazy developers
std.tobool = std.toboolean

--- [SHARED AND MENU]
---
--- If `value` has a metamethod `__tocolor`, calls it with `value` as argument and returns its result.
---
--- Otherwise, returns `nil`.
---
---@param value any The valueect to convert to a color.
---@return dreamwork.std.Color | nil clr The color value of `value`, or `nil` if `value` cannot be converted to a color.
function std.tocolor( value )
    local fn = debug_getmetavalue( value, "__tocolor" )
    if fn == nil then
        return nil
    else
        return fn( value )
    end
end

--- [SHARED AND MENU]
---
--- Checks if the value is valid.
---@param value any The value to check.
---@return boolean is_valid Returns `true` if the value is valid, otherwise `false`.
function std.isvalid( value )
    local fn = debug_getmetavalue( value, "__isvalid" )
    if fn == nil then
        return false
    else
        return fn( value )
    end
end

--- [SHARED AND MENU]
---
--- coroutine library
---
--- Coroutines are similar to threads, however they do not run simultaneously.
---
--- They offer a way to split up tasks and dynamically pause & resume functions.
---
---@class dreamwork.std.coroutine
local coroutine = std.coroutine or {}
std.coroutine = coroutine

do

    local glua_coroutine = _G.coroutine
    if glua_coroutine == nil then
        error( "The `coroutine` library not found, dreamwork cannot be loaded!" )
    end

    coroutine.create = coroutine.create or glua_coroutine.create
    coroutine.resume = coroutine.resume or glua_coroutine.resume
    coroutine.running = coroutine.running or glua_coroutine.running
    coroutine.status = coroutine.status or glua_coroutine.status
    coroutine.wrap = coroutine.wrap or glua_coroutine.wrap
    coroutine.yield = coroutine.yield or glua_coroutine.yield

    ---@diagnostic disable-next-line: deprecated
    coroutine.isyieldable = coroutine.isyieldable or glua_coroutine.isyieldable

    if coroutine.isyieldable == nil then

        local coroutine_running = coroutine.running
        local coroutine_status = coroutine.status

        --- [SHARED AND MENU]
        ---
        --- Returns `true` when the running coroutine can yield.
        ---
        --- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-coroutine.isyieldable"])
        ---
        ---@return boolean
        ---@nodiscard
        ---@diagnostic disable-next-line: duplicate-set-field
        function coroutine.isyieldable()
            local co = coroutine_running()
            return co ~= nil and coroutine_status( co ) == "running"
        end

    end

end

---@diagnostic disable-next-line : undefined-field
local isTable = _G.isTable
if isTable == nil then

    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Checks if the value type is a `table`.
    ---
    ---@param value any The value to check.
    ---@return boolean is_table Returns `true` if the value is a table, otherwise `false`.
    function isTable( value )
        return raw_type( value ) == "table"
    end

end

local isString, STRING, NUMBER
do

    local debug_registermetatable = debug.registermetatable
    local debug_setmetatable = debug.setmetatable

    -- nil ( 0 )
    do

        local NIL = debug_getmetatable( nil )
        if NIL == nil then
            NIL = {}
            debug_setmetatable( nil, NIL )
        end

        debug_registermetatable( "nil", NIL )

        NIL.__type = "nil"
        NIL.__typeid = 0

        ---@private
        function NIL.__toboolean()
            return false
        end

        ---@private
        function NIL.__tonumber()
            return 0
        end

        NIL.__len = NIL.__tonumber

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is `nil`.
        ---
        ---@param value any The value to check.
        ---@return boolean is_nil Returns `true` if the value is `nil`, otherwise `false`.
        function std.isNil( value )
            return value == nil
        end

    end

    -- boolean ( 1 )
    do

        local BOOLEAN = debug_getmetatable( false )
        if BOOLEAN == nil then
            BOOLEAN = {}
            debug_setmetatable( false, BOOLEAN )
        end

        debug_registermetatable( "boolean", BOOLEAN )

        BOOLEAN.__type = "boolean"
        BOOLEAN.__typeid = 1

        ---@private
        function BOOLEAN.__toboolean( value )
            return value
        end

        ---@private
        function BOOLEAN.__tonumber( value )
            return value == true and 1 or 0
        end

        ---@private
        function BOOLEAN.__len()
            return 1
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `boolean`.
        ---
        ---@param value any The value to check.
        ---@return boolean is_bool Returns `true` if the value is a boolean, otherwise `false`.
        function std.isBoolean( value )
            return value == true or value == false
        end

    end

    -- number ( 3 )
    do

        NUMBER = debug_getmetatable( 0 )
        if NUMBER == nil then
            NUMBER = {}
            debug_setmetatable( 0, NUMBER )
        end

        debug_registermetatable( "number", NUMBER )

        NUMBER.__type = "number"
        NUMBER.__typeid = 3

        ---@private
        function NUMBER.__toboolean( value )
            return value ~= 0
        end

        ---@private
        function NUMBER.__tonumber( value )
            return value
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `number`.
        ---
        ---@param value any The value to check.
        ---@return boolean is_number Returns `true` if the value is a number, otherwise `false`.
        function std.isNumber( value )
            return debug_getmetatable( value ) == NUMBER
        end

    end

    -- string ( 4 )
    do

        STRING = debug_getmetatable( "" )
        if STRING == nil then
            STRING = {}
            debug_setmetatable( "", STRING )
        end

        debug_registermetatable( "string", STRING )

        STRING.__type = "string"
        STRING.__typeid = 4

        ---@private
        function STRING.__toboolean( value )
            return value ~= "" and value ~= "0" and value ~= "false"
        end

        STRING.__tonumber = raw.tonumber

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `string`.
        ---
        ---@param value any The value to check.
        ---@return boolean is_string Returns `true` if the value is a string, otherwise `false`.
        function isString( value )
            return debug_getmetatable( value ) == STRING
        end

        std.isString = isString

    end

    -- table ( 5 )
    std.isTable = isTable

    -- function ( 6 )
    do

        local FUNCTION = debug_getmetatable( debug_fempty )
        if FUNCTION == nil then
            FUNCTION = {}
            debug_setmetatable( debug_fempty, FUNCTION )
        end

        debug_registermetatable( "function", FUNCTION )

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `function`.
        ---
        ---@param value any
        ---@return boolean isFunction returns true if the value is a function, otherwise false
        function std.isFunction( value )
            return debug_getmetatable( value ) == FUNCTION
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value is callable.
        ---
        ---@param value any The value to check.
        ---@return boolean is_callable Returns `true` if the value is can be called (like a function), otherwise `false`.
        function std.iscallable( value )
            local metatable = debug_getmetatable( value )
            return metatable ~= nil and ( metatable == FUNCTION or debug_getmetatable( metatable.__call ) == FUNCTION )
        end

    end

    -- thread ( 8 )
    do

        local object = coroutine.create( debug_fempty )

        local THREAD = debug_getmetatable( object )
        if THREAD == nil then
            THREAD = {}
            debug_setmetatable( object, THREAD )
        end

        debug_registermetatable( "thread", THREAD )

        --- [SHARED AND MENU]
        ---
        --- Checks if the value type is a `thread`.
        ---
        ---@param value any The value to check.
        ---@return boolean is_thread Returns `true` if the value is a thread, otherwise `false`.
        function std.isThread( value )
            return debug_getmetatable( value ) == THREAD
        end

    end

end

dofile( "std/math.lua" )
dofile( "std/math.ease.lua" )

local math = std.math

do

    local math_ceil, math_log, math_isfinite = math.ceil, math.log, math.isfinite
    local math_ln2 = math.ln2

    ---@private
    function NUMBER.__len( value )
        if math_isfinite( value ) then
            if ( value % 1 ) == 0 then
                return math_ceil( math_log( value + 1 ) / math_ln2 ) + ( value < 0 and 1 or 0 )
            elseif value >= 1.175494351E-38 and value <= 3.402823466E+38 then
                return 32
            else
                return 64
            end
        else
            return 0
        end
    end

end

dreamwork.UnsafeBytes = {
    -- ()
    [ 0x28 ] = "%(",
    [ 0x29 ] = "%)",

    -- []
    [ 0x5B ] = "%[",
    [ 0x5D ] = "%]",

    -- .
    [ 0x2E ] = "%.",

    -- %
    [ 0x25 ] = "%%",

    -- +-
    [ 0x2B ] = "%+",
    [ 0x2D ] = "%-",

    -- *
    [ 0x2A ] = "%*",

    -- ?
    [ 0x3F ] = "%?",

    -- ^
    [ 0x5E ] = "%^",

    -- $
    [ 0x24 ] = "%$"
}

dofile( "std/table.lua" )
dofile( "std/string.lua" )
dofile( "std/path.lua" )
dofile( "std/bit.lua" )

local string = std.string
STRING.__len = string.len

local string_format = string.format
local string_byte = string.byte

--- [SHARED AND MENU]
---
--- Returns the value of the key in a table.
---
---@param tbl table The table.
---@param key any The key.
---@return any
function raw.index( tbl, key )
    if isString( key ) then
        ---@cast key string

        local uint8_1, uint8_2 = string_byte( key, 1, 2 )
        if uint8_1 == 0x5F --[[ "_" ]] and uint8_2 == 0x5F --[[ "_" ]] then
            return nil
        end

    end

    return raw_get( tbl, key )
end

std.SYSTEM_ENDIANNESS = std.SYSTEM_ENDIANNESS or string.byte( string.dump( std.debug.fempty ), 7 ) == 0x00

--- [SHARED AND MENU]
---
--- Converts the value to a hashable string.
---
--- The function uses the `__tohash` metafield to convert the value to a string.
---
--- If the value does not have a `__tohash` metafield, then the object address is used.
---
---@param e any The value to convert.
---@return string str The hashable string.
function std.tohash( e )
    local fn = debug_getmetavalue( e, "__tohash" )
    if fn == nil then
        return string_format( "%p", e )
    else
        return fn( e )
    end
end

-- TODO: remove me later or rewrite
do

    local iter = 1000
    local warmup = math.min( iter / 100, 100 )

    function dreamwork.bench( name, fn )
        for _ = 1, warmup do
            fn()
        end

        debug.gc.stop()

        local st = os_clock()
        for _ = 1, iter do
            fn()
        end

        st = os_clock() - st
        debug.gc.restart()

        print( string_format( "%d iterations of %s, took %f sec.", iter, name, st ) )

        return st
    end

end

local table_concat = std.table.concat

dofile( "std/class.lua" )

do


    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Returns a string representing the name of the type of the passed object.
    ---
    ---@param value any The value to get the type of.
    ---@return string type_name The type name of the given value.
    local function type( value )
        return debug_getmetavalue( value, "__type" ) or raw_type( value )
    end

    std.type = type

    --- [SHARED AND MENU]
    ---
    --- Validates the type of the argument and returns a boolean and an error message.
    ---
    ---@param value any The argument value.
    ---@param arg_num any The argument number/key.
    ---@param expected_type "string" | "number" | "boolean" | "table" | "function" | "thread" | "any" | string The expected type name.
    ---@return boolean ok Returns `true` if the argument is of the expected type, `false` otherwise.
    ---@return string? msg The error message.
    function std.arg( value, arg_num, expected_type )
        local got = type( value )
        if got == expected_type or expected_type == "any" then
            return true, nil
        else
            return false, string_format( "bad argument #%s to \'%s\' ('%s' expected, got '%s')", arg_num, debug_getinfo( 2, "n" ).name or "unknown", expected_type, got )
        end
    end

end

--- [SHARED AND MENU]
---
--- The pack library that packs/unpacks types as binary.
---
---@class dreamwork.std.pack
std.pack = std.pack or {}

dofile( "std/pack.bytes.lua" )
dofile( "std/pack.bits.lua" )
dofile( "std/pack.lua" )

dofile( "std/math.classes.lua" )

dofile( "std/structures.lua" )
dofile( "std/futures.lua" )
dofile( "std/time.lua" )

local time = std.time

if coroutine.wait == nil then

    local coroutine_yield = coroutine.yield
    local time_elapsed = time.elapsed

    ---@async
    function coroutine.wait( seconds )
        local end_time = time_elapsed() + seconds
        while true do
            if end_time < time_elapsed() then return end
            coroutine_yield()
        end
    end

end

dofile( "std/version.lua" )
dofile( "std/bigint.lua" )
dofile( "std/color.lua" )

---@class dreamwork.std.ColorClass.scheme
local color_scheme
do

    local Color = std.Color
    color_scheme = Color.scheme

    -- General
    color_scheme.white = Color( 255, 255, 255, 255 )
    color_scheme.black = Color( 0, 0, 0, 255 )

    color_scheme.red = Color( 255, 0, 0, 255 )
    color_scheme.green = Color( 0, 255, 0, 255 )
    color_scheme.blue = Color( 0, 0, 255, 255 )

    color_scheme.yellow = Color( 255, 255, 0, 255 )
    color_scheme.cyan = Color( 0, 255, 255, 255 )
    color_scheme.magenta = Color( 255, 0, 255, 255 )

    color_scheme.gray = Color( 128, 128, 128, 255 )

    color_scheme.text_primary = Color( 200 )
    color_scheme.text_secondary = Color( 150 )

    -- Garry's Mod
    -- Thank you code_gs <3
    -- https://discord.com/channels/565105920414318602/565108080300261398/905385921283756062
    color_scheme.server_message = Color( 156, 241, 255, 200 )
    color_scheme.server_error = Color( 136, 221, 255, 255 )

    color_scheme.client_message = Color( 255, 241, 122, 200 )
    color_scheme.client_error = Color( 255, 221, 102, 255 )

    color_scheme.menu_message = Color( 100, 220, 100, 200 )
    color_scheme.menu_error = Color( 120, 220, 100, 255 )

    -- DreamWork
    color_scheme.dreamwork_main = Color( 180, 180, 255 )

    color_scheme.dreamwork_info = Color( 70, 135, 255 )
    color_scheme.dreamwork_warn = Color( 255, 130, 90 )
    color_scheme.dreamwork_error = Color( 250, 55, 40 )
    color_scheme.dreamwork_debug = Color( 0, 200, 150 )

    color_scheme.dreamwork_menu = Color( 75, 175, 80 )
    color_scheme.dreamwork_client = Color( 225, 170, 10 )
    color_scheme.dreamwork_server = Color( 5, 170, 250 )

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

--- [SHARED AND MENU]
---
--- The encoding/decoding libraries.
---
---@class dreamwork.std.encoding
std.encoding = std.encoding or {}

dofile( "std/encoding.base16.lua" )
dofile( "std/encoding.base32.lua" )
dofile( "std/encoding.base64.lua" )
dofile( "std/encoding.percent.lua" )

dofile( "std/encoding.utf8.lua" )
dofile( "std/encoding.unicode.lua" )
dofile( "std/encoding.punycode.lua" )

dofile( "std/encoding.json.lua" )
dofile( "std/encoding.vdf.lua" )

dofile( "engine.lua" )

local engine = dreamwork.engine

do

    local ErrorNoHalt = _G.ErrorNoHalt

    if ErrorNoHalt == nil then
        local engine_consoleMessageColored = engine.consoleMessageColored
        local error_color = color_scheme.error

        function ErrorNoHalt( str )
            return engine_consoleMessageColored( str, error_color )
        end
    end

    local string_match = string.match
    local string_rep = string.rep

    --- [SHARED AND MENU]
    ---
    --- Throws an error with the specified message and level.
    ---
    ---@param message? string The error message to throw.
    ---@param stack_level? integer The stack level to throw the error.
    ---@param dont_break? boolean If `true`, the error will not break the current stack.
    local function std_error( message, stack_level, dont_break )
        if message == nil then
            message = "unknown"
        else
            message = tostring( message )
        end

        if stack_level == nil then
            stack_level = 1
        end

        if dont_break then
            local title

            local level_info = debug_getinfo( stack_level, "S" )
            if level_info ~= nil then
                title = string_match( level_info.source, "^@?addons/([^/]+)" )
            end

            local stack, size = { "\n[" .. ( title or "LUA ERROR" ) .. "] " .. message }, 1

            while true do
                local info = debug_getinfo( size + stack_level, "Sln" )
                if info == nil then
                    break
                end

                size = size + 1
                stack[ size ] = table_concat( { string_rep( " ", size ), ( size - 1 ), ". ", info.name or "unknown", " - ", info.short_src or "unknown", ":", info.currentline or -1 } )
            end

            size = size + 1
            stack[ size ] = "\n"

            return ErrorNoHalt( table_concat( stack, "\n", 1, size ) )
        end

        return error( message, stack_level + 1 )
    end

    std.error = std_error

    --- [SHARED AND MENU]
    ---
    --- Throws an error with the specified message and level.
    ---
    ---@param stack_level? integer The stack level to throw the error.
    ---@param dont_break? boolean If `true`, the error will not break the current stack.
    ---@param fmt string The error message to throw.
    ---@param ... any The error message arguments to format/interpolate.
    function std.errorf( stack_level, dont_break, fmt, ... )
        return std_error( string_format( fmt, ... ), ( stack_level or 1 ) + 1, dont_break )
    end

end

do

    local engine_consoleMessage = engine.consoleMessage

    --- [SHARED AND MENU]
    ---
    --- Prints the given arguments to the console.
    ---
    ---@param ... any The arguments to print.
    ---@diagnostic disable-next-line: duplicate-set-field
    function std.print( ... )
        local arg_count = select( "#", ... )
        if arg_count == 0 then
            engine_consoleMessage( "\n" )
        elseif arg_count == 1 then
            engine_consoleMessage( tostring( ... ) .. "\n" )
        else
            local args = { ... }

            for arg_num = 1, arg_count, 1 do
                args[ arg_num ] = tostring( args[ arg_num ] )
            end

            engine_consoleMessage( table_concat( args, "\t", 1, arg_count ) .. "\n" )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Prints a formatted string to the console.
    ---
    --- Basically the same as `print( string.format( fmt, ... ) )`
    ---@param fmt string The format string.
    ---@param ... any The arguments to format/interpolate.
    function std.printf( fmt, ... )
        return engine_consoleMessage( string_format( fmt, ... ) .. "\n" )
    end

    do

        local engine_consoleMessageColored = engine.consoleMessageColored
        local realm_color = color_scheme.realm
        local isColor = std.isColor
        local tocolor = std.tocolor

        --- [SHARED AND MENU]
        ---
        --- Prints the given arguments to the console with colors!
        ---
        ---@param ... any The arguments to print.
        function std.printc( ... )
            local color = realm_color
            local args = { ... }

            for ang_num = 1, select( "#", ... ), 1 do
                local value = args[ ang_num ]
                if isColor( value ) then
                    ---@cast value dreamwork.std.Color
                    color = value
                elseif isString( value ) then
                    ---@cast value string
                    engine_consoleMessageColored( value, color )
                else
                    ---@cast value any
                    engine_consoleMessageColored( tostring( value ), tocolor( value ) or color )
                end
            end

            engine_consoleMessage( "\n" )
        end

        local color_fromHex = std.Color.fromHex
        local string_char = string.char
        local string_sub = string.sub
        local string_len = string.len

        --- [SHARED AND MENU]
        ---
        --- Prints a formatted string to the console with colors!
        ---
        --- Works very similarly to `printf`, but supports an additional `%C` specifier for colors.
        ---
        ---@param fmt string The format string.
        ---@param ... any The arguments to format/interpolate.
        function std.printfc( fmt, ... )
            local fmt_length = string_len( fmt )
            if fmt_length == 0 then
                return
            end

            fmt = fmt .. "\n"
            fmt_length = fmt_length + 1

            local arg_count = select( "#", ... )
            local arg_index = 0
            local args = { ... }

            local color = realm_color
            local break_point = 1
            local index = 0

            local buffer, buffer_length = {}, 0

            while index ~= fmt_length do
                index = index + 1

                local uint8_1 = string_byte( fmt, index, index )
                if uint8_1 == 0x25 --[[ % ]] then
                    if ( index - break_point ) ~= 0 then
                        buffer_length = buffer_length + 1
                        buffer[ buffer_length ] = string_sub( fmt, break_point, index - 1 )
                    end

                    if index == fmt_length then
                        buffer_length = buffer_length + 1
                        buffer[ buffer_length ] = "%"
                        break_point = index
                        break
                    end

                    index = index + 1
                    break_point = index + 1

                    local uint8_2 = string_byte( fmt, index, index )

                    if uint8_2 == 0x25 --[[ % ]] or uint8_2 == 0x7B --[[ { ]] or uint8_2 == 0x7D --[[ } ]] then
                        buffer_length = buffer_length + 1
                        buffer[ buffer_length ] = string_char( uint8_2 )
                    else

                        arg_index = arg_index + 1

                        if arg_index > arg_count then
                            std.errorf( 2, false, fmt, "Argument #%d [%s] to 'printfc' is missing!", arg_index, string_char( uint8_1, uint8_2 ) )
                        end

                        if uint8_2 == 0x43 --[[ C ]] then
                            if buffer_length ~= 0 then
                                engine_consoleMessageColored( table_concat( buffer, "", 1, buffer_length ), color )
                                buffer_length = 0
                            end

                            color = tocolor( args[ arg_index ] ) or color
                        else
                            buffer_length = buffer_length + 1
                            buffer[ buffer_length ] = string_format( string_char( uint8_1, uint8_2 ), args[ arg_index ] )
                        end

                    end
                elseif uint8_1 == 0x7B --[[ { ]] then
                    ---@type integer | nil
                    local end_index

                    for i = index, fmt_length, 1 do
                        if string_byte( fmt, i, i ) == 0x7D --[[ } ]] then
                            end_index = i
                            break
                        end
                    end

                    if end_index ~= nil then
                        if ( index - break_point ) ~= 0 then
                            buffer_length = buffer_length + 1
                            buffer[ buffer_length ] = string_sub( fmt, break_point, index - 1 )
                        end

                        if buffer_length ~= 0 then
                            engine_consoleMessageColored( table_concat( buffer, "", 1, buffer_length ), color )
                            buffer_length = 0
                        end

                        index = index + 1

                        if ( end_index - index ) == 0 then
                            color = realm_color
                        else
                            local color_str = string_sub( fmt, index, end_index - 1 )
                            if string_byte( color_str, 1, 1 ) == 0x23 --[[ # ]] then
                                color = color_fromHex( color_str, false )
                            else
                                color = color_scheme[ color_str ] or realm_color
                            end
                        end

                        index = end_index
                        break_point = end_index + 1
                    end

                end
            end

            if break_point < fmt_length then
                buffer_length = buffer_length + 1
                buffer[ buffer_length ] = string_sub( fmt, break_point, fmt_length )
            end

            if buffer_length ~= 0 then
                engine_consoleMessageColored( table_concat( buffer, "", 1, buffer_length ), color )
            end
        end

    end

end

dofile( "std/game.lua" )

--- [SHARED AND MENU]
---
--- The checksum calculation libraries.
---
---@class dreamwork.std.checksum
std.checksum = std.checksum or {}

dofile( "std/checksum.crc.lua" )
dofile( "std/checksum.adler.lua" )
dofile( "std/checksum.fletcher.lua" )

--- [SHARED AND MENU]
---
--- The compression libraries.
---
---@class dreamwork.std.compress
std.compress = std.compress or {}

dofile( "std/compress.deflate.lua" )
dofile( "std/compress.lzma.lua" )
dofile( "std/compress.lzw.lua" )

--- [SHARED AND MENU]
---
--- The hash libraries.
---
---@class dreamwork.std.hash
std.hash = std.hash or {}

dofile( "std/hash.fnv.lua" )
dofile( "std/hash.md5.lua" )
dofile( "std/hash.sha1.lua" )
dofile( "std/hash.sha256.lua" )

--- [SHARED AND MENU]
---
--- The crypto libraries.
---
---@class dreamwork.std.crypto
std.crypto = std.crypto or {}

dofile( "std/crypto.chacha20.lua" )
dofile( "std/crypto.hmac.lua" )
dofile( "std/crypto.pbkdf2.lua" )

dofile( "std/utils.lua" )
dofile( "std/uuid.lua" )

dofile( "std/timer.lua" )
dofile( "std/hook.lua" )
dofile( "std/url.lua" )

if dreamwork.TickTimer0_05 == nil then
    local timer = std.Timer( 0.05, 0, dreamwork.PREFIX .. "::TickTimer0_05" )
    dreamwork.TickTimer0_05 = timer
    timer:start()
end

if dreamwork.TickTimer0_1 == nil then
    local timer = std.Timer( 0.1, 0, dreamwork.PREFIX .. "::TickTimer0_1" )
    dreamwork.TickTimer0_1 = timer
    timer:start()
end

if dreamwork.TickTimer0_25 == nil then
    local timer = std.Timer( 0.25, 0, dreamwork.PREFIX .. "::TickTimer0_25" )
    dreamwork.TickTimer0_25 = timer
    timer:start()
end

if dreamwork.TickTimer1 == nil then
    local timer = std.Timer( 1, 0, dreamwork.PREFIX .. "::TickTimer1" )
    dreamwork.TickTimer1 = timer
    timer:start()
end

dofile( "std/console.lua" )
dofile( "std/console.logger.lua")

local console_Variable = std.console.Variable

if LUA_SERVER then

    -- https://github.com/Facepunch/garrysmod-requests/issues/2793
    local sv_defaultdeployspeed = console_Variable.get( "sv_defaultdeployspeed", "number" )
    if sv_defaultdeployspeed ~= nil and sv_defaultdeployspeed.value == 4 then
        sv_defaultdeployspeed.value = 1
    end

    -- draw everything manually, don't use this crap
    local mp_show_voice_icons = console_Variable.get( "mp_show_voice_icons", "boolean" )
    if mp_show_voice_icons ~= nil and mp_show_voice_icons.value then
        mp_show_voice_icons.value = false
    end

end

local logger = std.console.Logger( {
    color = color_scheme.dreamwork_main,
    title = dreamwork.PREFIX,
    interpolation = false
} )

dreamwork.Logger = logger

-- dofile( "std/message.lua" )

local std_metatable = getmetatable( std )

if std_metatable == nil then

    ---@type table<string, fun( self: table ): any>
    local indexes = {}

    ---@type table<string, fun( self: table, value: any )>
    local newindexes = {}

    do

        local raw_set = raw.set

        std_metatable = {
            __indexes = indexes,
            __index = function( self, key )
                local fn = indexes[ key ]
                if fn ~= nil then
                    return fn( self )
                end
            end,
            __newindexes = newindexes,
            __newindex = function( self, key, value )
                local fn = newindexes[ key ]

                if fn == nil then
                    raw_set( self, key, value )
                    return
                end

                value = fn( self, value )

                if value ~= nil then
                    raw_set( self, key, value )
                end
            end
        }

        std.setmetatable( std, std_metatable )

    end

    do

        local developer = std.console.Variable.get( "developer", "integer" )
        if developer == nil then

            ---@private
            function indexes.DEVELOPER()
                return 1
            end

        else

            ---@private
            function indexes.DEVELOPER()
                return developer.value
            end

        end

    end

    ---@private
    function indexes.DST_TZ()
        if std.DST then
            return std.TZ + 1
        else
            return std.TZ
        end
    end

    if LUA_CLIENT then

        local time_elapsed = time.elapsed

        local frame_time = 0
        local fps = 0

        ---@private
        function indexes.FPS()
            return fps
        end

        ---@private
        function indexes.FRAME_TIME()
            return frame_time
        end

        local last_pre_render = 0

        engine.hookCatch( "PreRender", function()
            local elapsed_time = time_elapsed()

            if last_pre_render ~= 0 then
                frame_time = elapsed_time - last_pre_render
                fps = 1 / frame_time
            end

            last_pre_render = elapsed_time
        end, 1 )

    end

end

do

    local setTimeout = std.setTimeout
    local futures = std.futures

    --- [SHARED AND MENU]
    ---
    --- Puts current thread to sleep for given amount of seconds.
    ---
    ---@see dreamwork.std.futures.pending
    ---@see dreamwork.std.futures.wakeup
    ---@async
    ---@param seconds number
    function std.sleep( seconds )
        local co = futures.running()
        if co == nil then
            error( "`sleep` cannot be called from main thread!", 2 )
        end

        ---@cast co thread

        setTimeout( function()
            futures.wakeup( co )
        end, seconds )

        return futures.pending()
    end

end

-- Welcome message
do

    local name

    local cvar = std.console.Variable.get( LUA_SERVER and "hostname" or "name", "string" )
    if cvar == nil then
        name = "stranger"
    else
        ---@type string
        name = cvar.value
        if string.isEmpty( name ) or name == "unnamed" then
            name = "stranger"
        end
    end

    local splashes = {
        "eW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==",
        "I'm not here to tell you how great I am!",
        "Woah-oh-oh, tell me where you wanna go ♪",
        "We will have a great Future together.",
        "I'm here to show you how great I am!",
        "Millions of pieces without a tether",
        "Why are we always looking for more?",
        "Never forget to finish your Task's!",
        "T2gsIHlvdSdyZSBhIHNtYXJ0IG9uZS4=",
        "Take it in and breathe the light",
        "Don't worry, " .. name .. " :>",
        "Big Brother is watching you",
        "As we build it once again",
        "I'll make you a promise.",
        "Flying over rooftops...",
        "Hello, " .. name .. "!",
        "Dream + Framework = <3",
        "We need more packages!",
        "Pew-pew-pew-pew-pew! ♪",
        "Play SOMA sometime;",
        "Where's fireworks!?",
        "Looking For More ♪",
        "I'm watching you.",
        "Faster than ever.",
        "Love Wins Again ♪",
        "Made with love <3",
        "Blazing fast ☄",
        "Ancient Tech ♪",
        "Here For You ♪",
        "Good Enough ♪",
        "MAKE A MOVE ♪",
        "v" .. version,
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
        "Eat Me ♪"
    }

    local count = #splashes + 1
    splashes[ count ] = "Wow, here more " .. ( count - 1 ) .. " splashes!"

    local splash = splashes[ math.random( 1, count ) ]

    local logo
    if std.WINDOWS then
        logo = "\n       / *    .      +                                                         ⣀⣀⣤⠤⢤⣀⠀ \n  .   /                        /  '           '                         ⢀⣠⠴⠒⢋⣉⣀⣠⣄⣀⣈⡇   \n     *   .         '          /           *                   ⠀⠀⠀⠀⣠⣴⣾⣯⠴⠚⠉⠉⠀⠀⠀⠀⣤⠏⣿      \n            *      * %s⠀⠀⣠⣴⡿⠿⢛⠁⠁⣸⠀⠀⠀⠀⠀⣤⣾⠵⠚⠁      \n '                +   +                    _|_     '    *  ⠀⣠⣴⠿⠋⠁⠀⠀⠀⠀⠘⣿⠀⣀⡠⠞⠛⠁⠂⠁⠀⠀      \n       .                             .      |         ⠀⠀⣀⣴⠟⠋⠁⠀⠀⠀⠀⠐⠠⡤⣾⣙⣶⡶⠃⠀⠀⠀⠀⠀⠀⠀       \n⠉                ____    o  +   .    +                ⣤⢾⣋⠉        __ ⡴⢿⢛⠃              \n⠄       o       / __ \\_____ __  __ _ _ __ _____     ⣴⡼⢏⠑__  _____/ /__ ⢿               \n⠂⠂      .      / / / /⠁⠁⠁//_ \\/ _` | '_ ` _ \\ \\ /\\ / / _  \\/ ___/ //_/                 \n⠁   +       ⣀⣴/ /_/ / /⠞⠁/ __/ (_) | | | | | \\ V  V / (_) / /  / ,<                    \n         ⣠⢴⣿⠟/_____/_/  ⠞\\___|\\__,_|_| |_| |_|\\_/\\_/ \\___/_/  /_/|_|                   \n⠀⠀⠀⠀⠀⢀⡴⢏⡵⠛⠀⠀⠀⠀⠀⠀⠀⣀⣴⠞⠛                                                                  \n⠀⠀⠀⣀⣼⠛⣲⡏⠁⠀⠀⠀⠀⠀⢀⣠⡾⠋⠉⠁⠁⠁        .-.    o  +   .    |                                     \n⠀⠀⡴⠟⠀⢰⡯⠄⠀⠀⠀⠀⣠⢴⠟⠉ ⠁              ) )             --o--                                  \n⠀⡾⠁⠁⠀⠘⠧⠤⢤⣤⠶⠏⠙⠁    *     *       '-´   ⠁   ⠁    ⠁  |                                    \n⠘⣇⠂⢀⣀⣀⠤⠞⠋                                                                              \n⠀⠈⠉⠉⠉     .      +                      *   '      '        +                          \n╭────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       \n┊  GitHub: https://github.com/Pika-Software                                            \n┊  Discord: https://discord.gg/Gzak99XGvv                                              \n┊  Website: https://p1ka.eu                                                            \n┊  Developers: Pika Software                                                           \n┊  License: MIT                                                                        \n╰────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──────⋆⋅☆⋅⋆──ˎˊ˗                                       \n"
    else
        -- logo = "\n                            ,                          ,                 /<^^/^^>      \n          *                             *                            <^^/^^/^^^/^^>    \n         /          +  %s  <^^^/^^^>      <^^^>  \n        /                  *          o         ,             </^^^/>      ,     <^^>  \n       *       .                                           <^/^^^>  ' ,___/_\\__<^>     \n                                           _|_         <^^/^^>         \\ / _ \\ /       \n              o       *              .      |        <^^/^>        -=   > (_) <   =-   \n    +            ____                              <^^/>          _    /_\\___/_\\       \n                / __ \\____ __  __ _ _ __ _____   <^^/>____  _____/ /__`   \\ /   ` .    \n  +      +     / / / / __//_ \\/ _` | '_ ` _ \\ \\ /\\ / / _  \\/ ___/ //_/  /  `  \\        \n              / /_/ / /  / __/ (_) | | | | | \\ V  V / (_) / /  / ,<                    \n         <^> /_____/_/ <>\\___|\\__,_|_| |_| |_|\\_/\\_/ \\___/_/  /_/|_|                   \n       <^/>         <^^>                                                               \n    </  />      <^^^>     *       .-.          *   '      '        +                   \n  <^/>  <>    <^^^>                ) )               |                                 \n <^>   <^^^^^^^^>    *     '      '-´              --o--                               \n <^>       <^^/>                 *                   |                                 \n   <^^^^^^>       +           *           *   '      '        +                        \n ___________________________________________                                           \n/  GitHub: https://github.com/Pika-Software                                            \n   Discord: https://discord.gg/Gzak99XGvv                                              \n   Website: https://p1ka.eu                                                            \n   Developers: Pika Software                                                           \n   License: MIT                                                                        \n\\___________________________________________                                           \n"
        logo = "\n               / *    .      +                                                    \n          .   /                        /  '           '     .                     \n   .         *   .         '          /           *                               \n                                     *      *                         .      +    \n     '                +   +                    _|_     '    *                     \n       .                             .          |                 +      |        \n          o      '            +        .              .     '          --o--      \n            * .                                                    '     |        \n     '          .         '    '                                 /               o\n  '                    .             DreamWork                  /                 \n     .          '   +    .                           +      .  *                  \n           .                          +                   .            +        . \n     o                %s.                   \n                                               .           *         *            \n           .         .      +                      *   '      '        +          \n                       o  +   .    +      .     .                o                \n     .-.                         '                    .                           \n      ) ) .          o                        |             o             '   .   \n     '-´                               '    --o--                                 \n               .                              |                      +        .   \n\n  GitHub: https://github.com/Pika-Software\n  Discord: https://discord.gg/Gzak99XGvv\n  Website: https://p1ka.eu\n  Developers: Pika Software\n  License: MIT\n"
    end

    std.printfc( logo, string.pad( splash, 40, " ", nil, std.encoding.utf8.len( splash ) ) )

end

if math.randomseed == 0 then
    math.randomseed = time.now( "ms", false )
    logger:info( "Random seed was re-synchronized with milliseconds since the Unix epoch." )
end

dofile( "std/sqlite.lua" )
dofile( "database.lua" )
dofile( "std/fs.lua" )

do

    local bytepack_writeUInt32 = std.pack.bytes.writeUInt32

    logger:info( "Started with %d game(s) and %d addon(s).", engine.GameCount, engine.AddonCount )

    ---@param game_info dreamwork.engine.GameInfo
    engine.hookCatch( "engine.Game.mounted", function( game_info )
        logger:debug( "Game '%s' (AppID: %d) was mounted.", game_info.folder, game_info.depot )
    end, 1 )

    ---@param game_info dreamwork.engine.GameInfo
    engine.hookCatch( "engine.Game.unmounted", function( game_info )
        logger:debug( "Game '%s' (AppID: %d) was unmounted.", game_info.folder, game_info.depot )
    end, 1 )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "engine.Addon.mounted", function( addon_info )
        local folder = string_format( "gma_%x%x%x%x", bytepack_writeUInt32( addon_info.index ) )
        addon_info.folder = folder

        logger:debug( "Addon '%s' (WorkshopID: %d, folder: %s) was mounted.", addon_info.title, addon_info.wsid, folder )
    end, 1 )

    ---@param addon_info dreamwork.engine.AddonInfo
    engine.hookCatch( "engine.Addon.unmounted", function( addon_info )
        logger:debug( "Addon '%s' (WorkshopID: %d, folder: %s) was unmounted.", addon_info.title, addon_info.wsid, addon_info.folder )
    end, 1 )

    local changes_timeout = std.Timer( 0.5, 1, dreamwork.PREFIX .. "::ContentWatcher" )

    local function perform_synchronization()
        logger:debug( "Game content change triggered, synchronization..." )
        time.tick( "ms", false )

        local game_changes, addon_changes = engine.SyncContent()

        if game_changes == 0 and addon_changes == 0 then
            logger:debug( "No changes found, skipped." )
        else
            logger:debug( "Synchronization finished with %d game(s) and %d addon(s) in %d ms.", game_changes, addon_changes, time.tick( "ms", false ) )
        end
    end

    changes_timeout:attach( perform_synchronization )
    perform_synchronization()

    engine.hookCatch( "GameContentChanged", function()
        changes_timeout:start()
    end, 1 )

end

dofile( "std/game.hooks.lua" )
dofile( "std/audio_stream.lua" )

-- https://github.com/willox/gmbc
if std.loadbinary( "gmbc" ) then
    logger:info( "'gmbc' was loaded & connected as LuaJIT bytecode compiler." )
else
    logger:warn( "'gmbc' is missing, bytecode compilation not available." )
end

do

    ---@diagnostic disable-next-line: undefined-field
    local gmbc_load_bytecode = _G.gmbc_load_bytecode

    ---@diagnostic disable-next-line: undefined-field
    local CompileString = _G.CompileString

    local getfenv, setfenv = std.getfenv, std.setfenv
    local file_read = std.fs.read
    local pcall = std.pcall

    --- [SHARED AND MENU]
    ---
    --- Loads a string as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param lua_code string The lua code chunk.
    ---@param chunk_name string | nil The lua code chunk name.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    local function loadstring( lua_code, chunk_name, env )
        local fn = CompileString( lua_code, chunk_name or "=(loadstring)", false )
        if fn == nil then
            return nil, "lua code compilation failed"
        elseif isString( fn ) then
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast fn string
            return nil, fn
        else
            setfenv( fn, env or getfenv( 2 ) )
            return fn
        end
    end

    std.loadstring = loadstring

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
    local function loadbytecode( bytecode, env )
        local success, result = pcall( gmbc_load_bytecode, bytecode )
        if success then
            setfenv( result, env or getfenv( 2 ) )
            return result, nil
        else
            return nil, result
        end
    end

    std.loadbytecode = loadbytecode

    --- [SHARED AND MENU]
    ---
    --- Loads a file as
    --- a lua code chunk in the specified environment
    --- and returns function as a compile result.
    ---
    ---@param file_path string The path to the file to read.
    ---@param is_bytecode boolean If `true`, the file will be loaded as a bytecode chunk.
    ---@param env table | nil The environment of compiled function.
    ---@return function | nil fn The compiled function.
    ---@return string | nil msg The error message.
    function std.loadfile( file_path, is_bytecode, env )
        local success, content = pcall( file_read, file_path )
        if success then
            if env == nil then
                env = getfenv( 2 )
            end

            if is_bytecode then
                return loadbytecode( content, env )
            else
                return loadstring( content, file_path, env )
            end
        else
            return nil, content
        end
    end

end

do

    local loadstring = std.loadstring
    local math_floor = math.floor
    local math_max = math.max
    local arg = std.arg

    local empty_env = {}

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
    ---@return fun( ... ): ... fjn
    function std.junction( ... )
        local out_arg_count = select( '#', ... )
        local out_args = { ... }

        local in_arg_count = 0

        for i = 1, out_arg_count, 1 do
            local value = out_args[ i ]
            local valid, err_msg = arg( value, i, "number" )
            if valid then
                out_args[ i ] = math_floor( value )
                in_arg_count = math_max( in_arg_count, value )
            else
                error( err_msg, 2 )
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

--[[

    TODO:

    FileReader     FileWriter       __init( file_path: string )
    file.Reader            file.Writer

    NetworkReader  NetworkWriter    __init( network_name: string )
    network.Reader         network.Writer
    net.Reader             net.Writer

    network.Message
    NetworkMessage
    net.Message

    net.MessageReader       net.MessageWriter

]]

dofile( "std/http.lua" )
dofile( "std/http.github.lua" )

dofile( "std/steam.lua" )
dofile( "std/steam.identifier.lua" )
dofile( "std/steam.workshop.lua" )

dofile( "std/addon.lua" )

if LUA_CLIENT_MENU then
    dofile( "std/window.lua" )
    dofile( "std/menu.lua" )
    dofile( "std/client.lua" )
    dofile( "std/render.lua" )
end

---@diagnostic disable-next-line: undefined-field
local glua_system = _G.system

if glua_system ~= nil then

    std_metatable.__indexes.SYSTEM_COUNTRY = glua_system.GetCountry or function() return "gb" end

    if glua_system.BatteryPower ~= nil then

        local system_BatteryPower = glua_system.BatteryPower

        local battery_power = 0

        local function update_battery()
            if battery_power ~= system_BatteryPower() then
                battery_power = system_BatteryPower()
                if battery_power == 255 then
                    std.SYSTEM_HAS_BATTERY = false
                    std.SYSTEM_BATTERY_LEVEL = 100
                else
                    std.SYSTEM_HAS_BATTERY = true
                    std.SYSTEM_BATTERY_LEVEL = battery_power
                end
            end
        end

        update_battery()

        dreamwork.TickTimer1:attach( update_battery, "dreamwork::battery" )

    end

    if LUA_CLIENT_MENU then

        local system_HasFocus = glua_system.HasFocus
        if system_HasFocus ~= nil then

            ---@class dreamwork.std.window
            ---@field focus boolean `true` if the game's window has focus, `false` otherwise.
            local window = std.window

            local has_focus = system_HasFocus()
            window.focus = has_focus

            dreamwork.TickTimer0_05:attach( function()
                if has_focus ~= system_HasFocus() then
                    has_focus = not has_focus
                    window.focus = has_focus
                end
            end, "dreamwork::window_focus" )

        end

    end

end

dofile( "std/server.lua" )
dofile( "std/level.lua" )

if LUA_CLIENT_SERVER then
    dofile( "std/physics.lua" )
    dofile( "std/entity.lua" )
    dofile( "std/player.lua" )
    -- dofile( "std/network.lua" )
end

-- TODO: NetTable class

dofile( "std/input.lua" )

if std.LUA_VERSION ~= "Lua 5.1" then
    logger:warn( "Lua version changed, possible unpredictable behavior. (" .. std.LUA_VERSION .. ")" )
end

if LUA_CLIENT_SERVER then
    dofile( "transport.lua" )
end

logger:info( "Start-up time: %.2f ms.", ( os_clock() - dreamwork.StartTime ) * 1000 )

do

    logger:info( "Preparing the database to begin migration..." )
    local start_time = os_clock()

    local db = dreamwork.db
    db.optimize()
    db.prepare()
    db.migrate( "initial file table" )

    logger:info( "Migration completed, time spent: %.2f ms.", ( os_clock() - start_time ) * 1000 )

end

if LUA_CLIENT_SERVER then
    logger:info( "Preparing the transport to begin connection..." )
    dreamwork.transport.startup()
end



do
    local start_time = os_clock()
    debug.gc.collect()
    logger:info( "Clean-up time: %.2f ms.", ( os_clock() - start_time ) * 1000 )
end

-- TODO: package manager start-up ( aka package loading )

-- TODO: put https://wiki.facepunch.com/gmod/Global.IsFirstTimePredicted somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.RecipientFilter somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.ClientsideScene somewhere
-- TODO: put https://wiki.facepunch.com/gmod/util.ScreenShake somewhere
-- TODO: put https://wiki.facepunch.com/gmod/Global.AddonMaterial somewhere
-- TODO: put _G.util.ScreenShake somewhere or remove

-- TODO: Write "VideoRecorder" class ( https://wiki.facepunch.com/gmod/video.Record )

--[[

    TODO: return missing functions

    -- dofile - missing in glua
    -- require - broken in glua

]]


-- TODO: plugins support

--[[

    -- TODO

    concepts

    local utf8 = require( "utf8" )
    local custom_utf8 = require( "package.utf8" )

    local ... = dofile( "./path.to.lua", ... )


                            gmod <--------\
                            /\          ||
                            ||          ||
    [ LAYER 1 ] - dreamwork.std -> dreamwork.engine
        /\
    [ LAYER 2 ] - package with __package object
        /\
    [ LAYER 3 ] - file/module with __dir and __file objects

    {

        dependencies:
            cool_lib: >= 1.0.0

    }

    local cool_lib = require( "cool_lib" )

    dofile( "file.lua" ) - ./file.lua

    dofile( "/garrysmod/gamemodes/sandbox/file.lua" )




    Addon 1:

        MY_LIST = {}


    Addon 2:

        local addon1 = require( "addon1" )

        local lst = addon1.MY_LIST

        lst[ #lst + 1 ] = "addon2"


]]
