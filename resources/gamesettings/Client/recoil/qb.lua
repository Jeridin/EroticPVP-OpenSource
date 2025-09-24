local recoils = {
    -- Handguns
    [453432689] = 0.3, [-1075685676] = 0.5, [1593441988] = 0.2, [584646201] = 0.3,
    [911657153] = 0.1, [-1716589765] = 0.6, [-1076751822] = 0.2, [-771403250] = 0.5,
    [137902532] = 0.4, [1198879012] = 0.9, [-598887786] = 0.9, [-1045183535] = 0.6,
    [-879347409] = 0.6, [-1746263880] = 0.3, [-2009644972] = 0.3, [-1355376991] = 0.3,
    [727643628] = 0.3, [-1853920116] = 0.3, [1470379660] = 0.3,

    -- Submachine Guns
    [324215364] = 0.5, [736523883] = 0.4, [2024373456] = 0.1, [-270015777] = 0.1,
    [171789620] = 0.2, [-619010992] = 0.3, [-1121678507] = 0.1, [1198256469] = 0.3,

    -- Shotguns
    [487013001] = 0.4, [2017895192] = 0.7, [-494615257] = 0.4, [-1654528753] = 0.2,
    [-1466123874] = 0.7, [984333226] = 0.2, [-275439685] = 0.7, [317205821] = 0.2,
    [1432025498] = 0.4, [94989220] = 0.0,

    -- Assault Rifles
    [`WEAPON_AK47`] = 0.5, [961495388] = 0.2, [-2084633992] = 0.3, [-86904375] = 0.1,
    [`weapon_762`] = 0.1, [-1357824103] = 0.1, [-1063057011] = 0.2, [2132975508] = 0.2,
    [1649403952] = 0.3, [-1768145561] = 0.2, [-2066285827] = 0.2, [-1658906650] = 0.0,

    -- Light Machine Guns
    [-1660422300] = 0.1, [2144741730] = 0.1, [1627465347] = 0.1, [-608341376] = 0.1,

    -- Sniper Rifles
    [100416529] = 0.5, [205991906] = 0.7, [-952879014] = 0.3, [856002082] = 1.2,
    [177293209] = 0.6, [1785463520] = 0.3,

    -- Heavy Weapons
    [-1312131151] = 0.0, [-1568386805] = 1.0, [1305664598] = 1.0, [1119849093] = 0.1,
    [2138347493] = 0.3, [1834241177] = 2.4, [1672152130] = 0.0, [125959754] = 0.5,
    [-1238556825] = 0.3,

    -- Custom Weapons
    -- Pistols
    [`weapon_m1911`] = 0.3, [`weapon_m9`] = 0.2, [`weapon_m45a1`] = 0.3,
    [`WEAPON_GLOCK17`] = 0.3, [`weapon_browning`] = 0.3, [`makarov`] = 0.2,

    -- Assault Rifles
    [`weapon_mpx`] = 0.4, [`weapon_scar`] = 0.5, [`weapon_ak74`] = 0.3,
    [`weapon_tacticalrifle`] = 0.2, [`weapon_mk47fm`] = 0.5, [`weapon_m4`] = 0.2,

    -- Submachine Guns
    [`weapon_miniuzi`] = 0.5, [`weapon_minismg2`] = 0.5, [`weapon_microsmg2`] = 0.5,

    -- Shotguns
    [`weapon_combatshotgun`] = 0.4
}

local wait = Wait
local GetCurrentPedWeapon = GetCurrentPedWeapon
local GetGameplayCamRelativePitch = GetGameplayCamRelativePitch
local SetGameplayCamRelativePitch = SetGameplayCamRelativePitch
local GetFollowPedCamViewMode = GetFollowPedCamViewMode
local IsPedShooting = IsPedShooting
local IsPedDoingDriveby = IsPedDoingDriveby

Recoil:RegisterMode('qb', function(self)
    local ped = PlayerPedId()
    if IsPedShooting(ped) and not IsPedDoingDriveby(ped) then
        local _, wep = GetCurrentPedWeapon(ped)
        local recoil = recoils[wep]

        if recoil and recoil ~= 0 then
            local timeValue = 0
            local followCamMode = GetFollowPedCamViewMode()

            repeat
                wait(0)
                local pitch = GetGameplayCamRelativePitch()

                if followCamMode ~= 4 then
                    SetGameplayCamRelativePitch(pitch + 0.1, 0.2)
                    timeValue = timeValue + 0.1
                else
                    if recoil > 0.1 then
                        SetGameplayCamRelativePitch(pitch + 0.6, 1.2)
                        timeValue = timeValue + 0.6
                    else
                        SetGameplayCamRelativePitch(pitch + 0.016, 0.333)
                        timeValue = timeValue + 0.1
                    end
                end
            until (timeValue >= recoil) or (self.activeMode ~= 'qb')
        end
    end
end)
