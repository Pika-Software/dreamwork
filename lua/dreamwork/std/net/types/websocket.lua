local dreamwork_Logger = dreamwork.Logger

local dreamwork_exceptions = dreamwork.exceptions
local exceptions_call = dreamwork_exceptions.call

local dreamwork_engine = dreamwork.engine
local engine_websocket = dreamwork_engine.websocket

local websocket_create = engine_websocket.create
local websocket_open = engine_websocket.open
local websocket_write = engine_websocket.write
local websocket_close = engine_websocket.close

---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local gc = std.gc
local gc_setTableRules = gc.setTableRules

local raw = std.raw
local raw_index = raw.index
local raw_tostring = raw.tostring
local raw_pairs = raw.pairs

local math = std.math
local math_min = math.min
local math_huge = math.huge

local string = std.string
local string_lower = string.lower
local string_format = string.format

local type = std.type
local error = std.error
local pcall = std.pcall
local isString = std.isString

local setTimeout = std.setTimeout
local clearTimeout = std.clearTimeout

local ValueError = std.ValueError
local TypeError = std.TypeError
local Emitter = std.Emitter
local URL = std.URL


---@alias dreamwork.std.WebSocket.Status
---| "connecting" # Handshake in progress.
---| "open" # Connected, ready to send / receive.
---| "closing" # Close requested, waiting for the peer / flush.
---| "closed" # Not connected.

local STATUS_CONNECTING = 0
local STATUS_OPEN = 1
local STATUS_CLOSING = 2
local STATUS_CLOSED = 3

---@type table<integer, dreamwork.std.WebSocket.Status>
local status_names = {
    [ STATUS_CONNECTING ] = "connecting",
    [ STATUS_OPEN ] = "open",
    [ STATUS_CLOSING ] = "closing",
    [ STATUS_CLOSED ] = "closed"
}

--- Seconds a graceful close may take before the socket is terminated.
local DEFAULT_CLOSE_TIMEOUT = 5

--- Default first reconnect delay and its upper bound, in seconds.
local DEFAULT_RECONNECT_DELAY = 1
local DEFAULT_RECONNECT_MAX_DELAY = 30


--- One backend connection, created by every `open` (manual or reconnect).
---
--- Backend callbacks capture their own connection and are ignored once the socket
--- moved on to a newer one, so late callbacks of a replaced handle cannot touch it.
---
---@class dreamwork.std.WebSocket.Connection
---@field status integer `STATUS_CONNECTING` / `STATUS_OPEN` / `STATUS_CLOSING` / `STATUS_CLOSED`.
---@field handle dreamwork.engine.websocket.Handle | nil The backend handle, `nil` once closed.
---@field errored boolean `true` once the backend reported an error on this connection.
---@field manual boolean `true` once the close was requested locally, disables reconnecting.
---@field close_timeout integer | nil The pending graceful close timeout.
---@field reason string | nil Close reason, set when closed.
---@field code integer | nil Close code, set when closed.

---@type table<dreamwork.std.WebSocket, string>
local urls = {}
gc_setTableRules( urls, true, false )

---@type table<dreamwork.std.WebSocket, dreamwork.std.WebSocket.Options>
local options_by_socket = {}
gc_setTableRules( options_by_socket, true, false )

--- The current (or last) connection of every socket.
---
---@type table<dreamwork.std.WebSocket, dreamwork.std.WebSocket.Connection>
local connections = {}
gc_setTableRules( connections, true, false )

--- Failed reconnect attempts in a row, reset by a successful handshake or a manual `open`.
---
---@type table<dreamwork.std.WebSocket, integer>
local reconnect_attempts = {}
gc_setTableRules( reconnect_attempts, true, false )

--- Pending reconnect timeouts.
---
---@type table<dreamwork.std.WebSocket, integer>
local reconnect_timeouts = {}
gc_setTableRules( reconnect_timeouts, true, false )

--- Per-socket event listeners.
---
---@type dreamwork.std.Emitter
local events = Emitter( "WebSocket" )

