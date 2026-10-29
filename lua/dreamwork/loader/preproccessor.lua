---@class dreamwork
local dreamwork = _G.dreamwork
local std = dreamwork.std

local string = std.string
local string_len = string.len
local string_match = string.match
local string_findByte = string.findByte
local string_byteSplit = string.byteSplit

local table = std.table
local table_concat = table.concat

--- [SHARED AND MENU]
---
--- Dreamwork Code Fabric
---
--- Library for code pre-build and exclusive features.
---
---@class dreamwork.factory
local factory = dreamwork.factory or {}
dreamwork.factory = factory

--[[

    TODO: Concept

    #if defined( SERVER )

        server.tickrate.set( 60 )

    #else

        #include( "./client.lua" )

    #endif

]]

--[[

    https://www.geeksforgeeks.org/cpp/cpp-preprocessors-and-directives/
    https://github.com/ReFreezed/LuaPreprocess



    <name> - always a string, if string is empty then causes an #error
    <value> - always a string, if string is empty, then the value is `nil`
    <code> - always a string, if string is empty then causes an #error


    > variables:

    #global <name> <value> -> defines a global variable, accessible in all files

    #local <name> <value> -> defines a local variable, accessible only in the current file

    #define -> #local <name> <value>

    #undef -> #local <name>


    > conditions:

    #if / #elif / #else / #endif -> separate lua compilation with a condition, aka #if <code> / #elif <code> / #else / #endif

    #ifdef / #ifndef -> just checks that a variable not equal to nil (exists), aka #ifdef <name> / #ifndef <name>


    > binary modules:

    #load <file_path> -> preloads the specified binary module, do nothing if the module is already loaded


    > insertion:

    #include <file_path> <ignore if already included> -> inserts the contents of the file into the current file, do nothing if the file is already included
    #compile / #endcompile -> separate lua compilation, if return result not nil then the result will be included as string in code


    > notices:

    #info <message> -> produces an information notice

    #warn <message> -> produces a warning notice

    #error <message> -> halts compilation process and produces an error notice

    #debug <message> -> produces a debug notice


--]]

--[[

#define printf std.printf

print( "hello %s", "world" ) -> std.printf( "hello %s", "world" )


--]]


---@class dreamwork.factory.PreprocessorStatement
---@field locals table<string, string>
---@field lines string[]
---@field line integer

---@class dreamwork.factory.PreprocessorResult
---@field lines table<integer, integer>
---@field line_count integer
---@field code string

---@alias dreamwork.factory.PreprocessorDirective fun( statement: dreamwork.factory.PreprocessorStatement, parameters: string ): string | nil

