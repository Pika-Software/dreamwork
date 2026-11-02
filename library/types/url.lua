---@meta _

--- [SHARED AND MENU]
---
--- A parsed URL, see the [URL Standard](https://url.spec.whatwg.org/).
---
--- Fields are computed from the internal state on access and can be assigned,
--- assigned values are parsed the same way the browser `URL` setters do,
--- invalid values are ignored.
---
--- `tostring( url )` returns `url.href`.
---
--- ```lua
--- local url = URL( "https://user:pass@example.com:8080/a/b?x=1#top" )
---
--- url.protocol -- "https:"
--- url.host     -- "example.com:8080"
--- url.pathname -- "/a/b"
--- url.search   -- "?x=1"
--- url.hash     -- "#top"
---
--- url.port = 443
--- url.href     -- "https://user:pass@example.com/a/b?x=1#top"
--- ```
---
---@class URL : Object, URL.State
---@field __class URLClass
---@field state URL.State The internal state, prefer the fields below.
---@field href string The whole serialized URL, assigning it re-parses the URL and throws on invalid input.
---@field origin string? *Read-only.* The `scheme://host:port` origin, `nil` for schemes without one (e.g. `file:`, `data:`).
---@field protocol string? The scheme followed by `":"`, e.g. `"https:"`.
---@field username string? The percent-encoded username, `nil` if not given.
---@field password string? The percent-encoded password, `nil` if not given.
---@field host string The hostname followed by `":port"` when the port is not the default one, `""` if there is no host.
---@field hostname string? The serialized host: a lowercase ASCII domain, a dotted IPv4 address or an IPv6 address in brackets.
---@field port integer? The port, `nil` when it is not given or is the default port of the scheme.
---@field pathname string? The path, e.g. `"/a/b"`, opaque paths (`mailto:`, `data:`) are returned as is.
---@field query string? The percent-encoded query without the leading `"?"`.
---@field search string The query with a leading `"?"`, `""` if the query is empty.
---@field searchParams URL.SearchParams The query as a list of name-value pairs, changes to it update the URL.
---@field fragment string? The percent-encoded fragment without the leading `"#"`.
---@field hash string The fragment with a leading `"#"`, `""` if the fragment is empty.
local __URL = {}

--- [SHARED AND MENU]
---
--- The class used to create new `URL` instances.
---
--- Calling the class parses `url`, relative URLs are resolved against `base`,
--- which can be a string or another `URL`.
---
--- Throws an error if `url` is invalid or is relative and `base` is not given,
--- use `URL.canParse` to check without throwing.
---
--- ```lua
--- local base_url = "https://developer.mozilla.org"
---
--- local a = URL( "/", base_url )                -- "https://developer.mozilla.org/"
--- local b = URL( base_url )                     -- "https://developer.mozilla.org/"
---
--- URL( "en-US/docs", b )                        -- "https://developer.mozilla.org/en-US/docs"
--- URL( "/en-US/docs", a )                       -- "https://developer.mozilla.org/en-US/docs"
--- URL( "../x?y#z", "https://h.com/a/b/c" )      -- "https://h.com/a/x?y#z"
--- URL( "//other.com/p", "https://h.com/" )      -- "https://other.com/p"
---
--- URL( "/en-US/docs" )                          -- error: Missing scheme
--- ```
---@class URLClass : URL, Class
---@field __base URL
---@overload fun( url: string, base: string | URL | nil ): URL
URL = {}

--- [SHARED AND MENU]
---
--- A list of query parameters, stored as `{ name, value }` pairs in order.
---
--- Names may repeat, a pair without `=` in the query has an empty value.
---
--- When taken from `url.searchParams`, every change is written back to the URL.
---
--- `tostring( params )` returns the serialized query without the leading `"?"`,
--- `#params` is the number of pairs.
---
--- ```lua
--- local url = URL( "https://example.com/?a=1&b=2" )
--- local params = url.searchParams
---
--- params:get( "a" )      -- "1"
--- params:append( "c", "x y" )
--- url.search             -- "?a=1&b=2&c=x+y"
--- ```
---
---@class URL.SearchParams : Object
---@field __class URL.SearchParamsClass
---@field url URL | nil The URL this list belongs to, `nil` for standalone lists.
---@field [ integer ] { [ 1 ]: string, [ 2 ]: string | nil } The name-value pairs.
local SearchParams = {}

--- [SHARED AND MENU]
---
--- The class used to create new `URL.SearchParams` instances.
---
--- Calling the class creates a list from a query string (a leading `"?"` is skipped,
--- `"+"` is decoded as a space) or from a list of `{ name, value }` pairs.
---
--- ```lua
--- URL.SearchParams( "?a=1&b=x+y" ):get( "b" ) -- "x y"
--- URL.SearchParams( { { "a", "1" }, { "flag" } } ):has( "flag" ) -- true
--- ```
---
---@class URL.SearchParamsClass : URL.SearchParams, Class
---@field __base URL.SearchParams
---@operator len:integer
---@overload fun( init: string | { [ 1 ]: string, [ 2 ]: string | nil }[] | nil, url: URL | nil ): URL.SearchParams
local SearchParamsClass = {}

URL.SearchParams = SearchParamsClass

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URLSearchParams`.
---
---@param value any The value to check.
---@return boolean result Returns `true` if the value is a `URLSearchParams`, otherwise `false`.
---@nodiscard
function isURLSearchParams(value) end

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URL`.
---
---@param value any The value to check.
---@return boolean result Returns `true` if the value is a URL, otherwise `false`.
---@nodiscard
function isURL(value) end

---@param query string | { [ 1 ]: string, [ 2 ]: string | nil }[] | nil
---@param url? URL
---@protected
function SearchParams:__init(query, url) end

---@return string
---@protected
function SearchParams:__tostring() end

---@return string
---@protected
function SearchParams:__represent() end

--- [SHARED AND MENU]
---
--- Appends a name-value pair to the end of the list.
---
---@param name string The name of the parameter.
---@param value? string The value of the parameter, `nil` is the same as `""`.
function SearchParams:append(name, value) end

--- [SHARED AND MENU]
---
--- Removes every pair with the given name.
---
--- If `value` is given, only pairs with both the given name and value are removed.
---
---@param name string The name of the parameters to remove.
---@param value? string The value the removed pairs must have.
function SearchParams:delete(name, value) end

--- [SHARED AND MENU]
---
--- Returns the value of the first pair with the given name.
---
---@param name string The name of the parameter.
---@return string | nil value The value, `nil` if there is no such pair.
---@nodiscard
function SearchParams:get(name) end

--- [SHARED AND MENU]
---
--- Returns the values of every pair with the given name, in order.
---
--- ```lua
--- URL.SearchParams( "a=1&b=2&a=3" ):getAll( "a" ) -- { "1", "3" }
--- ```
---
---@param name string The name of the parameters.
---@return string[] values The values, empty if there are no such pairs.
---@nodiscard
function SearchParams:getAll(name) end

--- [SHARED AND MENU]
---
--- Checks if there is a pair with the given name.
---
--- If `value` is given, the pair must also have the given value.
---
---@param name string The name of the parameter.
---@param value? string The value the pair must have.
---@return boolean exists `true` if such a pair exists, otherwise `false`.
---@nodiscard
function SearchParams:has(name, value) end

--- [SHARED AND MENU]
---
--- Sets the value of the first pair with the given name and removes the other pairs with that name.
---
--- Appends a new pair if there is no pair with the given name.
---
--- ```lua
--- local params = URL.SearchParams( "a=1&b=2&a=3" )
--- params:set( "a", "9" )
--- tostring( params ) -- "a=9&b=2"
--- ```
---
---@param name string The name of the parameter.
---@param value? string The new value.
function SearchParams:set(name, value) end

--- [SHARED AND MENU]
---
--- Sorts the pairs by name, pairs with the same name keep their relative order.
---
--- ```lua
--- local params = URL.SearchParams( "b=1&a=2&b=0" )
--- params:sort()
--- tostring( params ) -- "a=2&b=1&b=0"
--- ```
function SearchParams:sort() end

--- [SHARED AND MENU]
---
--- Returns an iterator over the name-value pairs.
---
--- ```lua
--- for name, value in url.searchParams:iterator() do
---     print( name, value )
--- end
--- ```
---
---@return fun(): string | nil, string | nil iterator The iterator function.
---@nodiscard
function SearchParams:iterator() end

--- [SHARED AND MENU]
---
--- Returns an iterator over the names, names that repeat are returned every time.
---
---@return fun(): string | nil iterator The iterator function.
---@nodiscard
function SearchParams:keys() end

--- [SHARED AND MENU]
---
--- Returns an iterator over the values, a `nil` value gives `""`.
---
---@return fun(): string | nil iterator The iterator function.
---@nodiscard
function SearchParams:values() end

---@param key string
---@protected
function __URL:__index(key) end

---@param key string
---@param value any
---@protected
function __URL:__newindex(key, value) end

---@return string
---@protected
function __URL:__tostring() end

---@return string
---@protected
function __URL:__represent() end

---@param str string
---@param base? string | URL
---@protected
function __URL:__init(str, base) end

--- [SHARED AND MENU]
---
--- Parses a URL string into a plain state table, without creating a `URL` object.
---
--- Same rules as calling `URL`, throws an error if the URL is invalid.
---
--- ```lua
--- local state = URL.parse( "https://example.com:8080/a/b?q" )
--- state.hostname -- "example.com"
--- state.port     -- 8080
--- state.path     -- { "a", "b" }
--- ```
---
---@see URL
---
---@param url string The URL string to parse.
---@param base? string | URL The base URL that relative URLs are resolved against.
---@return URL.State state The parsed URL state.
---@nodiscard
function URL.parse(url, base) end

--- [SHARED AND MENU]
---
--- Checks if a URL string can be parsed, without throwing an error.
---
--- ```lua
--- URL.canParse( "https://example.com" ) -- true, state
--- URL.canParse( "/path" )                -- false, "...Invalid URL: Missing scheme"
--- URL.canParse( "/path", "https://h/" )  -- true, state
--- ```
---
---@param url string The URL string to check.
---@param base? string | URL The base URL that relative URLs are resolved against.
---@return boolean success `true` if the URL is valid, otherwise `false`.
---@return URL.State | string state_or_error The parsed URL state, or the error message if the URL is invalid.
---@nodiscard
function URL.canParse(url, base) end

--- [SHARED AND MENU]
---
--- Serializes a URL state, as returned by `URL.parse`, into a URL string.
---
--- Gives the same result as `url.href`.
---
--- ```lua
--- local state = URL.parse( "HTTP://Example.com:80/a?b#c" )
--- URL.serialize( state )       -- "http://example.com/a?b#c"
--- URL.serialize( state, true ) -- "http://example.com/a?b"
--- ```
---
---@param state URL.State The URL state to serialize.
---@param exclude_fragment? boolean If `true`, the fragment is left out, defaults to `false`.
---@return string url_str The serialized URL.
---@nodiscard
function URL.serialize(state, exclude_fragment) end

--- [SHARED AND MENU]
---
--- Percent-encodes a whole URI, like JavaScript `encodeURI`.
---
--- Letters, digits, `-_.!~*'()` and the URI delimiters `;,/?:@&=+$#` are kept,
--- every other byte is encoded as `%XX`, spaces included.
---
--- ```lua
--- URL.encodeURI( "https://h/a b?q=ü" ) -- "https://h/a%20b?q=%C3%BC"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
---
---@param uri string The URI to encode.
---@return string encoded_uri The encoded URI.
---@nodiscard
function URL.encodeURI(uri) end

--- [SHARED AND MENU]
---
--- Decodes `%XX` escapes in a whole URI, like JavaScript `decodeURI`.
---
--- Escapes of the URI delimiters `;/?:@&=+$,#` are kept as is,
--- so the structure of the URI does not change. Invalid escapes are kept as is.
---
--- ```lua
--- URL.decodeURI( "/a%20b%2Fc" ) -- "/a b%2Fc"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI
---
---@param uri string The URI to decode.
---@return string decoded_uri The decoded URI.
---@nodiscard
function URL.decodeURI(uri) end

--- [SHARED AND MENU]
---
--- Percent-encodes a single URI component, like JavaScript `encodeURIComponent`.
---
--- Only letters, digits and `-_.!~*'()` are kept, every other byte is encoded as `%XX`,
--- spaces become `%20`. Use it for values put into a path segment or a query.
---
--- ```lua
--- URL.encodeURIComponent( "a b&c=d/e" ) -- "a%20b%26c%3Dd%2Fe"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
---
---@param uri string The URI component to encode.
---@return string encoded_uri The encoded URI component.
---@nodiscard
function URL.encodeURIComponent(uri) end

--- [SHARED AND MENU]
---
--- Decodes every `%XX` escape in a URI component, like JavaScript `decodeURIComponent`.
---
--- `"+"` is kept as is, invalid escapes are kept as is.
---
--- ```lua
--- URL.decodeURIComponent( "a%20b%26c+d" ) -- "a b&c+d"
--- ```
---
--- See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
---
---@param uri string The URI component to decode.
---@return string decoded_uri The decoded URI component.
---@nodiscard
function URL.decodeURIComponent(uri) end
