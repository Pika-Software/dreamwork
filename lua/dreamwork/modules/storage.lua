local dreamwork_engine = dreamwork.engine
local engine_hook = dreamwork_engine.hook

---@class dreamwork.storage
local storage = {}
dreamwork.storage = storage

local std = dreamwork.std

local assert = std.assert
local pcall = std.pcall

local isTable = std.isTable
local isNumber = std.isNumber
local isString = std.isString
local isCallable = std.isCallable

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local console = std.console

local string = std.string
local string_len = string.len

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
local tostring = std.tostring
local tonumber = std.tonumber

---@type table<string, dreamwork.std.sqlite.ColumnType>
local value_types = { value = "blob" }

--- [SHARED AND MENU]
---
--- Returns the value for the specified key.
---
---@param key string The key of the value.
---@return string | nil value The value, or `nil` if the key does not exist.
---@nodiscard
function storage.read( key )
    local row = sqlite_cast( sqlite_queryFirst( "SELECT hex( value ) AS value FROM 'dreamwork.storage' WHERE key=?", key ), value_types )
    if row == nil then
        return nil
    end

    ---@type string
    return row.value
end

--- [SHARED AND MENU]
---
--- Sets the value for the specified key.
---
--- Values are stored as blobs, so they may contain any bytes.
---
---@param key string The key of the value.
---@param value string The value to store.
function storage.write( key, value )
    sqlite_query( "INSERT INTO 'dreamwork.storage' (key, value) VALUES (?, ?) ON CONFLICT( key ) DO UPDATE SET value = excluded.value", key, SQLiteBlob( value ) )
end

--- [SHARED AND MENU]
---
--- Removes the value for the specified key.
---
---@param key string The key of the value.
function storage.delete( key )
    sqlite_query( "DELETE FROM 'dreamwork.storage' WHERE key=?", key )
end

--- [SHARED AND MENU]
---
--- Returns the JSON-deserialized value for the specified key.
---
--- Raises a `DecodeError` if the stored value is not valid JSON.
---
---@param key string The key of the value.
---@return dreamwork.std.json.Value | nil value The value, or `nil` if the key does not exist.
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
--- Sets the value for the specified key, serialized as JSON.
---
--- Raises an `EncodeError` if the value cannot be serialized.
---
---@param key string The key of the value.
---@param value dreamwork.std.json.Value The value to store.
function storage.writeJSON( key, value )
    storage.write( key, json_serialize( value ) )
end

