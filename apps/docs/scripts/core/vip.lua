Vip = Vip or {}

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

local function call_method_no_args(target, methodName)
    if type(target) ~= "table" and type(target) ~= "userdata" then
        return false, nil
    end

    local okIndex, method = pcall(function()
        return target[methodName]
    end)

    if not okIndex then
        return false, nil
    end

    if type(method) ~= "function" then
        return false, nil
    end

    local ok, result = pcall(method)
    if not ok then
        ok, result = pcall(method, target)
    end

    if not ok then
        return false, nil
    end

    return true, result
end

local function try_get_any_method_value(target, methodNames)
    for i = 1, #methodNames do
        local ok, value = call_method_no_args(target, methodNames[i])
        if ok then
            return true, value
        end
    end

    return false, nil
end

local function try_get_any_field_value(target, fieldNames)
    if type(target) ~= "table" and type(target) ~= "userdata" then
        return false, nil
    end

    for i = 1, #fieldNames do
        local ok, value = pcall(function()
            return target[fieldNames[i]]
        end)

        if not ok then
            value = nil
        end

        if value ~= nil and type(value) ~= "function" then
            return true, value
        end
    end

    return false, nil
end

local function resolve_backend_table()
    local candidates = {
        "VIPStorage",
        "VipStorage",
        "Vip",
        "Vip",
        "Game"
    }

    local listMethodNames = {
        "GetVIPs",
        "GetVips",
        "GetVipList",
        "GetVIPList"
    }

    local byNameMethodNames = {
        "GetVIP",
        "GetVip",
        "GetVIPByName",
        "GetVipByName"
    }

    for i = 1, #candidates do
        local globalName = candidates[i]
        local candidate = rawget(_G, globalName)

        if type(candidate) == "table" and candidate ~= Vip then
            for j = 1, #listMethodNames do
                if type(candidate[listMethodNames[j]]) == "function" then
                    return candidate
                end
            end

            for j = 1, #byNameMethodNames do
                if type(candidate[byNameMethodNames[j]]) == "function" then
                    return candidate
                end
            end
        end
    end

    return nil
end

local function get_raw_vip_list()
    local backend = resolve_backend_table()
    if not backend then
        return {}
    end

    local listMethodNames = {
        "GetVIPs",
        "GetVips",
        "GetVipList",
        "GetVIPList"
    }

    for i = 1, #listMethodNames do
        local methodName = listMethodNames[i]
        local method = backend[methodName]
        if type(method) == "function" then
            local ok, result = pcall(method)
            if not ok then
                ok, result = pcall(method, backend)
            end

            if ok and type(result) == "table" then
                return result
            end
        end
    end

    return {}
end

local function get_raw_vip_by_name(name)
    local backend = resolve_backend_table()
    if not backend then
        return nil
    end

    local byNameMethodNames = {
        "GetVIP",
        "GetVip",
        "GetVIPByName",
        "GetVipByName"
    }

    for i = 1, #byNameMethodNames do
        local methodName = byNameMethodNames[i]
        local method = backend[methodName]
        if type(method) == "function" then
            local ok, result = pcall(method, name)
            if not ok then
                ok, result = pcall(method, backend, name)
            end

            if ok and result ~= nil then
                return result
            end
        end
    end

    return nil
end

local function normalize_vip_entry(rawVip)
    if rawVip == nil then
        return nil
    end

    local hasName, name = try_get_any_method_value(rawVip, {
        "GetVipName",
        "GetName"
    })

    if not hasName then
        hasName, name = try_get_any_field_value(rawVip, {
            "vipName",
            "name",
            "Name"
        })
    end

    if type(name) ~= "string" or name == "" then
        return nil
    end

    local hasDescription, description = try_get_any_method_value(rawVip, {
        "GetVipDescription",
        "GetDescription"
    })

    if not hasDescription then
        hasDescription, description = try_get_any_field_value(rawVip, {
            "vipDescription",
            "description",
            "Description"
        })
    end

    if type(description) ~= "string" then
        description = ""
    end

    local hasType, vipType = try_get_any_method_value(rawVip, {
        "GetVipType",
        "GetType"
    })

    if not hasType then
        hasType, vipType = try_get_any_field_value(rawVip, {
            "vipType",
            "type",
            "Type"
        })
    end

    if type(vipType) ~= "number" then
        vipType = (type(VipFlag) == "table" and type(VipFlag.NO_FLAG) == "number") and VipFlag.NO_FLAG or 0
    end

    local hasOnline, isOnline = try_get_any_method_value(rawVip, {
        "IsVipOnline",
        "IsOnline"
    })

    if not hasOnline then
        hasOnline, isOnline = try_get_any_field_value(rawVip, {
            "isOnline",
            "online",
            "IsOnline"
        })
    end

    local hasNotify, notifyOnLogin = try_get_any_method_value(rawVip, {
        "IsNotifyOnLoginEnabled",
        "GetNotifyOnLogin"
    })

    if not hasNotify then
        hasNotify, notifyOnLogin = try_get_any_field_value(rawVip, {
            "notifyOnLogin",
            "notify",
            "NotifyOnLogin"
        })
    end

    return {
        name = name,
        description = description,
        type = vipType,
        online = isOnline == true,
        notifyOnLogin = notifyOnLogin == true,
        raw = rawVip
    }
