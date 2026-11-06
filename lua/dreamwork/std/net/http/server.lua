---@diagnostic disable-next-line: undefined-global
local glua_httpserver = httpserver

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call
local exceptions_report = dreamwork_exceptions.report

local engine_timer_simple = dreamwork.engine.timer.simple

---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.http
local http = std.http

local debug = std.debug
local debug_newproxy = debug.newproxy
local debug_getmetatable = debug.getmetatable

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_set = raw.set
local raw_index = raw.index
local raw_pairs = raw.pairs

local math = std.math
local math_floor = math.floor

local string = std.string
local string_format = string.format
local string_upper = string.upper

local class = std.class
local class_new = class.new
local class_isInherited = class.isInherited

local uuid = std.uuid
local uuid_unique = uuid.unique

local error = std.error
local type = std.type

local Future = std.Future


local httpserver_available = glua_httpserver ~= nil and glua_httpserver.Create ~= nil

---@type fun(): holylib.HttpServer
local httpserver_Create

---@type fun( server: holylib.HttpServer )
local httpserver_Destroy

---@type fun( name: string ): holylib.HttpServer | nil
local httpserver_FindByName

---@type fun(): holylib.HttpServer[]
local httpserver_GetAll

if httpserver_available then
    httpserver_Create = glua_httpserver.Create
    httpserver_Destroy = glua_httpserver.Destroy
    httpserver_FindByName = glua_httpserver.FindByName
    httpserver_GetAll = glua_httpserver.GetAll
end

---@alias dreamwork.std.http.Server.Handler fun( request: dreamwork.std.http.Server.Request, response: dreamwork.std.http.Server.Response ): ( boolean | dreamwork.std.Future | nil )
---@alias dreamwork.std.http.Server.ErrorHandler fun( request: dreamwork.std.http.Server.Request, response: dreamwork.std.http.Server.Response, err: any )

---@class dreamwork.std.http.Server.State
---@field handle holylib.HttpServer The HolyLib server.
---@field owned boolean `true` if this wrapper created the server, only owned servers are destroyed by `__gc`.
---@field deferred table<holylib.HttpRequest, boolean> Deferred raw requests, weak keys (HolyLib holds them until handled).
---@field waiting table<holylib.HttpRequest, dreamwork.std.http.Server.Exchange> Exchanges of deferred requests, weak keys and values.
---@field on_error dreamwork.std.http.Server.ErrorHandler | nil
---@field restart_pending boolean
---@field tcp_nodelay boolean | nil Last assigned value, HolyLib has no getter.
---@field read_timeout number | nil Last assigned value, HolyLib has no getter.
---@field write_timeout number | nil Last assigned value, HolyLib has no getter.
---@field payload_max_length integer | nil Last assigned value, HolyLib has no getter.
---@field keep_alive_timeout integer | nil Last assigned value, HolyLib has no getter.
---@field keep_alive_max_count integer | nil Last assigned value, HolyLib has no getter.
---@field thread_sleep integer | nil Last assigned value, HolyLib has no getter.

---@type table<dreamwork.std.http.Server, dreamwork.std.http.Server.State>
local states = {}
gc_setTableRules( states, true, false )

--- Strong references to running servers, so a listening server is never collected.
---
---@type table<dreamwork.std.http.Server, boolean>
local running = {}

--- The data shared by a `Request` and its `Response`.
---
--- Never references the wrappers themselves, weak-key tables in LuaJIT are not ephemerons,
--- so a value pointing back at its key would keep the entry alive forever.
---
---@class dreamwork.std.http.Server.Exchange
---@field raw holylib.HttpRequest | holylib.HttpResponse | nil The HolyLib object, `nil` once finished.
---@field state dreamwork.std.http.Server.State | nil The server state, `nil` for prepared responses.
---@field guard userdata | nil The finalizer guard of a deferred request.
---@field cache table<string, any> | nil Request properties read so far.
---@field content string | nil
---@field content_type string | nil
---@field status integer | nil

---@type table<dreamwork.std.http.Server.Request | dreamwork.std.http.Server.Response, dreamwork.std.http.Server.Exchange>
local exchanges = {}
gc_setTableRules( exchanges, true, false )

