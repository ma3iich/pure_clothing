-- Shared by the shop and the wardrobe: read / apply a piece, talk to the server, notify.

local collectionsOk = GetPedCollectionNameFromDrawable ~= nil and GetPedCollectionLocalIndexFromDrawable ~= nil
    and GetPedCollectionNameFromProp ~= nil and GetPedCollectionLocalIndexFromProp ~= nil

CollectionsOk = collectionsOk

function Gender()
    return GenderOfModel(GetEntityModel(PlayerPedId()))
end

---What the character wears in a slot: { d, t } (props: d = -1 when nothing).
function ReadPiece(ped, slot)
    if slot.prop then
        return { d = GetPedPropIndex(ped, slot.prop), t = math.max(GetPedPropTextureIndex(ped, slot.prop), 0) }
    end
    return { d = GetPedDrawableVariation(ped, slot.component), t = GetPedTextureVariation(ped, slot.component) }
end

function ApplyPiece(ped, slot, piece)
    if slot.prop then
        if piece.d < 0 then ClearPedProp(ped, slot.prop) else SetPedPropIndex(ped, slot.prop, piece.d, piece.t, true) end
    else
        SetPedComponentVariation(ped, slot.component, piece.d, piece.t, 0)
    end
end

function IsNaked(gender, slot, piece)
    return IsBare(gender, slot, piece)
end

---Key of the picture of a piece: <m|f>/<c11|p0>/<collection or _base>/<index in the collection>.
function PictureKey(ped, gender, slot, d)
    local isProp = slot.prop ~= nil
    local id = slot.prop or slot.component
    local prefix = (gender == 'male' and 'm' or 'f') .. '/' .. (isProp and 'p' or 'c') .. id .. '/'
    local collection, localIndex = '', d
    if collectionsOk then
        local nameOf = isProp and GetPedCollectionNameFromProp or GetPedCollectionNameFromDrawable
        local localOf = isProp and GetPedCollectionLocalIndexFromProp or GetPedCollectionLocalIndexFromDrawable
        collection = string.lower(nameOf(ped, id, d) or '')
        localIndex = localOf(ped, id, d)
    end
    return prefix .. (collection == '' and '_base' or collection) .. '/' .. localIndex, collection
end

-- ---- small call / reply channel with the server --------------------------------------------

local pending, nextId = {}, 0

RegisterNetEvent('pure_clothing:reply', function(id, result)
    if pending[id] ~= nil then pending[id] = { result } end
end)

function ServerCall(name, data, timeout)
    nextId = nextId + 1
    local id = nextId
    pending[id] = false
    TriggerServerEvent('pure_clothing:call', id, name, data)
    local deadline = GetGameTimer() + (timeout or 10000)
    while pending[id] == false and GetGameTimer() < deadline do Wait(50) end
    local r = pending[id]
    pending[id] = nil
    return r and r[1] or nil
end

function Notify(text, kind)
    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function() exports.ox_lib:notify({ description = text, type = kind or 'inform' }) end)
        if ok then return end
    end
    AddTextEntry('PURE_CLOTHING_NOTIFY', text)
    BeginTextCommandThefeedPost('PURE_CLOTHING_NOTIFY')
    EndTextCommandThefeedPostTicker(false, false)
end
