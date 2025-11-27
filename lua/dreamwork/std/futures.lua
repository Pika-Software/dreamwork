--- Python-like futures, made by Retro

---@class dreamwork.std
local std = dreamwork.std

local gc_setTableRules = std.gc.setTableRules
local pcall, xpcall = std.pcall, std.xpcall
local isFunction = std.isFunction
local tostring = std.tostring

local coroutine = std.coroutine
local string = std.string
local Queue = std.Queue

--- [SHARED AND MENU]
---
--- The futures library.
---
---@class dreamwork.std.futures
local futures = std.futures or {}
std.futures = futures

-- TODO: use errors instead of string
-- TODO: make cancel error

---@package
---@enum dreamwork.std.futures.result
futures.RESULT = futures.RESULT or {
    YIELD = std.Symbol( "futures.RESULT_YIELD" ),
    ERROR = std.Symbol( "futures.RESULT_ERROR" ),
    END =   std.Symbol( "futures.RESULT_END" )
}

---@package
---@enum dreamwork.std.futures.action
futures.ACTION = futures.ACTION or {
    CANCEL = std.Symbol( "futures.ACTION_CANCEL" ),
    RESUME = std.Symbol( "futures.ACTION_RESUME" ),
}

local RESULT_YIELD = futures.RESULT.YIELD
local RESULT_ERROR = futures.RESULT.ERROR
local RESULT_END = futures.RESULT.END

local ACTION_CANCEL = futures.ACTION.CANCEL
local ACTION_RESUME = futures.ACTION.RESUME

---@private
---@type { [thread]: function }
local listeners = futures.listeners
if listeners == nil then
    listeners = {}
    futures.listeners = listeners
    gc_setTableRules( listeners, true, false )
end

---@private
---@type { [thread]: thread }
local coroutine_listeners = futures.coroutine_listeners
if coroutine_listeners == nil then
    coroutine_listeners = {}
    futures.coroutine_listeners = coroutine_listeners
    gc_setTableRules( coroutine_listeners, true, false )
end

--- Abstract type that is used to type hint async functions.
---
---@see dreamwork.std.futures.apairs for example
---@alias dreamwork.std.futures.AsyncIterator<K, V> table<K, V> | nil
---@alias AsyncIterator<K, V> dreamwork.std.futures.AsyncIterator<K, V>

---@alias dreamwork.std.futures.Awaitable { await: async fun(...): ... }
---@alias Awaitable dreamwork.std.futures.Awaitable

local coroutine_running = coroutine.running
futures.running = coroutine_running

local coroutine_resume = coroutine.resume
futures.wakeup = coroutine_resume

local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
local coroutine_yield = coroutine.yield

-- TODO: replace this crap with normal errors
local ErrorNoHaltWithStack = _G.ErrorNoHaltWithStack

local function display_error( message )
    return ErrorNoHaltWithStack( message )
end

local async_thread_result
do

    local string_find = string.find
    local isString = std.isString

    ---@async
    ---@param ok boolean
    function async_thread_result( ok, value, ... )
        local fn = listeners[ coroutine_running() ]
        if isFunction( fn ) then
            fn( ok, value, ... )
        elseif not ok then
            -- TODO: use errors instead of this string
            if isString( value ) and string_find( value, "Operation was cancelled" ) then
                return
            end

            ErrorNoHaltWithStack( value )
        end
    end

end

---@async
local function async_thread( fn, ... )
    return async_thread_result( pcall( fn, ... ) )
end

--- [SHARED AND MENU]
---
--- Executes a function in a new coroutine
--- you can use this function to call async functions even in sync code
--- callback will be called when function returned or errored
--- it will be called with these arguments:
--- * ok: boolean - whether the function returned without errors
--- * ... - return values of the function (or error message)
---
--- ## Example
--- ```lua
--- ---@async
--- local function asyncFunction( a, b )
---     sleep( 1 )
---     return
--- end
---
--- futures.run( asyncFunction, function( ok, result )
---     if ok then
---         print( "result:", result ) -- result: 4
---     else
---         print( "error:", result )
---     end
--- end, 2, 2 ) -- 2 and 2 are arguments for asyncFunction
--- ```
---@see dreamwork.std.futures.cancel you can cancel returned coroutine from this function
---@param target async fun(...):... The function to execute.
---@param callback fun(ok: boolean, ...)? The callback function.
---@param ... any Arguments to pass into the target function
---@return thread co The created coroutine object.
local function futures_run( target, callback, ... )
    local co = coroutine_create( async_thread )
    listeners[ co ] = callback

    local ok, err = coroutine_resume( co, target, ... )

    if not ok then
        ErrorNoHaltWithStack( err )
    end

    return co
