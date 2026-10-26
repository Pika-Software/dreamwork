---@class dreamwork.std
local std = dreamwork.std

local isString = std.isString
local isTable = std.isTable

local tostring = std.tostring
local pairs = std.pairs

local raw = std.raw
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local class = std.class

local debug = std.debug
local debug_fempty = debug.fempty
local debug_getmetatable = debug.getmetatable

local table = std.table
local table_concat = table.concat

local string = std.string
local string_byteRep = string.byteRep
local string_toNumber = string.toNumber
local string_sub, string_len = string.sub, string.len
local string_char, string_byte = string.char, string.byte
local string_gsub, string_match = string.gsub, string.match
local string_find, string_format = string.find, string.format

--- [SHARED AND MENU]
---
--- A XML node object, representing a node in an XML document.
---
--- Can be converted to string using `:toString()` or `tostring()`.
---
--- Usage:
---
--- ```lua
--- local root = XMLNode.fromString( [[
--- <root>
---     <child>
---         <title>Test Title</title>
---     </child>
--- </root>
--- ]] )
---
--- print( root:toString( false ) ) -- <root><child><title>Test Title</title></child></root>
--- ```
---
---@class dreamwork.std.XMLNode : dreamwork.std.Object
---@field __class dreamwork.std.XMLNodeClass
---@field name string The name of the node.
---@field attributes nil | table<string, (string | nil)> The attributes of the node.
---@field parent dreamwork.std.XMLNode | nil The parent node.
---@field data nil | string | table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])> The data of the node.
local XMLNode = class.base( "XMLNode", false )

---@alias dreamwork.std.XMLNode.Value string | dreamwork.std.XMLNode

--- [SHARED AND MENU]
---
--- A XML node class, allowing parsing and creation of XML nodes.
---
--- Usage:
---
--- ```lua
--- local root = XMLNode.fromString( [[
--- <root>
---     <child>
---         <title>Test Title</title>
---     </child>
---     <child>
---         <title>Test Title 2</title>
---     </child>
---     <child>
---         <title>Test Title 3</title>
---     </child>
--- </root>
--- ]] )
---
--- print( root:get( "child[2].title" ) ) -- Test Title 2
--- ```
---
---@class dreamwork.std.XMLNodeClass : dreamwork.std.XMLNode
---@field __base dreamwork.std.XMLNode
---@overload fun(name: string, attributes: (table<string, string> | nil), parent: (dreamwork.std.XMLNode | nil) ): dreamwork.std.XMLNode
local XMLNodeClass = class.create( XMLNode )
std.XMLNode = XMLNodeClass

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `XMLNode`.
---
---@param value any
---@return boolean is_xml_node
local function isNode( value )
    return debug_getmetatable( value ) == XMLNode
end

std.isXMLNode = isNode

