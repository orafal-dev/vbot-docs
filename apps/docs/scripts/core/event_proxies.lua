-- File: core/event_proxies.lua
-- High-level event proxy wrappers for common game events

--[[
    Event Proxies provide a clean interface for handling game events.
    
    Usage Example:
        local lootProxy = LootMessageProxy:New("my_loot_handler")
        lootProxy:OnReceive(function(proxy, message)
            print("Looted: " .. message)
        end)
]]

-- ============================================================================
-- Generic Text Message Proxy
-- ============================================================================
-- Handles general server text messages (e.g., "You are hungry", level ups)
GenericTextMessageProxy = {}
GenericTextMessageProxy.__index = GenericTextMessageProxy

--- Creates a generic text-message proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function GenericTextMessageProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        -- Check if the message class is a standard server message or warning
        if packet.message_class == 21 or packet.message_class == 22 then
            if proxy._onReceiveCallback then
                proxy._onReceiveCallback(proxy, packet.message)
            end
        end
    end
    
    Events.RegisterPacketEvent({
        id = "text_message_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_TEXT_MESSAGE,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when a matching message arrives.
---@param callback function Callback signature: function(proxy, message)
---@return table
function GenericTextMessageProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function GenericTextMessageProxy:GetName()
    return self.name
end

-- ============================================================================
-- Battle Message Proxy
-- ============================================================================
-- Handles combat-related text messages in the console
BattleMessageProxy = {}
BattleMessageProxy.__index = BattleMessageProxy

--- Creates a battle-message proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function BattleMessageProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        -- Message class 21 includes battle messages
        if packet.message_class == 21 then
            if proxy._onReceiveCallback then
                proxy._onReceiveCallback(proxy, packet.message)
            end
        end
    end
    
    Events.RegisterPacketEvent({
        id = "battle_message_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_TEXT_MESSAGE,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when a matching battle message arrives.
---@param callback function Callback signature: function(proxy, message)
---@return table
function BattleMessageProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function BattleMessageProxy:GetName()
    return self.name
end

-- ============================================================================
-- Loot Message Proxy
-- ============================================================================
-- Handles loot-related messages ("You looted X items")
LootMessageProxy = {}
LootMessageProxy.__index = LootMessageProxy

--- Creates a loot-message proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function LootMessageProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback and packet.message then
            -- Filter for loot-specific messages
            local msg = packet.message:lower()
            if msg:find("loot") or msg:find("you see") then
                proxy._onReceiveCallback(proxy, packet.message)
            end
        end
    end
    
    Events.RegisterPacketEvent({
        id = "loot_message_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_TEXT_MESSAGE,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when a loot-like message arrives.
---@param callback function Callback signature: function(proxy, message)
---@return table
function LootMessageProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function LootMessageProxy:GetName()
    return self.name
end

-- ============================================================================
-- Container Open Proxy
-- ============================================================================
-- Triggered when a container window opens
ContainerOpenProxy = {}
ContainerOpenProxy.__index = ContainerOpenProxy

--- Creates a container-open proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function ContainerOpenProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            -- packet should contain: containerIndex, containerName, containerItemID
            proxy._onReceiveCallback(proxy, packet.containerIndex, packet.containerName, packet.containerID)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "container_open_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_OPEN_CONTAINER,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when a container is opened.
---@param callback function Callback signature: function(proxy, containerIndex, containerName, containerID)
---@return table
function ContainerOpenProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function ContainerOpenProxy:GetName()
    return self.name
end

-- ============================================================================
-- Container Close Proxy
-- ============================================================================
-- Triggered when a container window closes
ContainerCloseProxy = {}
ContainerCloseProxy.__index = ContainerCloseProxy

--- Creates a container-close proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function ContainerCloseProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.containerIndex)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "container_close_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_CLOSE_CONTAINER,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when a container is closed.
---@param callback function Callback signature: function(proxy, containerIndex)
---@return table
function ContainerCloseProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function ContainerCloseProxy:GetName()
    return self.name
end

-- ============================================================================
-- Container Add Item Proxy
-- ============================================================================
-- Triggered when an item is added to a container
ContainerAddItemProxy = {}
ContainerAddItemProxy.__index = ContainerAddItemProxy

--- Creates a container-add-item proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function ContainerAddItemProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.containerIndex, packet.slot, packet.item)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "container_add_item_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_CREATE_CONTAINER,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when item is added to container.
---@param callback function Callback signature: function(proxy, containerIndex, slot, item)
---@return table
function ContainerAddItemProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function ContainerAddItemProxy:GetName()
    return self.name
end

-- ============================================================================
-- Container Update Item Proxy
-- ============================================================================
-- Triggered when an item in a container changes
ContainerUpdateItemProxy = {}
ContainerUpdateItemProxy.__index = ContainerUpdateItemProxy

--- Creates a container-update-item proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function ContainerUpdateItemProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.containerIndex, packet.slot, packet.item)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "container_update_item_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_CHANGE_IN_CONTAINER,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when container item changes.
---@param callback function Callback signature: function(proxy, containerIndex, slot, item)
---@return table
function ContainerUpdateItemProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function ContainerUpdateItemProxy:GetName()
    return self.name
end

-- ============================================================================
-- Container Remove Item Proxy
-- ============================================================================
-- Triggered when an item is removed from a container
ContainerRemoveItemProxy = {}
ContainerRemoveItemProxy.__index = ContainerRemoveItemProxy

--- Creates a container-remove-item proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function ContainerRemoveItemProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.containerIndex, packet.slot)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "container_remove_item_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_DELETE_IN_CONTAINER,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when item is removed from container.
---@param callback function Callback signature: function(proxy, containerIndex, slot)
---@return table
function ContainerRemoveItemProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function ContainerRemoveItemProxy:GetName()
    return self.name
end

-- ============================================================================
-- Stats Change Proxy
-- ============================================================================
-- Triggered when player stats change (HP, Mana, etc.)
StatsChangeProxy = {}
StatsChangeProxy.__index = StatsChangeProxy

--- Creates a player-stats-change proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function StatsChangeProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "stats_change_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_PLAYER_DATA,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when player stats packet arrives.
---@param callback function Callback signature: function(proxy, packet)
---@return table
function StatsChangeProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function StatsChangeProxy:GetName()
    return self.name
end

-- ============================================================================
-- Skills Change Proxy
-- ============================================================================
-- Triggered when player skills change
SkillsChangeProxy = {}
SkillsChangeProxy.__index = SkillsChangeProxy

--- Creates a player-skills-change proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function SkillsChangeProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "skills_change_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_PLAYER_SKILLS,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when skills packet arrives.
---@param callback function Callback signature: function(proxy, packet)
---@return table
function SkillsChangeProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function SkillsChangeProxy:GetName()
    return self.name
end

-- ============================================================================
-- Creature Add Proxy
-- ============================================================================
-- Triggered when a creature appears on screen
CreatureAddProxy = {}
CreatureAddProxy.__index = CreatureAddProxy

--- Creates a creature-add proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function CreatureAddProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.creatureId, packet.creatureName, packet.position)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "creature_add_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_ADD_CREATURE,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when creature appears.
---@param callback function Callback signature: function(proxy, creatureId, creatureName, position)
---@return table
function CreatureAddProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function CreatureAddProxy:GetName()
    return self.name
end

-- ============================================================================
-- Creature Remove Proxy
-- ============================================================================
-- Triggered when a creature disappears from screen
CreatureRemoveProxy = {}
CreatureRemoveProxy.__index = CreatureRemoveProxy

--- Creates a creature-remove proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function CreatureRemoveProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy, packet.creatureId)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "creature_remove_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_REMOVE_CREATURE,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when creature disappears.
---@param callback function Callback signature: function(proxy, creatureId)
---@return table
function CreatureRemoveProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function CreatureRemoveProxy:GetName()
    return self.name
