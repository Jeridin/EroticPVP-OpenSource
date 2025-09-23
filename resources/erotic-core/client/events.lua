RegisterNetEvent("erotic-core:loadUser", function(userData)
    core.user = userData
    print(("[erotic-core] Welcome %s! Arena ID: %s"):format(userData.username, userData.arena_id))
end)
