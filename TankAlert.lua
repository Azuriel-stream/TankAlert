-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- NEW: 1.12-Safe String Functions (v1.5.1) ---
-- We capture the basic string functions to make the addon standalone
local _strlower = string.lower
local _strfind = string.find
local _strsub = string.sub

-- --- Throttle Timers (v1.5) ---
local TankAlert_Last_CC_Alert_Time = 0
local TankAlert_Last_Disarm_Alert_Time = 0

-- --- Addon Settings (v1.5) ---
local TankAlert_Defaults = {
    -- Global settings apply to all classes
    global = {
        enabled = true,
        forceChannel = "auto",
        announceCC = true,
        announceDisarm = true,
        alertThrottle = 8,
    },
    WARRIOR = {
        abilities = {
            Taunt = true,
            SunderArmor = true,
            ShieldSlam = true,
            Revenge = true,
            MockingBlow = true,
        }
    },
    DRUID = {
        abilities = {
            Growl = true,
        }
    }
}
TankAlert_Settings = {}


-- --- Helper Function: Raid Assist (v1.1) ---
function TankAlert_IsRaidAssist()
    -- (This function is unchanged)
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
    -- (This function is unchanged)
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

-- --- Helper Function to "normalize" ability names (v1.4) ---
function TankAlert_GetAbilityKey(name)
    -- (This function is unchanged)
    if (name == "Taunt") then return "Taunt" end
    if (name == "Sunder Armor") then return "SunderArmor" end
    if (name == "Shield Slam") then return "ShieldSlam" end
    if (name == "Revenge") then return "Revenge" end
    if (name == "Mocking Blow") then return "MockingBlow" end
    if (name == "Growl") then return "Growl" end
    return nil
end


