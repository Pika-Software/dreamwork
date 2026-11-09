---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.lua
local lua = std.lua

local setmetatable = std.setmetatable

local string = std.string
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_byteRep = string.byteRep


--- [SHARED AND MENU]
---
--- Lua 5.1 / LuaJIT lexer.
---
--- Tokens are returned as flat arrays ( `types`, `values`, `lines` ) instead of token tables,
--- whitespace, newlines and comments are kept as tokens, so concatenating all values gives back the original code.
---
---@class dreamwork.std.lua.lexer
local lexer = {}
lua.lexer = lexer

--- [SHARED AND MENU]
---
--- Spaces and tabs, without newlines.
lexer.TOKEN_SPACE = 1

--- [SHARED AND MENU]
---
--- A single `\n`.
lexer.TOKEN_NEWLINE = 2

--- [SHARED AND MENU]
---
--- `--`, `--[[ ]]`, `//`, `/* */` comments and the shebang line.
lexer.TOKEN_COMMENT = 3

--- [SHARED AND MENU]
---
--- Quoted and long bracket strings, the value includes quotes / brackets.
lexer.TOKEN_STRING = 4

--- [SHARED AND MENU]
---
--- Number literals, including LuaJIT `LL`, `ULL` and `i` suffixes.
lexer.TOKEN_NUMBER = 5

--- [SHARED AND MENU]
---
--- Names and keywords.
lexer.TOKEN_NAME = 6

--- [SHARED AND MENU]
---
--- Operators and punctuation.
lexer.TOKEN_SYMBOL = 7

