---@meta _

--- [SHARED AND MENU]
---
--- A HTML node object, representing an element, or the document itself with name `#document`.
---
--- Unlike `XMLNode`, children are kept as an ordered list of strings and nodes, like in the browser DOM.
---
--- Usage:
---
--- ```lua
--- local document = HTMLNode.fromString( [[<ul id="list"><li>One<li class="active">Two</ul>]] )
---
--- print( document:querySelector( "#list > li.active" ):getText() ) -- Two
--- ```
---
---@class HTMLNode : Object
---@field __class HTMLNodeClass
---@field name string The tag name of the node, lowercase for HTML elements and `#document` for documents.
---@field attributes nil | table<string, string> The attributes of the node, boolean attributes have an empty value.
---@field parent HTMLNode | nil The parent node.
---@field children nil | HTMLNode.Value[] The child nodes and text chunks in document order.
---@field doctype nil | string The DOCTYPE of a document, e.g. `html`.
local __HTMLNode = {}

---@alias HTMLNode.Value string | HTMLNode

--- [SHARED AND MENU]
---
--- A HTML node class, allowing parsing and building of HTML documents.
---
--- Usage:
---
--- ```lua
--- local document = HTMLNode.createDocument( "Hello" )
---
--- local body = document:querySelector( "body" )
--- body:add( "h1" ):append( "Hello, world!" )
--- body:add( "a", { href = "https://example.com" } ):append( "Link" )
---
--- print( document:toString( true ) )
--- ```
---
---@class HTMLNodeClass : HTMLNode, Class
---@field __base HTMLNode
---@overload fun( name: string, attributes: ( table<string, string> | nil ), parent: ( HTMLNode | nil ) ): HTMLNode
HTMLNode = {}

--- [SHARED AND MENU]
---
--- Checks whether the value type is a `HTMLNode`.
---
---@param value any
---@return boolean is_html_node
---@nodiscard
function isHTMLNode(value) end

---@param name string
---@param attributes table<string, string> | nil
---@param parent HTMLNode | nil
---@protected
function __HTMLNode:__init(name, attributes, parent) end

--- [SHARED AND MENU]
---
--- Checks whether the node is a void element, which has no end tag and no children, like `br` or `img`.
---
---@return boolean is_void
---@nodiscard
function __HTMLNode:isVoid() end

--- [SHARED AND MENU]
---
--- Checks whether the node is a document.
---
---@return boolean is_document
---@nodiscard
function __HTMLNode:isDocument() end

--- [SHARED AND MENU]
---
--- Checks whether the node has no children.
---
---@return boolean is_empty
---@nodiscard
function __HTMLNode:isEmpty() end

--- [SHARED AND MENU]
---
--- Returns the value of the attribute with the given name or `nil` if not found.
---
---@param name string The name of the attribute to get.
---@return nil | string value The value of the attribute or `nil` if not found.
---@nodiscard
function __HTMLNode:getAttribute(name) end

--- [SHARED AND MENU]
---
--- Sets the value of the attribute with the given name, `true` sets a boolean attribute, `nil` or `false` removes it.
---
---@param name string The name of the attribute to set.
---@param value any The value of the attribute.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:setAttribute(name, value) end

--- [SHARED AND MENU]
---
--- Checks whether the node has the attribute with the given name.
---
---@param name string The name of the attribute.
---@return boolean has_attribute
---@nodiscard
function __HTMLNode:hasAttribute(name) end

--- [SHARED AND MENU]
---
--- Removes the attribute with the given name.
---
---@param name string The name of the attribute to remove.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:removeAttribute(name) end

--- [SHARED AND MENU]
---
--- Checks whether the node has the given class in its `class` attribute.
---
---@param name string The class name.
---@return boolean has_class
---@nodiscard
function __HTMLNode:hasClass(name) end

--- [SHARED AND MENU]
---
--- Adds the class to the `class` attribute of the node.
---
---@param name string The class name.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:addClass(name) end

--- [SHARED AND MENU]
---
--- Removes the class from the `class` attribute of the node, the attribute is removed when no classes are left.
---
---@param name string The class name.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:removeClass(name) end

