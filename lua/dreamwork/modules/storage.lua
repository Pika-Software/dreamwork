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
local isString = std.isString

local raw = std.raw
local raw_tostring = raw.tostring

local string = std.string
local string_format = string.format

local table_concat = std.table.concat

local json = std.json
local json_encode, json_decode = json.encode, json.decode

local sqlite = std.sqlite
local SQLiteBlob = sqlite.Blob
local sqlite_cast = sqlite.cast
local sqlite_queryFirst = sqlite.queryFirst
local sqlite_transaction = sqlite.transaction
local sqlite_query, sqlite_rawQuery = sqlite.query, sqlite.rawQuery

local time = std.time
local time_now = time.now
local time_tick = time.tick

local error = std.error
local pcall = std.pcall
local assert = std.assert
local tonumber = std.tonumber

local LUA_MENU = std.LUA_MENU

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
---@return dreamwork.std.json.Value | nil value The value, or `nil` if the key does not exist.
---@nodiscard
function storage.readJSON( key )
    local value = storage.read( key )
    if value == nil then
        return nil
    end

    return json_decode( value )
end

--- [SHARED AND MENU]
---
--- Stores the value under the specified key, serialized as JSON.
---
--- Raises an `EncodeError` if the value cannot be serialized.
---
---@param key string The key of the value.
---@param value dreamwork.std.json.Value The value to encode and store.
function storage.writeJSON( key, value )
    storage.write( key, json_encode( value ) )
end