end

futures.run = futures_run


---@async
local function handle_pending( value, ... )
    if value == ACTION_CANCEL then
        return error( "Operation was cancelled" ) -- TODO: use error
    else
        return value, ...
    end
end

--- [SHARED AND MENU]
---
--- Puts current coroutine to sleep until futures.wakeup is called
--- can be used to wait for some event.
---
--- ## Example
--- ```lua
--- ---@async
--- local function request( url )
---     local co = futures.running()
---
---     http.Fetch( url, function( body, size, headers, code )
---         futures.wakeup( co, body )
---     end)
---
---     return futures.pending() -- this will return all arguments passed to futures.wakeup
--- end
---
--- local function main()
---     local body = request( "https://example.com" )
---     print( body ) -- <!DOCTYPE html>...
--- end
---
--- futures.run( main )
--- ```
---@see dreamwork.std.futures.wakeup
---@async
---@return ...
local function futures_pending()
    return handle_pending( coroutine_yield() )
end

futures.pending = futures_pending

-- --- [SHARED AND MENU]
-- ---
-- --- Used to wake up pending coroutine.
-- ---
-- ---@see dreamwork.std.futures.pending for example
-- ---@param co thread
-- function futures.wakeup( co, ... )
--     coroutine_resume( co, ... )
-- end


--- [SHARED AND MENU]
---
--- Cancels execution of passed coroutine.
---
--- `CancelError` will be thrown in coroutine.
---
--- NB! pcall inside coroutine can catch this error
--- so coroutine may not be cancelled because of pcall.
---
--- ## Example
--- ```lua
--- ---@async
--- local function work()
---     while true do
---        print( "working" )
---        sleep( 1 )
---     end
--- end
---
--- local co = futures.run( work, function(ok, value )
---     -- because we cancelled coroutine
---     -- ok will be false
---     -- value will be CancelError
--- end)
---
--- futures.cancel( co ) -- this will stop coroutine from executing
--- ```
---@param co thread
function futures.cancel( co )
    local status = coroutine_status( co )
    if status == "suspended" then
        coroutine_resume( co, ACTION_CANCEL )
    elseif status == "normal" and coroutine_running() then
        -- let's hope that passed coroutine resumed us
        ---@diagnostic disable-next-line: await-in-sync
        coroutine_yield( ACTION_CANCEL )
    elseif status == "running" then
        error( "Operation was cancelled" ) -- TODO: use error
    end
end


--- [SHARED AND MENU]
---
--- Transfers data between coroutines in symmetrical way
--- used in asynchronous iterators
--- you probably should not use it.
---
---@see dreamwork.std.futures.apairs for example
---@async
---@param co thread
---@param ... any
---@return boolean success
---@return any ...
local function futures_transfer( co, ... )
    local status = coroutine_status( co )
    if status == "suspended" then
        return coroutine_resume( co, ... )
    elseif status == "normal" then
        return true, coroutine_yield( ... )
    elseif status == "running" then
        return false, "cannot transfer to a running coroutine"
    else
        return false, "thread is dead"
    end
end

futures.transfer = futures_transfer


---@async
local function handle_yield( ok, value, ... )
    -- ignore errors, they must be handled by whoever calls us
    if not ok or value == RESULT_ERROR then
        return
    end

    if value == ACTION_CANCEL then
        return error( "Operation was cancelled" ) -- TODO: use error
    elseif value == ACTION_RESUME then
        return ...
    elseif value ~= nil then
        ErrorNoHaltWithStack( "invalid yield action: " .. tostring( value ) )
    else
        -- caller probably went sleeping
        return handle_yield( true, coroutine_yield() )
    end
end

do

    --- [SHARED AND MENU]
    ---
    --- Yields given arguments to the apairs listener.
    ---
    ---@see dreamwork.std.futures.apairs for example
    ---@async
    local function futures_yield( ... )
        local listener = coroutine_listeners[ coroutine_running() ]
        if listener then
            return handle_yield( futures_transfer( listener, RESULT_YIELD, ... ) )
        else
            -- whaat? we don't have a listener?!
            error( "Operation was cancelled" ) -- TODO: use error
        end
    end

    futures.yield = futures_yield
    std.yield = futures_yield

