local taskStatus = {
    active = false,
    id = 0,
    status = 0
  }
  
  function closeGuiFail()
    taskStatus.status = 2
  end
  
  function closeGui()
    taskStatus.status = 2
  end
  
  exports('closeGui', closeGui)
  exports('closeGuiFail', closeGuiFail)
  
  RegisterNUICallback('finished', function(data, cb)
    taskStatus.status = 3
    cb("Thank you!")
  end)
  
  local function updateStatus(type)
    CreateThread(function()
      SendReactMessage("updateStatus", type)
      Wait(100)
      SendReactMessage("updateStatus", "normal")
      SendReactMessage("showTaskbar", false)
    end)
  end
  
  exports('updateStatus', updateStatus)
  
  local function resetTaskStatus(statusType, plyPed, dict, anim, scenario)
    taskStatus = { active = false, id = 0, status = 0 }
    updateStatus(statusType)
    if anim ~= "" then
      StopAnimTask(plyPed, dict, anim, 2.0)
    end
    if scenario ~= "" then
      ClearPedTasks(plyPed)
    end
  end
  
  local function taskBar(data)
    local length, text, runcheck, deadcheck, ignoreclear, keepweapon, vehicle, distcheck, animation, desc, showTime, flopcheck, canShoot = data.length, data.text, data.runcheck, data.deadcheck, data.ignoreclear, data.keepweapon, data.vehicle, data.distcheck, data.animation, data.desc, data.showTime, data.flopcheck, data.canShoot
    local keepoutofvehicle = data.keepoutofvehicle
    local plyPed = PlayerPedId()
    local startPos = GetEntityCoords(plyPed)
    local dict, anim, scenario, stuck = "", "", "", false
  
    if deadcheck and IsEntityDead(plyPed) then
      return 0 -- Return 0% if the player is dead
    end
  
    if not keepweapon then
      Wait(500)
    end
  
    if animation and animation.dict then
      dict = animation.dict
      anim = animation.anim
      stuck = animation.stuck or false
      if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
          Citizen.Wait(0)
        end
      end
    elseif animation and animation.scenario then
      scenario = animation.scenario
      if not IsPedUsingScenario(plyPed, scenario) then
        ClearPedTasks(plyPed)
        TaskStartScenarioInPlace(plyPed, scenario, 0, true)
      end
    end
  
    if taskStatus.active then return 0 end
    taskStatus.active = true
    local id = taskStatus.id + 1
    taskStatus.id = id
    taskStatus.status = 1
  
    SendReactMessage("updateError", false)
    SendReactMessage("showTaskbar", true)
  
    SendReactMessage("updateWidth", 0)
    SendReactMessage("showTime", true)
    SendReactMessage("updateTime", math.ceil(length / 100))
  
    local targetTimer = GetGameTimer() + length
    local targetWidth = 100
  
    while taskStatus.id == id and taskStatus.status == 1 do
      Wait(5)
  
      local currentTimer = GetGameTimer()
      if currentTimer > targetTimer then
        taskStatus.status = 3
      end
  
      local diff = length - (targetTimer - currentTimer)
      local width = math.ceil((diff / length) * 100)
      if width > targetWidth then
        width = targetWidth
      elseif width < 0 then
        width = 0
      end
  
      SendReactMessage("updateTime", math.ceil((targetTimer - currentTimer) / 100))
  
      SendReactMessage("updateText", text)
      SendReactMessage("updateWidth", width)
  
      local function checkAndReset(statusType)
        resetTaskStatus(statusType, plyPed, dict, anim, scenario)
        return width
      end

      AddEventHandler('baseevents:onPlayerDied', function()
        return checkAndReset("error")
      end)
  
      if runcheck and (IsPedClimbing(plyPed) or IsPedJumping(plyPed) or IsPedSwimming(plyPed)) then
        return checkAndReset("error")
      end
  
      if IsPedShooting(plyPed) and not canShoot then
        return checkAndReset("error")
      end
  
      if keepoutofvehicle and IsPedInAnyVehicle(plyPed, false) then
        return checkAndReset("error")
      end
  
      if deadcheck and IsEntityDead(plyPed) then
        return checkAndReset("error")
      end
  
      if vehicle and GetPedInVehicleSeat(vehicle, -1) ~= plyPed then
        return checkAndReset("error")
      end
  
      if distcheck and #(GetEntityCoords(plyPed) - startPos) > distcheck then
        return checkAndReset("error")
      end
  
      if flopcheck and IsPedRagdoll(plyPed) then
        return checkAndReset("error")
      end
  
      if IsControlJustReleased(0, 202) or IsControlJustReleased(0, 73) then
        return checkAndReset("error")
      end
  
      if anim ~= "" and not IsEntityPlayingAnim(plyPed, dict, anim, 3) then
        local flag = animation.flag or (stuck and 0 or 49)
        TaskPlayAnim(plyPed, dict, anim, 3.0, 1.0, -1, flag, 0, 0, 0, 0)
      end
  
      if scenario ~= "" and not IsPedUsingScenario(plyPed, scenario) then
        ClearPedTasks(plyPed)
        TaskStartScenarioInPlace(plyPed, scenario, 0, true)
      end
    end
  
    local res = taskStatus.status
    if res == 2 then
      local diff = length - GetGameTimer()
      local total = math.ceil((diff / length) * 100)
      resetTaskStatus("orange", plyPed, dict, anim, scenario)
      SendReactMessage("updateWidth", 0)
      return total
    else
      SendReactMessage("showTaskbar", false)
      resetTaskStatus("normal", plyPed, dict, anim, scenario)
      SendReactMessage("updateWidth", 0)
      return 100
    end
  end
  
  exports('taskBar', taskBar)
  
  function isTaskbarFree()
    return not taskStatus.active
  end
  
  exports('isTaskbarFree', isTaskbarFree)
