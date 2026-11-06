---@meta _

---@alias WebSocket.Status
---| "connecting" # Handshake in progress.
---| "open" # Connected, ready to send / receive.
---| "closing" # Close requested, waiting for the peer / flush.
---| "closed" # Not connected.

--- One backend connection, created by every `open` (manual or reconnect).
---
--- Backend callbacks capture their own connection and are ignored once the socket
--- moved on to a newer one, so late callbacks of a replaced handle cannot touch it.
---
---@class WebSocket.Connection
---@field status integer `STATUS_CONNECTING` / `STATUS_OPEN` / `STATUS_CLOSING` / `STATUS_CLOSED`.
---@field handle dreamwork.engine.websocket.Handle | nil The backend handle, `nil` once closed.
---@field errored boolean `true` once the backend reported an error on this connection.
---@field manual boolean `true` once the close was requested locally, disables reconnecting.
---@field close_timeout integer | nil The pending graceful close timeout.
---@field reason string | nil Close reason, set when closed.
---@field code integer | nil Close code, set when closed.

--- [SHARED AND MENU]
---
--- Automatic reconnect settings, the delay doubles after every failed attempt.
---
---@class WebSocket.ReconnectOptions
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
---@class WebSocket.Options
---@field headers table<string, string> | nil Extra handshake headers (`Capabilities.headers`).
---@field cookies http.CookieJar | nil Cookie jar; matching cookies are sent in the `Cookie` header (`Capabilities.headers`).
---@field verify_certificate boolean | nil Verify the TLS certificate (`Capabilities.verify_certificate`). Defaults to `true`.
---@field compression boolean | nil Negotiate `permessage-deflate` (`Capabilities.compression`).
---@field reconnect boolean | WebSocket.ReconnectOptions | nil Reconnect after the connection is lost or fails, `true` uses the defaults. Never after a local `close`.
---@field close_timeout number | nil Seconds a graceful close may take before the socket is terminated. Defaults to `5`.

--- [SHARED AND MENU]
---
--- A WebSocket client. Backends are tried in order: `gwsockets`, `tungstenite`, then a
--- `WebClient` / browser fallback on client and menu.
---
--- A socket stays alive while it is connecting, open or waiting for a reconnect,
--- even without references to it, call `close` to release it.
---
---@class WebSocket : Object
---@field __class WebSocketClass
---@field url string The WebSocket URL. **Read-only.**
local __WebSocket = {}

---@param key string The field name being read.
---@return any value
---@protected
function __WebSocket:__index(key) end

---@param key string
---@protected
function __WebSocket:__newindex(key) end

---@return string representation
---@protected
function __WebSocket:__represent() end

---@param url string | URL The `ws://` or `wss://` URL to connect to.
---@param options WebSocket.Options | nil Optional connection options.
---@protected
function __WebSocket:__init(url, options) end

--- [SHARED AND MENU]
---
--- Opens the connection, cancelling a pending reconnect and resetting its attempt counter.
---
--- Throws if the socket is already connecting, open or closing, or if the backend fails to create the socket.
---
function __WebSocket:open() end

--- [SHARED AND MENU]
---
--- Sends a message. Binary frames need `Capabilities.binary`, otherwise the payload is sent as text.
---
---@param message string The payload to send.
---@param is_binary boolean? Send as a binary frame. Defaults to `false`.
function __WebSocket:send(message, is_binary) end

--- [SHARED AND MENU]
---
--- Alias of `WebSocket:send`.
---
---@param message string The payload to send.
---@param is_binary boolean? Send as a binary frame. Defaults to `false`.
function __WebSocket:write(message, is_binary) end

--- [SHARED AND MENU]
---
--- Closes the connection and cancels a pending reconnect; a locally closed socket never reconnects.
---
--- With `force`, terminates immediately (code `1006`) and discards queued outbound messages
--- when possible; otherwise flushes first when the backend supports it, and terminates
--- when the peer does not finish the close within `close_timeout` seconds.
---
---@param force boolean? Immediately terminate instead of a graceful close. Defaults to `false`.
function __WebSocket:close(force) end

--- [SHARED AND MENU]
---
--- Returns the current connection status as a string.
---
---@return WebSocket.Status status `"connecting"`, `"open"`, `"closing"` or `"closed"`.
---@nodiscard
function __WebSocket:getStatus() end

--- [SHARED AND MENU]
---
--- Returns `true` while the handshake is in progress.
---
---@return boolean is_connecting `true` if status is `"connecting"`.
---@nodiscard
function __WebSocket:isConnecting() end

--- [SHARED AND MENU]
---
--- Returns `true` when the socket is open and ready to send / receive.
---
---@return boolean is_open `true` if status is `"open"`.
---@nodiscard
function __WebSocket:isOpen() end

--- [SHARED AND MENU]
---
--- Alias of `WebSocket:isOpen`.
---
---@return boolean is_connected `true` if status is `"open"`.
---@nodiscard
function __WebSocket:isConnected() end

--- [SHARED AND MENU]
---
--- Returns `true` while a graceful close is in progress.
---
---@return boolean is_closing `true` if status is `"closing"`.
---@nodiscard
function __WebSocket:isClosing() end

--- [SHARED AND MENU]
---
--- Returns `true` when the socket is not connected, also while waiting for a reconnect.
---
---@return boolean is_closed `true` if status is `"closed"`.
---@nodiscard
function __WebSocket:isClosed() end

