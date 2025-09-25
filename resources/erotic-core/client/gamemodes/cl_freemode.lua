core = core or {}
core.spawnHandlers = core.spawnHandlers or {}

local wasDead = false
local alreadySpawned = false

RegisterNetEvent("erotic-core:worldJoined", function(world)
    alreadySpawned = false

    core.currentWorldId = world.id
    core.currentMode = world.information.gamemode
    core.currentSpawns = world.spawns or {}

    if core.currentMode == "freemode" and not alreadySpawned then
        -- teleport to first spawn immediately on join
        if #core.currentSpawns > 0 then
            local s = core.currentSpawns[1]
            DoScreenFadeOut(150)
            while not IsScreenFadedOut() do Wait(0) end

            NetworkResurrectLocalPlayer(s.x, s.y, s.z, s.h or 0.0, true, true, false)
            RequestCollisionAtCoord(s.x, s.y, s.z)
            SetEntityCoordsNoOffset(PlayerPedId(), s.x, s.y, s.z, false, false, false, true)
            SetEntityHeading(PlayerPedId(), s.h or 0.0)

            SetEntityHealth(PlayerPedId(), 200)
            AddArmourToPed(PlayerPedId(), 100)

            DoScreenFadeIn(150)
            alreadySpawned = true
        end
    end
end)


-- Freemode: fixed first spawn
core.spawnHandlers["freemode"] = {
    onJoin = function()
        if core.currentSpawns and #core.currentSpawns > 0 then
            core.teleportAndHeal(core.currentSpawns[1])
        end
    end,
    onDeath = function()
        if core.currentSpawns and #core.currentSpawns > 0 then
            core.teleportAndHeal(core.currentSpawns[1])
        end
    end
}
