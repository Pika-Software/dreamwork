local timer = _G.timer
if timer == nil then
    error( "timer library not found" )
end

---@class dreamwork.std
local std = _G.dreamwork.std

if std.Timer ~= nil then
    return
end

local string = std.string

local math = std.math
local math_max = math.max

local gc_setTableRules = std.debug.gc.setTableRules
local time_elapsed = std.time.elapsed
local table_eject = std.table.eject

local timer_RepsLeft = timer.RepsLeft
local timer_UnPause = timer.UnPause
local timer_Exists = timer.Exists
local timer_Create = timer.Create
local timer_Adjust = timer.Adjust

---@alias dreamwork.std.Timer.state
---| `0` # Timer stopped.
---| `1` # Timer paused.
---| `2` # Timer running.

--- [SHARED AND MENU]
---
--- The timer object.
---
---@class dreamwork.std.Timer : dreamwork.std.Object
---@field __class dreamwork.std.TimerClass
---@field name string The internal name of the timer. **Read-only.**
---@field state dreamwork.std.Timer.state The current state of the timer. **Read-only.**
---@field interval number The delay between repetitions of the timer in seconds.
---@field repetition_index integer The current repetition index of the timer. **Read-only.**
---@field repetitions_total integer The total amount of repetitions of the timer.
---@field repetitions_remaining integer The remaining amount of repetitions of the timer. **Read-only.**
---@field time_total number The total running time of the timer in seconds. **Read-only.**
---@field time_remaining number The remaining running time of the timer in seconds. **Read-only.**
---@field time_elapsed number The total elapsed time of the timer in seconds. **Read-only.**
---@field time_left number The remaining time until the next run of timer callbacks in seconds, or `nil` if the timer is stopped. **Read-only.**
---@field start_time number The start time of the timer in seconds. **Read-only.**
local Timer = std.class.base( "Timer", true )

--- [SHARED AND MENU]
---
--- The timer class.
---
---@class dreamwork.std.TimerClass : dreamwork.std.Timer
---@field __base dreamwork.std.Timer
---@overload fun( interval: number?, repetitions_total: integer?, name: string? ): dreamwork.std.Timer
local TimerClass = std.class.create( Timer )
std.Timer = TimerClass

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias Timer dreamwork.std.Timer

---@type table<dreamwork.std.Timer, string>
local names = {}

gc_setTableRules( names, true, false )

do

    local timer_Remove = timer.Remove

    ---@protected
    function Timer:__gc()
        local name = names[ self ]
        if name ~= nil and timer_Exists( name ) then
            timer_Remove( name )
        end
    end

end

---@type table<dreamwork.std.Timer, dreamwork.std.Timer.state>
local states = {}

gc_setTableRules( states, true, false )

do

    local status2string = {
        [ 0 ] = "stopped",
        [ 1 ] = "paused",
        [ 2 ] = "running"
    }

    ---@protected
    function Timer:__tostring()
        return string.format( "Timer: %p [%s][%s]", self, self.name, status2string[ self.state ] or "unknown" )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the timer object is stopped.
---
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
function Timer:isStopped()
    return self.state == 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer object is paused.
---
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
function Timer:isPaused()
    return self.state == 1
end

--- [SHARED AND MENU]
---
--- Checks if the timer object is running.
---
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
function Timer:isRunning()
    return self.state == 2
end

---@type table<dreamwork.std.Timer, boolean>
local in_call = {}

gc_setTableRules( in_call, true, false )

---@type table<dreamwork.std.Timer, table>
local callbacks = {}

gc_setTableRules( callbacks, true, false )

---@alias dreamwork.std.Timer.callback fun( timer: dreamwork.std.Timer )

---@class dreamwork.std.Timer.query_data
---@field [1] boolean `true` to attach, `false` to detach.
---@field [2] any The identifier of the callback.
---@field [3] nil | dreamwork.std.Timer.callback The callback function.
---@field [4] nil | boolean `true` to run once, `false` to run forever.

---@type table<dreamwork.std.Timer, dreamwork.std.Timer.query_data[]>
local queues = {}

gc_setTableRules( queues, true, false )

---@type table<dreamwork.std.Timer, number>
local intervals = {}

gc_setTableRules( intervals, true, false )

---@type table<dreamwork.std.Timer, integer>
local repetitions_total = {}

gc_setTableRules( repetitions_total, true, false )

---@type table<dreamwork.std.Timer, integer>
local repetition_indexes = {}

gc_setTableRules( repetition_indexes, true, false )

---@type table<dreamwork.std.Timer, number>
local start_times = {}

gc_setTableRules( start_times, true, false )

