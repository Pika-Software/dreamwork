---@meta garrysmod.usercommand


--- [SHARED]
---
--- A user command is created each time a player sends a movement update to the server, and is used to process the player's input.
---
--- See [CUserCmd](https://wiki.facepunch.com/gmod/CUserCmd).
---
---@class garrysmod.UserCommand : metatable
local UserCommand = {}


--- [SHARED]
---
--- Adds a single key to the active buttons bitflag. See also `CUserCmd:SetButtons`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:AddKey)
---
---@param key integer Key to add, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
function UserCommand:AddKey( key ) end

--- [SHARED]
---
--- Removes all keys from the command.
---
--- > **NOTE**: If you are looking to affect player movement, you may need to use `CUserCmd:ClearMovement` instead of clearing the buttons.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:ClearButtons)
function UserCommand:ClearButtons() end

--- [SHARED]
---
--- Clears the movement from the command.
---
--- See also `CUserCmd:SetForwardMove`, `CUserCmd:SetSideMove` and  `CUserCmd:SetUpMove`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:ClearMovement)
function UserCommand:ClearMovement() end

--- [SHARED]
---
--- Returns an increasing number representing the index of the user cmd.
---
--- > WARNING: The value returned is occasionally `0` inside [GM:CreateMove](https://wiki.facepunch.com/gmod/GM:CreateMove) and [GM:StartCommand](https://wiki.facepunch.com/gmod/GM:StartCommand). It is advised to check for a non-zero value if you wish to get the correct number.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:CommandNumber)
---
---@return integer command_number The command number.
---@nodiscard
function UserCommand:CommandNumber() end

--- [SHARED]
---
--- Returns a bitflag indicating which buttons are pressed.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetButtons)
---
---@return integer buttons Pressed buttons, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
---@nodiscard
function UserCommand:GetButtons() end

--- [SHARED]
---
--- The speed the client wishes to move forward with, negative if the clients wants to move backwards.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetForwardMove)
---
---@return number speed The desired speed
---@nodiscard
function UserCommand:GetForwardMove() end

--- [SHARED]
---
--- Gets the current impulse from the client, usually 0. [See impulses list](https://developer.valvesoftware.com/wiki/Impulse) and some CUserCmd:SetImpulse.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetImpulse)
---
---@return integer impulse The impulse.
---@nodiscard
function UserCommand:GetImpulse() end

--- [SHARED]
---
--- Returns the scroll delta as whole number.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetMouseWheel)
---
---@return number delta Scroll delta
---@nodiscard
function UserCommand:GetMouseWheel() end

--- [SHARED]
---
--- Returns the delta of the angular horizontal mouse movement of the player.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetMouseX)
---
---@return number delta xDelta
---@nodiscard
function UserCommand:GetMouseX() end

--- [SHARED]
---
--- Returns the delta of the angular vertical mouse movement of the player.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetMouseY)
---
---@return number delta yDelta
---@nodiscard
function UserCommand:GetMouseY() end

--- [SHARED]
---
--- The speed the client wishes to move sideways with, positive if it wants to move right, negative if it wants to move left.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetSideMove)
---
---@return number speed requestSpeed
---@nodiscard
function UserCommand:GetSideMove() end

--- [SHARED]
---
--- The speed the client wishes to move up with, negative if the clients wants to move down.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetUpMove)
---
---@return number speed requestSpeed
---@nodiscard
function UserCommand:GetUpMove() end

--- [SHARED]
---
--- Gets the direction the player is looking in.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:GetViewAngles)
---
---@return garrysmod.Angle angles The direction the player is looking in.
---@nodiscard
function UserCommand:GetViewAngles() end

--- [SHARED]
---
--- When players are not sending usercommands to the server (often due to lag), their last usercommand will be executed multiple times as a backup. This function returns true if that is happening.
---
--- This will never return true clientside.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:IsForced)
---
---@return boolean is_forced isForced
---@nodiscard
function UserCommand:IsForced() end

--- [SHARED]
---
--- Returns whether the user command is valid.
---
---@return boolean is_valid `true` if the command is valid.
---@nodiscard
function UserCommand:IsValid() end

--- [SHARED]
---
--- Returns true if the specified button(s) is pressed.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:KeyDown)
---
---@param key integer Bitflag representing which button to check, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
---@return boolean down `true` if the given key/button is down.
---@nodiscard
function UserCommand:KeyDown( key ) end

--- [SHARED]
---
--- Removes a key bit from the current key bitflag.
---
--- For movement you will want to use `CUserCmd:SetForwardMove`, `CUserCmd:SetUpMove` and `CUserCmd:SetSideMove`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:RemoveKey)
---
---@param button integer Bitflag to be removed from the key bitflag, see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
function UserCommand:RemoveKey( button ) end

