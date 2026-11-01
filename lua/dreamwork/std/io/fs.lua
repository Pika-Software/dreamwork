local glua_file = file
local file_Exists = glua_file.Exists

--- TODO
---@type fun( path: string )
---@diagnostic disable-next-line: undefined-global
local OpenFolder = OpenFolder


---@class dreamwork.std
local std = dreamwork.std

local class = std.class

local LUA_CLIENT = std.LUA_CLIENT
local LUA_SERVER = std.LUA_SERVER

local debug = std.debug
local debug_fempty = debug.fempty

local console = std.console

local pcall = std.pcall


--- [SHARED AND MENU]
---
--- The file system library, objects over the virtual file system (see `dreamwork.vfs`).
---
---@class dreamwork.std.fs
local fs = std.fs or {}
std.fs = fs

--- [SHARED AND MENU]
---
--- The file object.
---
---@class dreamwork.std.fs.File : dreamwork.std.Object
---@field __class dreamwork.std.fs.FileClass
---@field path string The absolute path of the file. **READ-ONLY**
local File = class.base( "File", false )

---@class dreamwork.std.fs.FileClass : dreamwork.std.fs.File
---@field __base dreamwork.std.fs.File
---@overload fun(): dreamwork.std.fs.File
local FileClass = class.create( File )
fs.File = FileClass

--- [SHARED AND MENU]
---
--- The directory object.
---
---@class dreamwork.std.fs.Directory : dreamwork.std.Object
---@field __class dreamwork.std.fs.DirectoryClass
---@field path string The absolute path of the directory. **READ-ONLY**
local Directory = class.base( "Directory", false )

---@class dreamwork.std.fs.DirectoryClass : dreamwork.std.fs.Directory
---@field __base dreamwork.std.fs.Directory
---@overload fun(): dreamwork.std.fs.Directory
local DirectoryClass = class.create( Directory )
fs.Directory = DirectoryClass
