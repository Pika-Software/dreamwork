---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
local engine_nextTick = dreamwork_engine.nextTick

local exceptions_call = dreamwork.exceptions.call
local dreamwork_Logger = dreamwork.Logger

local std = dreamwork.std

local isFunction = std.isFunction
local loadbinary = std.loadbinary


--- [SHARED AND MENU]
---
--- HTTP request engine, wraps the best available client:
--- `reqwest`, `chttp` or the built-in `HTTP` function (in that order of priority).
---
--- Requests made before the first tick are queued and sent on the next tick.
---
---@class dreamwork.engine.http
---@field ClientName "reqwest" | "chttp" | "garrysmod" | "" The name of the loaded HTTP client, empty if none was found.
---@field UserAgent string The default `User-Agent` header value, applied to `reqwest` requests that don't set one.
local http = {
    UserAgent = "DreamWork/" .. dreamwork.Version .. " - Garry's Mod/" .. std.GAME_VERSION
}

dreamwork_engine.http = http

--- The name of the loaded HTTP client, empty if none was found.
---
---@type "reqwest" | "chttp" | "garrysmod" | ""
local client_name = ""

--- Sends a request using the loaded client, returns `false` if sending failed.
---
---@type fun( options: ( garrysmod.http.Request | gm_chttp.Request | gm_reqwest.Request ) ): boolean
local client_fn

if loadbinary( "reqwest" ) then
    local reqwest = reqwest

    ---@type table<dreamwork.std.http.RequestHeader, string>
    local default_headers = {
        [ "User-Agent" ] = http.UserAgent,
    }

    --- Adds the default `User-Agent` header and sends the request through `reqwest`.
    ---
    ---@param options gm_reqwest.Request
    ---@return boolean success Always `true`, `reqwest` reports errors via `options.failed`.
    function client_fn( options )
        if options.headers == nil then
            options.headers = default_headers
        elseif options.headers[ "User-Agent" ] == nil then
            options.headers[ "User-Agent" ] = http.UserAgent
        end

        reqwest( options )
        return true
    end

    client_name = "reqwest"
elseif loadbinary( "chttp" ) then
    client_fn = CHTTP
    client_name = "chttp"
elseif isFunction( HTTP ) then
    client_fn = HTTP
    client_name = "garrysmod"
end

http.ClientName = client_name

if client_fn == nil then
    dreamwork_Logger:error( "HTTP client '%s' loading failed, sending requests is not possible.", client_name )
    function client_fn() return false end
else
    dreamwork_Logger:info( "'%s' was loaded & connected as HTTP client.", client_name )
end

do

    --- Requests waiting for the first tick, `[ 0 ]` holds the queue size.
    ---
    ---@type garrysmod.http.Request[]
    local request_queue = { [ 0 ] = 0 }

    --- Queues the request until the first tick, then replaced by the client function.
    ---
    ---@param options garrysmod.http.Request
    ---@return boolean success
    local function make_request( options )
        local queue_size = request_queue[ 0 ] + 1
        request_queue[ queue_size ] = options
        request_queue[ 0 ] = queue_size
        return true
    end

    engine_nextTick( function()
        make_request = client_fn

        for i = 1, request_queue[ 0 ], 1 do
            local options = request_queue[ i ]
            request_queue[ i ] = nil

            local success, result = exceptions_call( client_fn, options )
            if success and not result then
                options.failed( "failed to connect to '" .. client_name .. "' http client" )
            end
        end
    end )

    --- [SHARED AND MENU]
    ---
    --- Sends an HTTP request using the loaded client.
    ---
    --- If the client fails to accept the request, `options.failed` is called with an error message.
    ---
    ---@param options garrysmod.http.Request The request options.
    ---@return boolean success `true` if the request was sent or queued, `false` if no client is available.
    function http.request( options )
        return make_request( options )
    end

end
