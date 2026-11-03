---@class dreamwork
local dreamwork = dreamwork
if dreamwork.exceptions ~= nil then return end

local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local std = dreamwork.std

local gc = std.gc

local raw = std.raw
local raw_select = raw.select
local raw_tostring = raw.tostring

local pcall = std.pcall


--- [SHARED AND MENU]
---
--- Core of the error pipeline: call stack capturing, hidden frames, `xpcall` handlers
--- and reporting errors to the `dreamwork.lua.error` engine hook.
---
--- User-facing functions (`toError`, `try`, `error`, `errorf`, `warn`, `assert`) live in `std`.
---
---@class dreamwork.exceptions
---@field Sentinel string Message handed back to the engine once dreamwork has displayed the error itself.
local exceptions = {
    Sentinel = "The original error message was caught by dreamwork, see above for details about the error."
}

dreamwork.exceptions = exceptions


--- Survives loader reloads together with this module, so functions hidden by persistent engine modules stay hidden.
---
--- Weak keys, reloaded modules register new functions and the old ones must not be kept alive.
---
---@type table<function, (true | nil)>
local hidden_functions = {}
gc.setTableRules( hidden_functions, true, false )

--- [SHARED AND MENU]
---
--- Hides the given functions from error call stacks.
---
--- Use it for internal dispatchers and wrappers (hook runners, timer callers, ...)
--- whose frames carry no useful information for whoever reads the error.
---
---@param ... function The functions to hide.
function exceptions.hide( ... )
    for i = 1, raw_select( "#", ... ), 1 do
        hidden_functions[ raw_select( i, ... ) ] = true
    end
end

--- [SHARED AND MENU]
---
--- Shows the given functions in error call stacks again, undoing `hide`.
---
---@param ... function The functions to show.
function exceptions.show( ... )
    for i = 1, raw_select( "#", ... ), 1 do
        hidden_functions[ raw_select( i, ... ) ] = nil
    end
end

--- [SHARED AND MENU]
---
--- Checks whether the frame belongs to a hidden function and is left out of error call stacks.
---
--- Pass it to `debug.Stack:filter` to clean up a stack captured by hand.
---
---@param frame dreamwork.std.debug.StackLevel | debuginfo The frame to check.
---@return boolean is_hidden
---@nodiscard
function exceptions.isHiddenFrame( frame )
    local fn = frame.func
    return not (fn == nil or hidden_functions[ fn ] == nil)
end

--- [SHARED AND MENU]
---
--- Checks whether the function is hidden from error call stacks.
---
--- Use it when there is only a function and no stack frame to check.
---
---@param fn function The function to check.
---@return boolean is_hidden
---@nodiscard
function exceptions.isHiddenFunction( fn )
    return hidden_functions[ fn ] ~= nil
end

--- [SHARED AND MENU]
---
--- Passes the error to the `dreamwork.lua.error` handlers, which display it.
---
---@param error_object dreamwork.std.Error The error to report.
---@return any result The value returned by the handlers.
function exceptions.report( error_object )
    return hook_call( "dreamwork.lua.error", error_object )
end

--- [SHARED AND MENU]
---
--- Converts the value into a string without ever raising an error.
---
--- Safe to use inside error handlers, where a second error would replace the original one.
---
---@param value any The value to convert.
---@return string str The string, or a placeholder if `tostring` failed.
---@nodiscard
function exceptions.tostring( value )
    local success, result = pcall( raw_tostring, value )
    return success and result or "<value that cannot be converted to string>"
end
