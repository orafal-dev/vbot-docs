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

local function call_profile_file(methodName, path, options)
    require_table("ProfileFiles", ProfileFiles)
    local method = ProfileFiles[methodName]
    if type(method) ~= "function" then
        error("Cavebot: runtime method 'ProfileFiles." .. tostring(methodName) .. "' is not available", 3)
    end

    local ok, result = method(path, options)
    if not ok then
        error(tostring(result or (methodName .. " failed")), 3)
    end
    return true, result
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

-- Bit mask used by Walker Special Areas. Combine values with bitwise OR when
-- one rectangle disables more than one cavebot feature.
Cavebot.Walker.SpecialAreaFeature = SpecialAreaFeature or {
    Walker = 1,
    Targeting = 2,
    MagicShooter = 4,
    Looter = 8,
    All = 15
}

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

function Cavebot.Walker.Defer(timeoutMs)
    if type(timeoutMs) ~= "number" or timeoutMs % 1 ~= 0 or
        timeoutMs < 1 or timeoutMs > 60000 then
        error("Cavebot.Walker.Defer: timeoutMs must be an integer between 1 and 60000", 2)
    end
    return call_walker("Defer", timeoutMs)
end

function Cavebot.Walker.CompleteDeferred(token)
    if type(token) ~= "number" or token % 1 ~= 0 or token < 1 then
        error("Cavebot.Walker.CompleteDeferred: token must be a positive integer", 2)
    end
    return call_walker("CompleteDeferred", token)
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

---Moves an existing waypoint without replacing its identity, type, or action data.
---@param index integer One-based waypoint index.
---@param x integer
---@param y integer
---@param z integer
---@return boolean
function Cavebot.Walker.SetWaypointPosition(index, x, y, z)
    return call_walker("SetWaypointPosition", index, x, y, z)
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

---@return table[]
function Cavebot.Walker.GetSpecialAreas()
    return call_walker("GetSpecialAreas") or {}
end

---@return integer
function Cavebot.Walker.GetSpecialAreaCount()
    return call_walker("GetSpecialAreaCount")
end

---@param area table Must contain x, y, z; width, height, featureMask, and enabled may be omitted.
---@return integer|string|false assignedId
function Cavebot.Walker.AddSpecialArea(area)
    if type(area) ~= "table" then
        error("Cavebot.Walker.AddSpecialArea: area must be a table", 2)
    end
    return call_walker("AddSpecialArea", area)
end

---@param id integer|string Stable area ID returned by AddSpecialArea/GetSpecialAreas.
---@param updateData table Fields to update; omitted fields remain unchanged.
---@return boolean
function Cavebot.Walker.UpdateSpecialArea(id, updateData)
    if type(updateData) ~= "table" then
        error("Cavebot.Walker.UpdateSpecialArea: updateData must be a table", 2)
    end
    return call_walker("UpdateSpecialArea", id, updateData)
end

---@param id integer|string
---@return boolean
function Cavebot.Walker.DeleteSpecialArea(id)
    return call_walker("DeleteSpecialArea", id)
end

---@return boolean removedAny
function Cavebot.Walker.ClearSpecialAreas()
    return call_walker("ClearSpecialAreas")
end

---@param sourceIndex integer One-based source index.
---@param targetIndex integer One-based target index.
---@param dropAfterTarget? boolean
---@return boolean
function Cavebot.Walker.ReorderSpecialArea(sourceIndex, targetIndex, dropAfterTarget)
    return call_walker("ReorderSpecialArea", sourceIndex, targetIndex, dropAfterTarget == true)
end

---@param x integer
---@param y integer
---@param z integer
---@param featureMask integer Cavebot.Walker.SpecialAreaFeature value or combined mask.
---@return boolean
function Cavebot.Walker.IsPositionInsideSpecialArea(x, y, z, featureMask)
    return call_walker("IsPositionInsideSpecialArea", x, y, z, featureMask)
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

Cavebot.Walker.NavigationMode = {
    Waypoints = "waypoints",
    AutoExplore = "auto_explore"
}

Cavebot.Walker.AutoExploreStyle = {
    Natural = "natural",
    Thorough = "thorough",
    WideRoam = "wide_roam"
}

Cavebot.Walker.AutoExploreConnectorKind = {
    WalkOn = "walk_on",
    Ladder = "ladder",
    Rope = "rope",
    Hole = "hole",
    Teleport = "teleport"
}

---@param mode "waypoints"|"auto_explore" Navigation mode can change only while Walker is stopped.
---@return boolean
function Cavebot.Walker.SetNavigationMode(mode)
    return call_walker("SetNavigationMode", mode)
end

---@return "waypoints"|"auto_explore"
function Cavebot.Walker.GetNavigationMode()
    return call_walker("GetNavigationMode")
end

---@param settings table Partial settings update: style, maximumFloorsUp/Down, allowWalkOn/Ladder/Rope/Hole/Teleport, autoOpenDoors.
---@return boolean
function Cavebot.Walker.SetAutoExploreSettings(settings)
    if type(settings) ~= "table" then
        error("Cavebot.Walker.SetAutoExploreSettings: settings must be a table", 2)
    end
    return call_walker("SetAutoExploreSettings", settings)
