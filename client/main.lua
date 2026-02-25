local QBCore = exports['qb-core']:GetCoreObject()
local activeBoxes = {}
local carryingBox = false
local boxObject = nil

-- Initialize blips
CreateThread(function()
    -- Job Start Blip
    if Config.JobStart.blip.enabled then
        local blip = AddBlipForCoord(Config.JobStart.coords.x, Config.JobStart.coords.y, Config.JobStart.coords.z)
        SetBlipSprite(blip, Config.JobStart.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.JobStart.blip.scale)
        SetBlipColour(blip, Config.JobStart.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.JobStart.blip.label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- Drop Off Blip
    if Config.DropOff.blip.enabled then
        local blip = AddBlipForCoord(Config.DropOff.coords.x, Config.DropOff.coords.y, Config.DropOff.coords.z)
        SetBlipSprite(blip, Config.DropOff.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.DropOff.blip.scale)
        SetBlipColour(blip, Config.DropOff.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.DropOff.blip.label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- Trading Blip
    if Config.TradingLocation.blip.enabled then
        local blip = AddBlipForCoord(Config.TradingLocation.coords.x, Config.TradingLocation.coords.y, Config.TradingLocation.coords.z)
        SetBlipSprite(blip, Config.TradingLocation.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.TradingLocation.blip.scale)
        SetBlipColour(blip, Config.TradingLocation.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.TradingLocation.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Spawn Peds
CreateThread(function()
    -- Job Start Ped
    local startPed = CreatePed(4, GetHashKey(Config.JobStart.ped), Config.JobStart.coords.x, Config.JobStart.coords.y, Config.JobStart.coords.z - 1.0, Config.JobStart.heading, false, true)
    SetEntityAsMissionEntity(startPed, true, true)
    SetPedFleeAttributes(startPed, 0, 0)
    SetPedDiesWhenInjured(startPed, false)
    TaskStartScenarioInPlace(startPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetEntityInvincible(startPed, true)
    FreezeEntityPosition(startPed, true)
    SetBlockingOfNonTemporaryEvents(startPed, true)
    
    -- Trading Ped
    local tradePed = CreatePed(4, GetHashKey(Config.TradingLocation.ped), Config.TradingLocation.coords.x, Config.TradingLocation.coords.y, Config.TradingLocation.coords.z - 1.0, Config.TradingLocation.heading, false, true)
    SetEntityAsMissionEntity(tradePed, true, true)
    SetPedFleeAttributes(tradePed, 0, 0)
    SetPedDiesWhenInjured(tradePed, false)
    TaskStartScenarioInPlace(tradePed, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    SetEntityInvincible(tradePed, true)
    FreezeEntityPosition(tradePed, true)
    SetBlockingOfNonTemporaryEvents(tradePed, true)
end)

-- Spawn boxes at random locations
local function SpawnBoxes()
    for i = 1, Config.MaxActiveBoxes do
        local location = Config.BoxLocations[math.random(1, #Config.BoxLocations)]
        local box = CreateObject(GetHashKey(Config.BoxModel), location.x, location.y, location.z, true, true, true)
        PlaceObjectOnGroundProperly(box)
        FreezeEntityPosition(box, true)
        
        -- Create blip for box
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, Config.BoxBlip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.BoxBlip.scale)
        SetBlipColour(blip, Config.BoxBlip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.BoxBlip.label)
        EndTextCommandSetBlipName(blip)
        
        table.insert(activeBoxes, {object = box, coords = location, blip = blip})
    end
end

-- Pick up box
local function PickupBox(boxEntity)
    if carryingBox then return end
    
    carryingBox = true
    RequestAnimDict(Config.BoxCarryAnimation.dict)
    while not HasAnimDictLoaded(Config.BoxCarryAnimation.dict) do
        Wait(10)
    end
    
    TaskPlayAnim(PlayerPedId(), Config.BoxCarryAnimation.dict, Config.BoxCarryAnimation.anim, 8.0, 8.0, -1, Config.BoxCarryAnimation.flag, 0, false, false, false)
    
    boxObject = CreateObject(GetHashKey(Config.BoxModel), 0, 0, 0, true, true, true)
    AttachEntityToEntity(boxObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    
    -- Remove original box and its blip
    for i, box in ipairs(activeBoxes) do
        if box.object == boxEntity then
            DeleteObject(boxEntity)
            if box.blip then
                RemoveBlip(box.blip)
            end
            table.remove(activeBoxes, i)
            break
        end
    end
    
    QBCore.Functions.Notify('Take the box to the drop off point', 'primary')
end

-- Drop off box
local function DropOffBox()
    if not carryingBox then
        QBCore.Functions.Notify('You need to be carrying a box', 'error')
        return
    end
    
    carryingBox = false
    ClearPedTasks(PlayerPedId())
    
    if boxObject then
        DeleteObject(boxObject)
        boxObject = nil
    end
    
    TriggerServerEvent('recycle:server:dropOffBox')
    
    -- Respawn a new box with blip
    Wait(1000)
    local location = Config.BoxLocations[math.random(1, #Config.BoxLocations)]
    local box = CreateObject(GetHashKey(Config.BoxModel), location.x, location.y, location.z, true, true, true)
    PlaceObjectOnGroundProperly(box)
    FreezeEntityPosition(box, true)
    
    -- Create blip for new box
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, Config.BoxBlip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.BoxBlip.scale)
    SetBlipColour(blip, Config.BoxBlip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BoxBlip.label)
    EndTextCommandSetBlipName(blip)
    
    table.insert(activeBoxes, {object = box, coords = location, blip = blip})
end

-- Start Job
local function StartJob()
    if #activeBoxes > 0 then
        QBCore.Functions.Notify('You are already working', 'error')
        return
    end
    
    SpawnBoxes()
    QBCore.Functions.Notify('Collect boxes and bring them to the drop off point', 'success')
end

-- Stop Job
local function StopJob()
    if #activeBoxes == 0 then
        QBCore.Functions.Notify('You are not working', 'error')
        return
    end
    
    -- Clear all boxes and blips
    for _, box in ipairs(activeBoxes) do
        if DoesEntityExist(box.object) then
            DeleteObject(box.object)
        end
        if box.blip then
            RemoveBlip(box.blip)
        end
    end
    activeBoxes = {}
    
    -- Clear carrying state
    if carryingBox then
        carryingBox = false
        ClearPedTasks(PlayerPedId())
        if boxObject then
            DeleteObject(boxObject)
            boxObject = nil
        end
    end
    
    QBCore.Functions.Notify('You stopped working', 'primary')
end

-- Open Trading Menu
local function OpenTradingMenu()
    TriggerServerEvent('recycle:server:getTradingData')
end

-- Setup ox_target interactions
if Config.InteractionType == 'ox_target' then
    -- Job Start
    exports.ox_target:addBoxZone({
        coords = Config.JobStart.coords,
        size = vector3(2, 2, 2),
        rotation = Config.JobStart.heading,
        options = {
            {
                name = 'recycle_start',
                icon = 'fa-solid fa-recycle',
                label = 'Start Recycle Job',
                canInteract = function()
                    return #activeBoxes == 0
                end,
                onSelect = function()
                    StartJob()
                end
            },
            {
                name = 'recycle_stop',
                icon = 'fa-solid fa-stop',
                label = 'Stop Recycle Job',
                canInteract = function()
                    return #activeBoxes > 0
                end,
                onSelect = function()
                    StopJob()
                end
            }
        }
    })
    
    -- Drop Off
    exports.ox_target:addBoxZone({
        coords = Config.DropOff.coords,
        size = vector3(3, 3, 2),
        rotation = Config.DropOff.heading,
        options = {
            {
                name = 'recycle_dropoff',
                icon = 'fa-solid fa-box',
                label = 'Drop Off Box',
                canInteract = function()
                    return carryingBox
                end,
                onSelect = function()
                    DropOffBox()
                end
            }
        }
    })
    
    -- Trading
    exports.ox_target:addBoxZone({
        coords = Config.TradingLocation.coords,
        size = vector3(2, 2, 2),
        rotation = Config.TradingLocation.heading,
        options = {
            {
                name = 'recycle_trade',
                icon = 'fa-solid fa-exchange',
                label = 'Trade & Sell Materials',
                onSelect = function()
                    OpenTradingMenu()
                end
            }
        }
    })
    
    -- Boxes (global objects)
    exports.ox_target:addModel(Config.BoxModel, {
        {
            name = 'pickup_box',
            icon = 'fa-solid fa-hand',
            label = 'Pick Up Box',
            distance = 2.0,
            canInteract = function(entity)
                return not carryingBox
            end,
            onSelect = function(data)
                PickupBox(data.entity)
            end
        }
    })
end

-- Text UI interactions
if Config.InteractionType == 'textui' then
    -- Job Start/Stop
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - Config.JobStart.coords)
            
            if dist < 2.0 then
                sleep = 0
                if #activeBoxes == 0 then
                    lib.showTextUI('[E] Start Recycle Job')
                else
                    lib.showTextUI('[E] Stop Recycle Job')
                end
                
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    if #activeBoxes == 0 then
                        StartJob()
                    else
                        StopJob()
                    end
                end
            elseif dist < 3.0 then
                lib.hideTextUI()
            end
            
            Wait(sleep)
        end
    end)
    
    -- Drop Off
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - Config.DropOff.coords)
            
            if dist < 3.0 and carryingBox then
                sleep = 0
                lib.showTextUI('[E] Drop Off Box')
                
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    DropOffBox()
                end
            elseif dist < 4.0 then
                lib.hideTextUI()
            end
            
            Wait(sleep)
        end
    end)
    
    -- Trading
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - Config.TradingLocation.coords)
            
            if dist < 2.0 then
                sleep = 0
                lib.showTextUI('[E] Trade & Sell Materials')
                
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    OpenTradingMenu()
                end
            elseif dist < 3.0 then
                lib.hideTextUI()
            end
            
            Wait(sleep)
        end
    end)
    
    -- Boxes
    CreateThread(function()
        while true do
            local sleep = 1000
            
            if not carryingBox and #activeBoxes > 0 then
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                for _, box in ipairs(activeBoxes) do
                    local dist = #(playerCoords - box.coords)
                    
                    if dist < 2.0 then
                        sleep = 0
                        lib.showTextUI('[E] Pick Up Box')
                        
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            PickupBox(box.object)
                            break
                        end
                    end
                end
                
                if sleep == 1000 then
                    lib.hideTextUI()
                end
            end
            
            Wait(sleep)
        end
    end)
end

-- Receive trading data from server
RegisterNetEvent('recycle:client:receiveTradingData', function(data)
    NUI.Open(data)
end)

-- Trade complete callback
RegisterNetEvent('recycle:client:tradeComplete', function(data)
    NUI.SendMessage('tradeComplete', data)
end)

-- NUI Callbacks
RegisterNUICallback('tradeMaterials', function(data, cb)
    TriggerServerEvent('recycle:server:tradeMaterials', data.amount)
    cb('ok')
end)

RegisterNUICallback('sellResource', function(data, cb)
    TriggerServerEvent('recycle:server:sellResource', data.itemName, data.amount)
    cb('ok')
end)
