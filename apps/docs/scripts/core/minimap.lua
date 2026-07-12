Minimap = Minimap or {}

local NON_WALKABLE_PIXEL_COLORS = {
    [0x00] = true,
    [0x0C] = true,
    [0x33] = true,
    [0x56] = true,
    [0x8C] = true,
    [0xBA] = true,
    [0xC0] = true,
    [0xD2] = true,
    [0xFE] = true
}

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

--- Returns map tile flags at a world position.
---@param position table
---@return table|nil
function Minimap.GetTileFlags(position)
    validate_position_table(position, "Minimap.GetTileFlags")

    if type(Map) == "table" and type(Map.GetTileFlags) == "function" then
        return Map.GetTileFlags(position)
    end

    if type(Game) == "table" and type(Game.GetMapTileFlags) == "function" then
        return Game.GetMapTileFlags(position.x, position.y, position.z)
    end

    return nil
end

--- Returns map tile objects at a world position.
---@param position table
---@param includeCreatures? boolean
---@return table[]
function Minimap.GetTileItems(position, includeCreatures)
    validate_position_table(position, "Minimap.GetTileItems")

    local include = includeCreatures == true

    if type(Map) == "table" and type(Map.GetTileItems) == "function" then
        local items = Map.GetTileItems(position, include)
        if type(items) == "table" then
            return items
        end
        return {}
    end

    if type(Game) == "table" and type(Game.GetMapTileItems) == "function" then
        local items = Game.GetMapTileItems(position.x, position.y, position.z, include)
        if type(items) == "table" then
            return items
        end
    end

    return {}
end

--- Returns true if tile is currently walkable according to map cache.
---@param position table
---@return boolean|nil
function Minimap.IsWalkable(position)
    local flags = Minimap.GetTileFlags(position)
    if type(flags) ~= "table" then
        return nil
    end

    return flags.isWalkable == true
end

--- Returns true if tile is currently pathable according to map cache.
---@param position table
---@return boolean|nil
function Minimap.IsPathable(position)
    local flags = Minimap.GetTileFlags(position)
    if type(flags) ~= "table" then
        return nil
    end

    return flags.isPathable == true
end

--- Returns Minimap pixel color index at a world position when binding exists.
---@param position table
---@return integer|nil
function Minimap.GetTilePixelColor(position)
    validate_position_table(position, "Minimap.GetTilePixelColor")

    if type(Game) ~= "table" or type(Game.GetMinimapTilePixelColor) ~= "function" then
        return nil
    end

    return Game.GetMinimapTilePixelColor(position.x, position.y, position.z)
end

--- Returns true when a Minimap pixel color index is walkable.
---@param pixelColorIndex integer
---@return boolean
function Minimap.IsPixelColorWalkable(pixelColorIndex)
    validate_non_negative_integer(pixelColorIndex, "pixelColorIndex", "Minimap.IsPixelColorWalkable")
    return NON_WALKABLE_PIXEL_COLORS[pixelColorIndex] ~= true
end

--- Returns true when tile is walkable by Minimap color (if color API exists).
---@param position table
---@return boolean|nil
function Minimap.IsWalkableByColor(position)
    local colorIndex = Minimap.GetTilePixelColor(position)
    if type(colorIndex) ~= "number" then
        return nil
    end

    return Minimap.IsPixelColorWalkable(colorIndex)
end

--- Finds path between two positions using game pathfinding.
---@param fromPosition table
---@param toPosition table
---@param maxComplexity? integer
---@param flags? integer
---@return table
function Minimap.FindPath(fromPosition, toPosition, maxComplexity, flags)
    validate_position_table(fromPosition, "Minimap.FindPath")
    validate_position_table(toPosition, "Minimap.FindPath")

    if type(Map) == "table" and type(Map.FindPath) == "function" then
        return Map.FindPath(fromPosition, toPosition, maxComplexity, flags)
    end

    if type(Game) == "table" and type(Game.FindPath) == "function" then
        local complexity = maxComplexity
        if complexity == nil then
            complexity = 300
        end

        local pathFlags = flags
        if pathFlags == nil then
            pathFlags = PathFindFlags.CHECK_GOAL_POSITION
                + PathFindFlags.ALLOW_NON_PATHABLE
                + PathFindFlags.ALLOW_NOT_SEEN_TILES
                + PathFindFlags.IGNORE_CREATURES
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

    return {
        Directions = {},
        pathFindResult = PathFindResult and PathFindResult.NO_WAY or 4
    }
end

--- Returns compact tile data (flags, objects, pixelColor).
---@param position table
---@param includeCreatures? boolean
---@return table
function Minimap.GetTileInfo(position, includeCreatures)
    validate_position_table(position, "Minimap.GetTileInfo")

    return {
        position = { x = position.x, y = position.y, z = position.z },
        flags = Minimap.GetTileFlags(position),
        items = Minimap.GetTileItems(position, includeCreatures),
        pixelColor = Minimap.GetTilePixelColor(position),
        walkableByColor = Minimap.IsWalkableByColor(position)
    }
end

Minimap.GetTileFlags = Minimap.GetTileFlags
Minimap.GetTileItems = Minimap.GetTileItems
Minimap.IsWalkable = Minimap.IsWalkable
Minimap.IsPathable = Minimap.IsPathable
Minimap.GetTilePixelColor = Minimap.GetTilePixelColor
Minimap.IsPixelColorWalkable = Minimap.IsPixelColorWalkable
Minimap.IsWalkableByColor = Minimap.IsWalkableByColor
Minimap.FindPath = Minimap.FindPath
Minimap.GetTileInfo = Minimap.GetTileInfo

return Minimap




