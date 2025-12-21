-- TankAlert (v1.9)
-- Create our main frame
local tankAlert_Frame = CreateFrame("Frame")

-- --- Throttle Timers (v1.5) ---
local TankAlert_Last_CC_Alert_Time = 0
local TankAlert_Last_Disarm_Alert_Time = 0

-- --- v1.9 Combat Tracking ---
local TankAlert_CombatStartTime = 0

-- --- v1.6 Threat Data ---
local TankAlert_CurrentThreat = {}
local TankAlert_WhisperThrottle = {}
local TankAlert_PlayerClass = nil -- Localized for safety
local TankAlert_Version = "1.9"

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
local _format = string.format

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
    },
    PALADIN = {
        abilities = {
            HandOfReckoning = true,
            HolyStrike = true,
        }
    },
    SHAMAN = {
        abilities = {
            EarthshakerSlam = true, -- The Main Taunt
            EarthShock = true,
            FrostShock = true,
            LightningStrike = true, 
            Stormstrike = true,
        }
    }
}

-- =========================================================================
--  GUI ENGINE (v1.7)
--  Pure Lua Interface for Vanilla 1.12
-- =========================================================================

local TankAlert_GUI = {
    frame = nil,
    widgets = {}
}

-- --- GUI Helpers: Display Names & Order ---
local TankAlert_AbilityDisplayNames = {
    ["Taunt"] = "Taunt",
    ["SunderArmor"] = "Sunder Armor",
    ["ShieldSlam"] = "Shield Slam",
    ["Revenge"] = "Revenge",
    ["MockingBlow"] = "Mocking Blow",
    ["Growl"] = "Growl",
    -- v1.8 Paladin
    ["HandOfReckoning"] = "Hand of Reckoning",
    ["HolyStrike"] = "Holy Strike",
    -- v1.8 Shaman
    ["EarthshakerSlam"] = "Earthshaker Slam",
    ["EarthShock"] = "Earth Shock",
    ["FrostShock"] = "Frost Shock",
    ["LightningStrike"] = "Lightning Strike",
    ["Stormstrike"] = "Stormstrike"
}

-- Explicit order to ensure consistent layout (Col 1 then Col 2)
local TankAlert_AbilityOrder = {
    WARRIOR = {"SunderArmor", "Revenge", "ShieldSlam", "Taunt", "MockingBlow"},
    DRUID = {"Growl"},
    PALADIN = {"HandOfReckoning", "HolyStrike"},
    SHAMAN = {"EarthshakerSlam", "EarthShock", "LightningStrike", "Stormstrike", "FrostShock"}
}

