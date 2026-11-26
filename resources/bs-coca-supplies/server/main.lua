local RSGCore = exports['rsg-core']:GetCoreObject()

local Locations = {}
local GlobalCooldowns = {}
local PlayerCooldowns = {}

local DATA_FILE = 'data/locations.json'

local function debugPrint(message)
    if Config.Debug then
        print(('[bs-coca-supplies] %s'):format(message))
    end
end

local function notifyClient(src, message, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Broken Spur',
        description = message,
        type = nType or 'inform'
    })
end

local function isAdmin(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, Config.AdminAce) then return true end

    if Config.AllowRSGAdminPermission and RSGCore.Functions.HasPermission then
        local ok, result = pcall(function()
            return RSGCore.Functions.HasPermission(src, 'admin')
        end)
        if ok and result then return true end
    end

    return false
end

local function saveLocations()
    local encoded = json.encode(Locations, { indent = true })
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, encoded, -1)
end

local function loadLocations()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if not raw or raw == '' then
        Locations = {}
        saveLocations()
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print('[bs-coca-supplies] ERROR: locations.json is invalid JSON. No locations loaded.')
        Locations = {}
        return
    end

    Locations = decoded
    print(('[bs-coca-supplies] Loaded %d interaction points.'):format(#Locations))
end

local function findLocation(id)
    for index, location in ipairs(Locations) do
        if location.id == id then
            return index, location
        end
    end
    return nil, nil
end

local function validItem(itemName)
    if type(itemName) ~= 'string' or #itemName < 2 or #itemName > 64 then
        return false
    end

    local sharedItems = RSGCore.Shared and RSGCore.Shared.Items
    return sharedItems and sharedItems[itemName] ~= nil
end

local function validatePayload(data)
    if type(data) ~= 'table' then return false, 'Invalid interaction data.' end

    local validTypes = { gathering = true, search = true, loot = true, custom = true }
    if not validTypes[data.type] then return false, 'Invalid interaction type.' end

    if type(data.label) ~= 'string' or #data.label < 2 or #data.label > 48 then
        return false, 'Name must be between 2 and 48 characters.'
    end

    if not validItem(data.rewardItem) then
        return false, 'That reward item does not exist in RSGCore shared items.'
    end

    local minAmount = math.floor(tonumber(data.minAmount) or 0)
    local maxAmount = math.floor(tonumber(data.maxAmount) or 0)
    local cooldown = math.floor(tonumber(data.cooldown) or 0)
    local distance = tonumber(data.distance)
    local coords = data.coords

    if minAmount < 1 or maxAmount < minAmount or maxAmount > Config.MaxRewardAmount then
        return false, 'Invalid reward quantity.'
    end
    if cooldown < Config.MinCooldown or cooldown > Config.MaxCooldown then
        return false, 'Cooldown is outside the allowed range.'
    end
    if not distance or distance < 1 or distance > Config.MaxInteractDistance then
        return false, 'Interaction distance is outside the allowed range.'
    end
    if type(coords) ~= 'table'
        or type(coords.x) ~= 'number'
        or type(coords.y) ~= 'number'
        or type(coords.z) ~= 'number' then
        return false, 'Invalid location coordinates.'
    end

    if math.abs(coords.x) > 10000 or math.abs(coords.y) > 10000 or math.abs(coords.z) > 2000 then
        return false, 'Coordinates are outside valid world bounds.'
    end

    return true
end

local function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end

local function distanceBetween(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

lib.callback.register('bs-coca-supplies:server:isAdmin', function(source)
    return isAdmin(source)
end)

lib.callback.register('bs-coca-supplies:server:getLocations', function(source)
    if isAdmin(source) then
        return Locations
    end

    -- Players receive only fields needed for interaction; no admin-only metadata.
    local public = {}
    for _, location in ipairs(Locations) do
        public[#public + 1] = {
            id = location.id,
            type = location.type,
            label = location.label,
            rewardItem = location.rewardItem,
            coords = location.coords,
            distance = location.distance
        }
    end
    return public
end)

lib.callback.register('bs-coca-supplies:server:createLocation', function(source, data)
    if not isAdmin(source) then return false, 'Permission denied.' end
    if #Locations >= Config.MaxLocations then return false, 'Maximum location count reached.' end

    local valid, reason = validatePayload(data)
    if not valid then return false, reason end

    local id = ('city_%s_%s'):format(os.time(), math.random(1000, 9999))
    local location = {
        id = id,
        type = data.type,
        label = data.label,
        rewardItem = data.rewardItem,
        minAmount = math.floor(data.minAmount),
        maxAmount = math.floor(data.maxAmount),
        cooldown = math.floor(data.cooldown),
        distance = tonumber(data.distance),
        propModel = tostring(data.propModel or ''):sub(1, 64),
        coords = data.coords,
        heading = tonumber(data.heading) or 0,
        createdAt = os.time(),
        createdBy = GetPlayerName(source) or 'console'
    }

    Locations[#Locations + 1] = location
    saveLocations()
    debugPrint(('Created %s by %s'):format(id, location.createdBy))
    return true, ('Created "%s" (%s).'):format(location.label, id)
end)

lib.callback.register('bs-coca-supplies:server:updateLocation', function(source, data)
    if not isAdmin(source) then return false, 'Permission denied.' end
    if type(data) ~= 'table' or type(data.id) ~= 'string' then return false, 'Invalid location ID.' end

    local index, oldLocation = findLocation(data.id)
    if not index then return false, 'Location not found.' end

    local valid, reason = validatePayload(data)
    if not valid then return false, reason end

    Locations[index] = {
        id = oldLocation.id,
        type = data.type,
        label = data.label,
        rewardItem = data.rewardItem,
        minAmount = math.floor(data.minAmount),
        maxAmount = math.floor(data.maxAmount),
        cooldown = math.floor(data.cooldown),
        distance = tonumber(data.distance),
        propModel = tostring(data.propModel or ''):sub(1, 64),
        coords = data.coords,
        heading = tonumber(data.heading) or 0,
        createdAt = oldLocation.createdAt,
        createdBy = oldLocation.createdBy,
        updatedAt = os.time(),
        updatedBy = GetPlayerName(source) or 'console'
    }

    saveLocations()
    return true, ('Updated "%s".'):format(data.label)
end)

lib.callback.register('bs-coca-supplies:server:removeLocation', function(source, id)
    if not isAdmin(source) then return false, 'Permission denied.' end
    local index, location = findLocation(id)
    if not index then return false, 'Location not found.' end

    table.remove(Locations, index)
    GlobalCooldowns[id] = nil
    PlayerCooldowns[id] = nil
    saveLocations()
    return true, ('Removed "%s".'):format(location.label)
end)

lib.callback.register('bs-coca-supplies:server:collect', function(source, id)
    local index, location = findLocation(id)
    if not location then return false, 'This interaction no longer exists.' end

    local playerCoords = getPlayerCoords(source)
    if not playerCoords then return false, 'Unable to verify your position.' end

    local distance = distanceBetween(playerCoords, location.coords)
    local allowedDistance = (tonumber(location.distance) or Config.DefaultDistance) + Config.ServerDistanceTolerance
    if distance > allowedDistance then
        return false, 'You are too far away.'
    end

    local now = os.time()
    local nextAllowed = GlobalCooldowns[id] or 0
    if now < nextAllowed then
        return false, ('This location is depleted. Try again in %d seconds.'):format(nextAllowed - now)
    end

    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player data is not ready.' end

    if not validItem(location.rewardItem) then
        return false, 'The configured reward item is missing from RSGCore.'
    end

    local amount = math.random(location.minAmount, location.maxAmount)
    local added = Player.Functions.AddItem(location.rewardItem, amount)
    if added == false then
        return false, 'Your inventory is full.'
    end

    GlobalCooldowns[id] = now + location.cooldown
    notifyClient(source, ('You collected %sx %s.'):format(amount, location.rewardItem), 'success')
    return true, 'Collected.', amount
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    math.randomseed(os.time())
    loadLocations()
end)

RegisterCommand('bs-coca-supplies-reload', function(source)
    if source ~= 0 and not isAdmin(source) then
        notifyClient(source, 'Permission denied.', 'error')
        return
    end
    loadLocations()
    if source ~= 0 then
        notifyClient(source, 'Interaction locations reloaded.', 'success')
    end
end, false)
