---@meta _

---@alias Timer.state
---| `0` # Timer stopped.
---| `1` # Timer paused.
---| `2` # Timer running.

--- [SHARED AND MENU]
---
--- The timer object.
---
---@class Timer : Object
---@field __class TimerClass
---@field name string The internal name of the timer. **Read-only.**
---@field state Timer.state The current state of the timer. **Read-only.**
---@field interval number The delay between repetitions of the timer in seconds.
---@field repetition_index integer The current repetition index of the timer. **Read-only.**
---@field repetitions_total integer The total amount of repetitions of the timer.
---@field repetitions_left integer The remaining amount of repetitions of the timer. **Read-only.**
---@field time_total number The total running time of the timer in seconds. **Read-only.**
---@field time_remaining number The remaining running time of the timer in seconds. **Read-only.**
---@field time_elapsed number The total elapsed time of the timer in seconds. **Read-only.**
---@field time_left number The remaining time until the next run of timer callbacks in seconds, or the interval if the timer is stopped. **Read-only.**
---@field start_time number The start time of the timer in seconds, `0` if the timer is stopped. **Read-only.**
local __Timer = {}

---@param interval number | nil
---@param repetition_count integer | nil
---@param name string | nil
---@protected
function __Timer:__init(interval, repetition_count, name) end

---@protected
function __Timer:__gc() end

---@protected
function __Timer:__index(key) end

---@protected
function __Timer:__newindex(key, value) end

---@return string
---@nodiscard
---@protected
function __Timer:__represent() end

--- [SHARED AND MENU]
---
--- Checks if the timer object is stopped.
---
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
---@nodiscard
function __Timer:isStopped() end

--- [SHARED AND MENU]
---
--- Checks if the timer object is paused.
---
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
---@nodiscard
function __Timer:isPaused() end

--- [SHARED AND MENU]
---
--- Checks if the timer object is running.
---
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
---@nodiscard
function __Timer:isRunning() end

--- [SHARED AND MENU]
---
--- Attaches a handler called on every run of the timer, attaching the same handler twice is a no-op.
---
--- Handlers run in protected mode, one failing handler is reported and never stops the others.
---
---@param handler fun( timer: Timer ) | Hook The callback or callable object.
function __Timer:attach(handler) end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler, detached right before the next run of the timer calls it.
---
---@param handler fun( timer: Timer ) | Hook The callback or callable object.
function __Timer:once(handler) end

--- [SHARED AND MENU]
---
--- Detaches a handler previously passed to `attach` or `once`.
---
---@param handler fun( timer: Timer ) | Hook The exact handler reference.
---@return boolean removed `true` if the handler was attached.
function __Timer:detach(handler) end

--- [SHARED AND MENU]
---
--- Removes every handler of the timer, pending handlers of a running call are skipped.
---
function __Timer:clear() end

--- [SHARED AND MENU]
---
--- Waits for the next run of the timer.
---
---@return Timer timer
---@async
function __Timer:await() end

--- [SHARED AND MENU]
---
--- Starts/restarts the timer object.
---
function __Timer:start() end

--- [SHARED AND MENU]
---
--- Stops the timer object.
---
function __Timer:stop() end

--- [SHARED AND MENU]
---
--- Pauses the timer object.
---
function __Timer:pause() end

--- [SHARED AND MENU]
---
--- Resumes/unpauses the timer object.
---
function __Timer:resume() end

--- [SHARED AND MENU]
---
--- The class used to create new `Timer` instances.
---
---@class TimerClass : Timer, Class
---@field __base Timer
---@overload fun( interval: ( number | nil ), repetitions_total: ( integer | nil ), name: ( string | nil ) ): Timer
Timer = {}
