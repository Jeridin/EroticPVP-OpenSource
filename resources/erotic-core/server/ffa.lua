core = rawget(_G, "core") or {}
_G.core = core

local function joinFFA(src)
    local ok, err = core.joinGamemode(src, "ffa")
    if not ok then
        if err == "World is full" then
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "FFA is currently full." } })
        elseif err == "Finish your current match before switching arenas." then
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", err } })
        else
            TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", err or "Unable to join FFA right now." } })
        end
        return
    end

    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You entered the Free-For-All arena." } })
end

local function leaveFFA(src)
    local world = core.getWorldByPlayer(src)
    if not world or world.gamemode ~= "ffa" then
        TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You are not in FFA." } })
        return
    end

    core.leaveCurrentWorld(src, "ui")
    TriggerClientEvent("chat:addMessage", src, { args = { "[Arena]", "You left the Free-For-All arena." } })
end

RegisterCommand("joinffa", function(src)
    joinFFA(src)
end, false)

RegisterCommand("leaveffa", function(src)
    leaveFFA(src)
end, false)
