local std = _G.dreamwork.std

---@class dreamwork.std.hash
local hash = std.hash

local bit = std.bit
local math = std.math
local string = std.string

local bit_bxor = bit.bxor
local bit_band, bit_bor = bit.band, bit.bor
local bit_lshift, bit_rshift = bit.lshift, bit.rshift

local string_len = string.len
local string_rep = string.rep
local string_format = string.format
local string_char, string_byte = string.char, string.byte

local math_floor = math.floor

local bytepack = std.pack.bytes
local bytepack_readUInt32 = bytepack.readUInt32
local bytepack_writeUInt32 = bytepack.writeUInt32

--- [SHARED AND MENU]
---
--- SHA1 object.
---
---@class dreamwork.std.hash.SHA1 : dreamwork.std.Object
---@field __class dreamwork.std.hash.SHA1Class
local SHA1 = std.class.base( "SHA1" )

---@alias SHA1 dreamwork.std.hash.SHA1

--- [SHARED AND MENU]
---
--- SHA1 class that computes a cryptographic 160-bit hash value.
---
--- Like other hash classes, it takes input data ( string )
--- and produces a digest ( string ) — a
--- fixed-size output string that represents that data.
---
--- **SHA1 is insecure**
---
--- Because of collision attacks,
--- attackers can find two different inputs
--- that produce the same hash.
---
--- This violates one of the basic principles
--- of a secure hash function - collision resistance.
---
---@class dreamwork.std.hash.SHA1Class : dreamwork.std.hash.SHA1
---@field __base dreamwork.std.hash.SHA1
---@field digest_size integer
---@field block_size integer
---@overload fun(): dreamwork.std.hash.SHA1
local SHA1Class = std.class.create( SHA1 )
hash.SHA1 = SHA1Class

SHA1Class.digest_size = 20
SHA1Class.block_size = 64

function SHA1:update( str )
    -- local str_length = string_len( str )

    -- local message_length = self.message_length + str_length
    -- self.message_length = message_length

    -- if message_length < 64 then
    --     self.message = self.message .. str
    -- else
    --     local message, position, blocks_size = self.message .. str, self.position, bucket64( message_length )

    --     local a, b, c, d = self.a, self.b, self.c, self.d

    --     for index = position + 1, blocks_size, 64 do
    --         a, b, c, d = transform( a, b, c, d, message, index )
    --     end

    --     self.a, self.b, self.c, self.d = a, b, c, d

    --     self.position = position + blocks_size
    --     self.message = message
    -- end

    -- return self
end

