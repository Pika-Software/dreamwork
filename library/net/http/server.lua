---@meta _

---@alias http.Server.Handler fun( request: http.Server.Request, response: http.Server.Response ): ( boolean | Future | nil )
---@alias http.Server.ErrorHandler fun( request: http.Server.Request, response: http.Server.Response, err: any )

---@class http.Server.State
---@field handle holylib.HttpServer The HolyLib server.
---@field owned boolean `true` if this wrapper created the server, only owned servers are destroyed by `__gc`.
---@field deferred table<holylib.HttpRequest, boolean> Deferred raw requests, weak keys (HolyLib holds them until handled).
---@field waiting table<holylib.HttpRequest, http.Server.Exchange> Exchanges of deferred requests, weak keys and values.
---@field on_error http.Server.ErrorHandler | nil
---@field restart_pending boolean
---@field tcp_nodelay boolean | nil Last assigned value, HolyLib has no getter.
---@field read_timeout number | nil Last assigned value, HolyLib has no getter.
---@field write_timeout number | nil Last assigned value, HolyLib has no getter.
---@field payload_max_length integer | nil Last assigned value, HolyLib has no getter.
---@field keep_alive_timeout integer | nil Last assigned value, HolyLib has no getter.
---@field keep_alive_max_count integer | nil Last assigned value, HolyLib has no getter.
---@field thread_sleep integer | nil Last assigned value, HolyLib has no getter.

--- The data shared by a `Request` and its `Response`.
---
--- Never references the wrappers themselves, weak-key tables in LuaJIT are not ephemerons,
--- so a value pointing back at its key would keep the entry alive forever.
---
---@class http.Server.Exchange
---@field raw holylib.HttpRequest | holylib.HttpResponse | nil The HolyLib object, `nil` once finished.
---@field state http.Server.State | nil The server state, `nil` for prepared responses.
---@field guard userdata | nil The finalizer guard of a deferred request.
---@field cache table<string, any> | nil Request properties read so far.
---@field content string | nil
---@field content_type string | nil
---@field status integer | nil

--- [SERVER]
---
--- An incoming request delivered to an `http.Server` route handler.
---
--- A request is valid until it is finished, synchronous handlers finish when they return.
--- Properties read before that stay readable, everything else raises an error.
---
---@class http.Server.Request : Object
---@field __class http.Server.RequestClass
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
local Request = {}

---@param exchange http.Server.Exchange
---@protected
function Request:__init(exchange) end

---@param key string
---@return any
---@protected
function Request:__index(key) end

---@param key string
---@protected
function Request:__newindex(key) end

---@return boolean is_valid
---@protected
function Request:__isvalid() end

--- [SERVER]
---
--- Returns `true` if the request has the given header.
---
---@param key string The header name.
---@return boolean has_header
---@nodiscard
function Request:hasHeader(key) end

--- [SERVER]
---
--- Returns `true` if the request has the given query / form parameter.
---
---@param key string The parameter name.
---@return boolean has_param
---@nodiscard
function Request:hasParam(key) end

--- [SERVER]
---
--- Returns the value of the given header, or `nil` if missing.
---
---@param key string The header name.
---@return string | nil value
---@nodiscard
function Request:getHeader(key) end

--- [SERVER]
---
--- Returns the value of the given query / form parameter, or `nil` if missing.
---
---@param key string The parameter name.
---@return string | nil value
---@nodiscard
function Request:getParam(key) end

--- [SERVER]
---
--- Returns a path parameter captured from a `:name` segment in the route pattern, or `nil` if missing.
---
---@param key string The path parameter name without the leading `":"`.
---@return string | nil value
---@nodiscard
function Request:getPathParam(key) end

--- [SERVER]
---
--- Sends the response and invalidates the request and its response.
---
--- Synchronous handlers are finished automatically when they return,
--- call this only from handlers that returned `false` to defer the reply.
---
--- Calling it again does nothing.
---
function Request:finish() end

--- [SERVER]
---
--- The class used to create `http.Server.Request` wrappers.
---
---@class http.Server.RequestClass : http.Server.Request, Class
---@field __base http.Server.Request
---@overload fun( exchange: http.Server.Exchange ): http.Server.Request
local RequestClass = {}

