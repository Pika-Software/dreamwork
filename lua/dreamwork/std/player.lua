local _G = _G
local std, glua_game = _G.dreamwork.std, _G.game

local glua_player, NULL, Player = _G.player, _G.NULL, _G.Player
local player_Iterator = glua_player.Iterator

---@class Player
local PLAYER = std.debug.findmetatable( "Player" )

---@class dreamwork.std.player
local player = {
    getLimit = glua_game.MaxPlayers,
    iterator = player_Iterator
}

-- TODO: make player class

-- TODO: bots, alive, dead, all iterator/s

if std.LUA_SERVER then
    -- local PLAYER_IsListenServerHost = PLAYER.IsListenServerHost
    -- local player_CreateNextBot = glua_player.CreateNextBot

    -- function PLAYER.new( value )
    --     if is_string( value ) then
    --         ---@diagnostic disable-next-line: param-type-mismatch
    --         return player_CreateNextBot( value )
    --     elseif is_number( value ) then
    --         ---@diagnostic disable-next-line: param-type-mismatch
    --         return Player( value )
    --     else
    --         for _, ply in player_Iterator() do
    --             if PLAYER_IsListenServerHost( ply ) then
    --                 return ply
    --             end
    --         end

    --         return NULL
    --     end
    -- end
elseif std.LUA_CLIENT then
    -- local LocalPlayer = _G.LocalPlayer

    -- function PLAYER.new( value )
    --     if is_string( value ) then
    --         return std.error( "Client cannot create players.", 2 )
    --     elseif is_number( value ) then
    --         ---@diagnostic disable-next-line: param-type-mismatch
    --         return Player( value )
    --     else
    --         return LocalPlayer()
    --     end
    -- end

    do

        local command_run = std.console.Command.run
        local glua_chat = _G.chat

        ---@class dreamwork.std.player.chat
        local chat = {
            playSound = glua_chat.PlaySound,
            filterText = _G.util.FilterText
        }

        local key2key = {
            getPosition = "GetChatBoxPos",
            getSize = "GetChatBoxSize",
            addText = "AddText",
            close = "Close",
            open = "Open"
        }

        std.setmetatable( chat, {
            __index = function( _, key )
                return glua_chat[ key2key[ key ] or -1 ]
            end
        } )

        --- Sends a message to the player chat.
        ---@param text string The message's content.
        ---@param teamChat boolean? Whether the message should be sent as team chat.
        function chat.say( text, teamChat )
            command_run( teamChat and "say_team" or "say", text )
        end

        player.chat = chat

    end

end

-- TODO: https://wiki.facepunch.com/gmod/team
---@class dreamwork.std.player.team
local team = {}

player.team = team


-- ---@class dreamwork.std.player
-- player = std.class( "player", PLAYER, player )
-- return player

-- TODO: https://wiki.facepunch.com/gmod/Global.Path aka player bot path
