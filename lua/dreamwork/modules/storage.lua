local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook
local dreamwork_Logger = dreamwork.Logger

--- [SHARED AND MENU]
---
--- A persistent SQLite-backed storage with an in-memory read cache.
---
--- Every write goes to the database first and then to the cache, reads are served from the cache and fall back to the database.
---
---@class dreamwork.storage
local storage = {}
dreamwork.storage = storage

local std = dreamwork.std

local isTable = std.isTable
local isNumber = std.isNumber
local isString = std.isString

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber
local raw_tostring = raw.tostring

local string = std.string
local string_len = string.len
local string_gsub = string.gsub
local string_trim = string.trim
local string_format = string.format

local table_concat = std.table.concat

local json = std.json
local json_serialize, json_deserialize = json.serialize, json.deserialize

local sqlite = std.sqlite
local SQLiteBlob = sqlite.Blob
local sqlite_cast = sqlite.cast
local sqlite_transaction = sqlite.transaction
local sqlite_query, sqlite_rawQuery = sqlite.query, sqlite.rawQuery
local sqlite_queryFirst, sqlite_queryValue = sqlite.queryFirst, sqlite.queryValue

local time = std.time
local time_now = time.now
local time_tick = time.tick

local error = std.error
local pcall = std.pcall
local assert = std.assert
local tonumber = std.tonumber

local LUA_SERVER = std.LUA_SERVER


do

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local value_types = { value = "blob" }

    ---@type table<string, string>
    local cache = {}

    --- [SHARED AND MENU]
    ---
    --- Returns the value stored under the specified key.
    ---
    --- The value is read from the cache, on a miss it is loaded from the database and cached.
    ---
    ---@param key string The key of the value.
    ---@return string | nil value The stored value, or `nil` if the key does not exist.
    ---@nodiscard
    function storage.read( key )
        ---@type string
        local value = cache[ key ]
        if value ~= nil then
            return value
        end

        local row = sqlite_cast( sqlite_queryFirst( "SELECT hex( value ) AS value FROM 'dreamwork.storage' WHERE key=?", key ), value_types )
        if row == nil then
            return nil
        end

        local row_value = raw_tostring( row.value )
        cache[ key ] = row_value

        ---@type string
        return row_value
    end

    --- [SHARED AND MENU]
    ---
    --- Stores the value under the specified key, replacing the previous one.
    ---
    --- Values are stored as blobs, so they may contain any bytes.
    ---
    ---@param key string The key of the value.
    ---@param value string The value to store.
    function storage.write( key, value )
        sqlite_query( "INSERT INTO 'dreamwork.storage' (key, value) VALUES (?, ?) ON CONFLICT( key ) DO UPDATE SET value = excluded.value", key, SQLiteBlob( value ) )
        cache[ key ] = value
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the value stored under the specified key, does nothing if the key does not exist.
    ---
    ---@param key string The key of the value.
    function storage.delete( key )
        sqlite_query( "DELETE FROM 'dreamwork.storage' WHERE key=?", key )
        cache[ key ] = nil
    end

end

--- [SHARED AND MENU]
---
--- Returns the value stored under the specified key, deserialized from JSON.
---
--- Raises a `DecodeError` if the stored value is not valid JSON.
---
---@param key string The key of the value.
---@return dreamwork.std.json.Object | dreamwork.std.json.Array | nil value The value, or `nil` if the key does not exist.
---@nodiscard
function storage.readJSON( key )
    local value = storage.read( key )
    if value == nil then
        return nil
    end

    return json_deserialize( value )
end

--- [SHARED AND MENU]
---
--- Stores the value under the specified key, serialized as JSON.
---
--- Raises an `EncodeError` if the value cannot be serialized.
---
---@param key string The key of the value.
---@param value dreamwork.std.json.Value The value to serialize and store.
function storage.writeJSON( key, value )
    storage.write( key, json_serialize( value ) )
end

