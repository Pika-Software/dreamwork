---@meta _

--- [SHARED AND MENU]
---
--- Loads a file as
--- a lua code chunk in the specified environment
--- and returns function as a compile result.
---
---@param file_path string The path to the file to read.
---@param is_bytecode boolean If `true`, the file will be loaded as a bytecode chunk.
---@param env table | nil The environment of compiled function.
---@return function | nil fn The compiled function.
---@return string | nil msg The error message.
---@nodiscard
function loadfile(file_path, is_bytecode, env) end
