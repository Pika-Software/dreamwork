---@meta _

--- [SHARED AND MENU]
---
--- The Github API library.
---
---@class http.github
http.github = {}

--- [SHARED AND MENU]
---
--- The last rate limit state reported by the Github API, empty until the first response.
---
---@class http.github.RateLimit
---@field limit? integer The requests allowed per window.
---@field remaining? integer The requests left in the current window.
---@field reset? integer The unix time (seconds) when the window resets.
local ratelimit = {}

http.github.ratelimit = ratelimit

--- [SHARED AND MENU]
---
--- Extra options of a request.
---
---@class http.github.RequestOptions
---@field json? any The value serialized as the JSON body.
---@field parameters? table<string, any> The query parameters.

--- [SHARED AND MENU]
---
--- Sends a request to the Github API.
---
--- Returns `nil` and a message when the rate limit is exhausted for too long, other statuses are returned as is.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response, only applies to `GET` requests, `true` by default.
---@param extra http.github.RequestOptions? The JSON body and query parameters.
---@return http.Response | nil response The response, `nil` if the rate limit is exceeded.
---@return string | nil message The reason if there is no response.
---@nodiscard
---@async
function http.github.request(method, pathname, headers, body, do_cache, extra) end

--- [SHARED AND MENU]
---
--- Makes a request to the Github API and parses the JSON response.
---
--- Works like `pcall`: returns `true` and the data, or `false` and the error message. Empty responses (`204`) give an empty table.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded.
---@return table | string data The data returned from the API, or the error message.
---@nodiscard
---@async
function http.github.apiRequest(method, pathname, headers, body, do_cache, extra) end

--- [SHARED AND MENU]
---
--- Same as `apiRequest`, but a `404` is not a failure: it returns `true` and `nil`.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded (`true` for a `404`).
---@return table | string | nil data The data returned from the API, `nil` if not found, or the error message.
---@async
function http.github.tryApiRequest(method, pathname, headers, body, do_cache, extra) end

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
function http.github.template(pathname, replaces) end

--- [SHARED AND MENU]
---
--- Replaces all placeholders in `pathname` (see `template`) and makes a request to the Github API.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param replaces table<string, any> The table to replace placeholders with.
---@param headers table? The headers to send with the request.
---@param body string? The body to send with the request.
---@param do_cache boolean? Whether to cache the response.
---@param extra http.github.RequestOptions? The JSON body and query parameters.
---@return boolean ok Whether the request succeeded.
---@return table | string data The data returned from the API, or the error message.
---@nodiscard
---@async
function http.github.templateRequest(method, pathname, replaces, headers, body, do_cache, extra) end

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
function http.github.paginate(pathname, parameters, max_pages, start_page) end

--- Downloads a response body as is (archives, raw files), anything but `200` is a failure.
---
---@param pathname string
---@param headers table?
---@return boolean ok
---@return string body_or_message
---@async
function http.github.fetchRaw(pathname, headers) end

--- [SHARED AND MENU]
---
--- Fetches a list of all github emojis.
---
---@return boolean ok Whether the request succeeded.
---@return table<string, string> | string data The list of emojis, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getEmojis() end

--- [SHARED AND MENU]
---
--- Fetches a list of all github licenses.
---
---@return boolean ok Whether the request succeeded.
---@return http.github.License[] | string list The list, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getLicenses() end

--- [SHARED AND MENU]
---
--- Fetches the current rate limit state of the token (does not count against the limit).
---
---@return boolean ok Whether the request succeeded.
---@return table | string limits The `resources` and `rate` tables sent by Github, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getRateLimit() end

--- [SHARED AND MENU]
---
--- Fetches the user profile.
---
---@param login string The username.
---@return boolean ok Whether the request succeeded.
---@return http.github.User | string user The user, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getUser(login) end

--- [SHARED AND MENU]
---
--- Fetches a list of all repositories owned by an organization.
---
---@param organization string The name of the organization.
---@return boolean ok Whether the request succeeded.
---@return http.github.Repository[] | string repos The list of repositories, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getRepositories(organization) end

