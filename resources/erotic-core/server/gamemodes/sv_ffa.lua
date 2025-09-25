core = core or {}

local function sendSpawnToPlayer(src, world)
    if not world.spawns or #world.spawns == 0 then
        print(("[erotic-core] No spawn points for world %s"):format(world.name))
        return
    end
    local spawn = world.spawns[math.random(#world.spawns)]
    TriggerClientEvent("erotic-core:spawnAt", src, spawn)
    print("spawnAt sent to", src)
end

AddEventHandler("erotic-core:serverJoinedWorld", function(src, worldId)
    local world = core.worlds[worldId]
    if not world or world.information.gamemode ~= "ffa" then return end
    sendSpawnToPlayer(src, world)
end)

RegisterNetEvent("erotic-core:requestRespawn", function(worldId)
    local src = source
    local world = core.worlds[worldId]
    if not world or world.information.gamemode ~= "ffa" then return end
    sendSpawnToPlayer(src, world)
end)
