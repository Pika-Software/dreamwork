---@meta _

--- [SHARED AND MENU]
---
--- A node in a generic tree structure.
---
--- Each node holds an arbitrary `value`,
--- an optional `parent` link, and a list
--- of child nodes (stored in the node's array part, sized by `width`).
---
--- Nodes track their own `depth` (distance from the root)
--- and expose helpers to link/unlink from a parent,
--- traverse the subtree, and measure its size.
---
---@class Node<T> : Object
---@field __class NodeClass
---@field value T The value stored in the node.
---@field parent? Node<T> The parent node, or `nil` if this node is a root (not currently linked to anything).
---@field depth number How many links deep this node is from its root (root has depth `0`).
---@field width number The number of direct children this node has.
local __Node = {}

---@return string
---@protected
function __Node:__represent() end

---@return boolean
---@protected
function __Node:__toboolean() end

---@return integer
---@protected
function __Node:__len() end

---@generic T
---@param self Node<T>
---@param value T
---@param parent Node<T> | nil
---@protected
function __Node:__init(value, parent) end

--- Writes the node and its whole subtree, depth-first,
--- every node is a presence bit, its value (`writer:writeObject`), the number of children (`UInt32`) and the children.
---
--- Values must be objects with `__serialize`, or `nil`.
---
--- ```
--- writer:writeObject( root ) -- calls `value:__serialize( writer )` for every value
--- ```
---
---@generic T
---@param self Node<T>
---@param writer BinaryWriter The writer.
---@param ... any The arguments passed to `__serialize` of every value.
---@protected
function __Node:__serialize(writer, ...) end

--- Reads the subtree written by `__serialize` into the node, replacing its values and children.
---
--- Values are read with `reader:readClass( value_class, ... )`,
--- existing children are reused, new ones are created with the class of this node,
--- `parent` and `depth` are restored from the tree.
---
--- ```
--- local root = reader:readClass( Node, Vector3 )
--- ```
---
---@generic T
---@param self Node<T>
---@param reader BinaryReader The reader.
---@param value_class? Class The class of the values, can be omitted if every value is `nil`.
---@param ... any The arguments passed to `__deserialize` of every value.
---@protected
function __Node:__deserialize(reader, value_class, ...) end

--- [SHARED AND MENU]
---
--- Unlinks this node from its parent, removing it from the parent's child
--- list and resetting this node's depth to `0`.
---
--- Any children of this node are then re-linked to it so their depths stay
--- consistent with the change.
---
---@generic T
---@param self Node<T>
function __Node:unlink() end

--- [SHARED AND MENU]
---
--- Links this node to a parent node, appending it to the parent's child
--- list and updating this node's depth to `parent.depth + 1`.
---
--- Throws if `parent` is (or is a descendant of) this node, since that
--- would create a cycle. Existing children of this node are re-linked
--- afterward so their depths stay consistent with the change.
---
---@generic T
---@param self Node<T>
---@param parent Node<T> The parent node to link to.
function __Node:link(parent) end

--- [SHARED AND MENU]
---
--- Walks this node and every descendant in depth-first, parent-before-child
--- order, calling `callback` once for each node visited.
---
---@generic T
---@param self Node<T>
---@param callback fun( node: Node<T> ) The callback invoked for each node in the subtree.
function __Node:traverse(callback) end

--- [SHARED AND MENU]
---
--- Returns the size of the node tree.
---
---@generic T
---@param self Node<T>
---@return integer size The size of the node tree.
---@nodiscard
function __Node:size() end

--- [SHARED AND MENU]
---
--- The class used to create new `Node` instances.
---
---@generic T
---@class NodeClass : Node
---@field __base Node
---@overload fun( value: T, parent: ( Node<T> | nil ) ): Node<T>
Node = {}
