local shakeCounter = 0
local shakeCounter2 = 0
local isShaking = false
local intenseCam = false
local wait = Wait
local IsPedStill = IsPedStill
local IsPlayerFreeAiming = IsPlayerFreeAiming
local IsPedAimingFromCover = IsPedAimingFromCover
local ShakeGameplayCam = ShakeGameplayCam
local StopGameplayCamShaking = StopGameplayCamShaking
local function setIntenseCam()
    CreateThread(function()
        while intenseCam do
            
            local plyPed = PlayerPedId()
    
            while true do
                local isAiming = IsPlayerFreeAiming(playerID)
                local isPedStill = IsPedStill(plyPed)
        
                if isAiming and isPedStill and not IsPedAimingFromCover(plyPed) then
    
                    wait(100)
        
                    shakeCounter = shakeCounter + 1
                    shakeCounter2 = 0
        
                    if shakeCounter == 5 then
                        isShaking = true
                        ShakeGameplayCam('HAND_SHAKE', 0.2)
                    end
        
                elseif isAiming and not isPedStill then
        
                    wait(10)
        
                    shakeCounter2 = shakeCounter2 + 1
                    shakeCounter = 0
        
                    if shakeCounter2 == 5 then
                        isShaking = true
                        ShakeGameplayCam('HAND_SHAKE', 0.9)
                    end
        
                    shakeCounter = 0
                    shakeCounter2 = 0
        
                else
        
                    if isShaking then
        
                        isShaking = false
                        shakeCounter = 0
                        shakeCounter2 = 0
        
                        StopGameplayCamShaking(true)
        
                    end
        
                    wait(1000)
        
                end
        
            end
        end
    end)
end

function SetIntenseCamEnabled(state)
    intenseCam = state
    isShaking = false
    shakeCounter = 0
    shakeCounter2 = 0
    StopGameplayCamShaking(true)
    if state then
        setIntenseCam()
    end
end

exports("SetIntenseCamEnabled", SetIntenseCamEnabled)