--- [SERVER]
---
--- The response writer for an `http.Server` route handler.
---
--- Backed by the same HolyLib `HttpRequest` as the paired `Request` (HolyLib 0.8 merged the response into it),
--- or by an `HttpResponse` when used from `:prepare`.
---
--- Assign `content`, `content_type`, or `status` to build the reply, or use `:send`.
---
---@class http.Server.Response : Object
---@field __class http.Server.ResponseClass
---@field content string | nil The response body, `nil` until assigned. Assigning calls `SetContent` with the current `content_type`.
---@field content_type string The `Content-Type`, defaults to `"text/plain"`.
---@field status integer | nil The response status code (`100`–`599`), `nil` until assigned.
local Response = {}

---@param exchange http.Server.Exchange
---@protected
function Response:__init(exchange) end

---@param key string
---@return any
---@protected
function Response:__index(key) end

---@param key string
---@param value any
---@protected
function Response:__newindex(key, value) end

---@return boolean is_valid
---@protected
function Response:__isvalid() end

--- [SERVER]
---
--- Sets a response header.
---
---@param key string The header name.
---@param value string The header value.
---@return http.Server.Response self
function Response:setHeader(key, value) end

--- [SERVER]
---
--- Sets a redirect response.
---
---@param url string The redirect target URL.
---@param code integer? The redirect status code. Defaults to `302`.
---@return http.Server.Response self
function Response:setRedirect(url, code) end

--- [SERVER]
---
--- Sets the status, body and optionally the content type in one call.
---
---@param status integer The response status code.
---@param content string The response body.
---@param content_type http.ContentType? The `Content-Type`, defaults to the current `content_type`.
---@return http.Server.Response self
function Response:send(status, content, content_type) end

--- [SERVER]
---
--- Shortcut for `Request:finish` of the paired request.
---
--- Does nothing for responses created by `:prepare`.
---
function Response:finish() end

--- [SERVER]
---
--- The class used to create `http.Server.Response` wrappers.
---
---@class http.Server.ResponseClass : http.Server.Response, Class
---@field __base http.Server.Response
---@overload fun( exchange: http.Server.Exchange ): http.Server.Response
local ResponseClass = {}

