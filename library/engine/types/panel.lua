---@meta _

---@class Panel : Object
---@field __class PanelClass
local __Panel = {}

---@protected
function __Panel:__init() end

---@class PanelClass : Panel
---@field __base Panel
---@overload fun(): Panel
Panel = {}

function Panel.getMain() end

function Panel.getHovered() end

function Panel.getHUD() end

function Panel.getOverlay() end
