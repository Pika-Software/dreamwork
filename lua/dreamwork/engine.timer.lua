if dreamwork.engine.timer ~= nil then return end

local dreamwork_errorHandler = dreamwork.errorHandler
local dreamwork_getUpTime = dreamwork.getUpTime

---@class dreamwork.engine
local engine = dreamwork.engine
local std = dreamwork.std

local xpcall = std.xpcall

local debug = std.debug
local debug_fempty = debug.fempty

local bit = std.bit
local bit_rshift = bit.rshift

local math = std.math
local math_max = math.max
local math_huge = math.huge


---
--- Named timers ticked by garry's mod `timer` or the `Think` hook.
---
---@class dreamwork.std.engine.timer
local engine_timer = {}
engine.timer = engine_timer

---@type table<string, number>
local intervals = {}

--- `0` means endless.
---
---@type table<string, integer>
local repetitions = {}

---@type table<string, ( fun() | dreamwork.std.Hook )>
local handlers = {}

---@type table<( fun() | dreamwork.std.Hook ), boolean>
local handlerIsType = {}

---@type table<string, dreamwork.std.Timer.state>
local states = {}

---@type table<string, integer>
local repetition_indexes = {}

---@type table<string, number>
local start_times = {}

---@type table<string, number>
local paused_time_lefts = {}

-- Running timers are kept in a binary min-heap ordered by deadline,
-- so a tick only has to look at the top.

--- Names of scheduled timers.
---
---@type string[]
local heap_names = {}

--- The amount of scheduled timers.
local heap_size = 0

--- The amount of created fallback simple timers.
local simple_count = 0

--- Uptime of the next call, `heap_deadlines[ i ]` belongs to `heap_names[ i ]`.
---
---@type number[]
local heap_deadlines = {}

--- Heap positions of scheduled timers, `nil` if the timer is stopped, paused or in its last call.
---
---@type table<string, integer>
local heap_positions = {}

---@param index integer
---@param name string
---@param deadline number
local function heap_place( index, name, deadline )
    heap_names[ index ] = name
    heap_deadlines[ index ] = deadline
    heap_positions[ name ] = index
end

---@param index integer
---@param name string
---@param deadline number
local function heap_siftUp( index, name, deadline )
    while index > 1 do
        local parent = bit_rshift( index, 1 )

        local parent_deadline = heap_deadlines[ parent ]
        if parent_deadline <= deadline then
            break
        end

        heap_place( index, heap_names[ parent ], parent_deadline )
        index = parent
    end

    heap_place( index, name, deadline )
end

---@param index integer
---@param name string
---@param deadline number
local function heap_siftDown( index, name, deadline )
    while true do
        local child = index * 2
        if child > heap_size then
            break
        end

        local child_deadline = heap_deadlines[ child ]

        if child < heap_size then
            local right_deadline = heap_deadlines[ child + 1 ]
            if right_deadline < child_deadline then
                child = child + 1
                child_deadline = right_deadline
            end
        end

        if deadline <= child_deadline then
            break
        end

        heap_place( index, heap_names[ child ], child_deadline )
        index = child
    end

    heap_place( index, name, deadline )
end

---@param name string
---@param deadline number
local function heap_set( name, deadline )
    local index = heap_positions[ name ]
    if index == nil then
        heap_size = heap_size + 1
        heap_siftUp( heap_size, name, deadline )
    elseif deadline < heap_deadlines[ index ] then
        heap_siftUp( index, name, deadline )
    else
        heap_siftDown( index, name, deadline )
    end
end

---@param name string
local function unschedule( name )
    local index = heap_positions[ name ]
    if index == nil then
        return
    end

    heap_positions[ name ] = nil

    local size = heap_size
    local last_name, last_deadline = heap_names[ size ], heap_deadlines[ size ]

    heap_names[ size ] = nil
    heap_deadlines[ size ] = nil

    heap_size = size - 1

    -- fill the hole with the last entry
    if index ~= size then
        if last_deadline < heap_deadlines[ index ] then
            heap_siftUp( index, last_name, last_deadline )
        else
            heap_siftDown( index, last_name, last_deadline )
        end
    end
end

---@param name string
---@param delay number
local function schedule( name, delay )
    heap_set( name, dreamwork_getUpTime() + delay )