function SHA1:digest( as_hex )

    local position = self.position
    local message_length = self.message_length
    local remaining = message_length - position
    local padding = 64 - ( remaining + 9 )

    local bit_count = message_length * 8

    if message_length > 0x20000000 then
        bit_count = bit_count % 0x100000000
    end

    -- local B1, R1 = math.modf( bit_count / 0x01000000 )
    -- local B2, R2 = math.modf( 0x01000000 * R1 / 0x00010000)
    -- local B3, R3 = math.modf( 0x00010000 * R2 / 0x00000100)
    -- local B4     =            0x00000100 * R3


    local block = self.message .. "\128" .. string_rep( "\0", padding ) ..
        string_char( bytepack_writeUInt32( bit_count ) ) ..
        string_char( bytepack_writeUInt32( math_floor( message_length / 0x20000000 ) ) )

    -- local third_append = schar( uint32_to_bytes(#str * 8))

    -- str = str .. "\128" .. second_append .. "\0\0\0\0" .. third_append
end

-- TODO: implement (example: md5)

local engine_SHA1 = dreamwork.engine.SHA1

if engine_SHA1 == nil then

    -- TODO: implement (example: md5)

else

    local base16_decode = std.encoding.base16.decode

    --- [SHARED AND MENU]
    ---
    --- Computes the SHA1 digest of the given input string.
    ---
    --- This static method takes a string and returns its SHA1 hash as a hexadecimal string.
    --- Commonly used for checksums, data integrity validation, and password hashing.
    ---
    ---@param message string The message to compute SHA1 for.
    ---@param as_hex? boolean If true, the result will be a hex string.
    ---@return string str_result The SHA1 string of the message.
    function SHA1Class.digest( message, as_hex )
        local hex_str = engine_SHA1( message )
        if as_hex then
            return hex_str
        else
            return base16_decode( hex_str )
        end
    end

end


-- --
-- -- Return a W32 object for the number zero
-- --
-- local function ZERO()
--    return {
--       false, false, false, false,     false, false, false, false,
--       false, false, false, false,     false, false, false, false,
--       false, false, false, false,     false, false, false, false,
--       false, false, false, false,     false, false, false, false,
--    }
-- end

-- local hex_to_bits = {
--    ["0"] = { false, false, false, false },
--    ["1"] = { false, false, false, true  },
--    ["2"] = { false, false, true,  false },
--    ["3"] = { false, false, true,  true  },

--    ["4"] = { false, true,  false, false },
--    ["5"] = { false, true,  false, true  },
--    ["6"] = { false, true,  true,  false },
--    ["7"] = { false, true,  true,  true  },

--    ["8"] = { true,  false, false, false },
--    ["9"] = { true,  false, false, true  },
--    ["A"] = { true,  false, true,  false },
--    ["B"] = { true,  false, true,  true  },

--    ["C"] = { true,  true,  false, false },
--    ["D"] = { true,  true,  false, true  },
--    ["E"] = { true,  true,  true,  false },
--    ["F"] = { true,  true,  true,  true  },

--    ["a"] = { true,  false, true,  false },
--    ["b"] = { true,  false, true,  true  },
--    ["c"] = { true,  true,  false, false },
--    ["d"] = { true,  true,  false, true  },
--    ["e"] = { true,  true,  true,  false },
--    ["f"] = { true,  true,  true,  true  },
-- }

-- --
-- -- Given a string of 8 hex digits, return a W32 object representing that number
-- --
-- local function from_hex(hex)

--    assert(type(hex) == 'string')
--    assert(hex:match('^[0123456789abcdefABCDEF]+$'))
--    assert(#hex == 8)

--    local W32 = { }

--    for letter in hex:gmatch('.') do
--       local b = hex_to_bits[letter]
--       assert(b)
--       table.insert(W32, 1, b[1])
--       table.insert(W32, 1, b[2])
--       table.insert(W32, 1, b[3])
--       table.insert(W32, 1, b[4])
--    end

--    return W32
-- end

-- local function COPY(old)
--    local W32 = { }
--    for k,v in pairs(old) do
--       W32[k] = v
--    end

--    return W32
-- end

-- local function ADD(first, ...)

--    local a = COPY(first)

--    local C, b, sum

--    for v = 1, select('#', ...) do
--       b = select(v, ...)
--       C = 0

--       for i = 1, #a do
--          sum = (a[i] and 1 or 0)
--              + (b[i] and 1 or 0)
--              + C

--          if sum == 0 then
--             a[i] = false
--             C    = 0
--          elseif sum == 1 then
--             a[i] = true
--             C    = 0
--          elseif sum == 2 then
--             a[i] = false
--             C    = 1
--          else
--             a[i] = true
--             C    = 1
--          end
--       end
--       -- we drop any ending carry

--    end

--    return a
-- end

-- local function XOR(first, ...)

--    local a = COPY(first)
--    local b
--    for v = 1, select('#', ...) do
--       b = select(v, ...)
--       for i = 1, #a do
--          a[i] = a[i] ~= b[i]
--       end
--    end

--    return a

-- end

-- local function AND(a, b)

--    local c = ZERO()

--    for i = 1, #a do
--       -- only need to set true bits; other bits remain false
--       if  a[i] and b[i] then
--          c[i] = true
--       end
--    end

--    return c
-- end

-- local function OR(a, b)

--    local c = ZERO()

--    for i = 1, #a do
--       -- only need to set true bits; other bits remain false
--       if  a[i] or b[i] then
--          c[i] = true
--       end
--    end

--    return c
-- end

-- local function OR3(a, b, c)

--    local d = ZERO()

--    for i = 1, #a do
--       -- only need to set true bits; other bits remain false
--       if a[i] or b[i] or c[i] then
--          d[i] = true
--       end
--    end

--    return d
-- end

-- local function NOT(a)

--    local b = ZERO()

--    for i = 1, #a do
--       -- only need to set true bits; other bits remain false
--       if not a[i] then
--          b[i] = true
--       end
--    end

--    return b
-- end

-- local function ROTATE(bits, a)

--    local b = COPY(a)

--    while bits > 0 do
--       bits = bits - 1
--       table.insert(b, 1, table.remove(b))
--    end

--    return b

-- end


-- local binary_to_hex = {
--    ["0000"] = "0",
--    ["0001"] = "1",
--    ["0010"] = "2",
--    ["0011"] = "3",
--    ["0100"] = "4",
--    ["0101"] = "5",
--    ["0110"] = "6",
--    ["0111"] = "7",
--    ["1000"] = "8",
--    ["1001"] = "9",
--    ["1010"] = "a",
--    ["1011"] = "b",
--    ["1100"] = "c",
--    ["1101"] = "d",
--    ["1110"] = "e",
--    ["1111"] = "f",
-- }

-- local function asHEX(a)

--    local hex = ""
--    local i = 1
--    while i < #a do
--       local binary = (a[i + 3] and '1' or '0')
--                      ..
--                      (a[i + 2] and '1' or '0')
--                      ..
--                      (a[i + 1] and '1' or '0')
--                      ..
--                      (a[i + 0] and '1' or '0')

--       hex = binary_to_hex[binary] .. hex

--       i = i + 4
--    end

--    return hex

-- end

-- local x67452301 = from_hex("67452301")
-- local xEFCDAB89 = from_hex("EFCDAB89")
-- local x98BADCFE = from_hex("98BADCFE")
-- local x10325476 = from_hex("10325476")
-- local xC3D2E1F0 = from_hex("C3D2E1F0")

-- local x5A827999 = from_hex("5A827999")
-- local x6ED9EBA1 = from_hex("6ED9EBA1")
-- local x8F1BBCDC = from_hex("8F1BBCDC")
-- local xCA62C1D6 = from_hex("CA62C1D6")

-- local function sha1(msg)
--    assert( #msg < 0x7FFFFFFF) -- have no idea what would happen if it were large

--    local H0 = x67452301
--    local H1 = xEFCDAB89
--    local H2 = x98BADCFE
--    local H3 = x10325476
--    local H4 = xC3D2E1F0

--    local msg_len_in_bits = #msg * 8

--    local non_zero_message_bytes = #msg + 9
--    local current_mod = non_zero_message_bytes % 64

--    local second_append = ""
--    if current_mod ~= 0 then
--       second_append = string.rep(string.char(0), 64 - current_mod)
--    end

--    -- now to append the length as a 64-bit number.
--    local B1, R1 = math.modf(msg_len_in_bits  / 0x01000000)
--    local B2, R2 = math.modf( 0x01000000 * R1 / 0x00010000)
--    local B3, R3 = math.modf( 0x00010000 * R2 / 0x00000100)

--    msg = msg .. "\128" .. second_append .. "\0\0\0\0" .. string.char( B1, B2, B3, 0x00000100 * R3 )

--    assert(#msg % 64 == 0)

--    --local fd = io.open("/tmp/msg", "wb")
--    --fd:write(msg)
--    --fd:close()

--    local chunks = #msg / 64

--    local W = { }
--    local start, A, B, C, D, E, f, K, TEMP
--    local chunk = 0

--    while chunk < chunks do
--       --
--       -- break chunk up into W[0] through W[15]
--       --
--       start = chunk * 64 + 1
--       chunk = chunk + 1

--       for t = 0, 15, 1 do
--         W[t] = from_hex(string.format("%02x%02x%02x%02x", msg:byte(start, start + 3)))
--         start = start + 4
--       end

--       --
--       -- build W[16] through W[79]
--       --
--       for t = 16, 79 do
--          -- For t = 16 to 79 let Wt = S1(Wt-3 XOR Wt-8 XOR Wt-14 XOR Wt-16).
--          W[t] = ROTATE(1, XOR(W[t-3], W[t-8], W[t-14], W[t-16]))
--       end

--       A = H0
--       B = H1
--       C = H2
--       D = H3
--       E = H4

--       for t = 0, 79 do
--          if t <= 19 then
--             -- (B AND C) OR ((NOT B) AND D)
--             f = OR(AND(B, C), AND(NOT(B), D))
--             K = x5A827999
--          elseif t <= 39 then
--             -- B XOR C XOR D
--             f = XOR(B, C, D)
--             K = x6ED9EBA1
--          elseif t <= 59 then
--             -- (B AND C) OR (B AND D) OR (C AND D
--             f = OR3(AND(B, C), AND(B, D), AND(C, D))
--             K = x8F1BBCDC
--          else
--             -- B XOR C XOR D
--             f = XOR(B, C, D)
--             K = xCA62C1D6
--          end

--          -- TEMP = S5(A) + ft(B,C,D) + E + Wt + Kt;
--          TEMP = ADD(ROTATE(5, A), f, E, W[t], K)

--          --E = D; 　　D = C; 　　　C = S30(B);　　 B = A; 　　A = TEMP;
--          E = D
--          D = C
--          C = ROTATE(30, B)
--          B = A
--          A = TEMP

--          --printf("t = %2d: %s  %s  %s  %s  %s", t, A:HEX(), B:HEX(), C:HEX(), D:HEX(), E:HEX())
--       end

--       -- Let H0 = H0 + A, H1 = H1 + B, H2 = H2 + C, H3 = H3 + D, H4 = H4 + E.
--       H0 = ADD(H0, A)
--       H1 = ADD(H1, B)
--       H2 = ADD(H2, C)
--       H3 = ADD(H3, D)
--       H4 = ADD(H4, E)
--    end

--    return asHEX(H0) .. asHEX(H1) .. asHEX(H2) .. asHEX(H3) .. asHEX(H4)
-- end

-- local function hex_to_binary(hex)
--    return hex:gsub('..', function(hexval)
--                             return string.char(tonumber(hexval, 16))
--                          end)
-- end

-- local function sha1_binary(msg)
--    return hex_to_binary(sha1(msg))
-- end

-- local xor_with_0x5c = {
--    ["\0"] = "\92",   ["\1"] = "\93",
--    ["\2"] = "\94",   ["\3"] = "\95",
--    ["\4"] = "\88",   ["\5"] = "\89",
--    ["\6"] = "\90",   ["\7"] = "\91",
--    ["\8"] = "\84",   ["\9"] = "\85",
--    ["\10"] = "\86",   ["\11"] = "\87",
--    ["\12"] = "\80",   ["\13"] = "\81",
--    ["\14"] = "\82",   ["\15"] = "\83",
--    ["\16"] = "\76",   ["\17"] = "\77",
--    ["\18"] = "\78",   ["\19"] = "\79",
--    ["\20"] = "\72",   ["\21"] = "\73",
--    ["\22"] = "\74",   ["\23"] = "\75",
--    ["\24"] = "\68",   ["\25"] = "\69",
--    ["\26"] = "\70",   ["\27"] = "\71",
--    ["\28"] = "\64",   ["\29"] = "\65",
--    ["\30"] = "\66",   ["\31"] = "\67",
--    ["\32"] = "\124",   ["\33"] = "\125",
--    ["\34"] = "\126",   ["\35"] = "\127",
--    ["\36"] = "\120",   ["\37"] = "\121",
--    ["\38"] = "\122",   ["\39"] = "\123",
--    ["\40"] = "\116",   ["\41"] = "\117",
--    ["\42"] = "\118",   ["\43"] = "\119",
--    ["\44"] = "\112",   ["\45"] = "\113",
--    ["\46"] = "\114",   ["\47"] = "\115",
--    ["\48"] = "\108",   ["\49"] = "\109",
--    ["\50"] = "\110",   ["\51"] = "\111",
--    ["\52"] = "\104",   ["\53"] = "\105",
--    ["\54"] = "\106",   ["\55"] = "\107",
--    ["\56"] = "\100",   ["\57"] = "\101",
--    ["\58"] = "\102",   ["\59"] = "\103",
--    ["\60"] = "\96",   ["\61"] = "\97",
--    ["\62"] = "\98",   ["\63"] = "\99",
--    ["\64"] = "\28",   ["\65"] = "\29",
--    ["\66"] = "\30",   ["\67"] = "\31",
--    ["\68"] = "\24",   ["\69"] = "\25",
--    ["\70"] = "\26",   ["\71"] = "\27",
--    ["\72"] = "\20",   ["\73"] = "\21",
--    ["\74"] = "\22",   ["\75"] = "\23",
--    ["\76"] = "\16",   ["\77"] = "\17",
--    ["\78"] = "\18",   ["\79"] = "\19",
--    ["\80"] = "\12",   ["\81"] = "\13",
--    ["\82"] = "\14",   ["\83"] = "\15",
--    ["\84"] = "\8",   ["\85"] = "\9",
--    ["\86"] = "\10",   ["\87"] = "\11",
--    ["\88"] = "\4",   ["\89"] = "\5",
--    ["\90"] = "\6",   ["\91"] = "\7",
--    ["\92"] = "\0",   ["\93"] = "\1",
--    ["\94"] = "\2",   ["\95"] = "\3",
--    ["\96"] = "\60",   ["\97"] = "\61",
--    ["\98"] = "\62",   ["\99"] = "\63",
--    ["\100"] = "\56",   ["\101"] = "\57",
--    ["\102"] = "\58",   ["\103"] = "\59",
--    ["\104"] = "\52",   ["\105"] = "\53",
--    ["\106"] = "\54",   ["\107"] = "\55",
--    ["\108"] = "\48",   ["\109"] = "\49",
--    ["\110"] = "\50",   ["\111"] = "\51",
--    ["\112"] = "\44",   ["\113"] = "\45",
--    ["\114"] = "\46",   ["\115"] = "\47",
--    ["\116"] = "\40",   ["\117"] = "\41",
--    ["\118"] = "\42",   ["\119"] = "\43",
--    ["\120"] = "\36",   ["\121"] = "\37",
--    ["\122"] = "\38",   ["\123"] = "\39",
--    ["\124"] = "\32",   ["\125"] = "\33",
--    ["\126"] = "\34",   ["\127"] = "\35",
--    ["\128"] = "\220",   ["\129"] = "\221",
--    ["\130"] = "\222",   ["\131"] = "\223",
--    ["\132"] = "\216",   ["\133"] = "\217",
--    ["\134"] = "\218",   ["\135"] = "\219",
--    ["\136"] = "\212",   ["\137"] = "\213",
--    ["\138"] = "\214",   ["\139"] = "\215",
--    ["\140"] = "\208",   ["\141"] = "\209",
--    ["\142"] = "\210",   ["\143"] = "\211",
--    ["\144"] = "\204",   ["\145"] = "\205",
--    ["\146"] = "\206",   ["\147"] = "\207",
--    ["\148"] = "\200",   ["\149"] = "\201",
--    ["\150"] = "\202",   ["\151"] = "\203",
--    ["\152"] = "\196",   ["\153"] = "\197",
--    ["\154"] = "\198",   ["\155"] = "\199",
--    ["\156"] = "\192",   ["\157"] = "\193",
--    ["\158"] = "\194",   ["\159"] = "\195",
--    ["\160"] = "\252",   ["\161"] = "\253",
--    ["\162"] = "\254",   ["\163"] = "\255",
--    ["\164"] = "\248",   ["\165"] = "\249",
--    ["\166"] = "\250",   ["\167"] = "\251",
--    ["\168"] = "\244",   ["\169"] = "\245",
--    ["\170"] = "\246",   ["\171"] = "\247",
--    ["\172"] = "\240",   ["\173"] = "\241",
--    ["\174"] = "\242",   ["\175"] = "\243",
--    ["\176"] = "\236",   ["\177"] = "\237",
--    ["\178"] = "\238",   ["\179"] = "\239",
--    ["\180"] = "\232",   ["\181"] = "\233",
--    ["\182"] = "\234",   ["\183"] = "\235",
--    ["\184"] = "\228",   ["\185"] = "\229",
--    ["\186"] = "\230",   ["\187"] = "\231",
--    ["\188"] = "\224",   ["\189"] = "\225",
--    ["\190"] = "\226",   ["\191"] = "\227",
--    ["\192"] = "\156",   ["\193"] = "\157",
--    ["\194"] = "\158",   ["\195"] = "\159",
--    ["\196"] = "\152",   ["\197"] = "\153",
--    ["\198"] = "\154",   ["\199"] = "\155",
--    ["\200"] = "\148",   ["\201"] = "\149",
--    ["\202"] = "\150",   ["\203"] = "\151",
--    ["\204"] = "\144",   ["\205"] = "\145",
--    ["\206"] = "\146",   ["\207"] = "\147",
--    ["\208"] = "\140",   ["\209"] = "\141",
--    ["\210"] = "\142",   ["\211"] = "\143",
--    ["\212"] = "\136",   ["\213"] = "\137",
--    ["\214"] = "\138",   ["\215"] = "\139",
--    ["\216"] = "\132",   ["\217"] = "\133",
--    ["\218"] = "\134",   ["\219"] = "\135",
--    ["\220"] = "\128",   ["\221"] = "\129",
--    ["\222"] = "\130",   ["\223"] = "\131",
--    ["\224"] = "\188",   ["\225"] = "\189",
--    ["\226"] = "\190",   ["\227"] = "\191",
--    ["\228"] = "\184",   ["\229"] = "\185",
--    ["\230"] = "\186",   ["\231"] = "\187",
--    ["\232"] = "\180",   ["\233"] = "\181",
--    ["\234"] = "\182",   ["\235"] = "\183",
--    ["\236"] = "\176",   ["\237"] = "\177",
--    ["\238"] = "\178",   ["\239"] = "\179",
--    ["\240"] = "\172",   ["\241"] = "\173",
--    ["\242"] = "\174",   ["\243"] = "\175",
--    ["\244"] = "\168",   ["\245"] = "\169",
--    ["\246"] = "\170",   ["\247"] = "\171",
--    ["\248"] = "\164",   ["\249"] = "\165",
--    ["\250"] = "\166",   ["\251"] = "\167",
--    ["\252"] = "\160",   ["\253"] = "\161",
--    ["\254"] = "\162",   ["\255"] = "\163",
-- }

-- local xor_with_0x36 = {
--    ["\0"] = "\54",   ["\1"] = "\55",
--    ["\2"] = "\52",   ["\3"] = "\53",
--    ["\4"] = "\50",   ["\5"] = "\51",
--    ["\6"] = "\48",   ["\7"] = "\49",
--    ["\8"] = "\62",   ["\9"] = "\63",
--    ["\10"] = "\60",   ["\11"] = "\61",
--    ["\12"] = "\58",   ["\13"] = "\59",
--    ["\14"] = "\56",   ["\15"] = "\57",
--    ["\16"] = "\38",   ["\17"] = "\39",
--    ["\18"] = "\36",   ["\19"] = "\37",
--    ["\20"] = "\34",   ["\21"] = "\35",
--    ["\22"] = "\32",   ["\23"] = "\33",
--    ["\24"] = "\46",   ["\25"] = "\47",
--    ["\26"] = "\44",   ["\27"] = "\45",
--    ["\28"] = "\42",   ["\29"] = "\43",
--    ["\30"] = "\40",   ["\31"] = "\41",
--    ["\32"] = "\22",   ["\33"] = "\23",
--    ["\34"] = "\20",   ["\35"] = "\21",
--    ["\36"] = "\18",   ["\37"] = "\19",
--    ["\38"] = "\16",   ["\39"] = "\17",
--    ["\40"] = "\30",   ["\41"] = "\31",
--    ["\42"] = "\28",   ["\43"] = "\29",
--    ["\44"] = "\26",   ["\45"] = "\27",
--    ["\46"] = "\24",   ["\47"] = "\25",
--    ["\48"] = "\6",   ["\49"] = "\7",
--    ["\50"] = "\4",   ["\51"] = "\5",
--    ["\52"] = "\2",   ["\53"] = "\3",
--    ["\54"] = "\0",   ["\55"] = "\1",
--    ["\56"] = "\14",   ["\57"] = "\15",
--    ["\58"] = "\12",   ["\59"] = "\13",
--    ["\60"] = "\10",   ["\61"] = "\11",
--    ["\62"] = "\8",   ["\63"] = "\9",
--    ["\64"] = "\118",   ["\65"] = "\119",
--    ["\66"] = "\116",   ["\67"] = "\117",
--    ["\68"] = "\114",   ["\69"] = "\115",
--    ["\70"] = "\112",   ["\71"] = "\113",
--    ["\72"] = "\126",   ["\73"] = "\127",
--    ["\74"] = "\124",   ["\75"] = "\125",
--    ["\76"] = "\122",   ["\77"] = "\123",
--    ["\78"] = "\120",   ["\79"] = "\121",
--    ["\80"] = "\102",   ["\81"] = "\103",
--    ["\82"] = "\100",   ["\83"] = "\101",
--    ["\84"] = "\98",   ["\85"] = "\99",
--    ["\86"] = "\96",   ["\87"] = "\97",
--    ["\88"] = "\110",   ["\89"] = "\111",
--    ["\90"] = "\108",   ["\91"] = "\109",
--    ["\92"] = "\106",   ["\93"] = "\107",
--    ["\94"] = "\104",   ["\95"] = "\105",
--    ["\96"] = "\86",   ["\97"] = "\87",
--    ["\98"] = "\84",   ["\99"] = "\85",
--    ["\100"] = "\82",   ["\101"] = "\83",
--    ["\102"] = "\80",   ["\103"] = "\81",
--    ["\104"] = "\94",   ["\105"] = "\95",
--    ["\106"] = "\92",   ["\107"] = "\93",
--    ["\108"] = "\90",   ["\109"] = "\91",
--    ["\110"] = "\88",   ["\111"] = "\89",
--    ["\112"] = "\70",   ["\113"] = "\71",
--    ["\114"] = "\68",   ["\115"] = "\69",
--    ["\116"] = "\66",   ["\117"] = "\67",
--    ["\118"] = "\64",   ["\119"] = "\65",
--    ["\120"] = "\78",   ["\121"] = "\79",
--    ["\122"] = "\76",   ["\123"] = "\77",
--    ["\124"] = "\74",   ["\125"] = "\75",
--    ["\126"] = "\72",   ["\127"] = "\73",
--    ["\128"] = "\182",   ["\129"] = "\183",
--    ["\130"] = "\180",   ["\131"] = "\181",
--    ["\132"] = "\178",   ["\133"] = "\179",
--    ["\134"] = "\176",   ["\135"] = "\177",
--    ["\136"] = "\190",   ["\137"] = "\191",
--    ["\138"] = "\188",   ["\139"] = "\189",
--    ["\140"] = "\186",   ["\141"] = "\187",
--    ["\142"] = "\184",   ["\143"] = "\185",
--    ["\144"] = "\166",   ["\145"] = "\167",
--    ["\146"] = "\164",   ["\147"] = "\165",
--    ["\148"] = "\162",   ["\149"] = "\163",
--    ["\150"] = "\160",   ["\151"] = "\161",
--    ["\152"] = "\174",   ["\153"] = "\175",
--    ["\154"] = "\172",   ["\155"] = "\173",
--    ["\156"] = "\170",   ["\157"] = "\171",
--    ["\158"] = "\168",   ["\159"] = "\169",
--    ["\160"] = "\150",   ["\161"] = "\151",
--    ["\162"] = "\148",   ["\163"] = "\149",
--    ["\164"] = "\146",   ["\165"] = "\147",
--    ["\166"] = "\144",   ["\167"] = "\145",
--    ["\168"] = "\158",   ["\169"] = "\159",
--    ["\170"] = "\156",   ["\171"] = "\157",
--    ["\172"] = "\154",   ["\173"] = "\155",
--    ["\174"] = "\152",   ["\175"] = "\153",
--    ["\176"] = "\134",   ["\177"] = "\135",
--    ["\178"] = "\132",   ["\179"] = "\133",
--    ["\180"] = "\130",   ["\181"] = "\131",
--    ["\182"] = "\128",   ["\183"] = "\129",
--    ["\184"] = "\142",   ["\185"] = "\143",
--    ["\186"] = "\140",   ["\187"] = "\141",
--    ["\188"] = "\138",   ["\189"] = "\139",
--    ["\190"] = "\136",   ["\191"] = "\137",
--    ["\192"] = "\246",   ["\193"] = "\247",
--    ["\194"] = "\244",   ["\195"] = "\245",
--    ["\196"] = "\242",   ["\197"] = "\243",
--    ["\198"] = "\240",   ["\199"] = "\241",
--    ["\200"] = "\254",   ["\201"] = "\255",
--    ["\202"] = "\252",   ["\203"] = "\253",
--    ["\204"] = "\250",   ["\205"] = "\251",
--    ["\206"] = "\248",   ["\207"] = "\249",
--    ["\208"] = "\230",   ["\209"] = "\231",
--    ["\210"] = "\228",   ["\211"] = "\229",
--    ["\212"] = "\226",   ["\213"] = "\227",
--    ["\214"] = "\224",   ["\215"] = "\225",
--    ["\216"] = "\238",   ["\217"] = "\239",
--    ["\218"] = "\236",   ["\219"] = "\237",
--    ["\220"] = "\234",   ["\221"] = "\235",
--    ["\222"] = "\232",   ["\223"] = "\233",
--    ["\224"] = "\214",   ["\225"] = "\215",
--    ["\226"] = "\212",   ["\227"] = "\213",
--    ["\228"] = "\210",   ["\229"] = "\211",
--    ["\230"] = "\208",   ["\231"] = "\209",
--    ["\232"] = "\222",   ["\233"] = "\223",
--    ["\234"] = "\220",   ["\235"] = "\221",
--    ["\236"] = "\218",   ["\237"] = "\219",
--    ["\238"] = "\216",   ["\239"] = "\217",
--    ["\240"] = "\198",   ["\241"] = "\199",
--    ["\242"] = "\196",   ["\243"] = "\197",
--    ["\244"] = "\194",   ["\245"] = "\195",
--    ["\246"] = "\192",   ["\247"] = "\193",
--    ["\248"] = "\206",   ["\249"] = "\207",
--    ["\250"] = "\204",   ["\251"] = "\205",
--    ["\252"] = "\202",   ["\253"] = "\203",
--    ["\254"] = "\200",   ["\255"] = "\201",
-- }


-- local blocksize = 64 -- 512 bits

-- local function hmac_sha1(key, text)
--    assert(type(key)  == 'string', "key passed to hmac_sha1 should be a string")
--    assert(type(text) == 'string', "text passed to hmac_sha1 should be a string")

--    if #key > blocksize then
--       key = sha1_binary(key)
--    end

--    local key_xord_with_0x36 = key:gsub('.', xor_with_0x36) .. string.rep(string.char(0x36), blocksize - #key)
--    local key_xord_with_0x5c = key:gsub('.', xor_with_0x5c) .. string.rep(string.char(0x5c), blocksize - #key)

--    return sha1(key_xord_with_0x5c .. sha1_binary(key_xord_with_0x36 .. text))
-- end

-- local function hmac_sha1_binary(key, text)
--    return hex_to_binary(hmac_sha1(key, text))
-- end


