-- sv_worlds.lua
core = core or {}

-- define preset / static worlds
core.worlds = {
    [1] = {
        id = 1,
        bucket = 1,
        name = "Free For All Arena",
        gamemode = "ffa",
        settings = { recoil = "qb", headshots = true, helmets = false },
        spawns = {
            {x = 123.4, y = -456.7, z = 21.0, h = 180.0},
            {x = 130.0, y = -460.0, z = 21.0, h = 90.0}
        },
        players = {}
    },
    [2] = {
        id = 2,
        bucket = 2,
        name = "1v1 Duel",
        gamemode = "duel",
        settings = { recoil = "qb", headshots = true, helmets = true },
        spawns = {
            {x = 200.0, y = -300.0, z = 50.0, h = 0.0},
            {x = 205.0, y = -305.0, z = 50.0, h = 180.0}
        },
        players = {}
    },
    [3] = {
        id = 3,
        bucket = 3,
        name = "Practice Range",
        gamemode = "practice",
        settings = { recoil = "qb", headshots = false, helmets = false },
        spawns = {
            {x = 300.0, y = -500.0, z = 28.0, h = 270.0}
        },
        players = {}
    },
    [4] = {
        id = 4,
        bucket = 4,
        name = "Grove Street FFA",
        gamemode = "ffa",
        settings = { recoil = "pma", headshots = true, helmets = false },
        spawns = {
            {x = 88.2693,  y = -1966.1018, z = 20.7474, h = 137.2590},
            {x = 83.8700,  y = -1948.5973, z = 20.7827, h = 46.4097},
            {x = 100.8329, y = -1913.3654, z = 21.1950, h = 149.9661},
            {x = 126.0752, y = -1929.2446, z = 21.3824, h = 71.9667}
        },
        players = {}
    },
    [5] = {
        id = 5,
        bucket = 5,
        name = "Freemode",
        gamemode = "freemode",
        settings = { recoil = "qb", headshots = true, helmets = false },
        spawns = {
            {x = -75.0, y = -818.0, z = 326.0, h = 0.0}
        },
        players = {}
    }
}

local maxId = 0
for id in pairs(core.worlds) do if id > maxId then maxId = id end end
core.nextWorldId = maxId + 1

function core.createWorld(def)
    local id = core.nextWorldId
    core.nextWorldId = id + 1

    local world = {
        id = id,
        bucket = id,
        name = def.name or ("World " .. id),
        gamemode = def.gamemode or "ffa",
        settings = def.settings or {},
        spawns = def.spawns or {},
        players = {}
    }

    core.worlds[id] = world
    print(("[erotic-core] Created world %s (%s) bucket %d"):format(world.name, world.gamemode, world.bucket))
    TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
    return world
end

-- join a world by id
RegisterNetEvent("erotic-core:joinWorld", function(src, id)
    local world = core.worlds[id]
    if not world then
        TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "World does not exist."}})
        return
    end

        -- now: check if already in new world (after cleanup just in case)
    if world.players[src] then
        TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "You’re already in this world."}})
        return
    end

    -- first: remove player from any existing world
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            print(("[erotic-core] %s left world %d"):format(GetPlayerName(src) or "Unknown", wid))
        end
    end

    SetPlayerRoutingBucket(src, world.bucket)
    world.players[src] = true

    print(("[erotic-core] %s joined world %d (bucket %d)"):format(GetPlayerName(src) or ("Player "..src), world.id, world.bucket))

    TriggerClientEvent("erotic-core:applyGameSettings", src, world.settings, world.gamemode)
    TriggerClientEvent("erotic-core:worldJoined", src, world)
    TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)

    TriggerEvent("erotic-core:serverJoinedWorld", src, id)
end)

-- clean up when a player drops
AddEventHandler("playerDropped", function()
    local src = source
    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            print(("[erotic-core] %s left world %d"):format(GetPlayerName(src) or "Unknown", wid))
            TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
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
    if not id then
        TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "Usage: /joinworld <worldId>"}})
        return
    end
    TriggerEvent("erotic-core:joinWorld", src, id)
end, false)

RegisterCommand("createworld", function(source, args)
    local name = args[1] or "Custom World"
    local gamemode = args[2] or "ffa"

    local world = core.createWorld({
        name = name,
        gamemode = gamemode,
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
                string.format("ID:%d Name:%s Gamemode:%s Players:%d", id, w.name, w.gamemode, (next(w.players) and #w.players or 0))
            }
        })
    end
end, false)