end

do

    ---@param name string
    ---@param deadline number
    ---@param now number
    local function timer_call( name, deadline, now )
        local repetition_index = repetition_indexes[ name ] + 1
        repetition_indexes[ name ] = repetition_index

        local repetitions_total = repetitions[ name ]
        local is_last = repetitions_total ~= 0 and repetition_index >= repetitions_total

        if is_last then
            unschedule( name )
        else
            local interval = intervals[ name ]

            deadline = deadline + interval
            if deadline <= now then
                -- too far behind, skip missed calls
                deadline = now + interval
            end

            heap_set( name, deadline )
        end

        local handler = handlers[ name ]
        if handlerIsType[ handler ] then
            ---@cast handler dreamwork.std.Hook
            xpcall( handler.call, dreamwork_errorHandler, handler )
        else
            ---@cast handler fun()
            xpcall( handler, dreamwork_errorHandler )
        end

        -- the callback can restart, stop or remove the timer
        if is_last and states[ name ] == 2 and heap_positions[ name ] == nil then
            states[ name ] = 0
            repetition_indexes[ name ] = 0
            start_times[ name ] = nil
        end
    end

    dreamwork.hideErrorFrame( timer_call )

    local function tick()
        if heap_size == 0 then return end

        local now = dreamwork_getUpTime()

        -- every call moves the top to `now` or later, or removes it,
        -- so timers rescheduled for this tick wait for the next one
        while heap_size ~= 0 and heap_deadlines[ 1 ] < now do
            timer_call( heap_names[ 1 ], heap_deadlines[ 1 ], now )
        end
    end

    local timer_api = systimer or timer
    if timer_api == nil then
        engine.hookCatch( "Think", "dreamwork.engine.timer", tick )
    else
        timer_api.Create( "dreamwork.engine.timer", 0, 0, tick )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the timer exists.
---
---@param name string The name of the timer.
---@return boolean exists Returns `true` if the timer exists, otherwise `false`.
---@nodiscard
function engine_timer.isExists( name )
    return states[ name ] ~= nil
end

--- [SHARED AND MENU]
---
--- Returns the state of the timer.
---
---@param name string The name of the timer.
---@return dreamwork.std.Timer.state state The state of the timer, `0` if the timer does not exist.
---@nodiscard
function engine_timer.getState( name )
    return states[ name ] or 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer is running.
---
---@param name string The name of the timer.
---@return boolean is_running Returns `true` if the timer is running, otherwise `false`.
---@nodiscard
function engine_timer.isRunning( name )
    return states[ name ] == 2
end

--- [SHARED AND MENU]
---
--- Checks if the timer is stopped, non-existent timers are stopped too.
---
---@param name string The name of the timer.
---@return boolean is_stopped Returns `true` if the timer is stopped, otherwise `false`.
---@nodiscard
function engine_timer.isStopped( name )
    local state = states[ name ]
    return state == nil or state == 0
end

--- [SHARED AND MENU]
---
--- Checks if the timer is paused.
---
---@param name string The name of the timer.
---@return boolean is_paused Returns `true` if the timer is paused, otherwise `false`.
---@nodiscard
function engine_timer.isPaused( name )
    return states[ name ] == 1
end

--- [SHARED AND MENU]
---
--- Checks if the timer repeats endlessly.
---
---@param name string The name of the timer.
---@return boolean is_endless Returns `true` if the timer is endless, otherwise `false`.
---@nodiscard
function engine_timer.isEndless( name )
    return repetitions[ name ] == 0
end

--- [SHARED AND MENU]
---
--- Returns the delay between repetitions of the timer.
---
---@param name string The name of the timer.
---@return number interval The interval in seconds, `0` if the timer does not exist.
---@nodiscard
function engine_timer.getInterval( name )
    return intervals[ name ] or 0
end

--- [SHARED AND MENU]
---
--- Sets the delay between repetitions of the timer.
---
--- A running or paused timer finishes the current repetition with the old interval.
---
---@param name string The name of the timer.
---@param interval number The interval in seconds.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setInterval( name, interval )
    if states[ name ] == nil then
        return false
    end

    intervals[ name ] = math_max( 0, interval )
    return true
end

