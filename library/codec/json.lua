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
--- Decodes a JSON string into a Lua value, the root can be any JSON value.
---
--- JSON `null` becomes `null` (never `nil`), numbers become Lua numbers, objects and arrays become plain tables.
---
--- A leading UTF-8 BOM is skipped, nesting deeper than `max_depth` levels is rejected.
---
--- Raises a `DecodeError` (with the byte position of the problem) on malformed input or trailing data.
---
---@see json.deserialize for objects and arrays only.
---
---@param json_str string The JSON string to decode.
---@param max_depth integer? The maximum nesting depth, default is `512`.
---@return json.Value json_value The decoded value.
function json.decode(json_str, max_depth) end

--- [SHARED AND MENU]
---
--- Deserializes a JSON string into a Lua table, the root must be an object or an array.
---
--- JSON `null` becomes `null` (never `nil`), numbers become Lua numbers, objects and arrays become plain tables.
---
--- A leading UTF-8 BOM is skipped, nesting deeper than `max_depth` levels is rejected.
---
--- Raises a `DecodeError` (with the byte position of the problem) on malformed input, trailing data or a non-table root.
---
---@see json.decode for any JSON value.
---
---@param json_str string The JSON string to deserialize.
---@param max_depth integer? The maximum nesting depth, default is `512`.
---@return json.Table json_table The deserialized table.
function json.deserialize(json_str, max_depth) end

--- [SHARED AND MENU]
---
--- Encodes a Lua value into a JSON string, the root can be any JSON value.
---
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
---@see json.serialize for objects and arrays only.
---
---@param value json.Value | nil The value to encode.
---@param prettify boolean? Whether to indent the output, default is `false`.
---@param max_depth integer? The maximum nesting depth, default is `512`.
---@return string json_str The JSON string.
---@nodiscard
function json.encode(value, prettify, max_depth) end

--- [SHARED AND MENU]
---
--- Serializes a Lua table into a JSON string, the root must be an object or an array.
---
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
---@see json.encode for any JSON value.
---
---@param tbl json.Table The table to serialize.
---@param prettify boolean? Whether to indent the output, default is `false`.
---@param max_depth integer? The maximum nesting depth, default is `512`.
---@return string json_str The JSON string.
---@nodiscard
function json.serialize(tbl, prettify, max_depth) end
