local dreamwork_getUpTime = dreamwork.getUpTime
local dreamwork_storage = dreamwork.storage
local dreamwork_engine = dreamwork.engine

local engine_http = dreamwork_engine.http

local http_ClientName = engine_http.ClientName
local http_request = engine_http.request

local storage_http = dreamwork_storage.http
local storage_write = storage_http.write
local storage_read = storage_http.read

local Logger = dreamwork.Logger

local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber
local raw_tostring = raw.tostring

local string = std.string
local string_find = string.find
local string_upper = string.upper
local string_lower = string.lower
local string_format = string.format
local string_gmatch = string.gmatch

local table = std.table
local table_sort = table.sort

local json = std.json
local json_serialize = json.serialize

local base64 = std.base64
local base64_encode = base64.encode

local error = std.error
local pcall = std.pcall
local pairs = std.pairs
local isString = std.isString
local isNumber = std.isNumber
local isURLSearchParams = std.isURLSearchParams
local setTimeout = std.setTimeout
local clearTimeout = std.clearTimeout

local HTTPError = std.HTTPError
local Future = std.Future
local URL = std.URL

local URL_SearchParams = URL.SearchParams
local URL_decodeURIComponent = URL.decodeURIComponent


---@class dreamwork.std.http
local http = std.http

--- [SHARED AND MENU]
---
---
---
---@class dreamwork.std.http.client
local client = {}
http.client = client

---@class dreamwork.std.http.client.Config
---@field timeout number The default timeout for http requests in seconds.
---@field cache_ttl number The default time to live of the session cache in minutes.
---@field cache_entries integer The maximum number of responses kept in the session cache, `0` disables it.
---@field max_redirects integer The default maximum number of redirects followed in Lua (with cookies and chttp).

--- [SHARED AND MENU]
---
--- The defaults of the http client, set by the `http_client` console command (`dreamwork_sci` / `dreamwork_cci`).
---
---@type dreamwork.std.http.client.Config
local config = {
    timeout = 10,
    cache_ttl = 1,
    cache_entries = 256,
    max_redirects = 10
}

client.config = config

--- Extra seconds the Lua-side timeout waits on top of the request timeout,
--- so the client's own timeout error comes first when it works.
local TIMEOUT_GRACE = 1

---@type table<string, boolean>
local supported_methods = {
    [ "HEAD" ] = true,
    [ "GET" ] = true,
    [ "POST" ] = true,
    [ "PUT" ] = true,
    [ "PATCH" ] = true,
    [ "DELETE" ] = true,
    [ "OPTIONS" ] = true
}

---@type table<string, boolean>
local query_methods = {
    [ "HEAD" ] = true,
    [ "GET" ] = true,
    [ "OPTIONS" ] = true
}

--- Response header names differ in case between clients,
--- so they are always lowercased, repeated names are joined with `", "`.
---
---@param headers table<string, string> | nil
---@return dreamwork.std.http.ResponseHeaders
local function normalize_headers( headers )
    if headers == nil then
        return {}
    end

    -- `reqwest` already lowercases names and keeps one value per name
    if http_ClientName == "reqwest" then
        return headers
    end

    ---@type dreamwork.std.http.ResponseHeaders
    local normalized = {}

    for name, value in raw_pairs( headers ) do
        local lower_name = string_lower( name )

        local previous = normalized[ lower_name ]
        if previous == nil then
            normalized[ lower_name ] = value
        else
            normalized[ lower_name ] = previous .. ", " .. value
        end
    end

    return normalized
end

---@param a { [1]: string, [2]: string }
---@param b { [1]: string, [2]: string }
---@return boolean
local function compare_pairs( a, b )
    local a_name, b_name = a[ 1 ], b[ 1 ]
    if a_name == b_name then
        return a[ 2 ] < b[ 2 ]
    end

    return a_name < b_name
end

--- Collects the string pairs of a table sorted by name,
--- so equal tables always give the same order, non-string pairs are skipped like the clients do.
---
---@param tbl table
---@param lowercase boolean
---@return { [1]: string, [2]: string }[]
local function sorted_pairs( tbl, lowercase )
    local list, count = {}, 0

    for name, value in pairs( tbl ) do
        if isString( name ) and isString( value ) then
            count = count + 1

            if lowercase then
                list[ count ] = { string_lower( name ), value }
            else
                list[ count ] = { name, value }
            end
        end
    end

    if count > 1 then
        table_sort( list, compare_pairs )
    end

    return list
