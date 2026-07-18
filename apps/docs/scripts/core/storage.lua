-- Persistent per-script storage helpers.
-- Values are stored by the native Storage API in a managed JSON file.

Storage = Storage or {}

local nativeGet = assert(Storage.Get, "Storage.Get native binding is unavailable")
local nativeSet = assert(Storage.Set, "Storage.Set native binding is unavailable")
local nativeRemove = assert(Storage.Remove, "Storage.Remove native binding is unavailable")
local nativeClear = assert(Storage.Clear, "Storage.Clear native binding is unavailable")
local nativeGetForCharacter = assert(Storage.GetForCharacter, "Storage.GetForCharacter native binding is unavailable")
local nativeSetForCharacter = assert(Storage.SetForCharacter, "Storage.SetForCharacter native binding is unavailable")
local nativeRemoveForCharacter = assert(Storage.RemoveForCharacter, "Storage.RemoveForCharacter native binding is unavailable")
local nativeClearForCharacter = assert(Storage.ClearForCharacter, "Storage.ClearForCharacter native binding is unavailable")

---@class StorageScope
---@field _prefix string
---@field _perCharacter boolean
local StorageScope = {}
StorageScope.__index = StorageScope

local function validateNamespace(namespace)
    if type(namespace) ~= "string" or namespace == "" then
        error("Storage.Namespace: namespace must be a non-empty string", 3)
    end
    if #namespace > 64 then
        error("Storage.Namespace: namespace cannot exceed 64 bytes", 3)
    end
    if not string.match(namespace, "^[%w_.%-]+$") then
        error("Storage.Namespace: namespace may contain only letters, numbers, '_', '-', and '.'", 3)
    end
end

local function scopedKey(scope, key)
    if type(key) ~= "string" or key == "" then
        error("Storage scope key must be a non-empty string", 3)
    end

    local fullKey = scope._prefix .. key
    if #fullKey > 256 then
        error("Storage scope key cannot exceed 256 bytes including its namespace", 3)
    end
    return fullKey
end

--- Reads a value from this logical namespace.
---@param key string
---@param default? any
---@return any
function StorageScope:Get(key, default)
    local fullKey = scopedKey(self, key)
    if self._perCharacter then
        return nativeGetForCharacter(fullKey, default)
    end
    return nativeGet(fullKey, default)
end

--- Stores a value in this logical namespace.
--- Supported values are nil, booleans, finite numbers, strings, and nested tables.
---@param key string
---@param value any
---@return boolean
function StorageScope:Set(key, value)
    local fullKey = scopedKey(self, key)
    if self._perCharacter then
        return nativeSetForCharacter(fullKey, value)
    end
    return nativeSet(fullKey, value)
end

--- Removes a value from this logical namespace.
---@param key string
---@return boolean
function StorageScope:Remove(key)
    local fullKey = scopedKey(self, key)
    if self._perCharacter then
        return nativeRemoveForCharacter(fullKey)
    end
    return nativeRemove(fullKey)
end

--- Creates a logical namespace inside the current script's managed storage file.
--- Set perCharacter to true to isolate its values by logged-in character name.
---@param namespace string
---@param perCharacter? boolean
---@return StorageScope
function Storage.Namespace(namespace, perCharacter)
    validateNamespace(namespace)
    return setmetatable({
        _prefix = namespace .. "::",
        _perCharacter = perCharacter == true
    }, StorageScope)
end

--- Creates a character-scoped logical namespace.
---@param namespace string
---@return StorageScope
function Storage.ForCharacter(namespace)
    return Storage.Namespace(namespace, true)
end

--- Direct helpers for values shared by every character running this script.
Storage.Global = {
    Get = nativeGet,
    Set = nativeSet,
    Remove = nativeRemove,
    Clear = nativeClear
}

--- Direct helpers for values isolated by the current character name.
Storage.Character = {
    Get = nativeGetForCharacter,
    Set = nativeSetForCharacter,
    Remove = nativeRemoveForCharacter,
    Clear = nativeClearForCharacter
}

Core = Core or {}
Core.Storage = Storage
