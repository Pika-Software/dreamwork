---@meta _

--- [SHARED AND MENU]
---
--- A unique, interned, opaque identifier.
---
--- Symbols are compared by identity and are cached by name,
--- so `Symbol( "x" ) == Symbol( "x" )` is always `true`.
---
--- They hold no data and are collected once nothing references them.
---
--- ```lua
--- local mark = Symbol( "x" )
---
--- print( mark == Symbol( "x" ) ) -- true
--- print( mark ) -- x
--- ```
---
---@class Symbol : Object, userdata

--- [SHARED AND MENU]
---
--- Gets or creates the symbol with the given name.
---
--- Symbols are interned: calling this repeatedly with the same name returns the same object
--- as long as it is still referenced somewhere.
---
---@param name string The name of the symbol, also used in its string representation.
---@return Symbol obj The symbol associated with the name.
---@nodiscard
function Symbol(name) end

--- [SHARED AND MENU]
---
--- Checks if a value is a symbol.
---
---@param value any The value to check.
---@return boolean is_symbol Returns `true` if the value is a symbol, otherwise `false`.
---@nodiscard
function isSymbol(value) end

--- [SHARED AND MENU]
---
--- A sentinel symbol that represents an explicit "no value".
---
--- Unlike `nil`, it can be stored in tables and passed around as a real value,
--- which makes it useful for telling "intentionally empty" apart from "missing".
---
--- It is a singleton, so compare it by identity: `value == null`.
---
---@class null : Symbol
null = {}
