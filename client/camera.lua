-- Camera of the shop: orbits around the character, driven by the mouse through the menu
-- (left drag turns the character, right drag orbits, wheel zooms towards the point under the cursor).

Camera = {}

local cfg = Config.Camera
local LAT_MAX = 0.6
local ELEV_START = 1.0
local SMOOTH = 0.18
local WALL_MARGIN, WALL_MIN = 0.15, 0.3
local RAY_FLAGS = 1 + 16

local active, cam = false, nil
local base, anchorZ
local target, current = {}, {}

local function vectors(heading)
    local h = math.rad(heading)
    local forward = vector3(-math.sin(h), math.cos(h), 0.0)
    local right = vector3(-math.cos(h), -math.sin(h), 0.0)
    return forward, right
end

local function obstacle(a, b)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(a.x, a.y, a.z, b.x, b.y, b.z, RAY_FLAGS, PlayerPedId(), 4)
    local _, hit, pos = GetShapeTestResult(ray)
    if hit == 1 or hit == true then return vector3(pos.x, pos.y, pos.z) end
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

local function place(v)
    local forward, right = vectors(v.cap)
    local point = vector3(base.x, base.y, anchorZ) + right * v.lat + vector3(0.0, 0.0, v.height)
    local e = math.rad(v.elev)
    local dir = forward * math.cos(e) + vector3(0.0, 0.0, math.sin(e))
    local dist = v.dist
    local wall = obstacle(point, point + dir * dist)
    if wall then dist = math.max(WALL_MIN, #(wall - point) - WALL_MARGIN) end
    local pos = point + dir * dist
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    PointCamAtCoord(cam, point.x, point.y, point.z)
end

function Camera.start()
    local ped = PlayerPedId()
    base = GetEntityCoords(ped)
    anchorZ = base.z
    local heading = GetEntityHeading(ped)
    target = { dist = cfg.Distance.start, height = cfg.Height.start, lat = 0.0, cap = heading, elev = ELEV_START }
    current = { dist = cfg.Distance.start, height = cfg.Height.start, lat = 0.0, cap = heading, elev = ELEV_START }
    cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cfg.Fov, false, 0)
    place(current)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    active = true

    CreateThread(function()
        local placed, next = {}, 0
        while active and cam do
            anchorZ = anchorZ + (GetEntityCoords(PlayerPedId()).z - anchorZ) * SMOOTH
            local moved = math.abs(anchorZ - (placed.anchorZ or math.huge)) > 1e-4
            for k, v in pairs(target) do
                current[k] = current[k] + (v - current[k]) * SMOOTH
                if math.abs(current[k] - (placed[k] or math.huge)) > 1e-4 then moved = true end
            end
            local now = GetGameTimer()
            if moved or now >= next then
                place(current)
                for k, v in pairs(current) do placed[k] = v end
                placed.anchorZ, next = anchorZ, now + 250
            end
            Wait(0)
        end
    end)
end

function Camera.stop()
    if not active then return end
    active = false
    RenderScriptCams(false, true, 500, true, true)
    if cam then DestroyCam(cam, false) end
    cam = nil
end

RegisterNUICallback('camRotate', function(data, cb)
    cb(1)
    local dx = tonumber(data and data.dx)
    if not active or not dx then return end
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + clamp(dx, -1.0, 1.0) * 360.0)
end)

RegisterNUICallback('camOrbit', function(data, cb)
    cb(1)
    local dx = tonumber(data and data.dx)
    if not active or not dx then return end
    target.cap = target.cap - clamp(dx, -1.0, 1.0) * 360.0
    target.lat = 0.0
end)

RegisterNUICallback('camZoom', function(data, cb)
    cb(1)
    if not active or type(data) ~= 'table' then return end
    local x, y = tonumber(data.x) or 0.5, tonumber(data.y) or 0.5
    local before = target.dist
    local after = clamp(before * ((tonumber(data.dir) or 0) > 0 and 0.85 or 1 / 0.85), cfg.Distance.min, cfg.Distance.max)
    if after == before then
        if after >= cfg.Distance.max then target.height, target.lat = cfg.Height.start, 0.0 end
        return
    end
    -- zoom towards the point under the cursor
    local half = math.tan(math.rad(cfg.Fov / 2)) * before
    local zc = target.height + (0.5 - y) * 2 * half
    local xc = target.lat + (x - 0.5) * 2 * half * GetAspectRatio(false)
    local r = after / before
    target.dist = after
    target.height = clamp(zc - (zc - target.height) * r, cfg.Height.min, cfg.Height.max)
    target.lat = clamp(xc - (xc - target.lat) * r, -LAT_MAX, LAT_MAX)
    if after >= cfg.Distance.max then target.height, target.lat = cfg.Height.start, 0.0 end
end)
