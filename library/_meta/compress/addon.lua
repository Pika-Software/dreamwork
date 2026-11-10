---@meta _


--- [SHARED AND MENU]
---
--- The file inside of the addon.
---
--- `content` is `nil` for files of a parsed addon until it is read with `Addon:readFile`,
--- the data stays in the addon string at `offset`.
---
---@class Addon.File
---@field path string The path of the file inside of the addon, e.g. `lua/autorun/test.lua`.
---@field size integer The size of the file in bytes.
---@field checksum integer The CRC-32 checksum of the file content, `0` if there is no checksum.
---@field content string | nil The file content, `nil` if it is still in the addon data.
---@field offset integer | nil The `1`-based position of the file content in the addon data.
