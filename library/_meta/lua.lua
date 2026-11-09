---@meta _


--- [SHARED AND MENU]
---
--- Options of `lua.generator.generate`.
---
---@class lua.GeneratorOptions
---@field indent? string The indentation of one level, `"    "` by default.
---@field compact? boolean Removes all optional whitespace and newlines, `false` by default.
---@field lines? boolean Places statements on their original lines, so line numbers in errors match the parsed code, `false` by default.


---@class lua.ast.Node
---@field type integer The node type, see `lua.parser.NODE_*`.
---@field line integer The line where the node starts, `1` for hand-made nodes is fine.

---@class lua.ast.Chunk : lua.ast.Node
---@field type 33 `lua.parser.NODE_CHUNK`
---@field name string The chunk name.
---@field body lua.ast.Statement[]
---@field end_line integer? The last line of the code.


---@alias lua.ast.Statement
---| lua.ast.Local
---| lua.ast.LocalFunction
---| lua.ast.FunctionDeclaration
---| lua.ast.Assignment
---| lua.ast.CallStatement
---| lua.ast.Do
---| lua.ast.While
---| lua.ast.Repeat
---| lua.ast.If
---| lua.ast.NumericFor
---| lua.ast.GenericFor
---| lua.ast.Return
---| lua.ast.Break
---| lua.ast.Continue
---| lua.ast.Goto
---| lua.ast.Label

--- `local a, b = 1, 2`
---
---@class lua.ast.Local : lua.ast.Node
---@field type 1 `lua.parser.NODE_LOCAL`
---@field names lua.ast.Identifier[]
---@field values lua.ast.Expression[] Empty if there is no `=`.

--- `local function name() end`
---
---@class lua.ast.LocalFunction : lua.ast.Node
---@field type 2 `lua.parser.NODE_LOCAL_FUNCTION`
---@field name lua.ast.Identifier
---@field func lua.ast.Function

--- `function a.b:c() end`, for methods `target` is the `Member` of the method name and `func.is_method` is `true`.
---
---@class lua.ast.FunctionDeclaration : lua.ast.Node
---@field type 3 `lua.parser.NODE_FUNCTION_DECLARATION`
---@field target lua.ast.Identifier | lua.ast.Member
---@field func lua.ast.Function

--- `a, b.c, d[ e ] = 1, 2, 3`
---
---@class lua.ast.Assignment : lua.ast.Node
---@field type 4 `lua.parser.NODE_ASSIGNMENT`
---@field targets ( lua.ast.Identifier | lua.ast.Member | lua.ast.Index )[]
---@field values lua.ast.Expression[]

--- `f()` or `a:b()` as a statement.
---
---@class lua.ast.CallStatement : lua.ast.Node
---@field type 5 `lua.parser.NODE_CALL_STATEMENT`
---@field call lua.ast.Call | lua.ast.MethodCall

---@class lua.ast.Do : lua.ast.Node
---@field type 6 `lua.parser.NODE_DO`
---@field body lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class lua.ast.While : lua.ast.Node
---@field type 7 `lua.parser.NODE_WHILE`
---@field condition lua.ast.Expression
---@field body lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class lua.ast.Repeat : lua.ast.Node
---@field type 8 `lua.parser.NODE_REPEAT`
---@field body lua.ast.Statement[]
---@field condition lua.ast.Expression

--- `if` / `elseif` branch.
---
---@class lua.ast.IfClause
---@field condition lua.ast.Expression
---@field body lua.ast.Statement[]
---@field line integer? The line of `if` / `elseif`.

---@class lua.ast.If : lua.ast.Node
---@field type 9 `lua.parser.NODE_IF`
---@field clauses lua.ast.IfClause[] The `if` clause and `elseif` clauses.
---@field else_body lua.ast.Statement[] | nil
---@field else_line integer? The line of `else`.
---@field end_line integer? The line of `end`.

--- `for i = start, limit, step do end`
---
---@class lua.ast.NumericFor : lua.ast.Node
---@field type 10 `lua.parser.NODE_NUMERIC_FOR`
---@field variable lua.ast.Identifier
---@field start lua.ast.Expression
---@field limit lua.ast.Expression
---@field step lua.ast.Expression | nil
---@field body lua.ast.Statement[]
---@field end_line integer? The line of `end`.

--- `for k, v in iterators do end`
---
---@class lua.ast.GenericFor : lua.ast.Node
---@field type 11 `lua.parser.NODE_GENERIC_FOR`
---@field variables lua.ast.Identifier[]
---@field iterators lua.ast.Expression[]
---@field body lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class lua.ast.Return : lua.ast.Node
---@field type 12 `lua.parser.NODE_RETURN`
---@field values lua.ast.Expression[]

---@class lua.ast.Break : lua.ast.Node
---@field type 13 `lua.parser.NODE_BREAK`

