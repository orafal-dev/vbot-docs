-- File: core/Cooldowns.lua
-- Cooldown management library for ValidusBot
-- Provides high-level API for spell/item/group Cooldowns

--[[
    Usage Examples:
    
    -- Check if a spell is in cooldown
    if Cooldowns.Spell.IsInCooldown("exori gran") then
        print("spell on cooldown!")
    end
    
    -- Get time left on cooldown
    local timeLeft = Cooldowns.Spell.GetTimeLeft("exura vita")
    print("spell ready in " .. Cooldowns.Utils.FormatTime(timeLeft))
    
    -- Check by item ID
    if Cooldowns.Item.IsInCooldown(3155) then  -- Sudden Death rune
        print("Rune on cooldown!")
    end
    
    -- Check action group Cooldowns (uses CooldownGroupId from lua_consts.lua)
    if Cooldowns.Group.IsInCooldown(CooldownGroupId.ATTACK) then
        print("Attack group on cooldown!")
    end
    
    -- Wait for spell to be ready
    while Cooldowns.Spell.IsInCooldown("exura vita") do
        local timeLeft = Cooldowns.Spell.GetTimeLeft("exura vita")
        print("Waiting " .. Cooldowns.Utils.FormatTime(timeLeft))
        wait(100)
    end
    Game.CastSpell("exura vita")
]]

-- ============================================================================
-- Cooldowns Table - Main namespace
-- ============================================================================
---@class Cooldowns
Cooldowns = {}

-- ============================================================================
-- spell Cooldowns
-- ============================================================================
Cooldowns.Spell = {}

--- Check if a spell is in cooldown by its words
---@param spellWords string The spell words (e.g. "exori gran", "exura vita")
---@return boolean onCooldown
function Cooldowns.Spell.IsInCooldown(spellWords)
    if type(spellWords) ~= "string" then
        error("Cooldowns.Spell.IsInCooldown: argument must be a string")
    end
    return Cooldown.HasSpellCooldown(spellWords)
end

--- Get the time left on a spell's cooldown
---@param spellWords string The spell words (e.g. "exori gran")
---@return integer timeLeftMs Time left in milliseconds, or 0 if not on cooldown
function Cooldowns.Spell.GetTimeLeft(spellWords)
    if type(spellWords) ~= "string" then
        error("Cooldowns.Spell.GetTimeLeft: argument must be a string")
    end
    return Cooldown.GetSpellCooldownTimeLeft(spellWords)
end

--- Check if a spell will be ready by a certain time
--- Returns true when spell cooldown expires within provided time window.
---@param spellWords string The spell words
---@param timeMs? integer Time in milliseconds from now (default 0)
---@return boolean willBeReady
function Cooldowns.Spell.WillBeReady(spellWords, timeMs)
    local timeLeft = Cooldowns.Spell.GetTimeLeft(spellWords)
    return timeLeft <= (timeMs or 0)
end

--- Check if a spell is ready (not on cooldown)
---@param spellWords string The spell words
---@return boolean isReady True if the spell is ready to cast
function Cooldowns.Spell.IsReady(spellWords)
    return not Cooldowns.Spell.IsInCooldown(spellWords)
end

-- ============================================================================
-- item/Rune Cooldowns
-- ============================================================================
Cooldowns.Item = {}

--- Check if an item is in cooldown by its item ID
---@param itemId integer The item ID (e.g. 3155 for Sudden Death)
---@return boolean onCooldown
function Cooldowns.Item.IsInCooldown(itemId)
    if type(itemId) ~= "number" then
        error("Cooldowns.Item.IsInCooldown: argument must be a number")
    end
    return Cooldown.HasItemCooldown(itemId)
end

--- Get the time left on an item's cooldown
---@param itemId integer The item ID
---@return integer timeLeftMs Time left in milliseconds, or 0 if not on cooldown
function Cooldowns.Item.GetTimeLeft(itemId)
    if type(itemId) ~= "number" then
        error("Cooldowns.Item.GetTimeLeft: argument must be a number")
    end
    return Cooldown.GetItemCooldownTimeLeft(itemId)
end

--- Check if an item will be ready by a certain time
--- Returns true when item cooldown expires within provided time window.
---@param itemId integer The item ID
---@param timeMs? integer Time in milliseconds from now (default 0)
---@return boolean willBeReady
function Cooldowns.Item.WillBeReady(itemId, timeMs)
    local timeLeft = Cooldowns.Item.GetTimeLeft(itemId)
    return timeLeft <= (timeMs or 0)
end

--- Check if an item is ready (not on cooldown)
---@param itemId integer The item ID
---@return boolean isReady True if the item is ready to use
function Cooldowns.Item.IsReady(itemId)
    return not Cooldowns.Item.IsInCooldown(itemId)
end

-- ============================================================================
-- Action group Cooldowns
-- Use CooldownGroupId constants from lua_consts.lua
-- CooldownGroupId.ATTACK, CooldownGroupId.HEALING, etc.
-- ============================================================================
Cooldowns.Group = {}

--- Check if an action group is in cooldown
---@param groupId integer The action group ID (use CooldownGroupId constants)
---@return boolean onCooldown
function Cooldowns.Group.IsInCooldown(groupId)
    if type(groupId) ~= "number" then
        error("Cooldowns.Group.IsInCooldown: argument must be a number")
    end
    return Cooldown.HasGroupCooldown(groupId)
end

