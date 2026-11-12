local std = dreamwork.std

---@class dreamwork.std.http
local http = std.http
local http_request = http.client.request

local json = std.json
local json_deserialize = json.deserialize

local base64 = std.base64
local base64_decode = base64.decode

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_sub = string.sub
local string_gsub = string.gsub
local string_find = string.find
local string_gmatch = string.gmatch

local time = std.time
local time_now = time.now
local time_elapsed = time.elapsed

local futures = std.futures
local futures_sleep = futures.sleep

local console = std.console
local console_Variable = console.Variable

local error = std.error
local pairs = std.pairs
local isTable = std.isTable
local tostring = std.tostring

local URL = std.URL
local URL_encodeURIComponent = URL.encodeURIComponent


--- [SHARED AND MENU]
---
--- The Github API library.
---
---@class dreamwork.std.http.github
local github = {}
http.github = github

---@type dreamwork.std.console.Variable<string>
local token = console_Variable( {
    name = "dreamwork_github_token",
    description = "The personal access token sent with every request, empty sends none, see https://github.com/settings/tokens",
    type = "string",
    default = "",
    archive = true,
    hidden = true
} )

-- https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting
local next_mutation_time = 0
local ratelimit_reset_time = 0

--- [SHARED AND MENU]
---
--- The last rate limit state reported by the Github API, empty until the first response.
---
---@class dreamwork.std.http.github.RateLimit
---@field limit? integer The requests allowed per window.
---@field remaining? integer The requests left in the current window.
---@field reset? integer The unix time (seconds) when the window resets.
local ratelimit = {}
github.ratelimit = ratelimit

--- Requests with these methods are sent at least one second apart, as GitHub asks for.
---
---@type table<string, boolean>
local mutative_methods = {
    [ "POST" ] = true,
    [ "PATCH" ] = true,
    [ "PUT" ] = true,
    [ "DELETE" ] = true
}

--- [SHARED AND MENU]
---
--- Extra options of a request.
---
---@class dreamwork.std.http.github.RequestOptions
---@field json? any The value serialized as the JSON body.
---@field parameters? table<string, any> The query parameters.

--- [SHARED AND MENU]
---
--- Sends a request to the Github API.
---
--- Returns `nil` and a message when the rate limit is exhausted for too long, other statuses are returned as is.
---
---@param method dreamwork.std.http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response, only applies to `GET` requests, `true` by default.
---@param extra dreamwork.std.http.github.RequestOptions? The JSON body and query parameters.
---@return dreamwork.std.http.Response | nil response The response, `nil` if the rate limit is exceeded.
---@return string | nil message The reason if there is no response.
---@nodiscard
---@async
local function request( method, pathname, headers, body, do_cache, extra )
    -- copied, so the caller's table is not changed
    ---@type dreamwork.std.http.RequestHeaders
    local request_headers = {
        Accept = "application/vnd.github+json",
        [ "X-GitHub-Api-Version" ] = "2022-11-28"
    }

    if headers ~= nil then
        for name, value in pairs( headers ) do
            request_headers[ name ] = value
        end
    end

    local href = "https://api.github.com" .. pathname

    local current_time = time_now()
    if ratelimit_reset_time > current_time then
        local diff = ratelimit_reset_time - current_time
        if diff < 30 then
            futures_sleep( diff )
        else
            return nil, "Github API rate limit exceeded, resets in " .. tostring( diff ) .. "s (" .. href .. ")"
        end
    end

    -- Rate limit mutative requests, `time.elapsed` counts in seconds
    if mutative_methods[ method ] then
        local diff = next_mutation_time - time_elapsed()
        if diff > 0 then
            next_mutation_time = next_mutation_time + 1
            futures_sleep( diff )
        else
            next_mutation_time = time_elapsed() + 1
        end
    end

    -- the response of a mutative request must never be served from the cache
    local use_cache = do_cache ~= false and method == "GET"

    ---@type dreamwork.std.http.Auth | nil
    local auth

    local token_value = token.value
    if token_value ~= nil and #token_value ~= 0 then
        auth = {
            token = token_value
        }
    end

    -- i believe there is no reason to implement queue, since requests are queued by the engine

    local result = http_request( {
        url = href,
        method = method,
        headers = request_headers,
        auth = auth,
        body = body,
        json = extra ~= nil and extra.json or nil,
        parameters = extra ~= nil and extra.parameters or nil,
        etag = use_cache,
        cache = use_cache
    } )

    local result_headers = result.headers

    -- the state is tracked on every response, so the limit is respected before it is hit
    local limit = raw_tonumber( result_headers[ "x-ratelimit-limit" ], 10 )
    local remaining = raw_tonumber( result_headers[ "x-ratelimit-remaining" ], 10 )
    local reset = raw_tonumber( result_headers[ "x-ratelimit-reset" ], 10 )

    if limit ~= nil and remaining ~= nil then
        ratelimit.limit, ratelimit.remaining, ratelimit.reset = limit, remaining, reset
    end

    if remaining == 0 and reset ~= nil then
        ratelimit_reset_time = reset
    end

    -- secondary rate limits ask to wait with `retry-after` (seconds)
    if result.status == 429 or result.status == 403 then
        local retry_after = raw_tonumber( result_headers[ "retry-after" ], 10 )
        if retry_after ~= nil then
            local retry_time = time_now() + retry_after
            if retry_time > ratelimit_reset_time then
                ratelimit_reset_time = retry_time
            end
        end
    end

    return result, nil
