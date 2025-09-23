-- Carbine Rifle Mk2 hash
local weaponHash = `WEAPON_CARBINERIFLE_MK2`

-- give weapon function
local function giveWeapon()
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, weaponHash, 250, false, true) -- 250 ammo, equipped
    print("[give-weapon] You have been given a Carbine Rifle Mk2.")
end

-- command: /carbine
RegisterCommand("gun", function()
    giveWeapon()
end, false)