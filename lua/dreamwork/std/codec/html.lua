---@class dreamwork.std
local std                        = dreamwork.std

local isString                   = std.isString
local tostring                   = std.tostring

local raw                        = std.raw
local raw_pairs                  = raw.pairs
local raw_select                 = raw.select
local raw_tonumber               = raw.tonumber

local class                      = std.class

local debug                      = std.debug
local debug_fempty               = debug.fempty
local debug_getmetatable         = debug.getmetatable

local table                      = std.table
local table_sort                 = table.sort
local table_concat               = table.concat

local string                     = std.string
local string_lower               = string.lower
local string_gmatch              = string.gmatch
local string_byteRep             = string.byteRep
local string_sub, string_len     = string.sub, string.len
local string_char, string_byte   = string.char, string.byte
local string_gsub, string_match  = string.gsub, string.match
local string_find, string_format = string.find, string.format

local utf8                       = std.utf8
local utf8_encode                = utf8.encode


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
---@class dreamwork.std.HTMLNode : dreamwork.std.Object
---@field __class dreamwork.std.HTMLNodeClass
---@field name string The tag name of the node, lowercase for HTML elements and `#document` for documents.
---@field attributes nil | table<string, string> The attributes of the node, boolean attributes have an empty value.
---@field parent dreamwork.std.HTMLNode | nil The parent node.
---@field children nil | dreamwork.std.HTMLNode.Value[] The child nodes and text chunks in document order.
---@field doctype nil | string The DOCTYPE of a document, e.g. `html`.
local HTMLNode = class.base( "HTMLNode", false )

---@alias dreamwork.std.HTMLNode.Value string | dreamwork.std.HTMLNode


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
---@class dreamwork.std.HTMLNodeClass : dreamwork.std.HTMLNode, dreamwork.std.Class
---@field __base dreamwork.std.HTMLNode
---@overload fun( name: string, attributes: ( table<string, string> | nil ), parent: ( dreamwork.std.HTMLNode | nil ) ): dreamwork.std.HTMLNode
local HTMLNodeClass = class.create( HTMLNode )
std.HTMLNode        = HTMLNodeClass


--- [SHARED AND MENU]
---
--- Checks whether the value type is a `HTMLNode`.
---
---@param value any
---@return boolean is_html_node
---@nodiscard
local function isHTMLNode( value )
    return debug_getmetatable( value ) == HTMLNode
end

std.isHTMLNode = isHTMLNode


---@type table<string, boolean>
local html_void = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    keygen = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true
}

-- content is not markup, `true` is decoded (escapable raw text)
---@type table<string, boolean>
local html_raw = {
    script = false,
    style = false,
    xmp = false,
    iframe = false,
    noembed = false,
    noframes = false,
    plaintext = false,
    textarea = true,
    title = true
}

-- whitespace is kept as is
---@type table<string, boolean>
local html_preformatted = {
    pre = true, listing = true, textarea = true, script = true, style = true, xmp = true, plaintext = true
}

-- whitespace-only text is never content
---@type table<string, boolean>
local html_no_text = {
    [ "#document" ] = true,
    html = true,
    head = true,
    table = true,
    thead = true,
    tbody = true,
    tfoot = true,
    tr = true,
    colgroup = true,
    ul = true,
    ol = true,
    dl = true,
    select = true,
    optgroup = true
}

-- elements written on one line by the pretty printer
---@type table<string, boolean>
local html_inline = {
    a = true,
    abbr = true,
    b = true,
    bdi = true,
    bdo = true,
    br = true,
    button = true,
    cite = true,
    code = true,
    data = true,
    dfn = true,
    em = true,
    i = true,
    img = true,
    input = true,
    kbd = true,
    label = true,
    mark = true,
    q = true,
    s = true,
    samp = true,
    small = true,
    span = true,
    strong = true,
    sub = true,
    sup = true,
    time = true,
    u = true,
    var = true,
    wbr = true
}


-- open elements implicitly closed by a start tag
---@type table<string, table<string, boolean>>
local html_closes = {}

do

    local closes_p = { p = true }

    for name in string_gmatch( "address article aside blockquote center details dialog dir div dl fieldset figcaption figure footer form header hgroup hr main menu nav ol p pre section table ul", "%S+" ) do
        html_closes[ name ] = closes_p
    end

    local closes_heading = { p = true, h1 = true, h2 = true, h3 = true, h4 = true, h5 = true, h6 = true }

    for level = 1, 6, 1 do
        html_closes[ "h" .. level ] = closes_heading
    end

    html_closes.li = { li = true, p = true }
    html_closes.dt = { dt = true, dd = true, p = true }
    html_closes.dd = html_closes.dt
    html_closes.option = { option = true }
    html_closes.optgroup = { option = true, optgroup = true }
    html_closes.tr = { tr = true, td = true, th = true }
    html_closes.td = { td = true, th = true }
    html_closes.th = html_closes.td
    html_closes.thead = { thead = true, tbody = true, tfoot = true, tr = true, td = true, th = true, caption = true }
    html_closes.tbody = html_closes.thead
    html_closes.tfoot = html_closes.thead
    html_closes.rt = { rt = true, rp = true }
    html_closes.rp = html_closes.rt

end

---@type table<integer, boolean>
local html_space = {
    [ 0x09 ] = true, -- \t
    [ 0x0A ] = true, -- \n
    [ 0x0C ] = true, -- \f
    [ 0x0D ] = true, -- \r
    [ 0x20 ] = true  -- space
}

local decode_entities
do

    ---@type table<string, string>
    local entities = {
        lt = "<",
        gt = ">",
        amp = "&",
        quot = "\"",
        apos = "'"
    }

    do
        local code_point = 0xA0

        -- Latin-1 Supplement, U+00A0 - U+00FF
        for name in string_gmatch( [[
        nbsp iexcl cent pound curren yen brvbar sect uml copy ordf laquo not shy reg macr
        deg plusmn sup2 sup3 acute micro para middot cedil sup1 ordm raquo frac14 frac12 frac34 iquest
        Agrave Aacute Acirc Atilde Auml Aring AElig Ccedil Egrave Eacute Ecirc Euml Igrave Iacute Icirc Iuml
        ETH Ntilde Ograve Oacute Ocirc Otilde Ouml times Oslash Ugrave Uacute Ucirc Uuml Yacute THORN szlig
        agrave aacute acirc atilde auml aring aelig ccedil egrave eacute ecirc euml igrave iacute icirc iuml
        eth ntilde ograve oacute ocirc otilde ouml divide oslash ugrave uacute ucirc uuml yacute thorn yuml
    ]], "%S+" ) do
            entities[ name ] = utf8_encode( code_point )
            code_point = code_point + 1
        end

    end

    -- Greek letters, U+0391 - U+03A9 and U+03B1 - U+03C9
    local greek = { "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho", false, "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega" }

    for index = 1, #greek, 1 do
        local name = greek[ index ]
        if name then
            entities[ name ] = utf8_encode( 0x390 + index )
            entities[ string_lower( name ) ] = utf8_encode( 0x3B0 + index )
        end
    end

    -- symbols and special characters
    for name, value in string_gmatch( [[
        OElig=338 oelig=339 Scaron=352 scaron=353 Yuml=376 fnof=402 circ=710 tilde=732 sigmaf=962
        thetasym=977 upsih=978 piv=982 ensp=8194 emsp=8195 thinsp=8201 zwnj=8204 zwj=8205 lrm=8206 rlm=8207
        ndash=8211 mdash=8212 lsquo=8216 rsquo=8217 sbquo=8218 ldquo=8220 rdquo=8221 bdquo=8222
        dagger=8224 Dagger=8225 bull=8226 hellip=8230 permil=8240 prime=8242 Prime=8243 lsaquo=8249
        rsaquo=8250 oline=8254 frasl=8260 euro=8364 image=8465 weierp=8472 real=8476 trade=8482 alefsym=8501
        larr=8592 uarr=8593 rarr=8594 darr=8595 harr=8596 crarr=8629 lArr=8656 uArr=8657 rArr=8658 dArr=8659
        hArr=8660 forall=8704 part=8706 exist=8707 empty=8709 nabla=8711 isin=8712 notin=8713 ni=8715
        prod=8719 sum=8721 minus=8722 lowast=8727 radic=8730 prop=8733 infin=8734 ang=8736 and=8743 or=8744
        cap=8745 cup=8746 int=8747 there4=8756 sim=8764 cong=8773 asymp=8776 ne=8800 equiv=8801 le=8804
        ge=8805 sub=8834 sup=8835 nsub=8836 sube=8838 supe=8839 oplus=8853 otimes=8855 perp=8869 sdot=8901
        lceil=8968 rceil=8969 lfloor=8970 rfloor=8971 lang=9001 rang=9002 loz=9674 spades=9824 clubs=9827
        hearts=9829 diams=9830
    ]], "(%w+)=(%d+)" ) do
        entities[ name ] = utf8_encode( raw_tonumber( value, 10 ) or 0 )
    end

    ---@param name string
    ---@return string | nil
    local function decode_entity( name )
        local replacement = entities[ name ]
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

    --- Decodes named (XML and HTML 4) and numeric character references in one pass, unknown ones are kept as is.
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

