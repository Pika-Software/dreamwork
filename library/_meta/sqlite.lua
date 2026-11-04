---@meta _


---@alias sqlite.Query
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

--- The type of a schema object, as stored in the `type` column of `sqlite_master`.
---
---@alias sqlite.ObjectType
---| "table" # A table, created with `CREATE TABLE`.
---| "index" # An index, created with `CREATE INDEX` or implicitly by `UNIQUE` / `PRIMARY KEY` constraints.
---| "view" # A view, created with `CREATE VIEW`.
---| "trigger" # A trigger, created with `CREATE TRIGGER`.

---@alias sqlite.QueryValue boolean | integer | number | string | sqlite.Blob | null
---@alias sqlite.QueryRow table<string, sqlite.QueryValue>

---@alias sqlite.ColumnType
---| "string" # Kept as is.
---| "number" # Converted with `tonumber`, `nil` if it is not a number.
---| "boolean" # `true` for any value except `"0"`.
---| "blob" # Decoded from base16, select the column as `hex( column )`.
