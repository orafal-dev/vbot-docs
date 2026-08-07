Self = Self or {}

--- Validates that value is a positive integer.
---@param value any
---@param argName string
---@param functionName string
local function validate_positive_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value <= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be a positive integer")
    end
end

--- Validates that value is an integer within an inclusive range.
---@param value any
---@param minimum integer
---@param maximum integer
---@param argName string
---@param functionName string
local function validate_integer_in_range(value, minimum, maximum, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value < minimum or value > maximum then
        error(functionName .. ": argument '" .. argName .. "' must be an integer between " .. minimum .. " and " .. maximum)
    end
end

--- Validates that table has integer x, y, z fields.
---@param pos table position table {x,y,z}
---@param functionName string
local function validate_position_table(pos, functionName)
    if type(pos) ~= "table" then
        error(functionName .. ": argument 'position' must be a table {x, y, z}")
    end

    if type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number" then
        error(functionName .. ": position table must contain numeric x, y, z")
    end

    if pos.x % 1 ~= 0 or pos.y % 1 ~= 0 or pos.z % 1 ~= 0 then
        error(functionName .. ": position x, y, z must be integers")
    end
end

--- Says text in local chat.
---@param message string
---@return boolean
function Self.Say(message)
    if type(message) ~= "string" or message == "" then
        error("Self.Say: argument 'message' must be a non-empty string")
    end

    return Game.Say(message)
end

--- Returns private C++-bound Self method by name when available.
---@param preferredName string
---@return function|nil
local function get_self_cpp_binding(preferredName)
    local fn = Self[preferredName]
    if type(fn) == "function" then
        return fn
    end
    return nil
end

local CHARACTER_FLAG = {
    poisoned = 0,
    burning = 1,
    electrified = 2,
    drunk = 3,
    manaShielded = 4,
    paralyzed = 5,
    hasted = 6,
    inCombat = 7,
    drowning = 8,
    freezing = 9,
    dazzled = 10,
    cursed = 11,
    strengthened = 12,
    inProtectionZone = 14,
    bleeding = 15,
    rooted = 19,
    feared = 20,
    newManaShield = 26
}

--- Calls a private C++ boolean getter and normalizes its result.
---@param bindingName string
---@return boolean|nil
local function call_cpp_boolean(bindingName)
    local fn = get_self_cpp_binding(bindingName)
    if not fn then
        return nil
    end

    local ok, result = pcall(fn)
    if not ok then
        return nil
    end

    if type(result) == "boolean" then
        return result
    end

    return nil
end

--- Reads one version-aware player condition flag.
---@param flag integer
---@return boolean|nil
local function call_character_status(flag)
    local fn = get_self_cpp_binding("_HasStatusFlag_CPP")
    if not fn then
        return nil
    end

    local ok, result = pcall(fn, flag)
    if not ok or type(result) ~= "boolean" then
        return nil
    end

    return result
end

--- Returns current health points.
---@return integer|nil
function Self.GetHealth()
    local fn = get_self_cpp_binding("_GetHealth_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns max health points.
---@return integer|nil
function Self.GetMaxHealth()
    local fn = get_self_cpp_binding("_GetMaxHealth_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns current mana points.
---@return integer|nil
function Self.GetMana()
    local fn = get_self_cpp_binding("_GetMana_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns max mana points.
---@return integer|nil
function Self.GetMaxMana()
    local fn = get_self_cpp_binding("_GetMaxMana_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns health percentage 0-100.
---@return number|nil
function Self.GetHealthPercentage()
    local fn = get_self_cpp_binding("_GetHealthPercentage_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns mana percentage 0-100.
---@return number|nil
function Self.GetManaPercentage()
    local fn = get_self_cpp_binding("_GetManaPercentage_CPP")
    if not fn then
        return nil
    end

    return fn()
end

--- Returns a read-only snapshot of currently available player stats.
--- Values can be nil when local player data is unavailable.
---@return table
function Self.GetStatsSnapshot()
    return {
        health = Self.GetHealth(),
        maxHealth = Self.GetMaxHealth(),
        mana = Self.GetMana(),
        maxMana = Self.GetMaxMana(),
        capacity = Self.GetCapacity(),
        stamina = Self.GetStamina(),
        online = Self.IsOnline(),
        isAlive = Self.IsAlive(),
        isAttacking = Self.IsAttacking(),
        isFollowing = Self.IsFollowing(),
        manaShieldCapacity = Self.GetManaShieldCapacity(),
        maxManaShieldCapacity = Self.GetMaxManaShieldCapacity(),
        targetId = Self.GetTargetId(),
        followId = Self.GetFollowId(),
        mousePosition = Self.GetMousePositionInWorld(),
        mouseWorldX = Self.GetMouseWorldX(),
        mouseWorldY = Self.GetMouseWorldY(),
        mouseWorldZ = Self.GetMouseWorldZ(),
        capacityFloor = Self.GetCapacityFloor(),
        level = Self.GetLevel(),
        soul = Self.GetSoul(),
        levelPercent = Self.GetLevelPercentage(),
        staminaHours = Self.GetStaminaHours(),
        staminaDays = Self.GetStaminaDays(),
        hasTarget = Self.HasTarget(),
        hasFollow = Self.HasFollow(),
        healthPercent = Self.GetHealthPercentage(),
        manaPercent = Self.GetManaPercentage(),
        statusFlags = Self.GetStatusFlagsSnapshot()
    }
end

--- Returns current carrying capacity.
---@return number|nil
function Self.GetCapacity()
    if type(Game) ~= "table" or type(Game.GetCapacity) ~= "function" then
        return nil
    end

    return Game.GetCapacity()
end

--- Returns the client-reported inventory count for an item, optionally filtered by tier.
---@param itemId integer Item type id (1..65535)
---@param tierLevel? integer Tier level (0..255); defaults to 0
---@return integer
function Self.GetItemCount(itemId, tierLevel)
    validate_integer_in_range(itemId, 1, 65535, "itemId", "Self.GetItemCount")

    local tier = tierLevel
    if tier == nil then
        tier = 0
    end
    validate_integer_in_range(tier, 0, 255, "tierLevel", "Self.GetItemCount")

    if type(Game) ~= "table" or type(Game.GetItemCount) ~= "function" then
        return 0
    end

    return Game.GetItemCount(itemId, tier)
end

--- Returns the world name for a character from the character list.
---@param characterName string
---@return string|nil
function Self.GetCharacterWorld(characterName)
    if type(characterName) ~= "string" or characterName == "" then
        error("Self.GetCharacterWorld: argument 'characterName' must be a non-empty string")
    end

    if type(Game) ~= "table" or type(Game.GetCharacterWorld) ~= "function" then
        return nil
    end

    return Game.GetCharacterWorld(characterName)
end

--- Returns stamina in minutes.
---@return integer|nil
function Self.GetStamina()
    if type(Game) ~= "table" or type(Game.GetStamina) ~= "function" then
        return nil
    end

    return Game.GetStamina()
end

--- Returns online state.
---@return boolean|nil
function Self.IsOnline()
    if type(Game) ~= "table" or type(Game.IsOnline) ~= "function" then
        return nil
    end

    return Game.IsOnline()
end

--- Returns alive state.
---@return boolean|nil
function Self.IsAlive()
    if type(Game) ~= "table" or type(Game.IsAlive) ~= "function" then
        return nil
    end

    return Game.IsAlive()
end

--- Returns attacking state.
---@return boolean|nil
function Self.IsAttacking()
    if type(Game) ~= "table" or type(Game.IsAttacking) ~= "function" then
        return nil
    end

    return Game.IsAttacking()
end

--- Returns following state.
---@return boolean|nil
function Self.IsFollowing()
    if type(Game) ~= "table" or type(Game.IsFollowing) ~= "function" then
        return nil
    end

    return Game.IsFollowing()
end

--- Returns true if character is hungry.
---@return boolean|nil
function Self.IsHungry()
    return call_cpp_boolean("_IsHungry_CPP")
end

--- Returns true if character is in resting area.
---@return boolean|nil
function Self.IsInRestingArea()
    return call_cpp_boolean("_IsInRestingArea_CPP")
end

--- Returns true if character is poisoned.
---@return boolean|nil
function Self.IsPoisoned()
    return call_character_status(CHARACTER_FLAG.poisoned)
end

--- Returns true if character is burning.
---@return boolean|nil
function Self.IsBurning()
    return call_character_status(CHARACTER_FLAG.burning)
end

--- Returns true if character is electrified.
---@return boolean|nil
function Self.IsElectrified()
    return call_character_status(CHARACTER_FLAG.electrified)
end

--- Returns true if character is drunk.
---@return boolean|nil
function Self.IsDrunk()
    return call_character_status(CHARACTER_FLAG.drunk)
end

--- Returns true if mana shield is active.
---@return boolean|nil
function Self.IsManaShielded()
    local oldShield = call_character_status(CHARACTER_FLAG.manaShielded)
    local newShield = call_character_status(CHARACTER_FLAG.newManaShield)
    if oldShield == nil or newShield == nil then
        return nil
    end

    return oldShield or newShield
end

--- Returns true if character is paralyzed.
---@return boolean|nil
function Self.IsParalyzed()
    return call_character_status(CHARACTER_FLAG.paralyzed)
end

--- Returns true if character is hasted.
---@return boolean|nil
function Self.IsHasted()
    return call_character_status(CHARACTER_FLAG.hasted)
end

--- Returns true if character is in combat.
---@return boolean|nil
function Self.IsInCombat()
    return call_character_status(CHARACTER_FLAG.inCombat)
end

--- Returns true if character is drowning.
---@return boolean|nil
function Self.IsDrowning()
    return call_character_status(CHARACTER_FLAG.drowning)
end

--- Returns true if character is freezing.
---@return boolean|nil
function Self.IsFreezing()
    return call_character_status(CHARACTER_FLAG.freezing)
end

--- Returns true if character is dazzled.
---@return boolean|nil
function Self.IsDazzled()
    return call_character_status(CHARACTER_FLAG.dazzled)
end

--- Returns true if character is cursed.
---@return boolean|nil
function Self.IsCursed()
    return call_character_status(CHARACTER_FLAG.cursed)
end

--- Returns true if character is strengthened.
---@return boolean|nil
function Self.IsStrengthened()
    return call_character_status(CHARACTER_FLAG.strengthened)
end

--- Returns true if character is in protection zone.
---@return boolean|nil
function Self.IsInProtectionZone()
    return call_character_status(CHARACTER_FLAG.inProtectionZone)
end

--- Returns true if character is bleeding.
---@return boolean|nil
function Self.IsBleeding()
    return call_character_status(CHARACTER_FLAG.bleeding)
end

--- Returns true if character is rooted.
---@return boolean|nil
function Self.IsRooted()
    return call_character_status(CHARACTER_FLAG.rooted)
end

--- Returns true if character is feared.
---@return boolean|nil
function Self.IsFeared()
    return call_character_status(CHARACTER_FLAG.feared)
end

--- Returns current mana shield capacity.
---@return integer|nil
function Self.GetManaShieldCapacity()
    if type(Game) ~= "table" or type(Game.GetManaShieldCapacity) ~= "function" then
        return nil
    end

    return Game.GetManaShieldCapacity()
end

--- Returns maximum mana shield capacity.
---@return integer|nil
function Self.GetMaxManaShieldCapacity()
    if type(Game) ~= "table" or type(Game.GetMaxManaShieldCapacity) ~= "function" then
        return nil
    end

    return Game.GetMaxManaShieldCapacity()
end

--- Returns attacked creature id.
---@return integer|nil
function Self.GetTargetId()
    if type(g_Creature) ~= "table" or type(g_Creature.GetTargetId) ~= "function" then
        return nil
    end

    return g_Creature.GetTargetId()
end

--- Returns followed creature id.
---@return integer|nil
function Self.GetFollowId()
    if type(g_Creature) ~= "table" or type(g_Creature.GetFollowId) ~= "function" then
        return nil
    end

    return g_Creature.GetFollowId()
end

--- Returns mouse world position.
---@return table|nil
function Self.GetMousePositionInWorld()
    if type(Game) ~= "table" or type(Game.GetMousePositionInWorld) ~= "function" then
        return nil
    end

    local pos = Game.GetMousePositionInWorld()
    if type(pos) ~= "table" then
        return nil
    end

    if type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number" then
        return nil
    end

    return {
        x = pos.x,
        y = pos.y,
        z = pos.z
    }
end

--- Returns mouse position text for logging.
---@return string
function Self.GetMousePositionText()
    local pos = Self.GetMousePositionInWorld()
    if type(pos) ~= "table" then
        return "nil"
    end

    return "{" .. tostring(pos.x) .. "," .. tostring(pos.y) .. "," .. tostring(pos.z) .. "}"
end

--- Returns mouse X world coordinate.
---@return number|nil
function Self.GetMouseWorldX()
    local pos = Self.GetMousePositionInWorld()
    if type(pos) ~= "table" then
        return nil
    end

    return pos.x
end

--- Returns mouse Y world coordinate.
---@return number|nil
function Self.GetMouseWorldY()
    local pos = Self.GetMousePositionInWorld()
    if type(pos) ~= "table" then
        return nil
    end

    return pos.y
end

--- Returns mouse Z world floor.
---@return number|nil
function Self.GetMouseWorldZ()
    local pos = Self.GetMousePositionInWorld()
    if type(pos) ~= "table" then
        return nil
    end

    return pos.z
end

--- Returns floor of capacity value.
---@return integer|nil
function Self.GetCapacityFloor()
    local capacity = Self.GetCapacity()
    if type(capacity) ~= "number" then
        return nil
    end

    return math.floor(capacity)
end

--- Returns current level.
---@return integer|nil
function Self.GetLevel()
    if type(Game) ~= "table" or type(Game.GetLevel) ~= "function" then
        return nil
    end

    return Game.GetLevel()
end

--- Returns current soul value.
---@return integer|nil
function Self.GetSoul()
    if type(Game) ~= "table" or type(Game.GetSoul) ~= "function" then
        return nil
    end

    return Game.GetSoul()
end

--- Returns level progression percent.
---@return number|nil
function Self.GetLevelPercentage()
    if type(Game) ~= "table" or type(Game.GetLevelPercentage) ~= "function" then
        return nil
    end

    return Game.GetLevelPercentage()
end

--- Returns stamina expressed in full hours.
---@return integer|nil
function Self.GetStaminaHours()
    local stamina = Self.GetStamina()
    if type(stamina) ~= "number" then
        return nil
    end

    return math.floor(stamina / 60)
end

--- Returns stamina expressed in full days.
---@return integer|nil
function Self.GetStaminaDays()
    local stamina = Self.GetStamina()
    if type(stamina) ~= "number" then
        return nil
    end

    return math.floor(stamina / (60 * 24))
end

--- Returns true when target id is valid (>0).
---@return boolean|nil
function Self.HasTarget()
    local targetId = Self.GetTargetId()
    if type(targetId) ~= "number" then
        return nil
    end

    return targetId > 0
end

--- Returns true when follow id is valid (>0).
---@return boolean|nil
function Self.HasFollow()
    local followId = Self.GetFollowId()
    if type(followId) ~= "number" then
        return nil
    end

    return followId > 0
end

--- Returns a snapshot of live character condition flags.
---@return table
function Self.GetStatusFlagsSnapshot()
    return {
        isHungry = Self.IsHungry(),
        isInRestingArea = Self.IsInRestingArea(),
        isPoisoned = Self.IsPoisoned(),
        isBurning = Self.IsBurning(),
        isElectrified = Self.IsElectrified(),
        isDrunk = Self.IsDrunk(),
        isManaShielded = Self.IsManaShielded(),
        isParalyzed = Self.IsParalyzed(),
        isHasted = Self.IsHasted(),
        isInCombat = Self.IsInCombat(),
        isDrowning = Self.IsDrowning(),
        isFreezing = Self.IsFreezing(),
        isDazzled = Self.IsDazzled(),
        isCursed = Self.IsCursed(),
        isStrengthened = Self.IsStrengthened(),
        isInProtectionZone = Self.IsInProtectionZone(),
        isBleeding = Self.IsBleeding(),
        isRooted = Self.IsRooted(),
        isFeared = Self.IsFeared()
    }
end

Self.isParalysed = Self.IsParalyzed

--- Formats a stats snapshot into one-line debug text.
---@param stats? table
---@param prefix? string
---@return string
function Self.FormatStatsSnapshot(stats, prefix)
    local snapshot = stats
    if snapshot == nil then
        snapshot = Self.GetStatsSnapshot()
    end

    local label = prefix or "self_stats"
    if snapshot == nil then
        return "[" .. tostring(label) .. "] snapshot=nil"
    end

    local mousePositionText = "nil"
    if type(snapshot.mousePosition) == "table" then
        mousePositionText = "{" .. tostring(snapshot.mousePosition.x)
            .. "," .. tostring(snapshot.mousePosition.y)
            .. "," .. tostring(snapshot.mousePosition.z) .. "}"
    end

    return "[" .. tostring(label) .. "]"
        .. " health=" .. tostring(snapshot.health)
        .. " maxHealth=" .. tostring(snapshot.maxHealth)
        .. " mana=" .. tostring(snapshot.mana)
        .. " maxMana=" .. tostring(snapshot.maxMana)
        .. " capacity=" .. tostring(snapshot.capacity)
        .. " stamina=" .. tostring(snapshot.stamina)
        .. " online=" .. tostring(snapshot.online)
        .. " isAlive=" .. tostring(snapshot.isAlive)
        .. " isAttacking=" .. tostring(snapshot.isAttacking)
        .. " isFollowing=" .. tostring(snapshot.isFollowing)
        .. " manaShieldCapacity=" .. tostring(snapshot.manaShieldCapacity)
        .. " maxManaShieldCapacity=" .. tostring(snapshot.maxManaShieldCapacity)
        .. " targetId=" .. tostring(snapshot.targetId)
        .. " followId=" .. tostring(snapshot.followId)
        .. " mousePosition=" .. mousePositionText
        .. " mouseWorldX=" .. tostring(snapshot.mouseWorldX)
        .. " mouseWorldY=" .. tostring(snapshot.mouseWorldY)
        .. " mouseWorldZ=" .. tostring(snapshot.mouseWorldZ)
        .. " capacityFloor=" .. tostring(snapshot.capacityFloor)
        .. " level=" .. tostring(snapshot.level)
        .. " soul=" .. tostring(snapshot.soul)
        .. " levelPercent=" .. tostring(snapshot.levelPercent)
        .. " staminaHours=" .. tostring(snapshot.staminaHours)
        .. " staminaDays=" .. tostring(snapshot.staminaDays)
        .. " hasTarget=" .. tostring(snapshot.hasTarget)
        .. " hasFollow=" .. tostring(snapshot.hasFollow)
        .. " healthPercent=" .. tostring(snapshot.healthPercent)
        .. " manaPercent=" .. tostring(snapshot.manaPercent)
end

--- Returns true when minimal local-player data can be queried.
---@return boolean
function Self.IsAvailable()
    return Self.GetHealth() ~= nil
end

--- Says text in whisper mode.
---@param message string
---@return boolean
function Self.Whisper(message)
    if type(message) ~= "string" or message == "" then
        error("Self.Whisper: argument 'message' must be a non-empty string")
    end

    return Game.Whisper(message)
end

--- Says text in yell mode.
---@param message string
---@return boolean
function Self.Yell(message)
    if type(message) ~= "string" or message == "" then
        error("Self.Yell: argument 'message' must be a non-empty string")
    end

    return Game.Yell(message)
end

--- Sends chat message to a specific channel.
---@param message string
---@param channelId integer
---@return boolean dispatched True when the action was submitted to the client
function Self.SayOnChannel(message, channelId)
    if type(message) ~= "string" or message == "" then
        error("Self.SayOnChannel: argument 'message' must be a non-empty string")
    end

    if type(channelId) ~= "number" or channelId % 1 ~= 0 or channelId < 0 then
        error("Self.SayOnChannel: argument 'channelId' must be an integer >= 0")
    end

    return Game.TalkOnChannel(message, channelId)
end

--- Sends message to NPC channel.
---@param message string
---@return boolean
function Self.SayToNpc(message)
    if type(message) ~= "string" or message == "" then
        error("Self.SayToNpc: argument 'message' must be a non-empty string")
    end

    return Game.TalkToNPC(message)
end

--- Sends private message to a player.
---@param playerName string
---@param message string
---@return boolean
function Self.PrivateMessage(playerName, message)
    if type(playerName) ~= "string" or playerName == "" then
        error("Self.PrivateMessage: argument 'playerName' must be a non-empty string")
    end

    if type(message) ~= "string" or message == "" then
        error("Self.PrivateMessage: argument 'message' must be a non-empty string")
    end

    return Game.TalkPrivate(message, playerName)
end

--- Equips an item with optional tier level.
---@param itemId integer
---@param tierLevel? integer
---@return boolean dispatched True when the action was submitted to the client
function Self.Equip(itemId, tierLevel)
    validate_positive_integer(itemId, "itemId", "Self.Equip")

    local tier = tierLevel
    if tier == nil then
        tier = 0
    end

    if type(tier) ~= "number" or tier % 1 ~= 0 or tier < 0 then
        error("Self.Equip: argument 'tierLevel' must be an integer >= 0")
    end

    return Game.EquipItem(itemId, tier)
end

--- Attacks a creature by id.
---@param creatureId integer
---@return boolean dispatched True when the action was submitted to the client
function Self.Attack(creatureId)
    validate_positive_integer(creatureId, "creatureId", "Self.Attack")
    return Game.AttackCreature(creatureId)
end

--- Follows a creature by id.
---@param creatureId integer
---@return boolean dispatched True when the action was submitted to the client
function Self.Follow(creatureId)
    validate_positive_integer(creatureId, "creatureId", "Self.Follow")
    return Game.FollowCreature(creatureId)
end

--- Stops both attack and follow actions.
---@return boolean dispatched True when the action was submitted to the client
function Self.StopAttackAndFollow()
    return Game.CancelAttackAndFollow()
end

--- Uses an item from a container slot.
---@param itemId integer
---@param containerIndex integer
---@param itemPos integer
---@param useItemWithHotkey? boolean
---@return boolean dispatched True when the action was submitted to the client
function Self.UseItemInContainer(itemId, containerIndex, itemPos, useItemWithHotkey)
    validate_positive_integer(itemId, "itemId", "Self.UseItemInContainer")

    if type(containerIndex) ~= "number" or containerIndex % 1 ~= 0 or containerIndex < 0 then
        error("Self.UseItemInContainer: argument 'containerIndex' must be an integer >= 0")
    end

    if type(itemPos) ~= "number" or itemPos % 1 ~= 0 or itemPos < 0 then
        error("Self.UseItemInContainer: argument 'itemPos' must be an integer >= 0")
    end

    local useWithHotkey = false
    if useItemWithHotkey ~= nil then
        useWithHotkey = useItemWithHotkey == true
    end

    return Game.UseItemInContainer(itemId, containerIndex, itemPos, useWithHotkey)
end

--- Uses an item on floor position and stack.
---@param position table position table {x,y,z}
---@param stackPosition integer
---@param itemId integer
---@return boolean dispatched True when the action was submitted to the client
function Self.UseItemOnFloor(position, stackPosition, itemId)
    validate_position_table(position, "Self.UseItemOnFloor")

    if type(stackPosition) ~= "number" or stackPosition % 1 ~= 0 or stackPosition < 0 then
        error("Self.UseItemOnFloor: argument 'stackPosition' must be an integer >= 0")
    end

    validate_positive_integer(itemId, "itemId", "Self.UseItemOnFloor")

    return Game.UseItemOnFloor(position.x, position.y, position.z, stackPosition, itemId)
end

--- Performs a movement step in given direction.
---@param direction integer
---@return boolean dispatched True when the action was submitted to the client
function Self.Step(direction)
    if type(direction) ~= "number" or direction % 1 ~= 0 then
        error("Self.Step: argument 'direction' must be an integer")
    end

    return Game.Step(direction)
end

--- Cancels current walk/autowalk.
---@return boolean dispatched True when the action was submitted to the client
function Self.CancelWalk()
    return Game.CancelWalk()
end

--- Mounts current mount.
---@return boolean dispatched True when the action was submitted to the client
function Self.Mount()
    return Game.Mount()
end

--- Dismounts current mount.
---@return boolean dispatched True when the action was submitted to the client
function Self.Dismount()
    return Game.Dismount()
end

--- Looks at a map position.
---@param position table position table {x,y,z}
---@return boolean dispatched True when the action was submitted to the client
function Self.LookAtPosition(position)
    validate_position_table(position, "Self.LookAtPosition")
    return Game.LookOnMap(position.x, position.y, position.z)
end

--- Looks at a creature by id.
---@param creatureId integer
---@return boolean dispatched True when the action was submitted to the client
function Self.LookAtCreature(creatureId)
    validate_positive_integer(creatureId, "creatureId", "Self.LookAtCreature")
    return Game.LookOnCreature(creatureId)
end

--- Buys item from NPC trade window.
---@param itemId integer
---@param itemCount integer
---@param ignoreCapacity? boolean
---@param buyInShoppingBags? boolean
---@return boolean dispatched True when the action was submitted to the client
function Self.BuyItem(itemId, itemCount, ignoreCapacity, buyInShoppingBags)
    validate_positive_integer(itemId, "itemId", "Self.BuyItem")
    validate_positive_integer(itemCount, "itemCount", "Self.BuyItem")

    local ignoreCap = ignoreCapacity == true
    local buyBags = buyInShoppingBags == true
    return Game.BuyItemFromNPC(itemId, itemCount, ignoreCap, buyBags)
end

--- Sells item through NPC trade window.
---@param itemId integer
---@param itemCount integer
---@param sellEquipped? boolean
---@return boolean dispatched True when the action was submitted to the client
function Self.SellItem(itemId, itemCount, sellEquipped)
    validate_positive_integer(itemId, "itemId", "Self.SellItem")
    validate_positive_integer(itemCount, "itemCount", "Self.SellItem")

    local sellEq = sellEquipped == true
    return Game.SellItemToNPC(itemId, itemCount, sellEq)
end




