---@class dreamwork.std
local std = _G.dreamwork.std

local class = std.class
local table_remove = std.table.remove
local string_format = std.string.format

do

    --- [SHARED AND MENU]
    ---
    --- A stack is a last-in-first-out (LIFO) data structure object.
    ---
    ---@class dreamwork.std.Stack : dreamwork.std.Object
    ---@field __class dreamwork.std.StackClass
    ---@field size integer The size of the stack. **Read-only**
    local Stack = class.base( "Stack" )

    ---@protected
    function Stack:__init()
        self.size = 0
    end

    ---@param writer dreamwork.std.pack.Writer
    ---@protected
    function Stack:__serialize( writer )
        local size = self.size
        writer:writeInt32( size )

        for i = 1, size, 1 do
            writer:serialize( self[ i ] )
        end
    end

    ---@param reader dreamwork.std.pack.Reader
    ---@param fallback dreamwork.std.Object | nil
    ---@protected
    function Stack:__deserialize( reader, fallback )
        local size = reader:readInt32() or 0
        self.size = size

        for i = 1, size, 1 do
            self[ i ] = reader:deserialize( self[ i ] or fallback or Stack, fallback )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the stack is empty.
    ---
    ---@return boolean
    function Stack:isEmpty()
        return self.size == 0
    end

    --- [SHARED AND MENU]
    ---
    --- Pushes a value onto the stack.
    ---
    ---@param value any The value to push onto the stack.
    ---@return integer position The position of the value in the stack.
    function Stack:push( value )
        local position = self.size + 1
        self.size, self[ position ] = position, value
        return position
    end

    --- [SHARED AND MENU]
    ---
    --- Pops the value from the top of the stack.
    ---
    ---@return any value The value that was removed from the stack.
    function Stack:pop()
        local position = self.size
        if position == 0 then
            return nil
        end

        self.size = position - 1

        local value = self[ position ]
        self[ position ] = nil
        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the value at the top of the stack.
    ---
    ---@return any value The value at the top of the stack.
    function Stack:peek()
        return self[ self.size ]
    end

    --- [SHARED AND MENU]
    ---
    --- Empties the stack.
    ---
    function Stack:empty()
        for i = 1, self.size, 1 do
            self[ i ] = nil
        end

        self.size = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator for the stack.
    ---
    ---@return function iterator The iterator function.
    ---@return Stack stack The stack being iterated over.
    function Stack:iterator()
        return self.pop, self
    end

    --- [SHARED AND MENU]
    ---
    --- A stack class.
    ---
    ---@class dreamwork.std.StackClass : dreamwork.std.Stack
    ---@field __base dreamwork.std.Stack
    ---@overload fun(): dreamwork.std.Stack
    local StackClass = class.create( Stack )
    std.Stack = StackClass

    ---@diagnostic disable-next-line: duplicate-doc-alias
    ---@alias Stack dreamwork.std.Stack

end

