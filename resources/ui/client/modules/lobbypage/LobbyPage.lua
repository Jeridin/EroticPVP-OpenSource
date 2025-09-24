-- LobbyPage.lua

LOBBYPAGE = {}

-- Handle button presses from React (fetchNui calls)
RegisterNUICallback("lobbyAction", function(data, cb)
    local action = data.action
    local mode = data.mode

    if action == "join" and mode then
        -- tell server: join that mode
        TriggerServerEvent("arena:requestJoin", mode)

    elseif action == "leave" then
        -- tell server: leave current mode
        TriggerServerEvent("arena:requestLeave")

    end

    cb({ success = true })
end)

print("[erotic-core] LobbyPage client loaded")
