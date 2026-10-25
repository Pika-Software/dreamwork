---@meta garrysmod.system


--- [SHARED AND MENU]
---
--- The system library provides functions that allow you to gather information about the system running the game, such as operating system, uptime and battery level.
---
---@class garrysmod.system
system = {}


--- [CLIENT AND MENU]
---
--- Returns whether or not the game window has focus.
---
--- > **NOTE**: This function does not work on dedicated servers and will instead return no value.
---
---@return boolean has_focus Whether or not the game window has focus.
function system.HasFocus() end

--- [CLIENT AND MENU]
---
--- Returns the country code of this computer, determined by the IP of the client.
---
--- Uses the steamworks API function `SteamUtils()->GetIPCountry()`.
---
--- > **NOTE**: This function does not work on dedicated servers and will instead return no value.
---
---@return string code Two-letter country code, using [ISO 3166-1](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) standard.
function system.GetCountry() end

---@alias garrysmod.system.BatteryPower 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70 | 71 | 72 | 73 | 74 | 75 | 76 | 77 | 78 | 79 | 80 | 81 | 82 | 83 | 84 | 85 | 86 | 87 | 88 | 89 | 90 | 91 | 92 | 93 | 94 | 95 | 96 | 97 | 98 | 99 | 100 | 255

--- [SHARED AND MENU]
---
--- Returns the current battery power.
---
--- > `0-100` if a battery (laptop, UPS, etc) is present.
---
--- > Will instead return `255` if plugged in without a battery.
---
---@return garrysmod.system.BatteryPower
function system.BatteryPower() end
