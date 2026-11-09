---@meta _

--- [SHARED AND MENU]
---
--- Lua 5.1 / LuaJIT lexer.
---
--- Tokens are returned as flat arrays ( `types`, `values`, `lines` ) instead of token tables,
--- whitespace, newlines and comments are kept as tokens, so concatenating all values gives back the original code.
---
---@class lua.lexer
lua.lexer = {}

--- [SHARED AND MENU]
---
--- Spaces and tabs, without newlines.
lua.lexer.TOKEN_SPACE = 1

--- [SHARED AND MENU]
---
--- A single `\n`.
lua.lexer.TOKEN_NEWLINE = 2

--- [SHARED AND MENU]
---
--- `--`, `--[[ ]]`, `//`, `/* */` comments and the shebang line.
lua.lexer.TOKEN_COMMENT = 3

--- [SHARED AND MENU]
---
--- Quoted and long bracket strings, the value includes quotes / brackets.
lua.lexer.TOKEN_STRING = 4

--- [SHARED AND MENU]
---
--- Number literals, including LuaJIT `LL`, `ULL` and `i` suffixes.
lua.lexer.TOKEN_NUMBER = 5

--- [SHARED AND MENU]
---
--- Names and keywords.
lua.lexer.TOKEN_NAME = 6

--- [SHARED AND MENU]
---
--- Operators and punctuation.
lua.lexer.TOKEN_SYMBOL = 7

--- [SHARED AND MENU]
---
--- A `#<name>` line accepted by the `is_directive` callback of `lexer.tokenize`, including `\` continued lines.
lua.lexer.TOKEN_DIRECTIVE = 8

--- [SHARED AND MENU]
---
--- Token type names, indexed by token type.
---
---@type string[]
lua.lexer.TOKEN_NAMES = {}

--- [SHARED AND MENU]
---
--- Reserved words of Lua 5.1 and LuaJIT ( `goto` ).
---
--- GLua `continue` is not here, the parser treats it as a keyword only at the start of a statement.
---
---@type table<string, boolean>
lua.lexer.keywords = nil

--- [SHARED AND MENU]
---
--- Checks if the string is a valid Lua name that is not a keyword.
---
--- GLua `continue` is rejected too, so the result is safe for both Lua and GLua.
---
---@param str string The string to check.
---@return boolean is_identifier `true` if the string can be used as a variable or field name.
---@nodiscard
function lua.lexer.isIdentifier(str) end

--- [SHARED AND MENU]
---
--- Counts `\n` characters in the string.
---
---@param str string The string to count newlines in.
---@return integer count The number of newlines.
---@nodiscard
function lua.lexer.countNewlines(str) end

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
function lua.lexer.tokenize(code, is_directive) end
