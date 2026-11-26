local spawnedProps = {}
local targetZones = {}

local function spawnStationProp(station)
    if station.spawnProp == false then return end
    local c = station.coords
    local candidates = { station.model } -- Never silently spawn the legacy desk
    local prop

    for _, modelName in ipairs(candidates) do
        if type(modelName) == 'string' then
            local model = joaat(modelName)
            if IsModelInCdimage(model) and IsModelValid(model) then
                RequestModel(model)
                local timeout = GetGameTimer() + 5000
                while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(50) end
                if HasModelLoaded(model) then
                    prop = CreateObject(model, c.x, c.y, c.z, false, false, false)
                    SetModelAsNoLongerNeeded(model)
                    if prop ~= 0 and DoesEntityExist(prop) then
                        break
                    end
                else
                end
            else
            end
        end
    end

    if not prop or prop == 0 or not DoesEntityExist(prop) then
        print('[bs-coca-stations] A nearby interaction could not load its prop.')
        return
    end

    SetEntityHeading(prop, c.w)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    spawnedProps[#spawnedProps + 1] = prop
end

local function addStationTarget(station)
    local c = station.coords
    local zoneId = exports['rsg-target']:addSphereZone({
        name = ('bs-craftingstation-%s'):format(station.id),
        coords = vector3(c.x, c.y, c.z),
        radius = station.targetRadius or 1.5,
        debug = false,
        options = {
            {
                name = ('bs-craftingstation-use-%s'):format(station.id),
                icon = 'fa-solid fa-mortar-pestle',
                label = ('Use %s'):format(station.label),
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('bs-coca-crafting:client:openStation', station.id)
                end,
            },
        },
    })

    if zoneId then targetZones[#targetZones + 1] = zoneId end
end

local Core=exports['rsg-core']:GetCoreObject()
local function clearStations()
    for _,zone in ipairs(targetZones)do exports['rsg-target']:removeZone(zone)end
    for _,prop in ipairs(spawnedProps)do if DoesEntityExist(prop)then DeleteEntity(prop)end end
    targetZones={};spawnedProps={}
end
CreateThread(function()
    local signature=''
    while true do
        if LocalPlayer.state.isLoggedIn then
            local stations=Core.Functions.AwaitCallback('bs-coca-stations:nearby',10000)
            if stations then
                local ids={};for _,station in ipairs(stations)do local c = station.coords; ids[#ids+1] = ('%s:%.3f:%.3f:%.3f:%.3f:%s'):format(station.id, c.x, c.y, c.z, c.w, tostring(station.spawnProp)..':'..tostring(station.model)) end
                table.sort(ids);local nextSignature=table.concat(ids,'|')
                if nextSignature~=signature then
                    clearStations();signature=nextSignature
                    for _,station in ipairs(stations)do spawnStationProp(station);addStationTarget(station)end
                end
            end
        else clearStations();signature='' end
        Wait(5000)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, zoneId in ipairs(targetZones) do
        exports['rsg-target']:removeZone(zoneId)
    end
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
end)

