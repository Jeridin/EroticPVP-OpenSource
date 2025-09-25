core = core or {}

-- sv_dev.lua
RegisterCommand("kill", function(source)
    if source == 0 then
        print("Run this in-game, not from the server console.")
        return
    end
    TriggerClientEvent("erotic-core:killMe", source)
end, false)