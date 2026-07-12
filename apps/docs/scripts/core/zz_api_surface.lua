local function starts_with(value, prefix)
    return string.sub(value, 1, #prefix) == prefix
end

local function to_pascal(name)
    if type(name) ~= "string" or name == "" then
        return name
    end

    return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end

local function classify_api_bucket(functionName)
    local lowered = string.lower(functionName)

    if starts_with(lowered, "get") or starts_with(lowered, "is") or starts_with(lowered, "has") or starts_with(lowered, "can") or starts_with(lowered, "find") or starts_with(lowered, "list") or starts_with(lowered, "resolve") then
        return "query"
    end

    return "actions"
end

local function add_function_bucket(moduleTable, functionName, fn)
    local bucket = classify_api_bucket(functionName)
    local pascalName = to_pascal(functionName)

    if bucket == "query" then
        bucket = "Query"
    else
        bucket = "Actions"
    end

    moduleTable[bucket] = moduleTable[bucket] or {}

    if moduleTable[bucket][pascalName] == nil then
        moduleTable[bucket][pascalName] = fn
    end

    if moduleTable[pascalName] == nil then
        moduleTable[pascalName] = fn
    end
end

local function normalize_module(moduleTable)
    if type(moduleTable) ~= "table" then
        return
    end

    for key, value in pairs(moduleTable) do
        if type(key) == "string" and type(value) == "function" and key ~= "New" then
            add_function_bucket(moduleTable, key, value)
        end
    end
end

local function build_public_module(sourceTable, Seen)
    if type(sourceTable) ~= "table" then
        return sourceTable
    end

    Seen = Seen or {}
    if Seen[sourceTable] ~= nil then
        return Seen[sourceTable]
    end

    local public = {}
    Seen[sourceTable] = public

    for key, value in pairs(sourceTable) do
        if type(key) == "string" then
            local outKey = to_pascal(key)
            local outValue

            if type(value) == "function" then
                outValue = value
            elseif type(value) == "table" then
                outValue = build_public_module(value, Seen)
            else
                outValue = value
            end

            if public[outKey] == nil then
                public[outKey] = outValue
            end
        elseif type(key) == "number" then
            public[key] = value
        end
    end

    normalize_module(public)
    return public
end

local function export_public(aliasName, sourceName)
    local sourceModule = _G[sourceName]

    if type(sourceModule) ~= "table" then
        local pascalSourceName = to_pascal(sourceName)
        sourceModule = _G[pascalSourceName]
    end

    if type(sourceModule) ~= "table" then
        return
    end

    local publicModule = build_public_module(sourceModule)

    _G[aliasName] = publicModule
end

Core = Core or {}

local moduleAliases = {
    { alias = "Self", source = "self" },
    { alias = "Container", source = "container" },
    { alias = "Item", source = "item" },
    { alias = "Map", source = "map" },
    { alias = "Position", source = "position" },
    { alias = "Spells", source = "spells" },
    { alias = "Cavebot", source = "cavebot" },
    { alias = "Game", source = "game" },
    { alias = "Hotkeys", source = "hotkeys" },
    { alias = "Module", source = "module" },
    { alias = "Engine", source = "engine" },
    { alias = "Creature", source = "creature" },
    { alias = "Creatures", source = "creatures" },
    { alias = "VIP", source = "vip" },
    { alias = "ChatChannel", source = "chatChannel" },
    { alias = "ChatChannelStorage", source = "chatChannelStorage" },
    { alias = "Inventory", source = "inventory" },
    { alias = "Minimap", source = "minimap" },
    { alias = "NpcTradeStorage", source = "npcTradeStorage" }
}

for i = 1, #moduleAliases do
    local mapping = moduleAliases[i]
    export_public(mapping.alias, mapping.source)

    if type(_G[mapping.alias]) == "table" and Core[mapping.alias] == nil then
        Core[mapping.alias] = _G[mapping.alias]
    end
end