--- [SHARED AND MENU]
---
--- Returns the number of children (nodes and text chunks) of the node.
---
---@return integer count
---@nodiscard
function __HTMLNode:getChildCount() end

--- [SHARED AND MENU]
---
--- Returns the child (node or text chunk) at the given index, negative indices count from the end.
---
---@param index integer The index of the child.
---@return nil | HTMLNode.Value child
---@nodiscard
function __HTMLNode:getChild(index) end

--- [SHARED AND MENU]
---
--- Returns an iterator over the children of the node in document order, values are strings or nodes.
---
---@return fun(): ( ( integer | nil ), HTMLNode.Value ) fn The iterator function.
---@nodiscard
function __HTMLNode:iterator() end

--- [SHARED AND MENU]
---
--- Detaches the node from its parent.
---
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:detach() end

--- [SHARED AND MENU]
---
--- Inserts a node or text at the given index, nodes are detached from their old parent first.
---
---@param index integer The index to insert at, clamped to the children range, negative indices count from the end.
---@param value HTMLNode.Value | any The node or text to insert, other values are converted to strings.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:insert(index, value) end

--- [SHARED AND MENU]
---
--- Appends nodes or text to the end of the children, nodes are detached from their old parent first.
---
--- Usage:
---
--- ```lua
--- local paragraph = HTMLNode( "p" ):append( "Hello ", HTMLNode( "b" ):append( "world" ), "!" )
--- print( paragraph ) -- <p>Hello <b>world</b>!</p>
--- ```
---
---@param ... HTMLNode.Value | any The nodes or text to append, other values are converted to strings.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:append(...) end

--- [SHARED AND MENU]
---
--- Creates a new element and appends it to the children of the node.
---
---@param name string The tag name of the new element.
---@param attributes table<string, string>? The attributes of the new element.
---@return HTMLNode child The new element.
function __HTMLNode:add(name, attributes) end

--- [SHARED AND MENU]
---
--- Removes the child at the given index or the given child node.
---
---@param child integer | HTMLNode The index of the child or the child node.
---@return nil | HTMLNode.Value removed The removed child, or `nil` if not found.
function __HTMLNode:remove(child) end

--- [SHARED AND MENU]
---
--- Removes all children of the node.
---
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:clear() end

--- [SHARED AND MENU]
---
--- Returns the text content of the node and all its descendants, like `textContent` in the browser DOM.
---
---@return string text
---@nodiscard
function __HTMLNode:getText() end

--- [SHARED AND MENU]
---
--- Replaces all children of the node with the given text.
---
---@param text string | any The text, other values are converted to strings.
---@return HTMLNode self The node itself, for chaining.
function __HTMLNode:setText(text) end

--- [SHARED AND MENU]
---
--- Returns the first child element of the node, skipping text.
---
---@return HTMLNode | nil element
---@nodiscard
function __HTMLNode:getFirstElement() end

--- [SHARED AND MENU]
---
--- Returns the child elements of the node, skipping text.
---
---@return HTMLNode[] elements
---@return integer count
---@nodiscard
function __HTMLNode:getElements() end

---@alias HTMLNode.Selector HTMLNode.SelectorCompound[][]

---@class HTMLNode.SelectorCompound
---@field combinator nil | string The relation to the compound on the left: `" "`, `">"`, `"+"` or `"~"`.
---@field tag nil | string
---@field id nil | string
---@field classes nil | string[]
---@field attributes nil | { name: string, operator: string | nil, value: string, insensitive: boolean }[]
---@field pseudos nil | { name: string, a: integer, b: integer, group: HTMLNode.Selector | nil }[]

--- [SHARED AND MENU]
---
--- Returns the first descendant element with the given `id`, or `nil` if not found.
---
---@param id string The id of the element.
---@return HTMLNode | nil element
---@nodiscard
function __HTMLNode:getElementById(id) end

--- [SHARED AND MENU]
---
--- Returns all descendant elements with the given tag name, `*` matches all elements.
---
---@param name string The tag name, case-insensitive.
---@return HTMLNode[] elements
---@return integer count
---@nodiscard
function __HTMLNode:getElementsByTagName(name) end

