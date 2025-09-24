core = core or {}

core.worlds = core.worlds or {}
core.personalWorlds = core.personalWorlds or {}
core.bucketAllocator = core.bucketAllocator or { next = 2000, recycled = {} }

local LOBBY_BUCKET = 0

local function debugPrint(msg)
    print(("[erotic-core][worlds] %s"):format(msg))
end

function core.allocateBucket(preferred)
    if preferred and preferred ~= LOBBY_BUCKET then
        if not core.worlds[preferred] then
            return preferred
        end
    end

    local recycled = table.remove(core.bucketAllocator.recycled)
    if recycled then
        return recycled
    end

    local nextId = core.bucketAllocator.next or 2000
    core.bucketAllocator.next = nextId + 1
    return nextId
end

function core.releaseBucket(bucket)
    if not bucket or bucket == LOBBY_BUCKET then return end
    table.insert(core.bucketAllocator.recycled, bucket)
end

function core.getWorld(bucket)
    return core.worlds[bucket]
end

function core.getWorldByPlayer(src)
    local bucket = GetPlayerRoutingBucket(src)
    return core.worlds[bucket]
end

function core.isPlayerInMatch(src)
    local world = core.getWorldByPlayer(src)
    return world and world.type == "match"
end

local function makeWorldName(gamemode, metadata)
    if metadata and metadata.name then
        return metadata.name
    end
    local settings = core.gamemodeSettings[gamemode]
    return (settings and settings.world and settings.world.name)
        or (settings and gamemode:gsub("^%l", string.upper))
        or gamemode
end

function core.registerWorld(bucket, gamemode, worldType, opts)
    if core.worlds[bucket] then
        local world = core.worlds[bucket]
        if opts and opts.metadata then
            world.metadata = world.metadata or {}
            for k, v in pairs(opts.metadata) do
                world.metadata[k] = v
            end
        end
        return world
    end

    local settings = core.gamemodeSettings[gamemode] or {}
    local worldCfg = settings.world or {}

    local world = {
        id = bucket,
        bucket = bucket,
        gamemode = gamemode,
        type = worldType or worldCfg.type or "generic",
        settings = settings,
        config = worldCfg,
        capacity = (opts and opts.capacity) or worldCfg.capacity,
        owner = opts and opts.owner,
        metadata = opts and opts.metadata or {},
        players = {},
        createdAt = os.time(),
        name = makeWorldName(gamemode, opts and opts.metadata)
    }

    if opts and opts.players then
        for _, src in ipairs(opts.players) do
            world.players[src] = true
        end
    end

    core.worlds[bucket] = world
    debugPrint(("registered %s world in bucket %s"):format(gamemode, bucket))
    return world
end

function core.destroyWorld(bucket, reason, opts)
    local world = core.worlds[bucket]
    if not world then return end

    local skipPlayers = opts and opts.skipPlayerHandling

    if not skipPlayers then
        for src, _ in pairs(world.players) do
            if GetPlayerPing(src) > 0 then
                SetPlayerRoutingBucket(src, LOBBY_BUCKET)
                TriggerClientEvent("erotic-core:setMode", src, "lobby")
                TriggerClientEvent("erotic-core:arenaEndToLobby", src)

                if world.gamemode == "ffa" then
                    TriggerClientEvent("erotic-core:ffaExit", src)
                elseif world.gamemode == "custom" then
                    TriggerClientEvent("erotic-core:customWorldExit", src)
                end
            end
        end
    end

    if world.type == "personal" and world.owner then
        if core.personalWorlds[world.owner] == bucket then
            core.personalWorlds[world.owner] = nil
        end
    end

    core.worlds[bucket] = nil

    if world.type ~= "static" then
        core.releaseBucket(bucket)
    end

    debugPrint(("destroyed world %s (bucket %s) reason=%s"):format(world.name or world.gamemode, bucket, tostring(reason)))
end

function core.unregisterWorld(bucket)
    core.destroyWorld(bucket, "unregister", { skipPlayerHandling = true })
