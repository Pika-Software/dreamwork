local dreamwork_engine = dreamwork.engine

---@type garrysmod.sql
local sql = dreamwork_engine.requireLibrary( "sql" )
local sql_Query = sql.Query

local dreamwork_Logger = dreamwork.Logger

---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_select = raw.select

local string = std.string
local string_sub = string.sub
local string_gsub = string.gsub
local string_trim = string.trim
local string_match = string.match
local string_format = string.format
local string_replace = string.replace
local string_interpolateByte = string.interpolateByte

local isBoolean = std.isBoolean
local isNumber = std.isNumber
local isString = std.isString

local class = std.class
local class_isInherited = class.isInherited

local base16 = std.base16
local base16_encode = base16.encode
local base16_decode = base16.decode

local try = std.try
local type = std.type
local error = std.error
local tonumber = std.tonumber
local tostring = std.tostring

local null = std.null


--- [SHARED AND MENU]
---
--- The local SQLite library wrapper.
---
---@class dreamwork.std.sqlite
local sqlite = {}
std.sqlite = sqlite

--- [SHARED AND MENU]
---
--- Returns the last error message from the last query.
---
---@return string | nil err_msg The last error message.
---@nodiscard
function sqlite.getLastError()
    return sql.m_strError
end

--- [SHARED AND MENU]
---
--- Converts a string to a safe string for use in an SQL query.
---
---@param str string | dreamwork.std.null | nil The string to convert.
---@return string str The safe string.
---@nodiscard
local function escape( str, no_quotes )
    if str == nil or str == null then
        return "null"
    end

    ---@cast str string

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
---@param query_str dreamwork.std.sqlite.Query The SQL query to execute.
---@return dreamwork.std.sqlite.QueryRow[] | nil result The result of the query.
local function query_raw( query_str )
    -- blob literals can make queries megabytes long
    local str_length = #query_str
    if str_length > 64 then
        dreamwork_Logger:debug( "Executing SQL query: " .. string_sub( query_str, 1, 64 ) .. "... (+" .. (str_length - 64) .. " bytes)" )
    else
        dreamwork_Logger:debug( "Executing SQL query: " .. query_str )
    end

    ---@type dreamwork.std.sqlite.QueryRow[] | false | nil
    local result = sql_Query( query_str )
    if result == false then
        error( sql.m_strError, 2 )
    end

    return result
end

sqlite.rawQuery = query_raw

--- [SHARED AND MENU]
---
--- Checks if a schema object ( table, index, view or trigger ) exists in the database.
---
--- Names are compared case-insensitively, like SQLite identifiers.
---
--- Only the main database is checked, objects created with `CREATE TEMP` are not found.
---
--- Indexes that SQLite creates implicitly for `UNIQUE` / `PRIMARY KEY` constraints are named `sqlite_autoindex_<table>_<n>` and count as indexes.
---
--- Both arguments are escaped, so any string is safe to pass. A `nil` or empty `kind_name` never matches, and an unknown `kind_type` simply returns `false`.
---
--- ```lua
--- sqlite.isExists( "dreamwork.storage" )           -- any type
--- sqlite.isExists( "dreamwork.storage", "table" )  -- tables only
--- sqlite.isExists( "my_index", "index" )           -- indexes only
--- ```
---
---@param kind_name string The name of the schema object.
---@param kind_type dreamwork.std.sqlite.ObjectType? The type of the schema object, any type if `nil`.
---@return boolean is_exists `true` if a schema object with the given name ( and type ) exists, `false` otherwise.
---@nodiscard
function sqlite.isExists( kind_name, kind_type )
    if kind_type == nil then
        return query_raw( string_format( "select 1 from sqlite_master where name=%s collate nocase limit 1", escape( kind_name ) ) ) ~= nil
    end

    return query_raw( string_format( "select 1 from sqlite_master where name=%s collate nocase and type=%s limit 1", escape( kind_name ), escape( kind_type ) ) ) ~= nil
end

--- [SHARED AND MENU]
---
--- A blob query parameter.
---
--- Blobs are written as hex literals, so they may contain any bytes, including null bytes.
---
--- `sql.Query` cuts blob results at the first null byte,
--- so read them back as `hex( column )` and decode with `sqlite.cast` using the `"blob"` type.
---
---@class dreamwork.std.sqlite.Blob : dreamwork.std.Object
---@field __class dreamwork.std.sqlite.BlobClass
---@field data string The raw bytes of the blob.
local Blob = class.base( "Blob", false, nil )

---@param data string
---@protected
function Blob:__init( data )
    self.data = data
end

