---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.raw
local raw = std.raw

--- [SHARED AND MENU]
---
--- The debug library is intended to help you debug your scripts,
--- however it also has several other powerful uses.
---
---@class dreamwork.std.debug
local debug = {}
std.debug = debug

local fempty = debug.fempty
if fempty == nil then

    --- [SHARED AND MENU]
    ---
    --- Just empty function, do nothing.
    ---
    --- Sometimes makes jit happy :>
    ---
    function fempty()
        -- yep, it's literally empty
    end

    debug.fempty = fempty

end

do

    local glua_debug = _G.debug

    -- LuaJIT
    debug.newproxy = _G.newproxy

    -- Lua 5.1
    debug.debug = glua_debug.debug
    debug.getinfo = glua_debug.getinfo
    debug.getregistry = glua_debug.getregistry
    debug.traceback = glua_debug.traceback

    debug.getlocal = glua_debug.getlocal
    debug.setlocal = glua_debug.setlocal

    --- [SHARED AND MENU]
    ---
    --- Returns the metatable of the given value.
    ---
    --- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.getmetatable)
    ---
    ---@type fun( object: any ): dreamwork.Metatable | nil
    debug.getmetatable = glua_debug.getmetatable or std.getmetatable

    --- [SHARED AND MENU]
    ---
    --- Sets the metatable for the given value to the given table (which can be `nil`).
    ---
    --- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-debug.setmetatable)
    ---
    ---@type fun( object: any, metatable: dreamwork.Metatable | nil )
    debug.setmetatable = glua_debug.setmetatable

    debug.getupvalue = glua_debug.getupvalue -- fucked up in menu
    debug.setupvalue = glua_debug.setupvalue -- fucked up in menu

    debug.getfenv = glua_debug.getfenv or getfenv
    debug.setfenv = glua_debug.setfenv or setfenv

    debug.gethook = glua_debug.gethook
    debug.sethook = glua_debug.sethook

    -- Lua 5.2/jit
    debug.upvalueid = glua_debug.upvalueid       -- fucked up in menu
    debug.upvaluejoin = glua_debug.upvaluejoin   -- fucked up in menu

    debug.getuservalue = glua_debug.getuservalue -- fucked up in menu
    debug.setuservalue = glua_debug.setuservalue -- fucked up in menu

end

if debug.getmetatable == nil or debug.setmetatable == nil or debug.getinfo == nil then
    error( "execution environment is broken or sandboxed - it's over ;c" )
end

--- [SHARED AND MENU]
---
--- Calls the given function or object with the given arguments.
---
---@param f function | any The function or object to call.
---@param ... any The arguments to pass to the function or object.
---@return any ... The result of execution.
function debug.fcall( f, ... )
    return f( ... )
end

local debug_getmetatable = debug.getmetatable
local debug_getinfo = debug.getinfo

if debug.newproxy == nil then

    local setmetatable = std.setmetatable

    ---@diagnostic disable-next-line: duplicate-set-field
    function debug.newproxy( add_metatable )
        local fake_userdata = {}

        if add_metatable then
            ---@type dreamwork.Metatable | nil
            local metatable

            if add_metatable == true then
                metatable = {}
            else
                metatable = debug_getmetatable( add_metatable )
            end

            setmetatable( fake_userdata, metatable )
        end

        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast fake_userdata userdata

        return fake_userdata
    end

end

do

    local raw_get = raw.get

    --- [SHARED AND MENU]
    ---
    --- Returns the value of the given key in the metatable of the given value.
    ---
    --- Returns `nil` if not found.
    ---
    ---@param value any The value to get the metatable from.
    ---@param key string The searchable key.
    ---@return any | nil value The value of the given key.
    function debug.getmetavalue( value, key, allow_index )
        local metatable = debug_getmetatable( value )
        if metatable == nil then
            return nil
        elseif allow_index then
            return metatable[ key ]
        else
            return raw_get( metatable, key )
        end
    end

end

do

    local debug_getupvalue = debug.getupvalue

    --- [SHARED AND MENU]
    ---
    --- Returns all upvalues of the given function.
    ---
    ---@param fn function The function to get upvalues from.
    ---@param position? integer The start position of the upvalues, default is `0`.
    ---@return table<string, any> values A table with the upvalues.
    ---@return integer value_count The count of upvalues.
    function debug.getupvalues( fn, position )
        if position == nil then
            position = 1
        end

        local index = position
        local values = {}

        ::getupvalues_loop::

        local name, value = debug_getupvalue( fn, index )

        if name ~= nil then
            index = index + 1
            values[ name ] = value
            goto getupvalues_loop
        end

        return values, index - position
    end

end

--- [SHARED AND MENU]
---
--- Returns the function at the given stack level.
---
---@param level integer The stack level.
---@return function | nil The function at the given level, or `nil` if the level is invalid.
function debug.getf( level )
    local info = debug_getinfo( level + 1, "f" )
    if info == nil then
        return nil
    else
        return info.func
    end
end

if raw.type == nil then

    local type = type

    local values, count = debug.getupvalues( type )

    if count == 0 or values.C_type == nil then
        raw.type = type
    else
        raw.type = values.C_type
    end

