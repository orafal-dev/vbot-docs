Container = Container or {}

local function validate_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer")
    end
end

local function validate_non_negative_integer(value, argName, functionName)
    validate_integer(value, argName, functionName)
    if value < 0 then
        error(functionName .. ": argument '" .. argName .. "' must be >= 0")
    end
end

local function validate_positive_integer(value, argName, functionName)
    validate_integer(value, argName, functionName)
    if value <= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be > 0")
    end
end

local function validate_position_table(pos, argName, functionName)
    if type(pos) ~= "table" then
        error(functionName .. ": argument '" .. argName .. "' must be a table {x, y, z}")
    end

    if type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number" then
        error(functionName .. ": argument '" .. argName .. "' must contain numeric x, y, z")
    end

    if pos.x % 1 ~= 0 or pos.y % 1 ~= 0 or pos.z % 1 ~= 0 then
        error(functionName .. ": argument '" .. argName .. "' x, y, z must be integers")
    end
end

--- Moves an item from one Container slot to another Container slot.
---@param fromContainerIndex integer
---@param fromSlotIndex integer
---@param itemId integer
---@param toContainerIndex integer
---@param toSlotIndex integer
---@param itemCount integer
---@return any result Underlying Game API return value
function Container.MoveItemToContainer(fromContainerIndex, fromSlotIndex, itemId, toContainerIndex, toSlotIndex, itemCount)
    validate_non_negative_integer(fromContainerIndex, "fromContainerIndex", "Container.MoveItemToContainer")
    validate_non_negative_integer(fromSlotIndex, "fromSlotIndex", "Container.MoveItemToContainer")
    validate_positive_integer(itemId, "itemId", "Container.MoveItemToContainer")
    validate_non_negative_integer(toContainerIndex, "toContainerIndex", "Container.MoveItemToContainer")
    validate_non_negative_integer(toSlotIndex, "toSlotIndex", "Container.MoveItemToContainer")
    validate_positive_integer(itemCount, "itemCount", "Container.MoveItemToContainer")

    return Game.MoveItemFromContainerToContainer(
        fromContainerIndex,
        fromSlotIndex,
        itemId,
        toContainerIndex,
        toSlotIndex,
        itemCount
    )
end

--- Uses an item that is inside a Container.
---@param itemId integer
---@param containerIndex integer
---@param itemPos integer
---@param useItemWithHotkey? boolean
---@return any result Underlying Game API return value
function Container.UseItem(itemId, containerIndex, itemPos, useItemWithHotkey)
    validate_positive_integer(itemId, "itemId", "Container.UseItem")
    validate_non_negative_integer(containerIndex, "containerIndex", "Container.UseItem")
    validate_non_negative_integer(itemPos, "itemPos", "Container.UseItem")

    local useWithHotkey = false
    if useItemWithHotkey ~= nil then
        useWithHotkey = useItemWithHotkey == true
    end

    return Game.UseItemInContainer(itemId, containerIndex, itemPos, useWithHotkey)
end

--- Moves an item from a Container slot to floor position.
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param toPosition table position table {x,y,z}
---@param itemCount integer
---@return any result Underlying Game API return value
function Container.MoveItemToFloor(containerIndex, slotIndex, itemId, toPosition, itemCount)
    validate_non_negative_integer(containerIndex, "containerIndex", "Container.MoveItemToFloor")
    validate_non_negative_integer(slotIndex, "slotIndex", "Container.MoveItemToFloor")
    validate_positive_integer(itemId, "itemId", "Container.MoveItemToFloor")
    validate_positive_integer(itemCount, "itemCount", "Container.MoveItemToFloor")

    validate_position_table(toPosition, "toPosition", "Container.MoveItemToFloor")

    return Game.MoveItemFromContainerToFloor(containerIndex, slotIndex, itemId, toPosition.x, toPosition.y, toPosition.z, itemCount)
end

