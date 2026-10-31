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
--- Checks if a table exists in the database.
---
---@param name string The name of the table to check.
---@return boolean exist `true` if the table exists, `false` otherwise.
---@nodiscard
function sqlite.tableExists(name) end

--- [SHARED AND MENU]
---
--- Checks if an index exists in the database.
---
---@param name string The name of the index to check.
---@return boolean exist `true` if the index exists, `false` otherwise.
---@nodiscard
function sqlite.indexExists(name) end

--- [SHARED AND MENU]
---
--- Executes a SQL query with parameters.
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
--- Executes a transaction of SQL queries in one block.
---
---@generic V
---@param fn fun( query_fn: ( fun( str: sqlite.Query, ...: sqlite.QueryValue ): ( sqlite.QueryRow[] | nil ) ) ): V The function to execute all SQL queries in one transaction.
---@return V value The result of function execution.
function sqlite.transaction(fn) end