end

--- Serializes parameters as `application/x-www-form-urlencoded`,
--- plain tables are sorted, so the same parameters give the same url for caching.
---
---@param parameters dreamwork.std.http.Parameters | dreamwork.std.URL.SearchParams
---@return string
local function serialize_parameters( parameters )
    if isURLSearchParams( parameters ) then
        return raw_tostring( parameters )
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    return raw_tostring( URL_SearchParams( sorted_pairs( parameters, false ) ) )
end

---@param response dreamwork.std.http.Response
---@return dreamwork.std.http.Response
local function copy_response( response )
    ---@type dreamwork.std.http.ResponseHeaders
    local headers = {}

    for name, value in raw_pairs( response.headers ) do
        headers[ name ] = value
    end

    return {
        status = response.status,
        body = response.body,
        headers = headers
    }
end

---@type table<string, dreamwork.std.http.client.SessionCache>
local session_cache = {}

local session_cache_count = 0

---@param method string
---@param url string
---@param body string | nil
---@param content_type string | nil
---@param headers dreamwork.std.http.RequestHeaders
---@return string
local function cache_identifier( method, url, body, content_type, headers )
    return json_serialize( { method, url, body or false, content_type or false, sorted_pairs( headers, true ) }, false )
end

--- Once the cache is full, expired entries are removed first, then the oldest one.
---
--- A lowered limit is reached gradually, one eviction per insert.
---
---@param entry dreamwork.std.http.client.SessionCache
---@param now number
local function cache_insert( entry, now )
    local identifier = entry.identifier

    if session_cache[ identifier ] == nil then
        local limit = config.cache_entries
        if limit <= 0 then return end

        if session_cache_count >= limit then
            ---@type string | nil
            local oldest_identifier

            local oldest_start = now

            for other_identifier, other in raw_pairs( session_cache ) do
                local start = other.start
                if (now - start) >= other.age then
                    session_cache[ other_identifier ] = nil
                    session_cache_count = session_cache_count - 1
                elseif start <= oldest_start then
                    oldest_identifier, oldest_start = other_identifier, start
                end
            end

            if session_cache_count >= limit and oldest_identifier ~= nil then
                session_cache[ oldest_identifier ] = nil
                session_cache_count = session_cache_count - 1
            end
        end

        session_cache_count = session_cache_count + 1
    end

    session_cache[ identifier ] = entry
end

---@param entry dreamwork.std.http.client.SessionCache
local function cache_remove( entry )
    local identifier = entry.identifier

    if session_cache[ identifier ] == entry then
        session_cache[ identifier ] = nil
        session_cache_count = session_cache_count - 1
    end
end

--- Keeps only successful responses, the lifetime can be shortened by `Cache-Control`.
---
---@param entry dreamwork.std.http.client.SessionCache
---@param response dreamwork.std.http.Response
local function cache_update( entry, response )
    local status = response.status
    if status < 200 or status > 299 then
        cache_remove( entry )
        return
    end

    local cache_control = response.headers[ "cache-control" ]
    if cache_control == nil then return end

    ---@type table<string, ( boolean | number )>
    local cache_options = {}

    for key, value in string_gmatch( string_lower( cache_control ), "([%w_-]+)=?\"?([%w_-]*)" ) do
        if string_find( value, "^%d+$" ) == nil then
            cache_options[ key ] = true
        else
            cache_options[ key ] = raw_tonumber( value, 10 )
        end
    end

    if cache_options[ "no-cache" ] or cache_options[ "no-store" ] then
        cache_remove( entry )
        return
    end

    -- `s-maxage` is meant for shared caches, this one is private
    local max_age = cache_options[ "max-age" ]
    if isNumber( max_age ) then
        ---@cast max_age number
        if max_age <= 0 then
            cache_remove( entry )
        elseif max_age < entry.age then
            entry.age = max_age
        end
    end
end

---@type table<integer, boolean>
local redirect_statuses = {
    [ 301 ] = true,
    [ 302 ] = true,
    [ 303 ] = true,
    [ 307 ] = true,
    [ 308 ] = true
}

