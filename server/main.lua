local QBCore = exports['qb-core']:GetCoreObject()

-- Anti-exploit: Track last action times per player
local lastDropOff = {}
local lastTrade = {}
local lastSell = {}

-- Get player's total traded materials from metadata
local function GetPlayerStats(Player)
    local metadata = Player.PlayerData.metadata or {}
    return {
        totalTraded = metadata.recycleTraded or 0
    }
end

-- Update player's total traded materials in metadata
local function UpdatePlayerStats(Player, amount)
    local metadata = Player.PlayerData.metadata or {}
    metadata.recycleTraded = (metadata.recycleTraded or 0) + amount
    Player.Functions.SetMetaData('recycleTraded', metadata.recycleTraded)
end

-- Box Drop Off Handler
RegisterNetEvent('recycle:server:dropOffBox', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Anti-spam: Cooldown check (minimum 3 seconds between drops)
    local currentTime = os.time()
    if lastDropOff[src] and (currentTime - lastDropOff[src]) < 3 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to drop box too quickly')
        return
    end
    lastDropOff[src] = currentTime
    
    -- Distance check: Player must be near drop off location
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dropOffCoords = vector3(Config.DropOff.coords.x, Config.DropOff.coords.y, Config.DropOff.coords.z)
    local distance = #(playerCoords - dropOffCoords)
    
    if distance > 10.0 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to drop box from too far away: '..distance..'m')
        TriggerClientEvent('QBCore:Notify', src, 'You must be at the drop off location', 'error')
        return
    end
    
    -- Give random amount of materials (1-3 items)
    local amount = math.random(1, 3)
    local reward = Config.DropOff.reward
    
    Player.Functions.AddItem(reward, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward], 'add', amount)
    TriggerClientEvent('QBCore:Notify', src, 'You received '..amount..'x '..reward, 'success')
end)

-- Get Trading Data (balance and stats)
RegisterNetEvent('recycle:server:getTradingData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local materialItem = Player.Functions.GetItemByName('recyclablematerial')
    local balance = materialItem and materialItem.amount or 0
    
    local stats = GetPlayerStats(Player)
    
    -- Get sellable items from inventory
    local sellableItems = {}
    if Config.ResourceSelling.enabled then
        for itemName, price in pairs(Config.ResourceSelling.prices) do
            local item = Player.Functions.GetItemByName(itemName)
            if item and item.amount > 0 then
                table.insert(sellableItems, {
                    name = itemName,
                    label = item.label or itemName,
                    amount = item.amount,
                    price = price
                })
            end
        end
    end
    
    TriggerClientEvent('recycle:client:receiveTradingData', src, {
        balance = balance,
        totalTraded = stats.totalTraded,
        rewards = Config.Trading.rewards,
        scaling = Config.Trading.scalingBonus,
        sellableItems = sellableItems
    })
end)

