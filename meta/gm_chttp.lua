---@meta gm_chttp

--- [SHARED AND MENU]
---
--- Version of the loaded `gmsv_chttp` binary module.
---
---@type string
CHTTP_VERSION = nil

--- [SHARED AND MENU]
---
--- Request table for `CHTTP`, compatible with the one used by `HTTP`.
---
---@class gm_chttp.Request : garrysmod.http.Request
---@field noredirect boolean | nil If `true`, `3xx` redirects are not followed and the redirect response itself is passed to `success`. Not available in `HTTP`.
---@field success nil | fun( status_code: integer, body: string, headers: table<string, string> ) Called when a response is received (with any status code). After redirects, this is the final response. Header names keep the case sent by the server; repeated headers are joined with `","`.
---@field failed nil | fun( reason: string ) Called when the request could not be completed. `reason` is the libcurl error message (e.g. `"Timeout was reached"`), `"invalid method"`, `"invalid url or GET parameters"`, or the reason returned by the `OnCHTTPRequest` hook. If missing, the failure is printed as a console warning.

--- [SHARED AND MENU]
---
--- Drop-in replacement for `HTTP` from the [gmod-chttp](https://github.com/timschumi/gmod-chttp) binary module, built on libcurl.
---
--- Available after `require( "chttp" )`. The request is sent on a worker thread and callbacks are called from a zero-delay timer on the main thread, so requests also work in singleplayer and while the server is hibernating.
---
--- Before the request is sent, the `OnCHTTPRequest` hook is called with the `request` table. The hook can edit the table to change the request, or return a `string` to cancel it; that string is then passed to `failed` (an empty string becomes `"request rejected by hook"`).
---
--- Errors in the request (invalid method, url, ...) are reported through `failed`, not raised as Lua errors.
---
--- On Linux the CA bundle is searched for in the usual system locations; it can be overridden with the `CHTTP_CAINFO` environment variable.
---
--- ```lua
--- CHTTP( {
---     url = "https://example.com",
---     success = function( status_code, body, headers ) print( status_code, #body ) end,
---     failed = function( reason ) print( reason ) end
--- } )
--- ```
---
--- [View documents](https://github.com/timschumi/gmod-chttp)
---
---@param request gm_chttp.Request
---@return true is_sent Always `true`; failures are reported through `failed`. Raises a Lua error if `request` is not a table.
function CHTTP( request ) end
