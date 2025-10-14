local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('fortune_teller:server:giveReward', function(reward)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(reward) ~= 'table' then return end

    
    if reward.money and type(reward.money) == 'number' and reward.money > 0 then
        Player.Functions.AddMoney('cash', reward.money)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Fortune Teller',
            description = ('You receive $%s'):format(reward.money),
            type = 'success'
        })
    end

    
    if reward.item and type(reward.item) == 'string' then
        local amount = reward.amount or 1
        local success = Player.Functions.AddItem(reward.item, amount)
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Fortune Teller',
                description = ('You received %sx %s'):format(amount, reward.item),
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Fortune Teller',
                description = ('Your inventory is full — the spirits kept your gift.'),
                type = 'error'
            })
        end
    end

   
    if reward.xp and type(reward.xp) == 'number' then
       
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Fortune Teller',
            description = ('You feel wiser (+%s XP)'):format(reward.xp),
            type = 'inform'
        })
    end
end)