--- [SHARED AND MENU]
---
--- Returns the total amount of repetitions of the timer.
---
---@param name string The name of the timer.
---@return integer repetitions_total The total amount of repetitions, `0` if the timer is endless or does not exist.
---@nodiscard
function engine_timer.repetitionsTotal( name )
    return repetitions[ name ] or 0
end

--- [SHARED AND MENU]
---
--- Sets the total amount of repetitions of the timer.
---
--- If a running or paused timer has already reached the new amount, it gets stopped.
---
---@param name string The name of the timer.
---@param repetitions_total integer The total amount of repetitions, `0` for endless.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setRepetitions( name, repetitions_total )
    if states[ name ] == nil then
        return false
    end

    repetitions_total = math_max( 0, repetitions_total )
    repetitions[ name ] = repetitions_total

    if repetitions_total ~= 0 and states[ name ] ~= 0 and repetition_indexes[ name ] >= repetitions_total then
        engine_timer.stop( name )
    end

    return true
end

--- [SHARED AND MENU]
---
--- Returns the amount of repetitions the timer has made since it was started.
---
---@param name string The name of the timer.
---@return integer repetition_index The amount of made repetitions, `0` if the timer is stopped.
---@nodiscard
function engine_timer.repetitionIndex( name )
    return repetition_indexes[ name ] or 0
end

--- [SHARED AND MENU]
---
--- Returns the remaining amount of repetitions of the timer.
---
---@param name string The name of the timer.
---@return integer | number repetitions_left The remaining amount of repetitions, `math.huge` if the timer is endless, `0` if the timer does not exist.
---@nodiscard
function engine_timer.repetitionsLeft( name )
    local repetitions_total = repetitions[ name ]
    if repetitions_total == nil then
        return 0
    elseif repetitions_total == 0 then
        return math_huge
    end

    return math_max( 0, repetitions_total - repetition_indexes[ name ] )
end

--- [SHARED AND MENU]
---
--- Returns the time left until the next call of the timer.
---
---@param name string The name of the timer.
---@return number time_left The time left in seconds, `math.huge` if the timer is stopped or does not exist.
---@nodiscard
function engine_timer.getTimeLeft( name )
    local state = states[ name ]
    if state == 1 then
        return paused_time_lefts[ name ]
    elseif state ~= 2 then
        return math_huge
    end

    local index = heap_positions[ name ]
    if index == nil then
        -- the last call is in progress
        return 0
    end

    return math_max( 0, heap_deadlines[ index ] - dreamwork_getUpTime() )
end

--- [SHARED AND MENU]
---
--- Returns the total running time of the timer.
---
---@param name string The name of the timer.
---@return number time_total The total time in seconds, `math.huge` if the timer is endless, `0` if the timer does not exist.
---@nodiscard
function engine_timer.timeTotal( name )
    local repetitions_total = repetitions[ name ]
    if repetitions_total == nil then
        return 0
    elseif repetitions_total == 0 then
        return math_huge
    end

    return intervals[ name ] * repetitions_total
end

--- [SHARED AND MENU]
---
--- Returns the uptime at which the timer was started.
---
---@param name string The name of the timer.
---@return number | nil start_time The start time in seconds, or `nil` if the timer is stopped.
---@nodiscard
function engine_timer.getStartTime( name )
    return start_times[ name ]
end

--- [SHARED AND MENU]
---
--- Sets the function called by the timer.
---
---@param name string The name of the timer.
---@param fn fun() | dreamwork.std.Hook The function to call.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.setFunction( name, fn )
    if states[ name ] == nil then
        return false
    end

    handlers[ name ] = fn
    return true
end

--- [SHARED AND MENU]
---
--- Creates a stopped timer or stops and reconfigures an existing one.
---
--- Omitted arguments keep the previous values of an existing timer.
---
---@param name string The name of the timer.
---@param interval number | nil The delay between repetitions in seconds, defaults to `1`.
---@param repetitions_total integer | nil The total amount of repetitions, `0` for endless, defaults to `1`.
---@param fn fun() | dreamwork.std.Hook | nil The function to call, defaults to an empty function.
---@return boolean success Always `true`.
function engine_timer.create( name, interval, repetitions_total, fn )
    unschedule( name )

    states[ name ] = 0
    repetition_indexes[ name ] = 0
    paused_time_lefts[ name ] = nil
    start_times[ name ] = nil

    if interval ~= nil then
        intervals[ name ] = math_max( 0, interval )
    elseif intervals[ name ] == nil then
        intervals[ name ] = 1
    end

    if repetitions_total ~= nil then
        repetitions[ name ] = math_max( 0, repetitions_total )
    elseif repetitions[ name ] == nil then
        repetitions[ name ] = 1
    end

    if fn ~= nil then
        handlers[ name ] = fn
    elseif handlers[ name ] == nil then
        handlers[ name ] = debug_fempty
    end

    return true