--- [SHARED]
---
--- Forces the associated player to select a weapon. This is used internally in the default HL2 weapon selection HUD.
---
--- This may not work immediately if the current command is in prediction. Use [input.SelectWeapon](https://wiki.facepunch.com/gmod/input.SelectWeapon) to switch the weapon from the client when the next available command can do so.
---
--- > **NOTE**: This is the ideal function to use to create a custom weapon selection HUD, as it allows prediction to run properly for [WEAPON:Deploy](https://wiki.facepunch.com/gmod/WEAPON:Deploy) and [GM:PlayerSwitchWeapon](https://wiki.facepunch.com/gmod/GM:PlayerSwitchWeapon).
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SelectWeapon)
---
---@param weapon garrysmod.Weapon The weapon entity to select.
function UserCommand:SelectWeapon( weapon ) end

--- [SHARED]
---
--- Sets the buttons as a bitflag. See also `CUserCmd:GetButtons`.
---
--- > **NOTE**: If you are looking to affect player movement, you may need to use `CUserCmd:SetForwardMove` instead of setting the keys.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetButtons)
---
---@param buttons integer Bitflag representing which buttons are "down", see [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
function UserCommand:SetButtons( buttons ) end

--- [SHARED]
---
--- Sets speed the client wishes to move forward with, negative if the clients wants to move backwards.
---
--- See also `CUserCmd:ClearMovement`, `CUserCmd:SetSideMove` and `CUserCmd:SetUpMove`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetForwardMove)
---
---@param speed number The new speed to request. The client will not be able to move faster than their set walk/sprint speed.
function UserCommand:SetForwardMove( speed ) end

--- [SHARED]
---
--- Sets the impulse command to be sent to the server.
---
--- Here are a few examples of impulse numbers:
--- - `100` toggles their flashlight
--- - `101` gives the player all Half-Life 2 weapons with `sv_cheats` set to `1`
--- - `200` toggles holstering / restoring the current weapon
---   When holstered, the `EF_NODRAW` flag is set on the active weapon.
--- - `154` toggles noclip
---
--- [See full list](https://developer.valvesoftware.com/wiki/Impulse)
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetImpulse)
---
---@param impulse integer The impulse to send.
function UserCommand:SetImpulse( impulse ) end

--- [SHARED]
---
--- Sets the scroll delta.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetMouseWheel)
---
---@param speed number The scroll delta.
function UserCommand:SetMouseWheel( speed ) end

--- [SHARED]
---
--- Sets the delta of the angular horizontal mouse movement of the player.
---
--- See also `CUserCmd:SetMouseY`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetMouseX)
---
---@param speed number Angular horizontal move delta.
function UserCommand:SetMouseX( speed ) end

--- [SHARED]
---
--- Sets the delta of the angular vertical mouse movement of the player.
---
--- See also `CUserCmd:SetMouseX`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetMouseY)
---
---@param speed number Angular vertical move delta.
function UserCommand:SetMouseY( speed ) end

--- [SHARED]
---
--- Sets speed the client wishes to move sidewards with, positive to move right, negative to move left.
---
--- See also `CUserCmd:SetForwardMove` and  `CUserCmd:SetUpMove`.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetSideMove)
---
---@param speed number The new speed to request.
function UserCommand:SetSideMove( speed ) end

--- [SHARED]
---
--- Sets speed the client wishes to move upwards with, negative to move down.
---
--- See also `CUserCmd:SetSideMove` and  `CUserCmd:SetForwardMove`.
--- > **NOTE**: This function does **not** move the client up/down ladders. To force ladder movement, consider `CUserCMD:SetButtons` and use IN_FORWARD from [Enums/IN](https://wiki.facepunch.com/gmod/Enums/IN).
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetUpMove)
---
---@param speed number The new speed to request.
function UserCommand:SetUpMove( speed ) end

--- [SHARED]
---
--- Sets the direction the client wants to move in.
---
--- > **NOTE**: For human players, the pitch (vertical) angle should be clamped to +/- 89° to prevent the player's view from glitching.
--- > **NOTE**: For fake clients (those created with `player.CreateNextBot`), this functionally dictates the 'move angles' of the bot. This typically functions separately from the colloquial view angles. This can be utilized by `CUserCmd:SetForwardMove` and its related functions.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:SetViewAngles)
---
---@param view_angles garrysmod.Angle New view angles.
function UserCommand:SetViewAngles( view_angles ) end

--- [SHARED]
---
--- Returns tick count since joining the server.
---
--- > **NOTE**: This will always return 0 for bots.
---
--- > **NOTE**: Returns 0 clientside during prediction calls. If you are trying to use CUserCmd:Set*() on the client in a movement or command hook, keep doing so till TickCount returns a non-zero number to maintain prediction.
---
--- [View wiki](https://wiki.facepunch.com/gmod/CUserCmd:TickCount)
---
---@return integer ticks The amount of ticks passed since joining the server.
---@nodiscard
function UserCommand:TickCount() end
