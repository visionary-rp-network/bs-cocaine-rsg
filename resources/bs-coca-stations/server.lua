local Core=exports['rsg-core']:GetCoreObject()
local last={}
Core.Functions.CreateCallback('bs-coca-stations:nearby',function(src,cb)
    if not Core.Functions.GetPlayer(src) then return cb({}) end
    local now=GetGameTimer()
    if last[src] and now-last[src]<3000 then return cb(nil) end
    last[src]=now
    local ped=GetPlayerPed(src)
    if not ped or ped==0 then return cb({}) end
    local position=GetEntityCoords(ped)
    local nearby={}
    for _,station in ipairs(Config.Stations or {}) do
        local coords = exports['bs-coca-crafting']:GetCraftBenchPlacement(station.id)
        local c = coords or station.coords
        if #(position - vector3(c.x, c.y, c.z)) <= 30.0 then
            local entry = {}
            for key, value in pairs(station) do entry[key] = value end
            if coords then
                entry.coords = coords
                -- Placement does not imply a spawned prop. Respect saved admin choice.
                local configured = exports['bs-coca-crafting']:GetCraftBenchAppearance(station.id)
                if configured then
                    entry.spawnProp = configured.spawnProp == true
                    entry.model = configured.model
                end
            end
            nearby[#nearby + 1] = entry
        end
    end
    for _, station in ipairs(exports['bs-coca-crafting']:GetNearbyCustomCraftBenches(position, 30.0)) do
        nearby[#nearby + 1] = station
    end
    cb(nearby)
end)
AddEventHandler('playerDropped',function()last[source]=nil end)
