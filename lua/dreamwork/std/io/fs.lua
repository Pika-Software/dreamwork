---@class dreamwork.std
local std = dreamwork.std

local class = std.class

--- [SHARED AND MENU]
---
--- The file object.
---
---@class dreamwork.std.fs.File : dreamwork.std.Object
---@field __class dreamwork.std.fs.FileClass
local File = class.base( "File", false )

---@class dreamwork.std.fs.FileClass : dreamwork.std.fs.File, dreamwork.std.Class
---@field __base dreamwork.std.fs.File
---@overload fun(): dreamwork.std.fs.File
local FileClass = class.create( File )
std.File = FileClass

--- [SHARED AND MENU]
---
--- The directory object.
---
---@class dreamwork.std.fs.Directory : dreamwork.std.Object
---@field __class dreamwork.std.fs.DirectoryClass
local Directory = class.base( "Directory", false )

---@class dreamwork.std.fs.DirectoryClass : dreamwork.std.fs.Directory, dreamwork.std.Class
---@field __base dreamwork.std.fs.Directory
---@overload fun(): dreamwork.std.fs.Directory
local DirectoryClass = class.create( Directory )
std.Directory = DirectoryClass
