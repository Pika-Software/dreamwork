---@class dreamwork.storage
local storage = dreamwork.storage or {}
dreamwork.storage = storage

local std = dreamwork.std

local assert = std.assert
local pcall = std.pcall

local isTable = std.isTable
local isNumber = std.isNumber
local isString = std.isString
local isCallable = std.isCallable

local console = std.console

local string = std.string
local string_len = string.len

local sqlite = std.sqlite
local sqlite_transaction = sqlite.transaction
local sqlite_query, sqlite_rawQuery = sqlite.query, sqlite.rawQuery
local sqlite_queryOne, sqlite_queryValue = sqlite.queryOne, sqlite.queryValue

local time = std.time
local time_now = time.now
local time_tick = time.tick

local raw_tonumber = std.raw.tonumber

--- [SHARED AND MENU]
---
--- Returns the value for the specified key.
---
---@param key string
---@return string
function storage.read( key )
    ---@type string
    return sqlite_queryValue( "SELECT VALUE FROM 'dreamwork.store' WHERE key=?", key )
end

--- [SHARED AND MENU]
---
--- Sets the value for the specified key.
---
---@param key string
---@param value string
function storage.write( key, value )
    sqlite_query( "INSERT OR REPLACE INTO 'dreamwork.store' VALUES (?, ?)", key, value )
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

    --- [SHARED AND MENU]
    ---
    --- A cache storage for http requests.
    ---
    ---@class dreamwork.storage.http
    local http = {}
    storage.http = http

    --- [SHARED AND MENU]
    ---
    --- Gets the cached content for the specified URL.
    ---
    ---@param url string
    ---@return table?
    function http.read( url )
        return sqlite_queryOne( "SELECT etag, content FROM 'dreamwork.storage.http' WHERE url=? LIMIT 1", url )
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

        -- we are unable to store null bytes in sqlite
        if string.hasByte( content, 0x00 ) then
            if ignore_errors then
                return
            end

            error( "null bytes are not allowed", 2 )
        end

        sqlite_query( "INSERT OR REPLACE INTO 'dreamwork.storage.http' (url, etag, timestamp, content) VALUES (?, ?, ?, ?)", url, etag, time_now( "ms", false ), content )
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
    ---@field os_time number

    --- [SHARED AND MENU]
    ---
    --- Returns the file record for the specified path.
    ---
    ---@param file_path string The path to the file.
    ---@return dreamwork.storage.files.Record | nil data The file record, or `nil` if not found.
    function files.read( file_path )
        local result = sqlite_queryOne( "SELECT * FROM 'dreamwork.storage.files' WHERE path=?", file_path )
        if result ~= nil then
            return {
                path = result.path,
                size = raw_tonumber( result.size, 10 ) or -1,
                time = raw_tonumber( result.os_time, 10 ) or 0
            }
        end

        return nil
    end

    --- [SHARED AND MENU]
    ---
    --- Writes the file record for the specified path.
    ---
    ---@param file_path string The path to the file.
    ---@param file_size integer The size of the file in bytes.
    ---@param file_timestamp integer The timestamp of the file.
    ---@param file_hash string The hash of the file (SHA256/MD5).
    function files.write( file_path, file_size, file_timestamp, file_hash )
        sqlite_query( "INSERT OR REPLACE INTO 'dreamwork.storage.files' (path, size, timestamp, hash) VALUES (?, ?, ?, ?)", file_path, file_size, file_timestamp, file_hash )
    end

end

-- --- repositories
-- if std.LUA_SERVER then

--     ---@class dreamwork.repositories
--     local repositories = {}

--     --- [SERVER]
--     ---
--     --- Returns a list of all repositories
--     ---
--     ---@return table lst The list of repositories.
--     function repositories.getRepositories()
--         return sqlite_query( "select * from 'dreamwork.repositories'" ) or {}
--     end

--     --- [SERVER]
--     ---
--     --- Adds a new repository to the database.
--     ---
--     ---@param url string
--     function repositories.addRepository( url )
--         -- sadly gmod's sqlite does not support returning clause :(
--         return sqlite_queryOne( "insert or ignore into 'dreamwork.repositories' (url) values (?); select * from 'dreamwork.repositories' where url=?", url, url )
--     end

--     local getRepositoryID
--     do

--         --- [SERVER]
--         ---
--         --- Returns the repository ID for the specified repository.
--         ---@param value table | number | string The repository to get the ID for.
--         ---@return number? id The repository ID, or `nil` if the repository does not exist.
--         function getRepositoryID( value )
--             if isTable( value ) then
--                 ---@cast value table
--                 return value.id or getRepositoryID( value.url )
--             elseif isNumber( value ) then
--                 ---@cast value number
--                 return value
--             elseif isString( value ) then
--                 ---@cast value string
--                 ---@type number
--                 return sqlite_queryValue( "select id from 'dreamwork.repositories' where url=?", value )
--             end
--         end

