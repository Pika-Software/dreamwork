---@class dreamwork
local dreamwork = dreamwork
if dreamwork.detour ~= nil then return end

-- https://github.com/unknown-gd/safety-lite/blob/main/src/detour.lua
local functions = {}

---@generic F: function
---@alias dreamwork.detour.Function fun( in_fn: F, ...: any ): any, any, any, any, any, any

--- [SHARED AND MENU]
---
--- A library for intercepting engine functions and runtime patching using detour/hook.
---
---@class dreamwork.detour
local detour = dreamwork.detour or {}
dreamwork.detour = detour

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` instead of the `old_fn`.
---
---@generic F: function
---@param in_fn F The original function.
---@param new_fn dreamwork.detour.Function<F> The new function to call instead of `old_fn`.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `old_fn`.
function detour.attach( in_fn, new_fn )
    local old_fn = functions[ in_fn ]
    if old_fn == nil then
        old_fn = in_fn
    end

    local function fn( ... )
        return new_fn( old_fn, ... )
    end

    functions[ fn ] = old_fn
    return fn
end

--- [SHARED AND MENU]
---
--- Returns the original function that the function given hooked.
---
---@generic F: function
---@param fn F The hooked function.
---@return F original The original function to overwrite with.
---@return boolean @True if the hook was detached.
function detour.detach( fn )
    local old_fn = functions[ fn ]
    if old_fn == nil then
        return fn, false
    else
        functions[ fn ] = nil
        return old_fn, true
    end
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
    else
        return old_fn, true
    end
end

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` instead of the `in_fn`.
---
---@generic F: function
---@param new_fn dreamwork.detour.Function<F> The new function to call instead of `in_fn`.
---@param in_fn? F The original function.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`.
function detour.fast( new_fn, in_fn )
    if in_fn == nil then
        return new_fn
    end

    return detour.attach( in_fn, function( fn, ... )
        local a, b, c, d, e, f = new_fn( ... )
        if a == nil then
            return fn( ... )
        end

        return a, b, c, d, e, f
    end )
end
