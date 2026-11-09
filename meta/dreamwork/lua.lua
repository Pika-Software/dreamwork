---@meta dreamwork.std.lua


--- [SHARED AND MENU]
---
--- Options of `std.lua.generator.generate`.
---
---@class dreamwork.std.lua.GeneratorOptions
---@field indent? string The indentation of one level, `"    "` by default.
---@field compact? boolean Removes all optional whitespace and newlines, `false` by default.
---@field lines? boolean Places statements on their original lines, so line numbers in errors match the parsed code, `false` by default.


---@class dreamwork.std.lua.ast.Node
---@field type integer The node type, see `std.lua.parser.NODE_*`.
---@field line integer The line where the node starts, `1` for hand-made nodes is fine.

---@class dreamwork.std.lua.ast.Chunk : dreamwork.std.lua.ast.Node
---@field type 33 `std.lua.parser.NODE_CHUNK`
---@field name string The chunk name.
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The last line of the code.


---@alias dreamwork.std.lua.ast.Statement
---| dreamwork.std.lua.ast.Local
---| dreamwork.std.lua.ast.LocalFunction
---| dreamwork.std.lua.ast.FunctionDeclaration
---| dreamwork.std.lua.ast.Assignment
---| dreamwork.std.lua.ast.CallStatement
---| dreamwork.std.lua.ast.Do
---| dreamwork.std.lua.ast.While
---| dreamwork.std.lua.ast.Repeat
---| dreamwork.std.lua.ast.If
---| dreamwork.std.lua.ast.NumericFor
---| dreamwork.std.lua.ast.GenericFor
---| dreamwork.std.lua.ast.Return
---| dreamwork.std.lua.ast.Break
---| dreamwork.std.lua.ast.Continue
---| dreamwork.std.lua.ast.Goto
---| dreamwork.std.lua.ast.Label

--- `local a, b = 1, 2`
---
---@class dreamwork.std.lua.ast.Local : dreamwork.std.lua.ast.Node
---@field type 1 `std.lua.parser.NODE_LOCAL`
---@field names dreamwork.std.lua.ast.Identifier[]
---@field values dreamwork.std.lua.ast.Expression[] Empty if there is no `=`.

--- `local function name() end`
---
---@class dreamwork.std.lua.ast.LocalFunction : dreamwork.std.lua.ast.Node
---@field type 2 `std.lua.parser.NODE_LOCAL_FUNCTION`
---@field name dreamwork.std.lua.ast.Identifier
---@field func dreamwork.std.lua.ast.Function

--- `function a.b:c() end`, for methods `target` is the `Member` of the method name and `func.is_method` is `true`.
---
---@class dreamwork.std.lua.ast.FunctionDeclaration : dreamwork.std.lua.ast.Node
---@field type 3 `std.lua.parser.NODE_FUNCTION_DECLARATION`
---@field target dreamwork.std.lua.ast.Identifier | dreamwork.std.lua.ast.Member
---@field func dreamwork.std.lua.ast.Function

--- `a, b.c, d[ e ] = 1, 2, 3`
---
---@class dreamwork.std.lua.ast.Assignment : dreamwork.std.lua.ast.Node
---@field type 4 `std.lua.parser.NODE_ASSIGNMENT`
---@field targets ( dreamwork.std.lua.ast.Identifier | dreamwork.std.lua.ast.Member | dreamwork.std.lua.ast.Index )[]
---@field values dreamwork.std.lua.ast.Expression[]

--- `f()` or `a:b()` as a statement.
---
---@class dreamwork.std.lua.ast.CallStatement : dreamwork.std.lua.ast.Node
---@field type 5 `std.lua.parser.NODE_CALL_STATEMENT`
---@field call dreamwork.std.lua.ast.Call | dreamwork.std.lua.ast.MethodCall

---@class dreamwork.std.lua.ast.Do : dreamwork.std.lua.ast.Node
---@field type 6 `std.lua.parser.NODE_DO`
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class dreamwork.std.lua.ast.While : dreamwork.std.lua.ast.Node
---@field type 7 `std.lua.parser.NODE_WHILE`
---@field condition dreamwork.std.lua.ast.Expression
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class dreamwork.std.lua.ast.Repeat : dreamwork.std.lua.ast.Node
---@field type 8 `std.lua.parser.NODE_REPEAT`
---@field body dreamwork.std.lua.ast.Statement[]
---@field condition dreamwork.std.lua.ast.Expression

