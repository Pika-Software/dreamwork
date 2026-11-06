---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
local dreamwork_Logger = dreamwork.Logger

local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs

local string = std.string
local string_format = string.format

local json = std.json
local json_encode = json.encode

local error = std.error
local isString = std.isString
local loadbinary = std.loadbinary


--- [SHARED AND MENU]
---
--- Callbacks and handshake options passed to `dreamwork.engine.websocket.create`.
---
---@class dreamwork.engine.websocket.Options
---@field headers table<string, string> | nil Extra handshake headers (`gwsockets` only), including `Cookie` when set by `std.WebSocket`.
---@field verify_certificate boolean | nil Verify the TLS certificate (`gwsockets` only). Defaults to `true`.
---@field compression boolean | nil Negotiate `permessage-deflate` (`gwsockets` only).
---@field on_open nil | fun() Called when the handshake succeeds.
---@field on_message nil | fun( message: string ) Called for every received frame.
---@field on_error nil | fun( message: string ) Called on a transport / protocol error.
---@field on_close nil | fun( reason: string | nil, code: integer | nil, errored: boolean ) Called when the connection ends.

--- [CLIENT AND MENU]
---
--- WebClient backend handle: a headless `std.WebClient` that runs the browser `WebSocket`.
---
---@class dreamwork.engine.websocket.WebClientHandle
---@field client dreamwork.std.WebClient The client hosting the browser socket.
---@field closed boolean `true` once the socket was closed, every later callback is ignored.

--- [SHARED AND MENU]
---
--- Handle of a backend WebSocket created by `dreamwork.engine.websocket.create`.
---
--- Pass it only to `websocket.open` / `write` / `close`. The concrete value
--- depends on `BackendName`:
---
--- * `"tungstenite"` — `gm_tungstenite.Socket` userdata
--- * `"gwsockets"` — `gm_gwsockets.WebSocket` table
--- * `"webclient"` — `dreamwork.engine.websocket.WebClientHandle`
---
--- Do not read or write fields on the handle from outside the engine module.
---
---@alias dreamwork.engine.websocket.Handle gm_tungstenite.Socket | gm_gwsockets.WebSocket | dreamwork.engine.websocket.WebClientHandle

--- [SHARED AND MENU]
---
--- WebSocket engine, wraps the best available backend:
--- `gwsockets`, `tungstenite`, or a `std.WebClient` / browser fallback on client and menu.
---
---@class dreamwork.engine.websocket
---@field BackendName "gwsockets" | "tungstenite" | "webclient" | "" The name of the loaded WebSocket backend, empty if none was found.
---@field Capabilities dreamwork.engine.websocket.Capabilities Features supported by the loaded backend.
local websocket = {}

dreamwork_engine.websocket = websocket

--- [SHARED AND MENU]
---
--- Features supported by the loaded WebSocket backend.
---
---@class dreamwork.engine.websocket.Capabilities
---@field binary boolean Binary frames can be sent and are received as raw bytes (otherwise text only, binary frames are decoded lossily).
---@field headers boolean Extra handshake headers (and `Cookie`) are sent.
---@field compression boolean `permessage-deflate` can be negotiated.
---@field verify_certificate boolean TLS certificate verification can be turned off.
local capabilities = {
    binary = false,
    headers = false,
    compression = false,
    verify_certificate = false
}

websocket.Capabilities = capabilities

---@type "gwsockets" | "tungstenite" | "webclient" | ""
local backend_name = ""

---@type fun( url: string, options: dreamwork.engine.websocket.Options ): dreamwork.engine.websocket.Handle
local create_fn

---@type fun( handle: dreamwork.engine.websocket.Handle ) | nil
local open_fn

---@type fun( handle: dreamwork.engine.websocket.Handle, message: string, is_binary: boolean? )
local write_fn

---@type fun( handle: dreamwork.engine.websocket.Handle, force: boolean? )
local close_fn


