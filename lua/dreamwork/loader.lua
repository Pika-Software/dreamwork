local dofile = dofile or include
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

---@class dreamwork.std
---@field _G table The global environment of Lua.
---@field LUA_VERSION string The version of the Lua interpreter.
---@field GAME_VERSION integer Contains the version number of the Garrys Mod. For example: `201211` = `01.01.2012`
---@field GAME_BRANCH "x86-64" | "dev" | "prerelease" | "unknown" | string The branch the Garry's Mod is running on. This will be `unknown` on main branch.
---@field LUA_MENU boolean `true` if code is running on the menu, `false` otherwise.
---@field LUA_CLIENT boolean `true` if code is running on the client, `false` otherwise.
---@field LUA_CLIENT_MENU boolean `true` if code is running on the client or menu, `false` otherwise.
---@field LUA_CLIENT_SERVER boolean `true` if code is running on the client or server, `false` otherwise.
---@field LUA_SERVER boolean `true` if code is running on the server, `false` otherwise.
local std = dreamwork.std

std.LUA_VERSION = _VERSION or "unknown"

---@diagnostic disable-next-line: assign-type-mismatch
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

---@generic K, V
---@class dreamwork.Metatable<K, V>
---@field __type? string
---@field MetaName? string
---@field __typeid? integer
---@field MetaID? integer
---@field __mode? "v" | "k" | "kv"
---@field __metatable? any
---@field __tostring? fun(self: table<K, V>): string
---@field __gc? fun(self: table<K,V>)
---@field __add? fun(self: table<K,V>, other: any): any
---@field __sub? fun(self: table<K,V>, other: any): any
---@field __mul? fun(self: table<K,V>, other: any): any
---@field __div? fun(self: table<K,V>, other: any): any
---@field __mod? fun(self: table<K,V>, other: any): any
---@field __pow? fun(self: table<K,V>, other: any): any
---@field __unm? fun(self: table<K,V>): any
---@field __idiv? fun(self: table<K,V>, other: any): any
---@field __band? fun(self: table<K,V>, other: any): any
---@field __bor? fun(self: table<K,V>, other: any): any
---@field __bxor? fun(self: table<K,V>, other: any): any
---@field __bnot? fun(self: table<K,V>): any
---@field __shl? fun(self: table<K,V>, other: any): any
---@field __shr? fun(self: table<K,V>, other: any): any
---@field __concat? fun(self: table<K,V>, other: any): any
---@field __len? fun(self: table<K,V>): integer
---@field __eq? fun(self: table<K,V>, other: any): boolean
---@field __lt? fun(self: table<K,V>, other: any): boolean
---@field __le? fun(self: table<K,V>, other: any): boolean
---@field __index? table<any, any>|fun(self: table<K,V>, key: K): any
---@field __newindex? table<any, any>|fun(self: table<K,V>, key: K, value: V)
---@field __call? fun(self: table<K,V>, ...): any
---@field __pairs? fun(self: table<K,V>): fun(tbl: table<K,V>, key: K?): K?, V?
---@field __close? fun(self: table<K,V>, errobj: any): any
---@field __serialize? fun(self: table<K,V>, writer: dreamwork.std.buffer.Writer, data: any?)
---@field __deserialize? fun(self: table<K,V>, reader: dreamwork.std.buffer.Reader, data: any?)
---@field __tostring? fun(self: table<K,V>): string
---@field __tonumber? fun(self: table<K,V>): number
---@field __toboolean? fun(self: table<K,V>): boolean
---@field __tocolor? fun(self: table<K,V>): (red: integer, green: integer, blue: integer, alpha: (integer | nil))
---@field __tostring? fun( self: table<K,V>): string

