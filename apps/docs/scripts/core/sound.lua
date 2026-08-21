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
    UNJUSTIFIED_KILL = 13
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
---@param instant? boolean Play immediately when true.
function soundPlayById(soundId, instant)
    instant = instant or false
    Sound.Play({sound_id = soundId, instant = instant})
end

--- Play an alarm by name (queued by default).
--- A bare name is resolved in the product Alarms folder first, then beside the
--- calling script. A fully qualified path is used directly. Missing or invalid
--- WAV files raise an error. Historical built-in aliases are tried only after
--- both exact filename locations and require their canonical packaged WAV.
---@param soundName string Bare alarm name/WAV filename or full absolute WAV path
---@param instant? boolean Play immediately when true.
function soundPlayByName(soundName, instant)
    instant = instant or false
    Sound.Play({sound_name = soundName, instant = instant})
end

--- Play a custom sound from an explicit full path (queued by default).
---@param filePath string Fully qualified absolute path to a WAV file
---@param instant? boolean Play immediately when true.
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
---@param maxWaitMs? number Maximum wait; defaults to 5000 ms.
---@return boolean completed
function soundPlayAndWait(options, maxWaitMs)
    maxWaitMs = maxWaitMs or 5000
    
    -- Play the sound
    Sound.Play(options)
    
    -- Wait for it to start playing
    local startTime = Time.MonotonicMs()
    while not Sound.IsPlaying() do
        if (Time.MonotonicMs() - startTime) > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    -- Wait for it to finish
    while Sound.IsPlaying() do
        if (Time.MonotonicMs() - startTime) > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    return true
end

--- Play an alarm by bare name, WAV filename, or fully qualified path.
--- Bare names search the product Alarms folder before the calling script's
--- folder. Full paths are used directly without either lookup.
---@param filename string Alarm name, WAV filename, or full absolute WAV path
---@param instant? boolean Play immediately when true.
function soundPlayBotSound(filename, instant)
    if type(filename) ~= "string" or filename == "" then
        error("Sound.PlayBotSound: filename must be a non-empty string", 2)
    end

    soundPlayByName(filename, instant)
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
---@param maxWaitMs? number Maximum wait; defaults to 10000 ms.
---@return boolean True if sound finished, false if timeout
function soundWaitForCompletion(maxWaitMs)
    maxWaitMs = maxWaitMs or 10000
    local startTime = Time.MonotonicMs()
    
    while Sound.IsPlaying() do
        local elapsed = Time.MonotonicMs() - startTime
        if elapsed > maxWaitMs then
            return false
        end
        wait(50)
    end
    
    return true
end

--- Play a sound by ID only if not already queued/playing
---@param soundId number BotSoundId enum value
---@param instant? boolean Play immediately when true.
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

--- Play a resolved alarm only if it is not already queued/playing.
--- Uses the same Alarms-folder, script-folder, and absolute-path resolution as
--- Sound.PlayByName.
---@param soundName string Alarm name, WAV filename, or full absolute WAV path
---@param instant? boolean Play immediately when true.
---@return boolean True if sound was queued, false if already queued
function soundPlayByNameSmart(soundName, instant)
    instant = instant or false
    
    if Sound.IsQueued({sound_name = soundName}) then
        return false
    end
    
    Sound.Play({sound_name = soundName, instant = instant})
    return true
end

--- Play a full-path WAV only if not already queued/playing.
---@param filePath string Fully qualified absolute path to a WAV file
---@param instant? boolean Play immediately when true.
---@return boolean True if sound was queued, false if already queued
function soundPlayFileSmart(filePath, instant)
    instant = instant or false
    
    if Sound.IsQueued({file_path = filePath}) then
        return false
    end
    
    Sound.Play({file_path = filePath, instant = instant})
    return true
end

--- Check whether the resolved sound is queued or playing. Name and path
--- resolution is identical to Sound.Play, and missing files raise an error.
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

-- Canonical high-level methods. The historical global helpers below remain
-- available for existing scripts, while new scripts should use Sound.*.
Sound.PlayById = soundPlayById
Sound.PlayByName = soundPlayByName
Sound.PlayFile = soundPlayFile
Sound.StopAll = soundStopAll
Sound.GetQueueLength = soundGetQueueLength
Sound.PlayAndWait = soundPlayAndWait
Sound.WaitForCompletion = soundWaitForCompletion
Sound.PlayByIdSmart = soundPlayByIdSmart
Sound.PlayByNameSmart = soundPlayByNameSmart
Sound.PlayFileSmart = soundPlayFileSmart
Sound.PlayBotSound = soundPlayBotSound

Core = Core or {}
Core.Sound = Sound

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


