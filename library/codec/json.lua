---@meta _

--- [SHARED AND MENU]
---
--- The JSON format is a lightweight data interchange format.
---
--- JSON is a subset of JavaScript, and can be used to share data between different programming languages.
---
--- See https://en.wikipedia.org/wiki/JSON
---
---@class json
json = {}

--- [SHARED AND MENU]
---
--- Deserialize a JSON string into a table.
---
---@param str string The JSON string to deserialize.
---@return table | nil tbl The deserialized table or `nil` if the deserialization failed.
---@nodiscard
function json.deserialize(str) end
