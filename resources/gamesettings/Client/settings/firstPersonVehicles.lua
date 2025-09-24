local firstPersonVehicleEnabled = false
local WasAimingThirdPerson

local wait = Wait
local is_ped_in_any_vehicle = IsPedInAnyVehicle
local get_follow_vehicle_cam_view_mode = GetFollowVehicleCamViewMode
local set_follow_vehicle_cam_view_mode = SetFollowVehicleCamViewMode
local is_control_pressed = IsControlPressed
local is_using_keyboard = IsUsingKeyboard
local is_aim_cam_active = IsAimCamActive
local disable_aim_cam_this_update = DisableAimCamThisUpdate
local stop_gameplay_cam_shaking = StopGameplayCamShaking
local createthread = CreateThread
local function firstPersonVehicle()
    createthread(function()
        while firstPersonVehicleEnabled do
            wait(10)
            local isInVehicle = is_ped_in_any_vehicle(PlayerPedId(), true)
            local viewMode = get_follow_vehicle_cam_view_mode()
            local isAiming = (is_control_pressed(0, 25) and is_using_keyboard(0)) or is_aim_cam_active()
        
            if isInVehicle and isAiming and not WasAimingThirdPerson then
                if viewMode ~= 4 then
                    set_follow_vehicle_cam_view_mode(4)
                    disable_aim_cam_this_update()
                    WasAimingThirdPerson = viewMode
                end
            elseif WasAimingThirdPerson and not isAiming then
                set_follow_vehicle_cam_view_mode(WasAimingThirdPerson)
                WasAimingThirdPerson = false
                wait(250)
            end
        end
    end)
end

function SetFirstPersonVehicleEnabled(state)
    firstPersonVehicleEnabled = state
    stop_gameplay_cam_shaking(true)
    if state then
        firstPersonVehicle()
    end
end

exports("setFirstPersonVehicleEnabled", SetFirstPersonVehicleEnabled)