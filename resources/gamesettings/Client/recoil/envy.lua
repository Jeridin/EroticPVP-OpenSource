-- Weapon Recoil: Recoil (vertical and horizontal) for individual weapon; 0.0 means no recoil at all, 0.1 means default

local WeaponRecoil = {
    [`weapon_tacticalrifle`] = { vertical = .31, horizontal = .15 },
    [`weapon_MK18`] = { vertical = .15 },
    [`weapon_specialcarbine`] = { vertical = .11 },
    [`weapon_heavyrifle`] = { vertical = .19 },
    [`weapon_glock17`] = { vertical = .21 },
    [`weapon_fnx45`] = { vertical = .21 },
    [`WEAPON_GLOCK18`] = { vertical = .80, horizontal = .20 },
    [`weapon_appistol`] = { vertical = .80, horizontal = .20 },
    [`weapon_minismg`] = { vertical = .80 },
    [`WEAPON_TEC9`] = { vertical = .20 },
    [`weapon_combatmg`] = { vertical = .15 },
    [`weapon_m249`] = { vertical = .15 },
    [`weapon_m60`] = { vertical = .15 },
    [`weapon_assaultrifle`] = { vertical = .23 },
    [`weapon_combatpdw`] = { vertical = .11 },
    [`weapon_assaultsmg`] = { vertical = .18 },
    [`weapon_smg_mk2`] = { vertical = .26 },
    [`weapon_microsmg`] = { vertical = .48 },
    [`weapon_762`] = { vertical = .56, horizontal = .18 },
    [`weapon_mp5`] = { vertical = .26 },
}

-- Group recoil: This is the recoil for the group overall if it is lacking an individual weapon recoil; 0.0 means no recoil at all

local GroupRecoil = {
    [416676503] = { vertical = .20, horizontal = .1 }, -- Handgun
    [-957766203] = { vertical = .17 }, -- Submachine
    [860033945] = { vertical = .25 }, -- Shotgun
    [970310034] = { vertical = .27 }, -- Assault Rifle
    [1159398588] = { vertical = .18 }, -- LMG
    [3082541095] = { vertical = .15 }, -- Sniper
    [2725924767] = { vertical = .3 } -- Heavy
}

local isMoving = false
local storedRecoils = {}

local random = math.random
local function GetStressRecoil()
    return random() * (1.16 - 1.11) + 1.11
end

local GetEntitySpeed = GetEntitySpeed
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetVehicleClass = GetVehicleClass
local GetWeapontypeGroup = GetWeapontypeGroup
local GetGameplayCamRelativeHeading = GetGameplayCamRelativeHeading
local SetGameplayCamRelativeHeading = SetGameplayCamRelativeHeading
local GetGameplayCamRelativePitch = GetGameplayCamRelativePitch
local SetGameplayCamRelativePitch = SetGameplayCamRelativePitch
local GetFollowPedCamViewMode = GetFollowPedCamViewMode
local ceil = math.ceil
local IsPedArmed = IsPedArmed
local SetWeaponRecoilShakeAmplitude = SetWeaponRecoilShakeAmplitude
local GetWeaponRecoilShakeAmplitude = GetWeaponRecoilShakeAmplitude
local IsPedShooting = IsPedShooting
local wait = Wait

Recoil:RegisterMode('envy', function()
    
    local plyPed = PlayerPedId() -- Defining the player's ped
    
    local isArmed = IsPedArmed(plyPed, 4) -- Checking if they are armed
    local _, weapon = GetCurrentPedWeapon(plyPed, true) -- Get's the ped's weapon
    
    local vehicle = GetVehiclePedIsIn(plyPed, false)
    local inVehicle = vehicle ~= 0

    if isArmed then
        if inVehicle then
            if not storedRecoils[weapon] then
                storedRecoils[weapon] = GetWeaponRecoilShakeAmplitude(weapon)
                SetWeaponRecoilShakeAmplitude(weapon, 4.5)
            end
        else
            if storedRecoils[weapon] then
                SetWeaponRecoilShakeAmplitude(weapon, storedRecoils[weapon])
                storedRecoils[weapon] = nil
            end
        end
    end
    
    if isArmed and IsPedShooting(plyPed) then -- Check if they are armed and dangerous (shooting)
        local movementSpeed = ceil(GetEntitySpeed(plyPed)) -- Getting the speed of the ped
        local stressRecoil = GetStressRecoil()
        local camHeading = GetGameplayCamRelativeHeading()
        local headingFactor = random(10, 40 + movementSpeed) / 100
        local weaponRecoil = WeaponRecoil[weapon] or GroupRecoil[GetWeapontypeGroup(weapon)] or { vertical = 0.1, horizontal = 0.1 }
        local rightLeft = random(1, 4) -- Chance to move left or right
        local horizontalRecoil = (headingFactor * stressRecoil) * ((weaponRecoil.horizontal or 0.1) * 10)

        if rightLeft == 1 then -- If chance is 1, move right
            SetGameplayCamRelativeHeading(camHeading + horizontalRecoil)
        elseif rightLeft == 3 then -- If chance is 3, move left
            SetGameplayCamRelativeHeading(camHeading - horizontalRecoil)
        end
        
        if not isMoving then -- Checks if the recoil is already being vertically adjusted
            local farRange = ceil(75 + (movementSpeed * 3.0)) -- Faster the player is moving, the higher the random range for recoil
            local recoil = random(50, farRange) / 100 -- Random math from 50-farRange and then divides by 100
            local isFirstPerson = GetFollowPedCamViewMode() == 4
            local currentRecoil = 0.0 -- Sets a default value for current recoil at 0
            local finalRecoilTarget = (recoil * (weaponRecoil.vertical * 10)) * stressRecoil -- Working out the target for recoil

            if isFirstPerson then
                finalRecoilTarget = finalRecoilTarget / 9.5
            end

            local vehicleClass = inVehicle and GetVehicleClass(vehicle) or 0
            local weirdRecoil = vehicleClass == 13 or vehicleClass == 8

            repeat
                isMoving = true -- Sets the moving var to true
                wait(5)
                SetGameplayCamRelativePitch(GetGameplayCamRelativePitch() + (weirdRecoil and (random(28, 32) / 10) or 0.1), 0.125) -- Move the camera pitch up by 0.1
                currentRecoil = currentRecoil + 0.1 -- Increment current recoil by 0.1 as we moved up by 0.1
            until currentRecoil >= finalRecoilTarget -- Repeat until the currentRecoil variable reaches the desired recoil target
            
            isMoving = false -- Sets the moving var to false				
        end        
    end
    
end)

Recoil:OnModeChange(function()
    for weaponHash, recoil in pairs(storedRecoils) do
        SetWeaponRecoilShakeAmplitude(GetHashKey(weaponHash), recoil)
    end
end)

AddEventHandler("onResourceStop", function()
    for weaponHash, recoil in pairs(storedRecoils) do
        SetWeaponRecoilShakeAmplitude(GetHashKey(weaponHash), recoil)
    end
end)
