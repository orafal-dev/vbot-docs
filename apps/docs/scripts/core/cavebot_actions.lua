Cavebot = Cavebot or {}
Cavebot.Actions = Cavebot.Actions or {}

local handlers = Cavebot.Actions.Handlers or {}
Cavebot.Actions.Handlers = handlers
Cavebot.Actions.LastResult = Cavebot.Actions.LastResult or nil

local function require_table(name, value)
    if type(value) ~= "table" then
        error("Cavebot.Actions: required table '" .. name .. "' is not available", 3)
    end
end

local function as_number(value, fallback)
    if type(value) == "number" then
        return value
    end

    return fallback
end

local function non_empty_string(value)
    if type(value) == "string" and value ~= "" then
        return value
    end

    return nil
end

local function call_no_throw(fn, ...)
    if type(fn) ~= "function" then
        return false, nil
    end

    return pcall(fn, ...)
end

local function get_action_config(context)
    local config = context.actionConfig or context.action_config
    if type(config) == "table" then
        return config
    end

    return {}
end

local function get_action_params(context)
    local config = get_action_config(context)
    if type(config.params) == "table" then
        return config.params
    end

    return {}
end

local function get_vendor_profile(context)
    local vendor = context.vendorProfile or context.vendor_profile
    if type(vendor) == "table" then
        return vendor
    end

    return {}
end

local function get_supply_profile(context)
    local profile = context.supplyProfile or context.supply_profile
    if type(profile) == "table" then
        return profile
    end

    return nil
end

local function log_action_result(result)
    Cavebot.Actions.LastResult = result

    if type(print) ~= "function" or type(result) ~= "table" then
        return
    end

    local actionType = result.actionType or "unknown"
    if result.ok == false then
        print("[Cavebot.Actions] " .. actionType .. " failed: " .. tostring(result.error or "unknown"))
    elseif result.pending == true then
        print("[Cavebot.Actions] " .. actionType .. " pending")
    else
        print("[Cavebot.Actions] " .. actionType .. " completed")
    end
end

local function route_to_label(context, labelName)
    local label = non_empty_string(labelName)
    if not label or not Cavebot or not Cavebot.Walker then
        return false
    end

    if type(Cavebot.Walker.GoTo) ~= "function" or type(Cavebot.Walker.SetPausedByLua) ~= "function" then
        return false
    end

    local beforeIndex = nil
    if type(Cavebot.Walker.GetSelectedWaypointIndex) == "function" then
        local ok, value = pcall(Cavebot.Walker.GetSelectedWaypointIndex)
        if ok then
            beforeIndex = value
        end
    end

    local ok = pcall(Cavebot.Walker.GoTo, label)
    if not ok then
        return false
    end

    if beforeIndex ~= nil and type(Cavebot.Walker.GetSelectedWaypointIndex) == "function" then
        local readOk, afterIndex = pcall(Cavebot.Walker.GetSelectedWaypointIndex)
        if readOk and afterIndex == beforeIndex then
            return false
        end
    end

    Cavebot.Walker.SetPausedByLua(false)
    return true
end

local function finish(context, result)
    result = result or { ok = true }
    log_action_result(result)

    local explicitLabel = non_empty_string(result.goToLabel) or non_empty_string(result.gotoLabel)
    if explicitLabel and route_to_label(context or {}, explicitLabel) then
        return result
    end

    if Cavebot and Cavebot.Walker and type(Cavebot.Walker.Resume) == "function" then
        Cavebot.Walker.Resume()
    end
    return result
end

function Cavebot.Actions.GetLastResult()
    return Cavebot.Actions.LastResult
end

local function normalize_context(context)
    if context == nil then
        return {}
    end
    if type(context) ~= "table" then
        error("Cavebot.Actions.Run: context must be a table", 3)
    end
    return context
end

function Cavebot.Actions.Register(actionType, handler)
    if type(actionType) ~= "string" or actionType == "" then
        error("Cavebot.Actions.Register: actionType must be a non-empty string", 2)
    end
    if type(handler) ~= "function" then
        error("Cavebot.Actions.Register: handler must be a function", 2)
    end

    handlers[actionType] = handler
    return true
end

