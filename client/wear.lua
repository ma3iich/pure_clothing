-- Wearing clothes with ox_inventory: use an item = put it on, wardrobe = take a piece off.
-- With pure_inventory this file steps aside: its clothing slots already do the same job.

Wear = {}

local busy = false
local wardrobeOpen = false
local state = {}
local lastWorn = {}
local planReconcile -- defined below: re-reads the state from the server after a delay

local function enabled()
    return GetResourceState('pure_inventory') ~= 'started'
end

-- Real gloves (arms 16+) are a slot of their own. Sleeve / skin arms (0-15) go with the top:
-- bare torso = bare arms, and a top put on from an item brings its own sleeves back.
local function applyWithArms(ped, gender, slot, piece)
    ApplyPiece(ped, slot, piece)
    if slot.component ~= 11 then return end
    local armsSlot = SlotsByKey.gloves or { key = 'gloves', component = 3 }
    local arms = ReadPiece(ped, armsSlot)
    if not IsNaked(gender, armsSlot, arms) then return end -- real gloves: untouched
    if IsNaked(gender, slot, piece) then
        local naked = NakedOf(gender, armsSlot)
        SetPedComponentVariation(ped, 3, naked.d, naked.t, 0)
    elseif type(piece.arms) == 'table' and IsNaked(gender, armsSlot, piece.arms) then
        SetPedComponentVariation(ped, 3, piece.arms.d, piece.arms.t, 0)
    end
end

local function currentOf(ped, slot)
    local piece = ReadPiece(ped, slot)
    if slot.component == 11 then
        piece.arms = { d = GetPedDrawableVariation(ped, 3), t = GetPedTextureVariation(ped, 3) }
    end
    return piece
end

