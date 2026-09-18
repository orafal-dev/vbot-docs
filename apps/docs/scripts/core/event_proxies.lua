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
-- Generic incoming/outgoing packet proxies
-- ============================================================================

local function validate_packet_proxy_name(name, functionName)
    if type(name) ~= "string" or name == "" then
        error(functionName .. ": name must be a non-empty string")
    end
end

local function validate_packet_proxy_ids(packetIds, functionName)
    local function validate_opcode(opcode)
        if type(opcode) ~= "number" or opcode % 1 ~= 0 or opcode < 0 or opcode > 255 then
            error(functionName .. ": packet_id values must be byte-sized integers (0..255)")
        end
    end

    if type(packetIds) == "number" then
        validate_opcode(packetIds)
        return packetIds
    end

    if type(packetIds) ~= "table" or #packetIds == 0 then
        error(functionName .. ": packet_id must be an opcode or a non-empty opcode array")
    end

    local copy = {}
    for index, opcode in ipairs(packetIds) do
        validate_opcode(opcode)
        copy[index] = opcode
    end
    return copy
end

--- Generic proxy for one or more incoming or outgoing packet opcodes.
PacketEventProxy = {}
PacketEventProxy.__index = PacketEventProxy

--- Creates and immediately registers a packet proxy.
--- The table form accepts name, optional id, packet_id, incoming, and the
--- native text-message filter fields message_contains/message_case_sensitive.
---@param nameOrOptions string|PacketEventProxyOptions Proxy name or registration options
---@param packetId? integer|integer[] Opcode(s), required with the string form
---@param incoming? boolean Defaults to true
---@return PacketEventProxy
function PacketEventProxy:New(nameOrOptions, packetId, incoming)
    local name = nameOrOptions
    local nativeId = nil
    local messageContains = nil
    local messageCaseSensitive = nil

    if type(nameOrOptions) == "table" then
        name = nameOrOptions.name or nameOrOptions.id
        nativeId = nameOrOptions.id
        packetId = nameOrOptions.packet_id or nameOrOptions.packet_ids
        incoming = nameOrOptions.incoming
        messageContains = nameOrOptions.message_contains
        messageCaseSensitive = nameOrOptions.message_case_sensitive
    end

    validate_packet_proxy_name(name, "PacketEventProxy.New")
    local normalizedPacketIds = validate_packet_proxy_ids(packetId, "PacketEventProxy.New")
    if incoming == nil then
        incoming = true
    elseif type(incoming) ~= "boolean" then
        error("PacketEventProxy.New: incoming must be a boolean")
    end

    if nativeId == nil then
        nativeId = "packet_proxy_" .. (incoming and "incoming_" or "outgoing_") .. name
    else
        validate_packet_proxy_name(nativeId, "PacketEventProxy.New")
    end

    local proxy = {
        name = name,
        incoming = incoming,
        packetIds = normalizedPacketIds,
        _onPacketCallback = nil,
        _registrationId = nil
    }
    setmetatable(proxy, self)

    local registration = {
        id = nativeId,
        packet_id = normalizedPacketIds,
        incoming = incoming,
        callback = function(packet)
            local callback = proxy._onPacketCallback
            if callback then
                callback(proxy, packet)
            end
        end
    }
    if messageContains ~= nil then
        registration.message_contains = messageContains
    end
    if messageCaseSensitive ~= nil then
        registration.message_case_sensitive = messageCaseSensitive
    end

    proxy._registrationId = Events.RegisterPacketEvent(registration)
    return proxy
end

--- Assigns a direction-agnostic callback: function(proxy, packet).
---@param callback function
---@return PacketEventProxy
function PacketEventProxy:OnPacket(callback)
    if type(callback) ~= "function" then
        error("PacketEventProxy.OnPacket: callback must be a function")
    end
    self._onPacketCallback = callback
    return self
end

--- Assigns an incoming callback: function(proxy, packet).
---@param callback function
---@return PacketEventProxy
function PacketEventProxy:OnReceive(callback)
    if not self.incoming then
        error("PacketEventProxy.OnReceive: proxy is outgoing; use OnSend or OnPacket")
    end
    return self:OnPacket(callback)
end

--- Assigns an outgoing callback: function(proxy, packet).
---@param callback function
---@return PacketEventProxy
function PacketEventProxy:OnSend(callback)
    if self.incoming then
        error("PacketEventProxy.OnSend: proxy is incoming; use OnReceive or OnPacket")
    end
    return self:OnPacket(callback)
end

--- Unregisters this proxy. Repeated calls return false.
---@return boolean
function PacketEventProxy:Unregister()
    if self._registrationId == nil then
        return false
    end

    local removed = Events.UnregisterPacketEvent(self._registrationId)
    if removed then
        self._registrationId = nil
    end
    return removed