--- `if` / `elseif` branch.
---
---@class dreamwork.std.lua.ast.IfClause
---@field condition dreamwork.std.lua.ast.Expression
---@field body dreamwork.std.lua.ast.Statement[]
---@field line integer? The line of `if` / `elseif`.

---@class dreamwork.std.lua.ast.If : dreamwork.std.lua.ast.Node
---@field type 9 `std.lua.parser.NODE_IF`
---@field clauses dreamwork.std.lua.ast.IfClause[] The `if` clause and `elseif` clauses.
---@field else_body dreamwork.std.lua.ast.Statement[] | nil
---@field else_line integer? The line of `else`.
---@field end_line integer? The line of `end`.

--- `for i = start, limit, step do end`
---
---@class dreamwork.std.lua.ast.NumericFor : dreamwork.std.lua.ast.Node
---@field type 10 `std.lua.parser.NODE_NUMERIC_FOR`
---@field variable dreamwork.std.lua.ast.Identifier
---@field start dreamwork.std.lua.ast.Expression
---@field limit dreamwork.std.lua.ast.Expression
---@field step dreamwork.std.lua.ast.Expression | nil
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The line of `end`.

--- `for k, v in iterators do end`
---
---@class dreamwork.std.lua.ast.GenericFor : dreamwork.std.lua.ast.Node
---@field type 11 `std.lua.parser.NODE_GENERIC_FOR`
---@field variables dreamwork.std.lua.ast.Identifier[]
---@field iterators dreamwork.std.lua.ast.Expression[]
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The line of `end`.

---@class dreamwork.std.lua.ast.Return : dreamwork.std.lua.ast.Node
---@field type 12 `std.lua.parser.NODE_RETURN`
---@field values dreamwork.std.lua.ast.Expression[]

---@class dreamwork.std.lua.ast.Break : dreamwork.std.lua.ast.Node
---@field type 13 `std.lua.parser.NODE_BREAK`

--- GLua `continue`.
---
---@class dreamwork.std.lua.ast.Continue : dreamwork.std.lua.ast.Node
---@field type 14 `std.lua.parser.NODE_CONTINUE`

--- LuaJIT `goto label`.
---
---@class dreamwork.std.lua.ast.Goto : dreamwork.std.lua.ast.Node
---@field type 15 `std.lua.parser.NODE_GOTO`
---@field label string

--- LuaJIT `::name::`.
---
---@class dreamwork.std.lua.ast.Label : dreamwork.std.lua.ast.Node
---@field type 16 `std.lua.parser.NODE_LABEL`
---@field name string


---@alias dreamwork.std.lua.ast.Expression
---| dreamwork.std.lua.ast.Nil
---| dreamwork.std.lua.ast.Boolean
---| dreamwork.std.lua.ast.Number
---| dreamwork.std.lua.ast.String
---| dreamwork.std.lua.ast.Vararg
---| dreamwork.std.lua.ast.Function
---| dreamwork.std.lua.ast.Table
---| dreamwork.std.lua.ast.Binary
---| dreamwork.std.lua.ast.Unary
---| dreamwork.std.lua.ast.Identifier
---| dreamwork.std.lua.ast.Member
---| dreamwork.std.lua.ast.Index
---| dreamwork.std.lua.ast.Call
---| dreamwork.std.lua.ast.MethodCall
---| dreamwork.std.lua.ast.Paren

---@class dreamwork.std.lua.ast.Nil : dreamwork.std.lua.ast.Node
---@field type 17 `std.lua.parser.NODE_NIL`

---@class dreamwork.std.lua.ast.Boolean : dreamwork.std.lua.ast.Node
---@field type 18 `std.lua.parser.NODE_BOOLEAN`
---@field value boolean

---@class dreamwork.std.lua.ast.Number : dreamwork.std.lua.ast.Node
---@field type 19 `std.lua.parser.NODE_NUMBER`
---@field value number | nil `nil` for LuaJIT `LL`, `ULL` and `i` literals.
---@field raw string? The source text, used by the generator if set.