--- [SHARED AND MENU]
---
--- A `#<name>` line accepted by the `is_directive` callback of `lexer.tokenize`, including `\` continued lines.
lexer.TOKEN_DIRECTIVE = 8

--- [SHARED AND MENU]
---
--- Token type names, indexed by token type.
---
---@type string[]
lexer.TOKEN_NAMES = { "space", "newline", "comment", "string", "number", "name", "symbol", "directive" }

--- [SHARED AND MENU]
---
--- Reserved words of Lua 5.1 and LuaJIT ( `goto` ).
---
--- GLua `continue` is not here, the parser treats it as a keyword only at the start of a statement.
---
---@type table<string, boolean>
local keywords = {
    [ "and" ] = true,
    [ "break" ] = true,
    [ "do" ] = true,
    [ "else" ] = true,
    [ "elseif" ] = true,
    [ "end" ] = true,
    [ "false" ] = true,
    [ "for" ] = true,
    [ "function" ] = true,
    [ "goto" ] = true,
    [ "if" ] = true,
    [ "in" ] = true,
    [ "local" ] = true,
    [ "nil" ] = true,
    [ "not" ] = true,
    [ "or" ] = true,
    [ "repeat" ] = true,
    [ "return" ] = true,
    [ "then" ] = true,
    [ "true" ] = true,
    [ "until" ] = true,
    [ "while" ] = true
}

lexer.keywords = keywords

---@type table<integer, boolean>
local is_space = {
    [ 0x20 ] = true, -- ' '
    [ 0x09 ] = true, -- \t
    [ 0x0B ] = true, -- \v
    [ 0x0C ] = true, -- \f
    [ 0x0D ] = true  -- \r
}

---@type table<integer, boolean>
local is_name_start = { [ 0x5F --[[ _ ]] ] = true }

---@type table<integer, boolean>
local is_name_part = { [ 0x5F --[[ _ ]] ] = true }

---@type table<integer, boolean>
local is_digit = {}

---@type table<integer, boolean>
local is_number_part = { [ 0x5F --[[ _ ]] ] = true, [ 0x2E --[[ . ]] ] = true }

for byte = 0x41 --[[ A ]], 0x5A --[[ Z ]], 1 do
    is_name_start[ byte ], is_name_part[ byte ], is_number_part[ byte ] = true, true, true
end

for byte = 0x61 --[[ a ]], 0x7A --[[ z ]], 1 do
    is_name_start[ byte ], is_name_part[ byte ], is_number_part[ byte ] = true, true, true
end

for byte = 0x30 --[[ 0 ]], 0x39 --[[ 9 ]], 1 do
    is_name_part[ byte ], is_digit[ byte ], is_number_part[ byte ] = true, true, true
end

-- LuaJIT accepts any non-ASCII byte in names
for byte = 0x80, 0xFF, 1 do
    is_name_start[ byte ], is_name_part[ byte ] = true, true
end

--- Two-byte symbols, `[ first_byte ][ second_byte ]`.
---
---@type table<integer, table<integer, boolean>>
local double_symbols = {
    [ 0x2E --[[ . ]] ] = { [ 0x2E --[[ . ]] ] = true },
    [ 0x3D --[[ = ]] ] = { [ 0x3D --[[ = ]] ] = true },
    [ 0x7E --[[ ~ ]] ] = { [ 0x3D --[[ = ]] ] = true },
    [ 0x3C --[[ < ]] ] = { [ 0x3D --[[ = ]] ] = true, [ 0x3C --[[ < ]] ] = true },
    [ 0x3E --[[ > ]] ] = { [ 0x3D --[[ = ]] ] = true, [ 0x3E --[[ > ]] ] = true },
    [ 0x3A --[[ : ]] ] = { [ 0x3A --[[ : ]] ] = true },
    [ 0x21 --[[ ! ]] ] = { [ 0x3D --[[ = ]] ] = true },
    [ 0x26 --[[ & ]] ] = { [ 0x26 --[[ & ]] ] = true },
    [ 0x7C --[[ | ]] ] = { [ 0x7C --[[ | ]] ] = true }
}

--- [SHARED AND MENU]
---
--- Checks if the string is a valid Lua name that is not a keyword.
---
--- GLua `continue` is rejected too, so the result is safe for both Lua and GLua.
---
---@param str string The string to check.
---@return boolean is_identifier `true` if the string can be used as a variable or field name.
---@nodiscard
function lexer.isIdentifier( str )
    local length = #str
    if length == 0 or keywords[ str ] or str == "continue" or not is_name_start[ string_byte( str, 1 ) ] then
        return false
    end

    for position = 2, length, 1 do
        if not is_name_part[ string_byte( str, position ) ] then
            return false
        end
    end

    return true
end

--- [SHARED AND MENU]
---
--- Counts `\n` characters in the string.
---
---@param str string The string to count newlines in.
---@return integer count The number of newlines.
---@nodiscard
local function countNewlines( str )
    local count, position = 0, 1

    ::newline_counter::

    local newline_position = string_find( str, "\n", position, true )
    if newline_position == nil then
        return count
    end

    count, position = count + 1, newline_position + 1

    ---@diagnostic disable-next-line: missing-return
    goto newline_counter
end

lexer.countNewlines = countNewlines

---@type table<integer, string>
local long_closings = setmetatable( {}, {
    __index = function( self, level )
        local closing = "]" .. string_byteRep( 0x3D, level ) .. "]"
        self[ level ] = closing
        return closing
    end
} )

--- Scans `[[ ]]`, `[==[ ]==]` and so on.
---
---@param code string
---@param position integer The position of the opening `[`.
---@param length integer
---@return integer | nil end_position `nil` if there is no long bracket at the position.
local function scan_long_bracket( code, position, length )
    local level_end = position + 1

    ::level_scanner::

    local byte = string_byte( code, level_end )
    if byte == 0x3D --[[ = ]] then
        level_end = level_end + 1
        goto level_scanner
    elseif byte ~= 0x5B --[[ [ ]] then
        return nil
    end

    local _, end_position = string_find( code, long_closings[ level_end - position - 1 ], level_end + 1, true )
    return end_position or length
end

---@param code string
---@param position integer The position of the first character.
---@param is_hex boolean
---@return integer end_position
local function scan_number( code, position, is_hex )
    local end_position = position

    ::number_scanner::

    local byte = string_byte( code, end_position + 1 )
    if is_number_part[ byte ] then
        end_position = end_position + 1
        goto number_scanner
    elseif byte == 0x2B --[[ + ]] or byte == 0x2D --[[ - ]] then
        local last_byte = string_byte( code, end_position )
        if is_hex then
            if last_byte == 0x70 --[[ p ]] or last_byte == 0x50 --[[ P ]] then
                end_position = end_position + 1
                goto number_scanner
            end
        elseif last_byte == 0x65 --[[ e ]] or last_byte == 0x45 --[[ E ]] then
            end_position = end_position + 1
            goto number_scanner
        end
    end

    return end_position
end

--- Unfinished strings end before the newline.
---
---@param code string
---@param position integer The position of the opening quote.
---@param length integer
---@return integer end_position
local function scan_quoted( code, position, length )
    local quote_byte = string_byte( code, position )

    ::string_scanner::

    position = position + 1
    if position > length then
        return length
    end

    local byte = string_byte( code, position )
    if byte == quote_byte then
        return position
    elseif byte == 0x0A --[[ \n ]] then
        return position - 1
    elseif byte == 0x5C --[[ \ ]] then
        position = position + 1
        byte = string_byte( code, position )

        if byte == 0x0D --[[ \r ]] then
            if string_byte( code, position + 1 ) == 0x0A --[[ \n ]] then
                position = position + 1
            end
        elseif byte == 0x0A --[[ \n ]] then
            if string_byte( code, position + 1 ) == 0x0D --[[ \r ]] then
                position = position + 1
            end
        elseif byte == 0x7A --[[ z ]] then
            -- `\z` skips the following whitespace, newlines included
            ::whitespace_skipper::

            byte = string_byte( code, position + 1 )
            if byte == 0x0A or is_space[ byte ] then
                position = position + 1
                goto whitespace_skipper
            end
        end
    end

    ---@diagnostic disable-next-line: missing-return
    goto string_scanner
end

--- `\` followed by optional spaces right before the newline continues the directive.
---
---@param code string
---@param newline_position integer
---@param line_start integer
---@return boolean
local function is_continued( code, newline_position, line_start )
    local position = newline_position - 1

    ::space_skipper::

    if position < line_start then
        return false
    end

    local byte = string_byte( code, position )
    if byte == 0x20 or byte == 0x09 or byte == 0x0D then
        position = position - 1
        goto space_skipper
    end

    return byte == 0x5C --[[ \ ]]
end

--- [SHARED AND MENU]
---
--- Splits Lua code into tokens.
---
--- Never fails, malformed tokens ( unfinished strings, invalid numbers ) are left for the parser to report.
---
---@param code string The code to tokenize.
---@param is_directive ( fun( name: string ): boolean )? If set, `#<name>` at the start of a line produces a `TOKEN_DIRECTIVE` token when this function returns `true`.
---@return integer[] types The token types, see `lexer.TOKEN_*`.
---@return string[] values The token source texts.
---@return integer[] lines The lines where tokens start.
---@return integer count The number of tokens.
function lexer.tokenize( code, is_directive )
    local types, values, lines, count = {}, {}, {}, 0
    local length = #code
    local position, line = 1, 1
    local line_start = is_directive ~= nil

    -- shebang
    if string_byte( code, 1 ) == 0x23 --[[ # ]] and string_byte( code, 2 ) == 0x21 --[[ ! ]] then
        position = string_find( code, "\n", 1, true ) or (length + 1)
        types[ 1 ], values[ 1 ], lines[ 1 ], count = 3 --[[ comment ]], string_sub( code, 1, position - 1 ), 1, 1
        line_start = false
    end

    ::token_scanner::

    if position > length then
        return types, values, lines, count
    end

    local byte, next_byte = string_byte( code, position, position + 1 )
    local token_type, end_position, multiline = 7 --[[ symbol ]], position, false

    if byte == 0x0A --[[ \n ]] then
        token_type = 2 --[[ newline ]]
    elseif is_space[ byte ] then
        token_type = 1 --[[ space ]]

        ::space_scanner::

        if is_space[ string_byte( code, end_position + 1 ) ] then
            end_position = end_position + 1
            goto space_scanner
        end
    elseif is_name_start[ byte ] then
        token_type = 6 --[[ name ]]

        ::name_scanner::

        if is_name_part[ string_byte( code, end_position + 1 ) ] then
            end_position = end_position + 1
            goto name_scanner
        end
    elseif is_digit[ byte ] or (byte == 0x2E --[[ . ]] and is_digit[ next_byte ]) then
        token_type = 5 --[[ number ]]
        end_position = scan_number( code, position, byte == 0x30 --[[ 0 ]] and (next_byte == 0x78 --[[ x ]] or next_byte == 0x58 --[[ X ]]) )
    elseif byte == 0x22 --[[ " ]] or byte == 0x27 --[[ ' ]] then
        token_type, multiline = 4 --[[ string ]], true
        end_position = scan_quoted( code, position, length )
    elseif byte == 0x2D --[[ - ]] and next_byte == 0x2D then
        token_type, multiline = 3 --[[ comment ]], true

        local long_end
        if string_byte( code, position + 2 ) == 0x5B --[[ [ ]] then
            long_end = scan_long_bracket( code, position + 2, length )
        end

        if long_end == nil then
            end_position = (string_find( code, "\n", position, true ) or (length + 1)) - 1
            multiline = false
        else
            end_position = long_end
        end
    elseif byte == 0x2F --[[ / ]] and next_byte == 0x2F then
        token_type = 3 --[[ comment ]]
        end_position = (string_find( code, "\n", position, true ) or (length + 1)) - 1
    elseif byte == 0x2F --[[ / ]] and next_byte == 0x2A --[[ * ]] then
        token_type, multiline = 3 --[[ comment ]], true

        local _, comment_end = string_find( code, "*/", position + 2, true )
        end_position = comment_end or length
    elseif byte == 0x5B --[[ [ ]] and (next_byte == 0x5B or next_byte == 0x3D --[[ = ]]) then
        local long_end = scan_long_bracket( code, position, length )
        if long_end ~= nil then
            token_type, end_position, multiline = 4 --[[ string ]], long_end, true
        end
    elseif byte == 0x23 --[[ # ]] and line_start then
        local name_start = position + 1

        while string_byte( code, name_start ) == 0x20 or string_byte( code, name_start ) == 0x09 do
            name_start = name_start + 1
        end

        if is_name_start[ string_byte( code, name_start ) ] then
            local name_end = name_start

            while is_name_part[ string_byte( code, name_end + 1 ) ] do
                name_end = name_end + 1
            end

            ---@cast is_directive fun( name: string ): boolean

            if is_directive( string_sub( code, name_start, name_end ) ) then
                token_type, multiline = 8 --[[ directive ]], true

                local search_position = position

                ::directive_scanner::

                local newline_position = string_find( code, "\n", search_position, true )
                if newline_position == nil then
                    end_position = length
                elseif is_continued( code, newline_position, search_position ) then
                    search_position = newline_position + 1
                    goto directive_scanner
                else
                    end_position = newline_position - 1
                end
            end
        end
    end

    if token_type == 7 --[[ symbol ]] then
        if byte == 0x2E --[[ . ]] and next_byte == 0x2E and string_byte( code, position + 2 ) == 0x2E then
            end_position = position + 2
        else
            local seconds = double_symbols[ byte ]
            if seconds ~= nil and seconds[ next_byte ] then
                end_position = position + 1
            end
        end
    end

    local value = string_sub( code, position, end_position )

    count = count + 1
    types[ count ], values[ count ], lines[ count ] = token_type, value, line

    if token_type == 2 --[[ newline ]] then
        line, line_start = line + 1, is_directive ~= nil
    elseif token_type ~= 1 --[[ space ]] then
        line_start = false

        if multiline then
            line = line + countNewlines( value )
        end
    end

    position = end_position + 1

    ---@diagnostic disable-next-line: missing-return
    goto token_scanner
end