-- --- Widget Factory: Checkbox ---
local function GUI_CreateCheckbox(parent, x, y, labelText, tooltipText, onClickFunc)
    -- Generate a unique name for the global scope (Required by 1.12 templates)
    local name = "TA_Check_" .. string.gsub(labelText, "%s+", "") .. math.random(1000)
    
    local cb = CreateFrame("CheckButton", name, parent, "OptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- Set Label
    getglobal(name.."Text"):SetText(labelText)
    
    -- Handle Click
    cb:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        if (onClickFunc) then onClickFunc(isChecked) end
    end)
    
    -- Handle Tooltip
    cb:SetScript("OnEnter", function()
        if (tooltipText) then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(labelText, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, nil, nil, nil, 1)
            GameTooltip:Show()
        end
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    return cb
end

-- --- Widget Factory: Slider ---
local function GUI_CreateSlider(parent, x, y, minVal, maxVal, labelText, onChangeFunc)
    local name = "TA_Slider_" .. math.random(1000)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(180)
    slider:SetHeight(16)
    
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    
    -- Labels
    getglobal(name.."Text"):SetText(labelText)
    getglobal(name.."Low"):SetText(minVal.."%")
    getglobal(name.."High"):SetText(maxVal.."%")
    
    -- Value Display (Create a font string to show current value)
    local valText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valText:SetPoint("TOP", slider, "BOTTOM", 0, 3)
    valText:SetText(slider:GetValue())
    
    slider:SetScript("OnValueChanged", function()
        local val = math.floor(this:GetValue())
        valText:SetText(val .. "%")
        if (onChangeFunc) then onChangeFunc(val) end
    end)
    
    return slider
end

-- --- Initialize the Main Window ---
local function TankAlert_InitGUI()
    if (TankAlert_GUI.frame) then return end -- Already initialized

    -- 1. Create Main Frame
    local f = CreateFrame("Frame", "TankAlertOptions", UIParent)
    f:SetWidth(400)
    f:SetHeight(520)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Make movable
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Header
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("TankAlert v" .. TankAlert_Version)
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    
    TankAlert_GUI.frame = f
    f:Hide() -- Hide by default

    -- ====================
    -- SECTION 1: GLOBAL
    -- ====================
    local y = -50
    local x = 20
    
    TankAlert_GUI.widgets.master = GUI_CreateCheckbox(f, x, y, "Enable Addon", "Master switch for TankAlert.", function(checked)
        TankAlert_Settings.global.enabled = checked
        if (checked) then 
             DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Enabled.")
        else
             DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[TankAlert]|r Disabled.")
        end
    end)
    
    y = y - 30
    TankAlert_GUI.widgets.cc = GUI_CreateCheckbox(f, x, y, "Announce CC", "Announce when Stunned or Feared.", function(checked)
        TankAlert_Settings.global.announceCC = checked
    end)
    
    TankAlert_GUI.widgets.disarm = GUI_CreateCheckbox(f, x+150, y, "Announce Disarm", "Announce when Disarmed.", function(checked)
        TankAlert_Settings.global.announceDisarm = checked
    end)

    -- ====================
    -- SECTION 2: THREAT
    -- ====================
    y = y - 40
    local headerThreat = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerThreat:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    headerThreat:SetText("Threat Whispers (Requires TWThreat)")
    
    y = y - 20
    TankAlert_GUI.widgets.whisper = GUI_CreateCheckbox(f, x, y, "Enable Whispers", "Whisper players approaching aggro.", function(checked)
        TankAlert_Settings.global.announceThreatWhisper = checked
    end)
    
    y = y - 30
    TankAlert_GUI.widgets.tankonly = GUI_CreateCheckbox(f, x, y, "Only if I am Tank", "Only send whispers if YOU are the Main Tank.", function(checked)
        TankAlert_Settings.global.onlyTankWhispers = checked
    end)

    y = y - 40
    TankAlert_GUI.widgets.threshold = GUI_CreateSlider(f, x+10, y, 50, 100, "Whisper Threshold %", function(val)
        TankAlert_Settings.global.threatWhisperThreshold = val
    end)

    -- ====================
    -- SECTION 3: CHANNEL
    -- ====================
    y = y - 50
    local headerChan = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerChan:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    headerChan:SetText("Output Channel")
    
    y = y - 20
    -- Radio button simulation
    local function UpdateChannels(selected)
        TankAlert_Settings.global.forceChannel = selected
        TankAlert_GUI.widgets.chanAuto:SetChecked(selected == "auto")
        TankAlert_GUI.widgets.chanSay:SetChecked(selected == "say")
        TankAlert_GUI.widgets.chanParty:SetChecked(selected == "party")
        TankAlert_GUI.widgets.chanRaid:SetChecked(selected == "raid")
    end
    
    TankAlert_GUI.widgets.chanAuto = GUI_CreateCheckbox(f, x, y, "Auto", "Smart detection (Raid/Party).", function() UpdateChannels("auto") end)
    TankAlert_GUI.widgets.chanSay = GUI_CreateCheckbox(f, x+150, y, "Say", "Force Say.", function() UpdateChannels("say") end)
    
    y = y - 26 -- Move down for second row
    TankAlert_GUI.widgets.chanParty = GUI_CreateCheckbox(f, x, y, "Party", "Force Party.", function() UpdateChannels("party") end)
    TankAlert_GUI.widgets.chanRaid = GUI_CreateCheckbox(f, x+150, y, "Raid", "Force Raid.", function() UpdateChannels("raid") end)

    -- ====================
    -- SECTION 4: CLASS
    -- ====================
    y = y - 40
    local headerClass = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    headerClass:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
    headerClass:SetText("Tracked Abilities (" .. (TankAlert_PlayerClass or "Unknown") .. ")")

    y = y - 20
    local classSettings = TankAlert_Settings[TankAlert_PlayerClass]
    local abilityOrder = TankAlert_AbilityOrder[TankAlert_PlayerClass]

    if (classSettings and classSettings.abilities and abilityOrder) then
        local col = 0
        local startY = y
        local count = 0
        
        for _, abilityKey in ipairs(abilityOrder) do
            if (classSettings.abilities[abilityKey] ~= nil) then
                local displayName = TankAlert_AbilityDisplayNames[abilityKey] or abilityKey
                local savedKey = abilityKey 

                GUI_CreateCheckbox(f, x + (col * 150), y, displayName, "Track " .. displayName, function(checked)
                     classSettings.abilities[savedKey] = checked
                end):SetChecked(classSettings.abilities[abilityKey])
                
                y = y - 25
                count = count + 1
                
                if (count == 3) then
                     y = startY
                     col = col + 1
                end
            end
        end
    else
        local noClass = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        noClass:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
        noClass:SetText("No configurable abilities for this class.")
    end

    -- --- Script: OnShow (Sync UI to Data) ---
    f:SetScript("OnShow", function()
        local g = TankAlert_Settings.global
        TankAlert_GUI.widgets.master:SetChecked(g.enabled)
        TankAlert_GUI.widgets.cc:SetChecked(g.announceCC)
        TankAlert_GUI.widgets.disarm:SetChecked(g.announceDisarm)
        TankAlert_GUI.widgets.whisper:SetChecked(g.announceThreatWhisper)
        TankAlert_GUI.widgets.tankonly:SetChecked(g.onlyTankWhispers)
        
        TankAlert_GUI.widgets.threshold:SetValue(g.threatWhisperThreshold)
        
        TankAlert_GUI.widgets.chanAuto:SetChecked(g.forceChannel == "auto")
        TankAlert_GUI.widgets.chanSay:SetChecked(g.forceChannel == "say")
        TankAlert_GUI.widgets.chanParty:SetChecked(g.forceChannel == "party")
        TankAlert_GUI.widgets.chanRaid:SetChecked(g.forceChannel == "raid")
    end)
end

-- =========================================================================
--  END GUI ENGINE
-- =========================================================================


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
    ["Hand of Reckoning"] = "HandOfReckoning",
    ["Holy Strike"] = "HolyStrike",
    ["Earthshaker Slam"] = "EarthshakerSlam",
    ["Earth Shock"] = "EarthShock",
    ["Frost Shock"] = "FrostShock",
    ["Lightning Strike"] = "LightningStrike",
    ["Stormstrike"] = "Stormstrike",
}

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
    },
    PALADIN = {
        {name = "Hand of Reckoning", pattern = "Hand of Reckoning", failure = "resisted", extract = "resisted by (.+)"},
        {name = "Holy Strike", pattern = "Holy Strike", failures = {"dodged", "parried", "missed"}},
    },
    SHAMAN = {
        {name = "Earthshaker Slam", pattern = "Earthshaker Slam", failure = "resisted", extract = "resisted by (.+)"},
        {name = "Earth Shock", pattern = "Earth Shock", failure = "resisted", extract = "resisted by (.+)"},
        {name = "Frost Shock", pattern = "Frost Shock", failure = "resisted", extract = "resisted by (.+)"},
        {name = "Lightning Strike", pattern = "Lightning Strike", failures = {"dodged", "parried", "missed"}},
        {name = "Stormstrike", pattern = "Stormstrike", failures = {"dodged", "parried", "missed"}}
    }
}

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