end

local function ensureStaticWorld(gamemode)
    local settings = core.gamemodeSettings[gamemode]
    if not settings then return nil end
    local worldCfg = settings.world or {}
    local bucket = worldCfg.bucket or settings.bucket or LOBBY_BUCKET
    return core.registerWorld(bucket, gamemode, "static", { metadata = { name = worldCfg.name } })
end

function core.updateWorldBlips(world)
    if not world then return end
    local settings = world.settings
    if not settings or not settings.blips then return end

    local players = {}
    for id in pairs(world.players) do
        table.insert(players, id)
    end

    for id in pairs(world.players) do
        if GetPlayerPing(id) > 0 then
            TriggerClientEvent("erotic-core:enableBlips", id, players, settings.blipInterval or 3000)
        end
    end
end

local function shouldBlockJoin(src)
    if core.isPlayerInMatch(src) then
        return true, "Finish your current match before switching arenas."
    end
    return false, nil
end

function core.leaveCurrentWorld(src, reason)
    local bucket = GetPlayerRoutingBucket(src)
    if bucket == LOBBY_BUCKET then
        if GetPlayerPing(src) > 0 then
            TriggerClientEvent("erotic-core:setMode", src, "lobby")
        end
        return nil
    end

    local world = core.worlds[bucket]
    if not world then
        if GetPlayerPing(src) > 0 then
            SetPlayerRoutingBucket(src, LOBBY_BUCKET)
            TriggerClientEvent("erotic-core:setMode", src, "lobby")
            TriggerClientEvent("erotic-core:arenaEndToLobby", src)
        end
        return nil
    end

    world.players[src] = nil

    if world.gamemode == "ffa" then
        if GetPlayerPing(src) > 0 then
            TriggerClientEvent("erotic-core:ffaExit", src)
        end
        core.updateWorldBlips(world)
    elseif world.gamemode == "custom" then
        if GetPlayerPing(src) > 0 then
            TriggerClientEvent("erotic-core:customWorldExit", src)
        end
    end

    if GetPlayerPing(src) > 0 then
        SetPlayerRoutingBucket(src, LOBBY_BUCKET)
        TriggerClientEvent("erotic-core:setMode", src, "lobby")
        TriggerClientEvent("erotic-core:arenaEndToLobby", src)
    end

    if world.type == "personal" and not next(world.players) then
        core.destroyWorld(bucket, "empty", { skipPlayerHandling = true })
    end

    return world
end

function core.joinWorldByBucket(bucket, src, opts)
    local world = core.worlds[bucket]
    if not world then
        return false, "World not available"
    end

    local blocked, reason = shouldBlockJoin(src)
    if blocked then
        return false, reason
    end

    if world.capacity and core.tableCount(world.players) >= world.capacity and not (opts and opts.overrideCapacity) then
        return false, "World is full"
    end

    if GetPlayerRoutingBucket(src) == bucket then
        return true, world
    end

    if GetPlayerRoutingBucket(src) ~= LOBBY_BUCKET then
        core.leaveCurrentWorld(src, "switch")
    end

    SetPlayerRoutingBucket(src, bucket)
    world.players[src] = true

    if GetPlayerPing(src) > 0 then
        TriggerClientEvent("erotic-core:setMode", src, world.gamemode)
        TriggerClientEvent("erotic-core:applyGameSettings", src, world.gamemode)
    end

    if world.gamemode == "ffa" then
        TriggerClientEvent("erotic-core:ffaEnter", src, world.settings.spawns)
        core.updateWorldBlips(world)
    elseif world.gamemode == "custom" then
        local settings = world.settings
        local fallback = settings.defaultSpawn or vector4(231.1525, -1390.9653, 30.4999, 339.3951)
        local spawn = (opts and opts.spawn) or world.metadata.spawn or fallback
        TriggerClientEvent("erotic-core:customWorldEnter", src, {
            name = world.name,
            owner = world.owner,
            spawn = spawn,
            template = world.metadata.template
        })
    end

    local label = GetPlayerName(src) or ("Player " .. tostring(src))
    debugPrint(('%s joined world %s (bucket %s)'):format(label, world.name or world.gamemode, bucket))

    return true, world
