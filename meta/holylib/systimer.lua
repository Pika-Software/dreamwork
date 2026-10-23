---@meta holylib.systimer


--- [SHARED AND MENU]
---
--- This module is just the timer library, but it doesn't use `CurTime`.
---
---@class holylib.systimer
systimer = {}

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
function systimer.Adjust( identifier, delay, repetitions, func ) end

--- [SHARED AND MENU]
---
--- Creates a timer with the given name.
---
---@param identifier string Identifier of the timer to adjust.
---@param delay number The delay interval in seconds. **Must be specified.**
---@param repetitions integer Repetitions. Use 0 for infinite or nil to keep previous value.
---@param func fun() The new function. Use nil to keep previous value.
function systimer.Create( identifier, delay, repetitions, func ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer exists.
---
---@param identifier string Identifier of the timer.
---@return boolean exists Returns whether the timer exists or not.
function systimer.Exists( identifier ) end

--- [SHARED AND MENU]
---
--- Removes the given timer.
---
---@param identifier string Identifier of the timer.
function systimer.Remove( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully started again.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully started or not.
function systimer.Start( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully stopped.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully stopped or not.
function systimer.Stop( identifier ) end

--- [SHARED AND MENU]
---
--- Returns true if the given timer was successfully paused.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully paused or not.
function systimer.Pause( identifier ) end

--- [SHARED AND MENU]
---
--- Unpauses the given timer.
---
--- Unlike systimer.
---
--- Start this won't reset the time left until it executes again.
---
---@param identifier string Identifier of the timer.
---@return boolean success Returns whether the timer was successfully unpaused or not.
function systimer.UnPause( identifier ) end

--- [SHARED AND MENU]
---
--- Returns the time left until the given timer is executed again.
---
--- Returns `0` if the timer wasn't found.
---
---@param identifier string Identifier of the timer.
---@return number | 0 time_left Returns the time left until the timer is executed again.
function systimer.TimeLeft( identifier ) end

--- [SHARED AND MENU]
---
--- Returns the number of reps left for the given timer.
---
--- Returns `0` if the timer wasn't found or the reps are below `0`.
---
---@param identifier string Identifier of the timer.
---@return integer | 0 reps_left Returns the number of reps left for the given timer.
function systimer.RepsLeft( identifier ) end