end

---@async
local function async_iteratable_thread( fn, ... )
    coroutine_yield() -- wait until anext wakes us up
    local ok, err = pcall( fn, ... )

    local listener = coroutine_listeners[ coroutine_running() ]
    if listener then
        if ok then
            futures_transfer( listener, RESULT_END )
        else
            futures_transfer( listener, RESULT_ERROR, err )
        end
    elseif not ok then
        error( err )
    end
end

---@async
---@param co thread
---@param ok boolean
local function handle_anext( co, ok, value, ... )
    if not ok then
        return error( value )
    end

    if value == RESULT_YIELD then
        return ...
    elseif value == RESULT_END then
        return -- return nothing so for loop with be stopped
    elseif value == RESULT_ERROR then
        return error( ... )
    elseif value ~= nil then
        ErrorNoHaltWithStack( "invalid anext result: " .. tostring( value ) )
    end

    -- iterator went sleeping, wait until it wakes us up
    return handle_anext( co, true, coroutine_yield() )
end

--- [SHARED AND MENU]
---
--- Retrieves next value from async iterator coroutine
--- this function returned by apairs
--- you probably should not use it.
---
---@see dreamwork.std.futures.apairs for example
---@async
---@param iterator thread
local function futures_anext( iterator, ... )
    return handle_anext( iterator, futures_transfer( iterator, ACTION_RESUME, ... ) )
end

futures.anext = futures_anext

--- [SHARED AND MENU]
---
--- Iterates over async iterator, calling it with given arguments.
---
--- ## Example
--- ```lua
--- ---@async
--- ---@return AsyncIterator<number>
--- local function count( from, to )
---     for i = from, to do
---         futures.yield( i )
---     end
--- end
---
--- local function main()
---     for i in futures.apairs( count, 1, 5 ) do
---         print( i ) -- 1, 2, 3, 4, 5
---     end
--- end
---
--- futures.run( main )
--- ```
---@see dreamwork.std.futures.yield
---@see dreamwork.std.futures.AsyncIterator
---@async
---@generic K, V
---@param iterator async fun(...): dreamwork.std.futures.AsyncIterator<K, V>
---@return async fun(...): K, V
---@return thread
local function futures_apairs( iterator, ... )
    local co = coroutine_create( async_iteratable_thread )
    coroutine_listeners[ co ] = coroutine_running()
    coroutine_resume( co, iterator, ... )
    return futures_anext, co
end

futures.apairs = futures_apairs
std.apairs = futures_apairs

--- [SHARED AND MENU]
---
--- Collects all values from async iterator into a list.
---
---@async
---@generic V
---@param iterator async fun(...): dreamwork.std.futures.AsyncIterator<V>
---@return V[] results
---@return number length
function futures.collect( iterator, ... )
    local results, length = {}, 0
    for value in futures_apairs( iterator, ... ) do
        length = length + 1
        results[ length ] = value
    end

    return results, length
end

--- [SHARED AND MENU]
---
--- Collects all values from async iterator into a table.
---
---@async
---@generic K, V
---@param iterator async fun(...): dreamwork.std.futures.AsyncIterator<K, V>
---@return table<K, V> result
function futures.collectTable( iterator, ... )
    local result = {}
    for k, v in futures_apairs( iterator, ... ) do
        result[ k ] = v
    end

    return result
end

