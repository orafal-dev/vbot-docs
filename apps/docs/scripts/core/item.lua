Item = Item or {}

local function validate_positive_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value <= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be a positive integer")
    end
end

local function validate_non_negative_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value < 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer >= 0")
    end
end

--- Uses an Item on a creature target.
---@param itemId integer Item id to use
---@param creatureId integer creature id target
---@return boolean dispatched False when the creature is unavailable
function Item.UseOnCreature(itemId, creatureId)
    validate_positive_integer(itemId, "itemId", "Item.UseOnCreature")
    validate_positive_integer(creatureId, "creatureId", "Item.UseOnCreature")
    return Game.UseWithItemOnCreature(itemId, creatureId)
end

--- Uses an Item directly by id, like pressing an in-game item hotkey.
--- No backpack needs to be open and no container index or slot is required.
--- Use this for direct-use items such as Magic Shield Potions.
---@param itemId integer Item id to use
---@return boolean dispatched Whether the action was accepted for dispatch
function Item.Use(itemId)
    validate_positive_integer(itemId, "itemId", "Item.Use")
    return Game.UseItem(itemId)
end

--- Uses a use-with Item on the local player.
--- This is for Items that require a creature target. Direct-use Items should
--- use Item.Use(itemId) instead.
---@param itemId integer Item id to use on the local player
---@return boolean dispatched False when the local player is unavailable
function Item.UseOnSelf(itemId)
    validate_positive_integer(itemId, "itemId", "Item.UseOnSelf")
    return Game.UseWithItemOnSelf(itemId)
end

--- Buys an Item from NPC trade.
---@param itemId integer Item id to buy
---@param itemCount integer Quantity to buy
---@param ignoreCapacity? boolean Ignore capacity check
---@param buyInShoppingBags? boolean Buy in shopping bags when available
---@return any result Underlying Game API return value
function Item.Buy(itemId, itemCount, ignoreCapacity, buyInShoppingBags)
    validate_positive_integer(itemId, "itemId", "Item.Buy")
    validate_positive_integer(itemCount, "itemCount", "Item.Buy")

    local ignoreCap = ignoreCapacity == true
    local buyBags = buyInShoppingBags == true
    return Game.BuyItemFromNPC(itemId, itemCount, ignoreCap, buyBags)
end

--- Sells an Item to NPC trade.
---@param itemId integer Item id to sell
---@param itemCount integer Quantity to sell
---@param sellEquipped? boolean Include equipped items
---@return any result Underlying Game API return value
function Item.Sell(itemId, itemCount, sellEquipped)
    validate_positive_integer(itemId, "itemId", "Item.Sell")
    validate_positive_integer(itemCount, "itemCount", "Item.Sell")

    local sellEq = sellEquipped == true
    return Game.SellItemToNPC(itemId, itemCount, sellEq)
end

--- Uses a container Item with an Item on the floor.
---@param floorPosition table position table {x,y,z}
---@param fromItemId integer Source Item id (from container)
---@param toItemId integer Target floor Item id
---@param toStackPosition integer Target stack index
---@return any result Underlying Game API return value
function Item.UseFromContainerOnFloor(floorPosition, fromItemId, toItemId, toStackPosition)
    if type(floorPosition) ~= "table" then
        error("Item.UseFromContainerOnFloor: argument 'floorPosition' must be a table {x, y, z}")
    end

    validate_positive_integer(fromItemId, "fromItemId", "Item.UseFromContainerOnFloor")
    validate_positive_integer(toItemId, "toItemId", "Item.UseFromContainerOnFloor")
    validate_non_negative_integer(toStackPosition, "toStackPosition", "Item.UseFromContainerOnFloor")

    return Game.UseItemWithFromContainerOnFloor(
        floorPosition.x,
        floorPosition.y,
        floorPosition.z,
        fromItemId,
        toItemId,
        toStackPosition
    )
end

--- Uses a floor Item with an Item in container.
---@param floorPosition table position table {x,y,z}
---@param fromItemId integer Source floor Item id
---@param fromStackPosition integer Source floor stack index
---@param toItemId integer Target container Item id
---@return any result Underlying Game API return value
function Item.UseFromFloorToContainer(floorPosition, fromItemId, fromStackPosition, toItemId)
    if type(floorPosition) ~= "table" then
        error("Item.UseFromFloorToContainer: argument 'floorPosition' must be a table {x, y, z}")
    end

    validate_positive_integer(fromItemId, "fromItemId", "Item.UseFromFloorToContainer")
    validate_non_negative_integer(fromStackPosition, "fromStackPosition", "Item.UseFromFloorToContainer")
    validate_positive_integer(toItemId, "toItemId", "Item.UseFromFloorToContainer")

    return Game.UseItemWithFromFloorToContainer(
        floorPosition.x,
        floorPosition.y,
        floorPosition.z,
        fromItemId,
        fromStackPosition,
        toItemId
    )
