local ffaSpawns = {}
local inFFA = false
local kills, deaths = 0, 0

local function getRandomSpawn()
    return ffaSpawns[math.random(1, #ffaSpawns)]
end

RegisterNetEvent("erotic-core:ffaEnter", function(spawns)
    core.currentMode = "ffa"
    core.applyGameSettings("ffa")

    ffaSpawns = spawns or {}
    inFFA = true
    kills, deaths = 0, 0
    local coords = getRandomSpawn()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    AddArmourToPed(ped, 100)

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    print("[erotic-core] You joined FFA.")
end)

RegisterNetEvent("erotic-core:ffaExit", function()
    core.currentMode = "lobby"
    
    inFFA = false
    local ped = PlayerPedId()
    local lobby = vector4(231.15, -1390.96, 30.49, 339.39)
    SetEntityCoordsNoOffset(ped, lobby.x, lobby.y, lobby.z, false, false, false, true)
    SetEntityHeading(ped, lobby.w)
    print("[erotic-core] You left FFA.")
end)

-- handle respawn only if in FFA
CreateThread(function()
    while true do
        Wait(500)
        if inFFA and IsEntityDead(PlayerPedId()) then
            deaths += 1
            Wait(100)
            local coords = getRandomSpawn()
            local ped = PlayerPedId()
            ResurrectPed(ped)

            SetEntityHealth(ped, 200)
            AddArmourToPed(ped, 100)

            ClearPedTasksImmediately(ped)
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
            SetEntityHeading(ped, coords.w)
            print(("[erotic-core] Respawned in FFA. Kills: %d | Deaths: %d"):format(kills, deaths))
        end
    end
end)

-- track kills (when this client kills another player)
AddEventHandler("gameEventTriggered", function(name, args)
    if not inFFA then return end
    if name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local attacker = args[2]
        if attacker == PlayerPedId() and IsPedAPlayer(victim) and IsEntityDead(victim) then
            kills += 1
            print(("[erotic-core] Kill registered! Kills: %d | Deaths: %d"):format(kills, deaths))
        end
    end
end)
