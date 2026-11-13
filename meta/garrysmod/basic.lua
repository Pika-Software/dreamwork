---@meta garrysmod


--- `true` if the code is running in the menu state (menu Lua VM), `false` otherwise.
---
--- The menu state is a separate Lua VM from the client and server ones, so `CLIENT` and `SERVER` are both `false` there.
---@type boolean
MENU_DLL = nil

--- `true` if the code is running on the client realm, `false` otherwise.
---@type boolean
CLIENT = nil

--- `true` if the code is running on the server realm, `false` otherwise.
---@type boolean
SERVER = nil

--- The current Garry's Mod version number, e.g. `240101`.
---
--- Can be `nil` on a state where it is not yet available.
---@type integer | nil
VERSION = nil

--- The Garry's Mod branch the game is running on, e.g. `"unknown"`, `"dev"`, `"prerelease"`, `"x86-64"`.
---
--- Can be `nil` on a state where it is not yet available.
---@type string | nil
BRANCH = nil

---@type table | nil
GM = nil

---@type table | nil
GAMEMODE = nil

--- Orthographic projection borders for `CameraData`.
---
--- Each field is the distance of that border from the view position;
--- `left + right` and `top + bottom` should equal 0 to center on the view position.
---
---@class garrysmod.Orthographic
---@field left number Distance of the left border from the view position.
---@field right number Distance of the right border from the view position.
---@field top number Distance of the top border from the view position.
---@field bottom number Distance of the bottom border from the view position.

--- Camera setup structure, used by `cam` and `render` view functions and the `CalcView` hook.
---
---@class garrysmod.CameraData
---@field origin garrysmod.Vector The camera's position.
---@field angles garrysmod.Angle The camera's angles.
---@field fov integer The camera's field of view, in degrees.
---@field znear number Distance to the near clipping plane.
---@field zfar number Distance to the far clipping plane.
---@field drawviewer boolean Set `true` to draw the local player's player model.
---@field ortho garrysmod.Orthographic? If set, enables orthographic mode.

--- Data about a bullet that was fired, passed to the `EntityFireBullets` hook.
---
---@class garrysmod.FiredBullet
---@field AmmoType string The type of ammo that was fired.
---@field Attacker garrysmod.Entity The `Entity` that fired the bullet.
---@field Damage number The amount of damage dealt by the bullet. When `0`, damage is determined by the AmmoData of the bullet's ammo type.
---@field Force number The physics impact force of the bullet.
---@field Tracer integer Frequency of visible bullet tracers: a tracer is fired once after this many non-tracer bullets. Set to `1` to always fire a tracer.
---@field Trace garrysmod.Trace The `TraceResult` structure from the `Trace` that determined where and what the bullet hit.

--- Bullet structure, used by `Entity:FireBullets`.
---
---@class garrysmod.Bullet
---@field Attacker garrysmod.Entity? The entity that fired the bullet, used for damage attribution.
---@field Callback fun(attacker: garrysmod.Entity, trace: garrysmod.Trace, damage: garrysmod.DamageInfo)? Called for each bullet hit; allows modifying the damage info.
---@field Damage number? Damage dealt by each bullet. `0` uses the ammo type's default damage.
---@field Force number? Physics impact force of each bullet.
---@field Distance number? Maximum distance the bullet can travel.
---@field HullSize number? Size of the hull used for the bullet trace; `0` makes it a ray.
---@field Num integer? Number of bullets fired at once (e.g. shotgun pellets). Default `1`.
---@field Tracer integer? Frequency of visible tracers: a tracer is fired once after this many non-tracer bullets. Default `1`.
---@field TracerName string? Effect name of the tracer. Default `"Tracer"`.
---@field AmmoType string? Ammo type name, determines base damage and impact effects.
---@field Src garrysmod.Vector The origin of the bullets.
---@field Dir garrysmod.Vector The direction of the bullets.
---@field Spread garrysmod.Vector? Random spread applied to the bullet direction, per axis.
---@field IgnoreEntity garrysmod.Entity? Entity ignored by the bullet trace.
---@field Filter (garrysmod.Entity | garrysmod.Entity[] | fun(ent: garrysmod.Entity): boolean)? Entities the trace ignores, or a function returning `true` to hit.
---@field Mask integer? Trace mask (`MASK_*`) used for the bullet trace.
---@field DisableLagComp boolean? Set `true` to disable lag compensation for this bullet (server only).