do

    local table = std.table

    --- [SHARED AND MENU]
    ---
    --- Futures are objects that hold the result that can be assigned asynchronously
    --- they can be awaited to get the result
    --- or add callback with :addCallback(...) method.
    ---
    --- ```lua
    --- local fut = futures.Future()
    ---
    --- fut:addCallback( function( fut )
    ---     print( fut:result() ) -- "hello world"
    --- end )
    ---
    --- fut:setResult( "hello world" )
    ---
    --- -- or you can await it
    ---
    --- ---@async
    --- local function main()
    ---     print( fut:await() ) -- "hello world"
    --- end
    ---
    --- futures.run( main )
    ---
    --- -- also you can set error or cancel it
    --- fut:setError( "something went wrong" )
    --- fut:cancel()
    --- ```
    ---@class dreamwork.std.futures.Future : dreamwork.Object
    ---@field __class dreamwork.std.futures.FutureClass
    ---@field protected callbacks function[] The list of callbacks that will be called when future is done.
    ---@field protected state `0` | `1` | `2` `0` - PENDING, `1` - FINISHED, `2` - CANCELLED.
    ---@field protected result_value any The result value of the future.
    ---@field protected error_value any The error value of the future.
    local Future = futures.Future and futures.Future.__base or std.class.base( "Future" )

    ---@alias Future dreamwork.std.futures.Future

    ---@protected
    function Future:__init()
        self.state = 0
        self.callbacks = {}
    end

    ---@protected
    function Future:__tostring()
        local state = self.state
        if state ~= 0 then
            if state == 2 then
                return string.format( "Future: %p [cancelled]", self )
            elseif self.error_value then
                return string.format( "Future: %p [failure][%s]", self, tostring( self.error_value ) )
            else
                return string.format( "Future: %p [success][%s]", self, tostring( self.result_value ) )
            end
        else
            return string.format( "Future: %p [pending]", self )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if Future is pending.
    ---
    ---@return boolean
    function Future:isPending()
        return self.state == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if Future is finished (or cancelled).
    ---
    ---@return boolean
    function Future:isFinished()
        return self.state ~= 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns true if Future was cancelled.
    ---
    ---@return boolean
    function Future:isCancelled()
        return self.state == 2
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all callbacks.
    ---
    ---@private
    function Future:runCallbacks()
        local callbacks = self.callbacks
        self.callbacks = {}

        for i = 1, #callbacks, 1 do
            xpcall( callbacks[ i ], display_error, self )
        end
    end

    do

        local table_insert = table.insert

        --- [SHARED AND MENU]
        ---
        --- Adds callback that will be called when future is done
        --- if future is already done, callback will be called immediately.
        ---
        ---@see dreamwork.std.futures.Future.removeCallback for removing callback
        ---@param fn fun( fut: dreamwork.std.futures.Future )
        function Future:addCallback( fn )
            if self.state ~= 0 then
                xpcall( fn, display_error, self )
            else
                table_insert( self.callbacks, fn )
            end
        end

    end

    do

        local table_remove = table.remove

        --- [SHARED AND MENU]
        ---
        --- Removes callback that was previously added with `:addCallback`.
        ---
        ---@see dreamwork.std.futures.Future.addCallback for adding callback
        ---@param value function
        function Future:removeCallback( value )
            local callbacks = self.callbacks
            for i = #callbacks, 1, -1 do
                if callbacks[ i ] == value then
                    table_remove( callbacks, i )
                end
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Sets result of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---
    ---@see dreamwork.std.futures.Future.result to retrieve result
    ---@see dreamwork.std.futures.Future.await to asynchronously retrieve result
    ---@param result any
    function Future:setResult( result )
        if self.state ~= 0 then
            error( "future is already finished", 2 )
        end

        self.state = 1
        self.result_value = result

        self:runCallbacks()
    end

    --- [SHARED AND MENU]
    ---
    --- Sets error of the Future, marks it as finished, and runs all callbacks
    --- if future is already finished, error will be thrown.
    ---
    ---@param err any
    function Future:setError( err )
        if self.state ~= 0 then
            error( "future is already finished", 2 )
        end

        self.state = 1
        self.error_value = err

        self:runCallbacks()
    end

    --- [SHARED AND MENU]
    ---
    --- Tries to cancel future, if it's already done, returns `false`
    --- otherwise marks it as cancelled, runs all callbacks and returns `true`.
    ---
    ---@return boolean cancelled
    function Future:cancel()
        if self.state ~= 0 then
            return false
        end

        self.state = 2
        self:runCallbacks()
        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Returns error if future is finished and has error
    --- otherwise returns nil
    --- if future is not finished or cancelled, returns error.
    ---
    ---@see dreamwork.std.futures.Future.setError
    ---@return unknown?
    function Future:error()
        local state = self.state
        if state == 2 then
            return "future was cancelled"
        elseif state == 0 then
            return "future is not finished"
        else
            return self.error_value
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns result if future is finished
    --- otherwise throws an error.
    ---
    ---@see dreamwork.std.futures.Future.setResult
    ---@return any
    function Future:result()
        local state = self.state
        if state == 2 then
            return error( "future was cancelled" )
        elseif state == 0 then
            return error( "future is not finished" )
        else
            local error_value = self.error_value
            if error_value == nil then
                return self.result_value
            else
                error( error_value )
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Await until future will be finished
    --- if it contains an error, then it will be thrown.
    ---
    ---@async
    ---@return any
    function Future:await()
        if self.state == 0 then
            local co = coroutine_running()

            self:addCallback( function()
                coroutine_resume( co )
            end )

            futures_pending()
        end

        if self.state == 0 then
            error( "future hasn't changed it's state wtf???" )
        end

        return self:result()
    end

    --- [SHARED AND MENU]
    ---
    --- Future class.
    ---
    ---@class dreamwork.std.futures.FutureClass : dreamwork.std.futures.Future
    ---@field __base dreamwork.std.futures.Future
    ---@overload fun(): dreamwork.std.futures.Future
    local FutureClass = std.class.create( Future )
    futures.Future = FutureClass