--- Sends the response of the exchange and invalidates its wrappers, does nothing if already finished or prepared.
---
---@param exchange dreamwork.std.http.Server.Exchange
local function finish_exchange( exchange )
    local raw_request = exchange.raw
    local state = exchange.state

    if raw_request == nil or state == nil then return end

    ---@cast raw_request holylib.HttpRequest

    exchange.raw = nil

    local guard = exchange.guard
    if guard ~= nil then
        exchange.guard = nil
        ---@diagnostic disable-next-line: param-type-mismatch
        raw_set( debug_getmetatable( guard ), "__gc", nil )
    end

    state.deferred[ raw_request ] = nil
    state.waiting[ raw_request ] = nil

    if raw_request:IsValid() then
        raw_request:MarkHandled()
    end
end


--- [SERVER]
---
--- An incoming request delivered to an `http.Server` route handler.
---
--- A request is valid until it is finished, synchronous handlers finish when they return.
--- Properties read before that stay readable, everything else raises an error.
---
---@class dreamwork.std.http.Server.Request : dreamwork.std.Object
---@field __class dreamwork.std.http.Server.RequestClass
---@field path string The request path, e.g. `"/users/42"`. **Read-only.**
---@field body string The raw request body. **Read-only.**
---@field remote_addr string The client IP (after proxy header rewriting when configured). **Read-only.**
---@field remote_port integer The remote port the request came from. **Read-only.**
---@field local_addr string The local address that accepted the connection. **Read-only.**
---@field local_port integer The local port that accepted the connection. **Read-only.**
---@field method string The HTTP method, e.g. `"GET"` or `"POST"`. **Read-only.**
---@field content_length integer The request `Content-Length`. **Read-only.**
---@field authorization_count integer The number of `Authorization` credentials parsed from the request. **Read-only.**
---@field client holylib.CBaseClient | nil The HolyLib `CBaseClient` for the connected player that matched this request's IP, if any. **Read-only.**
---@field player garrysmod.Player | nil The `Player` for the connected player that matched this request's IP, if any. **Read-only.**
local Request = class.base( "http.Server.Request" )

---@type table<string, string>
local request_getters = {
    path = "GetPath",
    body = "GetBody",
    remote_addr = "GetRemoteAddr",
    remote_port = "GetRemotePort",
    local_addr = "GetLocalAddr",
    local_port = "GetLocalPort",
    method = "GetMethod",
    content_length = "GetContentLength",
    authorization_count = "GetAuthorizationCount",
    client = "GetClient",
    player = "GetPlayer"
}

--- Returns the raw request or throws if it was already finished.
---
---@param request dreamwork.std.http.Server.Request
---@return holylib.HttpRequest
local function request_raw( request )
    local raw_request = exchanges[ request ].raw
    if raw_request == nil then
        error( "http.Server.Request is already finished", 3 )
    end

    ---@cast raw_request holylib.HttpRequest
    return raw_request
end

---@param exchange dreamwork.std.http.Server.Exchange
---@protected
function Request:__init( exchange )
    exchanges[ self ] = exchange
end

---@param key string
---@return any
---@protected
function Request:__index( key )
    local getter = request_getters[ key ]
    if getter == nil then
        return raw_index( Request, key )
    end

    local exchange = exchanges[ self ]

    local cache = exchange.cache
    if cache == nil then
        cache = {}
        exchange.cache = cache
    else
        local value = cache[ key ]
        if value ~= nil then
            return value
        end
    end

    local raw_request = request_raw( self )

    -- cached, so it outlives `:finish`
    local value = raw_request[ getter ]( raw_request )
    cache[ key ] = value
    return value
end

---@param key string
---@protected
function Request:__newindex( key )
    error( string_format( "attempt to modify read-only http.Server.Request property '%s'", key ), 2 )
end

---@return boolean is_valid
---@protected
function Request:__isvalid()
    return exchanges[ self ].raw ~= nil
end

--- [SERVER]
---
--- Returns `true` if the request has the given header.
---
---@param key string The header name.
---@return boolean has_header
---@nodiscard
function Request:hasHeader( key )
    return request_raw( self ):HasHeader( key )
end

--- [SERVER]
---
--- Returns `true` if the request has the given query / form parameter.
---
---@param key string The parameter name.
---@return boolean has_param
---@nodiscard
function Request:hasParam( key )
    return request_raw( self ):HasParam( key )
end

