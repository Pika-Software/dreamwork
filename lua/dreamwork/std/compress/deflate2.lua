--[[
    Based heavily on sdefl
    https://github.com/fxfactorial/sdefl
--]]

---@class dreamwork.std
local std = _G.dreamwork.std

---@class dreamwork.std.deflate2
local deflate2 = std.deflate2 or {}
std.deflate2 = deflate2

local bit = std.bit

local SDEFL_MAX_OFF = bit.lshift( 1, 20 )
local SDEFL_WIN_SIZ = SDEFL_MAX_OFF
local SDEFL_WIN_MSK = SDEFL_WIN_SIZ - 1

local SDEFL_MIN_MATCH = 4
local SDEFL_MAX_MATCH = 258

local SDEFL_HASH_BITS = 20 -- Was 19 originally
local SDEFL_HASH_SIZ = bit.lshift( 1, SDEFL_HASH_BITS )
local SDEFL_NIL = -1

local SDEFL_LVL_MIN = 0
local SDEFL_LVL_DEF = 5
local SDEFL_LVL_MAX = 8

deflate2.lvl_min = SDEFL_LVL_MIN
deflate2.lvl_def = SDEFL_LVL_DEF
deflate2.lvl_max = SDEFL_LVL_MAX

local max = std.math.max
local floor = std.math.floor

---@class dreamwork.std.deflate2.sdefl
---@field bits integer
---@field cnt integer
---@field tbl integer[] Size is `SDEFL_HASH_SIZ`
---@field prv integer[] #Size is `SDEFL_WIN_SIZ`

---@param dest integer[]
---@param src integer[]
local function addTable( dest, src )
    local len = #dest

    for i = 1, #src do
        dest[ len + i ] = src[ i ]
    end
end

---@param n integer
local function r2( n )
    return { n, n + 128, n + 64, n + 192 }
end

---@param n integer
local function r4( n )
    local tab1 = r2( n )
    local tab2 = r2( n + 32 )
    local tab3 = r2( n + 16 )
    local tab4 = r2( n + 48 )

    local output = {}
    addTable( output, tab1 )
    addTable( output, tab2 )
    addTable( output, tab3 )
    addTable( output, tab4 )
    return output
end

---@param n integer
local function r6( n )
    local tab1 = r4( n )
    local tab2 = r4( n + 8 )
    local tab3 = r4( n + 4 )
    local tab4 = r4( n + 12 )

    local output = {}
    addTable( output, tab1 )
    addTable( output, tab2 )
    addTable( output, tab3 )
    addTable( output, tab4 )
    return output
end

---@type integer[]
local sdeflMirror = {}

addTable( sdeflMirror, r6( 0 ) )
addTable( sdeflMirror, r6( 2 ) )
addTable( sdeflMirror, r6( 1 ) )
addTable( sdeflMirror, r6( 3 ) )

sdeflMirror[ 0 ] = std.table.remove( sdeflMirror, 1 )

local byte = std.string.byte

local function getByte( str, index, lastIndex )
    return byte( str, index + 1, lastIndex and lastIndex + 1 or nil )
end

