local std = dreamwork.std

local math = std.math
local math_floor = math.floor

local raw = std.raw
local raw_tonumber = raw.tonumber

local rbit = raw.bit
local rbit_band = rbit.band

local string = std.string
local string_byte = string.byte
local string_match = string.match
local string_format = string.format

local table = std.table

local ascii = std.ascii
local ascii_isDigit = ascii.isDigit

local class = std.class

local error = std.error
local isNumber = std.isNumber
local setmetatable = std.setmetatable

local ValueError = std.ValueError


---@class dreamwork.std.steam
local steam = std.steam

---@type table<dreamwork.std.steam.IdentifierType, integer>
local type2int = {
    Invalid = 0,
    Individual = 1,
    Multiseat = 2,
    GameServer = 3,
    AnonGameServer = 4,
    Pending = 5,
    ContentServer = 6,
    Clan = 7,
    Chat = 8,
    ConsoleUser = 9,
    AnonUser = 10
}

---@type table<dreamwork.std.steam.IdentifierUniverse, integer>
local universe2int = {
    Invalid = 0,
    Public = 1,
    Beta = 2,
    Internal = 3,
    Dev = 4,
    RC = 5
}

local int2universe = table.flipped( universe2int )
local int2type = table.flipped( type2int )

---@type table<string, integer>
local letter2int = {
    I = 0,
    U = 1,
    M = 2,
    G = 3,
    A = 4,
    P = 5,
    C = 6,
    g = 7,
    T = 8,
    L = 8,
    c = 8,
    i = 9,
    a = 10
}

local int2letter = table.flipped( letter2int )
int2letter[ 8 ] = "T"

local TYPE_INDIVIDUAL = 1
local TYPE_GAME_SERVER = 3
local TYPE_ANON_GAME_SERVER = 4
local TYPE_CLAN = 7
local TYPE_CHAT = 8

local UNIVERSE_PUBLIC = 1

--- The `Chat` instance flag of clan chats, rendered as `c` in Steam3.
local INSTANCE_FLAG_CLAN = 0x80000

--- The `Chat` instance flag of lobbies, rendered as `L` in Steam3.
local INSTANCE_FLAG_LOBBY = 0x40000

--- The default instance of `Individual` accounts (desktop).
local INSTANCE_DESKTOP = 1

--- `STEAM_X:Y:Z`, the prefix is case-insensitive like in the Source engine.
local STEAM2_PATTERN = "^[Ss][Tt][Ee][Aa][Mm]_(%d+):([01]):(%d+)$"

--- Packs universe, type and instance into the upper 32 bits of a SteamID64.
---
--- Arithmetic instead of `bit` keeps universes above `127` unsigned.
---
---@param universe integer The 8-bit universe.
---@param account_type integer The 4-bit account type.
---@param instance integer The 20-bit instance.
---@return integer high `universe << 24 | account_type << 20 | instance`.
local function pack( universe, account_type, instance )
    return universe * 0x1000000 + account_type * 0x100000 + instance
end

--- Extracts the 8-bit universe from the upper 32 bits of a SteamID64.
---
---@param high integer
---@return integer universe
local function unpackUniverse( high )
    return math_floor( high / 0x1000000 )
end

--- Extracts the 4-bit account type from the upper 32 bits of a SteamID64.
---
---@param high integer
---@return integer account_type
local function unpackType( high )
    return math_floor( high / 0x100000 ) % 0x10
end

--- Returns the instance used when none is given, `1` (desktop) for `Individual`, `0` otherwise.
---
---@param account_type integer
---@return integer instance
local function defaultInstance( account_type )
    return account_type == TYPE_INDIVIDUAL and INSTANCE_DESKTOP or 0
