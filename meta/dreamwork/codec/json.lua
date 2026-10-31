---@meta dreamwork.std.json


--- A JSON primitive: string, number, boolean or `null`.
---
---@alias dreamwork.std.json.Primitive string | number | boolean | dreamwork.std.null

--- A JSON array, a sequence of JSON values.
---
---@alias dreamwork.std.json.Array dreamwork.std.json.Value[]

--- A JSON object, string keys mapped to JSON values.
---
---@alias dreamwork.std.json.Object table<string, dreamwork.std.json.Value>

--- Any valid JSON value.
---
---@alias dreamwork.std.json.Value dreamwork.std.json.Primitive | dreamwork.std.json.Array | dreamwork.std.json.Object

--- A JSON document root, an object or an array.
---
---@alias dreamwork.std.json.Table dreamwork.std.json.Object | dreamwork.std.json.Array
