-- Custom scripts: Visionary RP Network (VRP) | Broken Spur project | sovereign_rp. Original upstream credits and licenses retained.
local Core = exports['rsg-core']:GetCoreObject()
local Inv = exports['rsg-inventory']
local plantReady = {}
local busy = {}
local lastHarvest, lastSale = {}, {}
local npcUsed = {}
local function notify(src, message, kind)
  TriggerClientEvent('RSGCore:Client:Notify', src, {title='Broken Spur', description=message, type=kind or 'inform', duration=5000})
end
local function near(src, pos, distance)
  local ped = GetPlayerPed(src)
  return ped ~= 0 and #(GetEntityCoords(ped)-pos) <= distance
end
local function count(src, name) return Inv:GetItemCount(src, name) or 0 end
local function remove(src, name, amount, reason)
  return Inv:RemoveItem(src, name, amount, nil, reason) == true
end
local function add(src, name, amount, reason)
  return Inv:AddItem(src, name, amount, nil, nil, reason) == true
end
local function hasItems()
  for _, name in pairs(Config.Items) do
    if not Core.Shared.Items[name] then
      print(('[bs-cocaine] Missing item %s; resource is not ready'):format(name))
      return false
    end
  end
  return true
end
local ready = false
CreateThread(function()
  Wait(2000)
  ready = Config.Enabled and hasItems()
  if Config.Enabled and #Config.Plants == 0 then
    ready = false
    print('[bs-cocaine] Configure coca field before enabling')
  end
end)
local function usable(src)
  return ready and Core.Functions.GetPlayer(src) ~= nil
end
RegisterNetEvent('bs-cocaine:server:harvest', function(index)
  local src=source
  if not usable(src) or type(index)~='number' or index%1~=0 then return end
  local plant=Config.Plants[index]
  if not plant or not near(src, plant.coords, Config.InteractDistance+1.0) then return end
  local now=os.time()
  if (lastHarvest[src] or 0)+Config.HarvestCooldownSeconds>now then return end
  if (plantReady[index] or 0)>now then return notify(src,'This plant needs time to regrow.','error') end
  lastHarvest[src]=now
  local qty=math.random(Config.HarvestAmount.min,Config.HarvestAmount.max)
  if not Inv:CanAddItem(src,Config.Items.leaf,qty) then return notify(src,'Not enough inventory space.','error') end
  plantReady[index]=now+Config.FieldRespawnSeconds
  if not add(src,Config.Items.leaf,qty,'bs-cocaine-harvest') then
    plantReady[index]=0
    return notify(src,'Harvest failed.','error')
  end
  notify(src,('Harvested %d leaves.'):format(qty),'success')
  TriggerClientEvent('bs-cocaine:client:plantCooldown',-1,index,plantReady[index])
end)
local function finishCraft(src, index)
  local station=Config.Benches[index]
  local recipe=station and Config.Recipes[station.stage]
  if not usable(src) or not recipe or not near(src,station.coords,Config.InteractDistance+1.0) then return end
  for item,amount in pairs(recipe.inputs) do
    if count(src,item)<amount then return notify(src,'Missing crafting ingredients.','error') end
  end
  if not Inv:CanAddItem(src,recipe.output,recipe.amount) then
    return notify(src,'Not enough inventory space.','error')
  end
  local removed={}
  for item,amount in pairs(recipe.inputs) do
    if not remove(src,item,amount,'bs-cocaine-craft') then
      for restore,qty in pairs(removed) do
        if not add(src,restore,qty,'bs-cocaine-rollback') then
          print(('[bs-cocaine] CRITICAL: failed refund src=%s item=%s qty=%s'):format(src,restore,qty))
        end
      end
      return notify(src,'Crafting failed; check inventory.','error')
    end
    removed[item]=amount
  end
  if not add(src,recipe.output,recipe.amount,'bs-cocaine-craft') then
    for item,amount in pairs(removed) do
      if not add(src,item,amount,'bs-cocaine-rollback') then
        print(('[bs-cocaine] CRITICAL: failed refund src=%s item=%s qty=%s'):format(src,item,amount))
      end
    end
    return notify(src,'Output failed; check inventory.','error')
  end
  notify(src,'Production completed.','success')
