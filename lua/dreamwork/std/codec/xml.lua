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
local string_gmatch = string.gmatch


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
---@field order nil | (string | integer)[] The document order of the children, element names and indices of `texts`, maintained automatically.
---@field texts nil | string[] The text chunks in document order, together they are the text slot `[1]`, maintained automatically.
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
---@nodiscard
local function isNode( value )
    return debug_getmetatable( value ) == XMLNode
end

std.isXMLNode = isNode

--- Checks whether the value is a list of node values.
---
---@param value any
---@return boolean is_list
local function isList( value )
    return isTable( value ) and debug_getmetatable( value ) ~= XMLNode
end

--- Returns the data table key for the given key, numeric keys fall back to number keys like in `get`, `"1"` is the text slot.
---
---@param data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>
---@param key string
---@return string | integer key
local function data_key( data, key )
    if data[ key ] ~= nil then
        return key
    end

    local number = string_toNumber( key )
    if number ~= nil and (number == 1 or data[ number ] ~= nil) then
        return number
    end

    return key
end

--- Converts values that are not strings, nodes or lists to strings.
---
---@param value any
---@return dreamwork.std.XMLNode.Value | dreamwork.std.XMLNode.Value[] | nil
local function to_value( value )
    if value == nil or isString( value ) or isTable( value ) then
        return value
    end

    return tostring( value )
end

--- Returns the data table of the node, converting empty and text-only data and starting the document order.
---
---@param node dreamwork.std.XMLNode
---@return table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])> data
local function node_data_table( node )
    local data = node.data
    if data == nil then
        data = {}
        node.data = data
        node.order = {}
    elseif isString( data ) then
        ---@cast data string
        node.texts = { data }
        node.order = { 1 }

        data = { [ 1 ] = data }
        node.data = data
    end

    ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>
    return data
end

