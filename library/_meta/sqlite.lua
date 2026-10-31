---@meta _


---@class sqlite

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

---@alias sqlite.QueryValue boolean | integer | number | string | null
---@alias sqlite.QueryRow table<string, sqlite.QueryValue>
