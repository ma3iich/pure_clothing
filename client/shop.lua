-- The shop: opens the menu, dresses the character while the player tries clothes on, sends the
-- purchases to the server and gives the character his own clothes back when the menu closes.

Shop = {}

local MAX_TILES = 3000
local isOpen = false
local shopIndex, owner
local origin, current, hides = {}, {}, {}
local keep = {} -- free pieces (sleeves) paid for: kept on the character when the shop closes

local read, apply, gender, call = ReadPiece, ApplyPiece, Gender, ServerCall

local function copy(piece) return { d = piece.d, t = piece.t } end

local function mapHeight()
    if IsRadarHidden() then return nil end
    local margin = (1.0 - GetSafeZoneSize()) / 2.0
    return margin + (IsBigmapActive() and 0.4824 or 0.1909)
end

-- Favourites: on the player's computer, one list per character.
local function favKey() return 'pure_clothing:favorites:' .. tostring(owner or 'player') end

local function favorites()
    local raw = GetResourceKvpString(favKey())
    if not raw then return {} end
    local ok, list = pcall(json.decode, raw)
    return ok and type(list) == 'table' and list or {}
end

local function slotsOfShop(shop)
    local list = {}
    for _, slot in ipairs(Config.Slots) do
        if ShopSells(shop, slot.key) then
            list[#list + 1] = { key = slot.key, prop = slot.prop, component = slot.component, icon = slot.icon }
        end
    end
    return list
end

-- ---- open / close ---------------------------------------------------------------------------

function Shop.open(index)
    if isOpen or Config.EnableShops == false then return end
    local shop = Config.Shops[index]
    if not shop then return end
    local ped = PlayerPedId()
    local g = gender()
    if not g then return Notify(L('wrong_model'), 'error') end

    local res = call('open', { shop = index })
    if not res or not res.ok then return Notify(res and res.reason or L('no_answer'), 'error') end

    isOpen, shopIndex, owner = true, index, res.owner
    origin, current, hides, keep = {}, {}, {}, {}
    for _, slot in ipairs(Config.Slots) do
        origin[slot.key] = read(ped, slot)
        current[slot.key] = copy(origin[slot.key])
    end

    FreezeEntityPosition(ped, true)
    Camera.start()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            model = g == 'male' and 'mp_m_freemode_01' or 'mp_f_freemode_01',
            slots = slotsOfShop(shop),
            worn = origin,
            shop = { name = shop.name },
            favorites = favorites(),
            texts = Texts(),
            theme = Config.Theme,
            menu = Config.Menu,
            logo = Config.Logo or false,
            map = mapHeight(),
        },
    })
end

local function restore()
    local ped = PlayerPedId()
    for _, slot in ipairs(Config.Slots) do
        if keep[slot.key] then
            apply(ped, slot, keep[slot.key])
        elseif origin[slot.key] then
            apply(ped, slot, origin[slot.key])
        end
    end
end

-- A free piece (sleeves without gloves) stays on the character and is remembered.
local function keepFree(pieces)
    for _, piece in ipairs(pieces) do
        if piece.bare then
            keep[piece.key] = { d = piece.d, t = piece.t }
            origin[piece.key] = { d = piece.d, t = piece.t }
            if Wear and Wear.setWorn then Wear.setWorn(piece.key, { d = piece.d, t = piece.t }) end
        end
    end
end

function Shop.close()
    if not isOpen then return end
    isOpen = false
    restore()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Camera.stop()
    FreezeEntityPosition(PlayerPedId(), false)
    hides, current = {}, {}
end

function Shop.isOpen() return isOpen end

exports('OpenShop', Shop.open)
exports('CloseShop', Shop.close)

---Picture key of a piece worn by the player's character, for your own shop: exports.pure_clothing:PictureKey('jacket', 9)
exports('PictureKey', function(key, drawable)
    local slot = SlotsByKey[key]
    local g = Gender()
    local d = math.tointeger(tonumber(drawable))
    if not slot or not g or not d or d < 0 then return nil end
    return (PictureKey(PlayerPedId(), g, slot, d))
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Shop.close() end
end)

-- ---- menu callbacks -------------------------------------------------------------------------

