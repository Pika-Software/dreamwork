---@meta _

---@class steam
steam = {}

--- [SHARED AND MENU]
---
--- [Steam Account Type](https://developer.valvesoftware.com/wiki/SteamID#Types_of_Steam_Accounts)
---
---@alias steam.Identifier.type
---| `"Invalid"`
---| `"Individual"`
---| `"Multiseat"`
---| `"GameServer"`
---| `"AnonGameServer"`
---| `"Pending"`
---| `"ContentServer"`
---| `"Clan"`
---| `"Chat"`
---| `"ConsoleUser"`
---| `"AnonUser"

--- [SHARED AND MENU]
---
--- [Steam Account Universe](https://developer.valvesoftware.com/wiki/SteamID#Universes_Available_for_Steam_Accounts)
---
---@alias steam.Identifier.universe
---| `"Invalid"`
---| `"Public"`
---| `"Beta"`
---| `"Internal"`
---| `"Dev"`
---| `"RC"`

--- [SHARED AND MENU]
---
--- The Steam ID object.
---
---@class steam.Identifier : Object
---@field __class steam.IdentifierClass
---@field universe steam.Identifier.universe Indicates the Steam environment (e.g., public, beta).
---@field type steam.Identifier.type Specifies the entity type (e.g., individual user, group, game server).
---@field instance integer Differentiates between multiple instances of the same type within a universe. For individual user accounts, this is typically set to 1, representing the desktop instance.
---@field id integer The unique account number.
---@operator add( integer ): steam.Identifier
---@operator sub( integer ): steam.Identifier
local Identifier = {}

--- [SHARED AND MENU]
---
--- The class used to create new `steam.Identifier` instances.
---
---@class steam.IdentifierClass : steam.Identifier
---@field __base steam.Identifier
---@overload fun( universe?: steam.Identifier.universe, type?: steam.Identifier.type, id?: integer, instance?: integer ): steam.Identifier
local IdentifierClass = {}

steam.Identifier = IdentifierClass

---@protected
function Identifier:__add(int32) end

---@protected
function Identifier:__sub(int32) end

---@protected
function IdentifierClass:__new(universe, type, id, instance) end

--- [SHARED AND MENU]
---
--- Converts a SteamID object to a Steam2 identifier.
---
---@param ignore_universe? boolean
---@return string
function Identifier:toSteam2(ignore_universe) end

--- [SHARED AND MENU]
---
--- Converts a SteamID object to a Steam3 identifier.
---
---@return string steam3_str Steam3 identifier.
function Identifier:toSteam3() end

---@return string
---@protected
function Identifier:__tostring() end

--- [SHARED AND MENU]
---
--- Converts a SteamID object to a 64-bit integer.
---
---@param object steam.Identifier
---@return string uint64_str SteamID as a 64-bit integer
function Identifier.to64(object) end

--- [SHARED AND MENU]
---
--- Gets the URL for a SteamID object.
---
---@param http? boolean If `true`, returns the HTTP URL, otherwise returns the HTTPS URL.
---@return string | nil url_str The URL for the SteamID object.
function Identifier:getURL(http) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid 64-bit identifier.
---
---@param uint64_str string The 64-bit identifier to check.
---@return boolean is_valid `true` if the string is a valid 64-bit identifier, `false` otherwise
---@return nil | string error_message The error message if the string is not a valid 64-bit identifier.
function IdentifierClass.isValid64(uint64_str) end

--- [SHARED AND MENU]
---
--- Creates a new SteamID object from a 64-bit number string.
---
---@param uint64_str string The 64-bit number string.
---@return steam.Identifier
function IdentifierClass.from64(uint64_str) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid Steam2 identifier.
---
---@param steam2_str string The Steam2 identifier to check.
---@return boolean is_valid `true` if the string is a valid Steam2 identifier, `false` otherwise
function IdentifierClass.isValidSteam2(steam2_str) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid Steam3 identifier.
---
---@param steam3_str string The Steam3 identifier to check.
---@return boolean is_valid `true` if the string is a valid Steam3 identifier, `false` otherwise
function IdentifierClass.isValidSteam3(steam3_str) end

--- [SHARED AND MENU]
---
--- Creates a new SteamID object from a steam2 string.
---
---@param steam2_str string The steam2 string to parse.
---@param allow_zero_universe? boolean Whether to allow the universe to be zero.
---@return steam.Identifier object The SteamID object.
function IdentifierClass.fromSteam2(steam2_str, allow_zero_universe) end

--- [SHARED AND MENU]
---
--- Creates a new SteamID object from a steam3 string.
---
---@param steam3_str string The steam3 string to parse.
---@return steam.Identifier object The SteamID object.
function IdentifierClass.fromSteam3(steam3_str) end
