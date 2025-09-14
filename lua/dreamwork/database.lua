local _G = _G

---@class dreamwork
local dreamwork = _G.dreamwork
local std = dreamwork.std

local sqlite = std.sqlite
local sqlite_transaction = sqlite.transaction
local sqlite_query, sqlite_rawQuery = sqlite.query, sqlite.rawQuery
local sqlite_queryOne, sqlite_queryValue = sqlite.queryOne, sqlite.queryValue

local time_now = std.time.now

-- http_cache table, used for etag caching in http library
do

    local string_len, string_find
    do
        local string = std.string
        string_len, string_find = string.len, string.find
    end

    --- [SHARED AND MENU]
    ---
    --- A cache for http requests.
    ---
    ---@class dreamwork.http_cache
    ---@field MAX_SIZE number The maximum size of cached content.
    local http_cache = {}

    --- [SHARED AND MENU]
    ---
    --- Gets the cached content for the specified URL.
    ---
    ---@param url string
    ---@return table?
    function http_cache.get( url )
        return sqlite_queryOne( "select etag, content from 'dreamwork.http_cache' where url=? limit 1", url )
    end

    local MAX_SIZE = 50 * 1024
    http_cache.MAX_SIZE = MAX_SIZE

    --- [SHARED AND MENU]
    ---
    --- Sets the cached content for the specified URL.
    ---
    ---@param url string The URL to cache.
    ---@param etag string The ETag for the cached content.
    ---@param content string The cached content.
    function http_cache.set( url, etag, content )
        -- do not cache content that are larger than MAX_SIZE
        if string_len( content ) > MAX_SIZE then
            return
        end

        -- we are unable to store null bytes in sqlite
        if string_find( content, "\x00", 1, true ) then
            return
        end

        sqlite_query( "insert or replace into 'dreamwork.http_cache' (url, etag, timestamp, content) values (?, ?, ?, ?)", url, etag, time_now(), content )
    end

    dreamwork.http_cache = http_cache

end

-- key-value store for dreamwork
do

    --- [SHARED AND MENU]
    ---
    --- A key-value store for dreamwork.
    ---
    ---@class dreamwork.store
    local store = {}

    --- [SHARED AND MENU]
    ---
    --- Returns the value for the specified key.
    ---
    ---@param key string
    ---@return string
    function store.get( key )
        return sqlite_queryValue( "select value from 'dreamwork.store' where key=?", key )
    end

    --- [SHARED AND MENU]
    ---
    --- Sets the value for the specified key.
    ---
    ---@param key string
    ---@param value string
    function store.set( key, value )
        sqlite_query( "insert or replace into 'dreamwork.store' values (?, ?)", key, value )
    end

    dreamwork.store = store

end