end

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
---@class dreamwork.std.steam.Identifier : dreamwork.std.Object
---@field __class dreamwork.std.steam.IdentifierClass
---@field high integer The upper 32 bits of the SteamID64, `universe << 24 | type << 20 | instance`, read-only.
---@field id integer The unique account number (the lower 32 bits of the SteamID64, also known as `AccountID`), read-only.
---@field package uint64_str string | nil The cached result of `to64`.
---@operator add( integer ): dreamwork.std.steam.Identifier
---@operator sub( integer ): dreamwork.std.steam.Identifier
local Identifier = class.base( "Identifier" )

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
---@class dreamwork.std.steam.IdentifierClass : dreamwork.std.steam.Identifier, dreamwork.std.Class
---@field __base dreamwork.std.steam.Identifier
---@overload fun( universe: dreamwork.std.steam.IdentifierUniverse?, type: dreamwork.std.steam.IdentifierType?, id: integer?, instance: integer? ): dreamwork.std.steam.Identifier
local IdentifierClass = class.create( Identifier )
steam.Identifier = IdentifierClass

--- Creates an identifier from the raw halves of the SteamID64, without validation.
---
---@param high integer The upper 32 bits, see `pack`.
---@param id integer The account number, the lower 32 bits.
---@return dreamwork.std.steam.Identifier
local function create( high, id )
    return setmetatable( {
        high = high,
        id = id
    }, Identifier )
end

---@param universe dreamwork.std.steam.IdentifierUniverse? The universe, `Public` by default.
---@param account_type dreamwork.std.steam.IdentifierType? The account type, `Individual` by default.
---@param id integer? The 32-bit account number, `0` by default.
---@param instance integer? The 20-bit instance, `1` for `Individual` accounts and `0` for the rest by default.
---@return dreamwork.std.steam.Identifier
---@protected
function IdentifierClass:__new( universe, account_type, id, instance )
    local type_int = type2int[ account_type or "Individual" ] or 0
    return create( pack( universe2int[ universe or "Public" ] or 0, type_int, instance or defaultInstance( type_int ) ), id or 0 )
end

--- [SHARED AND MENU]
---
--- The all-zero Steam ID, `Invalid` universe and type with account number `0`.
---
--- Also returned by `parse` for the placeholder strings of the Source engine (`BOT`, `STEAM_ID_PENDING`, ...).
---
local INVALID = create( 0, 0 )
IdentifierClass.INVALID = INVALID

--- [SHARED AND MENU]
---
--- Returns the universe of the Steam ID, the Steam environment the account belongs to (e.g. `Public`, `Beta`).
---
---@return dreamwork.std.steam.IdentifierUniverse universe The universe, `Invalid` if the packed value is unknown.
---@nodiscard
function Identifier:getUniverse()
    return int2universe[ unpackUniverse( self.high ) ] or "Invalid"
end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given universe, the account type, instance and account number are kept.
---
---@param universe dreamwork.std.steam.IdentifierUniverse The universe, unknown names are stored as `Invalid`.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withUniverse( universe )
    local high = self.high
    return create( pack( universe2int[ universe ] or 0, unpackType( high ), high % 0x100000 ), self.id )
end

--- [SHARED AND MENU]
---
--- Returns the account type of the Steam ID (e.g. `Individual` user, `Clan` group, `GameServer`).
---
---@return dreamwork.std.steam.IdentifierType account_type The account type, `Invalid` if the packed value is unknown.
---@nodiscard
function Identifier:getType()
    return int2type[ unpackType( self.high ) ] or "Invalid"
end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given account type, the universe, instance and account number are kept.
---
--- The instance is not reset, use `withInstance` when switching to or from `Individual` or `Chat`.
---
---@param account_type dreamwork.std.steam.IdentifierType The account type, unknown names are stored as `Invalid`.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withType( account_type )
    local high = self.high
    return create( pack( unpackUniverse( high ), type2int[ account_type ] or 0, high % 0x100000 ), self.id )
end

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
function Identifier:getInstance()
    return self.high % 0x100000
end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given instance, the universe, account type and account number are kept.
---
---@param instance integer The 20-bit instance, wrapped to 20 bits.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withInstance( instance )
    local high = self.high
    return create( (high - high % 0x100000) + instance % 0x100000, self.id )