---@param name string
---@param attributes table<string, string> | nil
---@param parent dreamwork.std.XMLNode | nil
---@protected
function XMLNode:__init( name, attributes, parent )
    self.name = name
    self.parent = parent
    self.attributes = attributes

    if parent == nil then return end

    local parent_data = parent.data
    if parent_data == nil then
        parent.data = {
            [ name ] = self -- create new data with self if parent has no data
        }

        return
    end

    if isString( parent_data ) then
        ---@cast parent_data string

        parent.data = {
            [ name ] = self,
            [ "" ] = parent_data -- replace string data with map that contains string as text and self
        }

        return
    end

    ---@cast parent_data table<string, (dreamwork.std.XMLNode.Value | dreamwork.std.XMLNode.Value[])>

    local value = parent_data[ name ]
    if value == nil then
        parent_data[ name ] = self -- put self if no value in map
        return
    end

    if isString( value ) or isNode( value ) then
        ---@cast value string | dreamwork.std.XMLNode
        parent_data[ name ] = { value, self } -- only way is replace string value with `dreamwork.std.XMLNode.Value[]`
        return
    end

    ---@cast value table<string, dreamwork.std.XMLNode.Value[]>

    value[ #value + 1 ] = self -- append self to existing array
end

--- [SHARED AND MENU]
---
--- Checks whether the node is empty.
---
---@return boolean is_empty
function XMLNode:isEmpty()
    return self.data == nil
end

--- [SHARED AND MENU]
---
--- Returns the value of the attribute with the given name or `nil` if not found.
---
---@param name string The name of the attribute to get.
---@return nil | string value The value of the attribute or `nil` if not found.
function XMLNode:getAttribute( name )
    local attributes = self.attributes
    if attributes == nil then
        return nil
    end

    return attributes[ name ]
end

--- [SHARED AND MENU]
---
--- Sets the value of the attribute with the given name.
---
---@param name string The name of the attribute to set.
---@param value string | nil The value to set for the attribute, or `nil` to remove the attribute.
function XMLNode:setAttribute( name, value )
    local attributes = self.attributes
    if attributes == nil then
        self.attributes = {
            [ name ] = value
        }

        return
    end

    attributes[ name ] = value
end

--- [SHARED AND MENU]
---
--- Returns the value of the node at the given key or `nil` if not found.
---
--- Each key segment can be indexed with `[n]`, e.g. `child[2].title`, and an empty key `""` returns the node's text.
---
---@param key string The key to look up in the node's data, with dot-separated keys for nested values.
---@return nil | string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[] value The value of the node at the given key, or `nil` if not found.
function XMLNode:get( key )
    local node = self
    local position = 1

    ::get_loop::

    local data = node.data
    if data == nil then
        return nil
    end

    local key_end = string_find( key, ".", position, true )

    local name
    if key_end ~= nil then
        name = string_sub( key, position, key_end - 1 )
    elseif position == 1 then
        name = key
    else
        name = string_sub( key, position )
    end

    local index
    if string_byte( name, -1 ) == 0x5D --[[ ] ]] then
        -- plain find and `tonumber` without a base are compiled, a capture pattern is not
        local index_start = string_find( name, "[", 1, true )
        if index_start ~= nil then
            index = raw_tonumber( string_sub( name, index_start + 1, -2 ) )
            if index ~= nil then
                name = string_sub( name, 1, index_start - 1 )
            end
        end
    end

    if isString( data ) then
        ---@cast data string

        if key_end == nil and name == "" and (index == nil or index == 1) then
            return data
        end

        return nil
    end

    ---@cast data table<string, (dreamwork.std.XMLNode.Value | dreamwork.std.XMLNode.Value[])>

    local data_value = data[ name ]
    if data_value == nil then
        local number = string_toNumber( name )
        if number == nil then
            return nil
        end

        data_value = data[ number ]
        if data_value == nil then
            return nil
        end
    end

    if index ~= nil then
        if isString( data_value ) or isNode( data_value ) then
            -- a single value is a list of one
            if index ~= 1 then
                return nil
            end
        else
            ---@cast data_value dreamwork.std.XMLNode.Value[]
            data_value = data_value[ index ]
        end
    end

    if key_end == nil then
        return data_value
    end

    if isNode( data_value ) then
        ---@cast data_value dreamwork.std.XMLNode
        node = data_value
        position = key_end + 1
        goto get_loop
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Sets the value of the node at the given key, supporting dot-separated keys for nested values.
---
--- Missing or non-node intermediate values are replaced with new empty nodes.
---
---@param key string The key to set, with dot-separated keys for nested values.
---@param value dreamwork.std.XMLNode.Value | dreamwork.std.XMLNode.Value[] | nil The value to set, which can be a string or a node, or `nil` to remove the value.
function XMLNode:set( key, value )
    local node = self

    ::set_loop::

    local data = node.data
    if data == nil or isString( data ) then
        ---@diagnostic disable-next-line: assign-type-mismatch
        data = { [ "" ] = data }
        node.data = data
    end

    ---@cast data table<string, (dreamwork.std.XMLNode.Value | dreamwork.std.XMLNode.Value[])>

    local key_start = string_find( key, ".", 1, true )
    if key_start == nil or key_start == string_len( key ) then
        if key_start ~= nil then
            key = string_sub( key, 1, key_start - 1 )
        end

        if isNode( value ) then
            ---@cast value dreamwork.std.XMLNode
            value.parent = node
        end

        data[ key ] = value
        return
    end

    local name = string_sub( key, 1, key_start - 1 )
    key = string_sub( key, key_start + 1 )

    local data_value = data[ name ]
    if isNode( data_value ) then
        ---@cast data_value dreamwork.std.XMLNode
        node = data_value
        goto set_loop
    end

    local child = XMLNodeClass( name, nil, nil )
    child.parent = node
    data[ name ] = child

    node = child
    goto set_loop