--- [SHARED AND MENU]
---
--- The class used to create new `Blob` instances.
---
---@class dreamwork.std.sqlite.BlobClass : dreamwork.std.sqlite.Blob, dreamwork.std.Class
---@field __base dreamwork.std.sqlite.Blob
---@overload fun( data: string ) : dreamwork.std.sqlite.Blob
sqlite.Blob = class.create( Blob )

--- [SHARED AND MENU]
---
--- Executes a SQL query with parameters.
---
--- `NULL` values in the result are replaced with `std.null`.
---
--- `sql.Query` returns SQL `NULL` as the string `"NULL"`, so a text value that is exactly `"NULL"` is read as `std.null` too, store such data as a blob.
---
---@param query_str dreamwork.std.sqlite.Query The SQL query to execute.
---@param ... dreamwork.std.sqlite.QueryValue The parameters to use in the query.
---@return dreamwork.std.sqlite.QueryRow[] | nil result The result of the query.
local function query( query_str, ... )
    ---@type string[]
    local variables = {}

    for index = 1, raw_select( "#", ... ), 1 do
        local value = raw_select( index, ... )
        if value == nil or value == null then
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
        elseif class_isInherited( value, Blob ) then
            ---@cast value dreamwork.std.sqlite.Blob
            variables[ index ] = "X'" .. base16_encode( value.data ) .. "'"
        else
            std.errorf( "bad argument #%s to \'%s\' ('%s' expected, got '%s')", index, "sqlite.query", "boolean | integer | number | string | dreamwork.std.sqlite.Blob | nil", type( value ) )
        end
    end

    local result = query_raw( string_interpolateByte( string_trim( (string_gsub( query_str, "[%s\n]+", " " )) ), 0x3F --[[ ? ]], variables ) )
    if result == nil then
        return nil
    end

    for j = 1, #result, 1 do
        local row = result[ j ]
        for key, value in raw_pairs( row ) do
            if value == "NULL" then
                row[ key ] = null
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
---@param str dreamwork.std.sqlite.Query The SQL query to execute.
---@param row integer? The row to return.
---@param ... dreamwork.std.sqlite.QueryValue The parameters to use in the query.
---@return dreamwork.std.sqlite.QueryRow | nil result The selected row of the result.
---@nodiscard
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
---@param str dreamwork.std.sqlite.Query The SQL query to execute.
---@param ... dreamwork.std.sqlite.QueryValue The parameters to use in the query.
---@return dreamwork.std.sqlite.QueryRow | nil result The first row of the result.
---@nodiscard
local function query_first( str, ... )
    return query_row( str, 1, ... )
end

sqlite.queryFirst = query_first

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first value of the first row.
---
---@param str dreamwork.std.sqlite.Query The SQL query to execute.
---@param ... dreamwork.std.sqlite.QueryValue The parameters to use in the query.
---@return dreamwork.std.sqlite.QueryValue | nil value The first value of the first row of the result.
---@nodiscard
function sqlite.queryValue( str, ... )
    local result = query_first( str, ... )
    if result ~= nil then
        local _, value = raw_next( result )
        return value
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Converts the string values of a result row to the specified types, in-place.
---
--- `std.null` values are kept as is, except for `"blob"` columns, since `hex( NULL )` is an empty string.
---
---@param row dreamwork.std.sqlite.QueryRow | nil The row to convert.
---@param column_types table<string, dreamwork.std.sqlite.ColumnType> The column names mapped to their types.
---@return dreamwork.std.sqlite.QueryRow | nil row The same row.
function sqlite.cast( row, column_types )
    if row == nil then
        return nil
    end

    for column_name, column_type in raw_pairs( column_types ) do
        local value = row[ column_name ]
        if isString( value ) then
            ---@cast value string
            if column_type == "number" then
                row[ column_name ] = tonumber( value, 10 )
            elseif column_type == "boolean" then
                row[ column_name ] = value ~= "0"
            elseif column_type == "blob" then
                row[ column_name ] = base16_decode( value )
            elseif column_type ~= "string" then
                std.errorf( "unknown column type '%s' for column '%s'", column_type, column_name )
            end
        end
    end

    return row
end

--- [SHARED AND MENU]
---
--- Executes a transaction of SQL queries in one block.
---
---@generic V: any | nil
---@param fn fun( query_fn: ( fun( str: dreamwork.std.sqlite.Query, ...: dreamwork.std.sqlite.QueryValue ): ( dreamwork.std.sqlite.QueryRow[] | nil ) ) ): ( V | nil ) The function to execute all SQL queries in one transaction.
---@return V value The result of function execution.
function sqlite.transaction( fn )
    query_raw( "begin" )

    local ok, result = try( fn, query )
    if ok then
        query_raw( "commit" )
        return result
    end

    query_raw( "rollback" )
    return error( result, 2 )
end