RegisterNUICallback('category', function(data, cb)
    local slot = isOpen and type(data) == 'table' and SlotsByKey[data.key]
    local shop = Config.Shops[shopIndex]
    local g = gender()
    if not slot or not shop or not g or not ShopSells(shop, slot.key) then return cb({ items = {} }) end

    local ped = PlayerPedId()
    local isProp = slot.prop ~= nil
    local id = slot.prop or slot.component
    local total = isProp and GetNumberOfPedPropDrawableVariations(ped, id) or GetNumberOfPedDrawableVariations(ped, id)
    local texturesOf = isProp and GetNumberOfPedPropTextureVariations or GetNumberOfPedTextureVariations
    local naked = NakedOf(g, slot).d
    local items = {}

    if isProp then items[#items + 1] = { p = -1, n = true } end

    for d = 0, math.min(total - 1, MAX_TILES) do
        if not isProp and d == naked then
            items[#items + 1] = { p = d, n = true }
        elseif not isProp and slot.component == 3 and IsBare(g, slot, { d = d }) then
            -- sleeves / skin without gloves: free, chosen with the top and saved in the top's item
            local picture = PictureKey(ped, g, slot, d)
            items[#items + 1] = { p = d, t = math.max(texturesOf(ped, id, d) or 1, 1), c = picture, price = 0, bare = true }
        elseif not isProp and IsBare(g, slot, { d = d }) then
            -- another "bare" drawable (qb-radialmenu...): not a piece to sell
        else
            local price = PriceOf(g, slot, d, shop)
            if price then
                local picture, collection = PictureKey(ped, g, slot, d)
                items[#items + 1] = {
                    p = d,
                    t = math.max(texturesOf(ped, id, d) or 1, 1),
                    c = picture,
                    a = CollectionsOk and not GtaCollections[collection] or nil,
                    price = price,
                }
            end
        end
    end

    cb({ items = items })
end)

RegisterNUICallback('set', function(data, cb)
    cb(1)
    local slot = isOpen and type(data) == 'table' and SlotsByKey[data.key]
    local d, t = math.tointeger(tonumber(data and data.d)), math.tointeger(tonumber(data and data.t))
    if not slot or not d or not t then return end
    current[slot.key] = { d = d, t = t }
    hides[slot.key] = nil
    apply(PlayerPedId(), slot, current[slot.key])
end)

RegisterNUICallback('hide', function(data, cb)
    cb(1)
    local slot = isOpen and type(data) == 'table' and SlotsByKey[data.key]
    local g = gender()
    if not slot or not g then return end
    if data.hide then
        hides[slot.key] = true
        apply(PlayerPedId(), slot, NakedOf(g, slot))
    else
        hides[slot.key] = nil
        apply(PlayerPedId(), slot, current[slot.key] or origin[slot.key])
    end
end)

RegisterNUICallback('favorite', function(data, cb)
    cb(1)
    if not isOpen or type(data) ~= 'table' or type(data.key) ~= 'string' then return end
    if not data.key:match('^[mf]/[cp]%d+/[%w_]+/%d+$') then return end
    local list = favorites()
    local pos
    for i = 1, #list do
        if list[i] == data.key then pos = i break end
    end
    if data.on == true and not pos then
        if #list >= 2000 then table.remove(list, 1) end
        list[#list + 1] = data.key
    elseif data.on ~= true and pos then
        table.remove(list, pos)
    else
        return
    end
    SetResourceKvp(favKey(), json.encode(list))
end)

local function piecesToBuy(list)
    local pieces = {}
    for i = 1, math.min(#list, #Config.Slots) do
        local p = list[i]
        local slot = type(p) == 'table' and SlotsByKey[p.key]
        if slot then
            local piece = { key = slot.key, d = math.tointeger(tonumber(p.d)), t = math.tointeger(tonumber(p.t)) or 0 }
            if piece.d and piece.d >= 0 then piece.c = PictureKey(PlayerPedId(), gender(), slot, piece.d) end
            if slot.component == 3 and piece.d and IsBare(gender(), slot, piece) then piece.bare = true end
            -- the sleeves chosen in the shop go with the top (real gloves stay a piece of their own)
            if slot.component == 11 and current.gloves and SlotsByKey.gloves
                and IsBare(gender(), SlotsByKey.gloves, current.gloves) then
                piece.arms = { d = current.gloves.d, t = current.gloves.t }
            end
            pieces[#pieces + 1] = piece
        end
    end
    return pieces
end

RegisterNUICallback('buyOne', function(data, cb)
    if not isOpen or type(data) ~= 'table' then return cb({ ok = false }) end
    local pieces = piecesToBuy({ data })
    if #pieces ~= 1 then return cb({ ok = false, reason = L('nothing_selected') }) end
    local res = call('buy', { shop = shopIndex, pieces = pieces })
    if not res then return cb({ ok = false, reason = L('no_answer') }) end
    if res.ok then keepFree(pieces) end
    cb({ ok = res.ok == true, price = res.total, reason = res.reason })
end)

RegisterNUICallback('checkout', function(data, cb)
    if not isOpen or type(data) ~= 'table' or type(data.pieces) ~= 'table' then return cb({ ok = false }) end
    local pieces = piecesToBuy(data.pieces)
    if #pieces == 0 then return cb({ ok = false, reason = L('nothing_selected') }) end
    local res = call('buy', { shop = shopIndex, pieces = pieces })
    if not res then return cb({ ok = false, reason = L('no_answer') }) end
    cb({ ok = res.ok == true, total = res.total, reason = res.reason })
    if res.ok then
        keepFree(pieces)
        Shop.close()
        Notify(L('paid', '$' .. tostring(res.total or 0), #pieces), 'success')
    end
end)

RegisterNUICallback('reset', function(_, cb)
    cb(1)
    if not isOpen then return end
    hides = {}
    for _, slot in ipairs(Config.Slots) do
        if origin[slot.key] then current[slot.key] = copy(origin[slot.key]) end
    end
    restore()
end)

RegisterNUICallback('exit', function(_, cb)
    cb(1)
    Shop.close()
end)
