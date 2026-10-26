-- Who the player is and his money: QBCore / Qbox / ESX, or standalone (license + 'money' item).

Framework = { name = 'standalone' }

local function started(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

do
    local wanted = Config.Framework or 'auto'
    if wanted == 'auto' then
        if started('qbx_core') then Framework.name = 'qbx'
        elseif started('qb-core') then Framework.name = 'qb'
        elseif started('es_extended') then Framework.name = 'esx'
        end
    else
        Framework.name = wanted
    end
end

local core

local function qb()
    if not core then core = exports['qb-core']:GetCoreObject() end
    return core
end

local function esx()
    if not core then core = exports.es_extended:getSharedObject() end
    return core
end

local function player(src)
    if Framework.name == 'qbx' then return exports.qbx_core:GetPlayer(src) end
    if Framework.name == 'qb' then return qb().Functions.GetPlayer(src) end
    if Framework.name == 'esx' then return esx().GetPlayerFromId(src) end
end

---Identifier of the character (citizenid, ESX identifier, or the license in standalone).
function Framework.identifier(src)
    if Framework.name == 'standalone' then
        return GetPlayerIdentifierByType(src, 'license')
    end
    local p = player(src)
    if not p then return end
    if Framework.name == 'esx' then return p.identifier end
    return p.PlayerData and p.PlayerData.citizenid
end

---@param account 'cash' | 'bank'
function Framework.getMoney(src, account)
    if Framework.name == 'standalone' then
        return Inventory.getItemCount(src, 'money')
    end
    local p = player(src)
    if not p then return 0 end
    if Framework.name == 'esx' then
        if account == 'bank' then
            local acc = p.getAccount('bank')
            return acc and acc.money or 0
        end
        return p.getMoney()
    end
    return p.Functions.GetMoney(account) or 0
end

---Takes the money; returns true when it was taken.
function Framework.removeMoney(src, amount, account, reason)
    if amount <= 0 then return true end
    if Framework.getMoney(src, account) < amount then return false end
    if Framework.name == 'standalone' then
        return Inventory.removeItem(src, 'money', amount)
    end
    local p = player(src)
    if not p then return false end
    if Framework.name == 'esx' then
        if account == 'bank' then p.removeAccountMoney('bank', amount, reason) else p.removeMoney(amount, reason) end
        return true
    end
    return p.Functions.RemoveMoney(account, amount, reason) ~= false
end

function Framework.addMoney(src, amount, account, reason)
    if amount <= 0 then return end
    if Framework.name == 'standalone' then
        return Inventory.addItem(src, 'money', amount)
    end
    local p = player(src)
    if not p then return end
    if Framework.name == 'esx' then
        if account == 'bank' then p.addAccountMoney('bank', amount, reason) else p.addMoney(amount, reason) end
        return
    end
    p.Functions.AddMoney(account, amount, reason)
end
