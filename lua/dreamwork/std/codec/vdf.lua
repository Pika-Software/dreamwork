local glua_util = util

---@class dreamwork.std
local std = dreamwork.std

local isTable = std.isTable
local isString = std.isString
local isNumber = std.isNumber
local isBoolean = std.isBoolean

local error = std.error
local setmetatable = std.setmetatable

local raw = std.raw
local raw_pairs = raw.pairs
local raw_tostring = raw.tostring
local raw_tonumber = raw.tonumber

local table = std.table
local table_concat = table.concat

local string = std.string
local string_sub, string_rep = string.sub, string.rep
local string_char, string_byte = string.char, string.byte
local string_find, string_gsub = string.find, string.gsub
local string_lower = string.lower

--- [SHARED AND MENU]
---
--- The KeyValues format is used in the Source engine to store meta data for resources, scripts, materials, VGUI elements, and more..
---
---@class dreamwork.std.vdf
local vdf = {}
std.vdf = vdf

if glua_util.TableToKeyValues == nil then

    local escape_map = {
        [ "\\" ] = "\\\\",
        [ "\"" ] = "\\\"",
        [ "\n" ] = "\\n",
        [ "\t" ] = "\\t"
    }

    ---@type table<integer, string>
    local indents = setmetatable( {}, {
        __index = function( self, depth )
            local indent = string_rep( "\t", depth )
            self[ depth ] = indent
            return indent
        end
    } )

    --- plain finds are JIT-compiled, `gsub` is not, so it only runs when there is something to escape
    ---@param str string
    ---@return string
    local function escape( str )
        if string_find( str, "\\", 1, true ) == nil and string_find( str, "\"", 1, true ) == nil and
            string_find( str, "\n", 1, true ) == nil and string_find( str, "\t", 1, true ) == nil then
            return str
        end

        return (string_gsub( str, "[\\\"\n\t]", escape_map ))
    end

    ---@param value any
    ---@return string | nil str
    local function stringify( value )
        if isString( value ) then
            return escape( value )
        elseif isNumber( value ) then
            return raw_tostring( value )
        elseif isBoolean( value ) then
            return value and "1" or "0"
        end

        return nil
    end

    ---@param buffer string[]
    ---@param buffer_size integer
    ---@param tbl table
    ---@param depth integer
    ---@param visited table<table, boolean>
    ---@return integer buffer_size
    local function write_table( buffer, buffer_size, tbl, depth, visited )
        if visited[ tbl ] then
            error( "circular reference detected", 3 )
        end

        visited[ tbl ] = true

        local indent = indents[ depth ]

        for key, value in raw_pairs( tbl ) do
            local key_str = stringify( key )
            if key_str ~= nil then
                if isTable( value ) then
                    buffer[ buffer_size + 1 ] = indent
                    buffer[ buffer_size + 2 ] = "\""
                    buffer[ buffer_size + 3 ] = key_str
                    buffer[ buffer_size + 4 ] = "\"\n"
                    buffer[ buffer_size + 5 ] = indent
                    buffer[ buffer_size + 6 ] = "{\n"

                    buffer_size = write_table( buffer, buffer_size + 6, value, depth + 1, visited )

                    buffer[ buffer_size + 1 ] = indent
                    buffer[ buffer_size + 2 ] = "}\n"
                    buffer_size = buffer_size + 2
                else
                    local value_str = stringify( value )
                    if value_str ~= nil then
                        buffer[ buffer_size + 1 ] = indent
                        buffer[ buffer_size + 2 ] = "\""
                        buffer[ buffer_size + 3 ] = key_str
                        buffer[ buffer_size + 4 ] = "\"\t\t\""
                        buffer[ buffer_size + 5 ] = value_str
                        buffer[ buffer_size + 6 ] = "\"\n"
                        buffer_size = buffer_size + 6
                    end
                end
            end
        end

        visited[ tbl ] = nil

        return buffer_size
    end

    --- [SHARED AND MENU]
    ---
    --- Converts the given table into a KeyValues string (pure Lua implementation).
    ---
    --- Nested tables become sub-sections, booleans are written as `1`/`0`,
    --- unsupported keys and values (functions, userdata, etc.) are skipped.
    ---
    --- `\`, `"`, `\n` and `\t` are escaped, so use `uses_escape_sequences` when deserializing.
    ---
    ---@param tbl table The table to convert.
    ---@param root_key string? The root key name, defaults to `TableToKeyValues`.
    ---@return string key_values The KeyValues string.
    ---@nodiscard
    function vdf.serialize( tbl, root_key )
        local buffer = {
            "\"",
            stringify( root_key or "TableToKeyValues" ) or "TableToKeyValues",
            "\"\n{\n"
        }

        local buffer_size = write_table( buffer, 3, tbl, 1, {} ) + 1
        buffer[ buffer_size ] = "}\n"

        return table_concat( buffer, "", 1, buffer_size )
    end

