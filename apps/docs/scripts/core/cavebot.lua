Cavebot = Cavebot or {}

local function require_table(globalName, value)
    if type(value) ~= "table" then
        error("Cavebot: required global table '" .. globalName .. "' is not available", 3)
    end
end

local function get_runtime_table(primaryName, legacyName)
    local primary = _G[primaryName]
    if type(primary) == "table" then
        return primary, primaryName
    end

    if type(legacyName) == "string" then
        local legacy = _G[legacyName]
        if type(legacy) == "table" then
            return legacy, legacyName
        end
    end

    return nil, primaryName
end

local function get_feature_id(featureName, fallbackId)
    if type(BotFeatureId) == "table" and type(BotFeatureId[featureName]) == "number" then
        return BotFeatureId[featureName]
    end
    return fallbackId
end

local WALKER_FEATURE_ID = get_feature_id("WALKER", 5)
local LURE_MANAGER_FEATURE_ID = get_feature_id("LURE_MANAGER", 4)

local function call_walker(methodName, ...)
    local runtime, runtimeName = get_runtime_table("Walker", "walker")
    require_table(runtimeName, runtime)
    local method = runtime[methodName]
    if type(method) ~= "function" then
        error("Cavebot.Walker: runtime method '" .. runtimeName .. "." .. tostring(methodName) .. "' is not available", 3)
    end
    return method(...)
end

local function call_lure(methodName, ...)
    local runtime, runtimeName = get_runtime_table("Lure", "lure")
    require_table(runtimeName, runtime)
    local method = runtime[methodName]
    if type(method) ~= "function" then
        error("Cavebot.Lure: runtime method '" .. runtimeName .. "." .. tostring(methodName) .. "' is not available", 3)
    end
    return method(...)
end

local function call_events(methodName, ...)
    require_table("Events", Events)
    local method = Events[methodName]
    if type(method) ~= "function" then
        error("Cavebot.events: runtime method 'Events." .. tostring(methodName) .. "' is not available", 3)
    end
    return method(...)
end

local function call_features(methodName, ...)
    require_table("Features", Features)
    local method = Features[methodName]
    if type(method) ~= "function" then
        error("Cavebot.features: runtime method 'Features." .. tostring(methodName) .. "' is not available", 3)
    end
    return method(...)
end

local function normalize_waypoint_table(waypoint)
    if type(waypoint) ~= "table" then
        error("Cavebot.Walker: waypoint must be a table", 3)
    end

    return {
        type = waypoint.type,
        x = waypoint.x,
        y = waypoint.y,
        z = waypoint.z,
        labelName = waypoint.labelName,
        useWithItemId = waypoint.useWithItemId,
        delayMs = waypoint.delayMs,
        scriptContent = waypoint.scriptContent
    }
end

-- walker namespace
Cavebot.Walker = Cavebot.Walker or {}

function Cavebot.Walker.SetEnabled(enabled)
    return call_walker("SetEnabled", enabled)
end

function Cavebot.Walker.IsEnabled()
    local runtime = get_runtime_table("Walker", "walker")
    if type(runtime) == "table" and type(runtime.IsEnabled) == "function" then
        return runtime.IsEnabled()
    end
    return call_features("IsActive", WALKER_FEATURE_ID)
end

function Cavebot.Walker.Resume()
    return call_walker("Resume")
end

function Cavebot.Walker.GoTo(labelName)
    if type(labelName) ~= "string" or labelName == "" then
        error("Cavebot.Walker.GoTo: labelName must be a non-empty string", 2)
    end
    return call_walker("GoTo", labelName)
end

function Cavebot.Walker.GetSelectedWaypointIndex()
    return call_walker("GetSelectedWaypointIndex")
end

function Cavebot.Walker.SetSelectedWaypointIndex(index)
    return call_walker("SetSelectedWaypointIndex", index)
end

function Cavebot.Walker.SelectClosestWaypoint()
    return call_walker("SelectClosestWaypoint")
end

function Cavebot.Walker.GetWaypointCount()
    return call_walker("GetWaypointCount")
end

function Cavebot.Walker.GetWaypoints()
    return call_walker("GetWaypoints") or {}
end

function Cavebot.Walker.AddWaypoint(waypoint)
    return call_walker("AddWaypoint", normalize_waypoint_table(waypoint))
end

