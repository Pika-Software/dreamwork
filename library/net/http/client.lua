---@meta _

--- [SHARED AND MENU]
---
---
---
---@class http.client
http.client = {}

---@class http.client.Config
---@field timeout number The default timeout for http requests in seconds.
---@field cache_ttl number The default time to live of the session cache in minutes.
---@field cache_entries integer The maximum number of responses kept in the session cache, `0` disables it.
---@field max_redirects integer The default maximum number of redirects followed in Lua (with cookies and chttp).

--- [SHARED AND MENU]
---
--- The defaults of the http client, set by the `http_client` console command (`dreamwork_sci` / `dreamwork_cci`).
---
---@type http.client.Config
http.client.config = nil

--- [SHARED AND MENU]
---
--- Executes an asynchronous http request with the given options.
---
--- Response header names are always lowercase.
---
--- Responses of `cache` requests are copies, so they can be changed freely.
---
--- With `cookies` and the `chttp` client, redirects are followed in Lua (up to `max_redirects`),
--- so the cookies set by every redirect response are stored.
---
---@see http.Request for the request options structure.
---@see http.Response for the response structure.
---
---@param options http.Request The request options.
---@return http.Response data The response.
---@async
function http.client.request(options) end

--- [SHARED AND MENU]
---
--- Sends a GET request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.get(url, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a POST request.
---
---@param url http.RequestURL The URL to send the request to.
---@param parameters http.Parameters? The body to send with the request.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.post(url, parameters, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a PUT request.
---
---@param url http.RequestURL The URL to send the request to.
---@param parameters http.Parameters? The body to send with the request.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.put(url, parameters, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a PATCH request.
---
---@param url http.RequestURL The URL to send the request to.
---@param parameters http.Parameters? The body to send with the request.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.patch(url, parameters, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a DELETE request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.delete(url, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends an OPTIONS request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.options(url, headers, timeout) end

--- [SHARED AND MENU]
---
--- Sends a HEAD request.
---
---@param url http.RequestURL The URL to send the request to.
---@param headers http.RequestHeaders? The headers to send with the request.
---@param timeout integer? The timeout in seconds.
---@return http.Response response The response from the request.
---@async
function http.client.head(url, headers, timeout) end