do

    --- [SHARED AND MENU]
    ---
    --- A queue is a first-in-first-out (FIFO) data structure object.
    ---
    ---@class dreamwork.std.Queue : dreamwork.std.Object
    ---@field __class dreamwork.std.QueueClass
    ---@field front integer The front of the queue. **Read-only**
    ---@field back integer The back of the queue. **Read-only**
    local Queue = class.base( "Queue" )

    ---@protected
    function Queue:__init()
        self.front = 0
        self.back = 0
    end

    ---@param writer dreamwork.std.pack.Writer
    ---@protected
    function Queue:__serialize( writer )
        writer:writeInt32( self.front )
        writer:writeInt32( self.back )

        for i = self.back + 1, self.front, 1 do
            writer:serialize( self[ i ] )
        end
    end

    ---@param reader dreamwork.std.pack.Reader
    ---@param fallback dreamwork.std.Object | nil
    ---@protected
    function Queue:__deserialize( reader, fallback )
        local front, back = reader:readInt32() or 0, reader:readInt32() or 0
        self.front, self.back = front, back

        for i = back + 1, front, 1 do
            self[ i ] = reader:deserialize( self[ i ] or fallback or Queue, fallback )
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the length of the queue.
    ---
    ---@return integer length The length of the queue.
    function Queue:getLength()
        return self.front - self.back
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if the queue is empty.
    ---
    ---@return boolean isEmpty Returns true if the queue is empty.
    function Queue:isEmpty()
        return self.front == self.back
    end

    --- [SHARED AND MENU]
    ---
    --- Empties the queue.
    ---
    function Queue:empty()
        for i = self.back + 1, self.front, 1 do
            self[ i ] = nil
        end

        self.front = 0
        self.back = 0
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the value at the front of the queue or the back if `from_tail` is `true`.
    ---
    ---@param from_tail? boolean If `true`, returns the value at the back of the queue.
    ---@return any value The value at the front of the queue.
    function Queue:peek( from_tail )
        return self[ from_tail and self.front or ( self.back + 1 ) ]
    end

    --- [SHARED AND MENU]
    ---
    --- Appends a value to the end of the queue or the front if `to_head` is `true`.
    ---
    ---@param value any The value to append.
    ---@param to_head? boolean If `true`, appends the value to the front of the queue.
    function Queue:push( value, to_head )
        if to_head then
            local back = self.back
            self[ back ] = value
            self.back = back - 1
        else
            local front = self.front + 1
            self[ front ] = value
            self.front = front
        end
    end

    --- [SHARED AND MENU]
    ---
    --- Removes and returns the value at the back of the queue or the front if `from_tail` is `true`.
    ---
    ---@param from_tail? boolean If `true`, removes and returns the value at the front of the queue.
    ---@return any value The value at the back of the queue or the front if `from_tail` is `true`.
    function Queue:pop( from_tail )
        local back, front = self.back, self.front
        if back == front then return nil end

        local value

        if from_tail then

            value = self[ front ]
            self[ front ] = nil -- unreference the value

            front = front - 1
            self.front = front

        else

            back = back + 1
            self.back = back

            value = self[ back ]
            self[ back ] = nil -- unreference the value

        end

        -- reset pointers if the queue is empty
        if back == front then
            self.front = 0
            self.back = 0
        end

        return value
    end

    --- [SHARED AND MENU]
    ---
    --- Returns an iterator for the queue.
    ---
    ---@param from_tail? boolean If `true`, returns an iterator for the back of the queue.
    ---@return fun( queue: dreamwork.std.Queue, from_tail: boolean ): any iterator The iterator function.
    ---@return dreamwork.std.Queue queue The queue being iterated over.
    ---@return boolean from_tail `true` if the iterator is for the back of the queue.
    function Queue:iterator( from_tail )
        return self.pop, self, from_tail == true
    end

    --- [SHARED AND MENU]
    ---
    --- A queue class.
    ---
    ---@class dreamwork.std.QueueClass : dreamwork.std.Queue
    ---@field __base dreamwork.std.Queue
    ---@overload fun(): dreamwork.std.Queue
    local QueueClass = class.create( Queue )
    std.Queue = QueueClass

    ---@alias Queue dreamwork.std.Queue

end

do

    --- [SHARED AND MENU]
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

    ---@protected
    ---@return string
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

    ---@param writer dreamwork.std.pack.Writer
    ---@protected
    function Node:__serialize( writer )
        writer:writeInt32( self.depth )

        local width = self.width
        writer:writeInt32( width )

        for index = 1, width, 1 do
            writer:serialize( self[ index ] )
        end
    end

    ---@param reader dreamwork.std.pack.Reader
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

    --- [SHARED AND MENU]
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

    --- [SHARED AND MENU]
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

    --- [SHARED AND MENU]
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

    --- [SHARED AND MENU]
    ---
    --- A node class.
    ---
    ---@class dreamwork.std.NodeClass : dreamwork.std.Node
    ---@field __base dreamwork.std.Node
    ---@overload fun( value: any, parent: dreamwork.std.Node? ): dreamwork.std.Node
    local NodeClass = class.create( Node )
    std.Node = NodeClass

end

do

    local debug = std.debug
    local debug_newproxy = debug.newproxy
    local debug_getmetatable = debug.getmetatable

    --- [SHARED AND MENU]
    ---
    --- A symbol.
    ---
    ---@class dreamwork.std.Symbol : userdata

    ---@alias Symbol dreamwork.std.Symbol

    ---@type table<dreamwork.std.Symbol, string>
    local names = {}
    debug.gc.setTableRules( names, true, false )

    ---@type table<string, dreamwork.std.Symbol>
    local symbols = {}

    debug.gc.setTableRules( symbols, false, true )

    local proxy_template = debug_newproxy( true )

    local Symbol = debug_getmetatable( proxy_template )
    Symbol.__type = "Symbol"

    ---@return string
    ---@private
    function Symbol:__tostring()
        return names[ self ]
    end

    --- [SHARED AND MENU]
    ---
    --- Creates a new symbol.
    ---
    ---@param name string The name of the symbol.
    ---@return dreamwork.std.Symbol obj The new symbol.
    function std.Symbol( name )
        local symbol = symbols[ name ]
        if symbol == nil then
            symbol = debug_newproxy( proxy_template )
            names[ symbol ] = string_format( "%s Symbol: %p", name, symbol )
            symbols[ name ] = symbol
        end

        return symbol
    end

    --- [SHARED AND MENU]
    ---
    --- Checks if a value is a symbol.
    ---
    ---@param value any The value to check.
    function std.issymbol( value )
        return debug_getmetatable( value ) == Symbol
    end

end
