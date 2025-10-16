local _G = _G
local std = _G.dreamwork.std
local isString = std.isString
local setmetatable = std.setmetatable
local physenv, util = _G.physenv, _G.util

---@class dreamwork.std.physics
local physics = {
    getSimulationDuration = physenv.GetLastSimulationTime
}

do

    ---@class dreamwork.std.physics.collide
    local collide = {
        createFromModel = _G.CreatePhysCollidesFromModel,
        createBox = _G.CreatePhysCollideBox,
    }

    setmetatable( collide, { __index = std.debug.findmetatable( "PhysCollide" ) } )

    physics.collide = collide

end

---@type PhysObj
---@diagnostic disable-next-line: assign-type-mismatch
physics.object = setmetatable( {}, { __index = std.debug.findmetatable( "PhysObj" ) } )

do

    ---@class dreamwork.std.physics.surface
    local surface = {
        getID = util.GetSurfaceIndex,
        getData = util.GetSurfaceData,
        getName = util.GetSurfacePropName
    }

    local physenv_AddSurfaceData = physenv.AddSurfaceData
    local table_concat = std.table.concat
    local tostring = std.tostring

    local MAT = std.MAT
    local mat2name = {
        [ MAT.A ] = "A",
        [ MAT.B ] = "B",
        [ MAT.C ] = "C",
        [ MAT.D ] = "D",
        [ MAT.E ] = "E",
        [ MAT.F ] = "F",
        [ MAT.G ] = "G",
        [ MAT.H ] = "H",
        [ MAT.I ] = "I",
        [ MAT.L ] = "L",
        [ MAT.M ] = "M",
        [ MAT.N ] = "N",
        [ MAT.O ] = "O",
        [ MAT.P ] = "P",
        [ MAT.S ] = "S",
        [ MAT.T ] = "T",
        [ MAT.V ] = "V",
        [ MAT.W ] = "W",
        [ MAT.Y ] = "Y"
    }

    -- https://wiki.facepunch.com/gmod/Structures/SurfacePropertyData
    local garry2key = {
        hardnessFactor = "audiohardnessfactor",
        hardThreshold = "impactHardThreshold",
        hardVelocityThreshold = "audioHardMinVelocity",
        reflectivity = "audioreflectivity",
        roughnessFactor = "audioroughnessfactor",
        roughThreshold = "scrapeRoughThreshold",
        jumpFactor = "jumpfactor",
        maxSpeedFactor = "maxspeedfactor",
        breakSound = "break",
        bulletImpactSound = "bulletimpact",
        impactHardSound = "impacthard",
        impactSoftSound = "impactsoft",
        rollingSound = "roll",
        scrapeRoughSound = "scraperough",
        scrapeSmoothSound = "scrapesmooth",
        stepLeftSound = "stepleft",
        stepRightSound = "stepright",
        strainSound = "strain"
    }

    --- Adds surface properties to the game's physics environment.
    ---@param data SurfacePropertyData | table The surface data to be added.
    function surface.add( data )
        local buffer, length = {}, 0

        for key, value in pairs( data ) do
            key = tostring( key )

            if key ~= "name" then
                value = tostring( value )

                if key == "material" then
                    key, value = "gamematerial", mat2name[ value ] or value
                end

                length = length + 1
                buffer[ length ] = "\""

                length = length + 1
                buffer[ length ] = garry2key[ key ] or key

                length = length + 1
                buffer[ length ] = "\"\t\""

                length = length + 1
                buffer[ length ] = value

                length = length + 1
                buffer[ length ] = "\"\n"
            end
        end

        if length == 0 then
            error( "Invalid surface data", 2 )
        else
            local name = data.name
            if isString( name ) then
                physenv_AddSurfaceData( "\"" .. name .. "\"\n{\n" .. table_concat( buffer, "", 1, length ) .. "}" )
            else
                error( "Invalid surface name", 2 )
            end
        end
    end

    physics.surface = surface

end

do

    ---@class dreamwork.std.physics.settings
    ---@field max_ovw_time number Maximum amount of seconds to precalculate collisions with world. ( Default: 1 )
    ---@field max_ovo_time number Maximum amount of seconds to precalculate collisions with objects. ( Default: 0.5 )
    ---@field max_collisions_per_tick number Maximum collision checks per tick.
    --- Objects may penetrate after this many collision checks. ( Default: 50000 )
    ---@field max_object_collisions_pre_tick number Maximum collision per object per tick.
    --- Object will be frozen after this many collisions (visual hitching vs. CPU cost). ( Default: 10 )
    ---@field max_velocity number Maximum world-space speed of an object in inches per second. ( Default: 4000 )
    ---@field max_angular_velocity number Maximum world-space rotational velocity in degrees per second. ( Default: 7200 )
    ---@field min_friction_mass number Minimum mass of an object to be affected by friction. ( Default: 10 )
    ---@field max_friction_mass number Maximum mass of an object to be affected by friction. ( Default: 2500 )
    local settings = {}

    local physenv_GetPerformanceSettings, physenv_SetPerformanceSettings = physenv.GetPerformanceSettings, physenv.SetPerformanceSettings
    local physenv_GetAirDensity, physenv_SetAirDensity = physenv.GetAirDensity, physenv.SetAirDensity
    local physenv_GetGravity, physenv_SetGravity = physenv.GetGravity, physenv.SetGravity

    -- https://wiki.facepunch.com/gmod/Structures/PhysEnvPerformanceSettings
    local key2performance = {
        max_ovw_time = "LookAheadTimeObjectsVsWorld",
        max_ovo_time = "LookAheadTimeObjectsVsObject",

        max_collisions_per_tick = "MaxCollisionChecksPerTimestep",
        max_object_collisions_pre_tick = "MaxCollisionsPerObjectPerTimestep",

        max_velocity = "MaxVelocity",
        max_angular_velocity = "MaxAngularVelocity",

        min_friction_mass = "MinFrictionMass",
        max_friction_mass = "MaxFrictionMass"
    }

    setmetatable( settings, {
        __index = function( tbl, key )
            local performanceKey = key2performance[ key ]
            if performanceKey ~= nil then
                return physenv_GetPerformanceSettings()[ performanceKey ]
            elseif key == "gravity" then
                return physenv_GetGravity()
            elseif key == "air_density" then
                return physenv_GetAirDensity()
            end
        end,
        __newindex = function( tbl, key, value )
            local performanceKey = key2performance[ key ]
            if performanceKey ~= nil then
                local values = physenv_GetPerformanceSettings()
                values[ performanceKey ] = value
                physenv_SetPerformanceSettings( values )
            elseif key == "gravity" then
                physenv_SetGravity( value )
            elseif key == "air_density" then
                physenv_SetAirDensity( value )
            end
        end
    } )

    physics.settings = settings

end

return physics
