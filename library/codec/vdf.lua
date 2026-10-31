---@meta _

--- [SHARED AND MENU]
---
--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---
---@class vdf
vdf = {}

--- [SHARED AND MENU]
---
--- Converts the given table into a KeyValues string (pure Lua implementation).
---
--- Nested tables become sub-sections, booleans are written as `1`/`0`,
--- unsupported keys and values (functions, userdata, etc.) are skipped.
---
--- Raises an `EncodeError` on circular references.
---
--- `\`, `"`, `\n` and `\t` are escaped, so use `uses_escape_sequences` when deserializing.
---
---@param tbl table The table to convert.
---@param root_key string? The root key name, defaults to `TableToKeyValues`.
---@return string key_values The KeyValues string.
---@nodiscard
function vdf.serialize(tbl, root_key) end

--- [SHARED AND MENU]
---
--- Converts a KeyValues string into a key/value table (pure Lua implementation).
---
--- The root key is discarded, its contents are returned.
---
--- Order is not preserved, repeated keys overwrite earlier ones, numeric keys and values are converted to numbers.
---
--- Supports quoted and unquoted tokens, `//` comments and skips `[$CONDITION]` blocks.
---
--- Raises a `DecodeError` (with the byte position of the problem) on unterminated strings or conditionals,
--- keys without values, a missing root key or unbalanced braces, empty input decodes to an empty table.
---
---@param key_values string The KeyValues string to convert.
---@param uses_escape_sequences boolean? If set to `true`, will replace `\t`, `\n`, `\"` and `\\` with their escaped variants.
---@param preserve_key_case boolean? Whether to preserve key case or not (always lowercase).
---@return table result The converted table.
---@nodiscard
function vdf.deserialize(key_values, uses_escape_sequences, preserve_key_case) end