end

--- [SHARED AND MENU]
---
--- Returns a Steam ID with the given account number, the universe, account type and instance are kept.
---
---@param account_id integer The 32-bit account number, wrapped to 32 bits.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function Identifier:withAccountID( account_id )
    return create( self.high, account_id % 0x100000000 )
end

--- Offsets the account number, wrapping around 32 bits, the other fields are kept.
---
--- Works for both `identifier + number` and `number + identifier`.
---
---@param a dreamwork.std.steam.Identifier | integer
---@param b dreamwork.std.steam.Identifier | integer
---@return dreamwork.std.steam.Identifier
---@protected
function Identifier.__add( a, b )
    -- `number + identifier`
    if isNumber( a ) then
        a, b = b, a
    end

    return create( a.high, (a.id + b) % 0x100000000 )
end

--- Offsets the account number backwards, wrapping around 32 bits, the other fields are kept.
---
--- Only `identifier - number` is supported, `number - identifier` raises an error.
---
---@param int32 integer The offset.
---@return dreamwork.std.steam.Identifier
---@protected
function Identifier:__sub( int32 )
    if isNumber( self ) then
        error( "attempt to subtract an identifier from a number, only `identifier - number` is supported", 2 )
    end

    return create( self.high, (self.id - int32) % 0x100000000 )
end

--- Compares all SteamID64 fields, so the same account in different instances is not equal.
---
---@param a dreamwork.std.steam.Identifier
---@param b dreamwork.std.steam.Identifier
---@return boolean
---@protected
function Identifier.__eq( a, b )
    return a.id == b.id and a.high == b.high
end

--- Compares as SteamID64 numbers, also used for `<=` and `table.sort`.
---
---@param a dreamwork.std.steam.Identifier
---@param b dreamwork.std.steam.Identifier
---@return boolean
---@protected
function Identifier.__lt( a, b )
    local a_high, b_high = a.high, b.high
    if a_high == b_high then
        return a.id < b.id
    end

    return a_high < b_high
end

--- [SHARED AND MENU]
---
--- Checks if both Steam IDs belong to the same account, ignoring the instance.
---
--- Unlike `==`, a desktop Steam ID matches the web or console instance of the same user.
---
---@param other dreamwork.std.steam.Identifier The Steam ID to compare with.
---@return boolean is_same `true` if universe, account type and account number match, `false` otherwise.
---@nodiscard
function Identifier:isSameAccount( other )
    local a_high, b_high = self.high, other.high
    return self.id == other.id and (a_high - a_high % 0x100000) == (b_high - b_high % 0x100000)
end

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
function Identifier:isValid()
    local high = self.high

    local universe = unpackUniverse( high )
    if universe == 0 or int2universe[ universe ] == nil then
        return false
    end

    local account_type = unpackType( high )
    if account_type == 0 or int2type[ account_type ] == nil then
        return false
    elseif account_type == TYPE_INDIVIDUAL or account_type == TYPE_CLAN then
        return self.id ~= 0
    end

    return true
end

Identifier.__isvalid = Identifier.isValid

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is an `Individual` user account.
---
---@return boolean is_individual
---@nodiscard
function Identifier:isIndividual()
    return unpackType( self.high ) == TYPE_INDIVIDUAL
end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `Clan` (Steam group) account.
---
---@return boolean is_clan
---@nodiscard
function Identifier:isClan()
    return unpackType( self.high ) == TYPE_CLAN
end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `GameServer` or `AnonGameServer` account.
---
---@return boolean is_game_server
---@nodiscard
function Identifier:isGameServer()
    local account_type = unpackType( self.high )
    return account_type == TYPE_GAME_SERVER or account_type == TYPE_ANON_GAME_SERVER
end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a `Chat` account, including clan chats and lobbies.
---
---@return boolean is_chat
---@nodiscard
function Identifier:isChat()
    return unpackType( self.high ) == TYPE_CHAT
