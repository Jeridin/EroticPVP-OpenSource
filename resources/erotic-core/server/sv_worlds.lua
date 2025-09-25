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
    TriggerClientEvent("erotic-core:worldsUpdate", -1, core.worlds)
    return world
end

-- join a world by id
RegisterNetEvent("erotic-core:joinWorld", function(src, id, password)
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

    -- max player check
    local count = 0 for _ in pairs(world.players) do count = count + 1 end
    if world.information.maxPlayers and count >= world.information.maxPlayers then
        TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "World is full."}})
        return
    end

    -- password check
    if world.information.passwordProtected then
        if not password or password ~= world.information.password then
            TriggerClientEvent("chat:addMessage", src, { args = {"[Arena]", "Incorrect or missing password."}})
            return
        end
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

    TriggerClientEvent("erotic-core:applyGameSettings", src, world.settings, world.information.gamemode)
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
