local RSGCore = exports['rsg-core']:GetCoreObject()

local Locations = {}
local textVisible = false
local activeLocation = nil
local busy = false

local function notify(description, nType)
    lib.notify({
        title = 'Broken Spur',
        description = description,
        type = nType or 'inform'
    })
end

local function refreshLocations()
    local result = lib.callback.await('bs-coca-supplies:server:getLocations', false)
    Locations = result or {}
end

local function isAdmin()
    -- Server remains authoritative. This is only used to hide admin commands locally.
    local ok, allowed = pcall(function()
        return lib.callback.await('bs-coca-supplies:server:isAdmin', false)
    end)
    return ok and allowed == true
end

local function closestLocation(maxDistance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest, closestDistance

    for _, location in pairs(Locations) do
        local point = vector3(location.coords.x, location.coords.y, location.coords.z)
        local distance = #(coords - point)
        local radius = tonumber(location.distance) or Config.DefaultDistance
        local allowedDistance = maxDistance or radius

        if distance <= allowedDistance then
            if not closestDistance or distance < closestDistance then
                closest = location
                closestDistance = distance
            end
        end
    end

    return closest, closestDistance
end

local function getPlacementInput(existing)
    local defaults = existing or {}
    local options = {
        { value = 'gathering', label = 'Gathering - collect a resource' },
        { value = 'search', label = 'Search - search a container or area' },
        { value = 'loot', label = 'Loot - search for supplies' },
        { value = 'custom', label = 'Custom - general interaction' }
    }

    local input = lib.inputDialog(existing and 'Edit Interaction Point' or 'Place Interaction Point', {
        {
            type = 'select',
            label = 'Interaction type',
            options = options,
            required = true,
            default = defaults.type or 'gathering'
        },
        {
            type = 'input',
            label = 'Display name',
            description = 'Example: Coca Plant, Supply Crate, Abandoned Tools',
            required = true,
            min = 2,
            max = 48,
            default = defaults.label or ''
        },
        {
            type = 'input',
            label = 'Reward item ID',
            description = 'Exact RSGCore item name, e.g. bs_coca_leaf',
            required = true,
            min = 2,
            max = 64,
            default = defaults.rewardItem or ''
        },
        {
            type = 'number',
            label = 'Minimum quantity',
            required = true,
            min = 1,
            max = Config.MaxRewardAmount,
            default = defaults.minAmount or 1
        },
        {
            type = 'number',
            label = 'Maximum quantity',
            required = true,
            min = 1,
            max = Config.MaxRewardAmount,
            default = defaults.maxAmount or 1
        },
        {
            type = 'number',
            label = 'Respawn cooldown (seconds)',
            description = 'Shared cooldown for this location',
            required = true,
            min = Config.MinCooldown,
            max = Config.MaxCooldown,
            default = defaults.cooldown or 900
        },
        {
            type = 'number',
            label = 'Interaction distance (metres)',
            required = true,
            min = 1,
            max = Config.MaxInteractDistance,
            default = defaults.distance or Config.DefaultDistance
        },
        {
            type = 'input',
            label = 'Prop model (optional)',
            description = 'Reference label only; leave blank for a ground/area point',
            required = false,
            max = 64,
            default = defaults.propModel or ''
        }
    })

    return input
end

local function submitLocation(existing, moveToCurrentPosition)
    local input = getPlacementInput(existing)
    if not input then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local payload = {
        id = existing and existing.id or nil,
        type = input[1],
        label = input[2],
        rewardItem = input[3],
        minAmount = input[4],
        maxAmount = input[5],
        cooldown = input[6],
        distance = input[7],
        propModel = input[8] or '',
        coords = (existing and not moveToCurrentPosition) and existing.coords
            or { x = coords.x, y = coords.y, z = coords.z },
        heading = (existing and not moveToCurrentPosition) and (existing.heading or heading) or heading
    }

    local eventName = existing and 'bs-coca-supplies:server:updateLocation'
        or 'bs-coca-supplies:server:createLocation'

    local success, message = lib.callback.await(eventName, false, payload)
    notify(message or (success and 'Saved.' or 'Could not save.'), success and 'success' or 'error')

    if success then refreshLocations() end
end

RegisterCommand(Config.Commands.place, function()
    if not isAdmin() then
        notify('You do not have permission to place interaction points.', 'error')
        return
    end
    submitLocation(nil)
end, false)

local function teleportToLocation(location)
    if not location or type(location.coords) ~= 'table' then
        notify('This location has no valid saved coordinates.', 'error')
        return
    end

    local ped = PlayerPedId()
    local coords = location.coords

    DoScreenFadeOut(250)
    local fadeTimeout = GetGameTimer() + 2000
    while not IsScreenFadedOut() and GetGameTimer() < fadeTimeout do
        Wait(10)
    end

    -- Use the exact saved point coordinates and heading from the placement record.
    SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 0.15, false, false, false, false)
    SetEntityHeading(ped, tonumber(location.heading) or 0.0)
    Wait(250)
    DoScreenFadeIn(350)
    notify(('Teleported to %s.'):format(location.label), 'success')
end

