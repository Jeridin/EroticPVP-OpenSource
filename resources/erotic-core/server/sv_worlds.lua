core = core or {}

local lobbyBuckets = {}
local LOBBY_BUCKET_START = 100000

core.worlds = {
    [1] = {
        id = 1,
        bucket = 1,
        information = {
            name = "Grove Street FFA",
            gamemode = "ffa",
        },
        settings = { recoil = "pma", headshots = false, helmets = false, blips = true },
        spawns = {
            {x = 88.2693,  y = -1966.1018, z = 20.7474, h = 137.2590},
            {x = 83.8700,  y = -1948.5973, z = 20.7827, h = 46.4097},
            {x = 100.8329, y = -1913.3654, z = 21.1950, h = 149.9661},
            {x = 126.0752, y = -1929.2446, z = 21.3824, h = 71.9667}
        },
        players = {}
    },
    [2] = {
        id = 2,
        bucket = 2,
        information = {
            name = "Freemode",
            tags = { "freeplay" },
            gamemode = "freemode",
            maxPlayers = 10,
            passwordProtected = true,
            password = "123",
        },
        settings = { recoil = "envy", headshots = false, helmets = false },
        spawns = {
            {x = 231.0791, y = -1390.8812, z = 30.4998, h = 138.2659}
        },
        players = {}
    }
}

function core.broadcastWorldsUpdate()
    local worldsData = {}
    for id, world in pairs(core.worlds) do
        local playerCount = 0
        for _ in pairs(world.players) do
            playerCount = playerCount + 1
        end
        
        worldsData[id] = {
            id = world.id,
            bucket = world.bucket,
            information = world.information,
            settings = world.settings,
            spawns = world.spawns,
            playerCount = playerCount
        }
    end
    
    TriggerClientEvent("erotic-core:worldsUpdate", -1, worldsData)
end

function core.getWorldCount()
    local count = 0
    for _ in pairs(core.worlds) do count = count + 1 end
    return count
end

local maxId = 0
for id in pairs(core.worlds) do if id > maxId then maxId = id end end
core.nextWorldId = maxId + 1

function core.createWorld(def)
    local id = core.nextWorldId
    core.nextWorldId = id + 1

    local world = {
        id = id,
        bucket = id,
        information = def.lobbyinfo or {
            name = "World "..id,
            tags = {},
            gamemode = def.gamemode or "freemode",
            maxPlayers = 10,
            passwordProtected = false,
            password = nil,
        },
        settings = def.settings or {},
        spawns = def.spawns or {},
        players = {}
    }

    core.worlds[id] = world
    print(("[erotic-core] Created world %s (%s) bucket %d"):format(world.information.name, world.information.gamemode, world.bucket))
    core.broadcastWorldsUpdate()
    return world
end

RegisterNetEvent('erotic-core:setLobbyBucket', function()
    local source = source
    
    local currentBucket = GetPlayerRoutingBucket(source)
    local currentWorld = nil
    
    -- Find and REMOVE player from any world they're in
    for wid, world in pairs(core.worlds) do
        if world.players[source] then
            currentWorld = wid
            world.players[source] = nil  -- Remove from world
            print(string.format("[LobbyPage] Removed player %d from world %d (entering lobby)", source, wid))
        end
    end
    
    -- Broadcast updated world counts
    core.broadcastWorldsUpdate()
    
    local uniqueBucket = LOBBY_BUCKET_START + source
    
    lobbyBuckets[source] = {
        lobbyBucket = uniqueBucket,
        originalBucket = currentBucket,
        wasInWorld = currentWorld
    }
    
    SetPlayerRoutingBucket(source, uniqueBucket)
    print(string.format("[LobbyPage] Player %d moved from bucket %d to lobby bucket %d", source, currentBucket, uniqueBucket))
end)

RegisterNetEvent('erotic-core:restoreBucket', function()
    local source = source
    
    if lobbyBuckets[source] then
        local originalBucket = lobbyBuckets[source].originalBucket
        SetPlayerRoutingBucket(source, originalBucket)
        
        print(string.format("[LobbyPage] Player %d restored from lobby to bucket %d", source, originalBucket))
        lobbyBuckets[source] = nil
    end
end)

RegisterNetEvent("erotic-core:requestWorldsData", function()
    local src = source

    local worldsData = {}
    for id, world in pairs(core.worlds) do
        local playerCount = 0
        for _ in pairs(world.players) do
            playerCount = playerCount + 1
        end
        
        worldsData[id] = {
            id = world.id,
            bucket = world.bucket,
            information = world.information,
            settings = world.settings,
            spawns = world.spawns,
            playerCount = playerCount
        }
    end

    TriggerClientEvent("erotic-core:worldsUpdate", src, worldsData)
end)

RegisterNetEvent("erotic-core:joinWorld", function(id, password)
    local src = source

    if lobbyBuckets[src] then
        lobbyBuckets[src] = nil
    end
    
    local world = core.worlds[id]
    
    if not world then
        TriggerClientEvent("erotic-core:joinResult", src, false, "World does not exist.")
        return
    end

    if world.players[src] then
        TriggerClientEvent("erotic-core:joinResult", src, false, "You're already in this world.")
        return
    end

    local count = 0 
    for _ in pairs(world.players) do count = count + 1 end
    
    if world.information.maxPlayers and count >= world.information.maxPlayers then
        TriggerClientEvent("erotic-core:joinResult", src, false, "World is full.")
        return
    end

    if world.information.passwordProtected then
        print(string.format("[erotic-core] World %d requires password", id))
        if not password or password ~= world.information.password then
            TriggerClientEvent("erotic-core:joinResult", src, false, "Incorrect password.")
            return
        end
        print(string.format("[erotic-core] Password correct for world %d", id))
    end

    -- Remove from existing worlds
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
        end
    end

    -- Set to world bucket and add player
    SetPlayerRoutingBucket(src, world.bucket)
    world.players[src] = true

    print(string.format("[erotic-core] Player %d joined world %d (bucket %d)", src, world.id, world.bucket))

    TriggerClientEvent("erotic-core:applyGameSettings", src, world.settings, world.information.gamemode)
    TriggerClientEvent("erotic-core:worldJoined", src, world)
    core.broadcastWorldsUpdate()
    TriggerClientEvent("erotic-core:joinResult", src, true, "Joined " .. world.information.name)
    
    TriggerEvent("erotic-core:serverJoinedWorld", src, id)
end)

AddEventHandler("playerDropped", function()
    local src = source

    -- Clean up lobby bucket
    if lobbyBuckets[src] then
        lobbyBuckets[src] = nil
        print(string.format("[LobbyPage] Cleared lobby bucket for dropped player %d", src))
    end

    -- Clean up from worlds
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            print(("[erotic-core] %s left world %d"):format(GetPlayerName(src) or "Unknown", wid))
            core.broadcastWorldsUpdate()
            if next(w.players) == nil and wid > 3 then
                core.worlds[wid] = nil
                print(("[erotic-core] Destroyed empty world %d"):format(wid))
            end
            break
        end
    end
end)