do

    local http_cache_size = console.Variable( {
        name = "dreamwork.http.cache_size",
        description = "The maximum size of cached content in KB, used for etag caching in http library.",
        replicated = not std.LUA_MENU,
        archive = std.LUA_MENU_SERVER,
        type = "integer",
        default = 50,
        min = 0,
        max = 16384
    } )

    local http_cache_total_size = console.Variable( {
        name = "dreamwork.http.cache_total_size",
        description = "The maximum total size of all cached content in KB, the oldest entries are removed first.",
        replicated = not std.LUA_MENU,
        archive = std.LUA_MENU_SERVER,
        type = "integer",
        default = 8192,
        min = 0,
        max = 1048576
    } )

    local http_cache_lifetime = console.Variable( {
        name = "dreamwork.http.cache_lifetime",
        description = "The number of days cached content is kept for, 0 keeps it forever.",
        replicated = not std.LUA_MENU,
        archive = std.LUA_MENU_SERVER,
        type = "integer",
        default = 30,
        min = 0,
        max = 3650
    } )

    --- [SHARED AND MENU]
    ---
    --- A cache storage for http requests.
    ---
    ---@class dreamwork.storage.http
    local http = {}
    storage.http = http

    ---@class dreamwork.storage.http.Record
    ---@field etag string
    ---@field content string

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { content = "blob" }

    --- [SHARED AND MENU]
    ---
    --- Gets the cached content for the specified URL.
    ---
    ---@param url string
    ---@return dreamwork.storage.http.Record | nil record The cached record, or `nil` if not found.
    ---@nodiscard
    function http.read( url )
        return sqlite_cast( sqlite_queryFirst( "SELECT etag, hex( content ) AS content FROM 'dreamwork.storage.http' WHERE url=? LIMIT 1", url ), record_types )
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the cached content for the specified URL.
    ---
    ---@param url string The URL to cache.
    ---@param etag string The ETag key for the cached content.
    ---@param content string The cached content.
    ---@param ignore_errors? boolean Whether to ignore errors when writing to the cache.
    function http.write( url, etag, content, ignore_errors )
        -- do not cache content that are larger than MAX_SIZE
        if string_len( content ) > (http_cache_size.value * 1024) then
            if ignore_errors then
                return
            end

            error( "content is too large", 2 )
        end

        sqlite_query( "INSERT INTO 'dreamwork.storage.http' (url, etag, timestamp, content) VALUES (?, ?, ?, ?) ON CONFLICT( url ) DO UPDATE SET etag = excluded.etag, timestamp = excluded.timestamp, content = excluded.content", url, etag, time_now( "ms", false ), SQLiteBlob( content ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the cached content for the specified URL.
    ---
    ---@param url string The URL to remove.
    function http.delete( url )
        sqlite_query( "DELETE FROM 'dreamwork.storage.http' WHERE url=?", url )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes expired cache entries, then the oldest ones until the total size fits `dreamwork.http.cache_total_size`.
    ---
    function http.prune()
        local lifetime = http_cache_lifetime.value
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
        ]], http_cache_total_size.value * 1024 )
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- A storage for file hashes.
    ---
    ---@class dreamwork.files
    local files = {}
    storage.files = files

    ---@class dreamwork.storage.files.Record
    ---@field path string
    ---@field size number
    ---@field timestamp number
    ---@field hash string

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { size = "number", timestamp = "number", hash = "blob" }

    --- [SHARED AND MENU]
    ---
    --- Returns the file record for the specified path.
    ---
    ---@param file_path string The path to the file.
    ---@return dreamwork.storage.files.Record | nil data The file record, or `nil` if not found.
    ---@nodiscard
    function files.read( file_path )
        ---@diagnostic disable-next-line: return-type-mismatch
        return sqlite_cast( sqlite_queryFirst( "SELECT path, size, timestamp, hex( hash ) AS hash FROM 'dreamwork.storage.files' WHERE path=?", file_path ), record_types )
    end

    --- [SHARED AND MENU]
    ---
    --- Writes the file record for the specified path.
    ---
    ---@param file_path string The path to the file.
    ---@param file_size integer The size of the file in bytes.
    ---@param file_timestamp integer The timestamp of the file.
    ---@param file_hash string The hash of the file (SHA256/MD5), raw or hex digest.
    function files.write( file_path, file_size, file_timestamp, file_hash )
        sqlite_query( "INSERT INTO 'dreamwork.storage.files' (path, size, timestamp, hash) VALUES (?, ?, ?, ?) ON CONFLICT( path ) DO UPDATE SET size = excluded.size, timestamp = excluded.timestamp, hash = excluded.hash", file_path, file_size, file_timestamp, SQLiteBlob( file_hash ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the file record for the specified path.
    ---
    ---@param file_path string The path to the file.
    function files.delete( file_path )
        sqlite_query( "DELETE FROM 'dreamwork.storage.files' WHERE path=?", file_path )
    end

end

if std.LUA_SERVER then

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
            error( "Invalid repository '" .. tostring( value ) .. "' was given as #1 argument.", 3 )
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
    ---@field name string
    ---@field execute fun( query: fun( str: string, ...: any ): table[] | nil )

    ---@type dreamwork.storage.Migration[]
    local migrations = {
        {
            name = "0.1.0",
            execute = function()
                --- added key-value store
                sqlite_rawQuery( "CREATE TABLE 'dreamwork.storage' (key TEXT UNIQUE, value BLOB)" )

                -- http_cache add primary key
                sqlite_rawQuery( "DROP TABLE IF EXISTS 'dreamwork.storage.http'" )

                sqlite_rawQuery( [[CREATE TABLE 'dreamwork.storage.http' (
                    url TEXT PRIMARY KEY,
                    etag TEXT,
                    timestamp INTEGER,
                    content BLOB
                )]] )

                --- initial file table
                sqlite_rawQuery( [[
                    CREATE TABLE 'dreamwork.storage.files' (
                        path TEXT PRIMARY KEY,
                        size INTEGER NOT NULL CHECK(size >= 0),
                        timestamp INTEGER,
                        hash BLOB
                    )
                ]] )
            end
        },
        {
            name = "0.1.1",
            execute = function()
                --- repositories and packages, server only
                if not std.LUA_SERVER then return end

                sqlite_rawQuery( "CREATE TABLE 'dreamwork.repositories' (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT UNIQUE NOT NULL)" )

                -- `UNIQUE` leads with the parent ID, so its index also serves lookups by repository / package
                sqlite_rawQuery( [[
                    CREATE TABLE 'dreamwork.packages' (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL,
                        url TEXT NOT NULL,
                        type INTEGER NOT NULL,
                        repositoryID INTEGER NOT NULL REFERENCES 'dreamwork.repositories' (id) ON DELETE CASCADE,
                        UNIQUE( repositoryID, name )
                    )
                ]] )

                sqlite_rawQuery( [[
                    CREATE TABLE 'dreamwork.package_versions' (
                        version TEXT NOT NULL,
                        metadata TEXT,
                        packageID INTEGER NOT NULL REFERENCES 'dreamwork.packages' (id) ON DELETE CASCADE,
                        UNIQUE( packageID, version )
                    )
                ]] )
            end
        }
    }

    ---@type table<string, integer>
    local migration_indexes = {}

    for i = 1, #migrations, 1 do
        local migration_name = migrations[ i ].name
        if migration_indexes[ migration_name ] ~= nil then
            error( "Database migration '" .. migration_name .. "' is defined twice." )
        end

        migration_indexes[ migration_name ] = i
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a migration exists and returns `true` or `false`.
    ---
    ---@param name string The name/version of the migration.
    ---@return boolean is_exists `true` if migration exists, `false` otherwise.
    ---@nodiscard
    local function is_migration_exists( name )
        return migration_indexes[ name ] ~= nil
    end

    storage.isMigrationExists = is_migration_exists

    --- [SHARED AND MENU]
    ---
    --- Runs a migration using specified migration table.
    ---
    ---@param migration dreamwork.storage.Migration The migration to run.
    ---@return boolean is_success Always `true`, on failure an error is thrown.
    local function migrate_by_table( migration )
        assert( isCallable( migration.execute ), "Database migration failed: '%s' does not have an 'execute' function.", migration.name )
        dreamwork.Logger:info( "Running migration '" .. tostring( migration.name ) .. "'..." )

        local execute = migration.execute

        -- the migration record is written in the same transaction, so a crash can't leave it unrecorded
        local success, error_object = pcall( sqlite_transaction, function( query )
            execute( query )
            query( "insert into 'dreamwork.storage.migrations' (name, timestamp) values (?, ?)", migration.name, time_now( "ms", false ) )
        end )

        if success then
            return true
        end

        -- rethrown as is, the error already carries the stack of where the migration failed
        dreamwork.Logger:error( "Database migration '%s' failed.", migration.name )
        error( error_object, 2 )
    end

    storage.migrateByTable = migrate_by_table

    --- Runs all migrations up to `last_index` that are not in the migration history yet, in definition order.
    ---
    ---@param last_index integer
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

        for i = 1, last_index, 1 do
            local migration = migrations[ i ]
            if not finished_migrations[ migration.name ] then
                migrate_by_table( migration )
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all pending migrations up to and including the specified one.
    ---
    ---@param name string The name/version of the migration.
    function storage.migrateByName( name )
        local last_index = migration_indexes[ name ]
        if last_index == nil then
            error( "Database migration failed: '" .. tostring( name ) .. "' does not exist.", 2 )
        end

        migrate_until( last_index )
    end

    --- [SHARED AND MENU]
    ---
    --- Runs all pending migrations.
    ---
    function storage.migrate()
        migrate_until( #migrations )
    end

end

---@param ... string
---@return table<string, dreamwork.std.sqlite.QueryRow> | nil
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
--- Initializes the database.
---
function storage.init()
    dreamwork.Logger:info( "Preparing the database to begin migration..." )
    time_tick()

    local pragma_values = pragma_read( "foreign_keys", "journal_mode", "synchronous", "wal_autocheckpoint" )
    if pragma_values ~= nil then
        if (tonumber( pragma_values.foreign_keys or 0, 10 ) or 0) == 0 then
            sqlite_rawQuery( "pragma foreign_keys = 1" )
        end

        if pragma_values.journal_mode == "delete" then
            sqlite_rawQuery( "pragma journal_mode = wal" )
        end

        if (tonumber( pragma_values.synchronous or 0, 10 ) or 0) ~= 1 then
            sqlite_rawQuery( "pragma synchronous = normal" )
        end

        if (tonumber( pragma_values.wal_autocheckpoint or 0, 10 ) or 0) > 100 then
            sqlite_rawQuery( "pragma wal_autocheckpoint = 100" )
        end
    end

    -- truncate WAL journal on shutdown
    engine_hook.catch( "ShutDown", "dreamwork.sqlite", function()
        local success, error_message = pcall( sqlite_rawQuery, "pragma wal_checkpoint(TRUNCATE)" )
        if not success then
            dreamwork.Logger:error( "Failed to truncate WAL journal: %s", error_message )
        end
    end, -1000 )

    sqlite_rawQuery( "CREATE TABLE IF NOT EXISTS 'dreamwork.storage.migrations' (name TEXT, timestamp INTEGER)" )

    storage.migrate()
    storage.http.prune()

    dreamwork.Logger:info( "Migration completed, time spent: %.2f ms.", time_tick( "ms" ) )
end