function Cavebot.Actions.Run(context)
    require_table("Cavebot.Walker", Cavebot.Walker)

    context = normalize_context(context)
    local actionType = context.actionType or context.action_type
    if type(actionType) ~= "string" or actionType == "" then
        return finish(context, { ok = false, error = "missing_action_type" })
    end

    local handler = handlers[actionType]
    if type(handler) ~= "function" then
        return finish(context, { ok = false, error = "unknown_action_type", actionType = actionType })
    end

    local ok, result = pcall(handler, context)
    if not ok then
        return finish(context, { ok = false, error = tostring(result), actionType = actionType })
    end

    return finish(context, result)
end

local function count_item_in_open_containers(itemId)
    if type(Container) ~= "table" then
        return 0, false
    end

    local okContainers, containers = call_no_throw(Container.GetOpenContainers)
    if not okContainers or type(containers) ~= "table" then
        return 0, false
    end

    local total = 0
    for i = 1, #containers do
        local containerNumber = containers[i] and containers[i].containerNumber
        if type(containerNumber) == "number" then
            local okItems, items = call_no_throw(Container.GetItems, containerNumber)
            if okItems and type(items) == "table" then
                for j = 1, #items do
                    local item = items[j]
                    if type(item) == "table" and item.itemId == itemId then
                        total = total + as_number(item.count, 1)
                    end
                end
            end
        end
    end

    return total, true
end

local function talk_to_npc(message)
    local text = non_empty_string(message)
    if not text or type(Game) ~= "table" or type(Game.TalkToNPC) ~= "function" then
        return false
    end

    local ok = call_no_throw(Game.TalkToNPC, text)
    return ok == true
end

