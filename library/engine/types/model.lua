---@meta _

---@class Model : Object
local __Model = {}

---@class ModelClass : Model
Model = {}

--- [SHARED AND MENU]
---
--- Returns the ID of the activity by name.
---
--- Basic activities: https://developer.valvesoftware.com/wiki/Activity_List#Base_activities
---
--- Gmod ones: https://wiki.facepunch.com/gmod/Enums/ACT
---
---@param act_name string The name of the activity.
---@return integer act_id The ID of the activity.
---@nodiscard
function Model.getGlobalActivityID(act_name) end

--- [SHARED AND MENU]
---
--- Returns the name of the activity by ID.
---
--- Basic activities: https://developer.valvesoftware.com/wiki/Activity_List#Base_activities
---
--- Gmod ones: https://wiki.facepunch.com/gmod/Enums/ACT
---
---@param act_id integer The ID of the activity.
---@return string act_name The name of the activity.
---@nodiscard
function Model.getGlobalActivityName(act_id) end