---@type table<dreamwork.std.WebSocket.Event, boolean>
local event_names = {
    open = true,
    message = true,
    close = true,
    error = true,
    reconnect = true
}

--- Throws unless `event` is a known WebSocket event, the error points at the method's caller.
---
---@param event any
local function check_event( event )
    if not event_names[ event ] then
        error( string_format( "unknown WebSocket event '%s'", raw_tostring( event ) ), 3 )
    end
end

--- Returns the internal integer status of the socket.
---
---@param socket dreamwork.std.WebSocket The socket to inspect.
---@return integer status `STATUS_CONNECTING` / `STATUS_OPEN` / `STATUS_CLOSING` / `STATUS_CLOSED`.
local function get_status( socket )
    local connection = connections[ socket ]
    if connection == nil then
        return STATUS_CLOSED
    end

    return connection.status
end

--- Cancels a pending reconnect of the socket.
---
---@param socket dreamwork.std.WebSocket
local function cancel_reconnect( socket )
    local timeout_id = reconnect_timeouts[ socket ]
    if timeout_id ~= nil then
        reconnect_timeouts[ socket ] = nil
        clearTimeout( timeout_id )
    end
end

local connect, terminate

--- Fires the `"error"` event, logs the error when nobody listens.
---
---@param socket dreamwork.std.WebSocket The socket that failed.
---@param message string The error message.
local function emit_error( socket, message )
    if events:count( socket, "error" ) == 0 then
        dreamwork_Logger:warn( "WebSocket '%s' error: %s", urls[ socket ], raw_tostring( message ) )
        return
    end

    events:emit( socket, "error", socket, message )
end

--- Schedules the next reconnect attempt, if reconnecting is enabled and attempts are left.
---
---@param socket dreamwork.std.WebSocket
local function schedule_reconnect( socket )
    local reconnect = options_by_socket[ socket ].reconnect
    if reconnect == nil then return end

    local attempt = (reconnect_attempts[ socket ] or 0) + 1
    if attempt > reconnect.attempts then
        reconnect_attempts[ socket ] = nil
        return
    end

    reconnect_attempts[ socket ] = attempt

    local delay = math_min( reconnect.delay * 2 ^ (attempt - 1), reconnect.max_delay )

    reconnect_timeouts[ socket ] = setTimeout( function()
        reconnect_timeouts[ socket ] = nil

        local ok, err = connect( socket )
        if not ok then
            emit_error( socket, raw_tostring( err ) )
            schedule_reconnect( socket )
        end
    end, delay )

    events:emit( socket, "reconnect", socket, attempt, delay )
end

--- Marks the connection open and fires the `"open"` event.
---
---@param socket dreamwork.std.WebSocket
---@param connection dreamwork.std.WebSocket.Connection
local function on_open( socket, connection )
    if connections[ socket ] ~= connection or connection.status ~= STATUS_CONNECTING then
        return
    end

    connection.status = STATUS_OPEN
    reconnect_attempts[ socket ] = nil

    events:emit( socket, "open", socket )
end

--- Fires the `"message"` event, also while a graceful close is in progress.
---
---@param socket dreamwork.std.WebSocket
---@param connection dreamwork.std.WebSocket.Connection
---@param message string The received payload.
local function on_message( socket, connection, message )
    if connections[ socket ] ~= connection then return end

    local status = connection.status
    if status == STATUS_OPEN or status == STATUS_CLOSING then
        events:emit( socket, "message", socket, message )
    end
end

--- Marks the connection closed, fires the `"close"` event and reconnects when enabled.
---
---@param socket dreamwork.std.WebSocket
---@param connection dreamwork.std.WebSocket.Connection
---@param reason string | nil Close reason from the peer or the local side.
---@param code integer | nil WebSocket close code, when the backend provides one.
---@param errored boolean | nil `true` when the close followed a transport error.
local function on_close( socket, connection, reason, code, errored )
    if connections[ socket ] ~= connection or connection.status == STATUS_CLOSED then
        return
    end

    connection.status = STATUS_CLOSED
    connection.handle = nil

    local close_timeout = connection.close_timeout
    if close_timeout ~= nil then
        connection.close_timeout = nil
        clearTimeout( close_timeout )
    end

    errored = errored == true or connection.errored
    connection.errored = errored
    connection.reason = reason
    connection.code = code

    events:emit( socket, "close", socket, reason, code, errored )

    -- a handler may have called `open` or `close` meanwhile
    if not connection.manual and connections[ socket ] == connection and reconnect_timeouts[ socket ] == nil then
        schedule_reconnect( socket )
    end
