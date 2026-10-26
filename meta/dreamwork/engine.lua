---@meta dreamwork.std.engine


--- [SHARED AND MENU]
---
--- Source game item.
---
---@class dreamwork.std.game.Item
local game = {}

---
--- The name of the game.
---
---@type string
game.title = nil

---
--- The Steam application ID of the game.
---
---@type integer
game.appid = nil

---
--- The mount folder name of the game.
---
---@type string
game.folder = nil

---
--- Whether the game is installed or not.
---
---@type boolean
game.installed = nil

---
--- Whether the game is mounted or not.
---
---@type boolean
game.mounted = nil

---
--- Whether the game is owned or not.
---
---@type boolean
game.owned = nil


---@class dreamwork.TimerAPI
---@field Adjust fun( identifier: string, delay: number, repetitions: ( integer | nil ), fn: ( fun() | nil ) ): boolean
---@field Create fun( identifier: string, delay: number, repetitions: integer, fn: fun() )
---@field Exists fun( identifier: string ): boolean
---@field Remove fun( identifier: string )
---@field Start fun( identifier: string ): boolean
---@field Stop fun( identifier: string ): boolean
---@field Pause fun( identifier: string ): boolean
---@field UnPause fun( identifier: string ): boolean
---@field IsRunning fun( identifier: string ): boolean
---@field IsPaused fun( identifier: string ): boolean
---@field TimeLeft fun( identifier: string ): number | 0
---@field RepsLeft fun( identifier: string ): integer | 0
---@field Simple fun( delay: number, fn: fun() )
local timer_api = {}
