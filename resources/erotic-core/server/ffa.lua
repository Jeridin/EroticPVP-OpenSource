core.ffaPlayers = core.ffaPlayers or {}

-- join FFA event
RegisterNetEvent("erotic-core:joinFFA", function(src)
    local settings = core.gamemodeSettings.ffa
    if not settings then return end

    SetPlayerRoutingBucket(src, settings.bucket)
    core.ffaPlayers[src] = true

    TriggerClientEvent("erotic-core:setMode", src, "ffa")
    TriggerClientEvent("erotic-core:ffaEnter", src, settings.spawns)

    core.updateFFABlips()

    print(("[erotic-core] %s joined FFA"):format(GetPlayerName(src)))
end)

-- leave FFA event
RegisterNetEvent("erotic-core:leaveFFA", function(src)
    core.ffaPlayers[src] = nil
    SetPlayerRoutingBucket(src, 0)

    TriggerClientEvent("erotic-core:setMode", src, "lobby")
    TriggerClientEvent("erotic-core:ffaExit", src)

    core.updateFFABlips()

    print(("[erotic-core] %s left FFA"):format(GetPlayerName(src)))
end)

-- cleanup on disconnect
AddEventHandler("playerDropped", function()
    core.ffaPlayers[source] = nil
    core.updateFFABlips()
end)

RegisterCommand("joinffa", function(src)
    TriggerEvent("erotic-core:joinFFA", src)
end, false)

RegisterCommand("leaveffa", function(src)
    TriggerEvent("erotic-core:leaveFFA", src)
end, false)

function core.updateFFABlips()
    local settings = core.gamemodeSettings.ffa
    if not settings or not settings.blips then return end

    -- collect all current FFA player IDs
    local players = {}
    for id, _ in pairs(core.ffaPlayers) do
        table.insert(players, id)
    end

    -- tell everyone in FFA who to track
    for id, _ in pairs(core.ffaPlayers) do
        TriggerClientEvent("erotic-core:enableBlips", id, players, settings.blipInterval or 3000)
    end
end
