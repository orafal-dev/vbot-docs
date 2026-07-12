NpcTradeStorage = NpcTradeStorage or {}

local function validate_non_empty_string(value, argName, functionName)
    if type(value) ~= "string" or value == "" then
        error(functionName .. ": argument '" .. argName .. "' must be a non-empty string")
    end
end

local function validate_positive_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value <= 0 then
        error(functionName .. ": argument '" .. argName .. "' must be a positive integer")
    end
end

local function validate_non_negative_integer(value, argName, functionName)
    if type(value) ~= "number" or value % 1 ~= 0 or value < 0 then
        error(functionName .. ": argument '" .. argName .. "' must be an integer >= 0")
    end
end

local function to_lower_safe(value)
    if type(value) ~= "string" then
        return ""
    end
    return string.lower(value)
end

local function call_game(methodName, ...)
    if type(Game) ~= "table" then
        return false, nil
    end

    local fn = Game[methodName]
    if type(fn) ~= "function" then
        return false, nil
    end

    local ok, result = pcall(fn, ...)
    if not ok then
        return false, nil
    end

    return true, result
end

local function normalize_offer(offer)
    if type(offer) ~= "table" then
        return nil
    end

    local itemId = offer.itemId
    if type(itemId) ~= "number" then
        itemId = offer.item_id
    end

    if type(itemId) ~= "number" then
        return nil
    end

    local name = offer.name
    if type(name) ~= "string" then
        name = offer.objectName
    end
    if type(name) ~= "string" then
        name = ""
    end

    local buyPrice = offer.buyPrice
    if type(buyPrice) ~= "number" then
        buyPrice = offer.objectBuyPrice
    end
    if type(buyPrice) ~= "number" then
        buyPrice = offer.buy_price
    end
    if type(buyPrice) ~= "number" then
        buyPrice = 0
    end

    local sellPrice = offer.sellPrice
    if type(sellPrice) ~= "number" then
        sellPrice = offer.objectSellPrice
    end
    if type(sellPrice) ~= "number" then
        sellPrice = offer.sell_price
    end
    if type(sellPrice) ~= "number" then
        sellPrice = 0
    end

    local capacity = offer.capacity
    if type(capacity) ~= "number" then
        capacity = offer.objectCapacity
    end
    if type(capacity) ~= "number" then
        capacity = 0
    end

    return {
        itemId = itemId,
        name = name,
        buyPrice = buyPrice,
        sellPrice = sellPrice,
        capacity = capacity,
        raw = offer
    }
end

--- Returns true when any NPC trade API is available.
---@return boolean
function NpcTradeStorage.IsAvailable()
    if type(Game) ~= "table" then
        return false
    end

    return type(Game.GetNPCTradeOffers) == "function"
        or type(Game.GetNPCOffers) == "function"
        or type(Game.GetNPCName) == "function"
        or type(Game.BuyItemFromNPC) == "function"
        or type(Game.SellItemToNPC) == "function"
end

--- Returns NPC trade window state when exposed by runtime.
---@return boolean|nil
function NpcTradeStorage.IsOpen()
    local ok, value = call_game("IsNPCTradeWindowOpened")
    if ok and type(value) == "boolean" then
        return value
    end

    ok, value = call_game("GetNPCName")
    if ok and type(value) == "string" then
        return value ~= "" and value ~= "(unknown)"
    end

    return nil
end

--- Returns current NPC trade partner name when exposed by runtime.
---@return string|nil
function NpcTradeStorage.GetNpcName()
    local ok, value = call_game("GetNPCName")
    if ok and type(value) == "string" then
        return value
    end

    return nil
end

