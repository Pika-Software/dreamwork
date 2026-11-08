---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine

local exceptions_call = dreamwork.exceptions.call
local dreamwork_getUpTime = dreamwork.getUpTime
local engine_hook = dreamwork_engine.hook

local std = dreamwork.std

do

    ---@type table<integer, fun()>
    local queue = {}

    ---@type table<integer, fun()>
    local spare_queue = {}

    ---@type integer
    local queue_size = 0

    --- [SHARED AND MENU]
    ---
    --- Functions run in the order they were queued, with no arguments, and their return values are ignored.
    ---
    --- Functions queued from inside a `nextTick` callback run on the following tick.
    ---
    ---@param fn fun() The function to call on the next tick.
    function dreamwork_engine.nextTick( fn )
        queue_size = queue_size + 1
        queue[ queue_size ] = fn
    end

    engine_hook.catch( "Tick", "modules.engine.timer.tick", function()
        local size = queue_size
        if size == 0 then return end

        local current = queue
        queue, spare_queue, queue_size = spare_queue, current, 0

        for i = 1, size, 1 do
            local fn = current[ i ]
            current[ i ] = nil

            exceptions_call( fn )
        end
    end, 1000 )

end