function Cavebot.Walker.InsertWaypoint(index, waypoint)
    return call_walker("InsertWaypoint", index, normalize_waypoint_table(waypoint))
end

function Cavebot.Walker.ReplaceWaypoint(index, waypoint)
    return call_walker("ReplaceWaypoint", index, normalize_waypoint_table(waypoint))
end

function Cavebot.Walker.DeleteWaypoint(index)
    return call_walker("DeleteWaypoint", index)
end

function Cavebot.Walker.ClearWaypoints()
    return call_walker("ClearWaypoints")
end

function Cavebot.Walker.MoveWaypointUp(index)
    if index == nil then
        return call_walker("MoveWaypointUp")
    end
    return call_walker("MoveWaypointUp", index)
end

function Cavebot.Walker.MoveWaypointDown(index)
    if index == nil then
        return call_walker("MoveWaypointDown")
    end
    return call_walker("MoveWaypointDown", index)
end

function Cavebot.Walker.IsStuck()
    return call_walker("IsStuck")
end

function Cavebot.Walker.SetStartFromNearestWaypoint(enabled)
    return call_walker("SetStartFromNearestWaypoint", enabled)
end

function Cavebot.Walker.GetStartFromNearestWaypoint()
    return call_walker("GetStartFromNearestWaypoint")
end

function Cavebot.Walker.SetNodeDistance(distance)
    return call_walker("SetNodeDistance", distance)
end

function Cavebot.Walker.GetNodeDistance()
    return call_walker("GetNodeDistance")
end

function Cavebot.Walker.SetWalkToLureCenter(enabled)
    return call_walker("SetWalkToLureCenter", enabled)
end

function Cavebot.Walker.GetWalkToLureCenter()
    return call_walker("GetWalkToLureCenter")
end

function Cavebot.Walker.SetLeaveLureOnPlayer(enabled)
    return call_walker("SetLeaveLureOnPlayer", enabled)
end

function Cavebot.Walker.GetLeaveLureOnPlayer()
    return call_walker("GetLeaveLureOnPlayer")
end

-- Player detection mode used by Leave Box If Player On Screen.
-- 0 = non-ally players, 1 = any player (including party/guild allies).
Cavebot.Walker.LeaveLurePlayerMode = {
    NonAllyPlayers = 0,
    AnyPlayer = 1
}

---@param mode integer 0 for non-ally players, 1 for any player.
---@return boolean
function Cavebot.Walker.SetLeaveLurePlayerMode(mode)
    return call_walker("SetLeaveLurePlayerMode", mode)
end

---@return integer mode 0 for non-ally players, 1 for any player.
function Cavebot.Walker.GetLeaveLurePlayerMode()
    return call_walker("GetLeaveLurePlayerMode")
end

function Cavebot.Walker.SetDebugHud(enabled)
    return call_walker("SetDebugHud", enabled)
end

function Cavebot.Walker.GetDebugHud()
    return call_walker("GetDebugHud")
end

function Cavebot.Walker.SetAutoRecorderEnabled(enabled)
    return call_walker("SetAutoRecorderEnabled", enabled)
end

function Cavebot.Walker.GetAutoRecorderEnabled()
    return call_walker("GetAutoRecorderEnabled")
end

function Cavebot.Walker.SetAutoRecorderOptions(options)
    return call_walker("SetAutoRecorderOptions", options)
end

function Cavebot.Walker.GetAutoRecorderOptions()
    return call_walker("GetAutoRecorderOptions") or {}
end

function Cavebot.Walker.SetDistanceBetweenWaypoints(distance)
    return call_walker("SetDistanceBetweenWaypoints", distance)
end

function Cavebot.Walker.GetDistanceBetweenWaypoints()
    return call_walker("GetDistanceBetweenWaypoints")
end

function Cavebot.Walker.SetPausedByLua(paused)
    return call_walker("SetPausedByLua", paused)
end

function Cavebot.Walker.IsPausedByLua()
    return call_walker("IsPausedByLua")
end

-- lure namespace
Cavebot.Lure = Cavebot.Lure or {}

function Cavebot.Lure.SetEnabled(enabled)
    return call_lure("SetEnabled", enabled)
end

function Cavebot.Lure.IsEnabled()
    local runtime = get_runtime_table("Lure", "lure")
    if type(runtime) == "table" and type(runtime.IsEnabled) == "function" then
        return runtime.IsEnabled()
    end
    return call_features("IsActive", LURE_MANAGER_FEATURE_ID)
