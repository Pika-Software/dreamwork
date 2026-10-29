---@meta _


--- [SHARED AND MENU]
---
--- The URL state object.
---
---@class URL.State
---@field scheme string?
---@field username string?
---@field password string?
---@field hostname string | table | number | nil
---@field port number?
---@field path string | table | nil
---@field fragment string?
---@field query string | URL.SearchParams
local URLState = {}
