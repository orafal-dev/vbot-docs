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
local nativeSharedGet = assert(Storage._SharedGet, "Storage shared-get native binding is unavailable")
local nativeSharedSet = assert(Storage._SharedSet, "Storage shared-set native binding is unavailable")
local nativeSharedClear = assert(Storage._SharedClear, "Storage shared-clear native binding is unavailable")
local nativeSharedGetVersioned = assert(Storage._SharedGetVersioned, "Storage shared-version native binding is unavailable")
local nativeSharedCompareExchange = assert(Storage._SharedCompareExchange, "Storage shared-CAS native binding is unavailable")
local nativeSharedSubscribe = assert(Storage._SharedSubscribe, "Storage shared-subscribe native binding is unavailable")
local nativeSharedUnsubscribe = assert(Storage._SharedUnsubscribe, "Storage shared-unsubscribe native binding is unavailable")

-- Keep the low-level revision API private. Public callers use the bounded,
-- optimistic SharedStorageScope:Update wrapper below.
Storage._SharedGet = nil
Storage._SharedSet = nil
Storage._SharedClear = nil
Storage._SharedGetVersioned = nil
Storage._SharedCompareExchange = nil
Storage._SharedSubscribe = nil
Storage._SharedUnsubscribe = nil

local SHARED_UPDATE_MAX_RETRIES = 8

---@class StorageScope
---@field _prefix string
---@field _perCharacter boolean
local StorageScope = {}
StorageScope.__index = StorageScope

---@class SharedStorageScope
---@field _namespace string
---@field _perCharacter boolean
local SharedStorageScope = {}
SharedStorageScope.__index = SharedStorageScope

---@class SharedStorageChangeWriter
---@field id string Stable only for this injected bot process
---@field name string Script filename, "walker", or "one-shot code"
---@field type "script"|"walker"|"one_shot"|"unknown"

---@class SharedStorageChangeEvent
---@field namespace string
---@field operation "set"|"remove"|"clear"
---@field scope "global"|"character"
---@field revision integer
---@field timestampUnixMs integer
---@field writer SharedStorageChangeWriter
---@field character? string
---@field key? string
---@field previousExists boolean
---@field newExists boolean
---@field previousValueIncluded boolean
---@field newValueIncluded boolean
---@field previousValue? any
---@field newValue? any
---@field changedCount? integer
---@field changedKeys? string[]
---@field changedKeysTruncated? boolean
---@field valueOmissionReason? string

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

local function sharedKey(key)
    if type(key) ~= "string" or key == "" then
        error("Shared storage key must be a non-empty string", 3)
    end
    if #key > 256 then
        error("Shared storage key cannot exceed 256 bytes", 3)
    end
    if string.find(key, "\0", 1, true) then
        error("Shared storage key cannot contain NUL bytes", 3)
    end
    return key
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

--- Opens a persistent namespace shared by every Lua script and character.
--- The namespace is an opt-in coordination boundary, not a security boundary.
---@param namespace string
---@return SharedStorageScope
function Storage.Shared(namespace)
    validateNamespace(namespace)
    return setmetatable({
        _namespace = namespace,
        _perCharacter = false
    }, SharedStorageScope)
end

--- Opens a persistent namespace shared by every Lua script for this character.
---@param namespace string
---@return SharedStorageScope
function Storage.SharedForCharacter(namespace)
    validateNamespace(namespace)
    return setmetatable({
        _namespace = namespace,
        _perCharacter = true
    }, SharedStorageScope)
end

--- Reads a value from this named shared namespace.
--- The second return value is nil on success or an I/O/validation error string.
---@param key string
---@param default? any
---@return any value
---@return string|nil errorMessage
function SharedStorageScope:Get(key, default)
    return nativeSharedGet(
        self._namespace,
        sharedKey(key),
        default,
        self._perCharacter)
end

--- Stores a value in this named shared namespace.
--- Passing nil removes the key.
---@param key string
---@param value any
---@return boolean success
---@return string|nil errorMessage
function SharedStorageScope:Set(key, value)
    return nativeSharedSet(
        self._namespace,
        sharedKey(key),
        value,
        self._perCharacter)
end

--- Removes a value from this named shared namespace.
---@param key string
---@return boolean success
---@return string|nil errorMessage
function SharedStorageScope:Remove(key)
    return nativeSharedSet(
        self._namespace,
        sharedKey(key),
        nil,
        self._perCharacter)
end

--- Clears only this scope. Character scopes never clear global or other-character data.
---@return boolean success
---@return string|nil errorMessage
function SharedStorageScope:Clear()
    return nativeSharedClear(self._namespace, self._perCharacter)
end

--- Atomically updates one shared key with bounded optimistic retries.
--- The updater may run more than once after a concurrent write, so it should
--- avoid side effects and should only calculate and return the replacement value.
--- If default is a table, do not mutate it in place; return a new table instead.
--- Returning nil removes the key. No native or filesystem lock is held while
--- the updater runs, so yielding or throwing cannot deadlock shared storage.
---@param key string
---@param updater function
---@param default? any
---@return boolean success
---@return any newValue
---@return string|nil errorMessage
function SharedStorageScope:Update(key, updater, default)
    key = sharedKey(key)
    if type(updater) ~= "function" then
        error("SharedStorageScope.Update: updater must be a function", 2)
    end

    for _ = 1, SHARED_UPDATE_MAX_RETRIES do
        local currentValue, revision, found, readError = nativeSharedGetVersioned(
            self._namespace,
            key,
            self._perCharacter)
        if readError ~= nil then
            return false, nil, readError
        end
        if not found then
            currentValue = default
        end

        local nextValue = updater(currentValue)
        local exchanged, _, writeError = nativeSharedCompareExchange(
            self._namespace,
            key,
            revision,
            nextValue,
            self._perCharacter)
        if exchanged then
            return true, nextValue, nil
        end
        if writeError ~= "conflict" then
            return false, nil, writeError or "shared storage update failed"
        end
    end

    return false, nil, "shared storage update remained contended after 8 attempts"
end

--- Registers an owner-scoped callback for changes committed by another script.
--- Pass key to observe one field or nil to observe this entire scope.
--- includeSelf defaults to false. The callback receives one event table.
---@param callback function
---@param key? string
---@param includeSelf? boolean
---@return string|nil subscriptionId
---@return string|nil errorMessage
function SharedStorageScope:OnChanged(callback, key, includeSelf)
    if type(callback) ~= "function" then
        error("SharedStorageScope.OnChanged: callback must be a function", 2)
    end
    if key ~= nil then
        key = sharedKey(key)
    end
    if includeSelf ~= nil and type(includeSelf) ~= "boolean" then
        error("SharedStorageScope.OnChanged: includeSelf must be a boolean or nil", 2)
    end

    local function dispatchEncodedEvent(encodedEvent)
        local event, decodeError = Json.TryDecode(encodedEvent)
        if event == nil then
            error("Shared storage event decode failed: " .. tostring(decodeError), 0)
        end
        callback(event)
    end

    return nativeSharedSubscribe(
        self._namespace,
        key,
        self._perCharacter,
        includeSelf == true,
        dispatchEncodedEvent)
end

--- Removes a shared-storage change subscription owned by this script.
---@param subscriptionId string
---@return boolean success
---@return string|nil errorMessage
function SharedStorageScope:OffChanged(subscriptionId)
    if type(subscriptionId) ~= "string" or subscriptionId == "" then
        error("SharedStorageScope.OffChanged: subscriptionId must be a non-empty string", 2)
    end
    return nativeSharedUnsubscribe(subscriptionId)
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
