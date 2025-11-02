---@class dreamwork.std
local std = _G.dreamwork.std

---@class dreamwork.std.chat
local chat = {}
std.chat = chat

--[[

    TODO:

    ui functions:
        https://wiki.facepunch.com/gmod/chat.Open
        https://wiki.facepunch.com/gmod/chat.Close
        https://wiki.facepunch.com/gmod/chat.AddText
        https://wiki.facepunch.com/gmod/chat.GetChatBoxPos
        https://wiki.facepunch.com/gmod/chat.GetChatBoxSize
        https://wiki.facepunch.com/gmod/chat.PlaySound - add sound override event

    player functions:
        https://wiki.facepunch.com/gmod/Player:Say
        https://wiki.facepunch.com/gmod/Player:IsTyping

    ui events:
        https://wiki.facepunch.com/gmod/GM:StartChat
        https://wiki.facepunch.com/gmod/GM:FinishChat

    message events:
        https://wiki.facepunch.com/gmod/GM:ChatText
        https://wiki.facepunch.com/gmod/GM:OnPlayerChat
        https://wiki.facepunch.com/gmod/gameevent/player_say
        https://wiki.facepunch.com/gmod/GM:PlayerSay

    filters:
        https://wiki.facepunch.com/gmod/GM:PlayerCanSeePlayersChat

    ui hooks:
        https://wiki.facepunch.com/gmod/GM:ChatTextChanged
        https://wiki.facepunch.com/gmod/GM:OnChatTab

--]]

-- _G.util.FilterText

-- addText = "AddText",
-- close = "Close",
-- open = "Open"

-- --- Sends a message to the player chat.
-- ---@param text string The message's content.
-- ---@param teamChat boolean? Whether the message should be sent as team chat.
-- function chat.say( text, teamChat )
--     command_run( teamChat and "say_team" or "say", text )
-- end