end

--- Returns the opaque native registration id, or nil after unregistration.
---@return string|nil
function PacketEventProxy:GetRegistrationId()
    return self._registrationId
end

--- Returns the proxy name.
---@return string
function PacketEventProxy:GetName()
    return self.name
end

--- Returns true for an incoming proxy and false for an outgoing proxy.
---@return boolean
function PacketEventProxy:IsIncoming()
    return self.incoming
end

local function create_packet_proxy_type()
    local proxyType = {}
    proxyType.__index = proxyType
    return setmetatable(proxyType, { __index = PacketEventProxy })
end

IncomingPacketProxy = create_packet_proxy_type()

--- Creates a generic incoming packet proxy.
---@param name string
---@param packetId integer|integer[]
---@return IncomingPacketProxy
function IncomingPacketProxy:New(name, packetId)
    return PacketEventProxy.New(self, name, packetId, true)
end

OutgoingPacketProxy = create_packet_proxy_type()

--- Creates a generic outgoing packet proxy.
---@param name string
---@param packetId integer|integer[]
---@return OutgoingPacketProxy
function OutgoingPacketProxy:New(name, packetId)
    return PacketEventProxy.New(self, name, packetId, false)
end

-- These named proxies cover every parser currently exported by the native Lua
-- packet serializer. Unparsed opcodes remain available through the two generic
-- direction-specific proxies and always include packet.opcode.

TextMessagePacketProxy = create_packet_proxy_type()

---@param name string
---@return TextMessagePacketProxy
function TextMessagePacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_TEXT_MESSAGE, true)
end

TalkPacketProxy = create_packet_proxy_type()

---@param name string
---@return TalkPacketProxy
function TalkPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_TALK, true)
end

CreateOnMapPacketProxy = create_packet_proxy_type()

---@param name string
---@return CreateOnMapPacketProxy
function CreateOnMapPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_CREATE_ON_MAP, true)
end

DeleteOnMapPacketProxy = create_packet_proxy_type()

---@param name string
---@return DeleteOnMapPacketProxy
function DeleteOnMapPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_DELETE_ON_MAP, true)
end

MoveCreaturePacketProxy = create_packet_proxy_type()

---@param name string
---@return MoveCreaturePacketProxy
function MoveCreaturePacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_MOVE_CREATURE, true)
end

FullMapPacketProxy = create_packet_proxy_type()

---@param name string
---@return FullMapPacketProxy
function FullMapPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_FULL_MAP, true)
end

MapRowPacketProxy = create_packet_proxy_type()

---@param name string
---@return MapRowPacketProxy
function MapRowPacketProxy:New(name)
    return PacketEventProxy.New(self, name, {
        GameServerOpcodes.GAME_SERVER_MAP_TOP_ROW,
        GameServerOpcodes.GAME_SERVER_MAP_RIGHT_ROW,
        GameServerOpcodes.GAME_SERVER_MAP_BOTTOM_ROW,
        GameServerOpcodes.GAME_SERVER_MAP_LEFT_ROW
    }, true)
end

GraphicalEffectPacketProxy = create_packet_proxy_type()

---@param name string
---@return GraphicalEffectPacketProxy
function GraphicalEffectPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_GRAPHICAL_EFFECT, true)
end

UnjustifiedPointsPacketProxy = create_packet_proxy_type()

---@param name string
---@return UnjustifiedPointsPacketProxy
function UnjustifiedPointsPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_UNJUSTIFIED_POINTS, true)
end

PlayerInventoryPacketProxy = create_packet_proxy_type()

---@param name string
---@return PlayerInventoryPacketProxy
function PlayerInventoryPacketProxy:New(name)
    return PacketEventProxy.New(self, name, GameServerOpcodes.GAME_SERVER_PLAYER_INVENTORY, true)
end

ClientLookPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientLookPacketProxy
function ClientLookPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_LOOK, false)
end

ClientMovementPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientMovementPacketProxy
function ClientMovementPacketProxy:New(name)
    return PacketEventProxy.New(self, name, {
        ClientOpcodes.CLIENT_AUTO_WALK,
        ClientOpcodes.CLIENT_WALK_NORTH,
        ClientOpcodes.CLIENT_WALK_EAST,
        ClientOpcodes.CLIENT_WALK_SOUTH,
        ClientOpcodes.CLIENT_WALK_WEST,
        ClientOpcodes.CLIENT_STOP,
        ClientOpcodes.CLIENT_WALK_NORTH_EAST,
        ClientOpcodes.CLIENT_WALK_SOUTH_EAST,
        ClientOpcodes.CLIENT_WALK_SOUTH_WEST,
        ClientOpcodes.CLIENT_WALK_NORTH_WEST
    }, false)