--- [SHARED AND MENU]
---
--- Returns all descendant elements that have all of the given whitespace-separated classes.
---
---@param names string The class names, separated by whitespace.
---@return HTMLNode[] elements
---@return integer count
---@nodiscard
function __HTMLNode:getElementsByClassName(names) end

--- [SHARED AND MENU]
---
--- Returns the first descendant element matching the CSS selector, or `nil` if not found.
---
--- Supported: type, `*`, `#id`, `.class`, attributes `[a]`, `[a=v]`, `[a~=v]`, `[a|=v]`, `[a^=v]`, `[a$=v]`, `[a*=v]` with optional `i` flag,
--- combinators ` `, `>`, `+`, `~`, selector lists `,`,
--- pseudo-classes `:first-child`, `:last-child`, `:only-child`, `:nth-child()`, `:nth-last-child()`, the `-of-type` variants, `:empty`, `:root` and `:not()`.
---
---@param selector string The CSS selector.
---@return HTMLNode | nil element
---@nodiscard
function __HTMLNode:querySelector(selector) end

--- [SHARED AND MENU]
---
--- Returns all descendant elements matching the CSS selector in document order, see `:querySelector()` for the supported syntax.
---
---@param selector string The CSS selector.
---@return HTMLNode[] elements
---@return integer count
---@nodiscard
function __HTMLNode:querySelectorAll(selector) end

--- [SHARED AND MENU]
---
--- Checks whether the node matches the CSS selector, see `:querySelector()` for the supported syntax.
---
---@param selector string The CSS selector.
---@return boolean is_matching
---@nodiscard
function __HTMLNode:matches(selector) end

--- [SHARED AND MENU]
---
--- Returns the closest element matching the CSS selector, starting with the node itself and going up through its ancestors.
---
---@param selector string The CSS selector.
---@return HTMLNode | nil element
---@nodiscard
function __HTMLNode:closest(selector) end

--- [SHARED AND MENU]
---
--- Returns the HTML string representation of this node, like `outerHTML` in the browser DOM, documents include their DOCTYPE.
---
--- Pretty formatting puts block elements on separate lines and trims the text next to them, so use compact output for exact data.
---
---@param pretty boolean? Whether to use pretty formatting (indentation and newlines).
---@param level integer? The indentation level.
---@return string str The HTML string representation of this node.
---@nodiscard
function __HTMLNode:toString(pretty, level) end

--- [SHARED AND MENU]
---
--- Returns the HTML string representation of the children of this node, like `innerHTML` in the browser DOM.
---
---@return string str The HTML string representation of the children.
---@nodiscard
function __HTMLNode:getInnerHTML() end

---@return string
---@protected
function __HTMLNode:__tostring() end

---@return string
---@protected
function __HTMLNode:__represent() end

--- [SHARED AND MENU]
---
--- Parses a HTML string into a document node.
---
--- The parser is lenient like a browser: it never fails, tag and attribute names are case-insensitive, attribute values may be unquoted or missing,
--- void elements (`br`, `img`, ...) have no end tag, optional end tags (`p`, `li`, `td`, ...) are closed implicitly, stray end tags are ignored
--- and `script`/`style` content is kept as raw text. Missing `html`, `head` and `body` elements are not created.
---
--- Inside `svg` and `math` names keep their case and `/>` closes the element.
---
--- By default whitespace is collapsed like a browser renders it and indentation is removed, `pre`, `textarea`, `script` and `style` keep it as is.
---
--- Comments and processing instructions are skipped, HTML 4 named and numeric character references are decoded.
---
---@param html_str string The HTML string to parse.
---@param keep_whitespace boolean? Whether to keep all whitespace in text, defaults to `false`.
---@return HTMLNode document The document node, with the elements as children.
---@nodiscard
function HTMLNode.fromString(html_str, keep_whitespace) end

--- [SHARED AND MENU]
---
--- Creates an empty HTML5 document with `html`, `head` (with UTF-8 charset and optional title) and `body` elements.
---
---@param title string? The title of the document.
---@return HTMLNode document The document node.
---@nodiscard
function HTMLNode.createDocument(title) end
