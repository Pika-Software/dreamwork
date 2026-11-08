---@meta _

--- [SHARED AND MENU]
---
--- An error raised when a Steam API call fails.
---
--- `result` is the Steam [EResult](https://partner.steamgames.com/doc/api/steam_api#EResult) code of the failure,
--- `nil` when Steam didn't report one.
---
--- ```lua
--- SteamError( 16 ) -- "Steam EResult 16: Operation timed out"
--- SteamError( 16, "player info request timed out" ) -- "player info request timed out (EResult 16: Operation timed out)"
--- SteamError( nil, "steam is not available" ) -- "steam is not available"
--- SteamError.Messages[ 15 ] -- "Access is denied"
--- ```
---
---@class SteamError : Error
---@field __class SteamErrorClass
---@field __parent Error
---@field message string | nil The reason of the failure.
---@field result integer | nil The Steam `EResult` code, `nil` if Steam didn't report one.
---@field Messages table<integer, string> The `EResult` description lookup table.
local __SteamError = {}

--- [SHARED AND MENU]
---
--- Steam [EResult](https://partner.steamgames.com/doc/api/steam_api#EResult) descriptions.
---
---@type table<integer, string>
__SteamError.Messages = nil

---@param result integer | nil
---@param message string | nil
---@protected
function __SteamError:__init(result, message) end

---@param error_message string | nil
---@return string
---@protected
function __SteamError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `SteamError` instances.
---
---@class SteamErrorClass : SteamError, ErrorClass
---@field __base SteamError
---@field __parent ErrorClass
---@overload fun( result: ( integer | nil ), message: ( string | nil ) ): SteamError
SteamError = {}
