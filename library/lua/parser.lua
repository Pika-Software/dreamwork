---@meta _

--- [SHARED AND MENU]
---
--- An error raised when Lua code cannot be parsed.
---
---@class lua.SyntaxError : Error
---@field __class lua.SyntaxErrorClass
---@field __parent Error
---@field message string The error message.
---@field chunk_name string The name of the chunk where the error occurred.
---@field line integer The line where the error occurred.
local SyntaxError = {}

---@param message string
---@param chunk_name string
---@param line integer
---@protected
function SyntaxError:__init(message, chunk_name, line) end

---@param error_message string
---@return string
---@protected
function SyntaxError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `SyntaxError` instances.
---
---@class lua.SyntaxErrorClass : lua.SyntaxError, Class
---@field __base lua.SyntaxError
---@field __parent ErrorClass
---@overload fun( message: string, chunk_name: string, line: integer ): lua.SyntaxError
lua.SyntaxError = {}

--- [SHARED AND MENU]
---
--- Lua 5.1 / LuaJIT ( and GLua ) parser, builds an AST from code or tokens.
---
--- AST nodes are plain tables with a `type` field, see `lua.ast.*`.
---
--- GLua operators are normalized: `!=` -> `~=`, `&&` -> `and`, `||` -> `or`, `!` -> `not`.
---
---@class lua.parser
lua.parser = {}

--- [SHARED AND MENU]
---
--- `Local` statement node, see `lua.ast.Local`.
lua.parser.NODE_LOCAL = 1

--- [SHARED AND MENU]
---
--- `LocalFunction` statement node, see `lua.ast.LocalFunction`.
lua.parser.NODE_LOCAL_FUNCTION = 2

--- [SHARED AND MENU]
---
--- `FunctionDeclaration` statement node, see `lua.ast.FunctionDeclaration`.
lua.parser.NODE_FUNCTION_DECLARATION = 3

--- [SHARED AND MENU]
---
--- `Assignment` statement node, see `lua.ast.Assignment`.
lua.parser.NODE_ASSIGNMENT = 4

--- [SHARED AND MENU]
---
--- `CallStatement` statement node, see `lua.ast.CallStatement`.
lua.parser.NODE_CALL_STATEMENT = 5

--- [SHARED AND MENU]
---
--- `Do` statement node, see `lua.ast.Do`.
lua.parser.NODE_DO = 6

--- [SHARED AND MENU]
---
--- `While` statement node, see `lua.ast.While`.
lua.parser.NODE_WHILE = 7

--- [SHARED AND MENU]
---
--- `Repeat` statement node, see `lua.ast.Repeat`.
lua.parser.NODE_REPEAT = 8

--- [SHARED AND MENU]
---
--- `If` statement node, see `lua.ast.If`.
lua.parser.NODE_IF = 9

--- [SHARED AND MENU]
---
--- `NumericFor` statement node, see `lua.ast.NumericFor`.
lua.parser.NODE_NUMERIC_FOR = 10

--- [SHARED AND MENU]
---
--- `GenericFor` statement node, see `lua.ast.GenericFor`.
lua.parser.NODE_GENERIC_FOR = 11

--- [SHARED AND MENU]
---
--- `Return` statement node, see `lua.ast.Return`.
lua.parser.NODE_RETURN = 12

--- [SHARED AND MENU]
---
--- `Break` statement node, see `lua.ast.Break`.
lua.parser.NODE_BREAK = 13

--- [SHARED AND MENU]
---
--- `Continue` statement node, see `lua.ast.Continue`.
lua.parser.NODE_CONTINUE = 14

--- [SHARED AND MENU]
---
--- `Goto` statement node, see `lua.ast.Goto`.
lua.parser.NODE_GOTO = 15

--- [SHARED AND MENU]
---
--- `Label` statement node, see `lua.ast.Label`.
lua.parser.NODE_LABEL = 16

--- [SHARED AND MENU]
---
--- `Nil` expression node, see `lua.ast.Nil`.
lua.parser.NODE_NIL = 17

--- [SHARED AND MENU]
---
--- `Boolean` expression node, see `lua.ast.Boolean`.
lua.parser.NODE_BOOLEAN = 18

