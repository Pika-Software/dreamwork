local std              = dreamwork.std

local debug            = std.debug

local raw              = std.raw

local rbit             = raw.bit
local rbit_band        = rbit.band

local table            = std.table
local table_concat     = table.concat

local bitpack          = std.bitpack
local bitpack_toString = bitpack.toString


local glua_Material = Material
local upvalues = debug.getupvalues( glua_Material )

---@type fun( path: string, params: ( string | nil ) ): garrysmod.Material, number
local c_material_fn = upvalues.C_Material
if c_material_fn == nil then

    ---@type { [ 1 ]: number, [ 2 ]: string }[]
    local bit_to_param = {
        { 1,  "vertexlitgeneric" },
        { 2,  "nocull" },
        { 4,  "alphatest" },
        { 8,  "mips" },
        { 16, "noclamp" },
        { 32, "smooth" },
        { 64, "ignorez" }
    }

    bit_to_param[ 0 ] = #bit_to_param

    --- [SHARED AND MENU]
    ---
    --- Loads a material from the file.
    ---
    ---@param file_path string The path to the file.
    ---@param parameters dreamwork.std.MaterialParameters? The parameters to load the image with.
    ---@return garrysmod.Material material The loaded material.
    ---@return number time_taken The time taken to load the material.
    ---@nodiscard
    function engine.loadMaterial( file_path, parameters )
        if parameters == nil then
            return glua_Material( file_path )
        end

        ---@type string[]
        local gparams = {}

        ---@type integer
        local gparam_count = 0

        for i = 1, bit_to_param[ 0 ], 1 do
            local data = bit_to_param[ i ]
            if rbit_band( parameters, data[ 1 ] ) ~= 0 then
                gparam_count = gparam_count + 1
                gparams[ gparam_count ] = data[ 2 ]
            end
        end

        if gparam_count == 0 then
            return glua_Material( file_path )
        elseif gparam_count == 1 then
            return glua_Material( file_path, gparams[ 1 ] )
        end

        return glua_Material( file_path, table_concat( gparams, " ", 1, gparam_count ) )
    end

else

    --- [SHARED AND MENU]
    ---
    --- Loads a material from the file.
    ---
    ---@param file_path string The path to the file.
    ---@param parameters dreamwork.std.MaterialParameters? The parameters to load the image with.
    ---@return garrysmod.Material material The loaded material.
    ---@return number time_taken The time taken to load the material.
    ---@nodiscard
    function engine.loadMaterial( file_path, parameters )
        if parameters == nil then
            return c_material_fn( file_path )
        end

        return c_material_fn( file_path, bitpack_toString( parameters ) )
    end

end