end

local function normalize_vip_list(rawList)
    local out = {}
    local seen = {}

    if type(rawList) ~= "table" then
        return out
    end

    for _, rawVip in pairs(rawList) do
        local Vip = normalize_vip_entry(rawVip)
        if Vip ~= nil then
            local normalizedName = to_lower_safe(Vip.name)
            if normalizedName ~= "" and not seen[normalizedName] then
                seen[normalizedName] = true
                out[#out + 1] = Vip
            end
        end
    end

    return out
end

local function get_heart_flag_value()
    if type(VipFlag) == "table" and type(VipFlag.HEART) == "number" then
        return VipFlag.HEART
    end

    return 1
end

local function sort_vips_by_name(vips)
    table.sort(vips, function(a, b)
        return to_lower_safe(a.name) < to_lower_safe(b.name)
    end)
end

--- Returns whether a direct Vip backend is currently exposed to Lua.
---@return boolean
function Vip.IsAvailable()
    return resolve_backend_table() ~= nil
end

--- Returns all Vip entries from runtime storage.
---@return table[]
function Vip.GetAll()
    local vips = normalize_vip_list(get_raw_vip_list())
    sort_vips_by_name(vips)
    return vips
end

--- Returns one Vip entry by exact name.
---@param vipName string
---@return table|nil
function Vip.Get(vipName)
    validate_non_empty_string(vipName, "vipName", "Vip.Get")

    local rawVip = get_raw_vip_by_name(vipName)
    local normalized = normalize_vip_entry(rawVip)
    if normalized ~= nil then
        return normalized
    end

    local normalizedQuery = to_lower_safe(vipName)
    local vips = Vip.GetAll()

    for i = 1, #vips do
        if to_lower_safe(vips[i].name) == normalizedQuery then
            return vips[i]
        end
    end

    return nil
end

--- Returns true if Vip entry exists by name.
---@param vipName string
---@return boolean
function Vip.Exists(vipName)
    return Vip.Get(vipName) ~= nil
end

--- Returns Vip count.
---@return integer
function Vip.Count()
    return #Vip.GetAll()
end

--- Returns count of online Vip entries.
---@return integer
function Vip.CountOnline()
    local count = 0
    local vips = Vip.GetAll()

    for i = 1, #vips do
        if vips[i].online then
            count = count + 1
        end
    end

    return count
end

--- Returns true when the given Vip is currently online.
---@param vipName string
---@return boolean
function Vip.IsOnline(vipName)
    local Vip = Vip.Get(vipName)
    return Vip ~= nil and Vip.online == true
end

--- Returns Vip type flag by name.
---@param vipName string
---@return integer|nil
function Vip.GetType(vipName)
    local Vip = Vip.Get(vipName)
    return Vip and Vip.type or nil
end

--- Returns Vip description by name.
---@param vipName string
---@return string|nil
function Vip.GetDescription(vipName)
    local Vip = Vip.Get(vipName)
    return Vip and Vip.description or nil
end

--- Returns notify-on-login status by name.
---@param vipName string
---@return boolean|nil
function Vip.GetNotifyOnLogin(vipName)
    local Vip = Vip.Get(vipName)
    if Vip == nil then
        return nil
    end

    return Vip.notifyOnLogin == true
end

--- Returns all Vip names sorted alphabetically.
---@param onlyOnline? boolean
---@return string[]
function Vip.GetNames(onlyOnline)
    local names = {}
    local vips = Vip.GetAll()
    local filterOnline = onlyOnline == true

    for i = 1, #vips do
        if (not filterOnline) or vips[i].online then
            names[#names + 1] = vips[i].name
        end
    end

    return names
end

--- Returns all Vip entries with a specific Vip type flag.
---@param vipType integer
---@return table[]
function Vip.GetByType(vipType)
    validate_non_negative_integer(vipType, "vipType", "Vip.GetByType")

    local out = {}
    local vips = Vip.GetAll()

    for i = 1, #vips do
        if vips[i].type == vipType then
            out[#out + 1] = vips[i]
        end
    end

    return out
end

--- Returns all Vip entries with HEART flag.
---@return table[]
function Vip.GetHearts()
    return Vip.GetByType(get_heart_flag_value())
end

--- Returns true when Vip has HEART flag.
---@param vipName string
---@return boolean
function Vip.IsHeart(vipName)
    local Vip = Vip.Get(vipName)
    if not Vip then
        return false
    end

    return Vip.type == get_heart_flag_value()
end

--- Finds Vip entries by case-insensitive name prefix.
---@param namePrefix string
---@param onlyOnline? boolean
---@return table[]
function Vip.FindByPrefix(namePrefix, onlyOnline)
    validate_non_empty_string(namePrefix, "namePrefix", "Vip.FindByPrefix")

    local out = {}
    local normalizedPrefix = to_lower_safe(namePrefix)
    local filterOnline = onlyOnline == true
    local vips = Vip.GetAll()

    for i = 1, #vips do
        local Vip = vips[i]
        if ((not filterOnline) or Vip.online) and string.sub(to_lower_safe(Vip.name), 1, #normalizedPrefix) == normalizedPrefix then
            out[#out + 1] = Vip
        end
    end

    return out
end

--- Returns a quick lookup table indexed by lowercase Vip name.
---@return table
function Vip.ToLookupTable()
    local out = {}
    local vips = Vip.GetAll()

    for i = 1, #vips do
        local Vip = vips[i]
        out[to_lower_safe(Vip.name)] = Vip
    end

    return out
end

--- Returns a snapshot table with common Vip stats and lists.
---@return table
function Vip.GetSnapshot()
    local all = Vip.GetAll()
    local hearts = Vip.GetHearts()

    return {
        available = Vip.IsAvailable(),
        count = #all,
        onlineCount = Vip.CountOnline(),
        heartCount = #hearts,
        names = Vip.GetNames(false),
        onlineNames = Vip.GetNames(true),
        vips = all
    }
end

Vip.Storage = Vip.Storage or {}

Vip.Storage.GetVIPs = Vip.GetAll
Vip.Storage.GetVIP = Vip.Get
Vip.Storage.HasVIP = Vip.Exists
Vip.Storage.GetVIPCount = Vip.Count
Vip.Storage.GetOnlineVIPCount = Vip.CountOnline

Vip.getVIPs = Vip.GetAll
Vip.getVIP = Vip.Get
Vip.hasVIP = Vip.Exists

if type(VIPStorage) ~= "table" then
    VIPStorage = {}
end

if type(VIPStorage.GetVIPs) ~= "function" then
    VIPStorage.GetVIPs = Vip.GetAll
end

if type(VIPStorage.GetVIP) ~= "function" then
    VIPStorage.GetVIP = Vip.Get
end

if type(VIPStorage.HasVIP) ~= "function" then
    VIPStorage.HasVIP = Vip.Exists
end

if type(VIPStorage.GetVIPCount) ~= "function" then
    VIPStorage.GetVIPCount = Vip.Count
end

if type(VIPStorage.GetOnlineVIPCount) ~= "function" then
    VIPStorage.GetOnlineVIPCount = Vip.CountOnline
end

if type(VipStorage) ~= "table" then
    VipStorage = {}
end

if type(VipStorage.GetVIPs) ~= "function" then
    VipStorage.GetVIPs = Vip.GetAll
end

if type(VipStorage.GetVIP) ~= "function" then
    VipStorage.GetVIP = Vip.Get
end

if type(VipStorage.HasVIP) ~= "function" then
    VipStorage.HasVIP = Vip.Exists
end

if type(VipStorage.GetVIPCount) ~= "function" then
    VipStorage.GetVIPCount = Vip.Count
end

if type(VipStorage.GetOnlineVIPCount) ~= "function" then
    VipStorage.GetOnlineVIPCount = Vip.CountOnline
end

-- Compatibility aliases (lower camel-case)
Vip.GetAll = Vip.GetAll
Vip.Get = Vip.Get
Vip.Exists = Vip.Exists
Vip.Count = Vip.Count
Vip.CountOnline = Vip.CountOnline
Vip.IsOnline = Vip.IsOnline
Vip.GetType = Vip.GetType
Vip.GetDescription = Vip.GetDescription
Vip.GetNotifyOnLogin = Vip.GetNotifyOnLogin
Vip.GetNames = Vip.GetNames
Vip.GetByType = Vip.GetByType
Vip.GetHearts = Vip.GetHearts
Vip.IsHeart = Vip.IsHeart
Vip.FindByPrefix = Vip.FindByPrefix
Vip.ToLookupTable = Vip.ToLookupTable
Vip.GetSnapshot = Vip.GetSnapshot

return Vip




