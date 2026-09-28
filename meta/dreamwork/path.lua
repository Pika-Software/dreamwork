---@meta dreamwork.std.path


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
---@class dreamwork.std.path.Data
local PathData = {}

--- The root of the file path.
---
---@type "/" | ""
PathData.root = ""

--- The directory of the file path.
---
---@type string
PathData.dir = ""

--- The `basename` of the file path, basically the name of the file with extension.
---
---@type string
PathData.base = ""

--- The name of file in the file path.
---
---@type string
PathData.name = ""

--- The extension of file in the file path.
---
---@type string
PathData.ext = ""

--- Whether the file path is absolute or not.
---
---@type boolean
PathData.abs = false
