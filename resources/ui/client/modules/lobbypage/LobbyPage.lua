local lobbyCamera = nil
local isInLobby = false
local originalPedCoords = nil
local originalPedHeading = nil
local loadedInteriorId = nil

local lobbyCoords = vector3(514.5808, 4834.8682, -63.5)

local lobbySpawns = {
    vector4(514.5808, 4834.8682, -63.5,    359.8080), -- Leader
    vector4(515.7495, 4835.9990, -62.5874, 28.3401), -- Slot 2
    vector4(512.8184, 4835.4800, -62.5878, 334.0247),  -- Slot 3
    vector4(512.1323, 4836.7051, -62.5878, 272.9919), -- Slot 4
}
local lobbyHeading = 359.8080
local lobbyCamCoords = vector3(513.8813, 4840.0156, -62.0)
local lobbyCamRotation = vector3(-5.0, 0.0, 180.0)

-- Load Doomsday IPLs
local function LoadDoomsdayIPLs()
    RequestIpl("xm_x17dlc_int_placement")
    RequestIpl("xm_x17dlc_int_placement_interior_0_x17dlc_int_base_ent_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_1_x17dlc_int_base_loop_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_2_x17dlc_int_bse_tun_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_3_x17dlc_int_base_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_8_x17dlc_int_sub_milo_")
    RequestIpl("xm_bunkerentrance_door")
    RequestIpl("xm_hatch_closed")
    RequestIpl("xm_hatches_terrain")
end

-- Setup lobby scene
local function SetupLobbyScene()
    local playerPed = PlayerPedId()

    originalPedCoords = GetEntityCoords(playerPed)
    originalPedHeading = GetEntityHeading(playerPed)

    TriggerServerEvent('erotic-core:setLobbyBucket')
    Wait(100)

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    RequestCollisionAtCoord(lobbyCoords.x, lobbyCoords.y, lobbyCoords.z)

    SetEntityCoords(playerPed, lobbyCoords.x, lobbyCoords.y, lobbyCoords.z, false, false, false, true)
    SetEntityHeading(playerPed, lobbyHeading)

    Wait(1000)

    local interiorId = GetInteriorAtCoords(lobbyCoords.x, lobbyCoords.y, lobbyCoords.z)
    local timeout = 0
    while interiorId == 0 and timeout < 50 do
        Wait(100)
        interiorId = GetInteriorAtCoords(lobbyCoords.x, lobbyCoords.y, lobbyCoords.z)
        timeout = timeout + 1
    end
    if interiorId ~= 0 then
        loadedInteriorId = interiorId
        PinInteriorInMemory(interiorId)
        RefreshInterior(interiorId)
    else
        print("[LobbyPage] WARNING: Failed to load submarine interior!")
    end

    FreezeEntityPosition(playerPed, true)

    if lobbyCamera then DestroyCam(lobbyCamera, false) end
    lobbyCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(lobbyCamera, lobbyCamCoords.x, lobbyCamCoords.y, lobbyCamCoords.z)
    SetCamRot(lobbyCamera, lobbyCamRotation.x, lobbyCamRotation.y, lobbyCamRotation.z, 2)
    SetCamFov(lobbyCamera, 50.0)
    SetCamActive(lobbyCamera, true)
    RenderScriptCams(true, false, 0, true, true)

    SetPlayerControl(PlayerId(), false, 0)
    DisplayRadar(false)

    RequestAnimDict("amb@world_human_stand_impatient@male@no_sign@base")
    while not HasAnimDictLoaded("amb@world_human_stand_impatient@male@no_sign@base") do Wait(10) end
    TaskPlayAnim(playerPed, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, 8.0, -1, 1, 0, false, false, false)

    DoScreenFadeIn(500)
end

