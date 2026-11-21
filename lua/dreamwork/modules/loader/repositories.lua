---@class dreamwork
local dreamwork = dreamwork

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile
local vfs_foreach = vfs.foreach
local vfs_readFile = vfs.readFile
local vfs_writeFile = vfs.writeFile
local vfs_deleteFile = vfs.deleteFile
local vfs_isDirectory = vfs.isDirectory

---@class dreamwork.std
local std = dreamwork.std

local LUA_SERVER = std.LUA_SERVER
local LUA_CLIENT = std.LUA_CLIENT
local LUA_REALM = std.LUA_REALM

local class = std.class

local raw = std.raw
local raw_pairs = raw.pairs

local string = std.string
local string_sub = string.sub
local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower
local string_match = string.match
local string_format = string.format
local string_hasSuffix = string.hasSuffix

local table = std.table
local table_sort = table.sort

local github = std.http.github
local github_fetchZip = github.fetchZip
local github_fetchFile = github.fetchFile
local github_getRepositoryTags = github.getRepositoryTags

local Version = std.Version
local Version_validate = Version.validate
local Version_fromString = Version.fromString

local pcall = std.pcall
local error = std.error
local tostring = std.tostring
local isString = std.isString

local URL = std.URL

local Zip = std.Zip

---@class dreamwork.loader
local loader = dreamwork.loader

---@class dreamwork.loader.Internal
local internal = loader.Internal
local packages = internal.packages
local register = internal.register
local load_package = internal.load_package
local archive_base = internal.archive_base
local package_states = internal.package_states
local parse_manifest = internal.parse_manifest
local version_matches = internal.version_matches

---@param data string
---@return dreamwork.std.Zip
local function parse_zip( data )
    return Zip( data )
end

---@param str string
---@return dreamwork.std.URL
local function parse_url( str )
    return URL( str )
end


--- [SHARED AND MENU]
---
--- Repositories: Git hosting services as sources of packages, one repository is one package with `package.json` at its root.
---
--- A package is imported as `user/repo[@range]`, the default host is `https://github.com`,
--- other hosts are written as `host/user/repo[@range]` or `https://host/user/repo[@range]`.
---

--- The directory of the downloaded repository archives, `{host}/{owner}/{repo}/{tag}.dat`.
---
---@type string
local ARCHIVE_DIRECTORY = "/garrysmod/data/dreamwork/packages"

--- The origin of `user/repo` without a host.
---
---@type string
local DEFAULT_ORIGIN = "https://github.com"

--- The archive name of the default branch.
---
---@type string
local DEFAULT_BRANCH_FILE = "head"

--- The hosting services by their origins, `scheme://host`.
---
---@type table<string, dreamwork.loader.RepositoryProvider>
local providers = {}
internal.providers = providers

providers[ DEFAULT_ORIGIN ] = {
    getTags = function( owner, name )
        local success, tags = github_getRepositoryTags( owner, name )
        if not success then
            return false, tags
        end

        ---@cast tags dreamwork.std.http.github.Repository.Tag[]

        ---@type string[]
        local tag_names = {}
        local tag_count = 0

        for index = 1, #tags, 1 do
            local tag_name = tags[ index ].name
            if isString( tag_name ) then
                tag_count = tag_count + 1
                tag_names[ tag_count ] = tag_name
            end
        end

        return true, tag_names
    end,
    fetchFile = github_fetchFile,
    fetchArchive = github_fetchZip
}

--- Splits the repository into its origin, host, owner and name, the owner and the name are lowercase.
---
--- `user/repo` is on `https://github.com`, `host/user/repo` is on `https://host`, a trailing `/` and `.git` are dropped.
---
---@param str string
---@return string | nil origin `nil` if it is not a repository.
---@return string | nil hostname
---@return string | nil owner
---@return string | nil name
local function split_repository( str )
    if string_find( str, "://", 1, true ) == nil then
        if string_find( str, "^[^/]+/[^/]+/?$" ) ~= nil then
            str = DEFAULT_ORIGIN .. "/" .. str
        else
            str = "https://" .. str
        end
    end

    local success, url = pcall( parse_url, str )
    if not success then
        return nil
    end

    ---@cast url dreamwork.std.URL

    local origin, hostname = url.origin, url.hostname
    if origin == nil or hostname == nil then
        return nil
    end

    local owner, name = string_match( url.pathname, "^/([^/]+)/([^/]+)/?$" )
    if owner == nil then
        return nil
    end

    name = string_gsub( name, "%.git$", "" )

    if string_match( owner, "^[%w_%.%-]+$" ) == nil or string_match( name, "^[%w_%.%-]+$" ) == nil then
        return nil
    end

    return origin, hostname, string_lower( owner ), string_lower( name )
