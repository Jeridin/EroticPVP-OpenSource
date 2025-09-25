core.users = {}

-- generate a truly unique 6-digit id
function core.generateArenaId(cb)
    local function try()
        local id = math.random(100000, 999999)
        exports.oxmysql:execute("SELECT 1 FROM users WHERE arena_id = ?", {id}, function(rows)
            if #rows == 0 then
                cb(id)
            else
                try() -- unlucky collision, try again
            end
        end)
    end
    try()
end

-- Get all identifiers for a player
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
