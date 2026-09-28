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
