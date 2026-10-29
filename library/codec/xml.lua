---@meta _

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
---@class XMLNode : Object
---@field __class XMLNodeClass
---@field name string The name of the node.
---@field attributes nil | table<string, (string | nil)> The attributes of the node.
---@field parent XMLNode | nil The parent node.
---@field data nil | string | table<string, (string | XMLNode | XMLNode.Value[])> The data of the node.
---@field order nil | (string | integer)[] The document order of the children, element names and indices of `texts`, maintained automatically.
---@field texts nil | string[] The text chunks in document order, together they are the text slot `[1]`, maintained automatically.
local __XMLNode = {}

---@alias XMLNode.Value string | XMLNode

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
---@class XMLNodeClass : XMLNode
---@field __base XMLNode
---@overload fun(name: string, attributes: (table<string, string> | nil), parent: (XMLNode | nil) ): XMLNode
XMLNode = {}

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `XMLNode`.
---
---@param value any
---@return boolean is_xml_node
---@nodiscard
function isXMLNode(value) end

---@param name string
---@param attributes table<string, string> | nil
---@param parent XMLNode | nil
---@protected
function __XMLNode:__init(name, attributes, parent) end

--- [SHARED AND MENU]
---
--- Checks whether the node is empty.
---
---@return boolean is_empty
---@nodiscard
function __XMLNode:isEmpty() end

--- [SHARED AND MENU]
---
--- Returns the value of the attribute with the given name or `nil` if not found.
---
---@param name string The name of the attribute to get.
---@return nil | string value The value of the attribute or `nil` if not found.
---@nodiscard
function __XMLNode:getAttribute(name) end

--- [SHARED AND MENU]
---
--- Sets the value of the attribute with the given name.
---
---@param name string The name of the attribute to set.
---@param value string | nil The value to set for the attribute, or `nil` to remove the attribute.
function __XMLNode:setAttribute(name, value) end

--- [SHARED AND MENU]
---
--- Returns the value of the node at the given key or `nil` if not found.
---
--- Each key segment can be indexed with `[n]`, e.g. `child[2].title`, key `"1"` returns the text next to child nodes and an empty key `""` returns the text of a text-only node.
---
---@param key string The key to look up in the node's data, with dot-separated keys for nested values.
---@return nil | string | XMLNode | XMLNode.Value[] value The value of the node at the given key, or `nil` if not found.
---@nodiscard
function __XMLNode:get(key) end

--- [SHARED AND MENU]
---
--- Sets the value of the node at the given key, supporting dot-separated keys for nested values.
---
--- Missing or non-node intermediate values are replaced with new empty nodes.
---
---@param key string The key to set, with dot-separated keys for nested values.
---@param value XMLNode.Value | XMLNode.Value[] | nil The value to set, which can be a string or a node, or `nil` to remove the value.
function __XMLNode:set(key, value) end

--- [SHARED AND MENU]
---
--- Checks if the node contains a value at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a value at the given key.
---@nodiscard
function __XMLNode:contains(key) end

--- [SHARED AND MENU]
---
--- Checks if the node contains a list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a list at the given key.
---@nodiscard
function __XMLNode:containsList(key) end

--- [SHARED AND MENU]
---
--- Checks if the node contains a string at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a string at the given key.
---@nodiscard
function __XMLNode:containsString(key) end

--- [SHARED AND MENU]
---
--- Checks if the node contains a node at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to check, with dot-separated keys for nested values.
---@return boolean is_contains Whether the node contains a node at the given key.
---@nodiscard
function __XMLNode:containsNode(key) end

--- [SHARED AND MENU]
---
--- Returns the length of the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to get the length of, with dot-separated keys for nested values.
---@return integer length The length of the list at the given key.
---@nodiscard
function __XMLNode:getLength(key) end

--- [SHARED AND MENU]
---
--- Pushes a value to the list at the given key, supporting dot-separated keys for nested values.
---
--- Pushing a string to the text slot `"1"` appends it to the text.
---
---@param key string The key to push the value to, with dot-separated keys for nested values.
---@param value string | XMLNode The value to push to the list.
function __XMLNode:push(key, value) end

--- [SHARED AND MENU]
---
--- Pops a value from the list at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to pop the value from, with dot-separated keys for nested values.
---@return nil | string | XMLNode The popped value, or `nil` if the key does not exist or the value is not a node.
function __XMLNode:pop(key) end

--- [SHARED AND MENU]
---
--- Removes the value at the given key, supporting dot-separated keys for nested values.
---
---@param key string The key to remove, with dot-separated keys for nested values.
---@return boolean success Returns `true` if the value was removed, `false` otherwise (e.g. key not found).
function __XMLNode:remove(key) end

--- [SHARED AND MENU]
---
--- Returns an iterator function for the node at the given key, supporting dot-separated keys for nested values.
---
--- Values are returned in map order, use `:children()` for document order.
---
--- Text of a text-only node is returned with an empty key `""`, text next to child nodes with key `1`, list items are returned one by one with the list key.
---
---@param key? string The key to iterate over, with dot-separated keys for nested values.
---@return fun(): ( ( string | nil ), ( string | XMLNode ) ) fn The iterator function, which returns key-value pairs for the node at the given key.
---@nodiscard
function __XMLNode:iterator(key) end

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
---@return fun(): ( ( string | integer | nil ), ( string | XMLNode ) ) fn The iterator function.
---@nodiscard
function __XMLNode:children(key) end

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
function __XMLNode:toString(pretty, name, level) end

--- [SHARED AND MENU]
---
--- Converts XML node structure to a Lua table.
---
--- Text content is stored in slot `[1]`, attributes and document order are not included.
---
---@return table
---@nodiscard
function __XMLNode:toTable() end

---@return string
---@protected
function __XMLNode:__tostring() end

---@return string
---@protected
function __XMLNode:__represent() end

--- [SHARED AND MENU]
---
--- Converts a table to an XML node structure.
---
---@param tbl table The table to convert to an XML node.
---@param name? string The name of the root node.
---@return XMLNode root_node The root node of the XML tree.
---@nodiscard
function XMLNode.fromTable(tbl, name) end

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
---@return XMLNode | nil root_node The root node, or `nil` if the string has no elements.
---@nodiscard
function XMLNode.fromString(xml_str, keep_whitespace) end
