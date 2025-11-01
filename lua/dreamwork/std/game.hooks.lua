local dreamwork = _G.dreamwork
local std = dreamwork.std

local engine_hookCatch = dreamwork.engine.hookCatch
local Hook = std.Hook

do

    ---@class dreamwork.std.game
    local game = std.game

    if game.Tick == nil then

        --- [SHARED AND MENU]
        ---
        --- A hook that is called every tick.
        local Tick = Hook( "game.Tick" )
        engine_hookCatch( "Tick", Tick, std.LUA_CLIENT_MENU and 2 or 1 )
        game.Tick = Tick

    end

    if game.ShutDown == nil then

        --- [SHARED]
        ---
        --- A hook that is called when the game is shutting down.
        local ShutDown = Hook( "game.ShutDown" )
        engine_hookCatch( "ShutDown", ShutDown, 2 )
        game.ShutDown = ShutDown

    end

end
