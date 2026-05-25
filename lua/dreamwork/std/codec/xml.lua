---@class dreamwork.std
local std = dreamwork.std

local tostring = std.tostring
local isTable = std.isTable
local len = std.len
local gc = std.gc

local table = std.table
local table_concat = table.concat

local string = std.string
local string_len, string_rep = string.len, string.rep
local string_char, string_byte = string.char, string.byte
local string_find, string_format = string.find, string.format
local string_isSpace, string_sub = string.isSpace, string.sub
local string_trim, string_isEmpty = string.trim, string.isEmpty
local string_match, string_gmatch = string.match, string.gmatch

local raw = std.raw
local raw_next = raw.next
local raw_pairs = raw.pairs
local raw_tonumber = raw.tonumber

local Stack = std.Stack

---@class dreamwork.std.xml
local xml = std.xml or {}
std.xml = xml

do

    local table_isSequential = table.isSequential

    local function isTableEmpty( tbl )
        local key = raw_next( tbl, nil )
        return key == nil or (key == "_attr" and raw_next( tbl, key ) == nil)
    end

    local function indent( level, pretty )
        if pretty then
            return string_rep( " ", level * 2 )
        end

        return ""
    end

    local function attributes_format( attributes )
        if attributes == nil then
            return ""
        end

        local lines, line_count = {}, 0

        for k, v in raw_pairs( attributes ) do
            line_count = line_count + 1
            lines[ line_count ] = string_format( " %s=\"%s\"", k, v )
        end

        return table_concat( lines, "", 1, line_count )
    end

    local function value_format( name, value, attributes, level, pretty )
        if value == "" then
            return string_format( "%s<%s%s/>", indent( level, pretty ), name, attributes_format( attributes ) )
        else
            return string_format( "%s<%s%s>%s</%s>", indent( level, pretty ), name, attributes_format( attributes ), value, name )
        end
    end

    local function parseTableToXml( lines, line_count, tbl, name, level, pretty )
        if name == "_attr" then
            return line_count
        end

        if isTable( tbl ) then
            if table_isSequential( tbl ) then
                for i = 1, len( tbl ), 1 do
                    line_count = parseTableToXml( lines, line_count, tbl[ i ], name, level, pretty )
                end
            elseif isTableEmpty( tbl ) then
                line_count = line_count + 1
                lines[ line_count ] = value_format( name, "", tbl._attr, level, pretty )
            else

                if name ~= nil then
                    line_count = line_count + 1
                    lines[ line_count ] = indent( level, pretty ) .. "<" .. name .. attributes_format( tbl._attr ) .. ">"
                end

                for key, value in raw_pairs( tbl ) do
                    line_count = parseTableToXml( lines, line_count, value, tostring( key ), level + 1, pretty )
                end

                if name ~= nil then
                    line_count = line_count + 1
                    lines[ line_count ] = indent( level, pretty ) .. "</" .. name .. ">"
                end

            end
        else
            line_count = line_count + 1
            lines[ line_count ] = value_format( name, tostring( tbl ), nil, level, pretty )
        end

        return line_count
    end

    function xml.serialize( tbl, pretty, name, level )
        local lines = {}

        local first_key, first_value = raw_next( tbl, nil )
        if first_key ~= nil then
            if raw_next( tbl, first_key ) == nil then
                if isTable( first_value ) then
                    first_key = tostring( first_key )
                    tbl = first_value
                else
                    first_key = "root"
                end
            else
                first_key = nil
            end
        end

        local line_count = parseTableToXml( lines, 0, tbl, name or first_key, level or 0, pretty )
        if line_count == 0 then
            return ""
        end

        if pretty then
            return table_concat( lines, "\n", 1, line_count )
        end

        return table_concat( lines, "", 1, line_count )
    end

end

-- local PI         = "<%?(.-)%?>"
-- local COMMENT    = "<!%-%-(.-)%-%->"
-- local LEADINGWS  = "^%s+"
-- local TRAILINGWS = "%s+$"

-- local DTD1       = "<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+[\"\'](.-)[\"\']%s*(%b[])%s*>"
-- local DTD2       = "<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+[\"\'](.-)[\"\']%s+[\"\'](.-)[\"\']%s*(%b[])%s*>"
-- local DTD3       = "<!DOCTYPE%s+(.-)%s+%[%s+.-%]>" -- Inline DTD Schema
-- local DTD4       = "<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+[\"\'](.-)[\"\']%s*>"
-- local DTD5       = "<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+[\"\'](.-)[\"\']%s+[\"\'](.-)[\"\']%s*>"
-- local DTD6       = "<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+[\"\'](.-)[\"\']%s*>"

-- local DTD_PATTERNS = { DTD1, DTD2, DTD3, DTD4, DTD5, DTD6 }


