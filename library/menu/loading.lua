---@meta _

--- [MENU]
---
--- The game's loading screen while connecting to a server.
---
--- The engine only reports a status string and a flat list of files. This module
--- cleans those up, notices which files are already on disk, and announces the changes.
---
--- ```lua
--- print( menu.loading.getDefaultHTML() ) -- asset://garrysmod/html/loading.html
--- print( menu.loading.active ) -- false
--- ```
---
---@class menu.loading
---@field active boolean `true` while the loading screen is open.
menu.loading = {}

--- [MENU]
---
--- Called when the loading screen opens.
---
---@type Event
menu.loading.Started = nil

--- [MENU]
---
--- Called when the loading screen closes.
---
---@type Event
menu.loading.Finished = nil

--- [MENU]
---
--- Called when the engine status text changes.
---
--- Arguments: `status: string`.
---
---@type Event
menu.loading.StatusChanged = nil

--- [MENU]
---
--- Called when the status text names a file that started downloading.
---
--- Arguments: `file_name: string`.
---
---@type Event
menu.loading.FileDownloading = nil

--- [MENU]
---
--- Called when a listed file is found on disk.
---
--- Each file is reported once per connection, a file that was already there is reported when the list is first scanned.
---
--- Arguments: `file_path: string`.
---
---@type Event
menu.loading.FileDownloaded = nil

--- [MENU]
---
--- Called when the number of listed files still missing from disk changes.
---
--- Arguments: `remaining: integer`, `total: integer`.
---
---@type Event
menu.loading.FilesChanged = nil

--- [MENU]
---
--- Returns the URL of the built-in loading page (`asset://garrysmod/html/loading.html`).
---
--- This is the page the game shows when the server has no loading URL of its own.
---
---@return string html_url The default loading page.
---@nodiscard
function menu.loading.getDefaultHTML() end

--- [MENU]
---
--- Returns how many files the server wants the client to have.
---
---@return integer file_count The number of files, `0` when the engine reports none.
---@nodiscard
function menu.loading.getFileCount() end

--- [MENU]
---
--- Returns the files the server wants the client to have.
---
--- Download suffixes (`.bz2`, `.ztmp`) are removed, backslashes become slashes,
--- and a bare workshop addon name is rewritten to `cache/workshop/…`.
---
---@return string[] files The normalized file paths. Empty when the engine has no list.
---@return integer file_count The number of files the engine reports, `0` when it reports none.
---@nodiscard
function menu.loading.getFiles() end

--- [MENU]
---
--- Returns the listed files that are not on disk yet.
---
--- The array is updated in place while the loading screen is open, its order is not kept.
---
---@return string[] files The files still missing.
---@return integer file_count The number of files still missing.
---@nodiscard
function menu.loading.getPending() end

--- [MENU]
---
--- Returns the listed files that are already on disk.
---
--- The array is updated in place while the loading screen is open.
---
---@return string[] files The files already on disk.
---@return integer file_count The number of files already on disk.
---@nodiscard
function menu.loading.getDownloaded() end

--- [MENU]
---
--- Returns the current join status.
---
--- Whitespace, `.bz2`, `.ztmp` and backslashes are removed, the same way the file list is cleaned.
---
---@return string status The status text, `""` when the engine has none.
---@nodiscard
function menu.loading.getStatus() end

--- [MENU]
---
--- Stops joining the server.
---
menu.loading.cancel = nil

--- [MENU]
---
--- Returns how much of the file list is already on disk.
---
--- The fraction is `downloaded / total`, clamped to `0..1`.
--- It stays `0` until the first list arrives while the screen is open,
--- and `1` when the screen is closed and the server asked for no files.
---
---@return number fraction From `0` to `1`.
---@return integer downloaded The number of listed files already on disk.
---@return integer total The number of files the server asked for.
---@nodiscard
function menu.loading.getProgress() end