end

github.request = request

--- Builds the error message of a failed response, including the message sent by Github.
---
---@param result dreamwork.std.http.Response
---@param pathname string
---@return string
---@nodiscard
local function failure( result, pathname )
    local message = ""

    local data = json_deserialize( result.body or "" )
    if data ~= nil and data.message ~= nil then
        message = ": " .. tostring( data.message )
    end

    return "failed to fetch data from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")" .. message
end

--- [SHARED AND MENU]
---
--- Makes a request to the Github API and parses the JSON response.
---
--- Works like `pcall`: returns `true` and the data, or `false` and the error message. Empty responses (`204`) give an empty table.
---
---@param method dreamwork.std.http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra dreamwork.std.http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded.
---@return table | string data The data returned from the API, or the error message.
---@nodiscard
---@async
local function apiRequest( method, pathname, headers, body, do_cache, extra )
    local result, message = request( method, pathname, headers, body, do_cache, extra )
    if result == nil then
        ---@cast message string
        return false, message
    end

    local status = result.status
    if not (status >= 200 and status < 300) then
        return false, failure( result, pathname )
    end

    local response_body = result.body
    if status == 204 or response_body == nil or response_body == "" then
        return true, {}
    end

    local data = json_deserialize( response_body )
    if data == nil then
        return false, "failed to parse JSON response from Github API (" .. tostring( status ) .. ") (" .. tostring( pathname ) .. ")"
    end

    ---@cast data table

    return true, data
end

github.apiRequest = apiRequest

--- [SHARED AND MENU]
---
--- Same as `apiRequest`, but a `404` is not a failure: it returns `true` and `nil`.
---
---@param method dreamwork.std.http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra dreamwork.std.http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded (`true` for a `404`).
---@return table | string | nil data The data returned from the API, `nil` if not found, or the error message.
---@async
local function tryApiRequest( method, pathname, headers, body, do_cache, extra )
    local result, message = request( method, pathname, headers, body, do_cache, extra )
    if result == nil then
        return false, message
    end

    local status = result.status
    if status == 404 then
        return true, nil
    end

    if not (status >= 200 and status < 300) then
        return false, failure( result, pathname )
    end

    local response_body = result.body
    if status == 204 or response_body == nil or response_body == "" then
        return true, {}
    end

    local data = json_deserialize( response_body )
    if data == nil or not isTable( data ) then
        return false, "failed to parse JSON response from Github API (" .. tostring( status ) .. ") (" .. tostring( pathname ) .. ")"
    end

    ---@cast data table

    return true, data
end

github.tryApiRequest = tryApiRequest

