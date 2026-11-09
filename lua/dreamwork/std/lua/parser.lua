---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.lua
local lua = std.lua

local error = std.error
local class = std.class

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local string_find = string.find
local string_match = string.match
local string_format = string.format

local table = std.table
local table_concat = table.concat

local utf8 = std.utf8
local utf8_encode = utf8.encode

local lexer = lua.lexer
local keywords = lexer.keywords
local lexer_tokenize = lexer.tokenize

--- [SHARED AND MENU]
---
--- An error raised when Lua code cannot be parsed.
---
---@class dreamwork.std.lua.SyntaxError : dreamwork.std.Error
---@field __class dreamwork.std.lua.SyntaxErrorClass
---@field __parent dreamwork.std.Error
---@field message string The error message.
---@field chunk_name string The name of the chunk where the error occurred.
---@field line integer The line where the error occurred.
local SyntaxError = class.base( "SyntaxError", false, std.Error )

---@param message string
---@param chunk_name string
---@param line integer
---@protected
function SyntaxError:__init( message, chunk_name, line )
    self.message = message
    self.chunk_name = chunk_name
    self.line = line
end

---@param error_message string
---@return string
---@protected
function SyntaxError:__message( error_message )
    return string_format( "%s:%d: %s", self.chunk_name, self.line, error_message )
end

--- [SHARED AND MENU]
---
--- The class used to create new `SyntaxError` instances.
---
---@class dreamwork.std.lua.SyntaxErrorClass : dreamwork.std.lua.SyntaxError, dreamwork.std.Class
---@field __base dreamwork.std.lua.SyntaxError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: string, chunk_name: string, line: integer ): dreamwork.std.lua.SyntaxError
local SyntaxErrorClass = class.create( SyntaxError )
lua.SyntaxError = SyntaxErrorClass


--- [SHARED AND MENU]
---
--- Lua 5.1 / LuaJIT ( and GLua ) parser, builds an AST from code or tokens.
---
--- AST nodes are plain tables with a `type` field, see `dreamwork.std.lua.ast.*`.
---
--- GLua operators are normalized: `!=` -> `~=`, `&&` -> `and`, `||` -> `or`, `!` -> `not`.
---
---@class dreamwork.std.lua.parser
local parser = {}
lua.parser = parser

--[[

    AST node types, statements are `1` - `16`, expressions are `17` - `31`.

--]]

--- [SHARED AND MENU]
---
--- `Local` statement node, see `dreamwork.std.lua.ast.Local`.
parser.NODE_LOCAL = 1

--- [SHARED AND MENU]
---
--- `LocalFunction` statement node, see `dreamwork.std.lua.ast.LocalFunction`.
parser.NODE_LOCAL_FUNCTION = 2

--- [SHARED AND MENU]
---
--- `FunctionDeclaration` statement node, see `dreamwork.std.lua.ast.FunctionDeclaration`.
parser.NODE_FUNCTION_DECLARATION = 3

--- [SHARED AND MENU]
---
--- `Assignment` statement node, see `dreamwork.std.lua.ast.Assignment`.
parser.NODE_ASSIGNMENT = 4

--- [SHARED AND MENU]
---
--- `CallStatement` statement node, see `dreamwork.std.lua.ast.CallStatement`.
parser.NODE_CALL_STATEMENT = 5

--- [SHARED AND MENU]
---
--- `Do` statement node, see `dreamwork.std.lua.ast.Do`.
parser.NODE_DO = 6

--- [SHARED AND MENU]
---
--- `While` statement node, see `dreamwork.std.lua.ast.While`.
parser.NODE_WHILE = 7

--- [SHARED AND MENU]
---
--- `Repeat` statement node, see `dreamwork.std.lua.ast.Repeat`.
parser.NODE_REPEAT = 8

--- [SHARED AND MENU]
---
--- `If` statement node, see `dreamwork.std.lua.ast.If`.
parser.NODE_IF = 9

--- [SHARED AND MENU]
---
--- `NumericFor` statement node, see `dreamwork.std.lua.ast.NumericFor`.
parser.NODE_NUMERIC_FOR = 10

--- [SHARED AND MENU]
---
--- `GenericFor` statement node, see `dreamwork.std.lua.ast.GenericFor`.
parser.NODE_GENERIC_FOR = 11

--- [SHARED AND MENU]
---
--- `Return` statement node, see `dreamwork.std.lua.ast.Return`.
parser.NODE_RETURN = 12

--- [SHARED AND MENU]
---
--- `Break` statement node, see `dreamwork.std.lua.ast.Break`.
parser.NODE_BREAK = 13

--- [SHARED AND MENU]
---
--- `Continue` statement node, see `dreamwork.std.lua.ast.Continue`.
parser.NODE_CONTINUE = 14