end

--- Records the error, fires `"error"`, and treats an error during the handshake as a failed connection.
---
---@param socket dreamwork.std.WebSocket
---@param connection dreamwork.std.WebSocket.Connection
---@param message string The error message from the backend.
local function on_error( socket, connection, message )
    if connections[ socket ] ~= connection or connection.status == STATUS_CLOSED then
        return
    end

    connection.errored = true
    emit_error( socket, message )

    -- not every backend reports a close after a failed handshake
    if connections[ socket ] == connection and connection.status == STATUS_CONNECTING then
        terminate( socket, connection, message, 1006, true )
    end
end

--- Immediately closes the backend handle and fires `"close"`.
---
---@param socket dreamwork.std.WebSocket
---@param connection dreamwork.std.WebSocket.Connection
---@param reason string
---@param code integer
---@param errored boolean
function terminate( socket, connection, reason, code, errored )
    local handle = connection.handle
    if handle ~= nil then
        connection.handle = nil
        -- the handle is dropped either way, a backend refusing to close a failed socket is not an error
        pcall( websocket_close, handle, true )
    end

    on_close( socket, connection, reason, code, errored )
end

--- Creates a new connection for the socket and starts the handshake.
---
---@param socket dreamwork.std.WebSocket
---@return boolean ok `false` if the backend failed to create or open the socket.
---@return any err The backend error when `ok` is `false`.
function connect( socket )
    local options = options_by_socket[ socket ]

    ---@type table<string, string> | nil
    local headers = options.headers

    local cookies = options.cookies
    if cookies ~= nil then
        local header_value = cookies:header( urls[ socket ] )
        if header_value ~= nil then
            ---@type table<string, string>
            local merged = {}

            ---@type string | nil
            local cookie_name

            if headers ~= nil then
                for name, value in raw_pairs( headers ) do
                    if isString( name ) and isString( value ) then
                        merged[ name ] = value
                        if string_lower( name ) == "cookie" then
                            cookie_name = name
                        end
                    end
                end
            end

            if cookie_name == nil then
                merged.Cookie = header_value
            else
                merged[ cookie_name ] = merged[ cookie_name ] .. "; " .. header_value
            end

            headers = merged
        end
    end

    ---@type dreamwork.std.WebSocket.Connection
    local connection = {
        status = STATUS_CONNECTING,
        errored = false,
        manual = false
    }

    connections[ socket ] = connection

    ---@type dreamwork.engine.websocket.Options
    local engine_options = {
        headers = headers,
        verify_certificate = options.verify_certificate,
        compression = options.compression,
        on_open = function()
            on_open( socket, connection )
        end,
        on_message = function( message )
            on_message( socket, connection, message )
        end,
        on_error = function( message )
            on_error( socket, connection, message )
        end,
        on_close = function( reason, code, errored )
            on_close( socket, connection, reason, code, errored )
        end
    }

    local ok, handle = pcall( websocket_create, urls[ socket ], engine_options )
    if not ok or handle == nil then
        connection.status = STATUS_CLOSED
        return false, handle or "failed to create WebSocket backend"
    end

    connection.handle = handle

    local err
    ok, err = pcall( websocket_open, handle )
    if not ok then
        connection.handle = nil
        connection.status = STATUS_CLOSED
        pcall( websocket_close, handle, true )
        return false, err
    end

    return true
end

--- [SHARED AND MENU]
---
--- Automatic reconnect settings, the delay doubles after every failed attempt.
---
---@class dreamwork.std.WebSocket.ReconnectOptions
---@field delay number | nil Seconds before the first attempt. Defaults to `1`.
---@field max_delay number | nil Upper bound of the delay in seconds. Defaults to `30`.
---@field attempts integer | nil Attempts in a row before giving up. Defaults to unlimited.

