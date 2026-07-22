Hotkeys = Hotkeys or {}

local key_map = {
    enter = 0x0D,
    space = 0x20,
    tab = 0x09,
    escape = 0x1B,
    backspace = 0x08,
    up = 0x26,
    down = 0x28,
    left = 0x25,
    right = 0x27,
    insert = 0x2D,
    delete = 0x2E,
    home = 0x24,
    endkey = 0x23,
    pageup = 0x21,
    pagedown = 0x22,
    printscreen = 0x2C,
    capslock = 0x14,
    numlock = 0x90,
    scrolllock = 0x91,
    pause = 0x13,
    apps = 0x5D,
    minus = 0xBD,
    equals = 0xBB,
    comma = 0xBC,
    period = 0xBE,
    slash = 0xBF,
    semicolon = 0xBA,
    quote = 0xDE,
    leftbracket = 0xDB,
    rightbracket = 0xDD,
    backslash = 0xDC,
    grave = 0xC0,
    f1 = 0x70,
    f2 = 0x71,
    f3 = 0x72,
    f4 = 0x73,
    f5 = 0x74,
    f6 = 0x75,
    f7 = 0x76,
    f8 = 0x77,
    f9 = 0x78,
    f10 = 0x79,
    f11 = 0x7A,
    f12 = 0x7B
}

local extended_default_keys = {
    insert = true,
    delete = true,
    home = true,
    endkey = true,
    pageup = true,
    pagedown = true,
    up = true,
    down = true,
    left = true,
    right = true
}

extended_default_keys.printscreen = true
extended_default_keys.numlock = true
extended_default_keys.apps = true
extended_default_keys.numpaddivide = true

for i = 0, 9 do
    local ch = tostring(i)
    key_map[ch] = string.byte(ch)
end

for i = string.byte("a"), string.byte("z") do
    local ch = string.char(i)
    key_map[ch] = i - 32
end

for i = 0, 9 do
    key_map["numpad" .. tostring(i)] = 0x60 + i
end

key_map.numpadmultiply = 0x6A
key_map.numpadadd = 0x6B
key_map.numpadsubtract = 0x6D
key_map.numpaddecimal = 0x6E
key_map.numpaddivide = 0x6F

for i = 13, 24 do
    key_map["f" .. tostring(i)] = 0x70 + i - 1
end

local function normalize_part(part)
    local p = string.lower(part)
    if p == "pgup" then return "pageup" end
    if p == "pgdn" then return "pagedown" end
    if p == "esc" then return "escape" end
    if p == "del" then return "delete" end
    if p == "ins" then return "insert" end
    if p == "home" then return "home" end
    if p == "end" then return "endkey" end
    if p == "return" then return "enter" end
    if p == "caps" then return "capslock" end
    if p == "scroll" then return "scrolllock" end
    if p == "prtsc" or p == "print" then return "printscreen" end
    if p == "menu" then return "apps" end
    if p == "dot" then return "period" end
    return p
end

--- Parses a textual hotkey combo (for example: "ctrl+f9", "insert", "shift+k").
--- Supported modifiers: ctrl, shift, alt. Alt combinations can be sent to the
--- client, but cannot be registered as Lua callback hotkeys.
---@param combination string
---@return table|nil parsed Parsed table: {keycode, ctrl, shift, alt, trigger_on_keydown, extended}
---@return string|nil err Error message when parsing fails
function Hotkeys.ParseCombo(combination)
    if type(combination) ~= "string" or combination == "" then
        return nil, "Hotkeys.ParseCombo: combination must be a non-empty string"
    end

    local parsed = {
        keycode = nil,
        ctrl = false,
        shift = false,
        alt = false,
        trigger_on_keydown = false,
        extended = false
    }

    for raw in string.gmatch(combination, "[^%+%s]+") do
        local part = normalize_part(raw)

        if part == "ctrl" or part == "control" then
            parsed.ctrl = true
        elseif part == "shift" then
            parsed.shift = true
        elseif part == "alt" then
            parsed.alt = true
        else
            local code = key_map[part]
            if not code then
                return nil, "Hotkeys.ParseCombo: unsupported key part '" .. tostring(raw) .. "'"
            end

            if extended_default_keys[part] then
                parsed.extended = true
            end

            if parsed.keycode ~= nil then
                return nil, "Hotkeys.ParseCombo: combination must contain exactly one non-modifier key"
            end

            parsed.keycode = code
        end
    end

    if parsed.keycode == nil then
        return nil, "Hotkeys.ParseCombo: missing key in combination"
    end

    return parsed
end

