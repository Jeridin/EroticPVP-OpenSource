core = rawget(_G, "core") or {}
_G.core = core

core.worlds = core.worlds or {}
core.personalWorlds = core.personalWorlds or {}
core.bucketAllocator = core.bucketAllocator or { next = 2000, recycled = {} }
core.worldRegistry = core.worldRegistry or { byId = {}, byBucket = {}, sequence = 0 }
core.defaultWorlds = core.defaultWorlds or {}
core.customWorldTemplates = core.customWorldTemplates or {}

if not next(core.customWorldTemplates) then
    core.customWorldTemplates = {
        default = {
            id = "default",
            label = "Training Facility",
            description = "Balanced interior with short sightlines.",
            spawn = vector4(-1598.15, -3011.45, -78.25, 355.0)
        },
        hangar = {
            id = "hangar",
            label = "LSIA Hangar",
            description = "Wide open hangar floor ideal for team fights.",
            spawn = vector4(-1266.59, -3014.69, -48.49, 90.0)
        },
        rooftop = {
            id = "rooftop",
            label = "Downtown Rooftop",
            description = "Vertical engagements with lots of cover objects.",
            spawn = vector4(-75.01, -818.65, 326.18, 180.12)
        }
    }
end

local LOBBY_BUCKET = 0

local function debugPrint(msg)
    print(("[erotic-core][worlds] %s"):format(msg))
end

local function sanitizeWorldId(id)
    if type(id) ~= "string" then return nil end
    local cleaned = id:lower():gsub("[^%w%-_]+", "-")
    cleaned = cleaned:gsub("%-+", "-")
    cleaned = cleaned:gsub("^-", ""):gsub("-$", "")
    if cleaned == "" then return nil end
    return cleaned
end

function core.generateWorldId(prefix)
    prefix = sanitizeWorldId(prefix) or "world"
    core.worldRegistry.sequence = (core.worldRegistry.sequence or 0) + 1
    return ("%s-%04d"):format(prefix, core.worldRegistry.sequence)
end

local function assignWorldIdentity(world, desiredId)
    if not world then return nil end

    if desiredId then
        desiredId = sanitizeWorldId(desiredId)
    end

    if world.id and core.worldRegistry.byId[world.id] == world then
        if desiredId and desiredId ~= world.id then
            core.worldRegistry.byId[world.id] = nil
        else
            desiredId = world.id
        end
    end

    if desiredId then
        if core.worldRegistry.byId[desiredId] and core.worldRegistry.byId[desiredId] ~= world then
            local base = desiredId
            local idx = 1
            local candidate = base
            while core.worldRegistry.byId[candidate] and core.worldRegistry.byId[candidate] ~= world do
                idx = idx + 1
                candidate = ("%s-%d"):format(base, idx)
            end
            desiredId = candidate
        end
    else
        desiredId = core.generateWorldId(world.gamemode or "world")
    end

    world.id = desiredId
    core.worldRegistry.byId[desiredId] = world
    core.worldRegistry.byBucket[world.bucket] = world

    return desiredId
end

local function makePersonalWorldId(key)
    local base = ("custom-%s"):format(key or "")
    local cleaned = sanitizeWorldId(base)
    if not cleaned then
        return core.generateWorldId("custom")
    end
    return cleaned
end

function core.getWorldById(id)
    if not id then return nil end
    return core.worldRegistry.byId[id]
end

local function buildWorldSummary(world)
    if not world then return nil end
    local templateInfo = nil
    if world.gamemode == "custom" and world.metadata then
        local templateKey = world.metadata.template
        templateInfo = templateKey and core.customWorldTemplates[templateKey] or nil
    end
    return {
        id = world.id,
        name = world.name,
        gamemode = world.gamemode,
        type = world.type,
        bucket = world.bucket,
        capacity = world.capacity,
        playerCount = core.tableCount(world.players),
        owner = world.owner,
        ownerName = world.metadata and world.metadata.ownerName or nil,
        template = world.metadata and world.metadata.template or nil,
        templateLabel = templateInfo and templateInfo.label or nil,
        createdAt = world.createdAt,
    }
end

