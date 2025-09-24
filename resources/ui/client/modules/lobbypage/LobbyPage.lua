-- LobbyPage.lua

LOBBYPAGE = LOBBYPAGE or {}
LOBBYPAGE.worlds = LOBBYPAGE.worlds or {}
LOBBYPAGE.templates = LOBBYPAGE.templates or {}

RegisterNetEvent("erotic-core:updateWorldList", function(worlds)
    LOBBYPAGE.worlds = worlds or {}
    SendReactMessage("updateWorldList", LOBBYPAGE.worlds)
end)

RegisterNetEvent("erotic-core:updateCustomTemplates", function(templates)
    LOBBYPAGE.templates = templates or {}
    SendReactMessage("updateCustomTemplates", LOBBYPAGE.templates)
end)

-- Handle button presses from React (fetchNui calls)
RegisterNUICallback("lobbyAction", function(data, cb)
    local action = data.action
    local mode = data.mode

    if action == "join" and mode then
        -- tell server: join that mode
        TriggerServerEvent("arena:requestJoin", mode)
        cb({ success = true })
        return

    elseif action == "leave" then
        -- tell server: leave current mode
        TriggerServerEvent("arena:requestLeave")
        cb({ success = true })
        return

    elseif action == "getWorlds" then
        cb({ success = true, worlds = LOBBYPAGE.worlds })
        return

    elseif action == "getTemplates" then
        cb({ success = true, templates = LOBBYPAGE.templates })
        return

    elseif action == "createCustom" then
        TriggerServerEvent("arena:createCustomWorld", data.options or {})
        cb({ success = true })
        return
    end

    cb({ success = false })
end)

print("[erotic-core] LobbyPage client loaded")
