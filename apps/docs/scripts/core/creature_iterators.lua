Creature = Creature or {}
Creatures = Creatures or {}

local SCAN_NONE = 0
local SCAN_PLAYERS = 1
local SCAN_MONSTERS = 2
local SCAN_NPCS = 4
local SCAN_ALL = 7

--- Builds a coroutine-like iterator over Creatures filtered by predicate.
---@param filterFn function|nil Predicate receiving creatureId
---@return function iterator Returns (creatureId, Creature)
local function make_iterator(filterFn)
    local ids = g_Creature.GetIds()
    local index = 0

    return function()
        while true do
            index = index + 1
            local creatureId = ids[index]

            if creatureId == nil then
                return nil
            end

            if g_Creature.IsValid(creatureId) and (filterFn == nil or filterFn(creatureId)) then
                return creatureId, Creature:New(creatureId)
            end
        end
    end
end

--- Iterates all valid Creatures currently returned by g_Creature.GetIds().
---@return function iterator Returns (creatureId, Creature)
function Creature.ICreatures()
    return make_iterator(nil)
end

--- Iterates only player Creatures.
---@return function iterator Returns (creatureId, Creature)
function Creature.IPlayers()
    return make_iterator(function(creatureId)
        return g_Creature.IsPlayer(creatureId)
    end)
end

--- Iterates only monster Creatures.
---@return function iterator Returns (creatureId, Creature)
function Creature.IMonsters()
    return make_iterator(function(creatureId)
        return g_Creature.IsMonster(creatureId)
    end)
end

--- Iterates only NPC Creatures.
---@return function iterator Returns (creatureId, Creature)
function Creature.INpcs()
    return make_iterator(function(creatureId)
        return g_Creature.IsNPC(creatureId)
    end)
end

--- Returns visible Creature ids in default scan range.
---@return integer[]
function Creatures.GetVisibleCreatureIds()
    local result = {}
    local ids = g_Creature.GetIdsByScan(SCAN_ALL, 7, 5, false, false)

    for i = 1, #ids do
        local creatureId = ids[i]
        if creatureId ~= nil and g_Creature.IsValid(creatureId) then
            result[#result + 1] = creatureId
        end
    end

    return result
end

--- Returns visible Creatures wrapped in Creature objects.
---@return table[]
function Creatures.GetVisibleCreatures()
    local ids = Creatures.GetVisibleCreatureIds()
    local result = {}

    for i = 1, #ids do
        result[#result + 1] = Creature:New(ids[i])
    end

    return result
end

--- Gets first Creature by exact name.
---@param creatureName string
---@return table|nil
function Creatures.GetCreatureByName(creatureName)
    if type(creatureName) ~= "string" or creatureName == "" then
        return nil
    end

    local creatureId = g_Creature.GetIdByName(creatureName)
    if type(creatureId) ~= "number" or creatureId <= 0 then
        return nil
    end

    return Creature:New(creatureId)
end

--- Returns local player Creature id.
---@return integer|nil
function Creatures.GetLocalPlayerId()
    return g_Creature.GetLocalPlayerId()
end

--- Returns player Creature id currently under mouse.
---@return integer|nil
function Creatures.GetPlayerIdUnderMouse()
    return g_Creature.GetPlayerIdUnderMouse()
end

--- Returns currently followed Creature id.
---@return integer|nil
function Creatures.GetFollowingCreatureId()
    return g_Creature.GetFollowingCreatureId()
end

--- Returns currently attacked Creature id.
---@return integer|nil
function Creatures.GetAttackingCreatureId()
    return g_Creature.GetAttackingCreatureId()
end

--- Checks whether a Creature id is on screen within optional relative bounds.
---@param creatureId integer
---@param xRelativeDistance? integer
---@param yRelativeDistance? integer
---@param multifloor? boolean
---@return boolean
function Creatures.IsCreatureOnScreen(creatureId, xRelativeDistance, yRelativeDistance, multifloor)
    local xRel = xRelativeDistance or 7
    local yRel = yRelativeDistance or 5
    local multi = multifloor == true
    return g_Creature.IsOnScreen(creatureId, xRel, yRel, multi)
end

--- Returns Creature ids from scanner API with optional filters.
---@param typeFlags? integer Bit mask of SCAN_* constants
---@param xRelativeDistance? integer
---@param yRelativeDistance? integer
---@param multifloor? boolean
---@param ignoreSummons? boolean
---@return integer[]
function Creatures.GetCreatureIdsByScan(typeFlags, xRelativeDistance, yRelativeDistance, multifloor, ignoreSummons)
    local flags = typeFlags or SCAN_ALL
    local xRel = xRelativeDistance or 7
    local yRel = yRelativeDistance or 5
    local multi = multifloor == true
    local ignore = ignoreSummons == true
    return g_Creature.GetIdsByScan(flags, xRel, yRel, multi, ignore)
end

--- Returns Creature objects from scanner API with optional filters.
---@param typeFlags? integer Bit mask of SCAN_* constants
---@param xRelativeDistance? integer
---@param yRelativeDistance? integer
---@param multifloor? boolean
---@param ignoreSummons? boolean
---@return table[]
function Creatures.GetCreaturesByScan(typeFlags, xRelativeDistance, yRelativeDistance, multifloor, ignoreSummons)
    local ids = Creatures.GetCreatureIdsByScan(typeFlags, xRelativeDistance, yRelativeDistance, multifloor, ignoreSummons)
    local result = {}

    for i = 1, #ids do
        local creatureId = ids[i]
        if creatureId ~= nil and g_Creature.IsValid(creatureId) then
            result[#result + 1] = Creature:New(creatureId)
        end
    end

    return result
end

--- Returns visible players using default scan window.
---@return table[]
function Creatures.GetVisiblePlayers()
    return Creatures.GetCreaturesByScan(SCAN_PLAYERS, 7, 5, false, false)
end

--- Returns visible monsters using default scan window.
---@param ignoreSummons? boolean
---@return table[]
function Creatures.GetVisibleMonsters(ignoreSummons)
    return Creatures.GetCreaturesByScan(SCAN_MONSTERS, 7, 5, false, ignoreSummons == true)
end

--- Returns visible NPCs using default scan window.
---@return table[]
function Creatures.GetVisibleNpcs()
    return Creatures.GetCreaturesByScan(SCAN_NPCS, 7, 5, false, false)
end




