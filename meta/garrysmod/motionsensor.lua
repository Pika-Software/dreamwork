---@meta garrysmod.motionsensor


--- [CLIENT AND MENU]
---
--- Functions related to Kinect for Windows usage in GMod.
---
--- See [Using The Kinect](https://wiki.facepunch.com/gmod/Using_The_Kinect) and [Kinect developing](https://wiki.facepunch.com/gmod/Kinect_developing).
---
--- > **WARNING**: Kinect feature works only on 32-bit version of the game.
---
---@class garrysmod.motionsensor
motionsensor = {}

--- [CLIENT AND MENU]
---
--- Returns the depth map material.
---
---@return garrysmod.Material material The material.
function motionsensor.GetColourMaterial() end

--- [CLIENT]
---
--- Returns players skeletal data if they are using Kinect.
---
--- See [Using The Kinect](https://wiki.facepunch.com/gmod/Using_The_Kinect) and [Kinect developing](https://wiki.facepunch.com/gmod/Kinect_developing).
---
---@return table skeleton The skeleton data.
function motionsensor.GetSkeleton() end

--- [CLIENT]
---
--- Return whether a kinect is connected - and active (ie - `Start` has been called).
---
---@return boolean is_active Connected and active or not.
function motionsensor.IsActive() end

--- [CLIENT AND MENU]
---
--- Returns `true` if we have detected that there's a kinect connected to the PC.
---
---@return boolean is_available Connected or not.
function motionsensor.IsAvailable() end

--- [CLIENT AND MENU]
---
--- This starts access to the kinect sensor. Note that this usually freezes the game for a couple of seconds.
---
---@return boolean started `true` if the access has been started.
function motionsensor.Start() end

--- [CLIENT]
---
--- Stops the motion capture.
---
function motionsensor.Stop() end
