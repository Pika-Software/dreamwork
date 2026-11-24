---@class dreamwork
local dreamwork = dreamwork

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

---@class dreamwork.std
local std = dreamwork.std

local class = std.class
local class_init = class.init

local debug = std.debug
local debug_getinfo = debug.getinfo
local debug_newproxy = debug.newproxy
local debug_getmetatable = debug.getmetatable

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_type = raw.type
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_tostring = raw.tostring

local string = std.string
local string_byte = string.byte
local string_format = string.format
local string_hasPrefix = string.hasPrefix

local error = std.error
local getfenv = std.getfenv
local isClass = std.isClass
local isObject = std.isObject


--- [SHARED AND MENU]
---
--- The sandbox of packages, used by `std` classes and functions to keep packages apart:
---
--- * `std` tables are given to packages as shared read-only views;
--- * named objects created by a package get its id as the prefix, `{id}::{name}`;
--- * objects, timeouts and handlers created by a package are released when it unloads.
---
--- The owner of the code is found by the environment of the calling function, see `sandbox.bind`.
---
---@class dreamwork.sandbox
local sandbox = {}
dreamwork.sandbox = sandbox


do

    --- Read-only views of `std` tables, the same view is shared by every package.
    ---
    ---@type table<table, userdata>
    local proxies = {}
    gc_setTableRules( proxies, true, false )

    --- Tables given to packages as is: classes and objects.
    ---
    ---@type table<table, boolean>
    local exposed = {}
    gc_setTableRules( exposed, true, false )

    ---@type fun( value: any ): any
    local proxy_value

    ---@param tbl table
    ---@return userdata
    local function create_proxy( tbl )
        local proxy = debug_newproxy( true )

        local metatable = debug_getmetatable( proxy )
        ---@cast metatable table

        function metatable.__index( _, key )
            return proxy_value( tbl[ key ] )
        end

        function metatable.__newindex( _, key )
            error( string_format( "attempt to modify read-only std table (field '%s')", raw_tostring( key ) ), 2 )
        end

        function metatable.__len()
            return #tbl
        end

        function metatable.__call( _, ... )
            return tbl( ... )
        end

        function metatable.__pairs()
            return function( _, key )
                local next_key, value = raw_next( tbl, key )
                return next_key, proxy_value( value )
            end
        end

        function metatable.__tostring()
            return string_format( "std: %p", tbl )
        end

        proxies[ tbl ] = proxy
        return proxy
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the read-only view of a table, classes, objects and non-table values are returned as is.
    ---
    ---@param value any
    ---@return any
    ---@nodiscard
    function proxy_value( value )
        if raw_type( value ) == "table" then
            local proxy = proxies[ value ]
            if proxy ~= nil then
                return proxy
            elseif exposed[ value ] then
                return value
            elseif isClass( value ) or isObject( value ) then
                exposed[ value ] = true
                return value
            end

            return create_proxy( value )
        end

        return value
    end

    sandbox.proxy = proxy_value

end

--- The owners by the environments of their functions.
---
---@type table<table, dreamwork.sandbox.Owner>
local environment_owners = {}
gc_setTableRules( environment_owners, true, false )

--- The owners of the claimed objects.
---
---@type table<any, dreamwork.sandbox.Owner>
local object_owners = {}
gc_setTableRules( object_owners, true, false )

--- [SHARED AND MENU]
---
--- Binds the functions defined with the environment to the owner.
---
---@param environment table
---@param owner dreamwork.sandbox.Owner
function sandbox.bind( environment, owner )
    environment_owners[ environment ] = owner
end

local sandbox_owner
do

    ---@type function
    local class__call = debug_getmetatable( std.Stack ).__call

    --- [SHARED AND MENU]
    ---
    --- Returns the owner of the Lua function at the stack level, the class plumbing (`__call`, `class.init`) and C functions are skipped.
    ---
    --- The lookup stops at the first other Lua function,
    --- so objects created by `std` itself while a package is calling it are never claimed.
    ---
    ---@param stack_level integer The level to start from, `1` is the function calling `sandbox.owner`.
    ---@return dreamwork.sandbox.Owner | nil owner
    ---@nodiscard
    function sandbox_owner( stack_level )
        stack_level = stack_level + 1

        ::owner_lookup::

        local info = debug_getinfo( stack_level, "fS" )
        if info == nil then
            return nil
        end

        local fn = info.func
        if fn == class__call or fn == class_init or info.what == "C" then
            stack_level = stack_level + 1
            goto owner_lookup
        end

        return environment_owners[ getfenv( fn ) ]
    end

    sandbox.owner = sandbox_owner