do

    --- [SHARED AND MENU]
    ---
    --- A cache of HTTP responses, keyed by URL and validated by ETag.
    ---
    --- Size and lifetime limits are controlled by `storage.http.config`, set by the `http_client` console command (`dreamwork_sci` / `dreamwork_cci`).
    ---
    ---@class dreamwork.storage.http
    local http = {}
    storage.http = http

    ---@class dreamwork.storage.http.Config
    ---@field cache_size integer The maximum size of a cached response in KB.
    ---@field cache_total_size integer The maximum total size of all cached responses in KB, the oldest entries are removed first.
    ---@field cache_lifetime integer The number of days cached responses are kept for, `0` keeps them forever.

    ---@type dreamwork.storage.http.Config
    local config = {
        cache_size = 50,
        cache_total_size = 8192,
        cache_lifetime = 30
    }

    http.config = config

    ---@class dreamwork.storage.http.Record
    ---@field etag string The ETag of the cached response.
    ---@field content string The cached response body.

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { content = "blob" }

    ---@type table<string, dreamwork.storage.http.Record>
    local cache = {}

    --- [SHARED AND MENU]
    ---
    --- Returns the cached response for the specified URL.
    ---
    --- The returned record is shared with the in-memory cache, do not modify it.
    ---
    ---@param url string The URL of the cached response.
    ---@return dreamwork.storage.http.Record | nil record The cached record, or `nil` if the URL is not cached.
    ---@nodiscard
    function http.read( url )
        ---@type dreamwork.storage.http.Record | nil
        local record = cache[ url ]
        if record ~= nil then
            return record
        end

        record = sqlite_cast( sqlite_queryFirst( "SELECT etag, hex( content ) AS content FROM 'dreamwork.storage.http' WHERE url=? LIMIT 1", url ), record_types )
        if record ~= nil then
            cache[ url ] = record
        end

        return record
    end

    --- [SHARED AND MENU]
    ---
    --- Caches the response for the specified URL, replacing the previous one.
    ---
    --- Raises an error if the content is larger than `config.cache_size`.
    ---
    ---@param url string The URL of the response.
    ---@param etag string The ETag of the response.
    ---@param content string The response body.
    ---@param ignore_errors? boolean If `true`, too large content is silently skipped instead of raising an error.
    function http.write( url, etag, content, ignore_errors )
        -- do not cache content that is larger than `config.cache_size`
        local content_size, max_size = string_len( content ), config.cache_size * 1024
        if content_size > max_size then
            if ignore_errors then
                return
            end

            error( string_format( "HTTP cache entry for '%s' is too large: %d bytes, the limit is %d bytes (http_client cache_size).", url, content_size, max_size ), 2 )
        end

        sqlite_query( "INSERT INTO 'dreamwork.storage.http' (url, etag, timestamp, content) VALUES (?, ?, ?, ?) ON CONFLICT( url ) DO UPDATE SET etag = excluded.etag, timestamp = excluded.timestamp, content = excluded.content", url, etag, time_now( "ms", false ), SQLiteBlob( content ) )
        cache[ url ] = { etag = etag, content = content }
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the cached response for the specified URL, does nothing if the URL is not cached.
    ---
    ---@param url string The URL of the cached response.
    function http.delete( url )
        sqlite_query( "DELETE FROM 'dreamwork.storage.http' WHERE url=?", url )
        cache[ url ] = nil
    end

    --- [SHARED AND MENU]
    ---
    --- Removes entries older than `config.cache_lifetime`, then the oldest ones until the total size fits `config.cache_total_size`.
    ---
    --- Clears the in-memory cache, so the remaining entries are reloaded from the database on demand.
    ---
    function http.prune()
        local lifetime = config.cache_lifetime
        if lifetime > 0 then
            sqlite_query( "DELETE FROM 'dreamwork.storage.http' WHERE timestamp < ?", time_now( "ms", false ) - lifetime * 86400000 )
        end

        -- running total from the newest entry, everything past the limit goes
        sqlite_query( [[
            DELETE FROM 'dreamwork.storage.http' WHERE url IN (
                SELECT url FROM (
                    SELECT url, SUM( length( CAST( content AS BLOB ) ) ) OVER ( ORDER BY timestamp DESC, url ) AS total_size
                    FROM 'dreamwork.storage.http'
                ) WHERE total_size > ?
            )
        ]], config.cache_total_size * 1024 )

        -- rows were removed in bulk, so the cache cannot be trusted anymore
        cache = {}
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- A storage of file records (size, timestamp and hash), used to detect changed files.
    ---
    ---@class dreamwork.storage.files
    local files = {}
    storage.files = files

    ---@class dreamwork.storage.files.Record
    ---@field path string The path to the file.
    ---@field size integer The size of the file in bytes.
    ---@field timestamp integer The modification timestamp of the file.
    ---@field hash string The hash of the file, as it was written.

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { size = "number", timestamp = "number", hash = "blob" }

    ---@type table<string, dreamwork.storage.files.Record>
    local cache = {}

    --- [SHARED AND MENU]
    ---
    --- Returns the file record for the specified path.
    ---
    --- The returned record is shared with the in-memory cache, do not modify it.
    ---
    ---@param file_path string The path to the file.
    ---@return dreamwork.storage.files.Record | nil record The file record, or `nil` if the path is not stored.
    ---@nodiscard
    function files.read( file_path )
        local record = cache[ file_path ]
        if record ~= nil then
            return record
        end

        ---@diagnostic disable-next-line: cast-local-type
        record = sqlite_cast( sqlite_queryFirst( "SELECT path, size, timestamp, hex( hash ) AS hash FROM 'dreamwork.storage.files' WHERE path=?", file_path ), record_types )
        if record ~= nil then
            cache[ file_path ] = record
        end

        return record
    end

    --- [SHARED AND MENU]
    ---
    --- Stores the file record for the specified path, replacing the previous one.
    ---
    ---@param file_path string The path to the file.
    ---@param file_size integer The size of the file in bytes.
    ---@param file_timestamp integer The modification timestamp of the file.
    ---@param file_hash string The hash of the file (SHA256/MD5), raw or hex digest.
    function files.write( file_path, file_size, file_timestamp, file_hash )
        sqlite_query( "INSERT INTO 'dreamwork.storage.files' (path, size, timestamp, hash) VALUES (?, ?, ?, ?) ON CONFLICT( path ) DO UPDATE SET size = excluded.size, timestamp = excluded.timestamp, hash = excluded.hash", file_path, file_size, file_timestamp, SQLiteBlob( file_hash ) )
        cache[ file_path ] = { path = file_path, size = file_size, timestamp = file_timestamp, hash = file_hash }
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the file record for the specified path, does nothing if the path is not stored.
    ---
    ---@param file_path string The path to the file.
    function files.delete( file_path )
        sqlite_query( "DELETE FROM 'dreamwork.storage.files' WHERE path=?", file_path )
        cache[ file_path ] = nil
    end

