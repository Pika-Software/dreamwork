---@class dreamwork.std
local std = dreamwork.std
local class = std.class

local table_remove = std.table.remove
local string_format = std.string.format

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- A node.
---
---@class dreamwork.std.Node : dreamwork.std.Object
---@field __class dreamwork.std.NodeClass
---@field value any The value of the node.
---@field parent dreamwork.std.Node The parent node of the node.
---@field depth number The depth of the node in the tree.
---@field width number The width of the node in the tree.
local Node = class.base( "Node" )

---@return string
---@protected
function Node:__tostring()
    return string_format( "Node: %p [%s][%d]", self, self.value, self.depth )
end

---@protected
function Node:__init( value, parent )
    self.depth, self.width = 0, 0
    self.value = value

    if parent ~= nil then
        self:link( parent )
    end
end

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

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Unlinks the node from its parent.
---
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
            break
        end
    end

    parent.width = width

    self.depth = 0

    for index = 1, self.width, 1 do
        self[ index ]:link( self )
    end
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Links the node to a parent node.
---
---@param parent dreamwork.std.Node The parent node to link to.
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

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Traverses the node tree.
---
---@param callback fun( node: dreamwork.std.Node ) The callback function.
function Node:traverse( callback )
    callback( self )

    for index = 1, self.width, 1 do
        self[ index ]:traverse( callback )
    end
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- Returns the size of the node tree.
---
---@return integer size The size of the node tree.
function Node:size()
    local size = 1

    for index = 1, self.width, 1 do
        size = size + self[ index ]:size()
    end

    return size
end

--- ![(SHARED AND MENU)](https://github.com/user-attachments/assets/8f5230ff-38f7-493b-b9fc-cc70ffd5b3f4)
---
--- A node class.
---
---@class dreamwork.std.NodeClass : dreamwork.std.Node
---@field __base dreamwork.std.Node
---@overload fun( value: any, parent: dreamwork.std.Node? ): dreamwork.std.Node
local NodeClass = class.create( Node )
std.Node = NodeClass
