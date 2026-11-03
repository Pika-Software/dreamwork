---@class dreamwork
local dreamwork = dreamwork
if dreamwork.detour ~= nil then
    return dreamwork.detour -- pls, do not reload this.
end

local std = dreamwork.std

local getfenv = std.getfenv

local debug = std.debug
local debug_fempty = debug.fempty

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
--- `debug.fempty` marks a hook that was installed into an empty slot, it is never called,
--- re-hooking such a slot installs the new hook into the empty slot again instead of stacking on the previous one.
---
--- Weak keys, entries are dropped along with unused hooked functions.
---
---@type table<function, function>
local originals = {}
gc.setTableRules( originals, true, false )

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
--- If the slot is empty, `new_fn` itself is installed as the hook, so don't reuse the same `new_fn` for multiple empty slots.
---
--- > NOTE: Re-hooking installs a new function into the slot, references to the previous hook cached elsewhere (e.g. `hook.Call` cached by the engine) keep calling the previous `new_fn`.
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

    local old_fn = originals[ in_fn ] or in_fn
    if old_fn == nil or old_fn == debug_fempty then
        originals[ new_fn ] = debug_fempty

        keys[ new_fn ] = key
        locations[ new_fn ] = location

        raw_set( location, key, new_fn )

        return new_fn
    end

    local function fn( ... )
        local a, b, c, d = new_fn( ... )
        if a == nil then
            return old_fn( ... )
        end

        return a, b, c, d
    end

    originals[ fn ] = old_fn

    keys[ fn ] = key
    locations[ fn ] = location

    raw_set( location, key, fn )

    return fn
end

--- [SHARED AND MENU]
---
--- Hooks `location[ key ]` with a function that calls the `new_fn` before calling the original, return result of `new_fn` will be ignored.
---
--- If the slot is empty, `new_fn` itself is installed as the hook, so its results are returned to the caller
--- and the same `new_fn` should not be reused for multiple empty slots.
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

    local old_fn = originals[ in_fn ] or in_fn
    if old_fn == nil or old_fn == debug_fempty then
        originals[ new_fn ] = debug_fempty

        keys[ new_fn ] = key
        locations[ new_fn ] = location

        raw_set( location, key, new_fn )

        return new_fn
    end

    local function fn( ... )
        new_fn( ... )
        return old_fn( ... )
    end

    originals[ fn ] = old_fn

    keys[ fn ] = key
    locations[ fn ] = location

    raw_set( location, key, fn )

    return fn
end

--- [SHARED AND MENU]
---
--- Replaces `location[ key ]` with the `new_fn`, the original function stays available via `detour.shadow` and `detour.unhook`.
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

    originals[ new_fn ] = originals[ in_fn ] or in_fn or debug_fempty

    keys[ new_fn ] = key
    locations[ new_fn ] = location

    raw_set( location, key, new_fn )

    return new_fn
end

--- [SHARED AND MENU]
---
--- Hooks `location[ key ]` with a function that calls the `new_fn` with the original function as the first argument.
---
---@param new_fn ( fun( in_fn: function | nil, ...: any ): any, any, any, any ) The new function to call instead of the original.
---@param location? table The table that holds the original function. Defaults to the environment of the calling function.
---@param key any The key of the original function in `location`.
---@return function hooked_fn Hooked function that was assigned to `location[ key ]`.
function detour.attach( new_fn, location, key )
    if location == nil then
        location = getfenv( 2 )
    end

    local in_fn = location[ key ]

    local old_fn = originals[ in_fn ] or in_fn

    local fn

    if old_fn == nil or old_fn == debug_fempty then
        old_fn = debug_fempty

        function fn( ... )
            return new_fn( nil, ... )
        end
    else
        function fn( ... )
            return new_fn( old_fn, ... )
        end
    end

    originals[ fn ] = old_fn

    keys[ fn ] = key
    locations[ fn ] = location

    raw_set( location, key, fn )

    return fn
end

--- [SHARED AND MENU]
---
--- Removes the hook and puts the original function back into the location it was hooked in.
---
--- The location is restored only if it still holds `fn`, `success` is `true` even if the location was not restored.
---
--- If the slot was empty before hooking, it is emptied again and `original` is `nil`.
---
--- > NOTE: References to `fn` cached elsewhere (e.g. `hook.Call` cached by the engine) keep calling the hook.
---
---@generic F: function
---@param fn F The hooked function.
---@return F | nil original The original function, `nil` if the slot was empty, or `fn` if it is not hooked.
---@return boolean success True if the hook was removed.
function detour.unhook( fn )
    ---@type function | nil
    local old_fn = originals[ fn ]
    if old_fn == nil then
        return fn, false
    end

    if old_fn == debug_fempty then
        old_fn = nil
    end

    originals[ fn ] = nil

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
--- Returns `nil` as the original of a hook that was installed into an empty slot.
---
---@generic F: function
---@param fn F Function to check. Can actually be any type though.
---@return F | nil original Unhooked value or function.
---@return boolean success Was the value hooked?
function detour.shadow( fn )
    local old_fn = originals[ fn ]
    if old_fn == nil then
        return fn, false
    end

    if old_fn == debug_fempty then
        return nil, true
    end

    return old_fn, true
end

return detour