--- [SHARED AND MENU]
---
--- Executes a Lua file and returns whatever the file returns.
---
--- The path is resolved relative to the calling file's folder first, then relative to the `lua/` folder.
---
--- > **NOTE**: On the client, this function tries to load the local client file if `sv_allowcslua` is `1`.
---
---@param file_path string Path to the Lua file, including the `.lua` extension.
---@return any ... Values returned by the executed file.
function include( file_path ) end

--- [SHARED AND MENU]
---
--- Marks a Lua file to be sent to clients when they join the server.
---
--- Does nothing on the client, so it is safe to call from a shared file.
---
---@param file_path string? Path to the Lua file, relative to the `lua/` folder. If omitted, the calling file is sent.
function AddCSLuaFile( file_path ) end

--- [SHARED AND MENU]
---
--- Writes text to the console. Arguments are converted to strings and concatenated, with no separator and no trailing newline.
---
--- Use `\n` to end the line. For colored output, see `MsgC`.
---
---@param ... any Values to print.
function Msg( ... ) end

--- [SHARED AND MENU]
---
--- Writes colored text to the console.
---
--- A `Color` sets the color of the text that follows it, until the next `Color`. Other arguments are converted to strings and printed with no separator and no trailing newline.
---
--- ```lua
--- MsgC( Color( 255, 0, 0 ), "Error: ", color_white, "something broke\n" )
--- ```
---
---@param ... any | garrysmod.Color Colors and values to print.
function MsgC( ... ) end

