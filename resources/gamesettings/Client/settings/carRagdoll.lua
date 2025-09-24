--[[
local WasOnVehicle = false
local RagdollSpeed = 30.0
local carRagDollEnabled = false  -- State control variable

-- Thread for car ragdoll
local wait = Wait
local set_ragdoll_blocking_flags = SetRagdollBlockingFlags
local get_entity_speed = GetEntitySpeed
local clear_ragdoll_blocking_flags = ClearRagdollBlockingFlags
local set_ped_to_ragdoll = SetPedToRagdoll


local function EnableCarRagdoll()
    CreateThread(function()
        while carRagDollEnabled do
            wait(10)
            if isOnVehicle then
                set_ragdoll_blocking_flags(PlayerPed, 2)
            elseif WasOnVehicle and not isOnVehicle then
                clear_ragdoll_blocking_flags(PlayerPed, 2)
                if get_entity_speed(PlayerPed) > RagdollSpeed then
                    set_ped_to_ragdoll(PlayerPed)
                end
                wait(1000)
            end
            WasOnVehicle = isOnVehicle
        end
    end)
end
]]

-- Function to control the state of car ragdoll
function SetCarRagdoll(state)
    --carRagDollEnabled = state
    OverridePedsCanStandOnTopFlag(state)
    --if state then
        --EnableCarRagdoll()
    --end
end

-- Exporting the function
exports("setCarRagdoll", SetCarRagdoll)