end

---@return table
function Cavebot.Walker.GetAutoExploreSettings()
    return call_walker("GetAutoExploreSettings") or {}
end

---@return boolean
function Cavebot.Walker.ResetAutoExploreCoverage()
    return call_walker("ResetAutoExploreCoverage")
end

---@return table
function Cavebot.Walker.GetAutoExploreStatus()
    return call_walker("GetAutoExploreStatus") or {}
end

---@param x integer
---@param y integer
---@param z integer
---@return boolean
function Cavebot.Walker.IsAutoExplorePositionPainted(x, y, z)
    return call_walker("IsAutoExplorePositionPainted", x, y, z)
end

---@return table[]
function Cavebot.Walker.GetAutoExploreConnectors()
    return call_walker("GetAutoExploreConnectors") or {}
end

---@param connector table Requires kind, source={x,y,z}, destination={x,y,z}; enabled and pairedConnectorId are optional.
---@return integer|string|false assignedId
function Cavebot.Walker.AddAutoExploreConnector(connector)
    if type(connector) ~= "table" then
        error("Cavebot.Walker.AddAutoExploreConnector: connector must be a table", 2)
    end
    return call_walker("AddAutoExploreConnector", connector)
end

---@param id integer|string
---@param updateData table Partial connector update.
---@return boolean
function Cavebot.Walker.UpdateAutoExploreConnector(id, updateData)
    if type(updateData) ~= "table" then
        error("Cavebot.Walker.UpdateAutoExploreConnector: updateData must be a table", 2)
    end
    return call_walker("UpdateAutoExploreConnector", id, updateData)
end

---@param id integer|string
---@return boolean
function Cavebot.Walker.DeleteAutoExploreConnector(id)
    return call_walker("DeleteAutoExploreConnector", id)
end

---@return boolean removedAny
function Cavebot.Walker.ClearAutoExploreConnectors()
    return call_walker("ClearAutoExploreConnectors")
end

---@param enabled boolean
---@return boolean
function Cavebot.Walker.SetAutoExploreConnectorRecording(enabled)
    return call_walker("SetAutoExploreConnectorRecording", enabled)
end

---@return boolean
function Cavebot.Walker.GetAutoExploreConnectorRecording()
    return call_walker("GetAutoExploreConnectorRecording")
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

---@param distance integer 1..7 and not above the current maximum.
---@return boolean
function Cavebot.Lure.SetKitingPreferredFarthestDistance(distance)
    return call_lure("SetKitingPreferredFarthestDistance", distance)
end

---@return integer
function Cavebot.Lure.GetKitingPreferredFarthestDistance()
    return call_lure("GetKitingPreferredFarthestDistance")
end

---@param distance integer 1..7 and not below the current preferred distance.
---@return boolean
function Cavebot.Lure.SetKitingMaximumFarthestDistance(distance)
    return call_lure("SetKitingMaximumFarthestDistance", distance)
end

---@return integer
function Cavebot.Lure.GetKitingMaximumFarthestDistance()
    return call_lure("GetKitingMaximumFarthestDistance")
end

---@param distance integer 1..7.
---@return boolean
function Cavebot.Lure.SetKitingCloseMonsterDistance(distance)
    return call_lure("SetKitingCloseMonsterDistance", distance)
end

---@return integer
function Cavebot.Lure.GetKitingCloseMonsterDistance()
    return call_lure("GetKitingCloseMonsterDistance")
end

---@param count integer 0..200.
---@return boolean
function Cavebot.Lure.SetKitingCloseMonsterCount(count)
    return call_lure("SetKitingCloseMonsterCount", count)
end

---@return integer
function Cavebot.Lure.GetKitingCloseMonsterCount()
    return call_lure("GetKitingCloseMonsterCount")
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

function Cavebot.Defer(timeoutMs)
    local token = Cavebot.Walker.Defer(timeoutMs)
    local completed = false
    local handle = {
        token = token
    }

    function handle:Complete()
        if completed then
            return false
        end

        local result = Cavebot.Walker.CompleteDeferred(token)
        if result then
            completed = true
        end
        return result
    end

    handle.Cancel = handle.Complete
    return handle
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

local function register_waypoint_observer(apiName, callback)
    if type(callback) ~= "function" then
        error(apiName .. ": callback must be a function", 3)
    end

    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_WAYPOINT_CHANGE) ~= "number" then
        error(apiName .. ": WalkerEvent.ON_WAYPOINT_CHANGE is not available", 3)
    end

    return Cavebot.RegisterEvent(
        WalkerEvent.ON_WAYPOINT_CHANGE,
        function(previousIndex, index, waypointType, x, y, z, labelName, uniqueId)
            if previousIndex == 0 then
                previousIndex = nil
            end

            return callback({
                previousIndex = previousIndex,
                index = index,
                type = waypointType,
                x = x,
                y = y,
                z = z,
                label = labelName,
                labelName = labelName,
                uniqueId = uniqueId
            })
        end
    )
end

