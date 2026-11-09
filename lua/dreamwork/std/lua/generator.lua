---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.lua
local lua = std.lua

local setmetatable = std.setmetatable

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_rep = string.rep
local string_byte = string.byte
local string_escape = string.escape
local string_format = string.format
local string_byteRep = string.byteRep

local table = std.table
local table_concat = table.concat

local math = std.math
local math_huge = math.huge
local math_floor = math.floor

local lexer = lua.lexer
local lexer_isIdentifier = lexer.isIdentifier
local lexer_countNewlines = lexer.countNewlines

--- [SHARED AND MENU]
---
--- Lua code generator, turns AST from `std.lua.parser` ( or a hand-made one ) back into Lua code.
---
--- Parentheses are added where operator priorities require them, so hand-made ASTs do not need `Paren` nodes.
---
--- Comments are not part of the AST and are not generated.
---
---@class dreamwork.std.lua.generator
local generator = {}
lua.generator = generator

---@type table<integer, boolean>
local is_word = { [ 0x5F --[[ _ ]] ] = true }

for byte = 0x30, 0x39, 1 do
    is_word[ byte ] = true
end

for byte = 0x41, 0x5A, 1 do
    is_word[ byte ], is_word[ byte + 0x20 ] = true, true
end

for byte = 0x80, 0xFF, 1 do
    is_word[ byte ] = true
end