do

    local timer_TimeLeft = timer.TimeLeft
    local string_sub = string.sub
    local math_huge = math.huge
    local math_abs = math.abs
    local raw_get = std.raw.get

    ---@protected
    function Timer:__index( key )
        if key == "name" then
            return names[ self ] or "unknown"
        elseif key == "state" then
            local name = names[ self ]
            if name ~= nil and timer_Exists( name ) and ( timer_TimeLeft( name ) or 0 ) < 0 then
                return 1
            else
                return states[ self ] or 0
            end
        elseif key == "interval" then
            return intervals[ self ] or 0
        elseif key == "start_time" then
            return start_times[ self ] or 0
        elseif key == "repetition_index" then
            local repetitions = self.repetitions_total
            if repetitions == 0 then
                return repetition_indexes[ self ] or 0
            else
                return repetitions - self.repetitions_remaining
            end
        elseif key == "repetitions_total" then
            return repetitions_total[ self ] or 1
        elseif key == "repetitions_remaining" then
            local repetitions = self.repetitions_total
            local name = names[ self ]

            if name == nil or self.state == 0 then
                return repetitions
            elseif repetitions == 0 then
                return math_huge
            end

            local repetitions_left = timer_RepsLeft( name )
            if repetitions_left == nil then
                return 0
            elseif repetitions_left == -1 then
                return math_huge
            else
                return repetitions_left
            end
        elseif key == "time_total" then
            local repetitions = self.repetitions_total
            if repetitions == 0 then
                return math_huge
            else
                return self.interval * repetitions
            end
        elseif key == "time_left" then
            if self.state == 0 then
                return self.interval
            end

            local name = names[ self ]
            if name == nil or not timer_Exists( name ) then
                return self.interval
            end

            local time_left = timer_TimeLeft( name )
            if time_left == nil then
                return self.interval
            end

            return math_abs( time_left )
        elseif key == "time_remaining" then
            if self.state == 0 then
                return self.time_total
            elseif self.repetitions_total == 0 then
                return math_huge
            else
                return self.time_total - self.time_elapsed
            end
        elseif key == "time_elapsed" then
            local interval = self.interval
            return ( self.repetition_index * interval ) - ( self.time_left - interval )
        elseif string_sub( key, 1, 2 ) == "__" then
            error( "unknown key '" .. key .. "'", 2 )
        else
            return raw_get( Timer, key )
        end
    end

end

do

    local tonumber = std.tonumber

    ---@protected
    function Timer:__newindex( key, value )
        if key == "interval" then
            local interval = math_max( 0, tonumber( value, 10 ) or 0 )
            intervals[ self ] = interval

            local name = names[ self ]
            if name ~= nil and timer_Exists( name ) then
                timer_Adjust( name, interval )
            end
        elseif key == "repetitions_total" then
            local repetitions = math_max( 0, tonumber( value, 10 ) or 1 )
            repetitions_total[ self ] = repetitions

            if self.state == 0 then
                local name = names[ self ]
                if name ~= nil and timer_Exists( name ) then
                    timer_Adjust( name, self.interval, repetitions )
                end
            end
        else
            error( "attempt to modify unknown timer property", 2 )
        end
    end

end

local timer_call
do

    local pcall = std.pcall

    ---@param self dreamwork.std.Timer
    function timer_call( self )
        if self.repetitions_total == 0 then
            local repetition_index = self.repetition_index + 1
            repetition_indexes[ self ] = repetition_index

            if start_times[ self ] == nil and repetition_index == 1 then
                start_times[ self ] = time_elapsed() - self.interval
            end
        elseif start_times[ self ] == nil and self.repetition_index == 1 then
            start_times[ self ] = time_elapsed() - self.interval
        end

        in_call[ self ] = true

        local lst = callbacks[ self ]
        if lst ~= nil then
            for i = #lst - 1, 1, -3 do
                if in_call[ self ] then
                    local success, err_msg = pcall( lst[ i ], self )
                    if not success then
                        -- TODO: replace with cool new errors that we make later
                        print( "[dreamwork] timer callback error: " .. err_msg )
                        table_eject( lst, i - 1, i + 1 )
                    elseif lst[ i + 1 ] then
                        table_eject( lst, i - 1, i + 1 )
                    end
                else
                    break
                end
            end
        end

        in_call[ self ] = nil

        local queue = queues[ self ]
        if queue ~= nil then
            queues[ self ] = nil

            for i = 1, #queue, 1 do
                local tbl = queue[ i ]
                if tbl[ 1 ] then
                    self:attach( tbl[ 2 ], tbl[ 3 ], tbl[ 4 ] )
                else
                    self:detach( tbl[ 2 ] )
                end
            end
        end

        local name = names[ self ]
        if name ~= nil and timer_RepsLeft( name ) == 0 then
            self:stop()
        end
    end

end

