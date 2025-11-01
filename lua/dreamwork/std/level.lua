local _G = _G
local glua_game, glua_engine, glua_util = _G.game, _G.engine, _G.util
local file_Exists = _G.file.Exists
local dreamwork = _G.dreamwork

---@class dreamwork.std
local std = dreamwork.std

local console = std.console
local console_Variable = console.Variable

-- TODO: think about native bsp parsers (maps like objects) like https://github.com/Nak2/NikNaks/tree/main/lua/niknaks/modules

--- [SHARED AND MENU]
---
--- The game-level library.
---
--- BSP: `maps/{name}.bsp`
--- AI navigation: `maps/{name}.ain`
--- Navigation Mesh: `maps/{name}.nav`
---
---@class dreamwork.std.level
---@field name string The name of the current loaded level.
local level = std.level or {}
std.level = level

-- TODO: rewrite this library

do

    local game_GetMap = level.getName or glua_game.GetMap
    level.getName = game_GetMap

    setmetatable( level, {
        __index = function( _, key )
            if key ~= "name" then return end

            local map = game_GetMap()
            if map == nil or map == "" then
                return "unknown"
            end

            level.name = map
            return map
        end
    } )

end


if std.LUA_CLIENT then
    level.getSunInfo = level.getSunInfo or glua_util.GetSunInfo
    level.redownloadLightmaps = level.redownloadLightmaps or _G.render.RedownloadAllLightmaps
end

--- [SHARED AND MENU]
---
--- Checks if a map/level exists.
---
---@param name string The map/level name in maps/*.bsp folder.
---@param gamePath? string An optional argument specifying the search location, as an example for addon searches.
---@return boolean
local function exists( name, gamePath )
    return file_Exists( "maps/" .. name .. ".bsp", gamePath or "GAME" )
end

level.exists = exists

if std.SHARED then

    level.getEntity = level.getEntity or glua_game.GetWorld

    level.cleanup = level.cleanup or glua_game.CleanUpMap
    level.cleanupRagdolls = level.cleanupRagdolls or glua_game.RemoveRagdolls -- idk what to do with this

    level.traceLine = level.traceLine or glua_util.TraceLine
    level.traceHull = level.traceHull or glua_util.TraceHull
    level.traceEntity = level.traceEntity or glua_util.TraceEntityHull

    level.getStartSpot = level.getStartSpot or glua_game.StartSpot
    level.getContents = level.getContents or glua_util.PointContents

    --- [SHARED AND MENU]
    ---
    --- Returns the gravity of the current level.
    ---
    ---@return integer gravity The gravity of the current level.
    function level.getGravity()
        return console_Variable.getNumber( "sv_gravity" )
    end

end

if std.LUA_SERVER then

    level.changeLightStyle = level.changeLightStyle or glua_engine.LightStyle
    level.getCounter = level.getCounter or glua_game.GetGlobalCounter
    level.setCounter = level.setCounter or glua_game.SetGlobalCounter
    level.getVersion = level.getVersion or glua_game.GetMapVersion
    level.getLoadType = level.getLoadType or glua_game.MapLoadType
    level.getState = level.getState or glua_game.GetGlobalState
    level.setState = level.setState or glua_game.SetGlobalState
    level.sendCommand = level.sendCommand or _G.hammer.SendCommand
    level.getNext = level.getNext or glua_game.GetMapNext

    do

        local glua_navmesh = _G.navmesh

        -- T0D0: make a classes
        local navmesh = {
            getEditCursorPosition = glua_navmesh.GetEditCursorPosition,
            getPlayerSpawnName = glua_navmesh.GetPlayerSpawnName,
            setPlayerSpawnName = glua_navmesh.SetPlayerSpawnName,
            clearWalkableSeeds = glua_navmesh.ClearWalkableSeeds,
            addWalkableSeed = glua_navmesh.AddWalkableSeed,
            getGroundHeight = glua_navmesh.GetGroundHeight,
            isGenerating = glua_navmesh.IsGenerating,
            generate = glua_navmesh.BeginGeneration,
            isLoaded = glua_navmesh.IsLoaded,
            reset = glua_navmesh.Reset,
            load = glua_navmesh.Load,
            save = glua_navmesh.Save,
            area = std.setmetatable( {
                getNearest = glua_navmesh.GetNearestNavArea,
                getBlocked = glua_navmesh.GetBlockedAreas,
                getByIndex = glua_navmesh.GetNavAreaByID,
                getByPosition = glua_navmesh.GetNavArea,
                getCount = glua_navmesh.GetNavAreaCount,
                getMarked = glua_navmesh.GetMarkedArea,
                setMarked = glua_navmesh.SetMarkedArea,
                getAll = glua_navmesh.GetAllNavAreas,
                create = glua_navmesh.CreateNavArea,
                findInBox = glua_navmesh.FindInBox,
                find = glua_navmesh.Find,
            }, {
                __index = std.debug.findmetatable( "CNavArea" )
            } ),
            ladder = std.setmetatable( {
                getByIndex = glua_navmesh.GetNavLadderByID,
                getMarked = glua_navmesh.GetMarkedLadder,
                setMarked = glua_navmesh.SetMarkedLadder,
                create = glua_navmesh.CreateNavLadder,
            }, {
                __index = std.debug.findmetatable( "CNavLadder" )
            } )
        }

        --- [SHARED AND MENU]
        ---
        --- Checks if a map/level navmesh exists.
        ---@param name string The map/level name in maps/*.nav folder.
        ---@param gamePath? string An optional argument specifying the search location, as an example for addon searches.
        ---@return boolean
        function navmesh.exists( name, gamePath )
            return file_Exists( "maps/" .. name .. ".nav", gamePath or "GAME" )
        end

        level.navmesh = navmesh

    end

    do

        local command_run = console.Command.run

        --- [SHARED AND MENU]
        ---
        --- It will end the current game, load the specified map and start a new game on it. Players are not kicked from the server.
        ---@param name string
        ---@return boolean isSuccessful
        function level.change( name )
            if exists( name ) then
                command_run( "changelevel", name )
                return true
            else
                return false
            end
        end

    end

    --- [SHARED AND MENU]
    ---
    --- Sets the gravity of the current level.
    ---@param value integer The value to set. Default: 600
    function level.setGravity( value )
        console_Variable.set( "sv_gravity", value )
    end

end

if std.LUA_MENU then

    --- [SHARED AND MENU]
    ---
    ---@class dreamwork.std.level.save
    local save = {}
    level.save = save

    save.getFileDetails = _G.GetSaveFileDetails

    -- TODO: https://wiki.facepunch.com/gmod/engine.WriteSave

end

-- TODO: level.lighting.
-- TODO: https://github.com/thegrb93/StarfallEx/blob/master/lua/starfall/libs_cl/light.lua
-- TODO: https://wiki.facepunch.com/gmod/Global.DynamicLight
-- TODO: https://wiki.facepunch.com/gmod/Global.ProjectedTexture
-- TODO: https://github.com/Nak2/NikNaks/blob/main/lua/niknaks/modules/sh_enums.lua