--- Backend: GWSockets
if loadbinary( "gwsockets" ) and GWSockets ~= nil and GWSockets.createWebSocket ~= nil then

    local gwsockets_create = GWSockets.createWebSocket

    ---@param url string
    ---@param options dreamwork.engine.websocket.Options
    ---@return dreamwork.engine.websocket.Handle
    function create_fn( url, options )
        local verify = options.verify_certificate
        if verify == nil then
            verify = true
        end

        local handle = gwsockets_create( url, verify )
        if handle == nil then
            error( "GWSockets.createWebSocket rejected the URL", 2 )
        end

        local headers = options.headers
        if headers ~= nil then
            for name, value in raw_pairs( headers ) do
                if isString( name ) and isString( value ) then
                    handle:setHeader( name, value )
                end
            end
        end

        if options.compression == true then
            handle:setMessageCompression( true )
        end

        local on_open = options.on_open
        local on_message = options.on_message
        local on_error = options.on_error
        local on_close = options.on_close

        if on_open ~= nil then
            function handle.onConnected( _ )
                on_open()
            end
        end

        if on_message ~= nil then
            function handle.onMessage( _, message )
                on_message( message )
            end
        end

        if on_error ~= nil then
            function handle.onError( _, err_message )
                on_error( err_message )
            end
        end

        if on_close ~= nil then
            function handle.onDisconnected( _, message )
                on_close( message, nil, false )
            end
        end

        return handle
    end

    ---@param handle dreamwork.engine.websocket.Handle
    function open_fn( handle )
        ---@cast handle gm_gwsockets.WebSocket
        handle:open()
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param message string
    ---@param is_binary boolean?
    function write_fn( handle, message, is_binary )
        ---@cast handle gm_gwsockets.WebSocket
        handle:write( message, is_binary == true )
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param force boolean?
    function close_fn( handle, force )
        ---@cast handle gm_gwsockets.WebSocket
        if force then
            handle:closeNow()
        else
            handle:close()
        end
    end

    capabilities.binary = true
    capabilities.headers = true
    capabilities.compression = true
    capabilities.verify_certificate = true

    backend_name = "gwsockets"

    --- Backend: gm_tungstenite (starts connecting from `connect`)
elseif loadbinary( "tungstenite" ) and tungstenite ~= nil and tungstenite.connect ~= nil then

    local tungstenite_connect = tungstenite.connect

    ---@param url string
    ---@param options dreamwork.engine.websocket.Options
    ---@return dreamwork.engine.websocket.Handle
    function create_fn( url, options )
        local handle = tungstenite_connect( url )

        local on_open = options.on_open
        local on_message = options.on_message
        local on_error = options.on_error
        local on_close = options.on_close

        if on_open ~= nil then
            function handle.on_connect( _ )
                on_open()
            end
        end

        if on_message ~= nil then
            function handle.on_message( _, message )
                on_message( message )
            end
        end

        if on_error ~= nil then
            function handle.on_error( _, err_message )
                on_error( err_message )
            end
        end

        if on_close ~= nil then
            function handle.on_disconnect( _, reason, code )
                on_close( reason, code, false )
            end
        end

        return handle
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param message string
    function write_fn( handle, message )
        ---@cast handle gm_tungstenite.Socket
        handle:send( message )
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param force boolean?
    function close_fn( handle, force )
        ---@cast handle gm_tungstenite.Socket
        if force then
            if handle.closeNow ~= nil then
                handle:closeNow()
            else
                handle:close_now()
            end
        else
            handle:close()
        end
    end

    backend_name = "tungstenite"

    --- Backend: browser WebSocket inside a headless `std.WebClient` (client / menu)
