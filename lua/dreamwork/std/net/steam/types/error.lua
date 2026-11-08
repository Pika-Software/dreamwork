---@class dreamwork.std
local std = dreamwork.std

local string = std.string
local string_format = string.format

local class = std.class

--- [SHARED AND MENU]
---
--- An error raised when a Steam API call fails.
---
--- `result` is the Steam [EResult](https://partner.steamgames.com/doc/api/steam_api#EResult) code of the failure,
--- `nil` when Steam didn't report one.
---
--- ```lua
--- std.SteamError( 16 ) -- "Steam EResult 16: Operation timed out"
--- std.SteamError( 16, "player info request timed out" ) -- "player info request timed out (EResult 16: Operation timed out)"
--- std.SteamError( nil, "steam is not available" ) -- "steam is not available"
--- std.SteamError.Messages[ 15 ] -- "Access is denied"
--- ```
---
---@class dreamwork.std.SteamError : dreamwork.std.Error
---@field __class dreamwork.std.SteamErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The reason of the failure.
---@field result integer | nil The Steam `EResult` code, `nil` if Steam didn't report one.
---@field Messages table<integer, string> The `EResult` description lookup table.
local SteamError = class.base( "SteamError", false, std.Error )

do

    --- [SHARED AND MENU]
    ---
    --- Steam [EResult](https://partner.steamgames.com/doc/api/steam_api#EResult) descriptions.
    ---
    ---@type table<integer, string>
    local result_messages = {
        [ 0 ] = "No result",
        [ 1 ] = "Success",
        [ 2 ] = "Generic failure",
        [ 3 ] = "Your Steam client doesn't have a connection to the back-end",
        [ 5 ] = "Password/ticket is invalid",
        [ 6 ] = "The user is logged in elsewhere",
        [ 7 ] = "Protocol version is incorrect",
        [ 8 ] = "A parameter is incorrect",
        [ 9 ] = "File was not found",
        [ 10 ] = "Called method is busy, action not taken",
        [ 11 ] = "Called object was in an invalid state",
        [ 12 ] = "The name was invalid",
        [ 13 ] = "The email was invalid",
        [ 14 ] = "The name is not unique",
        [ 15 ] = "Access is denied",
        [ 16 ] = "Operation timed out",
        [ 17 ] = "The user is VAC2 banned",
        [ 18 ] = "Account not found",
        [ 19 ] = "The Steam ID was invalid",
        [ 20 ] = "The requested service is currently unavailable",
        [ 21 ] = "The user is not logged on",
        [ 22 ] = "Request is pending, it may be in process or waiting on third party",
        [ 23 ] = "Encryption or decryption failed",
        [ 24 ] = "Insufficient privilege",
        [ 25 ] = "Too much of a good thing",
        [ 26 ] = "Access has been revoked (used for revoked guest passes)",
        [ 27 ] = "License/guest pass the user is trying to access is expired",
        [ 28 ] = "Guest pass has already been redeemed by account, cannot be used again",
        [ 29 ] = "The request is a duplicate and the action has already occurred in the past, ignored this time",
        [ 30 ] = "All the games in this guest pass redemption request are already owned by the user",
        [ 31 ] = "IP address not found",
        [ 32 ] = "Failed to write change to the data store",
        [ 33 ] = "Failed to acquire access lock for this operation",
        [ 34 ] = "The logon session has been replaced",
        [ 35 ] = "Failed to connect",
        [ 36 ] = "The authentication handshake has failed",
        [ 37 ] = "There has been a generic IO failure",
        [ 38 ] = "The remote server has disconnected",
        [ 39 ] = "Failed to find the shopping cart requested",
        [ 40 ] = "A user blocked the action",
        [ 41 ] = "The target is ignoring sender",
        [ 42 ] = "Nothing matching the request found",
        [ 43 ] = "The account is disabled",
        [ 44 ] = "This service is not accepting content changes right now",
        [ 45 ] = "Account doesn't have value, so this feature isn't available",
        [ 46 ] = "Allowed to take this action, but only because requester is admin",
        [ 47 ] = "A version mismatch in content transmitted within the Steam protocol",
        [ 48 ] = "The current CM can't service the user making a request, user should try another",
        [ 49 ] = "You are already logged in elsewhere, this cached credential login has failed",
        [ 50 ] = "The user is logged in elsewhere",
        [ 51 ] = "Long running operation has suspended/paused (e.g. content download)",
        [ 52 ] = "Operation has been canceled, typically by user (e.g. a content download)",
        [ 53 ] = "Operation canceled because data is ill formed or unrecoverable",
        [ 54 ] = "Operation canceled, not enough disk space",
        [ 55 ] = "The remote or IPC call has failed",
        [ 56 ] = "Password could not be verified as it's unset server side",
        [ 57 ] = "External account (PSN, Facebook...) is not linked to a Steam account",
        [ 58 ] = "PSN ticket was invalid",
        [ 59 ] = "External account (PSN, Facebook...) is already linked to some other account",
        [ 60 ] = "The sync cannot resume due to a conflict between the local and remote files",
        [ 61 ] = "The requested new password is not allowed",
        [ 62 ] = "New value is the same as the old one",
        [ 63 ] = "Account login denied due to 2nd factor authentication failure",
        [ 64 ] = "The requested new password is not legal",
        [ 65 ] = "Account login denied due to auth code invalid",
        [ 66 ] = "Account login denied due to 2nd factor auth failure, and no mail has been sent",
        [ 67 ] = "The users hardware does not support Intel's Identity Protection Technology (IPT)",
        [ 68 ] = "Intel's Identity Protection Technology (IPT) has failed to initialize",
        [ 69 ] = "Operation failed due to parental control restrictions for current user",
        [ 70 ] = "Facebook query returned an error",
        [ 71 ] = "Account login denied due to an expired auth code",
        [ 72 ] = "The login failed due to an IP restriction",
        [ 73 ] = "The current users account is currently locked for use",
        [ 74 ] = "The logon failed because the accounts email is not verified",
        [ 75 ] = "There is no URL matching the provided values",
        [ 76 ] = "Bad response due to a parse failure, missing field, etc",
        [ 77 ] = "The user cannot complete the action until they re-enter their password",
        [ 78 ] = "The value entered is outside the acceptable range",
        [ 79 ] = "Something happened that we didn't expect to ever happen",
        [ 80 ] = "The requested service has been configured to be unavailable",
        [ 81 ] = "The files submitted to the CEG server are not valid",
        [ 82 ] = "The device being used is not allowed to perform this action",
        [ 83 ] = "The action could not be complete because it is region restricted",
        [ 84 ] = "Temporary rate limit exceeded, try again later",
        [ 85 ] = "Need two-factor code to login",
        [ 86 ] = "The thing we're trying to access has been deleted",
        [ 87 ] = "Login attempt failed, try to throttle response to possible attacker",
        [ 88 ] = "Two factor authentication (Steam Guard) code is incorrect",
        [ 89 ] = "The activation code for two-factor authentication (Steam Guard) didn't match",
        [ 90 ] = "The current account has been associated with multiple partners",
        [ 91 ] = "The data has not been modified",
        [ 92 ] = "The account does not have a mobile device associated with it",
        [ 93 ] = "The time presented is out of range or tolerance",
        [ 94 ] = "SMS code failure, no match, none pending, etc",
        [ 95 ] = "Too many accounts access this resource",
        [ 96 ] = "Too many changes to this account",
        [ 97 ] = "Too many changes to this phone",
        [ 98 ] = "Cannot refund to payment method, must use wallet",
        [ 99 ] = "Cannot send an email",
        [ 100 ] = "Can't perform operation until payment has settled",
        [ 101 ] = "The user needs to provide a valid captcha",
        [ 102 ] = "A game server login token owned by this token's owner has been banned",
        [ 103 ] = "Game server owner is denied for some other reason such as account locked, community ban, vac ban, missing phone, etc",
        [ 104 ] = "The type of thing we were requested to act on is invalid",
        [ 105 ] = "The IP address has been banned from taking this action",
        [ 106 ] = "This Game Server Login Token (GSLT) has expired from disuse, it can be reset for use",
        [ 107 ] = "User doesn't have enough wallet funds to complete the action",
        [ 108 ] = "There are too many of this thing pending already",
        [ 109 ] = "No site licenses found",
        [ 110 ] = "The WG couldn't send a response because we exceeded max network send size",
        [ 111 ] = "The user is not friends with the target",
        [ 112 ] = "The user is limited",
        [ 113 ] = "The item can't be removed",
        [ 114 ] = "The account has been deleted",
        [ 115 ] = "A license for this already exists, but it's cancelled",
        [ 116 ] = "Access is denied because of a community cooldown (probably from support profile data resets)",
        [ 117 ] = "No launcher was specified, but a launcher was needed to choose correct realm for operation",
        [ 118 ] = "User must agree to China SSA or global SSA before login",
        [ 119 ] = "The specified launcher type is no longer supported",
        [ 120 ] = "The user's realm does not match the realm of the requested resource",
        [ 121 ] = "Signature check did not match",
        [ 122 ] = "Failed to parse input",
        [ 123 ] = "Account does not have a verified phone number",
        [ 124 ] = "The device battery is too low to complete the action",
        [ 125 ] = "The operation requires a charger to be plugged in, which wasn't present",
        [ 126 ] = "Cached credential was invalid, user must reauthenticate",
        [ 127 ] = "The phone number provided is a Voice Over IP number",
        [ 128 ] = "The data being accessed is not supported by this API",
        [ 129 ] = "Reached the maximum size of the family"
    }

    SteamError.Messages = result_messages

    ---@param result integer | nil
    ---@param message string | nil
    ---@protected
    function SteamError:__init( result, message )
        self.result = result
        self.message = message
    end

    ---@param error_message string | nil
    ---@return string
    ---@protected
    function SteamError:__message( error_message )
        local result = self.result
        if result == nil then
            return error_message or "Steam request failed"
        end

        local result_message = result_messages[ result ] or "Unknown result"

        if error_message == nil then
            return string_format( "Steam EResult %d: %s", result, result_message )
        end

        return string_format( "%s (EResult %d: %s)", error_message, result, result_message )
    end

end

--- [SHARED AND MENU]
---
--- The class used to create new `SteamError` instances.
---
---@class dreamwork.std.SteamErrorClass : dreamwork.std.SteamError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.SteamError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( result: ( integer | nil ), message: ( string | nil ) ): dreamwork.std.SteamError
std.SteamError = class.create( SteamError )
