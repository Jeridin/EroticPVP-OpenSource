local DisableSpeedBoosting = false

--[[
  True: headshots enabled
  False: headshots disabled
]]

function SetspeedBoostingOff(state)
    DisableSpeedBoosting = state == true
end

function GetspeedBoosting()
  return DisableSpeedBoosting
end

exports("setspeedBoostingOff", SetspeedBoostingOff)
exports("getspeedBoosting", GetspeedBoosting)

-- Disable "Speed boosting"
CreateThread(function()
    while true do
      Wait(0)
          Wait(500)
          if not IsPedInAnyVehicle(PlayerPedId(), false) then
            if IsPedUsingActionMode(PlayerPedId()) then
              SetPedUsingActionMode(PlayerPedId(), -1, -1, 1)
            end
          else
            Wait(3000)
        end
    end
  end)