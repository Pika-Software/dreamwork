local dreamwork_load = dreamwork.load

local dreamwork_storage = dreamwork.storage
local storage_delete = dreamwork_storage.delete
local storage_readJSON = dreamwork_storage.readJSON
local storage_writeJSON = dreamwork_storage.writeJSON

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_get = raw.get
local raw_tonumber = raw.tonumber

local string = std.string
local string_len = string.len
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_lower = string.lower
local string_match = string.match
local string_gmatch = string.gmatch
local string_format = string.format

local table = std.table
local table_sort = table.sort
local table_concat = table.concat
local table_remove = table.remove

local time = std.time
local time_now = time.now
local time_timestampFromCivil = time.timestampFromCivil

local class = std.class

local isString = std.isString
local isNumber = std.isNumber
local isTable = std.isTable

local ValueError = std.ValueError
local TypeError = std.TypeError
local URL = std.URL

local error = std.error

local LUA_CLIENT = std.LUA_CLIENT
local LUA_MENU = std.LUA_MENU


--- [SHARED AND MENU]
---
--- The HTTP library, requests, cookies and helpers for web APIs.
---
---@class dreamwork.std.http
local http = std.http or {}
std.http = http

---@type table<string, integer>
local month_numbers = {
    jan = 1,
    feb = 2,
    mar = 3,
    apr = 4,
    may = 5,
    jun = 6,
    jul = 7,
    aug = 8,
    sep = 9,
    oct = 10,
    nov = 11,
    dec = 12
}

-- ordering of cookies with equally long paths
local creation_counter = 0

