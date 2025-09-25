-- cl_events.lua
core = core or {}

-- receive user info from server
RegisterNetEvent("erotic-core:loadUser", function(userData)
    core.user = userData
    print(("[erotic-core] Welcome %s! Arena ID: %s"):format(userData.username, userData.arena_id))
end)

core = core or {}

local settingsActions = {
    locals = function(v) if v then TriggerEvent("core:enableLocals") end end,
    headshots = function(v) exports["gamesettings"]:setHsMulti(v) end,
    helmets = function(v) exports["gamesettings"]:setHelmetsEnabled(v) end,
    ragdoll = function(v) exports["gamesettings"]:setCarRagdoll(v) end,
    recoil = function(v) exports["gamesettings"]:setRecoilMode(v or "qb") end,
    spawningcars = function(v) exports["gamesettings"]:spawningcars(v, false) end,
    blips = function(v) if not v then TriggerEvent("erotic-core:disableBlips") end end
}

RegisterNetEvent("erotic-core:applyGameSettings", function(settings, mode)
    core.currentMode = mode
    for key,value in pairs(settings) do
        local fn = settingsActions[key]
        if fn then fn(value) end
    end
    if not settings.recoil then
        exports["gamesettings"]:setRecoilMode("qb")
    end
    print(("[erotic-core] Applied settings for %s"):format(mode))
end)

