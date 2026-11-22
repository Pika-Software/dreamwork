---@meta holylib.addonsystem


--- [SHARED AND MENU]
---
--- Engine Workshop / GMA addon mounting via Garry's Mod's `IAddonSystem`.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem)
---
---@class holylib.addonsystem
addonsystem = {}

--- [SHARED AND MENU]
---
--- Switches the active Steam Workshop collection to the given collection ID
--- and scans it for subscriptions to mount.
---
--- Also sets the `host_workshop_collection` convar to `collection_id`.
---
--- Content that was mounted from the previously active collection stays mounted.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.ChangeCollection)
---
---@param collection_id string The Steam Workshop collection ID.
function addonsystem.ChangeCollection( collection_id ) end

--- [SHARED AND MENU]
---
--- Clears the engine addon system, removing active addons.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.Clear)
---
function addonsystem.Clear() end

--- [SHARED AND MENU]
---
--- Mounts the given `.gma` file through the engine addon system
--- (same path used by `game.MountGMA`).
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.MountFile)
---
---@param file_path string Path to the GMA file.
---@return integer result The engine `IAddonSystem::MountFile` result code.
---@return string[] files Paths of the files mounted from the GMA.
function addonsystem.MountFile( file_path ) end

--- [SHARED AND MENU]
---
--- Refreshes the engine addon system so it picks up addon changes.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.Refresh)
---
function addonsystem.Refresh() end

--- [SHARED AND MENU]
---
--- Sets whether the given Workshop addon should be mounted.
---
--- `workshop_id` must be a string; passing a number can cause incorrect IDs.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.SetShouldMount)
---
---@param workshop_id string The Steam Workshop item ID.
---@param should_mount boolean? `true` to mount, `false` to unmount. Defaults to `false`.
function addonsystem.SetShouldMount( workshop_id, should_mount ) end

--- [SHARED AND MENU]
---
--- Returns whether the given Workshop addon should be mounted.
---
--- `workshop_id` must be a string; passing a number can cause incorrect IDs.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.ShouldMount)
---
---@param workshop_id string The Steam Workshop item ID.
---@return boolean should_mount `true` if the addon should be mounted.
---@nodiscard
function addonsystem.ShouldMount( workshop_id ) end

--- [SHARED AND MENU]
---
--- Subscribes to the given Steam Workshop item through `SteamUGC`,
--- adds it as an unloaded subscription, and on a listen server immediately
--- scans for subscriptions so it can be downloaded and mounted.
---
--- Throws if `SteamUGC` is unavailable.
---
--- [View documents](https://holylib.raphaelit7.com/addonsystem.Subscribe)
---
---@param workshop_id string The Steam Workshop item ID to subscribe to.
function addonsystem.Subscribe( workshop_id ) end
