local weaponsList = {
  ["WEAPON_VECTOR"] = 0.33300000429153,
  ["WEAPON_CARBINERIFLE"] = 0.33300000429153,
  ["WEAPON_M16"] = 0.33300000429153,
  ["WEAPON_USP45"] = 1.0,
  ["WEAPON_SP45"] = 1.0,
  ["WEAPON_AK47"] = 0.33300000429153,
  ["WEAPON_MINIUZI"] = 0.0,
  ["WEAPON_MPX"] = 0.33300000429153,
  ["WEAPON_PYTHON"] = 1.25,
  ["WEAPON_MARKSMANRIFLE_MK2"] = 0.28000000119209,
  ["WEAPON_PRECISIONRIFLE"] = 0.28000000119209,
  ["WEAPON_MAC10"] = 0.33300000429153,
  ["WEAPON_PISTOL50"] = 1.5,
  ["WEAPON_ADVANCEDRIFLE"] = 0.33300000429153,
  ["WEAPON_COMBATSHOTGUN"] = 1.75,
  ["WEAPON_SAWNOFFSHOTGUN"] = 2.25,
  ["WEAPON_APPISTOL"] = 0.5,
  ["WEAPON_BROWNING"] = 1.0,
  ["WEAPON_AUTOSHOTGUN"] = 0.66600000858307,
  ["WEAPON_HEAVYPISTOL"] = 1.0,
  ["WEAPON_AK74"] = 0.33300000429153,
  ["WEAPON_CARBINERIFLE_MK2"] = 0.33300000429153,
  ["makarov"] = 0.0,
  ["WEAPON_SCAR"] = 0.10000000149012,
  ["WEAPON_M45A1"] = 1.0,
  ["WEAPON_AK47"] = 0.33300000429153,
  ["WEAPON_SPECIALCARBINE"] = 0.33300000429153,
  ["WEAPON_MICROSMG2"] = 0.89999997615814,
  ["WEAPON_M70"] = 0.33300000429153,
  ["WEAPON_MARKSMANRIFLE"] = 0.28000000119209,
  ["WEAPON_HOMINGLAUNCHER"] = 1.0,
  ["WEAPON_MARKSMANPISTOL"] = 1.5,
  ["WEAPON_MINISMG"] = 0.75,
  ["WEAPON_MG"] = 1.0,
  ["WEAPON_MACHINEPISTOL"] = 0.5,
  ["WEAPON_MINISMG2"] = 0.75,
  ["WEAPON_VINTAGEPISTOL"] = 1.0,
  ["WEAPON_COMBATMG"] = 0.80000001192093,
  ["WEAPON_DBSHOTGUN"] = 1.5,
  ["WEAPON_COMBATPISTOL"] = 1.0,
  ["WEAPON_HEAVYSNIPER"] = 0.28000000119209,
  ["WEAPON_G17"] = 0.5,
  ["WEAPON_MK18"] = 0.33300000429153,
  ["WEAPON_762"] = 0.33300000429153,
  ["WEAPON_GLOCK"] = 1.0,
  ["WEAPON_HEAVYRIFLE"] = 0.33300000429153,
  ["WEAPON_COMPACTRIFLE"] = 0.40000000596046,
  ["WEAPON_TACTICALRIFLE"] = 0.33300000429153,
  ["WEAPON_PUMPSHOTGUN"] = 2.0,
}

local weaponRecoils = {
  [`WEAPON_PISTOL50`] = 6.2,
  [`WEAPON_M45A1`] = 6.2,
  [`WEAPON_BROWNING`] = 3.4,
  [`WEAPON_GLOCK`] = 3.4,
  [`MAKAROV`] = 3.4,
  [`WEAPON_PYTHON`] = 6.2
}

-- This is used to register new weapons
-- local registeredWeapons = exports.Inventory:GetAllWeapons()
-- CreateThread(function()
--   for weaponName, data in pairs(registeredWeapons) do
--     local recoil = GetWeaponRecoilShakeAmplitude(GetHashKey(weaponName))
--     weaponsList[weaponName] = {
--       recoil = recoil
--     }
--     print(weaponName, recoil)
--   end
-- end)


local function getAmplitudeScale(speed, bMin, bMax, tMin, tMax)
  return (((speed - bMin) * (tMax - tMin)) / (bMax - bMin)) + tMin
end

local SetWeaponRecoilShakeAmplitude = SetWeaponRecoilShakeAmplitude
local GetEntitySpeed = GetEntitySpeed
local IsPedInAnyVehicle = IsPedInAnyVehicle
local function setRecoilAmplitude(ped, weapon, modifier)
  local speed = GetEntitySpeed(ped) * 1.5
  SetWeaponRecoilShakeAmplitude(weapon,
    (IsPedInAnyVehicle(ped, false) and getAmplitudeScale(speed, 0.0, 150.0, 1.0, 8.0) or
      getAmplitudeScale(speed, 0.0, 18.0, 1.0, 6.0)) * modifier)
end

local GetSelectedPedWeapon = GetSelectedPedWeapon
local wait = Wait
local IsPedArmed = IsPedArmed
local get_hash_key = GetHashKey
Recoil:RegisterMode("hardcore", function()
  local PlayerPed = PlayerPedId()
  
    if IsPedArmed(PlayerPed, 6) then
        local weapon = GetSelectedPedWeapon(PlayerPed)
        setRecoilAmplitude(PlayerPed, weapon, weaponRecoils[weapon] or 3.0)
    else
        wait(250)
    end
end)

Recoil:OnModeChange(function()
  for weaponName, recoil in pairs(weaponsList) do
    SetWeaponRecoilShakeAmplitude(get_hash_key(weaponName), recoil)
  end
end)


AddEventHandler("onResourceStop", function()
  for weaponName, recoil in pairs(weaponsList) do
    SetWeaponRecoilShakeAmplitude(get_hash_key(weaponName), recoil)
  end
end)
