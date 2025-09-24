core.ffaPlayers = core.ffaPlayers or {}

RegisterCommand("joinffa", function(src)
    local settings = core.gamemodeSettings.ffa
    if not settings then return end

    SetPlayerRoutingBucket(src, settings.bucket)
    core.ffaPlayers[src] = true

    TriggerClientEvent("erotic-core:ffaEnter", src, settings.spawns)

    -- update blips for *all* players in FFA
    core.updateFFABlips()

    print(("[erotic-core] %s joined FFA"):format(GetPlayerName(src)))
end, false)

RegisterCommand("leaveffa", function(src)
    core.ffaPlayers[src] = nil
    SetPlayerRoutingBucket(src, 0)
    TriggerClientEvent("erotic-core:setMode", src, "lobby")

    TriggerClientEvent("erotic-core:ffaExit", src)

    -- update blips for the rest
    core.updateFFABlips()

    print(("[erotic-core] %s left FFA"):format(GetPlayerName(src)))
end, false)

AddEventHandler("playerDropped", function()
    core.ffaPlayers[source] = nil
    core.updateFFABlips()
end)

-- helper to rebuild blip lists for all FFA players
function core.updateFFABlips()
    local settings = core.gamemodeSettings.ffa
    if not settings.blips then return end

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