--- Get the time left on an action group's cooldown
---@param groupId integer The action group ID (use CooldownGroupId constants)
---@return integer timeLeftMs Time left in milliseconds, or 0 if not on cooldown
function Cooldowns.Group.GetTimeLeft(groupId)
    if type(groupId) ~= "number" then
        error("Cooldowns.Group.GetTimeLeft: argument must be a number")
    end
    return Cooldown.GetGroupCooldownTimeLeft(groupId)
end

--- Check if a group will be ready by a certain time
--- Returns true when group cooldown expires within provided time window.
---@param groupId integer The action group ID
---@param timeMs? integer Time in milliseconds from now (default 0)
---@return boolean willBeReady
function Cooldowns.Group.WillBeReady(groupId, timeMs)
    local timeLeft = Cooldowns.Group.GetTimeLeft(groupId)
    return timeLeft <= (timeMs or 0)
end

--- Check if a group is ready (not on cooldown)
---@param groupId integer The action group ID
---@return boolean isReady True if the group is ready
function Cooldowns.Group.IsReady(groupId)
    return not Cooldowns.Group.IsInCooldown(groupId)
end

-- ============================================================================
-- Use-With-item Exhaustion (for using items on creatures/players)
-- ============================================================================
Cooldowns.UseWith = {}

--- Check if the "use with" action is exhausted
-- This prevents rapid use-with actions (e.g., using runes on creatures)
---@return boolean isExhausted True if exhausted, false if ready
function Cooldowns.UseWith.IsExhausted()
    return Cooldown.IsUseWithItemExhausted()
end

--- Alias for checking if use-with is ready
---@return boolean isReady True if ready to use items on targets
function Cooldowns.UseWith.IsReady()
    return not Cooldowns.UseWith.IsExhausted()
end

-- ============================================================================
-- Utility Functions
-- ============================================================================
Cooldowns.Utils = {}

--- Format milliseconds to human-readable time
---@param ms number Time in milliseconds
---@return string formatted Formatted time (e.g. "1.5s", "2m 30s")
function Cooldowns.Utils.FormatTime(ms)
    if type(ms) ~= "number" or ms <= 0 then
        return "0s"
    end
    
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    if hours > 0 then
        minutes = minutes % 60
        seconds = seconds % 60
        return string.format("%dh %dm %ds", hours, minutes, seconds)
    elseif minutes > 0 then
        seconds = seconds % 60
        return string.format("%dm %ds", minutes, seconds)
    elseif seconds > 0 then
        local ms_remaining = ms % 1000
        if ms_remaining > 0 then
            return string.format("%.1fs", ms / 1000)
        else
            return string.format("%ds", seconds)
        end
    else
        return string.format("%dms", ms)
    end
end

--- Get all Cooldowns status (useful for debugging)
---@param spells? string[] Optional list of spell words to check
---@return table status Table of cooldown statuses
function Cooldowns.Utils.GetStatus(spells)
    local status = {
        spells = {},
        groups = {
            attack = Cooldowns.Group.GetTimeLeft(CooldownGroupId.ATTACK),
            healing = Cooldowns.Group.GetTimeLeft(CooldownGroupId.HEALING),
            support = Cooldowns.Group.GetTimeLeft(CooldownGroupId.SUPPORT),
            special = Cooldowns.Group.GetTimeLeft(CooldownGroupId.SPECIAL),
            crippling = Cooldowns.Group.GetTimeLeft(CooldownGroupId.CRIPPLING),
            focus = Cooldowns.Group.GetTimeLeft(CooldownGroupId.FOCUS),
            ultimate = Cooldowns.Group.GetTimeLeft(CooldownGroupId.ULTIMATE)
        },
        useWith = Cooldowns.UseWith.IsExhausted()
    }
    
    if spells and type(spells) == "table" then
        for _, spellWords in ipairs(spells) do
            status.spells[spellWords] = {
                inCooldown = Cooldowns.Spell.IsInCooldown(spellWords),
                timeLeft = Cooldowns.Spell.GetTimeLeft(spellWords)
            }
        end
    end
    
    return status
end

--- Print cooldown status to console (for debugging)
---@param spells? string[] Optional list of spells to check
function Cooldowns.Utils.PrintStatus(spells)
    local status = Cooldowns.Utils.GetStatus(spells)
    
    print("=== Cooldown Status ===")
    
    print("\nGroups:")
    print("  Attack:    " .. Cooldowns.Utils.FormatTime(status.groups.attack))
    print("  Healing:   " .. Cooldowns.Utils.FormatTime(status.groups.healing))
    print("  Support:   " .. Cooldowns.Utils.FormatTime(status.groups.support))
    print("  Special:   " .. Cooldowns.Utils.FormatTime(status.groups.special))
    print("  Crippling: " .. Cooldowns.Utils.FormatTime(status.groups.crippling))
    print("  Focus:     " .. Cooldowns.Utils.FormatTime(status.groups.focus))
    print("  Ultimate:  " .. Cooldowns.Utils.FormatTime(status.groups.ultimate))
    
    print("\nUse-With: " .. (status.useWith and "Exhausted" or "Ready"))
    
    if status.spells and next(status.spells) then
        print("\nSpells:")
        for spellWords, info in pairs(status.spells) do
            local statusStr = info.inCooldown 
                and ("CD: " .. Cooldowns.Utils.FormatTime(info.timeLeft))
                or "Ready"
            print(string.format("  %-20s %s", spellWords, statusStr))
        end
    end
    
    print("=====================")
end

-- Return the module
return Cooldowns




