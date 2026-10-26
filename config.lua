Config = {}

---------------------------------------------------------------------------------------------------
-- 1. GENERAL
---------------------------------------------------------------------------------------------------

Config.Locale = 'fr'                -- locales/<code>.json (fr, en)

Config.Debug = false                -- true: every call of the clothing system is printed in the server console

-- Framework: 'auto' (qbx_core, qb-core, es_extended detected at start, else standalone),
-- or force 'qbx', 'qb', 'esx', 'standalone' (players identified by their license, money = the 'money' item).
Config.Framework = 'auto'

-- Inventory: 'auto' (pure_inventory, else ox_inventory), or force 'pure_inventory' / 'ox_inventory'.
Config.Inventory = 'auto'

-- Item that holds one piece of clothing (already defined in pure_inventory; for ox_inventory see the README).
Config.Item = 'clothing'

-- Update check: at start, the server asks GitHub for the latest release and prints a line in the
-- server console when a newer version exists. Nothing is downloaded. false = no request to GitHub.
Config.CheckUpdates = true

---------------------------------------------------------------------------------------------------
-- 2. LOOK OF THE SHOP MENU
---------------------------------------------------------------------------------------------------

-- Picture in the top left corner. Put your own file in the web/ folder (png, jpg, svg or webp, square,
-- 200 x 200 px is enough) and write its name here, e.g. 'logo.png'. false = no picture.
Config.Logo = 'logo.svg'

Config.Theme = {
    Accent = '#c62a3c',                     -- selected tab / tile, buttons, "New" tag
    Background = 'rgba(16, 15, 20, 0.70)',  -- panels (the last number is the opacity: 0 = transparent, 1 = solid)
    Tile = 'rgba(36, 34, 43, 0.66)',        -- clothing tiles
    Text = '#f2f2f7',                       -- main text
    Price = '#39d0a6',                      -- prices
    Scale = 1.0,                            -- size of the whole menu (0.8 = smaller, 1.2 = bigger)
    Columns = 4,                            -- tiles per row
}

Config.Menu = {
    Favorites = true,       -- star on each tile + "favourites only" filter
    HideButton = true,      -- eye button: hide the worn piece while picking the one underneath
    NewTag = true,          -- "New" tag on add-on pieces
    HelpBar = true,         -- mouse / keyboard help at the bottom of the screen
    BuyOneButton = true,    -- "Buy this one" button (buy the selected piece without the rest of the cart)
    ResetButton = true,     -- "Reset" button
}

---------------------------------------------------------------------------------------------------
-- 3. SHOPS
---------------------------------------------------------------------------------------------------

-- false: no shop at all (no ped, no blip, no menu). Keep it when you already have your own clothing shop:
-- the clothing items, the wardrobe, the pictures and the underwear logic still work, and your shop gives
-- the items with the export exports.pure_clothing:GiveClothing(source, slotKey, drawable, texture) (see the README).
Config.EnableShops = true

-- Payment: 'cash' or 'bank'.
Config.Payment = 'cash'

-- How a shop opens: a target menu (pure-target, ox_target, qb-target) when one is running,
-- otherwise a key press near the ped.
Config.OpenKey = 'E'
Config.OpenDistance = 2.0

-- categories: which tabs the shop shows, 'all' or a list of slot keys (see Config.Slots).
-- priceMultiplier: every price of this shop is multiplied by it (3.0 = luxury shop).
Config.Shops = {
    {
        name = 'Binco',
        coords = vector4(425.56, -806.19, 29.49, 94.0),     -- the ped (x, y, z, heading)
        ped = 'a_f_y_business_02',
        blip = { sprite = 73, color = 47, scale = 0.7 },     -- false = no blip
        categories = 'all',
        priceMultiplier = 1.0,
    },
    {
        name = 'Ponsonbys',
        coords = vector4(-708.38, -152.86, 37.42, 118.0),
        ped = 'a_m_y_business_01',
        blip = { sprite = 73, color = 47, scale = 0.7 },
        categories = 'all',
        priceMultiplier = 3.0,
    },
    {
        name = 'Vangelico',
        coords = vector4(-622.46, -230.74, 38.06, 40.0),
        ped = 'a_f_y_business_01',
        blip = { sprite = 617, color = 47, scale = 0.7 },
        categories = { 'watch', 'bracelet', 'ears', 'neck', 'glasses' },
        priceMultiplier = 1.0,
    },
}

---------------------------------------------------------------------------------------------------
-- 4. PIECES OF CLOTHING AND PRICES
---------------------------------------------------------------------------------------------------