-- Cleanup
local function CleanupLobbyScene()
    isInLobby = false
    local playerPed = PlayerPedId()

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    if lobbyCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(lobbyCamera, false)
        lobbyCamera = nil
    end

    if loadedInteriorId and loadedInteriorId ~= 0 then
        UnpinInterior(loadedInteriorId)
        loadedInteriorId = nil
    end

    ClearPedTasks(playerPed)
    TriggerServerEvent('erotic-core:restoreBucket')

    if originalPedCoords then
        RequestCollisionAtCoord(originalPedCoords.x, originalPedCoords.y, originalPedCoords.z)
        SetEntityCoords(playerPed, originalPedCoords.x, originalPedCoords.y, originalPedCoords.z, false, false, false, true)
        SetEntityHeading(playerPed, originalPedHeading)
        originalPedCoords = nil
        originalPedHeading = nil
    end

    Wait(500)
    FreezeEntityPosition(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    DisplayRadar(true)
    DoScreenFadeIn(500)
end

-- =================
-- NUI Callbacks
-- =================
RegisterNUICallback("joinWorld", function(data, cb)
    print("[LobbyPage] Joining world:", json.encode(data))
    TriggerServerEvent("erotic-core:joinWorld", data.worldId, data.password)
    cb({ success = true })
end)

RegisterNUICallback("inviteToParty", function(data, cb)
    print("[LobbyPage] NUI inviteToParty called with:", json.encode(data))
    TriggerServerEvent("erotic-core:inviteToParty", data.arenaId)
    cb({ success = true })
end)

RegisterNUICallback("acceptInvite", function(data, cb)
    print("[LobbyPage] NUI acceptInvite called with:", json.encode(data))
    TriggerServerEvent("erotic-core:acceptInvite", data.inviteId)
    cb({ success = true })
end)

RegisterNUICallback("declineInvite", function(data, cb)
    print("[LobbyPage] NUI declineInvite called with:", json.encode(data))
    TriggerServerEvent("erotic-core:declineInvite", data.inviteId)
    cb({ success = true })
end)

RegisterNUICallback("addFriend", function(data, cb)
    print("[LobbyPage] NUI addFriend called with:", json.encode(data))
    TriggerServerEvent("erotic-core:addFriend", data.arenaId)
    cb({ success = true })
end)

-- ==============
-- Events
-- ==============
RegisterNetEvent('erotic-core:setLobbySpawn', function(slot)
    local playerPed = PlayerPedId()
    local pos = lobbySpawns[slot]
    if not pos then return end

    -- Make sure collision & interior are loaded
    RequestCollisionAtCoord(pos.x, pos.y, pos.z)

    local interior = GetInteriorAtCoords(pos.x, pos.y, pos.z)
    local timeout = 0
    while (not HasCollisionLoadedAroundEntity(playerPed) or interior == 0) and timeout < 100 do
        Wait(50)
        interior = GetInteriorAtCoords(pos.x, pos.y, pos.z)
        timeout = timeout + 1
    end

    SetEntityCoords(playerPed, pos.x, pos.y, pos.z, false, false, false, true)
    SetEntityHeading(playerPed, pos.w)
    FreezeEntityPosition(playerPed, true)  -- optional: hold in place
    Wait(100)
    FreezeEntityPosition(playerPed, false)
end)

RegisterNetEvent('erotic-core:lobbyOpened', function()
    if isInLobby then print("[LobbyPage] Already in lobby") return end
    print("[LobbyPage] Lobby opened")
    isInLobby = true

    LoadDoomsdayIPLs()
    Wait(500)
    SetupLobbyScene()

    TriggerServerEvent('erotic-core:playerReady')
    TriggerServerEvent('erotic-core:requestWorldsData')
end)

RegisterNetEvent('erotic-core:lobbyClosed', function()
    if not isInLobby then return end
    print("[LobbyPage] Lobby closed")
    CleanupLobbyScene()
    exports["ui"]:ToggleLobbyPage(false)
end)

-- Forward events from server to React
RegisterNetEvent('erotic-core:joinResult', function(success, message)
    print("[LobbyPage] Join result:", success, message)
    SendReactMessage('joinResult', { success = success, message = message })

    if success then
        print("[LobbyPage] Join successful, preparing for world spawn...")

        local playerPed = PlayerPedId()

        TriggerServerEvent('erotic-core:leaveParty')

        if lobbyCamera then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(lobbyCamera, false)
            lobbyCamera = nil
        end

        if loadedInteriorId and loadedInteriorId ~= 0 then
            UnpinInterior(loadedInteriorId)
            loadedInteriorId = nil
        end

        ClearPedTasks(playerPed)
        FreezeEntityPosition(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)
        DisplayRadar(true)

        isInLobby = false
        originalPedCoords = nil
        originalPedHeading = nil

        exports["ui"]:ToggleLobbyPage(false)
        print("[LobbyPage] Player ready for server teleport")
    end
end)

RegisterNetEvent('erotic-core:worldsUpdate', function(worlds)
    print("[LobbyPage] worldsUpdate:", json.encode(worlds))
    local worldsArray = {}
    for id, world in pairs(worlds) do table.insert(worldsArray, world) end
    SendReactMessage('setWorldsData', worldsArray)
end)

RegisterNetEvent('erotic-core:setUserData', function(data)
    print("[LobbyPage] setUserData:", json.encode(data))
    SendReactMessage('setUserData', data)
end)

RegisterNetEvent('erotic-core:partyInvite', function(invite)
    print("[LobbyPage] Received party invite:", json.encode(invite))
    SendReactMessage('partyInvite', invite)
end)

RegisterNetEvent('erotic-core:setFriendsList', function(friends)
    print("[LobbyPage] setFriendsList from server:", json.encode(friends))
    SendReactMessage('setFriendsList', friends)
end)

-- 🆕 Forward party updates from server -> React
RegisterNetEvent('erotic-core:updateParty', function(partyMembers)
    print("[LobbyPage] updateParty:", json.encode(partyMembers))
    SendReactMessage('setPartyMembers', partyMembers)
end)

RegisterNetEvent('erotic-core:lobbyClosed', function()
    if not isInLobby then return end
    print("[LobbyPage] Lobby closed")

    -- 🆕 tell server we left party if we were in one
    TriggerServerEvent('erotic-core:leaveParty')

    CleanupLobbyScene()
    exports["ui"]:ToggleLobbyPage(false)
end)