end

function core.joinGamemode(src, gamemode, opts)
    local settings = core.gamemodeSettings[gamemode]
    if not settings then
        return false, "Gamemode not found"
    end

    local blocked, blockReason = shouldBlockJoin(src)
    if blocked then
        return false, blockReason
    end

    local worldCfg = settings.world or {}

    if worldCfg.type == "static" then
        local world = ensureStaticWorld(gamemode)
        return core.joinWorldByBucket(world.bucket, src, opts)
    elseif worldCfg.type == "personal" then
        local world = core.createPersonalWorld(src, opts)
        return core.joinWorldByBucket(world.bucket, src, opts)
    elseif worldCfg.type == "match" then
        return false, "queue"
    else
        local bucket = core.allocateBucket(worldCfg.bucket)
        local world = core.registerWorld(bucket, gamemode, worldCfg.type or "dynamic", {
            metadata = { name = worldCfg.name },
            capacity = worldCfg.capacity
        })
        return core.joinWorldByBucket(world.bucket, src, opts)
    end
end

function core.getPersonalWorldKey(src)
    local user = core.users and core.users[src]
    if user and user.arena_id then
        return ("arena:%s"):format(user.arena_id)
    end
    return ("temp:%d"):format(src)
end

function core.findPersonalWorld(src)
    local key = core.getPersonalWorldKey(src)
    local bucket = core.personalWorlds[key]
    if not bucket then return nil end
    local world = core.worlds[bucket]
    if not world then
        core.personalWorlds[key] = nil
        return nil
    end
    return world
end

function core.createPersonalWorld(src, opts)
    local key = core.getPersonalWorldKey(src)
    local existingBucket = core.personalWorlds[key]
    if existingBucket and core.worlds[existingBucket] then
        local world = core.worlds[existingBucket]
        world.metadata.ownerSource = src
        world.metadata.ownerName = GetPlayerName(src)
        return world
    end

    local settings = core.gamemodeSettings.custom or {}
    local bucket = core.allocateBucket()
    local world = core.registerWorld(bucket, "custom", "personal", {
        owner = key,
        metadata = {
            name = opts and opts.name or (GetPlayerName(src) .. "'s Arena"),
            spawn = (opts and opts.spawn) or settings.defaultSpawn or vector4(231.1525, -1390.9653, 30.4999, 339.3951),
            template = opts and opts.template or "default",
            ownerSource = src,
            ownerName = GetPlayerName(src)
        },
        capacity = settings.world and settings.world.capacity or nil
    })

    core.personalWorlds[key] = bucket
    debugPrint(("created personal world %s for %s in bucket %s")
        :format(world.name, GetPlayerName(src) or src, bucket))

    return world
end

function core.joinPersonalWorld(src, opts)
    local world = core.findPersonalWorld(src)
    if not world then
        world = core.createPersonalWorld(src, opts)
    else
        local key = core.getPersonalWorldKey(src)
        if world.owner == key then
            world.metadata = world.metadata or {}
            world.metadata.ownerSource = src
            world.metadata.ownerName = GetPlayerName(src)
        end
    end

    local ok, err = core.joinWorldByBucket(world.bucket, src, opts)
    if not ok then
        return false, err
    end

    return true, world
end

function core.handleWorldOwnerLeft(src)
    local key = core.getPersonalWorldKey(src)
    local bucket = core.personalWorlds[key]
    if not bucket then return end
    local world = core.worlds[bucket]
    if not world then
        core.personalWorlds[key] = nil
        return
    end

    if core.tableCount(world.players) == 0 then
        core.destroyWorld(bucket, "owner disconnect", { skipPlayerHandling = true })
    else
        world.metadata.ownerSource = nil
    end
end
*** End of File
