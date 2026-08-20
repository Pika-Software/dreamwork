---@class dreamwork.std
local std = dreamwork.std

local table = std.table
local table_remove = table.remove

local string = std.string
local class = std.class

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
    return string.format( "Node: %p [%s][%d]", self, self.value, self.depth )
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

---@generic T
---@param self dreamwork.std.Node<T>
---@param writer dreamwork.std.buffer.Writer
---@protected
function Node:__serialize( writer )
    writer:writeInt32( self.depth )

    local width = self.width
    writer:writeInt32( width )

    for index = 1, width, 1 do
        writer:serialize( self[ index ] )
    end
end

---@generic T
---@param self dreamwork.std.Node<T>
---@param reader dreamwork.std.buffer.Reader
---@param fallback dreamwork.std.Object | nil
---@protected
function Node:__deserialize( reader, fallback )
    self.depth = reader:readInt32() or 0

    local width = reader:readInt32() or 0
    self.width = width

    for index = 1, width, 1 do
        self[ index ] = reader:deserialize( self[ index ] or fallback or Node, fallback )
    end
end

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
---@generic T
---@class dreamwork.std.NodeClass : dreamwork.std.Node
---@field __base dreamwork.std.Node
---@overload fun( value: T, parent: ( dreamwork.std.Node<T> | nil ) ): dreamwork.std.Node<T>
std.Node = class.create( Node )