--- [SERVER]
---
--- Returns the value of the given header, or `nil` if missing.
---
---@param key string The header name.
---@return string | nil value
---@nodiscard
function Request:getHeader( key )
    local raw_request = request_raw( self )
    if raw_request:HasHeader( key ) then
        return raw_request:GetHeader( key )
    end

    return nil
end

--- [SERVER]
---
--- Returns the value of the given query / form parameter, or `nil` if missing.
---
---@param key string The parameter name.
---@return string | nil value
---@nodiscard
function Request:getParam( key )
    local raw_request = request_raw( self )
    if raw_request:HasParam( key ) then
        return raw_request:GetParam( key )
    end

    return nil
end

--- [SERVER]
---
--- Returns a path parameter captured from a `:name` segment in the route pattern, or `nil` if missing.
---
---@param key string The path parameter name without the leading `":"`.
---@return string | nil value
---@nodiscard
function Request:getPathParam( key )
    return request_raw( self ):GetPathParam( key )
end

--- [SERVER]
---
--- Sends the response and invalidates the request and its response.
---
--- Synchronous handlers are finished automatically when they return,
--- call this only from handlers that returned `false` to defer the reply.
---
--- Calling it again does nothing.
---
function Request:finish()
    finish_exchange( exchanges[ self ] )
end

--- [SERVER]
---
--- The class used to create `http.Server.Request` wrappers.
---
---@class dreamwork.std.http.Server.RequestClass : dreamwork.std.http.Server.Request, dreamwork.std.Class
---@field __base dreamwork.std.http.Server.Request
---@overload fun( exchange: dreamwork.std.http.Server.Exchange ): dreamwork.std.http.Server.Request
local RequestClass = class.create( Request )


--- [SERVER]
---
--- The response writer for an `http.Server` route handler.
---
--- Backed by the same HolyLib `HttpRequest` as the paired `Request` (HolyLib 0.8 merged the response into it),
--- or by an `HttpResponse` when used from `:prepare`.
---
--- Assign `content`, `content_type`, or `status` to build the reply, or use `:send`.
---
---@class dreamwork.std.http.Server.Response : dreamwork.std.Object
---@field __class dreamwork.std.http.Server.ResponseClass
---@field content string | nil The response body, `nil` until assigned. Assigning calls `SetContent` with the current `content_type`.
---@field content_type string The `Content-Type`, defaults to `"text/plain"`.
---@field status integer | nil The response status code (`100`–`599`), `nil` until assigned.
local Response = class.base( "http.Server.Response", true )

--- Returns the raw response or throws if it was already sent.
---
---@param exchange dreamwork.std.http.Server.Exchange
---@return holylib.HttpRequest | holylib.HttpResponse
local function response_raw( exchange )
    local raw_response = exchange.raw
    if raw_response == nil then
        error( "http.Server.Response is already sent", 3 )
    end

    return raw_response
end

---@param exchange dreamwork.std.http.Server.Exchange
---@protected
function Response:__init( exchange )
    exchanges[ self ] = exchange
end

---@param key string
---@return any
---@protected
function Response:__index( key )
    if key == "content" then
        return exchanges[ self ].content
    elseif key == "content_type" then
        return exchanges[ self ].content_type or "text/plain"
    elseif key == "status" then
        return exchanges[ self ].status
    end

    return raw_index( Response, key )
end

---@param key string
---@param value any
---@protected
function Response:__newindex( key, value )
    local exchange = exchanges[ self ]

    if key == "content" then
        response_raw( exchange ):SetContent( value, exchange.content_type or "text/plain" )
        exchange.content = value
    elseif key == "content_type" then
        local content = exchange.content
        if content ~= nil then
            response_raw( exchange ):SetContent( content, value )
        end

        exchange.content_type = value
    elseif key == "status" then
        response_raw( exchange ):SetStatusCode( value )
        exchange.status = value
    else
        error( string_format( "attempt to modify unknown http.Server.Response property '%s'", key ), 2 )
    end
end

---@return boolean is_valid
---@protected
function Response:__isvalid()
    return exchanges[ self ].raw ~= nil
end

--- [SERVER]
---
--- Sets a response header.
---
---@param key string The header name.
---@param value string The header value.
---@return dreamwork.std.http.Server.Response self
function Response:setHeader( key, value )
    response_raw( exchanges[ self ] ):SetHeader( key, value )
    return self
end

