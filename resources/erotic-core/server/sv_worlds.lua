-- sv_worlds.lua
core = core or {}

-- define preset / static worlds
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

-- ========================================
-- LOBBY SYSTEM - ROUTING BUCKET MANAGEMENT
-- ========================================

local lobbyBuckets = {}
local LOBBY_BUCKET_START = 100000

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

-- ========================================
-- WORLDS MANAGEMENT
-- ========================================

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

RegisterNetEvent("erotic-core:requestWorldsData", function()
    local src = source
    print(string.format("[erotic-core] Player %d requested worlds data", src))
    
    -- Create a sanitized version of worlds with player counts instead of player tables
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
    
    print(string.format("[erotic-core] Sending %d worlds to player %d", #worldsData, src))
    TriggerClientEvent("erotic-core:worldsUpdate", src, worldsData)
end)

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

RegisterNetEvent("erotic-core:joinWorld", function(id, password)
    local src = source
    print(string.format("[erotic-core] Player %d attempting to join world %d", src, id))
    
    -- Clear lobby bucket tracking
    if lobbyBuckets[src] then
        print(string.format("[LobbyPage] Player %d leaving lobby to join world %d", src, id))
        lobbyBuckets[src] = nil
    end
    
    local world = core.worlds[id]
    
    if not world then
        print(string.format("[erotic-core] World %d does not exist", id))
        TriggerClientEvent("erotic-core:joinResult", src, false, "World does not exist.")
        return
    end

    if world.players[src] then
        print(string.format("[erotic-core] Player %d already in world %d", src, id))
        TriggerClientEvent("erotic-core:joinResult", src, false, "You're already in this world.")
        return
    end

    local count = 0 
    for _ in pairs(world.players) do count = count + 1 end
    print(string.format("[erotic-core] World %d has %d players", id, count))
    
    if world.information.maxPlayers and count >= world.information.maxPlayers then
        print(string.format("[erotic-core] World %d is full", id))
        TriggerClientEvent("erotic-core:joinResult", src, false, "World is full.")
        return
    end

    if world.information.passwordProtected then
        print(string.format("[erotic-core] World %d requires password", id))
        if not password or password ~= world.information.password then
            print(string.format("[erotic-core] Incorrect password for world %d", id))
            TriggerClientEvent("erotic-core:joinResult", src, false, "Incorrect password.")
            return
        end
        print(string.format("[erotic-core] Password correct for world %d", id))
    end

    -- Remove from existing worlds
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            print(string.format("[erotic-core] Removed player %d from world %d", src, wid))
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

RegisterNetEvent("erotic-core:createCustomWorld", function(data)
    local src = source
    
    local world = core.createWorld({
        lobbyinfo = {
            name = data.name or "Custom World",
            gamemode = data.gamemode or "ffa",
            maxPlayers = data.maxPlayers or 10,
            passwordProtected = data.passwordProtected or false,
            password = data.password or nil,
            tags = {"custom"}
        },
        settings = {recoil="qb", headshots=true, helmets=false},
        spawns = {
            {x = 0.0, y = 0.0, z = 72.0, h = 180.0}
        }
    })

    TriggerClientEvent("erotic-core:joinResult", src, true, "Created world: " .. world.information.name)
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

-- Commands
RegisterCommand("joinworld", function(src, args)
    local id = tonumber(args[1])
    local psw = (args[2])
    if not id then
        TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "Usage: /joinworld <worldId>"}})
        return
    end
    TriggerEvent("erotic-core:joinWorld", src, id, psw)
end, false)

RegisterCommand("createworld", function(source, args)
    local name = args[1] or "Custom World"
    local gamemode = args[2] or "ffa"

    local world = core.createWorld({
        lobbyinfo = {
            name = name,
            gamemode = gamemode,
        },
        settings = {recoil="qb", headshots=true, helmets=false},
        spawns = {
            {x = 0.0, y = 0.0, z = 72.0, h = 180.0}
        }
    })

    TriggerClientEvent("chat:addMessage", source, { args = {"[Arena]", "Created world ID " .. world.id}})
end, false)

RegisterCommand("listworlds", function(source)
    for id, w in pairs(core.worlds) do
        local playerCount = 0
        for _ in pairs(w.players) do
            playerCount = playerCount + 1
        end
        TriggerClientEvent("chat:addMessage", source, {
            args = {
                "[Arena]",
                string.format("ID:%d Name:%s Gamemode:%s Players:%d", id, w.information.name, w.information.gamemode, playerCount)
            }
        })
    end
end, false)

-- Add this near the other RegisterNetEvent calls in LobbyPage.lua
RegisterNetEvent('erotic-core:openLobby', function()
    if not isInLobby then
        print("[LobbyPage] Opening lobby")
        Wait(500)
        exports["ui"]:ToggleLobbyPage(true)
    end
end)