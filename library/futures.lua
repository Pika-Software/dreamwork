---@meta _

---@class dreamwork
local dreamwork = {}

--- [SHARED AND MENU]
---
--- This library provides Python-like futures for asynchronous programming,
--- such as `Futures`, `Tasks`, `Channels`, and async iterators.
---
--- Author: [Retr0](https://github.com/dankmolot)
---
---@class futures
futures = {}

---@class dreamwork.Future
---@field RESULT_YIELD Symbol
---@field RESULT_ERROR Symbol
---@field RESULT_END Symbol
---@field ACTION_CANCEL Symbol
---@field ACTION_RESUME Symbol
---@field Listeners table<thread, function>
---@field AsyncListeners table<thread, thread>
---@field Stacks table<thread, debug.Stack>
---@field Threads table<thread, thread>
dreamwork.Future = {}

--- [SHARED AND MENU]
---
--- Abstract type that is used to type hint async functions.
---
---@see futures.apairs for example
---@alias futures.AsyncIterator<K, V> table<K, V> | nil
---@alias AsyncIterator<K, V> futures.AsyncIterator<K, V>

---@alias futures.Awaitable { await: async fun(...): ... }
---@alias Awaitable futures.Awaitable

futures.running = coroutine.running

--- [SHARED AND MENU]
---
--- Returns the debug stack tracked for the current coroutine,
--- or `nil` if called outside of a coroutine.
---
---@return debug.Stack | nil
---@nodiscard
function futures.stack() end

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
---
---@see futures.cancel you can cancel returned coroutine from this function
---@param target async fun(...):... The function to execute.
---@param callback fun(ok: boolean, ...)? The callback function.
---@param ... any Arguments to pass into the target function
---@return thread co The created coroutine object.
function futures.run(target, callback, ...) end

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
---@see futures.wakeup
---@async
---@return ...
function futures.pending() end

--- [SHARED AND MENU]
---
--- Used to wake up a pending coroutine.
---
---@see futures.pending for example
---@param co thread The coroutine currently suspended inside `futures.pending`.
---@param ... any Values to return from that `futures.pending()` call.
function futures.wakeup(co, ...) end

--- [SHARED AND MENU]
---
--- Cancels execution of passed coroutine.
---
--- `ACTION_CANCEL` will be thrown in coroutine.
---
--- NB! pcall inside coroutine can catch this error
--- so coroutine may not be cancelled because of pcall,
--- use `futures.isCancel` to detect it and rethrow.
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
--- local co = futures.run( work, function( ok, value )
---     if futures.isCancel( value ) then
---         -- because we cancelled coroutine
---         -- ok will be false
---         -- value will be `ACTION_CANCEL`
---     end
--- end )
---
--- futures.cancel( co ) -- this will stop coroutine from executing
--- ```
---@param co thread The coroutine to cancel.
function futures.cancel(co) end

--- [SHARED AND MENU]
---
--- Checks whether the value is the cancellation signal thrown by `futures.cancel`.
---
---@param value any The value to check, e.g. an error caught by `pcall` or the `value` of a `futures.run` callback.
---@return boolean is_cancel `true` if the value is the cancellation signal, otherwise `false`.
---@nodiscard
function futures.isCancel(value) end

--- [SHARED AND MENU]
---
--- Transfers data between coroutines in symmetrical way
--- used in asynchronous iterators
--- you probably should not use it.
---
---@see futures.apairs for example
---
---@param co thread The coroutine to transfer control and values to.
---@param ... any Values to pass to `co`.
---@return boolean success
---@return any ...
---@async
function futures.transfer(co, ...) end

--- [SHARED AND MENU]
---
--- Yields given arguments to the apairs listener.
---
---@see futures.apairs for example
---
---@param ... any Values to yield to the listener.
---@return ... any Values passed back to this coroutine via ACTION_RESUME.
---@async
function futures.yield(...) end

--- [SHARED AND MENU]
---
--- Yields given arguments to the apairs listener.
---
---@see futures.apairs for example
---
---@param ... any Values to yield to the listener.
---@return ... any Values passed back to this coroutine via ACTION_RESUME.
---@async
function yield(...) end

--- [SHARED AND MENU]
---
--- Retrieves the next value from an async iterator coroutine.
---
--- Returned by `futures.apairs`;
--- you probably shouldn't call it directly.
---
---@see futures.apairs for example
---
---@param iterator thread The async-iterator coroutine, as returned by `futures.apairs`.
---@param ... any Values to resume the iterator with.
---@return any ... The next yielded value(s), or nothing if the iterator finished.
---@nodiscard
---@async
function futures.anext(iterator, ...) end

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
---
---@see futures.yield
---@see futures.AsyncIterator
---
---@generic K, V
---@param iterator async fun(...): futures.AsyncIterator<K, V> The async iterator function to drive.
---@param ... any Arguments to pass to `iterator`.
---@return async fun(...): K, V
---@return thread
---@nodiscard
---@async
function futures.apairs(iterator, ...) end

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
---
---@see futures.yield
---@see futures.AsyncIterator
---
---@generic K, V
---@param iterator async fun(...): futures.AsyncIterator<K, V> The async iterator function to drive.
---@param ... any Arguments to pass to `iterator`.
---@return async fun(...): K, V
---@return thread
---@nodiscard
---@async
function apairs(iterator, ...) end

--- [SHARED AND MENU]
---
--- Collects all values from async iterator into a list.
---
---@generic V
---@param iterator async fun(...): futures.AsyncIterator<V> The async iterator to collect values from.
---@param ... any Arguments to pass to `iterator`.
---@return V[] results
---@return number length
---@nodiscard
---@async
function futures.collect(iterator, ...) end

--- [SHARED AND MENU]
---
--- Collects all values from async iterator into a table.
---
---@generic K, V
---@param iterator async fun(...): futures.AsyncIterator<K, V> The async iterator to collect entries from.
---@param ... any Arguments to pass to `iterator`.
---@return table<K, V> result
---@nodiscard
---@async
function futures.collectTable(iterator, ...) end

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
---@class Future<T> : Object
---@field __class futures.FutureClass
---@field protected callbacks function[] The list of callbacks that will be called when future is done.
---@field protected state `0` | `1` | `2` `0` - PENDING, `1` - FINISHED, `2` - CANCELLED.
---@field protected result_value T The result value of the future.
---@field protected error_value string The error value of the future.
local __Future = {}

---@protected
function __Future:__init() end

---@protected
function __Future:__tostring() end

--- [SHARED AND MENU]
---
--- Returns `true` if Future is pending.
---
---@return boolean
---@nodiscard
function __Future:isPending() end

--- [SHARED AND MENU]
---
--- Returns `true` if Future is finished (or cancelled).
---
---@return boolean
---@nodiscard
function __Future:isFinished() end

--- [SHARED AND MENU]
---
--- Returns true if Future was cancelled.
---
---@return boolean
---@nodiscard
function __Future:isCancelled() end

--- [SHARED AND MENU]
---
--- Adds callback that will be called when future is done
--- if future is already done, callback will be called immediately.
---
---@see Future.removeCallback for removing callback
---
---@generic T
---@param self Future<T>
---@param fn fun( fut: Future<T> ) The callback to invoke with the future once it's done.
function __Future:addCallback(fn) end

--- [SHARED AND MENU]
---
--- Removes callback that was previously added with `:addCallback`.
---
---@see Future.addCallback for adding callback
---
---@generic T
---@param self Future<T>
---@param fn function The callback previously passed to `:addCallback`.
function __Future:removeCallback(fn) end

--- [SHARED AND MENU]
---
--- Sets result of the Future, marks it as finished, and runs all callbacks
--- if future is already finished, error will be thrown.
---
---@see Future.result to retrieve result
---@see Future.await to asynchronously retrieve result
---
---@generic T
---@param self Future<T>
---@param result T The value to resolve the future with.
function __Future:setResult(result) end

--- [SHARED AND MENU]
---
--- Sets error of the Future, marks it as finished, and runs all callbacks
--- if future is already finished, error will be thrown.
---
---@param err string The error to fail the future with.
function __Future:setError(err) end

--- [SHARED AND MENU]
---
--- Tries to cancel future, if it's already done, returns `false`
--- otherwise marks it as cancelled, runs all callbacks and returns `true`.
---
---@return boolean cancelled
function __Future:cancel() end

--- [SHARED AND MENU]
---
--- Returns the future's error, if any:
--- * if cancelled, returns "future was cancelled"
--- * if still pending, returns "future is not finished"
--- * if finished successfully, returns nil
--- * if finished with an error, returns that error
---
---@see Future.setError
---@return string | nil
---@nodiscard
function __Future:error() end

--- [SHARED AND MENU]
---
--- Returns result if future is finished
--- otherwise throws an error.
---
---@see Future.setResult
---@generic T
---@param self Future<T>
---@return T
---@nodiscard
function __Future:result() end

--- [SHARED AND MENU]
---
--- Await until future will be finished
--- if it contains an error, then it will be thrown.
---
---@async
---@generic T
---@param self Future<T>
---@return T
function __Future:await() end

--- [SHARED AND MENU]
---
--- The class used to create new `Future` instances.
---
---@class futures.FutureClass : Future
---@field __base Future
---@overload fun(): Future
Future = {}

--- [SHARED AND MENU]
---
--- Async task object.
---
---@class futures.Task<T> : Future
---@field __class futures.TaskClass
---@field __parent Future
---@field protected setResult fun( self: futures.Task<T>, result: T )
---@field protected setError fun( self: futures.Task<T>, error: self )
---@field addCallback fun( self: futures.Task<T>, callback: fun( task: futures.Task<T> ) )
local __Task = {}

---@protected
---@param fn async fun(...): any
function __Task:__init(fn, ...) end

--- [SHARED AND MENU]
---
--- The class used to create new `Task` instances.
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
---
---@class futures.TaskClass : futures.Task
---@field __base futures.Task
---@overload fun( fn: ( async fun( ...: any ): any ), ...: any ): futures.Task
Task = {}

--- [SHARED AND MENU]
---
--- A channel is a queue-type object that can be used by multiple coroutines.
---
---@class futures.Channel<T> : Object
---@field __class futures.ChannelClass
---@field max_size integer Maximum size of the channel.
---@field protected queue Queue<T> Queue of values.
---@field protected getters Queue<thread> Queue of getters.
---@field protected setters Queue<thread> Queue of setters.
---@field protected closed boolean `true` if the channel is closed, `false` otherwise.
local __Channel = {}

---@protected
---@param max_size number? Maximum size of the channel.
function __Channel:__init(max_size) end

---@return integer
---@protected
function __Channel:__len() end

--- [SHARED AND MENU]
---
--- Returns `true` if the channel is empty, `false` otherwise.
---
---@return boolean isEmpty
---@nodiscard
function __Channel:isEmpty() end

--- [SHARED AND MENU]
---
--- Returns `true` if the channel is full, `false` otherwise.
---
---@return boolean isFull
---@nodiscard
function __Channel:isFull() end

--- [SHARED AND MENU]
---
--- Closes the channel.
---
function __Channel:close() end

--- [SHARED AND MENU]
---
--- Returns `true` if the channel is closed, `false` otherwise.
---
---@return boolean isClosed
---@nodiscard
function __Channel:isClosed() end

--- [SHARED AND MENU]
---
--- Puts a value into the channel.
---
---@generic T
---@param self futures.Channel<T>
---@param value T The value to push. Must not be `nil`.
---@param force boolean? If `true`, push without waiting for space, bypassing the max-size check.
---@return boolean success
function __Channel:push(value, force) end

--- [SHARED AND MENU]
---
--- Gets a value from the channel.
---
---@generic T
---@param self futures.Channel<T>
---@param force boolean? If `true`, pop without waiting for a value even if the channel is empty.
---@return T | nil value
function __Channel:pop(force) end

--- [SHARED AND MENU]
---
--- The class used to create new `Channel` instances.
---
--- A channel is a queue-type class that can be used by multiple coroutines.
---
---@class futures.ChannelClass : futures.Channel
---@field __base futures.Channel
---@overload fun( maxsize: number? ): futures.Channel
Channel = {}

--- [SHARED AND MENU]
---
--- Awaits all given `awaitables` (in order) and returns their results in a table.
---
--- Each item must implement `:await()` (e.g. Future/Task) — plain functions are not supported.
---
--- If any awaitable throws, the error is re-thrown and all remaining awaitables are cancelled.
---
---@param awaitables Awaitable[] The list of awaitables (e.g. Future/Task instances) to await.
---@return any[]
---@async
function futures.all(awaitables) end

--- [SHARED AND MENU]
---
--- Returns first result of futures, or error.
---
--- Other awaitables will be cancelled after first result or error.
---
---@param futureList Future[] The list of futures to race against each other.
---@return any
---@async
function futures.any(futureList) end

--- [SHARED AND MENU]
---
--- Puts current thread to sleep for given amount of seconds.
---
---@see futures.pending
---@see futures.wakeup
---
---@param seconds number How long to sleep, in seconds.
---@async
function futures.sleep(seconds) end
