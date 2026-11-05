---@meta garrysmod.engine


--- [SHARED AND MENU]
---
--- Information about a game (e.g., Counter-Strike: Source) whose content can be mounted by the engine.
---
---@class garrysmod.engine.GameInfo
---@field depot integer The game's Steam depot (app) ID.
---@field folder string The game's mount folder name.
---@field title string The game's display title.
---@field owned boolean `true` if the user owns the game.
---@field mounted boolean `true` if the game's content is currently mounted.
---@field installed boolean `true` if the game is installed.

--- [SHARED AND MENU]
---
--- Information about a Steam Workshop addon (`.gma`) known to the engine.
---
---@class garrysmod.engine.AddonInfo
---@field downloaded boolean `true` if the addon is downloaded.
---@field size integer The addon's size in bytes.
---@field file string The path to the addon's `.gma` file.
---@field mounted boolean `true` if the addon is currently mounted.
---@field updated integer Time the addon was last updated on the Workshop, as a Unix timestamp.
---@field models integer The number of models in the addon.
---@field title string The addon's display title.
---@field tags string The addon's Workshop tags, comma-separated.
---@field wsid string The addon's Steam Workshop ID.
---@field timeadded integer Time the addon was subscribed to, as a Unix timestamp.

--- [SHARED AND MENU]
---
--- Information about a gamemode installed on the server/client.
---
---@class garrysmod.engine.GamemodeInfo
---@field name string The gamemode's folder name.
---@field title string The gamemode's display title.
---@field menusystem boolean `true` if the gamemode provides a menu system.
---@field workshopid string The gamemode's Steam Workshop ID, empty if none.
---@field maps string The map name patterns the gamemode supports, separated by `|` (e.g. `^gm_| ^gmod_`).

--- [CLIENT AND MENU]
---
--- Information about a piece of user generated content (demo, save or dupe) the player is subscribed to.
---
---@class garrysmod.engine.UserContent
---@field title string The content's title.
---@field type string The content's type (`demo`, `save` or `dupe`).
---@field tags string The content's Workshop tags, comma-separated.
---@field wsid string The content's Steam Workshop ID.
---@field timeadded integer Time the content was subscribed to, as a Unix timestamp.

--- [SHARED AND MENU]
---
--- The engine library provides functions to access various features in the game's engine, most are related to the demo and save systems.
---
---@class garrysmod.engine
engine = {}

--- [SHARED]
---
--- Returns non paused `FrameTime`.
---
---@return number frame_time The frame time in seconds.
function engine.AbsoluteFrameTime() end

--- [SHARED AND MENU]
---
--- Returns the name of the currently running gamemode.
---
---@return string name The active gamemode's name, this is the name of the gamemode's folder.
function engine.ActiveGamemode() end

--- [SERVER]
---
--- Closes the server and completely exits.
---
--- To enable this function for use on your server, add `-allowquit` to your commandline,
--- which will make this function run `quit keep_players` when executed,
--- this also does not forcibly disconnect players.
---
--- This is also available when running in server test mode (launch option `-systemtest`).
--- Server test mode is used internally at Facepunch as part of the build process
--- to make sure that the dedicated servers aren't crashing on startup.
---
---@return boolean is_closing `true` if server is about to shutdown, `false` if neither command line parameter is set.
function engine.CloseServer() end

--- [SHARED AND MENU]
---
--- Returns a list of addons the player have subscribed to on the workshop.
---
--- This list will also include "Floating" `.gma` addons that are mounted by the game,
--- but not the folder addons.
---
---@return garrysmod.engine.AddonInfo[] addons The list of addons.
function engine.GetAddons() end

--- [CLIENT AND MENU]
---
--- When starting playing a demo, `engine.GetDemoPlaybackTick` will be reset
--- and its old value will be added to this function's return value.
---
---@return integer tick The demo playback start tick.
function engine.GetDemoPlaybackStartTick() end

--- [CLIENT AND MENU]
---
--- Current tick of currently loaded demo.
---
--- If not playing a demo, it will return amount of ticks since last demo playback.
---
---@return integer tick The amount of ticks of currently loaded demo.
function engine.GetDemoPlaybackTick() end

--- [CLIENT AND MENU]
---
--- Returns time scale of demo playback.
---
--- If not during demo playback, returns `1`.
---
---@return number time_scale The time scale of demo playback, value of `demo_timescale` console variable.
function engine.GetDemoPlaybackTimeScale() end

--- [CLIENT AND MENU]
---
--- Returns total amount of ticks of currently loaded demo.
---
--- If not playing a demo, returns `0` or the value of last played demo.
---
---@return integer ticks Total amount of ticks of currently loaded demo.
function engine.GetDemoPlaybackTotalTicks() end