end

function Cavebot.Lure.GetState()
    return call_lure("GetState")
end

function Cavebot.Lure.IsLuring()
    return call_lure("IsLuring")
end

function Cavebot.Lure.IsFighting()
    return call_lure("IsFighting")
end

function Cavebot.Lure.SetForceLure(enabled)
    return call_lure("SetForceLure", enabled)
end

function Cavebot.Lure.IsForceLure()
    return call_lure("IsForceLure")
end

function Cavebot.Lure.EndForceLure()
    return call_lure("EndForceLure")
end

function Cavebot.Lure.SetOption(option)
    return call_lure("SetOption", option)
end

function Cavebot.Lure.GetOption()
    return call_lure("GetOption")
end

function Cavebot.Lure.SetNearRange(range)
    return call_lure("SetNearRange", range)
end

function Cavebot.Lure.GetNearRange()
    return call_lure("GetNearRange")
end

function Cavebot.Lure.SetAttackWhileLuring(enabled)
    return call_lure("SetAttackWhileLuring", enabled)
end

function Cavebot.Lure.GetAttackWhileLuring()
    return call_lure("GetAttackWhileLuring")
end

function Cavebot.Lure.SetConsiderOnlyReachable(enabled)
    return call_lure("SetConsiderOnlyReachable", enabled)
end

function Cavebot.Lure.GetConsiderOnlyReachable()
    return call_lure("GetConsiderOnlyReachable")
end

function Cavebot.Lure.SetSlowWalkDelayMs(delayMs)
    return call_lure("SetSlowWalkDelayMs", delayMs)
end

function Cavebot.Lure.GetSlowWalkDelayMs()
    return call_lure("GetSlowWalkDelayMs")
end

function Cavebot.Lure.SetSlowWalkingCreaturesCount(count)
    return call_lure("SetSlowWalkingCreaturesCount", count)
end

function Cavebot.Lure.GetSlowWalkingCreaturesCount()
    return call_lure("GetSlowWalkingCreaturesCount")
end

function Cavebot.Lure.SetSlowWalkBurstSteps(steps)
    return call_lure("SetSlowWalkBurstSteps", steps)
end

function Cavebot.Lure.GetSlowWalkBurstSteps()
    return call_lure("GetSlowWalkBurstSteps")
end

function Cavebot.Lure.SetIgnoringMonsters(enabled)
    return call_lure("SetIgnoringMonsters", enabled)
end

function Cavebot.Lure.GetIgnoringMonsters()
    return call_lure("GetIgnoringMonsters")
end

function Cavebot.Lure.SetStartEndLureActive(enabled)
    return call_lure("SetStartEndLureActive", enabled)
end

function Cavebot.Lure.GetStartEndLureActive()
    return call_lure("GetStartEndLureActive")
end

function Cavebot.Lure.SetWaypointDynamicLureActive(enabled)
    return call_lure("SetWaypointDynamicLureActive", enabled)
end

function Cavebot.Lure.GetWaypointDynamicLureActive()
    return call_lure("GetWaypointDynamicLureActive")
end

function Cavebot.Lure.SetUnblocking(enabled)
    return call_lure("SetUnblocking", enabled)
end

function Cavebot.Lure.GetUnblocking()
    return call_lure("GetUnblocking")
end

function Cavebot.Lure.GetLuredCreaturesCount()
    return call_lure("GetLuredCreaturesCount")
end

function Cavebot.Lure.HasActiveSettings()
    return call_lure("HasActiveSettings")
end

function Cavebot.Lure.IsOtherPlayerOnScreen()
    return call_lure("IsOtherPlayerOnScreen")
end

function Cavebot.Lure.GetSettings()
    return call_lure("GetSettings") or {}
end

function Cavebot.Lure.GetSettingCount()
    return call_lure("GetSettingCount")
end

function Cavebot.Lure.AddSetting(setting)
    if type(setting) ~= "table" then
        error("Cavebot.Lure.AddSetting: setting must be a table", 2)
    end
    return call_lure("AddSetting", setting)
end

function Cavebot.Lure.UpdateSetting(index, updateData)
    if type(updateData) ~= "table" then
        error("Cavebot.Lure.UpdateSetting: updateData must be a table", 2)
    end
    return call_lure("UpdateSetting", index, updateData)
end

function Cavebot.Lure.RemoveSetting(index)
    return call_lure("RemoveSetting", index)