--- RFC 6265 5.1.1, `Expires` dates in any of the formats servers use.
---
---@param str string
---@return integer | nil timestamp
local function parse_cookie_date( str )
    local hour, minute, second, day, month, year

    -- delimiters are every printable non-alphanumeric byte except ":"
    for token in string_gmatch( str, "[%w:\128-\255]+" ) do
        local h, m, s

        if hour == nil then
            h, m, s = string_match( token, "^(%d%d?):(%d%d?):(%d%d?)%f[%D]" )
        end

        if h ~= nil then
            hour, minute, second = raw_tonumber( h, 10 ), raw_tonumber( m, 10 ), raw_tonumber( s, 10 )
        elseif day == nil and string_find( token, "^%d%d?%f[%D]" ) ~= nil then
            day = raw_tonumber( string_match( token, "^%d+" ), 10 )
        elseif month == nil and month_numbers[ string_lower( string_sub( token, 1, 3 ) ) ] ~= nil then
            month = month_numbers[ string_lower( string_sub( token, 1, 3 ) ) ]
        elseif year == nil and string_find( token, "^%d%d%d?%d?%f[%D]" ) ~= nil then
            year = raw_tonumber( string_match( token, "^%d+" ), 10 )
        end
    end

    if hour == nil or day == nil or month == nil or year == nil then
        return nil
    end

    ---@cast minute integer
    ---@cast second integer

    if year < 70 then
        year = year + 2000
    elseif year < 100 then
        year = year + 1900
    end

    if day < 1 or day > 31 or year < 1601 or hour > 23 or minute > 59 or second > 59 then
        return nil
    end

    -- "Feb 30" does not exist, `time.timestampFromCivil` would roll it over into March
    if day > 30 and (month == 4 or month == 6 or month == 9 or month == 11) then
        return nil
    elseif month == 2 and day > ((year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 29 or 28) then
        return nil
    end

    return time_timestampFromCivil( year, month, day, hour, minute, second )
end

--- RFC 6265 5.1.3
---
---@param host string
---@param domain string
---@param is_ip boolean
---@return boolean
local function domain_match( host, domain, is_ip )
    if host == domain then
        return true
    elseif is_ip then
        return false
    end

    local position = string_len( host ) - string_len( domain )
    return position > 1 and string_byte( host, position ) == 0x2E --[[ . ]] and string_sub( host, position + 1 ) == domain
end

--- RFC 6265 5.1.4
---
---@param request_path string
---@param cookie_path string
---@return boolean
local function path_match( request_path, cookie_path )
    if request_path == cookie_path then
        return true
    end

    local cookie_path_length = string_len( cookie_path )
    if string_sub( request_path, 1, cookie_path_length ) ~= cookie_path then
        return false
    end

    return string_byte( cookie_path, cookie_path_length ) == 0x2F --[[ / ]] or string_byte( request_path, cookie_path_length + 1 ) == 0x2F --[[ / ]]
end

--- RFC 6265 5.1.4, the "directory" of the request path.
---
---@param request_path string
---@return string
local function default_path( request_path )
    if string_byte( request_path, 1 ) ~= 0x2F --[[ / ]] then
        return "/"
    end

    local directory = string_match( request_path, "^(.*)/" )
    if directory == nil or directory == "" then
        return "/"
    end

    return directory
end

--- Returns the parts of `url` that cookies are matched against.
---
---@param url string | dreamwork.std.URL
---@return string host The lowercase host, `""` if the URL has no host.
---@return string path The percent-encoded path.
---@return boolean is_secure `true` for `https://` and `wss://`.
---@return boolean is_ip `true` if the host is an IP address.
local function get_location( url )
    if isString( url ) then
        ---@cast url string
        url = URL( url )
    end

    ---@cast url dreamwork.std.URL

    ---@type dreamwork.std.URL.State
    local state = raw_get( url, "state" )
    local scheme, hostname = state.scheme, state.hostname

    return url.hostname or "", url.pathname or "/", scheme == "https" or scheme == "wss", hostname ~= nil and not isString( hostname )
end

--- Removes leading and trailing spaces and tabs (RFC 6265 WSP).
---
---@param str string
---@return string
local function trim( str )
    return string_match( str, "^[ \t]*(.-)[ \t]*$" )
end

--- RFC 6265 5.2.3, lowercases the domain and strips a leading `"."`.
---
---@param domain string
---@return string
local function normalize_domain( domain )
    if string_byte( domain, 1 ) == 0x2E --[[ . ]] then
        domain = string_sub( domain, 2 )
    end

    return string_lower( domain )
end

--- RFC 6265 5.3 steps 11-12, replaces the cookie with the same name, domain and path,
--- keeping its creation order, or removes it if the new one is already expired.
---
---@param jar dreamwork.std.http.CookieJar
---@param cookie dreamwork.std.http.Cookie
local function store_cookie( jar, cookie )
    local name, domain, path = cookie.name, cookie.domain, cookie.path

    local index
    for i = 1, #jar, 1 do
        local stored = jar[ i ]
        if stored.name == name and stored.domain == domain and stored.path == path then
            index = i
            break
        end
    end

    local expires = cookie.expires
    if expires ~= nil and expires <= time_now() then
        if index ~= nil then
            table_remove( jar, index )
        end

        return
    end

    if index == nil then
        creation_counter = creation_counter + 1
        cookie.created = creation_counter
        jar[ #jar + 1 ] = cookie
    else
        cookie.created = jar[ index ].created
        jar[ index ] = cookie
    end
end

--- RFC 6265 5.2 and 5.3, parses one `Set-Cookie` value and stores it.
---
---@param jar dreamwork.std.http.CookieJar
---@param str string
---@param host string
---@param request_path string
---@param is_secure boolean
---@param is_ip boolean
local function parse_set_cookie( jar, str, host, request_path, is_secure, is_ip )
    local pair_end = string_find( str, ";", 1, true )

    local pair = str
    if pair_end ~= nil then
        pair = string_sub( str, 1, pair_end - 1 )
    end

    local equals_position = string_find( pair, "=", 1, true )
    if equals_position == nil then
        return
    end

    local name = trim( string_sub( pair, 1, equals_position - 1 ) )
    if name == "" then
        return
    end

    local expires, max_age, domain, path, same_site
    local secure, http_only = false, false

    if pair_end ~= nil then
        for attribute in string_gmatch( string_sub( str, pair_end + 1 ), "[^;]+" ) do
            local key, value = string_match( attribute, "^[ \t]*([^=]-)[ \t]*=[ \t]*(.-)[ \t]*$" )
            if key == nil then
                key, value = trim( attribute ), ""
            end

            key = string_lower( key )

            if key == "expires" then
                expires = parse_cookie_date( value ) or expires
            elseif key == "max-age" then
                if string_find( value, "^%-?%d+$" ) ~= nil then
                    max_age = raw_tonumber( value, 10 )
                end
            elseif key == "domain" then
                if value ~= "" then
                    domain = normalize_domain( value )
                end
            elseif key == "path" then
                if string_byte( value, 1 ) == 0x2F --[[ / ]] then
                    path = value
                else
                    path = nil
                end
            elseif key == "secure" then
                secure = true
            elseif key == "httponly" then
                http_only = true
            elseif key == "samesite" then
                same_site = string_lower( value )
            end
        end
    end

    if max_age ~= nil then
        if max_age > 0 then
            expires = time_now() + max_age
        else
            expires = 0
        end
    end

    local host_only = domain == nil
    if host_only then
        domain = host
    elseif not domain_match( host, domain, is_ip ) then
        return
    elseif not is_ip and string_find( domain, ".", 1, true ) == nil then
        -- RFC 6265 5.3 step 5 for bare top-level domains like `com`, the only public suffixes known here
        if domain ~= host then
            return
        end

        host_only = true
    end

    -- draft-ietf-httpbis-rfc6265bis: secure cookies only from secure origins, and the name prefixes
    if secure and not is_secure then
        return
    elseif string_sub( name, 1, 9 ) == "__Secure-" and not secure then
        return
    elseif string_sub( name, 1, 7 ) == "__Host-" and not (secure and host_only and path == "/") then
        return
    end

    store_cookie( jar, {
        name = name,
        value = trim( string_sub( pair, equals_position + 1 ) ),
        domain = domain,
        path = path or default_path( request_path ),
        host_only = host_only,
        secure = secure,
        http_only = http_only,
        same_site = same_site,
        expires = expires,
        created = 0
    } )
end

--- Splits `Set-Cookie` values that the http client joined with `","`,
--- the comma in `Expires=Wed, 21 Oct 2015 ...` is not followed by `name=`.
---
---@param jar dreamwork.std.http.CookieJar
---@param str string
---@param host string
---@param request_path string
---@param is_secure boolean
---@param is_ip boolean
local function parse_set_cookies( jar, str, host, request_path, is_secure, is_ip )
    local start_position, position = 1, 1
    ::cookie_splitter::

    local comma_position = string_find( str, ",", position, true )
    if comma_position == nil then
        parse_set_cookie( jar, string_sub( str, start_position ), host, request_path, is_secure, is_ip )
        return
    end

    position = comma_position + 1

    if string_find( str, "^[ \t]*[^=;, \t]+[ \t]*=", position ) ~= nil then
        parse_set_cookie( jar, string_sub( str, start_position, comma_position - 1 ), host, request_path, is_secure, is_ip )
        start_position = position
    end

    goto cookie_splitter
end

--- RFC 6265 5.4 step 2, longer paths first, then earlier created first.
---
---@param a dreamwork.std.http.Cookie
---@param b dreamwork.std.http.Cookie
---@return boolean
local function cookie_order( a, b )
    local a_length, b_length = string_len( a.path ), string_len( b.path )
    if a_length == b_length then
        return a.created < b.created
    end

    return a_length > b_length
end

--- [SHARED AND MENU]
---
--- A cookie jar, stores cookies from `Set-Cookie` response headers and
--- builds the `Cookie` request header, following [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265).
---
--- Pass it as `cookies` to `http.request` to use it automatically.
---
--- Known limits:
--- * the public suffix list is not checked, only bare top-level domains (`Domain=com`) are rejected,
--- so a server can still set a cookie for a suffix like `Domain=co.uk`, keep jars per service you talk to;
--- * `reqwest` passes only the last `Set-Cookie` header of a response, the others are lost;
--- * cookies set by redirect responses are only stored with `chttp`, where redirects are followed in Lua,
--- `reqwest` and `HTTP` follow redirects on their own and show only the final response;
--- * cookies live in memory, use `CookieJar:save` and `CookieJar:load` to keep them between restarts.
---
--- ```lua
--- local jar = http.CookieJar()
---
--- std.http.request( { url = "https://example.com/login", method = "POST", cookies = jar } )
--- std.http.request( { url = "https://example.com/profile", cookies = jar } ) -- sends the session cookie
---
--- jar:set( "lang", "en", { domain = "example.com" } )
--- jar:get( "lang", "https://example.com/" ).value -- "en"
--- ```
---
---@class dreamwork.std.http.CookieJar : dreamwork.std.Object
---@field __class dreamwork.std.http.CookieJarClass
---@field [ integer ] dreamwork.std.http.Cookie The stored cookies, in creation order.
local CookieJar = class.base( "http.CookieJar" )

---@return string
---@protected
function CookieJar:__represent()
    return string_format( "http.CookieJar: %p [%d]", self, #self )
end

--- [SHARED AND MENU]
---
--- Returns the cookie with the given name that would be sent to `url`,
--- the one with the longest path if there are several.
---
--- Without `url` the first not expired cookie with this name is returned.
---
---@param name string The cookie name.
---@param url? string | dreamwork.std.URL The URL the cookie would be sent to.
---@return dreamwork.std.http.Cookie | nil cookie The cookie, or `nil` if there is none.
---@nodiscard
function CookieJar:get( name, url )
    local now = time_now()

    if url == nil then
        for index = 1, #self, 1 do
            local cookie = self[ index ]

            local expires = cookie.expires
            if cookie.name == name and (expires == nil or expires > now) then
                return cookie
            end
        end

        return nil
    end

    local host, request_path, is_secure, is_ip = get_location( url )

    ---@type dreamwork.std.http.Cookie | nil
    local result

    for index = 1, #self, 1 do
        local cookie = self[ index ]

        local expires = cookie.expires
        if cookie.name == name and (expires == nil or expires > now) and (is_secure or not cookie.secure)
            and (cookie.host_only and host == cookie.domain or not cookie.host_only and domain_match( host, cookie.domain, is_ip ))
            and path_match( request_path, cookie.path )
            and (result == nil or cookie_order( cookie, result )) then
            result = cookie
        end
    end

    return result
end

--- [SHARED AND MENU]
---
--- Sets a cookie, replacing the one with the same name, domain and path.
---
--- An expired `expires` or a `max_age` of `0` or less removes the cookie,
--- the returned cookie is not stored in that case.
---
--- Raises a `TypeError` on wrong argument types and a `ValueError` if `name` or `value`
--- would break the `Cookie` header, or if neither `domain` nor a `url` with a host is given.
---
---@param name string The cookie name, without `"="`, `";"`, `","`, whitespace or control characters.
---@param value string The cookie value, sent as is, without `";"` or control characters.
---@param options dreamwork.std.http.CookieOptions The cookie options, `domain` or `url` is required.
---@return dreamwork.std.http.Cookie cookie The cookie.
function CookieJar:set( name, value, options )
    if not isString( name ) then
        error( TypeError( 1, name, "string", "name", "http.CookieJar:set" ), 2 )
    elseif not isString( value ) then
        error( TypeError( 2, value, "string", "value", "http.CookieJar:set" ), 2 )
    elseif not isTable( options ) then
        error( TypeError( 3, options, "table", "options", "http.CookieJar:set" ), 2 )
    end

    -- would inject other cookies into the `Cookie` header
    if name == "" or string_find( name, "[%z\1-\32\127=;,]" ) ~= nil then
        error( ValueError( name, "cookie name must be non-empty and contain no '=', ';', ',', whitespace or control characters" ), 2 )
    elseif string_find( value, "[%z\1-\31\127;]" ) ~= nil then
        error( ValueError( value, "cookie value must contain no ';' or control characters" ), 2 )
    end

    local domain, path = options.domain, options.path
    if domain ~= nil then
        domain = normalize_domain( domain )

        if domain == "" then
            error( ValueError( options.domain, "cookie domain must be non-empty" ), 2 )
        end
    end

    local host_only = false

    local url = options.url
    if url ~= nil then
        local host, request_path = get_location( url )

        if domain == nil then
            if host == "" then
                error( ValueError( url, "cookie url has no host, specify `domain`" ), 2 )
            end

            domain, host_only = host, true
        end

        if path == nil then
            path = default_path( request_path )
        end
    elseif domain == nil then
        error( ValueError( options, "cookie `domain` or `url` must be specified" ), 2 )
    end

    if path ~= nil and string_byte( path, 1 ) ~= 0x2F --[[ / ]] then
        error( ValueError( path, "cookie path must start with '/'" ), 2 )
    end

    local expires = options.expires

    local max_age = options.max_age
    if max_age ~= nil then
        if max_age > 0 then
            expires = time_now() + max_age
        else
            expires = 0
        end
    end

    ---@type dreamwork.std.http.Cookie
    local cookie = {
        name = name,
        value = value,
        domain = domain,
        path = path or "/",
        host_only = host_only,
        secure = options.secure == true,
        http_only = options.http_only == true,
        same_site = options.same_site,
        expires = expires,
        created = 0
    }

    store_cookie( self, cookie )
    return cookie
end

--- [SHARED AND MENU]
---
--- Removes every cookie with the given name, only from `domain` if it is given.
---
---@param name string The cookie name.
---@param domain? string The domain to remove the cookie from.
function CookieJar:delete( name, domain )
    if domain ~= nil then
        domain = normalize_domain( domain )
    end

    for index = #self, 1, -1 do
        local cookie = self[ index ]
        if cookie.name == name and (domain == nil or cookie.domain == domain) then
            table_remove( self, index )
        end
    end
end

--- [SHARED AND MENU]
---
--- Removes every cookie, or only the session ones (without `expires`).
---
---@param session_only? boolean If `true`, only session cookies are removed.
function CookieJar:clear( session_only )
    for index = #self, 1, -1 do
        if not session_only then
            self[ index ] = nil
        elseif self[ index ].expires == nil then
            table_remove( self, index )
        end
    end
end

--- [SHARED AND MENU]
---
--- Stores cookies from the `Set-Cookie` response header(s) of a response from `url`.
---
--- Values joined with `","` by the http client are split back,
--- invalid cookies and cookies for other domains are ignored.
---
--- Nothing is stored if `url` has no host (e.g. `file:///`).
---
---@param set_cookie string | string[] The `Set-Cookie` header value, or a list of values.
---@param url string | dreamwork.std.URL The URL of the response.
function CookieJar:store( set_cookie, url )
    local host, request_path, is_secure, is_ip = get_location( url )
    if host == "" then
        return
    end

    if isString( set_cookie ) then
        ---@cast set_cookie string
        parse_set_cookies( self, set_cookie, host, request_path, is_secure, is_ip )
        return
    end

    if not isTable( set_cookie ) then
        error( TypeError( 1, set_cookie, "string or table", "set_cookie", "http.CookieJar:store" ), 2 )
    end

    ---@cast set_cookie string[]

    for index = 1, #set_cookie, 1 do
        parse_set_cookies( self, set_cookie[ index ], host, request_path, is_secure, is_ip )
    end
end

--- [SHARED AND MENU]
---
--- Builds the `Cookie` request header for `url`, expired cookies are removed.
---
--- Cookies with longer paths come first, see [RFC 6265 5.4](https://www.rfc-editor.org/rfc/rfc6265#section-5.4).
---
---@param url string | dreamwork.std.URL The URL the request is sent to.
---@return string | nil header The header value, or `nil` if no cookies match.
---@nodiscard
function CookieJar:header( url )
    local host, request_path, is_secure, is_ip = get_location( url )
    local now = time_now()

    ---@type dreamwork.std.http.Cookie[]
    local matches = {}
    local count = 0

    for index = #self, 1, -1 do
        local cookie = self[ index ]

        local expires = cookie.expires
        if expires ~= nil and expires <= now then
            table_remove( self, index )
        elseif (is_secure or not cookie.secure)
            and (cookie.host_only and host == cookie.domain or not cookie.host_only and domain_match( host, cookie.domain, is_ip ))
            and path_match( request_path, cookie.path ) then
            count = count + 1
            matches[ count ] = cookie
        end
    end

    if count == 0 then
        return nil
    end

    table_sort( matches, cookie_order )

    ---@type string[]
    local rows = {}

    for index = 1, count, 1 do
        local cookie = matches[ index ]
        rows[ index ] = cookie.name .. "=" .. cookie.value
    end

    return table_concat( rows, "; ", 1, count )
end

---@param name string
---@return string
local function storage_key( name )
    return "http.cookies." .. name
end

--- [SHARED AND MENU]
---
--- Saves the persistent cookies (the ones with `expires`) to `dreamwork.storage` under `name`,
--- session cookies are skipped, like a browser does on exit.
---
--- Saving a jar without persistent cookies removes the saved one.
---
---@param name string The name to save the jar under.
function CookieJar:save( name )
    if not isString( name ) then
        error( TypeError( 1, name, "string", "name", "http.CookieJar:save" ), 2 )
    end

    local now = time_now()

    -- without `created`, the creation order is the order in the list
    ---@type table[]
    local cookies = {}
    local count = 0

    for index = 1, #self, 1 do
        local cookie = self[ index ]

        local expires = cookie.expires
        if expires ~= nil and expires > now then
            count = count + 1
            cookies[ count ] = {
                name = cookie.name,
                value = cookie.value,
                domain = cookie.domain,
                path = cookie.path,
                host_only = cookie.host_only,
                secure = cookie.secure,
                http_only = cookie.http_only,
                same_site = cookie.same_site,
                expires = expires
            }
        end
    end

    if count == 0 then
        storage_delete( storage_key( name ) )
    else
        storage_writeJSON( storage_key( name ), cookies )
    end
end

--- [SHARED AND MENU]
---
--- Loads cookies saved with `CookieJar:save`, replacing the ones with the same name, domain and path.
---
--- Expired and malformed entries are skipped.
---
---@param name string The name the jar was saved under.
---@return integer count The number of loaded cookies, `0` if nothing was saved.
function CookieJar:load( name )
    if not isString( name ) then
        error( TypeError( 1, name, "string", "name", "http.CookieJar:load" ), 2 )
    end

    local cookies = storage_readJSON( storage_key( name ) )
    if not isTable( cookies ) then
        return 0
    end

    ---@cast cookies table

    local now = time_now()
    local count = 0

    for index = 1, #cookies, 1 do
        local data = cookies[ index ]

        if isTable( data ) and isString( data.name ) and isString( data.value ) and isString( data.domain ) and isString( data.path ) then
            local expires = data.expires
            if isNumber( expires ) and expires > now then
                local same_site = data.same_site

                store_cookie( self, {
                    name = data.name,
                    value = data.value,
                    domain = data.domain,
                    path = data.path,
                    host_only = data.host_only == true,
                    secure = data.secure == true,
                    http_only = data.http_only == true,
                    same_site = isString( same_site ) and same_site or nil,
                    expires = expires,
                    created = 0
                } )

                count = count + 1
            end
        end
    end

    return count
end

--- [SHARED AND MENU]
---
--- The class used to create new `http.CookieJar` instances.
---
---@class dreamwork.std.http.CookieJarClass : dreamwork.std.http.CookieJar, dreamwork.std.Class
---@field __base dreamwork.std.http.CookieJar
---@overload fun(): dreamwork.std.http.CookieJar
http.CookieJar = class.create( CookieJar )

-- core libs
dreamwork_load( "std/net/http/client.lua" )
dreamwork_load( "std/net/http/server.lua", true, LUA_CLIENT )

-- api
dreamwork_load( "std/net/http/api/github.lua" )
dreamwork_load( "std/net/http/api/facepunch.lua", true, not LUA_MENU )
