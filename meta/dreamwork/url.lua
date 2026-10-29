---@meta dreamwork.std.url


--- [SHARED AND MENU]
---
--- The URL state object.
---
---@class dreamwork.std.URL.State
---@field scheme string?
---@field username string?
---@field password string?
---@field hostname string | table | number | nil
---@field port number?
---@field path string | table | nil
---@field fragment string?
---@field query string | dreamwork.std.URL.SearchParams
local URLState = {}
