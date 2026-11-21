local dreamwork_engine = dreamwork.engine

local engine_mounts = dreamwork_engine.mounts

local mounts_GameMap = engine_mounts.GameMap
local mounts_GameList = engine_mounts.GameList
local mounts_GameFolders = engine_mounts.GameFolders
local mounts_GameCatalog = engine_mounts.GameCatalog

local vfs = dreamwork.vfs
local vfs_isFile = vfs.isFile

---@class dreamwork.std
local std = dreamwork.std

local class = std.class
local class_new = class.new

local raw = std.raw
local raw_index = raw.index
local raw_tostring = raw.tostring

local string = std.string
local string_format = string.format

local error = std.error
local isString = std.isString

local Directory = std.Directory

local LUA_MENU = std.LUA_MENU


--- The folders whose content belongs to another game.
---
---@type table<string, string>
local folder_aliases = {
    episodic = "hl2",
    ep2 = "hl2",
    lostcoast = "hl2"
}

--- The game objects by their Steam AppIDs, the same game gives the same object.
---
---@type table<integer, dreamwork.std.Game>
local objects = {}

--- The Steam AppIDs of game objects.
---
---@type table<dreamwork.std.Game, integer>
local depots = {}

--- The folder names of game objects.
---
---@type table<dreamwork.std.Game, string>
local folders = {}

--- The titles of game objects.
---
---@type table<dreamwork.std.Game, string>
local titles = {}

--- The icon material paths of game objects, `false` if the game has no icon.
---
---@type table<dreamwork.std.Game, string | false>
local icons = {}


--- [SHARED AND MENU]
---
--- A game whose content Garry's Mod can mount, e.g. Counter-Strike: Source.
---
--- Objects are read-only views of the engine state, fields are always up to date,
--- the same game always gives the same object.
---
--- ```lua
--- local css = Game.get( "cstrike" )
--- if css ~= nil and css.mounted then
---     print( css.title, css.directory:search( "*" ) )
--- end
--- ```
---
---@class dreamwork.std.Game : dreamwork.std.Object
---@field __class dreamwork.std.GameClass
---@field id integer The Steam AppID of the game, e.g. `240`. **READ-ONLY**
---@field name string The folder name of the game, e.g. `"cstrike"`, also its search path. **READ-ONLY**
---@field title string The title of the game, e.g. `"Counter-Strike: Source"`. **READ-ONLY**
---@field owned boolean `true` if the game is owned by the player. **READ-ONLY**
---@field installed boolean `true` if the game is installed. **READ-ONLY**
---@field mounted boolean `true` if the content of the game is mounted. **READ-ONLY**
---@field mount_time integer | nil The UNIX timestamp of when the content was mounted, `nil` if it is not mounted. **READ-ONLY**
---@field path string The absolute virtual path of the game content, e.g. `"/cstrike"`, it exists only while the game is mounted. **READ-ONLY**
---@field directory dreamwork.std.Directory The directory of the game content at `path`. **READ-ONLY**
---@field icon string | nil The material path of the 16x16 game icon, e.g. `"games/16/cstrike.png"`, `nil` if there is no icon. **READ-ONLY**
local Game = class.base( "Game", true )

---@class dreamwork.std.GameClass : dreamwork.std.Game, dreamwork.std.Class
---@field __base dreamwork.std.Game
---@overload fun( game_id: string | integer ): dreamwork.std.Game
local GameClass = class.create( Game )
std.Game = GameClass

--- Finds the Steam AppID of a supported game.
---
--- Folder names are not unique (e.g. two `insurgency` games), the mounted one wins, then the lowest AppID.
---
---@param game_id string | integer | dreamwork.std.Game
---@return integer | nil depot
local function find_depot( game_id )
    local depot = depots[ game_id ]
    if depot ~= nil then
        return depot
    end

    if not isString( game_id ) then
        if mounts_GameMap[ game_id ] == nil then
            return nil
        end

        ---@cast game_id integer
        return game_id
    end

    ---@cast game_id string
    local game_info = mounts_GameFolders[ folder_aliases[ game_id ] or game_id ]
    if game_info == nil then
        return nil
    end

    return game_info.depot
end

---@param depot integer
---@return dreamwork.std.Game
local function get_object( depot )
    local object = objects[ depot ]
    if object ~= nil then
        return object
    end

    local game_info = mounts_GameMap[ depot ]
    local folder = game_info.folder

    object = class_new( Game )
    objects[ depot ] = object

    depots[ object ] = depot
    folders[ object ] = folder
    titles[ object ] = game_info.title

    local icon = "games/16/" .. folder .. ".png"
    icons[ object ] = vfs_isFile( "/game/materials/" .. icon ) and icon

    return object
end

