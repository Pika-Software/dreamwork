---@meta _

--- [SHARED AND MENU]
---
--- The table library is a standard Lua library which provides functions to manipulate tables.
---
---@class tablelib
table = {}

---@generic V
---@param ... V
---@return V[]
---@nodiscard
function table.pack(...) end

--- [SHARED AND MENU]
---
--- Inserts a value into a table at the specified index.
---
---@generic V
---
---@overload fun( tbl: V[], value: V ): integer
---
---@param tbl V[] The table to insert the value into.
---@param index integer The index to insert the value at.
---@param value V The value to insert.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return integer index The index of the inserted value.
function table.insert(tbl, index, value, tbl_length) end

--- [SHARED AND MENU]
---
--- Moves elements from one table to another.
---
---@generic V
---@param source V[] The source table.
---@param start_position? integer The start position of the source table, defaults to 1.
---@param end_position? integer The end position of the source table, defaults to the length of the source table.
---@param offset? integer The start position of the destination table, defaults to 1.
---@param destination? V[] The destination table, defaults to the source table.
---@param source_length? integer The length of the source table. Optionally, it should be used to speed up calculations.
---@return V[] destination Selected destination table.
function table.move(source, start_position, end_position, offset, destination, source_length) end

--- [SHARED AND MENU]
---
--- Returns a shallow copy of the given table.
---
--- NOTE: This function is much faster that any other copy function and method,
--- but works and efficient enough only for small tables (up to 1000 elements).
---
---@generic V
---@param tbl V[] The table to copy.
---@return V[] The copied table.
---@nodiscard
function table.shallowCopy(tbl) end

--- [SHARED AND MENU]
---
--- Returns a range of elements from the given table.
---
---@generic V
---@param tbl V[] The table to get the range from.
---@param start_position? integer The start position of the range.
---@param end_position? integer The end position of the range.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] range_values The values of the range.
---@return integer range_length The length of the range.
---@nodiscard
function table.range(tbl, start_position, end_position, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns a shallow copy of the given table.
---
--- NOTE: This function is much faster that any other copy function and method,
--- but works and efficient enough only for small tables (up to 1000 elements).
---
---@generic V
---@param tbl V[] The table to copy.
---@return V[] The copied table.
function table.shallowCopy(tbl) end

--- [SHARED AND MENU]
---
--- Returns a range of elements from the given table.
---
---@generic V
---@param tbl V[] The table to get the range from.
---@param start_position? integer The start position of the range.
---@param end_position? integer The end position of the range.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] range_values The values of the range.
---@return integer range_length The length of the range.
function table.range(tbl, start_position, end_position, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns a slice of the given table.
---
---@generic V
---@param tbl V[] The table to slice.
---@param start_position? integer The start position of the slice.
---@param end_position? integer The end position of the slice.
---@param step? integer The step of the slice.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] slice The slice of the table.
---@return integer length The length of the sliced table.
---@nodiscard
function table.slice(tbl, start_position, end_position, step, tbl_length) end

--- [SHARED AND MENU]
---
--- Truncates the given table.
---
--- The original table is modified.
---
--- The truncated table is a shallow copy of the original table.
---
---@generic V
---@param tbl V[] The table to truncate.
---@param new_length? integer The length of the truncated table.
---@param tbl_length? integer The length of the original table. Optionally, it should be used to speed up calculations.
function table.truncate(tbl, new_length, tbl_length) end