end

if LUA_SERVER then

    --- [SERVER]
    ---
    --- A storage for package repositories, the packages they provide and the versions of these packages.
    ---
    ---@class dreamwork.repositories
    local repositories = {}
    dreamwork.repositories = repositories

    ---@class dreamwork.repositories.Repository
    ---@field id integer The repository ID.
    ---@field url string The repository URL.

    ---@class dreamwork.repositories.PackageVersion
    ---@field version string The version of the package.
    ---@field metadata string | dreamwork.std.null The metadata of the version.

    ---@class dreamwork.repositories.Package
    ---@field id integer The package ID.
    ---@field name string The package name, unique within its repository.
    ---@field url string The package URL.
    ---@field type integer The package type.
    ---@field repositoryID integer The ID of the repository that provides the package.
    ---@field versions dreamwork.repositories.PackageVersion[] The versions of the package.

    ---@class dreamwork.repositories.PackageInfo
    ---@field name string The package name, unique within its repository.
    ---@field url string The package URL.
    ---@field type integer The package type.
    ---@field versions? dreamwork.repositories.PackageVersion[] The versions of the package, all old versions are replaced.

    ---@alias dreamwork.repositories.RepositoryValue dreamwork.repositories.Repository | integer | string

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local repository_types = { id = "number" }

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local package_types = { id = "number", type = "number", repositoryID = "number" }

    --- [SERVER]
    ---
    --- Returns a list of all repositories.
    ---
    ---@return dreamwork.repositories.Repository[] list The list of repositories.
    ---@nodiscard
    function repositories.getRepositories()
        local rows = sqlite_query( "SELECT id, url FROM 'dreamwork.repositories' ORDER BY id" )
        if rows == nil then
            return {}
        end

        for i = 1, #rows, 1 do
            sqlite_cast( rows[ i ], repository_types )
        end

        ---@diagnostic disable-next-line: return-type-mismatch
        return rows
    end

    --- [SERVER]
    ---
    --- Adds a new repository to the database, an existing repository with the same URL is kept as is.
    ---
    ---@param url string The repository URL.
    ---@return dreamwork.repositories.Repository repository The added or existing repository.
    function repositories.addRepository( url )
        -- gmod's sqlite is older than the `RETURNING` clause
        sqlite_query( "INSERT INTO 'dreamwork.repositories' (url) VALUES (?) ON CONFLICT( url ) DO NOTHING", url )

        ---@diagnostic disable-next-line: return-type-mismatch
        return sqlite_cast( sqlite_queryFirst( "SELECT id, url FROM 'dreamwork.repositories' WHERE url=?", url ), repository_types )
    end

    --- Returns the repository ID for the specified repository.
    ---
    ---@param value dreamwork.repositories.RepositoryValue The repository, its ID or its URL.
    ---@return integer | nil id The repository ID, or `nil` if the repository does not exist.
    local function get_repository_id( value )
        if isTable( value ) then
            ---@cast value dreamwork.repositories.Repository
            return value.id or get_repository_id( value.url )
        elseif isNumber( value ) then
            ---@cast value integer
            return value
        elseif isString( value ) then
            ---@cast value string
            return raw_tonumber( sqlite_queryValue( "SELECT id FROM 'dreamwork.repositories' WHERE url=?", value ) )
        end

        return nil
    end

    --- Returns the repository ID for the specified repository, or throws an error if it does not exist.
    ---
    ---@param value dreamwork.repositories.RepositoryValue The repository, its ID or its URL.
    ---@return integer id The repository ID.
    local function resolve_repository_id( value )
        local repository_id = get_repository_id( value )
        if repository_id == nil then
            error( string_format( "Repository '%s' does not exist.", value ), 3 )
        end

        return repository_id
    end

    --- [SERVER]
    ---
    --- Removes the specified repository from the database, together with all its packages and their versions.
    ---
    ---@param repository dreamwork.repositories.RepositoryValue The repository to remove, its ID or its URL.
    function repositories.removeRepository( repository )
        -- packages and versions are removed by `ON DELETE CASCADE`
        sqlite_query( "DELETE FROM 'dreamwork.repositories' WHERE id=?", resolve_repository_id( repository ) )
    end

    --- [SERVER]
    ---
    --- Returns the package for the specified repository and name.
    ---
    ---@param repository dreamwork.repositories.RepositoryValue The repository to get the package from, its ID or its URL.
    ---@param name string The name of the package to get.
    ---@return dreamwork.repositories.Package | nil pkg The package, or `nil` if the package does not exist.
    ---@nodiscard
    function repositories.getPackage( repository, name )
        local pkg = sqlite_cast( sqlite_queryFirst( "SELECT id, name, url, type, repositoryID FROM 'dreamwork.packages' WHERE repositoryID=? AND name=?", resolve_repository_id( repository ), name ), package_types )
        if pkg == nil then
            return nil
        end

        pkg.versions = sqlite_query( "SELECT version, metadata FROM 'dreamwork.package_versions' WHERE packageID=?", pkg.id ) or {}

        ---@diagnostic disable-next-line: return-type-mismatch
        return pkg
    end

    --- [SERVER]
    ---
    --- Returns a list of packages for the specified repository.
    ---
    ---@param repository dreamwork.repositories.RepositoryValue The repository to get the packages from, its ID or its URL.
    ---@return dreamwork.repositories.Package[] list The list of packages.
    ---@nodiscard
    function repositories.getPackages( repository )
        local repository_id = resolve_repository_id( repository )

        local packages = sqlite_query( "SELECT id, name, url, type, repositoryID FROM 'dreamwork.packages' WHERE repositoryID=?", repository_id )
        if packages == nil then
            return {}
        end

        ---@type table<integer, dreamwork.repositories.PackageVersion[]>
        local package_versions = {}

        for i = 1, #packages, 1 do
            local pkg = sqlite_cast( packages[ i ], package_types )
            ---@cast pkg dreamwork.repositories.Package

            local versions = {}
            pkg.versions = versions
            package_versions[ pkg.id ] = versions
        end

        -- all versions in one query instead of one query per package
        local rows = sqlite_query( "SELECT v.packageID AS packageID, v.version AS version, v.metadata AS metadata FROM 'dreamwork.package_versions' AS v JOIN 'dreamwork.packages' AS p ON p.id = v.packageID WHERE p.repositoryID=?", repository_id )
        if rows ~= nil then
            for i = 1, #rows, 1 do
                local row = rows[ i ]

                local versions = package_versions[ raw_tonumber( row.packageID ) ]
                versions[ #versions + 1 ] = { version = row.version, metadata = row.metadata }
            end
        end

        ---@diagnostic disable-next-line: return-type-mismatch
        return packages
    end

    --- [SERVER]
    ---
    --- Replaces the packages of the specified repository.
    ---
    --- Packages that are not in `packages` are removed, existing packages keep their IDs.
    ---
    ---@param repository dreamwork.repositories.RepositoryValue The repository to update, its ID or its URL.
    ---@param packages dreamwork.repositories.PackageInfo[] | table<any, dreamwork.repositories.PackageInfo> The new packages of the repository.
    function repositories.updateRepository( repository, packages )
        local repository_id = resolve_repository_id( repository )

        sqlite_transaction( function( query )
            -- IDs stay as returned by sqlite, they are only used as keys and query parameters
            ---@type table<string, boolean>
            local kept_packages = {}

            for _, pkg in raw_pairs( packages ) do
                -- upsert instead of `REPLACE`, so the package keeps its ID and its versions are not orphaned
                query( "INSERT INTO 'dreamwork.packages' (name, url, type, repositoryID) VALUES (?, ?, ?, ?) ON CONFLICT( repositoryID, name ) DO UPDATE SET url = excluded.url, type = excluded.type", pkg.name, pkg.url, pkg.type, repository_id )

                -- the row always exists after the upsert above
                local package_id = sqlite_queryValue( "SELECT id FROM 'dreamwork.packages' WHERE repositoryID=? AND name=?", repository_id, pkg.name )
                ---@cast package_id string

                kept_packages[ package_id ] = true

                query( "DELETE FROM 'dreamwork.package_versions' WHERE packageID=?", package_id )

                local versions = pkg.versions
                if versions ~= nil then
                    for i = 1, #versions, 1 do
                        local package_version = versions[ i ]
                        query( "INSERT INTO 'dreamwork.package_versions' (version, metadata, packageID) VALUES (?, ?, ?) ON CONFLICT( packageID, version ) DO UPDATE SET metadata = excluded.metadata", package_version.version, package_version.metadata, package_id )
                    end
                end
            end

            -- remove packages that are gone, their versions are removed by `ON DELETE CASCADE`
            local rows = query( "SELECT id FROM 'dreamwork.packages' WHERE repositoryID=?", repository_id )
            if rows ~= nil then
                for i = 1, #rows, 1 do
                    local package_id = rows[ i ].id
                    if not kept_packages[ package_id ] then
                        query( "DELETE FROM 'dreamwork.packages' WHERE id=?", package_id )
                    end
                end
            end
        end )
    end

end

do

    ---@class dreamwork.storage.Migration
    ---@field name string The unique name/version of the migration.
    ---@field queries string[] The SQL queries of the migration, executed in order inside a single transaction.

    ---@type dreamwork.storage.Migration[]
    local migrations = {
        {
            name = "0.1.0",
            queries = {
                -- added key-value store
                "CREATE TABLE 'dreamwork.storage' (key TEXT UNIQUE, value BLOB)",

                -- http_cache add primary key
                "DROP TABLE IF EXISTS 'dreamwork.storage.http'",

                [[
                    CREATE TABLE 'dreamwork.storage.http' (
                        url TEXT PRIMARY KEY,
                        etag TEXT,
                        timestamp INTEGER,
                        content BLOB
                    )
                ]],

                -- initial file table
                [[
                    CREATE TABLE 'dreamwork.storage.files' (
                        path TEXT PRIMARY KEY,
                        size INTEGER NOT NULL CHECK(size >= 0),
                        timestamp INTEGER,
                        hash BLOB
                    )
                ]],

                "CREATE TABLE 'dreamwork.repositories' (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT UNIQUE NOT NULL)",

                -- `UNIQUE` leads with the parent ID, so its index also serves lookups by repository / package
                [[
                    CREATE TABLE 'dreamwork.packages' (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        url TEXT NOT NULL,
                        type INTEGER NOT NULL,
                        repositoryID INTEGER NOT NULL REFERENCES 'dreamwork.repositories' (id) ON DELETE CASCADE,
                        UNIQUE( repositoryID, name )
                    )
                ]],

                [[
                    CREATE TABLE 'dreamwork.package_versions' (
                        version TEXT NOT NULL,
                        metadata TEXT,
                        packageID INTEGER NOT NULL REFERENCES 'dreamwork.packages' (id) ON DELETE CASCADE,
                        UNIQUE( packageID, version )
                    )
                ]]
            }
        }
    }

    ---@type table<string, integer>
    local migration_indexes = {}

    for i = 1, #migrations, 1 do
        local migration = migrations[ i ]
        local migration_name = migration.name

        if migration_indexes[ migration_name ] ~= nil then
            error( string_format( "Database migration '%s' is defined more than once.", migration_name ) )
        end

        migration_indexes[ migration_name ] = i
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a migration with the specified name is defined.
    ---
    ---@param name string The name/version of the migration.
    ---@return boolean is_exists `true` if the migration is defined, `false` otherwise.
    ---@nodiscard
    local function is_migration_exists( name )
        return migration_indexes[ name ] ~= nil
    end

    storage.isMigrationExists = is_migration_exists

    --- [SHARED AND MENU]
    ---
    --- Runs the specified migration in a transaction and records it in the migration history.
    ---
    --- The migration history is not checked, so the migration runs even if it was already applied.
    ---
    --- On failure the transaction is rolled back and the error is rethrown.
    ---
    ---@param migration dreamwork.storage.Migration The migration to run.
    ---@return boolean is_success Always `true`, on failure an error is thrown.
    local function migrate_by_table( migration )
        local queries = migration.queries
        assert( isTable( queries ), "Database migration '%s' has no 'queries' table.", migration.name )
        dreamwork_Logger:info( "Applying database migration '%s'...", migration.name )

        -- the migration record is written in the same transaction, so a crash can't leave it unrecorded
        local success, error_object = pcall( sqlite_transaction, function( query )
            for i = 1, #queries, 1 do
                sqlite_rawQuery( queries[ i ] )
            end

            query( "insert into 'dreamwork.storage.migrations' (name, timestamp) values (?, ?)", migration.name, time_now( "ms", false ) )
        end )

        if success then
            return true
        end

        -- rethrown as is, the error already carries the stack of where the migration failed
        dreamwork_Logger:error( "Database migration '%s' failed, its changes were rolled back.", migration.name )
        error( error_object, 2 )
    end

    storage.migrateByTable = migrate_by_table

    --- Runs all migrations up to `last_index` that are not in the migration history yet, in definition order.
    ---
    ---@param last_index integer The index of the last migration to run.
    local function migrate_until( last_index )
        ---@type table<string, boolean>
        local finished_migrations = {}

        local history = sqlite_rawQuery( "select name from 'dreamwork.storage.migrations'" )
        if history ~= nil then
            for i = 1, #history, 1 do
                local history_name = history[ i ].name
                if isString( history_name ) then
                    ---@cast history_name string
                    finished_migrations[ history_name ] = true
                end
            end
        end

        ---@type dreamwork.storage.Migration[]
        local pending_migrations = {}
        local pending_count = 0

        for i = 1, last_index, 1 do
            local migration = migrations[ i ]
            if not finished_migrations[ migration.name ] then
                pending_count = pending_count + 1
                pending_migrations[ pending_count ] = migration
            end
        end

        if pending_count == 0 then
            return
        end

        ---@type string[]
        local pending_names = {}

        for i = 1, pending_count, 1 do
            pending_names[ i ] = "\"" .. pending_migrations[ i ].name .. "\""
        end

        dreamwork_Logger:info( "Found %d pending database migration%s: %s", pending_count, pending_count == 1 and "" or "s", table_concat( pending_names, " -> ", 1, pending_count ) )

        for i = 1, pending_count, 1 do
            migrate_by_table( pending_migrations[ i ] )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all pending migrations up to and including the specified one, in definition order.
    ---
    --- Raises an error if the migration is not defined.
    ---
    ---@param name string The name/version of the last migration to run.
    function storage.migrateByName( name )
        local last_index = migration_indexes[ name ]
        if last_index == nil then
            error( string_format( "Database migration '%s' does not exist.", name ), 2 )
        end

        migrate_until( last_index )
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all pending migrations, in definition order.
    ---
    function storage.migrate()
        migrate_until( #migrations )
    end

end

--- Returns the current values of the specified pragmas, pragmas without a result are omitted.
---
---@param ... string The names of the pragmas.
---@return table<string, string | number> values
local function pragma_read( ... )
    local keys = { ... }
    local key_count = select( "#", ... )

    local results = {}

    -- one query per pragma, so a pragma without a result row can't shift the others
    for i = 1, key_count, 1 do
        local key = keys[ i ]

        local rows = sqlite_rawQuery( "pragma " .. key )
        if rows ~= nil and rows[ 1 ] ~= nil then
            results[ key ] = rows[ 1 ][ key ]
        end
    end

    return results
end

--- [SHARED AND MENU]
---
--- Initializes the database: tunes the SQLite pragmas and runs all pending migrations.
---
--- The HTTP cache is pruned by the `http_client` console command (`dreamwork_sci` / `dreamwork_cci`), once its saved limits are applied.
---
function storage.init()
    dreamwork_Logger:info( "Initializing the database..." )
    time_tick()

    local pragma_values = pragma_read( "foreign_keys", "journal_mode", "synchronous", "wal_autocheckpoint" )
    if pragma_values ~= nil then
        if (tonumber( pragma_values.foreign_keys, 10 ) or 0) == 0 then
            sqlite_rawQuery( "pragma foreign_keys = 1" )
        end

        if pragma_values.journal_mode == "delete" then
            sqlite_rawQuery( "pragma journal_mode = wal" )
        end

        if (tonumber( pragma_values.synchronous, 10 ) or 0) ~= 1 then
            sqlite_rawQuery( "pragma synchronous = normal" )
        end

        if (tonumber( pragma_values.wal_autocheckpoint, 10 ) or 0) > 100 then
            sqlite_rawQuery( "pragma wal_autocheckpoint = 100" )
        end
    end

    -- truncate WAL journal on shutdown
    engine_hook.catch( "ShutDown", "dreamwork.sqlite", function()
        local success, error_message = pcall( sqlite_rawQuery, "pragma wal_checkpoint(TRUNCATE)" )
        if not success then
            dreamwork_Logger:error( "Failed to truncate the SQLite WAL journal on shutdown: %s", error_message )
        end
    end, -1000 )

    sqlite_rawQuery( "CREATE TABLE IF NOT EXISTS 'dreamwork.storage.migrations' (name TEXT, timestamp INTEGER)" )

    storage.migrate()

    dreamwork_Logger:info( "Database initialized in %.2f ms.", time_tick( "ms" ) )
end