--- Bytes that form a different token when repeated: `- -`, `[ [`, `. .`.
---
---@type table<integer, boolean>
local is_sticky = {
    [ 0x2D --[[ - ]] ] = true,
    [ 0x5B --[[ [ ]] ] = true,
    [ 0x2E --[[ . ]] ] = true
}

---@type table<string, integer>
local priorities = {
    [ "or" ] = 1,
    [ "and" ] = 2,
    [ "<" ] = 3,
    [ ">" ] = 3,
    [ "<=" ] = 3,
    [ ">=" ] = 3,
    [ "~=" ] = 3,
    [ "==" ] = 3,
    [ ".." ] = 5,
    [ "+" ] = 6,
    [ "-" ] = 6,
    [ "*" ] = 7,
    [ "/" ] = 7,
    [ "%" ] = 7,
    [ "^" ] = 10
}

local UNARY_PRIORITY = 8
local ATOM_PRIORITY = 11

--- Expressions that can be called or indexed without parentheses.
---
---@type table<integer, boolean>
local prefix_types = {
    [ 26 --[[ Identifier ]] ] = true,
    [ 31 --[[ Paren ]] ] = true,
    [ 27 --[[ Member ]] ] = true,
    [ 28 --[[ Index ]] ] = true,
    [ 29 --[[ Call ]] ] = true,
    [ 30 --[[ MethodCall ]] ] = true
}

--- [SHARED AND MENU]
---
--- Converts a number into a Lua number literal that reads back as the same number.
---
--- `inf`, `-inf` and `nan` become `(1/0)`, `(-1/0)` and `(0/0)`.
---
---@param value number The number to format.
---@return string literal The number literal.
---@nodiscard
local function formatNumber( value )
    if value ~= value then
        return "(0/0)"
    elseif value == math_huge then
        return "(1/0)"
    elseif value == -math_huge then
        return "(-1/0)"
    elseif value == math_floor( value ) and value > -9007199254740992 and value < 9007199254740992 then
        if value == 0 and 1 / value < 0 then
            return "-0"
        end

        return string_format( "%d", value )
    end

    local str = string_format( "%.14g", value )

    if raw_tonumber( str ) ~= value then
        str = string_format( "%.17g", value )
    end

    return str
end

generator.formatNumber = formatNumber

-- generator state, the generator does not call user code, so it is never re-entered

---@type string[]
local buffer = {}
local buffer_size = 0

local last_byte = 0
local last_number = false

local depth = 0
local current_line = 1

local compact = false
local keep_lines = false

---@type table<integer, string>
local indents = {}

--- Appends the string as is.
---
---@param str string
local function append( str )
    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = str
    last_byte, last_number = string_byte( str, -1 ), false
end

--- Appends the string, separating it with a space if it would merge with the previous one.
---
---@param str string
local function write( str )
    local first_byte = string_byte( str, 1 )

    if (is_word[ first_byte ] and is_word[ last_byte ]) or (first_byte == last_byte and is_sticky[ first_byte ]) or (last_number and first_byte == 0x2E --[[ . ]]) then
        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = " "
    end

    buffer_size = buffer_size + 1
    buffer[ buffer_size ] = str
    last_byte, last_number = string_byte( str, -1 ), false
end

--- A space in readable mode, nothing in compact mode.
local function space()
    if not compact then
        append( " " )
    end
end

--- `, ` in readable mode, `,` in compact mode.
local function comma()
    if compact then
        append( "," )
    else
        append( ", " )
    end
end

--- Moves to the original line of the node if lines are kept and it is below the current one.
---
---@param line integer | nil
---@return boolean moved
local function sync_line( line )
    if keep_lines and line ~= nil and line > current_line then
        append( string_byteRep( 0x0A, line - current_line ) .. indents[ depth ] )
        current_line = line
        return true
    end

    return false
end

--- Moves to the next line ( or to the given line if lines are kept ).
---
---@param line integer | nil The original line of the next node.
local function next_line( line )
    if keep_lines then
        if not sync_line( line ) and buffer_size ~= 0 then
            space()
        end
    elseif buffer_size ~= 0 and not compact then
        append( "\n" .. indents[ depth ] )
    end
end

local emit_expression, emit_block

---@param node dreamwork.std.lua.ast.Expression
---@return integer
local function expression_priority( node )
    local node_type = node.type
    if node_type == 24 --[[ Binary ]] then
        return priorities[ node.operator ]
    elseif node_type == 25 --[[ Unary ]] then
        return UNARY_PRIORITY
    elseif node_type == 19 --[[ Number ]] and node.raw == nil then
        local value = node.value
        if value < 0 or (value == 0 and 1 / value < 0) then
            return UNARY_PRIORITY
        end
    end

    return ATOM_PRIORITY
end

---@param node dreamwork.std.lua.ast.Expression
---@param wrap boolean
local function emit_wrapped( node, wrap )
    if wrap then
        append( "(" )
        emit_expression( node )
        append( ")" )
    else
        emit_expression( node )
    end
end

---@param node dreamwork.std.lua.ast.Expression
local function emit_prefix( node )
    emit_wrapped( node, not prefix_types[ node.type ] )
end

---@param expressions dreamwork.std.lua.ast.Expression[]
local function emit_list( expressions )
    for i = 1, #expressions, 1 do
        if i ~= 1 then
            comma()
        end

        emit_expression( expressions[ i ] )
    end
end

--- Writes `( <list> )`.
---
---@param expressions dreamwork.std.lua.ast.Expression[]
---@param end_line integer | nil The line of the closing `)`.
local function emit_arguments( expressions, end_line )
    if expressions[ 1 ] == nil then
        append( "(" )
        sync_line( end_line )
        append( ")" )
        return
    end

    append( "(" )
    space()
    emit_list( expressions )

    if not sync_line( end_line ) then
        space()
    end

    append( ")" )
end

---@param key string
local function emit_string_key( key )
    append( "[" )
    space()
    write( "\"" .. string_escape( key ) .. "\"" )
    space()
    append( "]" )
end

---@param node dreamwork.std.lua.ast.Function
---@param name_writer fun() | nil
local function emit_function( node, name_writer )
    write( "function" )

    if name_writer ~= nil then
        append( " " )
        name_writer()
    end

    local parameters = node.parameters
    local parameter_count = #parameters

    if parameter_count == 0 and not node.vararg then
        append( "()" )
    else
        append( "(" )
        space()

        for i = 1, parameter_count, 1 do
            if i ~= 1 then
                comma()
            end

            write( parameters[ i ].name )
        end

        if node.vararg then
            if parameter_count ~= 0 then
                comma()
            end

            write( "..." )
        end

        space()
        append( ")" )
    end

    emit_block( node.body, node.end_line, "end" )
end

---@param node dreamwork.std.lua.ast.Table
local function emit_table( node )
    local fields = node.fields
    local field_count = #fields

    if field_count == 0 then
        write( "{}" )
        return
    end

    local multiline = false

    if not (compact or keep_lines) then
        for i = 1, field_count, 1 do
            local field = fields[ i ]
            local value_type = field.value.type
            if field.kind ~= "list" or value_type == 23 --[[ Table ]] or value_type == 22 --[[ Function ]] then
                multiline = true
                break
            end
        end
    end

    write( "{" )

    if multiline then
        depth = depth + 1
    end

    for i = 1, field_count, 1 do
        local field = fields[ i ]

        if i ~= 1 then
            append( "," )
        end

        if multiline then
            append( "\n" .. indents[ depth ] )
        elseif keep_lines then
            next_line( field.line )
        else
            space()
        end

        local kind = field.kind
        if kind == "named" then
            local name = field.name
            ---@cast name string

            if lexer_isIdentifier( name ) then
                write( name )
            else
                emit_string_key( name )
            end

            space()
            append( "=" )
            space()
        elseif kind == "index" then
            append( "[" )
            space()
            emit_expression( field.key )
            space()
            append( "]" )
            space()
            append( "=" )
            space()
        end

        emit_expression( field.value )
    end

    if multiline then
        depth = depth - 1
        append( "\n" .. indents[ depth ] )
    elseif keep_lines and node.end_line ~= nil and node.end_line > current_line then
        next_line( node.end_line )
    else
        space()
    end

    append( "}" )
end

---@type table<integer, fun( node: dreamwork.std.lua.ast.Expression )>
local expression_emitters = {}

expression_emitters[ 17 --[[ Nil ]] ] = function()
    write( "nil" )
end

---@param node dreamwork.std.lua.ast.Boolean
expression_emitters[ 18 ] = function( node )
    write( node.value and "true" or "false" )
end

expression_emitters[ 21 --[[ Vararg ]] ] = function()
    write( "..." )
end

---@param node dreamwork.std.lua.ast.Number
expression_emitters[ 19 ] = function( node )
    write( node.raw or formatNumber( node.value ) )
    last_number = true
end

---@param node dreamwork.std.lua.ast.String
expression_emitters[ 20 ] = function( node )
    local str = node.raw
    if str == nil then
        write( "\"" .. string_escape( node.value ) .. "\"" )
        return
    end

    write( str )

    if keep_lines then
        current_line = current_line + lexer_countNewlines( str )
    end
end

---@param node dreamwork.std.lua.ast.Identifier
expression_emitters[ 26 ] = function( node )
    write( node.name )
end

---@param node dreamwork.std.lua.ast.Paren
expression_emitters[ 31 ] = function( node )
    append( "(" )
    emit_expression( node.expression )
    append( ")" )
end

---@param node dreamwork.std.lua.ast.Function
expression_emitters[ 22 ] = function( node )
    emit_function( node, nil )
end

expression_emitters[ 23 --[[ Table ]] ] = emit_table

---@param node dreamwork.std.lua.ast.Binary
expression_emitters[ 24 ] = function( node )
    local operator = node.operator
    local priority = priorities[ operator ]
    local right_associative = operator == ".." or operator == "^"

    local left_priority = expression_priority( node.left )
    emit_wrapped( node.left, left_priority < priority or (left_priority == priority and right_associative) )

    if sync_line( node.line ) then
        write( operator )
        append( " " )
    elseif compact then
        write( operator )
    else
        append( " " )
        append( operator )
        append( " " )
    end

    local right_priority = expression_priority( node.right )
    emit_wrapped( node.right, right_priority < priority or (right_priority == priority and not right_associative) )
end

---@param node dreamwork.std.lua.ast.Unary
expression_emitters[ 25 ] = function( node )
    local operator = node.operator
    write( operator )

    if operator == "not" and not compact then
        append( " " )
    end

    emit_wrapped( node.argument, expression_priority( node.argument ) < UNARY_PRIORITY )
end

---@param node dreamwork.std.lua.ast.Member
expression_emitters[ 27 ] = function( node )
    emit_prefix( node.object )

    local name = node.name
    if lexer_isIdentifier( name ) then
        append( "." )
        append( name )
    else
        emit_string_key( name )
    end
end

---@param node dreamwork.std.lua.ast.Index
expression_emitters[ 28 ] = function( node )
    emit_prefix( node.object )
    append( "[" )
    space()
    emit_expression( node.key )
    space()
    append( "]" )
end

---@param node dreamwork.std.lua.ast.Call
expression_emitters[ 29 ] = function( node )
    emit_prefix( node.callee )
    emit_arguments( node.arguments, node.end_line )
end

---@param node dreamwork.std.lua.ast.MethodCall
expression_emitters[ 30 ] = function( node )
    emit_prefix( node.object )
    append( ":" )
    append( node.method )
    emit_arguments( node.arguments, node.end_line )
end

--- Expressions that start with their own token, `Binary` and suffixed expressions start with their operand.
---
---@type table<integer, boolean>
local line_starters = {
    [ 17 --[[ Nil ]] ] = true,
    [ 18 --[[ Boolean ]] ] = true,
    [ 19 --[[ Number ]] ] = true,
    [ 20 --[[ String ]] ] = true,
    [ 21 --[[ Vararg ]] ] = true,
    [ 26 --[[ Identifier ]] ] = true,
    [ 31 --[[ Paren ]] ] = true,
    [ 22 --[[ Function ]] ] = true,
    [ 23 --[[ Table ]] ] = true,
    [ 25 --[[ Unary ]] ] = true
}

---@param node dreamwork.std.lua.ast.Expression
function emit_expression( node )
    local node_type = node.type

    if keep_lines and line_starters[ node_type ] then
        sync_line( node.line )
    end

    expression_emitters[ node_type ]( node )
end

--- Statements starting with `(` need a `;` before them, otherwise they continue the previous statement as a call.
---
---@param node dreamwork.std.lua.ast.Statement
---@return boolean
local function starts_with_paren( node )
    local node_type = node.type

    ---@type dreamwork.std.lua.ast.Expression
    local expression

    if node_type == 5 --[[ CallStatement ]] then
        expression = node.call
    elseif node_type == 4 --[[ Assignment ]] then
        expression = node.targets[ 1 ]
    else
        return false
    end

    ::prefix_walker::

    local expression_type = expression.type
    if expression_type == 29 --[[ Call ]] then
        expression = expression.callee
        goto prefix_walker
    elseif expression_type == 30 --[[ MethodCall ]] or expression_type == 27 --[[ Member ]] or expression_type == 28 --[[ Index ]] then
        expression = expression.object
        goto prefix_walker
    end

    return expression_type ~= 26 --[[ Identifier ]]
end

---@type table<integer, fun( node: dreamwork.std.lua.ast.Statement )>
local statement_emitters = {}

---@param node dreamwork.std.lua.ast.Statement
---@param is_first boolean `;` is not allowed at the start of a block.
local function emit_statement( node, is_first )
    next_line( node.line )

    if not is_first and starts_with_paren( node ) then
        append( ";" )
    end

    statement_emitters[ node.type ]( node )
end

--- Writes the statements and the closing keyword.
---
---@param body dreamwork.std.lua.ast.Statement[]
---@param end_line integer | nil
---@param closing string | nil
function emit_block( body, end_line, closing )
    local statement_count = #body

    depth = depth + 1

    for i = 1, statement_count, 1 do
        emit_statement( body[ i ], i == 1 )
    end

    depth = depth - 1

    if closing == nil then
        return
    end

    if statement_count == 0 and not keep_lines then
        space()
    else
        next_line( end_line )
    end

    write( closing )
end

---@param node dreamwork.std.lua.ast.Local
statement_emitters[ 1 ] = function( node )
    write( "local" )
    append( " " )

    local names = node.names
    for i = 1, #names, 1 do
        if i ~= 1 then
            comma()
        end

        write( names[ i ].name )
    end

    local values = node.values
    if values[ 1 ] ~= nil then
        space()
        append( "=" )
        space()
        emit_list( values )
    end
end

---@param node dreamwork.std.lua.ast.LocalFunction
statement_emitters[ 2 ] = function( node )
    write( "local" )
    append( " " )
    emit_function( node.func, function()
        write( node.name.name )
    end )
end

---@param target dreamwork.std.lua.ast.Identifier | dreamwork.std.lua.ast.Member
---@param is_method boolean
local function emit_function_name( target, is_method )
    if target.type == 26 --[[ Identifier ]] then
        write( target.name )
        return
    end

    ---@cast target dreamwork.std.lua.ast.Member

    local object = target.object
    ---@cast object dreamwork.std.lua.ast.Identifier | dreamwork.std.lua.ast.Member

    emit_function_name( object, false )
    append( is_method and ":" or "." )
    append( target.name )
end

---@param node dreamwork.std.lua.ast.FunctionDeclaration
statement_emitters[ 3 ] = function( node )
    local func = node.func
    emit_function( func, function()
        emit_function_name( node.target, func.is_method )
    end )
end

---@param node dreamwork.std.lua.ast.Assignment
statement_emitters[ 4 ] = function( node )
    emit_list( node.targets )
    space()
    append( "=" )
    space()
    emit_list( node.values )
end

---@param node dreamwork.std.lua.ast.CallStatement
statement_emitters[ 5 ] = function( node )
    emit_expression( node.call )
end

---@param node dreamwork.std.lua.ast.Do
statement_emitters[ 6 ] = function( node )
    write( "do" )
    emit_block( node.body, node.end_line, "end" )
end

---@param node dreamwork.std.lua.ast.While
statement_emitters[ 7 ] = function( node )
    write( "while" )
    append( " " )
    emit_expression( node.condition )
    append( " " )
    write( "do" )
    emit_block( node.body, node.end_line, "end" )
end

---@param node dreamwork.std.lua.ast.Repeat
statement_emitters[ 8 ] = function( node )
    write( "repeat" )
    emit_block( node.body, nil, "until" )
    append( " " )
    emit_expression( node.condition )
end

---@param node dreamwork.std.lua.ast.If
statement_emitters[ 9 ] = function( node )
    local clauses = node.clauses

    for i = 1, #clauses, 1 do
        local clause = clauses[ i ]

        if i == 1 then
            write( "if" )
        else
            next_line( clause.line )
            write( "elseif" )
        end

        append( " " )
        emit_expression( clause.condition )
        append( " " )
        write( "then" )
        emit_block( clause.body, nil, nil )
    end

    local else_body = node.else_body
    if else_body ~= nil then
        next_line( node.else_line )
        write( "else" )
        emit_block( else_body, nil, nil )
    end

    next_line( node.end_line )
    write( "end" )
end

---@param node dreamwork.std.lua.ast.NumericFor
statement_emitters[ 10 ] = function( node )
    write( "for" )
    append( " " )
    write( node.variable.name )
    space()
    append( "=" )
    space()
    emit_expression( node.start )
    comma()
    emit_expression( node.limit )

    local step = node.step
    if step ~= nil then
        comma()
        emit_expression( step )
    end

    append( " " )
    write( "do" )
    emit_block( node.body, node.end_line, "end" )
end

---@param node dreamwork.std.lua.ast.GenericFor
statement_emitters[ 11 ] = function( node )
    write( "for" )
    append( " " )

    local variables = node.variables
    for i = 1, #variables, 1 do
        if i ~= 1 then
            comma()
        end

        write( variables[ i ].name )
    end

    append( " " )
    write( "in" )
    append( " " )
    emit_list( node.iterators )
    append( " " )
    write( "do" )
    emit_block( node.body, node.end_line, "end" )
end

---@param node dreamwork.std.lua.ast.Return
statement_emitters[ 12 ] = function( node )
    write( "return" )

    local values = node.values
    if values[ 1 ] ~= nil then
        space()
        emit_list( values )
    end
end

statement_emitters[ 13 --[[ Break ]] ] = function()
    write( "break" )
end

statement_emitters[ 14 --[[ Continue ]] ] = function()
    write( "continue" )
end

---@param node dreamwork.std.lua.ast.Goto
statement_emitters[ 15 ] = function( node )
    write( "goto" )
    append( " " )
    write( node.label )
end

---@param node dreamwork.std.lua.ast.Label
statement_emitters[ 16 ] = function( node )
    append( "::" )
    append( node.name )
    append( "::" )
end

--- [SHARED AND MENU]
---
--- Generates Lua code from an AST node.
---
--- By default the code is formatted with one statement per line and indentation,
--- `options.compact` removes all optional whitespace, `options.lines` places statements on their original lines
--- ( line numbers in errors stay the same as in the parsed code ).
---
---@param node dreamwork.std.lua.ast.Node The AST node to generate code from, a chunk, a statement or an expression.
---@param options dreamwork.std.lua.GeneratorOptions? The generator options.
---@return string code The generated Lua code.
---@nodiscard
function generator.generate( node, options )
    local indent = "    "

    if options == nil then
        compact, keep_lines = false, false
    else
        compact, keep_lines = options.compact == true, options.lines == true
        indent = options.indent or indent
    end

    if compact then
        indent = ""
    end

    indents = setmetatable( { [ 0 ] = "" }, {
        __index = function( self, level )
            local str = string_rep( indent, level )
            self[ level ] = str
            return str
        end
    } )

    buffer, buffer_size = {}, 0
    last_byte, last_number = 0, false
    depth, current_line = 0, 1

    local node_type = node.type
    if node_type == 33 --[[ Chunk ]] then
        ---@cast node dreamwork.std.lua.ast.Chunk
        depth = -1
        emit_block( node.body, nil, nil )
        depth = 0
    elseif node_type <= 16 --[[ Label ]] then
        ---@cast node dreamwork.std.lua.ast.Statement
        emit_statement( node, true )
    else
        ---@cast node dreamwork.std.lua.ast.Expression
        emit_expression( node )
    end

    local code = table_concat( buffer, "", 1, buffer_size )
    buffer, buffer_size = {}, 0
    return code
end
