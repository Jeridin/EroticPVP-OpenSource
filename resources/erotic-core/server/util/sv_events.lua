core = core or {}
core.users = core.users or {}
core.pendingInvites = core.pendingInvites or {}
core.parties = core.parties or {}

function core.sendFriendsList(src, userArenaId)
    exports.oxmysql:execute("SELECT friends FROM users WHERE arena_id = ?", {userArenaId}, function(rows)
        if not rows or #rows == 0 then return end
        local friends = {}
        if rows[1].friends then
            friends = json.decode(rows[1].friends) or {}
        end

        if #friends == 0 then
            TriggerClientEvent("erotic-core:setFriendsList", src, {})
            return
        end

        local placeholders = table.concat({string.rep('?,', #friends):sub(1, -2)})
        local sql = ("SELECT arena_id, username, level, rank, tier FROM users WHERE arena_id IN (%s)"):format(placeholders)

        exports.oxmysql:execute(sql, friends, function(rows2)
            local list = {}
            for _, f in ipairs(rows2) do
                table.insert(list, {
                    id = f.arena_id,
                    username = f.username,
                    level = f.level,
                    rank = f.rank,
                    tier = f.tier,
                    status = "online"
                })
            end
            TriggerClientEvent("erotic-core:setFriendsList", src, list)
        end)
    end)
end

RegisterNetEvent("erotic-core:addFriend", function(arenaId)
    local src = source
    local user = core.users[src]
    if not user then return end

    local targetArenaId = tonumber(arenaId)
    if not targetArenaId then return end
    if targetArenaId == user.arena_id then return end

    -- Fetch current friends JSON
    exports.oxmysql:execute("SELECT friends FROM users WHERE arena_id = ?", {user.arena_id}, function(rows)
        if not rows or #rows == 0 then return end

        local friends = {}
        if rows[1].friends then
            friends = json.decode(rows[1].friends) or {}
        end

        -- Avoid duplicates
        for _, f in ipairs(friends) do
            if f == targetArenaId then
                return core.sendFriendsList(src, user.arena_id) -- Already added
            end
        end

        table.insert(friends, targetArenaId)

        exports.oxmysql:execute(
            "UPDATE users SET friends = ? WHERE arena_id = ?",
            {json.encode(friends), user.arena_id},
            function()
                core.sendFriendsList(src, user.arena_id)
            end
        )
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
        -- existing UI update
        TriggerClientEvent('erotic-core:updateParty', src, memberData)

        -- NEW: tell each member where to stand in the lobby based on their spawnIndex (1..4)
        if m.spawnIndex then
            TriggerClientEvent('erotic-core:setLobbySpawn', src, m.spawnIndex)
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
