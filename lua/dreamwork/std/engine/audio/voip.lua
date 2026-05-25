-- voice_enable

--[[

    TODO:

    player functions:
        https://wiki.facepunch.com/gmod/Player:GetVoiceVolumeScale
        https://wiki.facepunch.com/gmod/Player:IsVoiceAudible
        https://wiki.facepunch.com/gmod/Player:SetVoiceVolumeScale
        https://wiki.facepunch.com/gmod/Player:VoiceVolume
        https://wiki.facepunch.com/gmod/Player:IsSpeaking

    client events:
        https://wiki.facepunch.com/gmod/GM:PlayerStartVoice
        https://wiki.facepunch.com/gmod/GM:PlayerEndVoice

    filter:
        https://wiki.facepunch.com/gmod/GM:PlayerCanHearPlayersVoice

]]

-- do

--     local voice_chat_state = false

--     dreamwork.engine.hookCatch( "PlayerStartVoice", function( entity )
--         if entity ~= client.entity then return end
--         voice_chat_state = true
--     end, 1 )

--     dreamwork.engine.hookCatch( "PlayerEndVoice", function( entity )
--         if entity ~= client.entity then return end
--         voice_chat_state = false
--     end, 1 )

--     function client.getVoiceChat()
--         return voice_chat_state
--     end

-- end

-- client.setVoiceChat = _G.permissions.EnableVoiceChat
