-- scripts/core/Position.lua

---@class Position
local Position = {}
Position.__index = Position

--- Creates a Position object from numbers or a table.
---@param x number|table X coordinate or table {x,y,z}
---@param y? number Y coordinate
---@param z? number Z coordinate
---@return Position
function Position.New(x, y, z)
    local obj = {}
    if type(x) == "table" then
        obj.x = x.x
        obj.y = x.y
        obj.z = x.z
    else
        obj.x = x
        obj.y = y
        obj.z = z
    end
    setmetatable(obj, Position)
    return obj
end

--- Calculates Chebyshev distance between two positions.
--- Returns 9999 when z-level differs.
---@param otherPos table|Position
---@return integer
function Position:DistanceTo(otherPos)
    -- Handle mismatched floors
    if self.z ~= otherPos.z then
        return 9999 -- Standard "unreachable" huge distance
    end
    
    local dx = math.abs(self.x - otherPos.x)
    local dy = math.abs(self.y - otherPos.y)
    
    -- Chebyshev distance (max of dx, dy) is standard for grid games like Tibia
    return math.max(dx, dy)
end

local function normalize_position(pos)
    if type(pos) ~= "table" then
        return nil
    end

    local x = tonumber(pos.x)
    local y = tonumber(pos.y)
    local z = tonumber(pos.z)

    if not x or not y or not z then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function get_local_player_position()
    if type(g_Creature) ~= "table"
        or type(g_Creature.GetPosition) ~= "function"
        or (type(g_Creature.GetPlayerId) ~= "function" and type(g_Creature.GetLocalPlayerId) ~= "function") then
        return nil
    end

    local playerId = 0
    if type(g_Creature.GetPlayerId) == "function" then
        playerId = g_Creature.GetPlayerId()
    else
        playerId = g_Creature.GetLocalPlayerId()
    end

    if type(playerId) ~= "number" or playerId <= 0 then
        return nil
    end

    return normalize_position(g_Creature.GetPosition(playerId))
end

local function get_game_check_fn(name)
    if type(g_Game) == "table" and type(g_Game[name]) == "function" then
        return g_Game[name]
    end

    if type(Game) == "table" and type(Game[name]) == "function" then
        return Game[name]
    end

    return nil
end

--- Checks whether toPos is reachable from fromPos.
--- If fromPos is nil, local player Position is used.
---@param fromPos table|nil Source Position table {x,y,z}
---@param toPos table Destination Position table {x,y,z}
---@return boolean
function Position.IsReachable(fromPos, toPos)
    local sourcePos = normalize_position(fromPos) or get_local_player_position()
    local targetPos = normalize_position(toPos)
    if not sourcePos or not targetPos then
        return false
    end

    local fn = get_game_check_fn("IsReachable")
    if type(fn) ~= "function" then
        return false
    end

    local ok, result = pcall(fn,
        sourcePos.x, sourcePos.y, sourcePos.z,
        targetPos.x, targetPos.y, targetPos.z)

    return ok and result == true
end

--- Checks whether toPos is shootable from fromPos.
--- If fromPos is nil, local player Position is used.
---@param fromPos table|nil Source Position table {x,y,z}
---@param toPos table Destination Position table {x,y,z}
---@return boolean
function Position.IsShootable(fromPos, toPos)
    local sourcePos = normalize_position(fromPos) or get_local_player_position()
    local targetPos = normalize_position(toPos)
    if not sourcePos or not targetPos then
        return false
    end

    local fn = get_game_check_fn("IsShootable")
    if type(fn) ~= "function" then
        return false
    end

    local ok, result = pcall(fn,
        sourcePos.x, sourcePos.y, sourcePos.z,
        targetPos.x, targetPos.y, targetPos.z)

    return ok and result == true
end

--- Instance helper for reachability to this Position.
---@param fromPos table|nil Source Position, defaults to local player Position
---@return boolean
function Position:IsReachable(fromPos)
    return Position.IsReachable(fromPos, self)
end

--- Instance helper for shootability to this Position.
---@param fromPos table|nil Source Position, defaults to local player Position
---@return boolean
function Position:IsShootable(fromPos)
    return Position.IsShootable(fromPos, self)
end

-- Compatibility aliases for scripts preferring lower camel-case.
Position.IsReachable = Position.IsReachable
Position.IsShootable = Position.IsShootable

-- Publish globals for core libs that access Position directly.
_G.Position = Position

return Position





