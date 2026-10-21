local sql = sql
local sql_Query = sql.Query

local dreamwork_Logger = dreamwork.Logger

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_select = raw.select

local string = std.string
local string_match = string.match
local string_lower = string.lower
local string_replace = string.replace
local string_interpolateByte = string.interpolateByte

local isBoolean = std.isBoolean
local isNumber = std.isNumber
local isString = std.isString

local tostring = std.tostring
local pcall = std.pcall
local error = std.error
local type = std.type


--- [SHARED AND MENU]
---
--- The local SQLite library wrapper.
---
---@class dreamwork.std.sqlite
local sqlite = std.sqlite or {}
std.sqlite = sqlite

--- [SHARED AND MENU]
---
--- Returns the last error message from the last query.
---
---@return string | nil err_msg The last error message.
function sqlite.getLastError()
    return sql.m_strError
end

--- [SHARED AND MENU]
---
--- Converts a string to a safe string for use in an SQL query.
---
---@param str string? The string to convert.
---@return string str The safe string.
local function escape( str, no_quotes )
    if str == nil then
        return "null"
    end

    str = string_match(
        string_replace( str, "'", "''", false ),
        "^[^%z]+", 1
    ) or str

    if no_quotes then
        return str
    end

    return "'" .. str .. "'"
end

sqlite.escape = escape

--- [SHARED AND MENU]
---
--- Executes a raw SQL query.
---
---@param str garrysmod.sql.Query The SQL query to execute.
---@return garrysmod.sql.QueryRow[] | nil result The result of the query.
local function query_raw( str )
    dreamwork_Logger:debug( "Executing SQL query: " .. str )

    ---@type garrysmod.sql.QueryRow[] | false | nil
    local result = sql_Query( str )
    if result == false then
        error( sql.m_strError, 2 )
    end

    return result
end

sqlite.rawQuery = query_raw

--- [SHARED AND MENU]
---
--- Checks if a table exists in the database.
---
---@param name string The name of the table to check.
---@return boolean exist `true` if the table exists, `false` otherwise.
function sqlite.tableExists( name )
    return query_raw( "select name from sqlite_master where name=" .. escape( name ) .. " and type='table'" ) ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if an index exists in the database.
---
---@param name string The name of the index to check.
---@return boolean exist `true` if the index exists, `false` otherwise.
function sqlite.indexExists( name )
    return query_raw( "select name from sqlite_master where name=" .. escape( name ) .. " and type='index'" ) ~= nil
end

--- [SHARED AND MENU]
---
--- Executes a SQL query with parameters.
---
---@param str garrysmod.sql.Query The SQL query to execute.
---@param ... garrysmod.sql.QueryValue The parameters to use in the query.
---@return garrysmod.sql.QueryRow[] | nil result The result of the query.
local function query( str, ... )
    ---@type string[]
    local variables = {}

    for index = 1, raw_select( "#", ... ), 1 do
        local value = raw_select( index, ... )
        if value == nil then
            variables[ index ] = "NULL"
        elseif isString( value ) then
            ---@cast value string
            variables[ index ] = escape( value )
        elseif isBoolean( value ) then
            ---@cast value boolean
            variables[ index ] = value and "1" or "0"
        elseif isNumber( value ) then
            ---@cast value number
            variables[ index ] = tostring( value )
        else
            std.errorf( 2, false, "bad argument #%s to \'%s\' ('%s' expected, got '%s')", index, "sqlite.query", "boolean | integer | number | string | nil", type( value ) )
        end
    end

    local result = query_raw( string_interpolateByte( str, 0x3F --[[ ? ]], variables ) )
    if result == nil then
        return nil
    end

    for j = 1, #result, 1 do
        local row = result[ j ]
        for key, value in raw_pairs( row ) do
            ---@cast value string
            if isString( value ) and string_lower( value ) == "null" then
                row[ key ] = nil
            end
        end
    end

    return result
end

sqlite.query = query

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns a specific row.
---
---@param str garrysmod.sql.Query The SQL query to execute.
---@param row integer? The row to return.
---@param ... garrysmod.sql.QueryValue The parameters to use in the query.
---@return garrysmod.sql.QueryRow | nil result The selected row of the result.
local function query_row( str, row, ... )
    local result = query( str, ... )
    if result == nil then
        return nil
    else
        return result[ row or 1 ]
    end
end

sqlite.queryRow = query_row

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first row.
---
---@param str garrysmod.sql.Query The SQL query to execute.
---@param ... garrysmod.sql.QueryValue The parameters to use in the query.
---@return garrysmod.sql.QueryRow | nil result The first row of the result.
local function query_first( str, ... )
    return query_row( str, 1, ... )
end

sqlite.queryFirst = query_first

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first value of the first row.
---
---@param str garrysmod.sql.Query The SQL query to execute.
---@param ... garrysmod.sql.QueryValue The parameters to use in the query.
---@return garrysmod.sql.QueryValue | nil value The first value of the first row of the result.
function sqlite.queryValue( str, ... )
    local result = query_first( str, ... )
    if result ~= nil then
        return raw_next( result )
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Executes a transaction of SQL queries in one block.
---
---@generic V
---@param fn fun( query_fn: ( fun( str: garrysmod.sql.Query, ...: garrysmod.sql.QueryValue ): ( garrysmod.sql.QueryRow[] | nil ) ) ): V The function to execute all SQL queries in one transaction.
---@return V value The result of function execution.
function sqlite.transaction( fn )
    query_raw( "begin" )

    local ok, result = pcall( fn, query )
    if ok then
        query_raw( "commit" )
        return result
    end

    query_raw( "rollback" )
    return error( result, 2 )
end