--- [SHARED AND MENU]
---
--- Replaces all occurrences of `{name}` in `pathname` with the percent-encoded `replaces[name]`.
---
--- `{+name}` keeps `/` unencoded (for refs and file paths), `.` and `..` segments are rejected,
--- a missing value throws.
---
---@param pathname string The path to replace placeholders in.
---@param replaces table<string, any> The table to replace placeholders with.
---@return string pathname The path with placeholders replaced.
---@nodiscard
local function template( pathname, replaces )
    return (string_gsub( pathname, "{([%+%w_-]-)}", function( str )
        local reserved = string_find( str, "^%+" ) ~= nil
        local name = reserved and string_sub( str, 2 ) or str

        local value = replaces[ name ]
        if value == nil then
            error( "missing value for '{" .. name .. "}' in '" .. pathname .. "'", 3 )
        end

        value = tostring( value )

        if reserved then
            for segment in string_gmatch( value, "[^/]+" ) do
                if segment == "." or segment == ".." then
                    error( "invalid path segment '" .. segment .. "' in '{" .. name .. "}'", 3 )
                end
            end

            return (string_gsub( URL_encodeURIComponent( value ), "%%2[Ff]", "/" ))
        end

        if value == "." or value == ".." then
            error( "invalid value '" .. value .. "' for '{" .. name .. "}'", 3 )
        end

        return URL_encodeURIComponent( value )
    end ))
end

github.template = template

--- [SHARED AND MENU]
---
--- Replaces all placeholders in `pathname` (see `template`) and makes a request to the Github API.
---
---@param method dreamwork.std.http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param replaces table<string, any> The table to replace placeholders with.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra dreamwork.std.http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded.
---@return table | string data The data returned from the API, or the error message.
---@nodiscard
---@async
local function templateRequest( method, pathname, replaces, headers, body, do_cache, extra )
    return apiRequest( method, template( pathname, replaces ), headers, body, do_cache, extra )
end

github.templateRequest = templateRequest

--- [SHARED AND MENU]
---
--- Fetches every page of a list endpoint and joins them into one list.
---
--- Pages are 100 items, the loop stops when there is no `next` link (or the page is not full if the link is unknown).
---
---@param pathname string The path to send the requests to.
---@param parameters table<string, any>? The query parameters.
---@param max_pages integer? The maximum number of pages to fetch, `50` by default.
---@param start_page integer? The first page, `1` by default.
---@return boolean ok Whether every page was fetched.
---@return table[] | string items The joined list, or the error message.
---@nodiscard
---@async
local function paginate( pathname, parameters, max_pages, start_page )
    max_pages = max_pages or 50

    local items, item_count = {}, 0
    local page = start_page or 1
    local last_page = page + max_pages - 1

    ::next_page::

    -- a new table every page, the client reads it asynchronously
    local page_parameters = {}
    if parameters ~= nil then
        for name, value in pairs( parameters ) do
            page_parameters[ name ] = value
        end
    end

    page_parameters.per_page = 100
    page_parameters.page = page

    local result, message = request( "GET", pathname, nil, nil, nil, { parameters = page_parameters } )
    if result == nil then
        ---@cast message string
        return false, message
    end

    if result.status ~= 200 then
        return false, failure( result, pathname )
    end

    local data = json_deserialize( result.body or "" )
    if data == nil then
        return false, "failed to parse JSON response from Github API (" .. tostring( result.status ) .. ") (" .. tostring( pathname ) .. ")"
    end

    ---@cast data table

    local page_size = #data
    for i = 1, page_size do
        items[ item_count + i ] = data[ i ]
    end

    item_count = item_count + page_size

    local link = result.headers.link
    local has_next
    if link == nil then
        has_next = page_size >= 100
    else
        has_next = string_find( link, 'rel="next"', 1, true ) ~= nil
    end

    if has_next and page_size > 0 and page < last_page then
        page = page + 1
        goto next_page
    end

    return true, items
end

github.paginate = paginate

--- Decodes the base64 `content` of a blob, file or readme in place.
---
---@param data table
---@return table
local function decodeContent( data )
    if data.encoding == "base64" and data.content ~= nil then
        data.content = base64_decode( data.content )
        data.encoding = "raw"
    end

    return data