end

--- Uses an Item from one container slot on an Item in another container slot.
---@param fromContainer integer Source container index
---@param fromSlot integer Source slot index
---@param fromItemId integer Source Item id
---@param toContainer integer Destination container index
---@param toSlot integer Destination slot index
---@param toItemId integer Destination Item id
---@return any result Underlying Game API return value
function Item.UseFromContainerToContainer(fromContainer, fromSlot, fromItemId, toContainer, toSlot, toItemId)
    validate_non_negative_integer(fromContainer, "fromContainer", "Item.UseFromContainerToContainer")
    validate_non_negative_integer(fromSlot, "fromSlot", "Item.UseFromContainerToContainer")
    validate_positive_integer(fromItemId, "fromItemId", "Item.UseFromContainerToContainer")
    validate_non_negative_integer(toContainer, "toContainer", "Item.UseFromContainerToContainer")
    validate_non_negative_integer(toSlot, "toSlot", "Item.UseFromContainerToContainer")
    validate_positive_integer(toItemId, "toItemId", "Item.UseFromContainerToContainer")

    return Game.UseWithItemFromContainerToContainer(fromContainer, fromSlot, fromItemId, toContainer, toSlot, toItemId)
end

--- Returns static object info for an Item id.
---@param itemId integer
---@return table|nil info
function Item.GetInfo(itemId)
    validate_positive_integer(itemId, "itemId", "Item.GetInfo")
    return Game.GetObjectInfo(itemId)
end

--- Returns Item name by id.
---@param itemId integer
---@return string|nil name
function Item.GetName(itemId)
    local info = Item.GetInfo(itemId)
    return info and info.name or nil
end

--- Returns Item description by id.
---@param itemId integer
---@return string|nil description
function Item.GetDescription(itemId)
    local info = Item.GetInfo(itemId)
    return info and info.description or nil
end

--- Returns whether Item id has a given boolean info field.
---@param itemId integer
---@param fieldName string
---@return boolean
function Item.HasFlag(itemId, fieldName)
    if type(fieldName) ~= "string" or fieldName == "" then
        error("Item.HasFlag: argument 'fieldName' must be a non-empty string")
    end

    local info = Item.GetInfo(itemId)
    if not info then
        return false
    end

    return info[fieldName] == true
end

--- Convenience flag wrappers mapped from Game.GetObjectInfo fields.
function Item.IsContainer(itemId) return Item.HasFlag(itemId, "isContainer") end
function Item.IsCumulative(itemId) return Item.HasFlag(itemId, "isCumulative") end
function Item.IsUsable(itemId) return Item.HasFlag(itemId, "isUsable") end
function Item.IsMultiUsable(itemId) return Item.HasFlag(itemId, "isMultiUsable") end
function Item.IsMovable(itemId) return Item.HasFlag(itemId, "isMovable") end
function Item.IsTakable(itemId) return Item.HasFlag(itemId, "isTakable") end
function Item.IsGround(itemId) return Item.HasFlag(itemId, "isGround") end
function Item.IsLiquidContainer(itemId) return Item.HasFlag(itemId, "isLiquidContainer") end
function Item.IsCreature(itemId) return Item.HasFlag(itemId, "isCreature") end

--- Returns one Item entry from container slot.
---@param containerNumber integer
---@param slotIndex integer
---@return table|nil Item
function Item.GetFromContainer(containerNumber, slotIndex)
    validate_non_negative_integer(containerNumber, "containerNumber", "Item.GetFromContainer")
    validate_non_negative_integer(slotIndex, "slotIndex", "Item.GetFromContainer")
    return Game.GetContainerItem(containerNumber, slotIndex)
end

--- Finds Item in a specific container by id and optional tier.
---@param containerNumber integer
---@param itemId integer
---@param tierLevel? integer
---@return table|nil result
function Item.FindInContainer(containerNumber, itemId, tierLevel)
    validate_non_negative_integer(containerNumber, "containerNumber", "Item.FindInContainer")
    validate_positive_integer(itemId, "itemId", "Item.FindInContainer")

    if tierLevel == nil then
        return Game.FindItemInContainer(containerNumber, itemId)
    end

    validate_non_negative_integer(tierLevel, "tierLevel", "Item.FindInContainer")
    return Game.FindItemInContainer(containerNumber, itemId, tierLevel)
end




