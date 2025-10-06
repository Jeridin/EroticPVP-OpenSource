local hsmultiEnabled = false

--[[
  True: headshots enabled
  False: headshots disabled
]]

function SetHsMulti(state)
    hsmultiEnabled = state == true
end

function GetHsMulti()
  return hsmultiEnabled
end

exports("setHsMulti", SetHsMulti)
exports("getHsMulti", GetHsMulti)

local wait = Wait
local set_ped_suffers_critical_hits = SetPedSuffersCriticalHits
CreateThread(function()
  while true do
      wait(250)
      set_ped_suffers_critical_hits(PlayerPedId(), hsmultiEnabled)
  end
end)
