---@meta garrysmod.sql


--- [SHARED AND MENU]
---
--- The SQL library allows you to access powerful database software
--- included with **Garry's Mod**.
---
--- It is the preferred and fastest method of storing large amounts of data.
---
--- The database is located in `sv.db` serverside and `cl.db` clientside,
--- both in the Garry's Mod base folder.
---
--- SQL is a whole scripting language in itself although relatively simple,
--- it's something you'll need to read up on before using this library.
---
---@class garrysmod.sql
---@field m_strError string | nil
sql = {}

---@alias garrysmod.sql.Query
---| "SELECT"
---| "INSERT"
---| "UPDATE"
---| "DELETE"
---| "CREATE"
---| "ALTER"
---| "DROP"
---| "BEGIN"
---| "COMMIT"
---| "ROLLBACK"
---| "PRAGMA"
---| "REPLACE"
---| "WITH"
---| string

---@alias garrysmod.sql.QueryValue boolean | integer | number | string
---@alias garrysmod.sql.QueryRow table<string, garrysmod.sql.QueryValue>

--- [SHARED AND MENU]
---
--- Performs a query on the local SQLite database, returns a `table` as result set, `nil` if result is empty and `false` on error.
---
--- > NOTE: Every column value in the result set is returned as a string, including numbers, and a SQL NULL is returned as the string "NULL". Use sql.QueryTyped to receive typed values.
---
---@param sql_query string The query to execute.
---@return garrysmod.sql.QueryRow[] | false | nil `false` is returned if there is an error, `nil` if the query returned no data.
function sql.Query( sql_query ) end
