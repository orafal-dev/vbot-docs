--[[
File: scripts/core/Engine.lua
Provides high-level API for controlling bot internal features from Lua scripts.
This wraps the global Healer and Alarms tables into a unified Engine namespace.
]]

-- ============================================================================
-- Create Engine namespace
-- ============================================================================
Engine = Engine or {}

-- ============================================================================
-- HEALER API - Wraps global Healer.* functions
-- ============================================================================
Engine.Healer = {
    -- Direct C++ function bindings
    GetSpellCount = Healer.GetSpellCount,
    GetSpell = Healer.GetSpell,
    GetAllSpells = Healer.GetAllSpells,
    SetSpellEnabled = Healer.SetSpellEnabled,
    GetItemCount = Healer.GetItemCount,
    GetItem = Healer.GetItem,
    SetItemEnabled = Healer.SetItemEnabled
}

--- Add new healing spell
---@param spellData table spell configuration
---@return number New spell index
function Engine.Healer.AddSpell(spellData)
    if type(spellData) ~= "table" then
        error("Engine.Healer.AddSpell: spellData must be a table", 2)
    end
    return Healer.AddSpell(spellData)
end

--- Remove healing spell by index
---@param index number 1-based index
---@return boolean Success
function Engine.Healer.RemoveSpell(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    return Healer.RemoveSpell(index)
end

--- Clear all healing spells
function Engine.Healer.ClearAllSpells()
    return Healer.ClearAllSpells()
end

--- Add new healing item
---@param itemData table item configuration
---@return number New item index
function Engine.Healer.AddItem(itemData)
    if type(itemData) ~= "table" then
        error("Engine.Healer.AddItem: itemData must be a table", 2)
    end
    return Healer.AddItem(itemData)
end

--- Remove healing item by index
---@param index number 1-based index
---@return boolean Success
function Engine.Healer.RemoveItem(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    return Healer.RemoveItem(index)
end

--- Clear all healing items
function Engine.Healer.ClearAllItems()
    return Healer.ClearAllItems()
end

--- Get all healing spells with full details
---@return table Array of spell data tables
function Engine.Healer.GetSpells()
    return Healer.GetAllSpells()
end

--- Get a specific healing spell by index
---@param index number 1-based index
---@return table|nil spell data or nil if not found
function Engine.Healer.GetSpellByIndex(index)
    if type(index) ~= "number" or index < 1 then
        return nil
    end
    return Healer.GetSpell(index)
end

--- Find spell by spell words
---@param spellWords string The spell words to search for
---@return table|nil spell data and index, or nil if not found
function Engine.Healer.FindSpellByWords(spellWords)
    if type(spellWords) ~= "string" then
        error("Engine.Healer.FindSpellByWords: spellWords must be a string", 2)
    end
    
    local spells = Healer.GetAllSpells()
    local lowerWords = spellWords:lower()
    
    for i, spell in ipairs(spells) do
        if spell.spell_words:lower() == lowerWords then
            spell.index = i
            return spell
        end
    end
    
    return nil
end

--- Enable a healing spell
---@param index number 1-based index
---@return boolean Success (false if spell not found)
function Engine.Healer.EnableSpell(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    
    if not Healer.GetSpell(index) then
        return false
    end
    
    return Healer.SetSpellEnabled(index, true)
end

--- Disable a healing spell
---@param index number 1-based index
---@return boolean Success (false if spell not found)
function Engine.Healer.DisableSpell(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    
    if not Healer.GetSpell(index) then
        return false
    end
    
    return Healer.SetSpellEnabled(index, false)
end

--- Toggle a healing spell on/off
---@param index number 1-based index
---@return boolean|nil New enabled state, or nil if spell not found
function Engine.Healer.ToggleSpell(index)
    local spell = Healer.GetSpell(index)
    if not spell then
        return nil
    end
    
    local newState = not spell.enabled
    Healer.SetSpellEnabled(index, newState)
    return newState
end

--- Get all healing items with full details
---@return table Array of item data tables
function Engine.Healer.GetItems()
    local count = Healer.GetItemCount()
    local items = {}
    
    for i = 1, count do
        local item = Healer.GetItem(i)
        if item then
            item.index = i
            table.insert(items, item)
        end
    end
    
    return items
end

--- Find healing item by item ID
---@param itemId number item ID to search for
---@return table|nil item data and index, or nil if not found
function Engine.Healer.FindItemById(itemId)
    if type(itemId) ~= "number" then
        error("Engine.Healer.FindItemById: itemId must be a number", 2)
    end
    
    local count = Healer.GetItemCount()
    for i = 1, count do
        local item = Healer.GetItem(i)
        if item and item.item_id == itemId then
            item.index = i
            return item
        end
    end
    
    return nil
end

--- Enable a healing item
---@param index number 1-based index
---@return boolean Success
function Engine.Healer.EnableItem(index)
    if type(index) ~= "number" or index < 1 then
        error("Engine.Healer.EnableItem: index must be a positive number", 2)
    end
    return Healer.SetItemEnabled(index, true)
end

--- Disable a healing item
---@param index number 1-based index
---@return boolean Success
function Engine.Healer.DisableItem(index)
    if type(index) ~= "number" or index < 1 then
        error("Engine.Healer.DisableItem: index must be a positive number", 2)
    end
    return Healer.SetItemEnabled(index, false)
end

--- Toggle a healing item on/off
---@param index number 1-based index
---@return boolean New enabled state
function Engine.Healer.ToggleItem(index)
    local item = Healer.GetItem(index)
    if not item then
        error("Engine.Healer.ToggleItem: item not found at index " .. tostring(index), 2)
    end
    
    local newState = not item.enabled
    Healer.SetItemEnabled(index, newState)
    return newState
end

--- Disable all healing spells
function Engine.Healer.DisableAllSpells()
    local count = Healer.GetSpellCount()
    for i = 1, count do
        Engine.Healer.DisableSpell(i)
    end
end

--- Disable all healing items
function Engine.Healer.DisableAllItems()
    local count = Healer.GetItemCount()
    for i = 1, count do
        Engine.Healer.DisableItem(i)
    end
end

--- Enable only specific spells by spell words
---@param spellWordsList table Array of spell words strings
---@return number Number of spells enabled
function Engine.Healer.EnableOnlySpells(spellWordsList)
    if type(spellWordsList) ~= "table" then
        return 0
    end
    
    Engine.Healer.DisableAllSpells()
    
    local enabledCount = 0
    for _, spellWords in ipairs(spellWordsList) do
        local spell = Engine.Healer.FindSpellByWords(spellWords)
        if spell and spell.index then
            if Engine.Healer.EnableSpell(spell.index) then
                enabledCount = enabledCount + 1
            end
        end
    end
    
    return enabledCount
end

--- Enable only specific items by item IDs
---@param itemIdsList table Array of item IDs
function Engine.Healer.EnableOnlyItems(itemIdsList)
    if type(itemIdsList) ~= "table" then
        error("Engine.Healer.EnableOnlyItems: itemIdsList must be a table", 2)
    end
    
    Engine.Healer.DisableAllItems()
    
    for _, itemId in ipairs(itemIdsList) do
        local item = Engine.Healer.FindItemById(itemId)
        if item and item.index then
            Engine.Healer.EnableItem(item.index)
        end
    end
end

--- Print all healing spells to console
function Engine.Healer.PrintSpells()
    local spells = Engine.Healer.GetSpells()
    if #spells == 0 then
        print("No healing spells configured")
        return
    end
    
    print("=== Healing spells ===")
    for i, spell in ipairs(spells) do
        local status = spell.enabled and "[ON]" or "[OFF]"
        print(string.format("%d. %s %s", i, status, spell.display_string))
    end
end

--- Print all healing items to console
function Engine.Healer.PrintItems()
    local items = Engine.Healer.GetItems()
    if #items == 0 then
        print("No healing items configured")
        return
    end
    
    print("=== Healing Items ===")
    for i, item in ipairs(items) do
        local status = item.enabled and "[ON]" or "[OFF]"
        print(string.format("%d. %s %s", i, status, item.display_string))
    end
end

-- ============================================================================
-- ALARMS API - Wraps global Alarms.* functions
-- ============================================================================
Engine.Alarms = {}

--- Check if a specific alarm is enabled
---@param alarmId number BotSoundId constant (use BotSoundId.DISCONNECTED, etc.)
---@return boolean True if alarm is enabled
function Engine.Alarms.IsEnabled(alarmId)
    if type(alarmId) ~= "number" then
        error("Engine.Alarms.IsEnabled: alarmId must be a number", 2)
    end
    return Alarms.IsAlarmEnabled(alarmId)
end

--- Enable a specific alarm
---@param alarmId number BotSoundId constant
---@return boolean Success
function Engine.Alarms.Enable(alarmId)
    if type(alarmId) ~= "number" then
        error("Engine.Alarms.Enable: alarmId must be a number", 2)
    end
    return Alarms.SetAlarmEnabled(alarmId, true)
end

--- Disable a specific alarm
---@param alarmId number BotSoundId constant
---@return boolean Success
function Engine.Alarms.Disable(alarmId)
    if type(alarmId) ~= "number" then
        error("Engine.Alarms.Disable: alarmId must be a number", 2)
    end
    return Alarms.SetAlarmEnabled(alarmId, false)
end

--- Toggle an alarm on/off
---@param alarmId number BotSoundId constant
---@return boolean New enabled state
function Engine.Alarms.Toggle(alarmId)
    local currentState = Engine.Alarms.IsEnabled(alarmId)
    local newState = not currentState
    Alarms.SetAlarmEnabled(alarmId, newState)
    return newState
end

--- Get low health alarm threshold
---@return number Health percentage (0-100)
function Engine.Alarms.GetLowHealthThreshold()
    return Alarms.GetLowHealthPercentage()
end

--- Set low health alarm threshold
---@param percentage number Health percentage (0-100)
---@return boolean Success
function Engine.Alarms.SetLowHealthThreshold(percentage)
    if type(percentage) ~= "number" or percentage < 0 or percentage > 100 then
        error("Engine.Alarms.SetLowHealthThreshold: percentage must be between 0 and 100", 2)
    end
    return Alarms.SetLowHealthPercentage(percentage)
end

--- Get low mana alarm threshold
---@return number Mana percentage (0-100)
function Engine.Alarms.GetLowManaThreshold()
    return Alarms.GetLowManaPercentage()
end

--- Set low mana alarm threshold
---@param percentage number Mana percentage (0-100)
---@return boolean Success
function Engine.Alarms.SetLowManaThreshold(percentage)
    if type(percentage) ~= "number" or percentage < 0 or percentage > 100 then
        error("Engine.Alarms.SetLowManaThreshold: percentage must be between 0 and 100", 2)
    end
    return Alarms.SetLowManaPercentage(percentage)
end

--- Get creature detection filter list
---@return string Comma-separated list of creature names
function Engine.Alarms.GetCreatureFilter()
    return Alarms.GetCreatureDetectedNames()
end

--- Set creature detection filter (comma-separated names)
---@param namesString string Comma-separated creature names (e.g., "demon,dragon,hydra")
---@return boolean Success
function Engine.Alarms.SetCreatureFilter(namesString)
    if type(namesString) ~= "string" then
        error("Engine.Alarms.SetCreatureFilter: namesString must be a string", 2)
    end
    return Alarms.SetCreatureDetectedNames(namesString)
end

--- Get alarm messages filter list
---@return string Comma-separated list of alarm trigger messages
function Engine.Alarms.GetMessageFilter()
    return Alarms.GetAlarmMessages()
end

--- Set alarm messages filter (comma-separated messages)
---@param messagesString string Comma-separated messages
---@return boolean Success
function Engine.Alarms.SetMessageFilter(messagesString)
    if type(messagesString) ~= "string" then
        error("Engine.Alarms.SetMessageFilter: messagesString must be a string", 2)
    end
    return Alarms.SetAlarmMessages(messagesString)
end

--- Check if window flashing is enabled
---@return boolean True if enabled
function Engine.Alarms.IsFlashWindowEnabled()
    return Alarms.GetFlashTibiaWindowOnAlarm()
end

--- Enable/disable window flashing on alarm
---@param enabled boolean
---@return boolean Success
function Engine.Alarms.SetFlashWindow(enabled)
    if type(enabled) ~= "boolean" then
        error("Engine.Alarms.SetFlashWindow: enabled must be a boolean", 2)
    end
    return Alarms.SetFlashTibiaWindowOnAlarm(enabled)
end

--- Check if bringing window to focus is enabled
---@return boolean True if enabled
function Engine.Alarms.IsBringToFocusEnabled()
    return Alarms.GetBringTibiaToFocusOnAlarm()
end

--- Enable/disable bringing window to focus on alarm
---@param enabled boolean
---@return boolean Success
function Engine.Alarms.SetBringToFocus(enabled)
    if type(enabled) ~= "boolean" then
        error("Engine.Alarms.SetBringToFocus: enabled must be a boolean", 2)
    end
    return Alarms.SetBringTibiaToFocusOnAlarm(enabled)
end

--- Check if ally players are ignored
---@return boolean True if ignoring ally players
function Engine.Alarms.IsIgnoringAllyPlayers()
    return Alarms.GetIgnoreAllyPlayers()
end

--- Set whether to ignore ally players (party/guild members)
---@param ignore boolean
---@return boolean Success
function Engine.Alarms.SetIgnoreAllyPlayers(ignore)
    if type(ignore) ~= "boolean" then
        error("Engine.Alarms.SetIgnoreAllyPlayers: ignore must be a boolean", 2)
    end
    return Alarms.SetIgnoreAllyPlayers(ignore)
end

--- Disable all alarms
function Engine.Alarms.DisableAll()
    for _, alarmId in pairs(BotSoundId) do
        if type(alarmId) == "number" then
            Engine.Alarms.Disable(alarmId)
        end
    end
end

--- Enable all alarms
function Engine.Alarms.EnableAll()
    for _, alarmId in pairs(BotSoundId) do
        if type(alarmId) == "number" then
            Engine.Alarms.Enable(alarmId)
        end
    end
end

--- Enable only specific alarms
---@param alarmIdsList table Array of BotSoundId constants
function Engine.Alarms.EnableOnly(alarmIdsList)
    if type(alarmIdsList) ~= "table" then
        error("Engine.Alarms.EnableOnly: alarmIdsList must be a table", 2)
    end
    
    -- Disable all first
    Engine.Alarms.DisableAll()
    
    -- Enable specified alarms
    for _, alarmId in ipairs(alarmIdsList) do
        Engine.Alarms.Enable(alarmId)
    end
end

--- Print all alarm states to console
function Engine.Alarms.PrintStatus()
    print("=== Alarm Status ===")
    print("Low Health: " .. Engine.Alarms.GetLowHealthThreshold() .. "%")
    print("Low Mana:   " .. Engine.Alarms.GetLowManaThreshold() .. "%")
    print("")
    print("Window Flash:   " .. (Engine.Alarms.IsFlashWindowEnabled() and "ON" or "OFF"))
    print("Bring to Focus: " .. (Engine.Alarms.IsBringToFocusEnabled() and "ON" or "OFF"))
    print("Ignore Allies:  " .. (Engine.Alarms.IsIgnoringAllyPlayers() and "ON" or "OFF"))
    print("")
    
    local alarms = {
        {BotSoundId.DISCONNECTED, "Disconnected"},
        {BotSoundId.DAMAGE_TAKEN, "Damage Taken"},
        {BotSoundId.LOW_HEALTH, "Low Health"},
        {BotSoundId.LOW_MANA, "Low Mana"},
        {BotSoundId.PRIVATE_MESSAGE, "Private Message"},
        {BotSoundId.CREATURE_DETECTED, "creature Detected"},
        {BotSoundId.PLAYER_ATTACK, "Player Attack"},
        {BotSoundId.PLAYER_DETECTED, "Player Detected"},
        {BotSoundId.SKULL_ON_SCREEN, "Skull on Screen"},
        {BotSoundId.ENEMY_ON_SCREEN, "Enemy on Screen"},
        {BotSoundId.LOCAL_MESSAGE, "Local Message"},
        {BotSoundId.GM_ON_SCREEN, "GM on Screen"},
        {BotSoundId.WALKER_STUCK, "walker Stuck"},
        {BotSoundId.UNJUSTIFIED_KILL, "Unjustified Kill"}
    }
    
    print("Individual Alarms:")
    for _, alarm in ipairs(alarms) do
        local id, name = alarm[1], alarm[2]
        local status = Engine.Alarms.IsEnabled(id) and "[ON]" or "[OFF]"
        print(string.format("  %s %-25s", status, name))
    end
    
    print("=====================")
end

-- ============================================================================
-- AMMO REFILL API - Wraps global AmmoRefill.* functions with profile support
-- ============================================================================
Engine.AmmoRefill = {}

--- Add new ammo to current profile
---@param ammoData table Ammo configuration
---@return number New ammo index
function Engine.AmmoRefill.Add(ammoData)
    if type(ammoData) ~= "table" then
        error("Engine.AmmoRefill.Add: ammoData must be a table", 2)
    end
    return AmmoRefill.AddAmmo(ammoData)
end

--- Remove ammo by index from current profile
---@param index number 1-based index
---@return boolean Success
function Engine.AmmoRefill.Remove(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    return AmmoRefill.RemoveAmmo(index)
end

--- Clear all ammo from current profile
function Engine.AmmoRefill.ClearAll()
    return AmmoRefill.ClearAll()
end

--- Get all profile names
---@return table Array of profile name strings
function Engine.AmmoRefill.GetProfileNames()
    return AmmoRefill.GetProfileNames()
end

--- Get current active profile
---@return table|nil Profile info with name and index, or nil if none selected
function Engine.AmmoRefill.GetCurrentProfile()
    return AmmoRefill.GetCurrentProfile()
end

--- Set current profile by index or name
---@param indexOrName number|string Profile index (1-based) or profile name
---@return boolean Success
function Engine.AmmoRefill.SetProfile(indexOrName)
    if type(indexOrName) ~= "number" and type(indexOrName) ~= "string" then
        error("Engine.AmmoRefill.SetProfile: argument must be a number or string", 2)
    end
    return AmmoRefill.SetCurrentProfile(indexOrName)
end

--- Find profile index by name
---@param profileName string Profile name to search for
---@return number|nil Profile index (1-based), or nil if not found
function Engine.AmmoRefill.FindProfileByName(profileName)
    if type(profileName) ~= "string" then
        error("Engine.AmmoRefill.FindProfileByName: profileName must be a string", 2)
    end
    
    local profiles = AmmoRefill.GetProfileNames()
    for i, name in ipairs(profiles) do
        if name == profileName then
            return i
        end
    end
    
    return nil
end

--- Get all ammo configurations from current profile
---@return table Array of ammo data tables
function Engine.AmmoRefill.GetAll()
    return AmmoRefill.GetAllAmmo()
end

--- Get specific ammo by index from current profile
---@param index number 1-based index
---@return table|nil Ammo data or nil if not found
function Engine.AmmoRefill.Get(index)
    if type(index) ~= "number" or index < 1 then
        return nil
    end
    return AmmoRefill.GetAmmo(index)
end

--- Find ammo by item ID in current profile
---@param itemId number item ID to search for
---@return table|nil Ammo data and index, or nil if not found
function Engine.AmmoRefill.FindByItemId(itemId)
    if type(itemId) ~= "number" then
        error("Engine.AmmoRefill.FindByItemId: itemId must be a number", 2)
    end
    
    local ammos = AmmoRefill.GetAllAmmo()
    for i, ammo in ipairs(ammos) do
        if ammo.item_id == itemId then
            ammo.index = i
            return ammo
        end
    end
    
    return nil
end

--- Enable an ammo refill entry in current profile
---@param index number 1-based index
---@return boolean Success
function Engine.AmmoRefill.Enable(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    return AmmoRefill.SetAmmoEnabled(index, true)
end

--- Disable an ammo refill entry in current profile
---@param index number 1-based index
---@return boolean Success
function Engine.AmmoRefill.Disable(index)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    return AmmoRefill.SetAmmoEnabled(index, false)
end

--- Toggle an ammo refill entry in current profile
---@param index number 1-based index
---@return boolean|nil New enabled state, or nil if not found
function Engine.AmmoRefill.Toggle(index)
    local ammo = AmmoRefill.GetAmmo(index)
    if not ammo then
        return nil
    end
    
    local newState = not ammo.enabled
    AmmoRefill.SetAmmoEnabled(index, newState)
    return newState
end

--- Disable all ammo refill entries in current profile
function Engine.AmmoRefill.DisableAll()
    local count = AmmoRefill.GetAmmoCount()
    for i = 1, count do
        Engine.AmmoRefill.Disable(i)
    end
end

--- Enable all ammo refill entries in current profile
function Engine.AmmoRefill.EnableAll()
    local count = AmmoRefill.GetAmmoCount()
    for i = 1, count do
        Engine.AmmoRefill.Enable(i)
    end
end

--- Enable only specific ammo by item IDs in current profile
---@param itemIdsList table Array of item IDs
function Engine.AmmoRefill.EnableOnly(itemIdsList)
    if type(itemIdsList) ~= "table" then
        error("Engine.AmmoRefill.EnableOnly: itemIdsList must be a table", 2)
    end
    
    Engine.AmmoRefill.DisableAll()
    
    for _, itemId in ipairs(itemIdsList) do
        local ammo = Engine.AmmoRefill.FindByItemId(itemId)
        if ammo and ammo.index then
            Engine.AmmoRefill.Enable(ammo.index)
        end
    end
end

--- Print current profile status and ammo configuration
function Engine.AmmoRefill.PrintStatus()
    local profile = Engine.AmmoRefill.GetCurrentProfile()
    local ammos = Engine.AmmoRefill.GetAll()
    
    print("=== Ammo Refill Status ===")
    
    if profile then
        print("Current Profile: " .. profile.name .. " (index " .. profile.index .. ")")
    else
        print("Current Profile: None selected")
    end
    
    print("")
    
    if #ammos == 0 then
        print("No ammo configured in current profile")
    else
        print("Configured Ammo:")
        for i, ammo in ipairs(ammos) do
            local status = ammo.enabled and "[ON]" or "[OFF]"
            local location = ammo.refill_in_left_hand and "Left Hand" or "Quiver"
            local method = ammo.equip_from_hotkey and "Hotkey" or "container"
            print(string.format("%d. %s %s | %s | %s", i, status, ammo.display_string, location, method))
        end
    end
    
    print("========================")
end

--- Print all available profiles
function Engine.AmmoRefill.PrintProfiles()
    local profiles = Engine.AmmoRefill.GetProfileNames()
    local current = Engine.AmmoRefill.GetCurrentProfile()
    
    print("=== Ammo Refill Profiles ===")
    
    if #profiles == 0 then
        print("No profiles configured")
    else
        for i, name in ipairs(profiles) do
            local marker = (current and current.index == i) and " <ACTIVE>" or ""
            print(string.format("%d. %s%s", i, name, marker))
        end
    end
    
    print("============================")
end

--- Add new profile
---@param profileName string|nil Profile name (auto-generated if nil)
---@return number|boolean Profile index on success, false on failure
function Engine.AmmoRefill.AddProfile(profileName)
    if profileName ~= nil and type(profileName) ~= "string" then
        error("Engine.AmmoRefill.AddProfile: profileName must be a string or nil", 2)
    end
    return AmmoRefill.AddProfile(profileName or "")
end

--- Remove profile by index or name
---@param indexOrName number|string Profile index (1-based) or name
---@return boolean Success
function Engine.AmmoRefill.RemoveProfile(indexOrName)
    if type(indexOrName) ~= "number" and type(indexOrName) ~= "string" then
        error("Engine.AmmoRefill.RemoveProfile: argument must be a number or string", 2)
    end
    return AmmoRefill.RemoveProfile(indexOrName)
end

--- Rename profile
---@param indexOrName number|string Current profile index or name
---@param newName string New profile name
---@return boolean Success
function Engine.AmmoRefill.RenameProfile(indexOrName, newName)
    if type(indexOrName) ~= "number" and type(indexOrName) ~= "string" then
        error("Engine.AmmoRefill.RenameProfile: first argument must be a number or string", 2)
    end
    if type(newName) ~= "string" then
        error("Engine.AmmoRefill.RenameProfile: newName must be a string", 2)
    end
    return AmmoRefill.RenameProfile(indexOrName, newName)
end

-- ============================================================================
-- BOT FEATURE STATE API - Wraps the validated Features core library
-- ============================================================================
Engine.Features = {}

local function callFeatures(methodName, ...)
    local method = type(Features) == "table" and Features[methodName] or nil
    if type(method) ~= "function" then
        error("Engine.Features." .. methodName .. ": Features core API is unavailable", 3)
    end
    return method(...)
end

---@param featureIdentifier integer|string
---@return boolean
function Engine.Features.IsActive(featureIdentifier)
    return callFeatures("IsActive", featureIdentifier)
end

---@param featureIdentifier integer|string
function Engine.Features.Enable(featureIdentifier)
    return callFeatures("Enable", featureIdentifier)
end

---@param featureIdentifier integer|string
function Engine.Features.Disable(featureIdentifier)
    return callFeatures("Disable", featureIdentifier)
end

---@param featureIdentifier integer|string
function Engine.Features.Toggle(featureIdentifier)
    return callFeatures("Toggle", featureIdentifier)
end

---@param featureIdentifier integer|string
---@param activeStatus boolean
function Engine.Features.SetActive(featureIdentifier, activeStatus)
    return callFeatures("SetActive", featureIdentifier, activeStatus)
end

---@param featureIdentifier integer|string
---@return string
function Engine.Features.GetName(featureIdentifier)
    return callFeatures("GetName", featureIdentifier)
end

---@return integer[]
function Engine.Features.GetAllFeatureIds()
    return callFeatures("GetAllFeatureIds")
end

---@return integer[]
function Engine.Features.GetActiveFeatures()
    return callFeatures("GetActiveFeatures")
end

---@param featureList table
function Engine.Features.EnableMultiple(featureList)
    return callFeatures("EnableMultiple", featureList)
end

---@param featureList table
function Engine.Features.DisableMultiple(featureList)
    return callFeatures("DisableMultiple", featureList)
end

---@param excludeList? table
function Engine.Features.DisableAllExcept(excludeList)
    return callFeatures("DisableAllExcept", excludeList)
end

function Engine.Features.PrintStatus()
    return callFeatures("PrintStatus")
end

-- ============================================================================
-- EQUIPMENT STATE API - Wraps the Inventory core library
-- This is live equipped-item state. Equipment Manager enabled state is queried
-- through Engine.Features with BotFeatureId.EQUIPMENT_MANAGER.
-- ============================================================================
Engine.Equipment = {}

local function callInventory(methodName, ...)
    local method = type(Inventory) == "table" and Inventory[methodName] or nil
    if type(method) ~= "function" then
        error("Engine.Equipment." .. methodName .. ": Inventory core API is unavailable", 3)
    end
    return method(...)
end

---@return table
function Engine.Equipment.GetSlotConstants()
    return callInventory("GetEquipmentSlotConstants")
end

---@return boolean
function Engine.Equipment.CanRead()
    return callInventory("CanReadEquipment")
end

---@return boolean
function Engine.Equipment.CanMove()
    return callInventory("CanMoveEquipment")
end

---@param equipmentSlot integer
---@return table|nil
function Engine.Equipment.GetSlotItem(equipmentSlot)
    return callInventory("GetSlotItem", equipmentSlot)
end

---@return table
function Engine.Equipment.GetAllSlotItems()
    return callInventory("GetAllSlotItems")
end

---@param itemId integer
---@param tierLevel? integer
---@return boolean
function Engine.Equipment.Equip(itemId, tierLevel)
    return callInventory("Equip", itemId, tierLevel)
end

---@param itemId integer
---@param equipmentSlot integer
---@return boolean
function Engine.Equipment.LookSlotItem(itemId, equipmentSlot)
    return callInventory("LookSlotItem", itemId, equipmentSlot)
end

---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param equipmentSlot integer
---@param itemCount integer
---@return boolean
function Engine.Equipment.MoveFromContainerToSlot(containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
    return callInventory("MoveFromContainerToSlot", containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
end

---@param equipmentSlot integer
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param itemCount integer
---@return boolean
function Engine.Equipment.MoveFromSlotToContainer(equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
    return callInventory("MoveFromSlotToContainer", equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
end

---@param equipmentSlot integer
---@return integer|nil
function Engine.Equipment.GetSlotItemId(equipmentSlot)
    return callInventory("GetSlotItemId", equipmentSlot)
end

---@param equipmentSlot integer
---@return boolean|nil
function Engine.Equipment.HasItemInSlot(equipmentSlot)
    return callInventory("HasItemInSlot", equipmentSlot)
end

---@return integer[]
function Engine.Equipment.GetSlotIds()
    return callInventory("GetSlotIds")
end

---@return table
function Engine.Equipment.GetSnapshot()
    return callInventory("GetSnapshot")
end

-- ============================================================================
-- PVP TOOLS API - Wraps native PVP feature state
-- ============================================================================
local NativePVPTools = assert(PVPTools, "PVPTools native binding is unavailable")
local nativeIsHoldTargetEnabled = assert(NativePVPTools.IsHoldTargetEnabled)
local nativeSetHoldTargetEnabled = assert(NativePVPTools.SetHoldTargetEnabled)
local nativeToggleHoldTarget = assert(NativePVPTools.ToggleHoldTarget)
local nativeIsAntiPushEnabled = assert(NativePVPTools.IsAntiPushEnabled)
local nativeSetAntiPushEnabled = assert(NativePVPTools.SetAntiPushEnabled)
local nativeToggleAntiPush = assert(NativePVPTools.ToggleAntiPush)

Engine.PVPTools = {}

---@return boolean
function Engine.PVPTools.IsHoldTargetEnabled()
    return nativeIsHoldTargetEnabled()
end

---@param enabled boolean
---@return boolean
function Engine.PVPTools.SetHoldTargetEnabled(enabled)
    if type(enabled) ~= "boolean" then
        error("Engine.PVPTools.SetHoldTargetEnabled: enabled must be a boolean", 2)
    end
    return nativeSetHoldTargetEnabled(enabled)
end

---@return boolean
function Engine.PVPTools.ToggleHoldTarget()
    return nativeToggleHoldTarget()
end

---@return boolean
function Engine.PVPTools.IsAntiPushEnabled()
    return nativeIsAntiPushEnabled()
end

---@param enabled boolean
---@return boolean
function Engine.PVPTools.SetAntiPushEnabled(enabled)
    if type(enabled) ~= "boolean" then
        error("Engine.PVPTools.SetAntiPushEnabled: enabled must be a boolean", 2)
    end
    return nativeSetAntiPushEnabled(enabled)
end

---@return boolean
function Engine.PVPTools.ToggleAntiPush()
    return nativeToggleAntiPush()
end

local function validateOptionalProfile(profile, functionName)
    if profile == nil then
        return
    end
    if type(profile) == "number" and profile % 1 == 0 and profile >= 1 then
        return
    end
    if type(profile) == "string" and profile ~= "" then
        return
    end
    error(functionName .. ": profile must be a 1-based integer, non-empty exact name, or nil", 3)
end

local function validateRequiredProfile(profile, functionName)
    if profile == nil then
        error(functionName .. ": profile is required", 3)
    end
    validateOptionalProfile(profile, functionName)
end

-- ============================================================================
-- MAGIC SHOOTER API - Wraps profiles and live entry action replacement
-- ============================================================================
local NativeMagicShooter = assert(MagicShooter, "MagicShooter native binding is unavailable")
local nativeMagicShooterGetProfileCount = assert(NativeMagicShooter.GetProfileCount)
local nativeMagicShooterGetProfileNames = assert(NativeMagicShooter.GetProfileNames)
local nativeMagicShooterGetActiveProfile = assert(NativeMagicShooter.GetActiveProfile)
local nativeMagicShooterSetActiveProfile = assert(NativeMagicShooter.SetActiveProfile)
local nativeMagicShooterNextProfile = assert(NativeMagicShooter.NextProfile)
local nativeMagicShooterGetEntries = assert(NativeMagicShooter.GetEntries)
local nativeMagicShooterSetEntryRune = assert(NativeMagicShooter.SetEntryRune)
local nativeMagicShooterSetEntrySpell = assert(NativeMagicShooter.SetEntrySpell)

Engine.MagicShooter = {}

---@return integer
function Engine.MagicShooter.GetProfileCount()
    return nativeMagicShooterGetProfileCount()
end

---@return string[]
function Engine.MagicShooter.GetProfileNames()
    return nativeMagicShooterGetProfileNames()
end

---@return table|nil
function Engine.MagicShooter.GetActiveProfile()
    return nativeMagicShooterGetActiveProfile()
end

---@return table|nil
function Engine.MagicShooter.GetCurrentProfile()
    return nativeMagicShooterGetActiveProfile()
end

---@param profile integer|string
---@return boolean
function Engine.MagicShooter.SetActiveProfile(profile)
    validateRequiredProfile(profile, "Engine.MagicShooter.SetActiveProfile")
    return nativeMagicShooterSetActiveProfile(profile)
end

---@param profile integer|string
---@return boolean
function Engine.MagicShooter.SetCurrentProfile(profile)
    validateRequiredProfile(profile, "Engine.MagicShooter.SetCurrentProfile")
    return nativeMagicShooterSetActiveProfile(profile)
end

---@return table|nil
function Engine.MagicShooter.NextProfile()
    return nativeMagicShooterNextProfile()
end

---@param profile? integer|string
---@return table[]|nil, string|nil
function Engine.MagicShooter.GetEntries(profile)
    validateOptionalProfile(profile, "Engine.MagicShooter.GetEntries")
    return nativeMagicShooterGetEntries(profile)
end

---@param entryIndex integer
---@param runeId integer
---@param profile? integer|string
---@return boolean, string|nil
function Engine.MagicShooter.SetEntryRune(entryIndex, runeId, profile)
    if type(entryIndex) ~= "number" or entryIndex % 1 ~= 0 or entryIndex < 1 then
        error("Engine.MagicShooter.SetEntryRune: entryIndex must be a 1-based integer", 2)
    end
    if type(runeId) ~= "number" or runeId % 1 ~= 0 or runeId < 1 or runeId > 65535 then
        error("Engine.MagicShooter.SetEntryRune: runeId must be an integer between 1 and 65535", 2)
    end
    validateOptionalProfile(profile, "Engine.MagicShooter.SetEntryRune")
    return nativeMagicShooterSetEntryRune(entryIndex, runeId, profile)
end

---@param entryIndex integer
---@param spellWords string
---@param profile? integer|string
---@return boolean, string|nil
function Engine.MagicShooter.SetEntrySpell(entryIndex, spellWords, profile)
    if type(entryIndex) ~= "number" or entryIndex % 1 ~= 0 or entryIndex < 1 then
        error("Engine.MagicShooter.SetEntrySpell: entryIndex must be a 1-based integer", 2)
    end
    if type(spellWords) ~= "string" or #spellWords < 1 or #spellWords > 255 then
        error("Engine.MagicShooter.SetEntrySpell: spellWords must contain between 1 and 255 bytes", 2)
    end
    validateOptionalProfile(profile, "Engine.MagicShooter.SetEntrySpell")
    return nativeMagicShooterSetEntrySpell(entryIndex, spellWords, profile)
end

-- ============================================================================
-- TARGETING API - Wraps Targeting profile state
-- ============================================================================
local NativeTargeting = assert(Targeting, "Targeting native binding is unavailable")
local nativeTargetingGetProfileCount = assert(NativeTargeting.GetProfileCount)
local nativeTargetingGetProfileNames = assert(NativeTargeting.GetProfileNames)
local nativeTargetingGetActiveProfile = assert(NativeTargeting.GetActiveProfile)
local nativeTargetingSetActiveProfile = assert(NativeTargeting.SetActiveProfile)
local nativeTargetingNextProfile = assert(NativeTargeting.NextProfile)

Engine.Targeting = {}

---@return integer
function Engine.Targeting.GetProfileCount()
    return nativeTargetingGetProfileCount()
end

---@return string[]
function Engine.Targeting.GetProfileNames()
    return nativeTargetingGetProfileNames()
end

---@return table|nil
function Engine.Targeting.GetActiveProfile()
    return nativeTargetingGetActiveProfile()
end

---@return table|nil
function Engine.Targeting.GetCurrentProfile()
    return nativeTargetingGetActiveProfile()
end

---@param profile integer|string
---@return boolean
function Engine.Targeting.SetActiveProfile(profile)
    validateRequiredProfile(profile, "Engine.Targeting.SetActiveProfile")
    return nativeTargetingSetActiveProfile(profile)
end

---@param profile integer|string
---@return boolean
function Engine.Targeting.SetCurrentProfile(profile)
    validateRequiredProfile(profile, "Engine.Targeting.SetCurrentProfile")
    return nativeTargetingSetActiveProfile(profile)
end

---@return table|nil
function Engine.Targeting.NextProfile()
    return nativeTargetingNextProfile()
end

-- ============================================================================
-- FEATURE CONFIGURATION APIS
-- Native setters are explicit and execute feature-owned side effects. GetEntries
-- functions return detached snapshots; changing a returned table changes nothing.
-- ============================================================================
local function exposeNativeFunctions(engineName, nativeTable, functionNames)
    assert(type(nativeTable) == "table", engineName .. " native binding is unavailable")
    local namespace = Engine[engineName] or {}
    Engine[engineName] = namespace
    for _, functionName in ipairs(functionNames) do
        namespace[functionName] = assert(nativeTable[functionName],
            engineName .. "." .. functionName .. " native binding is unavailable")
    end
end

exposeNativeFunctions("MagicShooter", MagicShooter, {
    "SetEntryEnabled", "SetEntryRequiresTarget", "SetEntryPVPSafe", "SetEntryShootOverAllies",
    "SetEntryCustomSpell", "SetEntryAttackSkillBuffSpell", "SetEntryDontCastWhileWalking",
    "SetEntryPrioritizeWithMomentum", "SetEntryOption", "SetEntryCondition",
    "SetEntryManaPercentage", "SetEntryHealthPercentage", "SetEntryHealthCondition",
    "SetEntryHarmony", "SetEntryHarmonyCondition", "SetEntryMonsterCount", "SetEntryMonsterCountCondition",
    "SetEntryMinimumMonsterHealthPercentage", "SetEntryMaximumMonsterHealthPercentage",
    "SetEntryRange", "SetEntryDangerLevel", "SetEntryCustomDelay", "SetEntryShootAfterWalkDelay",
    "SetEntryMomentumDelay", "SetEntryMeleeSkillIncreasePercentage",
    "SetEntryDistanceSkillIncreasePercentage", "SetEntryCastMethod", "SetEntryPatternAnchor",
    "SetEntryPatternSource", "SetEntryPatternVariant", "SetEntryMonsterNames"
})

exposeNativeFunctions("Healer", HealerControl, {
    "SetSpellWords", "SetSpellCastValue", "SetSpellManaCost", "SetSpellAttribute",
    "SetSpellCondition", "SetSpellEnabled", "SetItemId", "SetItemCastValue",
    "SetItemDelay", "SetItemAttribute", "SetItemCondition", "SetItemAction",
    "SetItemUseWhenFeared", "SetItemEnabled"
})

exposeNativeFunctions("Conditions", Conditions, {
    "GetSpells", "GetHoldSpells", "SetSpellWords", "SetSpellManaCost", "SetSpellFlag",
    "SetSpellEnabled", "SetHoldSpellWords", "SetHoldSpellManaCost", "SetHoldSpellFlag",
    "SetHoldSpellEnabled", "GetUseHasteWithSharpShooterEnabled", "SetUseHasteWithSharpShooterEnabled",
    "GetCastInProtectionZoneEnabled", "SetCastInProtectionZoneEnabled",
    "GetManaShieldTimerBased", "SetManaShieldTimerBased",
    "GetRecoverySpellTimerBased", "SetRecoverySpellTimerBased",
    "GetManaShieldDelay", "SetManaShieldDelay", "GetRecoverySpellDelay", "SetRecoverySpellDelay"
})

exposeNativeFunctions("HealFriend", HealFriend, {
    "GetVocations", "GetArea", "GetPlayerNames", "SetPlayerNames",
    "GetSafeHealthPercentage", "SetSafeHealthPercentage", "GetMode", "SetMode",
    "GetPriorityOverHealer", "SetPriorityOverHealer", "GetPrioritizeBeforeHealer",
    "SetPrioritizeBeforeHealer", "SetVocationEnabled", "SetVocationPriority",
    "SetActionEnabled", "SetActionManaCost", "SetActionSpellWords", "SetActionItemId",
    "SetActionHealthPercentage", "SetActionMethod", "SetAreaSpellWords", "SetAreaManaCost",
    "SetAreaVocation", "SetAreaPlayersNeeded", "SetAreaHealthPercentage", "SetAreaMinimumHarmony",
    "SetAreaExtended", "SetAreaEnabled", "SetAreaKnightRequired", "SetAreaPaladinRequired",
    "SetAreaSorcererRequired", "SetAreaDruidRequired", "SetAreaMonkRequired"
})

exposeNativeFunctions("AmmoRefill", AmmoControl, {
    "SetEntryItemId", "SetEntryRefillLeftHand", "SetEntryEquipFromHotkey",
    "SetEntryThreshold", "SetEntryEnabled"
})

exposeNativeFunctions("EquipmentManager", EquipmentManager, {
    "GetProfiles", "SetActiveProfile", "GetEntries", "SetEntryItemId", "SetEntrySecondaryItemId",
    "SetEntryExcludedItemIds", "SetEntryExcludedItemIdsEnabled", "SetEntryTier",
    "SetEntryEquipFromHotkey", "SetEntryEquipAction", "SetEntryEnabled", "SetEntryDelay",
    "SetEntryHasDelay", "SetEntryUseExtraConditions", "SetEntryCheckHealthRange",
    "SetEntryCheckManaRange", "SetEntryHealthManaOperator", "SetEntryHealthRange", "SetEntryManaRange",
    "SetEntryKeepEquipped", "SetEntryKeepEquippedDuration", "SetEntrySlot", "SetEntryConditionOperator",
    "SetConditionType", "SetConditionMonstersAround", "SetConditionPlayersAround",
    "SetConditionCreaturesCount", "SetConditionTargetName", "SetConditionCreatureNames"
})

exposeNativeFunctions("Alarms", AlarmsControl, {
    "GetConfig", "SetLowHealthPercentage", "SetLowManaPercentage", "SetFlashWindowEnabled",
    "SetBringToFocusEnabled", "SetIgnoreAllyPlayers", "SetGmChatCheckEnabled", "SetDamageTakenRange",
    "SetPlayerAttackFilterMode", "SetPlayerDetectedFilterMode", "SetSkullFilterMode",
    "SetCreatureDetectedNames", "SetAlarmMessages", "SetPlayerAttackNames",
    "SetPlayerDetectedNames", "SetSkullNames", "SetEnemyNames", "SetGmNames"
})

exposeNativeFunctions("PVPTools", PVPControl, {
    "GetConfig", "SetHoldTargetEnabled", "SetTrashOnMouseEnabled", "SetAntiPushEnabled",
    "SetKillTargetEnabled", "SetMagicWallKeeperEnabled", "SetWildGrowthKeeperEnabled",
    "SetPreviousSpotWallEnabled", "SetPushmaxEnabled", "SetPushAttackedPlayerEnabled",
    "SetKillTargetManaCost", "SetKillTargetHealthPercentage", "SetKillTargetSpellWords",
    "SetWallKeeperRuneIds", "SetWildGrowthKeeperRuneIds", "SetPreviousSpotRuneIds",
    "SetPushmaxDisintegrateRuneId", "SetPushmaxNonDisintegrateRuneId",
    "SetDelayBetweenRuneAndPush", "SetAntiPushTrashItem", "SetMouseTrashItem", "ResetLastTarget"
})

exposeNativeFunctions("ComboBot", ComboControl, {
    "GetMode", "SetMode", "GetClientEntries", "GetRoomEntries", "GetRoomState",
    "SetClientEntryLeaderName", "SetClientEntryLeaderSpellWords", "SetClientEntryMySpellWords",
    "SetClientEntryMyRuneId", "SetClientEntryLeaderAction", "SetClientEntryMyAction",
    "SetClientEntryFocusOption", "SetClientEntryShootType", "SetClientEntryRange",
    "SetClientEntryEnabled", "SetClientEntryRequiresTarget", "SetRoomEntryLeaderSpellWords",
    "SetRoomEntryMySpellWords", "SetRoomEntryLeaderRuneId", "SetRoomEntryMyRuneId",
    "SetRoomEntryLeaderAction", "SetRoomEntryMyAction", "SetRoomEntryEquipMode",
    "SetRoomEntryRange", "SetRoomEntryEnabled", "SetRoomEntryRequiresTarget"
})

exposeNativeFunctions("Targeting", Targeting, {
    "GetEntries", "SetEntryEnabled", "SetEntryMonsterName", "SetEntryMonstersIgnoreList",
    "SetEntryPriority", "SetEntryDangerLevel", "SetEntryAttackOption", "SetEntryKeepDistanceOption",
    "SetEntryMinimumHealthPercentage", "SetEntryMaximumHealthPercentage",
    "SetEntryKeepDistanceRange", "SetEntryAnchoringRange", "SetEntryLootMonster",
    "SetEntryStayDiagonal", "SetEntryMustBeShootable", "SetEntryMustBeReachable", "SetEntryAnchoring"
})

exposeNativeFunctions("Extras", Extras, {
    "GetEatFoodEnabled", "SetEatFoodEnabled", "GetAntiIdleEnabled", "SetAntiIdleEnabled",
    "GetChangeGoldEnabled", "SetChangeGoldEnabled", "GetDashEnabled", "SetDashEnabled",
    "GetDodgeEnabled", "SetDodgeEnabled", "GetTrainingEnabled", "SetTrainingEnabled",
    "GetReconnectEnabled", "SetReconnectEnabled", "GetReconnectWhenDeadEnabled", "SetReconnectWhenDeadEnabled",
    "GetAutoMountEnabled", "SetAutoMountEnabled", "GetFollowPlayerEnabled", "SetFollowPlayerEnabled",
    "GetDisplayItemIdEnabled", "SetDisplayItemIdEnabled",
    "GetOpenPrivateChannelOnPMEnabled", "SetOpenPrivateChannelOnPMEnabled",
    "GetDisableMagicEffectsEnabled", "SetDisableMagicEffectsEnabled",
    "GetShowShootEffectsEnabled", "SetShowShootEffectsEnabled", "GetFakeXlogEnabled", "SetFakeXlogEnabled",
    "GetFollowPlayerName", "SetFollowPlayerName", "GetEatFoodIds", "SetEatFoodIds",
    "GetGoldChangeIds", "SetGoldChangeIds", "GetExerciseWeaponIds", "SetExerciseWeaponIds",
    "GetExerciseDummyIds", "SetExerciseDummyIds", "GetTrainingDelay", "SetTrainingDelay",
    "GetFollowMode", "SetFollowMode", "GetFollowDistance", "SetFollowDistance",
    "StartTraining", "StopTraining"
})

exposeNativeFunctions("TankMode", TankMode, {
    "GetManaShieldEnabled", "SetManaShieldEnabled", "GetCancelManaShieldEnabled", "SetCancelManaShieldEnabled",
    "GetCancelWhileManaShieldReadyEnabled", "SetCancelWhileManaShieldReadyEnabled",
    "GetManaShieldPotionEnabled", "SetManaShieldPotionEnabled",
    "GetPotionOnSpellCooldownEnabled", "SetPotionOnSpellCooldownEnabled",
    "GetPotionWhenFearedEnabled", "SetPotionWhenFearedEnabled",
    "GetManaShieldPotionId", "SetManaShieldPotionId",
    "GetManaShieldManaCost", "SetManaShieldManaCost",
    "GetCancelManaShieldManaCost", "SetCancelManaShieldManaCost",
    "GetManaShieldHealthPercentage", "SetManaShieldHealthPercentage",
    "GetManaShieldManaPercentage", "SetManaShieldManaPercentage",
    "GetCancelManaShieldHealthPercentage", "SetCancelManaShieldHealthPercentage",
    "GetCancelManaShieldManaPercentage", "SetCancelManaShieldManaPercentage",
    "GetManaShieldSpellWords", "SetManaShieldSpellWords",
    "GetCancelManaShieldSpellWords", "SetCancelManaShieldSpellWords"
})

exposeNativeFunctions("Looter", Looter, {
    "GetActionType", "SetActionType", "GetMode", "SetMode",
    "GetMinimumCapacity", "SetMinimumCapacity", "LootAroundCharacter"
})

exposeNativeFunctions("TimerActions", TimerActions, {
    "GetEntries", "SetEntryEnabled", "SetEntrySpellWords", "SetEntryItemId",
    "SetEntryType", "SetEntryDelay", "SetEntryUseInProtectionZone",
    "AddEntry", "RemoveEntry", "ClearEntries"
})

exposeNativeFunctions("SuppliesSorter", SuppliesSorter, {
    "GetEntries", "SetEntryEnabled", "SetEntryDestinationContainerId", "SetEntryItemIds",
    "AddEntry", "RemoveEntry", "ClearEntries"
})

exposeNativeFunctions("Channels", Channels, {
    "GetEntries", "SetEntryEnabled", "SetEntryName", "SetEntryMessage",
    "SetEntryIntervalSeconds", "SetEntryChannelId", "SetEntryTalkAction",
    "GetGlobalDelay", "SetGlobalDelay", "AddEntry", "RemoveEntry", "ClearEntries"
})

exposeNativeFunctions("Walker", Walker, {
    "Resume", "SetEnabled", "IsEnabled", "IsStuck", "GoTo",
    "GetSelectedWaypointIndex", "SetSelectedWaypointIndex", "SelectClosestWaypoint",
    "GetWaypointCount", "GetWaypoints", "AddWaypoint", "InsertWaypoint", "ReplaceWaypoint",
    "DeleteWaypoint", "ClearWaypoints", "MoveWaypointUp", "MoveWaypointDown",
    "SetStartFromNearestWaypoint", "GetStartFromNearestWaypoint", "SetNodeDistance", "GetNodeDistance",
    "SetWalkToLureCenter", "GetWalkToLureCenter", "SetLeaveLureOnPlayer", "GetLeaveLureOnPlayer",
    "SetLeaveLurePlayerMode", "GetLeaveLurePlayerMode",
    "SetDebugHud", "GetDebugHud", "SetAutoRecorderEnabled", "GetAutoRecorderEnabled",
    "SetAutoRecorderOptions", "GetAutoRecorderOptions", "SetDistanceBetweenWaypoints",
    "GetDistanceBetweenWaypoints", "SetPausedByLua", "IsPausedByLua"
})

exposeNativeFunctions("Lure", Lure, {
    "SetEnabled", "IsEnabled", "GetState", "IsLuring", "IsFighting",
    "SetForceLure", "IsForceLure", "EndForceLure", "SetOption", "GetOption",
    "SetNearRange", "GetNearRange", "SetAttackWhileLuring", "GetAttackWhileLuring",
    "SetConsiderOnlyReachable", "GetConsiderOnlyReachable", "SetSlowWalkDelayMs", "GetSlowWalkDelayMs",
    "SetSlowWalkingCreaturesCount", "GetSlowWalkingCreaturesCount", "SetSlowWalkBurstSteps",
    "GetSlowWalkBurstSteps", "SetIgnoringMonsters", "GetIgnoringMonsters",
    "SetStartEndLureActive", "GetStartEndLureActive", "SetWaypointDynamicLureActive",
    "GetWaypointDynamicLureActive", "SetUnblocking", "GetUnblocking", "GetLuredCreaturesCount",
    "HasActiveSettings", "IsOtherPlayerOnScreen", "GetSettings", "GetSettingCount",
    "AddSetting", "RemoveSetting", "ClearSettings"
})

-- HUD mutations retain per-script ownership because these functions are the
-- original context-aware native closures, merely grouped under Engine.HUD.
exposeNativeFunctions("HUD", HUD, {
    "AddScreenText", "AddScreenImage", "AddWorldText", "AddWorldImage", "AddWorldBox",
    "UpdateLifetime", "UpdateOffset", "RemoveElement", "UpdateText", "UpdateImageLabel",
    "UpdateColor", "UpdateWidth", "UpdateHeight", "UpdateBorderWidth", "UpdateBorderColor",
    "SetEnabled", "SetParent", "ClearParent", "SetDraggable", "SetDragTarget", "SetOnDragEnd",
    "SetAlignment", "SetPosition", "SetScreenPosition", "SetZIndex", "SetClickable",
    "GetElementEnabled", "GetElementVisible", "GetElementText", "GetElementColor",
    "GetWorldElementPosition", "GetScreenElementPosition", "GetElementWidth", "GetElementHeight"
})

exposeNativeFunctions("HUD", HUDControl, {
    "GetConfig", "SetMagicWallTimersEnabled", "SetXRayEnabled", "SetTargetingAnchorEnabled",
    "SetLevelSpyEnabled", "SetMagicWallIds", "SetWildGrowthIds", "SetTimerColor",
    "GetSpecialFoodCounters", "SetSpecialFoodCounterDelay", "RemoveSpecialFoodCounter"
})

exposeNativeFunctions("Delays", Delays, {
    "GetHealSpellDelay", "SetHealSpellDelay", "GetHealItemDelay", "SetHealItemDelay",
    "GetSupportSpellDelay", "SetSupportSpellDelay", "GetAttackSpellDelay", "SetAttackSpellDelay",
    "GetAttackItemDelay", "SetAttackItemDelay", "GetAttackCreatureDelay", "SetAttackCreatureDelay",
    "GetAntiIdleDelay", "SetAntiIdleDelay", "GetAlarmDelay", "SetAlarmDelay",
    "GetEatFoodDelay", "SetEatFoodDelay", "GetDashDelay", "SetDashDelay",
    "GetWalkerWalkDelay", "SetWalkerWalkDelay", "GetWalkerUseItemDelay", "SetWalkerUseItemDelay",
    "GetWalkerUseWithItemDelay", "SetWalkerUseWithItemDelay", "GetTargetingWalkDelay", "SetTargetingWalkDelay",
    "GetEquipItemDelay", "SetEquipItemDelay", "GetDropItemDelay", "SetDropItemDelay",
    "GetHealFriendSpellDelay", "SetHealFriendSpellDelay", "GetHealFriendItemDelay", "SetHealFriendItemDelay",
    "GetUseItemInContainerDelay", "SetUseItemInContainerDelay", "GetLootDelay", "SetLootDelay",
    "GetReconnectDelay", "SetReconnectDelay", "GetMoveDelay", "SetMoveDelay",
    "GetSpellCooldownSystemEnabled", "SetSpellCooldownSystemEnabled",
    "GetItemCooldownSystemEnabled", "SetItemCooldownSystemEnabled",
    "GetUseWithCooldownSystemEnabled", "SetUseWithCooldownSystemEnabled",
    "GetGlobalQueueSystemEnabled", "SetGlobalQueueSystemEnabled",
    "GetConnectionStabilityCheckEnabled", "SetConnectionStabilityCheckEnabled",
    "GetSpellPredictionSystemEnabled", "SetSpellPredictionSystemEnabled",
    "GetItemPredictionSystemEnabled", "SetItemPredictionSystemEnabled",
    "GetServerPingCheckEnabled", "SetServerPingCheckEnabled"
})

exposeNativeFunctions("Scripter", ScripterControl, {
    "Refresh", "GetAvailableScripts", "GetRunningScripts", "IsRunning",
    "Start", "Stop", "Restart", "StopSelf", "GetAutoStartEnabled", "SetAutoStartEnabled"
})

return Engine



