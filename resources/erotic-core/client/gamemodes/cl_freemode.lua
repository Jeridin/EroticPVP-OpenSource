core = core or {}
local wasDead = false
local alreadySpawned = false

RegisterNetEvent("erotic-core:worldJoined", function(world)
    core.currentWorldId = world.id
    core.currentMode = world.gamemode
    core.currentSpawns = world.spawns or {}

    if core.currentMode == "freemode" and not alreadySpawned then
        -- teleport to first spawn immediately on join
        if #core.currentSpawns > 0 then
            local s = core.currentSpawns[1]
            DoScreenFadeOut(150)
            while not IsScreenFadedOut() do Wait(0) end

            NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
            RequestCollisionAtCoord(s.x, s.y, s.z)
            SetEntityCoordsNoOffset(PlayerPedId(), s.x, s.y, s.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), s.h or 0.0)

            SetEntityHealth(PlayerPedId(), 200)
            AddArmourToPed(PlayerPedId(), 100)

            DoScreenFadeIn(150)
            alreadySpawned = true
        end
    end
end)

-- basic death/respawn loop just for freemode
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if core.currentMode == "freemode" and dead and not wasDead then
            if core.currentSpawns and #core.currentSpawns > 0 then
                local s = core.currentSpawns[1] -- freemode always first spawn
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
        end

        wasDead = dead
        Wait(200)
    end
end)
