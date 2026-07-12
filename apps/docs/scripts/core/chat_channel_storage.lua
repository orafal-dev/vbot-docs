ChatChannelStorage = ChatChannelStorage or {}

local unpack_fn = table.unpack or unpack

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

local function to_lower_safe(value)
    if type(value) ~= "string" then
        return ""
    end

    return string.lower(value)
end

local function call_backend_method(backend, methodName, ...)
    local method = backend[methodName]
    if type(method) ~= "function" then
        return false, nil
    end

    local args = { ... }

    local ok, result = pcall(method, unpack_fn(args))
    if ok then
        return true, result
    end

    ok, result = pcall(method, backend, unpack_fn(args))
    if ok then
        return true, result
    end

    return false, nil
end

local function resolve_backend_table()
    local candidates = {
        "ChatChannels",
        "Channels",
        "Game"
    }

    local apiMethodNames = {
        "GetOpenedChannels",
        "GetChatChannels",
        "GetChatChannel",
        "GetLocalChatChannel",
        "GetServerLogChannel"
    }

    for i = 1, #candidates do
        local candidate = rawget(_G, candidates[i])
        if type(candidate) == "table" and candidate ~= ChatChannelStorage then
            for j = 1, #apiMethodNames do
                if type(candidate[apiMethodNames[j]]) == "function" then
                    return candidate
                end
            end
        end
    end

    return nil
end

local function normalize_channel_name(name)
    if type(name) ~= "string" then
        return ""
    end

    return name
end

local function normalize_channel_id(channelId)
    if type(channelId) ~= "number" then
        return 0
    end

    if channelId % 1 ~= 0 or channelId < 0 then
        return 0
    end

    return channelId
end

local function get_any_method_value(target, methodNames)
    if type(target) ~= "table" and type(target) ~= "userdata" then
        return false, nil
    end

    for i = 1, #methodNames do
        local methodName = methodNames[i]
        local ok, method = pcall(function()
            return target[methodName]
        end)

        if ok and type(method) == "function" then
            local called, result = pcall(method)
            if not called then
                called, result = pcall(method, target)
            end

            if called then
                return true, result
            end
        end
    end

    return false, nil
end

local function get_any_field_value(target, fieldNames)
    if type(target) ~= "table" and type(target) ~= "userdata" then
        return false, nil
    end

    for i = 1, #fieldNames do
        local ok, value = pcall(function()
            return target[fieldNames[i]]
        end)

        if ok and value ~= nil and type(value) ~= "function" then
            return true, value
        end
    end

    return false, nil
end

local function normalize_channel_entry(rawChannel)
    if rawChannel == nil then
        return nil
    end

    local hasName, name = get_any_method_value(rawChannel, {
        "GetChannelName",
        "GetName"
    })

    if not hasName then
        hasName, name = get_any_field_value(rawChannel, {
            "channelName",
            "name",
            "Name"
        })
    end

    name = normalize_channel_name(name)
    if name == "" then
        return nil
    end

    local hasId, channelId = get_any_method_value(rawChannel, {
        "GetChannelId",
        "GetId"
    })

    if not hasId then
        hasId, channelId = get_any_field_value(rawChannel, {
            "channelId",
            "id",
            "Id"
        })
    end

    local normalizedId = normalize_channel_id(channelId)

    return {
        id = normalizedId,
        name = name,
        canSend = false,
        isOpened = true,
        isLocal = false,
        isServerLog = false,
        raw = rawChannel
    }
end

local function sort_channels(channels)
    table.sort(channels, function(a, b)
        local aName = to_lower_safe(a.name)
        local bName = to_lower_safe(b.name)
        if aName == bName then
            return a.id < b.id
        end

        return aName < bName
    end)
end

