Game = Game or {}

local native = {
    GetCharacterWorld = Game.GetCharacterWorld,
    LoginToPreviouslyLoggedCharacter = Game.LoginToPreviouslyLoggedCharacter,
    LoginToAccount = Game.LoginToAccount,
    LoginToCharacter = Game.LoginToCharacter,
    Logout = Game.Logout,
    EnterWorld = Game.EnterWorld
}

local function require_native_function(functionName)
    local fn = native[functionName]
    if type(fn) ~= "function" then
        error("Game." .. functionName .. ": native binding is not available", 3)
    end

    return fn
end

local function validate_non_empty_string(value, argName, functionName)
    if type(value) ~= "string" or value == "" then
        error(functionName .. ": argument '" .. argName .. "' must be a non-empty string", 3)
    end
end

--- Returns the world name for a character from the character list.
---@param characterName string
---@return string
function Game.GetCharacterWorld(characterName)
    validate_non_empty_string(characterName, "characterName", "Game.GetCharacterWorld")
    return require_native_function("GetCharacterWorld")(characterName)
end

--- Logs in to the previously selected/logged character.
---@return boolean
function Game.LoginToPreviouslyLoggedCharacter()
    return require_native_function("LoginToPreviouslyLoggedCharacter")()
end

--- Logs in to an account using email and password.
---@param email string
---@param password string
---@return boolean
function Game.LoginToAccount(email, password)
    validate_non_empty_string(email, "email", "Game.LoginToAccount")
    validate_non_empty_string(password, "password", "Game.LoginToAccount")
    return require_native_function("LoginToAccount")(email, password)
end

--- Selects and logs in to the named character.
---@param characterName string
---@return boolean
function Game.LoginToCharacter(characterName)
    validate_non_empty_string(characterName, "characterName", "Game.LoginToCharacter")
    return require_native_function("LoginToCharacter")(characterName)
end

--- Logs out from the current session.
---@return boolean
function Game.Logout()
    return require_native_function("Logout")()
end

--- Enters the world with the currently selected character.
---@return boolean
function Game.EnterWorld()
    return require_native_function("EnterWorld")()
end
