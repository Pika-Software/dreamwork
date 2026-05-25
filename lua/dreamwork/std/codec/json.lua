local glua_util = util

---@class dreamwork.std
local std = dreamwork.std

--- [SHARED AND MENU]
---
--- The JSON format is a lightweight data interchange format.
---
--- JSON is a subset of JavaScript, and can be used to share data between different programming languages.
---
--- See https://en.wikipedia.org/wiki/JSON
---
---@class dreamwork.std.json
local json = std.json or {}
std.json = json

if json.deserialize == nil then

    local util_JSONToTable = glua_util.JSONToTable or std.debug.fempty

    --- [SHARED AND MENU]
    ---
    --- Deserialize a JSON string into a table.
    ---
    ---@param str string The JSON string to deserialize.
    ---@return table | nil tbl The deserialized table or `nil` if the deserialization failed.
    function json.deserialize( str )
        return util_JSONToTable( str, true, true )
    end

end

json.serialize = json.serialize or glua_util.TableToJSON
