---@meta _

--- [SHARED AND MENU]
---
--- Lua code generator, turns AST from `lua.parser` ( or a hand-made one ) back into Lua code.
---
--- Parentheses are added where operator priorities require them, so hand-made ASTs do not need `Paren` nodes.
---
--- Comments are not part of the AST and are not generated.
---
---@class lua.generator
lua.generator = {}

--- [SHARED AND MENU]
---
--- Converts a number into a Lua number literal that reads back as the same number.
---
--- `inf`, `-inf` and `nan` become `(1/0)`, `(-1/0)` and `(0/0)`.
---
---@param value number The number to format.
---@return string literal The number literal.
---@nodiscard
function lua.generator.formatNumber(value) end

--- [SHARED AND MENU]
---
--- Generates Lua code from an AST node.
---
--- By default the code is formatted with one statement per line and indentation,
--- `options.compact` removes all optional whitespace, `options.lines` places statements on their original lines
--- ( line numbers in errors stay the same as in the parsed code ).
---
---@param node lua.ast.Node The AST node to generate code from, a chunk, a statement or an expression.
---@param options lua.GeneratorOptions? The generator options.
---@return string code The generated Lua code.
---@nodiscard
function lua.generator.generate(node, options) end
