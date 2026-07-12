ChatChannel = ChatChannel or {}
ChatChannel.__index = ChatChannel

local function validate_non_empty_string(value, argName, functionName)
    if type(value) ~= "string" or value == "" then
        error(functionName .. ": argument '" .. argName .. "' must be a non-empty string")
    end
end

local function validate_non_negative_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value < 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer >= 0")
    end
end

local function normalize_from_table(data)
    if type(data) ~= "table" then
        return nil
    end

    local id = data.id
    if type(id) ~= "number" then
        id = data.channelId
    end

    if type(id) ~= "number" or id % 1 ~= 0 or id < 0 then
        id = 0
    end

    local name = data.name
    if type(name) ~= "string" then
        name = data.channelName
    end

    if type(name) ~= "string" then
        name = ""
    end

    return {
        id = id,
        name = name,
        canSend = data.canSend == true,
        isOpened = data.isOpened ~= false,
        isLocal = data.isLocal == true,
        isServerLog = data.isServerLog == true,
        raw = data.raw
    }
end

local function resolve_from_storage(identifier)
    if type(ChatChannelStorage) ~= "table" then
        return nil
    end

    if type(ChatChannelStorage.ResolveChannel) == "function" then
        return ChatChannelStorage.ResolveChannel(identifier)
    end

    if type(identifier) == "number" and type(ChatChannelStorage.GetChatChannelById) == "function" then
        return ChatChannelStorage.GetChatChannelById(identifier)
    end

    if type(identifier) == "string" and type(ChatChannelStorage.GetChatChannelByName) == "function" then
        return ChatChannelStorage.GetChatChannelByName(identifier)
    end

    return nil
end

--- Creates a ChatChannel object.
---@param channelOrId table|integer
---@param channelName? string
---@return table
function ChatChannel.New(channelOrId, channelName)
    local normalized = nil

    if type(channelOrId) == "table" then
        normalized = normalize_from_table(channelOrId)
    elseif type(channelOrId) == "number" then
        normalized = {
            id = channelOrId,
            name = type(channelName) == "string" and channelName or "",
            canSend = false,
            isOpened = true,
            isLocal = false,
            isServerLog = false,
            raw = nil
        }
    end

    if not normalized then
        normalized = {
            id = 0,
            name = "",
            canSend = false,
            isOpened = false,
            isLocal = false,
            isServerLog = false,
            raw = nil
        }
    end

    return setmetatable(normalized, ChatChannel)
end

--- Returns ChatChannel object resolved by identifier.
---@param identifier any
---@return table|nil
function ChatChannel.FromIdentifier(identifier)
    local resolved = resolve_from_storage(identifier)
    if not resolved then
        return nil
    end

    return ChatChannel.New(resolved)
end

--- Returns ChatChannel by channel id.
---@param channelId integer
---@return table|nil
function ChatChannel.GetById(channelId)
    validate_non_negative_integer(channelId, "channelId", "ChatChannel.GetById")
    return ChatChannel.FromIdentifier(channelId)
end

--- Returns ChatChannel by channel name.
---@param channelName string
---@return table|nil
function ChatChannel.GetByName(channelName)
    validate_non_empty_string(channelName, "channelName", "ChatChannel.GetByName")
    return ChatChannel.FromIdentifier(channelName)
end

--- Returns channel id.
---@return integer
function ChatChannel:GetId()
    return self.id
end

--- Returns channel name.
---@return string
function ChatChannel:GetName()
    return self.name
end

--- Returns true when channel can be used for sending.
---@return boolean
function ChatChannel:CanSend()
    if self.id <= 0 then
        return false
    end

    if self.canSend then
        return true
    end

    if type(ChatChannelStorage) == "table" and type(ChatChannelStorage.CanSend) == "function" then
        return ChatChannelStorage.CanSend(self.id)
    end

    return false
end

--- Returns true when channel is opened/known.
---@return boolean
function ChatChannel:IsOpened()
    return self.isOpened == true
end

--- Returns true when channel represents local chat pseudo-channel.
---@return boolean
function ChatChannel:IsLocal()
    return self.isLocal == true
end

--- Returns true when channel represents server log pseudo-channel.
---@return boolean
function ChatChannel:IsServerLog()
    return self.isServerLog == true
end

--- Returns true when object has a valid name and id >= 0.
---@return boolean
function ChatChannel:IsValid()
    return type(self.name) == "string" and self.name ~= "" and type(self.id) == "number" and self.id >= 0
end

--- Sends message through this channel.
---@param message string
---@return boolean
function ChatChannel:Send(message)
    validate_non_empty_string(message, "message", "ChatChannel.Send")

    if not self:CanSend() then
        return false
    end

    if type(self) == "table" and type(self.sayOnChannel) == "function" then
        local ok, result = pcall(self.sayOnChannel, message, self.id)
        return ok and result == true
    end

    if type(Game) == "table" and type(Game.TalkOnChannel) == "function" then
        local ok, result = pcall(Game.TalkOnChannel, message, self.id)
        return ok and result == true
    end

    return false
end

--- Refreshes this channel object from storage by id/name.
---@return boolean
function ChatChannel:Refresh()
    local resolved = nil

    if self.id > 0 then
        resolved = resolve_from_storage(self.id)
    end

    if not resolved and type(self.name) == "string" and self.name ~= "" then
        resolved = resolve_from_storage(self.name)
    end

    if not resolved then
        return false
    end

    self.id = resolved.id
    self.name = resolved.name
    self.canSend = resolved.canSend == true
    self.isOpened = resolved.isOpened ~= false
    self.isLocal = resolved.isLocal == true
    self.isServerLog = resolved.isServerLog == true
    self.raw = resolved.raw

    return true
end

--- Converts object to a plain table snapshot.
---@return table
function ChatChannel:ToTable()
    return {
        id = self.id,
        name = self.name,
        canSend = self:CanSend(),
        isOpened = self.isOpened == true,
        isLocal = self.isLocal == true,
        isServerLog = self.isServerLog == true,
        raw = self.raw
    }
end

--- Returns formatted channel text for logs.
---@return string
function ChatChannel:ToString()
    return "[" .. tostring(self.id) .. "] " .. tostring(self.name)
        .. " canSend=" .. tostring(self:CanSend())
        .. " isOpened=" .. tostring(self:IsOpened())
        .. " isLocal=" .. tostring(self:IsLocal())
        .. " isServerLog=" .. tostring(self:IsServerLog())
end

-- Lower camel aliases
ChatChannel.New = ChatChannel.New
ChatChannel.FromIdentifier = ChatChannel.FromIdentifier
ChatChannel.GetById = ChatChannel.GetById
ChatChannel.GetByName = ChatChannel.GetByName

return ChatChannel