else
    vdf.serialize = glua_util.TableToKeyValues
end

---@type table<integer, string>
local unescape_map = {
    [ 0x6E --[[ n ]] ] = "\n",
    [ 0x74 --[[ t ]] ] = "\t",
    [ 0x5C --[[ \ ]] ] = "\\",
    [ 0x22 --[[ " ]] ] = "\""
}

local TOKEN_STRING = 1
local TOKEN_OPEN = 2
local TOKEN_CLOSE = 3
local TOKEN_CONDITION = 4

--- position of the next backslash, cached between tokens so the search never rescans the input
local next_backslash = 0

---@param str string
---@param position integer The position right after the opening quote.
---@param str_length integer
---@return string value
---@return integer position
local function read_escaped( str, position, str_length )
    local quote = string_find( str, "\"", position, true ) or (str_length + 1)

    if next_backslash < position then
        next_backslash = string_find( str, "\\", position, true ) or (str_length + 1)
    end

    if next_backslash > quote then
        return string_sub( str, position, quote - 1 ), quote + 1
    end

    local segments, segment_count = {}, 0

    while next_backslash < quote do
        segments[ segment_count + 1 ] = string_sub( str, position, next_backslash - 1 )

        local uint8 = string_byte( str, next_backslash + 1 )
        if uint8 == nil then
            segments[ segment_count + 2 ] = "\\"
        else
            segments[ segment_count + 2 ] = unescape_map[ uint8 ] or ("\\" .. string_char( uint8 ))
        end

        segment_count = segment_count + 2
        position = next_backslash + 2

        next_backslash = string_find( str, "\\", position, true ) or (str_length + 1)

        if quote < position then
            quote = string_find( str, "\"", position, true ) or (str_length + 1)
        end
    end

    segment_count = segment_count + 1
    segments[ segment_count ] = string_sub( str, position, quote - 1 )

    return table_concat( segments, "", 1, segment_count ), quote + 1
end

--- Byte loops for whitespace and unquoted tokens, plain `string.find` for quoted strings and comments,
--- both are JIT-compiled, unlike pattern searches.
---
---@param str string
---@param position integer
---@param str_length integer
---@param uses_escape_sequences boolean
---@return integer | nil kind
---@return integer start The start of the token, `0` if not a string.
---@return integer finish The end of the token, `0` if not a string.
---@return integer position The position after the token.
---@return string | nil value The unescaped value, only for quoted strings with escape sequences enabled.
local function read_token( str, position, str_length, uses_escape_sequences )
    local uint8 = string_byte( str, position )

    -- skip whitespace and `//` comments
    while uint8 == 0x20 or (uint8 ~= nil and ((uint8 >= 0x09 and uint8 <= 0x0D) or (uint8 == 0x2F --[[ / ]] and string_byte( str, position + 1 ) == 0x2F))) do
        if uint8 == 0x2F then
            position = string_find( str, "\n", position + 2, true ) or (str_length + 1)
        else
            position = position + 1
        end

        uint8 = string_byte( str, position )
    end

    if uint8 == nil then
        return nil, 0, 0, str_length + 1
    elseif uint8 == 0x7B --[[ { ]] then
        return TOKEN_OPEN, 0, 0, position + 1
    elseif uint8 == 0x7D --[[ } ]] then
        return TOKEN_CLOSE, 0, 0, position + 1
    elseif uint8 == 0x22 --[[ " ]] then
        if uses_escape_sequences then
            local value, next_position = read_escaped( str, position + 1, str_length )
            return TOKEN_STRING, 0, 0, next_position, value
        end

        local finish = string_find( str, "\"", position + 1, true ) or (str_length + 1)
        return TOKEN_STRING, position + 1, finish - 1, finish + 1
    elseif uint8 == 0x5B --[[ [ ]] then
        return TOKEN_CONDITION, 0, 0, (string_find( str, "]", position + 1, true ) or str_length) + 1
    end

    local finish = position + 1
    uint8 = string_byte( str, finish )

    while uint8 ~= nil and uint8 ~= 0x20 and (uint8 < 0x09 or uint8 > 0x0D) and
        uint8 ~= 0x22 --[[ " ]] and uint8 ~= 0x7B --[[ { ]] and uint8 ~= 0x7D --[[ } ]] do
        finish = finish + 1
        uint8 = string_byte( str, finish )
    end

    return TOKEN_STRING, position, finish - 1, finish
end

--- Checks if `str[start..finish]` is `-?digits`, `-?digits.digits?` or `-?.digits`.
---
---@param str string
---@param start integer
---@param finish integer
---@return boolean
local function is_number( str, start, finish )
    if string_byte( str, start ) == 0x2D --[[ - ]] then
        start = start + 1
    end

    if start > finish then
        return false
    end

    local has_dot = false

    for index = start, finish, 1 do
        local uint8 = string_byte( str, index )
        if uint8 == 0x2E --[[ . ]] then
            if has_dot then
                return false
            end

            has_dot = true
        elseif uint8 < 0x30 or uint8 > 0x39 then
            return false
        end
    end

    return not (has_dot and start == finish)
end

---@param str string
---@param position integer
---@param str_length integer
---@param uses_escape_sequences boolean
---@param preserve_key_case boolean
---@param result table
---@return integer position
local function read_section( str, position, str_length, uses_escape_sequences, preserve_key_case, result )
    local kind, start, finish, escaped

    kind, start, finish, position, escaped = read_token( str, position, str_length, uses_escape_sequences )

    while kind ~= nil and kind ~= TOKEN_CLOSE do
        if kind == TOKEN_OPEN then
            -- anonymous section, parse and discard
            position = read_section( str, position, str_length, uses_escape_sequences, preserve_key_case, {} )
        elseif kind == TOKEN_STRING then
            ---@type string | number
            local key

            if escaped == nil then
                key = string_sub( str, start, finish )

                if not preserve_key_case then
                    key = string_lower( key )
                end

                if is_number( str, start, finish ) then
                    key = raw_tonumber( key, 10 ) or key
                end
            else
                key = preserve_key_case and escaped or string_lower( escaped )

                if is_number( escaped, 1, #escaped ) then
                    key = raw_tonumber( escaped, 10 ) or key
                end
            end

            repeat
                kind, start, finish, position, escaped = read_token( str, position, str_length, uses_escape_sequences )
            until kind ~= TOKEN_CONDITION

            ---@type string | number | table
            local value

            if kind == TOKEN_OPEN then
                value = {}
                position = read_section( str, position, str_length, uses_escape_sequences, preserve_key_case, value )
            elseif kind == TOKEN_STRING then
                if escaped == nil then
                    value = string_sub( str, start, finish )

                    if is_number( str, start, finish ) then
                        value = raw_tonumber( value, 10 ) or value
                    end
                elseif is_number( escaped, 1, #escaped ) then
                    value = raw_tonumber( escaped, 10 ) or escaped
                else
                    value = escaped
                end

                -- skip trailing conditional, e.g. `"key" "value" [$WIN32]`
                local uint8 = string_byte( str, position )

                while uint8 == 0x20 or uint8 == 0x09 do
                    position = position + 1
                    uint8 = string_byte( str, position )
                end

                if uint8 == 0x5B --[[ [ ]] then
                    position = (string_find( str, "]", position + 1, true ) or str_length) + 1
                end
            else
                -- key without value, end of section or input
                return position
            end

            result[ key ] = value
        end

        kind, start, finish, position, escaped = read_token( str, position, str_length, uses_escape_sequences )
    end

    return position
end

--- [SHARED AND MENU]
---
--- Converts a KeyValues string into a key/value table (pure Lua implementation).
---
--- The root key is discarded, its contents are returned.
---
--- Order is not preserved, repeated keys overwrite earlier ones, numeric keys and values are converted to numbers.
---
--- Supports quoted and unquoted tokens, `//` comments and skips `[$CONDITION]` blocks.
---
---@param key_values string The KeyValues string to convert.
---@param uses_escape_sequences boolean? If set to `true`, will replace `\t`, `\n`, `\"` and `\\` with their escaped variants.
---@param preserve_key_case boolean? Whether to preserve key case or not (always lowercase).
---@return table result The converted table.
---@nodiscard
function vdf.deserialize( key_values, uses_escape_sequences, preserve_key_case )
    if not isString( key_values ) then
        error( "bad argument #1 to 'decode' (string expected)", 2 )
    end

    uses_escape_sequences = uses_escape_sequences == true
    next_backslash = 0

    local str_length = #key_values

    -- root key, its name is discarded
    local kind, _, _, position = read_token( key_values, 1, str_length, uses_escape_sequences )
    if kind ~= TOKEN_STRING then
        return {}
    end

    repeat
        kind, _, _, position = read_token( key_values, position, str_length, uses_escape_sequences )
    until kind ~= TOKEN_CONDITION

    local result = {}

    if kind == TOKEN_OPEN then
        read_section( key_values, position, str_length, uses_escape_sequences, preserve_key_case == true, result )
    end

    return result
end
