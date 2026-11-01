---@class dreamwork.engine
local dreamwork_engine = dreamwork.engine
if dreamwork_engine.mounts ~= nil then return end

local engine_hook = dreamwork_engine.hook
local hook_call = engine_hook.call

local std = dreamwork.std

local raw = std.raw
local raw_pairs = raw.pairs

local os = std.os
local os_time = os.time

local string = std.string
local string_fnv1a = string.fnv1a
local string_format = string.format


--- [SHARED AND MENU]
---
--- Tracks the games and addons whose content is currently mounted by the engine.
---
--- The state is refreshed on `dreamwork.content.update`, firing `dreamwork.game.mount`
--- and `dreamwork.addon.mount` for every change once the new state is in place.
---
---@class dreamwork.engine.mounts
---@field GameList dreamwork.engine.mounts.GameInfo[] The list of currently mounted games.
---@field GameCount integer The length of the `GameList` array.
---@field GameMap table<integer, dreamwork.engine.mounts.GameInfo> All games the engine can mount content from, by depot (app) ID.
---@field AddonList dreamwork.engine.mounts.AddonInfo[] The list of currently mounted addons.
---@field AddonCount integer The length of the `AddonList` array.
---@field AddonMap table<integer, dreamwork.engine.mounts.AddonInfo> The currently mounted addons, by local addon ID (`laid`).
local mounts = {}
dreamwork_engine.mounts = mounts


---@class garrysmod.engine
local glua_engine = dreamwork_engine.requireLibrary( "engine" )

if glua_engine.GetGames == nil then
    local woops = {}
    function glua_engine.GetGames()
        return woops
    end
end

if glua_engine.GetAddons == nil then
    local woops = {}
    function glua_engine.GetAddons()
        return woops
    end
end

local engine_GetGames = glua_engine.GetGames
local engine_GetAddons = glua_engine.GetAddons

---@type dreamwork.engine.mounts.GameInfo[]
local game_list = {}

---@type integer
local game_count = 0

---@type table<integer, dreamwork.engine.mounts.GameInfo>
local game_map = {}

---@type integer
local game_map_size = 0

---@type table<integer, dreamwork.engine.mounts.GameInfo>
local mounted_games = {}

---@type table<integer, integer>
local game_stamps = {}

---@type dreamwork.engine.mounts.AddonInfo[]
local addon_list = {}

---@type integer
local addon_count = 0

---@type table<integer, dreamwork.engine.mounts.AddonInfo>
local addon_map = {}

---@type table<integer, integer>
local addon_stamps = {}

---@type table<string, integer>
local addon_ids = {}

---@type table<integer, string>
local addon_files = {}

---@type integer
local update_stamp = 0

mounts.GameList, mounts.GameCount, mounts.GameMap = game_list, game_count, game_map
mounts.AddonList, mounts.AddonCount, mounts.AddonMap = addon_list, addon_count, addon_map

---@param addon_file string
---@return integer laid
local function get_addon_id( addon_file )
    local laid = addon_ids[ addon_file ]
    if laid ~= nil then
        return laid
    end

    laid = string_fnv1a( addon_file )

    -- linear probing on (rare) fnv1a collisions
    while addon_files[ laid ] ~= nil do
        laid = (laid + 1) % 0x100000000
    end

    addon_ids[ addon_file ] = laid
    addon_files[ laid ] = addon_file

    return laid
end

