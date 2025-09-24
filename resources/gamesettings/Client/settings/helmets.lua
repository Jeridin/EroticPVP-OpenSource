local helmetsEnabled = false

--[[
  True: bullet proof  helmets enabled
  False: bullet proof helmets disabled
]]

function SetHelmetsEnabled(state)
  helmetsEnabled = state == true
end

function GetHelmetsEnabled()
  return helmetsEnabled
end

exports("setHelmetsEnabled", SetHelmetsEnabled)
exports("getHelmetsEnabled", GetHelmetsEnabled)

local wait = Wait
local set_ped_config_flag = SetPedConfigFlag
CreateThread(function()
  while true do
    wait(1000)
    set_ped_config_flag(PlayerPedId(), 149, not helmetsEnabled)
    set_ped_config_flag(PlayerPedId(), 438, not helmetsEnabled)
  end
end)
