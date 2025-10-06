HUD = {
  isOpen = true,
  isPlayerHudVisible = false,
  isInventoryVisible = false,
  isCrosshairVisible = false,
  isTaskbarVisible = false,
  isLobbyPageVisible = false,

  ToggleNui = function(self, open)
    self.isOpen = open
    SendNUIMessage({ action = 'setVisible', data = open })
  end,

  TogglePlayerHud = function(self, visible)
    self.isPlayerHudVisible = visible
    SendNUIMessage({ action = 'showPlayerHud', data = visible })
  end,

  -- ToggleInventory = function(self, visible)
  --   self.isInventoryVisible = visible
  --   SendNUIMessage({ action = 'showInventory', data = visible })
  --   INVENTORY:sendUpdatedSlotsToNUI()
  -- end,

  ToggleCrosshair = function(self, visible)
    self.isCrosshairVisible = visible
    SendNUIMessage({ action = 'showCrosshair', data = visible })
  end,

  ToggleTaskbar = function(self, visible)
    self.isTaskbarVisible = visible
    SendNUIMessage({ action = 'showTaskbar', data = visible })
  end,

  ToggleLobbypage = function(self, visible)
    self.isLobbyPageVisible = visible
    SendNUIMessage({ action = 'showLobbyPage', data = visible })
    SetNuiFocus(visible, visible)
    SendReactMessage('setVisible', visible)
  end,
}

-- Export: Toggle main NUI visibility
exports('ToggleNui', function(open)
  HUD.isOpen = open
  SendNUIMessage({ action = 'setVisible', data = open })
end)

-- Export: Toggle Player HUD
exports('TogglePlayerHud', function(visible)
  local currentState = not HUD.isPlayerHudVisible
  HUD:TogglePlayerHud(currentState)
end)

-- Export: Toggle Inventory
-- exports('ToggleInventory', function(visible)
--   HUD.isInventoryVisible = visible
--   SendNUIMessage({ action = 'showInventory', data = visible })
--   INVENTORY:sendUpdatedSlotsToNUI()
-- end)

-- Export: Toggle Crosshair
exports('ToggleCrosshair', function(visible)
  HUD.isCrosshairVisible = visible
  SendNUIMessage({ action = 'showCrosshair', data = visible })
end)

-- Export: Toggle Taskbar
exports('ToggleTaskbar', function(visible)
  local currentState = not HUD.isTaskbarVisible
  HUD:ToggleTaskbar(currentState)
end)

exports('ToggleLobbyPage', function(currentState)
  local currentState = not HUD.isLobbyPageVisible
  HUD:ToggleLobbypage(currentState)

  if currentState then
    TriggerEvent('erotic-core:lobbyOpened')
  end
end)

RegisterCommand('hud', function()
  HUD:ToggleNui(not HUD.isOpen)
end)

RegisterCommand('playerhud', function()
  local currentState = not HUD.isPlayerHudVisible
  HUD:TogglePlayerHud(currentState)
end)

RegisterCommand('inventory', function()
  local currentState = not HUD.isInventoryVisible
  HUD:ToggleInventory(currentState)
end)

RegisterCommand('crosshair', function()
  local currentState = not HUD.isCrosshairVisible
  HUD:ToggleCrosshair(currentState)
end)

RegisterCommand('LobbyPage', function()
  local currentState = not HUD.isLobbyPageVisible
  HUD:ToggleLobbypage(currentState)
  TriggerEvent('erotic-core:lobbyOpened')
end)

RegisterCommand('taskbar', function()
  local currentState = not HUD.isTaskbarVisible
  HUD:ToggleTaskbar(currentState)
end)

-- RegisterNetEvent('Erotic:LoadUser')
-- AddEventHandler('Erotic:LoadUser', function()
--   HUD:ToggleNui(true)

--   Citizen.Wait(1)
--   HUD:TogglePlayerHud(true)
--   HUD:ToggleInventory(true)
--   -- HUD:ToggleCrosshair(true)
--   -- HUD:ToggleTaskbar(true)
-- end)
