core = core or {}
core.matches = core.matches or {}

-- Create a match. For duel: players={p1,p2}. For 4v4: players has 8 and we split into A/B.
function core.createMatch(players, gamemode)
    if not players or #players == 0 then
        print("[erotic-core] ERROR: createMatch with no players")
        return
    end

    local settings = core.gamemodeSettings[gamemode]
    if not settings then
        print("[erotic-core] ERROR: Unknown gamemode " .. tostring(gamemode))
        return
    end

    local bucketId = core.allocateBucket()

    local world = core.registerWorld(bucketId, gamemode, "match", {
        players = players,
        metadata = {
            name = settings.world and settings.world.name or (gamemode .. " Match"),
            queue = true
        },
        capacity = settings.world and settings.world.capacity or #players
    })

    local match = {
        id = bucketId,
        gamemode = gamemode,
        settings = settings,
        players = players,
        started = os.time(),
        round = 0,
        scores = { A = 0, B = 0 },       -- A vs B (for duel, A=p1 B=p2)
        alive = {},                      -- set of alive players
        sides = {},                      -- serverId => "A"/"B"
    }

    -- Assign teams/sides
    if gamemode == "duel" then
        match.sides[players[1]] = "A"
        match.sides[players[2]] = "B"
    elseif gamemode == "ranked4v4" then
        for i, src in ipairs(players) do
            match.sides[src] = (i <= 4) and "A" or "B"
        end
    end

    core.matches[bucketId] = match

    -- move players to bucket + apply mode
    for _, src in ipairs(players) do
        SetPlayerRoutingBucket(src, bucketId)
        TriggerClientEvent("erotic-core:setMode", src, gamemode)        -- switch mode
        TriggerClientEvent("erotic-core:applyGameSettings", src, gamemode) -- apply mode settings
        if world then
            world.players[src] = true
        end
    end

    -- optional blips per settings
    if settings.blips then
        for _, src in ipairs(players) do
            TriggerClientEvent("erotic-core:enableBlips", src, players, settings.blipInterval or 3000)
        end
    end

    print(("[erotic-core] Match %d started (%s) with %d players")
        :format(bucketId, gamemode, #players))

    core.startRound(bucketId)
end

-- Start a new round: reset alive sets and spawn players appropriately
function core.startRound(bucketId)
    local match = core.matches[bucketId]
    if not match then return end

    match.round = match.round + 1
    match.alive = {}

    local gm = match.gamemode
    local settings = match.settings

    -- reset all players alive
    for _, src in ipairs(match.players) do
        match.alive[src] = true
    end

    if gm == "duel" then
        local p1, p2 = match.players[1], match.players[2]
        local s1, s2 = settings.spawns[1], settings.spawns[2]
        TriggerClientEvent("erotic-core:arenaRoundSpawn", p1, gm, "A", s1)
        TriggerClientEvent("erotic-core:arenaRoundSpawn", p2, gm, "B", s2)

    elseif gm == "ranked4v4" then
        local idxA, idxB = 1, 1
        for _, src in ipairs(match.players) do
            local side = match.sides[src]
            if side == "A" then
                local spot = settings.teamSpawns.A[idxA]
                TriggerClientEvent("erotic-core:arenaRoundSpawn", src, gm, "A", spot)
                idxA = idxA + 1
            else
                local spot = settings.teamSpawns.B[idxB]
                TriggerClientEvent("erotic-core:arenaRoundSpawn", src, gm, "B", spot)
                idxB = idxB + 1
            end
        end
    else
        -- future modes
    end
end

-- Called by client exactly once when they die in a round-based mode
RegisterNetEvent("erotic-core:playerDiedOnce", function()
    local src = source
    local bucketId = GetPlayerRoutingBucket(src)
    local match = core.matches[bucketId]
    if not match then return end
    if match.settings.respawn then return end -- FFA etc. not round-based here

    -- mark dead
    match.alive[src] = false

    -- check if one side eliminated
    local anyA, anyB = false, false
    for _, p in ipairs(match.players) do
        if match.alive[p] then
            local side = match.sides[p]
            if side == "A" then anyA = true else anyB = true end
        end
    end

    if not anyA or not anyB then
        local winningSide = anyA and "A" or "B"
        core.finishRound(bucketId, winningSide)
    end
end)

function core.finishRound(bucketId, winningSide)
    local match = core.matches[bucketId]
    if not match then return end

    if winningSide then
        match.scores[winningSide] = match.scores[winningSide] + 1
    end

    -- tell clients: round over
    for _, src in ipairs(match.players) do
        TriggerClientEvent("erotic-core:arenaRoundEnd", src, match.round, winningSide, match.scores)
    end

    -- check for match end
    local target = match.settings.roundsToWin or math.huge
    if match.scores.A >= target or match.scores.B >= target then
        local winner = (match.scores.A >= target) and "A" or "B"
        core.endMatch(bucketId, winner)
        return
    end

    -- start next round after a short delay
    SetTimeout(4000, function()
        core.startRound(bucketId)
    end)
end

function core.endMatch(bucketId, winningSide)
    local match = core.matches[bucketId]
    if not match then return end

    for _, src in ipairs(match.players) do
        if GetPlayerPing(src) > 0 then
            SetPlayerRoutingBucket(src, 0)
            TriggerClientEvent("erotic-core:arenaMatchEnd", src, winningSide, match.scores)

            -- reset back to lobby
            TriggerClientEvent("erotic-core:setMode", src, "lobby")
            TriggerClientEvent("erotic-core:arenaEndToLobby", src)
        end
    end

    print(("[erotic-core] Match %d ended. Winner side: %s | Score A:%d B:%d")
        :format(bucketId, tostring(winningSide), match.scores.A, match.scores.B))

    core.matches[bucketId] = nil
    core.unregisterWorld(bucketId)
end

function core.handleMatchPlayerLeft(src, reason)
    local bucketId = GetPlayerRoutingBucket(src)
    local match = core.matches[bucketId]
    if not match then return end

    local playerName = GetPlayerName(src) or ("Player " .. tostring(src))
    local side = match.sides[src]

    -- remove from player lists
    match.alive[src] = nil
    match.sides[src] = nil
    for i, p in ipairs(match.players) do
        if p == src then
            table.remove(match.players, i)
            break
        end
    end

    local world = core.worlds[bucketId]
    if world then
        world.players[src] = nil
    end

    local winner = nil
    if side == "A" then
        winner = "B"
    elseif side == "B" then
        winner = "A"
    end

    print(("[erotic-core] %s left match %d (%s). Forcing end. Winner: %s")
        :format(playerName, bucketId, match.gamemode, tostring(winner)))

    core.endMatch(bucketId, winner)
end