--- Escapes the string for HTML text, or for a double-quoted attribute value.
---
---@param str string
---@param is_attribute boolean
---@return string
local function html_escape( str, is_attribute )
    if is_attribute then
        if string_find( str, "&", 1, true ) == nil and string_find( str, "\"", 1, true ) == nil then
            return str
        end

        return (string_gsub( string_gsub( str, "&", "&amp;" ), "\"", "&quot;" ))
    end

    if string_find( str, "&", 1, true ) == nil and string_find( str, "<", 1, true ) == nil and string_find( str, ">", 1, true ) == nil then
        return str
    end

    return (string_gsub( string_gsub( string_gsub( str, "&", "&amp;" ), "<", "&lt;" ), ">", "&gt;" ))
end

--- Converts values that are not strings or nodes to strings.
---
---@param value any
---@return dreamwork.std.HTMLNode.Value
local function html_value( value )
    if isString( value ) or isHTMLNode( value ) then
        return value
    end

    return tostring( value )
end

--- Appends text to the children of the node, merging it with the last text chunk.
---
---@param node dreamwork.std.HTMLNode
---@param text string
local function html_append_text( node, text )
    local children = node.children
    if children == nil then
        node.children = { text }
        return
    end

    local length = #children

    local last = children[ length ]
    if isString( last ) then
        children[ length ] = last .. text
    else
        children[ length + 1 ] = text
    end
end

