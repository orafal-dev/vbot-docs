--[[
File: scripts/core/features.lua
Provides a high-level API for interacting with the bot's core features.
]]

-- ============================================================================
-- FEATURE ID ENUMERATION
-- ============================================================================
BotFeatureId = {
    HEALER = 1,
    CONDITIONS_MANAGER = 2,
    HEAL_FRIEND = 3,
    LURE_MANAGER = 4,
    WALKER = 5,
    TARGETING = 6,
    MAGIC_SHOOTER = 7,
    ALARMS = 8,
    EXTRAS = 9,
    EQUIPMENT_MANAGER = 10,
    CHANNELS_MANAGER = 11,
    PVP_TOOLS = 12,
    LOOTER = 13,
    COMBO_BOT = 14,
    HUD = 15,
    AMMO_REFILL = 16,
    TANK_MODE = 17,
    TIMER_ACTIONS = 18
}

-- ============================================================================
-- FEATURE NAME MAPPING
-- ============================================================================
BotFeatureName = {
    [BotFeatureId.HEALER] = "Healer",
    [BotFeatureId.CONDITIONS_MANAGER] = "Conditions Manager",
    [BotFeatureId.HEAL_FRIEND] = "Heal Friend",
    [BotFeatureId.LURE_MANAGER] = "Lure Manager",
    [BotFeatureId.WALKER] = "Walker",
    [BotFeatureId.TARGETING] = "Targeting",
    [BotFeatureId.MAGIC_SHOOTER] = "Magic Shooter",
    [BotFeatureId.ALARMS] = "Alarms",
    [BotFeatureId.EXTRAS] = "Extras",
    [BotFeatureId.EQUIPMENT_MANAGER] = "Equipment Manager",
    [BotFeatureId.CHANNELS_MANAGER] = "Channels Manager",
    [BotFeatureId.PVP_TOOLS] = "PVP Tools",
    [BotFeatureId.LOOTER] = "Looter",
    [BotFeatureId.COMBO_BOT] = "Combo Bot",
    [BotFeatureId.HUD] = "HUD",
    [BotFeatureId.AMMO_REFILL] = "Ammo Refill",
    [BotFeatureId.TANK_MODE] = "Tank Mode",
    [BotFeatureId.TIMER_ACTIONS] = "Timer Actions"
}

-- Reverse mapping: string name -> feature ID (case-insensitive)
local FeatureNameToId = {}
for id, name in pairs(BotFeatureName) do
    FeatureNameToId[name:lower()] = id
end

local function isReservedInternalFeature(featureId)
    return featureId == BotFeatureId.OBJECTS_DUMPER
end

-- ============================================================================
-- HELPER FUNCTIONS (Private)
-- ============================================================================

--- Resolves a feature identifier to a numeric BotFeatureId
local function resolveFeatureId(featureIdentifier)
    if type(featureIdentifier) == "number" then
        if featureIdentifier < 0 or featureIdentifier > BotFeatureId.TIMER_ACTIONS then
            return nil
        end
        if isReservedInternalFeature(featureIdentifier) then
            return nil
        end
        return featureIdentifier
    elseif type(featureIdentifier) == "string" then
        return FeatureNameToId[featureIdentifier:lower()]
    end
    return nil
end

--- Validates a feature identifier and throws an error if invalid
local function validateFeatureId(featureIdentifier, functionName)
    local featureId = resolveFeatureId(featureIdentifier)
    if not featureId then
        local minPublicId = BotFeatureId.HEALER
        local errorMsg = string.format(
            "%s: Invalid feature identifier '%s'.\n" ..
            "Expected a numeric public BotFeatureId (%d-%d) or a feature name string.",
            functionName,
            tostring(featureIdentifier),
            minPublicId,
            BotFeatureId.TIMER_ACTIONS
        )
        error(errorMsg, 3)
    end
    return featureId
end

-- ============================================================================
-- WRAPPER FUNCTIONS
-- ============================================================================
-- These will be added to the existing Features table that C++ creates

--- Store original C++ functions (will be set after this file loads)
local _CPP_Toggle
local _CPP_IsActive

--- Initialize C++ function references (called automatically after binding)
local function initializeCppFunctions()
    if Features and Features.Toggle and Features.IsActive then
        _CPP_Toggle = Features.Toggle
        _CPP_IsActive = Features.IsActive
        return true
    end
    return false
end

-- ============================================================================
-- EXTENDED API FUNCTIONS
-- ============================================================================

--- Checks if a feature is currently active/enabled
function featuresIsActive(featureIdentifier)
    if not _CPP_IsActive then initializeCppFunctions() end
    local featureId = validateFeatureId(featureIdentifier, "Features.IsActive")
    return _CPP_IsActive(featureId)
