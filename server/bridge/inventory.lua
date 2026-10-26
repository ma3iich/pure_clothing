-- The inventory that receives the clothing items: pure_inventory, or ox_inventory.
-- pure_inventory also answers to the name ox_inventory, so it is checked first.

Inventory = { name = nil }

local function started(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

do
    local wanted = Config.Inventory or 'auto'
    if wanted == 'auto' then
        if started('pure_inventory') then Inventory.name = 'pure_inventory'
        elseif started('ox_inventory') then Inventory.name = 'ox_inventory'
        end
    elseif started(wanted) then
        Inventory.name = wanted
    end

    if not Inventory.name then
        print('^1[pure_clothing] no inventory found (pure_inventory or ox_inventory): the shops cannot give items^0')
    end
end

local function inv() return exports[Inventory.name] end

function Inventory.canCarry(src, item, count, metadata)
    if not Inventory.name then return false end
    local ok, result = pcall(function() return inv():CanCarryItem(src, item, count, metadata) end)
    return ok and result == true
end

---Returns true when the item was added (`slot`: a precise inventory slot, optional).
function Inventory.addItem(src, item, count, metadata, slot)
    if not Inventory.name then return false end
    local ok, result = pcall(function() return inv():AddItem(src, item, count, metadata, slot) end)
    return ok and result ~= false and result ~= nil
end

---The item held in an inventory slot ({ name, count, metadata }) or nil.
function Inventory.getSlot(src, slot)
    if not Inventory.name then return end
    local ok, result = pcall(function() return inv():GetSlot(src, slot) end)
    return ok and type(result) == 'table' and result or nil
end

function Inventory.getItemCount(src, item)
    if not Inventory.name then return 0 end
    local ok, result = pcall(function() return inv():GetItemCount(src, item) end)
    return ok and tonumber(result) or 0
end

---Returns true when the items were removed (`slot`: only from that inventory slot, optional).
function Inventory.removeItem(src, item, count, slot)
    if not Inventory.name then return false end
    local ok, result = pcall(function() return inv():RemoveItem(src, item, count, nil, slot) end)
    return ok and result ~= false and result ~= nil
end
