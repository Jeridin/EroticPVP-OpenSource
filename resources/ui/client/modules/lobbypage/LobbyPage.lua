-- LobbyPage.lua
LOBBYPAGE = {}
local userData = nil

print("[LobbyPage] Client script loading...")

-- Store user data when received
RegisterNetEvent('erotic-core:setUserData', function(data)
    print("[LobbyPage] Received user data:", json.encode(data))
    userData = data
    SendReactMessage('setUserData', data)
end)

-- Listen for worlds update from server
RegisterNetEvent('erotic-core:worldsUpdate', function(worlds)
    print("[LobbyPage] Received worldsUpdate from server")
    
    local worldsArray = {}
    for id, world in pairs(worlds) do
        print(string.format("[LobbyPage] Processing world %d: %s", id, world.information.name))
        table.insert(worldsArray, world)
    end
    
    print("[LobbyPage] Sending to React, array size:", #worldsArray)
    SendReactMessage('setWorldsData', worldsArray)
end)

RegisterNetEvent('erotic-core:lobbyOpened', function()
    print("[LobbyPage] Lobby opened - requesting fresh data")
    TriggerServerEvent('erotic-core:playerReady')
    TriggerServerEvent('erotic-core:requestWorldsData')
end)

RegisterNUICallback("requestWorlds", function(data, cb)
    print("[LobbyPage] NUI requested worlds refresh")
    TriggerServerEvent('erotic-core:requestWorldsData')
    cb({ success = true })
end)

RegisterNUICallback("joinWorld", function(data, cb)
    print("[LobbyPage] NUI Callback: joinWorld")
    print("[LobbyPage] World ID:", data.worldId)
    
    TriggerServerEvent("erotic-core:joinWorld", data.worldId, data.password)
    cb({ success = true })
end)

RegisterNUICallback("createWorld", function(data, cb)
    print("[LobbyPage] NUI Callback: createWorld")
    
    TriggerServerEvent("erotic-core:createCustomWorld", data)
    cb({ success = true })
end)

RegisterNetEvent('erotic-core:joinResult', function(success, message)
    print("[LobbyPage] Join result - Success:", success, "Message:", message)
    SendReactMessage('joinResult', { success = success, message = message })
end)

print("[LobbyPage] Client script loaded successfully")