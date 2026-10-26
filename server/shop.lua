-- Purchases: the server finds the shop from the player's position, computes every price itself,
-- takes the money and gives one item per piece. All or nothing: no money is taken when an item
-- cannot be carried, and the money is given back when an item could not be added.

local SHOP_RANGE = (Config.OpenDistance or 2.0) + 4.0
local lastCall = {}
local SPAM_DELAY = { buy = 300, open = 300 } -- ms between two calls of the same kind
Handlers = {}
local handlers = Handlers

-- Pictures that really exist in the resource (the client only chooses which one to show).
Pictures = {}
local pictures = Pictures
do
    local raw = LoadResourceFile(GetCurrentResourceName(), 'web/miniatures/index.json')
    local ok, list = pcall(json.decode, raw or '[]')
    if ok and type(list) == 'table' then
        for _, key in ipairs(list) do pictures[key] = true end
    end
end

function GenderOf(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    return GenderOfModel(GetEntityModel(ped))
end

---Picture of a piece for an inventory item (nui:// url), or nil when the resource has no picture for it.
---Used by pure_inventory when a worn piece becomes an item.
exports('PictureUrl', function(picture)
    if type(picture) ~= 'string' or not Pictures[picture] then return nil end
    return ('nui://%s/web/miniatures/%s.webp'):format(GetCurrentResourceName(), picture)
end)

local function shopNear(src, index)
    local shop = Config.Shops[math.tointeger(tonumber(index)) or 0]
    if not shop then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z)) > SHOP_RANGE then return end
    return shop
end

function handlers.open(src, data)
    if Config.EnableShops == false then return { ok = false, reason = L('cannot_now') } end
    local shop = shopNear(src, data.shop)
    if not shop then return { ok = false, reason = L('cannot_now') } end
    if not GenderOf(src) then return { ok = false, reason = L('wrong_model') } end
    return { ok = true, owner = Framework.identifier(src) }
end

local function readPiece(gender, shop, raw)
    if type(raw) ~= 'table' then return end
    local slot = SlotsByKey[raw.key]
    if not slot or not ShopSells(shop, slot.key) then return end

    local d, t = math.tointeger(tonumber(raw.d)), math.tointeger(tonumber(raw.t)) or 0
    if not d or d < 0 or d > 4095 or t < 0 or t > 255 then return end

    -- sleeves / skin without gloves: free, never an item (kept on the character)
    if slot.component == 3 and IsBare(gender, slot, { d = d }) then
        return { slot = slot, d = d, t = t, price = 0, bare = true }
    end
    if not slot.prop and IsBare(gender, slot, { d = d }) then return end

    local price = PriceOf(gender, slot, d, shop)
    if not price then return end

    local piece = { slot = slot, d = d, t = t, price = price }

    if slot.component == 11 and type(raw.arms) == 'table' then
        local ad, at = math.tointeger(tonumber(raw.arms.d)), math.tointeger(tonumber(raw.arms.t))
        if ad and at and ad >= 0 and ad <= 4095 and at >= 0 and at <= 255 then
            piece.arms = { d = ad, t = at }
        end
    end

    local picture = ('%s/%s%d/%s/%d'):format(gender == 'male' and 'm' or 'f', slot.prop and 'p' or 'c',
        slot.prop or slot.component, '_base', d)
    if type(raw.c) == 'string' and raw.c:match('^[mf]/[cp]%d+/[%w_]+/%d+$') then picture = raw.c end
    if pictures[picture] and picture:sub(1, 1) == (gender == 'male' and 'm' or 'f') then piece.picture = picture end

    return piece
end

function ClothingMetadata(gender, piece)
    local slot = piece.slot
    return {
        label = L('item_' .. slot.key),
        image = 'clothing_' .. slot.key,
        imageurl = piece.picture and ('nui://%s/web/miniatures/%s.webp'):format(GetCurrentResourceName(), piece.picture) or nil,
        weight = slot.weight or 0,
        clothing = { key = slot.key, model = Models[gender], d = piece.d, t = piece.t, arms = piece.arms },
    }