end

--- The `{host}/{owner}/{repo}` forms of the `repository` fields of `package.json`, `false` if it is not a repository.
---
---@type table<string, string | false>
local repository_ids = {}

--- Converts the repository to the `{host}/{owner}/{repo}` form, e.g. `github.com/user/my_lib`.
---
---@param str string
---@return string | nil id
local function repository_id( str )
    local id = repository_ids[ str ]
    if id == nil then
        local origin, hostname, owner, name = split_repository( str )
        id = origin ~= nil and (hostname .. "/" .. owner .. "/" .. name) or false
        repository_ids[ str ] = id
    end

    return id or nil
end

--- [SHARED AND MENU]
---
--- A source of packages, a repository on a hosting service (only GitHub for now).
---
--- Versions are the tags of the repository, `v1.0.0` and `1.0.0` are the same version, the package is downloaded as an archive
--- and kept in `/garrysmod/data/dreamwork/packages`, so it is installed again on the next start.
---
---@class dreamwork.Repository : dreamwork.std.Object
---@field __class dreamwork.RepositoryClass
---@field source dreamwork.std.URL The URL of the repository, e.g. `https://github.com/user/my_lib`.
---@field url string The short URL of the repository, e.g. `github.com/user/my_lib`.
---@field host string The host of the repository, e.g. `github.com`.
---@field owner string The owner of the repository, lowercase.
---@field name string The name of the repository, lowercase.
local Repository = class.base( "dreamwork.Repository", false )

--- [SHARED AND MENU]
---
--- The class of `Repository`.
---
---@class dreamwork.RepositoryClass : dreamwork.Repository, dreamwork.std.Class
---@field __base dreamwork.Repository
---@overload fun( url: string ): dreamwork.Repository
local RepositoryClass = class.create( Repository )
loader.Repository = RepositoryClass

---@param url string `user/repo`, `host/user/repo` or `https://host/user/repo`.
---@protected
function Repository:__init( url )
    local origin, hostname, owner, name = split_repository( url )
    if origin == nil then
        error( string_format( "'%s' is not a repository, expected 'user/repo' or 'https://github.com/user/repo'", url ), 3 )
    end

    ---@cast hostname string
    ---@cast owner string
    ---@cast name string

    if providers[ origin ] == nil then
        error( string_format( "'%s' is not a supported repository host", origin ), 3 )
    end

    self.url = hostname .. "/" .. owner .. "/" .. name
    self.host = hostname
    self.owner = owner
    self.name = name
    self.source = URL( origin .. "/" .. owner .. "/" .. name )
end

---@return string
---@protected
function Repository:__represent()
    return string_format( "Repository: %p [%s]", self, self.url )
end

---@param a dreamwork.Repository.Release
---@param b dreamwork.Repository.Release
---@return boolean
local function newer_release( a, b )
    return a.version > b.version
end

--- [SHARED AND MENU]
---
--- Returns the tags of the repository that are semantic versions, the newest first.
---
---@return dreamwork.Repository.Release[] releases The releases.
---@return integer release_count The number of releases.
---@async
function Repository:getReleases()
    local success, tags = providers[ self.source.origin ].getTags( self.owner, self.name )
    if not success then
        error( string_format( "tags of '%s' cannot be fetched: %s", self.url, tags ), 2 )
    end

    ---@cast tags string[]

    ---@type dreamwork.Repository.Release[]
    local releases = {}
    local release_count = 0

    for index = 1, #tags, 1 do
        local tag_name = tags[ index ]
        if Version_validate( tag_name ) then
            release_count = release_count + 1
            releases[ release_count ] = {
                version = Version_fromString( tag_name ),
                tag = tag_name
            }
        end
    end

    table_sort( releases, newer_release )
    return releases, release_count
end