--- [SHARED AND MENU]
---
--- Options applied when the socket is opened.
---
--- Headers, cookies, compression and `verify_certificate` are only used when the
--- backend supports them, see `WebSocket.Capabilities`.
---
---@class dreamwork.std.WebSocket.Options
---@field headers table<string, string> | nil Extra handshake headers (`Capabilities.headers`).
---@field cookies dreamwork.std.http.CookieJar | nil Cookie jar; matching cookies are sent in the `Cookie` header (`Capabilities.headers`).
---@field verify_certificate boolean | nil Verify the TLS certificate (`Capabilities.verify_certificate`). Defaults to `true`.
---@field compression boolean | nil Negotiate `permessage-deflate` (`Capabilities.compression`).
---@field reconnect boolean | dreamwork.std.WebSocket.ReconnectOptions | nil Reconnect after the connection is lost or fails, `true` uses the defaults. Never after a local `close`.
---@field close_timeout number | nil Seconds a graceful close may take before the socket is terminated. Defaults to `5`.


--- [SHARED AND MENU]
---
--- A WebSocket client. Backends are tried in order: `gwsockets`, `tungstenite`, then a
--- `std.WebClient` / browser fallback on client and menu.
---
--- A socket stays alive while it is connecting, open or waiting for a reconnect,
--- even without references to it, call `close` to release it.
---
---@class dreamwork.std.WebSocket : dreamwork.std.Object
---@field __class dreamwork.std.WebSocketClass
---@field url string The WebSocket URL. **Read-only.**
local WebSocket = class.base( "WebSocket", false, nil )

---@param key string The field name being read.
---@return any value
---@protected
function WebSocket:__index( key )
    if key == "url" then
        return urls[ self ]
    end

    return raw_index( WebSocket, key )
end

---@param key string
---@protected
function WebSocket:__newindex( key )
    error( string_format( "attempt to modify read-only WebSocket property '%s'", raw_tostring( key ) ), 2 )
end

---@return string representation
---@protected
function WebSocket:__represent()
    return string_format( "%s: %p [%s][%s]", type( self ), self, urls[ self ] or "?", status_names[ get_status( self ) ] )
end

---@param url string | dreamwork.std.URL The `ws://` or `wss://` URL to connect to.
---@param options dreamwork.std.WebSocket.Options | nil Optional connection options.
---@protected
function WebSocket:__init( url, options )
    ---@type dreamwork.std.URL
    local url_object

    if isString( url ) then
        ---@cast url string
        url_object = URL( url )
    else
        ---@cast url dreamwork.std.URL
        url_object = url
    end

    local protocol = string_lower( url_object.protocol or "" )
    if protocol ~= "ws:" and protocol ~= "wss:" then
        error( ValueError( url, string_format( "WebSocket URL must use ws:// or wss://, got '%s'", url_object.protocol or "?" ) ), 2 )
    end

    -- credentials and fragment are never part of the sent url;
    -- empty path becomes "/" so backends and browsers accept the URL
    local pathname = url_object.pathname
    if pathname == "" then
        pathname = "/"
    end

    local url_string = string_format( "%s//%s%s%s", url_object.protocol, url_object.host, pathname, url_object.search )

    ---@type dreamwork.std.WebSocket.Options
    local ws_options = {
        close_timeout = DEFAULT_CLOSE_TIMEOUT
    }

    if options ~= nil then
        ws_options.headers = options.headers
        ws_options.cookies = options.cookies
        ws_options.compression = options.compression
        ws_options.verify_certificate = options.verify_certificate
        ws_options.close_timeout = options.close_timeout or DEFAULT_CLOSE_TIMEOUT

        local reconnect = options.reconnect
        if reconnect == true then
            ws_options.reconnect = {
                delay = DEFAULT_RECONNECT_DELAY,
                max_delay = DEFAULT_RECONNECT_MAX_DELAY,
                attempts = math_huge
            }
        elseif reconnect then
            ---@cast reconnect dreamwork.std.WebSocket.ReconnectOptions
            ws_options.reconnect = {
                delay = reconnect.delay or DEFAULT_RECONNECT_DELAY,
                max_delay = reconnect.max_delay or DEFAULT_RECONNECT_MAX_DELAY,
                attempts = reconnect.attempts or math_huge
            }
        end
    end

    urls[ self ] = url_string
    options_by_socket[ self ] = ws_options
