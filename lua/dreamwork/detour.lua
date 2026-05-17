---@class dreamwork
local dreamwork = dreamwork
if dreamwork.detour ~= nil then return end

-- ref: https://github.com/unknown-gd/safety-lite/blob/main/src/detour.lua
local functions = {}

--- [SHARED AND MENU]
---
--- A library for intercepting engine functions and runtime patching using detour/hook.
---
---@class dreamwork.detour
local detour = dreamwork.detour or {}
dreamwork.detour = detour

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` instead of the `in_fn` and fallback to the original function if `new_fn` returns `nil`.
---
---@generic F: function
---@param new_fn F The new function to call instead of `in_fn`.
---@param in_fn? F The original function.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`.
function detour.simple( new_fn, in_fn )
    if in_fn == nil then
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
        else
            return a, b, c, d, e, f
        end
    end

    functions[ fn ] = old_fn
    return fn
end

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` before calling `in_fn`, return result of `new_fn` will be ignored.
---
---@generic F: function
---@param new_fn F The new function to call instead of `in_fn`.
---@param in_fn? F The original function.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`, return result of `new_fn` will be ignored.
function detour.before( new_fn, in_fn )
    if in_fn == nil then
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

    functions[ fn ] = old_fn
    return fn
end

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` after calling `in_fn`, return result of `in_fn` will be ignored.
---
---@generic F: function
---@param new_fn fun( results: any[], ... ): any, any, any, any, any, any The new function to call instead of `in_fn`.
---@param in_fn? F The original function.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`, return result of `in_fn` will be ignored.
function detour.after( new_fn, in_fn )
    if in_fn == nil then
        return new_fn
    end

    local old_fn = functions[ in_fn ]
    if old_fn == nil then
        old_fn = in_fn
    end

    local function fn( ... )
        local a, b, c, d, e, f = old_fn( ... )
        new_fn( { a, b, c, d, e, f }, ... )
        return a, b, c, d, e, f
    end

    functions[ fn ] = old_fn
    return fn
end

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` instead of the `in_fn`.
---
---@generic F: function
---@param in_fn F The original function.
---@param new_fn F The new function to call instead of `in_fn`.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`.
function detour.replace( new_fn, in_fn )
    if in_fn == nil then
        return new_fn
    end

    local old_fn = functions[ in_fn ]
    if old_fn == nil then
        old_fn = in_fn
    end

    functions[ new_fn ] = old_fn
    return new_fn
end

--- [SHARED AND MENU]
---
--- Returns a function that calls the `new_fn` instead of the `in_fn`.
---
---@generic F: function
---@param new_fn ( fun( in_fn: (F | nil), ...: any ): any, any, any, any, any, any ) The new function to call instead of `in_fn`.
---@param in_fn F | nil The original function.
---@return F hooked_fn Hooked function that calls `new_fn` instead of `in_fn`.
function detour.attach( new_fn, in_fn )
    if in_fn == nil then
        return function( ... )
            return new_fn( nil, ... )
        end
    end

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
