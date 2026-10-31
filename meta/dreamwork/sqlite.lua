---@meta dreamwork.std.sqlite


---@class dreamwork.std.sqlite

---@alias dreamwork.std.sqlite.Query
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

---@alias dreamwork.std.sqlite.QueryValue boolean | integer | number | string | dreamwork.std.null
---@alias dreamwork.std.sqlite.QueryRow table<string, dreamwork.std.sqlite.QueryValue>