end

--- [SHARED AND MENU]
---
--- Opens the connection, cancelling a pending reconnect and resetting its attempt counter.
---
--- Throws if the socket is already connecting, open or closing, or if the backend fails to create the socket.
---
function WebSocket:open()
    if get_status( self ) ~= STATUS_CLOSED then
        error( "WebSocket is already open or connecting", 2 )
    end

    if engine_websocket.BackendName == "" then
        error( "no WebSocket backend is available", 2 )
    end

    cancel_reconnect( self )
    reconnect_attempts[ self ] = nil

    local ok, err = connect( self )
    if not ok then
        error( err, 2 )
    end
end

--- [SHARED AND MENU]
---
--- Sends a message. Binary frames need `Capabilities.binary`, otherwise the payload is sent as text.
---
---@param message string The payload to send.
---@param is_binary boolean? Send as a binary frame. Defaults to `false`.
function WebSocket:send( message, is_binary )
    if not isString( message ) then
        error( TypeError( 1, message, "string", "message", "WebSocket:send" ), 2 )
    end

    local connection = connections[ self ]
    if connection == nil or connection.status ~= STATUS_OPEN then
        error( "WebSocket is not open", 2 )
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    websocket_write( connection.handle, message, is_binary == true )
end

--- [SHARED AND MENU]
---
--- Alias of `WebSocket:send`.
---
---@param message string The payload to send.
---@param is_binary boolean? Send as a binary frame. Defaults to `false`.
function WebSocket:write( message, is_binary )
    return self:send( message, is_binary )
end

--- [SHARED AND MENU]
---
--- Closes the connection and cancels a pending reconnect; a locally closed socket never reconnects.
---
--- With `force`, terminates immediately (code `1006`) and discards queued outbound messages
--- when possible; otherwise flushes first when the backend supports it, and terminates
--- when the peer does not finish the close within `close_timeout` seconds.
---
---@param force boolean? Immediately terminate instead of a graceful close. Defaults to `false`.
function WebSocket:close( force )
    cancel_reconnect( self )
    reconnect_attempts[ self ] = nil

    local connection = connections[ self ]
    if connection == nil then return end

    connection.manual = true

    local status = connection.status
    if status == STATUS_CLOSED then return end

    if force == true then
        terminate( self, connection, "closed by user", 1006, false )
        return
    end

    if status == STATUS_CLOSING then return end

    connection.status = STATUS_CLOSING

    local handle = connection.handle
    if handle == nil or not exceptions_call( websocket_close, handle, false ) then
        terminate( self, connection, "closed by user", 1006, false )
        return
    end

    -- the backend may already have reported the close
    if connection.status ~= STATUS_CLOSING then return end

    connection.close_timeout = setTimeout( function()
        connection.close_timeout = nil

        if connection.status == STATUS_CLOSING then
            terminate( self, connection, "close timed out", 1006, false )
        end
    end, options_by_socket[ self ].close_timeout )
end

--- [SHARED AND MENU]
---
--- Returns the current connection status as a string.
---
---@return dreamwork.std.WebSocket.Status status `"connecting"`, `"open"`, `"closing"` or `"closed"`.
---@nodiscard
function WebSocket:getStatus()
    return status_names[ get_status( self ) ]
end

--- [SHARED AND MENU]
---
--- Returns `true` while the handshake is in progress.
---
---@return boolean is_connecting `true` if status is `"connecting"`.
---@nodiscard
function WebSocket:isConnecting()
    return get_status( self ) == STATUS_CONNECTING
end

