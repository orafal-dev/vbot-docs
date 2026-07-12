-- ============================================================================
-- File: scripts/core/Creature.lua
-- Creature Object Wrapper for ValidusBot Lua Scripting engine
-- ============================================================================

---@class Creature
---@field _id number The unique Creature ID
---@field _cached_name string|nil Optional cached name
Creature = {}
Creature.__index = Creature

--- Creates a new Creature wrapper from a Creature ID.
---@param creatureId number The unique Creature ID
---@return Creature A new Creature wrapper instance
function Creature:New(creatureId)
    local obj = {
        _id = creatureId or 0,
        _cached_name = nil
    }
    setmetatable(obj, self)
    return obj
end

--- Gets the currently followed Creature, if any.
---@return Creature|nil Followed Creature wrapper or nil
function Creature.GetFollowed()
    local followId = 0

    if type(Creatures) == "table" and type(Creatures.GetFollowingCreatureId) == "function" then
        followId = Creatures.GetFollowingCreatureId() or 0
    elseif type(creatures) == "table" and type(creatures.getFollowingCreatureId) == "function" then
        followId = creatures.getFollowingCreatureId() or 0
    elseif type(Self) == "table" and type(Self.GetFollowId) == "function" then
        followId = Self.GetFollowId() or 0
    elseif type(self) == "table" and type(self.getFollowId) == "function" then
        followId = self.getFollowId() or 0
    end

    if type(followId) ~= "number" or followId <= 0 then
        return nil
    end

    return Creature:New(followId)
end

--- Gets the currently attacked Creature, if any.
---@return Creature|nil Target Creature wrapper or nil
function Creature.GetTarget()
    local targetId = 0

    if type(Self) == "table" and type(Self.GetTargetId) == "function" then
        targetId = Self.GetTargetId() or 0
    elseif type(self) == "table" and type(self.getTargetId) == "function" then
        targetId = self.getTargetId() or 0
    elseif type(Creatures) == "table" and type(Creatures.GetAttackingCreatureId) == "function" then
        targetId = Creatures.GetAttackingCreatureId() or 0
    elseif type(creatures) == "table" and type(creatures.getAttackingCreatureId) == "function" then
        targetId = creatures.getAttackingCreatureId() or 0
    end

    if type(targetId) ~= "number" or targetId <= 0 then
        return nil
    end

    return Creature:New(targetId)
end

--- Gets the local player Creature wrapper, if available.
---@return Creature|nil Local player Creature wrapper or nil
function Creature.GetLocalPlayer()
    local getLocalPlayerId = nil

    if type(Creatures) == "table" and type(Creatures.GetLocalPlayerId) == "function" then
        getLocalPlayerId = Creatures.GetLocalPlayerId
    elseif type(creatures) == "table" and type(creatures.getLocalPlayerId) == "function" then
        getLocalPlayerId = creatures.getLocalPlayerId
    end

    if type(getLocalPlayerId) ~= "function" then
        return nil
    end

    local playerId = getLocalPlayerId()
    if type(playerId) ~= "number" or playerId <= 0 then
        return nil
    end

    return Creature:New(playerId)
end

--- Gets the Creature's unique ID.
---@return number The Creature ID
function Creature:GetId()
    return self._id
end

--- Gets the Creature's display name.
---@return string The Creature's name
function Creature:GetName()
    if not self:IsValid() then
        return ""
    end
    if not self._cached_name then
        self._cached_name = g_Creature.GetName(self._id)
    end
    return self._cached_name or ""
end

--- Gets the Creature's lowercase name for comparisons.
---@return string The Creature's name in lowercase
function Creature:GetLowercaseName()
    return string.lower(self:GetName())
end

--- Gets the Creature's current world position.
---@return table position table with fields {x, y, z}
function Creature:GetPosition()
    if not self:IsValid() then
        return {x = 0, y = 0, z = 0}
    end
    return g_Creature.GetPosition(self._id)
end

--- Gets the Creature's health percentage (0-100).
---@return number Health percentage (0-100)
function Creature:GetHealthPercent()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetHealthPercent(self._id)
end

--- Gets the Creature's movement direction.
---@return number Direction constant
function Creature:GetDirection()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetDirection(self._id)
end

