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
---@param self dreamwork.std.Node<T>
---@param writer dreamwork.std.BinaryWriter The writer.
---@param ... any The arguments passed to `__serialize` of every value.
---@protected
function Node:__serialize( writer, ... )
    local value = self.value

    -- presence bit, `nil` has no `__serialize`
    if value == nil then
        writer:writeBit( 0 )
    else
        writer:writeBit( 1 )
        writer:writeObject( value, ... )
    end

    local width = self.width
    writer:writeUInt( width, 32 )

    for index = 1, width, 1 do
        writer:writeObject( self[ index ], ... )
    end
end

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
---@param self dreamwork.std.Node<T>
---@param reader dreamwork.std.BinaryReader The reader.
---@param value_class? dreamwork.std.Class The class of the values, can be omitted if every value is `nil`.
---@param ... any The arguments passed to `__deserialize` of every value.
---@protected
function Node:__deserialize( reader, value_class, ... )
    if reader:readBit() == 0 then
        self.value = nil
    elseif value_class == nil then
        error( "node has a value, but `value_class` is missing" )
    else
        self.value = reader:readClass( value_class, ... )
    end

    -- `readClass` creates the root without `__init`
    local depth = self.depth
    if depth == nil then
        depth = 0
        self.depth = 0
    end

    local old_width = self.width or 0
    local width = reader:readUInt( 32 )

    -- children get the class of this node, so subclasses stay subclasses
    local base = debug_getmetatable( self )
    ---@cast base dreamwork.std.Node

    -- every child takes at least 33 bits, so a broken width runs out of data instead of memory
    for index = 1, width, 1 do
        ---@type dreamwork.std.Node | nil
        local child = self[ index ]
        if child == nil then
            child = class_new( base )
            self[ index ] = child
        end

        -- `readObject`, not `readClass`: existing children are reused,
        -- and `depth` must be set before the child reads its own children
        child.parent, child.depth = self, depth + 1
        reader:readObject( child, value_class, ... )
    end

    for index = width + 1, old_width, 1 do
        self[ index ] = nil
    end

    self.width = width
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
---@generic T
---@class dreamwork.std.NodeClass : dreamwork.std.Node
---@field __base dreamwork.std.Node
---@overload fun( value: T, parent: ( dreamwork.std.Node<T> | nil ) ): dreamwork.std.Node<T>
std.Node = class.create( Node )