end

local raw_type = raw.type

--- [SHARED AND MENU]
---
--- Checks if the given function or stack level is a C function.
---
---@param location integer | function The function or stack level.
---@return boolean iscf `true` if the function is a C function, `false` otherwise.
function debug.iscf( location )
    if raw_type( location ) == "number" then
        location = location + 1
    end

    local dbg_info = debug_getinfo( location, "S" )
    if dbg_info == nil then
        return false
    end

    local what = dbg_info.what
    return not (what == "Lua" or what == "lua")
end

local registry = debug.getregistry()

--- [SHARED AND MENU]
---
--- Returns the registry table.
---
---@diagnostic disable-next-line: duplicate-set-field
function debug.getregistry()
    return registry
end

do

    ---@diagnostic disable-next-line: undefined-global
    local FindMetaTable = FindMetaTable

    if FindMetaTable == nil then

        function debug.findmetatable( name )
            return registry[ name ]
        end

    else

        --- [SHARED AND MENU]
        ---
        --- Returns the metatable of the given name or `nil` if not found.
        ---
        ---@param name string The name of the metatable.
        ---@return dreamwork.Metatable | nil meta The metatable.
        function debug.findmetatable( name )
            local cached = registry[ name ]
            if cached ~= nil then
                return cached
            end

            local metatable = FindMetaTable( name )
            if metatable ~= nil then
                registry[ name ] = metatable
                return metatable
            end

            return nil
        end

    end

end

do

    ---@type fun(name: string, tbl: dreamwork.Metatable)
    ---@diagnostic disable-next-line: undefined-global
    local RegisterMetaTable = RegisterMetaTable or fempty

    --- [SHARED AND MENU]
    ---
    --- Registers the metatable of the given name and table.
    ---
    ---@param name string The name of the metatable.
    ---@param tbl dreamwork.Metatable The metatable to register.
    ---@param do_full_register? boolean `true`, the metatable will be registered, `false` otherwise.
    ---@return integer meta_id The ID of the metatable or `-1` if not fully registered.
    function debug.registermetatable( name, tbl, do_full_register )
        tbl = registry[ name ] or tbl
        registry[ name ] = tbl

        if do_full_register then
            RegisterMetaTable( name, tbl )
        end

        return tbl.MetaID or -1
    end

end

--- [SHARED AND MENU]
---
---
---@param name string The name of the metatable.
---@return dreamwork.Metatable metatable The metatable.
function debug.initmetatable( name )
    local metatable = debug.findmetatable( name )
    if metatable == nil then
        metatable = {}
        debug.registermetatable( name, metatable, true )
    end

    return metatable
end

-- gmod developer/s sanity check
if debug_getmetatable( fempty ) == nil then
    debug.setmetatable( fempty, {} )
end

if debug_getmetatable( fempty ) == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns the metatable of the given value or `nil` if not found.
    ---
    ---@param value any The value.
    ---@return dreamwork.Metatable | nil meta The metatable.
    ---@diagnostic disable-next-line: duplicate-set-field
    function debug.getmetatable( value )
        return debug_getmetatable( value ) or registry[ raw_type( value ) ]
    end

    raw.print( "at any cost, but we'll build it once again..." )

end

--- [SHARED AND MENU]
---
--- Returns the current call stack relative to the specified stack level.
---
---@param stack_level? integer The stack `stack_level` to get the stack from.
---@param what? infowhat The fields to get from the stack.
---@return debuginfo[] stack The debug info stack.
---@return integer stack_size The size of the stack.
function debug.getstack( stack_level, what )
    if what == nil then
        what = "Snluf"
    end

    local stack, stack_length = {}, 0

    for location = 1 + (stack_level or 1), 16, 1 do
        local info = debug_getinfo( location, what )
        if info then
            stack_length = stack_length + 1
            stack[ stack_length ] = info
        else
            break
        end
    end

    return stack, stack_length
end

--- [SHARED AND MENU]
---
--- Returns the main function of the current stack.
---
---@param stack_level? integer The stack `stack_level` to get the main function from.
---@return function | nil main_fn The main function or `nil` if not found.
function debug.getfmain( stack_level )
    if stack_level == nil then
        stack_level = 2
    else
        stack_level = stack_level + 1
    end

    ::getfmain_loop::

    local info = debug_getinfo( stack_level, "fS" )

    if info == nil then
        return nil
    elseif info.what == "main" then
        return info.func
    end

    stack_level = stack_level + 1
    goto getfmain_loop
end

do

    local string_match = string.match

    --- [SHARED AND MENU]
    ---
    --- Returns the path to the file that the function is defined in.
    ---
    ---@param f function | integer The function or stack level to get the path from.
    ---@return string | nil file_path The file path or `nil` if not found.
    function debug.getfpath( f )
        local info = debug_getinfo( f, "S" )
        if info ~= nil then
            local source = info.source
            if source ~= nil then
                local rel_path = string_match( source, "^@?.-(lua/.*)$", 1 ) or source
                return "/workspace/lua/" .. (string_match( rel_path, "^.-([%w_]+/gamemode/.*)$", 1 ) or rel_path)
            end
        end

        return nil
    end

end
