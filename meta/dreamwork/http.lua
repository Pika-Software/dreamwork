---@meta dreamwork.std.http


---@alias dreamwork.std.http.RequestMethod
---| "HEAD" # Same as `GET`, but only retrieves headers (no body).
---| "GET" # Retrieve data from a server.
---| "POST" # Send data to the server to create a resource.
---| "PUT" # Replace a resource entirely at the given URL.
---| "PATCH" # Partially update a resource.
---| "DELETE" # Remove a resource from the server.
---| "OPTIONS" # Describe communication options for the target resource.


--- [SHARED AND MENU]
---
--- HTTP Request URL.
---
---@alias dreamwork.std.http.RequestURL
---| dreamwork.std.URL # URL object.
---| string # Absolute URL as a string.
---| "http://" # Default protocol.
---| "https://" # Default secure protocol.


--- [SHARED AND MENU]
---
--- HTTP Request content type.
---
---@alias dreamwork.std.http.Request.content_type
---| string
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


--- [SHARED AND MENU]
---
--- HTTP Request headers.
---
---@alias dreamwork.std.http.Request.headers table<string, string>


--- [SHARED AND MENU]
---
--- HTTP Request parameters.
---
---@alias dreamwork.std.http.Request.parameters dreamwork.std.URL.SearchParams | table | nil


--- [SHARED AND MENU]
---
--- Options table for `http.Request` function.
---
---@class dreamwork.std.http.Request
local Request = {}

--- Request method.
---
---@type dreamwork.std.http.RequestMethod
Request.method = nil

--- Request URL.
---
---@type dreamwork.std.http.RequestURL
Request.url = nil

--- KeyValue table for parameters.
---
--- This is only applicable to the following Request methods: **HEAD**, **GET**, **POST**
---
---@type dreamwork.std.http.Request.parameters
Request.parameters = nil

--- Body string for POST data.
---
--- If set, will override parameters.
---
---@type string?
Request.body = nil

--- Content type for body.
---
---@type dreamwork.std.http.Request.content_type?
Request.content_type = "text/plain; charset=utf-8"

--- KeyValue table for headers.
---
---@type dreamwork.std.http.Request.headers?
Request.headers = nil

--- The timeout for the connection in seconds.
---
--- The default timeout is 60 seconds.
---
--- `0` means no timeout.
---
---@type integer?
Request.timeout = 60

--- Whether to cache the Response.
---
---@type boolean?
Request.cache = false

--- The cache time to live for the Request.
---
---@type number?
Request.cache_ttl = nil

--- Whether to use ETag caching.
---
---@type boolean?
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
---@type dreamwork.std.http.Request.headers
Response.headers = nil