local function npc_say_handler(context)
    local config = get_action_config(context)
    local vendor = get_vendor_profile(context)
    local messages = config.messages or config.talkSequence or vendor.talkSequence or context.messages or context.message

    if type(messages) == "string" then
        messages = { messages }
    end

    if type(messages) ~= "table" or #messages == 0 then
        return {
            ok = false,
            actionType = "npc_say",
            error = "missing_messages",
            goToLabel = context.failureLabel
        }
    end

    local sent = {}
    for i = 1, #messages do
        local message = messages[i]
        if non_empty_string(message) then
            if not talk_to_npc(message) then
                return {
                    ok = false,
                    actionType = "npc_say",
                    error = "talk_failed",
                    failedMessage = message,
                    sent = sent,
                    goToLabel = context.failureLabel
                }
            end
            sent[#sent + 1] = message
        end
    end

    return {
        ok = true,
        actionType = "npc_say",
        sent = sent,
        goToLabel = context.successLabel
    }
end

local function run_vendor_talk_sequence(context)
    local vendor = get_vendor_profile(context)
    local messages = vendor.talkSequence
    if type(messages) ~= "table" or #messages == 0 then
        return true, {}
    end

    local sent = {}
    for i = 1, #messages do
        local message = messages[i]
        if non_empty_string(message) then
            if not talk_to_npc(message) then
                return false, sent, message
            end
            sent[#sent + 1] = message
        end
    end

    return true, sent, nil
end

local function check_supplies_handler(context)
    local profile = get_supply_profile(context)
    if type(profile) ~= "table" then
        return {
            ok = false,
            actionType = "check_supplies",
            error = "missing_supply_profile",
            goToLabel = context.failureLabel
        }
    end

    local result = {
        ok = true,
        actionType = "check_supplies",
        needsRefill = false,
        reasons = {},
        items = {}
    }

    if profile.checkCapacity == true and type(Game) == "table" then
        local okCapacity, capacity = call_no_throw(Game.GetCapacity)
        result.capacity = okCapacity and capacity or nil
        if okCapacity and type(capacity) == "number" and capacity < as_number(profile.minCapacity, 0) then
            result.needsRefill = true
            result.reasons[#result.reasons + 1] = "low_capacity"
        end
    end

    if profile.checkStamina == true and type(Game) == "table" then
        local okStamina, stamina = call_no_throw(Game.GetStamina)
        result.staminaMinutes = okStamina and stamina or nil
        if okStamina and type(stamina) == "number" and stamina < as_number(profile.minStaminaMinutes, 0) then
            result.needsRefill = true
            result.reasons[#result.reasons + 1] = "low_stamina"
        end
    end

    local items = profile.items
    if type(items) == "table" then
        for i = 1, #items do
            local item = items[i]
            local itemId = type(item) == "table" and as_number(item.itemId, 0) or 0
            if type(item) == "table" and item.enabled ~= false and itemId > 0 then
                local count, countAvailable = count_item_in_open_containers(itemId)
                local minCount = as_number(item.min, 0)
                local isLow = countAvailable and count < minCount

                if isLow then
                    result.needsRefill = true
                    result.reasons[#result.reasons + 1] = "low_item:" .. tostring(itemId)
                end

                result.items[#result.items + 1] = {
                    itemId = itemId,
                    name = item.name,
                    count = count,
                    min = minCount,
                    target = as_number(item.target, minCount),
                    low = isLow,
                    countAvailable = countAvailable
                }
            end
        end
    end

    if result.needsRefill then
        result.goToLabel = context.failureLabel
    else
        result.goToLabel = context.successLabel
    end

    return result
end

local function buy_item_from_npc(itemId, amount, item)
    if type(NpcTradeStorage) == "table" and type(NpcTradeStorage.Buy) == "function" then
        return call_no_throw(
            NpcTradeStorage.Buy,
            itemId,
            amount,
            item.ignoreCapacity == true,
            item.buyInShoppingBags == true)
    end

    if type(Game) == "table" and type(Game.BuyItemFromNPC) == "function" then
        return call_no_throw(
            Game.BuyItemFromNPC,
            itemId,
            amount,
            item.ignoreCapacity == true,
            item.buyInShoppingBags == true)
    end

    return false, nil
end

local function sell_item_to_npc(itemId, amount, item)
    if type(NpcTradeStorage) == "table" and type(NpcTradeStorage.Sell) == "function" then
        return call_no_throw(
            NpcTradeStorage.Sell,
            itemId,
            amount,
            item.sellEquipped == true)
    end

    if type(Game) == "table" and type(Game.SellItemToNPC) == "function" then
        return call_no_throw(
            Game.SellItemToNPC,
            itemId,
            amount,
            item.sellEquipped == true)
    end

    return false, nil
end

local function buy_supplies_handler(context)
    local profile = get_supply_profile(context)
    if type(profile) ~= "table" then
        return {
            ok = false,
            actionType = "buy_supplies",
            error = "missing_supply_profile",
            goToLabel = context.failureLabel
        }
    end

    local result = {
        ok = true,
        actionType = "buy_supplies",
        npcTalk = {},
        bought = {},
        skipped = {},
        errors = {}
    }

    local talkOk, sentMessages, failedMessage = run_vendor_talk_sequence(context)
    result.npcTalk = sentMessages or {}
    if not talkOk then
        result.ok = false
        result.error = "talk_failed"
        result.failedMessage = failedMessage
        result.goToLabel = context.failureLabel
        return result
    end

    local items = profile.items
    if type(items) ~= "table" then
        result.ok = false
        result.error = "missing_items"
        result.goToLabel = context.failureLabel
        return result
    end

    for i = 1, #items do
        local item = items[i]
        local itemId = type(item) == "table" and as_number(item.itemId, 0) or 0
        local buyConfig = type(item) == "table" and item.buy or nil
        local buyEnabled = true
        if type(buyConfig) == "table" and buyConfig.enabled == false then
            buyEnabled = false
        end

        if type(item) ~= "table" or item.enabled == false or itemId <= 0 or not buyEnabled then
            result.skipped[#result.skipped + 1] = { itemId = itemId, reason = "disabled" }
        else
            local count, countAvailable = count_item_in_open_containers(itemId)
            local targetCount = as_number(item.target, as_number(item.min, 0))
            local amountToBuy = targetCount - count

            if not countAvailable then
                result.errors[#result.errors + 1] = { itemId = itemId, error = "count_unavailable" }
            elseif amountToBuy <= 0 then
                result.skipped[#result.skipped + 1] = { itemId = itemId, reason = "already_enough", count = count, target = targetCount }
            else
                local ok = buy_item_from_npc(itemId, amountToBuy, item)
                if ok then
                    result.bought[#result.bought + 1] = { itemId = itemId, amount = amountToBuy, count = count, target = targetCount }
                else
                    result.errors[#result.errors + 1] = { itemId = itemId, error = "buy_failed", amount = amountToBuy }
                end
            end
        end
    end

    if #result.errors > 0 then
        result.ok = false
        result.error = "buy_errors"
        result.goToLabel = context.failureLabel
    else
        result.goToLabel = context.successLabel
    end

    return result
end

local function sell_loot_handler(context)
    local params = get_action_params(context)
    local sellItems = params.sellItems or context.sellItems

    local result = {
        ok = true,
        actionType = "sell_loot",
        npcTalk = {},
        sold = {},
        skipped = {},
        errors = {}
    }

    local talkOk, sentMessages, failedMessage = run_vendor_talk_sequence(context)
    result.npcTalk = sentMessages or {}
    if not talkOk then
        result.ok = false
        result.error = "talk_failed"
        result.failedMessage = failedMessage
        result.goToLabel = context.failureLabel
        return result
    end

    if type(sellItems) ~= "table" or #sellItems == 0 then
        result.ok = false
        result.error = "missing_sell_items"
        result.goToLabel = context.failureLabel
        return result
    end

    for i = 1, #sellItems do
        local item = sellItems[i]
        local itemId = type(item) == "table" and as_number(item.itemId, 0) or 0

        if type(item) ~= "table" or item.enabled == false or itemId <= 0 then
            result.skipped[#result.skipped + 1] = { itemId = itemId, reason = "disabled" }
        else
            local count, countAvailable = count_item_in_open_containers(itemId)
            local keepCount = as_number(item.keep, 0)
            local requestedAmount = as_number(item.amount, 0)
            local amountToSell = requestedAmount > 0 and requestedAmount or count - keepCount

            if not countAvailable then
                result.errors[#result.errors + 1] = { itemId = itemId, error = "count_unavailable" }
            elseif amountToSell <= 0 then
                result.skipped[#result.skipped + 1] = { itemId = itemId, reason = "nothing_to_sell", count = count, keep = keepCount }
            else
                if amountToSell > count then
                    amountToSell = count
                end

                local ok = sell_item_to_npc(itemId, amountToSell, item)
                if ok then
                    result.sold[#result.sold + 1] = { itemId = itemId, amount = amountToSell, count = count, keep = keepCount }
                else
                    result.errors[#result.errors + 1] = { itemId = itemId, error = "sell_failed", amount = amountToSell }
                end
            end
        end
    end

    if #result.errors > 0 then
        result.ok = false
        result.error = "sell_errors"
        result.goToLabel = context.failureLabel
    else
        result.goToLabel = context.successLabel
    end

    return result
end

local function custom_script_handler(context)
    local params = get_action_params(context)
    local script = params.script or params.code or context.script

    if type(script) ~= "string" or script == "" then
        return {
            ok = false,
            actionType = "custom_script",
            error = "missing_script",
            goToLabel = context.failureLabel
        }
    end

    local loader = type(loadstring) == "function" and loadstring or load
    if type(loader) ~= "function" then
        return {
            ok = false,
            actionType = "custom_script",
            error = "load_unavailable",
            goToLabel = context.failureLabel
        }
    end

    local loadOk, chunk, loadError = pcall(loader, script, "cavebot_custom_action")
    if not loadOk then
        loadOk, chunk, loadError = pcall(loader, script)
    end

    if type(chunk) ~= "function" then
        return {
            ok = false,
            actionType = "custom_script",
            error = tostring(loadError or "load_failed"),
            goToLabel = context.failureLabel
        }
    end

    local ok, scriptResult = pcall(chunk, context)
    if not ok then
        return {
            ok = false,
            actionType = "custom_script",
            error = tostring(scriptResult),
            goToLabel = context.failureLabel
        }
    end

    if type(scriptResult) == "table" then
        if scriptResult.actionType == nil then
            scriptResult.actionType = "custom_script"
        end
        return scriptResult
    end

    return {
        ok = scriptResult ~= false,
        actionType = "custom_script",
        value = scriptResult,
        goToLabel = scriptResult == false and context.failureLabel or context.successLabel
    }
end

local function pending_handler(context)
    return {
        ok = true,
        pending = true,
        actionType = context.actionType or context.action_type,
        configRef = context.configRef or context.config_ref
    }
end

Cavebot.Actions.Register("check_supplies", check_supplies_handler)
Cavebot.Actions.Register("buy_supplies", buy_supplies_handler)
Cavebot.Actions.Register("sell_loot", sell_loot_handler)
Cavebot.Actions.Register("open_depot", pending_handler)
Cavebot.Actions.Register("deposit_items", pending_handler)
Cavebot.Actions.Register("stash_items", pending_handler)
Cavebot.Actions.Register("withdraw_supplies", pending_handler)
Cavebot.Actions.Register("npc_say", npc_say_handler)
Cavebot.Actions.Register("bank", pending_handler)
Cavebot.Actions.Register("custom_script", custom_script_handler)
Cavebot.Actions.Register("tasker", pending_handler)
Cavebot.Actions.Register("imbuing", pending_handler)