-- Matches an attribute with non-closing double quotes (The equal sign is matched non-greedly by using =+?)
local ATTRERR1      = "=+?%s*\"[^\"]*$"

-- Matches an attribute with non-closing single quotes (The equal sign is matched non-greedly by using =+?)
local ATTRERR2      = "=+?%s*\'[^\']*$"

-- Matches a closing tag such as </person> or the end of a openning tag such as <person>
local TAGEXT        = "(%/?)>"

local ERRORS        = {
    xmlErr = "Error Parsing XML",
    declErr = "Error Parsing XMLDecl",
    declStartErr = "XMLDecl not at start of document",
    declAttrErr = "Invalid XMLDecl attributes",
    piErr = "Error Parsing Processing Instruction",
    commentErr = "Error Parsing Comment",
    cdataErr = "Error Parsing CDATA",
    dtdErr = "Error Parsing DTD",
    endTagErr = "End Tag Attributes Invalid",
    unmatchedTagErr = "Unbalanced Tag",
    incompleteXmlErr = "Incomplete XML Document"
}

local entities      = {
    { "&lt;",   "<" },
    { "&gt;",   ">" },
    { "&amp;",  "&" },
    { "&quot;", "\"" },
    { "&apos;", "\'" },
    {
        "&#(%d+);",
        function( code )
            local integer = raw_tonumber( code )
            if integer >= 0 and integer < 256 then
                return string_char( integer )
            end

            return "&#" .. code .. ";"
        end
    },
    {
        "&#x(%x+);",
        function( code )
            local integer = raw_tonumber( code, 16 )
            if integer >= 0 and integer < 256 then
                return string_char( integer )
            end

            return "&#x" .. code .. ";"
        end
    }
}

local entitiy_count = #entities

local function parseEntities( str )
    for i = 1, entitiy_count, 1 do
        local data = entities[ i ]
        str = string.gsub( str, data[ 1 ], data[ 2 ] )
    end

    return str
end

local function err( message, level )
    error( string_format( "%s [char=%d]\n", message or "Parse Error", level ) )
end

---@class dreamwork.std.xml.Node : dreamwork.std.Object
---@field __class dreamwork.std.xml.NodeClass
local Node = std.class.base( "xml.Node", false )

---@class dreamwork.std.xml.NodeClass : dreamwork.std.xml.Node
---@field __base dreamwork.std.xml.Node
---@overload fun( name: string, attributes: table<string, string> | nil, parent: dreamwork.std.xml.Node | nil ): dreamwork.std.xml.Node
local NodeClass = std.class.create( Node )

---@type table<dreamwork.std.xml.Node, string>
local node_names = {}
gc.setTableRules( node_names, true )

---@type table<dreamwork.std.xml.Node, integer>
local node_sizes = {}
gc.setTableRules( node_sizes, true )

---@type table<dreamwork.std.xml.Node, table<string, string> | nil>
local node_attributes = {}
gc.setTableRules( node_attributes, true )

---@type table<dreamwork.std.xml.Node, dreamwork.std.xml.Node>
local node_parents = {}
gc.setTableRules( node_parents, true )

---@protected
function Node:__init( name, attributes, parent )
    node_names[ self ] = name
    node_sizes[ self ] = 0

    node_attributes[ self ] = attributes

    if parent ~= nil then
        node_parents[ self ] = parent

        -- local node = parent[ name ]
        -- if node ~= nil then
        --     local list = NodeClass( name, nil, parent )

        --     node_sizes[ ]

        --     parent[ name ] = list
        -- end

        -- local parent_size = ( node_sizes[ parent ] or 0 ) + 1
        -- parent[ parent_size ] = self
        -- node_sizes[ parent ] = parent_size

        parent[ name ] = self
    end
end

---@param xml_tag string
---@return string
---@return table<string, string> | nil
local function parseTag( xml_tag )
    local attributes

    if string_match( xml_tag, "([%w-:_]+)%s*=%s*[\'\"](.-)[\'\"]" ) ~= nil then
        ---@type table<string, string>
        attributes = {}

        for key, value in string_gmatch( xml_tag, "([%w-:_]+)%s*=%s*[\'\"](.-)[\'\"]" ) do
            attributes[ key ] = value
        end
    end

    return string_match( xml_tag, "^.-(%s.*)" ) or xml_tag, attributes
end

---@param nodes dreamwork.std.xml.Node[]
---@param tag_name string
---@param tag_attributes table<string, string> | nil
local function tree_starttag( nodes, tag_name, tag_attributes )
    local stack_size = nodes[ 0 ]
    local parent = nodes[ stack_size ]

    stack_size = stack_size + 1

    nodes[ stack_size ] = NodeClass( tag_name, tag_attributes, parent )
    -- if isTable( parent ) then
    -- else
    --     -- print( value )
    -- end

    nodes[ 0 ] = stack_size


    -- inserting a new one to nodes stack