end

--- Downloads a response body as is (archives, raw files), anything but `200` is a failure.
---
---@param pathname string
---@param headers table?
---@return boolean ok
---@return string body_or_message
---@async
local function fetchRaw( pathname, headers )
    local result, message = request( "GET", pathname, headers, nil, false )
    if result == nil then
        ---@cast message string
        return false, message
    end

    if result.status ~= 200 then
        return false, failure( result, pathname )
    end

    return true, result.body or ""
end

github.fetchRaw = fetchRaw

--- [SHARED AND MENU]
---
--- Fetches a list of all github emojis.
---
---@return boolean ok Whether the request succeeded.
---@return table<string, string> | string data The list of emojis, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getEmojis()
    return apiRequest( "GET", "/emojis" )
end

--- [SHARED AND MENU]
---
--- Fetches a list of all github licenses.
---
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.License[] | string list The list, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getLicenses()
    return paginate( "/licenses" )
end

--- [SHARED AND MENU]
---
--- Fetches the current rate limit state of the token (does not count against the limit).
---
---@return boolean ok Whether the request succeeded.
---@return table | string limits The `resources` and `rate` tables sent by Github, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getRateLimit()
    return apiRequest( "GET", "/rate_limit", nil, nil, false )
end

--- [SHARED AND MENU]
---
--- Fetches the user profile.
---
---@param login string The username.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.User | string user The user, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getUser( login )
    return templateRequest( "GET", "/users/{login}", { login = login } )
end

--- [SHARED AND MENU]
---
--- Fetches a list of all repositories owned by an organization.
---
---@param organization string The name of the organization.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Repository[] | string repos The list of repositories, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getRepositories( organization )
    return paginate( template( "/orgs/{org}/repos", { org = organization } ) )
end

--- [SHARED AND MENU]
---
--- Fetches a list of all public repositories owned by a user.
---
---@param login string The username.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Repository[] | string repos The list of repositories, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getUserRepositories( login )
    return paginate( template( "/users/{login}/repos", { login = login } ) )
end

