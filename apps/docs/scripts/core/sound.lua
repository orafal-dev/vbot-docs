--[[
File: scripts/core/sound.lua
Provides a high-level API for playing sounds in the bot.
]]

-- ============================================================================
-- SOUND ID ENUMERATION
-- ============================================================================
-- Keep in sync with BotSoundId enum in C++

BotSoundId = {
    DISCONNECTED = 0,
    DAMAGE_TAKEN = 1,
    LOW_HEALTH = 2,
    LOW_MANA = 3,
    PRIVATE_MESSAGE = 4,
    CREATURE_DETECTED = 5,
    PLAYER_ATTACK = 6,
    PLAYER_DETECTED = 7,
    SKULL_ON_SCREEN = 8,
    ENEMY_ON_SCREEN = 9,
    LOCAL_MESSAGE = 10,
    GM_ON_SCREEN = 11,
    WALKER_STUCK = 12,
    UNJUSTIFIED_KILL = 13,
    
    CUSTOM_SOUND_1 = 14,
    CUSTOM_SOUND_2 = 15,
    CUSTOM_SOUND_3 = 16,
    CUSTOM_SOUND_4 = 17,
    CUSTOM_SOUND_5 = 18
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Validates sound playback options
---@param options table Configuration table
---@return boolean Success
local function validateSoundOptions(options)
    if type(options) ~= "table" then
        error("Sound API: options must be a table", 3)
        return false
    end
    
    local hasId = options.sound_id ~= nil
    local hasName = options.sound_name ~= nil
    local hasPath = options.file_path ~= nil
    
    local count = (hasId and 1 or 0) + (hasName and 1 or 0) + (hasPath and 1 or 0)
    if count ~= 1 then
        error("Sound API: Must provide exactly ONE of: sound_id, sound_name, or file_path", 3)
        return false
    end
    
    return true
end

-- ============================================================================
-- WRAPPER API FUNCTIONS
-- ============================================================================

--- Play a sound by ID (queued by default)
---@param soundId number BotSoundId enum value
---@param instant boolean Optional, play immediately if true
function soundPlayById(soundId, instant)
    instant = instant or false
    Sound.Play({sound_id = soundId, instant = instant})
end

--- Play a sound by name (queued by default)
---@param soundName string Name of the sound (case-insensitive)
---@param instant boolean Optional, play immediately if true
function soundPlayByName(soundName, instant)
    instant = instant or false
    Sound.Play({sound_name = soundName, instant = instant})
end

--- Play a custom sound file (queued by default)
---@param filePath string Full path to WAV file
---@param instant boolean Optional, play immediately if true
function soundPlayFile(filePath, instant)
    instant = instant or false
    Sound.Play({file_path = filePath, instant = instant})
end

--- Stop currently playing sound
function soundStopAll()
    Sound.Stop()
    Sound.ClearQueue()
end

--- Get the current sound queue length
---@return number Queue size
function soundGetQueueLength()
    return Sound.GetQueueSize()
end

--- Check if a sound is currently playing
---@return boolean True if playing
function soundIsCurrentlyPlaying()
    return Sound.IsPlaying()
end

--- Set minimum delay between queued sounds (in milliseconds)
---@param delayMs number Delay in milliseconds
function soundSetQueueDelay(delayMs)
    if type(delayMs) ~= "number" or delayMs < 0 then
        error("Sound.SetQueueDelay: delay must be a non-negative number", 2)
        return
    end
    Sound.SetMinDelay(delayMs)
end

--- Play a sound and wait for it to finish (blocking, requires coroutine)
---@param options table Sound configuration
---@param maxWaitMs number Optional, maximum time to wait (default: 5000ms)
function soundPlayAndWait(options, maxWaitMs)
    maxWaitMs = maxWaitMs or 5000
    
    -- Play the sound
    Sound.Play(options)
    
    -- Wait for it to start playing
    local startTime = os.clock() * 1000
    while not Sound.IsPlaying() do
        if (os.clock() * 1000 - startTime) > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    -- Wait for it to finish
    while Sound.IsPlaying() do
        if (os.clock() * 1000 - startTime) > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    return true
end

--- Play a custom notification sound from the bot's sounds folder
---@param filename string WAV filename (e.g., "notification.wav")
---@param instant boolean Optional, play immediately if true
function soundPlayBotSound(filename, instant)
    -- Assumes sounds are in: Documents/ValidusBot/Alarms/
    local path = "C:\\Users\\" .. os.getenv("USERNAME") .. "\\Documents\\ValidusBot\\Alarms\\" .. filename
    soundPlayFile(path, instant)
end

--- Get the duration of currently playing sound
---@return number Duration in milliseconds (0 if nothing playing)
function soundGetCurrentDuration()
    return Sound.GetCurrentDuration()
end

--- Get the duration of a WAV file without playing it
---@param filePath string Path to WAV file
---@return number Duration in milliseconds
function soundGetFileDuration(filePath)
    if type(filePath) ~= "string" then
        error("Sound.GetFileDuration: filePath must be a string", 2)
        return 0
    end
    return Sound.GetFileDuration(filePath)
end

--- Wait for current sound to finish (blocking)
---@param maxWaitMs number Optional max wait time (default: 10000ms)
---@return boolean True if sound finished, false if timeout
function soundWaitForCompletion(maxWaitMs)
    maxWaitMs = maxWaitMs or 10000
    local startTime = os.clock() * 1000
    
    while Sound.IsPlaying() do
        local elapsed = (os.clock() * 1000) - startTime
        if elapsed > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    return true
end

--- Play a sound by ID only if not already queued/playing
---@param soundId number BotSoundId enum value
---@param instant boolean Optional, play immediately if true
---@return boolean True if sound was queued, false if already queued
function soundPlayByIdSmart(soundId, instant)
    instant = instant or false
    
    -- Check if already queued/playing
    if Sound.IsQueued({sound_id = soundId}) then
        return false
    end
    
    Sound.Play({sound_id = soundId, instant = instant})
    return true
end

--- Play a sound by name only if not already queued/playing
---@param soundName string Name of the sound
---@param instant boolean Optional, play immediately if true
---@return boolean True if sound was queued, false if already queued
function soundPlayByNameSmart(soundName, instant)
    instant = instant or false
    
    if Sound.IsQueued({sound_name = soundName}) then
        return false
    end
    
    Sound.Play({sound_name = soundName, instant = instant})
    return true
end

--- Play a file only if not already queued/playing
---@param filePath string Path to WAV file
---@param instant boolean Optional, play immediately if true
---@return boolean True if sound was queued, false if already queued
function soundPlayFileSmart(filePath, instant)
    instant = instant or false
    
    if Sound.IsQueued({file_path = filePath}) then
        return false
    end
    
    Sound.Play({file_path = filePath, instant = instant})
    return true
end

--- Check if a sound is queued or playing
---@param options table Sound configuration
---@return boolean True if queued/playing
function soundIsQueued(options)
    return Sound.IsQueued(options)
end

-- Update convenience functions to use smart versions:
--- Plays low-health notification sound if not already queued.
---@param instant? boolean
---@return boolean
function soundLowHealth(instant)
    return soundPlayByIdSmart(BotSoundId.LOW_HEALTH, instant)
end

--- Plays low-mana notification sound if not already queued.
---@param instant? boolean
---@return boolean
function soundLowMana(instant)
    return soundPlayByIdSmart(BotSoundId.LOW_MANA, instant)
end

--- Plays player-detected notification sound if not already queued.
---@param instant? boolean
---@return boolean
function soundPlayerDetected(instant)
    return soundPlayByIdSmart(BotSoundId.PLAYER_DETECTED, instant)
end

--- Plays GM-detected notification sound if not already queued.
---@param instant? boolean
---@return boolean
function soundGMDetected(instant)
    return soundPlayByIdSmart(BotSoundId.GM_ON_SCREEN, instant)
end

return {
    PlayById = soundPlayById,
    PlayByName = soundPlayByName,
    PlayFile = soundPlayFile,
    Stop = soundStopAll,
    GetQueueLength = soundGetQueueLength,
    IsPlaying = soundIsCurrentlyPlaying,
    SetQueueDelay = soundSetQueueDelay,
    PlayAndWait = soundPlayAndWait,
    
    -- Convenience shortcuts
    LowHealth = soundLowHealth,
    LowMana = soundLowMana,
    PlayerDetected = soundPlayerDetected,
    GMDetected = soundGMDetected,
    PlayBotSound = soundPlayBotSound
}


