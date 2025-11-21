-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- Throttle Timers (v1.5) ---
local TankAlert_Last_CC_Alert_Time = 0
local TankAlert_Last_Disarm_Alert_Time = 0

-- --- v1.6 Threat Data ---
local TankAlert_CurrentThreat = {}
local TankAlert_WhisperThrottle = {}
local TankAlert_PlayerClass = nil -- Localized for safety

-- --- 1.12-Safe String Functions (v1.6.3) ---
local _strlower = string.lower
local _strfind = string.find
local _strsub = string.sub
local _strgsub = string.gsub
local _tonumber = tonumber
local _tinsert = table.insert
local _tremove = table.remove
local _strupper = string.upper
local _strlen = string.len

-- --- Addon Settings (v1.6) ---
local TankAlert_Defaults = {
    global = {
        enabled = true,
        forceChannel = "auto",
        announceCC = true,
        announceDisarm = true,
        alertThrottle = 8,
        announceThreatWhisper = true,
        threatWhisperThreshold = 90,
        whisperThrottle = 15,
        onlyTankWhispers = true,
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
    if (iconIndex == 1) then
        return "|cffFFFF00[Star]|r"
    elseif (iconIndex == 2) then
        return "|cffFFA500[Circle]|r"
    elseif (iconIndex == 3) then
        return "|cffC800FF[Diamond]|r"
    elseif (iconIndex == 4) then
        return "|cff00FF00[Triangle]|r"
    elseif (iconIndex == 5) then
        return "|cffFFFFFF[Moon]|r"
    elseif (iconIndex == 6) then
        return "|cff0070FF[Square]|r"
    elseif (iconIndex == 7) then
        return "|cffFF0000[Cross]|r"
    elseif (iconIndex == 8) then
        return "|cffFFFFFF[Skull]|r"
    else
        return ""
    end
end

-- --- Ability Name Lookup Table (v1.6.4) ---
local TankAlert_AbilityKeyLookup = {
    ["Taunt"] = "Taunt",
    ["Sunder Armor"] = "SunderArmor",
    ["Shield Slam"] = "ShieldSlam",
    ["Revenge"] = "Revenge",
    ["Mocking Blow"] = "MockingBlow",
    ["Growl"] = "Growl",
}

-- --- Helper Function to "normalize" ability names (v1.4) ---
function TankAlert_GetAbilityKey(name)
    return TankAlert_AbilityKeyLookup[name]
end

-- --- Ability Detection Patterns (v1.6.3) ---
local TankAlert_AbilityPatterns = {
    WARRIOR = {
        {name = "Taunt", pattern = "Taunt", failure = "resisted", extract = "resisted by (.+)"},
        {name = "Sunder Armor", pattern = "Sunder Armor", failures = {"dodged", "parried", "missed"}},
        {name = "Shield Slam", pattern = "Shield Slam", failures = {"dodged", "parried", "missed"}},
        {name = "Revenge", pattern = "Revenge", failures = {"dodged", "parried", "missed"}},
        {name = "Mocking Blow", pattern = "Mocking Blow", failures = {"dodged", "parried", "missed"}},
    },
    DRUID = {
        {name = "Growl", pattern = "Growl", failure = "resisted", extract = "resisted by (.+)"},
    }
}

-- --- Helper Function to detect ability failures (v1.6.3) ---
function TankAlert_DetectAbilityFailure(msg, classKey)
    local abilityName = nil
    local targetName = nil
    local failureType = nil
    
    local classAbilities = TankAlert_AbilityPatterns[classKey]
    if (not classAbilities) then return nil, nil, nil end
    
    for _, ability in ipairs(classAbilities) do
        if (_strfind(msg, ability.pattern)) then
            local failureList = ability.failure
            if (failureList) then
                if (type(failureList) == "string") then
                    failureList = {failureList}
                end
            else
                failureList = ability.failures or {}
            end
            
            for _, failure in ipairs(failureList) do
                if (_strfind(msg, failure)) then
                    abilityName = ability.name
                    failureType = _strlower(failure) == "resisted" and "RESISTED" or _strupper(failure)
                    
                    if (ability.extract) then
                        _, _, targetName = _strfind(msg, ability.extract)
                    else
                        if (failure == "missed") then
                            _, _, targetName = _strfind(msg, "missed%s+(.+)")
                        else
                            local extractPattern = failure .. "%s+by%s+(.+)"
                            _, _, targetName = _strfind(msg, extractPattern)
                        end
                    end
                    
                    return abilityName, failureType, targetName
                end
            end
        end
    end
    
    return nil, nil, nil
end

-- --- Error Logging Helper (v1.6.6) ---
local function TankAlert_LogError(functionName, errorMsg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[TankAlert Error]|r " .. functionName .. ": " .. (errorMsg or "Unknown error"))
end

local function TankAlert_LogWarning(functionName, warningMsg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFF8800[TankAlert Warning]|r " .. functionName .. ": " .. (warningMsg or "Unknown warning"))
end

-- --- Helper Function to parse the TWTv4 string (v1.6) ---
function TankAlert_ParseTWTMessage(msg)
    if (not msg or type(msg) ~= "string") then
        TankAlert_LogError("TankAlert_ParseTWTMessage", "Invalid message parameter")
        return
    end
    
    for k in pairs(TankAlert_CurrentThreat) do
        TankAlert_CurrentThreat[k] = nil
    end
    
    local _, _, dataString = _strfind(msg, "TWTv4=(.+)")
    if (not dataString) then return end
    
    local playerIndex = 1
    local playerString = ""
    local parseCount = 0
    
    while (playerString) do
        local splitStart, splitEnd = _strfind(dataString, ";", playerIndex)
        
        if (splitStart) then
            playerString = _strsub(dataString, playerIndex, splitStart - 1)
            playerIndex = splitEnd + 1
        else
            playerString = _strsub(dataString, playerIndex)
            playerIndex = -1
        end
        
        local d1, d2, d3, d4, d5
        local i1, i2, i3, i4
        
        i1 = _strfind(playerString, ":", 1, true)
        if (i1) then d1 = _strsub(playerString, 1, i1 - 1) end
        
        i2 = _strfind(playerString, ":", i1 and (i1 + 1) or 1, true)
        if (i2 and i1) then d2 = _strsub(playerString, i1 + 1, i2 - 1) end
        
        i3 = _strfind(playerString, ":", i2 and (i2 + 1) or 1, true)
        if (i3 and i2) then d3 = _strsub(playerString, i2 + 1, i3 - 1) end
        
        i4 = _strfind(playerString, ":", i3 and (i3 + 1) or 1, true)
        if (i4 and i3) then
            d4 = _strsub(playerString, i3 + 1, i4 - 1)
            d5 = _strsub(playerString, i4 + 1)
        end
        
        if (d1 and d2 and d3 and d4 and d5) then
            local threat = _tonumber(d3)
            local percent = _tonumber(d4)
            
            if (not threat or not percent) then
                TankAlert_LogWarning("TankAlert_ParseTWTMessage", "Failed to parse threat/percent for " .. (d1 or "UNKNOWN"))
            else
                TankAlert_CurrentThreat[d1] = {
                    isTank = (d2 == "1"),
                    threat = threat,
                    percent = percent,
                    isMelee = (d5 == "1"),
                }
                parseCount = parseCount + 1
            end
        end
        
        if (playerIndex == -1) then break end
    end
end


-- --- OnUpdate Frame for Threat Checks (v1.6.1) ---
local threatCheckFrame = CreateFrame("Frame")
threatCheckFrame:Hide()
local threatCheckTimer = 0
threatCheckFrame:SetScript("OnUpdate", function()
    local elapsed = arg1
    if (not elapsed or type(elapsed) ~= "number") then
        elapsed = 0
    end

    threatCheckTimer = threatCheckTimer + elapsed
    
    if (threatCheckTimer > 2) then
        threatCheckTimer = 0
        
        if (not TankAlert_Settings.global.announceThreatWhisper) then return end
        
        local myName = UnitName("player")

        -- If "Only Tank Whispers" is enabled, we check if WE are the tank.
        if (TankAlert_Settings.global.onlyTankWhispers) then
            local myData = TankAlert_CurrentThreat[myName]
            
            -- If I am not in the threat list, or I am not marked as the tank (isTank != true),
            -- then I should NOT send whispers. I leave that to the Main Tank.
            if (not myData or not myData.isTank) then
                return
            end
        end

        local threshold = TankAlert_Settings.global.threatWhisperThreshold
        
        for name, data in pairs(TankAlert_CurrentThreat) do
            if (name ~= myName and not data.isTank and data.percent and data.percent > threshold) then
                
                local now = GetTime()
                local lastWhisper = TankAlert_WhisperThrottle[name] or 0
                
                if (now > (lastWhisper + TankAlert_Settings.global.whisperThrottle)) then
                    local mobName = UnitName("target") or "the mob"
                    local whisperMsg = "[TankAlert] Careful! You are at " .. math.floor(data.percent) .. "% threat on " .. mobName .. "!"
                    
                    SendChatMessage(whisperMsg, "WHISPER", nil, name)
                    
                    TankAlert_WhisperThrottle[name] = now
                end
            end
        end
    end
end)

-- --- OnEvent Script ---
tankAlert_Frame:SetScript("OnEvent", function()
    local event = event
    local arg1 = arg1
    local arg2 = arg2
    
    if event == "PLAYER_ENTERING_WORLD" then
        
        _, TankAlert_PlayerClass = UnitClass("player")

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
        
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        tankAlert_Frame:RegisterEvent("UI_ERROR_MESSAGE")
        tankAlert_Frame:RegisterEvent("CHAT_MSG_ADDON")
        
        tankAlert_Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        tankAlert_Frame:RegisterEvent("PLAYER_REGEN_ENABLED")

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
    
    if (TankAlert_Settings.global.enabled == false) then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        threatCheckTimer = 0
        threatCheckFrame:Show()
        for k in pairs(TankAlert_WhisperThrottle) do
            TankAlert_WhisperThrottle[k] = nil
        end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        threatCheckFrame:Hide()
        for k in pairs(TankAlert_CurrentThreat) do
            TankAlert_CurrentThreat[k] = nil
        end
        return
    end
    
    -- --- CHAT_MSG_ADDON Handler (v1.6.3) ---
    if event == "CHAT_MSG_ADDON" then
        local prefix = arg1
        local msg = arg2
        local sender = arg4
        
        if (not prefix or not msg) then
            TankAlert_LogWarning("CHAT_MSG_ADDON", "Null prefix or message received")
            return
        end
        
        if (_strfind(prefix, "TWT")) then
            if (_strfind(msg, "TWTv4=")) then
                TankAlert_ParseTWTMessage(msg)
            end
        end
        return
    end
    
    if event == "UI_ERROR_MESSAGE" then
        local msg = arg1
        if (not msg) then return end
        
        local alertType = nil 
        local alertMessage = nil

        if (TankAlert_Settings.global.announceCC) then
            if (msg == "Can't do that while stunned") then
                alertType = "CC"
                alertMessage = "STUNNED"
            elseif (msg == "Can't do that while feared") then
                alertType = "CC"
                alertMessage = "FEARED"
            end
            
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
        
        if (not alertType and TankAlert_Settings.global.announceDisarm) then
            if (msg == "Must have a Melee Weapon equipped in the main hand") then
                if (GetInventoryItemLink("player", 16) ~= nil) then
                    alertType = "DISARM"
                    alertMessage = "DISARMED"
                end
            end
        end
        
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

            if (canAnnounce) then
                local channel = "SAY"
                if (TankAlert_Settings.global.forceChannel ~= "auto") then
                    channel = _strupper(TankAlert_Settings.global.forceChannel)
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
    
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local msg = arg1
        if (not msg) then return end

        if (not TankAlert_PlayerClass) then
            TankAlert_LogError("CHAT_MSG_SPELL_SELF_DAMAGE", "TankAlert_PlayerClass not initialized")
            return
        end

        local abilityName, failureType, targetName = TankAlert_DetectAbilityFailure(msg, TankAlert_PlayerClass)

        if (abilityName and failureType) then
            if (not TankAlert_Settings or not TankAlert_Settings[TankAlert_PlayerClass]) then
                TankAlert_LogError("CHAT_MSG_SPELL_SELF_DAMAGE", "Settings for class " .. TankAlert_PlayerClass .. " not found")
                return
            end
            
            local abilityKey = TankAlert_GetAbilityKey(abilityName)
            if (abilityKey == nil or TankAlert_Settings[TankAlert_PlayerClass].abilities[abilityKey] == false) then
                return
            end
            
            local messageBody = ""
            local targetInfo = "" 
            if (targetName) then
                targetName = _strgsub(targetName, "%p$", "")
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
                    channel = _strupper(TankAlert_Settings.global.forceChannel)
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


-- --- Slash Command Handler (v1.6.3) ---
SlashCmdList["TANKALERT"] = function(msg)
    local rawmsg = _strlower(msg or "")
    local cmd = ""
    local arg = ""
    local spacePos = _strfind(rawmsg, " ")
    
    if (spacePos) then
        cmd = _strsub(rawmsg, 1, spacePos - 1)
        arg = _strsub(rawmsg, spacePos + 1)
    else
        cmd = rawmsg
    end
    
    if (not TankAlert_Settings or not TankAlert_Settings.global) then
        TankAlert_LogError("SlashCommand", "Settings not initialized. Wait for addon to fully load.")
        return
    end
    
    local classSettings = TankAlert_Settings[TankAlert_PlayerClass]

    if (cmd == "toggle") then
        local abilityKey = nil
        
        if (arg == "cc") then
            TankAlert_Settings.global.announceCC = not TankAlert_Settings.global.announceCC
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r CC alerts (Stun/Fear): " .. (TankAlert_Settings.global.announceCC and "ON" or "OFF"))
            return
        elseif (arg == "disarm") then
            TankAlert_Settings.global.announceDisarm = not TankAlert_Settings.global.announceDisarm
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Disarm alerts: " .. (TankAlert_Settings.global.announceDisarm and "ON" or "OFF"))
            return
        elseif (arg == "whisper") then
            TankAlert_Settings.global.announceThreatWhisper = not TankAlert_Settings.global.announceThreatWhisper
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Threat Whispers: " .. (TankAlert_Settings.global.announceThreatWhisper and "ON" or "OFF"))
            return
        elseif (arg == "tankonly") then
            TankAlert_Settings.global.onlyTankWhispers = not TankAlert_Settings.global.onlyTankWhispers
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Only Whisper if Tanking: " .. (TankAlert_Settings.global.onlyTankWhispers and "ON" or "OFF"))
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

    elseif (cmd == "set") then
        local key, val
        local spacePos_set = _strfind(arg, " ")
        if (spacePos_set) then
            key = _strsub(arg, 1, spacePos_set - 1)
            val = _strsub(arg, spacePos_set + 1)
        end

        if (key == "threshold") then
            local num = _tonumber(val)
            if (num and num >= 50 and num <= 100) then
                TankAlert_Settings.global.threatWhisperThreshold = num
                DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Threat whisper threshold set to |cffFFFFFF" .. num .. "%|r.")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Invalid threshold. Must be a number between 50 and 100.")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Unknown command. Try: |cffFFFFFF/ta set threshold 90|r")
        end

    elseif (cmd == "on") then
        TankAlert_Settings.global.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cff00FF00ENABLED|r.")
        
    elseif (cmd == "off") or (cmd == "stop") then
        TankAlert_Settings.global.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Announcements are now |cffFF0000DISABLED|r.")
    else
        -- --- Dynamic Status Menu (v1.6) ---
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00------ [TankAlert Status] ------|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Class:|r |cffFFFFFF" .. TankAlert_PlayerClass .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Master Toggle:|r " .. (TankAlert_Settings.global.enabled and "|cff00FF00ENABLED|r" or "|cffFF0000DISABLED|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Force Channel:|r |cffFFFFFF" .. _strupper(TankAlert_Settings.global.forceChannel) .. "|r")
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00Global Alerts:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFCC (Stun/Fear):|r " .. (TankAlert_Settings.global.announceCC and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFDisarm:|r " .. (TankAlert_Settings.global.announceDisarm and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFFThreat Whispers:|r " .. (TankAlert_Settings.global.announceThreatWhisper and "ON" or "OFF") .. " (at " .. TankAlert_Settings.global.threatWhisperThreshold .. "%)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffFFFFFF  - Only if I am Tank:|r " .. (TankAlert_Settings.global.onlyTankWhispers and "ON" or "OFF"))

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
        DEFAULT_CHAT_FRAME:AddMessage("/ta set threshold [50-100]")
        
        -- FIXED: Added "tankonly" to the help string so users know it exists
        local toggleHelp = "/ta toggle [cc | disarm | whisper | tankonly | "
        if (classSettings and classSettings.abilities) then
            for ability, enabled in pairs(classSettings.abilities) do
                toggleHelp = toggleHelp .. _strlower(ability) .. " | "
            end
            toggleHelp = _strsub(toggleHelp, 1, -4)
        end
        toggleHelp = toggleHelp .. "]"
        DEFAULT_CHAT_FRAME:AddMessage(toggleHelp)
    end
end

-- Create the /ta slash command
SLASH_TANKALERT1 = "/ta"