--- Gets the Creature's movement speed.
---@return number Speed value
function Creature:GetSpeed()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetSpeed(self._id)
end

--- Gets the Creature's vocation/profession.
---@return number Vocation constant
function Creature:GetVocation()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetVocation(self._id)
end

--- Gets the Creature's skull type (PK status).
---@return number Skull constant
function Creature:GetSkull()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetSkull(self._id)
end

--- Gets the Creature's party shield status.
---@return number Party shield constant
function Creature:GetPartyShield()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetPartyShield(self._id)
end

--- Gets the Creature's guild shield status.
---@return number Guild shield constant
function Creature:GetGuildShield()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetGuildShield(self._id)
end

--- Gets the Creature's outfit/appearance data.
---@return table Outfit table
function Creature:GetOutfit()
    if not self:IsValid() then
        return {}
    end
    return g_Creature.GetOutfit(self._id)
end

--- Gets the Creature's master ID (for summons).
---@return number Master Creature ID or 0
function Creature:GetMasterId()
    if not self:IsValid() then
        return 0
    end
    return g_Creature.GetMasterId(self._id)
end

-- ============================================================================
-- TYPE CHECKING METHODS
-- ============================================================================

--- Checks if this Creature exists and is valid.
---@return boolean True if Creature is valid
function Creature:IsValid()
    return self._id > 0 and g_Creature.IsValid(self._id)
end

--- Checks if Creature is a player character.
---@return boolean True if player
function Creature:IsPlayer()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsPlayer(self._id)
end

--- Checks if Creature is a monster.
---@return boolean True if monster
function Creature:IsMonster()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsMonster(self._id)
end

--- Checks if Creature is an NPC.
---@return boolean True if NPC
function Creature:IsNPC()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsNPC(self._id)
end

--- Checks if Creature is a summon.
---@return boolean True if summon
function Creature:IsSummon()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsSummon(self._id)
end

--- Checks if Creature is currently visible on screen.
---@return boolean True if visible
function Creature:IsVisible()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsVisible(self._id)
end

--- Checks if Creature is a game master (GM/God).
---@return boolean True if GM
function Creature:IsGameMaster()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsGameMaster(self._id)
end

--- Checks if Creature is mounted.
---@return boolean True if mounted
function Creature:IsMounted()
    if not self:IsValid() then
        return false
    end
    return g_Creature.IsMounted(self._id)
end

-- ============================================================================
-- PARTY & GUILD HELPER METHODS
-- ============================================================================

--- Checks if Creature is in your party.
---@return boolean True if in party
function Creature:IsInParty()
    local shield = self:GetPartyShield()
    -- Use PartyShield.MEMBER instead of PARTY_SHIELD.MEMBER
    return shield >= PartyShield.MEMBER and shield <= PartyShield.IN_PARTY_WITH_SOMEONE
end

--- Checks if Creature is a party leader.
---@return boolean True if party leader
function Creature:IsPartyLeader()
    local shield = self:GetPartyShield()
    -- Use PartyShield constants
    return shield == PartyShield.LEADER 
        or shield == PartyShield.LEADER_SHARED_EXP_ACTIVATED 
        or shield == PartyShield.LEADER_SHARED_EXP_WORKING
end

--- Checks if Creature is in your guild.
---@return boolean True if in same guild
function Creature:IsInGuild()
    local shield = self:GetGuildShield()
    -- Use GuildShield.IN_SAME_GUILD instead of GUILD_SHIELD.IN_SAME_GUILD
    return shield == GuildShield.IN_SAME_GUILD or shield == GuildShield.WAR_FRIEND
end

--- Checks if Creature is a war enemy.
---@return boolean True if war enemy
function Creature:IsWarEnemy()
    -- Use GuildShield.WAR_ENEMY
    return self:GetGuildShield() == GuildShield.WAR_ENEMY
end

--- Checks if Creature is a war ally.
---@return boolean True if war ally
function Creature:IsWarAlly()
    -- Use GuildShield.WAR_FRIEND
    return self:GetGuildShield() == GuildShield.WAR_FRIEND
end

