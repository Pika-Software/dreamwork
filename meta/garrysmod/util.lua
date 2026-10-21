---@meta garrysmod.util


--- [SHARED AND MENU]
---
--- This is the list of utility functions.
---
---@class garrysmod.util
---@field CRC fun( data: string ): string
---@field MD5 fun( data: string ): string
---@field SHA1 fun( data: string ): string
---@field SHA256 fun( data: string ): string
---@field Base64Encode fun( input_str: string, inline: true ): string
---@field Base64Decode fun( input_str: string ): string
---@field JSONToTable fun( json_str: string, ignore_limits: boolean?, ignore_conversions: boolean? ): table | nil
---@field TableToJSON fun( tbl: table, pretty_print: boolean? ): string | nil
---@field AddNetworkString fun( network_name: string )
---@field NetworkIDToString fun( network_id: integer ): string | nil
---@field NetworkStringToID fun( network_name: string ): integer | nil
util = {}
