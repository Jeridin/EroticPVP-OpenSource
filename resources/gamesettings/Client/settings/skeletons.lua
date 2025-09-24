local skeletonsEnabled = false

local PlayerPed = PlayerPedId()
local GetPedBoneIndex = GetPedBoneIndex
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local vector2 = vector2
local boneindexes = {}
local function GetBonePosW2S(ped, boneIndex)
    if not boneindexes[boneIndex] then
        local newindex = GetPedBoneIndex(ped, boneIndex)
        boneindexes[boneIndex] = newindex
    end
    local boneindex = boneindexes[boneIndex]
    local bonepos = GetEntityBonePosition_2(ped, boneindex)
    local bool, screenX, screenY = GetScreenCoordFromWorldCoord(bonepos.x, bonepos.y, bonepos.z)
    return vector2(screenX, screenY)
end

local DrawLine_2d = DrawLine_2d
local function drawthing(firstbone, secondbone, width, r, g, b, a)
    if firstbone.x ~= -1.0 then
        if secondbone.x ~= -1.0 then
            DrawLine_2d(firstbone, secondbone, width, r, g, b, a)
        end
    end
end

local function DrawBones(ped, width, r, g, b, a)
    local rFoot = GetBonePosW2S(ped, 52301);
    local rCalf = GetBonePosW2S(ped, 36864);
    local rThigh = GetBonePosW2S(ped, 51826);

    local lFoot = GetBonePosW2S(ped, 14201);
    local lCalf = GetBonePosW2S(ped, 63931);
    local lThigh = GetBonePosW2S(ped, 58271);


    local pelvis = GetBonePosW2S(ped, 11816);
    local spineRoot = GetBonePosW2S(ped, 57597);
    local spine0 = GetBonePosW2S(ped, 23553);
    local spine1 = GetBonePosW2S(ped, 24816);
    local spine2 = GetBonePosW2S(ped, 24817);
    local spine3 = GetBonePosW2S(ped, 24818);

    local lClavicle = GetBonePosW2S(ped, 64729);
    local lUpperArm = GetBonePosW2S(ped, 45509);
    local lForearm = GetBonePosW2S(ped, 61163);
    local lHand = GetBonePosW2S(ped, 18905);

    local rClavicle = GetBonePosW2S(ped, 10706);
    local rUpperArm = GetBonePosW2S(ped, 40269);
    local rForearm = GetBonePosW2S(ped, 28252);
    local rHand = GetBonePosW2S(ped, 57005);

    local neck = GetBonePosW2S(ped, 39317);
    local head = GetBonePosW2S(ped, 39317);

    
    drawthing(rFoot, rCalf, width, r, g, b, a);
    drawthing(rCalf, rThigh, width, r, g, b, a);
    drawthing(rThigh, pelvis, width, r, g, b, a);

    drawthing(lFoot, lCalf, width, r, g, b, a);
    drawthing(lCalf, lThigh, width, r, g, b, a);
    drawthing(lThigh, pelvis, width, r, g, b, a);

    drawthing(pelvis, spineRoot, width, r, g, b, a);
    drawthing(spineRoot, spine0, width, r, g, b, a);
    drawthing(spine0, spine1, width, r, g, b, a);
    drawthing(spine1, spine2, width, r, g, b, a);
    drawthing(spine2, spine3, width, r, g, b, a);
    drawthing(spine3, neck, width, r, g, b, a);
    drawthing(neck, head, width, r, g, b, a);

    drawthing(lClavicle, lUpperArm, width, r, g, b, a);
    drawthing(lUpperArm, lForearm, width, r, g, b, a);
    drawthing(lForearm, lHand, width, r, g, b, a);

    drawthing(rClavicle, rUpperArm, width, r, g, b, a);
    drawthing(rUpperArm, rForearm, width, r, g, b, a);
    drawthing(rForearm, rHand, width, r, g, b, a);

    drawthing(rClavicle, neck, width, r, g, b, a);
    drawthing(lClavicle, neck, width, r, g, b, a);
end

local Wait = Wait
local PlayerPedId = PlayerPedId
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local function drawSkeletons()
    Wait(1000)
    CreateThread(function()
        while skeletonsEnabled do
            for _, id in pairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(id)
                DrawBones(targetPed, 0.0009, 144, 138, 255, 255.0)
            end
            Wait(1)
        end
    end)
end

exports("enableSkeletons", function(state)
    exports.core:enableESP(state)
    skeletonsEnabled = state
    drawSkeletons()
end)