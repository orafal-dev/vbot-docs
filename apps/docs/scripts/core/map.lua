Map = Map or {}

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

local function validate_non_negative_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value < 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer >= 0")
    end
end

local function validate_positive_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value <= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer > 0")
    end
end

--- Uses an item on a Map tile position.
---@param position table position table with integer x, y, z
---@param stackPosition integer Stack index on the tile
---@param itemId integer item id to use
---@return any result Underlying Game API return value
function Map.UseItemOnFloor(position, stackPosition, itemId)
    validate_position_table(position, "Map.UseItemOnFloor")
    validate_non_negative_integer(stackPosition, "stackPosition", "Map.UseItemOnFloor")
    validate_positive_integer(itemId, "itemId", "Map.UseItemOnFloor")

    return Game.UseItemOnFloor(position.x, position.y, position.z, stackPosition, itemId)
end

--- Performs a look action on a Map tile position.
---@param position table position table with integer x, y, z
---@return any result Underlying Game API return value
function Map.Look(position)
    validate_position_table(position, "Map.Look")
    return Game.LookOnMap(position.x, position.y, position.z)
end

--- Moves an item from floor tile into container slot.
---@param itemId integer item id on floor
---@param fromPosition table Source floor position {x,y,z}
---@param containerIndex integer Destination container index
---@param slotIndex integer Destination slot index
---@param itemCount integer Amount to move
---@return any result Underlying Game API return value
function Map.MoveItemFloorToContainer(itemId, fromPosition, containerIndex, slotIndex, itemCount)
    validate_positive_integer(itemId, "itemId", "Map.MoveItemFloorToContainer")
    validate_position_table(fromPosition, "Map.MoveItemFloorToContainer")
    validate_non_negative_integer(containerIndex, "containerIndex", "Map.MoveItemFloorToContainer")
    validate_non_negative_integer(slotIndex, "slotIndex", "Map.MoveItemFloorToContainer")
    validate_positive_integer(itemCount, "itemCount", "Map.MoveItemFloorToContainer")

    return Game.MoveItemFromFloorToContainer(itemId, fromPosition.x, fromPosition.y, fromPosition.z, containerIndex, slotIndex, itemCount)
end

--- Moves an item from one floor tile to another floor tile.
---@param fromPosition table Source floor position {x,y,z}
---@param itemId integer item id on source tile
---@param toPosition table Destination floor position {x,y,z}
---@param itemCount integer Amount to move
---@return any result Underlying Game API return value
function Map.MoveItemFloorToFloor(fromPosition, itemId, toPosition, itemCount)
    validate_position_table(fromPosition, "Map.MoveItemFloorToFloor")
    validate_positive_integer(itemId, "itemId", "Map.MoveItemFloorToFloor")
    validate_position_table(toPosition, "Map.MoveItemFloorToFloor")
    validate_positive_integer(itemCount, "itemCount", "Map.MoveItemFloorToFloor")

    return Game.MoveItemFromFloorToFloor(
        fromPosition.x,
        fromPosition.y,
        fromPosition.z,
        itemId,
        toPosition.x,
        toPosition.y,
        toPosition.z,
        itemCount
    )
end

--- Gets cached Map tile flags at a world position.
---@param position table position table with integer x, y, z
---@return table|nil flags Tile flags or nil when tile is unavailable
function Map.GetTileFlags(position)
    validate_position_table(position, "Map.GetTileFlags")
    return Game.GetMapTileFlags(position.x, position.y, position.z)
end

--- Gets objects currently present on a Map tile.
---@param position table position table with integer x, y, z
---@param includeCreatures? boolean Include creature appearances in the result
---@return table[] items
function Map.GetTileItems(position, includeCreatures)
    validate_position_table(position, "Map.GetTileItems")
    local includeCreatureItems = includeCreatures == true
    return Game.GetMapTileItems(position.x, position.y, position.z, includeCreatureItems)
end

--- Gets static object info/flags for an item id.
---@param itemId integer item id
---@return table|nil info
function Map.GetObjectInfo(itemId)
    validate_positive_integer(itemId, "itemId", "Map.GetObjectInfo")
    return Game.GetObjectInfo(itemId)
end

--- Computes a path between two world positions using game pathfinding.
---@param fromPosition table Source position {x,y,z}
---@param toPosition table Destination position {x,y,z}
---@param maxComplexity? integer Optional path complexity budget (default 300)
---@param flags? integer Optional PathFindFlags bitmask
---@return table result {Directions = integer[], pathFindResult = integer}
function Map.FindPath(fromPosition, toPosition, maxComplexity, flags)
    validate_position_table(fromPosition, "Map.FindPath")
    validate_position_table(toPosition, "Map.FindPath")

    local complexity = maxComplexity
    if complexity == nil then
        complexity = 300
    else
        validate_positive_integer(complexity, "maxComplexity", "Map.FindPath")
    end

    local pathFlags = flags
    if pathFlags == nil then
        pathFlags = PathFindFlags.CHECK_GOAL_POSITION
            + PathFindFlags.ALLOW_NON_PATHABLE
            + PathFindFlags.ALLOW_NOT_SEEN_TILES
            + PathFindFlags.IGNORE_CREATURES
    elseif type(pathFlags) ~= "number" or pathFlags % 1 ~= 0 or pathFlags < 0 then
        error("Map.FindPath: argument 'flags' must be an integer >= 0")
    end

    local Directions, pathFindResult = Game.FindPath(
        fromPosition.x, fromPosition.y, fromPosition.z,
        toPosition.x, toPosition.y, toPosition.z,
        complexity,
        pathFlags
    )

    return {
        Directions = Directions or {},
        pathFindResult = pathFindResult
    }
end




