core = core or {}

local wasDead = false

-- server tells us where to spawn
RegisterNetEvent("erotic-core:spawnAt", function(spawn)
    local ped = PlayerPedId()

    -- clear death state if needed
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.h, true, true, false)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.h)

    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)
end)

-- keep track of which world/mode we’re in
RegisterNetEvent("erotic-core:worldJoined", function(world)
    core.currentWorldId = world.id
    core.currentMode = world.gamemode
    core.currentSpawns = world.spawns or {}
end)

-- tiny death watcher just for FFA
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if core.currentMode == "ffa" and dead and not wasDead then
            -- pick random spawn locally
            if core.currentSpawns and #core.currentSpawns > 0 then
                local s = core.currentSpawns[math.random(#core.currentSpawns)]
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