---@param name string
---@param attributes table<string, string> | nil
---@param parent dreamwork.std.HTMLNode | nil
---@protected
function HTMLNode:__init( name, attributes, parent )
    self.name = name
    self.attributes = attributes

    if parent == nil then return end

    self.parent = parent

    local children = parent.children
    if children == nil then
        parent.children = { self }
    else
        children[ #children + 1 ] = self
    end
end

--- [SHARED AND MENU]
---
--- Checks whether the node is a void element, which has no end tag and no children, like `br` or `img`.
---
---@return boolean is_void
---@nodiscard
function HTMLNode:isVoid()
    return html_void[ self.name ] == true
end

--- [SHARED AND MENU]
---
--- Checks whether the node is a document.
---
---@return boolean is_document
---@nodiscard
function HTMLNode:isDocument()
    return self.name == "#document"
end

--- [SHARED AND MENU]
---
--- Checks whether the node has no children.
---
---@return boolean is_empty
---@nodiscard
function HTMLNode:isEmpty()
    local children = self.children
    return children == nil or children[ 1 ] == nil
end

--- [SHARED AND MENU]
---
--- Returns the value of the attribute with the given name or `nil` if not found.
---
---@param name string The name of the attribute to get.
---@return nil | string value The value of the attribute or `nil` if not found.
---@nodiscard
function HTMLNode:getAttribute( name )
    local attributes = self.attributes
    if attributes == nil then
        return nil
    end

    return attributes[ name ]
end

--- [SHARED AND MENU]
---
--- Sets the value of the attribute with the given name, `true` sets a boolean attribute, `nil` or `false` removes it.
---
---@param name string The name of the attribute to set.
---@param value any The value of the attribute.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:setAttribute( name, value )
    if value == nil or value == false then
        local attributes = self.attributes
        if attributes ~= nil then
            attributes[ name ] = nil
        end

        return self
    end

    if value == true then
        value = ""
    elseif not isString( value ) then
        value = tostring( value )
    end

    local attributes = self.attributes
    if attributes == nil then
        self.attributes = { [ name ] = value }
    else
        attributes[ name ] = value
    end

    return self
end

--- [SHARED AND MENU]
---
--- Checks whether the node has the attribute with the given name.
---
---@param name string The name of the attribute.
---@return boolean has_attribute
---@nodiscard
function HTMLNode:hasAttribute( name )
    local attributes = self.attributes
    return attributes ~= nil and attributes[ name ] ~= nil
end

--- [SHARED AND MENU]
---
--- Removes the attribute with the given name.
---
---@param name string The name of the attribute to remove.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:removeAttribute( name )
    return self:setAttribute( name, nil )
end

--- Checks whether the whitespace-separated class list contains the class name.
---
---@param class_str string
---@param name string
---@return boolean
local function has_class_name( class_str, name )
    if class_str == name then
        return true
    end

    local class_length = string_len( class_str )
    local start = 1

    ::class_loop::

    local name_start, name_end = string_find( class_str, name, start, true )
    if name_start == nil then
        return false
    end

    if (name_start == 1 or html_space[ string_byte( class_str, name_start - 1 ) ]) and
        (name_end == class_length or html_space[ string_byte( class_str, name_end + 1 ) ]) then
        return true
    end

    start = name_start + 1

    ---@diagnostic disable-next-line: missing-return
    goto class_loop
end

--- [SHARED AND MENU]
---
--- Checks whether the node has the given class in its `class` attribute.
---
---@param name string The class name.
---@return boolean has_class
---@nodiscard
function HTMLNode:hasClass( name )
    local attributes = self.attributes
    if attributes == nil then
        return false
    end

    local class_str = attributes.class
    return class_str ~= nil and has_class_name( class_str, name )
end

--- [SHARED AND MENU]
---
--- Adds the class to the `class` attribute of the node.
---
---@param name string The class name.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:addClass( name )
    local class_str = self:getAttribute( "class" )
    if class_str == nil or string_find( class_str, "%S" ) == nil then
        return self:setAttribute( "class", name )
    end

    if has_class_name( class_str, name ) then
        return self
    end

    return self:setAttribute( "class", class_str .. " " .. name )
end

--- [SHARED AND MENU]
---
--- Removes the class from the `class` attribute of the node, the attribute is removed when no classes are left.
---
---@param name string The class name.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:removeClass( name )
    local class_str = self:getAttribute( "class" )
    if class_str == nil or not has_class_name( class_str, name ) then
        return self
    end

    local names, name_count = {}, 0

    for class_name in string_gmatch( class_str, "%S+" ) do
        if class_name ~= name then
            name_count = name_count + 1
            names[ name_count ] = class_name
        end
    end

    if name_count == 0 then
        return self:setAttribute( "class", nil )
    end

    return self:setAttribute( "class", table_concat( names, " ", 1, name_count ) )
end

--- [SHARED AND MENU]
---
--- Returns the number of children (nodes and text chunks) of the node.
---
---@return integer count
---@nodiscard
function HTMLNode:getChildCount()
    local children = self.children
    if children == nil then
        return 0
    end

    return #children
end

--- [SHARED AND MENU]
---
--- Returns the child (node or text chunk) at the given index, negative indices count from the end.
---
---@param index integer The index of the child.
---@return nil | dreamwork.std.HTMLNode.Value child
---@nodiscard
function HTMLNode:getChild( index )
    local children = self.children
    if children == nil then
        return nil
    end

    if index < 0 then
        index = #children + index + 1
    end

    return children[ index ]
end

--- [SHARED AND MENU]
---
--- Returns an iterator over the children of the node in document order, values are strings or nodes.
---
---@return fun(): ( ( integer | nil ), dreamwork.std.HTMLNode.Value ) fn The iterator function.
---@nodiscard
function HTMLNode:iterator()
    local children = self.children
    if children == nil then
        return debug_fempty
    end

    local index = 0

    return function()
        index = index + 1

        local child = children[ index ]
        if child == nil then
            ---@diagnostic disable-next-line: return-type-mismatch
            return nil, nil
        end

        return index, child
    end
end

--- [SHARED AND MENU]
---
--- Detaches the node from its parent.
---
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:detach()
    local parent = self.parent
    if parent == nil then
        return self
    end

    self.parent = nil

    local children = parent.children
    if children == nil then
        return self
    end

    local length = #children

    for i = 1, length, 1 do
        if children[ i ] == self then
            for j = i, length - 1, 1 do
                children[ j ] = children[ j + 1 ]
            end

            children[ length ] = nil
            break
        end
    end

    return self
end

--- [SHARED AND MENU]
---
--- Inserts a node or text at the given index, nodes are detached from their old parent first.
---
---@param index integer The index to insert at, clamped to the children range, negative indices count from the end.
---@param value dreamwork.std.HTMLNode.Value | any The node or text to insert, other values are converted to strings.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:insert( index, value )
    value = html_value( value )

    if isHTMLNode( value ) then
        ---@cast value dreamwork.std.HTMLNode
        if value == self then
            std.errorf( "HTMLNode can not be a child of itself" )
            return self
        end

        value:detach()
        value.parent = self
    end

    local children = self.children
    if children == nil then
        children = {}
        self.children = children
    end

    local length = #children

    if index < 0 then
        index = length + index + 2
    end

    if index < 1 then
        index = 1
    elseif index > length + 1 then
        index = length + 1
    end

    for i = length, index, -1 do
        children[ i + 1 ] = children[ i ]
    end

    children[ index ] = value
    return self
end

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
---@param ... dreamwork.std.HTMLNode.Value | any The nodes or text to append, other values are converted to strings.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:append( ... )
    local values = { ... }

    for i = 1, raw_select( "#", ... ), 1 do
        self:insert( 0x7FFFFFFF, values[ i ] )
    end

    return self
end

--- [SHARED AND MENU]
---
--- Creates a new element and appends it to the children of the node.
---
---@param name string The tag name of the new element.
---@param attributes table<string, string>? The attributes of the new element.
---@return dreamwork.std.HTMLNode child The new element.
function HTMLNode:add( name, attributes )
    return HTMLNodeClass( name, attributes, self )
end

--- [SHARED AND MENU]
---
--- Removes the child at the given index or the given child node.
---
---@param child integer | dreamwork.std.HTMLNode The index of the child or the child node.
---@return nil | dreamwork.std.HTMLNode.Value removed The removed child, or `nil` if not found.
function HTMLNode:remove( child )
    local children = self.children
    if children == nil then
        return nil
    end

    if isHTMLNode( child ) then
        ---@cast child dreamwork.std.HTMLNode
        if child.parent ~= self then
            return nil
        end

        child:detach()
        return child
    end

    ---@cast child integer

    local length = #children

    if child < 0 then
        child = length + child + 1
    end

    local value = children[ child ]
    if value == nil then
        return nil
    end

    if isHTMLNode( value ) then
        ---@cast value dreamwork.std.HTMLNode
        value:detach()
        return value
    end

    for i = child, length - 1, 1 do
        children[ i ] = children[ i + 1 ]
    end

    children[ length ] = nil
    return value
end

--- [SHARED AND MENU]
---
--- Removes all children of the node.
---
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:clear()
    local children = self.children
    if children == nil then
        return self
    end

    for i = 1, #children, 1 do
        local child = children[ i ]
        if isHTMLNode( child ) then
            ---@cast child dreamwork.std.HTMLNode
            child.parent = nil
        end
    end

    self.children = nil
    return self
end

---@param node dreamwork.std.HTMLNode
---@param buffer string[]
---@param count integer
---@return integer count
local function collect_text( node, buffer, count )
    local children = node.children
    if children == nil then
        return count
    end

    for i = 1, #children, 1 do
        local child = children[ i ]
        if isString( child ) then
            ---@cast child string
            count = count + 1
            buffer[ count ] = child
        else
            ---@cast child dreamwork.std.HTMLNode
            count = collect_text( child, buffer, count )
        end
    end

    return count
end

--- [SHARED AND MENU]
---
--- Returns the text content of the node and all its descendants, like `textContent` in the browser DOM.
---
---@return string text
---@nodiscard
function HTMLNode:getText()
    local children = self.children
    if children == nil then
        return ""
    end

    if #children == 1 and isString( children[ 1 ] ) then
        ---@cast children string[]
        return children[ 1 ]
    end

    local buffer = {}
    return table_concat( buffer, "", 1, collect_text( self, buffer, 0 ) )
end

--- [SHARED AND MENU]
---
--- Replaces all children of the node with the given text.
---
---@param text string | any The text, other values are converted to strings.
---@return dreamwork.std.HTMLNode self The node itself, for chaining.
function HTMLNode:setText( text )
    self:clear()

    if not isString( text ) then
        text = tostring( text )
    end

    if text ~= "" then
        self.children = { text }
    end

    return self
end

---@param node dreamwork.std.HTMLNode
---@return boolean
local function is_element( node )
    return node.name ~= "#document"
end

--- [SHARED AND MENU]
---
--- Returns the first child element of the node, skipping text.
---
---@return dreamwork.std.HTMLNode | nil element
---@nodiscard
function HTMLNode:getFirstElement()
    local children = self.children
    if children == nil then
        return nil
    end

    for i = 1, #children, 1 do
        local child = children[ i ]
        if isHTMLNode( child ) then
            ---@cast child dreamwork.std.HTMLNode
            return child
        end
    end

    return nil
end

--- [SHARED AND MENU]
---
--- Returns the child elements of the node, skipping text.
---
---@return dreamwork.std.HTMLNode[] elements
---@return integer count
---@nodiscard
function HTMLNode:getElements()
    local elements, count = {}, 0

    local children = self.children
    if children ~= nil then
        for i = 1, #children, 1 do
            local child = children[ i ]
            if isHTMLNode( child ) then
                count = count + 1
                elements[ count ] = child
            end
        end
    end

    return elements, count
end

local selector_compile, selector_match
do

    --- Returns the position of the node among the element children of its parent and their count.
    ---
    ---@param node dreamwork.std.HTMLNode
    ---@param same_type boolean Whether only elements with the same name are counted.
    ---@return integer position
    ---@return integer count
    local function element_position( node, same_type )
        local parent = node.parent
        if parent == nil then
            return 1, 1
        end

        local children = parent.children
        if children == nil then
            return 1, 1
        end

        local name = node.name
        local position, count = 0, 0

        for i = 1, #children, 1 do
            local child = children[ i ]
            if isHTMLNode( child ) and (not same_type or child.name == name) then
                count = count + 1

                if child == node then
                    position = count
                end
            end
        end

        return position, count
    end

    --- Returns the element sibling of the node right before it.
    ---
    ---@param node dreamwork.std.HTMLNode
    ---@return dreamwork.std.HTMLNode | nil
    local function previous_element( node )
        local parent = node.parent
        if parent == nil then
            return nil
        end

        local children = parent.children
        if children == nil then
            return nil
        end

        local previous

        for i = 1, #children, 1 do
            local child = children[ i ]
            if child == node then
                return previous
            elseif isHTMLNode( child ) then
                previous = child
            end
        end

        return nil
    end

    --- Parses the `an+b` argument of `:nth-child()`.
    ---
    ---@param selector string
    ---@param argument string
    ---@return integer a
    ---@return integer b
    local function parse_nth( selector, argument )
        argument = string_lower( string_gsub( argument, "%s+", "" ) )

        if argument == "odd" then
            return 2, 1
        elseif argument == "even" then
            return 2, 0
        end

        if string_find( argument, "^[+-]?%d+$" ) ~= nil then
            return 0, raw_tonumber( argument, 10 ) or 0
        end

        local a_str, b_str = string_match( argument, "^([+-]?%d*)n([+-]?%d*)$" )
        if a_str == nil then
            std.errorf( "invalid selector '%s', bad nth argument '%s'", selector, argument )
            return 0, 0
        end

        local a
        if a_str == "" or a_str == "+" then
            a = 1
        elseif a_str == "-" then
            a = -1
        else
            a = raw_tonumber( a_str, 10 ) or 0
        end

        if b_str == "" then
            return a, 0
        end

        if string_byte( b_str, 1 ) == 0x2B --[[ + ]] then
            b_str = string_sub( b_str, 2 )
        end

        return a, raw_tonumber( b_str, 10 ) or 0
    end

    ---@param position integer
    ---@param a integer
    ---@param b integer
    ---@return boolean
    local function nth_match( position, a, b )
        if a == 0 then
            return position == b
        end

        local difference = position - b
        return difference % a == 0 and difference / a >= 0
    end

    ---@alias dreamwork.std.HTMLNode.Selector dreamwork.std.HTMLNode.SelectorCompound[][]

    ---@class dreamwork.std.HTMLNode.SelectorCompound
    ---@field combinator nil | string The relation to the compound on the left: `" "`, `">"`, `"+"` or `"~"`.
    ---@field tag nil | string
    ---@field id nil | string
    ---@field classes nil | string[]
    ---@field attributes nil | { name: string, operator: string | nil, value: string, insensitive: boolean }[]
    ---@field pseudos nil | { name: string, a: integer, b: integer, group: dreamwork.std.HTMLNode.Selector | nil }[]

    ---@type table<string, boolean>
    local nth_pseudos = {
        [ "nth-child" ] = true,
        [ "nth-last-child" ] = true,
        [ "nth-of-type" ] = true,
        [ "nth-last-of-type" ] = true
    }

    ---@type table<string, boolean>
    local plain_pseudos = {
        [ "first-child" ] = true,
        [ "last-child" ] = true,
        [ "only-child" ] = true,
        [ "first-of-type" ] = true,
        [ "last-of-type" ] = true,
        [ "only-of-type" ] = true,
        [ "empty" ] = true,
        [ "root" ] = true
    }

    --- Compiles a CSS selector list.
    ---
    ---@param selector string
    ---@return dreamwork.std.HTMLNode.Selector
    function selector_compile( selector )
        local selector_length = string_len( selector )

        ---@type dreamwork.std.HTMLNode.SelectorCompound[]
        local complex = {}

        ---@type dreamwork.std.HTMLNode.Selector
        local group = { complex }

        ---@type dreamwork.std.HTMLNode.SelectorCompound | nil
        local compound

        ---@type string | nil
        local combinator

        local position = 1

        ::selector_loop::

        local _, space_end = string_find( selector, "^%s*", position )
        local had_space = space_end >= position
        position = space_end + 1

        if position > selector_length then
            if compound == nil then
                std.errorf( "invalid selector '%s', unexpected end", selector )
            end

            return group
        end

        local uint8 = string_byte( selector, position )

        if uint8 == 0x2C --[[ , ]] then
            if compound == nil then
                std.errorf( "invalid selector '%s', unexpected ',' at position %d", selector, position )
            end

            complex = {}
            group[ #group + 1 ] = complex
            compound, combinator = nil, nil

            position = position + 1
            goto selector_loop
        end

        if uint8 == 0x3E --[[ > ]] or uint8 == 0x2B --[[ + ]] or uint8 == 0x7E --[[ ~ ]] then
            if compound == nil then
                std.errorf( "invalid selector '%s', unexpected combinator at position %d", selector, position )
            end

            combinator = string_char( uint8 )
            compound = nil

            position = position + 1
            goto selector_loop
        end

        if compound ~= nil and had_space then
            combinator = " "
            compound = nil
        end

        if compound == nil then
            compound = { combinator = combinator }
            complex[ #complex + 1 ] = compound
            combinator = nil
        end

        ---@cast compound dreamwork.std.HTMLNode.SelectorCompound

        if uint8 == 0x2A --[[ * ]] then
            position = position + 1
        elseif uint8 == 0x23 --[[ # ]] or uint8 == 0x2E --[[ . ]] then
            local _, name_end, name = string_find( selector, "^([%w_%-\128-\255]+)", position + 1 )
            if name_end == nil then
                std.errorf( "invalid selector '%s', expected a name at position %d", selector, position + 1 )
            end

            if uint8 == 0x23 --[[ # ]] then
                compound.id = name
            else
                local classes = compound.classes
                if classes == nil then
                    compound.classes = { name }
                else
                    classes[ #classes + 1 ] = name
                end
            end

            position = name_end + 1
        elseif uint8 == 0x5B --[[ [ ]] then
            local _, name_end, name = string_find( selector, "^%[%s*([%w_:%-\128-\255]+)%s*", position )
            if name_end == nil then
                std.errorf( "invalid selector '%s', expected an attribute name at position %d", selector, position + 1 )
            end

            ---@cast name_end integer

            local attribute = { name = string_lower( name ), value = "", insensitive = false }
            position = name_end + 1

            local _, operator_end, operator = string_find( selector, "^([~|%^%$%*]?=)%s*", position )
            if operator_end ~= nil then
                attribute.operator = operator
                position = operator_end + 1

                local _, value_end, _, value = string_find( selector, "^([\"'])(.-)%1", position )
                if value_end == nil then
                    _, value_end, value = string_find( selector, "^([^%s%]]+)", position )
                end

                if value_end == nil then
                    std.errorf( "invalid selector '%s', expected an attribute value at position %d", selector, position )
                end

                attribute.value = value
                position = value_end + 1

                local _, flag_end, flag = string_find( selector, "^%s+([iIsS])", position )
                if flag_end ~= nil then
                    if flag == "i" or flag == "I" then
                        attribute.insensitive = true
                        attribute.value = string_lower( value )
                    end

                    position = flag_end + 1
                end
            end

            local _, close_end = string_find( selector, "^%s*%]", position )
            if close_end == nil then
                std.errorf( "invalid selector '%s', expected ']' at position %d", selector, position )
            end

            position = close_end + 1

            local attributes = compound.attributes
            if attributes == nil then
                compound.attributes = { attribute }
            else
                attributes[ #attributes + 1 ] = attribute
            end
        elseif uint8 == 0x3A --[[ : ]] then
            local _, name_end, name = string_find( selector, "^:([%w%-]+)", position )
            if name_end == nil then
                std.errorf( "invalid selector '%s', expected a pseudo-class at position %d", selector, position )
            end

            name = string_lower( name )
            position = name_end + 1

            local pseudo = { name = name, a = 0, b = 0 }

            if name == "not" or nth_pseudos[ name ] then
                local _, argument_end = string_find( selector, "^%b()", position )
                if argument_end == nil then
                    std.errorf( "invalid selector '%s', expected '(' after ':%s'", selector, name )
                end

                local argument = string_sub( selector, position + 1, argument_end - 1 )
                position = argument_end + 1

                if name == "not" then
                    pseudo.group = selector_compile( argument )
                else
                    pseudo.a, pseudo.b = parse_nth( selector, argument )
                end
            elseif not plain_pseudos[ name ] then
                std.errorf( "invalid selector '%s', unsupported pseudo-class ':%s'", selector, name )
            end

            local pseudos = compound.pseudos
            if pseudos == nil then
                compound.pseudos = { pseudo }
            else
                pseudos[ #pseudos + 1 ] = pseudo
            end
        else
            local _, name_end, name = string_find( selector, "^([%w_%-\128-\255]+)", position )
            if name_end == nil then
                std.errorf( "invalid selector '%s', unexpected '%s' at position %d", selector, string_char( uint8 ), position )
            end

            compound.tag = string_lower( name )
            position = name_end + 1
        end

        ---@diagnostic disable-next-line: missing-return
        goto selector_loop
    end

    ---@param value string
    ---@param attribute { name: string, operator: string | nil, value: string, insensitive: boolean }
    ---@return boolean
    local function attribute_match( value, attribute )
        local operator = attribute.operator
        if operator == nil then
            return true
        end

        if attribute.insensitive then
            value = string_lower( value )
        end

        local expected = attribute.value

        if operator == "=" then
            return value == expected
        elseif operator == "~=" then
            return expected ~= "" and string_find( expected, "%s" ) == nil and has_class_name( value, expected )
        elseif operator == "|=" then
            return value == expected or string_sub( value, 1, string_len( expected ) + 1 ) == expected .. "-"
        elseif expected == "" then
            return false
        elseif operator == "^=" then
            return string_sub( value, 1, string_len( expected ) ) == expected
        elseif operator == "$=" then
            return string_sub( value, -string_len( expected ) ) == expected
        else -- *=
            return string_find( value, expected, 1, true ) ~= nil
        end
    end

    ---@param node dreamwork.std.HTMLNode
    ---@param compound dreamwork.std.HTMLNode.SelectorCompound
    ---@return boolean
    local function compound_match( node, compound )
        local tag = compound.tag
        if tag ~= nil and node.name ~= tag and string_lower( node.name ) ~= tag then
            return false
        end

        local attributes = node.attributes

        local id = compound.id
        if id ~= nil and (attributes == nil or attributes.id ~= id) then
            return false
        end

        local classes = compound.classes
        if classes ~= nil then
            local class_str = attributes and attributes.class
            if class_str == nil then
                return false
            end

            for i = 1, #classes, 1 do
                if not has_class_name( class_str, classes[ i ] ) then
                    return false
                end
            end
        end

        local attribute_selectors = compound.attributes
        if attribute_selectors ~= nil then
            if attributes == nil then
                return false
            end

            for i = 1, #attribute_selectors, 1 do
                local attribute = attribute_selectors[ i ]

                local value = attributes[ attribute.name ]
                if value == nil or not attribute_match( value, attribute ) then
                    return false
                end
            end
        end

        local pseudos = compound.pseudos
        if pseudos ~= nil then
            for i = 1, #pseudos, 1 do
                local pseudo = pseudos[ i ]
                local name = pseudo.name

                local matched
                if name == "not" then
                    matched = not selector_match( node, pseudo.group )
                elseif name == "empty" then
                    local children = node.children
                    matched = children == nil or children[ 1 ] == nil
                elseif name == "root" then
                    local parent = node.parent
                    matched = parent == nil or parent.name == "#document"
                else
                    local same_type = string_find( name, "of-type", 1, true ) ~= nil

                    local element_index, element_count = element_position( node, same_type )

                    if name == "first-child" or name == "first-of-type" then
                        matched = element_index == 1
                    elseif name == "last-child" or name == "last-of-type" then
                        matched = element_index == element_count
                    elseif name == "only-child" or name == "only-of-type" then
                        matched = element_count == 1
                    elseif name == "nth-child" or name == "nth-of-type" then
                        matched = nth_match( element_index, pseudo.a, pseudo.b )
                    else -- nth-last-child, nth-last-of-type
                        matched = nth_match( element_count - element_index + 1, pseudo.a, pseudo.b )
                    end
                end

                if not matched then
                    return false
                end
            end
        end

        return true
    end

    ---@param node dreamwork.std.HTMLNode
    ---@param complex dreamwork.std.HTMLNode.SelectorCompound[]
    ---@param index integer
    ---@return boolean
    local function complex_match( node, complex, index )
        local compound = complex[ index ]
        if not compound_match( node, compound ) then
            return false
        end

        if index == 1 then
            return true
        end

        local combinator = compound.combinator

        if combinator == ">" then
            local parent = node.parent
            return parent ~= nil and is_element( parent ) and complex_match( parent, complex, index - 1 )
        elseif combinator == "+" then
            local previous = previous_element( node )
            return previous ~= nil and complex_match( previous, complex, index - 1 )
        elseif combinator == "~" then
            local parent = node.parent
            if parent == nil then
                return false
            end

            local children = parent.children
            if children == nil then
                return false
            end

            for i = 1, #children, 1 do
                local child = children[ i ]
                if child == node then
                    return false
                end

                ---@cast child dreamwork.std.HTMLNode

                if isHTMLNode( child ) and complex_match( child, complex, index - 1 ) then
                    return true
                end
            end

            return false
        else -- descendant
            local parent = node.parent

            while parent ~= nil and is_element( parent ) do
                if complex_match( parent, complex, index - 1 ) then
                    return true
                end

                parent = parent.parent
            end

            return false
        end
    end

    --- Checks whether the node matches any selector of the compiled selector list.
    ---
    ---@param node dreamwork.std.HTMLNode
    ---@param group dreamwork.std.HTMLNode.Selector
    ---@return boolean
    function selector_match( node, group )
        if not is_element( node ) then
            return false
        end

        for i = 1, #group, 1 do
            local complex = group[ i ]
            if complex_match( node, complex, #complex ) then
                return true
            end
        end

        return false
    end

end

--- Collects the descendant elements of the node that pass the predicate in document order.
---
---@param node dreamwork.std.HTMLNode
---@param predicate fun( node: dreamwork.std.HTMLNode, argument: any ): boolean
---@param argument any
---@param results dreamwork.std.HTMLNode[]
---@param count integer
---@param first_only boolean
---@return integer count
local function html_search( node, predicate, argument, results, count, first_only )
    local children = node.children
    if children == nil then
        return count
    end

    for i = 1, #children, 1 do
        local child = children[ i ]
        if isHTMLNode( child ) then
            ---@cast child dreamwork.std.HTMLNode

            if predicate( child, argument ) then
                count = count + 1
                results[ count ] = child

                if first_only then
                    return count
                end
            end

            count = html_search( child, predicate, argument, results, count, first_only )

            if first_only and count ~= 0 then
                return count
            end
        end
    end

    return count
end

---@param node dreamwork.std.HTMLNode
---@param id string
---@return boolean
local function predicate_id( node, id )
    local attributes = node.attributes
    return attributes ~= nil and attributes.id == id
end

---@param node dreamwork.std.HTMLNode
---@param name string
---@return boolean
local function predicate_tag( node, name )
    return name == "*" or node.name == name or string_lower( node.name ) == name
end

---@param node dreamwork.std.HTMLNode
---@param names string[]
---@return boolean
local function predicate_classes( node, names )
    local attributes = node.attributes
    if attributes == nil then
        return false
    end

    local class_str = attributes.class
    if class_str == nil then
        return false
    end

    for i = 1, #names, 1 do
        if not has_class_name( class_str, names[ i ] ) then
            return false
        end
    end

    return true
end

--- [SHARED AND MENU]
---
--- Returns the first descendant element with the given `id`, or `nil` if not found.
---
---@param id string The id of the element.
---@return dreamwork.std.HTMLNode | nil element
---@nodiscard
function HTMLNode:getElementById( id )
    local results = {}
    html_search( self, predicate_id, id, results, 0, true )
    return results[ 1 ]
end

--- [SHARED AND MENU]
---
--- Returns all descendant elements with the given tag name, `*` matches all elements.
---
---@param name string The tag name, case-insensitive.
---@return dreamwork.std.HTMLNode[] elements
---@return integer count
---@nodiscard
function HTMLNode:getElementsByTagName( name )
    local results = {}
    return results, html_search( self, predicate_tag, string_lower( name ), results, 0, false )
end

--- [SHARED AND MENU]
---
--- Returns all descendant elements that have all of the given whitespace-separated classes.
---
---@param names string The class names, separated by whitespace.
---@return dreamwork.std.HTMLNode[] elements
---@return integer count
---@nodiscard
function HTMLNode:getElementsByClassName( names )
    local list, list_length = {}, 0

    for name in string_gmatch( names, "%S+" ) do
        list_length = list_length + 1
        list[ list_length ] = name
    end

    local results = {}

    if list_length == 0 then
        return results, 0
    end

    return results, html_search( self, predicate_classes, list, results, 0, false )
end

--- [SHARED AND MENU]
---
--- Returns the first descendant element matching the CSS selector, or `nil` if not found.
---
--- Supported: type, `*`, `#id`, `.class`, attributes `[a]`, `[a=v]`, `[a~=v]`, `[a|=v]`, `[a^=v]`, `[a$=v]`, `[a*=v]` with optional `i` flag,
--- combinators ` `, `>`, `+`, `~`, selector lists `,`,
--- pseudo-classes `:first-child`, `:last-child`, `:only-child`, `:nth-child()`, `:nth-last-child()`, the `-of-type` variants, `:empty`, `:root` and `:not()`.
---
---@param selector string The CSS selector.
---@return dreamwork.std.HTMLNode | nil element
---@nodiscard
function HTMLNode:querySelector( selector )
    local results = {}
    html_search( self, selector_match, selector_compile( selector ), results, 0, true )
    return results[ 1 ]
end

--- [SHARED AND MENU]
---
--- Returns all descendant elements matching the CSS selector in document order, see `:querySelector()` for the supported syntax.
---
---@param selector string The CSS selector.
---@return dreamwork.std.HTMLNode[] elements
---@return integer count
---@nodiscard
function HTMLNode:querySelectorAll( selector )
    local results = {}
    return results, html_search( self, selector_match, selector_compile( selector ), results, 0, false )
end

--- [SHARED AND MENU]
---
--- Checks whether the node matches the CSS selector, see `:querySelector()` for the supported syntax.
---
---@param selector string The CSS selector.
---@return boolean is_matching
---@nodiscard
function HTMLNode:matches( selector )
    return selector_match( self, selector_compile( selector ) )
end

--- [SHARED AND MENU]
---
--- Returns the closest element matching the CSS selector, starting with the node itself and going up through its ancestors.
---
---@param selector string The CSS selector.
---@return dreamwork.std.HTMLNode | nil element
---@nodiscard
function HTMLNode:closest( selector )
    local group = selector_compile( selector )

    ---@type dreamwork.std.HTMLNode | nil
    local node = self

    while node ~= nil do
        if selector_match( node, group ) then
            return node
        end

        node = node.parent
    end

    return nil
end

do

    ---@param attributes table<string, string>
    ---@return string
    local function format_attributes( attributes )
        local keys, key_count = {}, 0

        for key in raw_pairs( attributes ) do
            key_count = key_count + 1
            keys[ key_count ] = key
        end

        if key_count == 0 then
            return ""
        end

        if key_count ~= 1 then
            table_sort( keys )
        end

        for i = 1, key_count, 1 do
            local key = keys[ i ]

            local value = attributes[ key ]
            if not isString( value ) then
                value = tostring( value )
            end

            if value == "" then
                keys[ i ] = " " .. key
            else
                keys[ i ] = " " .. key .. "=\"" .. html_escape( value, true ) .. "\""
            end
        end

        return table_concat( keys, "", 1, key_count )
    end

    --- Writes the node without any added whitespace.
    ---
    ---@param buffer string[]
    ---@param count integer
    ---@param node dreamwork.std.HTMLNode
    ---@return integer count
    local function write_compact( buffer, count, node )
        local name = node.name
        local children = node.children

        if name == "#document" then
            local doctype = node.doctype
            if doctype ~= nil then
                count = count + 1
                buffer[ count ] = "<!DOCTYPE " .. doctype .. ">"
            end
        else
            local attributes = node.attributes

            count = count + 1

            if attributes == nil then
                buffer[ count ] = "<" .. name .. ">"
            else
                buffer[ count ] = "<" .. name .. format_attributes( attributes ) .. ">"
            end

            if html_void[ name ] then
                return count
            end
        end

        if children ~= nil then
            local is_raw = html_raw[ name ]

            for i = 1, #children, 1 do
                local child = children[ i ]
                if isString( child ) then
                    ---@cast child string
                    count = count + 1

                    if is_raw == false then
                        buffer[ count ] = child
                    else
                        buffer[ count ] = html_escape( child, false )
                    end
                else
                    ---@cast child dreamwork.std.HTMLNode
                    count = write_compact( buffer, count, child )
                end
            end
        end

        if name ~= "#document" then
            count = count + 1
            buffer[ count ] = "</" .. name .. ">"
        end

        return count
    end

    ---@param node dreamwork.std.HTMLNode
    ---@return string
    local function compact_string( node )
        local buffer = {}

        local count = write_compact( buffer, 0, node )
        if count == 1 then
            return buffer[ 1 ]
        end

        return table_concat( buffer, "", 1, count )
    end

    --- Checks whether the pretty printer writes the children of the node on separate lines.
    ---
    ---@param node dreamwork.std.HTMLNode
    ---@return boolean
    local function is_block( node )
        local name = node.name
        if html_void[ name ] or html_preformatted[ name ] or html_raw[ name ] ~= nil then
            return false
        end

        if name == "#document" then
            return true
        end

        local children = node.children
        if children == nil then
            return false
        end

        for i = 1, #children, 1 do
            local child = children[ i ]
            if isHTMLNode( child ) and not html_inline[ child.name ] then
                return true
            end
        end

        return false
    end

    --- Writes the node with each block child on its own line.
    ---
    ---@param lines string[]
    ---@param line_count integer
    ---@param node dreamwork.std.HTMLNode
    ---@param indent string
    ---@return integer line_count
    local function write_pretty( lines, line_count, node, indent )
        if not is_block( node ) then
            line_count = line_count + 1
            lines[ line_count ] = indent .. compact_string( node )
            return line_count
        end

        local name = node.name
        local child_indent = indent

        if name == "#document" then
            local doctype = node.doctype
            if doctype ~= nil then
                line_count = line_count + 1
                lines[ line_count ] = indent .. "<!DOCTYPE " .. doctype .. ">"
            end
        else
            local attributes = node.attributes

            line_count = line_count + 1

            if attributes == nil then
                lines[ line_count ] = indent .. "<" .. name .. ">"
            else
                lines[ line_count ] = indent .. "<" .. name .. format_attributes( attributes ) .. ">"
            end

            child_indent = indent .. "  "
        end

        local children = node.children
        if children ~= nil then
            for i = 1, #children, 1 do
                local child = children[ i ]
                if isString( child ) then
                    ---@cast child string
                    local text = string_match( child, "^%s*(.-)%s*$" )
                    if text ~= "" then
                        line_count = line_count + 1
                        lines[ line_count ] = child_indent .. html_escape( text, false )
                    end
                else
                    ---@cast child dreamwork.std.HTMLNode
                    line_count = write_pretty( lines, line_count, child, child_indent )
                end
            end
        end

        if name ~= "#document" then
            line_count = line_count + 1
            lines[ line_count ] = indent .. "</" .. name .. ">"
        end

        return line_count
    end

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
    function HTMLNode:toString( pretty, level )
        if pretty ~= true then
            return compact_string( self )
        end

        local indent = ""
        if level ~= nil and level > 0 then
            indent = string_byteRep( 0x20, level * 2 )
        end

        local lines = {}

        local line_count = write_pretty( lines, 0, self, indent )
        if line_count == 1 then
            return lines[ 1 ]
        end

        return table_concat( lines, "\n", 1, line_count )
    end

    --- [SHARED AND MENU]
    ---
    --- Returns the HTML string representation of the children of this node, like `innerHTML` in the browser DOM.
    ---
    ---@return string str The HTML string representation of the children.
    ---@nodiscard
    function HTMLNode:getInnerHTML()
        local children = self.children
        if children == nil then
            return ""
        end

        local is_raw = html_raw[ self.name ]

        local buffer, count = {}, 0

        for i = 1, #children, 1 do
            local child = children[ i ]
            if isString( child ) then
                ---@cast child string
                count = count + 1

                if is_raw == false then
                    buffer[ count ] = child
                else
                    buffer[ count ] = html_escape( child, false )
                end
            else
                ---@cast child dreamwork.std.HTMLNode
                count = write_compact( buffer, count, child )
            end
        end

        return table_concat( buffer, "", 1, count )
    end

    ---@return string
    ---@protected
    function HTMLNode:__tostring()
        return compact_string( self )
    end

    ---@return string
    ---@protected
    function HTMLNode:__represent()
        local attributes = self.attributes
        if attributes == nil then
            return string_format( "HTMLNode: %p <%s>", self, self.name )
        else
            return string_format( "HTMLNode: %p <%s%s>", self, self.name, format_attributes( attributes ) )
        end
    end

end

do

    -- parse helpers take all state as arguments: closures over parser locals make the
    -- backward `goto` of the parse loop close upvalues, which LuaJIT can not compile (NYI: UCLO)

    --- Adds the text to the node, collapsing whitespace like a browser renders it unless `preserve` is set.
    ---
    --- Indentation (whitespace with a line break) at the start and end of an element and whitespace-only text with a line break are removed.
    ---
    ---@param node dreamwork.std.HTMLNode
    ---@param html_str string
    ---@param from integer
    ---@param to integer
    ---@param preserve boolean
    ---@param closing boolean Whether the next tag is an end tag.
    local function parse_text( node, html_str, from, to, preserve, closing )
        local text = string_sub( html_str, from, to )

        if not preserve then
            local first = string_find( text, "[^ \t\n\r\f]" )
            if first == nil then
                if html_no_text[ node.name ] or string_find( text, "[\n\r]" ) ~= nil then
                    return
                end

                text = " "
            else
                local text_start, text_end = 1, string_len( text )

                if first ~= 1 and node.children == nil then
                    local newline = string_find( text, "[\n\r]" )
                    if newline ~= nil and newline < first then
                        text_start = first
                    end
                end

                if closing then
                    local newline = string_find( text, "[\n\r][ \t\n\r\f]*$" )
                    if newline ~= nil then
                        text_end = newline - 1
                    end
                end

                if text_start ~= 1 or text_end ~= string_len( text ) then
                    text = string_sub( text, text_start, text_end )
                end

                if string_find( text, "[\t\n\r\f]" ) ~= nil or string_find( text, "  ", 1, true ) ~= nil then
                    text = string_gsub( text, "[ \t\n\r\f]+", " " )
                end
            end
        end

        text = decode_entities( text )

        if text ~= "" then
            html_append_text( node, text )
        end
    end

    --- Finds the end tag of a raw text element, case-insensitive.
    ---
    ---@param html_lower string
    ---@param name string
    ---@param position integer
    ---@return integer | nil end_start
    local function find_raw_end( html_lower, name, position )
        local pattern = "</" .. name

        ::raw_loop::

        local end_start, end_name = string_find( html_lower, pattern, position, true )
        if end_start == nil then
            return nil
        end

        local uint8 = string_byte( html_lower, end_name + 1 )
        if uint8 == nil or uint8 == 0x2F --[[ / ]] or uint8 == 0x3E --[[ > ]] or html_space[ uint8 ] then
            return end_start
        end

        position = end_name + 1
        goto raw_loop
    end

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
    ---@return dreamwork.std.HTMLNode document The document node, with the elements as children.
    ---@nodiscard
    function HTMLNodeClass.fromString( html_str, keep_whitespace )
        keep_whitespace = keep_whitespace == true

        local html_length = string_len( html_str )

        ---@type string | nil
        local html_lower

        local document = HTMLNodeClass( "#document", nil, nil )

        local active = document

        local preserve = keep_whitespace

        ---@type table<dreamwork.std.HTMLNode, boolean>
        local preserving = {}

        ---@type table<dreamwork.std.HTMLNode, boolean>
        local foreign = {}

        local position = 1

        -- UTF-8 BOM
        local bom_1, bom_2, bom_3 = string_byte( html_str, 1, 3 )
        if bom_1 == 0xEF and bom_2 == 0xBB and bom_3 == 0xBF then
            position = 4
        end

        -- start of the pending text, a `<` that starts no markup is text too
        local text_start = position

        ::parse_loop::

        local tag_start = string_find( html_str, "<", position, true )
        if tag_start == nil then
            if text_start <= html_length then
                parse_text( active, html_str, text_start, html_length, preserve, true )
            end

            return document
        end

        local b1 = string_byte( html_str, tag_start + 1 )

        local is_markup = b1 == 0x21 --[[ ! ]] or b1 == 0x3F --[[ ? ]] or b1 == 0x2F --[[ / ]] or
            (b1 ~= nil and ((b1 >= 0x41 and b1 <= 0x5A) or (b1 >= 0x61 and b1 <= 0x7A)))

        if not is_markup then
            position = tag_start + 1
            goto parse_loop
        end

        if text_start < tag_start then
            local closing = b1 == 0x2F --[[ / ]]

            -- a start tag that implicitly closes the active element ends its text too
            if not closing and b1 ~= 0x21 --[[ ! ]] and b1 ~= 0x3F --[[ ? ]] and not preserve then
                local closes = html_closes[ string_lower( string_match( html_str, "^[^%s/>]+", tag_start + 1 ) ) ]
                closing = closes ~= nil and closes[ active.name ] == true
            end

            parse_text( active, html_str, text_start, tag_start - 1, preserve, closing )
        end

        do

            -- end of the markup, the parse continues after it
            local markup_end

            if b1 == 0x21 --[[ ! ]] then
                local b2, b3 = string_byte( html_str, tag_start + 2, tag_start + 3 )

                if b2 == 0x2D --[[ - ]] and b3 == 0x2D --[[ - ]] then
                    -- comment
                    local _, comment_end = string_find( html_str, "-->", tag_start + 2, true )
                    markup_end = comment_end or html_length
                else
                    html_lower = html_lower or string_lower( html_str )

                    if string_sub( html_lower, tag_start, tag_start + 8 ) == "<!doctype" then
                        local doctype_end = string_find( html_str, ">", tag_start + 9, true ) or (html_length + 1)
                        document.doctype = string_match( string_sub( html_str, tag_start + 9, doctype_end - 1 ), "^%s*(.-)%s*$" )
                        markup_end = doctype_end
                    elseif string_sub( html_str, tag_start, tag_start + 8 ) == "<![CDATA[" then
                        local cdata_start, cdata_end = string_find( html_str, "]]>", tag_start + 9, true )

                        -- CDATA is text in `svg` and `math`, a bogus comment otherwise
                        if foreign[ active ] and (cdata_start == nil or cdata_start > tag_start + 9) then
                            html_append_text( active, string_sub( html_str, tag_start + 9, (cdata_start or (html_length + 1)) - 1 ) )
                        end

                        markup_end = cdata_end or html_length
                    else
                        -- bogus comment
                        markup_end = string_find( html_str, ">", tag_start + 2, true ) or html_length
                    end
                end
            elseif b1 == 0x3F --[[ ? ]] then
                -- processing instruction, a bogus comment in HTML
                markup_end = string_find( html_str, ">", tag_start + 2, true ) or html_length
            elseif b1 == 0x2F --[[ / ]] then
                local _, name_end, tag_name = string_find( html_str, "^([%a][^%s/>]*)", tag_start + 2 )
                if name_end == nil then
                    -- `</>` is ignored, anything else is a bogus comment
                    markup_end = string_find( html_str, ">", tag_start + 2, true ) or html_length
                else
                    local tag_end = string_find( html_str, ">", name_end + 1, true )
                    if tag_end == nil then
                        return document
                    end

                    markup_end = tag_end

                    local name = string_lower( tag_name )

                    -- the nearest open element closes all elements opened after it, stray end tags are ignored
                    local node = active
                    while node ~= document do
                        if node.name == name or (foreign[ node ] and string_lower( node.name ) == name) then
                            active = node.parent
                            preserve = keep_whitespace or preserving[ active ] == true
                            break
                        end

                        node = node.parent
                    end
                end
            else
                local _, name_end, tag_name = string_find( html_str, "^([^%s/>]+)", tag_start + 1 )

                ---@type table<string, string> | nil
                local tag_attributes

                local self_closing = false
                local cursor = name_end + 1

                local name = string_lower( tag_name )
                local is_foreign = foreign[ active ] == true or name == "svg" or name == "math"

                ::attribute_loop::

                local _, skip_end = string_find( html_str, "^[%s/]*", cursor )
                self_closing = skip_end >= cursor and string_byte( html_str, skip_end ) == 0x2F --[[ / ]]
                cursor = skip_end + 1

                local uint8 = string_byte( html_str, cursor )
                if uint8 == nil then
                    -- the tag is not closed, it is dropped like in a browser
                    return document
                end

                if uint8 ~= 0x3E --[[ > ]] then
                    local _, attribute_end, attribute_name = string_find( html_str, "^([^%s/>][^%s/>=]*)", cursor )
                    ---@cast attribute_end integer

                    local attribute_value = ""
                    cursor = attribute_end + 1

                    local _, equals_end = string_find( html_str, "^%s*=%s*", cursor )
                    if equals_end ~= nil then
                        cursor = equals_end + 1

                        local quote = string_byte( html_str, cursor )
                        if quote == 0x22 --[[ " ]] or quote == 0x27 --[[ ' ]] then
                            local value_end = string_find( html_str, string_char( quote ), cursor + 1, true )
                            if value_end == nil then
                                return document
                            end

                            attribute_value = string_sub( html_str, cursor + 1, value_end - 1 )
                            cursor = value_end + 1
                        else
                            local _, value_end = string_find( html_str, "^[^%s>]*", cursor )
                            attribute_value = string_sub( html_str, cursor, value_end )
                            cursor = value_end + 1
                        end

                        attribute_value = decode_entities( attribute_value )
                    end

                    if not is_foreign then
                        attribute_name = string_lower( attribute_name )
                    end

                    if tag_attributes == nil then
                        tag_attributes = { [ attribute_name ] = attribute_value }
                    elseif tag_attributes[ attribute_name ] == nil then
                        -- the first of duplicate attributes wins
                        tag_attributes[ attribute_name ] = attribute_value
                    end

                    goto attribute_loop
                end

                markup_end = cursor


                if foreign[ active ] then
                    name = tag_name
                elseif not is_foreign then
                    local closes = html_closes[ name ]
                    if closes ~= nil then
                        while active ~= nil and closes[ active.name ] do
                            active = active.parent
                        end
                    end
                end

                local node = HTMLNodeClass( name, tag_attributes, active )

                if is_foreign then
                    foreign[ node ] = true

                    if not self_closing then
                        active = node

                        if preserve then
                            preserving[ node ] = true
                        end
                    end
                elseif html_void[ name ] then
                    -- no children, no end tag
                elseif html_raw[ name ] ~= nil then
                    html_lower = html_lower or string_lower( html_str )

                    local content_start = markup_end + 1

                    -- a line break right after the start tag is not content
                    if name == "textarea" then
                        if string_byte( html_str, content_start ) == 0x0D --[[ \r ]] then
                            content_start = content_start + 1
                        end

                        if string_byte( html_str, content_start ) == 0x0A --[[ \n ]] then
                            content_start = content_start + 1
                        end
                    end

                    local content_end
                    if name == "plaintext" then
                        content_end = html_length + 1
                        markup_end = html_length
                    else
                        content_end = find_raw_end( html_lower, name, content_start )
                        if content_end == nil then
                            content_end = html_length + 1
                            markup_end = html_length
                        else
                            markup_end = string_find( html_str, ">", content_end + 2, true ) or html_length
                        end
                    end

                    if content_end > content_start then
                        local content = string_sub( html_str, content_start, content_end - 1 )

                        if html_raw[ name ] then
                            content = decode_entities( content )
                        end

                        node.children = { content }
                    end
                else
                    active = node

                    if preserve or html_preformatted[ name ] then
                        preserving[ node ] = true
                        preserve = true
                    end

                    -- a line break right after the start tag is not content
                    if name == "pre" or name == "listing" then
                        if string_byte( html_str, markup_end + 1 ) == 0x0D --[[ \r ]] then
                            markup_end = markup_end + 1
                        end

                        if string_byte( html_str, markup_end + 1 ) == 0x0A --[[ \n ]] then
                            markup_end = markup_end + 1
                        end
                    end
                end
            end

            position = markup_end + 1
            text_start = position
        end

        ---@diagnostic disable-next-line: missing-return
        goto parse_loop
    end

    --- [SHARED AND MENU]
    ---
    --- Creates an empty HTML5 document with `html`, `head` (with UTF-8 charset and optional title) and `body` elements.
    ---
    ---@param title string? The title of the document.
    ---@return dreamwork.std.HTMLNode document The document node.
    ---@nodiscard
    function HTMLNodeClass.createDocument( title )
        local document = HTMLNodeClass( "#document", nil, nil )
        document.doctype = "html"

        local html = HTMLNodeClass( "html", nil, document )

        local head = HTMLNodeClass( "head", nil, html )
        HTMLNodeClass( "meta", { charset = "utf-8" }, head )

        if title ~= nil then
            HTMLNodeClass( "title", nil, head ):setText( title )
        end

        HTMLNodeClass( "body", nil, html )

        return document
    end

end