function core.getWorldSummaries()
    local summaries = {}
    for _, world in pairs(core.worldRegistry.byId) do
        local summary = buildWorldSummary(world)
        if summary then
            table.insert(summaries, summary)
        end
    end

    table.sort(summaries, function(a, b)
        if a.type == "static" and b.type ~= "static" then return true end
        if a.type ~= "static" and b.type == "static" then return false end
        return (a.createdAt or 0) < (b.createdAt or 0)
    end)

    return summaries
end

function core.sendWorldList(target)
    TriggerClientEvent("erotic-core:updateWorldList", target, core.getWorldSummaries())
end

function core.broadcastWorldList()
    core.sendWorldList(-1)
end

function core.getCustomTemplate(key)
    if type(key) ~= "string" or key == "" then
        return core.customWorldTemplates.default, "default"
    end

    local template = core.customWorldTemplates[key]
    if template then
        return template, key
    end

    return core.customWorldTemplates.default, "default"
end

function core.getCustomTemplates()
    local templates = {}
    for key, template in pairs(core.customWorldTemplates) do
        templates[#templates + 1] = {
            id = key,
            label = template.label or key,
            description = template.description,
        }
    end

    table.sort(templates, function(a, b)
        return a.label < b.label
    end)

    return templates
end

function core.sendCustomTemplates(target)
    TriggerClientEvent("erotic-core:updateCustomTemplates", target, core.getCustomTemplates())
end

function core.allocateBucket(preferred)
    if preferred and preferred ~= LOBBY_BUCKET then
        if not core.getWorld(preferred) then
            return preferred
        end
    end

    while #core.bucketAllocator.recycled > 0 do
        local recycled = table.remove(core.bucketAllocator.recycled)
        if recycled and not core.getWorld(recycled) then
            return recycled
        end
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
    if not bucket then return nil end
    return core.worldRegistry.byBucket[bucket] or core.worlds[bucket]
end

function core.getWorldByPlayer(src)
    local bucket = GetPlayerRoutingBucket(src)
    return core.getWorld(bucket)
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
    local desiredId = opts and opts.id or nil

    local existing = core.getWorld(bucket)
    if existing then
        if opts and opts.metadata then
            existing.metadata = existing.metadata or {}
            for k, v in pairs(opts.metadata) do
                existing.metadata[k] = v
            end
        end

        if opts and opts.capacity then
            existing.capacity = opts.capacity
        end

        assignWorldIdentity(existing, desiredId)
        core.broadcastWorldList()
        return existing
    end

    local settings = core.gamemodeSettings[gamemode] or {}
    local worldCfg = settings.world or {}

    if not desiredId and worldCfg and worldCfg.id then
        desiredId = worldCfg.id
    end

    local world = {
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
    }

    world.name = makeWorldName(gamemode, world.metadata)

    assignWorldIdentity(world, desiredId)

    if opts and opts.players then
        for _, src in ipairs(opts.players) do
            world.players[src] = true
        end
    end

    core.worlds[bucket] = world
    debugPrint(("registered %s world in bucket %s"):format(gamemode, bucket))
    core.broadcastWorldList()
    return world
end

function core.destroyWorld(bucket, reason, opts)
    local world = core.getWorld(bucket)
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
    if world.id then
        if core.worldRegistry.byId[world.id] == world then
            core.worldRegistry.byId[world.id] = nil
        end
    end
    if core.worldRegistry.byBucket[bucket] == world then
        core.worldRegistry.byBucket[bucket] = nil
    end

    if world.type ~= "static" then
        core.releaseBucket(bucket)
    end

    debugPrint(("destroyed world %s (bucket %s) reason=%s"):format(world.name or world.gamemode, bucket, tostring(reason)))
    core.broadcastWorldList()
end

function core.unregisterWorld(bucket)
    core.destroyWorld(bucket, "unregister", { skipPlayerHandling = true })
end

local function ensureStaticWorld(gamemode)
    local settings = core.gamemodeSettings[gamemode]
    if not settings then return nil end
    local worldCfg = settings.world or {}
    if worldCfg.type ~= "static" then return nil end
    local bucket = worldCfg.bucket or settings.bucket or LOBBY_BUCKET
    local world = core.registerWorld(bucket, gamemode, "static", {
        metadata = { name = worldCfg.name },
        capacity = worldCfg.capacity,
        id = worldCfg.id
    })
    if world then
        core.defaultWorlds[gamemode] = world.id
    end
    return world