--- [SERVER]
---
--- Sets a redirect response.
---
---@param url string The redirect target URL.
---@param code integer? The redirect status code. Defaults to `302`.
---@return dreamwork.std.http.Server.Response self
function Response:setRedirect( url, code )
    response_raw( exchanges[ self ] ):SetRedirect( url, code )
    return self
end

--- [SERVER]
---
--- Sets the status, body and optionally the content type in one call.
---
---@param status integer The response status code.
---@param content string The response body.
---@param content_type dreamwork.std.http.ContentType? The `Content-Type`, defaults to the current `content_type`.
---@return dreamwork.std.http.Server.Response self
function Response:send( status, content, content_type )
    local exchange = exchanges[ self ]
    local raw_response = response_raw( exchange )

    if content_type == nil then
        content_type = exchange.content_type or "text/plain"
    else
        exchange.content_type = content_type
    end

    raw_response:SetStatusCode( status )
    raw_response:SetContent( content, content_type )

    exchange.status = status
    exchange.content = content
    return self
end

--- [SERVER]
---
--- Shortcut for `Request:finish` of the paired request.
---
--- Does nothing for responses created by `:prepare`.
---
function Response:finish()
    finish_exchange( exchanges[ self ] )
end

--- [SERVER]
---
--- The class used to create `http.Server.Response` wrappers.
---
---@class dreamwork.std.http.Server.ResponseClass : dreamwork.std.http.Server.Response, dreamwork.std.Class
---@field __base dreamwork.std.http.Server.Response
---@overload fun( exchange: dreamwork.std.http.Server.Exchange ): dreamwork.std.http.Server.Response
local ResponseClass = class.create( Response )


--- Writes the error reply, through the server error handler when one is set.
---
---@param exchange dreamwork.std.http.Server.Exchange
---@param request dreamwork.std.http.Server.Request
---@param response dreamwork.std.http.Server.Response
---@param err any
local function send_error( exchange, request, response, err )
    local on_error = exchange.state.on_error
    if on_error == nil or not exceptions_call( on_error, request, response, err ) then
        local raw_response = exchange.raw
        if raw_response ~= nil then
            raw_response:SetStatusCode( 500 )
            raw_response:SetContent( "Internal Server Error", "text/plain" )
        end
    end
end

--- Marks the request as deferred.
---
--- HolyLib calls the route callback again for every unhandled request on later frames,
--- so deferred requests are tracked to skip those calls.
---
--- A guard finalizer finishes the request if the handler drops it without calling `:finish`,
--- otherwise the worker thread would wait for it forever.
---
---@param state dreamwork.std.http.Server.State
---@param exchange dreamwork.std.http.Server.Exchange
---@param raw_request holylib.HttpRequest
local function defer( state, exchange, raw_request )
    state.deferred[ raw_request ] = true
    state.waiting[ raw_request ] = exchange

    local guard = debug_newproxy( true )

    ---@diagnostic disable-next-line: param-type-mismatch
    raw_set( debug_getmetatable( guard ), "__gc", function()
        if raw_request:IsValid() then
            raw_request:MarkHandled()
        end
    end )

    exchange.guard = guard
end

--- Answers every deferred request with `503`.
---
--- HolyLib's `Stop` waits for its worker threads, which wait for deferred requests,
--- so stopping with deferred requests left would hang the main thread.
---
---@param state dreamwork.std.http.Server.State
local function flush_deferred( state )
    local deferred, waiting = state.deferred, state.waiting

    for raw_request in raw_pairs( deferred ) do
        deferred[ raw_request ] = nil

        if raw_request:IsValid() then
            raw_request:SetStatusCode( 503 )
            raw_request:SetContent( "Service Unavailable", "text/plain" )
        end

        local exchange = waiting[ raw_request ]
        if exchange == nil then
            -- the exchange is collected, its guard has not run yet
            if raw_request:IsValid() then
                raw_request:MarkHandled()
            end
        else
            finish_exchange( exchange )
        end
    end
end