local function dedupe_channels(channels)
    local out = {}
    local seen = {}

    for i = 1, #channels do
        local channel = channels[i]
        local key = tostring(channel.id) .. ":" .. to_lower_safe(channel.name)
        if not seen[key] then
            seen[key] = true
            out[#out + 1] = channel
        end
    end

    return out
end

local function get_raw_opened_channels()
    local backend = resolve_backend_table()
    if not backend then
        return {}
    end

    local ok, result = call_backend_method(backend, "GetOpenedChannels")
    if not ok or type(result) ~= "table" then
        return {}
    end

    return result
end

local function get_raw_chat_channels()
    local backend = resolve_backend_table()
    if not backend then
        return {}
    end

    local ok, result = call_backend_method(backend, "GetChatChannels")
    if not ok or type(result) ~= "table" then
        return {}
    end

    return result
end

local function get_raw_local_chat_channel()
    local backend = resolve_backend_table()
    if not backend then
        return nil
    end

    local ok, result = call_backend_method(backend, "GetLocalChatChannel")
    if not ok then
        return nil
    end

    return result
end

local function get_raw_server_log_channel()
    local backend = resolve_backend_table()
    if not backend then
        return nil
    end

    local ok, result = call_backend_method(backend, "GetServerLogChannel")
    if not ok then
        return nil
    end

    return result
end

local function get_raw_channel_by_name(channelName)
    local backend = resolve_backend_table()
    if not backend then
        return nil
    end

    local ok, result = call_backend_method(backend, "GetChatChannel", channelName)
    if not ok then
        return nil
    end

    return result
end

local function get_raw_channel_by_id(channelId)
    local backend = resolve_backend_table()
    if not backend then
        return nil
    end

    local ok, result = call_backend_method(backend, "GetChatChannel", channelId)
    if not ok then
        return nil
    end

    return result
end

local function build_opened_channels_snapshot()
    local openedRaw = get_raw_opened_channels()
    local sendableRaw = get_raw_chat_channels()

    local opened = {}
    local sendableKeys = {}

    for _, rawChannel in pairs(sendableRaw) do
        local normalized = normalize_channel_entry(rawChannel)
        if normalized then
            local key = tostring(normalized.id) .. ":" .. to_lower_safe(normalized.name)
            sendableKeys[key] = true
        end
    end

    for _, rawChannel in pairs(openedRaw) do
        local normalized = normalize_channel_entry(rawChannel)
        if normalized then
            local key = tostring(normalized.id) .. ":" .. to_lower_safe(normalized.name)
            normalized.canSend = sendableKeys[key] == true
            opened[#opened + 1] = normalized
        end
    end

    opened = dedupe_channels(opened)
    sort_channels(opened)

    return opened
end

local function build_sendable_channels_snapshot()
    local sendable = {}
    local rawChannels = get_raw_chat_channels()

    for _, rawChannel in pairs(rawChannels) do
        local normalized = normalize_channel_entry(rawChannel)
        if normalized then
            normalized.canSend = true
            sendable[#sendable + 1] = normalized
        end
    end

    sendable = dedupe_channels(sendable)
    sort_channels(sendable)

    return sendable
end

local function find_channel_by_name(channels, channelName)
    local expected = to_lower_safe(channelName)
    for i = 1, #channels do
        if to_lower_safe(channels[i].name) == expected then
            return channels[i]
        end
    end

    return nil
end

local function find_channel_by_id(channels, channelId)
    for i = 1, #channels do
        if channels[i].id == channelId then
            return channels[i]
        end
    end

    return nil
end

local function to_channel_identifier_string(channel)
    return "[" .. tostring(channel.id) .. "] " .. tostring(channel.name)
end

--- Returns whether chat-channel storage API is available in runtime bindings.
---@return boolean
function ChatChannelStorage.IsAvailable()
    return resolve_backend_table() ~= nil
end

--- Returns all opened channels.
---@return table[]
function ChatChannelStorage.GetOpenedChannels()
    return build_opened_channels_snapshot()
end

--- Returns all channels where sending messages is allowed.
---@return table[]
function ChatChannelStorage.GetChatChannels()
    return build_sendable_channels_snapshot()
end

--- Returns local chat channel when available.
---@return table|nil
function ChatChannelStorage.GetLocalChatChannel()
    local normalized = normalize_channel_entry(get_raw_local_chat_channel())
    if normalized then
        normalized.isLocal = true
        normalized.canSend = false
    end

    return normalized
end

--- Returns server log channel when available.
---@return table|nil
function ChatChannelStorage.GetServerLogChannel()
    local normalized = normalize_channel_entry(get_raw_server_log_channel())
    if normalized then
        normalized.isServerLog = true
        normalized.canSend = false
    end

    return normalized
end

--- Returns one channel by name.
---@param channelName string
---@return table|nil
function ChatChannelStorage.GetChatChannelByName(channelName)
    validate_non_empty_string(channelName, "channelName", "ChatChannelStorage.GetChatChannelByName")

    local direct = normalize_channel_entry(get_raw_channel_by_name(channelName))
    if direct then
        local canSend = find_channel_by_id(ChatChannelStorage.GetChatChannels(), direct.id)
        direct.canSend = canSend ~= nil
        return direct
    end

    return find_channel_by_name(ChatChannelStorage.GetOpenedChannels(), channelName)
end

--- Returns one channel by id.
---@param channelId integer
---@return table|nil
function ChatChannelStorage.GetChatChannelById(channelId)
    validate_non_negative_integer(channelId, "channelId", "ChatChannelStorage.GetChatChannelById")

    local direct = normalize_channel_entry(get_raw_channel_by_id(channelId))
    if direct then
        local canSend = find_channel_by_id(ChatChannelStorage.GetChatChannels(), direct.id)
        direct.canSend = canSend ~= nil
        return direct
    end

    return find_channel_by_id(ChatChannelStorage.GetOpenedChannels(), channelId)
end

--- Returns true if channel exists by name.
---@param channelName string
---@return boolean
function ChatChannelStorage.HasChannelByName(channelName)
    return ChatChannelStorage.GetChatChannelByName(channelName) ~= nil
end

--- Returns true if channel exists by id.
---@param channelId integer
---@return boolean
function ChatChannelStorage.HasChannelById(channelId)
    return ChatChannelStorage.GetChatChannelById(channelId) ~= nil
end

--- Returns opened-channel count.
---@return integer
function ChatChannelStorage.GetOpenedChannelCount()
    return #ChatChannelStorage.GetOpenedChannels()
end

--- Returns sendable-channel count.
---@return integer
function ChatChannelStorage.GetChatChannelCount()
    return #ChatChannelStorage.GetChatChannels()
end

--- Returns list of channel names.
---@param onlySendable? boolean
---@return string[]
function ChatChannelStorage.GetChannelNames(onlySendable)
    local channels = onlySendable == true and ChatChannelStorage.GetChatChannels() or ChatChannelStorage.GetOpenedChannels()
    local out = {}

    for i = 1, #channels do
        out[#out + 1] = channels[i].name
    end

    return out
end

--- Returns whether sending is allowed on a channel (by id, name, or channel table).
---@param channelIdentifier any
---@return boolean
function ChatChannelStorage.CanSend(channelIdentifier)
    local channel = ChatChannelStorage.ResolveChannel(channelIdentifier)
    return channel ~= nil and channel.canSend == true and channel.id > 0
end

--- Resolves a channel identifier (id, name, or table) into normalized channel table.
---@param channelIdentifier any
---@return table|nil
function ChatChannelStorage.ResolveChannel(channelIdentifier)
    local valueType = type(channelIdentifier)

    if valueType == "number" then
        return ChatChannelStorage.GetChatChannelById(channelIdentifier)
    end

    if valueType == "string" then
        return ChatChannelStorage.GetChatChannelByName(channelIdentifier)
    end

    if valueType == "table" then
        if type(channelIdentifier.id) == "number" then
            return ChatChannelStorage.GetChatChannelById(channelIdentifier.id)
        end

        if type(channelIdentifier.channelId) == "number" then
            return ChatChannelStorage.GetChatChannelById(channelIdentifier.channelId)
        end

        if type(channelIdentifier.name) == "string" and channelIdentifier.name ~= "" then
            return ChatChannelStorage.GetChatChannelByName(channelIdentifier.name)
        end

        if type(channelIdentifier.channelName) == "string" and channelIdentifier.channelName ~= "" then
            return ChatChannelStorage.GetChatChannelByName(channelIdentifier.channelName)
        end
    end

    return nil
end

--- Sends message to a channel identified by id/name/table.
---@param message string
---@param channelIdentifier any
---@return boolean
function ChatChannelStorage.Send(message, channelIdentifier)
    validate_non_empty_string(message, "message", "ChatChannelStorage.Send")

    local channel = ChatChannelStorage.ResolveChannel(channelIdentifier)
    if not channel then
        return false
    end

    if channel.id <= 0 or channel.canSend ~= true then
        return false
    end

    if type(self) == "table" and type(self.sayOnChannel) == "function" then
        local ok, result = pcall(self.sayOnChannel, message, channel.id)
        return ok and result == true
    end

    if type(Game) == "table" and type(Game.TalkOnChannel) == "function" then
        local ok, result = pcall(Game.TalkOnChannel, message, channel.id)
        return ok and result == true
    end

    return false
end

--- Returns channels lookup table by lowercase name.
---@return table
function ChatChannelStorage.ToNameLookupTable()
    local out = {}
    local channels = ChatChannelStorage.GetOpenedChannels()

    for i = 1, #channels do
        out[to_lower_safe(channels[i].name)] = channels[i]
    end

    return out
end

--- Returns channels lookup table by id.
---@return table
function ChatChannelStorage.ToIdLookupTable()
    local out = {}
    local channels = ChatChannelStorage.GetOpenedChannels()

    for i = 1, #channels do
        out[channels[i].id] = channels[i]
    end

    return out
end

--- Returns a snapshot with common channel-storage data.
---@return table
function ChatChannelStorage.GetSnapshot()
    local opened = ChatChannelStorage.GetOpenedChannels()
    local sendable = ChatChannelStorage.GetChatChannels()
    local localChannel = ChatChannelStorage.GetLocalChatChannel()
    local serverLog = ChatChannelStorage.GetServerLogChannel()

    return {
        available = ChatChannelStorage.IsAvailable(),
        openedCount = #opened,
        chatCount = #sendable,
        openedNames = ChatChannelStorage.GetChannelNames(false),
        sendableNames = ChatChannelStorage.GetChannelNames(true),
        localChannel = localChannel,
        serverLogChannel = serverLog,
        openedChannels = opened,
        chatChannels = sendable
    }
end

--- Returns formatted text for one channel.
---@param channel table
---@return string
function ChatChannelStorage.FormatChannel(channel)
    if type(channel) ~= "table" then
        return "nil"
    end

    return to_channel_identifier_string(channel)
        .. " canSend=" .. tostring(channel.canSend)
        .. " isOpened=" .. tostring(channel.isOpened)
        .. " isLocal=" .. tostring(channel.isLocal)
        .. " isServerLog=" .. tostring(channel.isServerLog)
end

-- Aliases
ChatChannelStorage.getAll = ChatChannelStorage.GetOpenedChannels
ChatChannelStorage.getByName = ChatChannelStorage.GetChatChannelByName
ChatChannelStorage.getById = ChatChannelStorage.GetChatChannelById

ChatChannelStorage.GetOpenedChannels = ChatChannelStorage.GetOpenedChannels
ChatChannelStorage.GetChatChannels = ChatChannelStorage.GetChatChannels
ChatChannelStorage.GetLocalChatChannel = ChatChannelStorage.GetLocalChatChannel
ChatChannelStorage.GetServerLogChannel = ChatChannelStorage.GetServerLogChannel
ChatChannelStorage.GetChatChannelByName = ChatChannelStorage.GetChatChannelByName
ChatChannelStorage.GetChatChannelById = ChatChannelStorage.GetChatChannelById
ChatChannelStorage.HasChannelByName = ChatChannelStorage.HasChannelByName
ChatChannelStorage.HasChannelById = ChatChannelStorage.HasChannelById
ChatChannelStorage.GetOpenedChannelCount = ChatChannelStorage.GetOpenedChannelCount
ChatChannelStorage.GetChatChannelCount = ChatChannelStorage.GetChatChannelCount
ChatChannelStorage.GetChannelNames = ChatChannelStorage.GetChannelNames
ChatChannelStorage.CanSend = ChatChannelStorage.CanSend
ChatChannelStorage.ResolveChannel = ChatChannelStorage.ResolveChannel
ChatChannelStorage.Send = ChatChannelStorage.Send
ChatChannelStorage.ToNameLookupTable = ChatChannelStorage.ToNameLookupTable
ChatChannelStorage.ToIdLookupTable = ChatChannelStorage.ToIdLookupTable
ChatChannelStorage.GetSnapshot = ChatChannelStorage.GetSnapshot
ChatChannelStorage.FormatChannel = ChatChannelStorage.FormatChannel

if type(ChatChannels) ~= "table" then
    ChatChannels = {}
end

if type(ChatChannels.GetOpenedChannels) ~= "function" then
    ChatChannels.GetOpenedChannels = ChatChannelStorage.GetOpenedChannels
end

if type(ChatChannels.GetChatChannels) ~= "function" then
    ChatChannels.GetChatChannels = ChatChannelStorage.GetChatChannels
end

if type(ChatChannels.GetChatChannelByName) ~= "function" then
    ChatChannels.GetChatChannelByName = ChatChannelStorage.GetChatChannelByName
end

if type(ChatChannels.GetChatChannelById) ~= "function" then
    ChatChannels.GetChatChannelById = ChatChannelStorage.GetChatChannelById
end

if type(ChatChannels.Send) ~= "function" then
    ChatChannels.Send = ChatChannelStorage.Send
end

return ChatChannelStorage




