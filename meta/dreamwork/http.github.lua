---@meta dreamwork.std.http.github


--- [SHARED AND MENU]
---
--- Git Tree
---
--- The hierarchy between files in a Git repository.
---
---@class dreamwork.std.http.github.Tree
local Tree = {}

---
--- The SHA1 of the tree.
---
---@type string
Tree.sha = nil

---
--- The URL of the tree.
---
---@type string
Tree.url = nil

---
--- Whether the tree is truncated.
---
--- If truncated is true in the response
--- then the number of items in the tree
--- array exceeded our maximum limit.
---
--- If you need to fetch more items,
--- use the non-recursive method of
--- fetching trees, and fetch one
--- sub-tree at a time.
---
---@type boolean
Tree.truncated = nil

--- [SHARED AND MENU]
---
--- A list of files and directories in the Tree.
---
---@class dreamwork.std.http.github.Tree.Item[]
Tree.tree = nil


--- [SHARED AND MENU]
---
--- A single file or directory in a Tree
---
---@class dreamwork.std.http.github.Tree.Item
local Item = {}

---
--- The path to the file or directory.
---
---@type string
Item.path = nil

---
--- The type of item that this is.
---
---| Mode    | Meaning                      | Types    |
---|:--------|:-----------------------------|:---------|
---|`100644` | Normal file (non-executable) | `Blob`
---|`100755` | Executable file              | `Blob`
---|`040000` | Directory                    | `Tree`
---|`120000` | Symbolic link                | `Blob`
---|`160000` | Git submodule (commit ref)   | `Commit`
---
---@type string
Item.mode = nil

---
--- The type of item that this is.
---
--- One of "blob", "tree", "commit".
---
---@type string
Item.type = nil

---
--- The SHA1 of the item.
---
---@type string
Item.sha = nil

---
--- The size of the item in bytes.
---
---@type number
Item.size = nil

---
--- The URL of the item.
---
---@type string
Item.url = nil


--- [SHARED AND MENU]
---
--- A GitHub user.
---
---@class dreamwork.std.http.github.User
local User = {}

---
--- Unique numeric ID of the user on GitHub.
---
---@type integer
User.id = nil

---
--- GitHub username.
---
---@type string
User.login = nil

---
--- GitHub user avatar URL.
---
---@type string
User.avatar_url = nil

---
--- Type of GitHub account: `"User"` for individuals, `"Organization"` for orgs.
---
---@type string
User.type = nil

---
--- API URL to fetch general user profile data in JSON.
---
---@type string
User.url = nil

---
--- Not a standard GitHub field in public APIs;
---
--- (likely indicates visibility like `"public"` or `"private"` view).
---
---@type string
User.user_view_type = nil

---
--- API endpoint to fetch users who follow this user.
---
---@type string
User.followers_url = nil

---
--- Template URL for users this user is following.
---
--- Replace `{other_user}` with a username to check specific following status.
---
---@type string
User.following_url = nil

---
--- Template API URL to fetch gists (code snippets) by this user.
---
--- `{gist_id}` is optional to target a specific gist.
---
---@type string
User.gists_url = nil

---
--- URL to the user’s GitHub profile (viewed in browser).
---
---@type string
User.html_url = nil

---
--- Internal GitHub GraphQL node ID, base64-encoded.
---
---@type string
User.node_id = nil

---
--- API URL to fetch organizations this user belongs to.
---
---@type string
User.organizations_url = nil

---
--- API URL to list GitHub events received by this user (e.g., starred, forked repos).
---
---@type string
User.received_events_url = nil

---
--- API URL to list this user’s public repositories.
---
---@type string
User.repos_url = nil

---
--- `true` if the user is a GitHub staff/admin, `false` otherwise.
---
---@type boolean
User.site_admin = nil

---
--- Template API URL to see repositories starred by this user.
---
--- Replace `{owner}` and `{repo}` with specific values if needed.
---
---@type string
User.starred_url = nil

---
--- API URL to fetch repos this user is subscribed to (watching for updates).
---
---@type string
User.subscriptions_url = nil