--- [SHARED AND MENU]
---
--- `Goto` statement node, see `dreamwork.std.lua.ast.Goto`.
parser.NODE_GOTO = 15

--- [SHARED AND MENU]
---
--- `Label` statement node, see `dreamwork.std.lua.ast.Label`.
parser.NODE_LABEL = 16

--- [SHARED AND MENU]
---
--- `Nil` expression node, see `dreamwork.std.lua.ast.Nil`.
parser.NODE_NIL = 17

--- [SHARED AND MENU]
---
--- `Boolean` expression node, see `dreamwork.std.lua.ast.Boolean`.
parser.NODE_BOOLEAN = 18

--- [SHARED AND MENU]
---
--- `Number` expression node, see `dreamwork.std.lua.ast.Number`.
parser.NODE_NUMBER = 19

--- [SHARED AND MENU]
---
--- `String` expression node, see `dreamwork.std.lua.ast.String`.
parser.NODE_STRING = 20

--- [SHARED AND MENU]
---
--- `Vararg` expression node, see `dreamwork.std.lua.ast.Vararg`.
parser.NODE_VARARG = 21

--- [SHARED AND MENU]
---
--- `Function` expression node, see `dreamwork.std.lua.ast.Function`.
parser.NODE_FUNCTION = 22

--- [SHARED AND MENU]
---
--- `Table` expression node, see `dreamwork.std.lua.ast.Table`.
parser.NODE_TABLE = 23

--- [SHARED AND MENU]
---
--- `Binary` expression node, see `dreamwork.std.lua.ast.Binary`.
parser.NODE_BINARY = 24

--- [SHARED AND MENU]
---
--- `Unary` expression node, see `dreamwork.std.lua.ast.Unary`.
parser.NODE_UNARY = 25

--- [SHARED AND MENU]
---
--- `Identifier` expression node, see `dreamwork.std.lua.ast.Identifier`.
parser.NODE_IDENTIFIER = 26

--- [SHARED AND MENU]
---
--- `Member` expression node, see `dreamwork.std.lua.ast.Member`.
parser.NODE_MEMBER = 27

--- [SHARED AND MENU]
---
--- `Index` expression node, see `dreamwork.std.lua.ast.Index`.
parser.NODE_INDEX = 28

--- [SHARED AND MENU]
---
--- `Call` expression node, see `dreamwork.std.lua.ast.Call`.
parser.NODE_CALL = 29

--- [SHARED AND MENU]
---
--- `MethodCall` expression node, see `dreamwork.std.lua.ast.MethodCall`.
parser.NODE_METHOD_CALL = 30

--- [SHARED AND MENU]
---
--- `Paren` expression node, see `dreamwork.std.lua.ast.Paren`.
parser.NODE_PAREN = 31

--- [SHARED AND MENU]
---
--- `TableField` node, see `dreamwork.std.lua.ast.TableField`.
parser.NODE_TABLE_FIELD = 32

--- [SHARED AND MENU]
---
--- `Chunk` node, see `dreamwork.std.lua.ast.Chunk`.
parser.NODE_CHUNK = 33

--- [SHARED AND MENU]
---
--- Node type names, indexed by node type.
---
---@type string[]
parser.NODE_NAMES = { "Local", "LocalFunction", "FunctionDeclaration", "Assignment", "CallStatement", "Do", "While", "Repeat", "If", "NumericFor", "GenericFor", "Return", "Break", "Continue", "Goto", "Label", "Nil", "Boolean", "Number", "String", "Vararg", "Function", "Table", "Binary", "Unary", "Identifier", "Member", "Index", "Call", "MethodCall", "Paren", "TableField", "Chunk" }

--- Left priorities of binary operators.
---
---@type table<string, integer>
local binary_left = {
    [ "or" ] = 1,
    [ "||" ] = 1,
    [ "and" ] = 2,
    [ "&&" ] = 2,
    [ "<" ] = 3,
    [ ">" ] = 3,
    [ "<=" ] = 3,
    [ ">=" ] = 3,
    [ "~=" ] = 3,
    [ "!=" ] = 3,
    [ "==" ] = 3,
    [ ".." ] = 5,
    [ "+" ] = 6,
    [ "-" ] = 6,
    [ "*" ] = 7,
    [ "/" ] = 7,
    [ "%" ] = 7,
    [ "^" ] = 10
}

--- Right priorities of binary operators, lower than left for right associative ones.
---
---@type table<string, integer>
local binary_right = {
    [ "or" ] = 1,
    [ "||" ] = 1,
    [ "and" ] = 2,
    [ "&&" ] = 2,
    [ "<" ] = 3,
    [ ">" ] = 3,
    [ "<=" ] = 3,
    [ ">=" ] = 3,
    [ "~=" ] = 3,
    [ "!=" ] = 3,
    [ "==" ] = 3,
    [ ".." ] = 4,
    [ "+" ] = 6,
    [ "-" ] = 6,
    [ "*" ] = 7,
    [ "/" ] = 7,
    [ "%" ] = 7,
    [ "^" ] = 9
}