end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is the chat of a Steam group, a `Chat` account with the clan flag.
---
---@return boolean is_clan_chat
---@nodiscard
function Identifier:isClanChat()
    local high = self.high
    return unpackType( high ) == TYPE_CHAT and rbit_band( high % 0x100000, INSTANCE_FLAG_CLAN ) ~= 0
end

--- [SHARED AND MENU]
---
--- Checks if the Steam ID is a matchmaking lobby, a `Chat` account with the lobby flag.
---
---@return boolean is_lobby
---@nodiscard
function Identifier:isLobby()
    local high = self.high
    return unpackType( high ) == TYPE_CHAT and rbit_band( high % 0x100000, INSTANCE_FLAG_LOBBY ) ~= 0
end

--- [SHARED AND MENU]
---
--- Returns the chat of a Steam group, `[g:1:N]` becomes `[c:1:N]`.
---
---@return dreamwork.std.steam.Identifier | nil object The clan chat Steam ID, or `nil` if the Steam ID is not a `Clan`.
---@nodiscard
function Identifier:toClanChat()
    local high = self.high
    if unpackType( high ) ~= TYPE_CLAN then
        return nil
    end

    return create( pack( unpackUniverse( high ), TYPE_CHAT, INSTANCE_FLAG_CLAN ), self.id )
end

--- [SHARED AND MENU]
---
--- Returns the Steam group of a clan chat, `[c:1:N]` becomes `[g:1:N]`.
---
---@return dreamwork.std.steam.Identifier | nil object The `Clan` Steam ID, or `nil` if the Steam ID is not a clan chat.
---@nodiscard
function Identifier:toClan()
    if not self:isClanChat() then
        return nil
    end

    return create( pack( unpackUniverse( self.high ), TYPE_CLAN, 0 ), self.id )
end

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
function Identifier:toSteam2( use_universe )
    local high = self.high
    if unpackType( high ) ~= TYPE_INDIVIDUAL then
        return nil
    end

    local id = self.id
    local y = id % 2
    return string_format( "STEAM_%d:%d:%d", use_universe and unpackUniverse( high ) or 0, y, (id - y) * 0.5 )
end

--- [SHARED AND MENU]
---
--- Converts the Steam ID to a Steam3 string, `[letter:universe:id]`, also used by `tostring`.
---
--- The letter is the account type, `c` and `L` for clan chats and lobbies.
---
--- The instance is appended as a fourth field for `AnonGameServer` accounts
--- and `Individual` accounts with a non-desktop instance, e.g. `[U:1:22202:2]`.
---
---@param self dreamwork.std.steam.Identifier
---@return string steam3_str The Steam3 string, e.g. `[U:1:22202]`.
---@nodiscard
local function toSteam3( self )
    local high = self.high
    local account_type, instance = unpackType( high ), high % 0x100000

    local letter = int2letter[ account_type ] or "I"
    if account_type == TYPE_CHAT then
        if rbit_band( instance, INSTANCE_FLAG_CLAN ) ~= 0 then
            letter = "c"
        elseif rbit_band( instance, INSTANCE_FLAG_LOBBY ) ~= 0 then
            letter = "L"
        end
    elseif account_type == TYPE_ANON_GAME_SERVER or (account_type == TYPE_INDIVIDUAL and instance ~= INSTANCE_DESKTOP) then
        return string_format( "[%s:%d:%d:%d]", letter, unpackUniverse( high ), self.id, instance )
    end

    return string_format( "[%s:%d:%d]", letter, unpackUniverse( high ), self.id )
end

Identifier.toSteam3 = toSteam3

---@return string
---@protected
function Identifier:__tostring()
    return toSteam3( self )
end

---@return string
---@protected
function Identifier:__represent()
    return string_format( "Steam Identifier: %p [%s]", self, toSteam3( self ) )
end