--- [SHARED AND MENU]
---
--- Returns a list containing info for all installed gamemodes.
---
---@return garrysmod.engine.GamemodeInfo[] gamemodes The installed gamemodes.
function engine.GetGamemodes() end

--- [SHARED AND MENU]
---
--- Returns a list of all games from which **Garry's Mod** supports mounting content.
---
---@return garrysmod.engine.GameInfo[] games The mountable games.
function engine.GetGames() end

--- [CLIENT AND MENU]
---
--- Returns the UGC (demos, saves and dupes) the player have subscribed to on the workshop.
---
---@return garrysmod.engine.UserContent[] content The subscribed user content.
---@deprecated Used internally for in-game menus, may be merged in the future into `engine.GetAddons`.
function engine.GetUserContent() end

--- [CLIENT AND MENU]
---
--- Returns `true` if we're currently playing a demo.
---
--- You will notice that there's no server-side version of this.
--- That's because there is no server when playing a demo.
--- Demos are both recorded and played back purely clientside.
---
---@return boolean is_playing `true` if the game is currently playing a demo.
function engine.IsPlayingDemo() end

--- [CLIENT AND MENU]
---
--- Returns `true` if the game is currently recording a demo file (`.dem`) using `gm_demo`.
---
---@return boolean is_recording `true` if the game is currently recording a demo.
function engine.IsRecordingDemo() end

--- [SERVER]
---
--- This is a direct binding to the function `engine->LightStyle`.
--- This function allows you to change the default light style of the map -
--- so you can make lighting lighter or darker.
---
--- You'll need to call `render.RedownloadAllLightmaps` clientside to refresh the lightmaps to this new color.
---
--- > NOTE: Calling this function with arguments `0` and `"a"` will cause dynamic lights such as those produced by the Light tool to stop working.
---
---@param lightstyle integer The lightstyle to edit, `0` to `63`. If you want to edit map lighting, you want to set this to `0`.
---@param pattern string The pattern to change the lightstyle to. `a` is the darkest, `z` is the brightest. You can use stuff like `"abcxyz"` to make flashing patterns. The normal brightness for a map is `m`. Values over `z` are allowed, `~` for instance.
function engine.LightStyle( lightstyle, pattern ) end

--- [CLIENT]
---
--- Loads a duplication from the local filesystem.
---
---@param dupe_name string The name of the file, e.g. `"dupes/8b809dd7a1a9a375e75be01cdc12e61f.dupe"`.
---@return { data: string } result The result table, `data` is the compressed dupe data, use `util.JSONToTable` to make it into a format useable by the duplicator tool.
function engine.OpenDupe( dupe_name ) end

--- [CLIENT]
---
--- Returns an estimate of the server's performance.
--- Equivalent to calling `FrameTime` from the server, according to source code.
---
---@return number frame_time The frame time in seconds.
---@return number deviation The server framerate [standard deviation](https://en.wikipedia.org/wiki/Standard_deviation).
function engine.ServerFrameTime() end

--- [MENU]
---
--- Sets the mounting options for mountable content.
---
---@param depot_id string The depot id of the game to mount.
---@param do_mount boolean The mount state, `true` to mount, `false` to unmount.
function engine.SetMounted( depot_id, do_mount ) end

--- [SHARED AND MENU]
---
--- Returns the number of ticks since the game server started.
---
---@return integer ticks The number of ticks since the game server started.
function engine.TickCount() end

--- [SHARED AND MENU]
---
--- Returns the time interval between each game tick in seconds.
---
--- This function is useful for making animations (usually serverside, such as doors rotating)
--- and similar things to be independent of the tickrate in hooks that run at the tick rate,
--- such as `GM:Tick`.
---
--- Clientside you'd want to use `FrameTime` for this purpose in hooks that run every frame.
---
--- The default tickrate is `66.6666`, aka `15` milliseconds interval between each game tick.
--- The tickrate can be adjusted via the `-tickrate` command line option.
---
---@return number interval The number of seconds between each game tick.
function engine.TickInterval() end

--- [CLIENT]
---
--- Returns video recording settings set by `video.Record`. Used by Demo-To-Video feature.
---
---@return table settings The video recording settings, see `VideoData` structure.
function engine.VideoSettings() end

--- [CLIENT]
---
--- Saves a duplication as a file.
---
---@param dupe string The dupe table, encoded by `util.TableToJSON` and compressed by `util.Compress`, a binary string.
---@param jpeg string The dupe icon, created by `render.Capture`, a binary string.
function engine.WriteDupe( dupe, jpeg ) end

--- [CLIENT]
---
--- Stores savedata into the game (can be loaded using the LoadGame menu).
---
---@param save_data string The data generated by `gmsave.SaveMap`, compressed by `util.Compress`, a binary string.
---@param name string The name the save will have.
function engine.WriteSave( save_data, name ) end
