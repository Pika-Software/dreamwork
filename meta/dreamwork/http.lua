---@meta dreamwork.std.http


---@class dreamwork.std.http.RequestMethod
---| "HEAD" # Same as `GET`, but only retrieves headers (no body).
---| "GET" # Retrieve data from a server.
---| "POST" # Send data to the server to create a resource.
---| "PUT" # Replace a resource entirely at the given URL.
---| "PATCH" # Partially update a resource.
---| "DELETE" # Remove a resource from the server.
---| "OPTIONS" # Describe communication options for the target resource.


---@alias dreamwork.std.http.RequestURL
---| "http://" # Default protocol.
---| "https://" # Default secure protocol.
---| string # Absolute URL as a string.


---@alias dreamwork.std.http.ContentType
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


---@alias dreamwork.std.http.Parameters table<string, string>


---@alias dreamwork.std.http.SharedHeader
---| "Content-Type" # Indicates the original media type of the resource (e.g., application/json; charset=UTF-8).
---| "Content-Length" # Indicates the size of the message body sent to the recipient in bytes.
---| "Content-Encoding" # Used to determine what compression algorithm has been applied to the payload.
---| "Content-Language" # Describes the intended natural language(s) for the audience of the enclosed body.


---@alias dreamwork.std.http.SecurityHeader
---| "Content-Security-Policy" # Restricts the resources (like JavaScript, CSS, Images) that the browser is allowed to load for a given page.
---| "Strict-Transport-Security" # Forces the browser to communicate with the server exclusively over secure HTTPS.
---| "X-Content-Type-Options" # Setting this to nosniff prevents browsers from MIME-sniffing away from the declared Content-Type.
---| "Transfer-Encoding" # Specifies the form of encoding used to safely transfer the payload.


---@alias dreamwork.std.http.CacheHeader
---| "Cache-Control" # Directives for caching mechanisms in both requests and responses (e.g., no-cache, max-age=3600).
---| "ETag" # A unique identifier for a specific version of a resource, used to make caching more efficient.
---| "Connection" # Controls whether the network connection stays open after the current transaction finishes (e.g., keep-alive).


---@alias dreamwork.std.http.RequestHeader
---| "Host" # The domain name of the server and the TCP port number (mandatory in HTTP/1.1).
---| "User-Agent" # Identifies the client application, operating system, and browser vendor.
---| "Authorization" # Contains the credentials or tokens needed to authenticate a client with a server.
---| "Accept" # Informs the server about the types of media/data formats the client can process (e.g., text/html, application/json).
---| "Accept-Language" # Tells the server which language preferences the client has.
---| "Accept-Encoding" # Details the data compression algorithms (like gzip or deflate) the client supports.
---| "Cookie" # Sends stored HTTP cookies previously delivered by the server via Set-Cookie.
---| "Referer" # Contains the address of the previous web page from which a link to the current page was followed.
---| dreamwork.std.http.SharedHeader
---| string

---@alias dreamwork.std.http.RequestHeaders table<dreamwork.std.http.RequestHeader, string>


---@alias dreamwork.std.http.ResponseHeader
---| "Server" # Contains information about the software used by the originating server to handle the request.
---| "Set-Cookie" # Used to send cookies from the server to the client so the client can store them.
---| "Location" # Used during redirections to indicate the URL the client should visit next.
---| "WWW-Authenticate" # Defines the authentication method that should be used to gain access to a resource.
---| "Retry-After" # Tells the client how long to wait before making another request (often used with 503 or 429 status codes).
---| dreamwork.std.http.SharedHeader
---| dreamwork.std.http.SecurityHeader
---| string


---@alias dreamwork.std.http.ResponseHeaders table<dreamwork.std.http.ResponseHeader, string>


---@alias dreamwork.std.http.ResponseCode
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


--- [SHARED AND MENU]
---
--- Options table for `http.Request` function.
---
---@class dreamwork.std.http.Request
local Request = {}

--- Request method.
---
---@type dreamwork.std.http.RequestMethod | nil
Request.method = nil

--- Request URL.
---
---@type dreamwork.std.http.RequestURL
Request.url = nil

--- KeyValue table for parameters.
---
--- This is only applicable to the following Request methods: **HEAD**, **GET**, **POST**
---
---@type dreamwork.std.http.Parameters | nil
Request.parameters = nil

--- Body string for POST data.
---
--- If set, will override parameters.
---
---@type string?
Request.body = nil

--- Content type for body.
---
---@type dreamwork.std.http.ContentType | nil
Request.content_type = "text/plain; charset=utf-8"

--- KeyValue table for headers.
---
---@type dreamwork.std.http.RequestHeaders | nil
Request.headers = nil

--- The timeout for the connection in seconds.
---
--- The default timeout is 60 seconds.
---
--- `0` means no timeout.
---
---@type integer | nil
Request.timeout = 60

--- Whether to cache the Response.
---
---@type boolean | nil
Request.cache = false

--- The cache time to live for the Request.
---
---@type number | nil
Request.cache_ttl = nil

--- Whether to use ETag caching.
---
---@type boolean | nil
Request.etag = false


--- [SHARED AND MENU]
---
--- The success callback.
---
---@class dreamwork.std.http.Response
local Response = {}

--- The Response status code.
---
---@type integer
Response.status = nil

--- The Response body.
---
---@type string
Response.body = nil

--- The Response headers.
---
---@type dreamwork.std.http.RequestHeaders
Response.headers = nil
