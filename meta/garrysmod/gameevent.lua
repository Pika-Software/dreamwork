---@meta garrysmod.gameevent


--- [SHARED]
---
--- The gameevent library allows Lua to listen to engine game events.
---
--- Once an event is registered with `gameevent.Listen`, it is fired through the `gameevent` hooks,
--- named after the event (e.g. `player_connect`, `player_disconnect`, `entity_killed`).
---
---@class garrysmod.gameevent
gameevent = {}

--- [SHARED]
---
--- Enables the listener for a game event, so it is passed to the hook system.
---
--- Listen to the event with `hook.Add( event_name, ... )`.
---
--- This must be called before the event can be received. On the client, only events the server broadcasts to clients are available.
---
---@param event_name string The name of the engine game event to listen to.
function gameevent.Listen( event_name ) end
