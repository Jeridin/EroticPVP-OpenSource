core.spawnCoords = vector4(231.1525, -1390.9653, 30.4999, 339.3951)
core.defaultModel = "mp_m_freemode_01"

function core.loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

function core.spawnPlayer()
    local modelHash = core.loadModel(core.defaultModel)
    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)

    RequestCollisionAtCoord(core.spawnCoords.x, core.spawnCoords.y, core.spawnCoords.z)

    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, core.spawnCoords.x, core.spawnCoords.y, core.spawnCoords.z, false, false, false, true)
    SetEntityHeading(ped, core.spawnCoords.w)

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
    print("[erotic-core] Player spawned successfully.")
end

function core.deathWatcher()
    CreateThread(function()
        while true do
            Wait(500)
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                print("[erotic-core] Player died. Respawning in 3 seconds...")
                Wait(3000)
                core.spawnPlayer()
            end
        end
    end)
end

AddEventHandler("onClientResourceStart", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    core.spawnPlayer()
    core.deathWatcher()
end)
