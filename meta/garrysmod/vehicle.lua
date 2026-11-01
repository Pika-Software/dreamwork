---@meta garrysmod.vehicle


--- [SHARED]
---
--- This is a list of all methods only available for vehicles. It is also possible to call [Entity](https://wiki.facepunch.com/gmod/Entity) functions on vehicles.
---
---@class garrysmod.Vehicle : garrysmod.Entity
local Vehicle = {}

--- [SERVER]
---
--- Returns the remaining boosting time left.
---
---@return number time_left The remaining boosting time left
function Vehicle:BoostTimeLeft() end

--- [SERVER]
---
--- Tries to find an Exit Point for leaving vehicle, if one is unobstructed in the direction given.
---
---@param yaw number Yaw/roll from vehicle angle to check for exit
---@param distance number Distance from origin to drop player
---@return garrysmod.Vector | nil exit_point Returns the vector for exit position or nil if cannot exit that way.
function Vehicle:CheckExitPoint( yaw, distance ) end

--- [SERVER]
---
--- Sets whether the engine is enabled or disabled, i.e. can be started or not.
---
---@param enable boolean Enable or disable the engine
function Vehicle:EnableEngine( enable ) end

--- [CLIENT]
---
--- Returns information about the ammo of the vehicle
---
---@return integer ammo_type Ammo type of the vehicle ammo
---@return integer clip_size Clip size
---@return integer count Count
function Vehicle:GetAmmo() end

--- [SHARED]
---
--- Gets the driver of the vehicle, returns [NULL](https://wiki.facepunch.com/gmod/NULL) if no driver is present.
---
---@return garrysmod.Entity driver The driver of the vehicle.
function Vehicle:GetDriver() end

--- [SERVER]
---
--- Returns the current speed of the vehicle in Half-Life Hammer Units (in/s). Same as [Entity:GetVelocity](https://wiki.facepunch.com/gmod/Entity:GetVelocity) + [Vector:Length](https://wiki.facepunch.com/gmod/Vector:Length).
---
---@return number speed The speed of the vehicle
function Vehicle:GetHLSpeed() end

--- [SERVER]
---
--- Returns the max speed of the vehicle in MPH.
---
---@return number max_speed The max speed of the vehicle in MPH
function Vehicle:GetMaxSpeed() end

--- [SERVER]
---
--- Returns some info about the vehicle.
---
---@return table operating_params The operating parameters.
function Vehicle:GetOperatingParams() end

--- [SHARED]
---
--- Gets the passenger of the vehicle, returns [NULL](https://wiki.facepunch.com/gmod/NULL) if no drivers is present.
---
---@param role integer The index of the passenger ( 0 is the driver )
---@return garrysmod.Entity passenger The passenger
function Vehicle:GetPassenger( role ) end

--- [SERVER]
---
--- Returns the seat position and angle of a given passenger seat.
---
---@param role integer The passenger role. ( 0 is the driver )
---@return garrysmod.Vector position The seat position in worldspace coordinates.
---@return garrysmod.Angle angles The seat angle in worldspace coordinates.
function Vehicle:GetPassengerSeatPoint( role ) end

--- [SERVER]
---
--- Returns the current RPM of the vehicle. This value is fake and doesn't actually affect the vehicle movement.
---
---@return number rpm The RPM.
function Vehicle:GetRPM() end

--- [SERVER]
---
--- Returns the current speed of the vehicle in MPH.
---
---@return number speed The speed of the vehicle in MPH
function Vehicle:GetSpeed() end

--- [SERVER]
---
--- Returns the current steering of the vehicle.
---
---@return number steering The current steering of the vehicle.
function Vehicle:GetSteering() end

--- [SERVER]
---
--- Returns the maximum steering degree of the vehicle
---
---@return number steering_degrees The maximum steering degree of the vehicle
function Vehicle:GetSteeringDegrees() end

--- [SERVER]
---
--- Returns the current throttle of the vehicle.
---
---@return number throttle The current throttle of the vehicle
function Vehicle:GetThrottle() end

--- [SERVER]
---
--- Returns the vehicle parameters of given vehicle.
---
---@return table vehicle_params The vehicle parameters.
function Vehicle:GetVehicleParams() end

--- [SHARED]
---
--- Returns the view position and forward angle of a given passenger seat.
---
---@param role integer? The passenger role. 0 is the driver. This parameter seems to be ignored by the game engine and is therefore optional. Defaults to `0`.
---@return garrysmod.Vector position The view position, will be 0, 0, 0 on failure
---@return garrysmod.Angle angles The view angles, will be 0, 0, 0 on failure
---@return number fov The field of view, will be 0 on failure
function Vehicle:GetVehicleViewPosition( role ) end

--- [SERVER]
---
--- Returns the [PhysObj](https://wiki.facepunch.com/gmod/PhysObj) of given wheel.
---
---@param wheel integer The wheel to retrieve
---@return garrysmod.Physics wheel The wheel
function Vehicle:GetWheel( wheel ) end

--- [SERVER]
---
--- Returns the base wheel height.
---
---@param wheel integer The wheel to get the base wheel height of.
---@return number height The base wheel height.
function Vehicle:GetWheelBaseHeight( wheel ) end

--- [SERVER]
---
--- Returns the wheel contact point.
---
---@param wheel integer The wheel to check
---@return garrysmod.Vector position The contact position
---@return integer surface_prop_id The Surface Properties ID of hit surface.
---@return boolean on_ground Whether the wheel is on ground or not
function Vehicle:GetWheelContactPoint( wheel ) end

--- [SERVER]
---
--- Returns the wheel count of the vehicle
---
---@return integer wheel_count The amount of wheels
function Vehicle:GetWheelCount() end

--- [SERVER]
---
--- Returns the total wheel height.
---
---@param wheel integer The wheel to get the base wheel height of.
---@return number height The total wheel height.
function Vehicle:GetWheelTotalHeight( wheel ) end

--- [SERVER]
---
--- Returns whether this vehicle has boost at all.
---
---@return boolean has_boost Whether this vehicle has boost at all.
function Vehicle:HasBoost() end

--- [SERVER]
---
--- Returns whether this vehicle has a brake pedal. See [Vehicle:SetHasBrakePedal](https://wiki.facepunch.com/gmod/Vehicle:SetHasBrakePedal).
---
---@return boolean has_brake_pedal Whether this vehicle has a brake pedal or not.
function Vehicle:HasBrakePedal() end

--- [SERVER]
---
--- Returns whether this vehicle is currently boosting or not.
---
---@return boolean is_boosting Whether this vehicle is currently boosting or not.
function Vehicle:IsBoosting() end

--- [SERVER]
---
--- Returns whether the engine is enabled or not, i.e. whether it can be started.
---
---@return boolean is_engine_enabled Whether the engine is enabled
function Vehicle:IsEngineEnabled() end

--- [SERVER]
---
--- Returns whether the engine is started or not.
---
---@return boolean is_engine_started Whether the engine is started or not.
function Vehicle:IsEngineStarted() end

--- [SHARED]
---
--- Determines whether a given [Vehicle](https://wiki.facepunch.com/gmod/Vehicle) is fully initialized.
---
--- It is possible, in uncommon circumstances, for a [valid](https://wiki.facepunch.com/gmod/Global.IsValid) [vehicle](https://wiki.facepunch.com/gmod/Entity:IsVehicle) entity to be in an invalid state, such as before [Entity:Spawn](https://wiki.facepunch.com/gmod/Entity:Spawn) is called on the vehicle after creation.
---
--- If this function returns `false`, then the [Vehicle](https://wiki.facepunch.com/gmod/Vehicle) functions are not usable on this vehicle, while [Entity](https://wiki.facepunch.com/gmod/Entity) functions are.
---
---@return boolean is_valid `true` if the Vehicle is in a valid state, or `false` if the Vehicle is in an invalid state.
function Vehicle:IsValidVehicle() end

--- [SERVER]
---
--- Returns whether this vehicle's engine is underwater or not. ( Internally the attachment point "engine" or "vehicle_engine" is checked )
---
---@return boolean in_water Whether this vehicle's engine is underwater or not.
function Vehicle:IsVehicleBodyInWater() end

--- [SERVER]
---
--- Releases the vehicle's handbrake (Jeep) so it can roll without any passengers.
---
--- This will be overwritten if the vehicle has a driver. Same as [Vehicle:SetHandbrake](https://wiki.facepunch.com/gmod/Vehicle:SetHandbrake)( false )
---
function Vehicle:ReleaseHandbrake() end

--- [SERVER]
---
--- Sets the boost. It is possible that this function does not work while the vehicle has a valid driver in it.
---
---@param boost number The new boost value
function Vehicle:SetBoost( boost ) end

--- [SERVER]
---
--- Turns on or off the Jeep handbrake so it can roll without a driver inside.
---
--- Does nothing while the vehicle has a driver in it.
---
---@param handbrake boolean true to turn on, false to turn off.
function Vehicle:SetHandbrake( handbrake ) end

--- [SERVER]
---
--- Sets whether this vehicle has a brake pedal.
---
---@param brake_pedal boolean Whether this vehicle has a brake pedal
function Vehicle:SetHasBrakePedal( brake_pedal ) end

--- [SERVER]
---
--- Sets maximum reverse throttle
---
---@param max_rev_throttle number The new maximum throttle. This number must be negative.
function Vehicle:SetMaxReverseThrottle( max_rev_throttle ) end

--- [SERVER]
---
--- Sets maximum forward throttle
---
---@param max_throttle number The new maximum throttle.
function Vehicle:SetMaxThrottle( max_throttle ) end

--- [SERVER]
---
--- Sets spring length of given wheel
---
---@param wheel integer The wheel to change spring length of
---@param length number The new spring length
function Vehicle:SetSpringLength( wheel, length ) end

--- [SERVER]
---
--- Sets the steering of the vehicle.
---
--- > NOTE (needs validation): The correct range, 0 to 1 or -1 to 1
---
---@param front number Angle of the front wheels (-1 to 1)
---@param rear number Angle of the rear wheels (-1 to 1)
function Vehicle:SetSteering( front, rear ) end

--- [SERVER]
---
--- Sets the maximum steering degrees of the vehicle
---
---@param steering_degrees number The new maximum steering degree
function Vehicle:SetSteeringDegrees( steering_degrees ) end

--- [SERVER]
---
--- Sets the throttle of the vehicle. It is possible that this function does not work with a valid driver in it.
---
---@param throttle number The new throttle.
function Vehicle:SetThrottle( throttle ) end

--- [SERVER]
---
--- Sets whether the entry or exit camera animation should be played or not.
---
---@param on boolean Whether the entry or exit camera animation should be played or not.
function Vehicle:SetVehicleEntryAnim( on ) end

--- [SERVER]
---
--- Sets the vehicle parameters for given vehicle.
---
--- > NOTE: Not all variables from the [Structures/VehicleParams](https://wiki.facepunch.com/gmod/Structures/VehicleParams) can be set.
---
---@param params table The new new vehicle parameters. See [Structures/VehicleParams](https://wiki.facepunch.com/gmod/Structures/VehicleParams).
function Vehicle:SetVehicleParams( params ) end

--- [SERVER]
---
--- Sets friction of given wheel. This must be used on an AirBoat. it is not supported for Jeep vehicles.
---
---@param wheel integer The wheel to change the friction of
---@param friction number The new friction to set
function Vehicle:SetWheelFriction( wheel, friction ) end

--- [SERVER]
---
--- Starts or stops the engine.
---
---@param start boolean True to start, false to stop.
function Vehicle:StartEngine( start ) end