do

    --- [SHARED AND MENU]
    ---
    --- A cache of HTTP responses, keyed by URL and validated by ETag.
    ---
    --- The size and lifetime limits are owned by the caller, see `http.client`.
    ---
    ---@class dreamwork.storage.http
    local http = {}
    storage.http = http

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
    ---@param url string The URL of the response.
    ---@param etag string The ETag of the response.
    ---@param content string The response body.
    function http.write( url, etag, content )
        sqlite_query(
            "INSERT INTO 'dreamwork.storage.http' (url, etag, timestamp, content) VALUES (?, ?, ?, ?) ON CONFLICT( url ) DO UPDATE SET etag = excluded.etag, timestamp = excluded.timestamp, content = excluded.content",
            url, etag, time_now( "ms", false ), SQLiteBlob( content )
        )

        cache[ url ] = {
            etag = etag,
            content = content,
        }
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
    --- Removes entries older than `lifetime`, then the oldest ones until the total size fits `total_size`.
    ---
    --- Clears the in-memory cache, so the remaining entries are reloaded from the database on demand.
    ---
    ---@param lifetime integer The time an entry is kept for, in milliseconds, `0` keeps it forever.
    ---@param total_size integer The size of all entries in bytes.
    function http.prune( lifetime, total_size )
        if lifetime > 0 then
            sqlite_query( "DELETE FROM 'dreamwork.storage.http' WHERE timestamp < ?", time_now( "ms", false ) - lifetime )
        end

        -- running total from the newest entry, everything past the limit goes
        sqlite_query( string.unindentLines( [[
            DELETE FROM 'dreamwork.storage.http' WHERE url IN (
                SELECT url FROM (
                    SELECT url, SUM( length( CAST( content AS BLOB ) ) ) OVER ( ORDER BY timestamp DESC, url ) AS total_size
                    FROM 'dreamwork.storage.http'
                ) WHERE total_size > ?
            )
        ]], 12 ), total_size )

        -- rows were removed in bulk, so the cache cannot be trusted anymore
        cache = {}
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- The records of the files downloaded by `dreamwork.transport`, by their SHA-256 hashes:
    --- the size and CRC-32 to check the cached file quickly and the last use for the cleanup.
    ---
    ---@class dreamwork.storage.transport
    local transport = {}
    storage.transport = transport

    ---@class dreamwork.storage.transport.Record
    ---@field hash string The SHA-256 hash of the file, lowercase hex, the name of the cached file.
    ---@field size integer The size of the file in bytes.
    ---@field checksum integer The CRC-32 of the file.
    ---@field timestamp integer The last use of the file, unix time in milliseconds.

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { size = "number", checksum = "number", timestamp = "number" }

    --- [SHARED AND MENU]
    ---
    --- Returns the record of the file.
    ---
    ---@param hash string The SHA-256 hash of the file, lowercase hex.
    ---@return dreamwork.storage.transport.Record | nil record The record, or `nil` if the file is not stored.
    ---@nodiscard
    function transport.read( hash )
        ---@type dreamwork.storage.transport.Record | nil
        return sqlite_cast( sqlite_queryFirst( "SELECT hash, size, checksum, timestamp FROM 'dreamwork.storage.transport' WHERE hash=?", hash ), record_types )
    end

    --- [SHARED AND MENU]
    ---
    --- Stores the record of the file, marked as used now.
    ---
    ---@param hash string The SHA-256 hash of the file, lowercase hex.
    ---@param size integer The size of the file in bytes.
    ---@param checksum integer The CRC-32 of the file.
    function transport.write( hash, size, checksum )
        sqlite_query( "INSERT INTO 'dreamwork.storage.transport' (hash, size, checksum, timestamp) VALUES (?, ?, ?, ?) ON CONFLICT( hash ) DO UPDATE SET size = excluded.size, checksum = excluded.checksum, timestamp = excluded.timestamp", hash, size, checksum, time_now( "ms", false ) )
    end

    --- [SHARED AND MENU]
    ---
    --- Marks the file as used now, so the cleanup keeps it.
    ---
    ---@param hash string The SHA-256 hash of the file, lowercase hex.
    function transport.touch( hash )
        sqlite_query( "UPDATE 'dreamwork.storage.transport' SET timestamp=? WHERE hash=?", time_now( "ms", false ), hash )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the record of the file, does nothing if the file is not stored.
    ---
    ---@param hash string The SHA-256 hash of the file, lowercase hex.
    function transport.delete( hash )
        sqlite_query( "DELETE FROM 'dreamwork.storage.transport' WHERE hash=?", hash )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the records of the files not used since `used_before`: the ones older than `lifetime`,
    --- then the oldest ones until the files take no more than `total_size`, and returns their hashes, so their files can be deleted.
    ---
    ---@param used_before integer The files used at or after this unix time in milliseconds are never removed (e.g. the ones used in this session).
    ---@param lifetime integer The time a file is kept for since its last use, in milliseconds, `0` keeps it forever.
    ---@param total_size integer The size of all files in bytes, `0` does not limit it.
    ---@return string[] hashes The hashes of the removed files.
    ---@return integer hash_count
    function transport.prune( used_before, lifetime, total_size )
        ---@type string[]
        local hashes = {}
        local hash_count = 0

        -- running total from the most recently used file, everything past the limit goes
        local rows = sqlite_query( string.unindentLines( [[
            SELECT hash FROM (
                SELECT hash, timestamp, SUM( size ) OVER ( ORDER BY timestamp DESC, hash ) AS total_size
                FROM 'dreamwork.storage.transport'
            ) WHERE timestamp < ? AND ((? > 0 AND timestamp < ?) OR (? > 0 AND total_size > ?))
        ]], 12 ), used_before, lifetime, time_now( "ms", false ) - lifetime, total_size, total_size )

        if rows == nil then
            return hashes, 0
        end

        for index = 1, #rows, 1 do
            local hash = raw_tostring( rows[ index ].hash )
            hash_count = hash_count + 1
            hashes[ hash_count ] = hash
        end

        if hash_count ~= 0 then
            sqlite_transaction( function( query )
                for index = 1, hash_count, 1 do
                    query( "DELETE FROM 'dreamwork.storage.transport' WHERE hash=?", hashes[ index ] )
                end
            end )
        end

        return hashes, hash_count
    end

end