--- Appends an element entry to the document order of the node.
---
---@param node dreamwork.std.XMLNode
---@param key string | integer
local function order_append( node, key )
    local order = node.order
    if order ~= nil and key ~= 1 then
        order[ #order + 1 ] = key
    end
end

--- Sets the number of entries of the key in the document order of the node, new entries are placed where the first old one was or at the end.
---
---@param node dreamwork.std.XMLNode
---@param key string | integer
---@param count integer
local function order_update( node, key, count )
    local order = node.order
    if order == nil or key == 1 then
        -- numbers in the order are text chunks, the text slot has no element entries
        return
    end

    local length = #order

    local existing = 0
    for i = 1, length, 1 do
        if order[ i ] == key then
            existing = existing + 1
        end
    end

    if existing == count then
        return
    end

    local first, write = nil, 0
    for i = 1, length, 1 do
        local entry = order[ i ]
        if entry == key then
            if first == nil then
                first = write + 1
            end
        else
            write = write + 1
            order[ write ] = entry
        end
    end

    if first == nil then
        first = write + 1
    end

    for i = write, first, -1 do
        order[ i + count ] = order[ i ]
    end

    for i = first, first + count - 1, 1 do
        order[ i ] = key
    end

    for i = write + count + 1, length, 1 do
        order[ i ] = nil
    end
end

--- Removes the last entry of the key from the document order of the node.
---
---@param node dreamwork.std.XMLNode
---@param key string | integer
local function order_pop( node, key )
    local order = node.order
    if order == nil or key == 1 then
        return
    end

    local length = #order

    for i = length, 1, -1 do
        if order[ i ] == key then
            for j = i, length - 1, 1 do
                order[ j ] = order[ j + 1 ]
            end

            order[ length ] = nil
            return
        end
    end
end

--- Appends text to the text slot of the node data table, keeping its position in the document order.
---
---@param node dreamwork.std.XMLNode
---@param data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>
---@param text string
local function text_append( node, data, text )
    local existing = data[ 1 ]
    if existing == nil then
        data[ 1 ] = text
    else
        data[ 1 ] = existing .. text
    end

    local order = node.order
    if order == nil then
        return
    end

    local texts = node.texts
    if texts == nil then
        texts = {}
        node.texts = texts

        if existing ~= nil then
            -- untracked text stays at the start
            texts[ 1 ] = existing

            for i = #order, 1, -1 do
                order[ i + 1 ] = order[ i ]
            end

            order[ 1 ] = 1
        end
    end

    local index = #texts + 1
    texts[ index ] = text
    order[ #order + 1 ] = index
end

--- Fills parallel key and value arrays with the children of the node in document order, text has key `false`.
---
--- Values that are not in the document order (e.g. written to `data` directly) come last, so nothing is ever lost.
---
--- The arrays can be reused, only the first `count` entries are valid. `consumed` must be empty and is left empty.
---
---@param node dreamwork.std.XMLNode
---@param keys (string | integer | false)[]
---@param values (string | dreamwork.std.XMLNode)[]
---@param consumed table<string | integer, integer>
---@return integer count
local function collect_children( node, keys, values, consumed )
    local count = 0

    local data = node.data
    if data == nil then
        return 0
    end

    if isString( data ) then
        keys[ 1 ], values[ 1 ] = false, data
        return 1
    end

    ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

    local order, texts = node.order, node.texts

    local text = data[ 1 ]
    if not isString( text ) then
        text = nil
    end

    -- text chunks keep their positions only while together they are still the text slot
    local text_pending, chunks_valid = text ~= nil, false
    if text_pending then
        local texts_length = texts == nil and 0 or #texts
        if order == nil or texts_length == 0 then
            count = 1
            keys[ 1 ], values[ 1 ] = false, text
            text_pending = false
        elseif texts_length == 1 then
            ---@cast texts string[]
            chunks_valid = texts[ 1 ] == text
        else
            ---@cast texts string[]
            chunks_valid = table_concat( texts, "", 1, texts_length ) == text
        end
    end

    if order ~= nil then
        for i = 1, #order, 1 do
            local entry = order[ i ]
            if isString( entry ) then
                local value = data[ entry ]
                if value ~= nil then
                    if isList( value ) then
                        local index = (consumed[ entry ] or 0) + 1

                        local item = value[ index ]
                        if item ~= nil then
                            consumed[ entry ] = index
                            count = count + 1
                            keys[ count ], values[ count ] = entry, item
                        end
                    elseif consumed[ entry ] == nil then
                        consumed[ entry ] = 1
                        count = count + 1
                        keys[ count ], values[ count ] = entry, value
                    end
                end
            elseif text_pending then
                if chunks_valid then
                    ---@cast texts string[]
                    local chunk = texts[ entry ]
                    if chunk ~= nil and chunk ~= "" then
                        count = count + 1
                        keys[ count ], values[ count ] = false, chunk
                    end
                else
                    -- edited text is written where the first chunk was
                    count = count + 1
                    keys[ count ], values[ count ] = false, text
                    text_pending = false
                end
            end
        end

        if chunks_valid then
            text_pending = false
        end
    end

    if text_pending then
        count = count + 1
        keys[ count ], values[ count ] = false, text
    end

    for key, value in raw_pairs( data ) do
        if key == 1 and text ~= nil then
            -- text, already collected
        elseif isList( value ) then
            ---@cast value dreamwork.std.XMLNode.Value[]
            for i = (consumed[ key ] or 0) + 1, #value, 1 do
                count = count + 1
                keys[ count ], values[ count ] = key, value[ i ]
            end
        elseif consumed[ key ] == nil then
            count = count + 1
            keys[ count ], values[ count ] = key, value
        end
    end

    if order ~= nil then
        for i = 1, count, 1 do
            local key = keys[ i ]
            if key ~= false then
                consumed[ key ] = nil
            end
        end
    end

    return count
end

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
        -- first child, the most common case while parsing
        parent.data = { [ name ] = self }
        parent.order = { name }
        return
    end

    parent_data = node_data_table( parent )

    local value = parent_data[ name ]
    if value == nil then
        parent_data[ name ] = self -- put self if no value in map
    elseif isList( value ) then
        ---@cast value dreamwork.std.XMLNode.Value[]
        value[ #value + 1 ] = self -- append self to existing array
    else
        ---@cast value string | dreamwork.std.XMLNode
        parent_data[ name ] = { value, self } -- only way is replace single value with `dreamwork.std.XMLNode.Value[]`
    end

    local order = parent.order
    if order ~= nil then
        order[ #order + 1 ] = name
    end
end

--- [SHARED AND MENU]
---
--- Checks whether the node is empty.
---
---@return boolean is_empty
---@nodiscard
function XMLNode:isEmpty()
    return self.data == nil
end

--- [SHARED AND MENU]
---
--- Returns the value of the attribute with the given name or `nil` if not found.
---
---@param name string The name of the attribute to get.
---@return nil | string value The value of the attribute or `nil` if not found.
---@nodiscard
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
--- Each key segment can be indexed with `[n]`, e.g. `child[2].title`, key `"1"` returns the text next to child nodes and an empty key `""` returns the text of a text-only node.
---
---@param key string The key to look up in the node's data, with dot-separated keys for nested values.
---@return nil | string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[] value The value of the node at the given key, or `nil` if not found.
---@nodiscard
function XMLNode:get( key )
    local position = 1
    local node = self

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
        if isList( data_value ) then
            ---@cast data_value dreamwork.std.XMLNode.Value[]
            data_value = data_value[ index ]
        elseif index ~= 1 then
            -- a single value is a list of one
            return nil
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

    local data = node_data_table( node )

    local key_start = string_find( key, ".", 1, true )
    if key_start == nil or key_start == string_len( key ) then
        if key_start ~= nil then
            key = string_sub( key, 1, key_start - 1 )
        end

        value = to_value( value )

        if isNode( value ) then
            ---@cast value dreamwork.std.XMLNode
            value.parent = node
        end

        local value_key = data_key( data, key )
        data[ value_key ] = value

        if value == nil then
            order_update( node, value_key, 0 )
        elseif isList( value ) then
            order_update( node, value_key, #value )
        else
            order_update( node, value_key, 1 )
        end

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
    order_update( node, name, 1 )

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
---@return string | integer key_name
---@return dreamwork.std.XMLNode | nil owner
local function resolve_data( node, key )
    local owner, key_name = resolve( node, key )
    if owner == nil then
        return nil, key_name, nil
    end

    local data = owner.data
    if data == nil or isString( data ) then
        return nil, key_name, nil
    end

    ---@cast data table<string, string|dreamwork.std.XMLNode|string|dreamwork.std.XMLNode[]>

    return data, data_key( data, key_name ), owner
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a value at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a value at the given key.
---@nodiscard
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
---@nodiscard
function XMLNode:containsList( key )
    local data, key_name = resolve_data( self, key )
    if data == nil then
        return false
    end

    return isList( data[ key_name ] )
end

--- [SHARED AND MENU]
---
--- Checks if the node contains a string at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a string at the given key.
---@nodiscard
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
---@nodiscard
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
---@nodiscard
function XMLNode:getLength( key )
    local data, key_name = resolve_data( self, key )
    if data == nil then
        return 0
    end

    local value = data[ key_name ]
    if isList( value ) then
        ---@cast value dreamwork.std.XMLNode.Value[]
        return #value
    end

    return 0
end

--- [SHARED AND MENU]
---
--- Pushes a value to the list at the given key, supporting dot-separated keys for nested values.
---
--- Pushing a string to the text slot `"1"` appends it to the text.
---
---@param key string The key to push the value to, with dot-separated keys for nested values.
---@param value string | dreamwork.std.XMLNode The value to push to the list.
function XMLNode:push( key, value )
    local node, key_name = resolve( self, key )
    if node == nil then
        return
    end

    local data = node_data_table( node )

    local inner_value = to_value( value )

    if isNode( inner_value ) then
        ---@cast inner_value dreamwork.std.XMLNode
        inner_value.parent = node
    end

    local value_key = data_key( data, key_name )

    local data_value = data[ value_key ]

    if value_key == 1 and isString( inner_value ) and (data_value == nil or isString( data_value )) then
        ---@cast inner_value string
        text_append( node, data, inner_value )
        return
    end

    if data_value == nil then
        data[ value_key ] = value
    elseif isList( data_value ) then
        ---@cast data_value dreamwork.std.XMLNode.Value[]
        data_value[ #data_value + 1 ] = inner_value
    else
        ---@cast data_value string | dreamwork.std.XMLNode
        data[ value_key ] = { data_value, inner_value }
    end

    order_append( node, value_key )
end

--- [SHARED AND MENU]
---
--- Pops a value from the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to pop the value from, with dot-separated keys for nested values.
---@return nil | string | dreamwork.std.XMLNode The popped value, or `nil` if the key does not exist or the value is not a node.
function XMLNode:pop( key )
    local data, key_name, owner = resolve_data( self, key )
    if data == nil then
        return nil
    end

    ---@cast owner dreamwork.std.XMLNode

    local data_value = data[ key_name ]
    if data_value == nil then
        return nil
    end

    order_pop( owner, key_name )

    if not isList( data_value ) then
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
    local data, key_name, owner = resolve_data( self, key )
    if data == nil or data[ key_name ] == nil then
        return false
    end

    ---@cast owner dreamwork.std.XMLNode

    data[ key_name ] = nil
    order_update( owner, key_name, 0 )
    return true
end

--- [SHARED AND MENU]
---
--- Returns an iterator function for the node at the given key, supporting dot-separated keys for nested values.
---
--- Values are returned in map order, use `:children()` for document order.
---
--- Text of a text-only node is returned with an empty key `""`, text next to child nodes with key `1`, list items are returned one by one with the list key.
---
---@param key? string The key to iterate over, with dot-separated keys for nested values.
---@return fun(): ( ( string | nil ), ( string | dreamwork.std.XMLNode ) ) fn The iterator function, which returns key-value pairs for the node at the given key.
---@nodiscard
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

    local entry_key, data_value

    local index = 0
    local size = 0

    return function()
        ::iterator_loop::

        if index < size then
            index = index + 1
            return entry_key, data_value[ index ]
        end

        entry_key, data_value = raw_next( data, entry_key )
        if entry_key == nil then
            ---@diagnostic disable-next-line: return-type-mismatch
            return nil, nil
        end

        if not isList( data_value ) then
            ---@cast data_value string
            index, size = 0, 0
            return entry_key, data_value
        end

        -- lists are flattened, empty ones are skipped
        index, size = 0, #data_value

        ---@diagnostic disable-next-line: missing-return
        goto iterator_loop
    end
end

--- [SHARED AND MENU]
---
--- Returns an iterator over the children of the node at the given key in document order, supporting dot-separated keys for nested values.
---
--- Text is returned with key `1` and elements with their name, values are strings or nodes.
---
--- Usage:
---
--- ```lua
--- local root = XMLNode.fromString( "<p>Hello <b>big</b> world</p>" )
---
--- for name, value in root:children() do
---     print( name, value ) -- 1 "Hello ", b "big", 1 " world"
--- end
--- ```
---
---@param key? string The key of the node to iterate over, with dot-separated keys for nested values.
---@return fun(): ( ( string | integer | nil ), ( string | dreamwork.std.XMLNode ) ) fn The iterator function.
---@nodiscard
function XMLNode:children( key )
    ---@type any
    local node = self
    if key ~= nil then
        node = self:get( key )
        if not isNode( node ) then
            return debug_fempty
        end
    end

    ---@cast node dreamwork.std.XMLNode

    local keys, values = {}, {}
    local count = collect_children( node, keys, values, {} )
    local index = 0

    return function()
        index = index + 1
        if index > count then
            ---@diagnostic disable-next-line: return-type-mismatch
            return nil, nil
        end

        local name = keys[ index ]
        if name == false then
            name = 1
        end

        return name, values[ index ]
    end
end

local escape_text, decode_entities, make_decoder
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

        -- `tonumber` also accepts `nan`, `inf`, `1e2` and `0x41`, so digits are validated first
        local code_point
        if uint8_2 == 0x78 --[[ x ]] or uint8_2 == 0x58 --[[ X ]] then
            if string_find( name, "^#[xX]%x+$" ) == nil then
                return nil
            end

            code_point = raw_tonumber( string_sub( name, 3 ), 16 )
        else
            if string_find( name, "^#%d+$" ) == nil then
                return nil
            end

            code_point = raw_tonumber( string_sub( name, 2 ), 10 )
        end

        if code_point == nil or code_point < 1 or code_point > 0x10FFFF or (code_point >= 0xD800 and code_point <= 0xDFFF) then
            return nil -- keeps the original text
        end

        return utf8_encode( code_point )
    end

    --- Returns an entity decoder that also knows the given entities, predefined entities can not be redefined.
    ---
    ---@param entities table<string, string>
    ---@return fun( name: string ): string | nil
    function make_decoder( entities )
        return function( name )
            local replacement = named_entities[ name ] or entities[ name ]
            if replacement ~= nil then
                return replacement
            end

            return decode_entity( name )
        end
    end

    --- Decodes named and numeric character references in one pass, unknown ones are kept as is.
    ---
    ---@param str string
    ---@param decoder? fun( name: string ): string | nil
    ---@return string
    function decode_entities( str, decoder )
        if string_find( str, "&", 1, true ) == nil then
            return str
        end

        return (string_gsub( str, "&(#?[%w_:%.%-\128-\255]+);", decoder or decode_entity ))
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
    ---@param buffers table[] Reused child arrays per depth, `buffers[0]` is the shared `consumed` table.
    ---@param depth integer
    ---@return integer line_count
    local function node_to_string( lines, line_count, object, name, indent, pretty, buffers, depth )
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

        line_count = line_count + 1
        lines[ line_count ] = open_tag .. ">"

        local child_indent = pretty and (indent .. "  ") or ""

        local keys, values = buffers[ depth * 2 - 1 ], buffers[ depth * 2 ]
        if keys == nil then
            keys, values = {}, {}
            buffers[ depth * 2 - 1 ], buffers[ depth * 2 ] = keys, values
        end

        -- children of this node stay in its arrays while deeper nodes use their own
        local count = collect_children( object, keys, values, buffers[ 0 ] )

        for i = 1, count, 1 do
            local key, value = keys[ i ], values[ i ]
            if key == false then
                ---@cast value string
                line_count = line_count + 1
                lines[ line_count ] = child_indent .. escape_text( value )
            elseif isNode( value ) then
                ---@cast value dreamwork.std.XMLNode
                line_count = node_to_string( lines, line_count, value, key, child_indent, pretty, buffers, depth + 1 )
            elseif isString( value ) then
                ---@cast value string
                line_count = line_count + 1
                lines[ line_count ] = child_indent .. "<" .. key .. ">" .. escape_text( value ) .. "</" .. key .. ">"
            else
                line_count = line_count + 1
                lines[ line_count ] = child_indent .. "<" .. key .. ">" .. escape_text( tostring( value ) ) .. "</" .. key .. ">"
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
    --- Children are written in document order, pretty formatting adds whitespace to the text, so use compact output for exact data.
    ---
    ---@param pretty? boolean Whether to use pretty formatting (indentation and newlines).
    ---@param name? string The name of the node.
    ---@param level? number The indentation level.
    ---@return string str The XML string representation of this node.
    ---@nodiscard
    function XMLNode:toString( pretty, name, level )
        pretty = pretty == true

        local indent = ""
        if pretty and level ~= nil and level > 0 then
            indent = string_byteRep( 0x20, level * 2 )
        end

        local lines = {}

        local line_count = node_to_string( lines, 0, self, name or self.name, indent, pretty, { [ 0 ] = {} }, 1 )
        if line_count == 1 then
            return lines[ 1 ]
        end

        return table_concat( lines, pretty and "\n" or "", 1, line_count )
    end

    --- [SHARED AND MENU]
    ---
    --- Converts XML node structure to a Lua table.
    ---
    --- Text content is stored in slot `[1]`, attributes and document order are not included.
    ---
    ---@return table
    ---@nodiscard
    function XMLNode:toTable()
        local data = self.data
        if data == nil then
            return {}
        end

        if isString( data ) then
            ---@cast data string
            return { [ 1 ] = data }
        end

        ---@cast data table<string, (string | dreamwork.std.XMLNode | dreamwork.std.XMLNode.Value[])>

        local result = {}

        for key, value in raw_pairs( data ) do
            if isNode( value ) then
                ---@cast value dreamwork.std.XMLNode
                result[ key ] = value:toTable()
            elseif not isList( value ) then
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

    --- Converts `\r\n` and `\r` line breaks to `\n`, as XML requires.
    ---
    ---@param str string
    ---@return string
    local function normalize_newlines( str )
        if string_find( str, "\r", 1, true ) == nil then
            return str
        end

        return (string_gsub( str, "\r\n?", "\n" ))
    end

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

        if not isList( parent_value ) then
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

    --- Appends text to the node, text next to child nodes is stored in slot `[1]`.
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
            text_append( node, data, text )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Converts a table to an XML node structure.
    ---
    ---@param tbl table The table to convert to an XML node.
    ---@param name? string The name of the root node.
    ---@return dreamwork.std.XMLNode root_node The root node of the XML tree.
    ---@nodiscard
    function XMLNodeClass.fromTable( tbl, name )
        local node = XMLNodeClass( name or "root", nil, nil )

        -- text slot from `toTable` has no position, so it goes first like in the serializer
        local text = tbl[ 1 ]
        if isString( text ) then
            ---@cast text string
            tree_text( node, text )
        end

        for key, value in pairs( tbl ) do
            if key == 1 and text ~= nil and value == text then
                goto skip_entry
            end

            if not isString( key ) then
                key = tostring( key )
            end

            if key == "1" and isString( value ) then
                ---@cast value string
                tree_text( node, value )
            elseif isNode( value ) then
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

            ::skip_entry::
        end

        return node
    end

    -- parse helpers take all state as arguments: closures over parser locals make the
    -- backward `goto` of the parse loop close upvalues, which LuaJIT can not compile (NYI: UCLO)

    ---@param xml_str string
    ---@param from integer
    ---@param to integer
    ---@return boolean
    local function has_newline( xml_str, from, to )
        local newline = string_find( xml_str, "\n", from, true )
        if newline ~= nil and newline <= to then
            return true
        end

        local carriage = string_find( xml_str, "\r", from, true )
        return carriage ~= nil and carriage <= to
    end

    ---@param xml_str string
    ---@param from integer
    ---@param to integer
    ---@param is_cdata boolean
    ---@param decoder nil | fun( name: string ): string | nil
    ---@return string
    local function segment_text( xml_str, from, to, is_cdata, decoder )
        local text = normalize_newlines( string_sub( xml_str, from, to ) )
        if is_cdata then
            return text
        end

        return decode_entities( text, decoder )
    end

    --- Adds the collected text segments to the node.
    ---
    ---@param xml_str string
    ---@param node dreamwork.std.XMLNode
    ---@param preserve boolean Whether the text is kept as is.
    ---@param decoder nil | fun( name: string ): string | nil
    ---@param closing boolean Whether the next tag is the end tag of the node.
    ---@param segment_start integer[]
    ---@param segment_end integer[]
    ---@param segment_first (integer | boolean)[] Position of the first non-space character, `false` for whitespace-only text and `true` for CDATA.
    ---@param count integer
    local function flush_text( xml_str, node, preserve, decoder, closing, segment_start, segment_end, segment_first, count )
        local first_start, last_end = segment_start[ 1 ], segment_end[ count ]

        if not preserve then
            local has_content = false
            for i = 1, count, 1 do
                if segment_first[ i ] ~= false then
                    has_content = true
                    break
                end
            end

            if not has_content then
                return
            end

            -- the start of the element text is trimmed fully, later text only loses indentation
            local first = segment_first[ 1 ]
            if first ~= true then
                local text_start = first or (segment_end[ 1 ] + 1)
                ---@cast text_start integer

                if text_start > first_start and (node.data == nil or has_newline( xml_str, first_start, text_start - 1 )) then
                    first_start = text_start
                end
            end

            -- the end of the element text is trimmed fully, text before a child only loses indentation
            if segment_first[ count ] ~= true then
                local lower = count == 1 and first_start or segment_start[ count ]

                local text_end = last_end
                while text_end >= lower and is_space[ string_byte( xml_str, text_end ) ] do
                    text_end = text_end - 1
                end

                if text_end < last_end and (closing or has_newline( xml_str, text_end + 1, last_end )) then
                    last_end = text_end
                end
            end
        end

        local text
        if count == 1 then
            if last_end < first_start then
                return
            end

            text = segment_text( xml_str, first_start, last_end, segment_first[ 1 ] == true, decoder )
        else
            local pieces, piece_count = {}, 0

            for i = 1, count, 1 do
                local from = i == 1 and first_start or segment_start[ i ]
                local to = i == count and last_end or segment_end[ i ]

                if to >= from then
                    piece_count = piece_count + 1
                    pieces[ piece_count ] = segment_text( xml_str, from, to, segment_first[ i ] == true, decoder )
                end
            end

            text = table_concat( pieces, "", 1, piece_count )
        end

        if text ~= "" then
            tree_text( node, text )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Converts an XML string to an XML node structure.
    ---
    --- By default the text of text-only elements is trimmed, in mixed content only indentation (whitespace with line breaks) is removed and whitespace-only text is skipped.
    ---
    --- With `keep_whitespace` or `xml:space="preserve"` all text is kept exactly as written.
    ---
    --- Line breaks are normalized to `\n`, attribute values are normalized as XML requires, character references and entities declared in the internal DOCTYPE subset are decoded.
    ---
    ---@param xml_str string The XML string to parse.
    ---@param keep_whitespace? boolean Whether to keep all whitespace in text, defaults to `false`.
    ---@return dreamwork.std.XMLNode | nil root_node The root node, or `nil` if the string has no elements.
    ---@nodiscard
    function XMLNodeClass.fromString( xml_str, keep_whitespace )
        keep_whitespace = keep_whitespace == true

        local xml_length = string_len( xml_str )

        ---@type dreamwork.std.XMLNode | nil
        local active_node

        ---@type dreamwork.std.XMLNode | nil
        local root_node

        -- whether the text of the active node is kept as is
        local preserve = keep_whitespace

        ---@type table<dreamwork.std.XMLNode, boolean>
        local preserving = {}

        ---@type nil | fun( name: string ): string | nil
        local decoder

        -- text segments of the active node, flushed when the next element tag starts
        ---@type integer[]
        local segment_start = {}

        ---@type integer[]
        local segment_end = {}

        -- position of the first non-space character, `false` for whitespace-only text and `true` for CDATA
        ---@type (integer | boolean)[]
        local segment_first = {}

        ---@type integer
        local segment_count = 0

        ---@type integer
        local position = 1

        -- UTF-8 BOM
        local bom_1, bom_2, bom_3 = string_byte( xml_str, 1, 3 )
        if bom_1 == 0xEF and bom_2 == 0xBB and bom_3 == 0xBF then
            position = 4
        end

        ::analyze_loop::

        local tag_start = string_find( xml_str, "<", position, true )

        local text_end = (tag_start or (xml_length + 1)) - 1
        if text_end >= position then
            local text_first = string_find( xml_str, "%S", position )
            if text_first ~= nil and text_first > text_end then
                text_first = nil
            end

            if active_node == nil then
                if text_first ~= nil then
                    std.errorf( 2, false, "XML parsing failed, text outside of the root element at position %d", text_first )
                    return nil
                end
            else
                segment_count = segment_count + 1
                segment_start[ segment_count ] = position
                segment_end[ segment_count ] = text_end
                segment_first[ segment_count ] = text_first or false
            end
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

                if cdata_start > tag_start + 9 then
                    segment_count = segment_count + 1
                    segment_start[ segment_count ] = tag_start + 9
                    segment_end[ segment_count ] = cdata_start - 1
                    segment_first[ segment_count ] = true
                end

                position = cdata_end + 1
                goto analyze_loop
            end

            -- DOCTYPE
            if b2 == 0x44 --[[ D ]] and b3 == 0x4F --[[ O ]] and b4 == 0x43 --[[ C ]] and b5 == 0x54 --[[ T ]] and
                b6 == 0x59 --[[ Y ]] and b7 == 0x50 --[[ P ]] and b8 == 0x45 --[[ E ]] then

                local _, doctype_end, subset = string_find( xml_str, "^<!DOCTYPE[^%[>]*(%b[])%s*>", tag_start )
                if doctype_end == nil then
                    _, doctype_end = string_find( xml_str, ">", tag_start, true )
                end

                if doctype_end == nil then
                    std.errorf( 2, false, "XML parsing failed, DOCTYPE is not closed at position %d", tag_start )
                    return nil
                end

                if subset ~= nil then
                    -- internal entities, the first declaration wins, replacement text is plain text
                    ---@type table<string, string>
                    local entities = {}
                    decoder = make_decoder( entities )

                    for entity_name, _, entity_value in string_gmatch( subset, "<!ENTITY%s+([%w_:%.%-\128-\255]+)%s+([\"\'])(.-)%2%s*>" ) do
                        if entities[ entity_name ] == nil then
                            entities[ entity_name ] = decode_entities( normalize_newlines( entity_value ), decoder )
                        end
                    end
                end

                position = doctype_end + 1
                goto analyze_loop
            end

            std.errorf( 2, false, "XML parsing failed, unknown markup declaration at position %d", tag_start )
            return nil
        end

        do

            local _, name_end, closing, tag_name = string_find( xml_str, "^(/?)([%w_:%.%-\128-\255]+)", tag_start + 1 )
            if name_end == nil then
                std.errorf( 2, false, "XML parsing failed, invalid tag name at position %d", tag_start )
                return nil
            end

            if segment_count ~= 0 then
                -- a single whitespace-only segment is indentation, nothing to add
                if segment_count ~= 1 or segment_first[ 1 ] ~= false or preserve then
                    ---@cast active_node dreamwork.std.XMLNode
                    flush_text( xml_str, active_node, preserve, decoder, closing == "/", segment_start, segment_end, segment_first, segment_count )
                end

                segment_count = 0
            end

            ---@type table<string, string> | nil
            local tag_attributes

            local cursor = name_end + 1

            ::attribute_loop::

            local _, attribute_end, attribute_key, quote = string_find( xml_str, "^%s*([%w_:%.%-\128-\255]+)%s*=%s*([\"\'])", cursor )
            if attribute_end ~= nil then
                local value_end = string_find( xml_str, quote, attribute_end + 1, true )
                if value_end == nil then
                    std.errorf( 2, false, "XML parsing failed, attribute '%s' value is not closed at position %d", attribute_key, attribute_end )
                    return nil
                end

                if tag_attributes == nil then
                    tag_attributes = {}
                elseif tag_attributes[ attribute_key ] ~= nil then
                    std.errorf( 2, false, "XML parsing failed, duplicate attribute '%s' at position %d", attribute_key, attribute_end )
                    return nil
                end

                local attribute_value = string_sub( xml_str, attribute_end + 1, value_end - 1 )

                -- line breaks and tabs become spaces, character references are decoded afterwards so they stay
                if string_find( attribute_value, "\n", 1, true ) ~= nil or string_find( attribute_value, "\r", 1, true ) ~= nil or string_find( attribute_value, "\t", 1, true ) ~= nil then
                    attribute_value = string_gsub( normalize_newlines( attribute_value ), "[\t\n]", " " )
                end

                tag_attributes[ attribute_key ] = decode_entities( attribute_value, decoder )

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
                preserve = keep_whitespace or (active_node ~= nil and preserving[ active_node ] == true)
            else
                if active_node == nil and root_node ~= nil then
                    std.errorf( 2, false, "XML parsing failed, multiple root elements, '%s' at position %d", tag_name, tag_start )
                    return nil
                end

                active_node = XMLNodeClass( tag_name, tag_attributes, active_node )

                if root_node == nil then
                    root_node = active_node
                end

                if not keep_whitespace and tag_attributes ~= nil then
                    local space = tag_attributes[ "xml:space" ]
                    if space == "preserve" then
                        preserve = true
                    elseif space == "default" then
                        preserve = false
                    end
                end

                if preserve then
                    preserving[ active_node ] = true
                end

                -- />
                if self_closing == "/" then
                    tree_endtag( active_node, tag_name )
                    active_node = active_node.parent
                    preserve = keep_whitespace or (active_node ~= nil and preserving[ active_node ] == true)
                end
            end

            position = tag_end + 1
        end

        ---@diagnostic disable-next-line: missing-return
        goto analyze_loop
    end

end
