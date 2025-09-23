core = core or {}

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
