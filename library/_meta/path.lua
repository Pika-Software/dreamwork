---@meta _


--- [SHARED AND MENU]
---
--- The result table of executing `path.parse`.
---
---    ┌─────────────────────┬────────────┐
---    │          dir        │    base    │
---    ├──────┬              ├──────┬─────┤
---    │ root │              │ name │ ext │
---    "  /    home/user/dir/  file  .txt "
---    └──────┴──────────────┴──────┴─────┘
--- (All spaces in the "" line should be ignored. They are purely for formatting.)
---
--- `dir .. name .. ext` is always the original path.
---
---@class path.ParsedData
local PathData = {}

--- The root of the file path, `"/"` for absolute paths, an empty string for relative ones.
---
---@type "/" | ""
PathData.root = ""

--- The directory of the file path with the root and the trailing slash, e.g. `"/home/user/dir/"`.
---
--- An empty string if the file path has no `/`.
---
---@type string
PathData.dir = ""

--- The base name of the file path, the file name with extension, e.g. `"file.txt"`.
---
---@type string
PathData.base = ""

--- The name of the file without the extension, e.g. `"file"`.
---
--- A leading dot is part of the name, e.g. `".bashrc"`.
---
---@type string
PathData.name = ""

--- The extension of the file with the dot, e.g. `".txt"`.
---
--- An empty string if the file has no extension.
---
---@type string
PathData.ext = ""

--- Whether the file path is absolute, i.e. starts with `/`.
---
---@type boolean
PathData.abs = false
