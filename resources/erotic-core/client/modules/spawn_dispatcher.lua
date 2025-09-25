core = core or {}
core.spawnHandlers = core.spawnHandlers or {}

---------------------------------------------------
-- Teleport & heal util
---------------------------------------------------
function core.teleportAndHeal(s)
    local ped = PlayerPedId()
    DoScreenFadeOut(150)
    while not IsScreenFadedOut() do Wait(0) end

    NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
    RequestCollisionAtCoord(s.x, s.y, s.z)
    SetEntityCoordsNoOffset(ped, s.x, s.y, s.z, false, false, false, true)
    SetEntityHeading(ped, s.h or 0.0)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

    DoScreenFadeIn(150)
end

---------------------------------------------------
-- Detect death, classify cause
---------------------------------------------------
local wasDead = false
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if dead and not wasDead and core.currentMode then
            local killer = GetPedSourceOfDeath(ped)
            local killerId = killer and NetworkGetPlayerIndexFromPed(killer) or -1

            local deathType
            if killerId ~= -1 then
                local killerServerId = GetPlayerServerId(killerId)
                if killerServerId ~= GetPlayerServerId(PlayerId()) then
                    -- killed by other player
                    deathType = "player"
                else
                    -- suicide/self-inflicted
                    deathType = "self"
                end
            else
                deathType = "natural" -- fall damage, NPC, vehicle, explosion, etc.
            end

            local handler = core.spawnHandlers[core.currentMode]
            if handler and handler.onDeath then
                handler.onDeath(deathType)
            end
        end

        wasDead = dead
        Wait(200)
    end
end)

---------------------------------------------------
-- Detect kills we do to others
---------------------------------------------------
AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local attacker = args[2]

    if attacker == PlayerPedId() and IsPedAPlayer(victim) then
        local victimServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victim))
        local killerServerId = GetPlayerServerId(PlayerId())

        local handler = core.spawnHandlers[core.currentMode]
        if handler and handler.onPlayerKilled then
            handler.onPlayerKilled(killerServerId, victimServerId)
        end
    end
end)
