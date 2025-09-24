core = rawget(_G, "core") or {}
_G.core = core

core.users = {}

function core.loadOrCreateUser(src, cb)
    local ids = core.getAllIdentifiers(src)

    if not ids.steam then
        cb(nil, "Steam required")
        return
    end

    exports.oxmysql:execute("SELECT * FROM users WHERE steam = ?", {ids.steam}, function(rows)
        if #rows > 0 then
            cb(rows[1])
        else
            local newArenaId = core.generateArenaId()
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
        end
    end)
end