--- Moves an equipped item to a Container slot.
---@param equipmentSlot integer
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param itemCount integer
---@return any result Underlying Game API return value
function Container.MoveItemFromEquipmentToContainer(equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Container.MoveItemFromEquipmentToContainer")
    validate_non_negative_integer(containerIndex, "containerIndex", "Container.MoveItemFromEquipmentToContainer")
    validate_non_negative_integer(slotIndex, "slotIndex", "Container.MoveItemFromEquipmentToContainer")
    validate_positive_integer(itemId, "itemId", "Container.MoveItemFromEquipmentToContainer")
    validate_positive_integer(itemCount, "itemCount", "Container.MoveItemFromEquipmentToContainer")

    return Game.MoveItemFromInventorySlotToContainer(equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
end

--- Moves an item from Container slot to equipment slot.
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param equipmentSlot integer
---@param itemCount integer
---@return any result Underlying Game API return value
function Container.MoveItemToEquipment(containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
    validate_non_negative_integer(containerIndex, "containerIndex", "Container.MoveItemToEquipment")
    validate_non_negative_integer(slotIndex, "slotIndex", "Container.MoveItemToEquipment")
    validate_positive_integer(itemId, "itemId", "Container.MoveItemToEquipment")
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Container.MoveItemToEquipment")
    validate_positive_integer(itemCount, "itemCount", "Container.MoveItemToEquipment")

    return Game.MoveItemFromContainerToInventorySlot(containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
end

--- Performs look action on an item inside a Container.
---@param itemId integer
---@param itemPos integer
---@param containerIndex integer
---@return any result Underlying Game API return value
function Container.LookItem(itemId, itemPos, containerIndex)
    validate_positive_integer(itemId, "itemId", "Container.LookItem")
    validate_non_negative_integer(itemPos, "itemPos", "Container.LookItem")
    validate_non_negative_integer(containerIndex, "containerIndex", "Container.LookItem")

    return Game.LookOnItemInContainer(itemId, itemPos, containerIndex)
end

--- Returns metadata for all currently opened containers.
---@return table[] containers
function Container.GetOpenContainers()
    local containers = Game.GetOpenContainers()
    if type(containers) ~= "table" then
        return {}
    end

    return containers
end

--- Returns Container metadata by opened Container number.
---@param containerNumber integer
---@return table|nil Container
function Container.GetByNumber(containerNumber)
    validate_non_negative_integer(containerNumber, "containerNumber", "Container.GetByNumber")
    return Game.GetContainerByNumber(containerNumber)
end

--- Returns Container metadata by Container name.
---@param containerName string
---@return table|nil Container
function Container.GetByName(containerName)
    if type(containerName) ~= "string" or containerName == "" then
        error("Container.GetByName: argument 'containerName' must be a non-empty string")
    end

    return Game.GetContainerByName(containerName)
end

--- Returns Container metadata by Container item id.
---@param containerId integer
---@return table|nil Container
function Container.GetById(containerId)
    validate_positive_integer(containerId, "containerId", "Container.GetById")
    return Game.GetContainerById(containerId)
end

--- Returns all items from a Container slot list.
---@param containerNumber integer
---@return table[] items
function Container.GetItems(containerNumber)
    validate_non_negative_integer(containerNumber, "containerNumber", "Container.GetItems")

    local items = Game.GetContainerItems(containerNumber)
    if type(items) ~= "table" then
        return {}
    end

    return items
end

--- Returns one item from a Container slot.
---@param containerNumber integer
---@param slotIndex integer
---@return table|nil item
function Container.GetItem(containerNumber, slotIndex)
    validate_non_negative_integer(containerNumber, "containerNumber", "Container.GetItem")
    validate_non_negative_integer(slotIndex, "slotIndex", "Container.GetItem")
    return Game.GetContainerItem(containerNumber, slotIndex)
end

--- Finds an item in one opened Container by item id and optional tier.
---@param containerNumber integer
---@param itemId integer
---@param tierLevel? integer
---@return table|nil result
function Container.FindItem(containerNumber, itemId, tierLevel)
    validate_non_negative_integer(containerNumber, "containerNumber", "Container.FindItem")
    validate_positive_integer(itemId, "itemId", "Container.FindItem")

    if tierLevel == nil then
        return Game.FindItemInContainer(containerNumber, itemId)
    end

    validate_non_negative_integer(tierLevel, "tierLevel", "Container.FindItem")
    return Game.FindItemInContainer(containerNumber, itemId, tierLevel)
end

--- Finds an item across all opened containers.
---@param itemId integer
---@param tierLevel? integer
---@return table|nil result
function Container.FindItemInOpenContainers(itemId, tierLevel)
    validate_positive_integer(itemId, "itemId", "Container.FindItemInOpenContainers")

    local containers = Container.GetOpenContainers()
    for i = 1, #containers do
        local containerNumber = containers[i].containerNumber
        if type(containerNumber) == "number" then
            local found
            if tierLevel == nil then
                found = Container.FindItem(containerNumber, itemId)
            else
                validate_non_negative_integer(tierLevel, "tierLevel", "Container.FindItemInOpenContainers")
                found = Container.FindItem(containerNumber, itemId, tierLevel)
            end

            if found then
                return found
            end
        end
    end

    return nil
end

--- Convenience metadata getters.
---@param containerNumber integer
---@return integer|nil value
function Container.GetSize(containerNumber)
    local Container = Container.GetByNumber(containerNumber)
    return Container and Container.size or nil
end

---@param containerNumber integer
---@return integer|nil value
function Container.GetItemsCount(containerNumber)
    local Container = Container.GetByNumber(containerNumber)
    return Container and Container.itemsCount or nil
end

---@param containerNumber integer
---@return integer|nil value
function Container.GetFreeSlots(containerNumber)
    local Container = Container.GetByNumber(containerNumber)
    return Container and Container.freeSlots or nil
end

---@param containerNumber integer
---@return integer|nil value
function Container.GetId(containerNumber)
    local Container = Container.GetByNumber(containerNumber)
    return Container and Container.containerId or nil
end

---@param containerNumber integer
---@return string|nil value
function Container.GetName(containerNumber)
    local Container = Container.GetByNumber(containerNumber)
    return Container and Container.name or nil
end