--- repositories
if std.SERVER then

    ---@class dreamwork.repositories
    local repositories = {}

    --- [SERVER]
    ---
    --- Returns a list of all repositories
    ---
    ---@return table lst The list of repositories.
    function repositories.getRepositories()
        return sqlite_query( "select * from 'dreamwork.repositories'" ) or {}
    end

    --- [SERVER]
    ---
    --- Adds a new repository to the database.
    ---
    ---@param url string
    function repositories.addRepository( url )
        -- sadly gmod's sqlite does not support returning clause :(
        return sqlite_queryOne( "insert or ignore into 'dreamwork.repositories' (url) values (?); select * from 'dreamwork.repositories' where url=?", url, url )
    end

    local isstring, isnumber, istable = std.isstring, std.isnumber, std.istable

    --- [SERVER]
    ---
    --- Returns the repository ID for the specified repository.
    ---@param value table | number | string The repository to get the ID for.
    ---@return number? id The repository ID, or `nil` if the repository does not exist.
    local function getRepositoryID( value )
        if istable( value ) then
            ---@cast value table
            return value.id or getRepositoryID( value.url )
        elseif isnumber( value ) then
            ---@cast value number
            return value
        elseif isstring( value ) then
            ---@cast value string
            return sqlite_queryValue( "select id from 'dreamwork.repositories' where url=?", value )
        end
    end

    --- [SERVER]
    ---
    --- Removes the specified repository from the database.
    ---
    ---@param repository table | number | string The repository to remove.
    function repositories.removeRepository( repository )
        local repository_id = getRepositoryID( repository )
        if repository_id == nil then
            error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
        end

        local repositoryIDStr = tostring( repository_id )

        sqlite_transaction( function()
            -- delete all versions, packages and repository
            local packages = sqlite_query( "select id from 'dreamwork.packages' where repositoryID=?", repositoryIDStr )
            if packages == nil then return end

            for i = 1, #packages do
                local packageID = packages[ i ].id
                sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?; delete from 'dreamwork.packages' where id=?", packageID, packageID )
            end

            sqlite_query( "delete from 'dreamwork.repositories' where id=?", repositoryIDStr )
        end )
    end

    --- [SERVER]
    ---
    --- Returns the package for the specified repository and name.
    ---
    ---@param repository table | number | string The repository to get the package from.
    ---@param name string The name of the package to get.
    ---@return table? pkg The package, or `nil` if the package does not exist.
    function repositories.getPackage( repository, name )
        local repository_id = getRepositoryID( repository )
        if repository_id == nil then
            error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
        end

        local pkg = sqlite_queryOne( "select * from 'dreamwork.packages' where name=? and repositoryID=?", name, tostring( repository_id ) )
        if pkg == nil then return end

        pkg.versions = sqlite_query( "select version, metadata from 'dreamwork.package_versions' where packageID=?", pkg.id )
        return pkg
    end

    --- [SERVER]
    ---
    --- Returns a list of packages for the specified repository.
    ---
    ---@param repository table | number | string The repository to get the packages from.
    ---@return table lst The list of packages.
    function repositories.getPackages( repository )
        local repository_id = getRepositoryID( repository )
        if repository_id == nil then
            error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
        end

        local packages = sqlite_query( "select * from 'dreamwork.packages' where repositoryID=?", tostring( repository_id ) )

        if packages == nil then
            return {}
        end

        -- fetch versions for each package
        for i = 1, #packages do
            local pkg = packages[ i ]
            pkg.versions = sqlite_query( "select version, metadata from 'dreamwork.package_versions' where packageID=?", pkg.id )
        end

        return packages
    end

    --- [SERVER]
    ---
    --- Updates the packages for the specified repository.
    ---
    ---@param repository table | number | string The repository to update.
    ---@param packages table The packages to update.
    function repositories.updateRepository( repository, packages )
        local repository_id = getRepositoryID( repository )
        if repository_id == nil then
            error( "Invalid repository '" .. tostring( repository ) .. "' was given as #1 argument.", 2 )
        end

        local repositoryIDStr = tostring( repository_id )

        local oldPackages = sqlite_query( "select id, name from 'dreamwork.packages' where repositoryID=?", repositoryIDStr ) or {}
        for i = 1, #oldPackages do
            local package = oldPackages[ i ]
            oldPackages[ package.name ] = package.id
        end

        return sqlite_transaction( function()
            for name, pkg in pairs( packages ) do
                sqlite_query( "insert or replace into 'dreamwork.packages' (name, url, type, repositoryID) values (?, ?, ?, ?)", pkg.name, pkg.url, pkg.type, repositoryIDStr )

                local packageID = sqlite_queryValue( "select id from 'dreamwork.packages' where name=? and repositoryID=?", pkg.name, repositoryIDStr )
                sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?", packageID )

                local versions = pkg.versions
                for i = 1, #versions do
                    local package = versions[ i ]
                    sqlite_query( "insert into 'dreamwork.package_versions' (version, metadata, packageID) values (?, ?, ?)", package.version, package.metadata, packageID )
                end

                oldPackages[ name ] = nil
            end

            -- remove old packages
            for _, id in pairs( oldPackages ) do
                sqlite_query( "delete from 'dreamwork.package_versions' where packageID=?; delete from 'dreamwork.packages' where id=?", id, id )
            end
        end )
    end

    dreamwork.repositories = repositories

end

-- files
do

    local tonumber = std.tonumber

    --- [SHARED AND MENU]
    ---
    --- The files hash database.
    ---
    ---@class dreamwork.files
    local files = {}

    --- [SHARED AND MENU]
    ---
    --- Saves a file to the database.
    ---
    ---@param path string The path of the file.
    ---@param size number The size of the file.
    ---@param seconds number The last modified time of the file.
    ---@param hash string The hash of the file.
    function files.save( path, size, seconds, hash )
        sqlite_query( "insert or replace into 'dreamwork.files' (path, size, os_time, hash) values (?, ?, ?, ?)", path, size, seconds, hash )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns a file from the database.
    ---
    ---@param path string The path of the file.
    ---@return table? data The file data.
    function files.get( path )
        local result = sqlite_queryOne( "select * from 'dreamwork.files' where path=?", path )
        if result == nil then return end

        result.size = tonumber( result.size, 10 ) or -1
        result.os_time = tonumber( result.os_time, 10 )
        return result
    end

    dreamwork.files = files

end