--- [SHARED AND MENU]
---
--- If object does not have a metatable, returns `nil`.
---
--- Otherwise, if the object's metatable has a `__metatable` field, returns the associated value.
---
--- Otherwise, returns the metatable of the given object.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-getmetatable)
---
---@type fun(object: any): dreamwork.Metatable | nil
std.getmetatable = getmetatable

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
---[View documents](http://www.lua.org/manual/5.4/manual.html#pdf-setmetatable)
---
---@generic K, V
---@type fun(tbl: table<K,V>, metatable: dreamwork.Metatable<K,V>): table<K,V>
std.setmetatable = setmetatable

std.xpcall = xpcall
std.pcall = pcall

-- raw data library
dofile( "dreamwork/std/raw.lua" )

---@class dreamwork.std.raw
local raw = std.raw

std.select = raw.select
std.tostring = raw.tostring

-- debug library
dofile( "dreamwork/std/debug.lua" )

---@class dreamwork.std.debug
local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetavalue = debug.getmetavalue

-- we need more sugar!!1
raw.getmetatable = debug.getmetatable
raw.setmetatable = debug.setmetatable

---@type fun( lua_path: string )
---@diagnostic disable-next-line: undefined-global
local send = LUA_SERVER and AddCSLuaFile or debug_fempty

send( "dreamwork/loader.lua" )
send( "dreamwork/std/raw.lua" )
send( "dreamwork/std/debug.lua" )

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

-- jit library
dofile( "dreamwork/std/jit.lua" )
send( "dreamwork/std/jit.lua" )

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
    ---@generic K, V
    ---@param tbl table<K, V>
    ---@param key K | nil
    ---@return K, V
    function std.next( tbl, key )
        return (debug_getmetavalue( tbl, "__pairs" ) or raw_next)( tbl, key )
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
    ---@generic K, V
    ---@param t table<K, V>
    ---@return fun( table: table<K, V>, index: ( K | nil ) ): K, V
    ---@return table<K, V>
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
    ---@generic V
    ---@param t V[]
    ---@return fun( table: V[], i: ( integer | nil ) ): integer, V
    ---@return V[]
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
--- Checks if the value is valid.
---
---@param value any
---@return boolean is_valid
function std.isValid( value )
    local fn = debug_getmetavalue( value, "__isvalid" )
    if fn == nil then
        return false
    else
        return fn( value )
    end
end

-- math library
dofile( "dreamwork/std/math.lua" )
send( "dreamwork/std/math.lua" )

---@class dreamwork.std.math
local math = std.math
local math_min = math.min
local math_relative = math.relative

--- [SHARED AND MENU]
---
--- The global environment table (outside of DreamWork).
---
---@type _G
---@diagnostic disable-next-line: undefined-global
std.global = std.getfenv( 1 ) or _G or _ENV

-- os library
dofile( "dreamwork/std/os.lua" )
send( "dreamwork/std/os.lua" )

dreamwork.InitTime = std.os.clock()

-- detour library
dofile( "dreamwork/detour.lua" )
send( "dreamwork/detour.lua" )

-- garbage collector
dofile( "dreamwork/std/gc.lua" )
send( "dreamwork/std/gc.lua" )

-- table library
dofile( "dreamwork/std/table.lua" )
send( "dreamwork/std/table.lua" )

-- string library
dofile( "dreamwork/std/string.lua" )
send( "dreamwork/std/string.lua" )

-- bit library
dofile( "dreamwork/std/bit.lua" )
send( "dreamwork/std/bit.lua" )

-- bytepack library
dofile( "dreamwork/std/codec/bytepack.lua" )
send( "dreamwork/std/codec/bytepack.lua" )

-- bitpack library
dofile( "dreamwork/std/codec/bitpack.lua" )
send( "dreamwork/std/codec/bitpack.lua" )

-- symbols
dofile( "dreamwork/std/types/symbol.lua" )
send( "dreamwork/std/types/symbol.lua" )

-- class library
dofile( "dreamwork/std/class.lua" )
send( "dreamwork/std/class.lua" )

-- queue class
dofile( "dreamwork/std/types/queue.lua" )
send( "dreamwork/std/types/queue.lua" )

-- stack class
dofile( "dreamwork/std/types/stack.lua" )
send( "dreamwork/std/types/stack.lua" )

-- node class
dofile( "dreamwork/std/types/node.lua" )
send( "dreamwork/std/types/node.lua" )

-- version class
dofile( "dreamwork/std/types/version.lua" )
send( "dreamwork/std/types/version.lua" )

-- time library
dofile( "dreamwork/std/time.lua" )
send( "dreamwork/std/time.lua" )

-- coroutine library
dofile( "dreamwork/std/coroutine.lua" )
send( "dreamwork/std/coroutine.lua" )

-- utf8 encoding library
dofile( "dreamwork/std/codec/utf8.lua" )
send( "dreamwork/std/codec/utf8.lua" )

-- utf16 encoding library
dofile( "dreamwork/std/codec/utf16.lua" )
send( "dreamwork/std/codec/utf16.lua" )

-- utf32 encoding library
dofile( "dreamwork/std/codec/utf32.lua" )
send( "dreamwork/std/codec/utf32.lua" )

-- buffer library
dofile( "dreamwork/std/codec/buffer.lua" )
send( "dreamwork/std/codec/buffer.lua" )

-- unicode encoding library
dofile( "dreamwork/std/codec/unicode.lua" )
send( "dreamwork/std/codec/unicode.lua" )

-- futures library
dofile( "dreamwork/std/futures.lua" )
send( "dreamwork/std/futures.lua" )

---@class dreamwork.std.string
local string = std.string
local string_format = string.format
local string_sub, string_len = string.sub, string.len
local string_char, string_byte = string.char, string.byte

---@class dreamwork.std.table
local table = std.table
local table_concat = table.concat

local bytepack = std.bytepack

do

    local bytepack_writeHex8 = bytepack.writeHex8

    ---@type table<integer, string>
    local escape_sequences = {
        [ 0x5C ] = "\\\\",
        [ 0x07 ] = "\\a",
        [ 0x08 ] = "\\b",
        [ 0x0C ] = "\\f",
        [ 0x0A ] = "\\n",
        [ 0x0D ] = "\\r",
        [ 0x09 ] = "\\t",
        [ 0x0B ] = "\\v",
        [ 0x22 ] = "\\\"",
        [ 0x27 ] = "\\\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Escapes special characters in a string.
    ---
    ---@param str string The string to escape.
    ---@param start_position? integer The start index.
    ---@param end_position? integer The end index.
    ---@param encode_spaces? boolean Whether to encode spaces.
    ---@return string escaped_str The escaped string.
    function string.escape( str, start_position, end_position, encode_spaces )
        ---@type integer
        local str_length = string_len( str )

        if str_length == 0 then
            return str
        end

        if start_position == nil then
            start_position = 1
        elseif start_position < 0 then
            start_position = math_relative( start_position, str_length )
        else
            start_position = math_min( start_position, str_length )
        end

        if end_position == nil then
            end_position = str_length
        elseif end_position < 0 then
            end_position = math_relative( end_position, str_length )
        else
            end_position = math_min( end_position, str_length )
        end

        local sequence_position = start_position
        local segments, segment_count = {}, 0

        local in_range = encode_spaces and 0x21 or 0x20

        for index = start_position, end_position, 1 do
            local uint8 = string_byte( str, index, index )
            local escape_sequence = escape_sequences[ uint8 ]
            if escape_sequence ~= nil then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. escape_sequence
                sequence_position = index + 1
            elseif uint8 < in_range or uint8 > 0x7F then
                segment_count = segment_count + 1
                segments[ segment_count ] = string_sub( str, sequence_position, index - 1 ) .. string_char( 0x5C, 0x78, bytepack_writeHex8( uint8 ) )
                sequence_position = index + 1
            end
        end

        segment_count = segment_count + 1
        segments[ segment_count ] = string_sub( str, sequence_position, end_position )

        return table_concat( segments, "", 1, segment_count )
    end

end

do

    local bytepack_readHex8 = bytepack.readHex8

    ---@type table<integer, string>
    local unescape_sequences = {
        [ 0x5C ] = "\\",
        [ 0x61 ] = "\a",
        [ 0x62 ] = "\b",
        [ 0x66 ] = "\f",
        [ 0x6E ] = "\n",
        [ 0x72 ] = "\r",
        [ 0x74 ] = "\t",
        [ 0x76 ] = "\v",
        [ 0x22 ] = "\"",
        [ 0x27 ] = "\'"
    }

    --- [SHARED AND MENU]
    ---
    --- Unescapes special characters in a string.
    ---
    ---@param escaped_str string The string to unescape.
    ---@param start_position? integer The start index.
    ---@param end_position? integer The end index.
    ---@return string str The unescaped string.
    function string.unescape( escaped_str, start_position, end_position )
        ---@type integer
        local str_length = string_len( escaped_str )

        if str_length == 0 then
            return escaped_str
        end

        if start_position == nil then
            start_position = 1
        elseif start_position < 0 then
            start_position = math_relative( start_position, str_length )
        else
            start_position = math_min( start_position, str_length )
        end

        if end_position == nil then
            end_position = str_length
        elseif end_position < 0 then
            end_position = math_relative( end_position, str_length )
        else
            end_position = math_min( end_position, str_length )
        end

        local segments, segment_count = {}, 0

        while true do
            local uint8_1 = string_byte( escaped_str, start_position, start_position )
            if uint8_1 == nil then
                break
            end

            segment_count = segment_count + 1

            if uint8_1 == 0x5C --[[ "\" ]] then
                start_position = start_position + 1

                local uint8_2 = string_byte( escaped_str, start_position, start_position )
                if uint8_2 == nil then
                    segments[ segment_count ] = string_char( uint8_1 )
                    break
                elseif uint8_2 == 0x78 --[[ "x" ]] then
                    start_position = start_position + 1

                    local uint8_3, uint8_4 = string_byte( escaped_str, start_position, start_position + 1 )
                    if uint8_3 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2 )
                        break
                    elseif uint8_4 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2, uint8_3 )
                        break
                    end

                    start_position = start_position + 1

                    local decoded_uint8 = bytepack_readHex8( uint8_3, uint8_4 )
                    if decoded_uint8 == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2, uint8_3, uint8_4 )
                    else
                        segments[ segment_count ] = string_char( decoded_uint8 )
                    end
                else
                    local unescape_sequence = unescape_sequences[ uint8_2 ]
                    if unescape_sequence == nil then
                        segments[ segment_count ] = string_char( uint8_1, uint8_2 )
                    else
                        segments[ segment_count ] = unescape_sequence
                    end
                end
            else
                segments[ segment_count ] = string_char( uint8_1 )
            end

            if start_position == end_position then
                break
            else
                start_position = start_position + 1
            end
        end

        if segment_count == 0 then
            return ""
        elseif segment_count == 1 then
            return segments[ 1 ]
        else
            return table_concat( segments, "", 1, segment_count )
        end
    end

end

do

    ---@class dreamwork.std
    ---@field SYSTEM_OSX boolean `true` if the game is running on OSX.
    ---@field SYSTEM_LINUX boolean `true` if the game is running on Linux.
    ---@field SYSTEM_WINDOWS boolean `true` if the game is running on Windows.
    ---@field SYSTEM_X64 boolean `true` if the game is running on 64-bit architecture.
    ---@field SYSTEM_X32 boolean `true` if the game is running on 32-bit architecture.
    ---@field SYSTEM_X86 boolean `true` if the game is running on 32-bit architecture.

    local jit = std.jit
    local jit_os = string.lower( jit.os )

    std.SYSTEM_OSX = jit_os == "osx"
    std.SYSTEM_LINUX = jit_os == "linux"
    std.SYSTEM_WINDOWS = jit_os == "windows"

    std.SYSTEM_X64 = string.match( jit.arch, "64" ) ~= nil
    std.SYSTEM_X32 = not std.SYSTEM_X64
    std.SYSTEM_X86 = std.SYSTEM_X32

end

do

    local time = std.time
    local gc = std.gc

    --- [SHARED AND MENU]
    ---
    --- Runs a benchmark on the given function, measuring the time it takes to execute a specified number of iterations.
    ---
    ---@param name string The name of the benchmark.
    ---@param fn function The function to benchmark.
    ---@param iterations? integer The number of iterations to run.
    function dreamwork.bench( name, fn, iterations )
        if iterations == nil then
            iterations = 1000
        end

        local warmup = math.min( iterations / 100, 100 )

        for _ = 1, warmup do
            fn()
        end

        gc.stop()
        time.tick()

        for _ = 1, iterations do
            fn()
        end

        local time_took = time.tick()
        gc.restart()

        local avg = time_took / iterations
        raw.print( string.format( "[DW] Benchmark `%s` - iter: %d / avg: %f / exp: %s / total: %f sec.", name, iterations, avg, time.transform( math.ceil( time.transform( avg, "s", "ms", true ) * iterations ), "ms", "s", true ), time_took ) )

        return time_took
    end

end

do

    local debug_registermetatable = debug.registermetatable

    local debug_getmetatable = debug.getmetatable
    local debug_setmetatable = debug.setmetatable

    -- nil ( 0 )
    do

        ---@class dreamwork.NilMetatable : dreamwork.Metatable
        local Nil = debug_getmetatable( nil )

        if Nil == nil then
            Nil = {}
            debug_setmetatable( nil, Nil )
        end

        debug_registermetatable( "nil", Nil )

        Nil.__type = "nil"
        Nil.__typeid = 0

        ---@private
        function Nil.__toboolean()
            return false
        end

        ---@private
        function Nil.__tonumber()
            return 0
        end

        Nil.__len = Nil.__tonumber

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is `nil`.
        ---
        ---@param value any
        ---@return boolean is_nil
        function std.isNil( value )
            return value == nil
        end

        std.Nil = Nil

    end

    -- boolean ( 1 )
    do

        ---@class dreamwork.BooleanMetatable : dreamwork.Metatable
        local Boolean = debug_getmetatable( false )

        if Boolean == nil then
            Boolean = {}
            debug_setmetatable( false, Boolean )
        end

        debug_registermetatable( "boolean", Boolean )

        Boolean.__type = "boolean"
        Boolean.__typeid = 1

        ---@private
        function Boolean.__toboolean( value )
            return value
        end

        ---@private
        function Boolean.__tonumber( value )
            return value == true and 1 or 0
        end

        ---@private
        function Boolean.__len()
            return 1
        end

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is `boolean`.
        ---
        ---@param value any
        ---@return boolean is_bool
        function std.isBoolean( value )
            return value == true or value == false
        end

        std.Boolean = Boolean

    end

    -- number ( 3 )
    do

        ---@class dreamwork.NumberMetatable : dreamwork.Metatable
        local Number = debug_getmetatable( 0 )

        if Number == nil then
            Number = {}
            debug_setmetatable( 0, Number )
        end

        debug_registermetatable( "number", Number )

        Number.__type = "number"
        Number.__typeid = 3

        ---@private
        function Number.__toboolean( value )
            return value ~= 0
        end

        ---@private
        function Number.__tonumber( value )
            return value
        end

        do

            local math_ceil, math_log, math_isfinite = math.ceil, math.log, math.isfinite
            local math_ln2 = math.ln2

            ---@param value number
            ---@private
            function Number.__len( value )
                if math_isfinite( value ) then
                    if (value % 1) == 0 then
                        return math_ceil( math_log( value + 1 ) / math_ln2 ) + (value < 0 and 1 or 0)
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

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `number`.
        ---
        ---@param value any
        ---@return boolean is_number
        function std.isNumber( value )
            return debug_getmetatable( value ) == Number
        end

        std.Number = Number

    end

    -- string ( 4 )
    do

        local String = debug_getmetatable( "" )

        if String == nil then
            String = {}
            debug_setmetatable( "", String )
        end

        debug_registermetatable( "string", String )

        String.__type = "string"
        String.__typeid = 4

        ---@private
        function String.__toboolean( value )
            return value ~= "" and value ~= "0" and value ~= "false"
        end

        String.__tonumber = raw.tonumber
        String.__len = string.len

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `string`.
        ---
        ---@param value any
        ---@return boolean is_string
        function std.isString( value )
            return debug_getmetatable( value ) == String
        end

        std.String = String

    end

    -- table ( 5 )
    ---@diagnostic disable-next-line: undefined-global
    if istable == nil then

        local raw_type = raw.type

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `table`.
        ---
        ---@param value any
        ---@return boolean is_table
        ---@diagnostic disable-next-line: duplicate-set-field
        function std.isTable( value )
            return raw_type( value ) == "table"
        end

    else
        ---@diagnostic disable-next-line: undefined-global
        std.isTable = istable
    end

    -- function ( 6 )
    do

        ---@class dreamwork.FunctionMetatable : dreamwork.Metatable
        local Function = debug_getmetatable( debug_fempty )

        if Function == nil then
            Function = {}
            debug_setmetatable( debug_fempty, Function )
        end

        debug_registermetatable( "function", Function )

        Function.__type = "function"
        Function.__typeid = 6

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `function`.
        ---
        ---@param value any
        ---@return boolean is_function
        function std.isFunction( value )
            return debug_getmetatable( value ) == Function
        end

        --- [SHARED AND MENU]
        ---
        --- Checks if the value is callable, basically it's a function or a table with a callable `__call` metamethod.
        ---
        ---@param value any
        ---@return boolean is_callable
        function std.isCallable( value )
            local metatable = debug_getmetatable( value )
            return metatable ~= nil and (metatable == Function or debug_getmetatable( metatable.__call ) == Function)
        end

        std.Function = Function

    end

    -- thread ( 8 )
    do

        local object = std.coroutine.create( debug_fempty )

        ---@class dreamwork.std.ThreadMetatable : dreamwork.Metatable
        local Thread = debug_getmetatable( object )

        if Thread == nil then
            Thread = {}
            debug_setmetatable( object, Thread )
        end

        debug_registermetatable( "thread", Thread )

        Thread.__type = "thread"
        Thread.__typeid = 8

        --- [SHARED AND MENU]
        ---
        --- Checks whether the value type is a `thread`.
        ---
        ---@param value any
        ---@return boolean is_thread
        function std.isThread( value )
            return debug_getmetatable( value ) == Thread
        end

        std.Thread = Thread

    end

end

local isString = std.isString
local isTable = std.isTable

--- [SHARED AND MENU]
---
--- Returns the value of the given key path.
---
--- If the key path does not exist, returns `nil`.
---
--- Example:
---
--- ```lua
---     local t = { a = { b = { c = { d = { e = "e value!" } } } } }
---     print( table.get( t, "a.b.c.d.e" ) ) -- e value!
--- ```
---@param tbl table The table to get the value from.
---@param str string The key path to get.
---@param separator? integer The separator of the key path, default is `0x2E`.
---@param str_length? integer The length of the key path, default is `string.len( str )`.
---@return any value The value of the key path.
function table.get( tbl, str, separator, start_position, end_position, str_length )
    if separator == nil then
        separator = 0x2E --[[ "." ]]
    end

    if str_length == nil then
        str_length = string_len( str )
    end

    if start_position == nil then
        start_position = 1
    elseif start_position < 0 then
        start_position = math_relative( start_position, str_length )
    else
        start_position = math_min( start_position, str_length )
    end

    if end_position == nil then
        end_position = str_length
    elseif end_position < 0 then
        end_position = math_relative( end_position, str_length )
    else
        end_position = math_min( end_position, str_length )
    end

    if start_position > end_position then
        return nil
    end

    local split_position = start_position - 1

    ::table_lookup_loop::

    if string_byte( str, start_position, start_position ) == separator then
        if split_position ~= start_position then
            tbl = tbl[ string_sub( str, split_position + 1, start_position - 1 ) ]
            if tbl == nil then return nil end
        end

        split_position = start_position
    end

    if start_position ~= end_position then
        start_position = start_position + 1
        goto table_lookup_loop
    end

    if split_position ~= start_position then
        tbl = tbl[ string_sub( str, split_position + 1, start_position ) ]
    end

    return tbl
end

--- [SHARED AND MENU]
---
--- Sets the value of the given key path.
---
--- Tables are created if they do not exist.
---
--- Example:
---
--- ```lua
---     local t = {}
---     table.set( t, "a.b.c.d.e", "e value!" )
---     print( t.a.b.c.d.e ) -- e value!
--- ```
---
---@param tbl table The table to set the value in.
---@param str string The key path.
---@param value any The value to set.
---@param separator? integer The separator of the key path, default is `0x2E`.
---@param str_length? integer The length of the key path, default is `string.len( str )`.
function table.set( tbl, str, value, separator, str_length )
    if separator == nil then
        separator = 0x2E --[[ "." ]]
    end

    if str_length == nil then
        str_length = string_len( str )
    end

    local split_position = 0
    local position = 1

    while true do
        local uint8 = string_byte( str, position, position )
        if uint8 == separator then
            if split_position ~= position then
                local key = string_sub( str, split_position + 1, position - 1 )

                if position == str_length then
                    tbl[ key ] = value
                    return
                end

                local tbl_value = tbl[ key ]
                if tbl_value ~= nil and isTable( tbl_value ) then
                    tbl = tbl_value
                else
                    local new_tbl = {}
                    tbl[ key ] = new_tbl
                    tbl = new_tbl
                end
            end

            split_position = position
        end

        if position == str_length then
            break
        else
            position = position + 1
        end
    end

    if split_position ~= position then
        tbl[ string_sub( str, split_position + 1, position ) ] = value
    end
end

do

    --- [SHARED AND MENU]
    ---
    --- Creates a shallow copy of the given table.
    ---
    --- The original table is not modified.
    ---
    --- The returned table is a shallow copy of the original table.
    ---
    ---@param tbl table The table to copy.
    ---@return table copy The copied table.
    local function copy_fn( tbl )
        local fn = debug_getmetavalue( tbl, "__copy" )
        if fn ~= nil then
            return fn( tbl )
        end

        local copy_tbl = {}
        for key, value in pairs( tbl ) do
            if isTable( value ) then
                copy_tbl[ key ] = copy_fn( value )
            else
                copy_tbl[ key ] = value
            end
        end

        return copy_tbl
    end

    table.copy = copy_fn

end


-- path library
dofile( "dreamwork/std/path.lua" )
send( "dreamwork/std/path.lua" )

-- color library
dofile( "dreamwork/std/color.lua" )
send( "dreamwork/std/color.lua" )

local color_lib = std.color

---@class dreamwork.std.color.Scheme
local color_scheme = color_lib.Scheme

do

    local color_fromRGBA = color_lib.fromRGBA

    --- [SHARED AND MENU]
    ---
    --- If `value` has a metamethod `__tocolor`, calls it with `value` as argument and returns its result.
    ---
    --- Otherwise, returns `nil`.
    ---
    ---@param value any The valueect to convert to a color.
    ---@return dreamwork.std.Color | nil clr The color value of `value`, or `nil` if `value` cannot be converted to a color.
    function std.tocolor( value )
        ---@type fun(value: any): (red: integer, green: integer, blue: integer, alpha: (integer | nil)) | nil
        local fn = debug_getmetavalue( value, "__tocolor" )
        if fn == nil then
            return nil
        else
            return color_fromRGBA( fn( value ) )
        end
    end

    -- General
    color_scheme.white = color_scheme[ 255 ]
    color_scheme.black = color_scheme[ 0 ]

    color_scheme.red = color_lib.fromRGBA( 255, 0, 0, 255 )
    color_scheme.green = color_lib.fromRGBA( 0, 255, 0, 255 )
    color_scheme.blue = color_lib.fromRGBA( 0, 0, 255, 255 )

    color_scheme.yellow = color_lib.fromRGBA( 255, 255, 0, 255 )
    color_scheme.cyan = color_lib.fromRGBA( 0, 255, 255, 255 )
    color_scheme.magenta = color_lib.fromRGBA( 255, 0, 255, 255 )

    color_scheme.gray = color_scheme[ 128 ]

    color_scheme.text_primary = color_scheme[ 200 ]
    color_scheme.text_secondary = color_scheme[ 150 ]

    -- Garry's Mod
    -- Thank you code_gs <3
    -- https://discord.com/channels/565105920414318602/565108080300261398/905385921283756062
    color_scheme.server_message = color_lib.fromRGBA( 156, 241, 255, 200 )
    color_scheme.server_error = color_lib.fromRGBA( 136, 221, 255, 255 )

    color_scheme.client_message = color_lib.fromRGBA( 255, 241, 122, 200 )
    color_scheme.client_error = color_lib.fromRGBA( 255, 221, 102, 255 )

    color_scheme.menu_message = color_lib.fromRGBA( 100, 220, 100, 200 )
    color_scheme.menu_error = color_lib.fromRGBA( 120, 220, 100, 255 )

    -- DreamWork
    color_scheme.dreamwork_main = color_lib.fromRGBA( 180, 180, 255 )

    color_scheme.dreamwork_info = color_lib.fromRGBA( 70, 135, 255 )
    color_scheme.dreamwork_warn = color_lib.fromRGBA( 255, 130, 90 )
    color_scheme.dreamwork_error = color_lib.fromRGBA( 250, 55, 40 )
    color_scheme.dreamwork_debug = color_lib.fromRGBA( 0, 200, 150 )

    color_scheme.dreamwork_menu = color_lib.fromRGBA( 75, 175, 80 )
    color_scheme.dreamwork_client = color_lib.fromRGBA( 225, 170, 10 )
    color_scheme.dreamwork_server = color_lib.fromRGBA( 5, 170, 250 )

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

    local raw_get = raw.get

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
            if string.hasPrefix( key, "__" ) then
                return nil
            end
        end

        return raw_get( tbl, key )
    end

end

do

    local debug_getinfo = debug.getinfo
    local raw_type = raw.type

    --- [SHARED AND MENU]
    ---
    --- Returns a string representing the name of the type of the passed object.
    ---
    ---@param value any The value to get the type of.
    ---@return string type_name The type name of the given value.
    local function type( value )
        return debug_getmetavalue( value, "__type" ) or
            debug_getmetavalue( value, "MetaName" ) or
            raw_type( value )
    end

    std.type = type

    --- [SHARED AND MENU]
    ---
    --- Validates the type of the argument and returns a boolean and an error message.
    ---
    ---@param value any The argument value.
    ---@param arg_num any The argument number/key.
    ---@param expected_type "string" | "number" | "boolean" | "table" | "function" | "thread" | "any" | string The expected type name.
    ---@return boolean ok `true` if the argument is of the expected type; otherwise, `false`.
    ---@return string? msg The error message if the argument type does not match the expected type, otherwise `nil`.
    function std.arg( value, arg_num, expected_type )
        local got = type( value )
        if got == expected_type or expected_type == "any" then
            return true, nil
        else
            return false, string_format( "bad argument #%s to \'%s\' ('%s' expected, got '%s')", arg_num, debug_getinfo( 2, "n" ).name or "unknown", expected_type, got )
        end
    end

    local len = std.len

    do

        ---@generic F: function
        ---@class dreamwork.OverloadInput<F>
        ---@field match string[] | string
        ---@field fn F

        ---@generic F: function
        ---@param inputs dreamwork.OverloadInput[]
        ---@param ... any
        ---@return function | nil
        local function input_select( inputs, ... )
            ---@type integer
            local arg_count = select( "#", ... )

            ---@type string[]
            local arg_types = {}

            for i = 1, arg_count, 1 do
                arg_types[ i ] = type( select( i, ... ) )
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
        --- Overloads the given function with the given inputs.
        ---
        ---@generic F: function
        ---@param inputs dreamwork.OverloadInput<F>[]
        ---@param fallback_fn? F
        ---@return F fn_over
        function std.dispatch( inputs, fallback_fn )
            local input_count = len( inputs )
            inputs[ 0 ] = input_count

            for i = 1, input_count, 1 do
                local input = inputs[ i ]

                if not std.isFunction( input.fn ) then
                    error( "overload: input " .. i .. " is not a function", 2 )
                end

                local input_match = input.match
                if input_match == nil then
                    error( "overload: input " .. i .. " has no match", 2 )
                elseif std.isString( input_match ) then
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

    end

    --- [SHARED AND MENU]
    ---
    --- Overloads the given function with the given inputs.
    ---
    ---@generic F: function
    ---@param main_fn function
    ---@param match string[] | string
    ---@param overload_fn function
    ---@return function
    function std.overload( main_fn, match, overload_fn )
        ---@type integer
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
                ---@type integer
                local arg_count = select( "#", ... )
                if arg_count ~= 1 then
                    return main_fn( ... )
                end

                if match == type( select( 1, ... ) ) then
                    return overload_fn( ... )
                else
                    return main_fn( ... )
                end
            end
        end

        return function( ... )
            ---@type integer
            local arg_count = select( "#", ... )
            if arg_count == required_args then
                for i = 1, arg_count, 1 do
                    if match[ i ] == type( select( i, ... ) ) then
                        if i == arg_count then
                            return overload_fn( ... )
                        end
                    else
                        break
                    end
                end
            end

            return main_fn( ... )
        end
    end

end

-- engine submodule
dofile( "dreamwork/engine.lua" )
send( "dreamwork/engine.lua" )

local engine = dreamwork.engine

do

    local ErrorNoHalt = ErrorNoHalt

    if ErrorNoHalt == nil then
        local engine_consoleMessageColored = engine.consoleMessageColored
        local error_color = color_scheme.error

        function ErrorNoHalt( str )
            return engine_consoleMessageColored( str, error_color )
        end
    end

    local debug_getinfo = debug.getinfo

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

            local stack, size = { "\n[" .. (title or "LUA ERROR") .. "] " .. message }, 1

            while true do
                local info = debug_getinfo( size + stack_level, "Sln" )
                if info == nil then
                    break
                end

                size = size + 1
                stack[ size ] = table_concat( { string_rep( " ", size ), (size - 1), ". ", info.name or "unknown", " - ", info.short_src or "unknown", ":", info.currentline or -1 } )
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
        return std_error( string_format( fmt, ... ), (stack_level or 1) + 1, dont_break )
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

        std.errorf( 4, false, fmt, ... )
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

        local color_fromHex = std.color.fromHex
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
                if isString( value ) then
                    ---@cast value string

                    if string_byte( value, 1, 1 ) == 0x23 --[[ # ]] and string_len( value ) < 10 then
                        color = color_fromHex( value )
                    else
                        engine_consoleMessageColored( value, color )
                    end
                else
                    ---@cast value any
                    engine_consoleMessageColored( tostring( value ), tocolor( value ) or color )
                end
            end

            engine_consoleMessage( "\n" )
        end

        -- TODO: rewrite function below with goto

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
                    if (index - break_point) ~= 0 then
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
                        if (index - break_point) ~= 0 then
                            buffer_length = buffer_length + 1
                            buffer[ buffer_length ] = string_sub( fmt, break_point, index - 1 )
                        end

                        if buffer_length ~= 0 then
                            engine_consoleMessageColored( table_concat( buffer, "", 1, buffer_length ), color )
                            buffer_length = 0
                        end

                        index = index + 1

                        if (end_index - index) == 0 then
                            color = realm_color
                        else
                            local color_str = string_sub( fmt, index, end_index - 1 )
                            if string_byte( color_str, 1, 1 ) == 0x23 --[[ # ]] then
                                color = color_fromHex( color_str )
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

-- crc checksum clases
dofile( "dreamwork/std/checksum/crc.lua" )
send( "dreamwork/std/checksum/crc.lua" )

-- adler checksum classes
dofile( "dreamwork/std/checksum/adler.lua" )
send( "dreamwork/std/checksum/adler.lua" )

-- fletcher checksum library
dofile( "dreamwork/std/checksum/fletcher.lua" )
send( "dreamwork/std/checksum/fletcher.lua" )

-- base16 encoding library
dofile( "dreamwork/std/codec/base16.lua" )
send( "dreamwork/std/codec/base16.lua" )

-- base32 encoding library
dofile( "dreamwork/std/codec/base32.lua" )
send( "dreamwork/std/codec/base32.lua" )

-- base64 encoding library
dofile( "dreamwork/std/codec/base64.lua" )
send( "dreamwork/std/codec/base64.lua" )

-- percent encoding library
dofile( "dreamwork/std/codec/percent.lua" )
send( "dreamwork/std/codec/percent.lua" )

-- punycode encoding library
dofile( "dreamwork/std/codec/punycode.lua" )
send( "dreamwork/std/codec/punycode.lua" )

-- json encoding library
dofile( "dreamwork/std/codec/json.lua" )
send( "dreamwork/std/codec/json.lua" )

-- xml encoding library
dofile( "dreamwork/std/codec/xml.lua" )
send( "dreamwork/std/codec/xml.lua" )

-- vdf encoding library
dofile( "dreamwork/std/codec/vdf.lua" )
send( "dreamwork/std/codec/vdf.lua" )

-- xml encoding library
dofile( "dreamwork/std/codec/xml.lua" )
send( "dreamwork/std/codec/xml.lua" )

-- fnv hash library
dofile( "dreamwork/std/hash/fnv.lua" )
send( "dreamwork/std/hash/fnv.lua" )

-- md5 hash library
dofile( "dreamwork/std/hash/md5.lua" )
send( "dreamwork/std/hash/md5.lua" )

-- sha1 hash library
dofile( "dreamwork/std/hash/sha1.lua" )
send( "dreamwork/std/hash/sha1.lua" )

-- sha256 hash library
dofile( "dreamwork/std/hash/sha256.lua" )
send( "dreamwork/std/hash/sha256.lua" )

-- sha512 hash library
dofile( "dreamwork/std/hash/sha512.lua" )
send( "dreamwork/std/hash/sha512.lua" )

-- bigint class
dofile( "dreamwork/std/types/bigint.lua" )
send( "dreamwork/std/types/bigint.lua" )

-- uuid library
dofile( "dreamwork/std/uuid.lua" )
send( "dreamwork/std/uuid.lua" )

---@class dreamwork.std.crypto
std.crypto = std.crypto or {}

-- hmac library
dofile( "dreamwork/std/crypto/hmac.lua" )
send( "dreamwork/std/crypto/hmac.lua" )

-- pbkdf2 library
dofile( "dreamwork/std/crypto/pbkdf2.lua" )
send( "dreamwork/std/crypto/pbkdf2.lua" )

-- TODO: crypto.ed25519 & crypto.chacha20/xchacha

-- lzw compression library
dofile( "dreamwork/std/compress/lzw.lua" )
send( "dreamwork/std/compress/lzw.lua" )

-- deflate compression library
dofile( "dreamwork/std/compress/deflate.lua" )
send( "dreamwork/std/compress/deflate.lua" )

-- lzma compression library
dofile( "dreamwork/std/compress/lzma.lua" )
send( "dreamwork/std/compress/lzma.lua" )

-- 2d vector class
dofile( "dreamwork/std/types/vector2.lua" )
send( "dreamwork/std/types/vector2.lua" )

-- 3d vector class
dofile( "dreamwork/std/types/vector3.lua" )
send( "dreamwork/std/types/vector3.lua" )

-- quaternion class
dofile( "dreamwork/std/types/quaternion.lua" )
send( "dreamwork/std/types/quaternion.lua" )

-- 3d angle class
dofile( "dreamwork/std/types/angle3.lua" )
send( "dreamwork/std/types/angle3.lua" )

-- valve matrix class
dofile( "dreamwork/std/types/vmatrix.lua" )
send( "dreamwork/std/types/vmatrix.lua" )