local UNARY_PRIORITY = 8

---@type table<string, string>
local canonical_operators = {
    [ "!=" ] = "~=",
    [ "&&" ] = "and",
    [ "||" ] = "or",
    [ "!" ] = "not"
}

---@type table<string, boolean>
local unary_operators = {
    [ "not" ] = true,
    [ "!" ] = true,
    [ "-" ] = true,
    [ "#" ] = true
}

---@type table<string, boolean>
local block_ends = {
    [ "end" ] = true,
    [ "else" ] = true,
    [ "elseif" ] = true,
    [ "until" ] = true
}

---@type table<integer, string>
local escapes = {
    [ 0x61 --[[ a ]] ] = "\a",
    [ 0x62 --[[ b ]] ] = "\b",
    [ 0x66 --[[ f ]] ] = "\f",
    [ 0x6E --[[ n ]] ] = "\n",
    [ 0x72 --[[ r ]] ] = "\r",
    [ 0x74 --[[ t ]] ] = "\t",
    [ 0x76 --[[ v ]] ] = "\v",
    [ 0x5C --[[ \ ]] ] = "\\",
    [ 0x22 --[[ " ]] ] = "\"",
    [ 0x27 --[[ ' ]] ] = "'",
    [ 0x0A --[[ \n ]] ] = "\n",
    [ 0x0D --[[ \r ]] ] = "\n"
}

---@type table<integer, integer>
local hex_values = {}

for byte = 0x30 --[[ 0 ]], 0x39 --[[ 9 ]], 1 do
    hex_values[ byte ] = byte - 0x30
end

for byte = 0x41 --[[ A ]], 0x46 --[[ F ]], 1 do
    hex_values[ byte ] = byte - 0x37
    hex_values[ byte + 0x20 ] = byte - 0x37
end

--- Decodes a quoted string literal.
---
---@param str string The literal with quotes.
---@return string | nil value
---@return string | nil error_message
local function decode_quoted( str )
    local length = #str
    local quote_byte = string_byte( str, 1 )

    if length < 2 or string_byte( str, length ) ~= quote_byte then
        return nil, "unfinished string"
    end

    -- fast path, nothing to decode
    if string_find( str, "\\", 2, true ) == nil then
        return string_sub( str, 2, length - 1 )
    end

    local buffer, buffer_size = {}, 0
    local position, segment_start = 2, 2

    ::string_decoder::

    if position >= length then
        if position ~= length then
            return nil, "unfinished string"
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = string_sub( str, segment_start, length - 1 )
        return table_concat( buffer, "", 1, buffer_size )
    end

    local byte = string_byte( str, position )
    if byte ~= 0x5C --[[ \ ]] then
        position = position + 1
        goto string_decoder
    end

    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = string_sub( str, segment_start, position - 1 )

    position = position + 1
    byte = string_byte( str, position )

    if position >= length then
        return nil, "unfinished string"
    end

    local escape = escapes[ byte ]
    if escape ~= nil then
        position = position + 1

        -- `\` + `\r\n` or `\n\r` is a single newline
        if byte == 0x0D then
            if string_byte( str, position ) == 0x0A then
                position = position + 1
            end
        elseif byte == 0x0A then
            if string_byte( str, position ) == 0x0D then
                position = position + 1
            end
        end
    elseif byte >= 0x30 and byte <= 0x39 then
        local value, digits = byte - 0x30, 1
        position = position + 1

        ::decimal_reader::

        byte = string_byte( str, position )
        if digits ~= 3 and byte ~= nil and byte >= 0x30 and byte <= 0x39 then
            value, digits, position = value * 10 + (byte - 0x30), digits + 1, position + 1
            goto decimal_reader
        end

        if value > 0xFF then
            return nil, "invalid escape sequence"
        end

        escape = string_char( value )
    elseif byte == 0x78 --[[ x ]] then
        local high, low = hex_values[ string_byte( str, position + 1 ) ], hex_values[ string_byte( str, position + 2 ) ]
        if high == nil or low == nil then
            return nil, "invalid escape sequence"
        end

        escape = string_char( high * 16 + low )
        position = position + 3
    elseif byte == 0x7A --[[ z ]] then
        escape = ""
        position = position + 1

        ::whitespace_skipper::

        byte = string_byte( str, position )
        if byte == 0x20 or (byte ~= nil and byte >= 0x09 and byte <= 0x0D) then
            position = position + 1
            goto whitespace_skipper
        end
    elseif byte == 0x75 --[[ u ]] and string_byte( str, position + 1 ) == 0x7B --[[ { ]] then
        local code_point = 0
        position = position + 2

        local digit = hex_values[ string_byte( str, position ) ]
        if digit == nil then
            return nil, "invalid escape sequence"
        end

        ::hex_reader::

        code_point, position = code_point * 16 + digit, position + 1
        if code_point >= 0x110000 then
            return nil, "invalid escape sequence"
        end

        digit = hex_values[ string_byte( str, position ) ]
        if digit ~= nil then
            goto hex_reader
        end

        -- LuaJIT rejects surrogates too
        if string_byte( str, position ) ~= 0x7D --[[ } ]] or (code_point >= 0xD800 and code_point <= 0xDFFF) then
            return nil, "invalid escape sequence"
        end

        escape = utf8_encode( code_point )
        position = position + 1
    else
        return nil, "invalid escape sequence"
    end

    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = escape

    segment_start = position
    goto string_decoder
end

--- Decodes a long bracket string literal.
---
---@param str string
---@return string | nil value
---@return string | nil error_message
local function decode_long( str )
    local level = string_find( str, "[", 2, true )
    if level == nil then
        return nil, "invalid long string delimiter"
    end

    level = level - 2

    local length = #str
    if length < level * 2 + 4 or string_byte( str, length ) ~= 0x5D --[[ ] ]] or string_byte( str, length - level - 1 ) ~= 0x5D then
        return nil, "unfinished long string"
    end

    local start_position = level + 3

    -- the first newline is skipped
    local byte = string_byte( str, start_position )
    if byte == 0x0D or byte == 0x0A then
        local next_byte = string_byte( str, start_position + 1 )
        if (next_byte == 0x0D or next_byte == 0x0A) and next_byte ~= byte then
            start_position = start_position + 2
        else
            start_position = start_position + 1
        end
    end

    return string_sub( str, start_position, length - level - 2 )
end

--- [SHARED AND MENU]
---
--- Decodes a string literal token ( quoted or long bracket ) into its value.
---
---@param str string The string literal with quotes or brackets.
---@return string | nil value The decoded value, or `nil` if the literal is malformed.
---@return string | nil error_message The reason the literal is malformed.
local function decodeString( str )
    if string_byte( str, 1 ) == 0x5B --[[ [ ]] then
        return decode_long( str )
    else
        return decode_quoted( str )
    end
end

parser.decodeString = decodeString

--- [SHARED AND MENU]
---
--- Decodes a number literal token.
---
--- LuaJIT `LL`, `ULL` and `i` literals are valid but cannot be represented as a Lua number, so they return `nil` without an error.
---
---@param str string The number literal.
---@return number | nil value The number, or `nil` if the literal is a 64-bit / imaginary literal or malformed.
---@return string | nil error_message The reason the literal is malformed.
local function decodeNumber( str )
    local value = raw_tonumber( str )
    if value ~= nil then
        return value
    end

    local base = string_match( str, "^(.-)[uU]?[lL][lL]$" ) or string_match( str, "^(.-)[iI]$" )
    if base ~= nil and raw_tonumber( base ) ~= nil then
        return nil
    end

    return nil, "malformed number"
end

parser.decodeNumber = decodeNumber

-- parser state, the parser does not call user code, so it is never re-entered

---@type string[]
local values = {}

---@type integer[]
local lines = {}

---@type integer[]
local types = {}

local count = 0
local index = 1
local chunk_name = "lua"
local last_line = 1

--- Releases the token arrays.
local function unload_tokens()
    types, values, lines, count = {}, {}, {}, 0
end

--- Releases the token arrays, so they are not kept until the next parse, and raises the error.
---
---@param message string
---@param token_index integer | nil
local function syntax_error( message, token_index )
    if token_index == nil then
        token_index = index
    end

    local line, near

    if token_index > count then
        line, near = lines[ count ] or 1, "<eof>"
    else
        line, near = lines[ token_index ], values[ token_index ]
    end

    unload_tokens()
    error( SyntaxErrorClass( string_format( "%s near '%s'", message, near ), chunk_name, line ), 3 )
end

---@param value string
---@param opening_value string | nil
---@param opening_index integer | nil
local function expect( value, opening_value, opening_index )
    if values[ index ] == value then
        index = index + 1
        return
    end

    if opening_index == nil or lines[ opening_index ] == lines[ index ] then
        syntax_error( string_format( "'%s' expected", value ) )
    else
        syntax_error( string_format( "'%s' expected (to close '%s' at line %d)", value, opening_value, lines[ opening_index ] ) )
    end
end

---@return string
local function expect_name()
    local value = values[ index ]
    if types[ index ] ~= 6 --[[ name ]] or keywords[ value ] then
        syntax_error( "<name> expected" )
    end

    index = index + 1
    return value
end

---@return dreamwork.std.lua.ast.Identifier
local function parse_identifier()
    return {
        type = 26 --[[ Identifier ]],
        name = expect_name(),
        line = lines[ index ]
    }
end

local parse_block, parse_expression, parse_subexpression, parse_function_body

---@return dreamwork.std.lua.ast.Expression[]
local function parse_expression_list()
    local expressions, expression_count = { parse_expression() }, 1

    while values[ index ] == "," do
        index = index + 1
        expression_count = expression_count + 1
        expressions[ expression_count ] = parse_expression()
    end

    return expressions
end

---@return dreamwork.std.lua.ast.Table
local function parse_table()
    local line, opening_index = lines[ index ], index
    index = index + 1

    ---@type dreamwork.std.lua.ast.TableField[]
    local fields, field_count = {}, 0

    ::field_parser::

    local value = values[ index ]
    if value ~= "}" then
        local field_line = lines[ index ]

        ---@type dreamwork.std.lua.ast.TableField
        local field

        if value == "[" then
            index = index + 1

            local key = parse_expression()

            expect( "]" )
            expect( "=" )

            field = {
                type = 32 --[[ TableField ]],
                kind = "index",
                key = key,
                value = parse_expression(),
                line = field_line,
            }
        elseif types[ index ] == 6 --[[ name ]] and values[ index + 1 ] == "=" and not keywords[ value ] then
            index = index + 2
            field = {
                type = 32 --[[ TableField ]],
                kind = "named",
                name = value,
                value = parse_expression(),
                line = field_line,
            }
        else
            field = {
                type = 32 --[[ TableField ]],
                kind = "list",
                value = parse_expression(),
                line = field_line,
            }
        end

        field_count = field_count + 1
        fields[ field_count ] = field

        value = values[ index ]

        if value == "," or value == ";" then
            index = index + 1
            goto field_parser
        end
    end

    expect( "}", "{", opening_index )

    return {
        type = 23 --[[ Table ]],
        fields = fields,
        line = line,
        end_line = lines[ index - 1 ]
    }
end

---@return dreamwork.std.lua.ast.Expression[]
local function parse_call_arguments()
    local value, token_type = values[ index ], types[ index ]

    if token_type == 4 --[[ string ]] then
        local str, error_message = decodeString( value )
        if error_message ~= nil then
            syntax_error( error_message )
        end

        index = index + 1

        return {
            {
                type = 20 --[[ String ]],
                value = str,
                raw = value,
                line = lines[ index - 1 ],
            },
        }
    elseif value == "{" then
        return {
            parse_table(),
        }
    end

    local opening_index = index
    expect( "(" )

    if values[ index ] == ")" then
        index = index + 1
        return {}
    end

    local arguments = parse_expression_list()
    expect( ")", "(", opening_index )

    return arguments
end

---@return dreamwork.std.lua.ast.Expression
local function parse_primary_expression()
    local value, line = values[ index ], lines[ index ]

    if value == "(" then
        local opening_index = index
        index = index + 1

        local expression = parse_expression()
        expect( ")", "(", opening_index )

        return {
            type = 31 --[[ Paren ]],
            expression = expression,
            line = line,
        }
    elseif types[ index ] == 6 --[[ name ]] and not keywords[ value ] then
        index = index + 1

        return {
            type = 26 --[[ Identifier ]],
            name = value,
            line = line,
        }
    end

    ---@diagnostic disable-next-line: missing-return
    syntax_error( "unexpected symbol" )
end

---@return dreamwork.std.lua.ast.Expression
local function parse_suffixed_expression()
    local expression = parse_primary_expression()

    ::suffix_parser::

    local value, token_type, line = values[ index ], types[ index ], lines[ index ]

    if value == "." then
        index = index + 1

        expression = {
            type = 27 --[[ Member ]],
            object = expression,
            name = expect_name(),
            line = line,
        }

        goto suffix_parser
    elseif value == "[" then
        local opening_index = index
        index = index + 1

        local key = parse_expression()
        expect( "]", "[", opening_index )

        expression = {
            type = 28 --[[ Index ]],
            object = expression,
            key = key,
            line = line,
        }

        goto suffix_parser
    elseif value == ":" then
        index = index + 1
        local method = expect_name()

        expression = {
            type = 30 --[[ MethodCall ]],
            object = expression,
            method = method,
            arguments = parse_call_arguments(),
            line = line,
            end_line = lines[ index - 1 ],
        }

        goto suffix_parser
    elseif value == "(" or value == "{" or token_type == 4 --[[ string ]] then
        expression = {
            type = 29 --[[ Call ]],
            callee = expression,
            arguments = parse_call_arguments(),
            line = line,
            end_line = lines[ index - 1 ],
        }

        goto suffix_parser
    end

    return expression
end

---@return dreamwork.std.lua.ast.Expression
local function parse_simple_expression()
    local value, token_type, line = values[ index ], types[ index ], lines[ index ]

    if token_type == 5 --[[ number ]] then
        local number, error_message = decodeNumber( value )
        if error_message ~= nil then
            syntax_error( error_message )
        end

        index = index + 1

        return {
            type = 19 --[[ Number ]],
            value = number,
            raw = value,
            line = line,
        }
    elseif token_type == 4 --[[ string ]] then
        local str, error_message = decodeString( value )
        if error_message ~= nil then
            syntax_error( error_message )
        end

        index = index + 1

        return {
            type = 20 --[[ String ]],
            value = str,
            raw = value,
            line = line,
        }
    elseif value == "nil" then
        index = index + 1

        return {
            type = 17 --[[ Nil ]],
            line = line,
        }
    elseif value == "true" then
        index = index + 1

        return {
            type = 18 --[[ Boolean ]],
            value = true,
            line = line,
        }
    elseif value == "false" then
        index = index + 1

        return {
            type = 18 --[[ Boolean ]],
            value = false,
            line = line,
        }
    elseif value == "..." then
        index = index + 1

        return {
            type = 21 --[[ Vararg ]],
            line = line,
        }
    elseif value == "{" then
        return parse_table()
    elseif value == "function" then
        index = index + 1
        return parse_function_body( line, false )
    end

    return parse_suffixed_expression()
end

---@param limit integer
---@return dreamwork.std.lua.ast.Expression
function parse_subexpression( limit )
    local value = values[ index ]

    ---@type dreamwork.std.lua.ast.Expression
    local expression

    if unary_operators[ value ] then
        local line = lines[ index ]
        index = index + 1

        expression = {
            type = 25 --[[ Unary ]],
            operator = canonical_operators[ value ] or value,
            argument = parse_subexpression( UNARY_PRIORITY ),
            line = line,
        }
    else
        expression = parse_simple_expression()
    end

    ::operator_parser::

    value = values[ index ]

    local left_priority = binary_left[ value ]
    if left_priority ~= nil and left_priority > limit then
        local line = lines[ index ]
        index = index + 1

        expression = {
            type = 24 --[[ Binary ]],
            operator = canonical_operators[ value ] or value,
            left = expression,
            right = parse_subexpression( binary_right[ value ] ),
            line = line,
        }

        goto operator_parser
    end

    return expression
end

---@return dreamwork.std.lua.ast.Expression
function parse_expression()
    return parse_subexpression( 0 )
end

---@param line integer
---@param is_method boolean
---@return dreamwork.std.lua.ast.Function
function parse_function_body( line, is_method )
    local opening_index = index
    expect( "(" )

    ---@type dreamwork.std.lua.ast.Identifier[]
    local parameters, parameter_count = {}, 0
    local vararg = false

    if values[ index ] ~= ")" then
        ::parameter_parser::

        if values[ index ] == "..." then
            index = index + 1
            vararg = true
        else
            parameter_count = parameter_count + 1
            parameters[ parameter_count ] = parse_identifier()

            if values[ index ] == "," then
                index = index + 1
                goto parameter_parser
            end
        end
    end

    expect( ")", "(", opening_index )

    local body = parse_block()
    expect( "end", "function", opening_index - 1 )

    return {
        type = 22 --[[ Function ]],
        parameters = parameters,
        vararg = vararg,
        is_method = is_method,
        body = body,
        line = line,
        end_line = lines[ index - 1 ]
    }
end

---@param expression dreamwork.std.lua.ast.Expression
---@return boolean
local function is_assignable( expression )
    local expression_type = expression.type
    return expression_type == 26 --[[ Identifier ]] or expression_type == 27 --[[ Member ]] or expression_type == 28 --[[ Index ]]
end

---@param line integer
---@return dreamwork.std.lua.ast.Statement
local function parse_expression_statement( line )
    local expression = parse_suffixed_expression()

    local value = values[ index ]
    if value == "=" or value == "," then
        local targets, target_count = { expression }, 1

        while values[ index ] == "," do
            index = index + 1

            local target = parse_suffixed_expression()
            target_count = target_count + 1
            targets[ target_count ] = target
        end

        for i = 1, target_count, 1 do
            if not is_assignable( targets[ i ] ) then
                syntax_error( "syntax error" )
            end
        end

        expect( "=" )

        return {
            type = 4 --[[ Assignment ]],
            targets = targets,
            values = parse_expression_list(),
            line = line,
        }
    end

    local expression_type = expression.type
    if expression_type ~= 29 --[[ Call ]] and expression_type ~= 30 --[[ MethodCall ]] then
        syntax_error( "syntax error" )
    end

    ---@cast expression dreamwork.std.lua.ast.Call | dreamwork.std.lua.ast.MethodCall

    return {
        type = 5 --[[ CallStatement ]],
        call = expression,
        line = line
    }
end

---@return dreamwork.std.lua.ast.Statement | nil
local function parse_statement()
    local value, line = values[ index ], lines[ index ]

    if value == "local" then
        index = index + 1

        if values[ index ] == "function" then
            index = index + 1

            return {
                type = 2 --[[ LocalFunction ]],
                name = parse_identifier(),
                func = parse_function_body( line, false ),
                line = line,
            }
        end

        local names, name_count = { parse_identifier() }, 1

        while values[ index ] == "," do
            index = index + 1
            name_count = name_count + 1
            names[ name_count ] = parse_identifier()
        end

        if values[ index ] == "=" then
            index = index + 1

            return {
                type = 1 --[[ Local ]],
                names = names,
                values = parse_expression_list(),
                line = line,
            }
        end

        return {
            type = 1 --[[ Local ]],
            names = names,
            values = {},
            line = line,
        }
    elseif value == "if" then
        local opening_index = index
        index = index + 1

        ---@type dreamwork.std.lua.ast.IfClause[]
        local clauses, clause_count = {}, 0

        local clause_line = line

        ::clause_parser::

        local condition = parse_expression()
        expect( "then" )

        clause_count = clause_count + 1
        clauses[ clause_count ] = { condition = condition, body = parse_block(), line = clause_line }

        value = values[ index ]
        if value == "elseif" then
            clause_line = lines[ index ]
            index = index + 1
            goto clause_parser
        end

        local else_body, else_line
        if value == "else" then
            else_line = lines[ index ]
            index = index + 1
            else_body = parse_block()
        end

        expect( "end", "if", opening_index )

        return {
            type = 9 --[[ If ]],
            clauses = clauses,
            else_body = else_body,
            else_line = else_line,
            line = line,
            end_line = lines[ index - 1 ],
        }
    elseif value == "while" then
        local opening_index = index
        index = index + 1

        local condition = parse_expression()
        expect( "do" )

        local body = parse_block()
        expect( "end", "while", opening_index )

        return {
            type = 7 --[[ While ]],
            condition = condition,
            body = body,
            line = line,
            end_line = lines[ index - 1 ],
        }
    elseif value == "for" then
        local opening_index = index
        index = index + 1

        local variable = parse_identifier()

        if values[ index ] == "=" then
            index = index + 1

            local start = parse_expression()
            expect( "," )

            local limit = parse_expression()

            local step
            if values[ index ] == "," then
                index = index + 1
                step = parse_expression()
            end

            expect( "do" )

            local body = parse_block()
            expect( "end", "for", opening_index )

            return {
                type = 10 --[[ NumericFor ]],
                variable = variable,
                start = start,
                limit = limit,
                step = step,
                body = body,
                line = line,
                end_line = lines[ index - 1 ],
            }
        end

        local variables, variable_count = { variable }, 1

        while values[ index ] == "," do
            index = index + 1
            variable_count = variable_count + 1
            variables[ variable_count ] = parse_identifier()
        end

        expect( "in" )

        local iterators = parse_expression_list()
        expect( "do" )

        local body = parse_block()
        expect( "end", "for", opening_index )

        return {
            type = 11 --[[ GenericFor ]],
            variables = variables,
            iterators = iterators,
            body = body,
            line = line,
            end_line = lines[ index - 1 ],
        }
    elseif value == "function" then
        index = index + 1

        local target_line = lines[ index ]
        local is_method = false

        ---@type dreamwork.std.lua.ast.Identifier | dreamwork.std.lua.ast.Member
        local target = {
            type = 26 --[[ Identifier ]],
            name = expect_name(),
            line = target_line,
        }

        while values[ index ] == "." do
            index = index + 1
            target = {
                type = 27 --[[ Member ]],
                object = target,
                name = expect_name(),
                line = target_line,
            }
        end

        if values[ index ] == ":" then
            index = index + 1
            is_method = true
            target = {
                type = 27 --[[ Member ]],
                object = target,
                name = expect_name(),
                line = target_line,
            }
        end

        return {
            type = 3 --[[ FunctionDeclaration ]],
            target = target,
            func = parse_function_body( line, is_method ),
            line = line,
        }
    elseif value == "do" then
        local opening_index = index
        index = index + 1

        local body = parse_block()
        expect( "end", "do", opening_index )

        return {
            type = 6 --[[ Do ]],
            body = body,
            line = line,
            end_line = lines[ index - 1 ],
        }
    elseif value == "repeat" then
        local opening_index = index
        index = index + 1

        local body = parse_block()
        expect( "until", "repeat", opening_index )

        return {
            type = 8 --[[ Repeat ]],
            body = body,
            condition = parse_expression(),
            line = line,
        }
    elseif value == "return" then
        index = index + 1

        local return_values
        value = values[ index ]

        if index > count or block_ends[ value ] or value == ";" then
            return_values = {}
        else
            return_values = parse_expression_list()
        end

        if values[ index ] == ";" then
            index = index + 1
        end

        if index <= count and not block_ends[ values[ index ] ] then
            syntax_error( "'<eof>' expected" )
        end

        return {
            type = 12 --[[ Return ]],
            values = return_values,
            line = line,
        }
    elseif value == "break" then
        index = index + 1

        return {
            type = 13 --[[ Break ]],
            line = line,
        }
    elseif value == "continue" and types[ index ] == 6 --[[ name ]] then
        -- GLua `continue`, still usable as a name in expressions
        local next_value = values[ index + 1 ]
        if next_value ~= "=" and next_value ~= "." and next_value ~= "[" and next_value ~= ":" and next_value ~= "(" and next_value ~= "," then
            index = index + 1

            return {
                type = 14 --[[ Continue ]],
                line = line,
            }
        end
    elseif value == "goto" and types[ index + 1 ] == 6 --[[ name ]] then
        index = index + 1

        return {
            type = 15 --[[ Goto ]],
            label = expect_name(),
            line = line
        }
    elseif value == "::" then
        index = index + 1

        local name = expect_name()
        expect( "::" )

        return {
            type = 16 --[[ Label ]],
            name = name,
            line = line,
        }
    elseif value == ";" then
        index = index + 1
        return nil
    end

    return parse_expression_statement( line )
end

---@return dreamwork.std.lua.ast.Statement[]
function parse_block()
    ---@type dreamwork.std.lua.ast.Statement[]
    local statements, statement_count = {}, 0

    ::statement_parser::

    if index <= count and not block_ends[ values[ index ] ] then
        local statement = parse_statement()
        if statement ~= nil then
            statement_count = statement_count + 1
            statements[ statement_count ] = statement
        end

        goto statement_parser
    end

    return statements
end

--- Copies significant tokens into the parser state.
---
---@param token_types integer[]
---@param token_values string[]
---@param token_lines integer[]
---@param token_count integer
---@param name string
local function load_tokens( token_types, token_values, token_lines, token_count, name )
    types, values, lines, count, index, chunk_name = {}, {}, {}, 0, 1, name

    if token_count == 0 then
        last_line = 1
    else
        last_line = token_lines[ token_count ] + lexer.countNewlines( token_values[ token_count ] )
    end

    for i = 1, token_count, 1 do
        local token_type = token_types[ i ]
        if token_type == 8 --[[ directive ]] then
            unload_tokens()
            error( SyntaxErrorClass( "unexpected directive near '" .. token_values[ i ] .. "'", name, token_lines[ i ] ), 3 )
        elseif token_type ~= 1 --[[ space ]] and token_type ~= 2 --[[ newline ]] and token_type ~= 3 --[[ comment ]] then
            count = count + 1
            types[ count ], values[ count ], lines[ count ] = token_type, token_values[ i ], token_lines[ i ]
        end
    end
end

---@return dreamwork.std.lua.ast.Chunk
local function parse_chunk()
    local body = parse_block()
    if index <= count then
        syntax_error( "'<eof>' expected" )
    end

    local chunk = {
        type = 33 --[[ Chunk ]],
        name = chunk_name,
        body = body,
        line = 1,
        end_line = last_line
    }

    unload_tokens()
    return chunk
end

--- [SHARED AND MENU]
---
--- Parses Lua code into an AST.
---
---@param code string The Lua code to parse.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return dreamwork.std.lua.ast.Chunk chunk The root node of the AST.
---@nodiscard
function parser.parse( code, name )
    local token_types, token_values, token_lines, token_count = lexer_tokenize( code )
    load_tokens( token_types, token_values, token_lines, token_count, name or "lua" )
    return parse_chunk()
end

--- [SHARED AND MENU]
---
--- Parses tokens returned by `lexer.tokenize` into an AST.
---
---@param token_types integer[] The token types.
---@param token_values string[] The token values.
---@param token_lines integer[] The token lines.
---@param token_count integer The number of tokens.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return dreamwork.std.lua.ast.Chunk chunk The root node of the AST.
---@nodiscard
function parser.parseTokens( token_types, token_values, token_lines, token_count, name )
    load_tokens( token_types, token_values, token_lines, token_count, name or "lua" )
    return parse_chunk()
end

--- [SHARED AND MENU]
---
--- Parses a single Lua expression into an AST.
---
---@param code string The Lua expression to parse.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return dreamwork.std.lua.ast.Expression expression The root node of the expression.
---@nodiscard
function parser.parseExpression( code, name )
    local token_types, token_values, token_lines, token_count = lexer_tokenize( code )
    load_tokens( token_types, token_values, token_lines, token_count, name or "lua" )

    local expression = parse_expression()
    if index <= count then
        syntax_error( "'<eof>' expected" )
    end

    unload_tokens()
    return expression
end
