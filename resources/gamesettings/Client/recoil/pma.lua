local recoilTable = {
    [`weapon_appistol`] = {noAim = 1.15, aim = 0.985},
    [`WEAPON_AK47`] = {noAim = 1.15, aim = 0.785},
    [`weapon_assaultrifle_mk2`] = {noAim = 1.15, aim = 0.785},
    [`weapon_bullpuprifle`] = {noAim = 1.15, aim = 0.785},
    [`weapon_bullpuprifle_mk2`] = {noAim = 1.15, aim = 0.785},
    [`weapon_carbinerifle_mk2`] = {noAim = 1.15, aim = 0.785},
    [`weapon_combatpistol`] = {noAim = 3.15, aim = 1.785},
    [`weapon_compactrifle`] = {noAim = 1.15, aim = 0.785},
    [`weapon_fnx45`] = {noAim = 3.15, aim = 1.785},
    [`weapon_glock18c`] = {noAim = 1.15, aim = 0.985},
    [`weapon_gusenberg`] = {noAim = 2.15, aim = 1.585},
    [`weapon_heavypistol`] = {noAim = 3.15, aim = 1.785},
    [`weapon_microsmg`] = {noAim = 3.15, aim = 1.995},
    [`weapon_minismg`] = {noAim = 1.15, aim = 0.985},
    [`weapon_pistol`] = {noAim = 1.15, aim = 1.785},
    [`weapon_pistol50`] = {noAim = 3.15, aim = 2.800},
    [`weapon_pistol_mk2`] = {noAim = 1.15, aim = 1.785},
    [`weapon_smg`] = {noAim = 1.15, aim = 1.285},
    [`weapon_smg_mk2`] = {noAim = 1.15, aim = 1.285},
    [`weapon_specialcarbine`] = {noAim = 5.15, aim = 4.085},
    [`weapon_sp45`] = {noAim = 3.15, aim = 1.785},
    [`weapon_usp45`] = {noAim = 3.15, aim = 1.785},
    [`weapon_vintagepistol`] = {noAim = 3.15, aim = 1.785},
    [`weapon_mk18`] = {noAim = 1.15, aim = 0.785},
}

local IsPedShooting = IsPedShooting
local GetSelectedPedWeapon = GetSelectedPedWeapon
local GetGameplayCamRelativePitch = GetGameplayCamRelativePitch
local IsControlPressed = IsControlPressed
local IsPedDoingDriveby = IsPedDoingDriveby
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetGameplayCamRelativeHeading = GetGameplayCamRelativeHeading
local SetGameplayCamRelativeHeading = SetGameplayCamRelativeHeading
local SetGameplayCamRelativePitch = SetGameplayCamRelativePitch


Recoil:RegisterMode('pma', function()
    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    local weprecoil = recoilTable[currentWeapon]
    
    if IsPedShooting(ped) then
        local regularRecoil = weprecoil and weprecoil.noAim or 0.6
        local recoilAiming = weprecoil and weprecoil.aim or 0.25
        local recoilVehicle = -1.0
        
        local recoil = GetGameplayCamRelativePitch()
        local isShooting = IsControlPressed(0, 25)
        local doingDriveby = IsPedDoingDriveby(ped)
        local inVehicle = IsPedInAnyVehicle(ped, true)
    
        if inVehicle then
            recoil = GetGameplayCamRelativeHeading()
        end
    
        if isShooting and not doingDriveby then
            recoil = recoil + recoilAiming
        elseif not doingDriveby then
            recoil = recoil + regularRecoil
        else
            recoil = recoil + recoilVehicle
        end
    
        if inVehicle then
            SetGameplayCamRelativeHeading(recoil);
        else
            SetGameplayCamRelativePitch(recoil, 1.0)
        end
    end
end)