end

function Cavebot.Lure.ClearSettings()
    return call_lure("ClearSettings")
end

-- Top-level convenience API
function Cavebot.SetEnabled(enabled)
    return Cavebot.Walker.SetEnabled(enabled)
end

function Cavebot.Enable()
    return Cavebot.Walker.SetEnabled(true)
end

function Cavebot.Disable()
    return Cavebot.Walker.SetEnabled(false)
end

function Cavebot.IsEnabled()
    return Cavebot.Walker.IsEnabled()
end

function Cavebot.SetLureEnabled(enabled)
    return Cavebot.Lure.SetEnabled(enabled)
end

function Cavebot.EnableLure()
    return Cavebot.Lure.SetEnabled(true)
end

function Cavebot.DisableLure()
    return Cavebot.Lure.SetEnabled(false)
end

function Cavebot.IsLureEnabled()
    return Cavebot.Lure.IsEnabled()
end

function Cavebot.SetEnginesEnabled(walkerEnabled, lureEnabled)
    Cavebot.SetEnabled(walkerEnabled)
    Cavebot.SetLureEnabled(lureEnabled)
    return Cavebot.GetStatus()
end

function Cavebot.Resume()
    return Cavebot.Walker.Resume()
end

function Cavebot.GoTo(labelName)
    return Cavebot.Walker.GoTo(labelName)
end

function Cavebot.GoToLabel(labelName)
    return Cavebot.Walker.GoTo(labelName)
end

function Cavebot.Pause(milliseconds, autoResume)
    if type(milliseconds) ~= "number" or milliseconds % 1 ~= 0 or milliseconds < 0 then
        error("Cavebot.Pause: milliseconds must be an integer >= 0", 2)
    end

    Cavebot.Disable()
    if autoResume ~= true then
        return nil
    end

    return call_events("Schedule", function()
        Cavebot.Enable()
        Cavebot.Resume()
    end, milliseconds)
end

function Cavebot.RegisterEvent(eventId, callback)
    if type(eventId) ~= "number" or eventId % 1 ~= 0 or eventId < 0 then
        error("Cavebot.RegisterEvent: eventId must be an integer >= 0", 2)
    end
    if type(callback) ~= "function" then
        error("Cavebot.RegisterEvent: callback must be a function", 2)
    end
    return call_events("RegisterWalkerEvent", eventId, callback)
end

function Cavebot.OnLabel(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_LABEL) ~= "number" then
        error("Cavebot.OnLabel: WalkerEvent.ON_LABEL is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.ON_LABEL, callback)
end

function Cavebot.OnWaypointChange(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_WAYPOINT_CHANGE) ~= "number" then
        error("Cavebot.OnWaypointChange: WalkerEvent.ON_WAYPOINT_CHANGE is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.ON_WAYPOINT_CHANGE, callback)
end

function Cavebot.OnAction(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_ACTION) ~= "number" then
        error("Cavebot.OnAction: WalkerEvent.ON_ACTION is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.ON_ACTION, callback)
end

function Cavebot.UnregisterAllEvents()
    return call_events("UnregisterAllWalkerEvents")
end

function Cavebot.GetStatus()
    return {
        walkerEnabled = Cavebot.IsEnabled(),
        lureEnabled = Cavebot.IsLureEnabled(),
        walkerStuck = Cavebot.Walker.IsStuck(),
        lureState = Cavebot.Lure.GetState(),
        lureMonsterCount = Cavebot.Lure.GetLuredCreaturesCount(),
        waypointCount = Cavebot.Walker.GetWaypointCount(),
        selectedWaypointIndex = Cavebot.Walker.GetSelectedWaypointIndex()
    }
end

function Cavebot.PrintStatus()
    local status = Cavebot.GetStatus()
    print("=== Cavebot Status ===")
    print("walker:          " .. (status.walkerEnabled and "ON" or "OFF"))
    print("lure Manager:    " .. (status.lureEnabled and "ON" or "OFF"))
    print("walker Stuck:    " .. (status.walkerStuck and "YES" or "NO"))
    print("lure State:      " .. tostring(status.lureState))
    print("Lured Monsters:  " .. tostring(status.lureMonsterCount))
    print("Waypoints:       " .. tostring(status.waypointCount))
    print("Selected WP:     " .. tostring(status.selectedWaypointIndex))
end

return Cavebot