engine_hook.catch( "dreamwork.content.update", "dreamwork.content.mount", function()
    local stamp = update_stamp + 1
    update_stamp = stamp

    local timestamp = os_time()

    -- (un)mount events are fired once the public state is fully updated,
    -- buffers are only allocated when something actually changed

    ---@type dreamwork.engine.mounts.GameInfo[] | nil
    local game_changes = nil

    ---@type integer
    local games_changed = 0

    ---@type dreamwork.engine.mounts.AddonInfo[] | nil
    local addon_changes = nil

    ---@type integer
    local addons_changed = 0

    ---@type dreamwork.engine.mounts.GameInfo[]
    local engine_games = engine_GetGames()
    local engine_game_count = #engine_games

    ---@type integer
    local new_game_count = 0

    for i = 1, engine_game_count, 1 do
        local game_info = engine_games[ i ]
        local depot = game_info.depot

        if game_map[ depot ] == nil then
            game_map_size = game_map_size + 1
        end

        game_map[ depot ] = game_info
        game_stamps[ depot ] = stamp

        if game_info.mounted then
            new_game_count = new_game_count + 1
            game_list[ new_game_count ] = game_info
            game_info.index = new_game_count

            local previous_info = mounted_games[ depot ]
            if previous_info == nil then
                game_info.mount_time = timestamp

                if game_changes == nil then
                    game_changes = {}
                end

                games_changed = games_changed + 1
                game_changes[ games_changed ] = game_info
            else
                game_info.mount_time = previous_info.mount_time
            end

            mounted_games[ depot ] = game_info
        end
    end

    -- some of the previously mounted games are gone
    if game_count > new_game_count - games_changed then
        for depot, game_info in raw_pairs( mounted_games ) do
            if game_stamps[ depot ] ~= stamp or not game_map[ depot ].mounted then
                mounted_games[ depot ] = nil
                game_info.mounted = false

                if game_changes == nil then
                    game_changes = {}
                end

                games_changed = games_changed + 1
                game_changes[ games_changed ] = game_info
            end
        end
    end

    -- some of the supported games are gone
    if game_map_size > engine_game_count then
        for depot in raw_pairs( game_map ) do
            if game_stamps[ depot ] ~= stamp then
                game_map[ depot ] = nil
                game_stamps[ depot ] = nil
                game_map_size = game_map_size - 1
            end
        end
    end

    for i = new_game_count + 1, game_count, 1 do
        game_list[ i ] = nil
    end

    game_count = new_game_count
    mounts.GameCount = new_game_count

    ---@type dreamwork.engine.mounts.AddonInfo[]
    local engine_addons = engine_GetAddons()

    ---@type integer
    local new_addon_count = 0

    for i = 1, #engine_addons, 1 do
        local addon_info = engine_addons[ i ]

        if addon_info.mounted then
            local laid = get_addon_id( addon_info.file )

            new_addon_count = new_addon_count + 1
            addon_list[ new_addon_count ] = addon_info
            addon_info.index = new_addon_count
            addon_info.laid = laid

            addon_stamps[ laid ] = stamp

            local previous_info = addon_map[ laid ]
            if previous_info == nil then
                addon_info.folder = string_format( "gma_%08x", laid )
                addon_info.mount_time = timestamp

                if addon_changes == nil then
                    addon_changes = {}
                end

                addons_changed = addons_changed + 1
                addon_changes[ addons_changed ] = addon_info
            else
                addon_info.folder = previous_info.folder
                addon_info.mount_time = previous_info.mount_time
            end

            addon_map[ laid ] = addon_info
        end
    end

    -- some of the previously mounted addons are gone
    if addon_count > new_addon_count - addons_changed then
        for laid, addon_info in raw_pairs( addon_map ) do
            if addon_stamps[ laid ] ~= stamp then
                addon_map[ laid ] = nil
                addon_stamps[ laid ] = nil
                addon_info.mounted = false

                if addon_changes == nil then
                    addon_changes = {}
                end

                addons_changed = addons_changed + 1
                addon_changes[ addons_changed ] = addon_info
            end
        end
    end

    for i = new_addon_count + 1, addon_count, 1 do
        addon_list[ i ] = nil
    end

    addon_count = new_addon_count
    mounts.AddonCount = new_addon_count

    if game_changes ~= nil then
        for i = 1, games_changed, 1 do
            local game_info = game_changes[ i ]
            hook_call( "dreamwork.game.mount", game_info, game_info.mounted )
        end
    end

    if addon_changes ~= nil then
        for i = 1, addons_changed, 1 do
            local addon_info = addon_changes[ i ]
            hook_call( "dreamwork.addon.mount", addon_info, addon_info.mounted )
        end
    end

    return games_changed, addons_changed
end, 1 )