--- [SHARED AND MENU]
---
--- Returns `true` when the socket is open and ready to send / receive.
---
---@return boolean is_open `true` if status is `"open"`.
---@nodiscard
function WebSocket:isOpen()
    return get_status( self ) == STATUS_OPEN
end

--- [SHARED AND MENU]
---
--- Alias of `WebSocket:isOpen`.
---
---@return boolean is_connected `true` if status is `"open"`.
---@nodiscard
function WebSocket:isConnected()
    return get_status( self ) == STATUS_OPEN
end

--- [SHARED AND MENU]
---
--- Returns `true` while a graceful close is in progress.
---
---@return boolean is_closing `true` if status is `"closing"`.
---@nodiscard
function WebSocket:isClosing()
    return get_status( self ) == STATUS_CLOSING
end

--- [SHARED AND MENU]
---
--- Returns `true` when the socket is not connected, also while waiting for a reconnect.
---
---@return boolean is_closed `true` if status is `"closed"`.
---@nodiscard
function WebSocket:isClosed()
    return get_status( self ) == STATUS_CLOSED
end

--- [SHARED AND MENU]
---
--- Returns `true` while a reconnect attempt is scheduled.
---
---@return boolean is_reconnecting
---@nodiscard
function WebSocket:isReconnecting()
    return reconnect_timeouts[ self ] ~= nil
end

---@alias dreamwork.std.WebSocket.Event
---| "open" # Handshake succeeded.
---| "message" # A text / binary frame was received.
---| "close" # The connection ended.
---| "error" # A transport / protocol error occurred.
---| "reconnect" # A reconnect attempt was scheduled.

--- Called when the handshake succeeds.
---
---@alias dreamwork.std.WebSocket.OpenHandler fun( socket: dreamwork.std.WebSocket )

--- Called for every received frame.
---
---@alias dreamwork.std.WebSocket.MessageHandler fun( socket: dreamwork.std.WebSocket, message: string )

--- Called when the connection ends.
---
---@alias dreamwork.std.WebSocket.CloseHandler fun( socket: dreamwork.std.WebSocket, reason: string | nil, code: integer | nil, errored: boolean )

--- Called when a transport / protocol error occurs.
---
--- Without any `"error"` handler the error is logged instead.
---
---@alias dreamwork.std.WebSocket.ErrorHandler fun( socket: dreamwork.std.WebSocket, message: string )

--- Called when a reconnect attempt is scheduled, `delay` seconds before it starts.
---
---@alias dreamwork.std.WebSocket.ReconnectHandler fun( socket: dreamwork.std.WebSocket, attempt: integer, delay: number )

--- [SHARED AND MENU]
---
--- Attaches a handler for the given event.
---
---@param event dreamwork.std.WebSocket.Event The event to listen to: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@param handler function The callback; signature depends on `event` (see overloads).
---@overload fun( self: dreamwork.std.WebSocket, event: "open", handler: dreamwork.std.WebSocket.OpenHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "message", handler: dreamwork.std.WebSocket.MessageHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "close", handler: dreamwork.std.WebSocket.CloseHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "error", handler: dreamwork.std.WebSocket.ErrorHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "reconnect", handler: dreamwork.std.WebSocket.ReconnectHandler )
function WebSocket:attach( event, handler )
    check_event( event )
    events:attach( self, event, handler )
end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler for the given event.
---
--- The handler is detached automatically right before it runs.
---
---@param event dreamwork.std.WebSocket.Event The event to listen to: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@param handler function The callback; signature depends on `event` (see overloads).
---@overload fun( self: dreamwork.std.WebSocket, event: "open", handler: dreamwork.std.WebSocket.OpenHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "message", handler: dreamwork.std.WebSocket.MessageHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "close", handler: dreamwork.std.WebSocket.CloseHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "error", handler: dreamwork.std.WebSocket.ErrorHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "reconnect", handler: dreamwork.std.WebSocket.ReconnectHandler )
function WebSocket:once( event, handler )
    check_event( event )
    events:once( self, event, handler )
