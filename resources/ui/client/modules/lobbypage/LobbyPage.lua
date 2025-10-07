-- LobbyPage.lua (Client-side - Updated with new coordinates)
local lobbyCamera = nil
local isInLobby = false
local originalPedCoords = nil
local originalPedHeading = nil
local loadedInteriorId = nil

-- Submarine Lobby Coordinates (UPDATED)
local lobbyCoords = vector3(514.5808, 4834.8682, -63.5)
local lobbyHeading = 359.8080
local lobbyCamCoords = vector3(513.8813, 4840.0156, -62.0)
local lobbyCamRotation = vector3(-5.0, 0.0, 180.0)

-- Load Doomsday IPLs
local function LoadDoomsdayIPLs()
    print("[LobbyPage] Loading Doomsday IPLs...")
    
    RequestIpl("xm_x17dlc_int_placement")
    RequestIpl("xm_x17dlc_int_placement_interior_0_x17dlc_int_base_ent_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_1_x17dlc_int_base_loop_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_2_x17dlc_int_bse_tun_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_3_x17dlc_int_base_milo_")
    RequestIpl("xm_x17dlc_int_placement_interior_8_x17dlc_int_sub_milo_")
    RequestIpl("xm_bunkerentrance_door")
    RequestIpl("xm_hatch_closed")
    RequestIpl("xm_hatches_terrain")
    
    print("[LobbyPage] IPLs requested")
end

-- Setup lobby scene
local function SetupLobbyScene()
    print("[LobbyPage] Setting up lobby scene")
    
    local playerPed = PlayerPedId()
    
    -- Store original position
    originalPedCoords = GetEntityCoords(playerPed)
    originalPedHeading = GetEntityHeading(playerPed)
    print("[LobbyPage] Stored original position:", originalPedCoords)
    
    -- Request server to set unique routing bucket for this player
    TriggerServerEvent('erotic-core:setLobbyBucket')
    
    Wait(100) -- Wait for routing bucket to be set
    
    -- Fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    
    -- Teleport player to submarine
    RequestCollisionAtCoord(lobbyCoords.x, lobbyCoords.y, lobbyCoords.z)
    SetEntityCoords(playerPed, lobbyCoords.x, lobbyCoords.y, lobbyCoords.z, false, false, false, true)
    SetEntityHeading(playerPed, lobbyHeading)
    
    -- Wait for collision to load
    Wait(1000)
    
    -- Load interior now that player is nearby
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
        print("[LobbyPage] Interior loaded, ID:", interiorId)
    else
        print("[LobbyPage] WARNING: Failed to load submarine interior!")
    end
    
    -- Freeze player in place
    FreezeEntityPosition(playerPed, true)
    
    -- Setup camera
    if lobbyCamera then
        DestroyCam(lobbyCamera, false)
    end
    
    lobbyCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(lobbyCamera, lobbyCamCoords.x, lobbyCamCoords.y, lobbyCamCoords.z)
    SetCamRot(lobbyCamera, lobbyCamRotation.x, lobbyCamRotation.y, lobbyCamRotation.z, 2)
    SetCamFov(lobbyCamera, 50.0)
    SetCamActive(lobbyCamera, true)
    RenderScriptCams(true, false, 0, true, true)
    
    -- Disable controls but keep player visible
    SetPlayerControl(PlayerId(), false, 0)
    DisplayRadar(false)
    
    -- Play idle animation
    RequestAnimDict("amb@world_human_stand_impatient@male@no_sign@base")
    while not HasAnimDictLoaded("amb@world_human_stand_impatient@male@no_sign@base") do
        Wait(10)
    end
    TaskPlayAnim(playerPed, "amb@world_human_stand_impatient@male@no_sign@base", "base", 8.0, 8.0, -1, 1, 0, false, false, false)
    
    -- Fade back in
    DoScreenFadeIn(500)
    
    print("[LobbyPage] Lobby scene setup complete")
end