end

--- Splits the key into the node owning the last segment and the last segment itself.
---
---@param node dreamwork.std.XMLNode
---@param key string
---@return dreamwork.std.XMLNode | nil owner
---@return string key_name
local function resolve( node, key )
    local key_path, key_name = string_match( key, "^(.+)%.([^.]+)$" )
    if key_path == nil then
        return node, key
    end

    local owner = node:get( key_path )
    if isNode( owner ) then
        ---@cast owner dreamwork.std.XMLNode
        return owner, key_name
    end

    return nil, key_name
end

--- Returns the data table of the node at the given key, or `nil` if there is none.
---
---@param node dreamwork.std.XMLNode
---@param key string
---@return table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])> | nil data
---@return string key_name
local function resolve_data( node, key )
    local owner, key_name = resolve( node, key )
    if owner == nil then
        return nil, key_name
    end

    local data = owner.data
    if data == nil or isString( data ) then
        return nil, key_name
    end

    ---@cast data table<string, string|dreamwork.std.XMLNode|string|dreamwork.std.XMLNode[]>

    return data, key_name
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a value at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a value at the given key.
function XMLNode:contains( key )
    local data, key_name = resolve_data( self, key )
    return data ~= nil and data[ key_name ] ~= nil
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a list at the given key.
function XMLNode:containsList( key )
    local data, key_name = resolve_data( self, key )
    if data == nil then
        return false
    end

    local value = data[ key_name ]
    return not (value == nil or isString( value ) or isNode( value ))
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a string at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a string at the given key.
function XMLNode:containsString( key )
    local data, key_name = resolve_data( self, key )
    return data ~= nil and isString( data[ key_name ] )
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a node at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a node at the given key.
function XMLNode:containsNode( key )
    local data, key_name = resolve_data( self, key )
    return data ~= nil and isNode( data[ key_name ] )
end

--- [SHARED AND MENU]
---
--- Returns the length of the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to get the length of, with dot-separated keys for nested values.
---@return integer length The length of the list at the given key.
function XMLNode:getLength( key )
    local data, key_name = resolve_data( self, key )
    if data == nil then
        return 0
    end

    local value = data[ key_name ]
    if value == nil or isString( value ) or isNode( value ) then
        return 0
    end

    ---@cast value dreamwork.std.XMLNode.Value[]
    return #value
end