end

do

    --- [SHARED AND MENU]
    ---
    --- Task is a Future wrapper around futures.run(...) to retrieve result of async function
    --- when task is created, it will immediately run given function.
    ---
    --- ## Example
    --- ```lua
    --- local function request( url )
    ---     -- asynchronous work....
    ---     return body
    --- end
    ---
    --- local task = futures.Task( request, "https://example.com" )
    --- task:addCallback( function( task )
    ---     local body = task:result()
    ---     print( body ) -- <!DOCTYPE html>...
    --- end )
    --- ```
    ---@class dreamwork.std.futures.Task : dreamwork.std.futures.Future
    ---@field __class dreamwork.std.futures.TaskClass
    ---@field __parent dreamwork.std.futures.Future
    ---@field private setResult fun( self, result )
    ---@field private setError fun( self, error )
    local Task = futures.Task and futures.Task.__base or std.class.base( "Task", false, futures.Future )

    ---@diagnostic disable-next-line: duplicate-doc-alias
    ---@alias Task dreamwork.std.futures.Task

    ---@protected
    ---@param fn async fun(...): any
    function Task:__init( fn, ... )
        self.__parent.__init( self )

        futures_run( fn, function( ok, value )
            if ok then
                self:setResult( value )
            else
                self:setError( value )
                -- TODO: check if error is cancel
            end
        end, ... )
    end

    --- [SHARED AND MENU]
    ---
    --- Task class.
    ---
    ---@class dreamwork.std.futures.TaskClass : dreamwork.std.futures.Task
    ---@field __base dreamwork.std.futures.Task
    ---@overload fun( fn: ( async fun(...): any ), ...: any ): dreamwork.std.futures.Task
    local TaskClass = std.class.create( Task )
    futures.Task = TaskClass
    std.Task = TaskClass

end