do

    --- [SHARED AND MENU]
    ---
    --- Database module.
    ---@class dreamwork.db
    local db = dreamwork.db or {}
    dreamwork.db = db

    --- [SHARED AND MENU]
    ---
    --- Improves the performance of sqlite databases.
    ---
    function db.optimize()
        if db.__optimized ~= nil then return end

        ---@private
        db.__optimized = true

        local pragma_values = sqlite_rawQuery( "pragma foreign_keys; pragma journal_mode; pragma synchronous; pragma wal_autocheckpoint" )
        if pragma_values ~= nil then
            if pragma_values[ 1 ]["foreign_keys"] == "0" then
                sqlite_rawQuery( "pragma foreign_keys = 1" )
            end

            if pragma_values[ 2 ]["journal_mode"] == "delete" then
                sqlite_rawQuery( "pragma journal_mode = wal" )
            end

            if pragma_values[ 3 ]["synchronous"] == "0" then
                sqlite_rawQuery( "pragma synchronous = normal" )
            end

            if pragma_values[ 4 ]["wal_autocheckpoint"] == "1000" then
                sqlite_rawQuery( "pragma wal_autocheckpoint = 100" )
            end
        end

        -- truncate WAL journal on shutdown
        dreamwork.engine.hookCatch( "ShutDown", function()
            if sqlite.query( "pragma wal_checkpoint(TRUNCATE)" ) == false then
                dreamwork.Logger:error( "Failed to truncate WAL journal: %s", sqlite.getLastError() )
            end
        end, 1 )
    end

    local migrations = {
        {
            name = "initial",
            execute = function() end
        },
        {
            name = "http_cache add primary key",
            execute = function()
                sqlite_rawQuery("drop table if exists 'dreamwork.http_cache'")
                sqlite_rawQuery([[create table 'dreamwork.http_cache' (
                    url text primary key,
                    etag text,
                    timestamp int,
                    content blob
                )]])
                return nil
            end
        },
        {
            name = "added key-value store",
            execute = function()
                sqlite_rawQuery("create table 'dreamwork.store' ( key text unique, value text )")
                return nil
            end
        },
        {
            name = "initial repositories and packages",
            execute = function()
                sqlite_rawQuery( "drop table if exists 'dreamwork.table_version'" )
                sqlite_rawQuery( "drop table if exists 'dreamwork.repository'" )
                sqlite_rawQuery( "drop table if exists 'dreamwork.packages'" )

                if std.SERVER then
                    sqlite_rawQuery( "create table 'dreamwork.repositories' ( id integer primary key autoincrement, url text unique not null )" )
                    sqlite_rawQuery( [[
                        create table 'dreamwork.packages' (
                            id integer primary key autoincrement,
                            name text not null,
                            url text not null,
                            type int not null,
                            repositoryID integer,

                            foreign key(repositoryID) references 'dreamwork.repositories' (id)
                            unique(name, repositoryID) on conflict replace
                        )
                    ]] )

                    sqlite_rawQuery( [[
                        create table 'dreamwork.package_versions' (
                            version text not null,
                            metadata text,
                            packageID integer not null,

                            foreign key(packageID) references 'dreamwork.packages' (id)
                            unique(version, packageID) on conflict replace
                        )
                    ]] )
                end
            end
        },
        {
            name = "initial file table",
            execute = function()
                sqlite_rawQuery( [[
                    create table 'dreamwork.files' (
                        id integer primary key autoincrement,
                        path text not null unique,
                        size integer not null,
                        os_time integer,
                        hash text
                    )
                ]] )
            end
        }
    }

    --- [SHARED AND MENU]
    ---
    --- Prepares the database by creating the migration history table.
    ---
    function db.prepare()
        sqlite_rawQuery( "create table if not exists 'dreamwork.migration_history' (name text, timestamp integer)" )
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a migration exists and returns `true` or `false`.
    ---
    ---@param name string The name of the migration.
    ---@return boolean exists `true` if migration exists, `false` otherwise.
    local function migrationExists( name )
        for i = 1, #migrations do
            if migrations[ i ].name == name then
                return true
            end
        end

        return false
    end

    db.migrationExists = migrationExists

    local migrateByTable
    do

        local iscallable = std.iscallable

        local function display_error( msg )
            error( "Database migration failed: " .. msg, -2 )
        end

        --- [SHARED AND MENU]
        ---
        --- Runs a migration by migration table.
        ---
        ---@param migration table The migration to run.
        ---@return boolean success Returns `true` if successful, `false` if failed.
        function migrateByTable( migration )
            if not iscallable( migration.execute ) then
                error( "Database migration failed: '" .. tostring( migration.name ) .. "' does not have an 'execute' function.", 2 )
            end

            dreamwork.Logger:info( "Running migration '" .. tostring( migration.name ) .. "'...")

            if xpcall( sqlite_transaction, display_error, migration.execute ) then
                sqlite_query( "insert into 'dreamwork.migration_history' (name, timestamp) values (?, ?)", migration.name, time_now() )
                return true
            else
                return false
            end
        end

        db.migrateByTable = migrateByTable

    end

    --- [SHARED AND MENU]
    ---
    --- Runs a migration by its name.
    ---
    ---@param name string
    function db.migrate( name )
        local history = sqlite_rawQuery( "select name from 'dreamwork.migration_history'" ) or {}
        for i = 1, #history do
            history[ history[ i ].name ] = true
        end

        -- find if given migration name exists
        if not migrationExists( name ) then
            error( "Database migration failed: '" .. name .. "' does not exist.", 2 )
        end

        -- first execute migrations
        for i = 1, #migrations do
            local migration = migrations[ i ]
            if ( not history[ migration.name ] and migrateByTable( migration ) == false ) or ( migration.name == name ) then
                break
            end
        end
    end

end