--- [SHARED AND MENU]
---
--- Fetches a list of all public repositories owned by a user.
---
---@param login string The username.
---@return boolean ok Whether the request succeeded.
---@return http.github.Repository[] | string repos The list of repositories, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getUserRepositories(login) end

--- [SHARED AND MENU]
---
--- Fetches a detailed information about a specific repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return http.github.Repository | string repo The repository, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getRepository(owner, repo) end

--- [SHARED AND MENU]
---
--- Fetches the tags (versions) of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param page integer? The page number, if omitted all pages are fetched.
---@return boolean ok Whether the request succeeded.
---@return http.github.Repository.Tag[] | string tags The list of tags, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getRepositoryTags(owner, repo, page) end

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
function http.github.getBranches(owner, repo) end

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
function http.github.getBranch(owner, repo, branch) end

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
function http.github.getTopics(owner, repo) end

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
---@return http.github.Tree | string tree The tree, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getTree(owner, repo, tree_sha, recursive, allow_truncated) end

--- [SHARED AND MENU]
---
--- Fetches the content of a blob (a blob = file contents) in a repository, using its SHA-1.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param file_sha string The SHA1 value of the blob.
---@return boolean ok Whether the request succeeded.
---@return http.github.Blob | string blob The blob, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getBlob(owner, repo, file_sha) end

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
function http.github.fetchBlob(owner, repo, file_sha) end

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
function http.github.getContents(owner, repo, path, ref) end

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
function http.github.fetchFile(owner, repo, path, ref) end

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
function http.github.getReadme(owner, repo, ref) end

--- [SHARED AND MENU]
---
--- Fetches a list of repository contributors.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return http.github.Contributor[] | string contributors The list of contributors, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getContributors(owner, repo) end

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
function http.github.getLanguages(owner, repo) end

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
function http.github.fetchZip(owner, repo, ref) end

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
function http.github.fetchTar(owner, repo, ref) end

--- [SHARED AND MENU]
---
--- Fetches the releases of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param max_pages integer? The maximum number of pages, `50` by default.
---@return boolean ok Whether the request succeeded.
---@return http.github.Release[] | string releases The list of releases, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getReleases(owner, repo, max_pages) end

--- [SHARED AND MENU]
---
--- Fetches the latest published release of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return boolean ok Whether the request succeeded.
---@return http.github.Release | string | nil release The release, `nil` if there are none, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getLatestRelease(owner, repo) end

--- [SHARED AND MENU]
---
--- Fetches the release of a tag.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param tag string The tag name.
---@return boolean ok Whether the request succeeded.
---@return http.github.Release | string | nil release The release, `nil` if not found, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getReleaseByTag(owner, repo, tag) end

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
function http.github.fetchReleaseAsset(owner, repo, asset_id) end

--- [SHARED AND MENU]
---
--- Fetches the commits of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param parameters table<string, any>? Filters: `sha` (branch/tag/commit), `path`, `author`, `since`, `until`.
---@param max_pages integer? The maximum number of pages, `1` by default.
---@return boolean ok Whether the request succeeded.
---@return http.github.Commit[] | string commits The list of commits, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getCommits(owner, repo, parameters, max_pages) end

--- [SHARED AND MENU]
---
--- Fetches a single commit, a branch or tag name resolves to its latest commit.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string The branch name, tag name, or commit sha-1.
---@return boolean ok Whether the request succeeded.
---@return http.github.Commit | string commit The commit, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getCommit(owner, repo, ref) end

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
function http.github.compare(owner, repo, base, head) end

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
function http.github.getIssues(owner, repo, parameters, max_pages) end

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
function http.github.createIssue(owner, repo, title, issue_body, labels) end

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
function http.github.getPullRequests(owner, repo, parameters, max_pages) end

--- [SHARED AND MENU]
---
--- Fetches a gist.
---
---@param gist_id string The gist id.
---@return boolean ok Whether the request succeeded.
---@return table | string gist The gist, `files` holds the content, or the error message if `ok` is `false`.
---@nodiscard
---@async
function http.github.getGist(gist_id) end

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
function http.github.searchRepositories(query, page) end

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
function http.github.searchCode(query, page) end

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
function http.github.renderMarkdown(text, repository) end
