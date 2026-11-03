---@meta garrysmod.http


---@alias garrysmod.http.RequestMethod
---| "GET"
---| "POST"
---| "HEAD"
---| "PUT"
---| "DELETE"
---| "PATCH"
---| "OPTIONS"


---@alias garrysmod.http.RequestURL "http://" | "https://" | string


---@class garrysmod.http.Request
---@field method garrysmod.http.RequestMethod | nil Request method, case insensitive. Any valid HTTP method is accepted; defaults to `"GET"`, also used when the method is invalid.
---@field url garrysmod.http.RequestURL The target url. Only `http://` and `https://` are allowed; anything else (or a non-string) fails with `"invalid url or GET parameters"`.
---@field parameters table<string, string> | nil KeyValue table for parameters. Sent as a URL query string for `GET`, `HEAD` and `OPTIONS`, and as a form body for `POST`, `PUT`, `DELETE` and `PATCH`. Pairs whose key or value is not a string (numbers included) are skipped.
---@field headers table<string, string> | nil KeyValue table for headers. Pairs with non-string keys or values are skipped. If no `User-Agent` is given, `"Valve/Steam HTTP Client 1.0 (4000)"` is sent to mimic `HTTP`.
---@field body string | nil Raw request body for `POST`, `PUT`, `DELETE` and `PATCH`, may contain binary data. If non-empty, will **override parameters**. Ignored for other methods.
---@field type string | nil Content type for `body`, sent as `Content-Type` only when `body` is used. A `Content-Type` in `headers` takes precedence. Defaults to `"text/plain; charset=utf-8"`.
---@field timeout number | nil The timeout for the whole request in seconds, truncated to an integer. Defaults to `60`; `0` disables the timeout.
---@field success fun( status_code: integer, body: string, headers: table<string, string> ) | nil
---@field failed fun( reason: string ) | nil


--- [SHARED AND MENU]
---
--- Launches an asynchronous http request with the given parameters.
---
---@param request garrysmod.http.Request
---@return boolean is_sent `true` if a request is queued, `false` if a request could not be queued. (i.e. When not giving a table or the game is ran with `-disablehttp`)
function HTTP( request ) end

--- [SHARED AND MENU]
---
--- Gets miscellaneous information from Facepunches API.
---
---@param callback fun( json: string )
function GetAPIManifest( callback ) end
