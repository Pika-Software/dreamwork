---@class dreamwork.std
local std = dreamwork.std

local table = std.table
local table_remove = table.remove

local string = std.string
local string_format = string.format

local debug_getmetatable = std.debug.getmetatable

local class = std.class
local class_new = class.new

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
--- ```lua
--- local root = std.Node( "root" )
--- local child = std.Node( "leaf", root )
---
--- print( child.parent == root ) -- true
--- print( root:size() ) -- 2
--- ```
---
---@class dreamwork.std.Node<T> : dreamwork.std.Object
---@field __class dreamwork.std.NodeClass
---@field value T The value stored in the node.
---@field parent? dreamwork.std.Node<T> The parent node, or `nil` if this node is a root (not currently linked to anything).
---@field depth number How many links deep this node is from its root (root has depth `0`).
---@field width number The number of direct children this node has.
local Node = class.base( "Node", false, nil )

---@return string
---@protected
function Node:__represent()
    return string_format( "Node: %p [%s][%d]", self, self.value, self.depth )
end

---@return boolean
---@protected
function Node:__toboolean()
    return self.width > 0
end

---@return integer
---@protected
function Node:__len()
    return self.width
end

---@generic T
---@param node dreamwork.std.Node<T>
---@param index integer | nil
---@return integer | nil
---@return dreamwork.std.Node<T> | nil
local function node_next( node, index )
    index = (index or 0) + 1

    if index > node.width then
        return nil
    end

    return index, node[ index ]
end

---@return fun( node: dreamwork.std.Node, index: integer | nil ): integer | nil, dreamwork.std.Node | nil
---@protected
function Node:__pairs()
    return node_next
end

---@generic T
---@param self dreamwork.std.Node<T>
---@param value T
---@param parent dreamwork.std.Node<T> | nil
---@protected
function Node:__init( value, parent )
    self.depth, self.width = 0, 0
    self.value = value

    if parent ~= nil then
        self:link( parent )
    end
end

--- Returns the node for `protobuf.tree`, `{ value = any, children = { ... } }`,
--- the children are converted the same way when they are written.
---
--- ```
--- writer:writeProto( root, protobuf.tree( Vector3 ) )
--- ```
---
---@generic T
---@param self dreamwork.std.Node<T>
---@return { value: T, children: dreamwork.std.Node<T>[] } message The node.
---@protected
function Node:__toProto()
    local width = self.width

    ---@type dreamwork.std.Node[]
    local children = {}

    for index = 1, width, 1 do
        children[ index ] = self[ index ]
    end

    return { value = self.value, children = children }
end

local Node_fromProto

--- Reads the subtree decoded by `protobuf.tree` into the node, replacing its values and children.
---
--- Existing children are reused, new ones are created with the class of this node,
--- `parent` and `depth` are restored from the tree.
---
--- ```
--- local root = reader:readProto( Node, protobuf.tree( Vector3 ) )
--- ```
---
---@generic T
---@param self dreamwork.std.Node<T>
---@param message { value: T, children: table[] } The decoded node.
---@protected
function Node:__fromProto( message )
    self.value = message.value

    -- `readProto` creates the root without `__init`
    local depth = self.depth
    if depth == nil then
        depth = 0
        self.depth = 0
    end

    local old_width = self.width or 0

    local children = message.children
    local width = #children

    -- children get the class of this node, so subclasses stay subclasses
    local base = debug_getmetatable( self )
    ---@cast base dreamwork.std.Node

    for index = 1, width, 1 do
        ---@type dreamwork.std.Node | nil
        local child = self[ index ]
        if child == nil then
            child = class_new( base )
            self[ index ] = child
        end

        -- `depth` must be set before the child reads its own children
        child.parent, child.depth = self, depth + 1
        Node_fromProto( child, children[ index ] )
    end

    for index = width + 1, old_width, 1 do
        self[ index ] = nil
    end

    self.width = width
end

Node_fromProto = Node.__fromProto

--- [SHARED AND MENU]
---
--- Unlinks this node from its parent, removing it from the parent's child
--- list and resetting this node's depth to `0`.
---
--- Any children of this node are then re-linked to it so their depths stay
--- consistent with the change.
---
---@generic T
---@param self dreamwork.std.Node<T>
function Node:unlink()
    local parent = self.parent
    if parent == nil then
        return
    end

    self.parent = nil

    local width = parent.width

    for index = width, 1, -1 do
        if parent[ index ] == self then
            table_remove( parent, index )
            width = width - 1
            parent.width = width
            break
        end
    end

    self.depth = 0

    for index = 1, width, 1 do
        self[ index ]:link( self )
    end
end

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
---@param self dreamwork.std.Node<T>
---@param parent dreamwork.std.Node<T> The parent node to link to.
function Node:link( parent )
    local width = parent.width
    for index = 1, width, 1 do
        if parent[ index ] == self then
            self.depth = parent.depth + 1
            return
        end
    end

    local sub_parent = parent
    while sub_parent ~= nil do
        if sub_parent == self then
            error( "child node cannot be parent", 2 )
        end

        sub_parent = sub_parent.parent
    end

    self.depth = parent.depth + 1
    self.parent = parent

    width = width + 1
    parent[ width ] = self
    parent.width = width

    for index = 1, self.width, 1 do
        self[ index ]:link( self )
    end
end

--- [SHARED AND MENU]
---
--- Walks this node and every descendant in depth-first, parent-before-child
--- order, calling `callback` once for each node visited.
---
---@generic T
---@param self dreamwork.std.Node<T>
---@param callback fun( node: dreamwork.std.Node<T> ) The callback invoked for each node in the subtree.
function Node:traverse( callback )
    callback( self )

    for index = 1, self.width, 1 do
        self[ index ]:traverse( callback )
    end
end

--- [SHARED AND MENU]
---
--- Returns the size of the node tree.
---
---@generic T
---@param self dreamwork.std.Node<T>
---@return integer size The size of the node tree.
---@nodiscard
function Node:size()
    local size = 1

    for index = 1, self.width, 1 do
        size = size + self[ index ]:size()
    end

    return size
end

--- [SHARED AND MENU]
---
--- The class used to create new `Node` instances.
---
--- ```lua
--- local root = std.Node( "root" )
--- local child = std.Node( "leaf", root )
--- ```
---
---@generic T
---@class dreamwork.std.NodeClass : dreamwork.std.Node, dreamwork.std.Class
---@field __base dreamwork.std.Node
---@overload fun( value: T, parent: ( dreamwork.std.Node<T> | nil ) ): dreamwork.std.Node<T>
std.Node = class.create( Node )