--- [SHARED AND MENU]
---
--- Returns the current synchronous server uptime in seconds (to at least 4 decimal places).
---
--- This value is affected by various factors such as:
--- - `host_timescale` - engine convar that affects the speed of the game
--- - [game.GetTimeScale](https://wiki.facepunch.com/gmod/game.GetTimeScale)
--- - `sv_pausable` - engine convar that pauses server
--- - if server empty (no players connected) - server will pause and not update time
---
--- You should use this function for timing in-game events but not for real-world events.
---
---@return number server_uptime Time synced with the game server.
function CurTime() end

--- [SHARED AND MENU]
---
--- Returns the current asynchronous server uptime in seconds (to at least 4 decimal places).
---
--- This will not be synced with the players current clock allowing you to get
--- [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)
--- without interference from [Prediction](https://wiki.facepunch.com/gmod/Prediction).
---
---@return number async_server_uptime The asynchronous server uptime in seconds.
function UnPredictedCurTime() end

--- [SHARED AND MENU]
---
--- Returns a highly accurate time in seconds since the start up, ideal for benchmarking. Unlike [Global.RealTime](https://wiki.facepunch.com/gmod/Global.RealTime),
---
--- this value will be updated any time the function is called, allowing for sub-think precision.
---
---@return number engine_uptime Engine uptime in seconds.
function SysTime() end

--- [SHARED AND MENU]
---
--- This function will compile the code argument as lua code and return a function that will execute that code.
---
--- Please note that this function will not automatically execute the given code after compiling it.
---
---@param code string The code to compile.
---@param identifier string An identifier in case an error is thrown.
---@param handleError boolean If `false` this function will return an error string instead of throwing an error.
---@return function | string result
function CompileString( code, identifier, handleError ) end

--- [SHARED AND MENU]
---
--- Writes text to the right hand side of the screen, like the old error system. Messages disappear after a couple of seconds.
---
---@param slot integer The location on the right hand screen to write the debug info to. Starts at 0, no upper limit.
---@param info string The debugging information to be written to the screen.
function DebugInfo( slot, info ) end

--- [SHARED AND MENU]
---
--- Returns whether the given value is a `table`.
---
---@param value any The value to check.
---@return boolean is_table `true` if the value is a table, `false` otherwise.
function istable( value ) end

--- [CLIENT AND MENU]
---
--- Gets the width of the game's window (in pixels).
---
--- > **NOTE**: `ScrW()` returns the width from the current viewport, this can be changed via
--- > [render.SetViewPort](https://wiki.facepunch.com/gmod/render.SetViewPort), inside Render Targets and
--- > `cam.Start` contexts.
---
---@return number width The width of the game's window in pixels.
function ScrW() end

--- [CLIENT AND MENU]
---
--- Gets the height of the game's window (in pixels).
---
--- > **NOTE**: `ScrH()` returns the height from the current viewport, this can be changed via
--- > [render.SetViewPort](https://wiki.facepunch.com/gmod/render.SetViewPort), inside Render Targets and
--- > `cam.Start` contexts.
---
---@return number height The height of the game's window in pixels.
function ScrH() end

--- [CLIENT]
---
--- Returns the player of the local client.
---
---@return garrysmod.Player pl The local player, `NULL` until the player entity is created.
function LocalPlayer() end

--- [SHARED]
---
--- Returns the entity with the given index.
---
---@param index integer The entity index.
---@return garrysmod.Entity entity The entity, `NULL` if it does not exist.
function Entity( index ) end

--- [MENU]
---
--- Opens a folder with the given name in the garrysmod folder using the operating system's file browser.
---
---@param folder_path string The path of the folder, relative to the `garrysmod/` folder.
function OpenFolder( folder_path ) end

--- [MENU]
---
--- Returns the contents of addonpresets.txt located in the garrysmod/settings folder. By default, this file stores your addon presets as JSON.
---
---@see SaveAddonPresets
---
---@return string json_str The contents of the file.
function LoadAddonPresets() end

--- [MENU]
---
--- Sets the content of addonpresets.txt located in the garrysmod/settings folder. By default, this file stores your addon presets as JSON.
---
---@see LoadAddonPresets
---
---@param json_str string The new contents of the file.
function SaveAddonPresets( json_str ) end

--- [MENU]
---
--- Joins the server with the specified IP.
---
---@param ip string The IP of the server to join.
function JoinServer( ip ) end

--- [MENU]
---
--- Returns `true` if the client is currently playing either a singleplayer or multiplayer game.
---
---@return boolean in_game `true` if we are in a game.
function IsInGame() end

--- [MENU]
---
--- Returns `true` when the loading panel is active.
---
---@return boolean in_loading `true` if the loading panel is active.
function IsInLoading() end

--- [CLIENT AND MENU]
---
--- Adds the given string to the computer's clipboard, which can then be pasted in or outside of GMod with Ctrl + V.
---
---@param text string The text to add to the clipboard.
function SetClipboardText( text ) end

--- [MENU]
---
--- Returns the default loading screen URL (`asset://garrysmod/html/loading.html`).
---
---@return string loading_url Default loading URL (`asset://garrysmod/html/loading.html`).
function GetDefaultLoadingHTML() end

--- [MENU]
---
--- Returns the number of files needed from the server you are currently joining.
---
---@return integer count The number of downloadables.
function NumDownloadables() end

--- [MENU]
---
--- Returns a table with the names of files needed from the server you are currently joining.
---
---@return string[] file_names Table of file names.
function GetDownloadables() end

--- [MENU]
---
--- Returns the current status of the server join progress.
---
---@return string status The current status.
function GetLoadStatus() end

--- [MENU]
---
--- Aborts joining of the server you are currently joining.
---
function CancelLoading() end

--- [CLIENT]
---
--- Returns the panel that is used as a wrapper for the HUD. If you want your panel to be hidden when the main menu is opened, parent it to this. Child panels will also have their controls disabled.
---
--- See also [vgui.GetWorldPanel](https://wiki.facepunch.com/gmod/vgui.GetWorldPanel).
---
---@return garrysmod.Panel hud_panel The HUD panel.
function GetHUDPanel() end

--- [MENU]
---
--- Returns the menu overlay panel, a container for panels like the error panel created in [GM:OnLuaError](https://wiki.facepunch.com/gmod/GM:OnLuaError).
---
---@return garrysmod.Panel overlay_panel The overlay panel.
function GetOverlayPanel() end

--- [MENU]
---
--- Retrieves data about the save with the specified filename. Similar to [GetDemoFileDetails](https://wiki.facepunch.com/gmod/Global.GetDemoFileDetails).
---
---@param filename string The file name of the save.
---@return table save_data Save data.
function GetSaveFileDetails( filename ) end

--- A [PhysCollide](https://wiki.facepunch.com/gmod/PhysCollide) holds collision data from VPhysics.
--- These objects can be used to run (currently quite limited) collision tests, but do not represent actual physics objects.
---
--- Created by `CreatePhysCollideBox` or `CreatePhysCollidesFromModel`.
---
---@class garrysmod.PhysCollide : metatable

--- [SHARED]
---
--- Creates a new [PhysCollide](https://wiki.facepunch.com/gmod/PhysCollide) from the given bounds.
---
--- > **BUG**: This fails to create planes or points - no components of the mins or maxs can be the same.
--- > See [issue #3568](https://github.com/Facepunch/garrysmod-issues/issues/3568).
---
---@param mins garrysmod.Vector Min corner of the box. This is not automatically ordered with the maxs and must contain the smallest vector components. See [OrderVectors](https://wiki.facepunch.com/gmod/Global.OrderVectors).
---@param maxs garrysmod.Vector Max corner of the box. This is not automatically ordered with the mins and must contain the largest vector components.
---@return garrysmod.PhysCollide phys_collide The new PhysCollide. This will be a NULL PhysCollide (`PhysCollide:IsValid` returns `false`) if given bad vectors or no more PhysCollides can be created in the physics engine.
function CreatePhysCollideBox( mins, maxs ) end

--- [SHARED]
---
--- Creates [PhysCollide](https://wiki.facepunch.com/gmod/PhysCollide) objects for every physics object the model has. The model must be precached with [util.PrecacheModel](https://wiki.facepunch.com/gmod/util.PrecacheModel) before being used with this function.
---
---@param model_name string Model path to get the collision objects of.
---@return garrysmod.PhysCollide[] | nil phys_collides Table of PhysCollide objects. The number of entries will match the model's physics object count. See also [Entity:GetPhysicsObjectCount](https://wiki.facepunch.com/gmod/Entity:GetPhysicsObjectCount). Returns no value if the model doesn't exist, or has not been precached.
function CreatePhysCollidesFromModel( model_name ) end

--- [MENU]
---
--- Returns if the game was started with either `-noaddons` or `-noworkshop`.
---
---@return boolean noaddons `true` if the game was started with `-noaddons`. See [Command Line Parameters](https://wiki.facepunch.com/gmod/Command_Line_Parameters).
---@return boolean noworkshop `true` if the game was started with `-noworkshop`. See [Command Line Parameters](https://wiki.facepunch.com/gmod/Command_Line_Parameters).
function GetAddonStatus() end

--- [MENU]
---
--- Runs a menu command. Equivalent to `RunConsoleCommand( "gamemenucommand", command )` unless the command starts with the `"engine"` keyword in which case it is equivalent to `RunConsoleCommand( command )`.
---
--- > **WARNING**: Invoking engine commands no longer works, prints out `Not running engine cmd 'concommand'`.
---
--- Should be one of the following:
--- * `Disconnect` - Disconnects from the current server.
--- * `OpenBenchmarkDialog` - Opens the "Video Hardware Stress Test" dialog.
--- * `OpenChangeGameDialog` - Does not work in GMod.
--- * `OpenCreateMultiplayerGameDialog` - Opens the Source dialog for creating a listen server.
--- * `OpenCustomMapsDialog` - Does nothing.
--- * `OpenFriendsDialog` - Does nothing.
--- * `OpenGameMenu` - Does not work in GMod.
--- * `OpenLoadCommentaryDialog` - Opens the "Developer Commentary" selection dialog. Useless in GMod.
--- * `OpenLoadDemoDialog` - Does nothing.
--- * `OpenLoadGameDialog` - Opens the Source "Load Game" dialog.
--- * `OpenNewGameDialog` - Opens the "New Game" dialog. Useless in GMod.
--- * `OpenOptionsDialog` - Opens the options dialog.
--- * `OpenPlayerListDialog` - Opens the "Mute Players" dialog that shows all players connected to the server and allows to mute them.
--- * `OpenSaveGameDialog` - Opens the Source "Save Game" dialog.
--- * `OpenServerBrowser` - Opens the legacy server browser.
--- * `Quit` - Quits the game **without** confirmation (unlike other Source games).
--- * `QuitNoConfirm` - Quits the game without confirmation (like other Source games).
--- * `ResumeGame` - Closes the menu and returns to the game.
--- * `engine 'concommand'` - Runs a console command. Unlike `RunConsoleCommand` it will ignore [Blocked ConCommands](https://wiki.facepunch.com/gmod/Blocked_ConCommands).
---
---@param command string The menu command to run.
function RunGameUICommand( command ) end

--- [SHARED AND MENU]
---
--- Returns the CurTime-based time in seconds it took to render the last frame.
---
--- This should be used for frame/tick based timing, such as movement prediction or animations.
---
--- > **NOTE**: This functions is contextual so in different contexts will return different results.
---
---@return number time (in seconds)
function FrameTime() end

--- Where [PrintMessage](https://wiki.facepunch.com/gmod/Global.PrintMessage) / [Player:PrintMessage](https://wiki.facepunch.com/gmod/Player:PrintMessage) displays the text ([Enums/HUD](https://wiki.facepunch.com/gmod/Enums/HUD)).
---
---@alias garrysmod.PrintMessageType
---| 1 # `HUD_PRINTNOTIFY` — console notify (same destination as console in practice)
---| 2 # `HUD_PRINTCONSOLE` — console only
---| 3 # `HUD_PRINTTALK` — chat (and console)
---| 4 # `HUD_PRINTCENTER` — center of the screen

--- [SHARED]
---
--- Displays a message to every player in chat, console, or the center of the screen.
---
--- On the client, only the local player receives the message.
---
--- > **NOTE**: When called serverside, this uses the archaic user message system ([umsg](https://wiki.facepunch.com/gmod/umsg)) and is limited to ≈250 characters.
--- >
--- > `HUD_PRINTCENTER` will not work when this is called clientside.
---
--- See also [Player:PrintMessage](https://wiki.facepunch.com/gmod/Player:PrintMessage).
---
---@param type garrysmod.PrintMessageType Where to display the message.
---@param message string The message to display.
function PrintMessage( type, message ) end

--- [CLIENT]
---
--- Creates or gets the rendertarget with the given name.
---
--- See `GetRenderTargetEx` for an advanced version of this function with more options.
---
--- Calling this function is equivalent to:
--- ```lua
--- GetRenderTargetEx( name,
--- 	width, height,
--- 	RT_SIZE_NO_CHANGE,
--- 	MATERIAL_RT_DEPTH_SEPARATE,
--- 	bit.bor( 2, 256 ),
--- 	0,
--- 	IMAGE_FORMAT_BGRA8888
--- )
--- ```
---
--- > **BUG**: This crashes when used on a cubemap texture.
--- > See [issue #2885](https://github.com/Facepunch/garrysmod-issues/issues/2885).
---
--- > **WARNING**: Rendertargets are not garbage-collected, which means they will remain in memory until you disconnect. So make sure to avoid creating new ones unnecessarily and re-use as many of your existing rendertargets as possible to avoid filling up all your memory.
---
--- > **WARNING**: Drawing rendertargets on themself can produce odd and unexpected results.
---
---@param name string The internal name of the render target.
---@param width integer The width of the render target, must be power of 2. If not set to PO2, the size will be automatically converted to the nearest PO2 size.
---@param height integer The height of the render target, must be power of 2. If not set to PO2, the size will be automatically converted to the nearest PO2 size.
---@return garrysmod.Texture texture The render target.
function GetRenderTarget( name, width, height ) end

--- [CLIENT]
---
--- Gets (or creates if it does not exist) the rendertarget with the given name. This function allows adjusting the creation of a rendertarget more than `GetRenderTarget`.
---
--- See also [render.PushRenderTarget](https://wiki.facepunch.com/gmod/render.PushRenderTarget) and [render.SetRenderTarget](https://wiki.facepunch.com/gmod/render.SetRenderTarget).
---
--- > **WARNING**: The name is treated like a path and gets its extension discarded. `"name.1"` and `"name.2"` are considered the same name and will result in the same render target being reused.
---
---@param name string The internal name of the render target.
---@param width integer The width of the render target, must be power of 2.
---@param height integer The height of the render target, must be power of 2.
---@param size_mode integer Bitflag that influences the sizing of the render target, see [RT_SIZE](https://wiki.facepunch.com/gmod/Enums/RT_SIZE).
---@param depth_mode integer Bitflag that determines the depth buffer usage of the render target, see [MATERIAL_RT_DEPTH](https://wiki.facepunch.com/gmod/Enums/MATERIAL_RT_DEPTH). PNGs may not render to non-`MATERIAL_RT_DEPTH_NONE` RenderTargets.
---@param texture_flags integer Bitflag that configures the texture, see [TEXTUREFLAGS](https://wiki.facepunch.com/gmod/Enums/TEXTUREFLAGS). List of flags can also be found on the [Valve Texture Format](https://developer.valvesoftware.com/wiki/Valve_Texture_Format) wiki.
---@param rt_flags integer Flags that control the HDR behaviour of the render target, see [CREATERENDERTARGETFLAGS](https://wiki.facepunch.com/gmod/Enums/CREATERENDERTARGETFLAGS).
---@param image_format integer Image format, see [IMAGE_FORMAT](https://wiki.facepunch.com/gmod/Enums/IMAGE_FORMAT). Some additional image formats are accepted, but don't have enums. See [VTF Enumerations](https://developer.valvesoftware.com/wiki/Valve_Texture_Format#VTF_enumerations).
---@return garrysmod.Texture texture The new render target.
function GetRenderTargetEx( name, width, height, size_mode, depth_mode, texture_flags, rt_flags, image_format ) end
