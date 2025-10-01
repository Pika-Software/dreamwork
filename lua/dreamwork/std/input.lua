local _G = _G

local dreamwork = _G.dreamwork
local glua_gui = _G.gui
local glua_vgui = _G.vgui
local glua_input = _G.input

---@class dreamwork.std
local std = dreamwork.std
local Command_run = std.console.Command.run

--- [SHARED AND MENU]
---
--- The input library allows you to
--- manipulate the client's input devices
--- (mouse & keyboard), such as the cursor
--- position and whether a key is pressed or not.
---
---@class dreamwork.std.input
local input = std.input or {}
std.input = input

if std.CLIENT_MENU then

    -- TODO: use ANALOG somewhere

    -- -- https://wiki.facepunch.com/gmod/Enums/ANALOG
    -- std.ANALOG = {
    --     MOUSE_X = 0,
    --     MOUSE_Y = 1,
    --     MOUSE_WHEEL = 3,
    --     JOY_X = 4,
    --     JOY_Y = 5,
    --     JOY_Z = 6,
    --     JOY_R = 7,
    --     JOY_U = 8,
    --     JOY_V = 9
    -- }

    do

        --- [CLIENT AND MENU]
        ---
        --- The cursor module allows to manipulate the client's cursor.
        ---
        ---@clas dreamwork.std.input.cursor
        local cursor = input.cursor or {}
        input.cursor = cursor

        cursor.isVisible = cursor.isVisible or glua_vgui.CursorVisible
        cursor.setVisible = cursor.setVisible or glua_gui.EnableScreenClicker or std.debug.fempty

        cursor.isHoveringWorld = cursor.isHoveringWorld or glua_vgui.IsHoveringWorld

        cursor.getPosition = cursor.getPosition or glua_input.GetCursorPos
        cursor.setPosition = cursor.setPosition or glua_input.SetCursorPos

        if std.debug.getmetatable( cursor ) == nil then
            local gui_MouseX = glua_gui.MouseX
            local gui_MouseY = glua_gui.MouseY

            std.setmetatable( cursor, {
                __index = function( _, key )
                    if key == 1 or key == "x" then
                        return gui_MouseX()
                    elseif key == 2 or key == "y" then
                        return gui_MouseY()
                    end
                end
            } )
        end

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The clipboard module allows to manipulate the client's clipboard.
        ---
        ---@class dreamwork.std.input.clipboard
        local clipboard = input.clipboard or {}
        input.clipboard = clipboard

        local clipboard_text = clipboard.getText and clipboard.getText() or ""

        --- [CLIENT AND MENU]
        ---
        --- Returns the contents of the clipboard.
        ---
        ---@return string
        function clipboard.getText()
            return clipboard_text
        end

        local SetClipboardText = _G.SetClipboardText
        if SetClipboardText == nil then
            SetClipboardText = std.debug.fempty
        end

        --- [CLIENT AND MENU]
        ---
        --- Sets the contents of the clipboard.
        ---
        ---@param text string
        function clipboard.setText( text )
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( text )
            clipboard_text = text
        end

        --- [CLIENT AND MENU]
        ---
        --- Adds text to the clipboard.
        ---
        ---@param text string
        function clipboard.addText( text )
            clipboard_text = clipboard_text .. text
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( text )
        end

        --- [CLIENT AND MENU]
        ---
        --- Clears the clipboard.
        ---
        function clipboard.clear()
            clipboard_text = ""
            ---@diagnostic disable-next-line: redundant-parameter
            SetClipboardText( clipboard_text )
        end

        -- TODO: add hooks and history

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The mouse module allows to manipulate the client's mouse.
        ---
        ---@class dreamwork.std.input.mouse
        local mouse = input.mouse or {}
        input.mouse = mouse

        mouse.wheel = glua_gui.InternalMouseWheeled
        mouse.move = gui.InternalCursorMoved

        mouse.press = glua_gui.InternalMousePressed
        mouse.release = glua_gui.InternalMouseReleased
        mouse.doubleClick = gui.InternalMouseDoublePressed

        mouse.isDown = glua_input.IsMouseDown

        mouse.wasPressed = glua_input.WasMousePressed
        mouse.wasReleased = glua_input.WasMouseReleased
        mouse.wasDoubleClicked = glua_input.WasMouseDoublePressed

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The key module allows manipulate the client's keys.
        ---
        ---@class dreamwork.std.input.key
        ---@field count integer The number of keys.
        local key = input.key or { count = 106 }
        input.key = key

        -- TODO: https://wiki.facepunch.com/gmod/input.IsButtonDown ?? whats a difference
        key.isDown = key.isDown or glua_input.IsKeyDown

        do

            local input_StartKeyTrapping = glua_input.StartKeyTrapping
            local input_CheckKeyTrapping = glua_input.CheckKeyTrapping
            local input_IsKeyTrapping = glua_input.IsKeyTrapping
            local futures_Future = std.futures.Future

            local captures = std.Stack()

            dreamwork.engine.hookCatch( "Tick", function()
                if captures:isEmpty() then return end

                if not input_IsKeyTrapping() then
                    input_StartKeyTrapping()
                end

                local key_code = input_CheckKeyTrapping()
                if key_code == nil then return end

                captures:pop():setResult( key_code )
            end, 1 )

            --- [CLIENT AND MENU]
            ---
            --- Starts a key capture and returns the key code of the key that was pressed.
            ---
            --- The captured key will not be pressed and committed to the game engine.
            ---
            ---@return integer key_code The key code of the key that was pressed.
            ---@async
            function key.capture()
                local f = futures_Future()
                captures:push( f )
                return f:await()
            end

        end

        do

            local key2name = {}

            do

                local input_GetKeyName = glua_input.GetKeyName

                std.setmetatable( key2name, {
                    __index = function( _, key_code )
                        local key_name = input_GetKeyName( key_code )
                        if key_name == nil then return "unknown" end
                        key2name[ key_code ] = key_name
                        return key_name
                    end
                } )

            end

            --- [CLIENT AND MENU]
            ---
            --- Get the name of a key.
            ---
            ---@param key_code integer The key code of the key.
            ---@return string key_code The name of the key.
            function key.getName( key_code )
                return key2name[ key_code ]
            end

            local name2key = {}

            do

                local input_GetKeyCode = glua_input.GetKeyCode

                std.setmetatable( name2key, {
                    __index = function( _, key_name )
                        local key_code = input_GetKeyCode( key_name )
                        if key_code == nil then return 0 end
                        name2key[ key_name ] = key_code
                        return key_code
                    end
                } )

            end

            --- [CLIENT AND MENU]
            ---
            --- Get the key code of a name.
            ---
            ---@param name string The name of the key.
            ---@return integer key_code The key code of the key.
            ---@see key.getName as a reverse lookup
            function key.getCode( name )
                return name2key[ name ]
            end

        end

        key.type = glua_gui.InternalKeyCodeTyped
        key.press = glua_gui.InternalKeyCodePressed
        key.release = glua_gui.InternalKeyCodeReleased

        key.wasTyped = glua_input.WasKeyTyped
        key.wasPressed = glua_input.WasKeyPressed
        key.wasReleased = glua_input.WasKeyReleased

    end

    input.typeByte = glua_gui.InternalKeyTyped
    input.isShiftDown = glua_input.IsShiftDown
    input.isControlDown = glua_input.IsControlDown

    do

        --- [CLIENT AND MENU]
        ---
        --- The bind module allows to manipulate the client's binds.
        ---
        ---@class dreamwork.std.input.binding
        local binding = input.binding or {}
        input.binding = binding

        binding.key = binding.key or glua_input.LookupBinding
        binding.get = binding.get or glua_input.LookupKeyBinding

        if std.MENU then

            local table_concat = std.table.concat
            local key_getName = input.key.getName

            --- [MENU]
            ---
            --- Sets the bind of a key.
            ---
            ---@param key_code integer
            ---@param ... string
            function binding.set( key_code, ... )
                Command_run( "bind", key_getName( key_code ), "'" .. table_concat( { ... }, ";" ) .. "'" )
            end

        end

    end

    do

        --- [CLIENT AND MENU]
        ---
        --- The controller module allows to manipulate the client's controllers.
        ---
        ---@class dreamwork.std.input.controller
        local controller = input.controller or {}
        input.controller = controller

        -- TODO: https://wiki.facepunch.com/gmod/input.GetAnalogValue
        -- TODO: https://wiki.facepunch.com/gmod/Enums/ANALOG

    end