--- Builds the options of the next request of a redirect, like browsers do:
--- `303` (and `301`/`302` after `POST`) switch to `GET` without a body,
--- credentials and the caller's `Cookie` header are not sent to another origin.
---
---@param options dreamwork.std.http.Request
---@param url dreamwork.std.URL
---@param method string
---@param body string | nil
---@param content_type string | nil
---@param status integer
---@param location string
---@return dreamwork.std.http.Request
local function redirect_options( options, url, method, body, content_type, status, location )
    local next_url = URL( location, url )

    ---@type dreamwork.std.http.Request
    local next_options = {}

    for key, value in raw_pairs( options ) do
        next_options[ key ] = value
    end

    next_options.url = next_url

    -- already serialized into the url or the body of the first request
    next_options.parameters = nil
    next_options.json = nil

    if (status == 303 and method ~= "HEAD") or ((status == 301 or status == 302) and method == "POST") then
        next_options.method = "GET"
        next_options.body = nil
        next_options.content_type = nil
    else
        next_options.method = method
        next_options.body = body
        next_options.content_type = content_type
    end

    if next_url.origin ~= url.origin then
        next_options.auth = nil

        local headers = options.headers
        if headers ~= nil then
            ---@type dreamwork.std.http.RequestHeaders
            local next_headers = {}

            for name, value in pairs( headers ) do
                local lower_name = string_lower( name )
                if lower_name ~= "authorization" and lower_name ~= "cookie" then
                    next_headers[ name ] = value
                end
            end

            next_options.headers = next_headers
        end
    end

    return next_options
end

