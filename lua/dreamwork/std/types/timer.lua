local engine = dreamwork.engine
local engine_timer = engine.timer

local engine_timer_create = engine_timer.create
local engine_timer_remove = engine_timer.remove
local engine_timer_restart = engine_timer.restart

local engine_timer_stop = engine_timer.stop
local engine_timer_pause = engine_timer.pause
local engine_timer_resume = engine_timer.resume

local engine_timer_getState = engine_timer.getState
local engine_timer_getInterval = engine_timer.getInterval
local engine_timer_setInterval = engine_timer.setInterval

local engine_timer_setRepetitions = engine_timer.setRepetitions
local engine_timer_repetitionIndex = engine_timer.repetitionIndex
local engine_timer_repetitionsTotal = engine_timer.repetitionsTotal
local engine_timer_repetitionsLeft = engine_timer.repetitionsLeft

local engine_timer_getTimeLeft = engine_timer.getTimeLeft
local engine_timer_getStartTime = engine_timer.getStartTime
local engine_timer_timeTotal = engine_timer.timeTotal

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local string = std.string
local string_sub = string.sub
local string_format = string.format

local math = std.math
local math_max = math.max
local math_huge = math.huge

local class = std.class

local uuid = std.uuid
local uuid_unique = uuid.unique

local represent = std.represent
local tonumber = std.tonumber
local type = std.type

local Hook = std.Hook

---@type table<dreamwork.std.Timer, string>
local names = {}
gc_setTableRules( names, true, false )

--- Timer objects by their names, used by callbacks so they don't keep objects alive.
---
---@type table<string, dreamwork.std.Timer>
local objects = {}
gc_setTableRules( objects, false, true )

---@type table<dreamwork.std.Timer, dreamwork.std.Hook>
local hooks = {}

setmetatable( hooks, {
    __index = function( self, timer )
        local hook = Hook( represent( timer ) )
        self[ timer ] = hook
        return hook
    end,
    __mode = "k"
} )

---@alias dreamwork.std.Timer.state
---| `0` # Timer stopped.
---| `1` # Timer paused.
---| `2` # Timer running.

--- [SHARED AND MENU]
---
--- The timer object.
---
---@class dreamwork.std.Timer : dreamwork.std.Hook
---@field __class dreamwork.std.TimerClass
---@field name string The internal name of the timer. **Read-only.**
---@field state dreamwork.std.Timer.state The current state of the timer. **Read-only.**
---@field interval number The delay between repetitions of the timer in seconds.
---@field repetition_index integer The current repetition index of the timer. **Read-only.**
---@field repetitions_total integer The total amount of repetitions of the timer.
---@field repetitions_left integer The remaining amount of repetitions of the timer. **Read-only.**
---@field time_total number The total running time of the timer in seconds. **Read-only.**
---@field time_remaining number The remaining running time of the timer in seconds. **Read-only.**
---@field time_elapsed number The total elapsed time of the timer in seconds. **Read-only.**
---@field time_left number The remaining time until the next run of timer callbacks in seconds, or the interval if the timer is stopped. **Read-only.**
---@field start_time number The start time of the timer in seconds, `0` if the timer is stopped. **Read-only.**
local Timer = class.base( "Timer", true, nil )

do

    ---@param name string
    local function timer_call( name )
        local timer = objects[ name ]
        if timer ~= nil then
            hooks[ timer ]:call( timer )
        end
    end

    dreamwork.hideErrorFrame( timer_call )

    ---@param interval number | nil
    ---@param repetition_count integer | nil
    ---@param name string | nil
    ---@protected
    function Timer:__init( interval, repetition_count, name )
        if name == nil then
            name = uuid_unique()
        end

        names[ self ] = name
        objects[ name ] = self

        engine_timer_create( name, math_max( 0, interval or 0 ), math_max( 0, repetition_count or 1 ), function()
            return timer_call( name )
        end )
    end

end

---@protected
function Timer:__gc()
    local name = names[ self ]
    if name ~= nil then
        -- the name could be taken by a newer timer
        local timer = objects[ name ]
        if timer == nil or timer == self then
            engine_timer_remove( name )
        end
    end
end

