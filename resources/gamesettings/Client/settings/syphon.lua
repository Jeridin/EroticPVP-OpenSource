-- local syphonEnabled = false

-- --[[
--   True: syphon enabled
--   False: syphon disabled
-- ]]

-- function SetSyphon(state)
--     syphonEnabled = state == true
-- end

-- function GetSyphon()
--     return syphonEnabled
-- end

-- exports("setSyphon", SetSyphon)
-- exports("getSyphon", GetSyphon)

-- RegisterNetEvent('baseevents:onPlayerKilled')
-- AddEventHandler("baseevents:onPlayerKilled", function (killerId)
--     local killerPed = GetPlayerPed(killerId)
--     local currentArmor = GetPedArmour(killerPed)
--     local currentHealth = GetEntityHealth(killerPed)

--     -- print("Before - Armor:", currentArmor, "Health:", currentHealth)

--     local newArmor = math.min(currentArmor + math.random(25, 100), 100) -- Ensure armor does not exceed 100
--     local newHealth = math.min(currentHealth + math.random(50, 150), 200) -- Ensure health does not exceed 200

--     if GetSyphon() then
--         SetPedArmour(killerPed, newArmor)
--         SetEntityHealth(killerPed, newHealth)
--         print("After - Armor:", newArmor, "Health:", newHealth)
--     end
-- end)
