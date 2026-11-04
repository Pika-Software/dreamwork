---@meta gm_gwsockets


--- [SHARED AND MENU]
---
--- Native WebSocket instance from the [GWSockets](https://github.com/FredyH/GWSockets) binary module.
---
--- Created by `GWSockets.createWebSocket`. Callbacks are optional methods on the table:
--- `onConnected`, `onMessage`, `onError` and `onDisconnected`. They are invoked from a
--- zero-delay `"__GWSocketTimer"` timer on the main thread.
---
--- URL schemes `ws://`, `wss://`, `http://` and `https://` are accepted; missing ports default
--- to `80` / `443`. Headers, cookies and compression must be configured **before** `open`.
---
---@class gm_gwsockets.WebSocket
---@field onConnected nil | fun( self: gm_gwsockets.WebSocket, message: string ) Called once the handshake succeeds. `message` is currently unused / empty.
---@field onMessage nil | fun( self: gm_gwsockets.WebSocket, message: string ) Called for every text or binary frame; binary payloads are passed as a Lua string of raw bytes.
---@field onError nil | fun( self: gm_gwsockets.WebSocket, message: string ) Called when anything goes wrong; always followed by `onDisconnected`.
---@field onDisconnected nil | fun( self: gm_gwsockets.WebSocket, message: string ) Called when the socket closes (locally, remotely, or after an error). A non-graceful peer close may be reported only on the next write.
local WebSocket = {}

--- [SHARED AND MENU]
---
--- Opens the connection. Throws if the socket is already connecting or connected.
---
--- By default the outbound queue is cleared (`should_clear_queue = true`), because there is
--- no way to know what the peer already received from a previous attempt. Pass `false` to keep it.
---
--- While connecting / connected the Lua table is held by a reference so callbacks keep working
--- even if nothing else references the socket.
---
---@param should_clear_queue? boolean Clear the outbound queue before connecting. Defaults to `true`.
function WebSocket:open( should_clear_queue ) end

--- [SHARED AND MENU]
---
--- Queues `message` for sending. Frames are held until the socket is connected.
---
--- Prefer starting writes from `onConnected`. Setting `is_binary` to `true` sends a binary
--- WebSocket frame instead of a text frame.
---
---@param message string The payload to send.
---@param is_binary? boolean Send as a binary frame. Defaults to `false` (text).
function WebSocket:write( message, is_binary ) end

--- [SHARED AND MENU]
---
--- Gracefully closes the connection after the outbound queue has been flushed.
---
function WebSocket:close() end

--- [SHARED AND MENU]
---
--- Immediately terminates the connection and discards every queued outbound message.
---
function WebSocket:closeNow() end

--- [SHARED AND MENU]
---
--- Drops every queued outbound message without closing the socket.
---
function WebSocket:clearQueue() end

--- [SHARED AND MENU]
---
--- Adds a cookie to the opening handshake. Throws if the socket is already connected / connecting,
--- or if the name / value is rejected by the underlying HTTP cookie parser.
---
---@param key string Cookie name.
---@param value string Cookie value.
function WebSocket:setCookie( key, value ) end

--- [SHARED AND MENU]
---
--- Adds an HTTP header to the opening handshake. Throws if the socket is already connected /
--- connecting, or if the name / value is invalid.
---
---@param key string Header name.
---@param value string Header value.
function WebSocket:setHeader( key, value ) end

--- [SHARED AND MENU]
---
--- Requests the `permessage-deflate` extension. It is only used when the peer also enables it
--- during the handshake. Throws if the socket is already connected / connecting.
---
--- Enabling compression over `wss://` can weaken TLS against CRIME / BREACH-style attacks.
---
---@param enabled boolean Whether to negotiate message compression.
function WebSocket:setMessageCompression( enabled ) end

--- [SHARED AND MENU]
---
--- When compression is enabled, disables context takeover so each message starts a fresh
--- compression context (less memory, worse ratio). Throws if the socket is already connected / connecting.
---
---@param disabled boolean Whether to disable context takeover.
function WebSocket:setDisableContextTakeover( disabled ) end

--- [SHARED AND MENU]
---
--- Returns whether the underlying socket currently reports as connected.
--- Prefer the callbacks over polling this.
---
---@return boolean connected
---@nodiscard
function WebSocket:isConnected() end

--- [SHARED AND MENU]
---
--- WebSockets for GLua from the [GWSockets](https://github.com/FredyH/GWSockets) binary module
--- (`gmsv_gwsockets` / `gmcl_gwsockets`), built on Boost.Beast.
---
--- Available after `require( "gwsockets" )`. SSL root certificates come from the system store
--- (Windows) or OpenSSL default verify paths (Linux). Extra directories can be added with
--- `GWSockets.addVerifyPath`.
---
--- ```lua
--- require( "gwsockets" )
---
--- local socket = GWSockets.createWebSocket( "wss://echo.websocket.events/" )
---
--- function socket:onConnected()
---     socket:write( "hello" )
--- end
---
--- function socket:onMessage( message )
---     print( message )
--- end
---
--- socket:open()
--- ```
---
--- [View documents](https://github.com/FredyH/GWSockets)
---
---@class gm_gwsockets
GWSockets = {}

--- [SHARED AND MENU]
---
--- Creates a disconnected WebSocket for `url`.
---
--- The URL **must** include a scheme (`ws://` / `wss://`, `http://` / `https://` are also accepted).
--- Returns nothing and prints via `ErrorNoHalt` when the URL cannot be parsed.
---
--- When `verify_certificate` is `false`, TLS peers with untrusted certificates are accepted.
---
---@param url string The WebSocket URL, including the scheme.
---@param verify_certificate? boolean Verify the TLS certificate. Defaults to `true`.
---@return gm_gwsockets.WebSocket | nil socket The socket table, or `nil` if the URL was invalid.
function GWSockets.createWebSocket( url, verify_certificate ) end

--- [SHARED AND MENU]
---
--- Adds a directory of CA certificates used when verifying TLS peers.
--- Needed on some Linux distributions where OpenSSL's default path is wrong.
--- Failures are reported with `ErrorNoHalt` and do not raise a Lua error.
---
---@param path string Absolute path to a directory of certificates (e.g. `"/etc/ssl/certs"`).
function GWSockets.addVerifyPath( path ) end
