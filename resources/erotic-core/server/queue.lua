core = rawget(_G, "core") or {}
_G.core = core

core.queues = {
    duel = { size = 2, players = {}, gamemode = "duel" },
    ranked4v4 = { size = 8, players = {}, gamemode = "ranked4v4" }
}

-- Add a player to a queue
function core.addToQueue(src, queueName)
    local queue = core.queues[queueName]
    if not queue then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "Queue does not exist." } })
        return
    end

    if core.isPlayerInMatch(src) then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You are already in a match." } })
        return
    end

    local currentWorld = core.getWorldByPlayer(src)
    if currentWorld and currentWorld.gamemode ~= "lobby" then
        core.leaveCurrentWorld(src, "queue")
    end

    -- prevent double-queue
    for _, p in ipairs(queue.players) do
        if p == src then
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You are already in this queue!" } })
            return
        end
    end

    table.insert(queue.players, src)
    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You joined the " .. queueName .. " queue." } })

    -- start match if full
    if #queue.players >= queue.size then
        local players = {}
        for i = 1, queue.size do
            table.insert(players, table.remove(queue.players, 1))
        end
        core.createMatch(players, queue.gamemode)
    end
end

-- Remove player from all queues (disconnect or manual leave)
function core.removeFromQueues(src)
    for _, queue in pairs(core.queues) do
        for i, p in ipairs(queue.players) do
            if p == src then
                table.remove(queue.players, i)
                break
            end
        end
    end
end

-- Register commands
RegisterCommand("queue1v1", function(src)
    core.addToQueue(src, "duel")
end, false)

RegisterCommand("queue4v4", function(src)
    core.addToQueue(src, "ranked4v4")
end, false)

RegisterCommand("leavequeue", function(src)
    core.removeFromQueues(src)
    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You left all queues." } })
end, false)

-- Cleanup when player leaves
AddEventHandler("playerDropped", function()
    local src = source
    core.removeFromQueues(src)
end)