--- [SHARED AND MENU]
---
--- Creates a truncated copy of the given table.
---
--- The original table is not modified.
---
--- The returned table is a shallow copy of the original table.
---
---@generic V
---@param tbl V[] The table to truncate.
---@param tbl_length? integer The length of the truncated table. Optionally, it should be used to speed up calculations.
---@return V[] truncated The truncated table.
---@nodiscard
function table.truncated(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Injects values from one table to another.
---
---@generic V
---@param destination V[] The destination table.
---@param source V[] The source table.
---@param offset? integer The position to inject.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param destination_length? integer The length of the destination table. Optionally, it should be used to speed up calculations.
---@param source_length? integer The length of the source table. Optionally, it should be used to speed up calculations.
function table.inject(destination, source, offset, start_position, end_position, destination_length, source_length) end

--- [SHARED AND MENU]
---
--- Ejects selected range of values from the given table.
---
---@generic V
---@param tbl V[] The table to remove values from.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] values The removed values.
---@return integer values_length The count of removed values.
function table.eject(tbl, start_position, end_position, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns true if the given table is empty.
---
---@param tbl table The table to check.
---@return boolean result `true` if the table is empty, `false` otherwise.
---@nodiscard
function table.isEmpty(tbl) end

--- [SHARED AND MENU]
---
--- Returns the index of the value in the given table.
---
--- Returns `nil` if the value is not found in the table.
---
---@generic V
---@param tbl V[] The table to search.
---@param searchable V The value to search for.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return integer | nil index The index of the value.
---@nodiscard
function table.getIndex(tbl, searchable, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns the key of the value in the given table.
---
--- Returns `nil` if the value is not found in the table.
---
---@generic K, V
---@param tbl table<K, V> The table to search.
---@param searchable V The value to search for.
---@return K | nil key The key of the value.
---@nodiscard
function table.getKey(tbl, searchable) end

--- [SHARED AND MENU]
---
--- Returns list (table) of keys and length of this list.
---
---@generic K, V
---@param tbl table<K, V> The table.
---@return K[] key_lst The list of keys.
---@return integer key_count The length of the list.
---@nodiscard
function table.keys(tbl) end

--- [SHARED AND MENU]
---
--- Returns list (table) of values and length of this list.
---
---@generic K, V
---@param tbl table<K, V> The table.
---@return V[] value_lst The list of values.
---@return integer value_count The length of the list.
---@nodiscard
function table.values(tbl) end

--- [SHARED AND MENU]
---
--- Returns the count of keys in the given table.
---
---@generic K, V
---@param tbl table<K, V> The table.
---@return integer key_count The count of keys.
---@nodiscard
function table.count(tbl) end

--- [SHARED AND MENU]
---
--- Flips the keys with values in the given list (table).
---
--- The original table is modified.
---
--- The keys are now the values and the values are now the keys.
---
--- `{ key = value } -> { value = key }`
---
---@generic K, V
---@param tbl table<K, V> The table to flip.
function table.flip(tbl) end

--- [SHARED AND MENU]
---
--- Creates a flipped version of the given table.
---
--- The original table is not modified.
---
--- The flipped table has the values as keys and the keys as values.
---
--- `{ key = value } -> { value = key }`
---
---@generic K, V
---@param tbl table<K, V> The table to flip.
---@return table<V, K> result The flipped table.
---@nodiscard
function table.flipped(tbl) end

---@class table.Pair<K,V>
---@field [1] K The key of the pair.
---@field [2] V The value of the pair.

--- [SHARED AND MENU]
---
--- Returns the list (table) of key/value pairs and length of this list.
---
---@generic K, V
---@param tbl table<K, V> The table.
---@return table.Pair<K, V>[] result The list of key/value pairs ( sequential table ).
---@return integer result_length The length of the list.
---@nodiscard
function table.pairs(tbl) end

--- [SHARED AND MENU]
---
--- Returns true if the given table is sequential.
---
---@param tbl table The table to check.
---@return boolean is_sequential `true` if the table is sequential, `false` otherwise.
---@nodiscard
function table.isSequential(tbl) end

--- [SHARED AND MENU]
---
--- Empties the indexes of the given table.
---
---@generic V
---@param tbl V[] The table to empty.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.clearIndexes(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Empties the keys of the given table.
---
---@generic K, V
---@param tbl table<K, V> The table to empty.
function table.clearKeys(tbl) end

--- [SHARED AND MENU]
---
--- Shuffles the given table.
---
---@generic V
---@param tbl V[] The table.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.shuffle(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns a random index and its value from the given sequential table.
---
---@generic V
---@param tbl V[] The sequential table.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V value The random value.
---@return integer | nil index The index of the value.
---@nodiscard
function table.randomVI(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Returns a random key and its value from the given table.
---
---@generic K, V
---@param tbl table<K, V> The key-value table.
---@return V value The random value.
---@return K key The key of the value.
---@nodiscard
function table.randomVK(tbl) end

--- [SHARED AND MENU]
---
--- Reverses all indexes in the given table.
---
--- The original table will be **modified**.
---
--- Example of a reversed table:
---
---|   Old   |   New   |
---|---------|---------|
---| `[ 1 ]` | `[ 5 ]` |
---| `[ 2 ]` | `[ 4 ]` |
---| `[ 3 ]` | `[ 3 ]` |
---| `[ 4 ]` | `[ 2 ]` |
---| `[ 5 ]` | `[ 1 ]` |
---
---@generic V
---@param tbl V[] The sequential table.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] tbl The reversed sequential table.
---@return integer length The length of the reversed table.
function table.reverse(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Creates a reversed by indexes copy of the given table.
---
--- The original table remains **unchanged**.
---
--- Example of a reversed table:
---
---|   Old   |   New   |
---|---------|---------|
---| `[ 1 ]` | `[ 5 ]` |
---| `[ 2 ]` | `[ 4 ]` |
---| `[ 3 ]` | `[ 3 ]` |
---| `[ 4 ]` | `[ 2 ]` |
---| `[ 5 ]` | `[ 1 ]` |
---
---@generic V
---@param tbl V[] The table to reverse.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] reversed The reversed table.
---@return integer length The length of the reversed table.
---@nodiscard
function table.reversed(tbl, tbl_length) end

--- [SHARED AND MENU]
---
--- Creates a new table, filled with the given value and size.
---
---@generic V
---@param value V The value to fill the table with.
---@param ... integer The sizes of the table.
---@return V[] tbl The created table.
---@nodiscard
function table.create(value, size, ...) end

--- [SHARED AND MENU]
---
--- Extracts selected range of values from the table.
---
---@generic V
---@param tbl V[] The table to extract values from.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param step_size? integer The step size.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return V[] values The extracted values.
---@return integer length The length of the extracted values.
---@nodiscard
function table.extract(tbl, start_position, end_position, step_size, tbl_length) end

--- [SHARED AND MENU]
---
--- Applies a function to each value of the table.
---
--- The original table remains **unchanged**.
---
--- The returned table is a shallow copy of the original table.
---
---@generic V
---@param tbl V[] The table to map.
---@param fn fun( index: integer, value: V ): V | nil The function to apply.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up execution.
---@return V[] mapped The new mapped sequential table.
---@return integer mapped_length The length of the new mapped sequential table.
---@nodiscard
function table.map(tbl, fn, tbl_length) end

--- [SHARED AND MENU]
---
--- Applies a function to each key/value pair of the table.
---
--- The original table remains **unchanged**.
---
--- The returned table is a shallow copy of the original table.
---
---@generic K, V
---@param tbl table<K, V> The key/value table.
---@param fn fun( key: K, value: V ): V | nil The function to apply.
---@return table<K, V> transformed The new transformed key/value table.
---@nodiscard
function table.transform(tbl, fn) end

--- [SHARED AND MENU]
---
--- Executes a provided function once for each table value.
---
---@generic V
---@param tbl V[] The table to execute the function on.
---@param fn fun( index: integer, value: V ) The function to execute.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up execution.
function table.foreach(tbl, fn, tbl_length) end

--- [SHARED AND MENU]
---
--- Removes a value from the given table by its value.
---
---@generic V
---@param tbl V[] The table to remove from.
---@param value V The value that will be removed.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
---@return integer | nil index The index of the value.
function table.removeByValue(tbl, value, tbl_length) end

--- [SHARED AND MENU]
---
--- Removes a range of values from the given table.
---
---@generic V
---@param tbl V[] The table to remove from.
---@param start_position? integer The start position.
---@param end_position? integer The end position.
---@param tbl_length? integer The length of the table. Optionally, it should be used to speed up calculations.
function table.removeByRange(tbl, start_position, end_position, tbl_length) end

--- [SHARED AND MENU]
---
--- Creates a shallow copy of the given table.
---
--- The original table is not modified.
---
--- The returned table is a shallow copy of the original table.
---
---@generic T
---@param tbl T The table to copy.
---@return T copy The copied table.
---@nodiscard
function table.copy(tbl) end