--- [SERVER]
---
--- An HTTP server backed by [HolyLib's httpserver](https://holylib.raphaelit7.com/httpserver).
---
--- ```lua
--- local server = http.Server()
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
---@class http.Server : Object
---@field __class http.ServerClass
---@field name string The server name used by `http.Server.findByName`, max length is 63 characters.
---@field address string The bind address from the last `:start`. **Read-only.**
---@field port integer The listen port from the last `:start`, or `0` before start. **Read-only.**
---@field running boolean `true` if the server is currently listening, `false` once destroyed. **Read-only.**
---@field error_handler http.Server.ErrorHandler | nil Called when a route handler throws or its future fails, `nil` (and the fallback when it throws itself) replies `500 Internal Server Error`.
---@field tcp_nodelay boolean | nil `true` sets TCP_NODELAY on accepted sockets. `nil` until assigned (HolyLib default).
---@field read_timeout number | nil The maximum time allowed for a read, in seconds (fractions are microseconds). `nil` until assigned (HolyLib default).
---@field write_timeout number | nil The maximum time allowed for a write, in seconds (fractions are microseconds). `nil` until assigned (HolyLib default).
---@field payload_max_length integer | nil The maximum accepted request body length in bytes. `nil` until assigned (HolyLib default).
---@field keep_alive_timeout integer | nil How long keep-alive connections may stay open, in seconds. `nil` until assigned (HolyLib default).
---@field keep_alive_max_count integer | nil How many requests a keep-alive connection may serve. `nil` until assigned (HolyLib default).
---@field thread_sleep integer | nil How long worker threads sleep (ms) while waiting for the main thread to handle a request. `nil` until assigned (HolyLib default).
local Server = {}

---@param key string
---@return any
---@protected
function Server:__index(key) end

---@param key string
---@param value any
---@protected
function Server:__newindex(key, value) end

---@return string
---@protected
function Server:__represent() end

---@param name string?
---@protected
function Server:__init(name) end

--- Destroys the HolyLib server when the object is collected, only if this wrapper created it.
---
---@protected
function Server:__gc() end

---@return boolean is_valid
---@protected
function Server:__isvalid() end

--- [SERVER]
---
--- Stops and destroys the underlying HolyLib server, even one found with `findByName` / `getAll`.
---
--- Further method calls raise an error.
---
function Server:destroy() end

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
function Server:start(address, port) end

--- [SERVER]
---
--- Stops the server if it is running, deferred requests are answered with `503`.
---
function Server:stop() end

--- [SERVER]
---
--- Registers a `GET` handler. Path parameters use `:name` segments (e.g. `"/user/:id"`).
---
--- When `ip_whitelist` is `true`, only requests from connected players' IPs are handled.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:get(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Registers a `POST` handler.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:post(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Registers a `PUT` handler.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:put(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Registers a `PATCH` handler.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:patch(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Registers a `DELETE` handler.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:delete(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Registers an `OPTIONS` handler.
---
---@param path string The URL path pattern.
---@param handler http.Server.Handler The route handler.
---@param ip_whitelist boolean? Restrict to connected players. Defaults to `false`.
function Server:options(path, handler, ip_whitelist) end

--- [SERVER]
---
--- Mounts a filesystem folder at the given URL path.
---
---@param path string The URL path prefix.
---@param folder string The filesystem folder to serve.
function Server:mount(path, folder) end

--- [SERVER]
---
--- Removes every mount previously set for `path`.
---
---@param path string The URL path prefix to unmount.
function Server:unmount(path) end

--- [SERVER]
---
--- Configures the worker thread pool size.
---
--- The pool is created on start, a running server restarts on the next frame.
---
---@param min_threads integer Minimum number of worker threads.
---@param max_threads integer Maximum number of worker threads.
function Server:setThreads(min_threads, max_threads) end

--- [SERVER]
---
--- Trusts `proxy_address` as a reverse proxy and reads the client IP from `header_name`.
---
---@param proxy_address string The remote address of the trusted proxy.
---@param header_name string Header that carries the real client IP, e.g. `"X-Forwarded-For"`.
---@param use_last_ip boolean? Prefer the last IP in a comma-separated header. Defaults to `false`.
function Server:addProxy(proxy_address, header_name, use_last_ip) end

--- [SERVER]
---
--- Queues a prepared response for the next matching request from the given player `user_id`.
---
--- `handler` runs immediately to fill the response, matching requests are then answered
--- on the worker thread without any Lua call. The response is invalid after `handler` returns.
---
---@param user_id integer The player's UserID (`-1` for non-player / unmatched clients).
---@param path string Exact request path to match.
---@param method http.RequestMethod | string Exact HTTP method to match.
---@param required_headers table<string, string> Headers that must be present with these values.
---@param handler fun( response: http.Server.Response ) Fills the prepared response.
---@param uses integer? How many times this entry may match. Defaults to `1`.
function Server:prepare(user_id, path, method, required_headers, handler, uses) end

--- [SERVER]
---
--- The class used to create new `http.Server` instances.
---
--- Requires HolyLib's `httpserver` module.
---
---@class http.ServerClass : http.Server, Class
---@field __base http.Server
---@field available boolean `true` when HolyLib's `httpserver` module is loaded.
---@overload fun( name: string? ): http.Server
http.Server = {}

http.Server.Request = RequestClass

http.Server.Response = ResponseClass

---@type boolean
http.Server.available = nil

--- [SERVER]
---
--- Finds an existing server by its `name` property.
---
--- Returns a dreamwork wrapper around the HolyLib object, or `nil` if none matched.
--- Wrappers of servers created elsewhere (e.g. before a reload) do not destroy them when collected.
---
---@param name string The server name to look for.
---@return http.Server | nil server
function http.Server.findByName(name) end

--- [SERVER]
---
--- Returns every currently existing HolyLib `HttpServer` wrapped as `http.Server` objects.
---
--- Wrappers of servers created elsewhere do not destroy them when collected.
---
---@return http.Server[] servers
function http.Server.getAll() end