--- [SHARED AND MENU]
---
--- A GitHub user who has contributed to a repository.
---
---@class dreamwork.std.http.github.Contributor : dreamwork.std.http.github.User
local Contributor = {}

---
--- API endpoint to retrieve the public events
--- performed by the user (such as pushes,
--- issues opened, pull requests, etc.).
---
--- Format: `https://api.github.com/users/{username}/events`
---
---@type string
Contributor.events_url = nil

---
--- Number of contributions made by this user.
---
---@type integer
Contributor.contributions = nil


do

    --- [SHARED AND MENU]
    ---
    --- A GitHub repository tag commit.
    ---
    ---@class dreamwork.std.http.github.Repository.Tag.Commit
    local commit = {}

    --- The SHA-1 hash of the commit that this tag points to.
    ---
    ---@type string
    commit.sha = nil

    --- API URL to fetch full information about the commit for this tag.
    ---
    ---@type string
    commit.url = nil

    --- [SHARED AND MENU]
    ---
    --- A GitHub repository tag.
    ---
    ---@class dreamwork.std.http.github.Repository.Tag
    local tag = {}

    --- Name of the tag.
    ---
    ---@type string
    tag.name = nil

    --- Commit associated with the tag.
    ---
    ---@type dreamwork.std.http.github.Repository.Tag.Commit
    tag.commit = nil

    --- URL to download the source code at this tag as a ZIP archive.
    ---
    ---@type string
    tag.zipball_url = nil

    --- URL to download the source code at this tag as a TAR.GZ archive.
    ---
    ---@type string
    tag.tarball_url = nil

    --- Internal GraphQL node ID for the tag object (base64 encoded).
    ---
    ---@type string
    tag.node_id = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- The GitHub license.
    ---
    ---@class dreamwork.std.http.github.License
    local license = {}

    --- Full human-readable name of the license (e.g., "MIT License").
    ---
    ---@type string
    license.name = nil

    --- A short machine-readable license identifier (e.g., "mit" for MIT License, "gpl-3.0" for GNU GPL v3).
    ---
    ---@type string
    license.key = nil

    --- API URL to fetch full license information from GitHub's API (can contain license text, permissions, conditions, etc.).
    ---
    ---@type string
    license.url = nil

    --- [SPDX](https://spdx.dev/) identifier for the license (standardized license codes like MIT, GPL-3.0, etc.).
    ---
    ---@type string
    license.spdx_id = nil

    --- GitHub's internal GraphQL node ID for the license, base64 encoded.
    ---
    ---@type string
    license.node_id = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- The GitHub repository.
    ---
    ---@class dreamwork.std.http.github.Repository
    local repository = {}

    --- Unique numeric ID of the repository.
    ---
    ---@type integer
    repository.id = nil

    --- The name of the repository.
    ---
    ---@type string
    repository.name = nil

    --- The description of the repository.
    ---
    ---@type string
    repository.description = nil

    --- Information about the repository owner.
    ---
    ---@type dreamwork.std.http.github.User
    repository.owner = nil

    --- Repository visibility level (public, private, internal).
    ---
    ---@type string
    repository.visibility = nil

    --- The full name of the repository, e.g. "Pika-Software/dreamwork".
    ---
    ---@type string
    repository.full_name = nil

    --- Size of the repository in kilobytes (KB).
    ---
    ---@type number
    repository.size = nil

    --- Timestamp when the repository was created.
    ---
    ---@type string
    repository.created_at = nil

    --- Timestamp of the last push (commit) to any branch.
    ---
    ---@type string
    repository.pushed_at = nil

    --- Timestamp when the repository was last updated (includes metadata changes, not only code).
    ---
    ---@type string
    repository.updated_at = nil

    --- Whether the repository is disabled (e.g., archived or locked by GitHub).
    ---
    ---@type boolean
    repository.disabled = nil

    --- Whether the repository is private (`true`) or public (`false`).
    ---
    ---@type boolean
    repository.private = nil

    --- The name of the default branch of the repository.
    ---
    ---@type string
    repository.default_branch = nil

    --- Number of forks plus other derivatives of the repository (usually matches `forks_count`).
    ---
    ---@type number
    repository.network_count = nil

    --- Internal GitHub GraphQL node ID, base64 encoded.
    ---
    ---@type string
    repository.node_id = nil

    --- Number of open issues currently in the repository.
    ---
    ---@type integer
    repository.open_issues_count = nil

    --- Whether this repository is a fork of another repository.
    ---
    ---@type boolean
    repository.fork = nil

    --- Number of forks (copies) made by users.
    ---
    ---@type integer
    repository.forks_count = nil

    --- API endpoint for the repository itself.
    ---
    ---@type string
    repository.url = nil

    --- URL to the GitHub repository page (the one you visit in browser).
    ---
    ---@type string
    repository.html_url = nil

    --- Git URL to clone the repository over Git protocol.
    ---
    ---@type string
    repository.git_url = nil

    --- SSH URL for cloning the repository over SSH.
    ---
    ---@type string
    repository.ssh_url = nil

    --- Whether GitHub Discussions feature is enabled.
    ---
    ---@type boolean
    repository.has_discussions = nil

    --- Whether the repository has downloadable releases or binaries.
    ---
    ---@type boolean
    repository.has_downloads = nil

    --- Whether the Issues feature is enabled for the repository.
    ---
    ---@type boolean
    repository.has_issues = nil

    --- Whether GitHub Pages (static site hosting) is enabled for the repository.
    ---
    ---@type boolean
    repository.has_pages = nil

    --- Whether GitHub Projects (kanban/project boards) is enabled.
    ---
    ---@type boolean
    repository.has_projects = nil

    --- Whether the repository has a wiki enabled.
    ---
    ---@type boolean
    repository.has_wiki = nil

    --- Whether the repository is marked as a template (for creating new repositories based on it).
    ---
    ---@type boolean
    repository.is_template = nil

    --- Main programming language detected in the repository.
    ---
    ---@type string
    repository.language = nil

    --- Number of stars (likes) the repository has received.
    ---
    ---@type integer
    repository.stargazers_count = nil

    --- Number of people watching (subscribed to notifications) the repository.
    ---
    ---@type integer
    repository.subscribers_count = nil

    --- Number of watchers (again, often identical to stargazers_count).
    ---
    ---@type integer
    repository.watchers_count = nil

    --- Temporary token for cloning private repos without credentials (usually empty unless needed).
    ---
    ---@type string
    repository.temp_clone_token = nil

    --- List of topics/tags associated with the repo (e.g., ["lua", "cryptography", "gmod"]).
    ---
    ---@type string[]
    repository.topics = nil

    --- Information about the software license attached to the repository.
    ---
    ---@type dreamwork.std.http.github.License
    repository.license = nil

    --- Information about the repository owner.
    ---
    ---@type dreamwork.std.http.github.User
    repository.owner = nil

    --- Whether commits made via the web interface require sign-off (DCO compliance).
    ---
    ---@type boolean
    repository.web_commit_signoff_required = nil

    --- Either `true` to allow private forks, or `false` to prevent private forks.
    ---
    ---@type boolean
    repository.allow_forking = nil

    --- Whether to archive this repository. `false` will unarchive a previously archived repository.
    ---
    ---@type boolean
    repository.archived = nil

    --- A list of permissions for the repository.
    ---
    ---@type table<string, boolean>
    repository.permissions = nil

    --- The archive format for the repository.
    ---
    ---@type string
    repository.archive_url = nil

    --- The assignees format for the repository.
    ---
    ---@type string
    repository.assignees_url = nil

    --- The blobs format for the repository.
    ---
    ---@type string
    repository.blobs_url = nil

    --- The branches format for the repository.
    ---
    ---@type string
    repository.branches_url = nil

    --- The clone format for the repository.
    ---
    ---@type string
    repository.clone_url = nil

    --- The collaborators format for the repository.
    ---
    ---@type string
    repository.collaborators_url = nil

    --- The comments format for the repository.
    ---
    ---@type string
    repository.comments_url = nil

    --- The commits format for the repository.
    ---
    ---@type string
    repository.commits_url = nil

    --- The compare format for the repository.
    ---
    ---@type string
    repository.compare_url = nil

    --- The contents format for the repository.
    ---
    ---@type string
    repository.contents_url = nil

    --- The contributors format for the repository.
    ---
    ---@type string
    repository.contributors_url = nil

    --- The deployments format for the repository.
    ---
    ---@type string
    repository.deployments_url = nil

    --- The downloads format for the repository.
    ---
    ---@type string
    repository.downloads_url = nil

    --- The events format for the repository.
    ---
    ---@type string
    repository.events_url = nil

    --- The forks format for the repository.
    ---
    ---@type string
    repository.forks_url = nil

    --- The git_commits format for the repository.
    ---
    ---@type string
    repository.git_commits_url = nil

    --- The git_refs format for the repository.
    ---
    ---@type string
    repository.git_refs_url = nil

    --- The git_tags format for the repository.
    ---
    ---@type string
    repository.git_tags_url = nil

    --- The hooks format for the repository.
    ---
    ---@type string
    repository.hooks_url = nil

    --- The issue_comment_url format for the repository.
    ---
    ---@type string
    repository.issue_comment_url = nil

    --- The issue_events format for the repository.
    ---
    ---@type string
    repository.issue_events_url = nil

    --- The issues format for the repository.
    ---
    ---@type string
    repository.issues_url = nil

    --- API endpoint template for fetching pull requests. `{number}` can be replaced with a pull request ID.
    ---
    ---@type string
    repository.pulls_url = nil

    --- The keys format for the repository.
    ---
    ---@type string
    repository.keys_url = nil

    --- The labels format for the repository.
    ---
    ---@type string
    repository.labels_url = nil

    --- The languages format for the repository.
    ---
    ---@type string
    repository.languages_url = nil

    --- The merges format for the repository.
    ---
    ---@type string
    repository.merges_url = nil

    --- The milestones format for the repository.
    ---
    ---@type string
    repository.milestones_url = nil

    ---
    ---
    ---@type string
    repository.notifications_url = nil

    --- API endpoint template for accessing release information. `{id}` is the release ID.
    ---
    ---@type string
    repository.releases_url = nil

    --- API endpoint to list all users who have starred the repository.
    ---
    ---@type string
    repository.stargazers_url = nil

    --- API endpoint for commit statuses (e.g., CI checks) per SHA-1. `{sha}` is the commit SHA-1.
    ---
    ---@type string
    repository.statuses_url = nil

    --- API endpoint to list the watchers (subscribers).
    ---
    ---@type string
    repository.subscribers_url = nil

    --- API endpoint to manage or check a user's subscription to the repository.
    ---
    ---@type string
    repository.subscription_url = nil

    --- URL for cloning the repo over Subversion (legacy).
    ---
    ---@type string
    repository.svn_url = nil

    --- API endpoint to list tags (version snapshots) in the repo.
    ---
    ---@type string
    repository.tags_url = nil

    --- API endpoint listing teams with access to the repository (for organizations).
    ---
    ---@type string
    repository.teams_url = nil

    --- API endpoint template to get Git trees (object structure) by SHA.
    ---
    ---@type string
    repository.trees_url = nil

end


do

    --- [SHARED AND MENU]
    ---
    --- A GitHub blob object.
    ---
    ---@class dreamwork.std.http.github.Blob
    local blob = {}

    --- The base64-encoded content of the file.
    ---
    --- You must decode it to get the original file contents.
    ---
    ---@type string
    blob.content = nil

    --- Encoding format used for content.
    ---
    --- Always `"base64"` for blobs.
    ---
    ---@type string
    blob.encoding = nil

    --- API URL to access this blob object.
    ---
    ---@type string
    blob.url = nil

    --- SHA-1 hash of the blob (unique identifier for the file contents).
    ---
    ---@type string
    blob.sha = nil

    --- Size of the content in bytes (here, 19 bytes).
    ---
    ---@type integer
    blob.size = nil

    --- Internal GitHub GraphQL node ID, base64-encoded.
    ---
    ---@type string
    blob.node_id = nil

end
