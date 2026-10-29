local glua_engine = engine

---@class dreamwork.std
local std = dreamwork.std

--- [CLIENT AND MENU]
---
--- The game demo library.
---
---@class dreamwork.std.game.demo
local demo = {}
game.demo = demo

demo.getTotalPlaybackTicks = glua_engine.GetDemoPlaybackTotalTicks
demo.getPlaybackStartTick = glua_engine.GetDemoPlaybackStartTick
demo.getPlaybackSpeed = glua_engine.GetDemoPlaybackTimeScale
demo.getPlaybackTick = glua_engine.GetDemoPlaybackTick
demo.isRecording = glua_engine.IsRecordingDemo
demo.isPlaying = glua_engine.IsPlayingDemo

if std.LUA_MENU then
    demo.getFileDetails = _G.GetDemoFileDetails
end