--- [SHARED AND MENU]
---
--- Converts the Steam ID to a SteamID64 string, like `Player:SteamID64()`.
---
--- A string, since Lua numbers can't hold 64-bit integers exactly.
--- The result is cached on the object.
---
---@param self dreamwork.std.steam.Identifier
---@return string uint64_str The decimal SteamID64, e.g. `76561197960287930`.
---@nodiscard
local function to64( self )
    local uint64_str = self.uint64_str
    if uint64_str ~= nil then
        return uint64_str
    end

    -- `( high, low ) / 1e6` twice, every intermediate value stays below 2 ^ 53
    local high = self.high

    local remainder = high % 1e6
    high = (high - remainder) / 1e6

    local temp = remainder * 0x100000000 + self.id
    local chunk1 = temp % 1e6

    temp = high * 0x100000000 + (temp - chunk1) / 1e6

    local chunk2 = temp % 1e6
    temp = (temp - chunk2) / 1e6

    if temp ~= 0 then
        uint64_str = string_format( "%d%06d%06d", temp, chunk2, chunk1 )
    elseif chunk2 ~= 0 then
        uint64_str = string_format( "%d%06d", chunk2, chunk1 )
    else
        uint64_str = string_format( "%d", chunk1 )
    end

    self.uint64_str = uint64_str
    return uint64_str
end

Identifier.to64 = to64

--- Writes the binary SteamID64, 8 little endian bytes like in `.gma` headers.
---
---@param writer dreamwork.std.BinaryWriter The writer to write to.
---@protected
function Identifier:__serialize( writer )
    writer:writeUInt( self.id, 32, true )
    writer:writeUInt( self.high, 32, true )
end

--- Reads the binary SteamID64 written by `__serialize`, overwrites all fields.
---
---@param reader dreamwork.std.BinaryReader The reader to read from.
---@protected
function Identifier:__deserialize( reader )
    self.id = reader:readUInt( 32, true )
    self.high = reader:readUInt( 32, true )
    self.uint64_str = nil
end

---@type table<integer, string>
local type2path = {
    [ TYPE_INDIVIDUAL ] = "profiles",
    [ TYPE_CLAN ] = "gid"
}

---@type table<string, integer>
local path2type = {
    profiles = TYPE_INDIVIDUAL,
    gid = TYPE_CLAN
}

--- [SHARED AND MENU]
---
--- Returns the Steam Community URL of the Steam ID, a profile for `Individual` and a group for `Clan` accounts.
---
---@param http boolean? If `true`, returns the HTTP URL, otherwise returns the HTTPS URL.
---@return string | nil url_str The URL, e.g. `https://steamcommunity.com/profiles/76561197960287930`, or `nil` for other account types.
---@nodiscard
function Identifier:toURL( http )
    local path = type2path[ unpackType( self.high ) ]
    if path == nil then
        return nil
    end

    return (http and "http" or "https") .. "://steamcommunity.com/" .. path .. "/" .. to64( self )
end

--- [SHARED AND MENU]
---
--- Creates a new Steam ID of a `Public` `Individual` desktop account from its account number.
---
---@param account_id integer The 32-bit account number, like `Player:AccountID()`.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function IdentifierClass.fromAccountID( account_id )
    return create( pack( UNIVERSE_PUBLIC, TYPE_INDIVIDUAL, INSTANCE_DESKTOP ), account_id )
end

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
local function isValid64( uint64_str )
    local uint64_str_length = #uint64_str

    if uint64_str_length == 0 or uint64_str_length > 20 then
        return false, "invalid length"
    end

    for i = 1, uint64_str_length, 1 do
        if not ascii_isDigit( string_byte( uint64_str, i, i ) ) then
            return false, "invalid character at position " .. i
        end
    end

    -- same length digit strings compare like numbers
    if uint64_str_length == 20 and uint64_str > "18446744073709551615" then
        return false, "value is out of 64-bit range"
    end

    return true
end

