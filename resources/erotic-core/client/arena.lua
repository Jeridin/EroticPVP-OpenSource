-- Arena spawn points
local arenaSpawns = {
    vector4(200.0, -900.0, 30.0, 90.0),
    vector4(205.0, -900.0, 30.0, 270.0)
}

RegisterNetEvent("erotic-core:arenaSpawn", function(bucketId, slot)
    local ped = PlayerPedId()
    local coords = arenaSpawns[slot] or arenaSpawns[1]
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    Wait(1000)
    
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    print(("[erotic-core] Spawned in arena bucket %d at slot %d"):format(bucketId, slot))
end)

-- detect death and notify server
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            TriggerServerEvent("erotic-core:playerDied")
            -- wait until respawn handled
            while IsEntityDead(ped) do Wait(500) end
        end
    end
end)

RegisterNetEvent("erotic-core:arenaEnd", function(match, winner)
    local ped = PlayerPedId()
    local lobby = vector4(231.15, -1390.96, 30.49, 339.39)

    SetEntityCoordsNoOffset(ped, lobby.x, lobby.y, lobby.z, false, false, false, true)
    SetEntityHeading(ped, lobby.w)

    if winner then
        if GetPlayerServerId(PlayerId()) == winner then
            print("[erotic-core] You won the match!")
        else
            print("[erotic-core] You lost. Winner: " .. GetPlayerName(GetPlayerFromServerId(winner)))
        end
    else
        print("[erotic-core] Match ended in a draw.")
    end
end)
