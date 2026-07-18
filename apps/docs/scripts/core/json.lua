-- Safe native-backed JSON helpers.

Json = assert(Json, "Json native binding is unavailable")

local nativeEncode = assert(Json.Encode, "Json.Encode native binding is unavailable")
local nativeDecode = assert(Json.Decode, "Json.Decode native binding is unavailable")

--- Encodes a Lua value as JSON. Raises an error for unsupported or oversized values.
---@param value any
---@param pretty? boolean|integer
---@return string
function Json.Encode(value, pretty)
    return nativeEncode(value, pretty)
end

--- Decodes JSON while preserving null as Json.Null and collection types for round trips.
---@param text string
---@return any
function Json.Decode(text)
    return nativeDecode(text)
end

--- Attempts to encode a value without raising an error.
---@param value any
---@param pretty? boolean|integer
---@return string|nil, string|nil
function Json.TryEncode(value, pretty)
    local ok, result = pcall(nativeEncode, value, pretty)
    if ok then
        return result, nil
    end
    return nil, tostring(result)
end

--- Attempts to decode JSON without raising an error.
---@param text string
---@return any|nil, string|nil
function Json.TryDecode(text)
    local ok, result = pcall(nativeDecode, text)
    if ok then
        return result, nil
    end
    return nil, tostring(result)
end

Core = Core or {}
Core.Json = Json