---@param options dreamwork.std.http.Request
---@param redirects integer The number of redirects followed in Lua so far.
---@return dreamwork.std.http.Response
---@async
local function send_request( options, redirects )
    local method = options.method
    if method == nil then
        method = "GET"
    elseif isString( method ) then
        method = string_upper( method )
    end

    if not supported_methods[ method ] then
        error( string_format( "unsupported http method '%s'", raw_tostring( method ) ), 2 )
    end

    ---@type dreamwork.std.URL
    local url

    local url_value = options.url
    if isString( url_value ) then
        ---@cast url_value string
        url = URL( url_value )
    else
        ---@cast url_value dreamwork.std.URL
        url = url_value
    end

    -- credentials and fragment are never part of the sent url
    local url_search = url.search
    local url_string = string_format( "%s//%s%s%s", url.protocol, url.host, url.pathname, url_search )

    local body = options.body
    local content_type = options.content_type

    local json_value = options.json
    if json_value ~= nil then
        if body ~= nil then
            error( "`body` and `json` cannot be used together", 2 )
        end

        body = json_serialize( json_value, false )

        if content_type == nil then
            content_type = "application/json; charset=utf-8"
        end
    end

    -- parameters are serialized here, so every client sends repeated names and the same encoding
    local parameters = options.parameters
    if parameters ~= nil then
        local query = serialize_parameters( parameters )
        if query ~= "" then
            if query_methods[ method ] then
                if url_search == "" then
                    url_string = url_string .. "?" .. query
                else
                    url_string = url_string .. "&" .. query
                end
            elseif body == nil then
                if content_type == nil then
                    content_type = "application/x-www-form-urlencoded"
                elseif string_find( content_type, "^application/x%-www%-form%-urlencoded" ) == nil then
                    error( "parameters can only be sent as 'application/x-www-form-urlencoded', use `body` for '" .. content_type .. "'", 2 )
                end

                body = query
            end
        end
    end

    -- the content type describes the body only
    if body == nil then
        content_type = nil
    elseif content_type == nil then
        content_type = "text/plain; charset=utf-8"
    end

    -- request headers
    ---@type dreamwork.std.http.RequestHeaders
    local headers = {}

    local has_authorization, has_if_none_match, has_user_agent = false, false, false

    ---@type string | nil
    local cookie_name

    local options_headers = options.headers
    if options_headers ~= nil then
        for name, value in pairs( options_headers ) do
            headers[ name ] = value

            local lower_name = string_lower( name )
            if lower_name == "authorization" then
                has_authorization = true
            elseif lower_name == "cookie" then
                cookie_name = name
            elseif lower_name == "if-none-match" then
                has_if_none_match = true
            elseif lower_name == "user-agent" then
                has_user_agent = true
            end
        end
    end

    -- authorization header
    if not has_authorization then
        local auth = options.auth
        if auth == nil then
            local username, password = url.username, url.password
            if username ~= nil or password ~= nil then
                headers.Authorization = "Basic " .. base64_encode( URL_decodeURIComponent( username or "" ) .. ":" .. URL_decodeURIComponent( password or "" ) )
            end
        else
            local token = auth.token
            if token == nil then
                headers.Authorization = "Basic " .. base64_encode( (auth.username or "") .. ":" .. (auth.password or "") )
            else
                headers.Authorization = "Bearer " .. token
            end
        end
    end

    -- cache lookup, before the cookie and etag headers that change between identical requests
    ---@type string | nil
    local identifier

    local cache = options.cache == true
    if cache then
        identifier = cache_identifier( method, url_string, body, content_type, headers )

        local cache_entry = session_cache[ identifier ]
        if cache_entry ~= nil and (dreamwork_getUpTime() - cache_entry.start) < cache_entry.age then
            return copy_response( cache_entry.future:await() )
        end
    end

    -- user-agent header, read on every request, so changes to `engine.http.UserAgent` apply
    if not has_user_agent then
        headers[ "User-Agent" ] = engine_http.UserAgent
    end

    -- cookie header
    local cookies = options.cookies
    if cookies ~= nil then
        local header_value = cookies:header( url )
        if header_value ~= nil then
            if cookie_name == nil then
                headers.Cookie = header_value
            else
                headers[ cookie_name ] = headers[ cookie_name ] .. "; " .. header_value
            end
        end
    end

    -- etag header
    local etag_caching = options.etag == true and method == "GET"

    ---@type string | nil
    local etag_content

    if etag_caching and not has_if_none_match then
        local stored = storage_read( url_string )
        if stored ~= nil then
            headers[ "If-None-Match" ] = stored.etag
            etag_content = stored.content
        end
    end

    -- request timeout
    local timeout = options.timeout
    if not isNumber( timeout ) then
        timeout = config.timeout
    end

    ---@cast timeout number

    local future = Future()

    -- cache entry, inserted after everything that can throw, so it is never left pending
    ---@type dreamwork.std.http.client.SessionCache | nil
    local cache_entry

    if cache then
        ---@cast identifier string

        local cache_ttl = options.cache_ttl
        if not isNumber( cache_ttl ) then
            cache_ttl = config.cache_ttl * 60
        end

        ---@cast cache_ttl number

        local now = dreamwork_getUpTime()

        cache_entry = {
            identifier = identifier,
            future = future,
            start = now,
            age = cache_ttl
        }

        cache_insert( cache_entry, now )
    end

    ---@param status integer
    ---@param response_body string
    ---@param raw_headers table<string, string> | nil
    ---@return dreamwork.std.http.Response
    local function build_response( status, response_body, raw_headers )
        local response_headers = normalize_headers( raw_headers )

        -- the jar is updated before anything sees the response
        if cookies ~= nil then
            local set_cookie = response_headers[ "set-cookie" ]
            if set_cookie ~= nil then
                cookies:store( set_cookie, url )
            end
        end

        if etag_caching then
            if status == 304 then
                -- only the etag sent by this request has its content stored
                if etag_content ~= nil then
                    status, response_body = 200, etag_content
                end
            elseif status == 200 then
                local etag_value = response_headers.etag
                if etag_value ~= nil then
                    -- too large or binary bodies are just not cached
                    storage_write( url_string, etag_value, response_body, true )
                end
            end
        end

        return {
            status = status,
            body = response_body,
            headers = response_headers
        }
    end

    --- The Lua-side timeout, so a client that never calls back can't hang the coroutine.
    ---@type integer | nil
    local timeout_id

    -- `chttp` can stop at redirects, so they are followed here and the cookies of every hop are stored
    local follow_redirects = cookies ~= nil and http_ClientName == "chttp"

    ---@type garrysmod.http.Request | gm_reqwest.Request | gm_chttp.Request
    local request_options = {
        method = method,
        url = url_string,
        headers = headers,
        body = body,
        type = content_type,
        timeout = timeout
    }

    if follow_redirects then
        request_options.noredirect = true
    end

    function request_options.success( status, response_body, raw_headers )
        -- cancelled, timed out or already failed
        if not future:isPending() then return end

        if timeout_id ~= nil then
            clearTimeout( timeout_id )
        end

        local success, response = pcall( build_response, status, response_body, raw_headers )
        if not success then
            if cache_entry ~= nil then
                cache_remove( cache_entry )
            end

            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast response string

            future:setError( response )
            return
        end

        if cache_entry ~= nil then
            cache_update( cache_entry, response )
        end

        future:setResult( response )
    end

    ---@param reason string
    ---@param reason_ext string | nil `reqwest` only, the detailed error message.
    function request_options.failed( reason, reason_ext )
        if not future:isPending() then return end

        if timeout_id ~= nil then
            clearTimeout( timeout_id )
        end

        if cache_entry ~= nil then
            cache_remove( cache_entry )
        end

        future:setError( HTTPError( nil, url_string, reason_ext or reason ) )
    end

    Logger:debug( "%s HTTP request to '%s', using '%s', with timeout %f seconds.", method, url_string, http_ClientName, timeout )

    -- armed before sending, the client may call back synchronously
    if timeout > 0 then
        timeout_id = setTimeout( request_options.failed, timeout + TIMEOUT_GRACE, "timed out, the http client did not respond" )
    end

    local success, sent = pcall( http_request, request_options )
    if not success then
        request_options.failed( raw_tostring( sent ) )
    elseif sent == false then
        request_options.failed( "connection to '" .. http_ClientName .. "' http client was failed" )
    end

    ---@type dreamwork.std.http.Response
    local response = future:await()

    if follow_redirects then
        local status = response.status
        if redirect_statuses[ status ] then
            local location = response.headers.location
            if location ~= nil then
                -- copied into the options of every hop by `redirect_options`
                local max_redirects = options.max_redirects
                if not isNumber( max_redirects ) then
                    max_redirects = config.max_redirects
                end

                if redirects >= max_redirects then
                    error( HTTPError( status, url_string, "too many redirects" ), 2 )
                end

                return send_request( redirect_options( options, url, method, body, content_type, status, location ), redirects + 1 )
            end
        end
    end

    -- the cached response is shared, every caller gets its own copy
    if cache_entry ~= nil then
        return copy_response( response )
    end

    return response
