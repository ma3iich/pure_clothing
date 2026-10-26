-- Wearing clothes with ox_inventory: a piece taken off becomes an item, an item used is put on.
-- With pure_inventory this file does nothing: its clothing slots already do the same job.
--
-- What each character changed is remembered in `pure_clothing_worn`:
--   [slot key] = { base = what the appearance script dresses him with, cur = 'off' or the worn piece }
-- After a reconnection the appearance script dresses him with `base` again and the client puts `cur`
-- back, so a piece already turned into an item cannot be taken off a second time.

if Inventory.name == 'pure_inventory' then return end

local item = Config.Item or 'clothing'
local states = {}

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `pure_clothing_worn` (
        `owner` varchar(64) NOT NULL,
        `data` longtext DEFAULT NULL,
        `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
        PRIMARY KEY (`owner`)
    )]])
end)

local function getState(owner)
    local state = states[owner]
    if state then return state end
    local row = MySQL.scalar.await('SELECT data FROM pure_clothing_worn WHERE owner = ?', { owner })
    local ok, decoded = pcall(json.decode, row or '{}')
    state = ok and type(decoded) == 'table' and decoded or {}
    states[owner] = state
    return state
end

local function saveState(owner)
    local state = states[owner]
    if not state or not next(state) then
        return MySQL.prepare('DELETE FROM pure_clothing_worn WHERE owner = ?', { owner })
    end
    MySQL.prepare('INSERT INTO pure_clothing_worn (owner, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { owner, json.encode(state) })
end

local function readWorn(slot, raw)
    if type(raw) ~= 'table' then return end
    local d, t = math.tointeger(tonumber(raw.d)), math.tointeger(tonumber(raw.t))
    if not d or not t or t < 0 or t > 255 or d > 4095 then return end
    if slot.prop and d < -1 or not slot.prop and d < 0 then return end
    local piece = { d = d, t = t }
    if slot.component == 11 and type(raw.arms) == 'table' then
        local ad, at = math.tointeger(tonumber(raw.arms.d)), math.tointeger(tonumber(raw.arms.t))
        if ad and at and ad >= 0 and ad <= 4095 and at >= 0 and at <= 255 then piece.arms = { d = ad, t = at } end
    end
    return piece
end

local function isNaked(gender, slot, piece)
    return IsBare(gender, slot, piece)
end

local function same(a, b)
    return type(a) == 'table' and type(b) == 'table' and a.d == b.d and a.t == b.t
end

local function pictureOf(gender, slot, piece, raw)
    local picture = ('%s/%s%d/_base/%d'):format(gender == 'male' and 'm' or 'f', slot.prop and 'p' or 'c',
        slot.prop or slot.component, piece.d)
    if type(raw) == 'string' and raw:match('^[mf]/[cp]%d+/[%w_]+/%d+$') and raw:sub(1, 1) == (gender == 'male' and 'm' or 'f') then
        picture = raw
    end
    return Pictures[picture] and picture or nil
end

local function session(src)
    local gender = GenderOf(src)
    local owner = Framework.identifier(src)
    if not gender or not owner then return end
    return gender, owner
end

---Remembers a piece worn without an item (free sleeves chosen in the shop): put back after a reconnection.
function SetWornPiece(src, key, piece)
    local gender, owner = session(src)
    local slot = SlotsByKey[key]
    if not gender or not slot then return end
    local state = getState(owner)
    local entry = state[key]
    state[key] = { base = entry and entry.base or piece, cur = { d = piece.d, t = piece.t } }
    saveState(owner)
end

---State of the character, for the client to put the pieces back after the appearance script.
function Handlers.wearState(src)
    local _, owner = session(src)
    if not owner then return {} end
    return getState(owner)
end

---Slots the player changed somewhere else (shop, outfit...): forgotten, the appearance script decides.
function Handlers.forget(src, data)
    local _, owner = session(src)
    if not owner then return {} end
    data.keys = type(data.keys) == 'table' and data.keys or {}
    local state = getState(owner)
    local changed = false
    for i = 1, math.min(#data.keys, 32) do
        local key = data.keys[i]
        if type(key) == 'string' and state[key] then
            state[key] = nil
            changed = true
        end
    end
    -- new base outfit of a slot that stays taken off (dressed by another script with an unknown piece)
    if type(data.rebase) == 'table' then
        for i = 1, math.min(#data.rebase, 32) do
            local r = data.rebase[i]
            local slot = type(r) == 'table' and SlotsByKey[r.key]
            local entry = slot and state[slot.key]
            local piece = slot and readWorn(slot, r)
            if entry and entry.cur == 'off' and piece then
                entry.base = piece
                changed = true
            end
        end
    end
    if changed then saveState(owner) end
    return {}
end

---Takes a piece off: it becomes an item.
function Handlers.takeOff(src, data)
    local gender, owner = session(src)
    local slot = SlotsByKey[data.key]
    if not gender or not slot then return { ok = false, reason = L('cannot_now') } end

    local reported = readWorn(slot, data.current)
    if not reported then return { ok = false, reason = L('cannot_now') } end

    local state = getState(owner)
    local entry = state[slot.key]
    if entry and entry.cur == 'off' then return { ok = false, reason = L('already_removed') } end

    -- a piece put on from an item is known by the server: the client cannot change it
    local piece = entry and type(entry.cur) == 'table' and readWorn(slot, entry.cur) or reported
    if isNaked(gender, slot, piece) then return { ok = false, reason = L('nothing_worn') } end

    local metadata = ClothingMetadata(gender, { slot = slot, d = piece.d, t = piece.t, arms = piece.arms,
        picture = pictureOf(gender, slot, piece, data.c) })

    if not Inventory.canCarry(src, item, 1, metadata) then return { ok = false, reason = L('no_room') } end
    if not Inventory.addItem(src, item, 1, metadata) then return { ok = false, reason = L('no_room') } end

    state[slot.key] = { base = entry and entry.base or reported, cur = 'off' }
    saveState(owner)

    return { ok = true }
end

---Puts on the clothing item held in the inventory slot; the piece worn there (if any) becomes an item.
function Handlers.putOn(src, data)
    local gender, owner = session(src)
    local invSlot = math.tointeger(tonumber(data.slot))
    if not gender or not invSlot then return { ok = false, reason = L('cannot_now') } end

    local held = Inventory.getSlot(src, invSlot)
    local meta = held and held.name == item and type(held.metadata) == 'table' and held.metadata.clothing
    local slot = type(meta) == 'table' and SlotsByKey[meta.key]
    if not slot then return { ok = false, reason = L('cannot_now') } end
    if meta.model ~= Models[gender] then return { ok = false, reason = L('wrong_model') } end

    local newPiece = readWorn(slot, meta)
    if not newPiece or isNaked(gender, slot, newPiece) then return { ok = false, reason = L('cannot_now') } end

    local reported = readWorn(slot, data.current)
    if not reported then return { ok = false, reason = L('cannot_now') } end

    local state = getState(owner)
    local entry = state[slot.key]
    local worn
    if not entry then
        worn = reported
    elseif entry.cur ~= 'off' then
        worn = readWorn(slot, entry.cur)
    end
    if worn and isNaked(gender, slot, worn) then worn = nil end

    if not Inventory.removeItem(src, item, 1, invSlot) then return { ok = false, reason = L('cannot_now') } end

    if worn then
        local metadata = ClothingMetadata(gender, { slot = slot, d = worn.d, t = worn.t, arms = worn.arms,
            picture = pictureOf(gender, slot, worn, data.c) })
        if not Inventory.addItem(src, item, 1, metadata, invSlot) and not Inventory.addItem(src, item, 1, metadata) then
            Inventory.addItem(src, item, 1, held.metadata, invSlot)
            return { ok = false, reason = L('no_room') }
        end
    end

    state[slot.key] = { base = entry and entry.base or reported, cur = newPiece }
    saveState(owner)

    return { ok = true, piece = newPiece }
end

-- Character selection screen (qb-multicharacter): when it asks for the skin of one of the player's
-- characters, the pieces that character changed are sent too, for the preview ped.
RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, citizenid)
    if name ~= 'qb-multicharacter:server:getSkin' or type(citizenid) ~= 'string' then return end
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    local owner = MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', { citizenid })
    if not license or owner ~= license then return end
    TriggerClientEvent('pure_clothing:previewState', src, citizenid, getState(citizenid))
end)

-- Characters that left are removed from memory (read again from the database next time).
CreateThread(function()
    while true do
        Wait(30 * 60000)
        local online = {}
        for _, playerId in ipairs(GetPlayers()) do
            local owner = Framework.identifier(tonumber(playerId))
            if owner then online[owner] = true end
        end
        for owner in pairs(states) do
            if not online[owner] then states[owner] = nil end
        end
    end
end)
