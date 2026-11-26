local Core = exports['rsg-core']:GetCoreObject()
local cooldowns={}
RegisterNetEvent('bs-cocaine:client:plantCooldown',function(index,untilTime)
  cooldowns[index]=untilTime
end)
local function prompt(text)
  -- Lightweight 3D prompt; avoids dependencies on another UI resource.
  local ped=PlayerPedId()
  local pos=GetEntityCoords(ped)
  local on,x,y=GetScreenCoordFromWorldCoord(pos.x,pos.y,pos.z+1.0)
  if on then
    SetTextScale(0.3,0.3)
    SetTextColor(255,255,255,255)
    SetTextCentre(true)
    local str=CreateVarString(10,'LITERAL_STRING',text)
    DisplayText(str,x,y)
  end
end
local function nearest()
  local pos=GetEntityCoords(PlayerPedId())
  local best,bestDist=nil,Config.InteractDistance
  for i,plant in ipairs(Config.Plants) do
    local dist=#(pos-plant.coords)
    if dist<bestDist and (cooldowns[i] or 0)<=GetCloudTimeAsInt() then best={kind='plant',index=i};bestDist=dist end
  end
  for i,bench in ipairs(Config.Benches) do
    local dist=#(pos-bench.coords)
    if dist<bestDist then best={kind='bench',index=i,label=bench.label};bestDist=dist end
  end
  return best
end
CreateThread(function()
  while true do
    if not Config.Enabled then Wait(3000)
    else
      local near=nearest()
      if not near then Wait(500)
      else
        Wait(0)
        if near.kind=='plant' then
          prompt('[G] Harvest coca leaves')
        else
          prompt('[G] '..near.label)
        end
        if IsControlJustPressed(0,Config.InteractKey) then
          if near.kind=='plant' then
            TriggerEvent('bs-cocaine:client:animateHarvest',near.index)
          else
            TriggerServerEvent('bs-cocaine:server:craft',near.index)
          end
          Wait(900)
        end
      end
    end
  end
end)
-- A separate target entry avoids changing existing weed sales.
-- Networked ambient NPCs only; server validates entity and distance.
CreateThread(function()
  if not Config.Enabled then return end
  if GetResourceState('rsg-target')~='started' then
    print('[bs-cocaine] rsg-target not started: NPC sales unavailable')
    return
  end
  exports['rsg-target']:addGlobalPed({
    {
      name='bs_cocaine_npc_sell',
      icon='fa-solid fa-handshake',
      label='Offer packaged product',
      distance=2.0,
      canInteract=function(entity)
        if not entity or not DoesEntityExist(entity)
          or IsPedAPlayer(entity)
          or not NetworkGetEntityIsNetworked(entity) then
          return false
        end

        local now = GetGameTimer()
        if not cocaineInventoryCheckAt or now >= cocaineInventoryCheckAt then
          cocaineHasProduct =
            exports['rsg-inventory']:HasItem(Config.Items.bag,1)
            or exports['rsg-inventory']:HasItem('bs_coca_bag_t1',1)
            or exports['rsg-inventory']:HasItem('bs_coca_bag_t2',1)
            or exports['rsg-inventory']:HasItem('bs_coca_bag_t3',1)
          cocaineInventoryCheckAt = now + 500
        end

        return cocaineHasProduct == true
      end,
      onSelect=function(data)
        local ped = data.entity
        if not ped or not DoesEntityExist(ped)
          or not NetworkGetEntityIsNetworked(ped) then return end

        local netId = NetworkGetNetworkIdFromEntity(ped)
        if not netId or netId == 0 then return end

        -- Hold the local briefly while the sale takes place.
        if not IsPedDeadOrDying(ped, true) then
          ClearPedTasks(ped)
          TaskTurnPedToFaceEntity(ped, PlayerPedId(), 1000)
          FreezeEntityPosition(ped, true)
        end

        -- Request the automatic sale.
        TriggerServerEvent('bs-cocaine:server:sell', netId, nil, 'auto')

        -- Release the local after the interaction.
        CreateThread(function()
          Wait(3000)
          if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, false)
          end
        end)
      end,
    }
  })
end)
AddEventHandler('onResourceStop',function(res)
  if res==GetCurrentResourceName() and GetResourceState('rsg-target')=='started' then
    exports['rsg-target']:removeGlobalPed({'bs_cocaine_npc_sell'})
  end
end)

-- bs-cocaine visible plant renderer
local plantObjects = {}
local plantModel = Config.PlantModel or 's_inv_bloodflower01x'

local function removePlant(index)
    local obj = plantObjects[index]
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
    end
    plantObjects[index] = nil
end

local function clearPlants()
    for index in pairs(plantObjects) do
        removePlant(index)
    end
end

