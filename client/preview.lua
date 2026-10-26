-- Character selection screen (qb-multicharacter): the preview ped is dressed by qb-clothing with the
-- saved outfit; the pieces the character changed (items used, pieces taken off) are applied on it too.
-- With pure_inventory this file steps aside: pure_inventory does the same job.

local previews = {} -- [citizenid] = { state, at }

RegisterNetEvent('pure_clothing:previewState', function(citizenid, state)
    if type(citizenid) == 'string' and type(state) == 'table' then
        previews[citizenid] = { state = state, at = GetGameTimer() }
    end
end)

local function matches(gender, slot, now, target)
    if target == 'off' then return IsBare(gender, slot, now) end
    return type(target) == 'table' and now.d == target.d and now.t == target.t
end

local function pedShows(ped, gender, state)
    for key, entry in pairs(state) do
        local slot = SlotsByKey[key]
        if slot and type(entry) == 'table' then
            local now = ReadPiece(ped, slot)
            if not matches(gender, slot, now, entry.base) and not matches(gender, slot, now, entry.cur) then return false end
        end
    end
    return true
end

AddEventHandler('qb-clothing:client:loadPlayerClothing', function(_, ped)
    if GetResourceState('pure_inventory') == 'started' then return end
    if type(ped) ~= 'number' or ped == 0 or ped == PlayerPedId() or not DoesEntityExist(ped) then return end
    CreateThread(function()
        Wait(300)
        if not DoesEntityExist(ped) then return end
        local gender = GenderOfModel(GetEntityModel(ped))
        if not gender then return end

        local chosen, newestAt = nil, 0
        for _, p in pairs(previews) do
            if next(p.state) and p.at > newestAt and GetGameTimer() - p.at < 3000 then chosen, newestAt = p.state, p.at end
        end
        if not chosen then
            for _, p in pairs(previews) do
                if next(p.state) and pedShows(ped, gender, p.state) then chosen = p.state break end
            end
        end
        if not chosen then return end

        local deadline = GetGameTimer() + 3000
        while DoesEntityExist(ped) and not pedShows(ped, gender, chosen) and GetGameTimer() < deadline do Wait(100) end
        if not DoesEntityExist(ped) then return end
        for key, entry in pairs(chosen) do
            local slot = SlotsByKey[key]
            if slot and type(entry) == 'table' then
                ApplyPiece(ped, slot, entry.cur == 'off' and NakedOf(gender, slot) or entry.cur)
            end
        end
    end)
end)