end

---@param nodes dreamwork.std.xml.Node[]
---@param tag_name string
---@param xml_start integer
local function tree_endtag( nodes, tag_name, xml_start )
    local previous = nodes[ nodes[ 0 ] - 1 ]
    if previous[ tag_name ] == nil then
        error( "XML Error - Unmatched Tag [" .. xml_start .. ":" .. tag_name .. "]\n" )
    end

    -- nodes[ 1 ] allways must be the root
    -- if previous == nodes[ 1 ] then
    --     tree_reduce( previous )
    -- end

    local stack_size = nodes[ 0 ]
    nodes[ stack_size ] = nil
    nodes[ 0 ] = stack_size - 1
end

---@param nodes dreamwork.std.xml.Node[]
---@param text string
local function tree_text( nodes, text )
    local parent = nodes[ nodes[ 0 ] ]
    local parent_size = node_sizes[ parent ]

    if node_sizes[ parent ] ~= 0 then
        parent_size = parent_size + 1
        parent[ parent_size ] = text
        node_sizes[ parent ] = parent_size
        return
    end

    local name = node_names[ parent ]

    local value = parent[ name ]
    print( value, name )

    if value == nil then
        parent[ name ] = text
    elseif isTable( value ) then
        local current_size = (node_sizes[ value ] or 0) + 1
        value[ current_size ] = text
        node_sizes[ value ] = current_size
    else

        local new = NodeClass( name, node_attributes[ parent ], parent )

        new[ 1 ] = value
        new[ 2 ] = text

        node_sizes[ new ] = 2
        parent[ name ] = new

    end
end

---@param str string
---@param start_position integer
---@return string
---@return table<string, string> | nil
local function parse_tag( str, start_position )
    local tag_start, tag_end, tag_name = string_find( str, "^([%w-:_]+)", start_position, false )

    local attribute_start, attribute_end, attribute_key, attribute_value = string_find( str, "([%w-:_]+)%s*=%s*[\'\"](.-)[\'\"]", tag_end + 1 )
    if attribute_end == nil then
        return tag_name, nil
    end

    ---@type table<string, string>
    local tag_attributes = {
        [ attribute_key ] = attribute_value or ""
    }

    ::parse_attributes::

    attribute_start, attribute_end, attribute_key, attribute_value = string_find( str, "([%w-:_]+)%s*=%s*[\'\"](.-)[\'\"]", attribute_end + 1 )

    if attribute_end ~= nil then
        tag_attributes[ attribute_key ] = attribute_value or ""
        goto parse_attributes
    end

    return tag_name, tag_attributes
end

