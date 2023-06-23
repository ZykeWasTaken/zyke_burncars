z = exports["zyke_lib"]:Fetch()

if (Config.Settings.zykeGangs.enabled == true) then
    GangFuncs = exports["zyke_gangs"]:Fetch()
end

-- Caching
local reservedVehicleNetIds = {} -- When starting to burn a vehicle, the entity's netId will be reserved in here
local onCooldown = {} -- If you repair your vehicle almost right after burning it, you will have a cooldown before you can get a reward (Note that putting your car in a garage and taking it out will give the vehicle a new entityId, meaning this cooldown will not work)

RegisterNetEvent("zyke_burncars:Reward", function(pos, netId)
    local function securityAlert(msg)
        print("!!!!!SECURITY ALERT!!!!!")
        print(msg)
        print("Offender source: " .. source)
        print("!!!!!SECURITY ALERT!!!!!")

        -- You can perform any action in here such as kicking or banning
        -- At the moment it just prints what happened to the console along with the player id of the offender
    end

    local veh = NetworkGetEntityFromNetworkId(netId)

    -- Make sure the netId is reserved and valid
    if (not reservedVehicleNetIds[netId]) then
        return securityAlert("Someone somehow managed to collect a reward from a vehicle that is not reserved, this should not be possible")
    end

    -- Make sure the vehicle is valid
    if (veh == 0) then
        return securityAlert("Someone somehow managed to collect a reward from an invalid vehicle, this should not be possible")
    end

    -- Make sure you're realistically close to the vehicle
    if (#(pos - GetEntityCoords(veh)) > 5) then
        return securityAlert("Someone somehow managed to collect a reward from a vehicle that is too far away, this should not be possible")
    end

    -- Handle caching
    reservedVehicleNetIds[netId] = nil -- Remove the netId from the reserved list

    -- Make sure that the vehicle hasn't been burned too recently (Prevent reward spamming)
    -- If you want to, you can add notifications here, but this functionality is mainly made to prevent malicious use, it won't happen very often that the same car will be burned twice within 15 minutes through regular gameplay
    if (onCooldown[veh]) then
        if (os.time() < onCooldown[veh]) then
            return false
        end
    end

    -- Below here you can add any reward you want, I will perform zyke_gang's objective progression and loyalty removal from the gang that owns the grid

    onCooldown[veh] = os.time() + Config.Settings.cooldown -- Add the vehicle to the cooldown list so that you can't spam rewards
    -- Remove loyalty from the gang that owns the grid
    if (Config.Settings.zykeGangs.enabled == true) then
        local gridOwner, grid = GangFuncs.GetGangForGrid(pos)
        if (gridOwner) then
            gridOwner.Functions.RemoveGridLoyalty({
                id = grid.id,
                handler = source,
                amount = "burnCar", -- Passing in the name of the loyalty removal, and zyke_gangs will fetch the amount in it's config
                details = {
                    reason = "burnCar",
                }
            })
        end

        -- Add towards objective progression
        local playerGang = GangFuncs.GetPlayerGang(source)
        if (playerGang) then
            exports["zyke_gangs"]:AddToObjective({
                name = "burnCars",
                identifier = source,
                amount = 1,
            })
        end
    end

    -- Logging using zyke_lib, not really needed, but if you want full transparency, you can use it
    z.Log({
        webhook = Webhooks["BurnCar"],
        scriptName = GetCurrentResourceName(),
        identifier = z.GetIdentifier(source),
        handler = source,
        message = "Player burned a car",
        action = "BurnCar",
        logsEnabled = true,
        rawData = {
            pos = pos,
            netId = netId,
            veh = veh,
        }
    })
end)

z.CreateCallback("zyke_burncars:ValidateRequest", function(source, cb, data)
    local isReserved = reservedVehicleNetIds[data.netId]
    if (isReserved) then return cb({state = false, reason = "alreadyReserved"}) end

    reservedVehicleNetIds[data.netId] = true

    if ((Config.Settings.itemsNeeded) and (#Config.Settings.itemsNeeded > 0)) then
        local player = z.GetPlayer(source)
        local hasItem = z.HasItem(player, Config.Settings.itemsNeeded)

        if (not hasItem) then
            reservedVehicleNetIds[data.netId] = nil

            return cb({state = false, reason = "missingItem"})
        end

        for _, itemSettings in pairs(Config.Settings.itemsNeeded) do
            if (itemSettings.remove == true) then
                z.RemoveItem(player, itemSettings)
            end
        end
    end

    -- In case anything happens, we will remove the netId from the reserved list after a while
    CreateThread(function()
        Wait(60000)
        reservedVehicleNetIds[data.netId] = nil
    end)

    return cb({state = true})
end)