--- [SHARED AND MENU]
---
--- Fetches a detailed information about a specific repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Repository | string repo The repository, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getRepository( owner, repo )
    return templateRequest( "GET", "/repos/{owner}/{repo}", {
        owner = owner,
        repo = repo
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the tags (versions) of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param page integer? The page number, if omitted all pages are fetched.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Repository.Tag[] | string tags The list of tags, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getRepositoryTags( owner, repo, page )
    return paginate( template( "/repos/{owner}/{repo}/tags", {
        owner = owner,
        repo = repo
    } ), nil, page ~= nil and 1 or nil, page )
end

--- [SHARED AND MENU]
---
--- Fetches the branches of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return table[] | string branches The list of branches, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getBranches( owner, repo )
    return paginate( template( "/repos/{owner}/{repo}/branches", {
        owner = owner,
        repo = repo
    } ) )
end

--- [SHARED AND MENU]
---
--- Fetches a single branch of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param branch string The branch name.
---@return boolean ok Whether the request succeeded.
---@return table | string branch The branch, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getBranch( owner, repo, branch )
    return templateRequest( "GET", "/repos/{owner}/{repo}/branches/{+branch}", {
        owner = owner,
        repo = repo,
        branch = branch
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the topics of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return string[] | string topics The list of topics, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getTopics( owner, repo )
    local ok, data = templateRequest( "GET", "/repos/{owner}/{repo}/topics", {
        owner = owner,
        repo = repo
    } )

    if not ok then
        return false, data
    end

    ---@cast data table
    return true, data.names or {}
end

--- [SHARED AND MENU]
---
--- Fetches a single Git tree — that is, a snapshot of the repository's file structure at a specific commit or tree.
---
--- Recursive trees are limited by Github to 100,000 entries / 7 MB, a truncated tree throws unless `allow_truncated` is set.
---
---@param owner string The account owner of the repository. The name is not case sensitive.
---@param repo string The name of the repository without the .git extension. The name is not case sensitive.
---@param tree_sha string The SHA1 value or ref (branch or tag) name of the tree.
---@param recursive boolean? Returns the objects or subtrees referenced by the tree specified in :tree_sha.
---@param allow_truncated boolean? Return a truncated tree instead of throwing.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Tree | string tree The tree, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getTree( owner, repo, tree_sha, recursive, allow_truncated )
    -- GitHub treats any value of `recursive` as true, even `false`
    local ok, tree = templateRequest( "GET", "/repos/{owner}/{repo}/git/trees/{+tree_sha}", {
        owner = owner,
        repo = repo,
        tree_sha = tree_sha
    }, nil, nil, nil, recursive == true and { parameters = { recursive = 1 } } or nil )

    if not ok then
        return false, tree
    end

    ---@cast tree table
    if tree.truncated == true and allow_truncated ~= true then
        return false, "Github tree is truncated (" .. tostring( owner ) .. "/" .. tostring( repo ) .. "/" .. tostring( tree_sha ) .. ")"
    end

    return true, tree
end

--- [SHARED AND MENU]
---
--- Fetches the content of a blob (a blob = file contents) in a repository, using its SHA-1.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param file_sha string The SHA1 value of the blob.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Blob | string blob The blob, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getBlob( owner, repo, file_sha )
    local ok, result = templateRequest( "GET", "/repos/{owner}/{repo}/git/blobs/{file_sha}", {
        owner = owner,
        repo = repo,
        file_sha = file_sha
    } )

    if not ok then
        return false, result
    end

    ---@cast result table
    return true, decodeContent( result )
end

--- [SHARED AND MENU]
---
--- Fetches the raw bytes of a blob, without the base64 overhead.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param file_sha string The SHA1 value of the blob.
---@return boolean ok Whether the request succeeded.
---@return string | string content The blob content, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.fetchBlob( owner, repo, file_sha )
    return fetchRaw( template( "/repos/{owner}/{repo}/git/blobs/{file_sha}", {
        owner = owner,
        repo = repo,
        file_sha = file_sha
    } ), { Accept = "application/vnd.github.raw+json" } )
end

--- [SHARED AND MENU]
---
--- Fetches the metadata of a file or the listing of a directory.
---
--- The content of a file is decoded.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param path string? The path in the repository, empty is the root.
---@param ref string? The branch, tag or commit, the default branch if omitted.
---@return boolean ok Whether the request succeeded.
---@return table | string content The file object or the list of directory entries, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getContents( owner, repo, path, ref )
    local ok, data = templateRequest( "GET", "/repos/{owner}/{repo}/contents/{+path}", {
        owner = owner,
        repo = repo,
        path = path or ""
    }, nil, nil, nil, ref ~= nil and { parameters = { ref = ref } } or nil )

    if not ok then
        return false, data
    end

    ---@cast data table
    return true, decodeContent( data )
end

--- [SHARED AND MENU]
---
--- Fetches the raw content of a file.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param path string The path of the file.
---@param ref string? The branch, tag or commit, the default branch if omitted.
---@return boolean ok Whether the request succeeded.
---@return string | string content The file content, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.fetchFile( owner, repo, path, ref )
    local pathname = template( "/repos/{owner}/{repo}/contents/{+path}", {
        owner = owner,
        repo = repo,
        path = path
    } )

    if ref ~= nil then
        pathname = pathname .. "?ref=" .. URL_encodeURIComponent( ref )
    end

    return fetchRaw( pathname, { Accept = "application/vnd.github.raw+json" } )
end

--- [SHARED AND MENU]
---
--- Fetches the readme of a repository, the content is decoded.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string? The branch, tag or commit, the default branch if omitted.
---@return boolean ok Whether the request succeeded.
---@return table | string readme The readme file object, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getReadme( owner, repo, ref )
    local ok, data = templateRequest( "GET", "/repos/{owner}/{repo}/readme", {
        owner = owner,
        repo = repo
    }, nil, nil, nil, ref ~= nil and { parameters = { ref = ref } } or nil )

    if not ok then
        return false, data
    end

    ---@cast data table
    return true, decodeContent( data )
end

--- [SHARED AND MENU]
---
--- Fetches a list of repository contributors.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Contributor[] | string contributors The list of contributors, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getContributors( owner, repo )
    return paginate( template( "/repos/{owner}/{repo}/contributors", {
        owner = owner,
        repo = repo
    } ) )
end

--- [SHARED AND MENU]
---
--- Fetches a list of repository languages.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return table<string, integer> | string languages The languages, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getLanguages( owner, repo )
    return templateRequest( "GET", "/repos/{owner}/{repo}/languages", {
        owner = owner,
        repo = repo
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the repository contents as a ZIP archive.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string? The branch name, tag name, or commit sha-1, the default branch if omitted.
---@return boolean ok Whether the request succeeded.
---@return string | string content The body of the zipball, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.fetchZip( owner, repo, ref )
    -- the body is a zip archive, so `apiRequest` would fail to parse it as JSON
    return fetchRaw( template( ref ~= nil and "/repos/{owner}/{repo}/zipball/{+ref}" or "/repos/{owner}/{repo}/zipball", {
        owner = owner,
        repo = repo,
        ref = ref
    } ) )
end

--- [SHARED AND MENU]
---
--- Fetches the repository contents as a gzipped TAR archive.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string? The branch name, tag name, or commit sha-1, the default branch if omitted.
---@return boolean ok Whether the request succeeded.
---@return string | string content The body of the tarball, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.fetchTar( owner, repo, ref )
    return fetchRaw( template( ref ~= nil and "/repos/{owner}/{repo}/tarball/{+ref}" or "/repos/{owner}/{repo}/tarball", {
        owner = owner,
        repo = repo,
        ref = ref
    } ) )
end

--- [SHARED AND MENU]
---
--- Fetches the releases of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param max_pages integer? The maximum number of pages, `50` by default.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Release[] | string releases The list of releases, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getReleases( owner, repo, max_pages )
    return paginate( template( "/repos/{owner}/{repo}/releases", {
        owner = owner,
        repo = repo
    } ), nil, max_pages )
end

--- [SHARED AND MENU]
---
--- Fetches the latest published release of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Release | string | nil release The release, `nil` if there are none, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getLatestRelease( owner, repo )
    return tryApiRequest( "GET", template( "/repos/{owner}/{repo}/releases/latest", {
        owner = owner,
        repo = repo
    } ) )
end

--- [SHARED AND MENU]
---
--- Fetches the release of a tag.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param tag string The tag name.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Release | string | nil release The release, `nil` if not found, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getReleaseByTag( owner, repo, tag )
    return tryApiRequest( "GET", template( "/repos/{owner}/{repo}/releases/tags/{+tag}", {
        owner = owner,
        repo = repo,
        tag = tag
    } ) )
end

--- [SHARED AND MENU]
---
--- Downloads a release asset.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param asset_id integer The asset id (`Release.assets[n].id`).
---@return boolean ok Whether the request succeeded.
---@return string | string content The asset content, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.fetchReleaseAsset( owner, repo, asset_id )
    return fetchRaw( template( "/repos/{owner}/{repo}/releases/assets/{asset_id}", {
        owner = owner,
        repo = repo,
        asset_id = asset_id
    } ), { Accept = "application/octet-stream" } )
end

--- [SHARED AND MENU]
---
--- Fetches the commits of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param parameters table<string, any>? Filters: `sha` (branch/tag/commit), `path`, `author`, `since`, `until`.
---@param max_pages integer? The maximum number of pages, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Commit[] | string commits The list of commits, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getCommits( owner, repo, parameters, max_pages )
    return paginate( template( "/repos/{owner}/{repo}/commits", {
        owner = owner,
        repo = repo
    } ), parameters, max_pages or 1 )
end

--- [SHARED AND MENU]
---
--- Fetches a single commit, a branch or tag name resolves to its latest commit.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string The branch name, tag name, or commit sha-1.
---@return boolean ok Whether the request succeeded.
---@return dreamwork.std.http.github.Commit | string commit The commit, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getCommit( owner, repo, ref )
    return templateRequest( "GET", "/repos/{owner}/{repo}/commits/{+ref}", {
        owner = owner,
        repo = repo,
        ref = ref
    } )
end

--- [SHARED AND MENU]
---
--- Compares two refs.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param base string The base ref.
---@param head string The head ref.
---@return boolean ok Whether the request succeeded.
---@return table | string comparison The comparison (`status`, `ahead_by`, `behind_by`, `commits`, `files`), or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.compare( owner, repo, base, head )
    return templateRequest( "GET", "/repos/{owner}/{repo}/compare/{+base}...{+head}", {
        owner = owner,
        repo = repo,
        base = base,
        head = head
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the issues of a repository (pull requests are included by Github).
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param parameters table<string, any>? Filters: `state`, `labels`, `assignee`, `since`.
---@param max_pages integer? The maximum number of pages, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return table[] | string issues The list of issues, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getIssues( owner, repo, parameters, max_pages )
    return paginate( template( "/repos/{owner}/{repo}/issues", {
        owner = owner,
        repo = repo
    } ), parameters, max_pages or 1 )
end

--- [SHARED AND MENU]
---
--- Creates an issue, requires a token.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param title string The issue title.
---@param issue_body string? The issue text.
---@param labels string[]? The labels.
---@return boolean ok Whether the request succeeded.
---@return table | string issue The created issue, or the error message if `ok` is `false`.
---@async
function github.createIssue( owner, repo, title, issue_body, labels )
    return templateRequest( "POST", "/repos/{owner}/{repo}/issues", {
        owner = owner,
        repo = repo
    }, nil, nil, false, {
        json = {
            title = title,
            body = issue_body,
            labels = labels
        }
    } )
end

--- [SHARED AND MENU]
---
--- Fetches the pull requests of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param parameters table<string, any>? Filters: `state`, `head`, `base`, `sort`.
---@param max_pages integer? The maximum number of pages, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return table[] | string pulls The list of pull requests, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getPullRequests( owner, repo, parameters, max_pages )
    return paginate( template( "/repos/{owner}/{repo}/pulls", {
        owner = owner,
        repo = repo
    } ), parameters, max_pages or 1 )
end

--- [SHARED AND MENU]
---
--- Fetches a gist.
---
---@param gist_id string The gist id.
---@return boolean ok Whether the request succeeded.
---@return table | string gist The gist, `files` holds the content, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.getGist( gist_id )
    return templateRequest( "GET", "/gists/{gist_id}", { gist_id = gist_id } )
end

--- [SHARED AND MENU]
---
--- Searches repositories.
---
---@param query string The search query (https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories).
---@param page integer? The page number, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return table | string result `total_count` and `items` (up to 100 repositories), or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.searchRepositories( query, page )
    return apiRequest( "GET", "/search/repositories", nil, nil, nil, {
        parameters = { q = query, per_page = 100, page = page or 1 }
    } )
end

--- [SHARED AND MENU]
---
--- Searches code, requires a token.
---
---@param query string The search query (https://docs.github.com/en/search-github/searching-on-github/searching-code).
---@param page integer? The page number, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return table | string result `total_count` and `items` (up to 100 matches), or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.searchCode( query, page )
    return apiRequest( "GET", "/search/code", nil, nil, nil, {
        parameters = { q = query, per_page = 100, page = page or 1 }
    } )
end

--- [SHARED AND MENU]
---
--- Renders Markdown to HTML.
---
---@param text string The Markdown text.
---@param repository string? The `owner/repo` used to link issues and mentions, switches to the `gfm` mode.
---@return boolean ok Whether the request succeeded.
---@return string | string html The rendered HTML, or the error message if `ok` is `false`.
---@nodiscard
---@async
function github.renderMarkdown( text, repository )
    local result, message = request( "POST", "/markdown", nil, nil, false, {
        json = {
            text = text,
            mode = repository ~= nil and "gfm" or "markdown",
            context = repository
        }
    } )

    if result == nil then
        ---@cast message string
        return false, message
    end

    if result.status ~= 200 then
        return false, failure( result, "/markdown" )
    end

    return true, result.body or ""
end
