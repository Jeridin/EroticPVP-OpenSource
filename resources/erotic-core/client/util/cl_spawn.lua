core.spawnCoords = vector4(231.1525, -1390.9653, 30.4999, 339.3951)
core.defaultModel = "mp_m_freemode_01"

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

    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

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
end

-- Default lobby spawn on join
AddEventHandler("onClientResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    
    -- Spawn the player
    core.spawnPlayer()
    
    -- Wait for spawn to complete, then trigger player loaded
    Wait(2000)
    ShutdownLoadingScreenNui()
    exports['ui']:ToggleLobbyPage(true)
    ShutdownLoadingScreen()
end)

-- Enable PVP
RegisterNetEvent("erotic-core:enablePVP", function()
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(PlayerPedId(), true, true)
end)