local function resolve_client_only(clientOnly, functionName)
    if clientOnly == nil then
        return true
    end
    if type(clientOnly) ~= "boolean" then
        error(functionName .. ": argument 'clientOnly' must be a boolean when provided", 3)
    end
    return clientOnly
end

local function send_parsed(parsed, clientOnly, functionName)
    if type(Events) ~= "table" or type(Events._SendKeyToClient_CPP) ~= "function" then
        error(functionName .. ": native client-key sender is unavailable; update the bot DLL", 3)
    end

    return Events._SendKeyToClient_CPP(
        parsed.keycode,
        parsed.ctrl == true,
        parsed.shift == true,
        parsed.alt == true,
        parsed.extended == true,
        resolve_client_only(clientOnly, functionName)
    ) == true
end

--- Sends one key press (down then up) to this script's Tibia client window.
--- A key may be a supported name such as "f1", "delete", or "a", or a
--- Windows virtual-key integer from 1 through 255. String combinations are
--- also accepted, though SendCombo is clearer for that use.
--- clientOnly defaults to true, bypassing ImGui and ValidusBot hotkey handlers.
---@param key string|integer
---@param clientOnly? boolean When false, route through the normal client window procedure
---@return boolean queued False when the Tibia window is unavailable or the message could not be queued
function Hotkeys.SendKey(key, clientOnly)
    local parsed
    local parseErr

    if type(key) == "string" then
        parsed, parseErr = Hotkeys.ParseCombo(key)
        if not parsed then
            error(parseErr, 2)
        end
    elseif type(key) == "number" and key % 1 == 0 and key >= 1 and key <= 255 then
        parsed = {
            keycode = key,
            ctrl = false,
            shift = false,
            alt = false,
            extended = key == 0x21 or key == 0x22 or key == 0x23 or key == 0x24
                or key == 0x25 or key == 0x26 or key == 0x27 or key == 0x28
                or key == 0x2C or key == 0x2D or key == 0x2E or key == 0x5D
                or key == 0x6F or key == 0x90
        }
    else
        error("Hotkeys.SendKey: argument 'key' must be a supported key name or an integer between 1 and 255", 2)
    end

    return send_parsed(parsed, clientOnly, "Hotkeys.SendKey")
end

--- Sends a full key combination such as "ctrl+shift+f9" or "alt+f1".
--- Modifiers are pressed in order and released in reverse order. clientOnly
--- defaults to true so the combination goes to Tibia without activating ImGui,
--- Lua callback hotkeys, or ValidusBot feature hotkeys.
---@param combination string
---@param clientOnly? boolean When false, route through the normal client window procedure
---@return boolean queued False when the Tibia window is unavailable or the message could not be queued
function Hotkeys.SendCombo(combination, clientOnly)
    local parsed, parseErr = Hotkeys.ParseCombo(combination)
    if not parsed then
        error(parseErr, 2)
    end
    return send_parsed(parsed, clientOnly, "Hotkeys.SendCombo")
end

--- Registers a combo through Events.RegisterKeyEvent.
---@param params table Registration options table
---@param params.id string Unique key event id
---@param params.combo string Combo text (e.g. "ctrl+f9")
---@param params.callback function Function called when combo fires
---@param params.name? string Optional display name
---@param params.trigger_on_keydown? boolean Optional trigger mode (default false = key up)
---@param params.extended? boolean Optional override for extended key flag
---@return boolean
function Hotkeys.RegisterCombo(params)
    if type(params) ~= "table" then
        error("Hotkeys.RegisterCombo: params must be a table", 2)
    end

    if type(params.id) ~= "string" or params.id == "" then
        error("Hotkeys.RegisterCombo: params.id must be a non-empty string", 2)
    end

    if type(params.callback) ~= "function" then
        error("Hotkeys.RegisterCombo: params.callback must be a function", 2)
    end

    local parsed, parseErr = Hotkeys.ParseCombo(params.combo)
    if not parsed then
        error(parseErr, 2)
    end

    if parsed.alt then
        error("Hotkeys.RegisterCombo: alt is supported for sending combinations but not for registering callback hotkeys", 2)
    end

    if params.trigger_on_keydown ~= nil then
        parsed.trigger_on_keydown = params.trigger_on_keydown == true
    end

    if params.extended ~= nil then
        parsed.extended = params.extended == true
    end

    local name = params.name
    if type(name) ~= "string" or name == "" then
        name = "Lua: " .. params.id
    end

    Events.RegisterKeyEvent({
        id = params.id,
        name = name,
        keycode = parsed.keycode,
        callback = params.callback,
        trigger_on_keydown = parsed.trigger_on_keydown,
        shift = parsed.shift,
        ctrl = parsed.ctrl,
        extended = parsed.extended
    })

    return true
end




