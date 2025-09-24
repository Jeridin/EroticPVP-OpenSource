core.spawnCoords = vector4(231.1525, -1390.9653, 30.4999, 339.3951)
core.defaultModel = "mp_m_freemode_01"
core.currentMode = "lobby" -- default when joining (can be "lobby", "ffa", "duel", "ranked4v4", etc.)

function core.loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

function core.spawnPlayer(coords)
    local modelHash = core.loadModel(core.defaultModel)
    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)

    local ped = PlayerPedId()
    local spawnPos = coords or core.spawnCoords

    RequestCollisionAtCoord(spawnPos.x, spawnPos.y, spawnPos.z)

    SetEntityCoordsNoOffset(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(ped, spawnPos.w)

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true)
    SetPlayerInvincible(PlayerId(), false)

    -- Basic clothing
    SetPedComponentVariation(ped, 3, 15, 0, 0)
    SetPedComponentVariation(ped, 4, 21, 0, 0)
    SetPedComponentVariation(ped, 6, 34, 0, 0)
    SetPedComponentVariation(ped, 11, 15, 0, 0)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    print("[erotic-core] Player spawned successfully in mode: " .. core.currentMode)
end

-- Default lobby spawn on join
AddEventHandler("onClientResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    core.currentMode = "lobby"
    core.spawnPlayer()
end)

-- Enable PVP
RegisterNetEvent("erotic-core:enablePVP", function()
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(PlayerPedId(), true, true)
end)

-- Re-assert PVP and handle respawn depending on mode
CreateThread(function()
    while true do
        Wait(2000)
        local ped = PlayerPedId()
        SetCanAttackFriendly(ped, true, true)

        if core.currentMode == "lobby" then
            if IsEntityDead(ped) then
                print("[erotic-core] Lobby death. Respawning")
                Wait(100)
                core.spawnPlayer()
            end
        elseif core.currentMode == "ffa" then
            -- handled by FFA logic, do nothing here
        elseif core.currentMode == "duel" or core.currentMode == "ranked4v4" then
            -- handled by match logic, do nothing here
        end
    end
end)
