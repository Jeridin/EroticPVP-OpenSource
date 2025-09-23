local activeBlips = {}
local trackingPlayers = {}
local blipThreadRunning = false

local trackingPlayers = {}
local blipThreadRunning = false
local updateInterval = 3000 -- default 3s

RegisterNetEvent("erotic-core:enableBlips", function(players, interval)
    trackingPlayers = players
    updateInterval = interval or 3000
    if not blipThreadRunning then
        blipThreadRunning = true
        CreateThread(function()
            while blipThreadRunning do
                -- create a *new* blip for each tracked player
                for _, id in ipairs(trackingPlayers) do
                    if id ~= GetPlayerServerId(PlayerId()) then
                        local player = GetPlayerFromServerId(id)
                        if player ~= -1 then
                            local ped = GetPlayerPed(player)
                            if DoesEntityExist(ped) then
                                local coords = GetEntityCoords(ped)
                                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                                SetBlipSprite(blip, 1)   -- dot
                                SetBlipColour(blip, 1)   -- red
                                SetBlipScale(blip, 0.7)
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString("Last Seen")
                                EndTextCommandSetBlipName(blip)

                                -- auto-remove after next update cycle
                                SetTimeout(updateInterval - 200, function()
                                    if DoesBlipExist(blip) then
                                        RemoveBlip(blip)
                                    end
                                end)
                            end
                        end
                    end
                end

                Wait(updateInterval) -- e.g. 3000ms
            end
        end)
    end
end)

RegisterNetEvent("erotic-core:disableBlips", function()
    blipThreadRunning = false
    trackingPlayers = {}
end)


-- For tracking a user
-- RegisterNetEvent("erotic-core:disableBlips", function()
--     blipThreadRunning = false
--     for _, blip in pairs(activeBlips) do
--         RemoveBlip(blip)
--     end
--     activeBlips = {}
--     trackingPlayers = {}
-- end)
