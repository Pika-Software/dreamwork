---@meta _

---
--- Named timers ticked by garry's mod `timer` or the `Think` hook.
---
---@class engine.timer
local engine_timer = {}

--- [SHARED AND MENU]
---
--- Checks if the timer exists.
---
---@param name string The name of the timer.
---@return boolean exists Returns `true` if the timer exists, otherwise `false`.
---@nodiscard
function engine_timer.isExists(name) end

--- [SHARED AND MENU]
---
--- Returns the state of the timer.
---
---@param name string The name of the timer.
---@return Timer.state state The state of the timer, `0` if the timer does not exist.
---@nodiscard
function engine_timer.getState(name) end

--- [SHARED AND MENU]
---
--- Checks if the timer is running.
---
---@param name string The name of the timer.
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
---@nodiscard
function engine_timer.isRunning(name) end

--- [SHARED AND MENU]
---
--- Checks if the timer is stopped, non-existent timers are stopped too.
---
---@param name string The name of the timer.
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
---@nodiscard
function engine_timer.isStopped(name) end

--- [SHARED AND MENU]
---
--- Checks if the timer is paused.
---
---@param name string The name of the timer.
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
---@nodiscard
function engine_timer.isPaused(name) end

--- [SHARED AND MENU]
---
--- Checks if the timer repeats endlessly.
---
---@param name string The name of the timer.
---@return boolean is_endless Returns `true` if the timer is endless, otherwise `false`.
---@nodiscard
function engine_timer.isEndless(name) end

--- [SHARED AND MENU]
---
--- Returns the delay between repetitions of the timer.
---
---@param name string The name of the timer.
---@return number interval The interval in seconds, `0` if the timer does not exist.
---@nodiscard
function engine_timer.getInterval(name) end

--- [SHARED AND MENU]
---
--- Sets the delay between repetitions of the timer.
---
--- A running or paused timer finishes the current repetition with the old interval.
---
---@param name string The name of the timer.
---@param interval number The interval in seconds.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setInterval(name, interval) end

--- [SHARED AND MENU]
---
--- Returns the total amount of repetitions of the timer.
---
---@param name string The name of the timer.
---@return integer repetitions_total The total amount of repetitions, `0` if the timer is endless or does not exist.
---@nodiscard
function engine_timer.repetitionsTotal(name) end

--- [SHARED AND MENU]
---
--- Sets the total amount of repetitions of the timer.
---
--- If a running or paused timer has already reached the new amount, it gets stopped.
---
---@param name string The name of the timer.
---@param repetitions_total integer The total amount of repetitions, `0` for endless.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setRepetitions(name, repetitions_total) end

--- [SHARED AND MENU]
---
--- Returns the amount of repetitions the timer has made since it was started.
---
---@param name string The name of the timer.
---@return integer repetition_index The amount of made repetitions, `0` if the timer is stopped.
---@nodiscard
function engine_timer.repetitionIndex(name) end

--- [SHARED AND MENU]
---
--- Returns the remaining amount of repetitions of the timer.
---
---@param name string The name of the timer.
---@return integer | number repetitions_left The remaining amount of repetitions, `math.huge` if the timer is endless, `0` if the timer does not exist.
---@nodiscard
function engine_timer.repetitionsLeft(name) end

--- [SHARED AND MENU]
---
--- Returns the time left until the next call of the timer.
---
---@param name string The name of the timer.
---@return number time_left The time left in seconds, `math.huge` if the timer is stopped or does not exist.
---@nodiscard
function engine_timer.getTimeLeft(name) end

--- [SHARED AND MENU]
---
--- Returns the total running time of the timer.
---
---@param name string The name of the timer.
---@return number time_total The total time in seconds, `math.huge` if the timer is endless, `0` if the timer does not exist.
---@nodiscard
function engine_timer.timeTotal(name) end

--- [SHARED AND MENU]
---
--- Returns the uptime at which the timer was started.
---
---@param name string The name of the timer.
---@return number | nil start_time The start time in seconds, or `nil` if the timer is stopped.
---@nodiscard
function engine_timer.getStartTime(name) end

--- [SHARED AND MENU]
---
--- Sets the function called by the timer.
---
---@param name string The name of the timer.
---@param fn fun() | Hook The function to call.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setFunction(name, fn) end

--- [SHARED AND MENU]
---
--- Creates a stopped timer or stops and reconfigures an existing one.
---
--- Omitted arguments keep the previous values of an existing timer.
---
---@param name string The name of the timer.
---@param interval number | nil The delay between repetitions in seconds, defaults to `1`.
---@param repetitions_total integer | nil The total amount of repetitions, `0` for endless, defaults to `1`.
---@param fn fun() | Hook | nil The function to call, defaults to an empty function.
---@return boolean success Always `true`.
function engine_timer.create(name, interval, repetitions_total, fn) end

--- [SHARED AND MENU]
---
--- Removes the timer.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer existed, otherwise `false`.
function engine_timer.remove(name) end

--- [SHARED AND MENU]
---
--- Starts the timer from the beginning, even if it is running or paused.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.restart(name) end

--- [SHARED AND MENU]
---
--- Starts the timer from the beginning, does nothing if it is already running.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.start(name) end

--- [SHARED AND MENU]
---
--- Stops the timer and resets its progress.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.stop(name) end

--- [SHARED AND MENU]
---
--- Pauses the running timer, keeping the time left until the next call.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer is paused, otherwise `false`.
function engine_timer.pause(name) end

--- [SHARED AND MENU]
---
--- Resumes the paused timer, or starts the stopped one.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer is running, otherwise `false`.
function engine_timer.resume(name) end

--- [SHARED AND MENU]
---
--- Calls the function once after the delay.
---
---@param delay number The delay in seconds.
---@param fn fun() The function to call.
function engine_timer.simple(delay, fn) end
