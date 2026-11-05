---@meta holylib.httpserver


--- [SERVER]
---
--- Creates and manages HTTP servers backed by [cpp-httplib](https://github.com/yhirose/cpp-httplib).
---
--- Part of [HolyLib](https://holylib.raphaelit7.com/httpserver). Requires the `httpserver` module to be enabled.
---
--- Supports: Linux32 | Linux64 | Windows32 | Windows64
---
--- [View documents](https://holylib.raphaelit7.com/httpserver)
---
---@class holylib.httpserver
httpserver = {}

--- [SERVER]
---
--- Creates a new `HttpServer`.
---
--- Servers persist across map changes until destroyed or HolyLib shuts down.
---
---@return holylib.HttpServer server The newly created server.
function httpserver.Create() end

--- [SERVER]
---
--- Stops and destroys the given `HttpServer`.
---
---@param server holylib.HttpServer The server to destroy.
function httpserver.Destroy( server ) end

--- [SERVER]
---
--- Finds a `HttpServer` by the name set with `HttpServer:SetName`.
---
---@param name string The server name to look for.
---@return holylib.HttpServer | nil server The matching server, or `nil` if none matched.
function httpserver.FindByName( name ) end

--- [SERVER]
---
--- Returns every currently existing `HttpServer` for this Lua state.
---
---@return holylib.HttpServer[] servers A sequential table of all servers.
function httpserver.GetAll() end


--- [SERVER]
---
--- Callback registered with `HttpServer:Get` / `Post` / `Put` / `Patch` / `Delete` / `Options`.
---
--- HolyLib only pushes the `HttpRequest`. Response body, headers, redirects and status are set on that same object
--- (`SetContent`, `SetHeader`, `SetRedirect`, `SetStatusCode`) to avoid an extra userdata allocation.
---
--- Return `false` to keep the HTTP thread waiting and finish later with `HttpRequest:MarkHandled`.
--- Any other return value (including `nil`) marks the request as handled when the callback returns.
---
---@alias holylib.HttpServer.Handler fun( request: holylib.HttpRequest ): boolean | nil

--- [SERVER]
---
--- Callback used by `HttpServer:AddPreparedResponse` to fill the prepared `HttpResponse`.
---
---@alias holylib.HttpServer.PreparedResponseHandler fun( response: holylib.HttpResponse )


--- [SERVER]
---
--- An HTTP server created with `httpserver.Create`.
---
--- Route handlers run on the main thread; the listen loop runs on a background thread.
--- After registering routes with `Get` / `Post` / … while the server is already running, call `Start` again.
---
---@class holylib.HttpServer
local HttpServer = {}

--- [SERVER]
---
--- Returns whether this object is still valid.
---
---@return boolean is_valid `true` if the userdata is valid.
function HttpServer:IsValid() end

--- [SERVER]
---
--- Returns the Lua table used by `__index` / `__newindex`.
---
---@return table lua_table The associated Lua table.
function HttpServer:GetTable() end

--- [SERVER]
---
--- Starts (or restarts) the server on the given address and port.
---
--- Call again after adding routes while the server is already running.
---
---@param address string Bind address, e.g. `"0.0.0.0"` or `"127.0.0.1"`.
---@param port integer TCP port to listen on.
function HttpServer:Start( address, port ) end

--- [SERVER]
---
--- Stops the HTTP server if it is running.
---
function HttpServer:Stop() end

--- [SERVER]
---
--- Processes pending requests on the main thread.
---
--- HolyLib calls this automatically from its think loop; usually not needed manually.
---
function HttpServer:Think() end

--- [SERVER]
---
--- Returns whether the server is currently listening.
---
---@return boolean is_running `true` if the listen thread is active.
function HttpServer:IsRunning() end

--- [SERVER]
---
--- Returns the bind address last passed to `Start`.
---
---@return string address The listen address.
function HttpServer:GetAddress() end

--- [SERVER]
---
--- Returns the port last passed to `Start`.
---
---@return integer port The listen port, or `0` before the first `Start`.
function HttpServer:GetPort() end

--- [SERVER]
---
--- Returns the name set with `SetName`.
---
---@return string name The server name, `"NONAME"` by default.
function HttpServer:GetName() end

--- [SERVER]
---
--- Sets the name used by `httpserver.FindByName`. Max length is 63 characters.
---
---@param name string The new server name.
function HttpServer:SetName( name ) end

--- [SERVER]
---
--- Registers a `GET` handler for `path`.
---
--- Path parameters use `:name` segments, e.g. `"/user/:id"`, and are read with `HttpRequest:GetPathParam`.
---
--- When `ip_whitelist` is `true`, only requests whose remote address matches a connected player's net channel are handled.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Get( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Registers a `POST` handler for `path`.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Post( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Registers a `PUT` handler for `path`.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Put( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Registers a `PATCH` handler for `path`.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Patch( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Registers a `DELETE` handler for `path`.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Delete( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Registers an `OPTIONS` handler for `path`.
---
---@param path string The URL path pattern.
---@param handler holylib.HttpServer.Handler The request callback.
---@param ip_whitelist? boolean Restrict to connected players. Defaults to `false`.
function HttpServer:Options( path, handler, ip_whitelist ) end

--- [SERVER]
---
--- Mounts a filesystem folder at the given URL path. Can be called multiple times for the same path.
---
---@param path string The URL path prefix.
---@param folder string The filesystem folder to serve.
function HttpServer:SetMountPoint( path, folder ) end

--- [SERVER]
---
--- Removes every mount previously set for `path`.
---
---@param path string The URL path prefix to unmount.
function HttpServer:RemoveMountPoint( path ) end

--- [SERVER]
---
--- Sets TCP_NODELAY on accepted sockets.
---
---@param nodelay boolean `true` to disable Nagle's algorithm.
function HttpServer:SetTCPnodelay( nodelay ) end

--- [SERVER]
---
--- Sets the maximum time allowed for a read.
---
---@param sec integer Seconds part of the timeout.
---@param usec integer Microseconds part of the timeout.
function HttpServer:SetReadTimeout( sec, usec ) end

--- [SERVER]
---
--- Sets the maximum time allowed for a write.
---
---@param sec integer Seconds part of the timeout.
---@param usec integer Microseconds part of the timeout.
function HttpServer:SetWriteTimeout( sec, usec ) end

--- [SERVER]
---
--- Sets the maximum accepted request body length in bytes.
---
---@param max_length integer Maximum payload size.
function HttpServer:SetPayloadMaxLength( max_length ) end

--- [SERVER]
---
--- Sets how long keep-alive connections may stay open.
---
---@param sec integer Keep-alive timeout in seconds.
function HttpServer:SetKeepAliveTimeout( sec ) end

--- [SERVER]
---
--- Sets how many keep-alive connections may be open at once.
---
---@param amount integer Maximum keep-alive connection count.
function HttpServer:SetKeepAliveMaxCount( amount ) end

--- [SERVER]
---
--- Sets how long worker threads sleep (ms) while waiting for the main thread to handle a request.
---
--- Raise this when handlers intentionally wait a long time before calling `MarkHandled`.
---
---@param sleep_ms integer Sleep duration in milliseconds. Defaults to `5`.
function HttpServer:SetThreadSleep( sleep_ms ) end

--- [SERVER]
---
--- Configures the internal thread pool size for request workers.
---
---@param min_threads integer Minimum number of worker threads.
---@param max_threads integer Maximum number of worker threads.
function HttpServer:SetThreads( min_threads, max_threads ) end

--- [SERVER]
---
--- Trusts `proxy_address` as a reverse proxy and reads the client IP from `header_name`.
---
--- When `unshit_address` is `true` and the header contains a comma-separated list, the last entry is used.
---
---@param proxy_address string The remote address of the trusted proxy.
---@param header_name string Header that carries the real client IP, e.g. `"X-Forwarded-For"`.
---@param unshit_address? boolean Prefer the last IP in a comma-separated header. Defaults to `false`.
function HttpServer:AddProxyAddress( proxy_address, header_name, unshit_address ) end

--- [SERVER]
---
--- Queues a prepared response for the next matching request from the given player `user_id`.
---
--- The request must match `path`, `method`, an empty body, and every header in `required_headers`.
--- `handler` receives an `HttpResponse` used to fill the prepared reply. After `uses` successful matches the entry is removed.
---
---@param user_id integer The player's UserID (`-1` for non-player / unmatched clients).
---@param path string Exact request path to match.
---@param method string Exact HTTP method to match, e.g. `"GET"`.
---@param required_headers table<string, string> Headers that must be present with these values.
---@param handler holylib.HttpServer.PreparedResponseHandler Fills the prepared response.
---@param uses? integer How many times this entry may match. Defaults to `1`.
function HttpServer:AddPreparedResponse( user_id, path, method, required_headers, handler, uses ) end


--- [SERVER]
---
--- An incoming HTTP request delivered to a route handler.
---
--- Response writers (`SetContent`, `SetHeader`, `SetRedirect`, `SetStatusCode`) are on this object
--- so handlers do not need a separate response userdata.
---
---@class holylib.HttpRequest
local HttpRequest = {}

--- [SERVER]
---
--- Returns whether this object is still valid.
---
---@return boolean is_valid `true` if the userdata is valid.
function HttpRequest:IsValid() end

--- [SERVER]
---
--- Returns the Lua table used by `__index` / `__newindex`.
---
---@return table lua_table The associated Lua table.
function HttpRequest:GetTable() end

--- [SERVER]
---
--- Returns whether the request has the given header.
---
---@param key string The header name.
---@return boolean has_header `true` if the header is present.
function HttpRequest:HasHeader( key ) end

--- [SERVER]
---
--- Returns whether the request has the given query / form parameter.
---
---@param key string The parameter name.
---@return boolean has_param `true` if the parameter is present.
function HttpRequest:HasParam( key ) end

--- [SERVER]
---
--- Returns the value of the given header.
---
---@param key string The header name.
---@return string value The header value, or an empty string if missing.
function HttpRequest:GetHeader( key ) end

--- [SERVER]
---
--- Returns the value of the given query / form parameter.
---
---@param key string The parameter name.
---@return string value The parameter value, or an empty string if missing.
function HttpRequest:GetParam( key ) end

--- [SERVER]
---
--- Returns a path parameter captured from a `:name` segment in the route pattern.
---
---@param key string The path parameter name without the leading `":"`.
---@return string | nil value The captured value, or `nil` if the parameter was not present.
function HttpRequest:GetPathParam( key ) end

--- [SERVER]
---
--- Returns the request path.
---
---@return string path The URL path.
function HttpRequest:GetPath() end

--- [SERVER]
---
--- Returns the raw request body.
---
---@return string body The request body.
function HttpRequest:GetBody() end

--- [SERVER]
---
--- Returns the client IP, after proxy header rewriting when configured.
---
---@return string address The remote address.
function HttpRequest:GetRemoteAddr() end

--- [SERVER]
---
--- Returns the remote port the request came from.
---
---@return integer port The remote port.
function HttpRequest:GetRemotePort() end

--- [SERVER]
---
--- Returns the local address that accepted the connection.
---
---@return string address The local address.
function HttpRequest:GetLocalAddr() end

--- [SERVER]
---
--- Returns the local port that accepted the connection.
---
---@return integer port The local port.
function HttpRequest:GetLocalPort() end

--- [SERVER]
---
--- Returns the HTTP method, e.g. `"GET"` or `"POST"`.
---
---@return string method The request method.
function HttpRequest:GetMethod() end

--- [SERVER]
---
--- Returns the authorization header entry count from cpp-httplib.
---
---@return integer count The authorization count.
function HttpRequest:GetAuthorizationCount() end

--- [SERVER]
---
--- Returns the request `Content-Length`.
---
---@return integer length The content length in bytes.
function HttpRequest:GetContentLength() end

--- [SERVER]
---
--- Returns the `CBaseClient` for the connected player that matched this request's IP, if any.
---
--- Requires the HolyLib `gameserver` module.
---
---@return holylib.CBaseClient | nil client The matched client, or `nil`.
function HttpRequest:GetClient() end

--- [SERVER]
---
--- Returns the `Player` entity for the connected player that matched this request's IP, if any.
---
---@return garrysmod.Player | nil player The matched player, or `nil`.
function HttpRequest:GetPlayer() end

--- [SERVER]
---
--- Marks the request as handled so the worker thread can send the response and continue.
---
--- Needed when the route handler returned `false` to defer the reply.
---
function HttpRequest:MarkHandled() end

--- [SERVER]
---
--- Sets the response body and content type.
---
---@param content string The response body.
---@param content_type? string The `Content-Type`. Defaults to `"text/plain"`.
function HttpRequest:SetContent( content, content_type ) end

--- [SERVER]
---
--- Sets a redirect response.
---
---@param url string The redirect target URL.
---@param code? integer The redirect status code. Defaults to `302`.
function HttpRequest:SetRedirect( url, code ) end

--- [SERVER]
---
--- Sets a response header.
---
---@param key string The header name.
---@param value string The header value.
function HttpRequest:SetHeader( key, value ) end

--- [SERVER]
---
--- Sets the response status code (`100`–`599`).
---
---@param code integer The HTTP status code.
function HttpRequest:SetStatusCode( code ) end


--- [SERVER]
---
--- A response object used only by `HttpServer:AddPreparedResponse`.
---
--- Route handlers write the response through `HttpRequest` instead.
---
---@class holylib.HttpResponse
local HttpResponse = {}

--- [SERVER]
---
--- Returns whether this object is still valid.
---
---@return boolean is_valid `true` if the userdata is valid.
function HttpResponse:IsValid() end

--- [SERVER]
---
--- Returns the Lua table used by `__index` / `__newindex`.
---
---@return table lua_table The associated Lua table.
function HttpResponse:GetTable() end

--- [SERVER]
---
--- Sets the response body and content type.
---
---@param content string The response body.
---@param content_type? string The `Content-Type`. Defaults to `"text/plain"`.
function HttpResponse:SetContent( content, content_type ) end

--- [SERVER]
---
--- Sets a redirect response.
---
---@param url string The redirect target URL.
---@param code? integer The redirect status code. Defaults to `302`.
function HttpResponse:SetRedirect( url, code ) end

--- [SERVER]
---
--- Sets a response header.
---
---@param key string The header name.
---@param value string The header value.
function HttpResponse:SetHeader( key, value ) end

--- [SERVER]
---
--- Sets the response status code (`100`–`599`).
---
---@param code integer The HTTP status code.
function HttpResponse:SetStatusCode( code ) end