-- --- Helper: Check for High Threat Non-Tanks (v1.9) ---
local function TankAlert_IsHighThreatPresent()
    -- Iterate through the current threat table
    for name, data in pairs(TankAlert_CurrentThreat) do
        -- Check if player is NOT a tank and has threat >= 80%
        if (data and data.percent and data.percent >= 80 and not data.isTank) then
            return true
        end
    end
    return false
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
        
        -- Class Gate
        if (not TankAlert_AbilityPatterns[TankAlert_PlayerClass]) then
             DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r v" .. TankAlert_Version .. " loaded but suspended (Class " .. TankAlert_PlayerClass .. " not supported).")
             tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
             return
        end

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
        
        -- INITIALIZE GUI (Lazy load on login)
        TankAlert_InitGUI()
        
        tankAlert_Frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        tankAlert_Frame:RegisterEvent("UI_ERROR_MESSAGE")
        tankAlert_Frame:RegisterEvent("CHAT_MSG_ADDON")
        
        tankAlert_Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        tankAlert_Frame:RegisterEvent("PLAYER_REGEN_ENABLED")

        TankAlert_Last_CC_Alert_Time = 0
        TankAlert_Last_Disarm_Alert_Time = 0
        TankAlert_CombatStartTime = 0

        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r v" .. TankAlert_Version .. " active. Type |cffFFFFFF/ta|r to open settings.")
        
        tankAlert_Frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
    
    if (TankAlert_Settings.global.enabled == false) then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        TankAlert_CombatStartTime = GetTime() -- v1.9 Start Timer
        threatCheckTimer = 0
        threatCheckFrame:Show()
        for k in pairs(TankAlert_WhisperThrottle) do
            TankAlert_WhisperThrottle[k] = nil
        end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        TankAlert_CombatStartTime = 0 -- v1.9 Reset Timer
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
        
        if (not prefix or not msg) then return end
        
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

        if (not TankAlert_PlayerClass) then return end

        local abilityName, failureType, targetName = TankAlert_DetectAbilityFailure(msg, TankAlert_PlayerClass)

        if (abilityName and failureType) then
            if (not TankAlert_Settings or not TankAlert_Settings[TankAlert_PlayerClass]) then return end
            
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
                local forcedChannel = TankAlert_Settings.global.forceChannel
                
                -- Determine Context
                local inRaid = (GetNumRaidMembers() > 0)
                local inParty = (GetNumPartyMembers() > 0)
                local isAssist = TankAlert_IsRaidAssist()
                
                -- Default Logic
                if (forcedChannel ~= "auto") then
                    channel = _strupper(forcedChannel)
                else
                    if (inRaid) then
                        -- v1.9 Logic: Smart Raid Warning
                        local useRW = false
                        local combatDuration = 0
                        
                        -- Calculate combat duration if currently in combat
                        if (TankAlert_CombatStartTime > 0) then
                            combatDuration = GetTime() - TankAlert_CombatStartTime
                        end

                        -- Rule 1: First 10 seconds of combat
                        if (combatDuration <= 10) then
                            useRW = true
                        -- Rule 2: After 10 seconds, only if High Threat detected
                        elseif (TankAlert_IsHighThreatPresent()) then
                            useRW = true
                        end
                        
                        -- Apply RW if conditions met AND we have permission
                        if (useRW and isAssist) then
                            channel = "RAID_WARNING"
                        else
                            channel = "RAID"
                        end
                    elseif (inParty) then
                        channel = "PARTY"
                    end
                end
                
                -- Prefix Formatting for RW
                if (channel == "RAID_WARNING") then
                     messagePrefix = UnitName("player") .. "'s "
                end
                
                SendChatMessage(messagePrefix .. messageBody, channel)
            end
        end
    end
    
