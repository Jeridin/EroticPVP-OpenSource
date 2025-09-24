local whitelistedVehicles = {"revolter", "sheava", "issi7", "cyclone", "shotaro", "toros", "omnisegt", "paragon",
                             "sultanrs", "neon", "streiter", "raiden", "tulip", "buffalo", "buffalo1", "buffalo2",
                             "buffalo3", "seven70", "massacro", "guardian", "vigero2", "coquette4", "jester", "jester3",
                             "jester4", "penumbra2", "schlagen", "italigto", "comet2", "comet6", "pariah", "nero2",
                             "specter2", "tempesta", "elegy", "sultan2", "banshee2", "cliffhanger", "bati", "sanchez",
                             "manchez", "bf400", "powersurge"}

                             
local spawnedCar
local spawningcars = true
local safezoneCheck = false
local inSafezone = true
local safezoneEnterCheck = nil
local safezoneExitCheck = nil
local function addSafezoneChecks()
    safezoneCheck = true
    safezoneEnterCheck = AddEventHandler("polyzone:enter", function(name)
        if name:find("safezone") then
            inSafezone = true
        end
    end)
    
    safezoneExitCheck = AddEventHandler("polyzone:exit", function(name)
        if name:find("safezone") then
            inSafezone = false
        end
    end)
end

local function removeSafezoneChecks()
    safezoneCheck = false
    if safezoneEnterCheck ~= nil then
        RemoveEventHandler(safezoneEnterCheck)
    end
    if safezoneExitCheck ~= nil then
        RemoveEventHandler(safezoneExitCheck)
    end
end

local pairs = pairs
local function IsVehicleWhitelisted(model)
    for _, name in pairs(whitelistedVehicles) do
        if model == GetHashKey(name) then
            return true
        end
    end
    return false
end

local function deleteVeh(vehicle)
    SetEntityAsMissionEntity(vehicle, false, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, false)
    SetEntityAsMissionEntity(vehicle, false, false)
    DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteVehicle(vehicle)
    end
end

local function deleteCurrentVehicle(playerPed)
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if DoesEntityExist(currentVehicle) then
        if GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
            deleteVeh(currentVehicle)
        else
            -- exports['drp-notifications']:SendAlert('error', 'You are not the driver.', 5000)
            return
        end
    end
end

local function deletePreviousVehicle(playerPed)
    if not DoesEntityExist(spawnedCar) then
        spawnedCar = false
        return
    end

    local shouldDelete = true
    for seatIndex = -1, 5 do
        local ped = GetPedInVehicleSeat(spawnedCar, seatIndex)
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            shouldDelete = false
        end
    end

    if shouldDelete then
        deleteVeh(spawnedCar)
    end
end

RegisterNetEvent("core:deletePreviousVehicle")
AddEventHandler("core:deletePreviousVehicle", function()
    deleteCurrentVehicle(PlayerPedId())
    deletePreviousVehicle(PlayerPedId())
end)

local createthread = CreateThread
local tonumber = tonumber
local get_hash_key = GetHashKey
local get_offset_from_entity_in_world_coords = GetOffsetFromEntityInWorldCoords
local table_unpack = table.unpack
local has_model_loaded = HasModelLoaded
local wait = Wait
local request_model = RequestModel
local create_vehicle = CreateVehicle
local get_entity_heading = GetEntityHeading
local does_entity_exist = DoesEntityExist
local set_ped_into_vehicle = SetPedIntoVehicle
local trigger_event = TriggerEvent
local get_vehicle_number_plate_text = GetVehicleNumberPlateText
local set_vehicle_engine_on = SetVehicleEngineOn
local set_vehicle_dirt_level = SetVehicleDirtLevel
local set_resource_kvp = SetResourceKvp
local get_resource_kvp_string = GetResourceKvpString
local tostring = tostring
local json_decode = json.decode
local json_encode = json.encode
local get_entity_model = GetEntityModel
RegisterNetEvent("drp:spawnvehicle")
AddEventHandler("drp:spawnvehicle", function(veh)
    -- local worldID = tonumber(exports['erotic-lobby']:getCurrentWorld())
    -- local trickLobby = worldID == 4
    if spawningcars or trickLobby and veh == "deluxo" then
        local vehiclehash = get_hash_key(veh)
        if not IsVehicleWhitelisted(vehiclehash) and not trickLobby then
            -- exports['drp-notifications']:SendAlert('error', 'This vehicle cannot be spawned.', 5000)
            return
        end

        if (safezoneCheck and not inSafezone) then
            -- exports['drp-notifications']:SendAlert('error', 'Vehicles cannot be spawned outside of safezone.', 5000)
            return
        end

        if IsPedInAnyVehicle(PlayerPedId(), true) then
            -- exports['drp-notifications']:SendAlert('error', 'You are already in a vehicle.', 5000)
            return
        end

        local x, y, z = table_unpack(get_offset_from_entity_in_world_coords(PlayerPedId(), 0.5, 0.0, 0.0))

        request_model(vehiclehash)

        createthread(function()
            local waiting = 0
            while not has_model_loaded(vehiclehash) do
                waiting = waiting + 100
                wait(100)
                if waiting > 5000 then
                    -- exports['drp-notifications']:SendAlert('error', 'Failed to spawn the vehicle.', 5000)
                    return
                end
            end

            deleteCurrentVehicle(PlayerPedId())

            deletePreviousVehicle(PlayerPedId())

            local car = create_vehicle(vehiclehash, x, y, z, get_entity_heading(PlayerPedId()), 1, 0)
            if does_entity_exist(car) then
                set_ped_into_vehicle(PlayerPedId(), car, -1)
                -- exports['drp-notifications']:SendAlert('inform', 'Vehicle spawned', 5000)
                trigger_event('keys:addNew', car, get_vehicle_number_plate_text(car))
                set_vehicle_engine_on(car, true, true, false)
                set_vehicle_dirt_level(car, 0.0)
                spawnedCar = car
                set_resource_kvp("last_vehicle", veh)

                createthread(function()
                    local savedMods = get_resource_kvp_string("vehicle_" .. tostring(vehiclehash) .. "_mods")
                    if savedMods then
                        local parsedMods = json_decode(savedMods)
                        if parsedMods then
                            exports["core"]:SetVehicleProperties(car, parsedMods)
                        end
                    end
                end)
            else
                -- exports['drp-notifications']:SendAlert('error', 'Failed to spawn the vehicle.', 5000)
            end
        end)
    else
        -- exports['drp-notifications']:SendAlert('error', 'Spawning cars is disabled in this lobby.', 5000)
    end
end)

AddEventHandler("drp:saveVehicleModsBennys", function(veh)
    if not does_entity_exist(veh) then return end
    local mods = exports['core']:GetVehicleProperties(veh)
    set_resource_kvp("vehicle_" .. tostring(get_entity_model(veh)) .. "_mods", json_encode(mods))
end)

RegisterCommand("previous_vehicle", function()
    TriggerEvent("drp:spawnvehicle", get_resource_kvp_string('last_vehicle') or "revolter")
end)

RegisterKeyMapping("previous_vehicle", "Spawn your last spawned vehicle", "KEYBOARD", "F3")

RegisterCommand("dv", function()
    if exports["core"]:inSafeZone() then
        deleteCurrentVehicle(PlayerPedId())
    end
end)
RegisterKeyMapping("dv", "Delete current vehicle", "KEYBOARD", "K")

exports("deletePreviousVehicle", deletePreviousVehicle)

exports("spawningcars", function(state, sfCheck)
    spawningcars = state
    if sfCheck then
        addSafezoneChecks()
    else
        removeSafezoneChecks()
    end
end)