--- [SHARED AND MENU]
---
--- Fetches `package.json` from the root of the repository and validates it, without downloading the archive.
---
---@param tag string? The tag, the default branch if `nil`.
---@return dreamwork.PackageManifest manifest The validated `package.json`.
---@async
function Repository:fetchManifest( tag )
    local success, content = providers[ self.source.origin ].fetchFile( self.owner, self.name, "package.json", tag )
    if not success then
        error( string_format( "'%s' has no 'package.json' in %s: %s", self.url, tag or "the default branch", content ), 2 )
    end

    local manifest, message = parse_manifest( content )
    if manifest == nil then
        error( string_format( "'package.json' of '%s' in %s is invalid: %s", self.url, tag or "the default branch", message ), 2 )
    end

    ---@cast manifest dreamwork.PackageManifest
    return manifest
end

---@param repository dreamwork.Repository
---@param tag string | nil
---@return string
local function archive_path( repository, tag )
    local file_name = DEFAULT_BRANCH_FILE
    if tag ~= nil then
        file_name = string_gsub( string_lower( tag ), "[^%w%._%-]", "_" )
    end

    return string_format( "%s/%s/%s/%s/%s.dat", ARCHIVE_DIRECTORY, repository.host, repository.owner, repository.name, file_name )
end

--- [SHARED AND MENU]
---
--- Downloads the archive of the tag, a downloaded tag is read from `/garrysmod/data/dreamwork/packages`.
---
---@param tag string? The tag, the default branch is downloaded again every time if `nil`.
---@return string data The `.zip` data.
---@return string file_path The path the archive is kept at.
---@async
function Repository:download( tag )
    local file_path = archive_path( self, tag )

    if tag ~= nil and vfs_isFile( file_path ) then
        return vfs_readFile( file_path ), file_path
    end

    local success, data = providers[ self.source.origin ].fetchArchive( self.owner, self.name, tag )
    if not success then
        error( string_format( "'%s' cannot be downloaded: %s", self.url, data ), 2 )
    end

    vfs_writeFile( file_path, data )

    return data, file_path
end

--- Registers the package from the downloaded archive.
---
---@param data string
---@param repository string The repository, `{host}/{owner}/{repo}`.
---@param file_path string The path the archive is kept at, deleted by `loader.uninstall`.
---@param tag string | nil The tag, `nil` for the default branch.
---@return dreamwork.Package | nil package
---@return string | nil message
local function register_archive( data, repository, file_path, tag )
    local success, archive = pcall( parse_zip, data )
    if not success then
        return nil, "invalid archive: " .. tostring( archive )
    end

    ---@cast archive dreamwork.std.Zip

    local base = archive_base( archive, true )
    if base == nil then
        return nil, "'package.json' is missing at the root of the repository"
    end

    local manifest, message = parse_manifest( archive:readFile( base .. "package.json" ) or "" )
    if manifest == nil then
        return nil, message
    end

    ---@cast manifest dreamwork.PackageManifest

    if manifest.repository == nil then
        manifest.repository = repository
    end

    return (register( manifest, {
        kind = "archive",
        archive = archive,
        base = base,
        preprocessed = false,
        repository = repository,
        file = file_path,
        tag = tag
    } )), nil
end

--- [SHARED AND MENU]
---
--- Installs the package from the repository and registers it, without loading it.
---
--- Without a range the default branch is downloaded, with a range the newest version tag that matches it.
--- `package.json` is fetched and validated before the archive is downloaded.
---
---@param selector string? The version range, e.g. `^1.0.0`, the default branch if `nil`, `""`, `"*"` or `"latest"`.
---@return dreamwork.Package package The installed package.
---@async
function Repository:install( selector )
    if selector == "" or selector == "*" or selector == "latest" then
        selector = nil
    end

    ---@type string | nil
    local tag

    if selector ~= nil then
        local releases, release_count = self:getReleases()

        for index = 1, release_count, 1 do
            local release = releases[ index ]
            if version_matches( release.version, selector ) then
                tag = release.tag
                break
            end
        end

        if tag == nil then
            error( string_format( "'%s' has no version tag that matches '%s'", self.url, selector ), 2 )
        end
    end

    -- a downloaded tag was checked before it was downloaded
    if tag == nil or not vfs_isFile( archive_path( self, tag ) ) then
        local manifest = self:fetchManifest( tag )
        if selector ~= nil and not version_matches( Version_fromString( manifest.version ), selector ) then
            error( string_format( "'%s' %s has the version %s in 'package.json', it does not match '%s'", self.url, tag, manifest.version, selector ), 2 )
        end
    end

    local data, file_path = self:download( tag )

    local package, message = register_archive( data, self.url, file_path, tag )
    if package == nil then
        vfs_deleteFile( file_path )
        error( string_format( "'%s' is not a package: %s", self.url, message ), 2 )
    end

    ---@cast package dreamwork.Package

    if not version_matches( package_states[ package ].version, selector ) then
        error( string_format( "'%s' is %s, it does not match '%s'", self.url, package_states[ package ].id, selector ), 2 )
    end

    return package