do

    local math_floor = math.floor
    local uuid_v7 = std.uuid.v7

    ---@protected
    function Timer:__init( interval, repetition_count, name )
        if name == nil then
            names[ self ] = uuid_v7()
        else
            names[ self ] = name
        end

        if interval == nil then
            intervals[ self ] = 0
        else
            intervals[ self ] = math_max( 0, interval )
        end

        if repetition_count == nil then
            repetitions_total[ self ] = 1
        else
            repetitions_total[ self ] = math_max( 0, math_floor( repetition_count ) )
        end

        states[ self ] = 0
        callbacks[ self ] = {}
    end

end

--- [SHARED AND MENU]
---
--- Attaches a callback to the timer object.
---
---@param fn dreamwork.std.Timer.callback The callback function.
---@param identifier? any The identifier of the callback, default is `unnamed`.
---@param once? boolean `true` to run once, `false` to run forever, default is `false`.
function Timer:attach( fn, identifier, once )
    if identifier == nil then
        identifier = "nil"
    end

    if in_call[ self ] then
        local queue = queues[ self ]
        if queue == nil then
            queues[ self ] = {
                { true, identifier, fn, once == true }
            }
        else
            queue[ #queue + 1 ] = { true, identifier, fn, once == true }
        end

        return
    end

    local lst = callbacks[ self ]
    if lst == nil then
        return
    end

    local lst_length = #lst

    for i = 1, lst_length, 3 do
        if lst[ i ] == identifier then
            lst[ i + 1 ] = fn
            lst[ i + 2 ] = once == true
            return
        end
    end

    lst[ lst_length + 1 ] = identifier
    lst[ lst_length + 2 ] = fn
    lst[ lst_length + 3 ] = once == true
end

do

    local debug_fempty = std.debug.fempty

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback from the timer object.
    ---
    ---@param identifier any The identifier of the callback to detach.
    function Timer:detach( identifier )
        if identifier == nil then
            identifier = "nil"
        end

        local lst = callbacks[ self ]
        if lst == nil then
            return
        end

        for i = 1, #lst, 3 do
            if lst[ i ] == identifier then
                if in_call[ self ] then
                    lst[ i + 1 ] = debug_fempty

                    local queue = queues[ self ]
                    if queue == nil then
                        queues[ self ] = {
                            { false, identifier }
                        }
                    else
                        queue[ #queue + 1 ] = { false, identifier }
                    end
                else
                    table_eject( lst, i, i + 2 )
                end

                break
            end
        end
    end

end

--- [SHARED AND MENU]
---
--- Detaches all callbacks from the timer object.
---
function Timer:clear()
    callbacks[ self ] = {}
    in_call[ self ] = nil
end

do

    local timer_Start = timer.Start

    --- [SHARED AND MENU]
    ---
    --- Starts/restarts the timer object.
    ---
    function Timer:start()
        local name = names[ self ]
        if name ~= nil then
            if timer_Exists( name ) then
                timer_Adjust( name, self.interval, self.repetitions_total )
                timer_Start( name )
            else
                timer_Create( name, self.interval, self.repetitions_total, function()
                    return timer_call( self )
                end )
            end
        end

        states[ self ] = 2
    end

end

do

    local timer_Stop = timer.Stop

    --- [SHARED AND MENU]
    ---
    --- Stops the timer object.
    ---
    function Timer:stop()
        repetition_indexes[ self ] = nil
        start_times[ self ] = nil

        local name = names[ self ]
        if name ~= nil then
            if self.state == 1 then
                timer_UnPause( name )
            end

            timer_Stop( name )
        end

        states[ self ] = 0
    end

end

---@type table<dreamwork.std.Timer, number>
local pause_times = {}

gc_setTableRules( pause_times, true, false )

do

    local timer_Pause = timer.Pause

    --- [SHARED AND MENU]
    ---
    --- Pauses the timer object.
    ---
    function Timer:pause()
        if self.state ~= 2 then
            return
        end

        local name = names[ self ]
        if name == nil then
            return
        end

        pause_times[ self ] = time_elapsed()
        timer_Pause( name )
        states[ self ] = 1
    end

end

--- [SHARED AND MENU]
---
--- Resumes/unpauses the timer object.
---
function Timer:resume()
    if self.state ~= 1 then
        return
    end

    local name = names[ self ]
    if name == nil then
        return
    end

    timer_UnPause( name )
    states[ self ] = 2
end

do

    local timer_Simple = timer.Simple

    --- [SHARED AND MENU]
    ---
    --- Calls the `fn` function after `delay` seconds.
    ---
    ---@param fn function The callback function.
    ---@param delay? number The delay in seconds, default is `0`.
    function std.setTimeout( fn, delay )
        timer_Simple( delay or 0, fn )
    end

end
