---@class dreamwork
local dreamwork = dreamwork

local dreamwork_vfs = dreamwork.vfs
local vfs_isFile = dreamwork_vfs.isFile
local vfs_readFile = dreamwork_vfs.readFile

local std = dreamwork.std

local error = std.error
local pcall = std.pcall
local tostring = std.tostring
local setmetatable = std.setmetatable

local string = std.string
local string_rep = string.rep
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find
local string_gsub = string.gsub
local string_match = string.match
local string_format = string.format
local string_gmatch = string.gmatch

local table = std.table
local table_concat = table.concat

local class = std.class

local loadstring = std.loadstring


--- [SHARED AND MENU]
---
--- Dreamwork Code Fabric
---
--- Library for code pre-build and exclusive features.
---
---@class dreamwork.sigil
local sigil = {}
dreamwork.sigil = sigil

--- [SHARED AND MENU]
---
--- An error raised when the preprocessor fails to process the code.
---
---@class dreamwork.sigil.Error : dreamwork.std.Error
---@field __class dreamwork.sigil.ErrorClass
---@field __parent dreamwork.std.Error
---@field message string The error message.
---@field chunk_name string The name of the chunk where the error occurred.
---@field line integer The line where the error occurred.
local SigilError = class.base( "sigil.Error", false, std.Error )

---@param message string
---@param chunk_name string
---@param line integer
---@protected
function SigilError:__init( message, chunk_name, line )
    self.message = message
    self.chunk_name = chunk_name
    self.line = line
end

---@param error_message string
---@return string
---@protected
function SigilError:__message( error_message )
    return string_format( "%s:%d: %s", self.chunk_name, self.line, error_message )
end

--- [SHARED AND MENU]
---
--- The class used to create new `SigilErrorClass` instances.
---
---@class dreamwork.sigil.ErrorClass : dreamwork.sigil.Error, dreamwork.std.Class
---@field __base dreamwork.sigil.Error
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: string, chunk_name: string, line: integer ): dreamwork.sigil.Error
local SigilErrorClass = class.create( SigilError )
sigil.Error = SigilErrorClass

--[[

    https://www.geeksforgeeks.org/cpp/cpp-preprocessors-and-directives/
    https://github.com/ReFreezed/LuaPreprocess

    Directive is a line that starts with `#<name>` ( leading whitespace allowed ),
    a trailing `\` continues the directive on the next line, `--` comments are stripped from parameters.

    Line numbers are preserved: directive lines and disabled blocks become empty lines,
    only `#include` and multi-line `#compile` results shift the following lines.

    <name> - always an identifier, if missing then causes an error
    <value> - rest of the line, if empty then the variable is removed ( `#define` keeps it as empty )
    <code> - lua expression, if missing then causes an error


    > variables ( macros ):

    #global <name> <value> -> defines a global variable, accessible in all files
    #local <name> <value> -> defines a local variable, accessible only in the current file ( and its includes )
    #define <name> <value> -> same as #local, but empty <value> still defines the variable
    #undef <name> -> removes the local variable ( also hides the global one )

    Function-like variables: `#define max( a, b ) ( (a) > (b) and (a) or (b) )`, `...` parameter is `__VA_ARGS__` in the body.

    Variables are substituted in code everywhere except strings, comments and field names ( `a.name`, `a:name` ).


    > conditions:

    #if <code> / #elif <code> / #else / #endif -> lua expression with substituted variables, `defined( <name> )` is available,
        `false`, `nil` and `0` are false

    #ifdef <name> / #ifndef <name> -> checks that a variable exists


    > binary modules:

    #load <module_name> -> preloads the specified binary module, do nothing if the module is already loaded


    > insertion:

    #include <file_path> [once] -> inserts the preprocessed contents of the file, `once` skips already included files
    #compile / #endcompile -> lua code executed during preprocessing, non-nil result is inserted into the code


    > notices:

    #info <message> -> produces an information notice
    #warn <message> -> produces a warning notice
    #debug <message> -> produces a debug notice
    #error <message> -> halts preprocessing and produces an error

--]]

