---@meta garrysmod.player


---@class garrysmod.Player : garrysmod.Entity
---@field AccountID fun( self: garrysmod.Player ): integer | nil
---@field UserID fun( self: garrysmod.Player ): integer
---@field IsBot fun( self: garrysmod.Player ): boolean
---@field Nick fun( self: garrysmod.Player ): string
---@field Kick fun( self: garrysmod.Player, reason: string )
---@field ConCommand fun( self: garrysmod.Player, command: string )