end

-- ============================================================================
-- Death Proxy
-- ============================================================================
-- Triggered when the player dies
DeathProxy = {}
DeathProxy.__index = DeathProxy

--- Creates a death proxy and registers packet listener.
---@param name string Unique proxy name suffix
---@return table
function DeathProxy:New(name)
    local proxy = {
        name = name,
        _onReceiveCallback = nil,
    }
    setmetatable(proxy, self)
    
    local function internalPacketHandler(packet)
        if proxy._onReceiveCallback then
            proxy._onReceiveCallback(proxy)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "death_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_DEATH,
        callback = internalPacketHandler,
        incoming = true
    })
    
    return proxy
end

--- Assigns callback called when death packet arrives.
---@param callback function Callback signature: function(proxy)
---@return table
function DeathProxy:OnReceive(callback)
    if type(callback) == "function" then
        self._onReceiveCallback = callback
    end
    return self
end

--- Returns proxy name.
---@return string
function DeathProxy:GetName()
    return self.name
end

-- PascalCase aliases for scripting compatibility.
GenericTextMessageProxy = GenericTextMessageProxy
BattleMessageProxy = BattleMessageProxy
LootMessageProxy = LootMessageProxy
ContainerOpenProxy = ContainerOpenProxy
ContainerCloseProxy = ContainerCloseProxy
ContainerAddItemProxy = ContainerAddItemProxy
ContainerUpdateItemProxy = ContainerUpdateItemProxy
ContainerRemoveItemProxy = ContainerRemoveItemProxy
StatsChangeProxy = StatsChangeProxy
SkillsChangeProxy = SkillsChangeProxy
CreatureAddProxy = CreatureAddProxy
CreatureRemoveProxy = CreatureRemoveProxy
DeathProxy = DeathProxy

local function attach_proxy_pascal_methods(proxyClass)
    if not proxyClass then
        return
    end

    if type(proxyClass.New) == "function" and proxyClass.new == nil then
        proxyClass.new = proxyClass.New
    end

    if type(proxyClass.OnReceive) == "function" and proxyClass.onReceive == nil then
        proxyClass.onReceive = proxyClass.OnReceive
    end

    if type(proxyClass.GetName) == "function" and proxyClass.getName == nil then
        proxyClass.getName = proxyClass.GetName
    end
end

attach_proxy_pascal_methods(GenericTextMessageProxy)
attach_proxy_pascal_methods(BattleMessageProxy)
attach_proxy_pascal_methods(LootMessageProxy)
attach_proxy_pascal_methods(ContainerOpenProxy)
attach_proxy_pascal_methods(ContainerCloseProxy)
attach_proxy_pascal_methods(ContainerAddItemProxy)
attach_proxy_pascal_methods(ContainerUpdateItemProxy)
attach_proxy_pascal_methods(ContainerRemoveItemProxy)
attach_proxy_pascal_methods(StatsChangeProxy)
attach_proxy_pascal_methods(SkillsChangeProxy)
attach_proxy_pascal_methods(CreatureAddProxy)
attach_proxy_pascal_methods(CreatureRemoveProxy)
attach_proxy_pascal_methods(DeathProxy)


