-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- NEW HELPER FUNCTION (v1.1) ---
-- This function checks if the player is a raid leader or assist
function TankAlert_IsRaidAssist()
    -- Check if we are even in a raid
    if (GetNumRaidMembers() == 0) then
        return false
    end

    -- Get our own name
    local playerName = UnitName("player")

    -- Loop through the raid roster
    for i = 1, GetNumRaidMembers() do
        -- Get the info for this raid member
        local name, rank = GetRaidRosterInfo(i)
        
        -- Check if this member is us
        if (name == playerName) then
            -- We found ourselves. Check our rank.
            -- Rank 2 = Leader, Rank 1 = Assist
            if (rank == 1 or rank == 2) then
                return true
            else
                -- We are a regular member (rank 0)
                return false
            end
        end
    end
    
    -- Failsafe in case we're not found in the roster (e.g., just joined)
    return false
end
-- --- END OF NEW FUNCTION ---


-- Set the script
tankAlert_Frame:SetScript("OnEvent", function()

    -- Check the GLOBAL variable 'event'
    
    if event == "PLAYER_ENTERING_WORLD" then
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r TankAlert is now active.")
        tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    local announceMsg = nil
    
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local msg = arg1
        
        if (msg) then
            if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
                announceMsg = "!!! TAUNT RESISTED !!!"
            elseif (string.find(msg, "Sunder Armor") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Sunder Armor FAILED"
            elseif (string.find(msg, "Shield Slam") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Shield Slam FAILED"
            elseif (string.find(msg, "Revenge") and (string.find(msg, "dodged") or string.find(msg, "missed") or string.find(msg, "parried"))) then
                announceMsg = "Revenge FAILED"
            end
        end
    end
    

    -- --- UPDATED ANNOUNCEMENT LOGIC (v1.1) ---
    if (announceMsg) then
        local channel = "SAY" -- Default for solo

        if (GetNumRaidMembers() > 0) then
            -- We are in a raid. Check our rank.
            if (TankAlert_IsRaidAssist()) then
                channel = "RAID_WARNING" -- Use warning if Assist/Leader
            else
                channel = "RAID" -- Use normal raid chat if member
            end
        elseif (GetNumPartyMembers() > 0) then
            -- We are in a party (but not a raid)
            channel = "PARTY"
        end
        
        SendChatMessage(announceMsg, channel)
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")