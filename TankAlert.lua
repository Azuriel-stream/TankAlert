-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- Helper Function: Raid Assist (v1.1) ---
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

-- --- Helper Function: Raid Icon Name (v1.1) ---
function TankAlert_GetRaidIconName(iconIndex)
    if iconIndex == 1 then
        return "|cffFFFF00[Star]|r" -- Yellow
    elseif iconIndex == 2 then
        return "|cffFFA500[Circle]|r" -- Orange
    elseif iconIndex == 3 then
        return "|cffC800FF[Diamond]|r" -- Purple
    elseif iconIndex == 4 then
        return "|cff00FF00[Triangle]|r" -- Green
    elseif iconIndex == 5 then
        return "|cffFFFFFF[Moon]|r" -- White
    elseif iconIndex == 6 then
        return "|cff0070FF[Square]|r" -- Blue
    elseif iconIndex == 7 then
        return "|cffFF0000[Cross]|r" -- Red
    elseif iconIndex == 8 then
        return "|cffFFFFFF[Skull]|r" -- White
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
    
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local msg = arg1
        local abilityName = nil
        local targetName = nil

        if (msg) then
            -- (Parsing logic is the same)
            if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
                abilityName = "Taunt"
                _, _, targetName = string.find(msg, "resisted by (.+)")
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "dodged")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "parried")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "Sunder Armor") and string.find(msg, "missed")) then
                abilityName = "Sunder Armor"
                _, _, targetName = string.find(msg, "missed (.+)")
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "dodged")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "parried")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "Shield Slam") and string.find(msg, "missed")) then
                abilityName = "Shield Slam"
                _, _, targetName = string.find(msg, "missed (.+)")
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

        -- --- UPDATED MESSAGE BUILDER (v1.1) ---
        if (abilityName) then
            
            local messageBody = ""
            local targetInfo = "" -- This will hold EITHER the icon OR the name

            if (targetName) then
                -- Sanitize the targetName
                targetName = string.gsub(targetName, "%p$", "")
                
                local raidIconText = ""
                -- Check if the failed target is your current target
                if (UnitName("target") == targetName) then
                    local iconIndex = GetRaidTargetIndex("target")
                    raidIconText = TankAlert_GetRaidIconName(iconIndex)
                end
                
                -- --- NEW LOGIC ---
                if (raidIconText ~= "") then
                    -- If we have an icon, use it
                    targetInfo = raidIconText
                else
                    -- If we have NO icon, use the target's name
                    targetInfo = targetName
                end
                -- --- END NEW LOGIC ---

                messageBody = abilityName .. " FAILED on " .. targetInfo .. ". Watch threat!"
            
            else
                -- Failsafe (no target name parsed at all)
                messageBody = abilityName .. " FAILED. Watch threat!"
            end

            -- 1. Determine Channel
            local channel = "SAY"
            local messagePrefix = "" 
            
            if (GetNumRaidMembers() > 0) then
                if (TankAlert_IsRaidAssist()) then
                    channel = "RAID_WARNING"
                    messagePrefix = UnitName("player") .. "'s "
                else
                    channel = "RAID"
                end
            elseif (GetNumPartyMembers() > 0) then
                channel = "PARTY"
            end
            
            -- 2. Send the message
            SendChatMessage(messagePrefix .. messageBody, channel)
        end
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")