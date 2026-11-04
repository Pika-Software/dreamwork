---@meta gm_tungstenite


--- [SERVER]
---
--- Connection state of a `tungstenite` socket.
---
---@alias gm_tungstenite.State
---| 0 # Connected — handshake finished, ready to send / receive.
---| 1 # Connecting — connect task is running.
---| 2 # NotConnected — reserved / unused in current builds.
---| 3 # Disconnected — closed or failed; `open` may reconnect.

--- [SERVER]
---
--- Native WebSocket client from the [gm_tungstenite](https://github.com/shockpast/gm_tungstenite)
--- binary module (`gmsv_tungstenite`), built on Rust's `tokio-tungstenite`.
---
--- Created by `tungstenite.connect`, which **starts connecting immediately**. Callbacks are
--- optional methods looked up by name on the userdata and invoked on the next tick of the
--- main thread:
---
--- * `on_connect` — handshake succeeded
--- * `on_message` — text frame, or binary frame decoded with lossy UTF-8
--- * `on_error` — I/O / protocol error (usually followed by `on_disconnect`)
--- * `on_disconnect( reason, code )` — connection ended
---
--- Outbound messages are text frames. The module also answers peer `Ping` frames and sends
--- its own heartbeat ping every 30 seconds.
---
---@class gm_tungstenite.Socket
local Socket = {}

--- [SERVER]
---
--- Queues a text frame. Alias of `write`.
---
--- Messages can be queued before `on_connect`; they are sent once the socket is connected.
---
---@param data string UTF-8 text payload.
function Socket:send( data ) end

--- [SERVER]
---
--- Queues a text frame. Alias of `send`.
---
---@param data string UTF-8 text payload.
function Socket:write( data ) end

--- [SERVER]
---
--- Requests a graceful close (`1000` / `"closed by user"`) after queued writes are flushed.
---
function Socket:close() end

--- [SERVER]
---
--- Aborts the connection immediately and fires `on_disconnect` with reason `"closed by user"`
--- and code `1000`. Alias of `closeNow`.
---
function Socket:close_now() end

--- [SERVER]
---
--- Aborts the connection immediately. Alias of `close_now`.
---
function Socket:closeNow() end

--- [SERVER]
---
--- Re-opens a socket that is in the `Disconnected` state. Returns `true` and does nothing
--- when the socket is still connecting or connected.
---
---@return boolean started `true` if a reconnect was started or the socket was already active.
function Socket:open() end

--- [SERVER]
---
--- Optional callback: connection established.
---
---@type nil | fun( self: gm_tungstenite.Socket )
Socket.on_connect = nil

--- [SERVER]
---
--- Optional callback: text (or lossy-decoded binary) message received.
---
---@type nil | fun( self: gm_tungstenite.Socket, message: string )
Socket.on_message = nil

--- [SERVER]
---
--- Optional callback: an error occurred.
---
---@type nil | fun( self: gm_tungstenite.Socket, err: string )
Socket.on_error = nil

--- [SERVER]
---
--- Optional callback: the connection ended.
---
---@type nil | fun( self: gm_tungstenite.Socket, reason: string, code: integer )
Socket.on_disconnect = nil

--- [SERVER]
---
--- WebSocket client library from [gm_tungstenite](https://github.com/shockpast/gm_tungstenite).
---
--- Available after `require( "tungstenite" )`. The global table is set during module open.
---
--- ```lua
--- require( "tungstenite" )
---
--- local conn = tungstenite.connect( "wss://echo.websocket.org" )
---
--- function conn:on_connect()
---     conn:send( "hello" )
--- end
---
--- function conn:on_message( message )
---     print( message )
--- end
---
--- function conn:on_disconnect( reason, code )
---     print( reason, code )
--- end
--- ```
---
--- [View documents](https://github.com/shockpast/gm_tungstenite)
---
---@class gm_tungstenite
---@field VERSION string Crate version of the loaded binary module.
tungstenite = {}

--- [SERVER]
---
--- Creates a socket and starts connecting to `url` immediately.
---
--- `tostring( socket )` returns `"tungstenite (<uuid>)"`.
---
---@param url string The WebSocket URL (`ws://` or `wss://`).
---@return gm_tungstenite.Socket socket The userdata socket.
function tungstenite.connect( url ) end