---@class dreamwork.sigil.Macro
---@field name string
---@field body string
---@field parameters string[] | nil
---@field vararg boolean
---@field types integer[] | nil
---@field values string[] | nil

---@class dreamwork.sigil.File
---@field name string The chunk name used in errors and notices.
---@field path string | nil The file path used to resolve relative includes.
---@field line integer The current line.

---@class dreamwork.sigil.Context
---@field locals table<string, dreamwork.sigil.Macro | false>
---@field env table
---@field sandbox table
---@field read fun( file_path: string ): string | nil
---@field logger dreamwork.std.console.Logger | false
---@field comments boolean
---@field hide table<string, boolean>
---@field included table<string, boolean>
---@field including table<string, boolean>

---@class dreamwork.sigil.Options
---@field name? string The chunk name used in errors and notices, defaults to `path` or `"sigil"`.
---@field path? string The path of processed file, used to resolve relative `#include` paths.
---@field defines? table<string, any> The initial local variables, values are converted with `tostring`.
---@field env? table The environment of `#if` expressions and `#compile` blocks, defaults to `std`.
---@field read? fun( file_path: string ): string | nil The file reader used by `#include`, defaults to `dreamwork.vfs.readFile`.
---@field logger? dreamwork.std.console.Logger | false The logger used by notices, `false` disables them, defaults to `dreamwork.Logger`.
---@field comments? boolean If `false`, comments will be removed from the result, defaults to `true`.

---@alias dreamwork.sigil.Directive fun( context: dreamwork.sigil.Context, file: dreamwork.sigil.File, parameters: string ): string | nil

local lexer = std.lua.lexer
local tokenize = lexer.tokenize
local count_newlines = lexer.countNewlines


--- Directives that are handled by the preprocessor itself.
---@type table<string, boolean>
local reserved = {
    [ "if" ] = true,
    [ "ifdef" ] = true,
    [ "ifndef" ] = true,
    [ "elif" ] = true,
    [ "elseif" ] = true,
    [ "else" ] = true,
    [ "endif" ] = true,
    [ "compile" ] = true,
    [ "endcompile" ] = true
}

--- [SHARED AND MENU]
---
--- Custom directives, can be extended.
---
---@type table<string, dreamwork.sigil.Directive>
local directives = {}
sigil.directives = directives

---@param name string
---@return boolean
local function is_directive( name )
    return reserved[ name ] or directives[ name ] ~= nil
end

---@param str string
---@return string
local function trim( str )
    return string_match( str, "^%s*(.-)%s*$" )
end

---@param context dreamwork.sigil.Context
---@param name string
---@return dreamwork.sigil.Macro | nil
local function find_macro( context, name )
    local macro = context.locals[ name ]
    if macro == false then
        return nil
    elseif macro == nil then
        return sigil.globals[ name ]
    end

    return macro
end

---@param context dreamwork.sigil.Context
---@param name string
---@return boolean
local function is_defined( context, name )
    return find_macro( context, name ) ~= nil or context.env[ name ] ~= nil
end