local function openLocationActions(location, contextId)
    local options = {
        {
            title = 'Teleport to This Location',
            description = 'Move yourself to the saved interaction point.',
            icon = 'location-arrow',
            onSelect = function()
                teleportToLocation(location)
            end
        },
        {
            title = 'Edit Interaction Settings',
            description = 'Change the type, reward, quantity, cooldown, or radius without moving the point.',
            icon = 'pen-to-square',
            onSelect = function()
                submitLocation(location, false)
            end
        },
        {
            title = 'Move Point to My Current Position',
            description = 'Relocate this saved point to where you are standing now.',
            icon = 'arrows-up-down-left-right',
            onSelect = function()
                submitLocation(location, true)
            end
        },
        {
            title = 'Delete Location',
            description = 'Permanently remove this saved interaction point (confirmation required).',
            icon = 'trash',
            iconColor = '#dc2626',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Delete Interaction Location',
                    content = ('Permanently delete "%s" (ID: %s)? This cannot be undone.'):format(location.label, location.id),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Delete Location', cancel = 'Cancel' }
                })
                if confirm ~= 'confirm' then return end

                local success, message = lib.callback.await('bs-coca-supplies:server:removeLocation', false, location.id)
                notify(message or (success and 'Deleted.' or 'Could not delete.'), success and 'success' or 'error')
                if success then
                    refreshLocations()
                    -- Close the deleted location's action menu; the list is rebuilt on next /bslocations.
                    lib.hideContext(false)
                end
            end
        }
    }

    lib.registerContext({
        id = contextId,
        title = location.label,
        menu = contextId == 'bs_cityinteractions_nearest_actions' and nil or 'bs_cityinteractions_locations',
        options = options
    })
    lib.showContext(contextId)
end

RegisterCommand(Config.Commands.edit, function()
    if not isAdmin() then
        notify('You do not have permission to edit interaction points.', 'error')
        return
    end

    local location = closestLocation(8.0)
    if not location then
        notify('No interaction point nearby. Stand within 8 metres.', 'error')
        return
    end

    openLocationActions(location, 'bs_cityinteractions_nearest_actions')
end, false)

RegisterCommand(Config.Commands.remove, function()
    if not isAdmin() then
        notify('You do not have permission to remove interaction points.', 'error')
        return
    end

    local location = closestLocation(8.0)
    if not location then
        notify('No interaction point nearby. Stand within 8 metres.', 'error')
        return
    end

    local confirm = lib.alertDialog({
        header = 'Remove Interaction Point',
        content = ('Remove "%s" (%s)? This cannot be undone.'):format(location.label, location.id),
        centered = true,
        cancel = true
    })

    if confirm ~= 'confirm' then return end

    local success, message = lib.callback.await('bs-coca-supplies:server:removeLocation', false, location.id)
    notify(message or (success and 'Removed.' or 'Could not remove.'), success and 'success' or 'error')
    if success then refreshLocations() end
end, false)

RegisterCommand(Config.Commands.list, function()
    if not isAdmin() then
        notify('You do not have permission to view the location list.', 'error')
        return
    end

    local options = {}
    for _, location in pairs(Locations) do
        options[#options + 1] = {
            title = ('%s [%s]'):format(location.label, location.type),
            description = ('ID: %s | Reward: %s | Cooldown: %ss'):format(
                location.id, location.rewardItem, location.cooldown
            ),
            onSelect = function()
                openLocationActions(location, ('bs_cityinteractions_location_%s'):format(location.id))
            end
        }
    end

    if #options == 0 then
        notify('No saved interaction points.')
        return
    end

    lib.registerContext({
        id = 'bs_cityinteractions_locations',
        title = 'Saved City Interactions',
        options = options
    })
    lib.showContext('bs_cityinteractions_locations')
end, false)

RegisterCommand(Config.Commands.reload, function()
    if not isAdmin() then
        notify('You do not have permission to reload locations.', 'error')
        return
    end
    refreshLocations()
    notify(('Loaded %d interaction points.'):format(#Locations), 'success')
end, false)

local function playInteractionAnimation(location)
    local animation = Config.Animations[location.type]
    if not animation then return end

    RequestAnimDict(animation.dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(animation.dict) and GetGameTimer() < timeout do
        Wait(25)
    end

    if HasAnimDictLoaded(animation.dict) then
        TaskPlayAnim(PlayerPedId(), animation.dict, animation.clip, 1.0, 1.0, -1, 1, 0.0, false, false, false)
    end
end

CreateThread(function()
    Wait(1500)
    refreshLocations()

    while true do
        local waitTime = 1000
        local location = closestLocation(12.0)

        if location and not busy then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local point = vector3(location.coords.x, location.coords.y, location.coords.z)
            local distance = #(coords - point)
            local radius = tonumber(location.distance) or Config.DefaultDistance

            if distance <= radius then
                waitTime = 0
                activeLocation = location

                if not textVisible then
                    lib.showTextUI(('[%s] %s - %s'):format(
                        Config.InteractKeyLabel,
                        Config.TypeLabels[location.type] or 'Interact',
                        location.label
                    ), { position = 'left-center' })
                    textVisible = true
                end

                if IsControlJustReleased(0, Config.InteractControl) then
                    busy = true
                    lib.hideTextUI()
                    textVisible = false

                    playInteractionAnimation(location)

                    local completed = lib.progressCircle({
                        duration = Config.ProgressDuration,
                        label = ('%s...'):format(Config.TypeLabels[location.type] or 'Interacting'),
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = Config.ProgressCanCancel,
                        disable = { move = true, car = true, combat = true }
                    })

                    ClearPedTasks(ped)

                    if completed then
                        local success, message, amount = lib.callback.await(
                            'bs-coca-supplies:server:collect',
                            false,
                            location.id
                        )

                        if success then
                            notify(('Collected %sx %s.'):format(amount, location.rewardItem), 'success')
                        else
                            notify(message or 'You cannot collect from this location right now.', 'error')
                        end
                    end

                    busy = false
                    activeLocation = nil
                    Wait(500)
                end
            elseif textVisible then
                lib.hideTextUI()
                textVisible = false
                activeLocation = nil
            end
        elseif textVisible then
            lib.hideTextUI()
            textVisible = false
            activeLocation = nil
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if textVisible then lib.hideTextUI() end
    ClearPedTasks(PlayerPedId())
end)
