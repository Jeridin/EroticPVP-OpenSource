local noRecoil = {
    [`WEAPON_COMBATMG`] = true,
    [`WEAPON_ASSAULTRIFLE_MK2`] = true,
    [`WEAPON_COMBATMG_MK2`] = true,
    [`WEAPON_SPECIALCARBINE`] = true,
    [`WEAPON_BULLPUPRIFLE_MK2`] = true,
    [`WEAPON_MICROSMG2`] = true,
    [`WEAPON_COMPACTRIFLE`] = true,
    [`WEAPON_GEPARD`] = true,
    [`WEAPON_MARKSMANRIFLE_MK2`] = true,
    [`WEAPON_ADVANCEDRIFLE`] = true,
    [`WEAPON_DRAGUNOV`] = true,
    [`WEAPON_GLOCK18C`] = true,
    [`WEAPON_MK47FM`] = true,
    [`WEAPON_AK74`] = true,
    [`WEAPON_MPX`] = true
}

Recoil:RegisterMode('roleplay3', function()
    local ply = PlayerPedId()
    if IsPedShooting(ply) then
        local weapon = GetSelectedPedWeapon(ply)
        if not noRecoil[weapon] then
            local GamePlayCam = IsPedInAnyVehicle(ply, false) and GetFollowVehicleCamViewMode() or GetFollowPedCamViewMode()
            local MovementSpeed = math.min(math.ceil(GetEntitySpeed(ply)), 69)
            local group = GetWeapontypeGroup(weapon)
            local p = GetGameplayCamRelativePitch()
            local cameraDistance = #(GetGameplayCamCoord() - GetEntityCoords(ply))
            local recoil = math.random(130, 140 + (math.ceil(MovementSpeed * 0.5))) / 100
            local rifle = group == 970310034 or group == 1159398588

            cameraDistance = (cameraDistance < 5.3 and 1.5) or (cameraDistance < 8.0 and 2.0) or 3.0

            if IsPedInAnyVehicle(ply, false) then
                recoil = recoil + (recoil * cameraDistance)
            else
                recoil = recoil * 0.8
            end

            if GamePlayCam == 4 then
                recoil = (rifle and recoil * 0.1) or recoil * 0.5
            elseif rifle then
                recoil = recoil * 0.1
            end

            local rightleft = math.random(4)
            local h = GetGameplayCamRelativeHeading()
            local hf = math.random(10, 40 + MovementSpeed) / 100
            hf = IsPedInAnyVehicle(ply, false) and hf * 2.0 or hf

            SetGameplayCamRelativeHeading(h + (rightleft == 1 and hf or -hf))
            SetGameplayCamRelativePitch(p + recoil, 0.8)
        end
    end
end)
