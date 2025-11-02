local _G = _G
local glua_system = _G.system

---@class dreamwork.std
local std = _G.dreamwork.std

--- [SHARED AND MENU]
---
--- Steam API library.
---
---@class dreamwork.std.steam
local steam = std.steam or {}
std.steam = steam

if glua_system ~= nil then

    steam.getAwayTime = glua_system.UpTime or function() return 0 end
    steam.getAppTime = glua_system.AppTime or steam.getAwayTime
    steam.getTime = glua_system.SteamTime or std.time.now

end
