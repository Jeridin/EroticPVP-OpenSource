PLAYERHUD = {
    StatusThread = function(self)
        while true do
          Wait(250)
    
          local armed = GetSelectedPedWeapon(PlayerPedId()) or false
          local hasWeapon = armed ~= `WEAPON_UNARMED`
    
          SendReactMessage('setStatusData', {
              health = GetEntityHealth(PlayerPedId()) - 100,
              armor = GetPedArmour(PlayerPedId()),
          })
        end
    end,
    
    CashHud = function()
        while true do
            Citizen.Wait(0)
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
            HideHudComponentThisFrame(13)
        end
    end,
    
    IdleCam = function()
        while true do
            Wait(250)
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
        end
    end,

    MovingHud = false,

    MoveHud = function(self, state)
    
        local newState = state or not self.MovingHud
    
        SetNuiFocus(newState, newState)
        SendReactMessage('setMovingHud', newState)
    
        self.MovingHud = newState
    
        if not newState then
            -- QBCore.Functions.Notify("HUD location saved!", "success")
          return 
        end
    
        -- QBCore.Functions.Notify("Drag around the HUD to move it, hit ESC to save and confirm. Use /resethud to move the HUD back to default position")
    
    end,
}

RegisterNUICallback('stopMovingHud', function(_, cb)
    PLAYERHUD:MoveHud(false)
    cb('ok')
end)
  
CreateThread(function()
    Wait(500)
    PLAYERHUD:StatusThread()
end)

CreateThread(function()
    Wait(15000)
    PLAYERHUD:IdleCam()
end)

CreateThread(function()
    Wait(250)
    PLAYERHUD:CashHud()
end)

RegisterCommand("movehud", function(source, args, rawCommand) 
    PLAYERHUD:MoveHud(args[1])
end, false)
  
RegisterCommand("resethud", function(source, args, rawCommand) 
    SendReactMessage('setHudPosition', { x = 0, y = 0 })
end, false)
  
TriggerEvent('chat:addSuggestion', '/togglehud', 'Toggle the health and driving HUD.')