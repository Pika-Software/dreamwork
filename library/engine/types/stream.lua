---@meta _

--- [SHARED AND MENU]
---
--- The audio stream object.
---
---@class AudioStream : Object
---@field __class AudioStreamClass
local __AudioStream = {}

---@class AudioStreamClass : AudioStream
---@field __base AudioStream
---@overload fun(): AudioStream
AudioStream = {}

---@protected
function __AudioStream:__init(location) end