IdentifierClass.isValid64 = isValid64

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a SteamID64 string, like `Player:SteamID64()`.
---
--- The string is not validated, check it with `isValid64` first or use `parse`.
---
---@param uint64_str string The decimal SteamID64, e.g. `76561197960287930`.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
local function from64( uint64_str )
    -- original variant was replaced with a more efficient implementation from Be1zebub: https://github.com/Be1zebub/Small-GLua-Things/blob/master/libs/steamid64-parse.lua
    local high, low = 0, 0

    for i = 1, #uint64_str, 1 do
        local temp = (low * 10) + (string_byte( uint64_str, i, i ) - 0x30)
        high = (high * 10) + math_floor( temp / 0x100000000 )
        low = temp % 0x100000000
    end

    return create( high, low )
end

IdentifierClass.from64 = from64

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
local function isValidSteam2( steam2_str )
    local x, _, z = string_match( steam2_str, STEAM2_PATTERN )
    if x == nil then
        return false, "invalid format, expected `STEAM_X:Y:Z`"
    end

    local universe = raw_tonumber( x, 10 )
    if universe == nil or universe > 255 then -- 2 ^ 8 ( 8 bits )
        return false, "universe is out of 8-bit range"
    end

    local id = raw_tonumber( z, 10 )
    if id == nil or id > 2147483647 then -- 2 ^ 31 - 1 ( 31 bits )
        return false, "account number is out of 31-bit range"
    end

    return true
end

IdentifierClass.isValidSteam2 = isValidSteam2

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
local function isValidSteam3( steam3_str )
    local letter, universe_str, id_str, instance_str = string_match( steam3_str, "^%[(%a):(%d+):(%d+):?(%d*)%]$" )
    if letter == nil then
        return false, "invalid format, expected `[letter:universe:id]`"
    elseif letter2int[ letter ] == nil then
        return false, "unknown account type letter `" .. letter .. "`"
    end

    local universe = raw_tonumber( universe_str, 10 )
    if universe == nil or universe > 255 then -- 2 ^ 8 ( 8 bits )
        return false, "universe is out of 8-bit range"
    end

    local id = raw_tonumber( id_str, 10 )
    if id == nil or id > 4294967295 then -- 2 ^ 32 - 1 ( 32 bits )
        return false, "account number is out of 32-bit range"
    end

    if instance_str ~= "" then
        local instance = raw_tonumber( instance_str, 10 )
        if instance == nil or instance > 1048575 then -- 2 ^ 20 - 1 ( 20 bits )
            return false, "instance is out of 20-bit range"
        end
    end

    return true
end

IdentifierClass.isValidSteam3 = isValidSteam3

--- [SHARED AND MENU]
---
--- Creates a new Steam ID of an `Individual` desktop account from a Steam2 string, like `Player:SteamID()`.
---
--- Only the format is enforced, the universe wraps to 8 bits,
--- check the string with `isValidSteam2` first or use `parse`.
---
---@param steam2_str string The Steam2 string, e.g. `STEAM_0:0:11101`, the `STEAM_` prefix is case-insensitive.
---@param allow_zero_universe boolean? If `true`, `STEAM_0:` stays `Invalid`, otherwise it is treated as `Public` like the Source engine does.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
local function fromSteam2( steam2_str, allow_zero_universe )
    local x, y, z = string_match( steam2_str, STEAM2_PATTERN )
    if x == nil then
        error( ValueError( steam2_str, "invalid Steam2 format, expected `STEAM_X:Y:Z`" ), 2 )
    end

    local universe = raw_tonumber( x, 10 ) % 0x100
    if universe == 0 and not allow_zero_universe then
        universe = UNIVERSE_PUBLIC
    end

    return create( pack( universe, TYPE_INDIVIDUAL, INSTANCE_DESKTOP ), (raw_tonumber( z, 10 ) * 2) + (y == "1" and 1 or 0) )
end