---@protected
function Timer:__index( key )
    if key == "name" then
        return names[ self ]
    elseif key == "state" then
        return engine_timer_getState( names[ self ] )
    elseif key == "interval" then
        return engine_timer_getInterval( names[ self ] )
    elseif key == "start_time" then
        return engine_timer_getStartTime( names[ self ] ) or 0
    elseif key == "repetition_index" then
        return engine_timer_repetitionIndex( names[ self ] )
    elseif key == "repetitions_total" then
        return engine_timer_repetitionsTotal( names[ self ] )
    elseif key == "repetitions_left" then
        return engine_timer_repetitionsLeft( names[ self ] )
    elseif key == "time_total" then
        return engine_timer_timeTotal( names[ self ] )
    elseif key == "time_left" then
        local name = names[ self ]
        if engine_timer_getState( name ) == 0 then
            return engine_timer_getInterval( name )
        end

        return engine_timer_getTimeLeft( name )
    elseif key == "time_remaining" then
        local name = names[ self ]
        if engine_timer_getState( name ) == 0 then
            return engine_timer_timeTotal( name )
        elseif engine_timer_repetitionsTotal( name ) == 0 then
            return math_huge
        end

        return engine_timer_timeTotal( name ) - self.time_elapsed
    elseif key == "time_elapsed" then
        local name = names[ self ]
        if engine_timer_getState( name ) == 0 then
            return 0
        end

        local interval = engine_timer_getInterval( name )
        return engine_timer_repetitionIndex( name ) * interval + math_max( 0, interval - engine_timer_getTimeLeft( name ) )
    elseif string_sub( key, 1, 2 ) == "__" then
        error( "unknown key '" .. key .. "'", 2 )
    end

    return raw_get( Timer, key )
end

---@protected
function Timer:__newindex( key, value )
    if key == "interval" then
        engine_timer_setInterval( names[ self ], tonumber( value, 10 ) or 0 )
        return
    end

    if key == "repetitions_total" then
        engine_timer_setRepetitions( names[ self ], tonumber( value, 10 ) or 1 )
        return
    end

    error( "attempt to modify unknown timer property", 2 )
end

do

    ---@type table<integer, string>
    local status_to_string = {
        [ 0 ] = "stopped",
        [ 1 ] = "paused",
        [ 2 ] = "running"
    }

    ---@return string
    ---@nodiscard
    ---@protected
    function Timer:__represent()
        return string_format( "%s: %p [%s][%s]", type( self ), self, self.name, status_to_string[ engine_timer_getState( names[ self ] ) ] or "unknown" )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the timer object is stopped.
---
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
---@nodiscard
function Timer:isStopped()
    return engine_timer_getState( names[ self ] ) == 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer object is paused.
---
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
---@nodiscard
function Timer:isPaused()
    return engine_timer_getState( names[ self ] ) == 1
end

--- [SHARED AND MENU]
---
--- Checks if the timer object is running.
---
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
---@nodiscard
function Timer:isRunning()
    return engine_timer_getState( names[ self ] ) == 2
end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the given stage of the hook.
--- If the handler is already attached to that stage, only its priority is
--- updated (when a new one is supplied); it will not be attached twice.
---
--- If the hook is currently running, the change is deferred and applied once
--- the hook finishes running.
---
---@param handler fun( timer: dreamwork.std.Timer )
function Timer:attach( handler )
    hooks[ self ]:attach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Attaches a handler function to the hook that automatically detaches
--- itself right before being invoked, so it only ever runs once.
---
---@param handler fun( timer: dreamwork.std.Timer )
function Timer:once( handler )
    hooks[ self ]:once( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given stage of the hook.
--- If the hook is currently running, the handler is replaced with a no-op and
--- the actual removal is deferred until the hook finishes running.
---
---@param handler fun( timer: dreamwork.std.Timer )
function Timer:detach( handler )
    hooks[ self ]:detach( "peek", handler )
end

--- [SHARED AND MENU]
---
--- Cancels the hook if it is currently running, and removes every handler,
--- resetting their priority tables as well.
---
function Timer:clear()
    hooks[ self ]:clear()
end

--- [SHARED AND MENU]
---
--- Waits for the next call of the timer.
---
---@async
function Timer:await()
    return hooks[ self ]:await( "peek" )
end

--- [SHARED AND MENU]
---
--- Starts/restarts the timer object.
---
function Timer:start()
    engine_timer_restart( names[ self ] )
end

--- [SHARED AND MENU]
---
--- Stops the timer object.
---
function Timer:stop()
    engine_timer_stop( names[ self ] )
end

--- [SHARED AND MENU]
---
--- Pauses the timer object.
---
function Timer:pause()
    engine_timer_pause( names[ self ] )
end

--- [SHARED AND MENU]
---
--- Resumes/unpauses the timer object.
---
function Timer:resume()
    if engine_timer_getState( names[ self ] ) == 1 then
        engine_timer_resume( names[ self ] )
    end
end

--- [SHARED AND MENU]
---
--- The class used to create new `Timer` instances.
---
---@class dreamwork.std.TimerClass : dreamwork.std.Timer
---@field __base dreamwork.std.Timer
---@overload fun( interval: ( number | nil ), repetitions_total: ( integer | nil ), name: ( string | nil ) ): dreamwork.std.Timer
std.Timer = class.create( Timer )