--- [SHARED AND MENU]
---
--- `Number` expression node, see `lua.ast.Number`.
lua.parser.NODE_NUMBER = 19

--- [SHARED AND MENU]
---
--- `String` expression node, see `lua.ast.String`.
lua.parser.NODE_STRING = 20

--- [SHARED AND MENU]
---
--- `Vararg` expression node, see `lua.ast.Vararg`.
lua.parser.NODE_VARARG = 21

--- [SHARED AND MENU]
---
--- `Function` expression node, see `lua.ast.Function`.
lua.parser.NODE_FUNCTION = 22

--- [SHARED AND MENU]
---
--- `Table` expression node, see `lua.ast.Table`.
lua.parser.NODE_TABLE = 23

--- [SHARED AND MENU]
---
--- `Binary` expression node, see `lua.ast.Binary`.
lua.parser.NODE_BINARY = 24

--- [SHARED AND MENU]
---
--- `Unary` expression node, see `lua.ast.Unary`.
lua.parser.NODE_UNARY = 25

--- [SHARED AND MENU]
---
--- `Identifier` expression node, see `lua.ast.Identifier`.
lua.parser.NODE_IDENTIFIER = 26

--- [SHARED AND MENU]
---
--- `Member` expression node, see `lua.ast.Member`.
lua.parser.NODE_MEMBER = 27

--- [SHARED AND MENU]
---
--- `Index` expression node, see `lua.ast.Index`.
lua.parser.NODE_INDEX = 28

--- [SHARED AND MENU]
---
--- `Call` expression node, see `lua.ast.Call`.
lua.parser.NODE_CALL = 29

--- [SHARED AND MENU]
---
--- `MethodCall` expression node, see `lua.ast.MethodCall`.
lua.parser.NODE_METHOD_CALL = 30

--- [SHARED AND MENU]
---
--- `Paren` expression node, see `lua.ast.Paren`.
lua.parser.NODE_PAREN = 31

--- [SHARED AND MENU]
---
--- `TableField` node, see `lua.ast.TableField`.
lua.parser.NODE_TABLE_FIELD = 32

--- [SHARED AND MENU]
---
--- `Chunk` node, see `lua.ast.Chunk`.
lua.parser.NODE_CHUNK = 33

--- [SHARED AND MENU]
---
--- Node type names, indexed by node type.
---
---@type string[]
lua.parser.NODE_NAMES = {}

--- [SHARED AND MENU]
---
--- Decodes a string literal token ( quoted or long bracket ) into its value.
---
---@param str string The string literal with quotes or brackets.
---@return string | nil value The decoded value, or `nil` if the literal is malformed.
---@return string | nil error_message The reason the literal is malformed.
function lua.parser.decodeString(str) end

--- [SHARED AND MENU]
---
--- Decodes a number literal token.
---
--- LuaJIT `LL`, `ULL` and `i` literals are valid but cannot be represented as a Lua number, so they return `nil` without an error.
---
---@param str string The number literal.
---@return number | nil value The number, or `nil` if the literal is a 64-bit / imaginary literal or malformed.
---@return string | nil error_message The reason the literal is malformed.
function lua.parser.decodeNumber(str) end

--- [SHARED AND MENU]
---
--- Parses Lua code into an AST.
---
---@param code string The Lua code to parse.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return lua.ast.Chunk chunk The root node of the AST.
---@nodiscard
function lua.parser.parse(code, name) end

--- [SHARED AND MENU]
---
--- Parses tokens returned by `lexer.tokenize` into an AST.
---
---@param token_types integer[] The token types.
---@param token_values string[] The token values.
---@param token_lines integer[] The token lines.
---@param token_count integer The number of tokens.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return lua.ast.Chunk chunk The root node of the AST.
---@nodiscard
function lua.parser.parseTokens(token_types, token_values, token_lines, token_count, name) end

--- [SHARED AND MENU]
---
--- Parses a single Lua expression into an AST.
---
---@param code string The Lua expression to parse.
---@param name string? The chunk name used in errors, `"lua"` by default.
---@return lua.ast.Expression expression The root node of the expression.
---@nodiscard
function lua.parser.parseExpression(code, name) end
