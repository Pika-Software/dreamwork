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

--- [MENU]
---
--- Opens a folder with the given name in the garrysmod folder using the operating system's file browser.
---
---@param folder_path string The path of the folder, relative to the `garrysmod/` folder.
function OpenFolder( folder_path ) end
