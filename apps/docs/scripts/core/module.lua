Module = Module or {}

local registry = {}
local rawModuleNew = Module.New or Module.new
local rawModuleStop = Module.Stop or Module.stop
local rawModulePause = Module.Pause or Module.pause
local rawModuleResume = Module.Resume or Module.resume

function Module.New(name, callback, delayMs)
    if type(rawModuleNew) ~= "function" then
        error("Module.New: underlying module binding is unavailable", 2)
    end

    return rawModuleNew(name, callback, delayMs)
end

function Module.Stop(name)
    if type(rawModuleStop) ~= "function" then
        error("Module.Stop: underlying module binding is unavailable", 2)
    end

    return rawModuleStop(name)
end

function Module.Pause(name)
    if type(rawModulePause) ~= "function" then
        error("Module.Pause: underlying module binding is unavailable", 2)
    end

    return rawModulePause(name)
end

function Module.Resume(name)
    if type(rawModuleResume) ~= "function" then
        error("Module.Resume: underlying module binding is unavailable", 2)
    end

    return rawModuleResume(name)
end

local function ensure_module_api(functionName)
    if type(Module) ~= "table" or type(Module.New) ~= "function" or type(Module.Stop) ~= "function" then
        error(functionName .. ": Module.New/Module.Stop are required", 3)
    end
end

local function ensure_module_pause_resume_api(functionName)
    ensure_module_api(functionName)
    if type(Module.Pause) ~= "function" or type(Module.Resume) ~= "function" then
        error(functionName .. ": Module.Pause/Module.Resume are required", 3)
    end
end

local function normalize_delay(delayMs, functionName)
    if type(delayMs) ~= "number" or delayMs < 0 or delayMs % 1 ~= 0 then
        error(functionName .. ": delayMs must be an integer >= 0", 3)
    end
    return delayMs
end

function Module.Every(name, callback, delayMs)
    ensure_module_api("Module.Every")

    if type(name) ~= "string" or name == "" then
        error("Module.Every: name must be a non-empty string", 2)
    end

    if type(callback) ~= "function" then
        error("Module.Every: callback must be a function", 2)
    end

    local delay = normalize_delay(delayMs, "Module.Every")

    Module.Stop(name)
    Module.New(name, callback, delay)

    registry[name] = {
        mode = "every",
        delayMs = delay,
        active = true
    }

    return true
end

function Module.After(name, callback, delayMs)
    ensure_module_api("Module.After")

    if type(name) ~= "string" or name == "" then
        error("Module.After: name must be a non-empty string", 2)
    end

    if type(callback) ~= "function" then
        error("Module.After: callback must be a function", 2)
    end

    local delay = normalize_delay(delayMs, "Module.After")

    Module.Stop(name)
    Module.New(name, function()
        if delay > 0 then
            wait(delay)
        end

        callback()
        Module.Stop(name)
        registry[name] = nil
    end, 0)

    registry[name] = {
        mode = "after",
        delayMs = delay,
        active = true
    }

    return true
end

function Module.Cancel(name)
    ensure_module_api("Module.Cancel")

    if type(name) ~= "string" or name == "" then
        error("Module.Cancel: name must be a non-empty string", 2)
    end

    Module.Stop(name)
    registry[name] = nil
    return true
end

function Module.PauseManaged(name)
    ensure_module_pause_resume_api("Module.PauseManaged")

    if type(name) ~= "string" or name == "" then
        error("Module.PauseManaged: name must be a non-empty string", 2)
    end

    Module.Pause(name)

    if registry[name] then
        registry[name].active = false
    end

    return true
end

function Module.ResumeManaged(name)
    ensure_module_pause_resume_api("Module.ResumeManaged")

    if type(name) ~= "string" or name == "" then
        error("Module.ResumeManaged: name must be a non-empty string", 2)
    end

    Module.Resume(name)

    if registry[name] then
        registry[name].active = true
    end

    return true
end

function Module.Exists(name)
    return registry[name] ~= nil
end

function Module.Get(name)
    return registry[name]
end

function Module.List()
    local out = {}
    for moduleName, data in pairs(registry) do
        out[#out + 1] = {
            name = moduleName,
            mode = data.mode,
            delayMs = data.delayMs,
            active = data.active
        }
    end

    return out
end

Module.New = Module.New
Module.Stop = Module.Stop
Module.Pause = Module.Pause
Module.Resume = Module.Resume
Module.Every = Module.Every
Module.After = Module.After
Module.Cancel = Module.Cancel
Module.PauseManaged = Module.PauseManaged
Module.ResumeManaged = Module.ResumeManaged
Module.Exists = Module.Exists
Module.Get = Module.Get
Module.List = Module.List

if Module.new == nil and type(Module.New) == "function" then
    Module.new = Module.New
end

if Module.stop == nil and type(Module.Stop) == "function" then
    Module.stop = Module.Stop
end

if Module.pause == nil and type(Module.Pause) == "function" then
    Module.pause = Module.Pause
end

if Module.resume == nil and type(Module.Resume) == "function" then
    Module.resume = Module.Resume
end

if Module.every == nil and type(Module.Every) == "function" then
    Module.every = Module.Every
end

if Module.after == nil and type(Module.After) == "function" then
    Module.after = Module.After
end

if Module.cancel == nil and type(Module.Cancel) == "function" then
    Module.cancel = Module.Cancel
end

if Module.pauseManaged == nil and type(Module.PauseManaged) == "function" then
    Module.pauseManaged = Module.PauseManaged
end

if Module.resumeManaged == nil and type(Module.ResumeManaged) == "function" then
    Module.resumeManaged = Module.ResumeManaged
end

return Module



