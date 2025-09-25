core = core or {}

local wasDead = false
local alreadySpawned = false

RegisterNetEvent("erotic-core:worldJoined", function(world)
    alreadySpawned = false

    core.currentWorldId = world.id
    core.currentMode    = world.information.gamemode
    core.currentSpawns  = world.spawns or {}

    -- spawn once on join if we’re in freemode
    if core.currentMode == "freemode" and not alreadySpawned and #core.currentSpawns > 0 then
        local s   = core.currentSpawns[1]
        local ped = PlayerPedId()

        DoScreenFadeOut(150)
        while not IsScreenFadedOut() do Wait(0) end

        NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
        RequestCollisionAtCoord(s.x, s.y, s.z)
        SetEntityCoordsNoOffset(ped, s.x, s.y, s.z, false, false, false, true)
        SetEntityHeading(ped, s.h or 0.0)

        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)

        DoScreenFadeIn(150)
        alreadySpawned = true
    end
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if core.currentMode == "freemode" and dead and not wasDead and #core.currentSpawns > 0 then
            local s = core.currentSpawns[1]

            DoScreenFadeOut(500)
            Wait(1000)
            while not IsScreenFadedOut() do Wait(0) end

            NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
            RequestCollisionAtCoord(s.x, s.y, s.z)
            SetEntityCoordsNoOffset(ped, s.x, s.y, s.z, false, false, false, true)
            SetEntityHeading(ped, s.h or 0.0)
            ClearPedBloodDamage(ped)
            ClearPedTasksImmediately(ped)

            Wait(250)
            SetEntityHealth(PlayerPedId(), 200)
            SetPedArmour(PlayerPedId(), 100)

            DoScreenFadeIn(500)
        end

        wasDead = dead
        Wait(200)
    end
end)
