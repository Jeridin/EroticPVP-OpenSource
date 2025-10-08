core = core or {}
core.users = core.users or {}
core.queue = core.queue or {}

function core.generateArenaId(cb)
    local function try()
        local id = math.random(100000, 999999)
        exports.oxmysql:execute("SELECT 1 FROM users WHERE arena_id = ?", {id}, function(rows)
            if #rows == 0 then
                cb(id)
            else
                try()
            end
        end)
    end
    try()
end

function core.getAllIdentifiers(src)
    local identifiers = {}
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        local prefix, value = v:match("([^:]+):(.+)")
        identifiers[prefix] = value
    end
    return identifiers
end

function core.loadOrCreateUser(src, cb)
    local ids = core.getAllIdentifiers(src)
    if not ids.steam then
        cb(nil, "Steam required")
        return
    end

    exports.oxmysql:execute("SELECT * FROM users WHERE steam = ?", {ids.steam}, function(rows)
        if #rows > 0 then
            cb(rows[1]) -- user exists, reuse their ArenaID
        else
            core.generateArenaId(function(newArenaId)
                exports.oxmysql:insert([[
                    INSERT INTO users (arena_id, username, steam, license, xbl, live, discord, fivem)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    newArenaId,
                    GetPlayerName(src),
                    ids.steam,
                    ids.license,
                    ids.xbl,
                    ids.live,
                    ids.discord,
                    ids.fivem
                }, function(newId)
                    cb({
                        id = newId,
                        arena_id = newArenaId,
                        username = GetPlayerName(src),
                        steam = ids.steam,
                        level = 1,
                        xp = 0,
                        gems = 0
                    })
                end)
            end)
        end
    end)
end

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
        TriggerClientEvent("erotic-core:setUserData", src, user)
    end)
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    core.users[src] = nil

    -- remove from queue
    if core.queue then
        for i, queued in ipairs(core.queue) do
            if queued == src then
                table.remove(core.queue, i)
                break
            end
        end
    end

    -- clean party membership
    local pid, party = (function()
        for partyId, p in pairs(core.parties) do
            if p.members[src] then return partyId, p end
        end
        return nil, nil
    end)()

    if party then
        party.members[src] = nil
        if next(party.members) == nil then
            print(("[PARTY] Destroyed empty party %d"):format(pid))
            core.parties[pid] = nil
        else
            print(("[PARTY] %s left party %d"):format(src, pid))
            broadcastParty(party)
        end
    end

    print(("[erotic-core] %s disconnected (%s)"):format(GetPlayerName(src) or "Unknown", reason))
end)