elseif std.WebClient ~= nil then

    local WebClient = std.WebClient

    local base64 = std.base64
    local base64_encode = base64.encode
    local base64_decode = base64.decode

    local setTimeout = std.setTimeout

    -- binary frames cross the JS <-> Lua bridge as base64, text frames as is;
    -- `%s` is the address as a JS string literal (`json.encode` escapes quotes, line breaks, ...)
    local js_template = string.unindentLines( [[
        function dw_ws_b64(buffer) {
            var bytes = new Uint8Array(buffer), str = '';
            for (var i = 0; i < bytes.length; i += 0x8000) {
                str += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
            }
            return btoa(str);
        }

        function dw_ws_send(data) {
            if (dw_websocket.readyState === 1) { dw_websocket.send(data); }
        }

        function dw_ws_send_binary(b64) {
            var str = atob(b64), bytes = new Uint8Array(str.length);
            for (var i = 0; i < str.length; i++) { bytes[i] = str.charCodeAt(i); }
            dw_ws_send(bytes.buffer);
        }

        var dw_websocket = new WebSocket(%s);

        dw_websocket.binaryType = 'arraybuffer';
        dw_websocket.onopen = function() { dw_ws.open(); };

        dw_websocket.onmessage = function(event) {
            if (typeof event.data === 'string') { dw_ws.message(event.data); }
            else { dw_ws.binary(dw_ws_b64(event.data)); }
        };

        dw_websocket.onerror = function() { dw_ws.error('WebSocket connection error'); };
        dw_websocket.onclose = function(event) { dw_ws.close(event.code, event.reason, !event.wasClean); };
    ]], 8 )

    --- Destroys the client unless it is already gone and drops its listeners,
    --- the `"destroy"` handler references the client through the socket handle.
    ---
    ---@param client dreamwork.std.WebClient
    local function destroy_client( client )
        if not client:isClosed() then
            client:close()
        end

        client:clear()
    end

    ---@param url string
    ---@param options dreamwork.engine.websocket.Options
    ---@return dreamwork.engine.websocket.Handle
    function create_fn( url, options )
        local client = WebClient()

        local on_open = options.on_open
        local on_message = options.on_message
        local on_error = options.on_error
        local on_close = options.on_close

        ---@type dreamwork.engine.websocket.WebClientHandle
        local handle = {
            client = client,
            closed = false
        }

        ---@param code integer | nil
        ---@param reason string | nil
        ---@param errored boolean | nil
        local function finish( code, reason, errored )
            if handle.closed then return end

            handle.closed = true

            -- never destroy the panel from inside its own JS callback
            setTimeout( destroy_client, 0, client )

            if on_close ~= nil then
                if reason == "" then
                    reason = nil
                end

                on_close( reason, code, errored == true )
            end
        end

        -- bridge callbacks must not capture `client`, they are reachable from it
        client:bind( "dw_ws.open", function()
            if handle.closed or on_open == nil then return end

            on_open()
        end )

        client:bind( "dw_ws.message", function( data )
            if handle.closed or on_message == nil then return end

            on_message( data )
        end )

        client:bind( "dw_ws.binary", function( data )
            if handle.closed or on_message == nil then return end

            on_message( base64_decode( data ) )
        end )

        client:bind( "dw_ws.error", function( message )
            if handle.closed or on_error == nil then return end

            on_error( message )
        end )

        client:bind( "dw_ws.close", finish )

        -- the panel can be removed from outside, e.g. by a VGUI cleanup
        client:attach( "destroy", function()
            finish( 1006, "WebClient was destroyed", true )
        end )

        -- queued until the blank document is ready
        client:run( string_format( js_template, json_encode( url ) ) )

        return handle
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param message string
    ---@param is_binary boolean?
    function write_fn( handle, message, is_binary )
        ---@cast handle dreamwork.engine.websocket.WebClientHandle
        if handle.closed then return end

        if is_binary then
            handle.client:run( "dw_ws_send_binary(" .. json_encode( base64_encode( message ) ) .. ");" )
        else
            handle.client:run( "dw_ws_send(" .. json_encode( message ) .. ");" )
        end
    end

    ---@param handle dreamwork.engine.websocket.Handle
    ---@param force boolean?
    function close_fn( handle, force )
        ---@cast handle dreamwork.engine.websocket.WebClientHandle
        if handle.closed then return end

        local client = handle.client

        if force or not client:isReady() then
            -- no callback on immediate close, the caller reports it
            handle.closed = true
            setTimeout( destroy_client, 0, client )
            return
        end

        -- the browser runs the closing handshake, `onclose` reports the result
        client:run( "dw_websocket.close(1000);" )
    end

    capabilities.binary = true
    backend_name = "webclient"

end

websocket.BackendName = backend_name

if create_fn == nil then
    dreamwork_Logger:error( "WebSocket backend loading failed, opening sockets is not possible." )

    function create_fn()
        error( "no WebSocket backend is available", 2 )
    end

    function write_fn()
        error( "no WebSocket backend is available", 2 )
    end

    function close_fn() end
else
    dreamwork_Logger:info( "'%s' was loaded & connected as WebSocket backend.", backend_name )
end

--- [SHARED AND MENU]
---
--- Creates a backend socket for `url` and starts connecting when the backend does so
--- automatically (`tungstenite`, `webclient`). Call `websocket.open` afterwards for backends
--- that need an explicit open (`gwsockets`).
---
---@param url string The WebSocket URL (`ws://` or `wss://`).
---@param options dreamwork.engine.websocket.Options Handshake options and event callbacks.
---@return dreamwork.engine.websocket.Handle handle The opaque backend handle.
function websocket.create( url, options )
    return create_fn( url, options )
end

--- [SHARED AND MENU]
---
--- Opens a socket that was created but not yet connected (`gwsockets`).
--- No-op for backends that connect from `create`.
---
---@param handle dreamwork.engine.websocket.Handle The handle returned by `websocket.create`.
function websocket.open( handle )
    if open_fn ~= nil then
        open_fn( handle )
    end
end

--- [SHARED AND MENU]
---
--- Sends a message on an open socket.
---
---@param handle dreamwork.engine.websocket.Handle The handle returned by `websocket.create`.
---@param message string The payload to send.
---@param is_binary boolean? Send as a binary frame (`gwsockets` only). Defaults to `false`.
function websocket.write( handle, message, is_binary )
    write_fn( handle, message, is_binary )
end

--- [SHARED AND MENU]
---
--- Closes the socket. With `force`, terminates immediately and discards queued outbound
--- messages when the backend supports it; otherwise flushes first when supported.
---
---@param handle dreamwork.engine.websocket.Handle The handle returned by `websocket.create`.
---@param force boolean? Immediately terminate instead of a graceful close. Defaults to `false`.
function websocket.close( handle, force )
    close_fn( handle, force == true )
end
