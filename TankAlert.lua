-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- Addon Settings (v1.3) ---
local TankAlert_Defaults = {
    enabled = true,
    forceChannel = "auto",
    abilities = {
        Taunt = true,
        SunderArmor = true,
        ShieldSlam = true,
        Revenge = true,
        MockingBlow = true, -- The only v1.3 addition
    }
}
TankAlert_Settings = {}


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
        return "|cffFFFF00[Star]|r"
    elseif iconIndex == 2 then
        return "|cffFFA500[Circle]|r"
    elseif iconIndex == 3 then
        return "|cffC800FF[Diamond]|r"
    elseif iconIndex == 4 then
        return "|cff00FF00[Triangle]|r"
    elseif iconIndex == 5 then
        return "|cffFFFFFF[Moon]|r"
    elseif iconIndex == 6 then
        return "|cff0070FF[Square]|r"
    elseif iconIndex == 7 then
        return "|cffFF0000[Cross]|r"
    elseif iconIndex == 8 then
        return "|cffFFFFFF[Skull]|r"
    else
        return ""
    end
end

-- --- Helper Function to "normalize" ability names (v1.3) ---
function TankAlert_GetAbilityKey(name)
    if (name == "Taunt") then return "Taunt" end
    if (name == "Sunder Armor") then return "SunderArmor" end
    if (name == "Shield Slam") then return "ShieldSlam" end
    if (name == "Revenge") then return "Revenge" end
    if (name == "Mocking Blow") then return "MockingBlow" end
    return nil
end


