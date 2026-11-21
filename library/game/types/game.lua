---@meta _

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
---@class Game : Object
---@field __class GameClass
---@field id integer The Steam AppID of the game, e.g. `240`. **READ-ONLY**
---@field name string The folder name of the game, e.g. `"cstrike"`, also its search path. **READ-ONLY**
---@field title string The title of the game, e.g. `"Counter-Strike: Source"`. **READ-ONLY**
---@field owned boolean `true` if the game is owned by the player. **READ-ONLY**
---@field installed boolean `true` if the game is installed. **READ-ONLY**
---@field mounted boolean `true` if the content of the game is mounted. **READ-ONLY**
---@field mount_time integer | nil The UNIX timestamp of when the content was mounted, `nil` if it is not mounted. **READ-ONLY**
---@field path string The absolute virtual path of the game content, e.g. `"/cstrike"`, it exists only while the game is mounted. **READ-ONLY**
---@field directory Directory The directory of the game content at `path`. **READ-ONLY**
---@field icon string | nil The material path of the 16x16 game icon, e.g. `"games/16/cstrike.png"`, `nil` if there is no icon. **READ-ONLY**
local __Game = {}

---@class GameClass : Game, Class
---@field __base Game
---@overload fun( game_id: string | integer ): Game
Game = {}

---@param game_id string | integer
---@return Game
---@protected
function Game:__new(game_id) end

---@param key string The field name being read.
---@return any value
---@protected
function __Game:__index(key) end

---@param key string
---@protected
function __Game:__newindex(key) end

---@return string
---@protected
function __Game:__represent() end

---@return boolean is_valid `true` if the game is still supported by the engine, `false` otherwise.
---@protected
function __Game:__isvalid() end

--- [SHARED AND MENU]
---
--- Returns the game with the given folder name or Steam AppID.
---
---@param game_id string | integer The folder name (e.g. `"cstrike"`) or the Steam AppID (e.g. `240`) of the game.
---@return Game | nil game The game, `nil` if it is not supported.
---@nodiscard
function Game.get(game_id) end

--- [SHARED AND MENU]
---
--- Returns all games from which Garry's Mod supports content mounting, sorted by Steam AppID.
---
---@return Game[] games The list of games.
---@return integer game_count The length of the list.
---@nodiscard
function Game.getAll() end

--- [SHARED AND MENU]
---
--- Returns the games whose content is currently mounted, in mount order.
---
---@return Game[] games The list of mounted games.
---@return integer game_count The length of the list.
---@nodiscard
function Game.getMounted() end

--- [SHARED AND MENU]
---
--- Checks whether the content of a game is currently mounted.
---
---@param game_id string | integer | Game The folder name, the Steam AppID or the game object.
---@return boolean is_mounted `true` if the game is mounted, `false` otherwise.
---@nodiscard
function Game.isMounted(game_id) end

--- [MENU]
---
--- Mounts the content of a game, `game.Mount` is called once the engine has mounted it.
---
---@param game_id string | integer | Game The folder name, the Steam AppID or the game object.
function Game.mount(game_id) end

--- [MENU]
---
--- Unmounts the content of a game, `game.Mount` is called once the engine has unmounted it.
---
---@param game_id string | integer | Game The folder name, the Steam AppID or the game object.
function Game.unmount(game_id) end