--     end

--     --- [SERVER]
--     ---
--     --- Removes the specified repository from the database.
--     ---
--     ---@param repository table | number | string The repository to remove.
--     function repositories.removeRepository( repository )
--         local repository_id = getRepositoryID( repository )
--         if repository_id == nil then
--             error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
--         end

--         local repositoryIDStr = tostring( repository_id )

--         sqlite_transaction( function()
--             -- delete all versions, packages and repository
--             local packages = sqlite_query( "select id from 'dreamwork.packages' where repositoryID=?", repositoryIDStr )
--             if packages == nil then return end

--             for i = 1, #packages do
--                 local packageID = packages[ i ].id
--                 sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?; delete from 'dreamwork.packages' where id=?", packageID, packageID )
--             end

--             sqlite_query( "delete from 'dreamwork.repositories' where id=?", repositoryIDStr )
--         end )
--     end

--     --- [SERVER]
--     ---
--     --- Returns the package for the specified repository and name.
--     ---
--     ---@param repository table | number | string The repository to get the package from.
--     ---@param name string The name of the package to get.
--     ---@return table? pkg The package, or `nil` if the package does not exist.
--     function repositories.getPackage( repository, name )
--         local repository_id = getRepositoryID( repository )
--         if repository_id == nil then
--             error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
--         end

--         local pkg = sqlite_queryOne( "select * from 'dreamwork.packages' where name=? and repositoryID=?", name, tostring( repository_id ) )
--         if pkg == nil then return end

--         pkg.versions = sqlite_query( "select version, metadata from 'dreamwork.package_versions' where packageID=?", pkg.id )
--         return pkg
--     end

--     --- [SERVER]
--     ---
--     --- Returns a list of packages for the specified repository.
--     ---
--     ---@param repository table | number | string The repository to get the packages from.
--     ---@return table lst The list of packages.
--     function repositories.getPackages( repository )
--         local repository_id = getRepositoryID( repository )
--         if repository_id == nil then
--             error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
--         end

--         local packages = sqlite_query( "select * from 'dreamwork.packages' where repositoryID=?", tostring( repository_id ) )

--         if packages == nil then
--             return {}
--         end

--         -- fetch versions for each package
--         for i = 1, #packages do
--             local pkg = packages[ i ]
--             pkg.versions = sqlite_query( "select version, metadata from 'dreamwork.package_versions' where packageID=?", pkg.id )
--         end

--         return packages
--     end

--     --- [SERVER]
--     ---
--     --- Updates the packages for the specified repository.
--     ---
--     ---@param repository table | number | string The repository to update.
--     ---@param packages table The packages to update.
--     function repositories.updateRepository( repository, packages )
--         local repository_id = getRepositoryID( repository )
--         if repository_id == nil then
--             error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
--         end

--         local repositoryIDStr = tostring( repository_id )

--         local oldPackages = sqlite_query( "select id, name from 'dreamwork.packages' where repositoryID=?", repositoryIDStr ) or {}
--         for i = 1, #oldPackages do
--             local package = oldPackages[ i ]
--             oldPackages[ package.name ] = package.id
--         end

--         return sqlite_transaction( function()
--             for name, pkg in pairs( packages ) do
--                 sqlite_query( "insert or replace into 'dreamwork.packages' (name, url, type, repositoryID) values (?, ?, ?, ?)", pkg.name, pkg.url, pkg.type, repositoryIDStr )

--                 local packageID = sqlite_queryValue( "select id from 'dreamwork.packages' where name=? and repositoryID=?", pkg.name, repositoryIDStr )
--                 sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?", packageID )

--                 local versions = pkg.versions
--                 for i = 1, #versions do
--                     local package = versions[ i ]
--                     sqlite_query( "insert into 'dreamwork.package_versions' (version, metadata, packageID) values (?, ?, ?)", package.version, package.metadata, packageID )
--                 end

--                 oldPackages[ name ] = nil
--             end

--             -- remove old packages
--             for _, id in pairs( oldPackages ) do
--                 sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?; delete from 'dreamwork.packages' where id=?", id, id )
--             end
--         end )
--     end

--     dreamwork.repositories = repositories

-- end