end

--- Enables a feature (turns it on)
function featuresEnable(featureIdentifier)
    if not _CPP_Toggle then initializeCppFunctions() end
    local featureId = validateFeatureId(featureIdentifier, "Features.Enable")
    if not featuresIsActive(featureId) then
        _CPP_Toggle(featureId)
    end
end

--- Disables a feature (turns it off)
function featuresDisable(featureIdentifier)
    if not _CPP_Toggle then initializeCppFunctions() end
    local featureId = validateFeatureId(featureIdentifier, "Features.Disable")
    if featuresIsActive(featureId) then
        _CPP_Toggle(featureId)
    end
end

--- Toggles a feature's state (on -> off, off -> on)
function featuresToggle(featureIdentifier)
    if not _CPP_Toggle then initializeCppFunctions() end
    local featureId = validateFeatureId(featureIdentifier, "Features.Toggle")
    _CPP_Toggle(featureId)
end

--- Sets a feature to a specific active state
function featuresSetActive(featureIdentifier, activeStatus)
    if type(activeStatus) ~= "boolean" then
        error(string.format(
            "Features.SetActive: Argument 'activeStatus' must be a boolean, got %s.",
            type(activeStatus)
        ), 2)
    end
    
    if activeStatus then
        featuresEnable(featureIdentifier)
    else
        featuresDisable(featureIdentifier)
    end
end

--- Gets the human-readable name of a feature
function featuresGetName(featureIdentifier)
    local featureId = validateFeatureId(featureIdentifier, "Features.GetName")
    return BotFeatureName[featureId] or "Unknown Feature"
end

--- Returns a list of all available feature IDs
function featuresGetAllFeatureIds()
    local ids = {}
    for id, _ in pairs(BotFeatureName) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

--- Returns a list of all currently active features
function featuresGetActiveFeatures()
    local active = {}
    for _, featureId in ipairs(featuresGetAllFeatureIds()) do
        if featuresIsActive(featureId) then
            table.insert(active, featureId)
        end
    end
    return active
end

--- Enables multiple features at once
function featuresEnableMultiple(featureList)
    if type(featureList) ~= "table" then
        error("Features.EnableMultiple: Argument must be a table/array of feature identifiers.", 2)
    end
    for _, feature in ipairs(featureList) do
        featuresEnable(feature)
    end
end

--- Disables multiple features at once
function featuresDisableMultiple(featureList)
    if type(featureList) ~= "table" then
        error("Features.DisableMultiple: Argument must be a table/array of feature identifiers.", 2)
    end
    for _, feature in ipairs(featureList) do
        featuresDisable(feature)
    end
end

--- Disables all features except those in the exclusion list
function featuresDisableAllExcept(ExcludeList)
    ExcludeList = ExcludeList or {}
    local excludeSet = {}
    for _, feature in ipairs(ExcludeList) do
        local featureId = resolveFeatureId(feature)
        if featureId then
            excludeSet[featureId] = true
        end
    end
    
    for _, featureId in ipairs(featuresGetAllFeatureIds()) do
        if not excludeSet[featureId] then
            featuresDisable(featureId)
        end
    end
end

--- Prints the status of all features
function featuresPrintStatus()
    print("=== Bot Features Status ===")
    for _, featureId in ipairs(featuresGetAllFeatureIds()) do
        local status = featuresIsActive(featureId) and "[ON]" or "[OFF]"
        print(string.format("%s %s", status, featuresGetName(featureId)))
    end
end

-- ============================================================================
-- HOOK INTO FEATURES TABLE (when it exists)
-- ============================================================================
-- This code will execute when user scripts run (after bindings are registered)

-- Lazy initialization: extend Features table on first access
local function extendFeaturesTable()
    if Features and not Features.Enable then
        initializeCppFunctions()
        
        -- Add wrapper functions to Features table
        Features.IsActive = featuresIsActive
        Features.Enable = featuresEnable
        Features.Disable = featuresDisable
        Features.Toggle = featuresToggle
        Features.SetActive = featuresSetActive
        Features.GetName = featuresGetName
        Features.GetAllFeatureIds = featuresGetAllFeatureIds
        Features.GetActiveFeatures = featuresGetActiveFeatures
        Features.EnableMultiple = featuresEnableMultiple
        Features.DisableMultiple = featuresDisableMultiple
        Features.DisableAllExcept = featuresDisableAllExcept
        Features.PrintStatus = featuresPrintStatus
    end
end

-- Auto-extend when this module is loaded (if Features already exists)
if Features then
    extendFeaturesTable()
end

-- Export for manual initialization if needed
return {
    ExtendFeaturesTable = extendFeaturesTable
}