-- Legacy blocking handler. Prefer Cavebot.ObserveLabel for telemetry.
function Cavebot.OnLabel(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_LABEL) ~= "number" then
        error("Cavebot.OnLabel: WalkerEvent.ON_LABEL is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.ON_LABEL, callback)
end

-- Explicit alias for the legacy blocking behavior.
function Cavebot.InterceptLabel(callback)
    return Cavebot.OnLabel(callback)
end

-- Non-blocking label observer.
function Cavebot.ObserveLabel(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.OBSERVE_LABEL) ~= "number" then
        error("Cavebot.ObserveLabel: WalkerEvent.OBSERVE_LABEL is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.OBSERVE_LABEL, callback)
end

-- Compatibility name; waypoint-change has always been documented as observational.
function Cavebot.OnWaypointChange(callback)
    return register_waypoint_observer("Cavebot.OnWaypointChange", callback)
end

function Cavebot.ObserveWaypointChange(callback)
    return register_waypoint_observer("Cavebot.ObserveWaypointChange", callback)
end

-- Legacy blocking handler. Prefer Cavebot.ObserveAction for telemetry.
function Cavebot.OnAction(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ON_ACTION) ~= "number" then
        error("Cavebot.OnAction: WalkerEvent.ON_ACTION is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.ON_ACTION, callback)
end

-- Explicit alias for the legacy blocking behavior.
function Cavebot.InterceptAction(callback)
    return Cavebot.OnAction(callback)
end

-- Non-blocking observer fired when an Action waypoint is reached, before any
-- legacy interceptor finishes. Use OnActionStarted/OnActionCompleted for
-- truthful execution telemetry.
function Cavebot.ObserveAction(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.OBSERVE_ACTION) ~= "number" then
        error("Cavebot.ObserveAction: WalkerEvent.OBSERVE_ACTION is not available", 2)
    end
    return Cavebot.RegisterEvent(WalkerEvent.OBSERVE_ACTION, callback)
end

local function register_action_lifecycle_observer(
    apiName,
    eventId,
    callback,
    includeCompletion)
    if type(callback) ~= "function" then
        error(apiName .. ": callback must be a function", 3)
    end

    return Cavebot.RegisterEvent(
        eventId,
        function(
            executionId,
            actionName,
            actionKind,
            waypointIndex,
            waypointUniqueId,
            x,
            y,
            z,
            ok,
            outcome,
            description,
            durationMs)
            local event = {
                executionId = executionId,
                action = actionName,
                name = actionName,
                kind = actionKind,
                waypoint = {
                    index = waypointIndex,
                    uniqueId = waypointUniqueId,
                    x = x,
                    y = y,
                    z = z
                }
            }

            if includeCompletion then
                event.ok = ok
                event.outcome = outcome
                event.description = description
                event.durationMs = durationMs
                if ok then
                    event.result = description
                else
                    event.error = description
                end
            end

            return callback(event)
        end
    )
end

-- Non-blocking. Fired once after Action interception has finished and the
-- Action state machine is about to run for the first time.
function Cavebot.OnActionStarted(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ACTION_STARTED) ~= "number" then
        error("Cavebot.OnActionStarted: WalkerEvent.ACTION_STARTED is not available", 2)
    end
    return register_action_lifecycle_observer(
        "Cavebot.OnActionStarted",
        WalkerEvent.ACTION_STARTED,
        callback,
        false)
end

-- Non-blocking. Fired once for every started Action when it reaches a terminal
-- success, handled failure, timeout, or cancellation result.
function Cavebot.OnActionCompleted(callback)
    require_table("WalkerEvent", WalkerEvent)
    if type(WalkerEvent.ACTION_COMPLETED) ~= "number" then
        error("Cavebot.OnActionCompleted: WalkerEvent.ACTION_COMPLETED is not available", 2)
    end
    return register_action_lifecycle_observer(
        "Cavebot.OnActionCompleted",
        WalkerEvent.ACTION_COMPLETED,
        callback,
        true)
end

function Cavebot.UnregisterAllEvents()
    return call_events("UnregisterAllWalkerEvents")
end

-- Walker and Lure Manager are always included. These are the optional bundle
-- sections accepted by Save and Load.
Cavebot.BundleFeature = Cavebot.BundleFeature or {
    Targeting = "targeting",
    MagicShooter = "magic_shooter",
    Looter = "looter"
}

--- Atomically saves a .validuswpt bundle. A bare filename is saved beside the
--- calling script; an explicit relative path is relative to that script.
---@param path string .validuswpt filename or path
---@param features table|nil optional bundle sections
---@return boolean ok
---@return string resolvedPath
function Cavebot.Save(path, features)
    return call_profile_file("SaveWaypoints", path, features)
end

--- Queues a .validuswpt bundle to load before the next Lua tick. A bare
--- filename is searched beside the script, then in the product Waypoints folder.
--- Loading replaces the active route and may stop running waypoint scripts.
---@param path string .validuswpt filename or path
---@param features table|nil optional bundle sections
---@return boolean queued
---@return string resolvedPath
function Cavebot.Load(path, features)
    return call_profile_file("LoadWaypoints", path, features)
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