end

--- [SHARED AND MENU]
---
--- Removes the timer.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer existed, otherwise `false`.
function engine_timer.remove( name )
    if states[ name ] == nil then
        return false
    end

    states[ name ] = nil
    intervals[ name ] = nil
    handlers[ name ] = nil
    repetitions[ name ] = nil
    start_times[ name ] = nil
    unschedule( name )
    paused_time_lefts[ name ] = nil
    repetition_indexes[ name ] = nil

    return true
end

--- [SHARED AND MENU]
---
--- Starts the timer from the beginning, even if it is running or paused.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
local function restart( name )
    if states[ name ] == nil then
        return false
    end

    states[ name ] = 2
    repetition_indexes[ name ] = 0
    paused_time_lefts[ name ] = nil
    start_times[ name ] = dreamwork_getUpTime()

    schedule( name, intervals[ name ] )
    return true
end

engine_timer.restart = restart

--- [SHARED AND MENU]
---
--- Starts the timer from the beginning, does nothing if it is already running.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.start( name )
    local state = states[ name ]
    if state == nil then
        return false
    elseif state == 2 then
        return true
    end

    return restart( name )
end

--- [SHARED AND MENU]
---
--- Stops the timer and resets its progress.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer exists, otherwise `false`.
function engine_timer.stop( name )
    if states[ name ] == nil then
        return false
    end

    unschedule( name )

    states[ name ] = 0
    repetition_indexes[ name ] = 0
    paused_time_lefts[ name ] = nil
    start_times[ name ] = nil

    return true
end

--- [SHARED AND MENU]
---
--- Pauses the running timer, keeping the time left until the next call.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer is paused, otherwise `false`.
function engine_timer.pause( name )
    local state = states[ name ]
    if state == 1 then
        return true
    elseif state ~= 2 then
        return false
    end

    local index = heap_positions[ name ]
    if index == nil then
        -- the last call is in progress
        return false
    end

    paused_time_lefts[ name ] = math_max( 0, heap_deadlines[ index ] - dreamwork_getUpTime() )
    unschedule( name )

    states[ name ] = 1
    return true
end

--- [SHARED AND MENU]
---
--- Resumes the paused timer, or starts the stopped one.
---
---@param name string The name of the timer.
---@return boolean success Returns `true` if the timer is running, otherwise `false`.
function engine_timer.resume( name )
    local state = states[ name ]
    if state == nil then
        return false
    elseif state == 2 then
        return true
    elseif state == 0 then
        return engine_timer.restart( name )
    end

    local time_left = paused_time_lefts[ name ]
    paused_time_lefts[ name ] = nil

    states[ name ] = 2
    schedule( name, time_left )
    return true
end

-- `systimer.Simple` is not used, it has the same heap corruption as `systimer.Create`
-- when called from a `systimer` callback, and every timer here runs inside one
local timer_Simple = timer ~= nil and timer.Simple or nil

if timer_Simple == nil then

    --- [SHARED AND MENU]
    ---
    --- Calls the function once after the delay.
    ---
    ---@param delay number The delay in seconds.
    ---@param fn fun() The function to call.
    function engine_timer.simple( delay, fn )
        simple_count = simple_count + 1

        local name = "dreamwork.engine.timer.simple." .. simple_count

        engine_timer.create( name, delay, 1, function()
            engine_timer.remove( name )
            return fn()
        end )

        restart( name )
    end

else

    --- [SHARED AND MENU]
    ---
    --- Calls the function once after the delay.
    ---
    ---@param delay number The delay in seconds.
    ---@param fn fun() The function to call.
    function engine_timer.simple( delay, fn )
        timer_Simple( delay, fn )
    end

end