---@param name string
---@param parameters string[] | nil
---@param body string
---@return dreamwork.sigil.Macro
local function make_macro( name, parameters, body )
    local vararg = false

    if parameters ~= nil and parameters[ #parameters ] == "..." then
        parameters[ #parameters ] = nil
        vararg = true
    end

    return {
        name = name,
        body = body,
        parameters = parameters,
        vararg = vararg
    }
end

--- Parses `<name> <value>` or `<name>( <parameters> ) <value>`.
---
---@param file dreamwork.sigil.File
---@param directive_name string
---@param parameters string
---@return string name
---@return string | nil parameter_list
---@return string value
local function parse_definition( file, directive_name, parameters )
    local name, parameter_list, value = string_match( parameters, "^([%a_][%w_]*)(%b())(.*)$" )
    if name == nil then
        name, value = string_match( parameters, "^([%a_][%w_]*)(.*)$" )
        if name == nil then
            error( SigilErrorClass( string_format( "Missing <name> in #%s.", directive_name ), file.name, file.line ), 2 )
        end
    end

    ---@cast name string
    ---@cast value string

    return name, parameter_list, trim( value )
end

---@param file dreamwork.sigil.File
---@param name string
---@param parameter_list string | nil
---@param value string
---@return dreamwork.sigil.Macro
local function parse_macro( file, name, parameter_list, value )
    if parameter_list == nil then
        return make_macro( name, nil, value )
    end

    ---@type string[]
    local parameters = {}

    local inner = trim( string_sub( parameter_list, 2, -2 ) )
    if inner ~= "" then
        local parameter_count = 0

        for parameter in string_gmatch( inner .. ",", "([^,]*)," ) do
            parameter = trim( parameter )

            if parameter_count ~= 0 and parameters[ parameter_count ] == "..." then
                error( SigilErrorClass( string_format( "Parameter '...' must be the last one in macro '%s'.", name ), file.name, file.line ), 2 )
            end

            if parameter ~= "..." and string_find( parameter, "^[%a_][%w_]*$" ) == nil then
                error( SigilErrorClass( string_format( "Invalid parameter '%s' in macro '%s'.", parameter, name ), file.name, file.line ), 2 )
            end

            parameter_count = parameter_count + 1
            parameters[ parameter_count ] = parameter
        end
    end

    return make_macro( name, parameters, value )
end

--- Collects arguments of function-like macro call.
---
---@param types integer[]
---@param values string[]
---@param index integer The index of `(` token.
---@param count integer
---@return string[] | nil arguments
---@return integer close_index
---@return integer newlines
local function collect_arguments( types, values, index, count )
    local arguments, argument_count = {}, 0
    local buffer, buffer_size = {}, 0
    local depth, newlines = 0, 0

    for i = index, count, 1 do
        local token_type, value = types[ i ], values[ i ]

        if token_type == 7 --[[ symbol ]] then
            if value == "(" or value == "{" or value == "[" then
                depth = depth + 1

                if depth == 1 then
                    value = ""
                end
            elseif value == ")" or value == "}" or value == "]" then
                depth = depth - 1

                if depth == 0 then
                    local argument = trim( table_concat( buffer, "", 1, buffer_size ) )
                    if argument_count ~= 0 or argument ~= "" then
                        argument_count = argument_count + 1
                        arguments[ argument_count ] = argument
                    end

                    return arguments, i, newlines
                end
            elseif value == "," and depth == 1 then
                argument_count = argument_count + 1
                arguments[ argument_count ] = trim( table_concat( buffer, "", 1, buffer_size ) )
                buffer_size = 0
                value = ""
            end
        elseif token_type == 2 --[[ newline ]] then
            newlines = newlines + 1
            value = " "
        elseif token_type == 3 --[[ comment ]] then
            newlines = newlines + count_newlines( value )
            value = " "
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = value
    end

    return nil, count, newlines
end

---@param file dreamwork.sigil.File
---@param macro dreamwork.sigil.Macro
---@param arguments string[]
---@return string
local function substitute( file, macro, arguments )
    local parameters = macro.parameters
    ---@cast parameters string[]

    local parameter_count, argument_count = #parameters, #arguments

    if argument_count < parameter_count or (argument_count > parameter_count and not macro.vararg) then
        error( SigilErrorClass( string_format( "Macro '%s' expects %d argument(s), got %d.", macro.name, parameter_count, argument_count ), file.name, file.line ), 2 )
    end

    ---@type table<string, string>
    local replacements = {}

    for i = 1, parameter_count, 1 do
        replacements[ parameters[ i ] ] = arguments[ i ]
    end

    if macro.vararg then
        replacements.__VA_ARGS__ = table_concat( arguments, ", ", parameter_count + 1, argument_count )
    end

    local types, values = macro.types, macro.values
    if types == nil or values == nil then
        types, values = tokenize( macro.body )
        macro.types, macro.values = types, values
    end

    local buffer = {}
    local previous

    for i = 1, #types, 1 do
        local token_type, value = types[ i ], values[ i ]

        if token_type == 6 --[[ name ]] and previous ~= "." and previous ~= ":" then
            buffer[ i ] = replacements[ value ] or value
        else
            buffer[ i ] = value
        end

        if token_type ~= 1 --[[ space ]] and token_type ~= 2 --[[ newline ]] and token_type ~= 3 --[[ comment ]] then
            previous = value
        end
    end

    return table_concat( buffer, "", 1, #types )
end

local expand_text

--- Tries to expand the name token at `index`.
---
---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param types integer[]
---@param values string[]
---@param index integer
---@param count integer
---@return string | nil replacement
---@return integer last_index
---@return integer newlines
local function expand_name( context, file, types, values, index, count )
    local name = values[ index ]

    local hide = context.hide
    if hide[ name ] then
        return nil, index, 0
    end

    local macro = find_macro( context, name )
    if macro == nil then
        return nil, index, 0
    end

    local body, last_index, newlines = macro.body, index, 0

    if macro.parameters ~= nil then
        local paren_index = index + 1

        while paren_index <= count do
            local token_type = types[ paren_index ]
            if token_type == 1 --[[ space ]] or token_type == 2 --[[ newline ]] or token_type == 3 --[[ comment ]] then
                paren_index = paren_index + 1
            else
                break
            end
        end

        if types[ paren_index ] ~= 7 --[[ symbol ]] or values[ paren_index ] ~= "(" then
            return nil, index, 0
        end

        local arguments, close_index, argument_newlines = collect_arguments( types, values, paren_index, count )
        if arguments == nil then
            error( SigilErrorClass( string_format( "Unterminated argument list of macro '%s'.", name ), file.name, file.line ), 2 )
        end

        ---@cast arguments string[]

        for i = index + 1, paren_index - 1, 1 do
            newlines = newlines + count_newlines( values[ i ] )
        end

        body = substitute( file, macro, arguments )
        newlines = newlines + argument_newlines
        last_index = close_index
    end

    hide[ name ] = true
    body = expand_text( context, file, body, false )
    hide[ name ] = nil

    return body, last_index, newlines
end

--- Parses `defined( <name> )` or `defined <name>` at `index`.
---
---@param types integer[]
---@param values string[]
---@param index integer The index of `defined` token.
---@param count integer
---@return string | nil name
---@return integer last_index
local function parse_defined( types, values, index, count )
    local with_paren = false

    for i = index + 1, count, 1 do
        local token_type, value = types[ i ], values[ i ]

        if token_type == 6 --[[ name ]] then
            if not with_paren then
                return value, i
            end

            for j = i + 1, count, 1 do
                if types[ j ] ~= 1 --[[ space ]] then
                    if values[ j ] == ")" then
                        return value, j
                    end

                    return nil, j
                end
            end

            return nil, count
        elseif token_type == 7 --[[ symbol ]] and value == "(" and not with_paren then
            with_paren = true
        elseif token_type ~= 1 --[[ space ]] then
            return nil, i
        end
    end

    return nil, count
end

--- Expands all macros in the given code.
---
---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param code string
---@param is_condition boolean If `true`, `defined( <name> )` will be replaced with `true` or `false`.
---@return string
function expand_text( context, file, code, is_condition )
    local types, values, _, count = tokenize( code )
    local buffer, buffer_size = {}, 0
    local previous

    local index = 1
    while index <= count do
        local token_type, value = types[ index ], values[ index ]

        if token_type == 6 --[[ name ]] then
            if is_condition and value == "defined" then
                local name, last_index = parse_defined( types, values, index, count )
                if name == nil then
                    error( SigilErrorClass( "Invalid 'defined' usage, expected 'defined( <name> )'.", file.name, file.line ), 2 )
                end

                ---@cast name string

                value = is_defined( context, name ) and "true" or "false"
                index = last_index
            elseif previous ~= "." and previous ~= ":" then
                local replacement, last_index = expand_name( context, file, types, values, index, count )
                if replacement ~= nil then
                    value = replacement
                    index = last_index
                end
            end
        end

        if token_type ~= 1 --[[ space ]] and token_type ~= 2 --[[ newline ]] and token_type ~= 3 --[[ comment ]] then
            previous = values[ index ]
        end

        buffer_size = buffer_size + 1
        buffer[ buffer_size ] = value

        index = index + 1
    end

    return table_concat( buffer, "", 1, buffer_size )
end

---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param code string
---@return any
local function execute( context, file, code )
    return loadstring( code, file.name, context.sandbox )()
end

---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param directive_name string
---@param expression string
---@return boolean
local function evaluate( context, file, directive_name, expression )
    if directive_name == "ifdef" or directive_name == "ifndef" then
        local name = string_match( expression, "^([%a_][%w_]*)$" )
        if name == nil then
            error( SigilErrorClass( string_format( "Missing <name> in #%s.", directive_name ), file.name, file.line ), 2 )
        end

        ---@cast name string

        return (find_macro( context, name ) ~= nil) == (directive_name == "ifdef")
    end

    if expression == "" then
        error( SigilErrorClass( string_format( "Missing <code> in #%s.", directive_name ), file.name, file.line ), 2 )
    end

    local success, result = pcall( execute, context, file, "return " .. expand_text( context, file, expression, true ) )
    if not success then
        error( SigilErrorClass( string_format( "Failed to evaluate #%s '%s': %s", directive_name, expression, tostring( result ) ), file.name, file.line ), 2 )
    end

    return result ~= nil and result ~= false and result ~= 0
end

--- Removes `--` comments and surrounding whitespace from directive parameters.
---
---@param parameters string
---@return string
local function clean_parameters( parameters )
    if string_find( parameters, "[-/]" ) == nil then
        return trim( parameters )
    end

    local types, values, _, count = tokenize( parameters )
    local buffer, buffer_size = {}, 0

    for i = 1, count, 1 do
        if types[ i ] ~= 3 --[[ comment ]] then
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = values[ i ]
        end
    end

    return trim( table_concat( buffer, "", 1, buffer_size ) )
end

---@param context dreamwork.sigil.Context
---@param code string
---@param name string
---@param file_path string | nil
---@return string
local function process( context, code, name, file_path )
    local types, values, _, count = tokenize( code, is_directive )

    ---@type dreamwork.sigil.File
    local file = { name = name, path = file_path, line = 1 }

    local buffer, buffer_size = {}, 0

    local conditions, depth = {}, 0
    local active = true

    ---@type string[] | nil
    local compile_buffer = nil
    local compile_size, compile_line, compile_active = 0, 0, false

    local keep_comments = context.comments
    local previous

    local index = 1
    while index <= count do
        local token_type, value = types[ index ], values[ index ]

        if token_type == 2 --[[ newline ]] then
            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = value

            if compile_buffer ~= nil then
                compile_size = compile_size + 1
                compile_buffer[ compile_size ] = value
            end

            file.line = file.line + 1
        elseif token_type == 8 --[[ directive ]] then
            local newlines = count_newlines( value )

            local directive_name, parameters = string_match( string_gsub( value, "\\[ \t\r]*\n", " " ), "^%s*#[ \t]*([%a_][%w_]*)(.*)$" )
            parameters = clean_parameters( parameters )

            if directive_name == "if" or directive_name == "ifdef" or directive_name == "ifndef" then
                local result = active and evaluate( context, file, directive_name, parameters )

                depth = depth + 1
                conditions[ depth ] = { parent = active, taken = result, else_line = nil, line = file.line, name = directive_name }
                active = result
            elseif directive_name == "elif" or directive_name == "elseif" or directive_name == "else" or directive_name == "endif" then
                local condition = conditions[ depth ]
                if condition == nil then
                    error( SigilErrorClass( string_format( "#%s without #if.", directive_name ), file.name, file.line ), 2 )
                end

                if directive_name == "endif" then
                    conditions[ depth ] = nil
                    depth = depth - 1
                    active = condition.parent
                else
                    if condition.else_line ~= nil then
                        error( SigilErrorClass( string_format( "#%s after #else at line %d.", directive_name, condition.else_line ), file.name, file.line ), 2 )
                    end

                    if not condition.parent or condition.taken then
                        active = false
                    elseif directive_name == "else" then
                        active = true
                    else
                        active = evaluate( context, file, directive_name, parameters )
                    end

                    if directive_name == "else" then
                        condition.else_line = file.line
                    end

                    condition.taken = condition.taken or active
                end
            elseif directive_name == "compile" then
                if compile_buffer ~= nil then
                    error( SigilErrorClass( string_format( "Nested #compile, previous one at line %d.", compile_line ), file.name, file.line ), 2 )
                end

                compile_buffer = { string_rep( "\n", file.line - 1 ) }
                compile_size, compile_line, compile_active = 1, file.line, active
            elseif directive_name == "endcompile" then
                if compile_buffer == nil then
                    error( SigilErrorClass( "#endcompile without #compile.", file.name, file.line ), 2 )
                end

                ---@cast compile_buffer string[]

                if compile_active then
                    local success, result = pcall( execute, context, file, table_concat( compile_buffer, "", 1, compile_size ) )
                    if not success then
                        error( SigilErrorClass( string_format( "#compile at line %d failed: %s", compile_line, tostring( result ) ), file.name, file.line ), 2 )
                    end

                    if result ~= nil then
                        buffer_size = buffer_size + 1
                        buffer[ buffer_size ] = tostring( result )
                    end
                end

                compile_buffer = nil
            elseif compile_buffer ~= nil then
                if active then
                    error( SigilErrorClass( string_format( "#%s is not allowed inside #compile.", directive_name ), file.name, file.line ), 2 )
                end
            elseif active then
                local result = directives[ directive_name ]( context, file, parameters )
                if result ~= nil then
                    buffer_size = buffer_size + 1
                    buffer[ buffer_size ] = result
                end
            end

            if newlines ~= 0 then
                buffer_size = buffer_size + 1
                buffer[ buffer_size ] = string_rep( "\n", newlines )
                file.line = file.line + newlines
            end
        elseif not active then
            if token_type == 4 --[[ string ]] or token_type == 3 --[[ comment ]] then
                local newlines = count_newlines( value )
                if newlines ~= 0 then
                    buffer_size = buffer_size + 1
                    buffer[ buffer_size ] = string_rep( "\n", newlines )
                    file.line = file.line + newlines
                end
            end
        elseif compile_buffer ~= nil then
            compile_size = compile_size + 1
            compile_buffer[ compile_size ] = value

            local newlines = count_newlines( value )
            if newlines ~= 0 then
                buffer_size = buffer_size + 1
                buffer[ buffer_size ] = string_rep( "\n", newlines )
                file.line = file.line + newlines
            end
        else
            if token_type == 6 --[[ name ]] then
                if previous ~= "." and previous ~= ":" then
                    local replacement, last_index, newlines = expand_name( context, file, types, values, index, count )
                    if replacement ~= nil then
                        previous = value
                        value = replacement
                        index = last_index

                        if newlines ~= 0 then
                            value = value .. string_rep( "\n", newlines )
                            file.line = file.line + newlines
                        end
                    end
                end
            elseif token_type == 3 --[[ comment ]] then
                local newlines = count_newlines( value )
                file.line = file.line + newlines

                if not keep_comments then
                    value = newlines == 0 and " " or string_rep( "\n", newlines )
                end
            elseif token_type == 4 --[[ string ]] then
                file.line = file.line + count_newlines( value )
            end

            if token_type ~= 1 --[[ space ]] and token_type ~= 3 --[[ comment ]] then
                previous = values[ index ]
            end

            buffer_size = buffer_size + 1
            buffer[ buffer_size ] = value
        end

        index = index + 1
    end

    if compile_buffer ~= nil then
        file.line = compile_line
        error( SigilErrorClass( "Unterminated #compile.", file.name, file.line ), 2 )
    end

    if depth ~= 0 then
        local condition = conditions[ depth ]
        file.line = condition.line
        error( SigilErrorClass( string_format( "Unterminated #%s.", condition.name ), file.name, file.line ), 2 )
    end

    return table_concat( buffer, "", 1, buffer_size )
end

--- [SHARED AND MENU]
---
--- Global variables, accessible in all files.
---
---@type table<string, dreamwork.sigil.Macro>
sigil.globals = {}

do

    ---@type table<string, boolean>
    local binary_modules = {}

    ---@param _ dreamwork.sigil.Context
    ---@param file dreamwork.sigil.File
    ---@param parameters string
    function directives.load( _, file, parameters )
        local module_name = string_match( parameters, "^['\"]?([%a_][%w_%.%-]*)['\"]?$" )
        if module_name == nil then
            error( SigilErrorClass( "Missing <module_name> in #load.", file.name, file.line ), 2 )
        end

        ---@cast module_name string

        if not binary_modules[ module_name ] then
            if std.loadbinary( module_name ) then
                binary_modules[ module_name ] = true
            else
                error( SigilErrorClass( string_format( "Failed to load binary module '%s'.", module_name ), file.name, file.line ), 2 )
            end
        end
    end

end

---@param _ dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param parameters string
function directives.global( _, file, parameters )
    local name, parameter_list, value = parse_definition( file, "global", parameters )
    if value == "" and parameter_list == nil then
        sigil.globals[ name ] = nil
    else
        sigil.globals[ name ] = parse_macro( file, name, parameter_list, value )
    end
end

---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param parameters string
directives[ "local" ] = function( context, file, parameters )
    local name, parameter_list, value = parse_definition( file, "local", parameters )
    if value == "" and parameter_list == nil then
        context.locals[ name ] = false
    else
        context.locals[ name ] = parse_macro( file, name, parameter_list, value )
    end
end

---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param parameters string
function directives.define( context, file, parameters )
    local name, parameter_list, value = parse_definition( file, "define", parameters )
    context.locals[ name ] = parse_macro( file, name, parameter_list, value )
end

---@param context dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param parameters string
function directives.undef( context, file, parameters )
    local name = string_match( parameters, "^([%a_][%w_]*)$" )
    if name == nil then
        error( SigilErrorClass( "Missing <name> in #undef.", file.name, file.line ), 2 )
    end

    context.locals[ name ] = false
end

do

    ---@param base_path string | nil
    ---@param file_path string
    ---@return string
    local function resolve_path( base_path, file_path )
        if base_path ~= nil and string_find( file_path, "^%.%.?/" ) ~= nil then
            file_path = (string_match( base_path, "^(.*/)" ) or "") .. file_path
        end

        local segments, segment_count = {}, 0
        local is_absolute = string_byte( file_path, 1 ) == 0x2F --[[ / ]]

        for segment in string_gmatch( file_path, "[^/\\]+" ) do
            if segment == ".." then
                if segment_count ~= 0 and segments[ segment_count ] ~= ".." then
                    segments[ segment_count ] = nil
                    segment_count = segment_count - 1
                elseif not is_absolute then
                    segment_count = segment_count + 1
                    segments[ segment_count ] = segment
                end
            elseif segment ~= "." then
                segment_count = segment_count + 1
                segments[ segment_count ] = segment
            end
        end

        return (is_absolute and "/" or "") .. table_concat( segments, "/", 1, segment_count )
    end

    ---@param context dreamwork.sigil.Context
    ---@param file dreamwork.sigil.File
    ---@param parameters string
    ---@return string | nil
    function directives.include( context, file, parameters )
        parameters = string_match( parameters, "^%((.*)%)$" ) or parameters

        local _, file_path, flag = string_match( parameters, "^%s*([\"'])(.-)%1%s*,?%s*(.-)%s*$" )
        if file_path == nil then
            file_path, flag = string_match( parameters, "^%s*<(.-)>%s*,?%s*(.-)%s*$" )
            if file_path == nil then
                file_path, flag = string_match( parameters, "^%s*([^%s,]+)%s*,?%s*(.-)%s*$" )
            end
        end

        if file_path == nil or file_path == "" then
            error( SigilErrorClass( "Missing <file_path> in #include.", file.name, file.line ), 2 )
        end

        ---@cast file_path string

        local once = flag == "once" or flag == "true"
        if not once and flag ~= "" and flag ~= "false" then
            error( SigilErrorClass( string_format( "Invalid #include flag '%s', expected 'once'.", flag ), file.name, file.line ), 2 )
        end

        file_path = resolve_path( file.path, file_path )

        if context.including[ file_path ] then
            error( SigilErrorClass( string_format( "Recursive #include of '%s'.", file_path ), file.name, file.line ), 2 )
        end

        if once and context.included[ file_path ] then
            return nil
        end

        local content = context.read( file_path )
        if content == nil then
            error( SigilErrorClass( string_format( "Failed to #include '%s', file not found.", file_path ), file.name, file.line ), 2 )
        end

        ---@cast content string

        context.included[ file_path ] = true
        context.including[ file_path ] = true

        local result = process( context, content, file_path, file_path )

        context.including[ file_path ] = nil
        return result
    end

end

---@param level string
---@return dreamwork.sigil.Directive
local function notice( level )
    ---@param context dreamwork.sigil.Context
    ---@param file dreamwork.sigil.File
    ---@param parameters string
    return function( context, file, parameters )
        local logger = context.logger
        if logger then
            logger[ level ]( logger, "%s:%d: %s", file.name, file.line, parameters )
        end
    end
end

directives.info = notice( "info" )
directives.warn = notice( "warn" )
directives.debug = notice( "debug" )

---@param _ dreamwork.sigil.Context
---@param file dreamwork.sigil.File
---@param parameters string
function directives.error( _, file, parameters )
    error( SigilErrorClass( parameters == "" and "#error" or parameters, file.name, file.line ), 2 )
end

---@param file_path string
---@return string | nil content
local function read_file( file_path )
    if vfs_isFile( file_path ) then
        return vfs_readFile( file_path )
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Preprocesses lua code, executing directives and substituting variables.
---
---@param code string The lua code to preprocess.
---@param options dreamwork.sigil.Options? The preprocessor options.
---@return string result The preprocessed lua code.
function sigil.preprocess( code, options )
    if options == nil then
        options = {}
    end

    local env = options.env or std

    local logger = options.logger
    if logger == nil then
        logger = dreamwork.Logger or false
    end

    ---@type dreamwork.sigil.Context
    local context = {
        locals = {},
        env = env,
        sandbox = {},
        read = options.read or read_file,
        logger = logger,
        comments = options.comments ~= false,
        hide = {},
        included = {},
        including = {}
    }

    local defines = options.defines
    if defines ~= nil then
        for name, value in std.raw.pairs( defines ) do
            context.locals[ name ] = make_macro( name, nil, tostring( value ) )
        end
    end

    context.sandbox = setmetatable( {
        ---@param name string
        ---@param value any
        define = function( name, value )
            context.locals[ name ] = make_macro( name, nil, value == nil and "" or tostring( value ) )
        end,
        ---@param name string
        undef = function( name )
            context.locals[ name ] = false
        end,
        ---@param name string
        ---@return boolean
        defined = function( name )
            return is_defined( context, name )
        end
    }, { __index = env } )

    local file_path = options.path
    if file_path ~= nil then
        context.included[ file_path ] = true
        context.including[ file_path ] = true
    end

    return process( context, code, options.name or file_path or "sigil", file_path )
end
