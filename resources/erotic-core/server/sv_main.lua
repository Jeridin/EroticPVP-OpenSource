core = core or {}

RegisterCommand("kill", function(source)
    if source == 0 then
        print("Run this in-game, not from the server console.")
        return
    end
    TriggerClientEvent("erotic-core:killMe", source)
end, false)

RegisterNetEvent('erotic-core:playerReady', function()
    local src = source
    
    core.loadOrCreateUser(src, function(userData, err)
        if err then
            print(("[erotic-core] Error loading user %d: %s"):format(src, err))
            return
        end
        
        core.users[src] = userData
        print(("[erotic-core] Loaded user %d - Arena ID: %d"):format(src, userData.arena_id))

        TriggerClientEvent('erotic-core:setUserData', src, userData)
        core.sendFriendsList(src, userData.arena_id)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if core.users[src] then
        print(("[erotic-core] Removing user %d"):format(src))
        core.users[src] = nil
    end

    for wid, w in pairs(core.worlds) do
        if w.players[src] then
            w.players[src] = nil
            core.broadcastWorldsUpdate()
            break
        end
    end
end)

exports('GetUserData', function(src)
    return core.users[src]
end)