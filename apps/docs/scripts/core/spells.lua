Spells = Spells or {}

local function require_cooldown_table()
    if type(Cooldown) ~= "table" then
        error("Spells: required runtime table 'Cooldown' is not available", 3)
    end
end

local function resolve_spell_words(spellOrWordsOrId, callerName)
    local valueType = type(spellOrWordsOrId)

    if valueType == "string" then
        if spellOrWordsOrId == "" then
            error(callerName .. ": spell words cannot be empty", 3)
        end
        return spellOrWordsOrId
    end

    if valueType == "number" then
        local words = Spells.GetWordsById(spellOrWordsOrId)
        if type(words) ~= "string" or words == "" then
            error(callerName .. ": unknown spell id " .. tostring(spellOrWordsOrId), 3)
        end
        return words
    end

    error(callerName .. ": expected spell words (string) or spell id (number)", 3)
end

function Spells.GetIdByWords(words)
    require_cooldown_table()
    if type(words) ~= "string" or words == "" then
        error("Spells.GetIdByWords: words must be a non-empty string", 2)
    end
    return Cooldown.GetSpellIdByWords(words)
end

function Spells.GetIdByName(name)
    require_cooldown_table()
    if type(name) ~= "string" or name == "" then
        error("Spells.GetIdByName: name must be a non-empty string", 2)
    end
    return Cooldown.GetSpellIdByName(name)
end

function Spells.GetWordsById(spellId)
    require_cooldown_table()
    if type(spellId) ~= "number" then
        error("Spells.GetWordsById: spellId must be a number", 2)
    end
    return Cooldown.GetSpellWordsById(spellId)
end

function Spells.GetGroupIds(spellOrWordsOrId)
    require_cooldown_table()
    local spellWords = resolve_spell_words(spellOrWordsOrId, "Spells.GetGroupIds")
    return Cooldown.GetSpellGroupCooldownIdsByWords(spellWords)
end

function Spells.IsInCooldown(spellOrWordsOrId)
    require_cooldown_table()
    local spellWords = resolve_spell_words(spellOrWordsOrId, "Spells.IsInCooldown")
    return Cooldown.HasSpellCooldown(spellWords)
end

function Spells.GetLeftCooldownTime(spellOrWordsOrId)
    require_cooldown_table()
    local spellWords = resolve_spell_words(spellOrWordsOrId, "Spells.GetLeftCooldownTime")
    return Cooldown.GetSpellCooldownTimeLeft(spellWords)
end

function Spells.IsReady(spellOrWordsOrId)
    return not Spells.IsInCooldown(spellOrWordsOrId)
end

function Spells.WillBeReady(spellOrWordsOrId, timeMs)
    local leftTime = Spells.GetLeftCooldownTime(spellOrWordsOrId)
    return leftTime <= (timeMs or 0)
end

function Spells.GetLeftGroupCooldownTime(groupId)
    require_cooldown_table()
    if type(groupId) ~= "number" then
        error("Spells.GetLeftGroupCooldownTime: groupId must be a number", 2)
    end
    return Cooldown.GetGroupCooldownTimeLeft(groupId)
end

function Spells.GroupIsInCooldown(groupId)
    require_cooldown_table()
    if type(groupId) ~= "number" then
        error("Spells.GroupIsInCooldown: groupId must be a number", 2)
    end
    return Cooldown.HasGroupCooldown(groupId)
end

function Spells.IsUseWithItemExhausted()
    require_cooldown_table()
    return Cooldown.IsUseWithItemExhausted()
end

function Spells.GetInfo(spellOrWordsOrId)
    local spellWords = resolve_spell_words(spellOrWordsOrId, "Spells.GetInfo")
    local spellId = Spells.GetIdByWords(spellWords)

    return {
        id = spellId,
        words = spellWords,
        cooldownId = spellId,
        groupIds = Spells.GetGroupIds(spellWords),
        inCooldown = Spells.IsInCooldown(spellWords),
        leftCooldownTime = Spells.GetLeftCooldownTime(spellWords)
    }
end

Spells.Item = Spells.Item or {}

function Spells.Item.IsInCooldown(itemId)
    require_cooldown_table()
    if type(itemId) ~= "number" then
        error("Spells.Item.IsInCooldown: itemId must be a number", 2)
    end
    return Cooldown.HasItemCooldown(itemId)
end

function Spells.Item.GetLeftCooldownTime(itemId)
    require_cooldown_table()
    if type(itemId) ~= "number" then
        error("Spells.Item.GetLeftCooldownTime: itemId must be a number", 2)
    end
    return Cooldown.GetItemCooldownTimeLeft(itemId)
end

function Spells.Item.GetCooldownId(itemId)
    require_cooldown_table()
    if type(itemId) ~= "number" then
        error("Spells.Item.GetCooldownId: itemId must be a number", 2)
    end
    return Cooldown.GetItemCooldownId(itemId)
end

function Spells.Item.GetGroupIds(itemId)
    require_cooldown_table()
    if type(itemId) ~= "number" then
        error("Spells.Item.GetGroupIds: itemId must be a number", 2)
    end
    return Cooldown.GetItemGroupCooldownIds(itemId)
end

function Spells.Item.IsReady(itemId)
    return not Spells.Item.IsInCooldown(itemId)
end

function Spells.Item.WillBeReady(itemId, timeMs)
    local leftTime = Spells.Item.GetLeftCooldownTime(itemId)
    return leftTime <= (timeMs or 0)
end

function Spells.Item.GetInfo(itemId)
    return {
        id = itemId,
        cooldownId = Spells.Item.GetCooldownId(itemId),
        groupIds = Spells.Item.GetGroupIds(itemId),
        inCooldown = Spells.Item.IsInCooldown(itemId),
        leftCooldownTime = Spells.Item.GetLeftCooldownTime(itemId)
    }
end

Spells.GetIdByWords = Spells.GetIdByWords
Spells.GetIdByName = Spells.GetIdByName
Spells.GetWordsById = Spells.GetWordsById
Spells.IsInCooldown = Spells.IsInCooldown
Spells.GetLeftCooldownTime = Spells.GetLeftCooldownTime
Spells.GroupIsInCooldown = Spells.GroupIsInCooldown
Spells.GetLeftGroupCooldownTime = Spells.GetLeftGroupCooldownTime
Spells.IsUseWithItemExhausted = Spells.IsUseWithItemExhausted

return Spells