-- Cleanup
local function CleanupLobbyScene()
    print("[LobbyPage] Cleaning up lobby scene")
    
    isInLobby = false
    local playerPed = PlayerPedId()
    
    -- Fade out
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    
    -- Restore camera
    if lobbyCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(lobbyCamera, false)
        lobbyCamera = nil
    end
    
    -- Unpin interior
    if loadedInteriorId and loadedInteriorId ~= 0 then
        UnpinInterior(loadedInteriorId)
        loadedInteriorId = nil
    end
    
    -- Clear tasks
    ClearPedTasks(playerPed)
    
    -- Request server to restore routing bucket
    TriggerServerEvent('erotic-core:restoreBucket')
    
    -- Restore player position
    if originalPedCoords then
        RequestCollisionAtCoord(originalPedCoords.x, originalPedCoords.y, originalPedCoords.z)
        SetEntityCoords(playerPed, originalPedCoords.x, originalPedCoords.y, originalPedCoords.z, false, false, false, true)
        SetEntityHeading(playerPed, originalPedHeading)
        originalPedCoords = nil
        originalPedHeading = nil
    end
    
    Wait(500)
    
    -- Restore controls
    FreezeEntityPosition(playerPed, false)
    SetPlayerControl(PlayerId(), true, 0)
    DisplayRadar(true)
    
    -- Fade back in
    DoScreenFadeIn(500)
    
    print("[LobbyPage] Cleanup complete")
end

-- Events
RegisterNetEvent('erotic-core:lobbyOpened', function()
    if isInLobby then
        print("[LobbyPage] Already in lobby")
        return
    end
    
    print("[LobbyPage] Lobby opened")
    isInLobby = true
    
    LoadDoomsdayIPLs()
    Wait(500)
    
    SetupLobbyScene()
    
    TriggerServerEvent('erotic-core:playerReady')
    TriggerServerEvent('erotic-core:requestWorldsData')
end)

RegisterNetEvent('erotic-core:lobbyClosed', function()
    if not isInLobby then
        return
    end
    
    print("[LobbyPage] Lobby closed")
    CleanupLobbyScene()
    exports["ui"]:ToggleLobbyPage(false)
end)

RegisterNUICallback("closeLobby", function(data, cb)
    print("[LobbyPage] UI close requested")
    TriggerEvent('erotic-core:lobbyClosed')
    cb({ success = true })
end)

RegisterNUICallback("requestWorlds", function(data, cb)
    TriggerServerEvent('erotic-core:requestWorldsData')
    cb({ success = true })
end)

RegisterNUICallback("joinWorld", function(data, cb)
    print("[LobbyPage] Joining world:", data.worldId)
    TriggerServerEvent("erotic-core:joinWorld", data.worldId, data.password)
    cb({ success = true })
end)

RegisterNetEvent('erotic-core:joinResult', function(success, message)
    print("[LobbyPage] Join result:", success, message)
    SendReactMessage('joinResult', { success = success, message = message })
    
    if success then
        print("[LobbyPage] Join successful, preparing for world spawn...")
        
        local playerPed = PlayerPedId()
        
        -- Restore camera immediately
        if lobbyCamera then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(lobbyCamera, false)
            lobbyCamera = nil
        end
        
        -- Unpin interior
        if loadedInteriorId and loadedInteriorId ~= 0 then
            UnpinInterior(loadedInteriorId)
            loadedInteriorId = nil
        end
        
        -- Clear tasks and unfreeze
        ClearPedTasks(playerPed)
        FreezeEntityPosition(playerPed, false)
        SetPlayerControl(PlayerId(), true, 0)
        DisplayRadar(true)
        
        isInLobby = false
        originalPedCoords = nil
        originalPedHeading = nil
        
        -- Close UI
        exports["ui"]:ToggleLobbyPage(false)
        
        print("[LobbyPage] Player ready for server teleport")
        -- Server will handle routing bucket and teleport when joining world
    end
end)

RegisterNetEvent('erotic-core:worldsUpdate', function(worlds)
    local worldsArray = {}
    for id, world in pairs(worlds) do
        table.insert(worldsArray, world)
    end
    SendReactMessage('setWorldsData', worldsArray)
end)

RegisterNetEvent('erotic-core:setUserData', function(data)
    SendReactMessage('setUserData', data)
end)

RegisterNetEvent('erotic-core:playerLoaded', function()
    local src = source
    print(string.format("[erotic-core] Player %d has fully loaded", src))

    exports["ui"]:ToggleLobbyPage(true)
end)
print("[LobbyPage] Script loaded")