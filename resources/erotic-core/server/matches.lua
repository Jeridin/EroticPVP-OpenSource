core.matches = {}
core.nextBucket = 1

core.gamemodeSettings = {
    duel = { blips = true, blipInterval = 3000 },    -- breadcrumb every 3s
    ranked4v4 = { blips = true, blipInterval = 5000 }, -- slower updates
    ffa = { blips = false }
}

function core.createMatch(players, gamemode)
    local bucketId = core.nextBucket
    core.nextBucket = core.nextBucket + 1

    core.matches[bucketId] = {
        id = bucketId,
        players = players,
        gamemode = gamemode,
        started = os.time(),
        alive = {}
    }

    for i, src in ipairs(players) do
        SetPlayerRoutingBucket(src, bucketId)
        core.matches[bucketId].alive[src] = true
        TriggerClientEvent("erotic-core:arenaSpawn", src, bucketId, i)
    end

    -- tell clients to enable blips if gamemode allows it
    local settings = core.gamemodeSettings[gamemode] or {}
    if settings.blips then
        for _, src in ipairs(players) do
            TriggerClientEvent("erotic-core:enableBlips", src, players, settings.blipInterval or 3000)
        end
    end

    print(("[erotic-core] Match %d started (%s) with %d players"):format(bucketId, gamemode, #players))
end

-- Death tracking is same as before
RegisterNetEvent("erotic-core:playerDied", function()
    local src = source
    local bucketId = GetPlayerRoutingBucket(src)
    local match = core.matches[bucketId]
    if not match then return end

    match.alive[src] = false

    -- check survivors
    local survivors = {}
    for _, p in ipairs(match.players) do
        if match.alive[p] then
            table.insert(survivors, p)
        end
    end

    if #survivors <= 1 then
        core.endMatch(bucketId, survivors[1])
    end
end)

function core.endMatch(bucketId, winner)
    local match = core.matches[bucketId]
    if not match then return end

    for _, src in ipairs(match.players) do
        if GetPlayerPing(src) > 0 then
            SetPlayerRoutingBucket(src, 0)
            TriggerClientEvent("erotic-core:arenaEnd", src, match, winner)
            TriggerClientEvent("erotic-core:disableBlips", src) -- cleanup blips
        end
    end

    core.matches[bucketId] = nil
    if winner then
        print(("[erotic-core] Match %d ended. Winner: %s"):format(bucketId, GetPlayerName(winner)))
    else
        print(("[erotic-core] Match %d ended in a draw."):format(bucketId))
    end
end