---Worn pieces, for the wardrobe.
local function wornList()
    local ped = PlayerPedId()
    local gender = Gender()
    local list = {}
    if not gender then return list end
    for _, slot in ipairs(Config.Slots) do
        local piece = ReadPiece(ped, slot)
        if not IsNaked(gender, slot, piece) then
            list[#list + 1] = { key = slot.key, icon = slot.icon, c = PictureKey(ped, gender, slot, piece.d) }
        end
    end
    return list
end

function Wear.takeOff(key)
    local slot = SlotsByKey[key]
    local gender = Gender()
    if busy or not slot or not gender or not enabled() then return false end
    local ped = PlayerPedId()
    local current = currentOf(ped, slot)
    if IsNaked(gender, slot, current) then return false end

    busy = true
    local res = ServerCall('takeOff', { key = key, current = current, c = PictureKey(ped, gender, slot, current.d) })
    busy = false

    if res and res.ok then
        state[key] = { base = state[key] and state[key].base or current, cur = 'off' }
        applyWithArms(ped, gender, slot, NakedOf(gender, slot))
        lastWorn[key] = currentOf(ped, slot)
        return true
    end
    if not res then planReconcile(true) end -- no answer: the server decides, nothing is put back by guess
    Notify(res and res.reason or L('no_answer'), 'error')
    return false
end

---Called by the inventory when a clothing item is used (ox_inventory: client.export of the item).
function Wear.use(data, slotData)
    local gender = Gender()
    local meta = type(slotData) == 'table' and type(slotData.metadata) == 'table' and slotData.metadata.clothing
    local slot = type(meta) == 'table' and SlotsByKey[meta.key]
    if busy or not gender or not slot or not enabled() then return false end
    if meta.model ~= Models[gender] then
        Notify(L('wrong_model'), 'error')
        return false
    end

    local ped = PlayerPedId()
    local worn = currentOf(ped, slot)

    busy = true
    local res = ServerCall('putOn', { slot = slotData.slot, current = worn, c = PictureKey(ped, gender, slot, worn.d) })
    busy = false

    if res and res.ok and type(res.piece) == 'table' then
        state[slot.key] = { base = state[slot.key] and state[slot.key].base or worn, cur = res.piece }
        applyWithArms(ped, gender, slot, res.piece)
        lastWorn[slot.key] = currentOf(ped, slot)
    else
        if not res then planReconcile(true) end
        Notify(res and res.reason or L('no_answer'), 'error')
    end
    return false -- the server removed the item itself
end

---A free piece chosen in the shop (sleeves): remembered as worn, like a piece put on from an item.
function Wear.setWorn(key, piece)
    if not enabled() or not SlotsByKey[key] then return end
    state[key] = { base = state[key] and state[key].base or piece, cur = { d = piece.d, t = piece.t } }
    lastWorn[key] = { d = piece.d, t = piece.t }
end

exports('useClothing', Wear.use)

-- ---- keeping the clothes in place -----------------------------------------------------------
-- The server remembers what the character changed (`state`). After the appearance script dressed
-- him (connection, respawn, new model), and every few seconds, the pieces he took off are taken off
-- again and the pieces he put on from an item are put back: another script that applies a saved
-- outfit (radial menu, outfit changer...) cannot undo them. A slot that shows a piece the server
-- does not know (changed in a clothing shop, a job outfit...) is forgotten: that script decides.


local function matches(gender, slot, now, target)
    if target == 'off' then return IsNaked(gender, slot, now) end
    return type(target) == 'table' and now.d == target.d and now.t == target.t
end

-- What the character wore at the last check, per slot: `lastWorn`.

local function snapshot(ped)
    for _, slot in ipairs(Config.Slots) do lastWorn[slot.key] = currentOf(ped, slot) end
end

-- The radial menu strips the arms together with the top: the arms were not taken off on purpose,
-- they are put back. Taken off alone, they become an item like any other piece.
local function topStripped(ped, gender)
    local topSlot, was = SlotsByKey.jacket, lastWorn.jacket
    if not topSlot or not was then return false end
    return not IsNaked(gender, topSlot, was) and IsNaked(gender, topSlot, ReadPiece(ped, topSlot))
end

-- A piece taken off by another script (radial menu...) becomes an item, like in the wardrobe.
local function externalRemovals(ped, gender)
    if Config.AutoTakeOff == false or (Shop.isOpen and Shop.isOpen()) then return end
    local armsWithTop = topStripped(ped, gender) -- decided before any slot changes below
    for _, slot in ipairs(Config.Slots) do
        local was, entry = lastWorn[slot.key], state[slot.key]
        if was and not IsNaked(gender, slot, was) and IsNaked(gender, slot, ReadPiece(ped, slot))
            and not (entry and entry.cur == 'off') and slot.component == 3 and armsWithTop then
            ApplyPiece(ped, slot, was)
        elseif was and not IsNaked(gender, slot, was) and IsNaked(gender, slot, ReadPiece(ped, slot))
            and not (entry and entry.cur == 'off') then
            busy = true
            local res = ServerCall('takeOff', { key = slot.key, current = was, c = PictureKey(ped, gender, slot, was.d) })
            busy = false
            if res and res.ok then
                state[slot.key] = { base = entry and entry.base or was, cur = 'off' }
                applyWithArms(ped, gender, slot, NakedOf(gender, slot))
            elseif res then
                applyWithArms(ped, gender, slot, was) -- refused (no room...): the piece stays on
                if res.reason then Notify(res.reason, 'error') end
            else
                planReconcile(true) -- no answer: the server decides, nothing is put back by guess
            end
            lastWorn[slot.key] = currentOf(ped, slot)
        end
    end
end

-- The inventory slot that holds this very piece as an item (same slot key and drawable), or nil.
local function itemSlotFor(gender, slot, piece)
    local ok, found = pcall(function() return exports.ox_inventory:Search('slots', Config.Item or 'clothing') end)
    if not ok or type(found) ~= 'table' then return end
    local best
    for _, it in ipairs(found) do
        local c = type(it.metadata) == 'table' and it.metadata.clothing
        if type(c) == 'table' and c.key == slot.key and c.model == Models[gender] and c.d == piece.d then
            if c.t == piece.t then return it.slot end
            best = best or it.slot
        end
    end
    return best
end

-- A piece dressed again by another script (radial menu...) while it is an item in the inventory:
-- the item is used, the piece is worn. Returns true when done.
local function putOnFromInventory(ped, gender, slot, now)
    local invSlot = itemSlotFor(gender, slot, now)
    if not invSlot then return false end
    busy = true
    local res = ServerCall('putOn', { slot = invSlot, current = NakedOf(gender, slot), c = PictureKey(ped, gender, slot, now.d) })
    busy = false
    if res and res.ok and type(res.piece) == 'table' then
        state[slot.key] = { base = state[slot.key] and state[slot.key].base or NakedOf(gender, slot), cur = res.piece }
        applyWithArms(ped, gender, slot, res.piece)
        lastWorn[slot.key] = currentOf(ped, slot)
        return true
    end
    return false
end

function Wear.reconcile(fetch)
    if not enabled() or (Shop.isOpen and Shop.isOpen()) then return end -- the shop dresses the character itself
    local ped = PlayerPedId()
    local gender = Gender()
    if not gender then return end

    if fetch then
        local fetched = ServerCall('wearState', {})
        state = type(fetched) == 'table' and fetched or {}
        -- wait until the appearance script dressed the character with the base outfit (checked every 250 ms),
        -- so the real pieces are put back at once, without the old outfit showing for seconds
        local deadline = GetGameTimer() + (Config.ApplyTimeout or 10000)
        repeat
            local ready = true
            for key, entry in pairs(state) do
                local slot = SlotsByKey[key]
                if slot and type(entry) == 'table' then
                    local now = ReadPiece(ped, slot)
                    if not matches(gender, slot, now, entry.cur) and not matches(gender, slot, now, entry.base) then ready = false end
                end
            end
            if ready then break end
            Wait(250)
        until GetGameTimer() > deadline
    else
        externalRemovals(ped, gender)
    end

    local forget, rebase = {}, {}

    local topSlot = SlotsByKey.jacket
    local topOff = topSlot and IsNaked(gender, topSlot, ReadPiece(ped, topSlot))

    for key, entry in pairs(state) do
        local slot = SlotsByKey[key]
        -- sleeves (free arms) are not put back while the top is off: bare torso = bare arms
        local sleevesWithoutTop = slot and slot.component == 3 and type(entry) == 'table' and type(entry.cur) == 'table'
            and IsNaked(gender, slot, entry.cur) and topOff
        if slot and type(entry) == 'table' and not sleevesWithoutTop then
            local now = ReadPiece(ped, slot)
            if not matches(gender, slot, now, entry.cur) then
                local known = matches(gender, slot, now, entry.base) or IsNaked(gender, slot, now)
                if entry.cur == 'off' and not IsNaked(gender, slot, now) and putOnFromInventory(ped, gender, slot, now) then
                    -- the piece came back from the inventory
                elseif known then
                    applyWithArms(ped, gender, slot, entry.cur == 'off' and NakedOf(gender, slot) or entry.cur)
                elseif entry.cur == 'off' then
                    -- a piece taken off (it is an item now) dressed again by another script with a piece the
                    -- server does not know (saved outfit...): it is that script's base outfit, and it stays off
                    entry.base = { d = now.d, t = now.t }
                    rebase[#rebase + 1] = { key = key, d = now.d, t = now.t }
                    applyWithArms(ped, gender, slot, NakedOf(gender, slot))
                elseif not IsNaked(gender, slot, entry.cur) then
                    -- a piece put on from an item, replaced by another script (outfit changer...): it goes back
                    -- into the inventory, and that script decides for the slot from now on
                    busy = true
                    ServerCall('takeOff', { key = key, current = entry.cur, c = PictureKey(ped, gender, slot, entry.cur.d) })
                    busy = false
                    forget[#forget + 1] = key
                else
                    forget[#forget + 1] = key
                end
            end
        end
    end

    if #forget > 0 or #rebase > 0 then
        for _, key in ipairs(forget) do state[key] = nil end
        Wait(400)
        ServerCall('forget', { keys = forget, rebase = rebase })
    end

    snapshot(ped)
end

local planned = false

function planReconcile()
    if planned then return end
    planned = true
    SetTimeout(Config.ApplyDelay or 3000, function()
        planned = false
        Wear.reconcile(true)
    end)
end

AddEventHandler('playerSpawned', planReconcile)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', planReconcile)
RegisterNetEvent('esx:playerLoaded', planReconcile)

CreateThread(function()
    if not enabled() then return end
    local ped = PlayerPedId()
    if NetworkIsPlayerActive(PlayerId()) then planReconcile() end
    while true do
        Wait(2000)
        local now = PlayerPedId()
        if now ~= ped then
            ped = now
            planReconcile()
        elseif not busy and not planned then
            Wear.reconcile(false)
        end
    end
end)

-- ---- wardrobe ------------------------------------------------------------------------------

function Wear.openWardrobe()
    if wardrobeOpen or not enabled() then return end
    if not Gender() then return Notify(L('wrong_model'), 'error') end
    wardrobeOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'wardrobe', data = { items = wornList(), texts = Texts(), theme = Config.Theme, logo = Config.Logo or false } })
end

function Wear.closeWardrobe()
    if not wardrobeOpen then return end
    wardrobeOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

exports('OpenWardrobe', Wear.openWardrobe)

RegisterNUICallback('takeOff', function(data, cb)
    if not wardrobeOpen or type(data) ~= 'table' then return cb({ items = wornList() }) end
    Wear.takeOff(data.key)
    cb({ items = wornList() })
end)

RegisterNUICallback('closeWardrobe', function(_, cb)
    cb(1)
    Wear.closeWardrobe()
end)

RegisterCommand('wardrobe', function() Wear.openWardrobe() end, false)
RegisterKeyMapping('wardrobe', L('wardrobe'), 'keyboard', '')

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Wear.closeWardrobe() end
end)