end

function core.ensureBaseWorlds()
    if not core.gamemodeSettings then return end

    for gamemode, settings in pairs(core.gamemodeSettings) do
        local worldCfg = settings.world
        if worldCfg and worldCfg.type == "static" then
            ensureStaticWorld(gamemode)
        end
    end

    core.broadcastWorldList()
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

    local world = core.getWorld(bucket)
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
        return world
    end

    core.broadcastWorldList()
    return world
end

function core.joinWorldByBucket(bucket, src, opts)
    local world = core.getWorld(bucket)
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
        local templateInfo = core.customWorldTemplates and core.customWorldTemplates[world.metadata.template]
        TriggerClientEvent("erotic-core:customWorldEnter", src, {
            name = world.name,
            owner = world.owner,
            spawn = spawn,
            template = world.metadata.template,
            templateLabel = templateInfo and templateInfo.label or nil
        })
    end

    local label = GetPlayerName(src) or ("Player " .. tostring(src))
    debugPrint(('%s joined world %s (bucket %s)'):format(label, world.name or world.gamemode, bucket))

    core.broadcastWorldList()
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
    local world = core.getWorld(bucket)
    if not world then
        core.personalWorlds[key] = nil
        return nil
    end
    return world
end

function core.createPersonalWorld(src, opts)
    local key = core.getPersonalWorldKey(src)
    local existingBucket = core.personalWorlds[key]
    local existingWorld = existingBucket and core.getWorld(existingBucket) or nil
    if existingWorld and not (opts and opts.replaceExisting) then
        existingWorld.metadata.ownerSource = src
        existingWorld.metadata.ownerName = GetPlayerName(src)
        assignWorldIdentity(existingWorld, existingWorld.id)
        return existingWorld
    end

    if existingWorld then
        core.destroyWorld(existingBucket, "recreate")
    end

    local settings = core.gamemodeSettings.custom or {}
    local template, templateKey = core.getCustomTemplate(opts and opts.template)
    local spawn = (opts and opts.spawn) or (template and template.spawn) or settings.defaultSpawn or vector4(231.1525, -1390.9653, 30.4999, 339.3951)
    local capacity = opts and opts.capacity or (settings.world and settings.world.capacity) or nil
    local name = (opts and opts.name and opts.name ~= "" and opts.name)
        or (GetPlayerName(src) .. "'s Arena")

    local personalId = opts and opts.id or makePersonalWorldId(key)

    local bucket = core.allocateBucket()
    local world = core.registerWorld(bucket, "custom", "personal", {
        owner = key,
        metadata = {
            name = name,
            spawn = spawn,
            template = templateKey,
            templateLabel = template and template.label or nil,
            ownerSource = src,
            ownerName = GetPlayerName(src)
        },
        capacity = capacity,
        id = personalId
    })

    core.personalWorlds[key] = bucket
    debugPrint(("created personal world %s for %s in bucket %s")
        :format(world.name, GetPlayerName(src) or src, bucket))

    return world
end

function core.resetPersonalWorld(src, opts)
    local key = core.getPersonalWorldKey(src)
    local existingBucket = core.personalWorlds[key]
    if existingBucket then
        local world = core.getWorld(existingBucket)
        if world then
            core.destroyWorld(existingBucket, "recreate")
        else
            core.personalWorlds[key] = nil
        end
    end

    opts = opts or {}
    opts.replaceExisting = true
    return core.createPersonalWorld(src, opts)
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
    local world = core.getWorld(bucket)
    if not world then
        core.personalWorlds[key] = nil
        return
    end

    if core.tableCount(world.players) == 0 then
        core.destroyWorld(bucket, "owner disconnect", { skipPlayerHandling = true })
    else
        world.metadata.ownerSource = nil
        core.broadcastWorldList()
    end
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function()
        Wait(0)
        core.ensureBaseWorlds()
        core.sendCustomTemplates(-1)
    end)
end)
*** End of File
