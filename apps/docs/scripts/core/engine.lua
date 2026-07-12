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
    UpdateSpell = Healer.UpdateSpell,
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

--- Update spell cast value and/or mana cost
---@param index number 1-based index
---@param castValue number|nil New cast value (optional)
---@param manaCost number|nil New mana cost (optional)
---@return boolean Success (false if spell not found)
function Engine.Healer.ModifySpell(index, castValue, manaCost)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    
    local spell = Healer.GetSpell(index)
    if not spell then
        return false
    end
    
    local updateData = {}
    if castValue then updateData.cast_value = castValue end
    if manaCost then updateData.mana_cost = manaCost end
    
    return Healer.UpdateSpell(index, updateData)
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

--- Update ammo configuration
---@param index number 1-based index
---@param updateData table Table with fields to update (refill_at_count, refill_in_left_hand, equip_from_hotkey, enabled)
---@return boolean Success
function Engine.AmmoRefill.Update(index, updateData)
    if type(index) ~= "number" or index < 1 then
        return false
    end
    if type(updateData) ~= "table" then
        error("Engine.AmmoRefill.Update: updateData must be a table", 2)
    end
    
    return AmmoRefill.UpdateAmmo(index, updateData)
end

--- Modify specific fields of an ammo entry (convenience wrapper)
---@param index number 1-based index
---@param refillAtCount number|nil Refill threshold (optional)
---@param refillInLeftHand boolean|nil Use left hand slot (optional)
---@param equipFromHotkey boolean|nil Use hotkey to equip (optional)
---@return boolean Success
function Engine.AmmoRefill.Modify(index, refillAtCount, refillInLeftHand, equipFromHotkey)
    local updateData = {}
    
    if refillAtCount ~= nil then
        if type(refillAtCount) ~= "number" then
            error("Engine.AmmoRefill.Modify: refillAtCount must be a number", 2)
        end
        updateData.refill_at_count = refillAtCount
    end
    
    if refillInLeftHand ~= nil then
        if type(refillInLeftHand) ~= "boolean" then
            error("Engine.AmmoRefill.Modify: refillInLeftHand must be a boolean", 2)
        end
        updateData.refill_in_left_hand = refillInLeftHand
    end
    
    if equipFromHotkey ~= nil then
        if type(equipFromHotkey) ~= "boolean" then
            error("Engine.AmmoRefill.Modify: equipFromHotkey must be a boolean", 2)
        end
        updateData.equip_from_hotkey = equipFromHotkey
    end
    
    return AmmoRefill.UpdateAmmo(index, updateData)
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

return Engine



