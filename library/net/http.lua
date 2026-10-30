---@meta _

--- [SHARED AND MENU]
---
--- The http library allows either the server or client to communicate with external websites via HTTP.
---
---@class http
http = {}

--- [SHARED AND MENU]
---
--- The table that converts HTTP status codes into their descriptions.
---
---@type table<integer, string>
http.StatusCodes = {}

---@class Cookies : Object
---@field __class CookiesClass
local Cookies = {}

function Cookies:get(name, url) end

function Cookies:set(name, value, options) end

---@class CookiesClass : Cookies
---@field __base Cookies
---@overload fun(): Cookies
local CookiesClass = {}

http.Cookies = CookiesClass

---@class http.Request.session_cache
---@field future Future
---@field start number
---@field age number

--- [SHARED AND MENU]
---
--- Executes an asynchronous http request with the given options.
---
---@param options http.Request The request options.
---@return http.Response data The response.
---@see http.Request for the request options structure.
---@see http.Response for the response structure.
---@async
function http.request(options) end

--- [SHARED AND MENU]
---
--- Sends a GET request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers? http.RequestHeaders The headers to send with the request.
---@param timeout? integer The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.get(url, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a POST request.
---
---@param url http.RequestURL The URL to send the request to.
---@param parameters? http.Parameters The body to send with the request.
---@param headers? http.RequestHeaders The headers to send with the request.
---@param timeout? integer The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.post(url, parameters, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a HEAD request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers? http.RequestHeaders The headers to send with the request.
---@param timeout? integer The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.head(url, headers, timeout) end

--- [MENU]
---
--- Gets miscellaneous information from Facepunches API.
---
---@param timeout number? The timeout in seconds.
---@return table data The data returned from the API.
---@nodiscard
---@async
function http.getFacepunchManifest(timeout) end