--- [SHARED AND MENU]
---
--- Pushes a value to the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to push the value to, with dot-separated keys for nested values.
---@param value string | dreamwork.std.XMLNode The value to push to the list.
function XMLNode:push( key, value )
    local node, key_name = resolve( self, key )
    if node == nil then
        return
    end

    local data = node.data
    if data == nil or isString( data ) then
        ---@diagnostic disable-next-line: assign-type-mismatch
        data = { [ "" ] = data }
        node.data = data
    end

    ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

    if isNode( value ) then
        ---@cast value dreamwork.std.XMLNode
        value.parent = node
    end

    local data_value = data[ key_name ]
    if data_value == nil then
        data[ key_name ] = value
        return
    end

    if isString( data_value ) or isNode( data_value ) then
        ---@cast data_value string | dreamwork.std.XMLNode
        data[ key_name ] = { data_value, value }
        return
    end

    ---@cast data_value dreamwork.std.XMLNode.Value[]
    data_value[ #data_value + 1 ] = value
end

--- [SHARED AND MENU]
---
--- Pops a value from the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to pop the value from, with dot-separated keys for nested values.
---@return nil | string | dreamwork.std.XMLNode The popped value, or `nil` if the key does not exist or the value is not a node.
function XMLNode:pop( key )
    local data, key_name = resolve_data( self, key )
    if data == nil then
        return nil
    end

    local data_value = data[ key_name ]
    if data_value == nil then
        return nil
    end

    if isString( data_value ) or isNode( data_value ) then
        ---@cast data_value string | dreamwork.std.XMLNode
        data[ key_name ] = nil
        return data_value
    end

    ---@cast data_value dreamwork.std.XMLNode.Value[]

    local data_length = #data_value

    local value = data_value[ data_length ]

    if data_length > 1 then
        data_value[ data_length ] = nil
    else
        data[ key_name ] = nil
    end

    return value
end

--- [SHARED AND MENU]
---
--- Removes the value at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to remove, with dot-separated keys for nested values.
---@return boolean success Returns `true` if the value was removed, `false` otherwise (e.g. key not found).
function XMLNode:remove( key )
    local data, key_name = resolve_data( self, key )
    if data == nil or data[ key_name ] == nil then
        return false
    end

    data[ key_name ] = nil
    return true
end

--- [SHARED AND MENU]
---
--- Returns an iterator function for the node at the given key, supporting dot-separated keys for nested values.
---
--- Text content is returned with an empty key `""`, list items are returned one by one with the list key.
---
---@param key? string The key to iterate over, with dot-separated keys for nested values.
---@return fun(): ( ( string | nil ), ( string | dreamwork.std.XMLNode ) ) fn The iterator function, which returns key-value pairs for the node at the given key.
function XMLNode:iterator( key )
    if key ~= nil then
        local node = self:get( key )
        if isNode( node ) then
            ---@cast node dreamwork.std.XMLNode
            return node:iterator()
        end

        return debug_fempty
    end

    local data = self.data
    if data == nil then
        return debug_fempty
    end

    if isString( data ) then
        ---@cast data string
        local wait = true

        return function()
            if wait then
                wait = false
                return "", data
            end

            ---@diagnostic disable-next-line: return-type-mismatch
            return nil, nil
        end
    end

    ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

    local data_key, data_value

    local index = 0
    local size = 0

    return function()
        ::iterator_loop::

        if index < size then
            index = index + 1
            return data_key, data_value[ index ]
        end

        data_key, data_value = raw_next( data, data_key )
        if data_key == nil then
            ---@diagnostic disable-next-line: return-type-mismatch
            return nil, nil
        end

        if isString( data_value ) or isNode( data_value ) then
            ---@cast data_value string
            index, size = 0, 0
            return data_key, data_value
        end

        -- lists are flattened, empty ones are skipped
        index, size = 0, #data_value

        ---@diagnostic disable-next-line: missing-return
        goto iterator_loop
    end
end

local escape_text, decode_entities
do

    local text_escapes = {
        [ "&" ] = "&amp;",
        [ "<" ] = "&lt;",
        [ ">" ] = "&gt;",
        [ "\"" ] = "&quot;"
    }

    --- Escapes `&`, `<`, `>` and `"` so the string is safe for both text and attribute values.
    ---
    ---@param str string
    ---@return string
    function escape_text( str )
        -- plain finds are much faster than a pattern set in the common no-escape case
        if string_find( str, "&", 1, true ) == nil and string_find( str, "<", 1, true ) == nil and
            string_find( str, ">", 1, true ) == nil and string_find( str, "\"", 1, true ) == nil then
            return str
        end

        return (string_gsub( str, "[&<>\"]", text_escapes ))
    end

    local named_entities = {
        lt = "<",
        gt = ">",
        amp = "&",
        quot = "\"",
        apos = "\'"
    }

    ---@param code_point integer
    ---@return string | nil
    local function utf8_encode( code_point )
        if code_point < 0x80 then
            return string_char( code_point )
        elseif code_point < 0x800 then
            return string_char(
                0xC0 + (code_point - code_point % 0x40) / 0x40,
                0x80 + code_point % 0x40
            )
        elseif code_point < 0x10000 then
            return string_char(
                0xE0 + (code_point - code_point % 0x1000) / 0x1000,
                0x80 + (code_point % 0x1000 - code_point % 0x40) / 0x40,
                0x80 + code_point % 0x40
            )
        else
            return string_char(
                0xF0 + (code_point - code_point % 0x40000) / 0x40000,
                0x80 + (code_point % 0x40000 - code_point % 0x1000) / 0x1000,
                0x80 + (code_point % 0x1000 - code_point % 0x40) / 0x40,
                0x80 + code_point % 0x40
            )
        end
    end

    ---@param name string
    ---@return string | nil
    local function decode_entity( name )
        local replacement = named_entities[ name ]
        if replacement ~= nil then
            return replacement
        end

        local uint8_1, uint8_2 = string_byte( name, 1, 2 )
        if uint8_1 ~= 0x23 --[[ # ]] then
            return nil
        end

        local code_point
        if uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]] then
            code_point = raw_tonumber( string_sub( name, 3 ), 16 )
        else
            code_point = raw_tonumber( string_sub( name, 2 ), 10 )
        end

        if code_point == nil or code_point < 1 or code_point > 0x10FFFF or (code_point >= 0xD800 and code_point <= 0xDFFF) then
            return nil -- keeps the original text
        end

        return utf8_encode( code_point )
    end

    --- Decodes named and numeric character references in one pass, unknown ones are kept as is.
    ---
    ---@param str string
    ---@return string
    function decode_entities( str )
        if string_find( str, "&", 1, true ) == nil then
            return str
        end

        return (string_gsub( str, "&(#?%w+);", decode_entity ))
    end

end

do

    ---@param attributes table<string, (string | nil)>
    ---@return string attributes_str
    local function format_attributes( attributes )
        ---@type string[]
        local lines = {}

        ---@type integer
        local line_count = 0

        for key, value in raw_pairs( attributes ) do
            if not isString( value ) then
                value = tostring( value )
            end

            line_count = line_count + 1
            lines[ line_count ] = " " .. key .. "=\"" .. escape_text( value ) .. "\""
        end

        if line_count == 0 then
            return ""
        elseif line_count == 1 then
            return lines[ 1 ]
        else
            return table_concat( lines, "", 1, line_count )
        end
    end

    ---@param lines string[]
    ---@param line_count integer
    ---@param object dreamwork.std.XMLNode
    ---@param name string
    ---@param indent string
    ---@param pretty boolean
    ---@return integer line_count
    local function node_to_string( lines, line_count, object, name, indent, pretty )
        local attributes = object.attributes

        local open_tag
        if attributes == nil then
            open_tag = indent .. "<" .. name
        else
            open_tag = indent .. "<" .. name .. format_attributes( attributes )
        end

        local data = object.data
        if data == nil then
            line_count = line_count + 1
            lines[ line_count ] = open_tag .. "/>"
            return line_count
        end

        if isString( data ) then
            ---@cast data string
            line_count = line_count + 1
            lines[ line_count ] = open_tag .. ">" .. escape_text( data ) .. "</" .. name .. ">"
            return line_count
        end

        ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

        line_count = line_count + 1
        lines[ line_count ] = open_tag .. ">"

        local child_indent = pretty and (indent .. "  ") or ""

        local text = data[ "" ]
        if isString( text ) then
            ---@cast text string
            line_count = line_count + 1
            lines[ line_count ] = child_indent .. escape_text( text )
        end

        for key, value in raw_pairs( data ) do
            if key == "" then
                -- text content, already written above
            elseif isNode( value ) then
                ---@cast value dreamwork.std.XMLNode
                line_count = node_to_string( lines, line_count, value, key, child_indent, pretty )
            elseif isString( value ) then
                ---@cast value string
                line_count = line_count + 1
                lines[ line_count ] = child_indent .. "<" .. key .. ">" .. escape_text( value ) .. "</" .. key .. ">"
            else
                ---@cast value dreamwork.std.XMLNode.Value[]

                for i = 1, #value, 1 do
                    local sub_value = value[ i ]
                    if isNode( sub_value ) then
                        ---@cast sub_value dreamwork.std.XMLNode
                        line_count = node_to_string( lines, line_count, sub_value, key, child_indent, pretty )
                    elseif isString( sub_value ) then
                        ---@cast sub_value string
                        line_count = line_count + 1
                        lines[ line_count ] = child_indent .. "<" .. key .. ">" .. escape_text( sub_value ) .. "</" .. key .. ">"
                    end
                end
            end
        end

        line_count = line_count + 1
        lines[ line_count ] = indent .. "</" .. name .. ">"

        return line_count
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the XML string representation of this node.
    ---
    ---@param pretty? boolean Whether to use pretty formatting (indentation and newlines).
    ---@param name? string The name of the node.
    ---@param level? number The indentation level.
    ---@return string str The XML string representation of this node.
    function XMLNode:toString( pretty, name, level )
        pretty = pretty == true

        local indent = ""
        if pretty and level ~= nil and level > 0 then
            indent = string_byteRep( 0x20, level * 2 )
        end

        local lines = {}

        local line_count = node_to_string( lines, 0, self, name or self.name, indent, pretty )
        if line_count == 1 then
            return lines[ 1 ]
        end

        return table_concat( lines, pretty and "\n" or "", 1, line_count )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts XML node structure to a Lua table.
    ---
    --- Text content is stored with an empty key `""`, attributes are not included.
    ---
    ---@return table
    function XMLNode:toTable()
        local data = self.data
        if data == nil then
            return {}
        end

        if isString( data ) then
            ---@cast data string
            return { [ "" ] = data }
        end

        ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

        local result = {}

        for key, value in raw_pairs( data ) do
            if isNode( value ) then
                ---@cast value dreamwork.std.XMLNode
                result[ key ] = value:toTable()
            elseif isString( value ) then
                result[ key ] = value
            else
                ---@cast value dreamwork.std.XMLNode.Value[]

                local list = {}

                for i = 1, #value, 1 do
                    local sub_value = value[ i ]
                    if isNode( sub_value ) then
                        ---@cast sub_value dreamwork.std.XMLNode
                        list[ i ] = sub_value:toTable()
                    else
                        list[ i ] = sub_value
                    end
                end

                result[ key ] = list
            end
        end

        return result
    end

    ---@return string
    ---@protected
    function XMLNode:__tostring()
        return self:toString( false )
    end

    ---@return string
    ---@protected
    function XMLNode:__represent()
        local attributes = self.attributes
        if attributes == nil then
            return string_format( "XMLNode: %p <%s/>", self, self.name )
        else
            return string_format( "XMLNode: %p <%s%s/>", self, self.name, format_attributes( attributes ) )
        end
    end

end

do

    ---@type table<integer, boolean>
    local is_space = {
        [ 0x09 ] = true, -- \t
        [ 0x0A ] = true, -- \n
        [ 0x0B ] = true, -- \v
        [ 0x0C ] = true, -- \f
        [ 0x0D ] = true, -- \r
        [ 0x20 ] = true  -- space
    }

    --- Collapses a node without attributes and children into a plain string in its parent.
    ---
    ---@param node dreamwork.std.XMLNode
    ---@param tag_name string
    local function tree_endtag( node, tag_name )
        if node.attributes ~= nil then return end

        local data = node.data
        if data == nil then
            data = ""
        elseif not isString( data ) then
            return
        end

        ---@cast data string

        local parent = node.parent
        if parent == nil then return end

        local parent_data = parent.data
        if parent_data == nil or isString( parent_data ) then return end

        ---@cast parent_data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

        local parent_value = parent_data[ tag_name ]
        if parent_value == node then
            parent_data[ tag_name ] = data
            return
        end

        if parent_value == nil or isString( parent_value ) or isNode( parent_value ) then
            return
        end

        ---@cast parent_value dreamwork.std.XMLNode.Value[]

        for i = #parent_value, 1, -1 do
            if parent_value[ i ] == node then
                parent_value[ i ] = data
                break
            end
        end
    end

    --- Appends text to the node, text next to child nodes is stored with an empty key `""`.
    ---
    ---@param node dreamwork.std.XMLNode
    ---@param text string
    local function tree_text( node, text )
        local data = node.data
        if data == nil then
            node.data = text
        elseif isString( data ) then
            ---@cast data string
            node.data = data .. text
        else
            ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>
            local existing = data[ "" ]
            if existing == nil then
                data[ "" ] = text
            else
                data[ "" ] = existing .. text
            end
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a table to an XML node structure.
    ---
    ---@param tbl table The table to convert to an XML node.
    ---@param name? string The name of the root node.
    ---@return dreamwork.std.XMLNode root_node The root node of the XML tree.
    function XMLNodeClass.fromTable( tbl, name )
        local node = XMLNodeClass( name or "root", nil, nil )

        for key, value in pairs( tbl ) do
            if not isString( key ) then
                key = tostring( key )
            end

            if isNode( value ) then
                ---@cast value dreamwork.std.XMLNode
                node:push( key, value )
            elseif isTable( value ) then
                ---@cast value table
                node:push( key, XMLNodeClass.fromTable( value, key ) )
            elseif isString( value ) then
                ---@cast value string
                node:push( key, value )
            else
                ---@cast value any
                node:push( key, tostring( value ) )
            end
        end

        return node
    end

    --- [SHARED AND MENU]
    ---
    --- Converts an XML string to an XML node structure.
    ---
    ---@param xml_str string
    ---@return dreamwork.std.XMLNode | nil
    function XMLNodeClass.fromString( xml_str )
        ---@type dreamwork.std.XMLNode | nil
        local active_node

        ---@type dreamwork.std.XMLNode | nil
        local root_node

        -- text chunks of the active node, joined once the next tag starts
        ---@type string[]
        local text_buffer = {}

        ---@type integer
        local text_count = 0

        ---@type integer
        local position = 1

        ::analyze_loop::

        local tag_start = string_find( xml_str, "<", position, true )

        -- text before the next tag, trimmed
        local text_start = string_find( xml_str, "%S", position )
        if text_start ~= nil and (tag_start == nil or text_start < tag_start) then
            if active_node == nil then
                std.errorf( 2, false, "XML parsing failed, text outside of the root element at position %d", text_start )
                return nil
            end

            local text_end = (tag_start or (string_len( xml_str ) + 1)) - 1
            while is_space[ string_byte( xml_str, text_end ) ] do
                text_end = text_end - 1
            end

            text_count = text_count + 1
            text_buffer[ text_count ] = decode_entities( string_sub( xml_str, text_start, text_end ) )
        end

        if tag_start == nil then
            if active_node ~= nil then
                std.errorf( 2, false, "XML parsing failed, incomplete XML, tag '%s' is not closed.", active_node.name )
                return nil
            end

            return root_node
        end

        local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( xml_str, tag_start + 1, tag_start + 8 )

        -- PI
        if b1 == 0x3F --[[ ? ]] then
            local _, pi_end = string_find( xml_str, "?>", tag_start + 2, true )
            if pi_end == nil then
                std.errorf( 2, false, "XML parsing failed, processing instruction is not closed at position %d", tag_start )
                return nil
            end

            position = pi_end + 1
            goto analyze_loop
        end

        if b1 == 0x21 --[[ ! ]] then
            -- Comment
            if b2 == 0x2D --[[ - ]] and b3 == 0x2D --[[ - ]] then
                local _, comment_end = string_find( xml_str, "-->", tag_start + 4, true )
                if comment_end == nil then
                    std.errorf( 2, false, "XML parsing failed, comment is not closed at position %d", tag_start )
                    return nil
                end

                position = comment_end + 1
                goto analyze_loop
            end

            -- CDATA
            if b2 == 0x5B --[[ [ ]] and b3 == 0x43 --[[ C ]] and b4 == 0x44 --[[ D ]] and b5 == 0x41 --[[ A ]] and
                b6 == 0x54 --[[ T ]] and b7 == 0x41 --[[ A ]] and b8 == 0x5B --[[ [ ]] then

                local cdata_start, cdata_end = string_find( xml_str, "]]>", tag_start + 9, true )
                if cdata_start == nil then
                    std.errorf( 2, false, "XML parsing failed, CDATA is not closed at position %d", tag_start )
                    return nil
                end

                if active_node == nil then
                    std.errorf( 2, false, "XML parsing failed, CDATA outside of the root element at position %d", tag_start )
                    return nil
                end

                text_count = text_count + 1
                text_buffer[ text_count ] = string_sub( xml_str, tag_start + 9, cdata_start - 1 )

                position = cdata_end + 1
                goto analyze_loop
            end

            -- DOCTYPE
            if b2 == 0x44 --[[ D ]] and b3 == 0x4F --[[ O ]] and b4 == 0x43 --[[ C ]] and b5 == 0x54 --[[ T ]] and
                b6 == 0x59 --[[ Y ]] and b7 == 0x50 --[[ P ]] and b8 == 0x45 --[[ E ]] then

                local _, doctype_end = string_find( xml_str, "^<!DOCTYPE[^%[>]*%b[]%s*>", tag_start )
                if doctype_end == nil then
                    _, doctype_end = string_find( xml_str, ">", tag_start, true )
                end

                if doctype_end == nil then
                    std.errorf( 2, false, "XML parsing failed, DOCTYPE is not closed at position %d", tag_start )
                    return nil
                end

                position = doctype_end + 1
                goto analyze_loop
            end

            std.errorf( 2, false, "XML parsing failed, unknown markup declaration at position %d", tag_start )
            return nil
        end

        do

            local _, name_end, closing, tag_name = string_find( xml_str, "^(/?)([%w_:%.%-]+)", tag_start + 1 )
            if name_end == nil then
                std.errorf( 2, false, "XML parsing failed, invalid tag name at position %d", tag_start )
                return nil
            end

            if text_count ~= 0 then
                ---@cast active_node dreamwork.std.XMLNode
                tree_text( active_node, text_count == 1 and text_buffer[ 1 ] or table_concat( text_buffer, "", 1, text_count ) )
                text_count = 0
            end

            ---@type table<string, string> | nil
            local tag_attributes

            local cursor = name_end + 1

            ::attribute_loop::

            local _, attribute_end, attribute_key, quote = string_find( xml_str, "^%s*([%w_:%.%-]+)%s*=%s*([\"\'])", cursor )
            if attribute_end ~= nil then
                local value_end = string_find( xml_str, quote, attribute_end + 1, true )
                if value_end == nil then
                    std.errorf( 2, false, "XML parsing failed, attribute '%s' value is not closed at position %d", attribute_key, attribute_end )
                    return nil
                end

                if tag_attributes == nil then
                    tag_attributes = {}
                end

                tag_attributes[ attribute_key ] = decode_entities( string_sub( xml_str, attribute_end + 1, value_end - 1 ) )

                cursor = value_end + 1
                goto attribute_loop
            end

            local _, tag_end, self_closing = string_find( xml_str, "^%s*(/?)>", cursor )
            if tag_end == nil then
                std.errorf( 2, false, "XML parsing failed, malformed tag '%s' at position %d", tag_name, tag_start )
                return nil
            end

            if closing == "/" then
                if tag_attributes ~= nil or self_closing == "/" then
                    std.errorf( 2, false, "XML parsing failed, malformed end tag '%s' at position %d", tag_name, tag_start )
                    return nil
                elseif active_node == nil or active_node.name ~= tag_name then
                    std.errorf( 2, false, "XML parsing failed, unmatched tag '%s' at position %d", tag_name, tag_start )
                    return nil
                end

                tree_endtag( active_node, tag_name )
                active_node = active_node.parent
            else
                if active_node == nil and root_node ~= nil then
                    std.errorf( 2, false, "XML parsing failed, multiple root elements, '%s' at position %d", tag_name, tag_start )
                    return nil
                end

                active_node = XMLNodeClass( tag_name, tag_attributes, active_node )

                if root_node == nil then
                    root_node = active_node
                end

                -- />
                if self_closing == "/" then
                    tree_endtag( active_node, tag_name )
                    active_node = active_node.parent
                end
            end

            position = tag_end + 1
        end

        ---@diagnostic disable-next-line: missing-return
        goto analyze_loop
    end

end