--- Checks if Creature has a skull (any PK status).
---@return boolean True if skulled
function Creature:IsSkulled()
    local skull = self:GetSkull()
    -- Use Skull.WHITE and Skull.BLACK (not SKULL.WHITE)
    return skull >= Skull.WHITE and skull <= Skull.BLACK
end

-- ============================================================================
-- DISTANCE & POSITION HELPER METHODS
-- ============================================================================

--- Gets the distance between this Creature and another position.
---@param targetPos table position table with {x, y, z}
---@return number Distance in tiles
function Creature:DistanceTo(targetPos)
    -- Delegate to the position class implementation
    -- Assumes position class has a DistanceTo method or similar logic
    -- If targetPos is a plain table, convert it; if it's a position object, use it directly.
    local myPos = Position.New(self:GetPosition())
    local otherPos = Position.New(targetPos)
    
    return myPos:DistanceTo(otherPos)
end

--- Gets the distance between this Creature and another Creature.
---@param otherCreature Creature Another Creature object
---@return number Distance in tiles
function Creature:DistanceToCreature(otherCreature)
    return self:DistanceTo(otherCreature:GetPosition())
end

--- Checks if this Creature is adjacent to a position.
---@param targetPos table position table
---@return boolean True if adjacent
function Creature:IsAdjacentTo(targetPos)
    return self:DistanceTo(targetPos) <= 1
end

--- Checks if this Creature is on the same floor.
---@param targetPos table position table
---@return boolean True if same floor
function Creature:IsSameFloor(targetPos)
    local myPos = self:GetPosition()
    return myPos.z == targetPos.z
end

--- Checks if this Creature is reachable via pathfinding.
--- Uses C++ A* implementation for accuracy.
---@return boolean True if reachable
function Creature:IsReachable()
    if not self:IsVisible() then
        return false
    end

    if type(g_Game) ~= "table" or type(g_Game.IsReachable) ~= "function" then
        return false
    end

    if type(g_Creature) ~= "table"
        or type(g_Creature.GetPosition) ~= "function"
        or (type(g_Creature.GetPlayerId) ~= "function" and type(g_Creature.GetLocalPlayerId) ~= "function") then
        return false
    end

    -- g_Game.IsReachable(fromX, fromY, fromZ, toX, toY, toZ)
    local myPos = self:GetPosition()
    local playerId = 0
    if type(g_Creature.GetPlayerId) == "function" then
        playerId = g_Creature.GetPlayerId()
    else
        playerId = g_Creature.GetLocalPlayerId()
    end

    if type(playerId) ~= "number" or playerId <= 0 then
        return false
    end

    local playerPos = g_Creature.GetPosition(playerId)

    if type(playerPos) ~= "table" then
        return false
    end

    return g_Game.IsReachable(
        playerPos.x, playerPos.y, playerPos.z,
        myPos.x, myPos.y, myPos.z
    )
end

--- Checks if this Creature is shootable (line-of-sight) from local player.
---@return boolean True if shootable
function Creature:IsShootable()
    if not self:IsVisible() then
        return false
    end

    local myPos = self:GetPosition()
    if type(myPos) ~= "table" then
        return false
    end

    if type(Position) ~= "table" or type(Position.IsShootable) ~= "function" then
        return false
    end

    return Position.IsShootable(nil, myPos)
end

-- ============================================================================
-- COMPARISON & UTILITY METHODS
-- ============================================================================

--- Compares this Creature with another by ID.
---@param other Creature Another Creature object
---@return boolean True if same Creature
function Creature:Equals(other)
    if type(other) ~= "table" or not other.GetId then
        return false
    end
    return self:GetId() == other:GetId()
end

--- Gets a string representation for debugging.
---@return string Creature description
function Creature:ToString()
    if not self:IsValid() then
        return string.format("Creature[INVALID, id=%d]", self._id)
    end
    return string.format("Creature[id=%d, name='%s', hp=%d%%]", 
        self._id, 
        self:GetName(), 
        self:GetHealthPercent())
end

--- Clears any cached data.
function Creature:ClearCache()
    self._cached_name = nil
end

Creature.__eq = function(a, b)
    return a:Equals(b)
end

Creature.__tostring = function(self)
    return self:ToString()
end

return Creature





