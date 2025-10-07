-- sv_events.lua
core = core or {}
core.queue = core.queue or {}
core.users = core.users or {}
core.pendingInvites = core.pendingInvites or {}
core.parties = core.parties or {}

-- =========================
-- CONNECT / LOAD USER FLOW
-- =========================
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

-- ====================
-- FRIENDS
-- ====================
RegisterNetEvent("erotic-core:addFriend", function(arenaId)
    local src = source
    local user = core.users[src]
    if not user then return end

    local targetArenaId = tonumber(arenaId)
    if not targetArenaId then return end

    if targetArenaId == user.arena_id then
        TriggerClientEvent("erotic-core:setFriendsList", src, {{
            id = user.arena_id,
            username = user.username .. " (You)",
            status = "online"
        }})
        return
    end

    exports.oxmysql:execute("SELECT arena_id, username, level FROM users WHERE arena_id = ?", {targetArenaId}, function(rows)
        if #rows == 0 then return end
        local friend = rows[1]
        TriggerClientEvent("erotic-core:setFriendsList", src, {{
            id = friend.arena_id,
            username = friend.username,
            status = "online"
        }})
    end)
end)

-- ===============================
-- PARTY SYSTEM
-- ===============================
local function getPartyByMember(src)
    for partyId, party in pairs(core.parties) do
        if party.members[src] then return partyId, party end
    end
    return nil, nil
end

local function getNextSlot(party)
    local used = {}
    for _, m in pairs(party.members) do
        if type(m) == "table" and m.spawnIndex then
            used[m.spawnIndex] = true
        end
    end
    for i = 1, 4 do
        if not used[i] then return i end
    end
    return 1
end

local function createParty(leader, member)
    local id = math.random(100000, 999999)
    core.parties[id] = {
        id = id,
        members = {
            [leader] = { spawnIndex = 1 },
            [member] = { spawnIndex = 2 }
        },
        leader = leader
    }
    print(("[PARTY] Created party %d with leader %s and member %s"):format(id, leader, member))
    return id
end

function broadcastParty(party)
    local memberData = {}
    for src, m in pairs(party.members) do
        local u = core.users[src]
        if u then
            table.insert(memberData, {
                id       = tostring(u.arena_id or u.id or src),
                username = u.username,
                level    = u.level or 1,
                isLeader = (src == party.leader),
                avatarUrl= u.avatarUrl,
                rank     = u.rank or "copper",
                tier     = u.tier or 1,
            })
        end
    end

    for src, m in pairs(party.members) do
        TriggerClientEvent('erotic-core:updateParty', src, memberData)
        if m.spawnIndex then
            TriggerClientEvent('erotic-core:setSpawnIndex', src, m.spawnIndex)
        end
    end
end

local function movePartyToBucket(partyId)
    local bucket = 20000 + partyId
    local party = core.parties[partyId]
    if not party then return end
    for src, _ in pairs(party.members) do
        SetPlayerRoutingBucket(src, bucket)
    end
end

-- ====================
-- Invites
-- ====================
RegisterNetEvent("erotic-core:inviteToParty", function(targetArenaId)
    local src = source
    local target = nil
    for id, user in pairs(core.users) do
        if user.arena_id == tonumber(targetArenaId) then target = id break end
    end
    if not target then return end

    local inviteId = math.random(100000, 999999)
    core.pendingInvites[inviteId] = { from = src, to = target }
    TriggerClientEvent('erotic-core:partyInvite', target, {
        id = tostring(inviteId),
        message = ("Party invite from %s"):format(GetPlayerName(src))
    })
end)

RegisterNetEvent("erotic-core:acceptInvite", function(inviteId)
    local src = source
    local invite = core.pendingInvites[tonumber(inviteId)]
    if not invite or invite.to ~= src then return end

    local from = invite.from
    local partyId, party = getPartyByMember(from)
    local myPartyId = select(1, getPartyByMember(src))

    if party and myPartyId == partyId then
        TriggerClientEvent('SendReactMessage', src, 'removeInvite', { id = tostring(inviteId) })
        core.pendingInvites[tonumber(inviteId)] = nil
        return
    end

    core.pendingInvites[tonumber(inviteId)] = nil

    if not party then
        partyId = createParty(from, src)
        party = core.parties[partyId]
    else
        party.members[src] = { spawnIndex = getNextSlot(party) }
    end

    broadcastParty(party)
    movePartyToBucket(partyId)
end)

RegisterNetEvent("erotic-core:leaveParty", function()
    local src = source
    local partyId, party = getPartyByMember(src)
    if not party then return end

    party.members[src] = nil
    if next(party.members) == nil then
        core.parties[partyId] = nil
    else
        broadcastParty(party)
    end
end)

RegisterNetEvent("erotic-core:declineInvite", function(inviteId)
    local src = source
    core.pendingInvites[tonumber(inviteId)] = nil
end)