do

    --- [SHARED AND MENU]
    ---
    --- A channel is a queue-type object that can be used by multiple coroutines.
    ---
    ---@alias Channel dreamwork.std.futures.Channel
    ---@class dreamwork.std.futures.Channel : dreamwork.Object
    ---@field __class dreamwork.std.futures.ChannelClass
    ---@field max_size integer Maximum size of the channel.
    ---@field private queue dreamwork.std.Queue Queue of values.
    ---@field private getters dreamwork.std.Queue Queue of getters.
    ---@field private setters dreamwork.std.Queue Queue of setters.
    ---@field private closed boolean `true` if the channel is closed, `false` otherwise.
    local Channel = futures.Channel and futures.Channel.__base or std.class.base( "Channel" )

    --[[

        [ 0 ] = max size
        [ 1 ] = queue
        [ 2 ] = getters
        [ 3 ] = setters
        [ 4 ] = closed

    ]]

    ---@protected
    ---@param max_size number? Maximum size of the channel.
    function Channel:__init( max_size )
        if max_size and max_size < 0 then
            error( "maxSize must be greater or equal to 0" )
        end

        self.max_size = max_size or 0
        self.queue = Queue()
        self.getters = Queue()
        self.setters = Queue()
        self.closed = false
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the number of elements in the channel.
    ---
    ---@return number length
    function Channel:getLength()
        return self.queue:getLength()
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is empty, `false` otherwise.
    ---
    ---@return boolean isEmpty
    function Channel:isEmpty()
        return self.queue:isEmpty()
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is full, `false` otherwise.
    ---
    ---@return boolean isFull
    function Channel:isFull()
        local max_size = self.max_size
        if max_size == 0 then
            return false
        else
            return self:getLength() >= max_size
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Closes the channel.
    ---
    function Channel:close()
        self.closed = true

        -- wake up all getters and setters
        local getters = self.getters
        while not getters:isEmpty() do
            coroutine_resume( getters:pop() )
        end

        local setters = self.setters
        while not setters:isEmpty() do
            coroutine_resume( setters:pop() )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns `true` if the channel is closed, `false` otherwise.
    ---
    ---@return boolean isClosed
    function Channel:isClosed()
        return self.closed
    end

    --- [SHARED AND MENU]
    ---
    --- Puts a value into the channel, without waiting.
    ---
    ---@param value any
    ---@return boolean success
    function Channel:putNow( value )
        if self:isFull() or self.closed or value == nil then
            return false
        end

        self.queue:push( value )

        local getter = self.getters:pop()
        if getter then
            coroutine_resume( getter )
        end

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Puts a value into the channel.
    ---
    ---@async
    ---@param value any
    ---@param wait boolean?
    ---@return boolean success
    function Channel:put( value, wait )
        while wait ~= false and ( self:isFull() and not self.closed ) do
            self.setters:push( coroutine_running() )
            futures_pending()
        end

        return self:putNow( value )
    end

    --- [SHARED AND MENU]
    ---
    --- Gets a value from the channel, without waiting.
    ---
    function Channel:getNow()
        if self:isEmpty() or self.closed then
            return nil
        end

        local value = self.queue:pop()

        local setter = self.setters:pop()
        if setter then
            coroutine_resume( setter )
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Gets a value from the channel.
    ---
    ---@async
    ---@param wait boolean?
    function Channel:get( wait )
        while wait ~= false and self:isEmpty() and not self.closed do
            self.getters:push( coroutine_running() )
            futures_pending()
        end

        return self:getNow()
    end

    --- [SHARED AND MENU]
    ---
    --- A channel is a queue-type class that can be used by multiple coroutines.
    ---
    ---@class dreamwork.std.futures.ChannelClass : dreamwork.std.futures.Channel
    ---@field __base dreamwork.std.futures.Channel
    ---@overload fun( maxsize: number? ): dreamwork.std.futures.Channel
    futures.Channel = std.class.create( Channel )

end

--- [SHARED AND MENU]
---
--- Awaits concurrently all given `awaitables` and returns results in table.
---
---@async
---@param awaitables Awaitable[]
---@return any[]
local function awaitList( awaitables )
    local results = {}
    for i = 1, #awaitables do
        results[ i ] = awaitables[ i ]:await()
    end

    return results
end

--- [SHARED AND MENU]
---
--- Cancels all given awaitables.
---
---@param awaitables (Awaitable | { cancel: function })[]
local function cancelList( awaitables )
    for i = 1, #awaitables do
        local awaitable = awaitables[ i ]
        if isFunction( awaitable.cancel ) then
            awaitable:cancel()
        end
    end
end

--- [SHARED AND MENU]
---
--- Awaits concurrently all given `awaitables` and returns results in table
---
--- if any of awaitables throws an error, it will be thrown.
---
--- if any of awaitables if function, it will be asynchronously executed with given vararg
---
--- On error also cancels all other awaitables.
---
---@async
---@param awaitables Awaitable[]
---@return any[]
function futures.all( awaitables )
    local ok, result = pcall( awaitList, awaitables )
    if ok then
        return result
    else
        cancelList( awaitables )
        error( result )
    end
end

--- [SHARED AND MENU]
---
--- Returns first result of futures, or error.
---
--- Other awaitables will be cancelled after first result or error.
---
---@async
---@param futureList Future[]
---@return any
function futures.any( futureList )
    local co = coroutine_running()
    local finished = false

    local function callback( fut )
        if not finished then
            finished = true
            coroutine_resume( co, fut )
        end
    end

    for i = 1, #futureList do
        futureList[ i ]:addCallback( callback )
    end

    ---@type Future
    local fut = futures_pending()
    cancelList( futureList )
    return fut:result()
end