do
    local ceil = std.math.ceil
    local log2 = std.math.log2

    ---@param n integer
    local function sdeflNPow2( n )
        return 2 ^ ceil( log2( n ) )
    end

    ---@param n integer
    local function sdeflILog2( n )
        return floor( log2( n ) )
    end

    local bor = bit.bor
    local lshift = bit.lshift

    ---String variant
    ---@param str string
    ---@param index integer
    local function sdeflULoad32Str( str, index )
        local val1, val2, val3, val4 = getByte( str, index, index + 3 )

        ---In case of unaligned read set 0 as default
        return val1 * 16777216 + (val2 or 0) * 65536 + (val3 or 0) * 256 + (val4 or 0)
    end

    local rshift = bit.rshift

    ---@param str string
    ---@param index integer
    local function sdeflHash32Str( str, index )
        local n = sdeflULoad32Str( str, index )

        return rshift( n * 0x9E377989, 32 - SDEFL_HASH_BITS )
    end

    local char = std.string.char

    ---No string variant :(
    ---@param dstTab string[]
    ---@param dstIndex integer
    ---@param sdefl dreamwork.std.deflate2.sdefl
    ---@param code integer
    ---@param bitCnt integer
    ---@return integer
    local function sdeflPutTab( dstTab, dstIndex, sdefl, code, bitCnt )
        sdefl.bits = bor( sdefl.bits, lshift( code, sdefl.cnt ) )
        sdefl.cnt = sdefl.cnt + bitCnt

        local cnt = sdefl.cnt
        while cnt >= 8 do
            dstTab[ dstIndex ] = char( sdefl.bits % 256 )
            dstIndex = dstIndex + 1

            sdefl.bits = rshift( sdefl.bits, 8 )
            cnt = cnt - 8
        end

        sdefl.cnt = cnt

        return dstIndex
    end

    local lxmin = { [ 0 ] = 0, 11, 19, 35, 67, 131 }
    local dxmax = { [ 0 ] = 0, 6, 12, 24, 48, 96, 192, 384, 768, 1536, 3072, 6144, 12288, 24576 }
    local lmin = { [ 0 ] = 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227 }
    local dmin = {
        [ 0 ] = 1,
        2,
        3,
        4,
        5,
        7,
        9,
        13,
        17,
        25,
        33,
        49,
        65,
        97,
        129,
        193,
        257,
        385,
        513,
        769,
        1025,
        1537,
        2049,
        3073,
        4097,
        6145,
        8193,
        12289,
        16385,
        24577,
    }

    ---@param dst integer[]
    ---@param dstIndex integer
    ---@param sdefl dreamwork.std.deflate2.sdefl
    ---@param dist integer
    ---@param len integer
    local function sdeflMatchTab( dst, dstIndex, sdefl, dist, len )
        local lc = len
        local lx = sdeflILog2( len - 3 ) - 2

        lx = max( 0, lx )
        if lx == 0 then
            lc = lc + 254
        elseif len >= 258 then
            lx = 0
            lc = 285
        else
            lc = lshift( lx - 1, 2 ) + 265 + rshift( len - lxmin[ lx ], lx )
        end

        if lc <= 279 then
            dstIndex = sdeflPutTab( dst, dstIndex, sdefl, sdeflMirror[ lshift( lc - 256, 1 ) ], 7 )
        else
            dstIndex = sdeflPutTab( dst, dstIndex, sdefl, sdeflMirror[ 0xc0 - 280 + lc ], 8 )
        end

        if lx ~= 0 then
            dstIndex = sdeflPutTab( dst, dstIndex, sdefl, len - lmin[ lc - 265 ], lx )
        end

        ---Distance encoding? :/
        do
            local dc = dist - 1
            local dx = sdeflILog2( rshift( sdeflNPow2( dist ), 2 ) )

            dx = max( 0, dx )

            if dx ~= 0 then
                dc = lshift( dx + 1, 1 ) + (dist > dxmax[ dx ] and 1 or 0)
            end

            dstIndex = sdeflPutTab( dst, dstIndex, sdefl, sdeflMirror[ lshift( dc, 3 ) ], 5 )

            if dx ~= 0 then
                dstIndex = sdeflPutTab( dst, dstIndex, sdefl, dist - dmin[ dc ], dx )
            end
        end

        return dstIndex
    end

    ---@param dst integer[]
    ---@param dstIndex integer
    ---@param sdefl dreamwork.std.deflate2.sdefl
    ---@param c integer
    local function sdeflLitTab( dst, dstIndex, sdefl, c )
        if c <= 143 then
            return sdeflPutTab( dst, dstIndex, sdefl, sdeflMirror[ 0x30 + c ], 8 )
        end

        return sdeflPutTab( dst, dstIndex, sdefl, 1 + 2 * sdeflMirror[ 0x90 - 144 + c ], 9 )
    end

    local min = std.math.min
    local clamp = std.math.clamp
    local concat = std.table.concat

    ---@param inStr string
    ---@param lvl integer?
    function deflate2.compress( inStr, lvl )
        lvl = clamp( lvl or deflate2.lvl_def, deflate2.lvl_min, deflate2.lvl_max )

        ---@type dreamwork.std.deflate2.sdefl
        local sdefl = {
            bits = 0,
            cnt = 0,
            prv = {},
            tbl = {},
        }

        ---@type string[]
        local out = {}

        local inLen = #inStr

        local p = 0
        local maxChain = lvl < 8 and lshift( 1, (lvl + 1) ) or lshift( 1, 13 )

        local q = 0 -- Index!!!!
        ---Q is index, out is table

        sdefl.bits = 0
        sdefl.cnt = 0

        for i = 0, SDEFL_HASH_SIZ - 1 do
            sdefl.tbl[ i ] = SDEFL_NIL
        end

        q = sdeflPutTab( out, q, sdefl, 0x01, 1 )
        q = sdeflPutTab( out, q, sdefl, 0x01, 2 )

        while p < inLen do
            local run, bestLen = 0, 0
            local dist = 0

            local maxMatch = min( inLen - p, SDEFL_MAX_MATCH )

            if maxMatch > SDEFL_MIN_MATCH then
                local limit = max( SDEFL_NIL, p - SDEFL_WIN_SIZ )
                local chainLen = maxChain

                local i = sdefl.tbl[ sdeflHash32Str( inStr, p ) ]
                while i > limit do
                    if
                        getByte( inStr, i + bestLen ) == getByte( inStr, p + bestLen )
                        and (sdeflULoad32Str( inStr, i ) == sdeflULoad32Str( inStr, p ))
                    then
                        local n = SDEFL_MIN_MATCH
                        while n < maxMatch and getByte( inStr, i + n ) == getByte( inStr, p + n ) do
                            n = n + 1
                        end

                        if n > bestLen then
                            bestLen = n
                            dist = p - i

                            if n == maxMatch then
                                break
                            end
                        end
                    end

                    chainLen = chainLen - 1

                    if chainLen == 0 then
                        break
                    end

                    i = sdefl.prv[ i % SDEFL_WIN_MSK ]
                end
            end

            if lvl >= 5 and bestLen >= SDEFL_MIN_MATCH and bestLen < maxMatch then
                local x = p + 1
                local tarLen = bestLen + 1
                local limit = max( SDEFL_NIL, x - SDEFL_WIN_SIZ )
                local chainLen = maxChain
                local i = sdefl.tbl[ sdeflHash32Str( inStr, p ) ]
                while i > limit do
                    if
                        getByte( inStr, i + bestLen ) == getByte( inStr, x + bestLen )
                        and sdeflULoad32Str( inStr, i ) == sdeflULoad32Str( inStr, x )
                    then
                        local n = SDEFL_MIN_MATCH
                        while n < tarLen and getByte( inStr, i + n ) == getByte( inStr, x + n ) do
                            n = n + 1
                        end

                        if n == tarLen then
                            bestLen = 0
                            break
                        end
                    end

                    chainLen = chainLen - 1

                    if chainLen == 0 then
                        break
                    end

                    i = sdefl.prv[ i % SDEFL_WIN_MSK ]
                end
            end

            if bestLen >= SDEFL_MIN_MATCH then
                q = sdeflMatchTab( out, q, sdefl, dist, bestLen )
                run = bestLen
            else
                q = sdeflLitTab( out, q, sdefl, getByte( inStr, p ) )
                run = 1
            end

            while run ~= 0 do
                run = run - 1

                local h = sdeflHash32Str( inStr, p )
                sdefl.prv[ p % SDEFL_WIN_MSK ] = sdefl.tbl[ h ]
                sdefl.tbl[ h ] = p
                p = p + 1
            end

            run = run - 1 -- Fuck C
        end

        q = sdeflPutTab( out, q, sdefl, 0, 7 )
        q = sdeflPutTab( out, q, sdefl, 2, 10 )
        q = sdeflPutTab( out, q, sdefl, 2, 3 )

        return concat( out, "", 0 )
    end
end

---@class dreamwork.std.deflate2.sinfl
---@field bits integer
---@field bitcnt integer
---@field lits integer[] #unsigned
---@field dsts integer[] #unsigned
---@field lens integer[] #unsigned
---@field tlit integer
---@field tdist integer
---@field tlen integer

do
    local band = bit.band
    local bor = bit.bor
    local rshift = bit.rshift
    local lshift = bit.lshift

    ---srcIndex will be returned since it's mutable
    ---@param srcStr string
    ---@param srcIndex integer
    ---@param endIndex integer
    ---@param sinfl dreamwork.std.deflate2.sinfl
    ---@param n integer
    ---@return integer new bits???
    ---@return integer new value of srcIndex, since its muted in process
    local function sinflGetStr( srcStr, srcIndex, endIndex, sinfl, n )
        local inIndex = srcIndex
        local v = band( sinfl.bits, 2 ^ n - 1 )

        sinfl.bits = rshift( sinfl.bits, n )
        sinfl.bitcnt = sinfl.bitcnt - n
        sinfl.bitcnt = max( sinfl.bitcnt, 0 )

        while sinfl.bitcnt < 16 and inIndex < endIndex do
            sinfl.bits = bor( sinfl.bits, lshift( getByte( srcStr, inIndex ), sinfl.bitcnt ) )
            inIndex = inIndex + 1
            sinfl.bitcnt = sinfl.bitcnt + 8
        end

        srcIndex = inIndex

        return v, srcIndex
    end

    local function toUnsigned( num )
        return num < 0 and num + 4294967296 or num
    end

    ---@param tree integer[] #unsigned
    ---@param lens integer[] #unsigned
    ---@param symcnt integer
    local function sinflBuildTab( tree, lens, lensIndex, symcnt )
        local cnt = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
        local first = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
        local codes = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }

        for n = 0, symcnt - 1 do
            local val = cnt[ lens[ n + lensIndex ] ]
            cnt[ lens[ n + lensIndex ] ] = val + 1
        end

        for n = 1, 15 do
            codes[ n ] = (codes[ n - 1 ] + cnt[ n - 1 ]) * 2
            first[ n ] = first[ n - 1 ] + cnt[ n - 1 ]
        end

        for n = 0, symcnt - 1 do
            local len = lens[ n + lensIndex ]
            if len ~= 0 then
                local code = codes[ len ]
                codes[ len ] = code + 1

                local slot = first[ len ]
                first[ len ] = slot + 1

                tree[ slot ] = toUnsigned( bor( lshift( code, 32 - len ), n * 16, len ) )
            end
        end

        return first[ 15 ]
    end

    local function sinflRev16( n )
        return bor( lshift( sdeflMirror[ band( n, 0xff ) ], 8 ), sdeflMirror[ band( rshift( n, 8 ), 0xff ) ] )
    end

    ---So `_` wont be global
    local _

    ---@param inStr string
    ---@param inIndex integer
    ---@param endIndex integer
    ---@param sinfl dreamwork.std.deflate2.sinfl
    ---@param tree integer[]
    ---@param maxx integer
    ---@return integer
    ---@return integer #New inIndex
    local function sinflDecode( inStr, inIndex, endIndex, sinfl, tree, maxx )
        local lo = 0
        local hi = toUnsigned( maxx )

        local search = toUnsigned( bor( lshift( sinflRev16( sinfl.bits ), 16 ), 0xffff ) )
        while lo < hi do
            local guess = floor( (lo + hi) / 2 )
            if search < tree[ guess ] then
                hi = guess
            else
                lo = guess + 1
            end
        end

        local key = tree[ lo - 1 ]
        _, inIndex = sinflGetStr( inStr, inIndex, endIndex, sinfl, band( key, 0x0f ) )

        return band( rshift( key, 4 ), 0x0fff ), inIndex
    end

    local order = { [ 0 ] = 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }
    local dbase = {
        [ 0 ] = 1,
        2,
        3,
        4,
        5,
        7,
        9,
        13,
        17,
        25,
        33,
        49,
        65,
        97,
        129,
        193,
        257,
        385,
        513,
        769,
        1025,
        1537,
        2049,
        3073,
        4097,
        6145,
        8193,
        12289,
        16385,
        24577, --30th
        0,     --31th (Shoulda be random???)
        0,     --32th (Shoulda be random??)
    }

    local dbits = {
        [ 0 ] = 0,
        0,
        0,
        0,
        1,
        1,
        2,
        2,
        3,
        3,
        4,
        4,
        5,
        5,
        6,
        6,
        7,
        7,
        8,
        8,
        9,
        9,
        10,
        10,
        11,
        11,
        12,
        12,
        13,
        13,
        0,
        0,
    }

    local lbase = {
        [ 0 ] = 3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        13,
        15,
        17,
        19,
        23,
        27,
        31,
        35,
        43,
        51,
        59,
        67,
        83,
        99,
        115,
        131,
        163,
        195,
        227,
        258,
        0,
        0,
    }

    local lbits = {
        [ 0 ] = 0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        1,
        1,
        1,
        2,
        2,
        2,
        2,
        3,
        3,
        3,
        3,
        4,
        4,
        4,
        4,
        5,
        5,
        5,
        5,
        0,
        0,
        0,
    }

    local HDR = 0
    local STORED = 1
    local FIXED = 2
    local DYNAMIC = 3
    local BLK = 4

    ---@alias dreamwork.std.deflate2.sinfl_states
    ---| `HDR`
    ---| `STORED`
    ---| `FIXED`
    ---| `DYNAMIC`
    ---| `BLK`

    local concat = std.table.concat
    local sub = std.string.sub

    local function createLens()
        return {
            [ 0 ] = 8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
        }
    end

    local char = std.string.char

    ---@param inStr string
    ---@return string
    function deflate2.decompress( inStr )
        local size = #inStr
        local inIndex = 0
        ---@type string[]
        local out = {}

        local e = inIndex + size -- End index
        local o = 0              -- o = index, out it tbl

        ---@type dreamwork.std.deflate2.sinfl_states
        local state = HDR

        ---Imagine the guy using memset(&s, 0, sizeof(s)) while i have to manually set all those zeroes in struct
        ---@type dreamwork.std.deflate2.sinfl
        local sinfl = {
            bitcnt = 0,
            bits = 0,
            lits = {
                [ 0 ] = 0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            },
            dsts = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            lens = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            tlit = 0,
            tdist = 0,
            tlen = 0,
        }
        local last = 0

        _, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 0 )

        while inIndex < e or sinfl.bitcnt ~= 0 do
            if state == HDR then --Header
                local type = 0
                last, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 1 )
                type, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 2 )

                if type == 0x00 then
                    state = STORED
                elseif type == 0x01 then
                    state = FIXED
                elseif type == 0x02 then
                    state = DYNAMIC
                else
                    return concat( out, "", 0 )
                end
            elseif state == STORED then --Uncompressed
                local len = 0
                _, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, band( sinfl.bitcnt, 7 ) )
                len, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 16 )
                _, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 16 )
                inIndex = inIndex - 2
                sinfl.bitcnt = 0

                if len > (e - inIndex) or len == 0 then
                    return concat( out, "" )
                end

                out[ o ] = sub( inStr, inIndex + 1, inIndex + len )
                inIndex = inIndex + len
                o = o + 1
                state = HDR
            elseif state == FIXED then
                local lens = createLens()

                sinfl.tlit = sinflBuildTab( sinfl.lits, lens, 0, 288 )
                sinfl.tdist = sinflBuildTab( sinfl.dsts, lens, 288, 32 )

                state = BLK
            elseif state == DYNAMIC then
                local nlit, ndist, nlen
                local nlens = { [ 0 ] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
                local lens = createLens() -- even though we will eventually
                --replace all the values here, it's still be faster due to pre-allocation

                for i = 0, 319 do
                    lens[ i ] = 0
                end

                nlit, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 5 )
                nlit = nlit + 257

                ndist, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 5 )
                ndist = ndist + 1

                nlen, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 4 )
                nlen = nlen + 4

                for n = 0, nlen - 1 do
                    local value
                    value, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 3 )
                    nlens[ order[ n ] ] = value
                end

                sinfl.tlen = sinflBuildTab( sinfl.lens, nlens, 0, 19 )

                local n = 0
                while n < nlit + ndist do
                    local sym
                    sym, inIndex = sinflDecode( inStr, inIndex, e, sinfl, sinfl.lens, sinfl.tlen )
                    if sym == 16 then
                        local start = 0
                        start, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 2 )

                        for _ = 3 + start, 1, -1 do
                            lens[ n ] = lens[ n - 1 ]
                            n = n + 1
                        end
                    elseif sym == 17 then
                        local start = 0
                        start, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 3 )

                        for _ = 3 + start, 1, -1 do
                            lens[ n ] = 0
                            n = n + 1
                        end
                    elseif sym == 18 then
                        local start = 0
                        start, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, 7 )

                        for _ = 11 + start, 1, -1 do
                            lens[ n ] = 0
                            n = n + 1
                        end
                    else
                        lens[ n ] = band( sym, 0xff )
                        n = n + 1
                    end
                end

                sinfl.tlit = sinflBuildTab( sinfl.lits, lens, 0, nlit )
                sinfl.tdist = sinflBuildTab( sinfl.dsts, lens, nlit, ndist )

                state = BLK
            elseif state == BLK then
                local sym
                sym, inIndex = sinflDecode( inStr, inIndex, e, sinfl, sinfl.lits, sinfl.tlit )

                if sym > 256 then
                    sym = sym - 257
                    do
                        local len
                        len, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, lbits[ sym ] )
                        len = len + lbase[ sym ]

                        local dsym
                        dsym, inIndex = sinflDecode( inStr, inIndex, e, sinfl, sinfl.dsts, sinfl.tdist )

                        local offs
                        offs, inIndex = sinflGetStr( inStr, inIndex, e, sinfl, dbits[ dsym ] )
                        offs = offs + dbase[ dsym ]

                        if offs > o then
                            return concat( out, "", 0 )
                        end

                        while len > 0 do
                            len = len - 1
                            out[ o ] = out[ o - offs ]
                            o = o + 1
                        end
                    end
                elseif sym == 256 then
                    if last ~= 0 then
                        return concat( out, "", 0 )
                    end

                    state = HDR
                else
                    out[ o ] = char( sym )
                    o = o + 1
                end
            end
        end

        return concat( out, "", 0 )
    end
end
