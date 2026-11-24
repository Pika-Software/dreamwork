---@class dreamwork.std
local std = dreamwork.std

local raw = std.raw
local raw_tonumber = raw.tonumber

local string = std.string
local string_byte, string_char = string.byte, string.char
local string_sub, string_find = string.sub, string.find
local string_gsub, string_upper = string.gsub, string.upper
local string_format = string.format

local table = std.table
local table_concat = table.concat

local raw_type = raw.type

local math = std.math
local math_huge, math_nan = math.huge, math.nan

local error = std.error

---@class dreamwork.std.protobuf
local protobuf = std.protobuf

--- [SHARED AND MENU]
---
--- The parsed `.proto` file, see `protobuf.parseSchema`.
---
---@class dreamwork.std.protobuf.FileDescriptor
---@field name string The name of the file, imports refer to it by this name.
---@field ["package"] string The protobuf package, `""` if the file has none.
---@field syntax "proto2" | "proto3" The syntax of the file.
---@field imports dreamwork.std.protobuf.ImportDescriptor[] The imported files.
---@field messages dreamwork.std.protobuf.MessageDescriptor[] The top-level messages.
---@field enums dreamwork.std.protobuf.EnumDescriptor[] The top-level enums.

--- [SHARED AND MENU]
---
---@class dreamwork.std.protobuf.ImportDescriptor
---@field path string The imported file name.
---@field ["public"] boolean `true` for `import public`.
---@field weak boolean `true` for `import weak`.

--- [SHARED AND MENU]
---
---@class dreamwork.std.protobuf.MessageDescriptor
---@field name string The short name.
---@field full_name string The name with the protobuf package and the parent messages, e.g. `my_pkg.Outer.Inner`.
---@field fields dreamwork.std.protobuf.FieldDescriptor[] The fields in declaration order.
---@field oneofs string[] The names of the `oneof` groups, `FieldDescriptor.oneof` is an index in it.
---@field messages dreamwork.std.protobuf.MessageDescriptor[] The nested messages, including the generated `map` entries.
---@field enums dreamwork.std.protobuf.EnumDescriptor[] The nested enums.
---@field map_entry boolean `true` for the generated `map<K, V>` entry messages.

--- [SHARED AND MENU]
---
---@class dreamwork.std.protobuf.FieldDescriptor
---@field name string The name of the field.
---@field number integer The field number.
---@field label "optional" | "required" | "repeated" | nil The label, `nil` for proto3 fields without one.
---@field type_name string The scalar type (`int32`, `string`, ...) or the referenced message/enum name as written.
---@field scope string The full name of the message the field is declared in, type names are resolved relative to it.
---@field oneof integer | nil The index in `MessageDescriptor.oneofs`.
---@field packed boolean | nil The `packed` option, `nil` if not set.
---@field default any The `default` option of proto2 fields, already converted to its type when possible.
---@field resolved dreamwork.std.protobuf.Type | dreamwork.std.protobuf.Enum | string | nil The type of generated fields (`protobuf.list`, ...), set instead of resolving `type_name`.

--- [SHARED AND MENU]
---
---@class dreamwork.std.protobuf.EnumDescriptor
---@field name string The short name.
---@field full_name string The name with the protobuf package and the parent messages.
---@field values { name: string, number: integer }[] The values in declaration order.

---@type table<string, boolean>
local map_key_types = {
    int32 = true,
    int64 = true,
    uint32 = true,
    uint64 = true,
    sint32 = true,
    sint64 = true,
    fixed32 = true,
    fixed64 = true,
    sfixed32 = true,
    sfixed64 = true,
    bool = true,
    string = true
}

