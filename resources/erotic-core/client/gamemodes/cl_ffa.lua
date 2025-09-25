core = core or {}
core.spawnHandlers = core.spawnHandlers or {}

local wasDead = false

local worldStats = {}  -- [worldId] = {kills=0, deaths=0}

---------------------------------------------------
-- helper to get current world stat table
---------------------------------------------------
local function getStats()
    if not core.currentWorldId then return {kills=0, deaths=0} end
    worldStats[core.currentWorldId] = worldStats[core.currentWorldId] or {kills=0, deaths=0}
    return worldStats[core.currentWorldId]
end

-- server tells us where to spawn
RegisterNetEvent("erotic-core:spawnAt", function(spawn)
    local ped = PlayerPedId()

    -- clear death state if needed
    NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.h, true, true, false)
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
    SetEntityHeading(ped, spawn.h)

    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)
end)

-- keep track of which world/mode we’re in
RegisterNetEvent("erotic-core:worldJoined", function(world)
    core.currentWorldId = world.id
    core.currentMode = world.information.gamemode
    core.currentSpawns = world.spawns or {}
    local stats = getStats()
    stats.kills = 0
    stats.deaths = 0
end)

core.spawnHandlers["ffa"] = {
    onJoin = function()
        if core.currentSpawns and #core.currentSpawns > 0 then
            local stats = getStats()
            stats.kills = 0
            stats.deaths = 0
            core.teleportAndHeal(core.currentSpawns[math.random(#core.currentSpawns)])
        end
    end,

    onDeath = function(deathType)
        local stats = getStats()
        stats.deaths = stats.deaths + 1
        print(("[erotic-core] Death (%s). K:%d D:%d"):format(deathType or "unknown", stats.kills, stats.deaths))

        if core.currentSpawns and #core.currentSpawns > 0 then
            core.teleportAndHeal(core.currentSpawns[math.random(#core.currentSpawns)])
        end
    end,

    onPlayerKilled = function(killerServerId, victimServerId)
        if killerServerId == GetPlayerServerId(PlayerId()) then
            local stats = getStats()
            stats.kills = stats.kills + 1
            print(("[erotic-core] Kill registered. K:%d D:%d"):format(stats.kills, stats.deaths))
        end
    end
}