--- [SHARED AND MENU]
---
--- Returns `true` while a reconnect attempt is scheduled.
---
---@return boolean is_reconnecting
---@nodiscard
function __WebSocket:isReconnecting() end

---@alias WebSocket.Event
---| "open" # Handshake succeeded.
---| "message" # A text / binary frame was received.
---| "close" # The connection ended.
---| "error" # A transport / protocol error occurred.
---| "reconnect" # A reconnect attempt was scheduled.

--- Called when the handshake succeeds.
---
---@alias WebSocket.OpenHandler fun( socket: WebSocket )

--- Called for every received frame.
---
---@alias WebSocket.MessageHandler fun( socket: WebSocket, message: string )

--- Called when the connection ends.
---
---@alias WebSocket.CloseHandler fun( socket: WebSocket, reason: string | nil, code: integer | nil, errored: boolean )

--- Called when a transport / protocol error occurs.
---
--- Without any `"error"` handler the error is logged instead.
---
---@alias WebSocket.ErrorHandler fun( socket: WebSocket, message: string )

--- Called when a reconnect attempt is scheduled, `delay` seconds before it starts.
---
---@alias WebSocket.ReconnectHandler fun( socket: WebSocket, attempt: integer, delay: number )

--- [SHARED AND MENU]
---
--- Attaches a handler for the given event.
---
---@param event WebSocket.Event The event to listen to: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@param handler function The callback; signature depends on `event` (see overloads).
---@overload fun( self: WebSocket, event: "open", handler: WebSocket.OpenHandler )
---@overload fun( self: WebSocket, event: "message", handler: WebSocket.MessageHandler )
---@overload fun( self: WebSocket, event: "close", handler: WebSocket.CloseHandler )
---@overload fun( self: WebSocket, event: "error", handler: WebSocket.ErrorHandler )
---@overload fun( self: WebSocket, event: "reconnect", handler: WebSocket.ReconnectHandler )
function __WebSocket:attach(event, handler) end

--- [SHARED AND MENU]
---
--- Attaches a one-shot handler for the given event.
---
--- The handler is detached automatically right before it runs.
---
---@param event WebSocket.Event The event to listen to: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@param handler function The callback; signature depends on `event` (see overloads).
---@overload fun( self: WebSocket, event: "open", handler: WebSocket.OpenHandler )
---@overload fun( self: WebSocket, event: "message", handler: WebSocket.MessageHandler )
---@overload fun( self: WebSocket, event: "close", handler: WebSocket.CloseHandler )
---@overload fun( self: WebSocket, event: "error", handler: WebSocket.ErrorHandler )
---@overload fun( self: WebSocket, event: "reconnect", handler: WebSocket.ReconnectHandler )
function __WebSocket:once(event, handler) end

--- [SHARED AND MENU]
---
--- Detaches a previously attached handler from the given event.
---
---@param event WebSocket.Event The event the handler was attached to.
---@param handler function The exact callback previously passed to `attach` or `once`.
---@overload fun( self: WebSocket, event: "open", handler: WebSocket.OpenHandler )
---@overload fun( self: WebSocket, event: "message", handler: WebSocket.MessageHandler )
---@overload fun( self: WebSocket, event: "close", handler: WebSocket.CloseHandler )
---@overload fun( self: WebSocket, event: "error", handler: WebSocket.ErrorHandler )
---@overload fun( self: WebSocket, event: "reconnect", handler: WebSocket.ReconnectHandler )
function __WebSocket:detach(event, handler) end

--- [SHARED AND MENU]
---
--- Removes every handler for `event`, or every handler of every event when omitted.
---
---@param event WebSocket.Event? The event to clear, or `nil` to clear all events.
function __WebSocket:clear(event) end

--- [SHARED AND MENU]
---
--- Waits until the given event fires, then resumes with that event's arguments.
---
--- * `"open"` returns at once when the socket is already open;
--- * `"close"` returns the last close at once when the socket is closed and no reconnect is pending;
--- * anything else throws when the socket is closed with no reconnect pending,
---   or when the socket closes first (a failed reconnect attempt counts as a close).
---
---@param event WebSocket.Event The event to wait for: `"open"`, `"message"`, `"close"`, `"error"` or `"reconnect"`.
---@return any ... The arguments that event's handlers receive.
---@async
---@overload fun( self: WebSocket, event: "open" ): WebSocket
---@overload fun( self: WebSocket, event: "message" ): WebSocket, string
---@overload fun( self: WebSocket, event: "close" ): WebSocket, string | nil, integer | nil, boolean
---@overload fun( self: WebSocket, event: "error" ): WebSocket, string
---@overload fun( self: WebSocket, event: "reconnect" ): WebSocket, integer, number
function __WebSocket:await(event) end

--- [SHARED AND MENU]
---
--- The class used to create new `WebSocket` instances.
---
--- Prefer attaching handlers before calling `open`.
---
--- ```lua
--- local ws = WebSocket( "wss://echo.websocket.events/", { reconnect = true } )
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
---@class WebSocketClass : WebSocket, Class
---@field __base WebSocket
---@field BackendName "tungstenite" | "gwsockets" | "webclient" | "" The loaded WebSocket backend, empty if none was found.
---@field Capabilities dreamwork.engine.websocket.Capabilities Features supported by the loaded backend. **Read-only.**
---@overload fun( url: string | URL, options: WebSocket.Options? ): WebSocket
WebSocket = {}