end

--- Splits `user/repo@range` into the repository and the range, the range is `nil` if missing or empty.
---
---@param spec string
---@return string repository
---@return string | nil selector
local function parse_spec( spec )
    -- a range never has `/`, so only the last `@` after the last `/` starts it
    local at = string_find( spec, "@[^/@]*$" )
    if at == nil then
        return spec, nil
    end

    local selector = string_sub( spec, at + 1 )
    return string_sub( spec, 1, at - 1 ), selector ~= "" and selector or nil
end

--- Finds an installed package of the repository: its `{author}/{name}` is `{owner}/{repo}`,
--- or it was downloaded from the repository, or its `package.json` names the repository.
--- A loaded package is preferred, then the newest one.
---
---@param id string `{host}/{owner}/{repo}`.
---@param key string `{owner}/{repo}`.
---@param selector string | nil
---@return dreamwork.Package | nil
local function find_installed( id, key, selector )
    ---@type dreamwork.Package | nil
    local best

    for _, package in raw_pairs( packages ) do
        local state = package_states[ package ]

        local manifest_repository = state.manifest.repository

        local is_match = string_lower( string_match( state.id, "^[^@]+" ) ) == key
            or state.source.repository == id
            or (manifest_repository ~= nil and repository_id( manifest_repository ) == id)

        if is_match and version_matches( state.version, selector ) then
            if best == nil or (state.status == "loaded" and package_states[ best ].status ~= "loaded") or state.version > package_states[ best ].version then
                best = package
            end
        end
    end

    return best
end

--- Finds the installed package of the repository, or installs it (not on the client).
---
---@param repository string `user/repo`, `host/user/repo` or `https://host/user/repo`.
---@param selector string | nil The version range, the default branch is installed if `nil`.
---@return dreamwork.Package | nil
---@async
local function resolve_package( repository, selector )
    local origin, hostname, owner, name = split_repository( repository )
    if origin == nil then
        error( string_format( "'%s' is not a package, expected 'user/repo[@range]'", repository ), 3 )
    end

    local key = owner .. "/" .. name

    local package = find_installed( hostname .. "/" .. key, key, selector )
    if package ~= nil or LUA_CLIENT then
        return package
    end

    return RepositoryClass( repository ):install( selector )
end

--- [SERVER AND MENU]
---
--- Finds the package, or downloads it from the repository if it is missing, and loads it in this realm.
---
--- A package that does not run in this realm is only installed (e.g. a client package on the server is sent to the clients).
---
--- ```lua
--- loader.install( "user/my_lib" )         -- the installed one, or the default branch
--- loader.install( "user/my_lib@^1.0.0" )  -- the newest tag that matches the range
--- loader.install( "https://github.com/user/my_lib@1.2.0" )
--- ```
---
---@param spec string `user/repo[@range]`, `host/user/repo[@range]` or `https://host/user/repo[@range]`.
---@return dreamwork.Package package The package.
---@return boolean is_loaded `true` if the package is loaded, see `Package.error` otherwise.
---@async
function loader.install( spec )
    local repository, selector = parse_spec( spec )

    local package = resolve_package( repository, selector )
    if package == nil then
        error( string_format( "package '%s' was not found", spec ), 2 )
    end

    ---@cast package dreamwork.Package

    local state = package_states[ package ]
    if not state.realms[ LUA_REALM ] then
        if LUA_SERVER and state.realms.client then
            internal.publish( state )
        end

        return package, false
    end

    return package, load_package( package )
end

