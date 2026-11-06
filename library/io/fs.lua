---@meta _

--- [SHARED AND MENU]
---
--- The file object.
---
---@class fs.File : Object
---@field __class fs.FileClass
local __File = {}

---@class fs.FileClass : fs.File, Class
---@field __base fs.File
---@overload fun(): fs.File
File = {}

--- [SHARED AND MENU]
---
--- The directory object.
---
---@class fs.Directory : Object
---@field __class fs.DirectoryClass
local __Directory = {}

---@class fs.DirectoryClass : fs.Directory, Class
---@field __base fs.Directory
---@overload fun(): fs.Directory
Directory = {}
