---@meta _

--- [SHARED AND MENU]
---
--- coroutine library
---
--- Coroutines are similar to threads, however they do not run simultaneously.
---
--- They offer a way to split up tasks and dynamically pause & resume functions.
---
---@class coroutinelib
coroutine = {}

---@type fun(): running: thread | nil
coroutine.running = nil

--- [SHARED AND MENU]
---
--- Returns `true` when the running coroutine can yield.
---
--- [View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-coroutine.isyieldable"])
---
---@return boolean is_yieldable
---@nodiscard
function coroutine.isyieldable() end
