---@meta garrysmod.timer

--- [SHARED AND MENU]
---
--- The timer library is a very useful set of functions which allow you to run a function periodically or after a given delay.
---
---@class garrysmod.timer
timer = {}

--- [SHARED AND MENU]
---
--- Adjusts the timer with the given name with the new values.
---
--- Returns `true` if the timer was successfully adjusted.
---
---@param identifier string Identifier of the timer to adjust.
---@param delay number The delay interval in seconds. **Must be specified.**
---@param repetitions ( integer | nil ) Repetitions. Use 0 for infinite or nil to keep previous value.
---@param func ( fun() | nil ) The new function. Use nil to keep previous value.
---@return boolean success Returns whether the adjustment was successful or not.
function timer.Adjust( identifier, delay, repetitions, func ) end

--- [SHARED AND MENU]
---
--- Creates a timer with the given name.
---
---@param identifier string Identifier of the timer to adjust.
---@param delay number The delay interval in seconds. **Must be specified.**
---@param repetitions integer Repetitions. Use 0 for infinite or nil to keep previous value.
---@param func fun() The new function. Use nil to keep previous value.
function timer.Create( identifier, delay, repetitions, func ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer exists.
---
---@param identifier string Identifier of the timer.
---@return boolean exists Returns whether the timer exists or not.
function timer.Exists( identifier ) end

--- [SHARED AND MENU]
---
--- Removes the given timer.
---
---@param identifier string Identifier of the timer.
function timer.Remove( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully started again.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully started or not.
function timer.Start( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully stopped.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully stopped or not.
function timer.Stop( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully paused.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully paused or not.
function timer.Pause( identifier ) end

--- [SHARED AND MENU]
---
--- Unpauses the given timer.
---
--- Unlike timer.
---
--- Start this won't reset the time left until it executes again.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully unpaused or not.
function timer.UnPause( identifier ) end

--- [SHARED AND MENU]
---
--- Returns `true` if the given timer is paused.
---
---@param identifier string Identifier of the timer.
---@return boolean is_paused Returns whether the timer is paused or not.
function timer.IsPaused( identifier ) end

--- [SHARED AND MENU]
---
--- Returns the time left until the given timer is executed again.
---
--- Returns `0` if the timer wasn't found.
---
---@param identifier string Identifier of the timer.
---@return number | 0 time_left Returns the time left until the timer is executed again.
function timer.TimeLeft( identifier ) end

--- [SHARED AND MENU]
---
--- Returns the number of reps left for the given timer.
---
--- Returns `0` if the timer wasn't found or the reps are below `0`.
---
---@param identifier string Identifier of the timer.
---@return integer | 0 reps_left Returns the number of reps left for the given timer.
function timer.RepsLeft( identifier ) end

--- [SHARED AND MENU]
---
--- Creates a simple timer that runs the given function after a specified delay.
---
---@see timer.Create
---@see systimer.Create
---
---@param delay number How long until the function should be ran (in seconds). A value of 0 differs in behavior, depending on where you're calling this function.
---@param func fun() The function to run after the specified delay.
function timer.Simple( delay, func ) end
