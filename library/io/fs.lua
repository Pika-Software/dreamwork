---@meta _

--- [SHARED AND MENU]
---
--- The file system library, objects over the virtual file system (see `dreamwork.vfs`).
---
---@class fs
fs = {}

--- [SHARED AND MENU]
---
--- The file object.
---
---@class fs.File : Object
---@field __class fs.FileClass
---@field path string The absolute path of the file. **READ-ONLY**
local File = {}

---@class fs.FileClass : fs.File, Class
---@field __base fs.File
---@overload fun(): fs.File
local FileClass = {}

fs.File = FileClass

--- [SHARED AND MENU]
---
--- The directory object.
---
---@class fs.Directory : Object
---@field __class fs.DirectoryClass
---@field path string The absolute path of the directory. **READ-ONLY**
local Directory = {}

---@class fs.DirectoryClass : fs.Directory, Class
---@field __base fs.Directory
---@overload fun(): fs.Directory
local DirectoryClass = {}

fs.Directory = DirectoryClass
