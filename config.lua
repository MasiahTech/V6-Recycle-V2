Config = {}

-- Interaction System (set to 'ox_target' or 'textui')
Config.InteractionType = 'ox_target' -- Options: 'ox_target', 'textui'

-- Job Start Location
Config.JobStart = {
    coords = vector3(-484.63, -1730.39, 19.55),
    heading = 270.0,
    ped = 's_m_y_garbage',
    blip = {
        enabled = true,
        sprite = 318,
        color = 2,
        scale = 0.8,
        label = 'Recycle Job'
    }
}

-- Box Pickup Locations (randomized spawn points)
Config.BoxLocations = {
    vector3(-554.85, -1707.42, 18.92),
    vector3(-556.73, -1703.92, 19.08),
    vector3(-475.59, -1673.46, 18.76),
    vector3(-447.28, -1664.54, 19.03),
    vector3(-443.55, -1665.72, 19.03),
    vector3(-439.67, -1667.12, 19.03),
    vector3(-422.61, -1673.46, 19.03),
    vector3(-419.04, -1674.95, 19.03),
    vector3(-415.65, -1676.16, 19.03),
    vector3(-412.56, -1677.42, 19.03),
}

-- Drop Off Location
Config.DropOff = {
    coords = vector3(-428.64, -1728.26, 19.78),
    heading = 90.0,
    blip = {
        enabled = true,
        sprite = 50,
        color = 5,
        scale = 0.7,
        label = 'Recycle Drop Off'
    },
    reward = 'recyclablematerial', -- Item given per box dropped off
    minAmount = 1, -- Minimum materials per box
    maxAmount = 5  -- Maximum materials per box (random 1-3)
}

-- Box Settings
Config.BoxModel = 'prop_drop_crate_01' -- Eberhard crate model
Config.BoxBlip = {
    sprite = 365, -- Recycle icon
    color = 2,    -- Green
    scale = 0.6,
    label = 'Recycle Box'
}
Config.MaxActiveBoxes = 5 -- Maximum boxes spawned at once
Config.BoxCarryAnimation = {
    dict = 'anim@heists@box_carry@',
    anim = 'idle',
    flag = 49
}

-- Trading Location (where players sell recyclablematerial)
Config.TradingLocation = {
    coords = vector3(-498.86, -1713.86, 19.97),
    heading = 180.0,
    ped = 's_m_m_scientist_01',
    blip = {
        enabled = true,
        sprite = 500,
        color = 3,
        scale = 0.8,
        label = 'Material Trading'
    }
}

-- Recyclable Material Trading System
Config.Trading = {
    -- Items players can get from trading recyclablematerial
    -- Format: {item = 'item_name', label = 'Display Name', rarity = 'common/uncommon/rare/epic', baseChance = number (0-100), minAmount = number, maxAmount = number}
    rewards = {
        -- Common Items (high chance)
        {item = 'plastic', label = 'Plastic', rarity = 'common', baseChance = 45, minAmount = 1, maxAmount = 3},
        {item = 'metalscrap', label = 'Metal Scrap', rarity = 'common', baseChance = 40, minAmount = 1, maxAmount = 3},
        {item = 'glass', label = 'Glass', rarity = 'common', baseChance = 35, minAmount = 1, maxAmount = 2},
        
        -- Uncommon Items (medium chance)
        {item = 'copper', label = 'Copper', rarity = 'uncommon', baseChance = 25, minAmount = 1, maxAmount = 2},
        {item = 'steel', label = 'Steel', rarity = 'uncommon', baseChance = 20, minAmount = 1, maxAmount = 2},
        {item = 'aluminum', label = 'Aluminum', rarity = 'uncommon', baseChance = 18, minAmount = 1, maxAmount = 2},
        
        -- Rare Items (low chance)
        {item = 'electronics', label = 'Electronics', rarity = 'rare', baseChance = 12, minAmount = 1, maxAmount = 1},
        {item = 'rubber', label = 'Rubber', rarity = 'rare', baseChance = 10, minAmount = 1, maxAmount = 2},
        
        -- Epic Items (very low chance)
        {item = 'gold', label = 'Gold Bar', rarity = 'epic', baseChance = 5, minAmount = 1, maxAmount = 1},
        {item = 'diamond', label = 'Diamond', rarity = 'epic', baseChance = 3, minAmount = 1, maxAmount = 1},
    },
    
    -- Scaling bonuses (more materials = more items received)
    -- These define the min/max items you can get per reward based on materials traded
    -- guaranteedItems = minimum number of different items you'll receive (no empty trades)
    scalingBonus = {
        {minAmount = 1, maxAmount = 10, itemMin = 1, itemMax = 3, guaranteedItems = 1},      -- Small: 1-3 items each, min 1 type
        {minAmount = 11, maxAmount = 25, itemMin = 5, itemMax = 10, guaranteedItems = 2},    -- Medium: 5-10 items each, min 2 types
        {minAmount = 26, maxAmount = 50, itemMin = 11, itemMax = 25, guaranteedItems = 3},   -- Large: 11-25 items each, min 3 types
        {minAmount = 51, maxAmount = 100, itemMin = 26, itemMax = 50, guaranteedItems = 5},  -- Huge: 26-50 items each, min 5 types
        {minAmount = 101, maxAmount = 250, itemMin = 50, itemMax = 100, guaranteedItems = 7} -- Massive: 50-100 items each, min 7 types
    },
    
    -- Minimum materials required to trade
    minTradeAmount = 1,
    
    -- Maximum materials per trade
    maxTradeAmount = 1000
}

-- Resource Selling (sell items you got from trading for money)
Config.ResourceSelling = {
    enabled = true,
    prices = {
        -- Format: ['item_name'] = price
        -- Common items (lower prices)
        ['plastic'] = 2,
        ['metalscrap'] = 4,
        ['glass'] = 6,
        
        -- Uncommon items (medium prices)
        ['copper'] = 8,
        ['steel'] = 10,
        ['aluminum'] = 12,
        
        -- Rare items (high prices)
        ['electronics'] = 14,
        ['rubber'] = 16,
        
        -- Epic items (very high prices)
        ['goldbar'] = 100,
        ['diamond'] = 150,
    }
}
