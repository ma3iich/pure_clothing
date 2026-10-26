-- Shared by the client and the server: texts, models, slots, prices.

local texts = {}

do
    local resource = GetCurrentResourceName()
    local raw = LoadResourceFile(resource, ('locales/%s.json'):format(Config.Locale or 'en'))
        or LoadResourceFile(resource, 'locales/en.json')
    local ok, decoded = pcall(json.decode, raw or '{}')
    texts = ok and type(decoded) == 'table' and decoded or {}
end

---Text of the current locale; %s / %d are replaced by the extra arguments.
function L(key, ...)
    local s = texts[key] or key
    local n = select('#', ...)
    if n > 0 then
        local args, i = { ... }, 0
        s = s:gsub('%%[sd]', function()
            i = i + 1
            return tostring(args[i] == nil and '' or args[i])
        end)
    end
    return s
end

function Texts() return texts end

Models = { male = `mp_m_freemode_01`, female = `mp_f_freemode_01` }

---'male' / 'female' for the freemode characters, nil for any other model.
function GenderOfModel(model)
    if model == Models.male then return 'male' end
    if model == Models.female then return 'female' end
end

SlotsByKey = {}
for _, slot in ipairs(Config.Slots) do
    SlotsByKey[slot.key] = slot
end

---Drawable and texture a slot takes when nothing is worn.
function NakedOf(gender, slot)
    if slot.prop then return { d = -1, t = 0 } end
    local naked = Config.Naked[gender] and Config.Naked[gender][slot.component] or { 0, 0 }
    return { d = naked[1] or 0, t = naked[2] or 0 }
end

---Is nothing worn in this slot? (the naked value, a bare drawable of another script, or no prop)
function IsBare(gender, slot, piece)
    if slot.prop then return piece.d < 0 end
    if piece.d == NakedOf(gender, slot).d then return true end
    local list = Config.BareDrawables and Config.BareDrawables[gender] and Config.BareDrawables[gender][slot.component]
    for _, d in ipairs(list or {}) do
        if type(d) == 'table' then
            if piece.d >= (d.from or 0) and piece.d <= (d.to or -1) then return true end
        elseif piece.d == d then
            return true
        end
    end
    return false
end

local function matches(entry, gender, key, drawable)
    if entry.key ~= key then return false end
    if entry.model ~= 'both' and entry.model ~= gender then return false end
    if entry.drawable then return entry.drawable == drawable end
    return entry.from and entry.to and drawable >= entry.from and drawable <= entry.to
end

---Does this shop show that slot?
function ShopSells(shop, key)
    if shop.categories == 'all' then return true end
    for _, k in ipairs(shop.categories or {}) do
        if k == key then return true end
    end
    return false
end

---Price of a piece in a shop, or nil when it is blacklisted.
function PriceOf(gender, slot, drawable, shop)
    for _, entry in ipairs(Config.Blacklist or {}) do
        if matches(entry, gender, slot.key, drawable) then return nil end
    end

    local price = slot.price or 0

    for _, entry in ipairs(Config.Prices or {}) do
        if matches(entry, gender, slot.key, drawable) then price = entry.price end
    end

    return math.floor(price * (shop.priceMultiplier or 1.0) + 0.5)
end