--- GLua `continue`.
---
---@class lua.ast.Continue : lua.ast.Node
---@field type 14 `lua.parser.NODE_CONTINUE`

--- LuaJIT `goto label`.
---
---@class lua.ast.Goto : lua.ast.Node
---@field type 15 `lua.parser.NODE_GOTO`
---@field label string

--- LuaJIT `::name::`.
---
---@class lua.ast.Label : lua.ast.Node
---@field type 16 `lua.parser.NODE_LABEL`
---@field name string


---@alias lua.ast.Expression
---| lua.ast.Nil
---| lua.ast.Boolean
---| lua.ast.Number
---| lua.ast.String
---| lua.ast.Vararg
---| lua.ast.Function
---| lua.ast.Table
---| lua.ast.Binary
---| lua.ast.Unary
---| lua.ast.Identifier
---| lua.ast.Member
---| lua.ast.Index
---| lua.ast.Call
---| lua.ast.MethodCall
---| lua.ast.Paren

---@class lua.ast.Nil : lua.ast.Node
---@field type 17 `lua.parser.NODE_NIL`

---@class lua.ast.Boolean : lua.ast.Node
---@field type 18 `lua.parser.NODE_BOOLEAN`
---@field value boolean

---@class lua.ast.Number : lua.ast.Node
---@field type 19 `lua.parser.NODE_NUMBER`
---@field value number | nil `nil` for LuaJIT `LL`, `ULL` and `i` literals.
---@field raw string? The source text, used by the generator if set.

---@class lua.ast.String : lua.ast.Node
---@field type 20 `lua.parser.NODE_STRING`
---@field value string The decoded value.
---@field raw string? The source text with quotes, used by the generator if set.

---@class lua.ast.Vararg : lua.ast.Node
---@field type 21 `lua.parser.NODE_VARARG`

---@class lua.ast.Function : lua.ast.Node
---@field type 22 `lua.parser.NODE_FUNCTION`
---@field parameters lua.ast.Identifier[] Without the implicit `self` of methods.
---@field vararg boolean
---@field is_method boolean `true` for `function a:b() end`.
---@field body lua.ast.Statement[]
---@field end_line integer? The line of `end`.

--- `kind` is `"list"` for `{ value }`, `"named"` for `{ name = value }` and `"index"` for `{ [ key ] = value }`.
---
---@class lua.ast.TableField : lua.ast.Node
---@field type 32 `lua.parser.NODE_TABLE_FIELD`
---@field kind "list" | "named" | "index"
---@field name string | nil The field name of `"named"` fields.
---@field key lua.ast.Expression | nil The key of `"index"` fields.
---@field value lua.ast.Expression

---@class lua.ast.Table : lua.ast.Node
---@field type 23 `lua.parser.NODE_TABLE`
---@field fields lua.ast.TableField[]
---@field end_line integer? The line of `}`.

---@alias lua.ast.BinaryOperator "or" | "and" | "<" | ">" | "<=" | ">=" | "~=" | "==" | ".." | "+" | "-" | "*" | "/" | "%" | "^"

---@class lua.ast.Binary : lua.ast.Node
---@field type 24 `lua.parser.NODE_BINARY`
---@field operator lua.ast.BinaryOperator
---@field left lua.ast.Expression
---@field right lua.ast.Expression

---@alias lua.ast.UnaryOperator "not" | "-" | "#"

---@class lua.ast.Unary : lua.ast.Node
---@field type 25 `lua.parser.NODE_UNARY`
---@field operator lua.ast.UnaryOperator
---@field argument lua.ast.Expression

---@class lua.ast.Identifier : lua.ast.Node
---@field type 26 `lua.parser.NODE_IDENTIFIER`
---@field name string

--- `object.name`
---
---@class lua.ast.Member : lua.ast.Node
---@field type 27 `lua.parser.NODE_MEMBER`
---@field object lua.ast.Expression
---@field name string

--- `object[ key ]`
---
---@class lua.ast.Index : lua.ast.Node
---@field type 28 `lua.parser.NODE_INDEX`
---@field object lua.ast.Expression
---@field key lua.ast.Expression

---@class lua.ast.Call : lua.ast.Node
---@field type 29 `lua.parser.NODE_CALL`
---@field callee lua.ast.Expression
---@field arguments lua.ast.Expression[]
---@field end_line integer? The line of the closing `)`, string or `}`.

--- `object:method( arguments )`
---
---@class lua.ast.MethodCall : lua.ast.Node
---@field type 30 `lua.parser.NODE_METHOD_CALL`
---@field object lua.ast.Expression
---@field method string
---@field arguments lua.ast.Expression[]
---@field end_line integer? The line of the closing `)`, string or `}`.

--- `( expression )`, truncates multiple values to one.
---
---@class lua.ast.Paren : lua.ast.Node
---@field type 31 `lua.parser.NODE_PAREN`
---@field expression lua.ast.Expression
