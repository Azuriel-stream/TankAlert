-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- Helper Function: Raid Assist (v1.1) ---
-- This function checks if the player is a raid leader or assist
function TankAlert_IsRaidAssist()
    if (GetNumRaidMembers() == 0) then
        return false
    end
    local playerName = UnitName("player")
    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if (name == playerName) then
            if (rank == 1 or rank == 2) then
                return true
            else
                return false
            end
        end
    end
    return false
end

-- --- Helper Function: Raid Icon (v1.1) ---
-- This function converts an icon index (1-8) into a chat string
function TankAlert_GetRaidIcon(iconIndex)
    if iconIndex == 1 then
        return "{Star}"
    elseif iconIndex == 2 then
        return "{Circle}"
    elseif iconIndex == 3 then
        return "{Diamond}"
    elseif iconIndex == 4 then
        return "{Triangle}"
    elseif iconIndex == 5 then
        return "{Moon}"
    elseif iconIndex == 6 then
        return "{Square}"
    elseif iconIndex == 7 then
        return "{Cross}"
    elseif iconIndex == 8 then
        return "{Skull}"
    else
        return ""
    end
end

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
        local abilityName = nil
        local targetName = nil

        if (msg) then
            -- --- Taunt ---
            if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
                abilityName = "Taunt"
                _, _, targetName = string.find(msg, "resisted by (.+)")
            
            -- --- Sunder Armor ---
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "dodged")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "parried")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "missed")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "missed (.+)")
                
            -- --- Shield Slam ---
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "dodged")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "parried")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "missed")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "missed (.+)")

            -- --- Revenge ---
            elseif (string.find(msg, "Revenge") and string.find(msg, "dodged")) then
                abilityName = "Revenge"
                _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "Revenge") and string.find(msg, "parried")) then
                abilityName = "Revenge"
                _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "Revenge") and string.find(msg, "missed")) then
                abilityName = "Revenge"
                _, _, targetName = string.find(msg, "missed (.+)")
            end
        end

        -- --- MESSAGE BUILDER ---
        if (abilityName and targetName) then
            
            -- Sanitize the targetName to remove trailing punctuation
            if (targetName) then
                targetName = string.gsub(targetName, "%p$", "")
            end
            
            local raidIcon = ""
            -- Check if your current target's name matches the name from the log
            if (UnitName("target") == targetName) then
                local iconIndex = GetRaidTargetIndex("target")
                raidIcon = TankAlert_GetRaidIcon(iconIndex)
                -- Add a space if the icon exists
                if (raidIcon ~= "") then
                    raidIcon = raidIcon .. " "
                end
            end
            
            -- Build the final message
            announceMsg = UnitName("player") .. "'s " .. abilityName .. " FAILED on " .. raidIcon .. targetName .. ". Watch threat!"
            
        elseif (abilityName) then
            -- Failsafe in case parsing fails
            announceMsg = UnitName("player") .. "'s " .. abilityName .. " FAILED. Watch threat!"
        end
    end
    
    -- --- ANNOUNCEMENT LOGIC ---
    if (announceMsg) then
        local channel = "SAY" -- Default for solo

        if (GetNumRaidMembers() > 0) then
            if (TankAlert_IsRaidAssist()) then
                channel = "RAID_WARNING"
            else
                channel = "RAID"
            end
        elseif (GetNumPartyMembers() > 0) then
            channel = "PARTY"
        end
        
        SendChatMessage(announceMsg, channel)
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")