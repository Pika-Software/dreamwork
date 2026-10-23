---@meta garrysmod.http


---@class garrysmod.http.RequestMethod
---| "GET" | "POST" | "HEAD" | "PUT"
---| "DELETE" | "PATCH" | "OPTIONS"


---@alias garrysmod.http.RequestURL "http://" | "https://" | string


---@class garrysmod.http.Request
---@field failed fun( reason: string ) | nil
---@field success fun( status_code: integer, body: string, headers: table<string, string> ) | nil
---@field method garrysmod.http.RequestMethod | nil Request method, case insensitive.
---@field url garrysmod.http.RequestURL The target url.
---@field parameters table<string, string> | nil KeyValue table for URL parameters. GET, POST, HEAD only.
---@field headers table<string, string> | nil KeyValue table for headers.
---@field body string | nil Body string for POST data. If set, will **override parameters**.
---@field type string | nil Content type for body.
---@field timeout number | nil The timeout for the connection in seconds.


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