end

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
---@see dreamwork.std.http.Request for the request options structure.
---@see dreamwork.std.http.Response for the response structure.
---
---@param options dreamwork.std.http.Request The request options.
---@return dreamwork.std.http.Response data The response.
---@async
function client.request( options )
    -- a tail call, so error levels inside point at the caller
    return send_request( options, 0 )
end

do

    local client_request = client.request

    --- [SHARED AND MENU]
    ---
    --- Sends a GET request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.get( url, headers, timeout )
        return client_request( {
            method = "GET",
            url = url,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends a POST request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param parameters? dreamwork.std.http.Parameters The body to send with the request.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.post( url, parameters, headers, timeout )
        return client_request( {
            method = "POST",
            url = url,
            parameters = parameters,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends a PUT request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param parameters? dreamwork.std.http.Parameters The body to send with the request.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.put( url, parameters, headers, timeout )
        return client_request( {
            method = "PUT",
            url = url,
            parameters = parameters,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends a PATCH request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param parameters? dreamwork.std.http.Parameters The body to send with the request.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.patch( url, parameters, headers, timeout )
        return client_request( {
            method = "PATCH",
            url = url,
            parameters = parameters,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends a DELETE request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.delete( url, headers, timeout )
        return client_request( {
            method = "DELETE",
            url = url,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends an OPTIONS request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.options( url, headers, timeout )
        return client_request( {
            method = "OPTIONS",
            url = url,
            headers = headers,
            timeout = timeout
        } )
    end

    --- [SHARED AND MENU]
    ---
    --- Sends a HEAD request.
    ---
    ---@param url dreamwork.std.http.RequestURL The URL to send the request to.
    ---@param headers? dreamwork.std.http.RequestHeaders The headers to send with the request.
    ---@param timeout? integer The timeout in seconds.
    ---@return dreamwork.std.http.Response response The response from the request.
    ---@async
    function client.head( url, headers, timeout )
        return client_request( {
            url = url,
            method = "HEAD",
            headers = headers,
            timeout = timeout
        } )
    end

end
