Inventory = Inventory or {}

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

local function get_equipment_slot_constants()
    if type(EquipmentSlot) == "table" then
        return EquipmentSlot
    end

    return {
        NONE = 0,
        HELMET = 1,
        AMULET = 2,
        BACKPACK = 3,
        ARMOR = 4,
        RIGHT_HAND = 5,
        LEFT_HAND = 6,
        LEGS = 7,
        BOOTS = 8,
        RING = 9,
        ARROW = 10
    }
end

local SLOT = get_equipment_slot_constants()

local function call_game_no_throw(methodName, ...)
    if type(Game) ~= "table" then
        return false, nil
    end

    local method = Game[methodName]
    if type(method) ~= "function" then
        return false, nil
    end

    local ok, result = pcall(method, ...)
    if not ok then
        return false, nil
    end

    return true, result
end

--- Returns equipment slot constants table.
---@return table
function Inventory.GetEquipmentSlotConstants()
    return SLOT
end

--- Returns true when direct equipment read APIs are available.
---@return boolean
function Inventory.CanReadEquipment()
    if type(Game) ~= "table" then
        return false
    end

    return type(Game.GetEquipmentItem) == "function"
        or type(Game.GetInventoryItem) == "function"
        or type(Game.GetEquipmentSlot) == "function"
end

--- Returns true when equipment movement APIs are available.
---@return boolean
function Inventory.CanMoveEquipment()
    if type(Game) ~= "table" then
        return false
    end

    return type(Game.MoveItemFromContainerToInventorySlot) == "function"
        and type(Game.MoveItemFromInventorySlotToContainer) == "function"
end

--- Returns equipped item data for one slot when runtime exposes it.
---@param equipmentSlot integer
---@return table|nil
function Inventory.GetSlotItem(equipmentSlot)
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Inventory.GetSlotItem")

    local ok, result = call_game_no_throw("GetEquipmentItem", equipmentSlot)
    if ok then
        return result
    end

    ok, result = call_game_no_throw("GetInventoryItem", equipmentSlot)
    if ok then
        return result
    end

    ok, result = call_game_no_throw("GetEquipmentSlot", equipmentSlot)
    if ok then
        return result
    end

    return nil
end

--- Returns equipped item map indexed by slot id.
---@return table
function Inventory.GetAllSlotItems()
    local out = {}
    for _, slotId in pairs(SLOT) do
        if type(slotId) == "number" and slotId > 0 then
            out[slotId] = Inventory.GetSlotItem(slotId)
        end
    end

    return out
end

--- Equips item by item id and optional tier.
---@param itemId integer
---@param tierLevel? integer
---@return any
function Inventory.Equip(itemId, tierLevel)
    validate_positive_integer(itemId, "itemId", "Inventory.Equip")

    local tier = tierLevel
    if tier == nil then
        tier = 0
    end

    validate_non_negative_integer(tier, "tierLevel", "Inventory.Equip")

    return Game.EquipItem(itemId, tier)
end

--- Looks at an equipped item in a specific slot.
---@param itemId integer
---@param equipmentSlot integer
---@return any
function Inventory.LookSlotItem(itemId, equipmentSlot)
    validate_positive_integer(itemId, "itemId", "Inventory.LookSlotItem")
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Inventory.LookSlotItem")
    return Game.LookOnItemInEquipment(itemId, equipmentSlot)
end

--- Moves item from container slot to equipment slot.
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param equipmentSlot integer
---@param itemCount integer
---@return any
function Inventory.MoveFromContainerToSlot(containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
    validate_non_negative_integer(containerIndex, "containerIndex", "Inventory.MoveFromContainerToSlot")
    validate_non_negative_integer(slotIndex, "slotIndex", "Inventory.MoveFromContainerToSlot")
    validate_positive_integer(itemId, "itemId", "Inventory.MoveFromContainerToSlot")
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Inventory.MoveFromContainerToSlot")
    validate_positive_integer(itemCount, "itemCount", "Inventory.MoveFromContainerToSlot")

    return Game.MoveItemFromContainerToInventorySlot(containerIndex, slotIndex, itemId, equipmentSlot, itemCount)
end

--- Moves item from equipment slot to container slot.
---@param equipmentSlot integer
---@param containerIndex integer
---@param slotIndex integer
---@param itemId integer
---@param itemCount integer
---@return any
function Inventory.MoveFromSlotToContainer(equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
    validate_positive_integer(equipmentSlot, "equipmentSlot", "Inventory.MoveFromSlotToContainer")
    validate_non_negative_integer(containerIndex, "containerIndex", "Inventory.MoveFromSlotToContainer")
    validate_non_negative_integer(slotIndex, "slotIndex", "Inventory.MoveFromSlotToContainer")
    validate_positive_integer(itemId, "itemId", "Inventory.MoveFromSlotToContainer")
    validate_positive_integer(itemCount, "itemCount", "Inventory.MoveFromSlotToContainer")

    return Game.MoveItemFromInventorySlotToContainer(equipmentSlot, containerIndex, slotIndex, itemId, itemCount)
end

--- Returns item id in a slot when supported by runtime.
---@param equipmentSlot integer
---@return integer|nil
function Inventory.GetSlotItemId(equipmentSlot)
    local item = Inventory.GetSlotItem(equipmentSlot)
    if type(item) ~= "table" then
        return nil
    end

    local itemId = item.itemId
    if type(itemId) ~= "number" then
        itemId = item.item_id
    end

    if type(itemId) ~= "number" then
        return nil
    end

    return itemId
end

--- Returns true if a slot has an equipped item (when readable).
---@param equipmentSlot integer
---@return boolean|nil
function Inventory.HasItemInSlot(equipmentSlot)
    local itemId = Inventory.GetSlotItemId(equipmentSlot)
    if itemId == nil then
        return nil
    end

    return itemId > 0
end

--- Returns slot ids from readable constants.
---@return integer[]
function Inventory.GetSlotIds()
    local ids = {}
    for _, value in pairs(SLOT) do
        if type(value) == "number" and value > 0 then
            ids[#ids + 1] = value
        end
    end

    table.sort(ids)
    return ids
end

--- Returns Inventory capabilities snapshot.
---@return table
function Inventory.GetSnapshot()
    return {
        canReadEquipment = Inventory.CanReadEquipment(),
        canMoveEquipment = Inventory.CanMoveEquipment(),
        slotIds = Inventory.GetSlotIds(),
        slots = Inventory.GetAllSlotItems()
    }
end

Inventory.getSlots = Inventory.GetAllSlotItems

Inventory.GetEquipmentSlotConstants = Inventory.GetEquipmentSlotConstants
Inventory.CanReadEquipment = Inventory.CanReadEquipment
Inventory.CanMoveEquipment = Inventory.CanMoveEquipment
Inventory.GetSlotItem = Inventory.GetSlotItem
Inventory.GetAllSlotItems = Inventory.GetAllSlotItems
Inventory.Equip = Inventory.Equip
Inventory.LookSlotItem = Inventory.LookSlotItem
Inventory.MoveFromContainerToSlot = Inventory.MoveFromContainerToSlot
Inventory.MoveFromSlotToContainer = Inventory.MoveFromSlotToContainer
Inventory.GetSlotItemId = Inventory.GetSlotItemId
Inventory.HasItemInSlot = Inventory.HasItemInSlot
Inventory.GetSlotIds = Inventory.GetSlotIds
Inventory.GetSnapshot = Inventory.GetSnapshot

return Inventory




