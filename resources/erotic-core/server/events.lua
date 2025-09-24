core = rawget(_G, "core") or {}
_G.core = core

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

    core.ensureBaseWorlds()
    core.sendCustomTemplates(src)
    core.sendWorldList(src)

    core.loadOrCreateUser(src, function(user, err)
        if not user then
            print("[erotic-core] ERROR: " .. tostring(err))
            DropPlayer(src, "Identifier error")
            return
        end

        core.users[src] = user
        print(("[erotic-core] Loaded user %s (ArenaID: %s)"):format(user.username, user.arena_id))
        TriggerClientEvent("erotic-core:loadUser", src, user)
        core.sendWorldList(src)
    end)
end)

-- Clean up on drop
AddEventHandler("playerDropped", function(reason)
    local src = source
    local world = core.leaveCurrentWorld(src, "disconnect")
    core.users[src] = nil

    if core.queue and type(core.queue) == "table" then
        for i, queued in ipairs(core.queue) do
            if queued == src then
                table.remove(core.queue, i)
                break
            end
        end
    end

    core.removeFromQueues(src)

    if world and world.type == "match" then
        core.handleMatchPlayerLeft(src, reason)
    elseif world and world.type == "personal" then
        core.handleWorldOwnerLeft(src)
    end

    print(("[erotic-core] %s disconnected (%s)"):format(GetPlayerName(src) or "Unknown", reason))
end)

RegisterNetEvent("arena:requestJoin", function(mode)
    local src = source
    mode = tostring(mode or ""):lower()

    if mode == "" then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Invalid mode." } })
        return
    end

    if mode == "ffa" or mode == "custom" then
        local ok, result = core.joinGamemode(src, mode)
        if not ok then
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", result or "Unable to join." } })
        else
            local worldName = (result and result.name) or mode
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Joined " .. worldName .. "." } })
        end
        return
    end

    if mode == "duel" or mode == "ranked4v4" then
        core.addToQueue(src, mode)
        return
    end

    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Unknown mode " .. mode } })
end)

RegisterNetEvent("arena:requestLeave", function()
    local src = source

    if core.isPlayerInMatch(src) then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Finish the match before leaving." } })
        return
    end

    core.removeFromQueues(src)
    local world = core.leaveCurrentWorld(src, "ui")
    if world then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Returned to lobby." } })
    else
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You are already in the lobby." } })
    end
end)

RegisterNetEvent("arena:createCustomWorld", function(options)
    local src = source
    options = options or {}

    local name = tostring(options.name or "")
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if #name > 48 then
        name = name:sub(1, 48)
    end

    local templateKey = options.template
    local template, normalizedTemplate = core.getCustomTemplate(templateKey)

    local capacity = tonumber(options.capacity)
    if capacity then
        capacity = math.floor(capacity)
        if capacity < 2 then capacity = 2 end
        if capacity > 32 then capacity = 32 end
    end

    local world = core.resetPersonalWorld(src, {
        name = name ~= "" and name or nil,
        template = normalizedTemplate,
        spawn = template and template.spawn or nil,
        capacity = capacity,
    })

    if not world then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Unable to create a custom arena right now." } })
        return
    end

    local ok, err = core.joinWorldByBucket(world.bucket, src, {
        spawn = world.metadata and world.metadata.spawn or (template and template.spawn),
        overrideCapacity = true
    })

    if not ok then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", err or "Unable to join the custom arena." } })
        return
    end

    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", ("Custom arena '%s' is ready."):format(world.name) } })
end)
