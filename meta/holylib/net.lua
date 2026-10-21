---@meta holylib.net


---@class garrysmod.net
net = {}

--- [SHARED AND MENU]
---
--- Moves the read position of the currently active incoming net message.
---
---@param position integer The bit position (relative to the start of the message's data) to seek to
function net.ReadSeek( position ) end

--- [SHARED AND MENU]
---
--- Moves the write position of the currently active outgoing net message.
---
---@param position integer The bit position (relative to the start of the message's data) to seek to
function net.WriteSeek( position ) end
