local RSGCore = exports['rsg-core']:GetCoreObject()
local fortuneTeller, candle
local fortuneActive = false


local lastReadingTime = 0
local COOLDOWN_DURATION = 300000 -- 5 minutes in ms


local lastErrorNotify = 0
local ERROR_NOTIFY_COOLDOWN = 10000 -- 10 seconds in ms


local function spawnFortuneTeller()
    if fortuneActive then return end

    local loc = Config.SpawnLocations[math.random(#Config.SpawnLocations)]
    local spawnCoords = loc.coords
    local model = GetHashKey(Config.FortuneTellerModel)
    RequestModel(model)
    local timeout = 5000
    local start = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - start) < timeout do Wait(100) end
    if not HasModelLoaded(model) then
        
        return
    end

    fortuneTeller = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z - 1.0, loc.heading, false, true)
    SetEntityInvincible(fortuneTeller, true)
    Citizen.InvokeNative(0x283978A15512B2FE, fortuneTeller, false)
    FreezeEntityPosition(fortuneTeller, true)
    SetBlockingOfNonTemporaryEvents(fortuneTeller, true)

    
    local candleModel = GetHashKey(Config.CandleModel)
    RequestModel(candleModel)
    start = GetGameTimer()
    while not HasModelLoaded(candleModel) and (GetGameTimer() - start) < timeout do Wait(100) end
    if not HasModelLoaded(candleModel) then
       
    else
        local candleCoords = vector3(spawnCoords.x + 0.5, spawnCoords.y + 0.2, spawnCoords.z)
        candle = CreateObject(candleModel, candleCoords.x, candleCoords.y, candleCoords.z, true, true, false)
        PlaceObjectOnGroundProperly(candle)
    end

   
    if GetResourceState('ox_target') ~= 'started' then
        
       
        CreateThread(function()
            while fortuneActive do
                local playerPed = PlayerPedId()
                local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(fortuneTeller))
                if dist < 2.0 and IsControlJustPressed(0, 0x27D1C284) then -- E key
                    openFortuneMenu()
                end
                Wait(0)
            end
        end)
        fortuneActive = true
        return
    end

    
    local targetLabel = 'Receive a Fortune Reading'
    exports.ox_target:addLocalEntity(fortuneTeller, {
        {
            name = 'fortune_teller_reading',
            icon = 'fa-solid fa-crystal-ball',
            distance = 2.0,
            label = targetLabel,
            canInteract = function()
                local timePassed = GetGameTimer() - lastReadingTime
                if timePassed < COOLDOWN_DURATION then
                    if GetGameTimer() - lastErrorNotify > ERROR_NOTIFY_COOLDOWN then
                        lib.notify({
                            title = 'John',
                            description = 'The spirits require time to realign. Wait ' .. math.ceil((COOLDOWN_DURATION - timePassed) / 60000) .. ' minutes.',
                            type = 'error'
                        })
                        lastErrorNotify = GetGameTimer()
                    end
                    return false
                end
                return true
            end,
            onSelect = function()
                openFortuneMenu()
            end
        }
    })

    

    fortuneActive = true
    lib.notify({
        title = 'The Fortune Teller',
        description = 'A traveling fortune teller has arrived in town...',
        type = 'inform'
    })
end


local function despawnFortuneTeller()
    if fortuneTeller then
        if GetResourceState('ox_target') == 'started' then
            pcall(function()
                exports.ox_target:removeLocalEntity(fortuneTeller)
            end)
        end
        DeletePed(fortuneTeller)
        fortuneTeller = nil
    end
    if candle then
        DeleteObject(candle)
        candle = nil
    end
    fortuneActive = false
end


function openFortuneMenu()
    local timeLeft = COOLDOWN_DURATION - (GetGameTimer() - lastReadingTime)
    local cooldownText = timeLeft > 0 and (' (Cooldown: ' .. math.ceil(timeLeft / 60000) .. ' min)' ) or ''
    
    lib.registerContext({
        id = 'fortune_menu',
        title = "Johns’s Reading" .. cooldownText,
        options = {
            { 
                title = 'Receive a Reading', 
                description = 'Cross her palm with silver...' .. cooldownText, 
                icon = 'fa-solid fa-crystal-ball', 
                event = 'fortune_teller:client:getReading',
                disabled = timeLeft > 0
            },
            { title = 'Leave', icon = 'x' }
        }
    })
    lib.showContext('fortune_menu')
end


RegisterNetEvent('fortune_teller:client:getReading', function()
    local timeLeft = COOLDOWN_DURATION - (GetGameTimer() - lastReadingTime)
    if timeLeft > 0 then
        if GetGameTimer() - lastErrorNotify > ERROR_NOTIFY_COOLDOWN then
            lib.notify({
                title = 'Baptist John',
                description = 'The spirits require time to realign. Wait ' .. math.ceil(timeLeft / 60000) .. ' minutes.',
                type = 'error'
            })
            lastErrorNotify = GetGameTimer()
        end
        return
    end

    lastReadingTime = GetGameTimer() -- Start cooldown

    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_WRITE_NOTEBOOK"), -1, true, false, false, false)
    lib.progressCircle({
        duration = 5000,
        label = 'Johgn studies the cards...',
        position = 'bottom',
        canCancel = false,
        disable = { move = true, car = true },
    })
    ClearPedTasksImmediately(PlayerPedId())

    local chosen = Config.Fortunes[math.random(#Config.Fortunes)]
    lib.notify({
        title = 'Baptist John',
        description = chosen.text,
        type = chosen.type == "bad" and 'error' or 'success'
    })

    if chosen.reward then
        TriggerServerEvent('fortune_teller:server:giveReward', chosen.reward)
    elseif chosen.curse then
        TriggerEvent('fortune_teller:client:applyCurse', chosen.curse)
    end
end)


RegisterNetEvent('fortune_teller:client:applyCurse', function(curse)
    local data = Config.Curses[curse]
    if not data then return end

    local ped = PlayerPedId()

    if curse == "slow" then
        SetRunSprintMultiplierForPlayer(PlayerId(), 0.7)
        lib.notify({ title = 'Curse', description = data.description, type = 'error' })
        Wait(data.duration)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        lib.notify({ title = 'Curse Lifted', description = data.lifted, type = 'inform' })

    elseif curse == "health_drain" then
        
        lib.notify({ title = 'Curse', description = data.description, type = 'error' })

        local draining = true
        CreateThread(function()
            while draining do
                local hp = GetEntityHealth(ped)
                if hp > 100 then
                    SetEntityHealth(ped, math.max(1, hp - math.floor(data.damage))) 
                end
                Wait(data.interval)
            end
            lib.notify({ title = 'Curse Lifted', description = data.lifted, type = 'inform' })
        end)

        Wait(data.duration)
        draining = false
    end
end)


Citizen.CreateThread(function()
    Wait(3000)
    spawnFortuneTeller()
    while true do
        Wait(Config.SpawnInterval * 60000)
        despawnFortuneTeller()
        Wait(5000)
        spawnFortuneTeller()
    end
end)


AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() == res then
        despawnFortuneTeller()
    end
end)