end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given event.
---
---@param event dreamwork.std.WebSocket.Event The event the handler was attached to.
---@param handler function The exact callback previously passed to `attach` or `once`.
---@overload fun( self: dreamwork.std.WebSocket, event: "open", handler: dreamwork.std.WebSocket.OpenHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "message", handler: dreamwork.std.WebSocket.MessageHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "close", handler: dreamwork.std.WebSocket.CloseHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "error", handler: dreamwork.std.WebSocket.ErrorHandler )
---@overload fun( self: dreamwork.std.WebSocket, event: "reconnect", handler: dreamwork.std.WebSocket.ReconnectHandler )
function WebSocket:detach( event, handler )
    check_event( event )
    events:detach( self, event, handler )
end

--- [SHARED AND MENU]
---
--- Removes every handler for `event`, or every handler of every event when omitted.
---
---@param event dreamwork.std.WebSocket.Event? The event to clear, or `nil` to clear all events.
function WebSocket:clear( event )
    if event ~= nil then
        check_event( event )
    end

    events:clear( self, event )
end

--- [SHARED AND MENU]
---
--- Waits until the given event fires, then resumes with that event's arguments.
---
--- * `"open"` returns at once when the socket is already open;
--- * `"close"` returns the last close at once when the socket is closed and no reconnect is pending;
--- * anything else throws when the socket is closed with no reconnect pending,
---   or when the socket closes first (a failed reconnect attempt counts as a close).
---
---@param event dreamwork.std.WebSocket.Event The event to wait for: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@return any ... The arguments that event's handlers receive.
---@async
---@overload fun( self: dreamwork.std.WebSocket, event: "open" ): dreamwork.std.WebSocket
---@overload fun( self: dreamwork.std.WebSocket, event: "message" ): dreamwork.std.WebSocket, string
---@overload fun( self: dreamwork.std.WebSocket, event: "close" ): dreamwork.std.WebSocket, string | nil, integer | nil, boolean
---@overload fun( self: dreamwork.std.WebSocket, event: "error" ): dreamwork.std.WebSocket, string
---@overload fun( self: dreamwork.std.WebSocket, event: "reconnect" ): dreamwork.std.WebSocket, integer, number
function WebSocket:await( event )
    check_event( event )

    local status = get_status( self )
    local idle = status == STATUS_CLOSED and reconnect_timeouts[ self ] == nil

    if event == "close" then
        if idle then
            local connection = connections[ self ]
            if connection == nil then
                return self, nil, nil, false
            end

            return self, connection.reason, connection.code, connection.errored
        end

        return events:await( self, "close" )
    end

    if event == "open" and status == STATUS_OPEN then
        return self
    end

    if idle then
        error( string_format( "WebSocket is closed, cannot await '%s'", event ), 2 )
    end

    return events:await( self, event, "close", string_format( "WebSocket was closed while awaiting '%s'", event ) )
end

--- [SHARED AND MENU]
---
--- The class used to create new `WebSocket` instances.
---
--- Prefer attaching handlers before calling `open`.
---
--- ```lua
--- local ws = std.WebSocket( "wss://echo.websocket.events/", { reconnect = true } )
---
--- ws:attach( "open", function( socket )
---     socket:send( "hello" )
--- end )
---
--- ws:attach( "message", function( socket, message )
---     print( message )
--- end )
---
--- ws:open()
--- ```
---
---@class dreamwork.std.WebSocketClass : dreamwork.std.WebSocket, dreamwork.std.Class
---@field __base dreamwork.std.WebSocket
---@field BackendName "tungstenite" | "gwsockets" | "webclient" | "" The loaded WebSocket backend, empty if none was found.
---@field Capabilities dreamwork.engine.websocket.Capabilities Features supported by the loaded backend. **Read-only.**
---@overload fun( url: string | dreamwork.std.URL, options: dreamwork.std.WebSocket.Options? ): dreamwork.std.WebSocket
local WebSocketClass = class.create( WebSocket )
WebSocketClass.BackendName = engine_websocket.BackendName
WebSocketClass.Capabilities = engine_websocket.Capabilities
std.WebSocket = WebSocketClass