-- Set the script
tankAlert_Frame:SetScript("OnEvent", function()

    -- Check the GLOBAL variable 'event'
    
    if event == "PLAYER_ENTERING_WORLD" then
        
        -- --- Settings Loader (v1.5) ---
        local _, classKey = UnitClass("player")
        TankAlert_PlayerClass = classKey 
        if (TankAlert_Settings == nil or type(TankAlert_Settings) ~= "table") then
            TankAlert_Settings = {}
        end
        if (TankAlert_Settings.global == nil or type(TankAlert_Settings.global) ~= "table") then
            TankAlert_Settings.global = TankAlert_Defaults.global
        else
            for key, value in pairs(TankAlert_Defaults.global) do
                if (TankAlert_Settings.global[key] == nil) then
                    TankAlert_Settings.global[key] = value
                end
            end
        end
        if (TankAlert_Defaults[TankAlert_PlayerClass]) then
            if (TankAlert_Settings[TankAlert_PlayerClass] == nil or type(TankAlert_Settings[TankAlert_PlayerClass]) ~= "table") then
                TankAlert_Settings[TankAlert_PlayerClass] = TankAlert_Defaults[TankAlert_PlayerClass]
            end
            if (TankAlert_Settings[TankAlert_PlayerClass].abilities == nil or type(TankAlert_Settings[TankAlert_PlayerClass].abilities) ~= "table") then
                TankAlert_Settings[TankAlert_PlayerClass].abilities = TankAlert_Defaults[TankAlert_PlayerClass].abilities
            end
            for key, value in pairs(TankAlert_Defaults[TankAlert_PlayerClass].abilities) do
                if (TankAlert_Settings[TankAlert_PlayerClass].abilities[key] == nil) then
                    TankAlert_Settings[TankAlert_PlayerClass].abilities[key] = value
                end
            end
        end

        
        -- --- Event Registration (v1.5) ---
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        tankAlert_Frame:RegisterEvent("UI_ERROR_MESSAGE")
        
        TankAlert_Last_CC_Alert_Time = 0
        TankAlert_Last_Disarm_Alert_Time = 0

        local status = "|cffFF0000DISABLED|r"
        if (TankAlert_Settings.global.enabled) then
            status = "|cff00FF00ENABLED|r"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r TankAlert is now active for |cffFFFFFF" .. TankAlert_PlayerClass .. "|r. (" .. status .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Type |cffFFFFFF/ta|r for options.")
        
        tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
    
    -- --- Master Toggle Check ---
    if (TankAlert_Settings.global.enabled == false) then
        return
    end
    
    
    -- --- UI Error Handler (v1.5.1) ---
    if event == "UI_ERROR_MESSAGE" then
        local msg = arg1
        if (not msg) then return end
        
        local alertType = nil 
        local alertMessage = nil

        -- 1. Check for Loss of Control
        if (TankAlert_Settings.global.announceCC) then
            if (msg == "Can't do that while stunned") then
                alertType = "CC"
                alertMessage = "STUNNED"
            elseif (msg == "Can't do that while feared") then
                alertType = "CC"
                alertMessage = "FEARED"
            end
            
            -- Druid Form Check
            if (alertType == "CC" and TankAlert_PlayerClass == "DRUID") then
                local isInBearForm = false
                for i = 1, 6 do 
                    local _, name, isActive = GetShapeshiftFormInfo(i)
                    if (isActive and (name == "Bear Form" or name == "Dire Bear Form")) then
                        isInBearForm = true
                        break
                    end
                end
                
                if (not isInBearForm) then
                    alertType = nil
                end
            end
            
        end
        
        -- 2. Check for Disarm
        if (not alertType and TankAlert_Settings.global.announceDisarm) then
            if (msg == "Must have a Melee Weapon equipped in the main hand") then
                if (GetInventoryItemLink("player", 16) ~= nil) then
                    alertType = "DISARM"
                    alertMessage = "DISARMED"
                end
            end
        end
        
        -- 3. If we have an alert, check the *correct* throttle
        if (alertType) then
            local now = GetTime()
            local throttle = TankAlert_Settings.global.alertThrottle
            local canAnnounce = false
            
            if (alertType == "CC") then
                if (now > (TankAlert_Last_CC_Alert_Time + throttle)) then
                    TankAlert_Last_CC_Alert_Time = now
                    canAnnounce = true
                end
            elseif (alertType == "DISARM") then
                if (now > (TankAlert_Last_Disarm_Alert_Time + throttle)) then
                    TankAlert_Last_Disarm_Alert_Time = now
                    canAnnounce = true
                end
            end

            -- 4. If we can announce, build and send
            if (canAnnounce) then
                local channel = "SAY"
                if (TankAlert_Settings.global.forceChannel ~= "auto") then
                    channel = string.upper(TankAlert_Settings.global.forceChannel)
                else
                    if (GetNumRaidMembers() > 0) then
                        if (TankAlert_IsRaidAssist()) then
                            channel = "RAID_WARNING"
                        else
                            channel = "RAID"
                        end
                    elseif (GetNumPartyMembers() > 0) then
                        channel = "PARTY"
                    end
                end
                
                local finalMessage = ""
                if (channel == "RAID_WARNING") then
                    local targetName = UnitName("target")
                    local targetInfo = ""
                    if (targetName) then
                        local iconIndex = GetRaidTargetIndex("target")
                        local iconText = TankAlert_GetRaidIconName(iconIndex)
                        if (iconText ~= "") then
                            targetInfo = "on " .. iconText .. " " .. targetName
                        else
                            targetInfo = "on " .. targetName
                        end
                    end
                    finalMessage = UnitName("player") .. " is " .. alertMessage .. "! Watch threat " .. targetInfo .. "!"
                else
                    finalMessage = "I'm " .. alertMessage .. "! Watch threat!"
                end
                
                SendChatMessage(finalMessage, channel)
            end
        end
        return
    end
    

    -- --- Main Ability Failure Handler ---
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- (This entire section is unchanged)
        local msg = arg1
        local abilityName = nil
        local targetName = nil
        local failureType = nil 

        if (not msg) then return end

        if (TankAlert_PlayerClass == "WARRIOR") then
            if (string.find(msg, "Taunt") and string.find(msg, "resisted")) then
                abilityName = "Taunt"
                failureType = "RESISTED"
                _, _, targetName = string.find(msg, "resisted by (.+)")
            elseif (string.find(msg, "Sunder Armor") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
                abilityName = "Sunder Armor"
                if (string.find(msg, "dodged")) then failureType = "DODGED"
                    _, _, targetName = string.find(msg, "dodged by (.+)")
                elseif (string.find(msg, "parried")) then failureType = "PARRIED"
                    _, _, targetName = string.find(msg, "parried by (.+)")
                elseif (string.find(msg, "missed")) then failureType = "MISSED"
                    _, _, targetName = string.find(msg, "missed (.+)")
                end
            elseif (string.find(msg, "Shield Slam") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
                abilityName = "Shield Slam"
                if (string.find(msg, "dodged")) then failureType = "DODGED"
                    _, _, targetName = string.find(msg, "dodged by (.+)")
                elseif (string.find(msg, "parried")) then failureType = "PARRIED"
                    _, _, targetName = string.find(msg, "parried by (.+)")
                elseif (string.find(msg, "missed")) then failureType = "MISSED"
                    _, _, targetName = string.find(msg, "missed (.+)")
                end
            elseif (string.find(msg, "Revenge") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
                abilityName = "Revenge"
                if (string.find(msg, "dodged")) then failureType = "DODGED"
                    _, _, targetName = string.find(msg, "dodged by (.+)")
                elseif (string.find(msg, "parried")) then failureType = "PARRIED"
                    _, _, targetName = string.find(msg, "parried by (.+)")
                elseif (string.find(msg, "missed")) then failureType = "MISSED"
                    _, _, targetName = string.find(msg, "missed (.+)")
                end
            elseif (string.find(msg, "Mocking Blow") and (string.find(msg, "dodged") or string.find(msg, "parried") or string.find(msg, "missed"))) then
                abilityName = "Mocking Blow"
                if (string.find(msg, "dodged")) then failureType = "DODGED"
                    _, _, targetName = string.find(msg, "dodged by (.+)")
                elseif (string.find(msg, "parried")) then failureType = "PARRIED"
                    _, _, targetName = string.find(msg, "parried by (.+)")
                elseif (string.find(msg, "missed")) then failureType = "MISSED"
                    _, _, targetName = string.find(msg, "missed (.+)")
                end
            end
        elseif (TankAlert_PlayerClass == "DRUID") then
            if (string.find(msg, "Growl") and string.find(msg, "resisted")) then
                abilityName = "Growl"
                failureType = "RESISTED"
                _, _, targetName = string.find(msg, "resisted by (.+)")
            end
        end

        if (abilityName and failureType) then
            local abilityKey = TankAlert_GetAbilityKey(abilityName)
            if (abilityKey == nil or TankAlert_Settings[TankAlert_PlayerClass] == nil or TankAlert_Settings[TankAlert_PlayerClass].abilities[abilityKey] == false) then
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
                messageBody = abilityName .. " " .. failureType .. " on " .. targetInfo .. ". Watch threat!"
            else
                messageBody = abilityName .. " " .. failureType .. ". Watch threat!"
            end

            if (messageBody ~= "") then
                local channel = "SAY"
                local messagePrefix = ""
                
                if (TankAlert_Settings.global.forceChannel ~= "auto") then
                    channel = string.upper(TankAlert_Settings.global.forceChannel)
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


-- --- UPDATED: Slash Command Handler (v1.5.1) ---
SlashCmdList["TANKALERT"] = function(msg)
    -- FIX 1: Use 1.12-safe string functions and parse manually
    local rawmsg = _strlower(msg or "")
    local cmd = ""
    local arg = ""
    
    local spacePos = _strfind(rawmsg, " ") -- Find the first space
    
    if (spacePos) then
        -- Command is everything before the space
        cmd = _strsub(rawmsg, 1, spacePos - 1)
        -- Argument is everything after the space (and lowercased)
        arg = _strsub(rawmsg, spacePos + 1)
    else
        -- No space, so the whole message is the command
        cmd = rawmsg
    end
    
    
    local classSettings = TankAlert_Settings[TankAlert_PlayerClass]

    if (cmd == "toggle") then
        local abilityKey = nil
        
        -- (This logic is unchanged)
        if (arg == "cc") then
            TankAlert_Settings.global.announceCC = not TankAlert_Settings.global.announceCC
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r CC alerts (Stun/Fear): " .. (TankAlert_Settings.global.announceCC and "ON" or "OFF"))
            return
        elseif (arg == "disarm") then
            TankAlert_Settings.global.announceDisarm = not TankAlert_Settings.global.announceDisarm
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Disarm alerts: " .. (TankAlert_Settings.global.announceDisarm and "ON" or "OFF"))
            return
        end
        
        if (classSettings and classSettings.abilities) then
            if (arg == "taunt") then abilityKey = "Taunt"
            elseif (arg == "sunder") then abilityKey = "SunderArmor"
            elseif (arg == "shieldslam") then abilityKey = "ShieldSlam"
            elseif (arg == "revenge") then abilityKey = "Revenge"
            elseif (arg == "mocking" or arg == "mockingblow") then abilityKey = "MockingBlow"
            elseif (arg == "growl") then abilityKey = "Growl"
            end
        end

        if (abilityKey and classSettings.abilities[abilityKey] ~= nil) then
            classSettings.abilities[abilityKey] = not classSettings.abilities[abilityKey]
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r " .. abilityKey .. " alerts: " .. (classSettings.abilities[abilityKey] and "ON" or "OFF"))
        else
            TankAlert_Settings.global.enabled = not TankAlert_Settings.global.enabled
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now " .. (TankAlert_Settings.global.enabled and "|cff00FF00ENABLED|r." or "|cffFF0000DISABLED|r."))
        end
        
    elseif (cmd == "force") then
        -- (This logic is unchanged)
        if (arg == "party") then
            TankAlert_Settings.global.forceChannel = "party"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFPARTY|r chat.")
        elseif (arg == "raid") then
            TankAlert_Settings.global.forceChannel = "raid"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFRAID|r chat.")
        elseif (arg == "say") then
            TankAlert_Settings.global.forceChannel = "say"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Forcing all announcements to |cffFFFFFFSAY|r.")
        elseif (arg == "auto") then
            TankAlert_Settings.global.forceChannel = "auto"
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements set to |cffFFFFFFAUTO|r-detect channel.")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Unknown channel. Use: |cffFFFFFF/ta force [auto | party | raid | say]|r")
        end

    elseif (cmd == "on") then
        -- (This logic is unchanged)
        TankAlert_Settings.global.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cff00FF00ENABLED|r.")
        
    elseif (cmd == "off") or (cmd == "stop") then
        -- (This logic is unchanged)
        TankAlert_Settings.global.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cffFF0000DISABLED|r.")
        
    else
        -- --- Dynamic Status Menu (v1.5) ---
        -- (This logic is unchanged)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00------ [TankAlert Status] ------|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Class:|r |cffFFFFFF" .. TankAlert_PlayerClass .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Master Toggle:|r " .. (TankAlert_Settings.global.enabled and "|cff00FF00ENABLED|r" or "|cffFF0000DISABLED|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Force Channel:|r |cffFFFFFF" .. string.upper(TankAlert_Settings.global.forceChannel) .. "|r")
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Global Alerts:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFCC (Stun/Fear):|r " .. (TankAlert_Settings.global.announceCC and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFDisarm:|r " .. (TankAlert_Settings.global.announceDisarm and "ON" or "OFF"))

        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Tracked Abilities:|r")
        if (classSettings and classSettings.abilities) then
            for ability, enabled in pairs(classSettings.abilities) do
                DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFF" .. ability .. ":|r " .. (enabled and "ON" or "OFF"))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  |cffFF0000No abilities configured for your class.|r")
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00------ [Commands] ------|r")
        DEFAULT_CHAT_FRAME:AddMessage("/ta [on | off | toggle] - Master switch.")
        DEFAULT_CHAT_FRAME:AddMessage("/ta force [auto | party | raid | say]")
        
        local toggleHelp = "/ta toggle [cc | disarm | "
        if (classSettings and classSettings.abilities) then
            for ability, enabled in pairs(classSettings.abilities) do
                toggleHelp = toggleHelp .. _strlower(ability) .. " | "
            end
            toggleHelp = string.sub(toggleHelp, 1, -4)
        end
        toggleHelp = toggleHelp .. "]"
        DEFAULT_CHAT_FRAME:AddMessage(toggleHelp)
    end
end

-- Create the /ta slash command
SLASH_TANKALERT1 = "/ta"