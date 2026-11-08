---@meta _

--- [SHARED AND MENU]
---
--- A [Steam ID](https://developer.valvesoftware.com/wiki/SteamID), the identifier of a Steam account.
---
--- Stored as the two 32-bit halves of the SteamID64,
--- use `getUniverse`, `getType` and `getInstance` to read the packed fields.
---
--- Converts between the textual formats:
--- * SteamID64 - `76561197960287930`, see `to64` and `from64`.
--- * Steam2 - `STEAM_0:0:11101`, see `toSteam2` and `fromSteam2`, only for `Individual` accounts.
--- * Steam3 - `[U:1:22202]`, see `toSteam3` and `fromSteam3`, also used by `tostring`.
--- * Community URL - `https://steamcommunity.com/profiles/76561197960287930`, see `getURL` and `parse`.
---
--- Identifiers are compared by value (`==`), so equal Steam IDs can still be different objects,
--- use `to64` as a table key. Methods never modify the object, the `with*` methods return a modified copy.
---
--- Identifiers are ordered like their SteamID64 numbers (`<`, `<=`, `table.sort`),
--- adding or subtracting an integer offsets the account number, wrapping around 32 bits.
---
--- Binary serialization writes the 8 little endian bytes of the SteamID64.
---
---@class steam.Identifier : Object
---@field __class steam.IdentifierClass
---@field high integer The upper 32 bits of the SteamID64, `universe << 24 | type << 20 | instance`, read-only.
---@field id integer The unique account number (the lower 32 bits of the SteamID64, also known as `AccountID`), read-only.
---@field package uint64_str string | nil The cached result of `to64`.
---@operator add( integer ): steam.Identifier
---@operator sub( integer ): steam.Identifier
local Identifier = {}

--- [SHARED AND MENU]
---
--- The class used to create new `steam.Identifier` instances.
---
--- `universe` defaults to `Public`, `type` to `Individual` and `id` to `0`,
--- unknown universe and type names become `Invalid`.
---
--- `instance` defaults to `1` (desktop) for `Individual` accounts and to `0` for the rest.
---
--- Use `parse`, `from64`, `fromSteam2`, `fromSteam3` or `fromAccountID` to create one from an existing ID.
---
---@class steam.IdentifierClass : steam.Identifier, Class
---@field __base steam.Identifier
---@overload fun( universe: steam.IdentifierUniverse?, type: steam.IdentifierType?, id: integer?, instance: integer? ): steam.Identifier
steam.Identifier = {}

---@param universe steam.IdentifierUniverse? The universe, `Public` by default.
---@param account_type steam.IdentifierType? The account type, `Individual` by default.
---@param id integer? The 32-bit account number, `0` by default.
---@param instance integer? The 20-bit instance, `1` for `Individual` accounts and `0` for the rest by default.
---@return steam.Identifier
---@protected
function steam.Identifier:__new(universe, account_type, id, instance) end

--- [SHARED AND MENU]
---
--- The all-zero Steam ID, `Invalid` universe and type with account number `0`.
---
--- Also returned by `parse` for the placeholder strings of the Source engine (`BOT`, `STEAM_ID_PENDING`, ...).
---
steam.Identifier.INVALID = nil

--- [SHARED AND MENU]
---
--- Returns the universe of the Steam ID, the Steam environment the account belongs to (e.g. `Public`, `Beta`).
---
---@return steam.IdentifierUniverse universe The universe, `Invalid` if the packed value is unknown.
---@nodiscard
function Identifier:getUniverse() end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given universe, the account type, instance and account number are kept.
---
---@param universe steam.IdentifierUniverse The universe, unknown names are stored as `Invalid`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withUniverse(universe) end

--- [SHARED AND MENU]
---
--- Returns the account type of the Steam ID (e.g. `Individual` user, `Clan` group, `GameServer`).
---
---@return steam.IdentifierType account_type The account type, `Invalid` if the packed value is unknown.
---@nodiscard
function Identifier:getType() end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given account type, the universe, instance and account number are kept.
---
--- The instance is not reset, use `withInstance` when switching to or from `Individual` or `Chat`.
---
---@param account_type steam.IdentifierType The account type, unknown names are stored as `Invalid`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withType(account_type) end

--- [SHARED AND MENU]
---
--- Returns the instance of the Steam ID.
---
--- Differentiates between multiple instances of the same account,
--- `1` (desktop) for individual user accounts, `0` for most others.
---
--- `Chat` accounts store their flags here, `0x80000` for clan chats and `0x40000` for lobbies.
---
---@return integer instance The 20-bit instance.
---@nodiscard
function Identifier:getInstance() end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given instance, the universe, account type and account number are kept.
---
---@param instance integer The 20-bit instance, wrapped to 20 bits.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withInstance(instance) end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given account number, the universe, account type and instance are kept.
---
---@param account_id integer The 32-bit account number, wrapped to 32 bits.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withAccountID(account_id) end

--- Offsets the account number, wrapping around 32 bits, the other fields are kept.
---
--- Works for both `identifier + number` and `number + identifier`.
---
---@param a steam.Identifier | integer
---@param b steam.Identifier | integer
---@return steam.Identifier
---@protected
function Identifier.__add(a, b) end

--- Offsets the account number backwards, wrapping around 32 bits, the other fields are kept.
---
--- Only `identifier - number` is supported, `number - identifier` raises an error.
---
---@param int32 integer The offset.
---@return steam.Identifier
---@protected
function Identifier:__sub(int32) end

--- Compares all SteamID64 fields, so the same account in different instances is not equal.
---
---@param a steam.Identifier
---@param b steam.Identifier
---@return boolean
---@protected
function Identifier.__eq(a, b) end

--- Compares as SteamID64 numbers, also used for `<=` and `table.sort`.
---
---@param a steam.Identifier
---@param b steam.Identifier
---@return boolean
---@protected
function Identifier.__lt(a, b) end

--- [SHARED AND MENU]
---
--- Checks if both Steam IDs belong to the same account, ignoring the instance.
---
--- Unlike `==`, a desktop Steam ID matches the web or console instance of the same user.
---
---@param other steam.Identifier The Steam ID to compare with.
---@return boolean is_same `true` if universe, account type and account number match, `false` otherwise.
---@nodiscard
function Identifier:isSameAccount(other) end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID could belong to a real account.
---
--- Universe and type must be known and not `Invalid`,
--- `Individual` and `Clan` accounts must also have a non-zero account number.
---
--- The instance is not checked.
---
---@return boolean is_valid `true` if the Steam ID is valid, `false` otherwise.
---@nodiscard
function Identifier:isValid() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is an `Individual` user account.
---
---@return boolean is_individual
---@nodiscard
function Identifier:isIndividual() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `Clan` (Steam group) account.
---
---@return boolean is_clan
---@nodiscard
function Identifier:isClan() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `GameServer` or `AnonGameServer` account.
---
---@return boolean is_game_server
---@nodiscard
function Identifier:isGameServer() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `Chat` account, including clan chats and lobbies.
---
---@return boolean is_chat
---@nodiscard
function Identifier:isChat() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is the chat of a Steam group, a `Chat` account with the clan flag.
---
---@return boolean is_clan_chat
---@nodiscard
function Identifier:isClanChat() end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a matchmaking lobby, a `Chat` account with the lobby flag.
---
---@return boolean is_lobby
---@nodiscard
function Identifier:isLobby() end

--- [SHARED AND MENU]
---
--- Returns the chat of a Steam group, `[g:1:N]` becomes `[c:1:N]`.
---
---@return steam.Identifier | nil object The clan chat Steam ID, or `nil` if the Steam ID is not a `Clan`.
---@nodiscard
function Identifier:toClanChat() end

--- [SHARED AND MENU]
---
--- Returns the Steam group of a clan chat, `[c:1:N]` becomes `[g:1:N]`.
---
---@return steam.Identifier | nil object The `Clan` Steam ID, or `nil` if the Steam ID is not a clan chat.
---@nodiscard
function Identifier:toClan() end

--- [SHARED AND MENU]
---
--- Converts the Steam ID to a Steam2 string, `STEAM_X:Y:Z`, where `Y` is the lowest bit of the account number and `Z` the rest.
---
--- The universe is rendered as `0` by default, like `Player:SteamID()` and the rest of the Source engine.
---
--- Steam2 can only describe `Individual` accounts, the instance is dropped.
---
---@param use_universe boolean? If `true`, the real universe is rendered instead, e.g. `STEAM_1:` for `Public`.
---@return string | nil steam2_str The Steam2 string, e.g. `STEAM_0:0:11101`, or `nil` if the Steam ID is not `Individual`.
---@nodiscard
function Identifier:toSteam2(use_universe) end

--- [SHARED AND MENU]
---
--- Converts the Steam ID to a Steam3 string, `[letter:universe:id]`, also used by `tostring`.
---
--- The letter is the account type, `c` and `L` for clan chats and lobbies.
---
--- The instance is appended as a fourth field for `AnonGameServer` accounts
--- and `Individual` accounts with a non-desktop instance, e.g. `[U:1:22202:2]`.
---
---@param self steam.Identifier
---@return string steam3_str The Steam3 string, e.g. `[U:1:22202]`.
---@nodiscard
function Identifier.toSteam3(self) end

---@return string
---@protected
function Identifier:__tostring() end

---@return string
---@protected
function Identifier:__represent() end

--- [SHARED AND MENU]
---
--- Converts the Steam ID to a SteamID64 string, like `Player:SteamID64()`.
---
--- A string, since Lua numbers can't hold 64-bit integers exactly.
--- The result is cached on the object.
---
---@param self steam.Identifier
---@return string uint64_str The decimal SteamID64, e.g. `76561197960287930`.
---@nodiscard
function Identifier.to64(self) end

--- Writes the binary SteamID64, 8 little endian bytes like in `.gma` headers.
---
---@param writer BinaryWriter The writer to write to.
---@protected
function Identifier:__serialize(writer) end

--- Reads the binary SteamID64 written by `__serialize`, overwrites all fields.
---
---@param reader BinaryReader The reader to read from.
---@protected
function Identifier:__deserialize(reader) end

--- [SHARED AND MENU]
---
--- Returns the Steam Community URL of the Steam ID, a profile for `Individual` and a group for `Clan` accounts.
---
---@param http boolean? If `true`, returns the HTTP URL, otherwise returns the HTTPS URL.
---@return string | nil url_str The URL, e.g. `https://steamcommunity.com/profiles/76561197960287930`, or `nil` for other account types.
---@nodiscard
function Identifier:toURL(http) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID of a `Public` `Individual` desktop account from its account number.
---
---@param account_id integer The 32-bit account number, like `Player:AccountID()`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function steam.Identifier.fromAccountID(account_id) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid SteamID64, 1 to 20 decimal digits within the unsigned 64-bit range.
---
--- Only the format is checked, use `Identifier:isValid` to check the parsed fields.
---
---@param uint64_str string The string to check.
---@return boolean is_valid `true` if the string is a valid SteamID64, `false` otherwise.
---@return nil | string error_message The reason why the string is invalid, `nil` if it is valid.
---@nodiscard
function steam.Identifier.isValid64(uint64_str) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a SteamID64 string, like `Player:SteamID64()`.
---
--- The string is not validated, check it with `isValid64` first or use `parse`.
---
---@param uint64_str string The decimal SteamID64, e.g. `76561197960287930`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function steam.Identifier.from64(uint64_str) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid Steam2 string, `STEAM_X:Y:Z` with an 8-bit universe, `0` or `1` and a 31-bit number.
---
--- The `STEAM_` prefix is case-insensitive.
---
---@param steam2_str string The string to check.
---@return boolean is_valid `true` if the string is a valid Steam2 string, `false` otherwise.
---@return nil | string error_message The reason why the string is invalid, `nil` if it is valid.
---@nodiscard
function steam.Identifier.isValidSteam2(steam2_str) end

--- [SHARED AND MENU]
---
--- Checks if a string is a valid Steam3 string, `[letter:universe:id]` or `[letter:universe:id:instance]`.
---
--- Requires the brackets, a known account type letter, an 8-bit universe,
--- a 32-bit account number and an optional 20-bit instance.
---
---@param steam3_str string The string to check.
---@return boolean is_valid `true` if the string is a valid Steam3 string, `false` otherwise.
---@return nil | string error_message The reason why the string is invalid, `nil` if it is valid.
---@nodiscard
function steam.Identifier.isValidSteam3(steam3_str) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID of an `Individual` desktop account from a Steam2 string, like `Player:SteamID()`.
---
--- Only the format is enforced, the universe wraps to 8 bits,
--- check the string with `isValidSteam2` first or use `parse`.
---
---@param steam2_str string The Steam2 string, e.g. `STEAM_0:0:11101`, the `STEAM_` prefix is case-insensitive.
---@param allow_zero_universe boolean? If `true`, `STEAM_0:` stays `Invalid`, otherwise it is treated as `Public` like the Source engine does.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function steam.Identifier.fromSteam2(steam2_str, allow_zero_universe) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a Steam3 string.
---
--- Brackets are optional, the instance is taken from the optional fourth field (`[A:1:123:456]`),
--- otherwise `c` and `L` chat letters set the clan chat and lobby instance flags
--- and the rest get the default instance of their account type.
---
--- Only the format is enforced, unknown letters become `Invalid` and numbers wrap to their field widths,
--- check the string with `isValidSteam3` first or use `parse`.
---
---@param steam3_str string The Steam3 string, e.g. `[U:1:22202]`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function steam.Identifier.fromSteam3(steam3_str) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a SteamID64, Steam2, Steam3 or Steam Community URL string, detected by its first character.
---
--- The string is fully validated, unlike with `from64`, `fromSteam2` and `fromSteam3`.
--- Steam3 strings must have brackets here, `STEAM_0:` is treated as `Public`.
---
--- Placeholders of the Source engine (`BOT`, `NULL`, `UNKNOWN`, `STEAM_ID_LAN` and `STEAM_ID_PENDING`) return `INVALID`.
---
---@param str string The string, e.g. `76561197960287930`, `STEAM_0:0:11101`, `[U:1:22202]` or `https://steamcommunity.com/profiles/76561197960287930`.
---@return steam.Identifier | nil object The Steam ID, or `nil` if the string is invalid.
---@return nil | string error_message The reason why the string is invalid, `nil` on success.
---@nodiscard
function steam.Identifier.tryParse(str) end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a SteamID64, Steam2, Steam3 or Steam Community URL string,
--- like `tryParse`, but raises a `ValueError` if the string is invalid.
---
---@param str string The string, e.g. `76561197960287930`, `STEAM_0:0:11101`, `[U:1:22202]` or `https://steamcommunity.com/profiles/76561197960287930`.
---@return steam.Identifier object The Steam ID.
---@nodiscard
function steam.Identifier.parse(str) end
