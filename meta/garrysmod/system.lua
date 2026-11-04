---@meta garrysmod.system


--- [SHARED AND MENU]
---
--- The system library provides functions that allow you to gather information about the system running the game, such as operating system, uptime and battery level.
---
---@class garrysmod.system
system = {}


--- [SHARED AND MENU]
---
--- Returns the total uptime of the current application as reported by Steam.
---
--- This will return a similar value to [Global.SysTime](https://wiki.facepunch.com/gmod/Global.SysTime).
---
--- > **NOTE**: This function does not work on Dedicated Servers and will instead return no value.
---
---@return number uptime Seconds of game uptime as an integer.
function system.AppTime() end

---@alias garrysmod.system.BatteryPower 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70 | 71 | 72 | 73 | 74 | 75 | 76 | 77 | 78 | 79 | 80 | 81 | 82 | 83 | 84 | 85 | 86 | 87 | 88 | 89 | 90 | 91 | 92 | 93 | 94 | 95 | 96 | 97 | 98 | 99 | 100

--- [SHARED AND MENU]
---
--- Returns the current battery power.
---
--- > `0-100` if a battery (laptop, UPS, etc) is present.
---
--- > Will instead return `255` if plugged in without a battery.
---
---@return garrysmod.system.BatteryPower | 255 battery_level The battery level, from `0` to `100`.
function system.BatteryPower() end

--- [CLIENT AND MENU]
---
--- Flashes the window, turning the border to white briefly.
---
--- > **WARNING**: Currently works only on Windows.
---
function system.FlashWindow() end

--- [SHARED AND MENU]
---
--- Returns the country code of this computer, determined by the IP of the client.
---
--- Uses the steamworks API function `SteamUtils()->GetIPCountry()`.
---
--- > **NOTE**: This function does not work on Dedicated Servers and will instead return no value.
---
---@return string code Two-letter country code, using [ISO 3166-1](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) standard.
function system.GetCountry() end

--- [SHARED AND MENU]
---
--- Returns whether or not the game window has focus.
---
--- > **NOTE**: This function does not work on dedicated servers and will instead return no value.
---
---@return boolean has_focus Whether or not the game window has focus.
function system.HasFocus() end

--- [SHARED AND MENU]
---
--- Returns whether the current OS is Linux.
---
---@return boolean is_linux Whether or not the game is running on Linux.
function system.IsLinux() end

--- [SHARED AND MENU]
---
--- Returns whether the current OS is OSX.
---
---@return boolean is_osx Whether or not the game is running on OSX.
function system.IsOSX() end

--- [CLIENT AND MENU]
---
--- Returns whether the game is being run in a window or in fullscreen (you can change this by opening the menu, clicking 'Options', then clicking the 'Video' tab, and changing the Display Mode using the dropdown menu).
---
---@return boolean is_windowed `true` if the game is currently running windowed, `false` if it is fullscreen.
function system.IsWindowed() end

--- [SHARED AND MENU]
---
--- Returns whether the current OS is Windows.
---
---@return boolean is_windows Whether the system the game runs on is Windows or not.
function system.IsWindows() end

--- [SHARED AND MENU]
---
--- Returns the synchronized Steam time. This is the number of seconds since the [Unix epoch](https://en.wikipedia.org/wiki/Unix_time).
---
--- > **NOTE**: This function does not work on Dedicated Servers and will instead return no value.
---
---@return number steam_time Current Steam-synchronized Unix time.
function system.SteamTime() end

--- [SHARED AND MENU]
---
--- Returns the amount of seconds since the Steam user last moved their mouse.
---
--- This is a direct binding to `ISteamUtils->GetSecondsSinceComputerActive`, and is most likely related to Steam's automatic "Away" online status.
---
--- > **NOTE**: This function does not work on Dedicated Servers and will instead return no value.
---
---@return number seconds The amount of seconds since the Steam user last moved their mouse.
function system.UpTime() end