---@type integer
local exclamation_mark = 0x23 --[[ # ]]

---@type table<string, dreamwork.factory.PreprocessorDirective>
local directives = {}

do

    ---@type table<string, boolean>
    local binary_modules = {}

    function directives.load( statement, parameters )
        local module_name = string_match( parameters, "^['\"]?([%a_][%w_]*)['\"]?$" )
        if module_name == nil then
            std.errorf( 2, false, "Missing <module_name> in #load at line %d.", statement.line )
        end

        ---@cast module_name string

        if not binary_modules[ module_name ] then
            local success = std.loadbinary( module_name )
            if success then
                binary_modules[ module_name ] = success
            else
                std.errorf( 2, false, "Failed to load binary module '%s' at line %d.", module_name, statement.line )
            end
        end
    end

end

---@type table<string, string>
local globals = {}
local globals_metatable = { __index = globals }

function directives.global( statement, parameters )
    local name, value = string_match( parameters, "^([%a_][%w_]*)%s*(.*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #global at line %d.", statement.line )
    end

    ---@cast name string

    if value ~= nil and string.byte( value, 1, 1 ) == nil then
        value = nil
    end

    globals[ name ] = value
end

directives[ "local" ] = function( statement, parameters )
    local name, value = string_match( parameters, "^([%a_][%w_]*)%s*(.*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #local at line %d.", statement.line )
    end

    ---@cast name string

    if value ~= nil and string.byte( value, 1, 1 ) == nil then
        value = nil
    end

    statement.locals[ name ] = value
end

function directives.define( statement, parameters )
    local name, value = string_match( parameters, "^([%a_][%w_]*)%s*(.*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #define at line %d.", statement.line )
    else
        statement.locals[ name ] = value or ""
    end
end

function directives.undef( statement, parameters )
    local name = string_match( parameters, "^([%a_][%w_]*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #undef at line %d.", statement.line )
    else
        statement.locals[ name ] = nil
    end
end

function directives.ifdef( statement, parameters )
    local name = string_match( parameters, "^([%a_][%w_]*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #define at line %d.", statement.line )
    end

end

function directives.ifndef( statement, parameters )
    local name = string_match( parameters, "^([%a_][%w_]*)$" )
    if name == nil then
        std.errorf( 2, false, "Missing <name> in #define at line %d.", statement.line )
    end

end

directives[ "else" ] = function( statement, parameters )

end

directives[ "endif" ] = function( statement, parameters )

end

-- ---@param code string
-- ---@param locals? table<string, string>
-- ---@return dreamwork.factory.PreprocessorResult
-- function factory.preprocess( code, locals )
--     local lines, line_count = string_byteSplit( code, 0x0A --[[ \n ]] )

--     if locals == nil then
--         locals = {}
--     end

--     std.setmetatable( locals, globals_metatable )

--     ---@type integer
--     local line = 0

--     ---@type dreamwork.factory.PreprocessorStatement
--     local statement = {
--         stack = std.Stack(),
--         locals = locals,
--         lines = lines,
--         code = code,
--         line = line
--     }

--     ::preprocessor_loop::

--     line = line + 1

--     local line_str = lines[ line ]

--     if line_str == nil then
--         goto preprocessor_break
--     end

--     local exclamation_position = string.findByte( line_str, exclamation_mark )
--     if exclamation_position == nil then
--         lines[ line ] = string.gsub( line_str, "[%a_][%w_]*", locals )
--         goto preprocessor_loop
--     end

--     local directive_name, parameters = string_match( line_str, "^%s*#([%a_][%w_]*)%s*(.*)%s*$", exclamation_position + 1 )
--     if directive_name == nil then
--     else

--         local directive_fn = directives[ directive_name ]
--         if directive_fn == nil then
--             std.errorf( 2, false, "Unknown directive '%s' at line %d.", directive_name, i )
--         end

--         ---@cast directive_fn fun( statement: dreamwork.factory.PreprocessorStatement, parameters: string ):

--         statement.line = i
--         lines[ i ] = directive_fn( statement, parameters ) or ""

--     end

--     goto preprocessor_loop

--     ::preprocessor_break::

--     ---@type dreamwork.factory.PreprocessorResult
--     return {
--         code = table_concat( lines, "\n", 1, line_count ),
--         line_count = line_count,
--         lines = {}
--     }
-- end

-- local code = [[

--     -- #load bitpack
--     #define print std.printf

--     -- #if defined( __SERVER )

--     --     server.tickrate.set( 60 )

--     -- #else

--     --     #include( "./client.lua" )

--     -- #endif

--     print( "hi" )

-- ]]

-- print( "\nOutput:\n", factory.preprocess( code ).code )

-- ---@type table<string, boolean>
-- local lua_keywords = {
--     [ "and" ] = true,
--     [ "break" ] = true,
--     [ "do" ] = true,
--     [ "else" ] = true,
--     [ "elseif" ] = true,
--     [ "end" ] = true,
--     [ "false" ] = true,
--     [ "for" ] = true,
--     [ "function" ] = true,
--     [ "if" ] = true,
--     [ "in" ] = true,
--     [ "local" ] = true,
--     [ "nil" ] = true,
--     [ "not" ] = true,
--     [ "or" ] = true,
--     [ "repeat" ] = true,
--     [ "return" ] = true,
--     [ "then" ] = true,
--     [ "true" ] = true,
--     [ "until" ] = true,
--     [ "while" ] = true
-- }

-- local function tdump( tok )
--     return yield( tok, tok )
-- end

-- local function ndump( tok, options )
--     if options and options.number then
--         tok = tonumber( tok )
--     end

--     return yield( "number", tok )
-- end

-- -- regular strings, single or double quotes; usually we want them
-- -- without the quotes
-- local function sdump( tok, options )
--     if options and options.string then
--         tok = tok:sub( 2, -2 )
--     end

--     return yield( "string", tok )
-- end

-- -- long Lua strings need extra work to get rid of the quotes
-- local function sdump_l( tok, options )
--     if options and options.string then
--         tok = tok:sub( 3, -3 )
--     end

--     return yield( "string", tok )
-- end

-- local function chdump( tok, options )
--     if options and options.string then
--         tok = tok:sub( 2, -2 )
--     end

--     return yield( "char", tok )
-- end

-- local function cdump( tok )
--     return yield( 'comment', tok )
-- end

-- local function wsdump( tok )
--     return yield( "space", tok )
-- end

-- local function pdump( tok )
--     return yield( 'prepro', tok )
-- end

-- local function plain_vdump( tok )
--     return yield( "iden", tok )
-- end

-- local function lua_vdump( tok )
--     if lua_keyword[ tok ] then
--         return yield( "keyword", tok )
--     else
--         return yield( "iden", tok )
--     end
-- end

-- local function cpp_vdump( tok )
--     if cpp_keyword[ tok ] then
--         return yield( "keyword", tok )
--     else
--         return yield( "iden", tok )
--     end
-- end

-- local NUMBER1 = '^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+'
-- local NUMBER2 = '^[%+%-]?%d+%.?%d*'
-- local NUMBER3 = '^0x[%da-fA-F]+'
-- local NUMBER4 = '^%d+%.?%d*[eE][%+%-]?%d+'
-- local NUMBER5 = '^%d+%.?%d*'

-- local IDEN = '^[%a_][%w_]*'
-- local WSPACE = '^%s+'
-- local STRING0 = [[^(['\"]).-\\%1]]
-- local STRING1 = [[^(['\"]).-[^\]%1]]
-- local STRING3 = "^((['\"])%2)" -- empty string
-- local PREPRO = '^#.-[^\\]\n'

-- local plain_matches = {
--     { WSPACE, wsdump },
--     { NUMBER3, ndump },
--     { IDEN, plain_vdump },
--     { NUMBER1, ndump },
--     { NUMBER2, ndump },
--     { STRING3, sdump },
--     { STRING0, sdump },
--     { STRING1, sdump },
--     { '^.', tdump }
-- }

-- local lua_matches = {
--     { WSPACE, wsdump },
--     { NUMBER3, ndump },
--     { IDEN, lua_vdump },
--     { NUMBER4, ndump },
--     { NUMBER5, ndump },
--     { STRING3, sdump },
--     { STRING0, sdump },
--     { STRING1, sdump },
--     { '^%-%-%[%[.-%]%]', cdump },
--     { '^%-%-.-\n', cdump },
--     { '^%[%[.-%]%]', sdump_l },
--     { '^==', tdump },
--     { '^~=', tdump },
--     { '^<=', tdump },
--     { '^>=', tdump },
--     { '^%.%.%.', tdump },
--     { '^%.%.', tdump },
--     { '^.', tdump }
-- }