end)

-- We start by only listening for the login event
tankAlert_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")


-- --- Slash Command Handler (v1.7) ---
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
    
    -- Class Gate
    if (not TankAlert_AbilityPatterns[TankAlert_PlayerClass]) then
         DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[TankAlert]|r Class " .. (TankAlert_PlayerClass or "Unknown") .. " is not supported.")
         return
    end
    
    -- If no command, open GUI
    if (cmd == "") then
        if (TankAlert_GUI.frame) then
            TankAlert_GUI.frame:Show()
        end
        return
    end

    if (not TankAlert_Settings or not TankAlert_Settings.global) then return end

    if (cmd == "toggle") then
         if (arg == "cc") then
            TankAlert_Settings.global.announceCC = not TankAlert_Settings.global.announceCC
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r CC alerts: " .. (TankAlert_Settings.global.announceCC and "ON" or "OFF"))
         elseif (arg == "disarm") then
            TankAlert_Settings.global.announceDisarm = not TankAlert_Settings.global.announceDisarm
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Disarm alerts: " .. (TankAlert_Settings.global.announceDisarm and "ON" or "OFF"))
         elseif (arg == "whisper") then
            TankAlert_Settings.global.announceThreatWhisper = not TankAlert_Settings.global.announceThreatWhisper
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Threat Whispers: " .. (TankAlert_Settings.global.announceThreatWhisper and "ON" or "OFF"))
         else
            if (TankAlert_GUI.frame) then TankAlert_GUI.frame:Show() end
         end
    elseif (cmd == "on") then
        TankAlert_Settings.global.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Enabled.")
    elseif (cmd == "off") then
        TankAlert_Settings.global.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[TankAlert]|r Disabled.")
    
    -- v1.9 DEBUGGING TOOL
    elseif (cmd == "debug") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFFA500[TankAlert Debug]|r Dumping Threat Table:")
        local count = 0
        local highThreatFound = false
        
        for name, data in pairs(TankAlert_CurrentThreat) do
            count = count + 1
            local role = data.isTank and "TANK" or "DPS/HEAL"
            local color = "|cffFFFFFF" -- White
            
            if (not data.isTank and data.percent >= 80) then
                color = "|cffFF0000" -- Red
                highThreatFound = true
            end

            DEFAULT_CHAT_FRAME:AddMessage(string.format(" - %s%s|r (%s): %d%% threat", color, name, role, data.percent))
        end
        
        if (count == 0) then
            DEFAULT_CHAT_FRAME:AddMessage(" - Table is empty. (Are you receiving TWTv4 syncs?)")
        else
            DEFAULT_CHAT_FRAME:AddMessage("Total entries: " .. count)
            if (highThreatFound) then
                DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[!] High Threat detected! (RW condition met)|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[OK] No High Threat detected.|r")
            end
        end

    else
        if (TankAlert_GUI.frame) then
            TankAlert_GUI.frame:Show()
        end
    end
end

SLASH_TANKALERT1 = "/ta"