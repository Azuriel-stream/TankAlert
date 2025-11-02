-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- Set the script
tankAlert_Frame:SetScript("OnEvent", function()

    -- Check the GLOBAL variable 'event'
    
    -- This event fires when we log in
    if event == "PLAYER_ENTERING_WORLD" then
        
        -- Register for our SINGLE combat event
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        
        -- Print a single "loaded" message
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r TankAlert is now active.")
        
        -- Unregister this event so it only fires once
        tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    local announceMsg = nil
    
    -- --- This is our ONLY handler ---
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- The entire combat log line (e.g., "Your Sunder Armor was dodged...") is in 'arg1'
        local msg = arg1
        
        if (msg) then
            -- Check for Taunt Resist
            if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
                announceMsg = "!!! TAUNT RESISTED !!!"
                
            -- Check for Sunder Armor Failure
            elseif (string.find(msg, "Sunder Armor") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Sunder Armor FAILED"
                
            -- Check for Shield Slam Failure
            elseif (string.find(msg, "Shield Slam") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Shield Slam FAILED"
                
            -- Check for Revenge Failure
            elseif (string.find(msg, "Revenge") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Revenge FAILED"
            end
        end
    end
    
    -- --- If we found a match, announce it ---
    if (announceMsg) then
        local channel = "SAY"
        if (GetNumRaidMembers() > 0) then
            channel = "RAID_WARNING"
        elseif (GetNumPartyMembers() > 0) then
            channel = "PARTY"
        end
        SendChatMessage(announceMsg, channel)
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")