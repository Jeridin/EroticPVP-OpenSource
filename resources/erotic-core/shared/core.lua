core = rawget(_G, "core") or {}
_G.core = core

-- Generate random 6-digit arena ID
function core.generateArenaId()
    return math.random(100000, 999999)
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

-- Utility: count table entries safely
function core.tableCount(tbl)
    if type(tbl) ~= "table" then return 0 end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end