---@return table
function xml.deserialize( xml_str )
    ---@type string[]
    local tags = { [ 0 ] = 0 }

    local root = NodeClass( "root" )
    local nodes = { [ 0 ] = 1, root }

    ---@type integer
    local position = 1
    ::analyze_loop::

    local xml_start, xml_end, xml_content, xml_tag = string_find( xml_str, "^([^<]*)<([^>]-)>", position, false )
    if xml_start == nil or xml_end == nil then
        if string_match( xml_str, "^%s*$", position ) == nil then
            error( "XML parsing failed, no more tags." )
        elseif tags[ 0 ] ~= 0 then
            error( "XML parsing failed, incomplete XML." )
        end

        return root
    end

    if xml_content ~= nil then
        xml_start = xml_start + string_len( xml_content )
        xml_content = parseEntities( string_trim( xml_content, "%s" ) )

        if not string_isEmpty( xml_content ) then
            tree_text( nodes, xml_content )
        end
    end

    -- position = ( parseTagType( tags, nodes, xml_str, xml_start, xml_end, xml_tag or "", position ) or xml_end ) + 1

    print( xml_tag )

    local b1, b2, b3, b4,
    b5, b6, b7, b8 = string_byte( xml_tag, 1, 8 )

    local xml_start_with_slash = b1 == 0x2F --[[ / ]]
    if xml_start_with_slash then
        xml_tag = string.sub( xml_tag, 2 )
    end

    local xml_end_with_slash = string_byte( xml_tag, -1, -1 ) == 0x2F --[[ / ]]
    if xml_end_with_slash then
        xml_tag = string.sub( xml_tag, 1, -2 )
    end

    -- PI
    if b1 == 0x3F --[[ ? ]] then
        position = (xml_end or position) + 1
        goto analyze_loop
    end

    -- Comment
    if b1 == 0x21 --[[ ! ]] and b2 == 0x2D --[[ - ]] and b3 == 0x2D --[[ - ]] then
        position = (xml_end or position) + 1
        goto analyze_loop
    end

    -- DOCTYPE
    if b1 == 0x21 --[[ ! ]] and b2 == 0x44 --[[ D ]] and b3 == 0x4F --[[ O ]] and b4 == 0x43 --[[ C ]] and
        b5 == 0x54 --[[ T ]] and b6 == 0x59 --[[ Y ]] and b7 == 0x50 --[[ P ]] and b8 == 0x45 --[[ E ]] then
        position = (xml_end or position) + 1
        goto analyze_loop
    end

    -- CDATA
    if b1 == 0x21 --[[ ! ]] and b2 == 0x5B --[[ [ ]] and b3 == 0x43 --[[ C ]] and b4 == 0x44 --[[ D ]] and
        b5 == 0x41 --[[ A ]] and b6 == 0x54 --[[ T ]] and b7 == 0x41 --[[ A ]] and b8 == 0x5B --[[ [ ]] then

        local cdata_start, cdata_end, cdata_text = string_find( xml_str, "<%!%[CDATA%[(.-)%]%]>", position )
        if cdata_start == nil then
            err( ERRORS.cdataErr, position )
        end

        tree_text( nodes, cdata_text )

        position = (xml_end or position) + 1
        goto analyze_loop
    end

    -- XML Declaration
    if b1 == 0x3F --[[ ? ]] and b2 == 0x78 --[[ x ]] and b3 == 0x6D --[[ m ]] and b4 == 0x6C --[[ l ]] and string_isSpace( b5 ) then
        position = (xml_end or position) + 1
        goto analyze_loop
    end

    local extension_start, extension_end, extension_text
    local error_start, error_end

    ::validation_loop::

    -- If there isn't an attribute without closing quotes (single or double quotes)
    -- then breaks to follow the normal processing of the tag.
    -- Otherwise, try to find where the quotes close.

    error_start, error_end = string_find( xml_tag, ATTRERR1 )
    if error_end == nil then
        error_start, error_end = string_find( xml_tag, ATTRERR2 )
        if error_end == nil then
            goto validation_finished
        end
    end

    extension_start, extension_end, extension_text = string_find( xml_str, TAGEXT, xml_end + 1 )
    xml_tag = xml_tag .. string_sub( xml_str, xml_end, extension_end - 1 )

    if xml_start == nil then
        err( ERRORS.xmlErr, position )
    end

    ---@diagnostic disable-next-line: cast-local-type
    xml_end = extension_end
    goto validation_loop

    ::validation_finished::

    local tag_name, tag_attributes = parse_tag( xml_tag, 1 )
    local stack_size = tags[ 0 ]

    if xml_start_with_slash then
        if tag_attributes ~= nil then
            -- Shouldn't have any attributes in endtag
            err( string_format( "%s (/%s)", ERRORS.endTagErr, tag_name ), position )
        end

        local current = tags[ stack_size ]
        tags[ 0 ] = stack_size - 1
        tags[ stack_size ] = nil

        if current ~= tag_name then
            err( string_format( "%s (/%s)", ERRORS.unmatchedTagErr, tag_name ), position )
        end

        tree_endtag( nodes, tag_name, xml_start or 0 )

        position = (xml_end or position) + 1
        goto analyze_loop
    end

    stack_size = stack_size + 1
    tags[ stack_size ] = tag_name
    tags[ 0 ] = stack_size

    tree_starttag( nodes, tag_name, tag_attributes )

    -- />
    if xml_end_with_slash then
        tags[ stack_size ] = nil
        tags[ 0 ] = stack_size - 1

        tree_endtag( nodes, tag_name, xml_start or 0 )
    end

    position = (xml_end or position) + 1

    ---@diagnostic disable-next-line: missing-return
    goto analyze_loop
end

-- print( "\nFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCK" )

-- -- print( xml.serialize( { name = "test" }, true ) )

-- local t = xml.deserialize( [[
-- <?xml version="1.0" encoding="UTF-8"?>
-- <root>
--     <a>1</a>
--     <a>2</a>
--     <a>3</a>
--     <b>2</b>
--     <c>3</c>
-- </root>
-- ]] )

-- PrintTable( t )

-- std.futures.run( function()
--     -- local r = std.http.get( "https://steamcommunity.com/groups/thealium/memberslistxml/?xml=1" )

--     -- local t = xml.deserialize( r.body )
--     -- -- PrintTable( t )

--     -- print( t.memberList.groupDetails.avatarFull )

--     local r= std.http.get( "https://alium.p1ka.eu/index.xml" )

--     local t = xml.deserialize( r.body )

--     PrintTable( t )
-- end )

-- TODO: finish this :c
