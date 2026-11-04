---@meta _

--- [SHARED AND MENU]
---
--- The local SQLite library wrapper.
---
---@class sqlite
sqlite = {}

--- [SHARED AND MENU]
---
--- Returns the last error message from the last query.
---
---@return string | nil err_msg The last error message.
---@nodiscard
function sqlite.getLastError() end

--- [SHARED AND MENU]
---
--- Converts a string to a safe string for use in an SQL query.
---
---@param str string | null | nil The string to convert.
---@return string str The safe string.
---@nodiscard
function sqlite.escape(str, no_quotes) end

--- [SHARED AND MENU]
---
--- Executes a raw SQL query.
---
---@param str sqlite.Query The SQL query to execute.
---@return sqlite.QueryRow[] | nil result The result of the query.
function sqlite.rawQuery(str) end

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
---@param kind_type? sqlite.ObjectType The type of the schema object, any type if `nil`.
---@return boolean is_exists `true` if a schema object with the given name ( and type ) exists, `false` otherwise.
---@nodiscard
function sqlite.isExists(kind_name, kind_type) end

--- [SHARED AND MENU]
---
--- A blob query parameter.
---
--- Blobs are written as hex literals, so they may contain any bytes, including null bytes.
---
--- `sql.Query` cuts blob results at the first null byte,
--- so read them back as `hex( column )` and decode with `sqlite.cast` using the `"blob"` type.
---
---@class sqlite.Blob : Object
---@field __class sqlite.BlobClass
---@field data string The raw bytes of the blob.
local Blob = {}

---@param data string
---@protected
function Blob:__init(data) end

--- [SHARED AND MENU]
---
--- The class used to create new `Blob` instances.
---
---@class sqlite.BlobClass : sqlite.Blob, Class
---@field __base sqlite.Blob
---@overload fun( data: string ) : sqlite.Blob
sqlite.Blob = {}

--- [SHARED AND MENU]
---
--- Executes a SQL query with parameters.
---
--- `NULL` values in the result are replaced with `null`.
---
--- `sql.Query` returns SQL `NULL` as the string `"NULL"`, so a text value that is exactly `"NULL"` is read as `null` too, store such data as a blob.
---
---@param str sqlite.Query The SQL query to execute.
---@param ... sqlite.QueryValue The parameters to use in the query.
---@return sqlite.QueryRow[] | nil result The result of the query.
function sqlite.query(str, ...) end

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns a specific row.
---
---@param str sqlite.Query The SQL query to execute.
---@param row integer? The row to return.
---@param ... sqlite.QueryValue The parameters to use in the query.
---@return sqlite.QueryRow | nil result The selected row of the result.
---@nodiscard
function sqlite.queryRow(str, row, ...) end

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first row.
---
---@param str sqlite.Query The SQL query to execute.
---@param ... sqlite.QueryValue The parameters to use in the query.
---@return sqlite.QueryRow | nil result The first row of the result.
---@nodiscard
function sqlite.queryFirst(str, ...) end

--- [SHARED AND MENU]
---
--- Executes a SQL query and returns the first value of the first row.
---
---@param str sqlite.Query The SQL query to execute.
---@param ... sqlite.QueryValue The parameters to use in the query.
---@return sqlite.QueryValue | nil value The first value of the first row of the result.
---@nodiscard
function sqlite.queryValue(str, ...) end

--- [SHARED AND MENU]
---
--- Converts the string values of a result row to the specified types, in-place.
---
--- `null` values are kept as is, except for `"blob"` columns, since `hex( NULL )` is an empty string.
---
---@param row sqlite.QueryRow | nil The row to convert.
---@param column_types table<string, sqlite.ColumnType> The column names mapped to their types.
---@return sqlite.QueryRow | nil row The same row.
function sqlite.cast(row, column_types) end

--- [SHARED AND MENU]
---
--- Executes a transaction of SQL queries in one block.
---
---@generic V: any | nil
---@param fn fun( query_fn: ( fun( str: sqlite.Query, ...: sqlite.QueryValue ): ( sqlite.QueryRow[] | nil ) ) ): ( V | nil ) The function to execute all SQL queries in one transaction.
---@return V value The result of function execution.
function sqlite.transaction(fn) end