--- Wraps a dreamwork handler into a single-argument HolyLib callback.
---
---@param state dreamwork.std.http.Server.State
---@param handler dreamwork.std.http.Server.Handler
---@return fun( raw_request: holylib.HttpRequest ): boolean
local function wrap_handler( state, handler )
    return function( raw_request )
        if state.deferred[ raw_request ] ~= nil then
            return false
        end

        ---@type dreamwork.std.http.Server.Exchange
        local exchange = { raw = raw_request, state = state }

        local request = RequestClass( exchange )
        local response = ResponseClass( exchange )

        local ok, result = exceptions_call( handler, request, response )
        if not ok then
            send_error( exchange, request, response, result )
        elseif result == false then
            defer( state, exchange, raw_request )
            return false
            ---@diagnostic disable-next-line: param-type-mismatch
        elseif result ~= nil and class_isInherited( result, Future ) then
            ---@cast result dreamwork.std.Future
            defer( state, exchange, raw_request )

            result:addCallback( function( future )
                if exchange.raw == nil then
                    return
                end

                local err = future:error()
                if err ~= nil then
                    exceptions_report( err )
                    send_error( exchange, request, response, err )
                end

                finish_exchange( exchange )
            end )

            return false
        end

        -- HolyLib marks the request handled after we return, the wrappers must not touch it after that
        exchange.raw = nil
        return true
    end
end

--- Returns the server state or throws if the server was destroyed.
---
---@param server dreamwork.std.http.Server
---@return dreamwork.std.http.Server.State
local function require_state( server )
    local state = states[ server ]
    if state == nil or not state.handle:IsValid() then
        error( "http.Server is destroyed", 3 )
    end

    return state
end

--- Restarts the server on the next frame if it is listening, so new routes and settings take effect.
---
--- Batched, so registering many routes in one frame restarts only once.
---
---@param state dreamwork.std.http.Server.State
local function schedule_restart( state )
    if state.restart_pending or not state.handle:IsRunning() then
        return
    end

    state.restart_pending = true

    engine_timer_simple( 0, function()
        if not state.restart_pending then
            return
        end

        state.restart_pending = false

        local handle = state.handle
        if handle:IsValid() and handle:IsRunning() then
            flush_deferred( state )
            handle:Start( handle:GetAddress(), handle:GetPort() )
        end
    end )
end

--- Stops and destroys the HolyLib server of the state.
---
---@param state dreamwork.std.http.Server.State
local function destroy_state( state )
    state.restart_pending = false

    local handle = state.handle
    if handle:IsValid() then
        flush_deferred( state )
        httpserver_Destroy( handle )
    end
end

