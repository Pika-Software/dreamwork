---@meta _

--- [SHARED AND MENU]
---
--- The Steam API library.
---
---@class steam
steam = {}

--- [CLIENT AND MENU]
---
--- Requests the Steam name of the user with the given Steam ID.
---
--- Fails with `SteamError` if Steam doesn't know the account (`EResult` 42) or doesn't respond in time (`EResult` 16).
---
---@param id steam.Identifier The Steam ID of the user, or its SteamID64 string.
---@param timeout number? The timeout in seconds, `10` by default.
---@return string name The Steam name of the user.
---@nodiscard
---@async
function steam.getUserName(id, timeout) end
