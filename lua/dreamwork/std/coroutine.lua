local glua_coroutine = coroutine

local coroutine_yield = coroutine.yield
local coroutine_status = coroutine.status
local coroutine_running = coroutine.running

---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- coroutine library
---
--- Coroutines are similar to threads, however they do not run simultaneously.
---
--- They offer a way to split up tasks and dynamically pause & resume functions.
---
---@class dreamwork.std.coroutine
local coroutine = {
    create = glua_coroutine.create,
    resume = glua_coroutine.resume,

    ---@type fun(): running: thread | nil
    running = coroutine_running,

    status = coroutine_status,
    wrap = glua_coroutine.wrap,
    yield = coroutine_yield,
    ---@diagnostic disable-next-line: deprecated
    isyieldable = glua_coroutine.isyieldable,
}

std.coroutine = coroutine

---@diagnostic disable-next-line: deprecated
if glua_coroutine.isyieldable == nil then

    --- [SHARED AND MENU]
    ---
    --- Returns `true` when the running coroutine can yield.
    ---
    --- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-coroutine.isyieldable"])
    ---
    ---@return boolean is_yieldable
    ---@nodiscard
    ---@diagnostic disable-next-line: duplicate-set-field
    function coroutine.isyieldable()
        local co = coroutine_running()
        return co ~= nil and coroutine_status( co ) == "running"
    end

end

local time_elapsed = std.time.elapsed

--- [SHARED AND MENU]
---
--- Repeatedly yields the coroutine for the given duration before continuing.
---
---@param seconds number
---@async
function coroutine.wait( seconds )
    local end_time = time_elapsed() + seconds
    ::coroutine_wait::

    if end_time >= time_elapsed() then
        coroutine_yield()
        goto coroutine_wait
    end
end
