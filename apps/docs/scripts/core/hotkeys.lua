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

for i = 0, 9 do
    local ch = tostring(i)
    key_map[ch] = string.byte(ch)
end

for i = string.byte("a"), string.byte("z") do
    local ch = string.char(i)
    key_map[ch] = i - 32
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
    return p
end

--- Parses a textual hotkey combo (for example: "ctrl+f9", "insert", "shift+k").
--- Supported modifiers: ctrl, shift.
--- alt is intentionally rejected because current Events.RegisterKeyEvent API does not expose alt.
---@param combination string
---@return table|nil parsed Parsed table: {keycode, ctrl, shift, trigger_on_keydown, extended}
---@return string|nil err Error message when parsing fails
function Hotkeys.ParseCombo(combination)
    if type(combination) ~= "string" or combination == "" then
        return nil, "Hotkeys.ParseCombo: combination must be a non-empty string"
    end

    local parsed = {
        keycode = nil,
        ctrl = false,
        shift = false,
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
            return nil, "Hotkeys.ParseCombo: alt is not supported by Events.RegisterKeyEvent in current API"
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




