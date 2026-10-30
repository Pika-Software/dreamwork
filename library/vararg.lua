---@meta _

--- [SHARED AND MENU]
---
--- Provides utility functions for selecting, accessing, modifying, slicing,
--- packing, and unpacking variable-length argument lists.
---
---@class vararg
vararg = {}

--- [SHARED AND MENU]
---
--- If `index` is a number, returns all arguments after argument number `index`;
---
--- a negative number indexes from the end (`-1` is the last argument).
---
--- Otherwise, `index` must be the string `"#"`, and `select` returns the total number of extra arguments it received.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-select)
---
---@overload fun( parameter: "#", ...: any ): integer
---@overload fun( parameter: integer, ...: any ): ...: any
vararg.select = raw.select

--- [SHARED AND MENU]
---
--- Returns the value at the specified argument `index`.
---
--- A positive index starts at `1`.
---
--- A negative index starts from the end, where `-1` is the last argument.
---
--- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-select)
---
---@param index integer The index of the value to retrieve.
---@param ... any The argument list to retrieve the value from.
---@return any value The value at `index`.
---@nodiscard
function vararg.get(index, ...) end

--- [SHARED AND MENU]
---
--- Sets the value at `index` with `value` in the argument list.
---
--- If `index` is out of bounds, the argument list is returned unchanged.
---
--- A positive index starts at `1`.
---
--- A negative index starts from the end, where `-1` is the last argument.
---
---@param index integer The index at which to replace the value.
---@param value any The value to set.
---@param ... any The argument list to modify.
---@return any ... The argument list with the value at `index` replaced.
---@nodiscard
function vararg.set(index, value, ...) end

--- [SHARED AND MENU]
---
--- Returns a slice of the argument list between `start_position` and
--- `end_position`, inclusive.
---
--- Positive positions start at `1`.
---
--- Negative positions start from the end, where `-1` is the last argument.
---
--- If `start_position` is omitted, `1` is used.
---
--- If `end_position` is omitted, the last argument is used.
---
--- Positions outside the argument list are clamped to its bounds.
---
---@param start_position? integer The first position to include.
---@param end_position? integer The last position to include.
---@param ... any The argument list to slice.
---@return any ... The selected portion of the argument list.
---@nodiscard
function vararg.slice(start_position, end_position, ...) end

--- [SHARED AND MENU]
---
--- Returns the argument list in reverse order.
---
--- `nil` values are preserved.
---
---@param ... any The argument list to reverse.
---@return any ... The reversed argument list.
---@nodiscard
function vararg.reverse(...) end

--- [SHARED AND MENU]
---
--- Packs the argument list into a table.
---
--- The number of arguments is stored at index `0`, allowing `nil` values
--- to be preserved.
---
---@param ... any The values to pack.
---@return table packed A table containing the packed values.
---@return integer A size of the given table.
---@nodiscard
function vararg.pack(...) end

--- [SHARED AND MENU]
---
--- Unpacks a table created by `vararg.pack` into an argument list.
---
--- The argument count must be stored at index `0`.
---
---@param tbl table The packed argument table.
---@return any ... The values stored in the table.
---@nodiscard
function vararg.unpack(tbl) end

--- [SHARED AND MENU]
---
--- Concatenates all given values into a single string, separated by `sep`.
---
--- Each value is converted to a string using `tostring` before being joined.
---
---@param sep string The separator to insert between each concatenated value.
---@param ... any The values to concatenate (converted via `tostring`).
---@return string str The resulting concatenated string.
---@nodiscard
function vararg.concat(sep, ...) end

--- [SHARED AND MENU]
---
--- Calls `fn` for each argument and returns the results as a new argument list.
---
--- `fn` receives the index first and the value second, same as `table.map`.
---
--- Only the first return value of `fn` is used for each argument.
---
--- The number of arguments is preserved, including `nil` values.
---
---@generic T
---@param fn fun( index: integer, value: T ): T | nil The function to apply to each argument.
---@param ... T The argument list to map.
---@return T ... The mapped argument list.
---@nodiscard
function vararg.map(fn, ...) end
