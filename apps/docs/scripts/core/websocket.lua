-- Independent ws:// and wss:// connections for Lua scripts.

WebSocket = assert(WebSocket, "WebSocket native binding is unavailable")

local nativeConnect = assert(WebSocket.Connect, "WebSocket.Connect native binding is unavailable")
local nativeSend = assert(WebSocket.Send, "WebSocket.Send native binding is unavailable")
local nativeReceive = assert(WebSocket.Receive, "WebSocket.Receive native binding is unavailable")
local nativeClose = assert(WebSocket.Close, "WebSocket.Close native binding is unavailable")
local nativeIsOpen = assert(WebSocket.IsOpen, "WebSocket.IsOpen native binding is unavailable")

-- Only the connection object API is public. Keeping the id-based native
-- operations reachable would let scripts operate on ids without ownership
-- and lifetime state carried by a Connection object.
WebSocket.Send = nil
WebSocket.Receive = nil
WebSocket.Close = nil
WebSocket.IsOpen = nil

local Connection = {}
Connection.__index = Connection
Connection.__metatable = "Validus.WebSocketConnection"

---@param data string
---@param binary? boolean
---@return boolean, string|nil
function Connection:Send(data, binary)
    return nativeSend(self._connectionId, data, binary == true)
end

--- Waits for text, binary, close, error, or timeout event data.
---@param timeoutMs? integer
---@return table
function Connection:Receive(timeoutMs)
    return nativeReceive(self._connectionId, timeoutMs or 30000)
end

---@param closeCode? integer
---@param reason? string
---@return boolean, string|nil
function Connection:Close(closeCode, reason)
    return nativeClose(self._connectionId, closeCode or 1000, reason or "")
end

---@return boolean
function Connection:IsOpen()
    return nativeIsOpen(self._connectionId)
end

Connection.__gc = function(self)
    if type(self) == "table" and self._connectionId ~= nil and nativeIsOpen(self._connectionId) then
        nativeClose(self._connectionId, 1000, "Lua WebSocket released")
    end
end

--- Opens an independent WebSocket connection. Must be called from a managed coroutine.
---@param url string
---@param options? table
---@return table|nil, string|nil
function WebSocket.Connect(url, options)
    if type(url) ~= "string" or url == "" then
        error("WebSocket.Connect: url must be a non-empty string", 2)
    end
    local request = {}
    if options ~= nil then
        if type(options) ~= "table" then
            error("WebSocket.Connect: options must be a table", 2)
        end
        for key, value in pairs(options) do
            request[key] = value
        end
    end
    request.url = url
    local result = nativeConnect(request)
    if not result.ok then
        return nil, result.error
    end
    return setmetatable({
        _connectionId = result.connectionId,
        url = result.url
    }, Connection), nil
end

Core = Core or {}
Core.WebSocket = WebSocket