--- Returns normalized NPC offers when exposed by runtime.
---@return table[]
function NpcTradeStorage.GetOffers()
    local ok, offers = call_game("GetNPCTradeOffers")
    if not ok or type(offers) ~= "table" then
        ok, offers = call_game("GetNPCOffers")
    end

    if not ok or type(offers) ~= "table" then
        return {}
    end

    local out = {}
    for _, offer in pairs(offers) do
        local normalized = normalize_offer(offer)
        if normalized then
            out[#out + 1] = normalized
        end
    end

    table.sort(out, function(a, b)
        return to_lower_safe(a.name) < to_lower_safe(b.name)
    end)

    return out
end

--- Returns one offer by item id.
---@param itemId integer
---@return table|nil
function NpcTradeStorage.GetOfferByItemId(itemId)
    validate_positive_integer(itemId, "itemId", "NpcTradeStorage.GetOfferByItemId")

    local offers = NpcTradeStorage.GetOffers()
    for i = 1, #offers do
        if offers[i].itemId == itemId then
            return offers[i]
        end
    end

    return nil
end

--- Returns one offer by case-insensitive name.
---@param itemName string
---@return table|nil
function NpcTradeStorage.GetOfferByName(itemName)
    validate_non_empty_string(itemName, "itemName", "NpcTradeStorage.GetOfferByName")

    local expected = to_lower_safe(itemName)
    local offers = NpcTradeStorage.GetOffers()
    for i = 1, #offers do
        if to_lower_safe(offers[i].name) == expected then
            return offers[i]
        end
    end

    return nil
end

--- Buys item from NPC trade.
---@param itemId integer
---@param itemCount integer
---@param ignoreCapacity? boolean
---@param buyInShoppingBags? boolean
---@return any
function NpcTradeStorage.Buy(itemId, itemCount, ignoreCapacity, buyInShoppingBags)
    validate_positive_integer(itemId, "itemId", "NpcTradeStorage.Buy")
    validate_positive_integer(itemCount, "itemCount", "NpcTradeStorage.Buy")

    local ignoreCap = ignoreCapacity == true
    local inBags = buyInShoppingBags == true
    return Game.BuyItemFromNPC(itemId, itemCount, ignoreCap, inBags)
end

--- Sells item to NPC trade.
---@param itemId integer
---@param itemCount integer
---@param sellEquipped? boolean
---@return any
function NpcTradeStorage.Sell(itemId, itemCount, sellEquipped)
    validate_positive_integer(itemId, "itemId", "NpcTradeStorage.Sell")
    validate_positive_integer(itemCount, "itemCount", "NpcTradeStorage.Sell")

    local includeEquipped = sellEquipped == true
    return Game.SellItemToNPC(itemId, itemCount, includeEquipped)
end

--- Returns formatted offers list for logging/debug.
---@return string[]
function NpcTradeStorage.FormatOffers()
    local out = {}
    local offers = NpcTradeStorage.GetOffers()

    for i = 1, #offers do
        local offer = offers[i]
        out[#out + 1] = "[" .. tostring(offer.itemId) .. "] " .. tostring(offer.name)
            .. " buy=" .. tostring(offer.buyPrice)
            .. " sell=" .. tostring(offer.sellPrice)
            .. " cap=" .. tostring(offer.capacity)
    end

    return out
end

--- Returns NPC trade snapshot.
---@return table
function NpcTradeStorage.GetSnapshot()
    local offers = NpcTradeStorage.GetOffers()

    return {
        available = NpcTradeStorage.IsAvailable(),
        isOpen = NpcTradeStorage.IsOpen(),
        npcName = NpcTradeStorage.GetNpcName(),
        offerCount = #offers,
        offers = offers
    }
end

NpcTradeStorage.getNPCName = NpcTradeStorage.GetNpcName
NpcTradeStorage.getNPCOffers = NpcTradeStorage.GetOffers

NpcTradeStorage.IsAvailable = NpcTradeStorage.IsAvailable
NpcTradeStorage.IsOpen = NpcTradeStorage.IsOpen
NpcTradeStorage.GetNpcName = NpcTradeStorage.GetNpcName
NpcTradeStorage.GetOffers = NpcTradeStorage.GetOffers
NpcTradeStorage.GetOfferByItemId = NpcTradeStorage.GetOfferByItemId
NpcTradeStorage.GetOfferByName = NpcTradeStorage.GetOfferByName
NpcTradeStorage.Buy = NpcTradeStorage.Buy
NpcTradeStorage.Sell = NpcTradeStorage.Sell
NpcTradeStorage.FormatOffers = NpcTradeStorage.FormatOffers
NpcTradeStorage.GetSnapshot = NpcTradeStorage.GetSnapshot

if type(NPCTradeStorage) ~= "table" then
    NPCTradeStorage = NpcTradeStorage
else
    if type(NPCTradeStorage.GetOffers) ~= "function" then
        NPCTradeStorage.GetOffers = NpcTradeStorage.GetOffers
    end
    if type(NPCTradeStorage.Buy) ~= "function" then
        NPCTradeStorage.Buy = NpcTradeStorage.Buy
    end
    if type(NPCTradeStorage.Sell) ~= "function" then
        NPCTradeStorage.Sell = NpcTradeStorage.Sell
    end
end

return NpcTradeStorage




