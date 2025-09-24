RegisterNetEvent("erotic-core:setMode", function(mode)
    core.currentMode = mode
    print("[erotic-core] Mode set to " .. mode)
    core.applyGameSettings(mode)
end)

function core.applyGameSettings(mode)
    local settings = core.gamemodeSettings[mode]
    if not settings then
        print("[erotic-core] Invalid mode: " .. tostring(mode) .. " — defaulting to lobby")
        core.currentMode = "lobby"
        core.applyGameSettings("lobby")
        return
    end

    -- Locals (peds/vehicles)
    if settings.locals ~= nil then
        if settings.locals then
            TriggerEvent("core:enableLocals")
        else
            -- Your cl_peds.lua disables them automatically at resource start
            -- so no need to do anything here
        end
    end

    -- Headshot multiplier
    if settings.headshots ~= nil then
        exports["gamesettings"]:setHsMulti(settings.headshots)
    end

    -- Helmets
    if settings.helmets ~= nil then
        exports["gamesettings"]:setHelmetsEnabled(settings.helmets)
    end

    -- Car ragdoll
    if settings.ragdoll ~= nil then
        exports["gamesettings"]:setCarRagdoll(settings.ragdoll)
    end

    if settings.recoil then 
        exports["gamesettings"]:setRecoilMode(settings.recoil)
    else
        exports["gamesettings"]:setRecoilMode("qb")
    end

    -- Spawning cars
    if settings.spawningcars ~= nil then
        exports["gamesettings"]:spawningcars(settings.spawningcars, false)
    end

    print("[erotic-core] Applied settings for mode: " .. mode)
end