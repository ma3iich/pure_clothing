-- Shop peds, blips, and the way to open a shop: a target menu when one runs
-- (pure-target, ox_target, qb-target), otherwise a key near the ped.

local peds, blips = {}, {}

local function targetResource()
    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end
end

local function addTarget(kind, ped, index)
    if kind == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'pure_clothing_shop_' .. index,
                icon = 'fa-solid fa-shirt',
                label = L('open_shop'),
                distance = Config.OpenDistance + 0.5,
                onSelect = function() Shop.open(index) end,
            },
        })
    elseif kind == 'qb-target' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                { icon = 'fas fa-tshirt', label = L('open_shop'), action = function() Shop.open(index) end },
            },
            distance = Config.OpenDistance + 0.5,
        })
    end
end

local function spawn()
    local kind = targetResource()

    for index, shop in ipairs(Config.Shops) do
        local model = joaat(shop.ped or 'a_f_y_business_02')
        RequestModel(model)
        local deadline = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(50) end

        if HasModelLoaded(model) then
            local c = shop.coords
            local ped = CreatePed(4, model, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedCanRagdoll(ped, false)
            SetPedDiesWhenInjured(ped, false)
            SetModelAsNoLongerNeeded(model)
            peds[index] = ped
            if kind then addTarget(kind, ped, index) end
        end

        if shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite or 73)
            SetBlipColour(blip, shop.blip.color or 47)
            SetBlipScale(blip, shop.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.name or 'Clothing')
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end

    return kind
end

-- Without a target resource: a key near the ped. Nothing runs while no shop is close.
local nearShop

local function keyLoop()
    RegisterCommand('pure_clothing_open', function()
        if nearShop then Shop.open(nearShop) end
    end, false)
    RegisterKeyMapping('pure_clothing_open', L('open_shop'), 'keyboard', Config.OpenKey or 'E')

    CreateThread(function()
        while true do
            local coords = GetEntityCoords(PlayerPedId())
            local closest, best = nil, (Config.OpenDistance or 2.0)
            for index, shop in ipairs(Config.Shops) do
                local dist = #(coords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
                if dist < best then closest, best = index, dist end
            end
            nearShop = closest

            if closest then
                while nearShop do
                    AddTextEntry('PURE_CLOTHING_HELP', L('press_to_open'))
                    BeginTextCommandDisplayHelp('PURE_CLOTHING_HELP')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    Wait(0)
                    local c = GetEntityCoords(PlayerPedId())
                    local shop = Config.Shops[nearShop]
                    if #(c - vector3(shop.coords.x, shop.coords.y, shop.coords.z)) > (Config.OpenDistance or 2.0) + 0.3 then
                        nearShop = nil
                    end
                end
            else
                Wait(1000)
            end
        end
    end)
end

CreateThread(function()
    if Config.EnableShops == false then return end
    local kind = spawn()
    if not kind then keyLoop() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ped in pairs(peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, blip in ipairs(blips) do RemoveBlip(blip) end
end)
