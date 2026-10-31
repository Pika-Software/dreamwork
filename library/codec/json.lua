---@meta _

--- [SHARED AND MENU]
---
--- The JSON format is a lightweight data interchange format.
---
--- Follows [RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259) strictly: objects, arrays, strings, numbers, `true`, `false` and `null`.
---
---@class json
json = {}

--- [SHARED AND MENU]
---
--- Deserialize a JSON string into a Lua value.
---
--- JSON `null` becomes `null` (never `nil`), numbers become Lua numbers, objects and arrays become plain tables.
---
--- A leading UTF-8 BOM is skipped, nesting deeper than `max_depth` levels is rejected.
---
--- Raises a `DecodeError` (with the byte position of the problem) on malformed input or trailing data.
---
---@param json_str string The JSON string to deserialize.
---@param max_depth? integer The maximum nesting depth, default is `512`.
---@return json.Value json_value The deserialized value.
function json.deserialize(json_str, max_depth) end

--- [SHARED AND MENU]
---
--- Serialize a Lua value into a JSON string.
---
--- Tables with only sequential keys `1..n` (and empty tables) become arrays, all other tables become objects.
---
--- `nil` and `null` are written as `null`.
---
--- Tables with a metatable are converted by the first available metamethod: `__tojson` (must return a valid JSON string, written as is), `__tonumber` (number) or `__tostring` (string).
---
--- Object keys that are not strings are converted: numbers and booleans are formatted, other values need `__tostring`.
---
--- Raises an `EncodeError` for any other non-JSON value (functions, threads, `NaN`/`inf`), unconvertible keys, keys that collide after conversion, or nesting deeper than `max_depth` levels (circular references).
---
---@param value json.Value | nil The value to serialize.
---@param prettify? boolean Whether to indent the output, default is `false`.
---@param max_depth? integer The maximum nesting depth, default is `512`.
---@return string json_str The JSON string.
---@nodiscard
function json.serialize(value, prettify, max_depth) end
