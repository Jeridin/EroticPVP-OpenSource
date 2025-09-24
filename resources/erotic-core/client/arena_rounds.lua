core = core or {}
core.currentMode = core.currentMode or "lobby"
local sentDeath = false

-- Round spawns (duel/4v4)
RegisterNetEvent("erotic-core:arenaRoundSpawn", function(gamemode, side, spawn)
    core.currentMode = gamemode
    local ped = PlayerPedId()

    -- if dead, force resurrection
    if IsEntityDead(ped) then
        ResurrectPed(ped)
        ClearPedTasksImmediately(ped)
    end

    -- move and reset
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.w)

    -- heal and armor up
    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

    -- clear wanted level or weird states
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedTasksImmediately(ped)

    -- reset death flag for this round
    sentDeath = false  

    print(("[erotic-core] Round spawn: %s at (%.2f, %.2f, %.2f)")
        :format(side, spawn.x, spawn.y, spawn.z))
end)

-- Round end feedback (you can hook UI here later)
RegisterNetEvent("erotic-core:arenaRoundEnd", function(roundNumber, winningSide, scores)
    -- print or show toast
    print(("[erotic-core] Round %d ended. Winner: %s | A:%d B:%d")
        :format(roundNumber, tostring(winningSide), scores.A, scores.B))
end)

-- Match end -> send to lobby (server calls disableBlips separately)
RegisterNetEvent("erotic-core:arenaMatchEnd", function(winningSide, scores)
    print(("[erotic-core] Match ended. Winner: %s | A:%d B:%d")
        :format(tostring(winningSide), scores.A, scores.B))
end)

RegisterNetEvent("erotic-core:arenaEndToLobby", function()
    core.currentMode = "lobby"
    -- use your existing lobby spawn function
    core.spawnPlayer()
end)

-- Debounced “I died” notifier for round modes
CreateThread(function()
    while true do
        Wait(300)
        if core.currentMode == "duel" or core.currentMode == "ranked4v4" then
            local ped = PlayerPedId()
            if not sentDeath and IsEntityDead(ped) then
                sentDeath = true
                TriggerServerEvent("erotic-core:playerDiedOnce")
            elseif sentDeath and not IsEntityDead(ped) then
                -- reset when server respawns you next round
                sentDeath = false
            end
        end
    end
end)