end

ClientEquipItemPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientEquipItemPacketProxy
function ClientEquipItemPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_EQUIP_ITEM, false)
end

ClientMoveItemPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientMoveItemPacketProxy
function ClientMoveItemPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_MOVE, false)
end

ClientUseItemPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientUseItemPacketProxy
function ClientUseItemPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_USE_ITEM, false)
end

ClientUseItemWithPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientUseItemWithPacketProxy
function ClientUseItemWithPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_USE_ITEM_WITH, false)
end

ClientUseOnCreaturePacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientUseOnCreaturePacketProxy
function ClientUseOnCreaturePacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_USE_ON_CREATURE, false)
end

ClientTalkPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientTalkPacketProxy
function ClientTalkPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_TALK, false)
end

ClientAttackPacketProxy = create_packet_proxy_type()

---@param name string
---@return ClientAttackPacketProxy
function ClientAttackPacketProxy:New(name)
    return PacketEventProxy.New(self, name, ClientOpcodes.CLIENT_ATTACK, false)
end

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
        if proxy._onReceiveCallback and packet.creature_id ~= nil then
            proxy._onReceiveCallback(proxy, packet.creature_id, packet.creature_name, packet.position)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "creature_add_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_CREATE_ON_MAP,
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
            -- Delete-on-map does not expose the removed creature id. Preserve
            -- the historical first argument as nil and provide the useful
            -- parsed location plus the complete packet as trailing arguments.
            proxy._onReceiveCallback(
                proxy,
                nil,
                packet.position,
                packet.stack_position,
                packet)
        end
    end
    
    Events.RegisterPacketEvent({
        id = "creature_remove_proxy_" .. name,
        packet_id = GameServerOpcodes.GAME_SERVER_DELETE_ON_MAP,
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

    if type(proxyClass.New) == "function" and rawget(proxyClass, "new") == nil then
        proxyClass.new = proxyClass.New
    end

    if type(proxyClass.OnReceive) == "function" and rawget(proxyClass, "onReceive") == nil then
        proxyClass.onReceive = proxyClass.OnReceive
    end

    if type(proxyClass.OnSend) == "function" and rawget(proxyClass, "onSend") == nil then
        proxyClass.onSend = proxyClass.OnSend
    end

    if type(proxyClass.OnPacket) == "function" and rawget(proxyClass, "onPacket") == nil then
        proxyClass.onPacket = proxyClass.OnPacket
    end

    if type(proxyClass.Unregister) == "function" and rawget(proxyClass, "unregister") == nil then
        proxyClass.unregister = proxyClass.Unregister
    end

    if type(proxyClass.GetRegistrationId) == "function" and rawget(proxyClass, "getRegistrationId") == nil then
        proxyClass.getRegistrationId = proxyClass.GetRegistrationId
    end

    if type(proxyClass.GetName) == "function" and rawget(proxyClass, "getName") == nil then
        proxyClass.getName = proxyClass.GetName
    end

    if type(proxyClass.IsIncoming) == "function" and rawget(proxyClass, "isIncoming") == nil then
        proxyClass.isIncoming = proxyClass.IsIncoming
    end
end

attach_proxy_pascal_methods(PacketEventProxy)
attach_proxy_pascal_methods(IncomingPacketProxy)
attach_proxy_pascal_methods(OutgoingPacketProxy)
attach_proxy_pascal_methods(TextMessagePacketProxy)
attach_proxy_pascal_methods(TalkPacketProxy)
attach_proxy_pascal_methods(CreateOnMapPacketProxy)
attach_proxy_pascal_methods(DeleteOnMapPacketProxy)
attach_proxy_pascal_methods(MoveCreaturePacketProxy)
attach_proxy_pascal_methods(FullMapPacketProxy)
attach_proxy_pascal_methods(MapRowPacketProxy)
attach_proxy_pascal_methods(GraphicalEffectPacketProxy)
attach_proxy_pascal_methods(UnjustifiedPointsPacketProxy)
attach_proxy_pascal_methods(PlayerInventoryPacketProxy)
attach_proxy_pascal_methods(ClientLookPacketProxy)
attach_proxy_pascal_methods(ClientMovementPacketProxy)
attach_proxy_pascal_methods(ClientEquipItemPacketProxy)
attach_proxy_pascal_methods(ClientMoveItemPacketProxy)
attach_proxy_pascal_methods(ClientUseItemPacketProxy)
attach_proxy_pascal_methods(ClientUseItemWithPacketProxy)
attach_proxy_pascal_methods(ClientUseOnCreaturePacketProxy)
attach_proxy_pascal_methods(ClientTalkPacketProxy)
attach_proxy_pascal_methods(ClientAttackPacketProxy)
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