local TOKEN_IDENTIFIER = 1
local TOKEN_NUMBER = 2
local TOKEN_STRING = 3
local TOKEN_SYMBOL = 4
local TOKEN_EOF = 5

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
    [ 0x27 --[[ ' ]] ] = "'",
    [ 0x22 --[[ " ]] ] = "\"",
    [ 0x3F --[[ ? ]] ] = "?"
}

-- tokenizer and parser state, the parser is not re-entrant and never yields

---@type integer[]
local token_types = {}

---@type any[]
local token_values = {}

---@type integer[]
local token_lines = {}

local token_count = 0

local token_index = 1

---@type string
local current_file = ""

---@param message string
---@param line integer
local function syntax_error( message, line )
    error( string_format( "%s:%d: %s", current_file, line, message ), 0 )
end

---@param token_type integer
---@param value any
---@param line integer
local function push_token( token_type, value, line )
    token_count = token_count + 1
    token_types[ token_count ] = token_type
    token_values[ token_count ] = value
    token_lines[ token_count ] = line
end

---@param byte integer | nil
---@return boolean
local function is_identifier_byte( byte )
    return byte ~= nil and (
        (byte >= 0x61 and byte <= 0x7A) or -- a-z
        (byte >= 0x41 and byte <= 0x5A) or -- A-Z
        (byte >= 0x30 and byte <= 0x39) or -- 0-9
        byte == 0x5F                       -- _
    )
end

---@param byte integer | nil
---@return boolean
local function is_digit( byte )
    return byte ~= nil and byte >= 0x30 and byte <= 0x39
end

--- Reads the quoted string at `position`, returns its value and the position after the closing quote.
---
---@param source string
---@param position integer
---@param line integer
---@return string value
---@return integer position
local function read_quoted( source, position, line )
    local quote = string_byte( source, position )
    position = position + 1

    ---@type string[]
    local parts = {}
    local part_count = 0

    local segment_start = position

    ::string_loop::

    local byte = string_byte( source, position )

    if byte == nil or byte == 0x0A then
        syntax_error( "unterminated string", line )
    elseif byte == quote then
        part_count = part_count + 1
        parts[ part_count ] = string_sub( source, segment_start, position - 1 )
        return table_concat( parts, "", 1, part_count ), position + 1
    elseif byte == 0x5C --[[ \ ]] then
        part_count = part_count + 1
        parts[ part_count ] = string_sub( source, segment_start, position - 1 )

        local next_byte = string_byte( source, position + 1 )
        local escaped = escapes[ next_byte ]

        if escaped ~= nil then
            part_count = part_count + 1
            parts[ part_count ] = escaped
            position = position + 2
        elseif next_byte == 0x78 or next_byte == 0x58 --[[ x X ]] then
            local hex_start = position + 2
            local hex_end = hex_start

            -- up to 2 hex digits
            for index = hex_start, hex_start + 1, 1 do
                local hex_byte = string_byte( source, index )
                if hex_byte ~= nil and ((hex_byte >= 0x30 and hex_byte <= 0x39) or (hex_byte >= 0x61 and hex_byte <= 0x66) or (hex_byte >= 0x41 and hex_byte <= 0x46)) then
                    hex_end = index + 1
                else
                    break
                end
            end

            if hex_end == hex_start then
                syntax_error( "invalid hex escape", line )
            end

            part_count = part_count + 1
            parts[ part_count ] = string_char( raw_tonumber( string_sub( source, hex_start, hex_end - 1 ), 16 ) or 0 )
            position = hex_end
        elseif is_digit( next_byte ) and next_byte <= 0x37 then
            local octal_start = position + 1
            local octal_end = octal_start

            -- up to 3 octal digits
            for index = octal_start, octal_start + 2, 1 do
                local octal_byte = string_byte( source, index )
                if octal_byte ~= nil and octal_byte >= 0x30 and octal_byte <= 0x37 then
                    octal_end = index + 1
                else
                    break
                end
            end

            local value = raw_tonumber( string_sub( source, octal_start, octal_end - 1 ), 8 ) or 0
            if value > 255 then
                syntax_error( "octal escape out of range", line )
            end

            part_count = part_count + 1
            parts[ part_count ] = string_char( value )
            position = octal_end
        else
            syntax_error( "invalid escape sequence", line )
        end

        segment_start = position
        goto string_loop
    end

    position = position + 1

    ---@diagnostic disable-next-line: missing-return
    goto string_loop
end

---@param source string
local function tokenize( source )
    token_count = 0
    token_index = 1

    local position = 1
    local line = 1

    -- adjacent strings are concatenated, like in C
    local previous_string = false

    ::token_loop::

    local byte = string_byte( source, position )
    if byte == nil then
        push_token( TOKEN_EOF, "<end of file>", line )
        return
    end

    if byte == 0x0A then
        line = line + 1
        position = position + 1
    elseif byte == 0x20 or byte == 0x09 or byte == 0x0D or byte == 0x0B or byte == 0x0C then
        position = position + 1
    elseif byte == 0x2F --[[ / ]] then
        local next_byte = string_byte( source, position + 1 )

        if next_byte == 0x2F then
            local line_end = string_find( source, "\n", position + 2, true )
            if line_end == nil then
                position = #source + 1
            else
                position = line_end
            end
        elseif next_byte == 0x2A --[[ * ]] then
            local comment_end = string_find( source, "*/", position + 2, true )
            if comment_end == nil then
                syntax_error( "unterminated comment", line )
            end

            ---@cast comment_end integer

            for index = position + 2, comment_end, 1 do
                if string_byte( source, index ) == 0x0A then
                    line = line + 1
                end
            end

            position = comment_end + 2
        else
            syntax_error( "unexpected '/'", line )
        end
    elseif byte == 0x22 or byte == 0x27 --[[ " ' ]] then
        local value
        value, position = read_quoted( source, position, line )

        if previous_string then
            token_values[ token_count ] = token_values[ token_count ] .. value
        else
            push_token( TOKEN_STRING, value, line )
            previous_string = true
        end

        goto token_loop
    elseif is_digit( byte ) or (byte == 0x2E --[[ . ]] and is_digit( string_byte( source, position + 1 ) )) then
        local number_end = position

        ::number_loop::

        local number_byte = string_byte( source, number_end )

        -- digits, letters (hex, exponent) and dots, exponent signs are checked below
        if is_identifier_byte( number_byte ) or number_byte == 0x2E then
            number_end = number_end + 1
            goto number_loop
        elseif (number_byte == 0x2B or number_byte == 0x2D) then
            local previous_byte = string_byte( source, number_end - 1 )
            -- `1e-5`, but not `0xE-5`
            if (previous_byte == 0x65 or previous_byte == 0x45) and string_byte( source, position + 1 ) ~= 0x78 and string_byte( source, position + 1 ) ~= 0x58 then
                number_end = number_end + 1
                goto number_loop
            end
        end

        push_token( TOKEN_NUMBER, string_sub( source, position, number_end - 1 ), line )
        previous_string = false
        position = number_end
    elseif is_identifier_byte( byte ) then
        local identifier_end = position + 1

        ::identifier_loop::

        if is_identifier_byte( string_byte( source, identifier_end ) ) then
            identifier_end = identifier_end + 1
            goto identifier_loop
        end

        push_token( TOKEN_IDENTIFIER, string_sub( source, position, identifier_end - 1 ), line )
        previous_string = false
        position = identifier_end
    else
        push_token( TOKEN_SYMBOL, string_char( byte ), line )
        previous_string = false
        position = position + 1
    end

    goto token_loop
end

---@return integer token_type
---@return any value
---@return integer line
local function peek()
    return token_types[ token_index ], token_values[ token_index ], token_lines[ token_index ]
end

---@return integer token_type
---@return any value
---@return integer line
local function next_token()
    local token_type, value, line = peek()

    if token_type ~= TOKEN_EOF then
        token_index = token_index + 1
    end

    return token_type, value, line
end

---@param symbol string
---@return boolean
local function accept( symbol )
    local token_type, value = peek()

    if token_type == TOKEN_SYMBOL and value == symbol then
        token_index = token_index + 1
        return true
    end

    return false
end

---@param symbol string
local function expect( symbol )
    local token_type, value, line = next_token()

    if token_type ~= TOKEN_SYMBOL or value ~= symbol then
        syntax_error( string_format( "expected '%s', got '%s'", symbol, value ), line )
    end
end

---@param what string
---@return string
local function expect_identifier( what )
    local token_type, value, line = next_token()

    if token_type ~= TOKEN_IDENTIFIER then
        syntax_error( string_format( "expected %s, got '%s'", what, value ), line )
    end

    return value
end

---@return string
local function expect_string()
    local token_type, value, line = next_token()

    if token_type ~= TOKEN_STRING then
        syntax_error( string_format( "expected a string, got '%s'", value ), line )
    end

    return value
end

--- Reads a dotted name, `foo.bar.Baz` or `.foo.Bar` for absolute type names.
---
---@param what string
---@return string
local function read_full_identifier( what )
    local name = ""

    if accept( "." ) then
        name = "."
    end

    name = name .. expect_identifier( what )

    ::name_loop::

    if accept( "." ) then
        name = name .. "." .. expect_identifier( what )
        goto name_loop
    end

    return name
end

--- Converts the text of an integer literal (`123`, `0x1F`, `017`) to a number.
---
---@param text string
---@return number | nil
local function parse_integer( text )
    if string_find( text, "^0[xX]%x+$" ) ~= nil then
        return raw_tonumber( string_sub( text, 3 ), 16 )
    elseif string_find( text, "^0[0-7]+$" ) ~= nil then
        return raw_tonumber( string_sub( text, 2 ), 8 )
    elseif string_find( text, "^%d+$" ) ~= nil then
        return raw_tonumber( text, 10 )
    end

    return nil
end

---@return integer
local function expect_integer()
    local is_negative = accept( "-" )

    local token_type, value, line = next_token()
    if token_type ~= TOKEN_NUMBER then
        syntax_error( string_format( "expected an integer, got '%s'", value ), line )
    end

    local number = parse_integer( value )
    if number == nil then
        syntax_error( string_format( "invalid integer '%s'", value ), line )
    end

    ---@cast number integer

    if is_negative then
        return -number
    end

    return number
end

--- Reads a constant (option value): a number, a string, an identifier or a `{ ... }` aggregate.
---
---@return any value The number, string or identifier name, `nil` for aggregates.
local function read_constant()
    if accept( "{" ) then
        local depth = 1

        ::aggregate_loop::

        local token_type, value, line = next_token()

        if token_type == TOKEN_EOF then
            syntax_error( "unterminated aggregate value", line )
        elseif token_type == TOKEN_SYMBOL then
            if value == "{" then
                depth = depth + 1
            elseif value == "}" then
                depth = depth - 1

                if depth == 0 then
                    return nil
                end
            end
        end

        goto aggregate_loop
    end

    local sign = 1

    if accept( "-" ) then
        sign = -1
    else
        accept( "+" )
    end

    local token_type, value, line = next_token()

    if token_type == TOKEN_NUMBER then
        local number = parse_integer( value )

        if number == nil and string_find( value, "^%d*%.?%d*[eE]?[%+%-]?%d*$" ) ~= nil then
            number = raw_tonumber( value, 10 )
        end

        if number == nil then
            syntax_error( string_format( "invalid number '%s'", value ), line )
        end

        return number * sign
    elseif token_type == TOKEN_IDENTIFIER then
        if value == "inf" then
            return math_huge * sign
        elseif value == "nan" then
            return math_nan
        elseif sign == -1 then
            syntax_error( string_format( "unexpected '-' before '%s'", value ), line )
        end

        -- `true`, `false` and enum value names
        return value
    elseif token_type == TOKEN_STRING then
        return value
    end

    syntax_error( string_format( "expected a constant, got '%s'", value ), line )
end

--- Reads an option name, `packed`, `(my.custom).field` or `a.b`.
---
---@return string
local function read_option_name()
    local name = ""

    ::option_name_loop::

    if accept( "(" ) then
        name = name .. "(" .. read_full_identifier( "an option name" ) .. ")"
        expect( ")" )
    else
        name = name .. expect_identifier( "an option name" )
    end

    if accept( "." ) then
        name = name .. "."
        goto option_name_loop
    end

    return name
end

--- Reads `[ name = value, ... ]` after a field or an enum value.
---
---@return table<string, any> | nil options
local function read_compact_options()
    if not accept( "[" ) then
        return nil
    end

    ---@type table<string, any>
    local options = {}

    ::compact_option_loop::

    local name = read_option_name()
    expect( "=" )
    options[ name ] = read_constant()

    if accept( "," ) then
        goto compact_option_loop
    end

    expect( "]" )
    return options
end

--- Skips `option name = value;`, the `option` keyword is already read.
local function skip_option_statement()
    read_option_name()
    expect( "=" )
    read_constant()
    expect( ";" )
end

--- Skips the tokens until `;` (`reserved`, `extensions`).
local function skip_statement()
    ::skip_loop::

    local token_type, value, line = next_token()

    if token_type == TOKEN_EOF then
        syntax_error( "unexpected end of file", line )
    elseif token_type ~= TOKEN_SYMBOL or value ~= ";" then
        goto skip_loop
    end
end

--- Skips `name { ... }` with balanced braces (`service`, `extend`).
local function skip_block()
    ::skip_head_loop::

    local token_type, value, line = next_token()

    if token_type == TOKEN_EOF then
        syntax_error( "unexpected end of file", line )
    elseif token_type ~= TOKEN_SYMBOL or value ~= "{" then
        goto skip_head_loop
    end

    local depth = 1

    ::skip_body_loop::

    token_type, value, line = next_token()

    if token_type == TOKEN_EOF then
        syntax_error( "unterminated block", line )
    elseif token_type == TOKEN_SYMBOL then
        if value == "{" then
            depth = depth + 1
        elseif value == "}" then
            depth = depth - 1

            if depth == 0 then
                return
            end
        end
    end

    goto skip_body_loop
end

---@param number integer
---@param line integer
local function check_field_number( number, line )
    if number < 1 or number > 0x1FFFFFFF then
        syntax_error( string_format( "field number %d is out of range 1-536870911", number ), line )
    elseif number >= 19000 and number <= 19999 then
        syntax_error( string_format( "field number %d is reserved for the protobuf implementation", number ), line )
    end
end

--- Converts the `default` option of a proto2 field to its type.
---
---@param field dreamwork.std.protobuf.FieldDescriptor
---@param value any
---@param line integer
---@return any
local function convert_default( field, value, line )
    local type_name = field.type_name

    if type_name == "bool" then
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        end

        syntax_error( "invalid bool default", line )
    elseif type_name == "string" or type_name == "bytes" then
        if raw_type( value ) ~= "string" then
            syntax_error( "invalid string default", line )
        end

        return value
    end

    -- numbers stay numbers, enum value names are resolved later
    return value
end

local syntax = "proto3"

local parse_message

---@param scope string
---@return dreamwork.std.protobuf.EnumDescriptor
local function parse_enum( scope )
    local name = expect_identifier( "an enum name" )

    ---@type dreamwork.std.protobuf.EnumDescriptor
    local descriptor = {
        name = name,
        full_name = scope == "" and name or (scope .. "." .. name),
        values = {}
    }

    local values = descriptor.values
    local value_count = 0

    expect( "{" )

    ::enum_loop::

    local token_type, value, line = next_token()

    if token_type == TOKEN_SYMBOL then
        if value == "}" then
            if value_count == 0 then
                syntax_error( string_format( "enum '%s' has no values", name ), line )
            end

            return descriptor
        elseif value ~= ";" then
            syntax_error( string_format( "unexpected '%s' in enum", value ), line )
        end
    elseif token_type == TOKEN_IDENTIFIER then
        if value == "option" then
            skip_option_statement()
        elseif value == "reserved" then
            skip_statement()
        else
            expect( "=" )
            local number = expect_integer()
            read_compact_options()
            expect( ";" )

            value_count = value_count + 1
            values[ value_count ] = { name = value, number = number }
        end
    else
        syntax_error( string_format( "unexpected '%s' in enum", value ), line )
    end

    ---@diagnostic disable-next-line: missing-return
    goto enum_loop
end

--- Converts `snake_case` to `SnakeCase` for the generated map entry names.
---
---@param name string
---@return string
local function to_camel_case( name )
    return (string_gsub( (string_gsub( name, "^%l", string_upper )), "_(%w)", string_upper ))
end

---@param descriptor dreamwork.std.protobuf.MessageDescriptor
---@param label "optional" | "required" | "repeated" | nil
---@param oneof integer | nil
---@param line integer
local function parse_field( descriptor, label, oneof, line )
    local fields = descriptor.fields
    local token_type, value = peek()

    if token_type == TOKEN_IDENTIFIER and value == "map" and token_types[ token_index + 1 ] == TOKEN_SYMBOL and token_values[ token_index + 1 ] == "<" then
        if label ~= nil or oneof ~= nil then
            syntax_error( "map fields can not have labels or be in a oneof", line )
        end

        next_token()
        expect( "<" )

        local key_type = expect_identifier( "a map key type" )
        if not map_key_types[ key_type ] then
            syntax_error( string_format( "invalid map key type '%s'", key_type ), line )
        end

        expect( "," )
        local value_type = read_full_identifier( "a map value type" )
        expect( ">" )

        local name = expect_identifier( "a field name" )
        expect( "=" )

        local number = expect_integer()
        check_field_number( number, line )

        read_compact_options()
        expect( ";" )

        local entry_name = to_camel_case( name ) .. "Entry"
        local entry_full_name = descriptor.full_name .. "." .. entry_name

        ---@type dreamwork.std.protobuf.MessageDescriptor
        local entry = {
            name = entry_name,
            full_name = entry_full_name,
            fields = {
                { name = "key",   number = 1, label = syntax == "proto2" and "optional" or nil, type_name = key_type,   scope = entry_full_name },
                { name = "value", number = 2, label = syntax == "proto2" and "optional" or nil, type_name = value_type, scope = entry_full_name }
            },
            oneofs = {},
            messages = {},
            enums = {},
            map_entry = true
        }

        local messages = descriptor.messages
        messages[ #messages + 1 ] = entry

        fields[ #fields + 1 ] = {
            name = name,
            number = number,
            label = "repeated",
            type_name = entry_full_name,
            scope = descriptor.full_name
        }

        return
    end

    local type_name = read_full_identifier( "a field type" )

    if type_name == "group" then
        syntax_error( "groups are not supported", line )
    end

    local name = expect_identifier( "a field name" )
    expect( "=" )

    local number = expect_integer()
    check_field_number( number, line )

    ---@type dreamwork.std.protobuf.FieldDescriptor
    local field = {
        name = name,
        number = number,
        label = label,
        type_name = type_name,
        scope = descriptor.full_name,
        oneof = oneof
    }

    local options = read_compact_options()
    if options ~= nil then
        local packed = options.packed
        if packed ~= nil then
            field.packed = packed == "true"
        end

        local default = options.default
        if default ~= nil then
            if syntax ~= "proto2" then
                syntax_error( "default values are only allowed in proto2", line )
            end

            field.default = convert_default( field, default, line )
        end
    end

    expect( ";" )
    fields[ #fields + 1 ] = field
end

---@param descriptor dreamwork.std.protobuf.MessageDescriptor
---@param line integer
local function parse_oneof( descriptor, line )
    local name = expect_identifier( "a oneof name" )

    local oneofs = descriptor.oneofs
    local oneof_index = #oneofs + 1
    oneofs[ oneof_index ] = name

    expect( "{" )

    ::oneof_loop::

    local token_type, value, value_line = peek()

    if token_type == TOKEN_SYMBOL then
        next_token()

        if value == "}" then
            return
        elseif value ~= ";" then
            syntax_error( string_format( "unexpected '%s' in oneof", value ), value_line )
        end
    elseif token_type == TOKEN_IDENTIFIER then
        if value == "option" then
            next_token()
            skip_option_statement()
        else
            parse_field( descriptor, nil, oneof_index, value_line )
        end
    else
        syntax_error( string_format( "unexpected '%s' in oneof '%s'", value, name ), line )
    end

    goto oneof_loop
end

---@param scope string
---@return dreamwork.std.protobuf.MessageDescriptor
function parse_message( scope )
    local name = expect_identifier( "a message name" )
    local full_name = scope == "" and name or (scope .. "." .. name)

    ---@type dreamwork.std.protobuf.MessageDescriptor
    local descriptor = {
        name = name,
        full_name = full_name,
        fields = {},
        oneofs = {},
        messages = {},
        enums = {},
        map_entry = false
    }

    expect( "{" )

    ::message_loop::

    local token_type, value, line = peek()

    if token_type == TOKEN_SYMBOL then
        next_token()

        if value == "}" then
            return descriptor
        elseif value ~= ";" then
            syntax_error( string_format( "unexpected '%s' in message '%s'", value, name ), line )
        end
    elseif token_type == TOKEN_IDENTIFIER then
        if value == "message" then
            next_token()
            local messages = descriptor.messages
            messages[ #messages + 1 ] = parse_message( full_name )
        elseif value == "enum" then
            next_token()
            local enums = descriptor.enums
            enums[ #enums + 1 ] = parse_enum( full_name )
        elseif value == "oneof" then
            next_token()
            parse_oneof( descriptor, line )
        elseif value == "option" then
            next_token()
            skip_option_statement()
        elseif value == "reserved" or value == "extensions" then
            next_token()
            skip_statement()
        elseif value == "extend" then
            next_token()
            skip_block()
        elseif value == "optional" or value == "required" or value == "repeated" then
            next_token()

            if value == "required" and syntax ~= "proto2" then
                syntax_error( "required fields are only allowed in proto2", line )
            end

            parse_field( descriptor, value, nil, line )
        else
            if syntax == "proto2" and not (value == "map" and token_values[ token_index + 1 ] == "<") then
                syntax_error( string_format( "field '%s' needs a label in proto2", value ), line )
            end

            parse_field( descriptor, nil, nil, line )
        end
    else
        syntax_error( string_format( "unexpected '%s' in message '%s'", value, name ), line )
    end

    ---@diagnostic disable-next-line: missing-return
    goto message_loop
end

--- [SHARED AND MENU]
---
--- Parses the text of a `.proto` file into a descriptor, without resolving type names or imports.
---
--- Supports `proto2` and `proto3`: messages, enums, nested types, `oneof`, `map<K, V>`, `repeated`,
--- `optional`, `required`, `[packed]`, `[default]` and imports.
--- Options, `reserved`, `extensions`, `extend` and `service` blocks are parsed and ignored, groups are not supported.
---
--- ```lua
--- local descriptor = protobuf.parseSchema( [[
---     syntax = "proto3";
---     message Point { int32 x = 1; int32 y = 2; }
--- ]], "point.proto" )
---
--- print( descriptor.messages[ 1 ].full_name ) -- Point
--- ```
---
---@param source string The text of the file.
---@param file_name string? The file name used in errors, `"<string>"` by default.
---@return dreamwork.std.protobuf.FileDescriptor descriptor The parsed file.
---@nodiscard
function protobuf.parseSchema( source, file_name )
    current_file = file_name or "<string>"
    tokenize( source )

    syntax = "proto2"

    ---@type dreamwork.std.protobuf.FileDescriptor
    local descriptor = {
        name = current_file,
        package = "",
        syntax = "proto2",
        imports = {},
        messages = {},
        enums = {}
    }

    local token_type, value, line = peek()

    -- proto2 is the default when `syntax` is missing, same as protoc
    if token_type == TOKEN_IDENTIFIER and value == "syntax" then
        next_token()
        expect( "=" )

        local syntax_value = expect_string()
        if syntax_value ~= "proto2" and syntax_value ~= "proto3" then
            syntax_error( string_format( "unsupported syntax '%s'", syntax_value ), line )
        end

        expect( ";" )

        syntax = syntax_value
        descriptor.syntax = syntax_value
    elseif token_type == TOKEN_IDENTIFIER and value == "edition" then
        syntax_error( "editions are not supported, use syntax = \"proto3\"", line )
    end

    local package = ""

    ::file_loop::

    token_type, value, line = next_token()

    if token_type == TOKEN_EOF then
        -- the token arrays keep their strings alive otherwise
        for index = 1, token_count, 1 do
            token_values[ index ] = nil
        end

        return descriptor
    elseif token_type == TOKEN_SYMBOL and value == ";" then
        goto file_loop
    elseif token_type ~= TOKEN_IDENTIFIER then
        syntax_error( string_format( "unexpected '%s'", value ), line )
    end

    if value == "package" then
        if package ~= "" then
            syntax_error( "multiple package statements", line )
        end

        package = read_full_identifier( "a package name" )
        expect( ";" )

        descriptor.package = package
    elseif value == "import" then
        local is_public, is_weak = false, false

        local next_type, next_value = peek()
        if next_type == TOKEN_IDENTIFIER then
            if next_value == "public" then
                is_public = true
            elseif next_value == "weak" then
                is_weak = true
            else
                syntax_error( string_format( "unexpected '%s' in import", next_value ), line )
            end

            next_token()
        end

        local imports = descriptor.imports

        imports[ #imports + 1 ] = {
            path = expect_string(),
            public = is_public,
            weak = is_weak,
        }

        expect( ";" )
    elseif value == "option" then
        skip_option_statement()
    elseif value == "message" then
        local messages = descriptor.messages
        messages[ #messages + 1 ] = parse_message( package )
    elseif value == "enum" then
        local enums = descriptor.enums
        enums[ #enums + 1 ] = parse_enum( package )
    elseif value == "service" or value == "extend" then
        skip_block()
    else
        syntax_error( string_format( "unexpected '%s'", value ), line )
    end

    ---@diagnostic disable-next-line: missing-return
    goto file_loop
end