-- Calculate drop chances based on amount with scaling
local function CalculateRewards(amount)
    -- Find scaling range
    local itemMin = 1
    local itemMax = 3
    local guaranteedMin = 1
    
    for _, scale in ipairs(Config.Trading.scalingBonus) do
        if amount >= scale.minAmount and amount <= scale.maxAmount then
            itemMin = scale.itemMin
            itemMax = scale.itemMax
            guaranteedMin = scale.guaranteedItems or 1
            break
        end
    end
    
    print('[RECYCLE] Trading '..amount..' materials - Item range: '..itemMin..'-'..itemMax..', Guaranteed min: '..guaranteedMin)
    
    local rewards = {}
    
    -- Roll for each possible reward
    for _, reward in ipairs(Config.Trading.rewards) do
        local roll = math.random(1, 100)
        
        -- Keep base chance, use scaled item amounts
        if roll <= reward.baseChance then
            local rewardAmount = math.random(itemMin, itemMax)
            
            print('[RECYCLE] '..reward.label..': chance='..reward.baseChance..'%, roll='..roll..' - WIN ('..rewardAmount..'x)')
            
            table.insert(rewards, {
                item = reward.item,
                label = reward.label,
                amount = rewardAmount,
                rarity = reward.rarity
            })
        else
            print('[RECYCLE] '..reward.label..': chance='..reward.baseChance..'%, roll='..roll..' - LOSE')
        end
    end
    
    -- Ensure minimum guaranteed items
    if #rewards < guaranteedMin then
        print('[RECYCLE] Only got '..#rewards..' items, need '..guaranteedMin..'. Adding random items...')
        
        -- Track which items we already have to avoid duplicates
        local existingItems = {}
        for _, reward in ipairs(rewards) do
            existingItems[reward.item] = true
        end
        
        -- Add random items until we reach the minimum
        local attempts = 0
        while #rewards < guaranteedMin and attempts < 50 do
            local randomReward = Config.Trading.rewards[math.random(1, #Config.Trading.rewards)]
            
            -- Only add if we don't already have this item
            if not existingItems[randomReward.item] then
                local rewardAmount = math.random(itemMin, itemMax)
                
                print('[RECYCLE] Guaranteed bonus: '..randomReward.label..' ('..rewardAmount..'x)')
                
                table.insert(rewards, {
                    item = randomReward.item,
                    label = randomReward.label,
                    amount = rewardAmount,
                    rarity = randomReward.rarity
                })
                
                existingItems[randomReward.item] = true
            end
            
            attempts = attempts + 1
        end
    end
    
    print('[RECYCLE] Total rewards received: '..#rewards)
    
    return rewards
end

-- Trade Materials
RegisterNetEvent('recycle:server:tradeMaterials', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Anti-spam: Cooldown check (minimum 1 second between trades)
    local currentTime = os.time()
    if lastTrade[src] and (currentTime - lastTrade[src]) < 1 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to trade too quickly')
        return
    end
    lastTrade[src] = currentTime
    
    -- Distance check: Player must be near trading location
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local tradeCoords = vector3(Config.TradingLocation.coords.x, Config.TradingLocation.coords.y, Config.TradingLocation.coords.z)
    local distance = #(playerCoords - tradeCoords)
    
    if distance > 10.0 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to trade from too far away: '..distance..'m')
        TriggerClientEvent('QBCore:Notify', src, 'You must be at the trading location', 'error')
        return
    end
    
    -- Validate amount is a number
    if type(amount) ~= 'number' then
        print('[RECYCLE EXPLOIT] Player '..src..' sent invalid amount type: '..type(amount))
        return
    end
    
    -- Sanitize amount (remove decimals)
    amount = math.floor(amount)
    
    -- Validate amount
    if amount < Config.Trading.minTradeAmount or amount > Config.Trading.maxTradeAmount then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid trade amount', 'error')
        return
    end
    
    -- Check if player has enough materials
    local materialItem = Player.Functions.GetItemByName('recyclablematerial')
    if not materialItem or materialItem.amount < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough recyclable materials', 'error')
        return
    end
    
    -- Remove materials
    Player.Functions.RemoveItem('recyclablematerial', amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['recyclablematerial'], 'remove', amount)
    
    -- Calculate rewards
    local rewards = CalculateRewards(amount)
    
    -- Give rewards
    for _, reward in ipairs(rewards) do
        Player.Functions.AddItem(reward.item, reward.amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item], 'add', reward.amount)
    end
    
    -- Update stats and save to metadata
    UpdatePlayerStats(Player, amount)
    local stats = GetPlayerStats(Player)
    
    -- Notify success
    TriggerClientEvent('QBCore:Notify', src, 'Trade successful! Received '..#rewards..' different items', 'success')
    
    -- Send updated data back to client
    TriggerClientEvent('recycle:client:tradeComplete', src, {
        rewards = rewards,
        totalTraded = stats.totalTraded,
        newBalance = materialItem.amount - amount
    })
end)

-- Sell Resources
RegisterNetEvent('recycle:server:sellResource', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Anti-spam: Cooldown check (minimum 0.5 second between sells)
    local currentTime = os.time()
    if lastSell[src] and (currentTime - lastSell[src]) < 0.5 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to sell too quickly')
        return
    end
    lastSell[src] = currentTime
    
    -- Distance check: Player must be near trading location
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local tradeCoords = vector3(Config.TradingLocation.coords.x, Config.TradingLocation.coords.y, Config.TradingLocation.coords.z)
    local distance = #(playerCoords - tradeCoords)
    
    if distance > 10.0 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to sell from too far away: '..distance..'m')
        TriggerClientEvent('QBCore:Notify', src, 'You must be at the trading location', 'error')
        return
    end
    
    if not Config.ResourceSelling.enabled then
        TriggerClientEvent('QBCore:Notify', src, 'Resource selling is disabled', 'error')
        return
    end
    
    -- Validate itemName is a string
    if type(itemName) ~= 'string' then
        print('[RECYCLE EXPLOIT] Player '..src..' sent invalid itemName type: '..type(itemName))
        return
    end
    
    -- Validate amount is a number
    if type(amount) ~= 'number' then
        print('[RECYCLE EXPLOIT] Player '..src..' sent invalid amount type: '..type(amount))
        return
    end
    
    -- Sanitize amount (remove decimals, ensure positive)
    amount = math.floor(math.abs(amount))
    
    if amount < 1 then
        return
    end
    
    -- Maximum sell amount per transaction (anti-dupe protection)
    if amount > 1000 then
        print('[RECYCLE EXPLOIT] Player '..src..' tried to sell excessive amount: '..amount)
        TriggerClientEvent('QBCore:Notify', src, 'Maximum 1000 items per sale', 'error')
        return
    end
    
    local price = Config.ResourceSelling.prices[itemName]
    if not price then
        TriggerClientEvent('QBCore:Notify', src, 'This item cannot be sold', 'error')
        return
    end
    
    local item = Player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough of this item', 'error')
        return
    end
    
    local totalPrice = price * amount
    
    -- Remove items and give money
    Player.Functions.RemoveItem(itemName, amount)
    Player.Functions.AddMoney('cash', totalPrice)
    
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', amount)
    TriggerClientEvent('QBCore:Notify', src, 'Sold '..amount..'x for $'..totalPrice, 'success')
    
    -- Refresh UI data
    TriggerEvent('recycle:server:getTradingData')
end)

