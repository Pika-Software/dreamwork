---@class dreamwork.std
local std = dreamwork.std

local gc = std.gc

local string = std.string
local string_format = string.format

local debug = std.debug
local debug_newproxy = debug.newproxy
local debug_getmetatable = debug.getmetatable

--- [SHARED AND MENU]
---
--- A unique, interned, opaque identifier.
---
--- Symbols are compared by identity and are cached by name,
--- so `std.Symbol( "x" ) == std.Symbol( "x" )` is always `true`.
---
--- They hold no data and are collected once nothing references them.
---
---@class dreamwork.std.Symbol : userdata

---@type table<string, dreamwork.std.Symbol>
local symbols = {}
gc.setTableRules( symbols, false, true )

---@type table<dreamwork.std.Symbol, string>
local names = {}
gc.setTableRules( names, false, true )

local proxy_template = debug_newproxy( true )

local Symbol = debug_getmetatable( proxy_template )
Symbol.__type = "Symbol"

---@protected
---@return string represent
function Symbol:__represent()
    return string_format( "Symbol: %p [%s]", self, names[ self ] )
end

---@protected
---@return string represent
function Symbol:__tostring()
    return names[ self ]
end

--- [SHARED AND MENU]
---
--- Gets or creates the symbol with the given name.
---
--- Symbols are interned: calling this repeatedly with the same name returns the same object
--- as long as it is still referenced somewhere.
---
---@param name string The name of the symbol, also used in its string representation.
---@return dreamwork.std.Symbol obj The symbol associated with the name.
---@nodiscard
function std.Symbol( name )
    local symbol = symbols[ name ]
    if symbol == nil then
        symbol = debug_newproxy( proxy_template )
        names[ symbol ] = name
        symbols[ name ] = symbol
    end

    return symbol
end

--- [SHARED AND MENU]
---
--- Checks if a value is a symbol.
---
---@param value any The value to check.
---@return boolean is_symbol Returns `true` if the value is a symbol, otherwise `false`.
---@nodiscard
function std.isSymbol( value )
    return debug_getmetatable( value ) == Symbol
end
