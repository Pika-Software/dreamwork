---@meta _

---@class Addon: Object
---@field __class AddonClass
local __Addon = {}

---@class AddonClass: Addon
---@field __base Addon
---@overload fun(): Addon
Addon = {}

---@protected
function __Addon:__init() end

--- [SHARED AND MENU]
---
--- Returns all subscribed publications.
---
---@return game.Addon[] items The subscribed addons.
---@return integer item_count The length of the addons found array (`#addons`).
---@nodiscard
function Addon.getDownloaded() end

--- [SHARED AND MENU]
---
--- Returns all mounted addons.
---
---@return steam.workshop.Item[] items The mounted addons.
---@return integer item_count The length of the addons found array (`#addons`).
---@nodiscard
function Addon.getMounted() end

---@protected
function __Addon:__index(key) end
