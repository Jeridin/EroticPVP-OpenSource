local disabledladderClimbing = false
local disabledFirstPerson = false

local Wait = Wait
local CreateThread = CreateThread
local DisableFirstPersonCamThisFrame = DisableFirstPersonCamThisFrame
local SetPedConfigFlag = SetPedConfigFlag
local function disableFirstPerson()
    CreateThread(function()
        while disabledFirstPerson do
            DisableFirstPersonCamThisFrame()
            Wait()
        end
    end)
end

local function disableLadderClimbing()
    CreateThread(function()
        while disabledladderClimbing do
            Wait(250)
            SetPedConfigFlag(PlayerPedId(), 146, true)
        end
    end)
end

exports("disableFirstPerson", function(state)
    disabledFirstPerson = state
    disableFirstPerson()
end)

exports("disableLadderClimbing", function(state)
    SetPedConfigFlag(PlayerPedId(), 146, state)
    disabledladderClimbing = state
    disableLadderClimbing()
end)

exports("disableQPeeking", function(state)
    SetPlayerCanUseCover(PlayerId(), not state)
end)