---@meta _

--- [SHARED AND MENU]
---
--- The Steam API library.
---
---@class steam
steam = {}

--- [SHARED AND MENU]
---
--- Returns the amount of seconds since the Steam user last moved their mouse.
---
--- Always `0` on dedicated servers.
---
---@return number seconds The amount of seconds since the user was last active.
---@nodiscard
function steam.getAwayTime() end

--- [SHARED AND MENU]
---
--- Returns the total uptime of the application in seconds as reported by Steam.
---
--- Uses `time.elapsed` on dedicated servers.
---
---@return number seconds The uptime in seconds.
---@nodiscard
function steam.getAppTime() end

--- [SHARED AND MENU]
---
--- Returns the Steam synchronized Unix time in seconds.
---
--- Uses `time.now` on dedicated servers.
---
---@return integer timestamp The Unix timestamp in seconds.
---@nodiscard
function steam.getTime() end

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