--- [SERVER]
---
--- An HTTP server backed by [HolyLib's httpserver](https://holylib.raphaelit7.com/httpserver).
---
--- ```lua
--- local server = std.http.Server()
---
--- server:get( "/hello", function( req, res )
---     res.content = "hello " .. req.remote_addr
--- end )
---
--- server:start( "0.0.0.0", 8080 )
--- ```
---
--- Handlers can defer the reply:
--- * return a `Future`, the request finishes when it settles, a failed or cancelled future replies via the error handler;
--- * return `false`, then call `req:finish()` (or `res:finish()`) later.
---
--- A deferred request that is dropped without `:finish` is finished when it is collected.
--- Stopping or restarting the server answers every deferred request with `503`.
---
--- A running server is kept alive until `:stop` or `:destroy`, a stopped one is destroyed when collected.
---
---@class dreamwork.std.http.Server : dreamwork.std.Object
---@field __class dreamwork.std.http.ServerClass
---@field name string The server name used by `http.Server.findByName`, max length is 63 characters.
---@field address string The bind address from the last `:start`. **Read-only.**
---@field port integer The listen port from the last `:start`, or `0` before start. **Read-only.**
---@field running boolean `true` if the server is currently listening, `false` once destroyed. **Read-only.**
---@field error_handler dreamwork.std.http.Server.ErrorHandler | nil Called when a route handler throws or its future fails, `nil` (and the fallback when it throws itself) replies `500 Internal Server Error`.
---@field tcp_nodelay boolean | nil `true` sets TCP_NODELAY on accepted sockets. `nil` until assigned (HolyLib default).
---@field read_timeout number | nil The maximum time allowed for a read, in seconds (fractions are microseconds). `nil` until assigned (HolyLib default).
---@field write_timeout number | nil The maximum time allowed for a write, in seconds (fractions are microseconds). `nil` until assigned (HolyLib default).
---@field payload_max_length integer | nil The maximum accepted request body length in bytes. `nil` until assigned (HolyLib default).
---@field keep_alive_timeout integer | nil How long keep-alive connections may stay open, in seconds. `nil` until assigned (HolyLib default).
---@field keep_alive_max_count integer | nil How many requests a keep-alive connection may serve. `nil` until assigned (HolyLib default).
---@field thread_sleep integer | nil How long worker threads sleep (ms) while waiting for the main thread to handle a request. `nil` until assigned (HolyLib default).
local Server = class.base( "http.Server", true )

--- Registers the state of a new server object.
---
---@param server dreamwork.std.http.Server
---@param handle holylib.HttpServer
---@param owned boolean
---@return dreamwork.std.http.Server
local function create_server( server, handle, owned )
    local deferred = {}
    gc_setTableRules( deferred, true, false )

    local waiting = {}
    gc_setTableRules( waiting, true, true )

    states[ server ] = {
        handle = handle,
        owned = owned,
        deferred = deferred,
        waiting = waiting,
        restart_pending = false
    }

    return server
end

--- Wraps an existing HolyLib `HttpServer`, reusing a dreamwork wrapper when one already exists.
---
--- The wrapper does not own the server, collecting it leaves the server alive.
---
---@param handle holylib.HttpServer
---@return dreamwork.std.http.Server
local function wrap_handle( handle )
    for server, state in raw_pairs( states ) do
        if state.handle == handle then
            return server
        end
    end

    return create_server( class_new( Server ), handle, false )
end

--- Splits seconds into the `sec, usec` pair HolyLib timeouts take.
---
---@param seconds number
---@return integer sec
---@return integer usec
local function split_seconds( seconds )
    local sec = math_floor( seconds )
    return sec, math_floor( (seconds - sec) * 1000000 )
end

---@type table<string, fun( state: dreamwork.std.http.Server.State ): any>
local server_getters = {
    name = function( state )
        return state.handle:GetName()
    end,
    address = function( state )
        return state.handle:GetAddress()
    end,
    port = function( state )
        return state.handle:GetPort()
    end,
    error_handler = function( state )
        return state.on_error
    end,
    tcp_nodelay = function( state )
        return state.tcp_nodelay
    end,
    read_timeout = function( state )
        return state.read_timeout
    end,
    write_timeout = function( state )
        return state.write_timeout
    end,
    payload_max_length = function( state )
        return state.payload_max_length
    end,
    keep_alive_timeout = function( state )
        return state.keep_alive_timeout
    end,
    keep_alive_max_count = function( state )
        return state.keep_alive_max_count
    end,
    thread_sleep = function( state )
        return state.thread_sleep
    end
}

---@type table<string, fun( state: dreamwork.std.http.Server.State, value: any )>
local server_setters = {
    name = function( state, name )
        state.handle:SetName( name )
    end,
    error_handler = function( state, fn )
        state.on_error = fn
    end,
    tcp_nodelay = function( state, nodelay )
        state.handle:SetTCPnodelay( nodelay )
        state.tcp_nodelay = nodelay
    end,
    read_timeout = function( state, seconds )
        state.handle:SetReadTimeout( split_seconds( seconds ) )
        state.read_timeout = seconds
    end,
    write_timeout = function( state, seconds )
        state.handle:SetWriteTimeout( split_seconds( seconds ) )
        state.write_timeout = seconds
    end,
    payload_max_length = function( state, max_length )
        state.handle:SetPayloadMaxLength( max_length )
        state.payload_max_length = max_length
    end,
    keep_alive_timeout = function( state, sec )
        state.handle:SetKeepAliveTimeout( sec )
        state.keep_alive_timeout = sec
    end,
    keep_alive_max_count = function( state, amount )
        state.handle:SetKeepAliveMaxCount( amount )
        state.keep_alive_max_count = amount
    end,
    thread_sleep = function( state, sleep_ms )
        state.handle:SetThreadSleep( sleep_ms )
        state.thread_sleep = sleep_ms
    end
}

---@param key string
---@return any
---@protected
function Server:__index( key )
    local getter = server_getters[ key ]
    if getter ~= nil then
        return getter( require_state( self ) )
    end

    if key == "running" then
        local state = states[ self ]
        return state ~= nil and state.handle:IsValid() and state.handle:IsRunning()
    end

    return raw_index( Server, key )
end

---@param key string
---@param value any
---@protected
function Server:__newindex( key, value )
    local setter = server_setters[ key ]
    if setter ~= nil then
        setter( require_state( self ), value )
    elseif server_getters[ key ] ~= nil or key == "running" then
        error( string_format( "attempt to modify read-only http.Server property '%s'", key ), 2 )
    else
        error( string_format( "attempt to modify unknown http.Server property '%s'", key ), 2 )
    end
end

---@return string
---@protected
function Server:__represent()
    local state = states[ self ]
    if state == nil or not state.handle:IsValid() then
        return string_format( "%s: %p [destroyed]", type( self ), self )
    end

    local handle = state.handle
    return string_format( "%s: %p [%s:%d - %s]", type( self ), self, handle:GetAddress(), handle:GetPort(), handle:GetName() )
end

---@param name string?
---@protected
function Server:__init( name )
    if not httpserver_available then
        error( "http.Server requires HolyLib's httpserver module", 2 )
    end

    local server = httpserver_Create()
    server:SetName( name or uuid_unique() )
    create_server( self, server, true )
end

--- Destroys the HolyLib server when the object is collected, only if this wrapper created it.
---
---@protected
function Server:__gc()
    local state = states[ self ]
    if state == nil then
        return
    end

    states[ self ] = nil

    if state.owned then
        exceptions_call( destroy_state, state )
    end
end

---@return boolean is_valid
---@protected
function Server:__isvalid()
    local state = states[ self ]
    return state ~= nil and state.handle:IsValid()
end

--- [SERVER]
---
--- Stops and destroys the underlying HolyLib server, even one found with `findByName` / `getAll`.
---
--- Further method calls raise an error.
---
function Server:destroy()
    local state = states[ self ]
    if state == nil then
        return
    end

    states[ self ] = nil
    running[ self ] = nil

    destroy_state( state )
end

--- [SERVER]
---
--- Starts (or restarts) the server on the given address and port.
---
--- HolyLib binds on a separate thread, so `running` may stay `false` for a moment
--- and a failed bind is not reported.
---
--- Route and setting changes on a running server restart it on the next frame.
---
---@param address string Bind address, e.g. `"0.0.0.0"` or `"127.0.0.1"`.
---@param port integer TCP port to listen on.
function Server:start( address, port )
    local state = require_state( self )
    state.restart_pending = false

    flush_deferred( state )
    state.handle:Start( address, port )

    running[ self ] = true
end

--- [SERVER]
---
--- Stops the server if it is running, deferred requests are answered with `503`.
---
function Server:stop()
    local state = require_state( self )
    state.restart_pending = false
    running[ self ] = nil

    flush_deferred( state )
    state.handle:Stop()
end

--- Registers a route with the given HolyLib method and restarts the server when it is listening.
---
---@param server dreamwork.std.http.Server
---@param method_name "Get" | "Post" | "Put" | "Patch" | "Delete" | "Options"
---@param path string
---@param handler dreamwork.std.http.Server.Handler
---@param ip_whitelist boolean?
local function add_route( server, method_name, path, handler, ip_whitelist )
    local state = require_state( server )
    local handle = state.handle

    handle[ method_name ]( handle, path, wrap_handler( state, handler ), ip_whitelist == true )
    schedule_restart( state )
end

--- [SERVER]
---
--- Registers a `GET` handler. Path parameters use `:name` segments (e.g. `"/user/:id"`).
---
--- When `ip_whitelist` is `true`, only requests from connected players' IPs are handled.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:get( path, handler, ip_whitelist )
    add_route( self, "Get", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Registers a `POST` handler.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:post( path, handler, ip_whitelist )
    add_route( self, "Post", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Registers a `PUT` handler.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:put( path, handler, ip_whitelist )
    add_route( self, "Put", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Registers a `PATCH` handler.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:patch( path, handler, ip_whitelist )
    add_route( self, "Patch", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Registers a `DELETE` handler.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:delete( path, handler, ip_whitelist )
    add_route( self, "Delete", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Registers an `OPTIONS` handler.
---
---@param path string The URL path pattern.
---@param handler dreamwork.std.http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:options( path, handler, ip_whitelist )
    add_route( self, "Options", path, handler, ip_whitelist )
end

--- [SERVER]
---
--- Mounts a filesystem folder at the given URL path.
---
---@param path string The URL path prefix.
---@param folder string The filesystem folder to serve.
function Server:mount( path, folder )
    local state = require_state( self )
    state.handle:SetMountPoint( path, folder )
    schedule_restart( state )
end

--- [SERVER]
---
--- Removes every mount previously set for `path`.
---
---@param path string The URL path prefix to unmount.
function Server:unmount( path )
    local state = require_state( self )
    state.handle:RemoveMountPoint( path )
    schedule_restart( state )
end

--- [SERVER]
---
--- Configures the worker thread pool size.
---
--- The pool is created on start, a running server restarts on the next frame.
---
---@param min_threads integer Minimum number of worker threads.
---@param max_threads integer Maximum number of worker threads.
function Server:setThreads( min_threads, max_threads )
    local state = require_state( self )
    state.handle:SetThreads( min_threads, max_threads )
    schedule_restart( state )
end

--- [SERVER]
---
--- Trusts `proxy_address` as a reverse proxy and reads the client IP from `header_name`.
---
---@param proxy_address string The remote address of the trusted proxy.
---@param header_name string Header that carries the real client IP, e.g. `"X-Forwarded-For"`.
---@param use_last_ip boolean? Prefer the last IP in a comma-separated header. Defaults to `false`.
function Server:addProxy( proxy_address, header_name, use_last_ip )
    require_state( self ).handle:AddProxyAddress( proxy_address, header_name, use_last_ip == true )
end

--- [SERVER]
---
--- Queues a prepared response for the next matching request from the given player `user_id`.
---
--- `handler` runs immediately to fill the response, matching requests are then answered
--- on the worker thread without any Lua call. The response is invalid after `handler` returns.
---
---@param user_id integer The player's UserID (`-1` for non-player / unmatched clients).
---@param path string Exact request path to match.
---@param method dreamwork.std.http.RequestMethod | string Exact HTTP method to match.
---@param required_headers table<string, string> Headers that must be present with these values.
---@param handler fun( response: dreamwork.std.http.Server.Response ) Fills the prepared response.
---@param uses integer? How many times this entry may match. Defaults to `1`.
function Server:prepare( user_id, path, method, required_headers, handler, uses )
    require_state( self ).handle:AddPreparedResponse( user_id, path, string_upper( method ), required_headers, function( raw_response )
        ---@type dreamwork.std.http.Server.Exchange
        local exchange = {
            raw = raw_response,
        }

        exceptions_call( handler, ResponseClass( exchange ) )

        -- HolyLib frees the response after this callback
        exchange.raw = nil
    end, uses )
end

--- [SERVER]
---
--- The class used to create new `http.Server` instances.
---
--- Requires HolyLib's `httpserver` module.
---
---@class dreamwork.std.http.ServerClass : dreamwork.std.http.Server, dreamwork.std.Class
---@field __base dreamwork.std.http.Server
---@field available boolean `true` when HolyLib's `httpserver` module is loaded.
---@overload fun( name: string? ): dreamwork.std.http.Server
local ServerClass = class.create( Server )
ServerClass.Request = RequestClass
ServerClass.Response = ResponseClass
ServerClass.available = httpserver_available

--- [SERVER]
---
--- Finds an existing server by its `name` property.
---
--- Returns a dreamwork wrapper around the HolyLib object, or `nil` if none matched.
--- Wrappers of servers created elsewhere (e.g. before a reload) do not destroy them when collected.
---
---@param name string The server name to look for.
---@return dreamwork.std.http.Server | nil server
function ServerClass.findByName( name )
    if not httpserver_available then
        error( "http.Server requires HolyLib's httpserver module", 2 )
    end

    local handle = httpserver_FindByName( name )
    if handle == nil then
        return nil
    end

    return wrap_handle( handle )
end

--- [SERVER]
---
--- Returns every currently existing HolyLib `HttpServer` wrapped as `http.Server` objects.
---
--- Wrappers of servers created elsewhere do not destroy them when collected.
---
---@return dreamwork.std.http.Server[] servers
function ServerClass.getAll()
    if not httpserver_available then
        error( "http.Server requires HolyLib's httpserver module", 2 )
    end

    local handles = httpserver_GetAll()

    ---@type dreamwork.std.http.Server[]
    local result = {}

    for i = 1, #handles, 1 do
        result[ i ] = wrap_handle( handles[ i ] )
    end

    return result
end

http.Server = ServerClass