end

--- [SHARED AND MENU]
---
--- Returns the owner of the function, `nil` for C functions, callable objects and functions outside of packages.
---
---@param fn any
---@return dreamwork.sandbox.Owner | nil owner
---@nodiscard
local function sandbox_ownerOf( fn )
    if raw_type( fn ) == "function" then
        return environment_owners[ getfenv( fn ) ]
    end

    return nil
end

sandbox.ownerOf = sandbox_ownerOf

--- [SHARED AND MENU]
---
--- Returns the name with the prefix of the owner, `{id}::{name}`.
---
---@param owner dreamwork.sandbox.Owner
---@param name string
---@return string name
---@nodiscard
function sandbox.prefix( owner, name )
    local prefix = owner.id .. "::"

    if string_hasPrefix( name, prefix ) then
        return name
    end

    return prefix .. name
end

--- [SHARED AND MENU]
---
--- Returns the path inside of the root directory of the calling owner, absolute paths are returned as is.
---
---@param file_path string
---@param stack_level integer The level of the caller, `1` is the function calling `sandbox.path`.
---@return string file_path
---@nodiscard
function sandbox.path( file_path, stack_level )
    if string_byte( file_path, 1, 1 ) == 0x2F --[[ / ]] then
        return file_path
    end

    local owner = sandbox_owner( stack_level + 1 )
    if owner == nil then
        return file_path
    end

    return owner.root .. "/" .. file_path
end

--- [SHARED AND MENU]
---
--- Remembers the object, `release_fn` is called with it when the owner is released.
---
---@param owner dreamwork.sandbox.Owner
---@param object any The object or identifier, objects are not kept alive.
---@param release_fn fun( object: any )
function sandbox.claim( owner, object, release_fn )
    owner.objects[ object ] = release_fn
    object_owners[ object ] = owner
end

--- [SHARED AND MENU]
---
--- Forgets the claimed object, use it when the object is released before its owner.
---
---@param object any
function sandbox.unclaim( object )
    local owner = object_owners[ object ]
    if owner ~= nil then
        object_owners[ object ] = nil
        owner.objects[ object ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Remembers the attached handler if it belongs to an owner, `detach_fn` is called with the arguments when the owner is released.
---
--- The same attachment is remembered once.
---
---@param handler any The attached handler.
---@param detach_fn fun( target: any, a: any, b: any, c: any )
---@param target any The emitter, event or hook.
---@param a any
---@param b any
---@param c any
function sandbox.track( handler, detach_fn, target, a, b, c )
    local owner = sandbox_ownerOf( handler )
    if owner == nil then
        return
    end

    local handlers = owner.handlers

    local attachments = handlers[ handler ]
    if attachments == nil then
        handlers[ handler ] = { { detach_fn, target, a, b, c } }
        return
    end

    local count = #attachments

    for index = 1, count, 1 do
        local attachment = attachments[ index ]
        if attachment[ 1 ] == detach_fn and attachment[ 2 ] == target and attachment[ 3 ] == a and attachment[ 4 ] == b and attachment[ 5 ] == c then
            return
        end
    end

    attachments[ count + 1 ] = { detach_fn, target, a, b, c }
end

--- [SHARED AND MENU]
---
--- Detaches the handlers of the owner and releases its claimed objects.
---
---@param owner dreamwork.sandbox.Owner
function sandbox.release( owner )
    local handlers = owner.handlers

    local new_handlers = {}
    gc_setTableRules( new_handlers, true, false )
    owner.handlers = new_handlers

    for _, attachments in raw_pairs( handlers ) do
        for index = 1, #attachments, 1 do
            local attachment = attachments[ index ]
            exceptions_call( attachment[ 1 ], attachment[ 2 ], attachment[ 3 ], attachment[ 4 ], attachment[ 5 ] )
        end
    end

    local objects = owner.objects

    local new_objects = {}
    gc_setTableRules( new_objects, true, false )
    owner.objects = new_objects

    for object, release_fn in raw_pairs( objects ) do
        object_owners[ object ] = nil
        exceptions_call( release_fn, object )
    end
end
