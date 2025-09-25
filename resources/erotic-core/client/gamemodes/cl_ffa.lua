core = core or {}

local wasDead = false
local worldStats = {}  -- [worldId] = {kills=0, deaths=0, damageDealt=0}

---------------------------------------------------
-- helper to get current world stat table
---------------------------------------------------
local function getStats()
    if not core.currentWorldId then return {kills=0, deaths=0, damageDealt=0} end
    worldStats[core.currentWorldId] = worldStats[core.currentWorldId] or {kills=0, deaths=0, damageDealt=0}
    return worldStats[core.currentWorldId]
end

-- spawn directly when server tells us
RegisterNetEvent("erotic-core:spawnAt", function(spawn)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.h, true, true, false)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.h)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
end)

-- world info sync
RegisterNetEvent("erotic-core:worldJoined", function(world)
    core.currentWorldId = world.id
    core.currentMode = world.information.gamemode
    core.currentSpawns = world.spawns or {}
    local stats = getStats()
    stats.kills, stats.deaths, stats.damageDealt = 0, 0, 0
end)

-- watch for death/respawn just for FFA
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if core.currentMode == "ffa" and dead and not wasDead then
            if core.currentSpawns and #core.currentSpawns > 0 then
                local s = core.currentSpawns[math.random(#core.currentSpawns)]
                DoScreenFadeOut(500)
                Wait(1000)
                while not IsScreenFadedOut() do Wait(0) end

                NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
                RequestCollisionAtCoord(s.x, s.y, s.z)
                SetEntityCoordsNoOffset(ped, s.x, s.y, s.z, false, false, false, true)
                SetEntityHeading(ped, s.h or 0.0)
                ClearPedBloodDamage(ped)
                ClearPedTasksImmediately(ped)
                Wait(100)
                SetEntityHealth(PlayerPedId(), 200)
                SetPedArmour(PlayerPedId(), 100)

                DoScreenFadeIn(500)

                -- death count
                local stats = getStats()
                stats.deaths = stats.deaths + 1
                print(("[erotic-core] Death. K:%d D:%d"):format(stats.kills, stats.deaths))
            end
        end
        wasDead = dead
        Wait(200)
    end
end)

---------------------------------------------------
-- Damage tracking + kill detection (optimized, no thread)
---------------------------------------------------
local APPLY_DELAY_MS = 50
local ARMOR_VALUE    = 1.0

local vitals   = {}    -- [ped] = { hp=?, ar=? }
local deadPeds = {}    -- peds already killed so we ignore ghost packets

local function decodeEventDamage(rawDamage, fatal)
    if not rawDamage then return 0 end
    local dmg = string.unpack("f", string.pack("i4", rawDamage))
    if fatal and dmg > 100 then dmg = dmg - 100 end
    return math.max(0, math.floor(dmg))
end

AddEventHandler("gameEventTriggered", function(name, args)
    if name ~= "CEventNetworkEntityDamage" then return end

    local victim, attacker, rawDamage, _, _, fatal = table.unpack(args)
    if attacker ~= PlayerPedId() or victim == PlayerPedId() or not IsPedAPlayer(victim) then return end

    -- if flagged dead and still dead, ignore ghost packet
    if deadPeds[victim] then
        if not IsEntityDead(victim) then deadPeds[victim] = nil else return end
    end

    -- snapshot pre-hit vitals
    local prev = vitals[victim]
    local prevHP = prev and prev.hp or GetEntityHealth(victim)
    local prevAR = prev and prev.ar or GetPedArmour(victim)

    local eventDmg = decodeEventDamage(rawDamage, fatal)

    SetTimeout(APPLY_DELAY_MS, function()
        local currHP, currAR = GetEntityHealth(victim), GetPedArmour(victim)

        -- one more tick to catch delayed armor/HP update
        Wait(0)
        local tmpHP, tmpAR = GetEntityHealth(victim), GetPedArmour(victim)
        if tmpHP < currHP then currHP = tmpHP end
        if tmpAR < currAR then currAR = tmpAR end

        local hpLoss = math.max(0, prevHP - currHP)
        local arLoss = math.max(0, prevAR - currAR)
        local raw = hpLoss + arLoss * ARMOR_VALUE

        -- clamp kill shot
        if currHP <= 0 then
            local maxPossible = prevHP + prevAR * ARMOR_VALUE
            if raw > maxPossible then raw = maxPossible end
        end

        local dmg = raw > 0 and raw or eventDmg

        if dmg > 0 then
            local stats = getStats()
            stats.damageDealt = (stats.damageDealt or 0) + dmg
            print(("[erotic-core] Damage dealt: +%d (H-%d A-%d | Total %d)")
                :format(dmg, hpLoss, arLoss, stats.damageDealt))
        end

        if currHP <= 0 then
            local stats = getStats()
            stats.kills = (stats.kills or 0) + 1
            deadPeds[victim] = true
            print(("[erotic-core] Kill registered. K:%d D:%d)")
                :format(stats.kills, stats.deaths or 0))
        end

        vitals[victim] = { hp = currHP, ar = currAR }
    end)
end)