--- Collects the loaded packages that depend on the package, directly or through other packages.
---
---@param package dreamwork.Package
---@param list dreamwork.Package[]
---@param seen table<dreamwork.Package, boolean>
local function collect_dependents( package, list, seen )
    for dependent in raw_pairs( package_states[ package ].dependents ) do
        if not seen[ dependent ] then
            seen[ dependent ] = true
            list[ #list + 1 ] = dependent
            collect_dependents( dependent, list, seen )
        end
    end
end

--- Checks if a registered package was installed from the archive.
---
---@param file_path string
---@return boolean
local function is_archive_used( file_path )
    for _, package in raw_pairs( packages ) do
        if package_states[ package ].source.file == file_path then
            return true
        end
    end

    return false
end

--- Uninstalls the package and returns the packages that depended on it and were loaded.
---
---@param package dreamwork.Package
---@param level integer
---@return dreamwork.Package[] dependents
local function uninstall( package, level )
    local state = package_states[ package ]

    local source = state.source
    if source.path ~= nil then
        error( string_format( "'%s' is a local package, delete '%s' instead", state.id, source.path ), level + 1 )
    end

    ---@type dreamwork.Package[]
    local dependents = {}
    collect_dependents( package, dependents, {} )

    loader.remove( package )

    -- a new version of the default branch is kept in the same file
    local file_path = source.file
    if file_path ~= nil and not is_archive_used( file_path ) and vfs_isFile( file_path ) then
        vfs_deleteFile( file_path )
    end

    return dependents
end

--- [SERVER AND MENU]
---
--- Unloads the package (and the packages that depend on it), forgets it and deletes its downloaded archive,
--- the packages that depended on it are loaded again with another version that fits them, if there is one.
---
--- Local packages (`/garrysmod/addons/*/packages`) cannot be uninstalled, delete their folders instead.
---
---@param package dreamwork.Package The package to uninstall.
---@async
function loader.uninstall( package )
    local dependents = uninstall( package, 2 )

    for index = 1, #dependents, 1 do
        local dependent = dependents[ index ]
        if package_states[ dependent ].status == "installed" then
            load_package( dependent )
        end
    end
end

--- [SERVER AND MENU]
---
--- Replaces the package with the newest version from its repository:
--- a package from the default branch is downloaded again, a package from a tag gets the newest version tag.
---
--- A loaded package is unloaded, the new version is loaded, the packages that depended on it are loaded again
--- (they pick the new version if their version ranges allow it), then the old version is uninstalled.
---
---@param package dreamwork.Package The package to upgrade, it must come from a repository.
---@return dreamwork.Package package The newest version, the same package if it is up to date.
---@return boolean is_upgraded `true` if a newer version was installed.
---@async
function loader.upgrade( package )
    local state = package_states[ package ]
    local source = state.source

    local url = source.repository
    if url == nil then
        error( string_format( "'%s' is not installed from a repository", state.id ), 2 )
    end

    ---@cast url string

    local repository = RepositoryClass( url )

    ---@type dreamwork.Package
    local newest

    if source.tag == nil then
        -- the same version of the default branch is the same package
        newest = repository:install( nil )
    else
        local releases, release_count = repository:getReleases()
        if release_count == 0 or not (releases[ 1 ].version > state.version) then
            return package, false
        end

        newest = repository:install( tostring( releases[ 1 ].version ) )
    end

    if newest == package then
        return package, false
    end

    local was_loaded = state.status == "loaded"

    -- dependents are loaded again only after the new version is
    local dependents = uninstall( package, 2 )

    if was_loaded then
        load_package( newest )

        for index = 1, #dependents, 1 do
            local dependent = dependents[ index ]
            if package_states[ dependent ].status == "installed" then
                load_package( dependent )
            end
        end
    elseif LUA_SERVER and package_states[ newest ].realms.client then
        internal.publish( package_states[ newest ] )
    end

    return newest, true
end

--- Registers the packages downloaded from repositories.
local function discover_archives()
    if not vfs_isDirectory( ARCHIVE_DIRECTORY ) then
        return
    end

    local offset = #ARCHIVE_DIRECTORY + 2

    for vfs_path, is_directory in vfs_foreach( ARCHIVE_DIRECTORY ) do
        if not is_directory and string_hasSuffix( vfs_path, ".dat" ) then
            local repository, file_name = string_match( string_sub( vfs_path, offset ), "^([^/]+/[^/]+/[^/]+)/([^/]+)%.dat$" )
            if repository ~= nil then
                local package, message = register_archive( vfs_readFile( vfs_path ), repository, vfs_path, file_name ~= DEFAULT_BRANCH_FILE and file_name or nil )
                if package == nil then
                    dreamwork.Logger:error( "'%s' is invalid: %s", vfs_path, message )
                end
            end
        end
    end
end

internal.parse_spec = parse_spec
internal.resolve_package = resolve_package
internal.discover_archives = discover_archives
