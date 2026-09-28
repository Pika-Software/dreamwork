---@meta dreamwork.std.server


--- [SHARED AND MENU]
---
--- The server information table.
---@class dreamwork.std.server.Info
local ServerInfo = {}

--- The server ping in milliseconds.
---@type number
ServerInfo.ping = 0

--- The server name.
---
--- This value is set on the server by the `hostname` convar.
---@type string
ServerInfo.name = "Garry's Mod"

--- The name of the loaded level on the server.
---
--- BSP: `maps/{name}.bsp`
--- AI navigation: `maps/{name}.ain`
--- Navigation Mesh: `maps/{name}.nav`
---@type string
ServerInfo.level_name = "gm_construct"

--- Contains the version number of GMod.
---@type number
ServerInfo.version = 201211

--- The server address in IP:Port format.
---@type string
ServerInfo.address = "127.0.0.1:27015"

--- Two digit country code in the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) standard.
---
--- This value is set on the server by the [sv_location](https://wiki.facepunch.com/gmod/Downloading_a_Dedicated_Server#locationflag) convar.
---@type string?
ServerInfo.country = nil

--- Time when you last played on this server, as UNIX timestamp or 0.
---@type number
ServerInfo.last_played_time = 0

--- Whether this server has password or not.
---
--- On the server, this value is set by the console variable `sv_password`.
---@type boolean
ServerInfo.has_password = false

--- Is the server signed into an anonymous account?
---
--- The value will be `false` if `+sv_setsteamaccount` is equal to a valid Steam game server token.
---
--- [Steam Game Server Accounts](https://wiki.facepunch.com/gmod/Steam_Game_Server_Accounts)
---@type boolean
ServerInfo.is_anonymous = false

--- The number of players on the server.
---
--- This is a total player count including both real people and bots created by the server.
---@type number
ServerInfo.player_count = 0

--- The maximum number of players on the server.
---
--- This value can be set at server startup using the console variable [`+maxplayers`](https://developer.valvesoftware.com/wiki/Maxplayers).
---@type number
ServerInfo.player_limit = 0

--- The number of bots on the server created by the server itself.
---@type number
ServerInfo.bot_count = 0

--- The number of real people (game clients) on the server.
---@type number
ServerInfo.human_count = 0

--- The [gamemode folder](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefolder) name and the [`GM.Folder`](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodefoldername) value.
---
--- This applies to Garry's gamemodes, they are different from the gamemodes in dreamwork...
---@type string
ServerInfo.gamemode_name = "sandbox"

--- The [`GM.Name`](https://wiki.facepunch.com/gmod/Gamemode_Creation#sharedlua) value.
---
--- This applies to Garry's gamemodes, they are different from the gamemodes in dreamwork...
---@type string
ServerInfo.gamemode_title = "Sandbox"

--- The identifier of the gamemode workshop item in the Steam workshop.
---@type string?
ServerInfo.gamemode_wsid = nil

--- The [category](https://wiki.facepunch.com/gmod/Gamemode_Creation#gamemodetextfile) of the gamemode, ex. `pvp`, `pve`, `rp` or `roleplay`.
---@type string
ServerInfo.gamemode_category = "other"


--- [MENU]
---
--- Queries the servers for it's information.
---@class dreamwork.std.server.QueryData
local QueryData = {}

--- The game directory to get the servers for
---@type string
QueryData.directory = "garrysmod"

--- Type of servers to retrieve. Valid values are `internet`, `favorite`, `history` and `lan`
---@type string
QueryData.type = nil

--- Steam application ID to get the servers for
---@type number
QueryData.appid = 4000

--- Called when a new server is found and queried.
---
--- Function argument(s):
--- * number `ping` - Latency to the server.
--- * string `name` - Name of the server
--- * string `gamemode_title` - "Nice" gamemode name
--- * string `level_name` - Current map
--- * number `player_count` - Total player number ( bot + human )
--- * number `player_limit` - Maximum reported amount of players
--- * number `bot_count` - Amount of bots on the server
--- * boolean `has_password` - Whether this server has password or not
--- * number `last_played_time` - Time when you last played on this server, as UNIX timestamp or 0
--- * string `address` - IP Address of the server
--- * string `gamemode_name` - Gamemode folder name
--- * number `gamemode_wsid` - Gamemode Steam Workshop ID
--- * boolean `is_anonymous` - Is the server signed into an anonymous account?
--- * string `version` - Version number, same format as jit.version_number
--- * string `country` - Two digit country code, `us` if nil
--- * string `gamemode_category` - Category of the gamemode, ex. `pvp`, `pve`, `rp` or `roleplay`
---
--- Function return value(s):
--- * boolean `stop` - Return `false` to stop the query.
---@type fun( ping: number, name: string, gamemode_title: string, level_name: string, player_count: number, player_limit: number, bot_count: number, has_password: boolean, last_played_time: number, address: string, gamemode_name: string, gamemode_wsid: number, is_anonymous: boolean, version: string, country: string, gamemode_category: string ): boolean
QueryData.server_queried = nil

--- Called if the query has failed, called with the servers IP Address
---@type function
QueryData.query_failed = nil

--- Called when the query is finished. No arguments
---@type function
QueryData.finished = nil