IdentifierClass.fromSteam2 = fromSteam2

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
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
local function fromSteam3( steam3_str )
    local letter, universe, id, instance_str = string_match( steam3_str, "^%[?(%a):(%d+):(%d+):?(%d*)%]?$" )
    if letter == nil then
        error( ValueError( steam3_str, "invalid Steam3 format, expected `[letter:universe:id]`" ), 2 )
    end

    local account_type = letter2int[ letter ] or 0

    ---@type integer
    local instance

    if instance_str ~= "" then
        instance = raw_tonumber( instance_str, 10 ) % 0x100000
    elseif letter == "c" then
        instance = INSTANCE_FLAG_CLAN
    elseif letter == "L" then
        instance = INSTANCE_FLAG_LOBBY
    else
        instance = defaultInstance( account_type )
    end

    return create( pack( raw_tonumber( universe, 10 ) % 0x100, account_type, instance ), raw_tonumber( id, 10 ) % 0x100000000 )
end

IdentifierClass.fromSteam3 = fromSteam3

--- Placeholder strings the Source engine returns instead of a real Steam ID.
---
---@type table<string, boolean>
local placeholders = {
    BOT = true,
    NULL = true,
    UNKNOWN = true,
    STEAM_ID_LAN = true,
    STEAM_ID_PENDING = true
}

--- Parses `http(s)://(www.)steamcommunity.com/profiles/<id64>` and `/gid/<id64>` URLs.
---
---@param url_str string
---@return dreamwork.std.steam.Identifier | nil object
---@return nil | string error_message
local function fromURL( url_str )
    local subdomain, path, uint64_str = string_match( url_str, "^https?://(%w*%.?)steamcommunity%.com/(%a+)/([^/]+)/?$" )
    if subdomain == nil or (subdomain ~= "" and subdomain ~= "www.") then
        return nil, "invalid URL, expected `https://steamcommunity.com/profiles/<SteamID64>`"
    end

    local account_type = path2type[ path ]
    if account_type == nil then
        return nil, "URL is not a `/profiles/` or `/gid/` link, vanity `/id/` URLs need the Steam Web API"
    end

    local is_valid, error_message = isValid64( uint64_str )
    if not is_valid then
        return nil, error_message
    end

    local object = from64( uint64_str )
    if unpackType( object.high ) ~= account_type then
        return nil, "Steam ID type doesn't match the `/" .. path .. "/` URL"
    end

    return object
end

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
---@return dreamwork.std.steam.Identifier | nil object The Steam ID, or `nil` if the string is invalid.
---@return nil | string error_message The reason why the string is invalid, `nil` on success.
---@nodiscard
local function tryParse( str )
    if placeholders[ str ] then
        return INVALID
    end

    local first_byte = string_byte( str, 1, 1 )
    if first_byte == nil then
        return nil, "empty string"
    end

    local is_valid, error_message

    if first_byte == 0x53 --[[ S ]] or first_byte == 0x73 --[[ s ]] then
        is_valid, error_message = isValidSteam2( str )
        if is_valid then
            return fromSteam2( str ), nil
        end
    elseif first_byte == 0x5B --[[ [ ]] then
        is_valid, error_message = isValidSteam3( str )
        if is_valid then
            return fromSteam3( str ), nil
        end
    elseif first_byte == 0x68 --[[ h ]] then
        return fromURL( str )
    else
        is_valid, error_message = isValid64( str )
        if is_valid then
            return from64( str ), nil
        end
    end

    return nil, error_message
end

IdentifierClass.tryParse = tryParse

--- [SHARED AND MENU]
---
--- Creates a new Steam ID from a SteamID64, Steam2, Steam3 or Steam Community URL string,
--- like `tryParse`, but raises a `ValueError` if the string is invalid.
---
---@param str string The string, e.g. `76561197960287930`, `STEAM_0:0:11101`, `[U:1:22202]` or `https://steamcommunity.com/profiles/76561197960287930`.
---@return dreamwork.std.steam.Identifier object The Steam ID.
---@nodiscard
function IdentifierClass.parse( str )
    local object, error_message = tryParse( str )
    if object == nil then
        error( ValueError( str, error_message ), 2 )
    end

    return object
end