---@class dreamwork.std.lua.ast.String : dreamwork.std.lua.ast.Node
---@field type 20 `std.lua.parser.NODE_STRING`
---@field value string The decoded value.
---@field raw string? The source text with quotes, used by the generator if set.

---@class dreamwork.std.lua.ast.Vararg : dreamwork.std.lua.ast.Node
---@field type 21 `std.lua.parser.NODE_VARARG`

---@class dreamwork.std.lua.ast.Function : dreamwork.std.lua.ast.Node
---@field type 22 `std.lua.parser.NODE_FUNCTION`
---@field parameters dreamwork.std.lua.ast.Identifier[] Without the implicit `self` of methods.
---@field vararg boolean
---@field is_method boolean `true` for `function a:b() end`.
---@field body dreamwork.std.lua.ast.Statement[]
---@field end_line integer? The line of `end`.

--- `kind` is `"list"` for `{ value }`, `"named"` for `{ name = value }` and `"index"` for `{ [ key ] = value }`.
---
---@class dreamwork.std.lua.ast.TableField : dreamwork.std.lua.ast.Node
---@field type 32 `std.lua.parser.NODE_TABLE_FIELD`
---@field kind "list" | "named" | "index"
---@field name string | nil The field name of `"named"` fields.
---@field key dreamwork.std.lua.ast.Expression | nil The key of `"index"` fields.
---@field value dreamwork.std.lua.ast.Expression

---@class dreamwork.std.lua.ast.Table : dreamwork.std.lua.ast.Node
---@field type 23 `std.lua.parser.NODE_TABLE`
---@field fields dreamwork.std.lua.ast.TableField[]
---@field end_line integer? The line of `}`.

---@alias dreamwork.std.lua.ast.BinaryOperator "or" | "and" | "<" | ">" | "<=" | ">=" | "~=" | "==" | ".." | "+" | "-" | "*" | "/" | "%" | "^"

---@class dreamwork.std.lua.ast.Binary : dreamwork.std.lua.ast.Node
---@field type 24 `std.lua.parser.NODE_BINARY`
---@field operator dreamwork.std.lua.ast.BinaryOperator
---@field left dreamwork.std.lua.ast.Expression
---@field right dreamwork.std.lua.ast.Expression

---@alias dreamwork.std.lua.ast.UnaryOperator "not" | "-" | "#"

---@class dreamwork.std.lua.ast.Unary : dreamwork.std.lua.ast.Node
---@field type 25 `std.lua.parser.NODE_UNARY`
---@field operator dreamwork.std.lua.ast.UnaryOperator
---@field argument dreamwork.std.lua.ast.Expression

---@class dreamwork.std.lua.ast.Identifier : dreamwork.std.lua.ast.Node
---@field type 26 `std.lua.parser.NODE_IDENTIFIER`
---@field name string

--- `object.name`
---
---@class dreamwork.std.lua.ast.Member : dreamwork.std.lua.ast.Node
---@field type 27 `std.lua.parser.NODE_MEMBER`
---@field object dreamwork.std.lua.ast.Expression
---@field name string

--- `object[ key ]`
---
---@class dreamwork.std.lua.ast.Index : dreamwork.std.lua.ast.Node
---@field type 28 `std.lua.parser.NODE_INDEX`
---@field object dreamwork.std.lua.ast.Expression
---@field key dreamwork.std.lua.ast.Expression

---@class dreamwork.std.lua.ast.Call : dreamwork.std.lua.ast.Node
---@field type 29 `std.lua.parser.NODE_CALL`
---@field callee dreamwork.std.lua.ast.Expression
---@field arguments dreamwork.std.lua.ast.Expression[]
---@field end_line integer? The line of the closing `)`, string or `}`.

--- `object:method( arguments )`
---
---@class dreamwork.std.lua.ast.MethodCall : dreamwork.std.lua.ast.Node
---@field type 30 `std.lua.parser.NODE_METHOD_CALL`
---@field object dreamwork.std.lua.ast.Expression
---@field method string
---@field arguments dreamwork.std.lua.ast.Expression[]
---@field end_line integer? The line of the closing `)`, string or `}`.

--- `( expression )`, truncates multiple values to one.
---
---@class dreamwork.std.lua.ast.Paren : dreamwork.std.lua.ast.Node
---@field type 31 `std.lua.parser.NODE_PAREN`
---@field expression dreamwork.std.lua.ast.Expression
