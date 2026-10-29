---@meta _

--- [SHARED AND MENU]
---
--- The Github API library.
---
---@class http.github
http.github = {}

--- [SHARED AND MENU]
---
--- Sends a request to the Github API.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers? table The headers to send with the request.
---@param body? string The body to send with the request.
---@param do_cache? boolean Whether to cache the response.
---@return http.Response response The response.
---@nodiscard
---@async
function http.github.request(method, pathname, headers, body, do_cache) end

--- [SHARED AND MENU]
---
--- Makes a request to the Github API.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param headers? table The headers to send with the request.
---@param body? string The body to send with the request.
---@param do_cache? boolean Whether to cache the response.
---@return table data The data returned from the API.
---@nodiscard
---@async
function http.github.apiRequest(method, pathname, headers, body, do_cache) end

--- [SHARED AND MENU]
---
--- Replaces all occurrences of `{name}` in `pathname` with `tbl[name]`.
---
---@param pathname string The path to replace placeholders in.
---@param replaces table<string, any> The table to replace placeholders with.
---@return string pathname The path with placeholders replaced.
---@nodiscard
function http.github.template(pathname, replaces) end

--- [SHARED AND MENU]
---
--- Replaces all occurrences of `{name}` in `pathname` with `tbl[name]` and makes a request to the Github API.
---
---@param method http.RequestMethod The request method.
---@param pathname string The path to send the request to.
---@param replaces table<string, any> The table to replace placeholders with.
---@return table data The data returned from the API.
---@nodiscard
---@async
function http.github.templateRequest(method, pathname, replaces) end

--- [SHARED AND MENU]
---
--- Fetches a list of all github emojis.
---
---@return table<string, string> data The list of emojis.
---@nodiscard
---@async
function http.github.getEmojis() end

--- [SHARED AND MENU]
---
--- Fetches a list of all github licenses.
---
---@return http.github.License[]
---@nodiscard
---@async
function http.github.getLicenses() end

--- [SHARED AND MENU]
---
--- Fetches a list of all repositories owned by an organization.
---
---@param organization string The name of the organization.
---@return http.github.Repository[] repos The list of repositories.
---@nodiscard
---@async
function http.github.getRepositories(organization) end

--- [SHARED AND MENU]
---
--- Fetches a detailed information about a specific repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return http.github.Repository repo The repository.
---@nodiscard
---@async
function http.github.getRepository(owner, repo) end

--- [SHARED AND MENU]
---
--- Fetches a lists the tags (versions) of a repository.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param page? integer The page number, default value is `1`.
---@return http.github.Repository.Tag[] tags The list of tags.
---@nodiscard
---@async
function http.github.getRepositoryTags(owner, repo, page) end

--- [SHARED AND MENU]
---
--- Fetches a single Git tree — that is, a snapshot of the repository's file structure at a specific commit or tree.
---
---@param owner string The account owner of the repository. The name is not case sensitive.
---@param repo string The name of the repository without the .git extension. The name is not case sensitive.
---@param tree_sha string The SHA1 value or ref (branch or tag) name of the tree.
---@param recursive? boolean Setting this parameter to any value returns the objects or subtrees referenced by the tree specified in :tree_sha.
---@return http.github.Tree tree The tree.
---@nodiscard
---@async
function http.github.getTree(owner, repo, tree_sha, recursive) end

--- [SHARED AND MENU]
---
--- Fetches the content of a blob (a blob = file contents) in a repository, using its SHA-1.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param file_sha string The SHA1 value of the blob.
---@return http.github.Blob blob The blob.
---@nodiscard
---@async
function http.github.getBlob(owner, repo, file_sha) end

--- [SHARED AND MENU]
---
--- Fetches a list of repository contributors.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return http.github.Contributor[] contributors The list of contributors.
---@nodiscard
---@async
function http.github.getContributors(owner, repo) end

--- [SHARED AND MENU]
---
--- Fetches a list of repository languages.
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@return table<string, integer> languages The languages.
---@nodiscard
---@async
function http.github.getLanguages(owner, repo) end

--- [SHARED AND MENU]
---
--- Fetches the repository contents as a ZIP archive based on a specific reference (branch name, tag name, or commit sha-1).
---
---@param owner string The owner of the repository.
---@param repo string The name of the repository.
---@param ref string The branch name, tag name, or commit sha-1.
---@return string content The body of the zipball.
---@nodiscard
---@async
function http.github.fetchZip(owner, repo, ref) end
