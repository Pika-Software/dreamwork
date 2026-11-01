---@meta garrysmod.weapon


--- [SHARED]
---
--- This is a list of all methods only available for all weapons (scripted and non-scripted). It is also possible to call [Entity](https://wiki.facepunch.com/gmod/Entity) functions on weapons.
---
---@class garrysmod.Weapon : garrysmod.Entity
local Weapon = {}

--- [SHARED]
---
--- Returns whether the weapon allows to being switched from when a better ( [Weapon:GetWeight](https://wiki.facepunch.com/gmod/Weapon:GetWeight) ) weapon is being picked up.
---
---@return boolean allowed Whether the weapon allows to being switched from.
function Weapon:AllowsAutoSwitchFrom() end

--- [SHARED]
---
--- Returns whether the weapon allows to being switched to when a better ([Weapon:GetWeight](https://wiki.facepunch.com/gmod/Weapon:GetWeight)) weapon is being picked up.
---
---@return boolean allowed Whether the weapon allows to being switched to.
function Weapon:AllowsAutoSwitchTo() end

--- [SHARED]
---
--- Calls a SWEP function on client. Does nothing on client.
---
--- > WARNING: This uses the [usermessage](https://wiki.facepunch.com/gmod/usermessage) internally, because of that, the combined length of the arguments of this function may not exceed 254 bytes/characters or the function will cease to function!
---
---@param function_name string Name of function to call. If you want to call `SWEP:MyFunc()` on client, you type in `"MyFunc"`
---@param data string? Custom data to be passed to the target SWEP function as the first argument.
function Weapon:CallOnClient( function_name, data ) end

--- [SHARED]
---
--- Returns how much primary ammo is in the magazine.
---
--- > NOTE: This is not shared between clients and will instead return the maximum primary clip size.
---
---@return integer ammo The amount of primary ammo in the magazine.
function Weapon:Clip1() end

--- [SHARED]
---
--- Returns how much secondary ammo is in the magazine.
---
--- > NOTE: This is not shared between clients and will instead return the maximum secondary clip size.
---
---@return integer ammo The amount of secondary ammo in the magazine.
function Weapon:Clip2() end

--- [SHARED]
---
--- Forces the weapon to reload while playing given animation.
---
--- Ammo will be reloaded after the animation ends, and it will reload both [Weapon:SetClip1](https://wiki.facepunch.com/gmod/Weapon:SetClip1) and [Weapon:SetClip2](https://wiki.facepunch.com/gmod/Weapon:SetClip2) (if used)
---
--- [Primary attack](https://wiki.facepunch.com/gmod/Weapon:SetNextPrimaryFire) and [secondary attack](https://wiki.facepunch.com/gmod/Weapon:SetNextSecondaryFire) will be unavailable for the duration of the reload (or until the weapon is switched away from)
---
--- > NOTE: This will stop the [Weapon:Think](https://wiki.facepunch.com/gmod/Weapon:Think) function from getting called while the weapon is reloading!
---
---@param act integer View model activity (animation) to play. This is usually `ACT_VM_RELOAD`. Uses the [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
---@return boolean success Did reloading actually take place (`true`) or fail (`false`), such as when no reload was necessary.
function Weapon:DefaultReload( act ) end

--- [SHARED]
---
--- Returns the sequence enumeration number that the weapon is playing.
---
--- > BUG: This can return inconsistent results between the server and client.
--- > See [issue #2543](https://github.com/Facepunch/garrysmod-issues/issues/2543).
---
---@return integer activity Current activity, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT). Returns 0 if the weapon doesn't have active sequence.
function Weapon:GetActivity() end

--- [SHARED]
---
--- Returns the weapon deploy speed, as set by [Weapon:SetDeploySpeed](https://wiki.facepunch.com/gmod/Weapon:SetDeploySpeed). If not previously set, the value will be polled from the `sv_defaultdeployspeed` [ConVar](https://wiki.facepunch.com/gmod/ConVar).
---
---@return number speed The deploy speed multiplier.
function Weapon:GetDeploySpeed() end

--- [SHARED]
---
--- Returns the hold type of the weapon.
---
---@return string hold_type The hold type of the weapon. You can find a list of default hold types [here](https://wiki.facepunch.com/gmod/Hold_Types).
function Weapon:GetHoldType() end

--- [SHARED]
---
--- Returns maximum primary clip size
---
---@return integer max_clip Maximum primary clip size
function Weapon:GetMaxClip1() end

--- [SHARED]
---
--- Returns maximum secondary clip size
---
---@return integer max_clip Maximum secondary clip size
function Weapon:GetMaxClip2() end

--- [SHARED]
---
--- Gets the next time the weapon can primary fire. ( Can call [WEAPON:PrimaryAttack](https://wiki.facepunch.com/gmod/WEAPON:PrimaryAttack) )
---
---@return number time The time, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)
function Weapon:GetNextPrimaryFire() end

--- [SHARED]
---
--- Gets the next time the weapon can secondary fire. ( Can call [WEAPON:SecondaryAttack](https://wiki.facepunch.com/gmod/WEAPON:SecondaryAttack) )
---
---@return number time The time, relative to [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime)
function Weapon:GetNextSecondaryFire() end

--- [SHARED]
---
--- Gets the primary ammo type of the given weapon.
---
---@return integer ammo_type The ammo type ID, or -1 if not found.
function Weapon:GetPrimaryAmmoType() end

--- [SHARED]
---
--- Returns the non-internal name of the weapon, that should be for displaying.
---
--- > NOTE: If that returns an untranslated message (#HL2_XX), use [language.GetPhrase](https://wiki.facepunch.com/gmod/language.GetPhrase) to see the "nice" name.
---
--- > NOTE: If SWEP.PrintName is not set in the Weapon or the Weapon Base then "<MISSING SWEP PRINT NAME>" will be returned.
---
---@return string print_name The "nice" name of the weapon.
function Weapon:GetPrintName() end

--- [SHARED]
---
--- Gets the ammo type of the given weapons secondary fire.
---
---@return integer ammo_type The secondary ammo type ID, or -1 if not found.
function Weapon:GetSecondaryAmmoType() end

--- [SHARED]
---
--- Returns the slot of the weapon.
---
--- > NOTE: The slot numbers start from 0.
---
---@return integer slot The slot of the weapon.
function Weapon:GetSlot() end

--- [SHARED]
---
--- Returns slot position of the weapon
---
---@return integer slot_pos The slot position of the weapon
function Weapon:GetSlotPos() end

--- [SHARED]
---
--- Returns the view model of the weapon.
---
---@return string model_path The view model of the weapon.
function Weapon:GetWeaponViewModel() end

--- [SHARED]
---
--- Returns the world model of the weapon.
---
---@return string model_path The world model of the weapon.
function Weapon:GetWeaponWorldModel() end

--- [SHARED]
---
--- Returns the "weight" of the weapon, which is used when deciding which [Weapon](https://wiki.facepunch.com/gmod/Weapon) is better by the engine.
---
---@return integer weight The weapon "weight".
function Weapon:GetWeight() end

--- [SHARED]
---
--- Returns whether the weapon has ammo left or not. It will return false when there's no ammo left in the magazine **and** when there's no reserve ammo left.
---
--- > NOTE: This will return true for weapons like crowbar, gravity gun, etc.
---
---@return boolean has_ammo Whether the weapon has ammo or not.
function Weapon:HasAmmo() end

--- [CLIENT]
---
--- Returns whenever the weapon is carried by the local player.
---
---@return boolean is_carried Is the weapon is carried by the local player or not
function Weapon:IsCarriedByLocalPlayer() end

--- [SHARED]
---
--- Checks if the weapon is a SWEP or a built-in weapon.
---
---@return boolean is_scripted Returns `true` if weapon is [scripted (SWEP)](https://wiki.facepunch.com/gmod/Structures/SWEP), `false` if not (A built-in HL2/HL:S weapon)
function Weapon:IsScripted() end

--- [SHARED]
---
--- Returns whether the weapon is visible. The term visibility is not exactly what gets checked here, first it checks if the owner is a player, then checks if the active view model has EF_NODRAW flag NOT set.
---
---@return boolean is_visible Is visible or not
function Weapon:IsWeaponVisible() end

--- [SHARED]
---
--- Returns the time since this weapon last fired a bullet with [Entity:FireBullets](https://wiki.facepunch.com/gmod/Entity:FireBullets) in seconds. It is not networked.
---
---@return number time The time in seconds when the last bullet was fired.
function Weapon:LastShootTime() end

--- [SHARED]
---
--- Forces weapon to play activity/animation.
---
---@param act integer Activity to play. See the [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT) (specifically `ACT_VM_`).
function Weapon:SendWeaponAnim( act ) end

--- [SHARED]
---
--- Sets the activity the weapon is playing.
---
--- See also [Weapon:GetActivity](https://wiki.facepunch.com/gmod/Weapon:GetActivity).
---
---@param act integer The new activity to set, see [Enums/ACT](https://wiki.facepunch.com/gmod/Enums/ACT).
function Weapon:SetActivity( act ) end

--- [SHARED]
---
--- Sets the number of bullets in the weapon's primary clip.
---
--- See [Weapon:SetClip2](https://wiki.facepunch.com/gmod/Weapon:SetClip2) for the secondary clip. See also [Weapon:DefaultReload](https://wiki.facepunch.com/gmod/Weapon:DefaultReload).
---
---@param ammo integer The amount of bullets the primary clip should contain.
function Weapon:SetClip1( ammo ) end

--- [SHARED]
---
--- Lets you change the number of bullets in the given weapons secondary clip.
---
---@param ammo integer The amount of bullets the clip should contain
function Weapon:SetClip2( ammo ) end

--- [SHARED]
---
--- Sets the hold type of the weapon. This function also calls [WEAPON:SetWeaponHoldType](https://wiki.facepunch.com/gmod/WEAPON:SetWeaponHoldType) and properly networks it to all clients.
---
--- > NOTE: This only works on scripted weapons.
---
--- > BUG: Using this function on weapons held by bots will not network holdtype changes to clients if the world model is set to an empty string (SWEP.WorldModel = "").
---
---@param name string Name of the hold type. You can find all default hold types [here](https://wiki.facepunch.com/gmod/Hold_Types)
function Weapon:SetHoldType( name ) end

--- [SHARED]
---
--- Sets the time since this weapon last fired in seconds. Used in conjunction with [Weapon:LastShootTime](https://wiki.facepunch.com/gmod/Weapon:LastShootTime).
---
--- This value is **not** networked to the client if set from server.
---
---@param time number? The time in seconds when the last time the weapon was fired. Defaults to `CurTime()`.
function Weapon:SetLastShootTime( time ) end

--- [SHARED]
---
--- Sets when the weapon can fire again. Time should be based on [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime).
---
--- > NOTE: The standard HL2 Pistol (`weapon_pistol`) bypasses this function due to an [internal implementation](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/weapon_pistol.cpp#L313-L317).
---
--- > BUG: This will fire extra bullets if the time is set to less than [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime).
--- > See [issue #3786](https://github.com/Facepunch/garrysmod-issues/issues/3786).
---
---@param time number Time when player should be able to use primary fire again
function Weapon:SetNextPrimaryFire( time ) end

--- [SHARED]
---
--- Sets when the weapon can alt-fire again. Time should be based on [Global.CurTime](https://wiki.facepunch.com/gmod/Global.CurTime).
---
---@param time number Time when player should be able to use secondary fire again
function Weapon:SetNextSecondaryFire( time ) end