end
RegisterNetEvent('bs-cocaine:server:craft', function(index)
  local src=source
  if not usable(src) or busy[src] or type(index)~='number' or index%1~=0 then return end
  local station=Config.Benches[index]
  if not station or not Config.Recipes[station.stage] or not near(src,station.coords,Config.InteractDistance+1.0) then return end
  busy[src]=true
  SetTimeout(Config.CraftSeconds*1000,function()
    if busy[src] then finishCraft(src,index) end
    busy[src]=nil
  end)
  notify(src,'Working at the bench...')
end)
RegisterNetEvent('bs-cocaine:server:sell',function(netId, itemName, mode)
  local src=source
  if not usable(src) or busy[src] or type(netId)~='number' or netId<=0 or netId%1~=0 then return end
  local now=os.time()
  if (lastSale[src] or 0)+Config.SaleCooldownSeconds>now then return end
  local ped=NetworkGetEntityFromNetworkId(netId)
  if not ped or ped==0 or not DoesEntityExist(ped) or GetEntityType(ped)~=1 or IsPedAPlayer(ped) then return end
  if not near(src,GetEntityCoords(ped),Config.NpcDistance+1.0) then return end
  if npcUsed[netId] and now - npcUsed[netId] < 300 then return notify(src,'This buyer is not interested.','error') end
  -- Automatic mixed-product sale, highest-value tier first.
  -- Preserve the existing buyer acceptance roll and cooldown.
  local remaining = math.max(0, math.floor(tonumber(Config.SaleQuantityMax) or 15))
  if remaining == 0 then return end

  local products = {}
  for _, tier in ipairs(Config.TierSales or {}) do
    products[#products+1] = {
      item = tier.item,
      price = tonumber(tier.price) or 0
    }
  end

  table.sort(products,function(a,b) return a.price>b.price end)

  products[#products+1] = {
    item = Config.Items.bag,
    price = nil
  }

  local plan = {}
  local totalQty, totalPay = 0, 0

  for _, product in ipairs(products) do
    if remaining <= 0 then break end
    local owned = count(src,product.item)
    if owned > 0 then
      local qty = math.min(owned,remaining)
      local price = product.price or math.random(Config.PriceMin,Config.PriceMax)
      plan[#plan+1] = {
        item = product.item,
        qty = qty,
        price = price
      }
      totalQty = totalQty + qty
      totalPay = totalPay + qty * price
      remaining = remaining - qty
    end
  end

  if totalQty == 0 then
    return notify(src,'You have no packaged product.','error')
  end

  lastSale[src] = now
  npcUsed[netId] = now

  if math.random(100) > Config.BuyChance then
    return notify(src,'The buyer declined.','error')
  end

  local removed = {}
  for _, entry in ipairs(plan) do
    if not remove(src,entry.item,entry.qty,'bs-cocaine-npc-sale') then
      for _, refund in ipairs(removed) do
        if not add(src,refund.item,refund.qty,'bs-cocaine-sale-refund') then
          print(('[bs-cocaine] CRITICAL: refund failed src=%s item=%s qty=%s')
            :format(src,refund.item,refund.qty))
        end
      end
      return notify(src,'Sale failed.','error')
    end
    removed[#removed+1] = entry
  end

  local player = Core.Functions.GetPlayer(src)
  if not player or not player.Functions.AddMoney(
    Config.SaleMoneyType,totalPay,'bs-cocaine-npc-sale'
  ) then
    for _, refund in ipairs(removed) do
      if not add(src,refund.item,refund.qty,'bs-cocaine-sale-refund') then
        print(('[bs-cocaine] CRITICAL: payment refund failed src=%s item=%s qty=%s')
          :format(src,refund.item,refund.qty))
      end
    end
    return notify(src,'Payment failed.','error')
  end

  notify(src,('Sold %d bags for $%d total.'):format(totalQty,totalPay),'success')
end)
AddEventHandler('playerDropped',function()
  local src=source
  busy[src]=nil
  lastHarvest[src]=nil
  lastSale[src]=nil
end)
CreateThread(function()
  while true do
    Wait(600000)
    local now=os.time()
    for id,t in pairs(npcUsed) do if t+300<now then npcUsed[id]=nil end end
  end
end)

-- bs-cocaine plant cooldown synchronization
RegisterNetEvent('bs-cocaine:server:requestPlantState', function()
    local src = source
    if not usable(src) then return end

    local now = os.time()
    for index, untilTime in pairs(plantReady) do
        if untilTime > now then
            TriggerClientEvent(
                'bs-cocaine:client:plantCooldown',
                src, index, untilTime
            )
        end
    end
end)

-- Broken Spur TEST: third-eye supply gathering. No per-location cooldowns.
RegisterNetEvent('bs-cocaine:server:gatherSupply', function(index)
    local src = source
    if not usable(src) or busy[src] or type(index) ~= 'number' or index % 1 ~= 0 then return end

    local location = Config.GatherLocations and Config.GatherLocations[index]
    if not location or not location.coords then return end

    local allowedItem = location.item == Config.Items.reagent or location.item == Config.Items.baggie
    if not allowedItem then return end

    local maxDistance = Config.GatherInteractDistance or 3.0
    if not near(src, location.coords, maxDistance) then return end

    local duration = (Config.GatherDurationSeconds or 10) * 1000
    busy[src] = true
    notify(src, 'Searching...', 'inform')

    SetTimeout(duration, function()
        if not busy[src] then return end
        busy[src] = nil

        if not usable(src) then return end
        if not near(src, location.coords, maxDistance) then
            return notify(src, 'You moved too far away. Search cancelled.', 'error')
        end

        local minimum = math.max(1, math.floor(tonumber(location.min) or 1))
        local maximum = math.max(minimum, math.floor(tonumber(location.max) or minimum))
        local quantity = math.random(minimum, maximum)

        if not Inv:CanAddItem(src, location.item, quantity) then
            return notify(src, 'Not enough inventory space.', 'error')
        end

        if not add(src, location.item, quantity, 'bs-cocaine-supply-gather') then
            return notify(src, 'Gathering failed. Check your inventory.', 'error')
        end

        local itemData = Core.Shared.Items[location.item]
        local label = itemData and itemData.label or location.item
        notify(src, ('Collected %d %s.'):format(quantity, label), 'success')
    end)
end)