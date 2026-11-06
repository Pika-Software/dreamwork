---@meta _

--- [SHARED AND MENU]
---
--- The HTTP library, requests, cookies and helpers for web APIs.
---
---@class http
http = {}

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
--- http.request( { url = "https://example.com/login", method = "POST", cookies = jar } )
--- http.request( { url = "https://example.com/profile", cookies = jar } ) -- sends the session cookie
---
--- jar:set( "lang", "en", { domain = "example.com" } )
--- jar:get( "lang", "https://example.com/" ).value -- "en"
--- ```
---
---@class http.CookieJar : Object
---@field __class http.CookieJarClass
---@field [ integer ] http.Cookie The stored cookies, in creation order.
local CookieJar = {}

---@return string
---@protected
function CookieJar:__represent() end

--- [SHARED AND MENU]
---
--- Returns the cookie with the given name that would be sent to `url`,
--- the one with the longest path if there are several.
---
--- Without `url` the first not expired cookie with this name is returned.
---
---@param name string The cookie name.
---@param url ( string | URL )? The URL the cookie would be sent to.
---@return http.Cookie | nil cookie The cookie, or `nil` if there is none.
---@nodiscard
function CookieJar:get(name, url) end

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
---@param options http.CookieOptions The cookie options, `domain` or `url` is required.
---@return http.Cookie cookie The cookie.
function CookieJar:set(name, value, options) end

--- [SHARED AND MENU]
---
--- Removes every cookie with the given name, only from `domain` if it is given.
---
---@param name string The cookie name.
---@param domain string? The domain to remove the cookie from.
function CookieJar:delete(name, domain) end

--- [SHARED AND MENU]
---
--- Removes every cookie, or only the session ones (without `expires`).
---
---@param session_only boolean? If `true`, only session cookies are removed.
function CookieJar:clear(session_only) end

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
---@param url string | URL The URL of the response.
function CookieJar:store(set_cookie, url) end

--- [SHARED AND MENU]
---
--- Builds the `Cookie` request header for `url`, expired cookies are removed.
---
--- Cookies with longer paths come first, see [RFC 6265 5.4](https://www.rfc-editor.org/rfc/rfc6265#section-5.4).
---
---@param url string | URL The URL the request is sent to.
---@return string | nil header The header value, or `nil` if no cookies match.
---@nodiscard
function CookieJar:header(url) end

--- [SHARED AND MENU]
---
--- Saves the persistent cookies (the ones with `expires`) to `dreamwork.storage` under `name`,
--- session cookies are skipped, like a browser does on exit.
---
--- Saving a jar without persistent cookies removes the saved one.
---
---@param name string The name to save the jar under.
function CookieJar:save(name) end

--- [SHARED AND MENU]
---
--- Loads cookies saved with `CookieJar:save`, replacing the ones with the same name, domain and path.
---
--- Expired and malformed entries are skipped.
---
---@param name string The name the jar was saved under.
---@return integer count The number of loaded cookies, `0` if nothing was saved.
function CookieJar:load(name) end

--- [SHARED AND MENU]
---
--- The class used to create new `http.CookieJar` instances.
---
---@class http.CookieJarClass : http.CookieJar, Class
---@field __base http.CookieJar
---@overload fun(): http.CookieJar
http.CookieJar = {}