do

    --- [SHARED AND MENU]
    ---
    --- The persistent cookies of `http.CookieJar:save`, by the names of the jars.
    ---
    ---@class dreamwork.storage.cookies
    local cookies = {}
    storage.cookies = cookies

    ---@class dreamwork.storage.cookies.Record
    ---@field name string The cookie name.
    ---@field value string The cookie value.
    ---@field domain string The domain of the cookie.
    ---@field path string The path of the cookie.
    ---@field host_only boolean `true` if the cookie is sent only to `domain` itself.
    ---@field secure boolean `true` if the cookie is sent only over HTTPS.
    ---@field http_only boolean `true` if the cookie was set with `HttpOnly`.
    ---@field same_site string | nil The `SameSite` attribute.
    ---@field expires number The expiration time, unix time in seconds.

    ---@type table<string, dreamwork.std.sqlite.ColumnType>
    local record_types = { host_only = "boolean", secure = "boolean", http_only = "boolean", expires = "number" }

    --- [SHARED AND MENU]
    ---
    --- Returns the not expired cookies of the jar, in the order they were written.
    ---
    ---@param jar string The name of the jar.
    ---@return dreamwork.storage.cookies.Record[] records The cookies.
    ---@return integer record_count
    ---@nodiscard
    function cookies.read( jar )
        local rows = sqlite_query( "SELECT name, value, domain, path, host_only, secure, http_only, same_site, expires FROM 'dreamwork.storage.cookies' WHERE jar=? AND expires>? ORDER BY position", jar, time_now() )
        if rows == nil then
            return {}, 0
        end

        local row_count = #rows

        for index = 1, row_count, 1 do
            local row = rows[ index ]
            sqlite_cast( row, record_types )

            -- `NOT NULL` keeps the columns of every row, no `SameSite` is an empty string
            if row.same_site == "" then
                row.same_site = nil
            end
        end

        ---@cast rows dreamwork.storage.cookies.Record[]
        return rows, row_count
    end

    --- [SHARED AND MENU]
    ---
    --- Replaces the cookies of the jar, an empty list removes the jar.
    ---
    --- Expired cookies of every jar are removed on the way.
    ---
    ---@param jar string The name of the jar.
    ---@param records dreamwork.storage.cookies.Record[] The cookies, kept in this order.
    ---@param record_count integer? The number of cookies, `#records` by default.
    function cookies.write( jar, records, record_count )
        if record_count == nil then
            record_count = #records
        end

        sqlite_transaction( function( query )
            query( "DELETE FROM 'dreamwork.storage.cookies' WHERE jar=? OR expires<=?", jar, time_now() )

            for index = 1, record_count, 1 do
                local record = records[ index ]
                query( "INSERT INTO 'dreamwork.storage.cookies' (jar, position, name, value, domain, path, host_only, secure, http_only, same_site, expires) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    jar, index, record.name, record.value, record.domain, record.path, record.host_only, record.secure, record.http_only, record.same_site or "", record.expires
                )
            end
        end )
    end

    --- [SHARED AND MENU]
    ---
    --- Removes the cookies of the jar, does nothing if the jar is not stored.
    ---
    ---@param jar string The name of the jar.
    function cookies.delete( jar )
        sqlite_query( "DELETE FROM 'dreamwork.storage.cookies' WHERE jar=?", jar )
    end

end

