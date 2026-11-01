---@class dreamwork
local dreamwork = dreamwork
if dreamwork.detour ~= nil then
    return dreamwork.detour -- pls, do not reload this.
end

local std = dreamwork.std

local getfenv = std.getfenv

local gc = std.gc

local raw = std.raw
local raw_get = raw.get
local raw_set = raw.set

--- [SHARED AND MENU]
---
--- A library for intercepting engine functions and runtime patching using detour/hook.
---
--- Hooking an already hooked slot replaces the previous hook instead of stacking.
---
---@class dreamwork.detour
local detour = {}
dreamwork.detour = detour

--- Hooked function -> original (unhooked) function.
---
--- Always points to the root original, so re-hooking a hooked function replaces the previous hook instead of stacking.
---
--- Weak keys, entries are dropped along with unused hooked functions.
---
---@type table<function, function>
local functions = {}
gc.setTableRules( functions, true, false )

--- Hooked function -> table it was installed into.
---
---@type table<function, table>
local locations = {}
gc.setTableRules( locations, true, false )

--- Hooked function -> key it was installed under in its location.
---
---@type table<function, any>
local keys = {}
gc.setTableRules( keys, true, false )

--- [SHARED AND MENU]
---
--- Hooks `location[ key ]` with a function that calls the `new_fn` instead of the original and fallback to the original function if `new_fn` returns `nil`.
---
---@generic F: function
---@param new_fn F The new function to call instead of the original.
---@param location? table The table that holds the original function. Defaults to the environment of the calling function.
---@param key any The key of the original function in `location`.
---@return F hooked_fn Hooked function that was assigned to `location[ key ]`.
function detour.simple( new_fn, location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local in_fn = location[ key ]
    if in_fn == nil then
        raw_set( location, key, new_fn )
        return new_fn
    end

    local old_fn = functions[ in_fn ]
    if old_fn == nil then
        old_fn = in_fn
    end

    local function fn( ... )
        local a, b, c, d, e, f = new_fn( ... )
        if a == nil then
            return old_fn( ... )
        end

        return a, b, c, d, e, f
    end

    raw_set( location, key, fn )
    functions[ fn ] = old_fn
    locations[ fn ] = location
    keys[ fn ] = key
    return fn
end

--- [SHARED AND MENU]
---
--- Hooks `location[ key ]` with a function that calls the `new_fn` before calling the original, return result of `new_fn` will be ignored.
---
---@generic F: function
---@param new_fn F The new function to call before the original.
---@param location? table The table that holds the original function. Defaults to the environment of the calling function.
---@param key any The key of the original function in `location`.
---@return F hooked_fn Hooked function that was assigned to `location[ key ]`.
function detour.before( new_fn, location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local in_fn = location[ key ]
    if in_fn == nil then
        raw_set( location, key, new_fn )
        return new_fn
    end

    local old_fn = functions[ in_fn ]
    if old_fn == nil then
        old_fn = in_fn
    end

    local function fn( ... )
        new_fn( ... )
        return old_fn( ... )
    end

    raw_set( location, key, fn )
    functions[ fn ] = old_fn
    locations[ fn ] = location
    keys[ fn ] = key
    return fn
end

--- [SHARED AND MENU]
---
--- Replaces `location[ key ]` with the `new_fn`, the original function stays available via `detour.shadow` and `detour.detach`.
---
--- `new_fn` itself is registered as the hook, so don't reuse the same `new_fn` to replace multiple functions.
---
---@generic F: function
---@param new_fn F The new function to call instead of the original.
---@param location? table The table that holds the original function. Defaults to the environment of the calling function.
---@param key any The key of the original function in `location`.
---@return F hooked_fn The `new_fn` that was assigned to `location[ key ]`.
function detour.replace( new_fn, location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local in_fn = location[ key ]
    if in_fn ~= nil then
        local old_fn = functions[ in_fn ]
        if old_fn == nil then
            old_fn = in_fn
        end

        functions[ new_fn ] = old_fn
        locations[ new_fn ] = location
        keys[ new_fn ] = key
    end

    raw_set( location, key, new_fn )
    return new_fn
end

--- [SHARED AND MENU]
---
--- Hooks `location[ key ]` with a function that calls the `new_fn` with the original function as the first argument.
---
---@param new_fn ( fun( in_fn: function | nil, ...: any ): any, any, any, any, any, any ) The new function to call instead of the original.
---@param location? table The table that holds the original function. Defaults to the environment of the calling function.
---@param key any The key of the original function in `location`.
---@return function hooked_fn Hooked function that was assigned to `location[ key ]`.
function detour.attach( new_fn, location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local in_fn = location[ key ]

    local fn

    if in_fn == nil then
        function fn( ... )
            return new_fn( nil, ... )
        end
    else
        local old_fn = functions[ in_fn ]
        if old_fn == nil then
            old_fn = in_fn
        end

        function fn( ... )
            return new_fn( old_fn, ... )
        end

        functions[ fn ] = old_fn
        locations[ fn ] = location
        keys[ fn ] = key
    end

    raw_set( location, key, fn )
    return fn
end

--- [SHARED AND MENU]
---
--- Restores the original function in `location[ key ]` if it is hooked.
---
---@param location? table The table that holds the hooked function. Defaults to the environment of the calling function.
---@param key any The key of the hooked function in `location`.
---@return function | nil original The function that is now in `location[ key ]`.
---@return boolean success True if the hook was detached.
function detour.detach( location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local fn = location[ key ]

    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    end

    functions[ fn ] = nil
    locations[ fn ] = nil
    keys[ fn ] = nil

    raw_set( location, key, old_fn )
    return old_fn, true
end

--- [SHARED AND MENU]
---
--- Removes the hook and puts the original function back into the location it was hooked in.
---
--- The location is restored only if it still holds `fn`.
---
---@generic F: function
---@param fn F The hooked function.
---@return F original The original function, or `fn` if it is not hooked.
---@return boolean success True if the hook was removed.
function detour.unhook( fn )
    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    end

    functions[ fn ] = nil

    local location = locations[ fn ]
    locations[ fn ] = nil

    local key = keys[ fn ]
    keys[ fn ] = nil

    if location ~= nil and raw_get( location, key ) == fn then
        raw_set( location, key, old_fn )
    end

    return old_fn, true
end

--- [SHARED AND MENU]
---
--- Returns the unhooked function if value is hooked, else returns ``fn``.
---
---@generic F: function
---@param fn F Function to check. Can actually be any type though.
---@return F original Unhooked value or function.
---@return boolean success Was the value hooked?
function detour.shadow( fn )
    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    end

    return old_fn, true
end

return detour