-- One line per slot, in the order of the shop tabs. Remove a line to never sell that slot.
-- `key` matches the clothing slots of pure_inventory (the item of a piece goes to that slot).
--   component : GTA component (1 mask, 3 arms/gloves, 4 legs, 5 bag, 6 shoes, 7 neck, 8 undershirt, 9 vest, 10 decals, 11 torso)
--   prop      : GTA prop (0 hat, 1 glasses, 2 ears, 6 watch, 7 bracelet)
--   price     : price of every piece of the slot (before Config.Prices and the shop's multiplier)
--   weight    : weight of the item (grams)
Config.Slots = {
    { key = 'jacket',   component = 11, icon = 'jacket',   price = 120, weight = 600 },
    { key = 'shirt',    component = 8,  icon = 'shirt',    price = 60,  weight = 250 },
    { key = 'gloves',   component = 3,  icon = 'gloves',   price = 40,  weight = 100 },
    { key = 'pants',    component = 4,  icon = 'pants',    price = 90,  weight = 500 },
    { key = 'shoes',    component = 6,  icon = 'shoes',    price = 80,  weight = 600 },
    { key = 'decals',   component = 10, icon = 'decals',   price = 20,  weight = 20 },
    { key = 'neck',     component = 7,  icon = 'neck',     price = 70,  weight = 100 },
    { key = 'mask',     component = 1,  icon = 'mask',     price = 100, weight = 150 },
    { key = 'bag',      component = 5,  icon = 'bag',      price = 150, weight = 500 },
    { key = 'vest',     component = 9,  icon = 'vest',     price = 200, weight = 500 },
    { key = 'hat',      prop = 0,       icon = 'hat',      price = 60,  weight = 150 },
    { key = 'glasses',  prop = 1,       icon = 'glasses',  price = 50,  weight = 50 },
    { key = 'ears',     prop = 2,       icon = 'ears',     price = 80,  weight = 20 },
    { key = 'watch',    prop = 6,       icon = 'watch',    price = 250, weight = 80 },
    { key = 'bracelet', prop = 7,       icon = 'bracelet', price = 120, weight = 50 },
}

-- Price of single pieces, instead of the price of their slot (the shop's multiplier still applies).
--   model    : 'male', 'female' or 'both'
--   key      : slot key
--   drawable : the number shown on the tile ("no. 627"), or a range with from / to (an add-on pack
--              is a block of numbers after the game's own pieces, e.g. jackets 627 to 632)
Config.Prices = {
    -- { model = 'both',   key = 'jacket', from = 627, to = 632, price = 500 },
    -- { model = 'female', key = 'shoes',  drawable = 12,         price = 40 },
}

-- Never sold (same fields, without price): uniforms, special outfits...
Config.Blacklist = {
    -- { model = 'both', key = 'jacket', from = 55, to = 57 },
}

---------------------------------------------------------------------------------------------------
-- 5. UNDERWEAR
---------------------------------------------------------------------------------------------------

-- Drawable (and texture) a component takes when its piece is taken off. Props are simply removed.
-- Values of the base game freemode characters: bare torso and arms, underwear, bare feet.
Config.Naked = {
    male = {
        [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 14, 12 }, [5] = { 0, 0 }, [6] = { 34, 0 },
        [7] = { 0, 0 }, [8] = { 15, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 15, 0 },
    },
    female = {
        [1] = { 0, 0 }, [3] = { 15, 0 }, [4] = { 15, 0 }, [5] = { 0, 0 }, [6] = { 35, 0 },
        [7] = { 0, 0 }, [8] = { 14, 0 }, [9] = { 0, 0 }, [10] = { 0, 0 }, [11] = { 15, 0 },
    },
}

-- Other drawables that leave the character bare: they count as "nothing worn".
--   arms (3) : 0 to 15 are sleeve / skin variants without gloves (the gloves start at 16)
--   torso 252 / 74 and legs 61 / 14 : used by qb-radialmenu to undress
-- A number, or a range { from = a, to = b }.
Config.BareDrawables = {
    male = { [3] = { { from = 0, to = 15 } }, [11] = { 252 }, [4] = { 61 } },
    female = { [3] = { { from = 0, to = 15 } }, [11] = { 74 }, [4] = { 14 } },
}

-- After the player is loaded, the clothes he changed are applied again as soon as your appearance script
-- dressed the character (checked every 250 ms, up to ApplyTimeout ms), after a first delay of ApplyDelay ms.
Config.ApplyDelay = 500
Config.ApplyTimeout = 10000

-- Without pure_inventory: a piece taken off by another script (radial menu, "remove shirt" option...)
-- becomes an item in the inventory, like a piece taken off in the wardrobe. false = it is put back on.
Config.AutoTakeOff = true

---------------------------------------------------------------------------------------------------
-- 6. CAMERA OF THE SHOP
---------------------------------------------------------------------------------------------------

Config.Camera = {
    Fov = 40.0,
    Distance = { min = 0.55, max = 2.8, start = 2.4 },  -- metres from the character
    Height = { min = -0.85, max = 0.7, start = -0.05 }, -- metres from the centre of the character
}
