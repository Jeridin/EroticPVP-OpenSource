local lobbySpawn = vector4(231.15, -1390.96, 30.49, 339.39)

RegisterNetEvent("erotic-core:customWorldEnter", function(data)
    core.currentMode = "custom"
    core.applyGameSettings("custom")

    local spawn = data and data.spawn or core.gamemodeSettings.custom.defaultSpawn or core.spawnCoords
    local ped = PlayerPedId()

    if IsEntityDead(ped) then
        ResurrectPed(ped)
        ClearPedTasksImmediately(ped)
    end

    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.w)

    local worldName = (data and data.name) or "Personal Arena"
    print(("[erotic-core] Entered %s"):format(worldName))
end)

RegisterNetEvent("erotic-core:customWorldExit", function()
    core.currentMode = "lobby"
    local ped = PlayerPedId()
    local spawn = lobbySpawn

    if IsEntityDead(ped) then
        ResurrectPed(ped)
        ClearPedTasksImmediately(ped)
    end

    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.w)

    print("[erotic-core] Left custom arena. Returning to lobby.")
end)
