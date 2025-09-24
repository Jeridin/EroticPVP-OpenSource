Recoil = {
    modes = {},
    activeMode = false
}

function Recoil:SetMode(mode)
    if type(mode) == "string" and mode:lower() == "disabled" then mode = false end
    assert(not mode or self.modes[mode], 'Mode ' .. tostring(mode) .. ' is not registered')
    self.activeMode = mode
    --[[]
    if (GetConvarInt('debugger_recoil', 0) == 1) then
        TriggerEvent("arena:postNotify", "Set recoil to mode '" .. tostring(mode) .. "'.", Config.UI.successColour)
    end]]
    
    for k, v in pairs(self.onResetCallbacks) do
        v(mode)
    end
end

exports("setRecoilMode", function(mode)
    Recoil:SetMode(mode)
end)

function Recoil:RegisterMode(modeName, onTickCallback)
    assert(not self.modes[modeName], 'Mode ' .. tostring(modeName) .. ' is already registered')
    self.modes[modeName] = {
        callback = onTickCallback
    }
end

---comment
---@param includeDisabled true to include the "disabled" mode at the start of the list
---@return string[]
function Recoil:GetModes(includeDisabled)
    local modes = {}
    if includeDisabled then
        modes[1] = "DISABLED"
    end
    for modeName, _ in pairs(self.modes) do
        table.insert(modes, modeName)
    end
    return modes
end

function Recoil:OnModeChange(cb)
    if not self.onResetCallbacks then
        self.onResetCallbacks = {}
    end
    table.insert(self.onResetCallbacks, cb)
end

local wait = Wait
CreateThread(function()
    while true do
        wait(1)
        if Recoil.activeMode and Recoil.modes[Recoil.activeMode] then
            Recoil.modes[Recoil.activeMode]:callback(Recoil.activeMode)
        end
    end
end)

local recoilModes = {
    DISABLED = {
        commands = {
            "DISABLED",
        }
    },
    nonstop = {
        commands = {
            "nonstop",
        }
    },
    hardcore = {
        commands = {
            "hardcore",
        }
    },
    qb = {
        commands = {
            "qb",
        }
    },
    pma = {
        commands = {
            "pma",
        }
    },
    roleplay = {
        commands = {
            "roleplay",
        }
    },
    roleplay2 = {
        commands = {
            "roleplay2",
        }
    },
    roleplay3 = {
        commands = {
            "roleplay3",
        }
    },
    envy = {
        commands = {
            "envy",
        }
    },
}

-- RegisterCommand("recoil", function(source, args, rawCommand)
--     local player = source
    
--     if #args < 1 then
--         return
--     end
    
--     local mode = args[1]:lower()
    
--     if not recoilModes[mode] then
--         local modesList = table.concat(table.keys(recoilModes), ", ")
--         return
--     end
    
--     Recoil:SetMode(mode)
--     print("^2Requested mode: " .. mode)
    
--     local commands = recoilModes[mode].commands
    
--     for _, command in ipairs(commands) do
        
--     end
-- end)

function SetRecoilMode(player, mode)
    mode = mode:lower()
    
    if not recoilModes[mode] then
        local modesList = table.concat(table.keys(recoilModes), ", ")
        --print("^1Invalid mode. Available modes: " .. modesList)
        return
    end
    
    Recoil:SetMode(mode)
    --print("^2Recoil set: " .. mode)
end

RegisterNetEvent('settings:ChangeRecoilMode')
AddEventHandler('settings:ChangeRecoilMode', function(mode)
    local player = source
    SetRecoilMode(player, mode)
end)

exports('SetRecoilMode', function(mode)
    local player = source
    SetRecoilMode(player, mode)
end)

table.keys = function(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end
