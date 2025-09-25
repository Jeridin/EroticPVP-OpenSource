core.queue = core.queue or {}
core.users = core.users or {}

-- Enforce Steam on connect
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update("Checking identifiers...")

    local ids = core.getAllIdentifiers(src)
    if not ids.steam then
        deferrals.done("Steam must be running to join this server.")
        CancelEvent()
        return
    end

    deferrals.done()
end)

-- Handle joining
AddEventHandler("playerJoining", function()
    local src = source
    TriggerClientEvent("erotic-core:enablePVP", src)
    
    core.loadOrCreateUser(src, function(user, err)
        if not user then
            print("[erotic-core] ERROR: " .. tostring(err))
            DropPlayer(src, "Identifier error")
            return
        end

        core.users[src] = user
        print(("[erotic-core] Loaded user %s (ArenaID: %s)"):format(user.username, user.arena_id))
        TriggerClientEvent("erotic-core:loadUser", src, user)
    end)
end)

-- Clean up on drop
AddEventHandler("playerDropped", function(reason)
    local src = source
    core.users[src] = nil

    if core.queue and type(core.queue) == "table" then
        for i, queued in ipairs(core.queue) do
            if queued == src then
                table.remove(core.queue, i)
                break
            end
        end
    end

    print(("[erotic-core] %s disconnected (%s)"):format(GetPlayerName(src) or "Unknown", reason))
end)