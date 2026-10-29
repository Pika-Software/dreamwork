---@meta _

--- [SHARED AND MENU]
---
--- The URL object.
---
---@class URL : Object, URL.State
---@field __class URLClass
---@field state URL.State internal state of URL
---@field href string full url
---@field origin string? *readonly* scheme + hostname + port
---@field protocol string? just a scheme with ':' appended at the end
---@field username string? used for basic auth as username
---@field password string? used for basic auth as password
---@field host string hostname + port
---@field hostname string?
---@field port number?
---@field pathname string?
---@field query string?
---@field search string? a query with '?' prepended
---@field searchParams URL.SearchParams
---@field fragment string?
---@field hash string? fragment with # prepended
local __URL = {}

--- [SHARED AND MENU]
---
--- The class used to create new `URL` instances.
---
--- Parses given URL string and returns a new URL object
--- using URL object with tostring(...) will result in getting `.href`
--- ```lua
--- local baseUrl = "https://developer.mozilla.org"
---
--- local A = URL("/", baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- local B = URL(baseURL)
--- -- => 'https://developer.mozilla.org/'
---
--- URL("en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- local D = URL("/en-US/docs", B)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", D)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", A)
--- -- => 'https://developer.mozilla.org/en-US/docs'
---
--- URL("/en-US/docs", "https://developer.mozilla.org/fr-FR/toto")
--- -- => 'https://developer.mozilla.org/en-US/docs'
--- ```
---@class URLClass : URL
---@field __base URL
---@overload fun( url: string, base: string | URL | nil ): URL
URL = {}

--- [SHARED AND MENU]
---
--- The URL search parameters object.
---
---@class URL.SearchParams : Object
---@field __class URL.SearchParamsClass
local SearchParams = {}

--- [SHARED AND MENU]
---
--- The class used to create new `URL.SearchParams` instances.
---
--- Parses given `init` and returns a new `URLSearchParams` object
--- if `init` is table, then it must be a list that consists of tables
--- that have two value, name and value
--- e.g. `{ {"name", "value"}, {"foo", "bar"}, {"good"} }`
---
--- also calling tostring(...) with `URLSearchParams` given will result in getting serialized query
--- also `#` can be used to get a total count of parameters (e.g. #searchParams)
---
---@class URL.SearchParamsClass : URL.SearchParams
---@field __base URL.SearchParams
---@operator len:integer
---@return URL.SearchParams
local SearchParamsClass = {}

---@protected
function SearchParams:__init(query, url) end

---@protected
function SearchParams:__tostring() end

--- [SHARED AND MENU]
---
--- Appends name and value to the end
---@param name string
---@param value string?
function SearchParams:append(name, value) end

--- [SHARED AND MENU]
---
--- searches all parameters with given name, and deletes them
--- if `value` is given, then searches for exactly given name AND value
---@param name string
---@param value string?
function SearchParams:delete(name, value) end

--- [SHARED AND MENU]
---
--- Finds first value associated with given name
---@param name string
---@return string | nil
function SearchParams:get(name) end

--- [SHARED AND MENU]
---
--- Finds all values associated with given name and returns them as list.
---@param name string
---@return table
function SearchParams:getAll(name) end

--- [SHARED AND MENU]
---
--- Returns true if parameters with given name exists and value if given.
---@param name string
---@param value string?
---@return boolean
function SearchParams:has(name, value) end

--- [SHARED AND MENU]
---
--- Sets first name to a given value (or appends [name, value])
--- and deletes other parameters with the same name
---@param name string
---@param value string?
function SearchParams:set(name, value) end

--- [SHARED AND MENU]
---
--- Sorts parameters inside `URLSearchParams`.
function SearchParams:sort() end

--- [SHARED AND MENU]
---
--- returns iterator that can be used in for loops
--- e.g. `for name, value in searchParams:entries() do ... end`
---@return fun(): string | nil, string | nil
function SearchParams:iterator() end

--- [SHARED AND MENU]
---
--- returns iterator that can be used in for loops
---@return fun(): string | nil
function SearchParams:keys() end

--- [SHARED AND MENU]
---
--- returns iterator that can be used in for loops
---@return fun(): string | nil
function SearchParams:values() end

URL.SearchParams = SearchParamsClass

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URLSearchParams`.
---@param any any The value to check.
---@return boolean result Returns `true` if the value is a `URLSearchParams`, otherwise `false`.
function isURLSearchParams(any) end

--- [SHARED AND MENU]
---
--- Checks if the given value is a `URL`.
---@param value any The value to check.
---@return boolean result Returns `true` if the value is a URL, otherwise `false`.
function isURL(value) end

---@protected
function __URL:__index(key) end

---@protected
function __URL:__newindex(key, value) end

---@return string
---@protected
function __URL:__tostring() end

---@protected
function __URL:__init(str, base) end

--- [SHARED AND MENU]
---
--- Parses given URL string but returns URLState object instead
---@see URL
---@param url string
---@param base string | URL | nil
---@return URL.State
function URL.parse(url, base) end

--- [SHARED AND MENU]
---
--- Returns true if given url can be parsed with URLState
--- otherwise returns false and error string
---@param url string
---@param base string | URL | nil
---@return boolean
---@return URL.State | string
function URL.canParse(url, base) end

--- [SHARED AND MENU]
---
--- Serializes given URLState object to full url string
--- basically same as accessing ``.href`` of URL object
---@param state URL.State
---@param excludeFragment? boolean if true, fragment will be excluded (default: false)
---@return string
function URL.serialize(state, excludeFragment) end

--- [SHARED AND MENU]
---
--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
---@param uri string
---@return string
function URL.encodeURI(uri) end

--- [SHARED AND MENU]
---
--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURI
---@param uri string
---@return string
function URL.decodeURI(uri) end

--- [SHARED AND MENU]
---
--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
---@param uri string
---@return string
function URL.encodeURIComponent(uri) end

--- [SHARED AND MENU]
---
--- see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/decodeURIComponent
---@param uri string
---@return string
function URL.decodeURIComponent(uri) end