---@param game_id string | integer
---@return dreamwork.std.Game
---@protected
function GameClass:__new( game_id )
    local depot = find_depot( game_id )
    if depot == nil then
        error( string_format( "game '%s' is not supported", raw_tostring( game_id ) ), 3 )
    end

    return get_object( depot )
end

---@param key string The field name being read.
---@return any value
---@protected
function Game:__index( key )
    if key == "id" then
        return depots[ self ]
    elseif key == "name" then
        return folders[ self ]
    elseif key == "title" then
        return titles[ self ]
    elseif key == "path" then
        return "/" .. folders[ self ]
    elseif key == "directory" then
        return Directory( "/" .. folders[ self ] )
    elseif key == "icon" then
        return icons[ self ] or nil
    end

    local game_info = mounts_GameMap[ depots[ self ] ]

    if key == "mounted" then
        return game_info ~= nil and game_info.mounted == true
    elseif key == "owned" then
        return game_info ~= nil and game_info.owned == true
    elseif key == "installed" then
        return game_info ~= nil and game_info.installed == true
    elseif key == "mount_time" then
        if game_info ~= nil and game_info.mounted then
            return game_info.mount_time
        end

        return nil
    end

    return raw_index( Game, key )
end

---@param key string
---@protected
function Game:__newindex( key )
    error( string_format( "attempt to modify read-only Game property '%s'", raw_tostring( key ) ), 2 )
end

---@return string
---@protected
function Game:__represent()
    return string_format( "Game: %p [%s (%d)]", self, folders[ self ], depots[ self ] )
end

---@return boolean is_valid `true` if the game is still supported by the engine, `false` otherwise.
---@protected
function Game:__isvalid()
    return mounts_GameMap[ depots[ self ] ] ~= nil
end

--- [SHARED AND MENU]
---
--- Returns the game with the given folder name or Steam AppID.
---
---@param game_id string | integer The folder name (e.g. `"cstrike"`) or the Steam AppID (e.g. `240`) of the game.
---@return dreamwork.std.Game | nil game The game, `nil` if it is not supported.
---@nodiscard
function GameClass.get( game_id )
    local depot = find_depot( game_id )
    if depot == nil then
        return nil
    end

    return get_object( depot )
end

--- [SHARED AND MENU]
---
--- Returns all games from which Garry's Mod supports content mounting, sorted by Steam AppID.
---
---@return dreamwork.std.Game[] games The list of games.
---@return integer game_count The length of the list.
---@nodiscard
function GameClass.getAll()
    local game_count = engine_mounts.GameCatalogCount

    ---@type dreamwork.std.Game[]
    local games = {}

    for i = 1, game_count, 1 do
        games[ i ] = get_object( mounts_GameCatalog[ i ].depot )
    end

    return games, game_count
end

--- [SHARED AND MENU]
---
--- Returns the games whose content is currently mounted, in mount order.
---
---@return dreamwork.std.Game[] games The list of mounted games.
---@return integer game_count The length of the list.
---@nodiscard
function GameClass.getMounted()
    local game_count = engine_mounts.GameCount

    ---@type dreamwork.std.Game[]
    local games = {}

    for i = 1, game_count, 1 do
        games[ i ] = get_object( mounts_GameList[ i ].depot )
    end

    return games, game_count
end

--- [SHARED AND MENU]
---
--- Checks whether the content of a game is currently mounted.
---
---@param game_id string | integer | dreamwork.std.Game The folder name, the Steam AppID or the game object.
---@return boolean is_mounted `true` if the game is mounted, `false` otherwise.
---@nodiscard
function GameClass.isMounted( game_id )
    local game_info = mounts_GameMap[ find_depot( game_id ) or -1 ]
    return game_info ~= nil and game_info.mounted == true
end

if LUA_MENU then

    ---@type fun( app_id: string, mount: boolean )
    ---@diagnostic disable-next-line: undefined-field
    local game_SetMounted = dreamwork_engine.requireLibrary( "game" ).SetMounted

    ---@param game_id string | integer | dreamwork.std.Game
    ---@param mount boolean
    local function set_mounted( game_id, mount )
        local depot = find_depot( game_id )
        if depot == nil then
            error( string_format( "game '%s' is not supported", raw_tostring( game_id ) ), 3 )
        end

        game_SetMounted( raw_tostring( depot ), mount )
    end

    --- [MENU]
    ---
    --- Mounts the content of a game, `game.Mount` is called once the engine has mounted it.
    ---
    ---@param game_id string | integer | dreamwork.std.Game The folder name, the Steam AppID or the game object.
    function GameClass.mount( game_id )
        set_mounted( game_id, true )
    end

    --- [MENU]
    ---
    --- Unmounts the content of a game, `game.Mount` is called once the engine has unmounted it.
    ---
    ---@param game_id string | integer | dreamwork.std.Game The folder name, the Steam AppID or the game object.
    function GameClass.unmount( game_id )
        set_mounted( game_id, false )
    end

end