end

---Gives one piece of clothing as an item, for your own shop (Config.EnableShops = false).
---`picture`: optional key from the client export PictureKey (otherwise the base game picture when it exists).
---Returns true when the item was given.
exports('GiveClothing', function(src, key, drawable, texture, picture, arms)
    src = tonumber(src)
    local gender = src and GenderOf(src)
    if not gender then return false end
    local piece = readPiece(gender, { categories = 'all', priceMultiplier = 1.0 },
        { key = key, d = drawable, t = texture, c = picture, arms = arms })
    if not piece or piece.bare then return false end
    return Inventory.addItem(src, Config.Item or 'clothing', 1, ClothingMetadata(gender, piece))
end)

function handlers.buy(src, data)
    if Config.EnableShops == false then return { ok = false, reason = L('cannot_now') } end
    local shop = shopNear(src, data.shop)
    if not shop then return { ok = false, reason = L('cannot_now') } end
    local gender = GenderOf(src)
    if not gender then return { ok = false, reason = L('wrong_model') } end
    if type(data.pieces) ~= 'table' or #data.pieces == 0 or #data.pieces > #Config.Slots then
        return { ok = false, reason = L('nothing_selected') }
    end

    local pieces, seen, total = {}, {}, 0
    for i = 1, #data.pieces do
        local piece = readPiece(gender, shop, data.pieces[i])
        if not piece or seen[piece.slot.key] then return { ok = false, reason = L('nothing_selected') } end
        seen[piece.slot.key] = true
        pieces[#pieces + 1] = piece
        total = total + piece.price
    end

    local account = Config.Payment == 'bank' and 'bank' or 'cash'
    if Framework.getMoney(src, account) < total then return { ok = false, reason = L('not_enough_money') } end

    local item = Config.Item or 'clothing'
    for _, piece in ipairs(pieces) do
        if not piece.bare and not Inventory.canCarry(src, item, 1, ClothingMetadata(gender, piece)) then
            return { ok = false, reason = L('no_room') }
        end
    end

    if not Framework.removeMoney(src, total, account, 'pure_clothing') then
        return { ok = false, reason = L('not_enough_money') }
    end

    local given = 0
    for _, piece in ipairs(pieces) do
        if piece.bare then
            given = given + 1
            if SetWornPiece then SetWornPiece(src, piece.slot.key, { d = piece.d, t = piece.t }) end
        elseif Inventory.addItem(src, item, 1, ClothingMetadata(gender, piece)) then
            given = given + 1
        else
            -- the money of the pieces that could not be given goes back
            Framework.addMoney(src, piece.price, account, 'pure_clothing refund')
            total = total - piece.price
        end
    end

    print(('[pure_clothing] %s bought %d piece(s) for $%d at %s'):format(GetPlayerName(src) or src, given, total, shop.name or '?'))

    if given == 0 then return { ok = false, reason = L('no_room') } end
    return { ok = true, total = total }
end

RegisterNetEvent('pure_clothing:call', function(id, name, data)
    local src = source
    if type(id) ~= 'number' or type(name) ~= 'string' or not handlers[name] then return end

    local now = GetGameTimer()
    lastCall[src] = lastCall[src] or {}
    if now - (lastCall[src][name] or 0) < (SPAM_DELAY[name] or 50) then
        return TriggerClientEvent('pure_clothing:reply', src, id, { ok = false, reason = L('buy_in_progress') })
    end
    lastCall[src][name] = now

    local ok, result = pcall(handlers[name], src, type(data) == 'table' and data or {})
    if not ok then
        print(('^1[pure_clothing] error in "%s": %s^0'):format(name, result))
        result = { ok = false, reason = L('cannot_now') }
    end
    if Config.Debug then
        print(('[pure_clothing] %s from %s: %s -> %s'):format(name, src, json.encode(data), json.encode(result)))
    end
    TriggerClientEvent('pure_clothing:reply', src, id, result)
end)

AddEventHandler('playerDropped', function()
    lastCall[source] = nil
end)