end

if std.CLIENT then

    --- [CLIENT]
    ---
    --- The weapon module allows to manipulate the client's weapon.
    ---
    ---@class dreamwork.std.input.weapon
    local weapon = input.weapon or {}
    input.weapon = weapon

    weapon.select = weapon.select or glua_input.SelectWeapon

    --- [CLIENT]
    ---
    --- Selects the previously selected weapon.
    ---
    --- Instantly sets the player's past weapons as active.
    ---
    function weapon.last()
        return Command_run( "lastinv" )
    end

    --- [CLIENT]
    ---
    --- Selects the next weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
    ---
    function weapon.next()
        return Command_run( "invnext" )
    end

    --- [CLIENT]
    ---
    --- Selects the previous weapon in the inventory.
    ---
    --- Weapons will most likely not be selected immediately because often players do not use `hud_fastswitch`, so they will just have their inventory with the selected weapon displayed in the next slot.
    ---
    function weapon.previous()
        return Command_run( "invprev" )
    end

end

if std.CLIENT_SERVER then

    --- [CLIENT AND SERVER]
    ---
    --- The kinect module allows to manipulate the client's kinect.
    ---
    --- Highly recommended to use with https://github.com/WilliamVenner/gmcl_rekinect
    ---
    ---@class dreamwork.std.input.kinect
    local kinect = input.kinect or {}
    input.kinect = kinect

    if std.CLIENT then
        local available
        if std.loadbinary( "rekinect" ) then
            dreamwork.Logger:info( "'rekinect' was loaded & connected as Kinect API." )
            available = true
        elseif motionsensor ~= nil then
            dreamwork.Logger:info( "Native Kinect API was connected." )
            available = true
        else
            dreamwork.Logger:warn( "Kinect API is not available." )
        end

        if available and motionsensor.IsAvailable() then
            dreamwork.Logger:info( "Supported Kinect sensor was detected and connected to the client." )
        end
    end

    -- TODO: https://wiki.facepunch.com/gmod/motionsensor

    -- TODO: gmcl_rekinect support ( net library required )


    --[[

        TODO: rewrite this and make it native

        local function init(serverSupportsExtendedBones)
            if serverSupportsExtendedBones then
                SENSORBONE.SPINE_BASE = 20
                SENSORBONE.NECK = 21
                SENSORBONE.SPINE_SHOULDER = 22
                SENSORBONE.HAND_TIP_LEFT = 23
                SENSORBONE.THUMB_LEFT = 24
                SENSORBONE.HAND_TIP_RIGHT = 25
                SENSORBONE.THUMB_RIGHT = 26

                if SERVER then
                    util.AddNetworkString("gmcl_rekinect_extended_bones")
                end

                local playerExtendedBones = {}
                motionsensor.RekinectExtendedBonesRegistry = playerExtendedBones

                net.Receive("gmcl_rekinect_extended_bones", function(len, ply)
                    if len == 0 then return end -- Checking if server supports extended bones
                    local id = CLIENT and net.ReadUInt(32) or ply:UserID()
                    local cmdNumber = net.ReadUInt(32)
                    local clear = net.ReadBool()

                    if not clear then
                        playerExtendedBones[id] = playerExtendedBones[id] or {}
                        local playerExtendedBones = playerExtendedBones[id]
                        if playerExtendedBones[cmdNumber] and cmdNumber <= playerExtendedBones[cmdNumber] then return end -- Out of order packet, ignore
                        playerExtendedBones.cmdNumber = cmdNumber
                        playerExtendedBones[SENSORBONE.SPINE_BASE] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.NECK] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.SPINE_SHOULDER] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.HAND_TIP_LEFT] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.THUMB_LEFT] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.HAND_TIP_RIGHT] = net.ReadVector()
                        playerExtendedBones[SENSORBONE.THUMB_RIGHT] = net.ReadVector()

                        if SERVER then
                            net.Start("gmcl_rekinect_extended_bones", true)
                            net.WriteUInt(id, 32)
                            net.WriteUInt(cmdNumber, 32)
                            net.WriteBool(false)
                            net.WriteVector(playerExtendedBones[SENSORBONE.SPINE_BASE])
                            net.WriteVector(playerExtendedBones[SENSORBONE.NECK])
                            net.WriteVector(playerExtendedBones[SENSORBONE.SPINE_SHOULDER])
                            net.WriteVector(playerExtendedBones[SENSORBONE.HAND_TIP_LEFT])
                            net.WriteVector(playerExtendedBones[SENSORBONE.THUMB_LEFT])
                            net.WriteVector(playerExtendedBones[SENSORBONE.HAND_TIP_RIGHT])
                            net.WriteVector(playerExtendedBones[SENSORBONE.THUMB_RIGHT])
                            net.Broadcast()
                        end
                    else
                        if playerExtendedBones[id] and playerExtendedBones[id][cmdNumber] and cmdNumber <= playerExtendedBones[id][cmdNumber] then return end -- Out of order packet, ignore

                        playerExtendedBones[id] = {
                            cmdNumber = cmdNumber
                        }

                        if SERVER then
                            net.Start("gmcl_rekinect_extended_bones")
                            net.WriteUInt(id, 32)
                            net.WriteUInt(cmdNumber, 32)
                            net.WriteBool(true)
                            net.Broadcast()
                        end
                    end
                end)

                gameevent.Listen("player_disconnect")

                hook.Add("player_disconnect", "gmcl_rekinect_extended_bones", function(_, __, ___, id)
                    playerExtendedBones[id] = nil
                end)

                local PLAYER = FindMetaTable("Player")
                local MotionSensorPos = PLAYER.MotionSensorPos

                function PLAYER:MotionSensorPos(bone)
                    local exBone

                    if bone >= SENSORBONE.SPINE_BASE and bone <= SENSORBONE.THUMB_RIGHT then
                        local id = self:UserID()
                        exBone = playerExtendedBones[id] and playerExtendedBones[id][bone] or Vector()
                    end

                    if exBone then
                        return exBone
                    else
                        return MotionSensorPos(self, bone)
                    end
                end

                if CLIENT then
                    chat.AddText(Color(0, 255, 0), "gmcl_rekinect: Server supports Xbox One Kinect extra bones.")
                    local GetSkeleton = motionsensor.GetSkeleton

                    function motionsensor.GetSkeleton()
                        if not motionsensor.IsActive() then return nil end
                        local ply = LocalPlayer()
                        local MotionSensorPos = ply.MotionSensorPos
                        local skeleton

                        if GetSkeleton then
                            skeleton = GetSkeleton()
                        else
                            skeleton = {
                                [SENSORBONE.SHOULDER_RIGHT] = MotionSensorPos(ply, SENSORBONE.SHOULDER_RIGHT),
                                [SENSORBONE.SHOULDER_LEFT] = MotionSensorPos(ply, SENSORBONE.SHOULDER_LEFT),
                                [SENSORBONE.HIP] = MotionSensorPos(ply, SENSORBONE.HIP),
                                [SENSORBONE.ELBOW_RIGHT] = MotionSensorPos(ply, SENSORBONE.ELBOW_RIGHT),
                                [SENSORBONE.KNEE_RIGHT] = MotionSensorPos(ply, SENSORBONE.KNEE_RIGHT),
                                [SENSORBONE.WRIST_RIGHT] = MotionSensorPos(ply, SENSORBONE.WRIST_RIGHT),
                                [SENSORBONE.ANKLE_LEFT] = MotionSensorPos(ply, SENSORBONE.ANKLE_LEFT),
                                [SENSORBONE.FOOT_LEFT] = MotionSensorPos(ply, SENSORBONE.FOOT_LEFT),
                                [SENSORBONE.WRIST_LEFT] = MotionSensorPos(ply, SENSORBONE.WRIST_LEFT),
                                [SENSORBONE.FOOT_RIGHT] = MotionSensorPos(ply, SENSORBONE.FOOT_RIGHT),
                                [SENSORBONE.HAND_RIGHT] = MotionSensorPos(ply, SENSORBONE.HAND_RIGHT),
                                [SENSORBONE.SHOULDER] = MotionSensorPos(ply, SENSORBONE.SHOULDER),
                                [SENSORBONE.HIP_LEFT] = MotionSensorPos(ply, SENSORBONE.HIP_LEFT),
                                [SENSORBONE.HIP_RIGHT] = MotionSensorPos(ply, SENSORBONE.HIP_RIGHT),
                                [SENSORBONE.HAND_LEFT] = MotionSensorPos(ply, SENSORBONE.HAND_LEFT),
                                [SENSORBONE.ANKLE_RIGHT] = MotionSensorPos(ply, SENSORBONE.ANKLE_RIGHT),
                                [SENSORBONE.SPINE] = MotionSensorPos(ply, SENSORBONE.SPINE),
                                [SENSORBONE.ELBOW_LEFT] = MotionSensorPos(ply, SENSORBONE.ELBOW_LEFT),
                                [SENSORBONE.KNEE_LEFT] = MotionSensorPos(ply, SENSORBONE.KNEE_LEFT),
                                [SENSORBONE.HEAD] = MotionSensorPos(ply, SENSORBONE.HEAD),
                            }
                        end

                        local playerExtendedBones = playerExtendedBones[ply:UserID()] or {}
                        skeleton[SENSORBONE.SPINE_BASE] = playerExtendedBones[SENSORBONE.SPINE_BASE] or Vector()
                        skeleton[SENSORBONE.NECK] = playerExtendedBones[SENSORBONE.NECK] or Vector()
                        skeleton[SENSORBONE.SPINE_SHOULDER] = playerExtendedBones[SENSORBONE.SPINE_SHOULDER] or Vector()
                        skeleton[SENSORBONE.HAND_TIP_LEFT] = playerExtendedBones[SENSORBONE.HAND_TIP_LEFT] or Vector()
                        skeleton[SENSORBONE.THUMB_LEFT] = playerExtendedBones[SENSORBONE.THUMB_LEFT] or Vector()
                        skeleton[SENSORBONE.HAND_TIP_RIGHT] = playerExtendedBones[SENSORBONE.HAND_TIP_RIGHT] or Vector()
                        skeleton[SENSORBONE.THUMB_RIGHT] = playerExtendedBones[SENSORBONE.THUMB_RIGHT] or Vector()

                        return skeleton
                    end
                end
            else
                -- Pollyfill motionsensor.GetSkeleton
                if CLIENT then
                    chat.AddText(Color(255, 0, 0), "gmcl_rekinect: Server does not support Xbox One Kinect extra bones.")

                    if not motionsensor.GetSkeleton then
                        function motionsensor.GetSkeleton()
                            if not motionsensor.IsActive() then return nil end
                            local ply = LocalPlayer()
                            local MotionSensorPos = ply.MotionSensorPos

                            return {
                                [SENSORBONE.SHOULDER_RIGHT] = MotionSensorPos(ply, SENSORBONE.SHOULDER_RIGHT),
                                [SENSORBONE.SHOULDER_LEFT] = MotionSensorPos(ply, SENSORBONE.SHOULDER_LEFT),
                                [SENSORBONE.HIP] = MotionSensorPos(ply, SENSORBONE.HIP),
                                [SENSORBONE.ELBOW_RIGHT] = MotionSensorPos(ply, SENSORBONE.ELBOW_RIGHT),
                                [SENSORBONE.KNEE_RIGHT] = MotionSensorPos(ply, SENSORBONE.KNEE_RIGHT),
                                [SENSORBONE.WRIST_RIGHT] = MotionSensorPos(ply, SENSORBONE.WRIST_RIGHT),
                                [SENSORBONE.ANKLE_LEFT] = MotionSensorPos(ply, SENSORBONE.ANKLE_LEFT),
                                [SENSORBONE.FOOT_LEFT] = MotionSensorPos(ply, SENSORBONE.FOOT_LEFT),
                                [SENSORBONE.WRIST_LEFT] = MotionSensorPos(ply, SENSORBONE.WRIST_LEFT),
                                [SENSORBONE.FOOT_RIGHT] = MotionSensorPos(ply, SENSORBONE.FOOT_RIGHT),
                                [SENSORBONE.HAND_RIGHT] = MotionSensorPos(ply, SENSORBONE.HAND_RIGHT),
                                [SENSORBONE.SHOULDER] = MotionSensorPos(ply, SENSORBONE.SHOULDER),
                                [SENSORBONE.HIP_LEFT] = MotionSensorPos(ply, SENSORBONE.HIP_LEFT),
                                [SENSORBONE.HIP_RIGHT] = MotionSensorPos(ply, SENSORBONE.HIP_RIGHT),
                                [SENSORBONE.HAND_LEFT] = MotionSensorPos(ply, SENSORBONE.HAND_LEFT),
                                [SENSORBONE.ANKLE_RIGHT] = MotionSensorPos(ply, SENSORBONE.ANKLE_RIGHT),
                                [SENSORBONE.SPINE] = MotionSensorPos(ply, SENSORBONE.SPINE),
                                [SENSORBONE.ELBOW_LEFT] = MotionSensorPos(ply, SENSORBONE.ELBOW_LEFT),
                                [SENSORBONE.KNEE_LEFT] = MotionSensorPos(ply, SENSORBONE.KNEE_LEFT),
                                [SENSORBONE.HEAD] = MotionSensorPos(ply, SENSORBONE.HEAD),
                            }
                        end
                    end
                end
            end

            if gmcl_rekinect_extended_bones_supported_callback ~= nil then
                gmcl_rekinect_extended_bones_supported_callback(serverSupportsExtendedBones)
            end
        end

        local serverSupportsExtendedBones = SERVER or util.NetworkStringToID("gmcl_rekinect_extended_bones") ~= 0

        if CLIENT and not game.IsDedicated() and not serverSupportsExtendedBones then
            hook.Add("Tick", "gmcl_rekinect_extended_bones", function()
                if util.NetworkStringToID("gmcl_rekinect_extended_bones") ~= 0 then
                    init(true)
                    hook.Remove("Tick", "gmcl_rekinect_extended_bones")
                end
            end)
        else
            init(serverSupportsExtendedBones)
        end

    --]]

end