-- Set the script
tankAlert_Frame:SetScript("OnEvent", function()

    -- Check the GLOBAL variable 'event'
    
    if event == "PLAYER_ENTERING_WORLD" then
        
        -- --- Settings Loader (v1.2) ---
        if (TankAlert_Settings == nil or type(TankAlert_Settings) ~= "table") then
            TankAlert_Settings = {}
        end
        -- (Merge logic is the same)
        for key, value in pairs(TankAlert_Defaults) do
            if (TankAlert_Settings[key] == nil) then
                TankAlert_Settings[key] = value
            end
        end
        if (TankAlert_Settings.abilities == nil or type(TankAlert_Settings.abilities) ~= "table") then
            TankAlert_Settings.abilities = TankAlert_Defaults.abilities
        end
        for key, value in pairs(TankAlert_Defaults.abilities) do
            if (TankAlert_Settings.abilities[key] == nil) then
                TankAlert_Settings.abilities[key] = value
            end
        end
        
        -- --- Event Registration (v1.3) ---
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

        local status = "|cffFF0000DISABLED|r"
        if (TankAlert_Settings.enabled) then
            status = "|cff00FF00ENABLED|r"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r TankAlert is now active. (" .. status .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Type |cffFFFFFF/ta|r for options.")
        
        tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
    
    -- --- Master Toggle Check ---
    if (TankAlert_Settings.enabled == false) then
        return
    end
    
    
    -- --- Main Handler for our actions ---
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local msg = arg1
        local abilityName = nil
        local targetName = nil

        if (not msg) then return end

        -- === SECTION 1: Check for FAILED abilities ===
        
        if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
            abilityName = "Taunt"
            _, _, targetName = string.find(msg, "resisted by (.+)")
        elseif (string.find(msg, "Sunder Armor") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
            abilityName = "Sunder Armor"
            if (string.find(msg, "dodged")) then _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "parried")) then _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "missed")) then _, _, targetName = string.find(msg, "missed (.+)")
            end
        elseif (string.find(msg, "Shield Slam") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
            abilityName = "Shield Slam"
            if (string.find(msg, "dodged")) then _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "parried")) then _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "missed")) then _, _, targetName = string.find(msg, "missed (.+)")
            end
        elseif (string.find(msg, "Revenge") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
            abilityName = "Revenge"
            if (string.find(msg, "dodged")) then _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "parried")) then _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "missed")) then _, _, targetName = string.find(msg, "missed (.+)")
            end
        elseif (string.find(msg, "Mocking Blow") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
            abilityName = "Mocking Blow"
            if (string.find(msg, "dodged")) then _, _, targetName = string.find(msg, "dodged by (.+)")
            elseif (string.find(msg, "parried")) then _, _, targetName = string.find(msg, "parried by (.+)")
            elseif (string.find(msg, "missed")) then _, _, targetName = string.find(msg, "missed (.+)")
            end
        end

        -- === SECTION 2: Build and Send Announcement ===
        if (abilityName) then
            local abilityKey = TankAlert_GetAbilityKey(abilityName)
            if (abilityKey == nil or TankAlert_Settings.abilities[abilityKey] == false) then
                return
            end
            
            local messageBody = ""
            local targetInfo = "" 

            if (targetName) then
                targetName = string.gsub(targetName, "%p$", "")
                local raidIconText = ""
                if (UnitName("target") == targetName) then
                    local iconIndex = GetRaidTargetIndex("target")
                    raidIconText = TankAlert_GetRaidIconName(iconIndex)
                end
                
                if (raidIconText ~= "") then
                    targetInfo = raidIconText
                else
                    targetInfo = targetName
                end
                
                messageBody = abilityName .. " FAILED on " .. targetInfo .. ". Watch threat!"
            else
                messageBody = abilityName .. " FAILED. Watch threat!"
            end

            if (messageBody ~= "") then
                local channel = "SAY"
                local messagePrefix = ""
                
                if (TankAlert_Settings.forceChannel ~= "auto") then
                    channel = string.upper(TankAlert_Settings.forceChannel)
                    if (channel == "RAID_WARNING") then
                         messagePrefix = UnitName("player") .. "'s "
                    end
                else
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
                end
                SendChatMessage(messagePrefix .. messageBody, channel)
            end
        end
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")


-- --- Slash Command Handler (v1.3) ---
SlashCmdList["TANKALERT"] = function(msg)
    local cmd, arg = string.match(string.lower(msg or ""), "([^ ]+) (.+)")
    if (cmd == nil and msg ~= "") then
        cmd = string.lower(msg)
    end

    if (cmd == "toggle") then
        if (arg == "taunt") then
            TankAlert_Settings.abilities.Taunt = not TankAlert_Settings.abilities.Taunt
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Taunt alerts: " .. (TankAlert_Settings.abilities.Taunt and "ON" or "OFF"))
        elseif (arg == "sunder") then
            TankAlert_Settings.abilities.SunderArmor = not TankAlert_Settings.abilities.SunderArmor
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Sunder Armor alerts: " .. (TankAlert_Settings.abilities.SunderArmor and "ON" or "OFF"))
        elseif (arg == "shieldslam") then
            TankAlert_Settings.abilities.ShieldSlam = not TankAlert_Settings.abilities.ShieldSlam
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Shield Slam alerts: " .. (TankAlert_Settings.abilities.ShieldSlam and "ON" or "OFF"))
        elseif (arg == "revenge") then
            TankAlert_Settings.abilities.Revenge = not TankAlert_Settings.abilities.Revenge
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Revenge alerts: " .. (TankAlert_Settings.abilities.Revenge and "ON" or "OFF"))
        elseif (arg == "mockingblow" or arg == "mocking") then
            TankAlert_Settings.abilities.MockingBlow = not TankAlert_Settings.abilities.MockingBlow
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Mocking Blow alerts: " .. (TankAlert_Settings.abilities.MockingBlow and "ON" or "OFF"))
        else
            TankAlert_Settings.enabled = not TankAlert_Settings.enabled
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now " .. (TankAlert_Settings.enabled and "|cff00FF00ENABLED|r." or "|cffFF0000DISABLED|r."))
        end
        
    elseif (cmd == "force") then
        if (arg == "party") then
            TankAlert_Settings.forceChannel = "party"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFPARTY|r chat.")
        elseif (arg == "raid") then
            TankAlert_Settings.forceChannel = "raid"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFRAID|r chat.")
        elseif (arg == "say") then
            TankAlert_Settings.forceChannel = "say"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFSAY|r.")
        elseif (arg == "auto") then
            TankAlert_Settings.forceChannel = "auto"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements set to |cffFFFFFFAUTO|r-detect channel.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Unknown channel. Use: |cffFFFFFF/ta force [auto | party | raid | say]|r")
        end

    elseif (cmd == "on") then
        TankAlert_Settings.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cff00FF00ENABLED|r.")
        
    elseif (cmd == "off") or (cmd == "stop") then
        TankAlert_Settings.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cffFF0000DISABLED|r.")
        
    else
        -- --- Status Menu (v1.3) ---
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00------ [TankAlert Status] ------|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Master Toggle:|r " .. (TankAlert_Settings.enabled and "|cff00FF00ENABLED|r" or "|cffFF0000DISABLED|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Force Channel:|r |cffFFFFFF" .. string.upper(TankAlert_Settings.forceChannel) .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Failed Abilities:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFTaunt:|r " .. (TankAlert_Settings.abilities.Taunt and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFSunder:|r " .. (TankAlert_Settings.abilities.SunderArmor and "ON" or "OFF")) -- FIX: Removed underscore
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFShield Slam:|r " .. (TankAlert_Settings.abilities.ShieldSlam and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFRevenge:|r " .. (TankAlert_Settings.abilities.Revenge and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFMocking Blow:|r " .. (TankAlert_Settings.abilities.MockingBlow and "ON" or "OFF"))
        -- We removed the "Failed Interrupts" section
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00------ [Commands] ------|r")
        DEFAULT_CHAT_FRAME:AddMessage("/ta [on|off|toggle] - Master switch.")
        DEFAULT_CHAT_FRAME:AddMessage("/ta force [auto | party | raid | say]")
        DEFAULT_CHAT_FRAME:AddMessage("/ta toggle [taunt | sunder | shieldslam | revenge | mocking]") -- FIX: Removed interrupt commands
    end
end

-- Create the /ta slash command
SLASH_TANKALERT1 = "/ta"