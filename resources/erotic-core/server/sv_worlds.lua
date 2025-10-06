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
            {x = 231.0791, y = -1390.8812, z = 30.4998, h = 138.2659} -- 231.0791, -1390.8812, 30.4998, 138.2659
        },
        players = {}
    }
}

-- Update the worldsUpdate event to send proper player counts
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
            playerCount = playerCount  -- Send count instead of player table
        }
    end
    
    print(string.format("[erotic-core] Sending %d worlds to player %d", #worldsData, src))
    TriggerClientEvent("erotic-core:worldsUpdate", src, worldsData)
end)

-- Also update the worldsUpdate trigger in joinWorld and other places
-- Replace every instance of:
-- TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
-- With a function call:

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

-- Now replace all TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds) with:
-- core.broadcastWorldsUpdate()

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
    -- TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
    core.broadcastWorldsUpdate()
    return world
end

-- Updated joinWorld with logging
RegisterNetEvent("erotic-core:joinWorld", function(id, password)
    local src = source
    print(string.format("[erotic-core] Player %d attempting to join world %d", src, id))
    
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

    SetPlayerRoutingBucket(src, world.bucket)
    world.players[src] = true

    print(string.format("[erotic-core] Player %d joined world %d (bucket %d)", src, world.id, world.bucket))

    TriggerClientEvent("erotic-core:applyGameSettings", src, world.settings, world.information.gamemode)
    TriggerClientEvent("erotic-core:worldJoined", src, world)
    -- TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
    core.broadcastWorldsUpdate()
    TriggerClientEvent("erotic-core:joinResult", src, true, "Joined " .. world.information.name)
    
    TriggerEvent("erotic-core:serverJoinedWorld", src, id)
end)

-- Add custom world creation from UI
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

-- clean up when a player drops
AddEventHandler("playerDropped", function()
    local src = source
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            print(("[erotic-core] %s left world %d"):format(GetPlayerName(src) or "Unknown", wid))
            -- TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
            core.broadcastWorldsUpdate()
            if next(w.players) == nil and wid > 3 then
                core.worlds[wid] = nil
                print(("[erotic-core] Destroyed empty world %d"):format(wid))
            end
            break
        end
    end
end)

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
        name = name,
        gamemode = information.gamemode,
        settings = {recoil="qb", headshots=true, helmets=false},
        spawns = {
            {x = 0.0, y = 0.0, z = 72.0, h = 180.0}
        }
    })

    TriggerClientEvent("chat:addMessage", source, { args = {"[Arena]", "Created world ID " .. world.id}})
end, false)

RegisterCommand("listworlds", function(source)
    for id, w in pairs(core.worlds) do
        TriggerClientEvent("chat:addMessage", source, {
            args = {
                "[Arena]",
                string.format("ID:%d Name:%s Gamemode:%s Players:%d", id, w.information.name, w.information.gamemode, (next(w.players) and #w.players or 0))
            }
        })
    end
end, false)
