---@meta _


--- A JSON primitive: string, number, boolean or `null`.
---
---@alias json.Primitive string | number | boolean | null

--- A JSON array, a sequence of JSON values.
---
---@alias json.Array json.Value[]

--- A JSON object, string keys mapped to JSON values.
---
---@alias json.Object table<string, json.Value>

--- Any valid JSON value.
---
---@alias json.Value json.Primitive | json.Array | json.Object

--- A JSON document root, an object or an array.
---
---@alias json.Table json.Object | json.Array