if LUA_MENU then

    --- [MENU]
    ---
    --- The saved values of the archived Lua-created console variables, the engine does not save them in the menu.
    ---
    --- Read and written by `console.Variable`.
    ---
    ---@class dreamwork.storage.variables
    local variables = {}
    storage.variables = variables

    --- The stored values, loaded once by `storage.init`.
    ---@type table<string, string>
    local cache = {}

    --- [MENU]
    ---
    --- Returns the saved value of the console variable.
    ---
    ---@param name string The name of the console variable.
    ---@return string | nil value The saved value, or `nil` if the variable has no saved value.
    ---@nodiscard
    function variables.read( name )
        return cache[ name ]
    end

    --- [MENU]
    ---
    --- Saves the value of the console variable, replacing the previous one.
    ---
    ---@param name string The name of the console variable.
    ---@param value string The value to save.
    function variables.write( name, value )
        if cache[ name ] == value then return end
        sqlite_query( "INSERT INTO 'dreamwork.storage.variables' (name, value) VALUES (?, ?) ON CONFLICT( name ) DO UPDATE SET value = excluded.value", name, value )
        cache[ name ] = value
    end

    --- [MENU]
    ---
    --- Removes the saved value of the console variable, does nothing if the variable has no saved value.
    ---
    ---@param name string The name of the console variable.
    function variables.delete( name )
        if cache[ name ] == nil then return end
        sqlite_query( "DELETE FROM 'dreamwork.storage.variables' WHERE name=?", name )
        cache[ name ] = nil
    end

    --- [MENU]
    ---
    --- Loads the saved values, called by `storage.init` after the migrations.
    ---
    function variables.init()
        local rows = sqlite_query( "SELECT name, value FROM 'dreamwork.storage.variables'" )
        if rows == nil then return end

        for index = 1, #rows, 1 do
            local row = rows[ index ]
            cache[ raw_tostring( row.name ) ] = raw_tostring( row.value )
        end
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
                -- key-value store
                "CREATE TABLE 'dreamwork.storage' (key TEXT UNIQUE, value BLOB)",

                -- http_cache add primary key
                [[
                    CREATE TABLE 'dreamwork.storage.http' (
                        url TEXT PRIMARY KEY,
                        etag TEXT,
                        timestamp INTEGER,
                        content BLOB
                    )
                ]],

                -- transport data
                [[
                    CREATE TABLE 'dreamwork.storage.transport' (
                        hash TEXT PRIMARY KEY,
                        size INTEGER NOT NULL CHECK(size >= 0),
                        checksum INTEGER NOT NULL,
                        timestamp INTEGER NOT NULL
                    )
                ]],

                -- persistent cookies of `http.CookieJar:save`
                [[
                    CREATE TABLE 'dreamwork.storage.cookies' (
                        jar TEXT NOT NULL,
                        position INTEGER NOT NULL,
                        name TEXT NOT NULL,
                        value TEXT NOT NULL,
                        domain TEXT NOT NULL,
                        path TEXT NOT NULL,
                        host_only INTEGER NOT NULL,
                        secure INTEGER NOT NULL,
                        http_only INTEGER NOT NULL,
                        same_site TEXT NOT NULL,
                        expires REAL NOT NULL,
                        PRIMARY KEY ( jar, name, domain, path )
                    )
                ]]
            }
        }
    }

    -- console variables saved by `storage.variables`, the engine does not save them in the menu
    if LUA_MENU then
        migrations[ #migrations + 1 ] = {
            name = "0.1.0-menu",
            queries = {
                "CREATE TABLE 'dreamwork.storage.variables' (name TEXT PRIMARY KEY, value TEXT NOT NULL)"
            }
        }
    end

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
--- The HTTP cache is pruned by `http.client`, with its console variable limits.
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
    engine_hook.catch( "ShutDown", "modules.sqlite.wal.truncate", function()
        local success, error_message = pcall( sqlite_rawQuery, "pragma wal_checkpoint(TRUNCATE)" )
        if not success then
            dreamwork_Logger:error( "Failed to truncate the SQLite WAL journal on shutdown: %s", error_message )
        end
    end, -1000 )

    sqlite_rawQuery( "CREATE TABLE IF NOT EXISTS 'dreamwork.storage.migrations' (name TEXT, timestamp INTEGER)" )

    storage.migrate()

    if LUA_MENU then
        storage.variables.init()
    end

    dreamwork_Logger:info( "Database initialized in %.2f ms.", time_tick( "ms" ) )
end