CreateThread(function()
    if not Config.Enabled then return end

    local hash = GetHashKey(plantModel)
    RequestModel(hash)

    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end

    if not HasModelLoaded(hash) then
        print('[bs-cocaine] Plant model failed to load')
        return
    end

    while Config.Enabled do
        local playerCoords = GetEntityCoords(PlayerPedId())

        for index, plant in ipairs(Config.Plants) do
            local distance = #(playerCoords - plant.coords)

            local available = (cooldowns[index] or 0) <= GetCloudTimeAsInt()
            if distance < 80.0 and available then
                if not plantObjects[index] then
                    local pos = plant.coords
                    -- Each field entry has the same legacy Z; find the actual terrain
                    -- height at each X/Y before placing the plant.
                    local spawnZ = pos.z
                    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 50.0, false)
                    if found then spawnZ = groundZ end
                    local obj = CreateObject(hash, pos.x, pos.y, spawnZ, false, false, false)
                    if obj and obj ~= 0 then
                        SetEntityCoordsNoOffset(obj, pos.x, pos.y, spawnZ, false, false, false)
                        PlaceObjectOnGroundProperly(obj)
                        FreezeEntityPosition(obj, true)
                        plantObjects[index] = obj
                    end
                end
            else
                removePlant(index)
            end
        end

        Wait(2000)
    end

    clearPlants()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearPlants()
    end
end)

-- bs-cocaine initial plant state request
CreateThread(function()
    if not Config.Enabled then return end

    Wait(5000)
    TriggerServerEvent('bs-cocaine:server:requestPlantState')
end)

-- Animated coca harvesting
local harvesting = false

RegisterNetEvent('bs-cocaine:client:animateHarvest', function(index)
    if harvesting then return end
    harvesting = true

    local ped = PlayerPedId()
    local plant = Config.Plants[index]

    if not plant or
       #(GetEntityCoords(ped) - plant.coords) >
       Config.InteractDistance + 1.0 then
        harvesting = false
        return
    end

    -- Keep the player at the plant while picking
    TaskStartScenarioInPlace(
        ped,
        GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'),
        5000,
        true,
        false,
        false,
        false
    )

    Wait(5000)
    ClearPedTasks(ped)

    -- Server validates and awards the harvest.
    -- Successful harvest triggers plant cooldown/despawn.
    if #(GetEntityCoords(ped) - plant.coords) <=
       Config.InteractDistance + 1.0 then
        TriggerServerEvent('bs-cocaine:server:harvest', index)
    end

    harvesting = false
end)
-- BS_COCINE_GATHER_ZONES: invisible rsg-target third-eye supply locations.
local bsCocaineGathering = false
local bsCocaineGatherZones = {}

local function bsCocaineStartGather(index)
    if bsCocaineGathering then return end

    local location = Config.GatherLocations and Config.GatherLocations[index]
    if not location or not location.coords then return end

    local ped = PlayerPedId()
    local maxDistance = Config.GatherInteractDistance or 3.0
    if #(GetEntityCoords(ped) - location.coords) > maxDistance then return end

    bsCocaineGathering = true
    TaskStartScenarioInPlace(
        ped,
        GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'),
        (Config.GatherDurationSeconds or 10) * 1000,
        true,
        false,
        false,
        false
    )

    TriggerServerEvent('bs-cocaine:server:gatherSupply', index)
    Wait((Config.GatherDurationSeconds or 10) * 1000)
    ClearPedTasks(ped)
    bsCocaineGathering = false
end

CreateThread(function()
    if not Config.Enabled then return end

    while GetResourceState('rsg-target') ~= 'started' do
        Wait(1000)
    end

    for index, location in ipairs(Config.GatherLocations or {}) do
        local gatherIndex = index
        local zoneName = ('bs_cocaine_gather_%d'):format(gatherIndex)
        local ok, zoneId = pcall(function()
            return exports['rsg-target']:AddCircleZone(
                zoneName,
                location.coords,
                1.5,
                { useZ = true, debugPoly = false },
                {
                    options = {
                        {
                            name = zoneName,
                            icon = 'fas fa-search',
                            label = location.label,
                            action = function()
                                bsCocaineStartGather(gatherIndex)
                            end,
                        }
                    },
                    distance = 2.0,
                }
            )
        end)

        if ok and zoneId then
            bsCocaineGatherZones[#bsCocaineGatherZones + 1] = zoneId
            print(('[bs-cocaine] Registered third-eye supply zone: %s'):format(zoneName))
        else
            print(('[bs-cocaine] Failed to register zone %s: %s'):format(zoneName, tostring(zoneId)))
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if GetResourceState('rsg-target') == 'started' then
        for _, zoneId in ipairs(bsCocaineGatherZones) do
            pcall(function()
                exports['rsg-target']:RemoveZone(zoneId)
            end)
        end
    end
end)