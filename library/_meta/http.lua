---@meta _


---
--- A cookie stored in `http.CookieJar`, see [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265#section-5.3).
---
---@class http.Cookie
---@field name string The cookie name.
---@field value string The cookie value, as sent by the server.
---@field domain string The lowercase domain the cookie belongs to, without a leading `"."`.
---@field path string The path the cookie is sent for, always starts with `"/"`.
---@field host_only boolean `true` if the cookie is only sent to `domain` itself, `false` if subdomains get it too.
---@field secure boolean `true` if the cookie is only sent over `https://`.
---@field http_only boolean The `HttpOnly` attribute, kept for completeness, it has no effect here.
---@field same_site string | nil The lowercase `SameSite` attribute, kept for completeness, it has no effect here.
---@field expires integer | nil The Unix timestamp (seconds) the cookie expires at, `nil` for session cookies.
---@field created integer The creation order, earlier cookies are sent first when paths are equally long.

---
--- The options for `CookieJar:set`.
---
---@class http.CookieOptions
---@field url? string | URL The URL the cookie is set for, `domain` and `path` are taken from it when not given.
---@field domain? string The domain, the cookie is also sent to its subdomains. Required if `url` is not given.
---@field path? string The path, defaults to the directory of `url` or `"/"`.
---@field expires? integer The Unix timestamp (seconds) the cookie expires at.
---@field max_age? integer The lifetime in seconds, takes precedence over `expires`.
---@field secure? boolean Only send the cookie over `https://`.
---@field http_only? boolean The `HttpOnly` attribute.
---@field same_site? "strict" | "lax" | "none" The `SameSite` attribute.

---
--- The HTTP request method.
---
---@alias http.RequestMethod
---| "HEAD" # Same as `GET`, but only retrieves headers (no body).
---| "GET" # Retrieve data from a server.
---| "POST" # Send data to the server to create a resource.
---| "PUT" # Replace a resource entirely at the given URL.
---| "PATCH" # Partially update a resource.
---| "DELETE" # Remove a resource from the server.
---| "OPTIONS" # Describe communication options for the target resource.

---
--- An in-memory cache entry of a request made with `Request.cache`.
---
---@class http.client.SessionCache
---@field identifier string The cache key, a JSON of the request's method, url (with query parameters), body, content type and headers (without the cookie jar and etag ones).
---@field future Future The future of the cached request, awaited by repeated identical requests.
---@field start number The time (in seconds, `time.elapsed`) when the request was cached.
---@field age number The lifetime of the cache entry in seconds, may be shortened by the response's `max-age`.

---
--- Credentials for `http.Request.auth`.
---
--- `token` is sent as `Bearer <token>`, otherwise `username` and `password` as `Basic` authentication.
---
---@class http.Auth
---@field username? string The username for `Basic` authentication.
---@field password? string The password for `Basic` authentication.
---@field token? string The token for `Bearer` authentication.

---
--- The URL of a request as a string.
---
---@alias http.RequestURL
---| "http://" # Default protocol.
---| "https://" # Default secure protocol.
---| string # Absolute URL as a string.

---
--- The media type of a request body, sent as the `Content-Type` header.
---
---@alias http.ContentType
---| "text/plain; charset=utf-8"
---| "text/html; charset=utf-8"
---| "text/css; charset=utf-8"
---| "text/csv; charset=utf-8"
---| "text/javascript; charset=utf-8"
---| "application/json; charset=utf-8"
---| "application/xml; charset=utf-8"
---| "application/x-www-form-urlencoded"
---| "multipart/form-data"
---| "application/yaml; charset=utf-8"
---| "application/octet-stream"
---| "application/pdf"
---| "application/zip"
---| "application/x-pem-file"
---| "application/jwt"
---| "application/vnd.api+json; charset=utf-8"
---| "image/png"
---| "image/jpeg"
---| "image/gif"
---| "audio/mpeg"
---| "audio/ogg"
---| "video/mp4"
---| "video/webm"
---| string

---
--- The key-value parameters of a request, sent in the URL query or as a form body.
---
---@alias http.Parameters table<string, string>

---
--- Well-known request header names.
---
---@alias http.RequestHeader
---| "Host" # The domain name of the server and the TCP port number (mandatory in HTTP/1.1).
---| "User-Agent" # Identifies the client application, operating system, and browser vendor.
---| "Authorization" # Contains the credentials or tokens needed to authenticate a client with a server.
---| "Accept" # Informs the server about the types of media/data formats the client can process (e.g., text/html, application/json).
---| "Accept-Language" # Tells the server which language preferences the client has.
---| "Accept-Encoding" # Details the data compression algorithms (like gzip or deflate) the client supports.
---| "Cookie" # Sends stored HTTP cookies previously delivered by the server via Set-Cookie.
---| "Referer" # Contains the address of the previous web page from which a link to the current page was followed.
---| "Content-Type" # Indicates the media type of the request body (e.g., application/json; charset=UTF-8).
---| "Content-Length" # Indicates the size of the request body in bytes.
---| "Content-Encoding" # Used to determine what compression algorithm has been applied to the request body.
---| "Content-Language" # Describes the intended natural language(s) for the audience of the request body.
---| "Cache-Control" # Directives for caching mechanisms (e.g., no-cache, max-age=3600).
---| "Connection" # Controls whether the network connection stays open after the current transaction finishes (e.g., keep-alive).
---| string

---
--- The key-value table of request headers.
---
---@alias http.RequestHeaders table<http.RequestHeader, string>

---
--- Well-known response header names, always lowercase.
---
---@alias http.ResponseHeader
---| "server" # Contains information about the software used by the originating server to handle the request.
---| "set-cookie" # Used to send cookies from the server to the client so the client can store them.
---| "location" # Used during redirections to indicate the URL the client should visit next.
---| "www-authenticate" # Defines the authentication method that should be used to gain access to a resource.
---| "retry-after" # Tells the client how long to wait before making another request (often used with 503 or 429 status codes).
---| "content-type" # Indicates the original media type of the resource (e.g., application/json; charset=UTF-8).
---| "content-length" # Indicates the size of the message body sent to the recipient in bytes.
---| "content-encoding" # Used to determine what compression algorithm has been applied to the payload.
---| "content-language" # Describes the intended natural language(s) for the audience of the enclosed body.
---| "content-security-policy" # Restricts the resources (like JavaScript, CSS, Images) that the browser is allowed to load for a given page.
---| "strict-transport-security" # Forces the browser to communicate with the server exclusively over secure HTTPS.
---| "x-content-type-options" # Setting this to nosniff prevents browsers from MIME-sniffing away from the declared `content-type`.
---| "transfer-encoding" # Specifies the form of encoding used to safely transfer the payload.
---| "cache-control" # Directives for caching mechanisms (e.g., no-cache, max-age=3600).
---| "etag" # A unique identifier for a specific version of a resource, used to make caching more efficient.
---| "connection" # Controls whether the network connection stays open after the current transaction finishes (e.g., keep-alive).
---| string

---
--- The key-value table of response headers.
---
---@alias http.ResponseHeaders table<http.ResponseHeader, string>

---
--- The HTTP response status code.
---
---@alias http.ResponseCode
---| 100 # continue
---| 101 # switching protocols
---| 102 # processing
---| 103 # early hints
---| 200 # ok / success
---| 201 # created
---| 202 # accepted
---| 203 # non-authoritative information
---| 204 # no content
---| 205 # reset content
---| 206 # partial content
---| 207 # multi-status
---| 208 # already reported
---| 226 # im used
---| 300 # multiple choices
---| 301 # moved permanently
---| 302 # found (temporary redirect)
---| 303 # see other
---| 304 # not modified
---| 305 # use proxy (deprecated)
---| 306 # unused (reserved)
---| 307 # temporary redirect
---| 308 # permanent redirect
---| 400 # bad request
---| 401 # unauthorized
---| 402 # payment required
---| 403 # forbidden
---| 404 # not found
---| 405 # method not allowed
---| 406 # not acceptable
---| 407 # proxy authentication required
---| 408 # request timeout
---| 409 # conflict
---| 410 # gone
---| 411 # length required
---| 412 # precondition failed
---| 413 # content too large
---| 414 # uri too long
---| 415 # unsupported media type
---| 416 # range not satisfiable
---| 417 # expectation failed
---| 418 # i'm a teapot (joke, reserved)
---| 421 # misdirected request
---| 422 # unprocessable content
---| 423 # locked
---| 424 # failed dependency
---| 425 # too early
---| 426 # upgrade required
---| 428 # precondition required
---| 429 # too many requests
---| 431 # request header fields too large
---| 451 # unavailable for legal reasons
---| 500 # internal server error
---| 501 # not implemented
---| 502 # bad gateway
---| 503 # service unavailable
---| 504 # gateway timeout
---| 505 # http version not supported
---| 506 # variant also negotiates
---| 507 # insufficient storage
---| 508 # loop detected
---| 510 # not extended (obsoleted)
---| 511 # network authentication required


---
--- Options table for `http.client.request` function.
---
---@class http.Request
local Request = {}

---
--- Request method.
---
---@type http.RequestMethod | nil
Request.method = nil

---
--- Request URL.
---
---@type http.RequestURL | URL
Request.url = nil

---
--- KeyValue table for parameters.
---
--- Appended to the URL query for **GET**, **HEAD** and **OPTIONS**,
--- or sent as an `application/x-www-form-urlencoded` body for other methods (unless `body` is set,
--- any other `content_type` is an error).
---
--- `URL.SearchParams` keep repeated names and their order, plain tables are sorted by name
--- and pairs with non-string names or values are skipped.
---
---@type http.Parameters | URL.SearchParams | nil
Request.parameters = nil

---
--- Body string for POST data.
---
--- If set, will override parameters.
---
---@type string?
Request.body = nil

---
--- A value serialized as the JSON body, cannot be used together with `body`.
---
--- Sets `content_type` to `"application/json; charset=utf-8"` unless it is given.
---
---@type json.Value | nil
Request.json = nil

---
--- Content type for body.
---
---@type http.ContentType | nil
Request.content_type = "text/plain; charset=utf-8"

---
--- KeyValue table for headers.
---
---@type http.RequestHeaders | nil
Request.headers = nil

---
--- The timeout for the connection in seconds.
---
--- Defaults to `http.client.config.timeout`, set by `http_client timeout` (`10` seconds).
---
--- `0` means no timeout.
---
--- The request also fails on the Lua side one second after the timeout,
--- so a client that never calls back can't hang the coroutine.
---
---@type number | nil
Request.timeout = 10

---
--- Whether to cache the Response.
---
---@type boolean | nil
Request.cache = false

---
--- The cache time to live for the Request.
---
---@type number | nil
Request.cache_ttl = nil

---
--- Whether to use ETag caching, only applies to `GET` requests.
---
---@type boolean | nil
Request.etag = false

---
--- The credentials sent as the `Authorization` header, unless it is already in `headers`.
---
---@type http.Auth | nil
Request.auth = nil

---
--- The cookie jar, matching cookies are sent in the `Cookie` header
--- (after the one from `headers`) and `set-cookie` from the response is stored in it.
---
--- Cookies set by redirect responses are only stored with `chttp`, where redirects are followed in Lua,
--- `reqwest` and `HTTP` follow redirects on their own. `reqwest` also passes only the last `Set-Cookie` header.
---
---@type http.CookieJar | nil
Request.cookies = nil

---
--- The most redirects followed in Lua, more fail the request with `"too many redirects"`.
---
--- Defaults to `http.client.config.max_redirects`, set by `http_client max_redirects` (`10` redirects).
---
--- Only applies when redirects are followed in Lua, with `cookies` and the `chttp` client,
--- other clients follow redirects on their own with their own limits.
---
---@type integer | nil
Request.max_redirects = 10


---
--- The response of a finished request.
---
---@class http.Response
local Response = {}

---
--- The Response status code.
---
---@type integer
Response.status = nil

---
--- The Response body.
---
---@type string
Response.body = nil

---
--- The Response headers, names are lowercase.
---
---@type http.ResponseHeaders
Response.headers = nil
