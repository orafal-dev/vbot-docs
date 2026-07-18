-- Coroutine-friendly HTTP and HTTPS helpers backed by an isolated WinHTTP client.

Http = assert(Http, "Http native binding is unavailable")

local nativeRequest = assert(Http.Request, "Http.Request native binding is unavailable")

local function copyOptions(options)
    local copy = {}
    if options ~= nil then
        if type(options) ~= "table" then
            error("HTTP options must be a table", 3)
        end
        for key, value in pairs(options) do
            copy[key] = value
        end
    end
    return copy
end

local function hasHeader(headers, wanted)
    if type(headers) ~= "table" then
        return false
    end
    wanted = string.lower(wanted)
    for name in pairs(headers) do
        if type(name) == "string" and string.lower(name) == wanted then
            return true
        end
    end
    return false
end

local function copyHeaders(headers)
    if headers == nil then
        return {}
    end
    if type(headers) ~= "table" then
        error("HTTP headers must be a table", 3)
    end
    local copy = {}
    for name, value in pairs(headers) do
        copy[name] = value
    end
    return copy
end

--- Performs an HTTP request. Must be called from a managed coroutine.
---@param options table
---@return table
function Http.Request(options)
    if type(options) ~= "table" then
        error("Http.Request: options must be a table", 2)
    end
    return nativeRequest(options)
end

---@param url string
---@param options? table
---@return table
function Http.Get(url, options)
    local request = copyOptions(options)
    request.url = url
    request.method = "GET"
    return nativeRequest(request)
end

---@param url string
---@param body? string
---@param options? table
---@return table
function Http.Post(url, body, options)
    local request = copyOptions(options)
    request.url = url
    request.method = "POST"
    request.body = body or ""
    return nativeRequest(request)
end

--- Fetches and decodes a JSON response. Returns data and the full response.
---@param url string
---@param options? table
---@return any|nil, table, string|nil
function Http.GetJson(url, options)
    local response = Http.Get(url, options)
    if not response.ok then
        return nil, response, response.error ~= "" and response.error or ("HTTP " .. tostring(response.status))
    end
    local value, decodeError = Json.TryDecode(response.body)
    return value, response, decodeError
end

--- Encodes a value as JSON and posts it. Content-Type defaults to application/json.
---@param url string
---@param value any
---@param options? table
---@return table
function Http.PostJson(url, value, options)
    local request = copyOptions(options)
    request.url = url
    request.method = "POST"
    request.body = Json.Encode(value)
    -- Do not mutate the caller's options.headers table when adding defaults.
    request.headers = copyHeaders(request.headers)
    if not hasHeader(request.headers, "content-type") then
        request.headers["Content-Type"] = "application/json"
    end
    if not hasHeader(request.headers, "accept") then
        request.headers["Accept"] = "application/json"
    end
    return nativeRequest(request)
end

Core = Core or {}
Core.Http = Http