do

    ---@class dreamwork.storage.Migration
    ---@field name string
    ---@field execute fun( self: dreamwork.storage.Migration )

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

                --- initial repositories and packages
                -- if std.LUA_SERVER then
                --     sqlite_rawQuery( "CREATE TABLE 'dreamwork.repositories' (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT UNIQUE NOT NULL)" )
                --     sqlite_rawQuery( [[
                --         CREATE TABLE 'dreamwork.packages' (
                --             id INTEGER PRIMARY KEY AUTOINCREMENT,
                --             name TEXT NOT NULL,
                --             url TEXT NOT NULL,
                --             type INT NOT NULL,
                --             repositoryID INTEGER,

                --             FOREIGN KEY(repositoryID) REFERENCES 'dreamwork.repositories' (id)
                --             UNIQUE(name, repositoryID) ON CONFLICT REPLACE
                --         )
                --     ]] )

                --     sqlite_rawQuery( [[
                --         CREATE TABLE 'dreamwork.package_versions' (
                --             version TEXT NOT NULL,
                --             metadata TEXT,
                --             packageID INTEGER NOT NULL,

                --             FOREIGN KEY(packageID) REFERENCES 'dreamwork.packages' (id)
                --             UNIQUE(version, packageID) ON CONFLICT REPLACE
                --         )
                --     ]] )
                -- end

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
        }
    }

    --- [SHARED AND MENU]
    ---
    --- Checks if a migration exists and returns `true` or `false`.
    ---
    ---@param name string The name/version of the migration.
    ---@return boolean is_exists `true` if migration exists, `false` otherwise.
    local function is_migration_exists( name )
        for i = 1, #migrations, 1 do
            if migrations[ i ].name == name then
                return true
            end
        end

        return false
    end

    storage.isMigrationExists = is_migration_exists

    --- [SHARED AND MENU]
    ---
    --- Runs a migration using specified migration table.
    ---
    ---@param migration dreamwork.storage.Migration The migration to run.
    ---@return boolean is_success `true` if successful, `false` if failed.
    local function migrate_by_table( migration )
        assert( isCallable( migration.execute ), "Database migration failed: '%s' does not have an 'execute' function.", migration.name )
        dreamwork.Logger:info( "Running migration '" .. tostring( migration.name ) .. "'..." )

        local success, err_msg = pcall( sqlite_transaction, migration.execute, migration )
        if success then
            sqlite_query( "insert into 'dreamwork.storage.migrations' (name, timestamp) values (?, ?)", migration.name, time_now() )
        else
            std.errorf( 2, false, "Database migration failed: %s", err_msg )
        end

        return success
    end

    storage.migrateByTable = migrate_by_table

    --- [SHARED AND MENU]
    ---
    --- Runs a migration by its name.
    ---
    ---@param name string
    function storage.migrateByName( name )
        ---@type table<string, boolean>
        local finished_migrations = {}

        ---@type dreamwork.storage.Migration[] | nil
        ---@diagnostic disable-next-line: assign-type-mismatch
        local history = sqlite_rawQuery( "select name from 'dreamwork.storage.migrations'" )
        if history ~= nil then
            for i = 1, #history, 1 do
                ---@type string
                ---@diagnostic disable-next-line: assign-type-mismatch
                local history_name = history[ i ].name
                if isString( history_name ) then
                    finished_migrations[ history_name ] = true
                end
            end
        end

        -- find if given migration name exists
        if not is_migration_exists( name ) then
            error( "Database migration failed: '" .. name .. "' does not exist.", 2 )
        end

        -- first execute migrations
        for i = 1, #migrations, 1 do
            local migration = migrations[ i ]
            local migration_name = migration.name

            if not (finished_migrations[ migration_name ] or migrate_by_table( migration )) or migration_name == name then
                break
            end
        end
    end

end

--- [SHARED AND MENU]
---
--- Initializes the database.
---
function storage.init()
    dreamwork.Logger:info( "Preparing the database to begin migration..." )
    time_tick()

    local pragma_values = sqlite_rawQuery( "pragma foreign_keys; pragma journal_mode; pragma synchronous; pragma wal_autocheckpoint" )

    if pragma_values ~= nil then
        if pragma_values[ 1 ][ "foreign_keys" ] == "0" then
            sqlite_rawQuery( "pragma foreign_keys = 1" )
        end

        if pragma_values[ 2 ][ "journal_mode" ] == "delete" then
            sqlite_rawQuery( "pragma journal_mode = wal" )
        end

        if pragma_values[ 3 ][ "synchronous" ] == "0" then
            sqlite_rawQuery( "pragma synchronous = normal" )
        end

        if pragma_values[ 4 ][ "wal_autocheckpoint" ] == "1000" then
            sqlite_rawQuery( "pragma wal_autocheckpoint = 100" )
        end
    end

    -- truncate WAL journal on shutdown
    dreamwork.engine.hookCatch( "ShutDown", function()
        if sqlite.query( "pragma wal_checkpoint(TRUNCATE)" ) == false then
            dreamwork.Logger:error( "Failed to truncate WAL journal: %s", sqlite.getLastError() )
        end
    end, 1 )

    sqlite_rawQuery( "CREATE TABLE IF NOT EXISTS 'dreamwork.storage.migrations' (name TEXT, timestamp INTEGER)" )

    storage.migrateByName( dreamwork.Version )

    dreamwork.Logger:info( "Migration completed, time spent: %.2f ms.", time_tick() )
end
