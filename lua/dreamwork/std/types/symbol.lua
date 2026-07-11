---@class dreamwork.std
local std = dreamwork.std

local string_format = std.string.format

local debug = std.debug
local debug_newproxy = debug.newproxy
local debug_getmetatable = debug.getmetatable

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- A symbol.
---
---@class dreamwork.std.Symbol : userdata

---@alias Symbol dreamwork.std.Symbol

---@type table<string, dreamwork.std.Symbol>
local symbols = {}

std.gc.setTableRules( symbols, false, true )

local proxy_template = debug_newproxy( true )

local Symbol = debug_getmetatable( proxy_template )
Symbol.__type = "Symbol"

---@type table<dreamwork.std.Symbol, string>
local types = {}
std.gc.setTableRules( types, true, false )

---@return string
---@protected
function Symbol:__tostring()
    return types[ self ]
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Creates a new symbol.
---
---@param name string The name of the symbol.
---@return dreamwork.std.Symbol obj The new symbol.
function std.Symbol( name )
    local symbol = symbols[ name ]
    if symbol == nil then
        symbol = debug_newproxy( proxy_template )
        types[ symbol ] = string_format( "%s Symbol: %p", name, symbol )
        symbols[ name ] = symbol
    end

    return symbol
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Checks if a value is a symbol.
---
---@param value any The value to check.
function std.isSymbol( value )
    return debug_getmetatable( value ) == Symbol
end
