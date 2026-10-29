---@meta _

--- [SHARED AND MENU]
---
--- Checks if a binary module is available and can be loaded.
---
---@param name string The binary module name.
---@return boolean installed `true` if binary module is available, `false` otherwise.
---@return string abs_path The absolute path to binary module.
function lookupbinary(name) end

--- [SHARED AND MENU]
---
--- Loads a binary module if available.
---
---@param name string The binary module name, for example: "chttp".
---@return boolean success `true` if binary module is successfully installed, `false` otherwise.
function loadbinary(name) end

---@class fs.MountInfo
---@field writable boolean If `true` mount allows creating directories inside.
---@field writable_extensions table<string, boolean> The extension map of allowed extensions to write.
---@field deletable boolean If `true` mount allows deleting files and directories.

---@class File : Object
local File = {}
