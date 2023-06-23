z = exports["zyke_lib"]:Fetch()

-- This is just to fetch the zyke_gangs functionalities, will only fetch if you have this setting enabled
if (Config.Settings.zykeGangs.enabled) then
    GangFuncs = exports["zyke_gangs"]:Fetch()
end

local timers = {} -- Hoisting
local closeVehicles = {}
local closestVehicle = nil
local shouldDisplayTampering = true

local function IsVehicleBlacklisted(veh)
    return Config.BlacklistedVehicles[GetEntityModel(veh)]
end

local function IsVehicleInDisabledClass(veh)
    return Config.Settings.disabledClasses[GetVehicleClass(veh)]
end

local function FetchCloseVehicles()
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply)
    local vehicles = {}
    local pool = GetGamePool("CVehicle")
    local maxDst = 250

    for _, veh in ipairs(pool) do
        local vehCoords = GetEntityCoords(veh)
        local dst = #(plyCoords - vehCoords)

        if (dst <= maxDst) then
            table.insert(vehicles, veh)
        end
    end

    return vehicles
end

-- Basically part of "MeetsRequirement", but is separate as "tamper" should not even be visible if these requirements are not met
local function ShouldDisplayTampering()
    local plyPos = GetEntityCoords(PlayerPedId())

    -- NOTE! That you can not use zyke_gangs functionalities if you do not have the script installed
    local zykeGangSettings = Config.Settings.zykeGangs
    if (zykeGangSettings.enabled == true) then -- Make sure you want to use zyke_gangs functionalities
        if (zykeGangSettings.hasToBeInGang) then
            local playerGang = GangFuncs.GetPlayerGang()

            if (not playerGang) then return false end -- Make sure the player is in a gang
        end

        if (zykeGangSettings.hasToBeInGrid) then
            local grid = GangFuncs.GetGridData(plyPos)

            if (grid.id == "empty") then return false end -- Make sure the player is in a marked grid
        end
    end

    return true
end

-- These requirements can be toggled inside of Config.Settings.requirements as well as Config.Settings.zykeGangs
local function MeetsRequirements(veh)
    local settings = Config.Settings.requirements

    if (settings.emptyVehicle) then
        if ((GetVehicleNumberOfPassengers(veh) > 0) or (not IsVehicleSeatFree(veh, -1))) then
            z.Notify(Config.Strings.emptyVehicleFailed.msg, Config.Strings.emptyVehicleFailed.type)
            return false
        end
    end

    if (settings.vehicleOff) then
        if (GetIsVehicleEngineRunning(veh)) then
            z.Notify(Config.Strings.vehicleOffFailed.msg, Config.Strings.vehicleOffFailed.type)
            return false
        end
    end

    return true
end

local function IsVehicleRearEngine(veh)
    return Config.RearEngines[GetEntityModel(veh)]
end

local function BurnCar(veh, isRear)
    local ply = PlayerPedId()
    local plyPos = GetEntityCoords(ply)
    local pos = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, "engine"))
    local meetsRequirements = MeetsRequirements(veh)
    SetEntityAsMissionEntity(veh, true, true)
    NetworkRegisterEntityAsNetworked(veh)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(veh), true)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    if (not meetsRequirements) then return false end

    local p = promise.new()
    z.Callback("zyke_burncars:ValidateRequest", function(res)
        p:resolve(res)
    end, {
        netId = netId,
    })

    local response = Citizen.Await(p)
    if (not response) then return false end
    if (response.state == false) then
        local str = Config.Strings[response.reason].msg

        if (response.reason == "missingItem") then
            local missingItems = ""
            for _, item in ipairs(Config.Settings.itemsNeeded) do
                local itemLabel = z.GetItem(item.name)?.label or item.name
                missingItems = missingItems .. itemLabel .. " (" .. item.amount .. "), "
            end

            str = str:format(missingItems:sub(1, -3))
        end

        z.Notify(str, Config.Strings[response.reason].type)
        return false
    end

    CreateThread(function()
        z.ProgressBar("tamperingWithCar", Config.Strings.tamperingWithCar, 15000, nil, false, {}, nil, nil, nil, nil, nil)
    end)

    if (not isRear) then
        SetVehicleDoorOpen(veh, 4, false, true)
    end

    z.PlayAnim(ply, "mini@repair", "fixing_a_player", 8.0, -8.0, -1, 15, 1.0, 0, 0, 0)
    FreezeEntityPosition(ply, true)
    Wait(15000)

    z.Notify(Config.Strings.tamperedwithVehicle.msg, Config.Strings.tamperedwithVehicle.type)
    ClearPedTasks(ply)
    FreezeEntityPosition(ply, false)
    SetVehicleEngineHealth(veh, 0.0)

    SetVehicleEngineHealth(veh, 0.0)
    Wait(5000)
    local fire = StartScriptFire(pos.x, pos.y, pos.z, 25, true)

    -- Right after the fire is started, we will give rewards
    -- plyPos will be used to verify the location of your position and the vehicle's position, to prevent malicious usage
    -- netId will be used to cache which vehicles have been burned and not, to prevent spamming and malicious usage
    TriggerServerEvent("zyke_burncars:Reward", plyPos, netId)

    -- Put in a thread so that you can tamper other vehicles without being stuck with this one
    CreateThread(function()
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)
        SetEntityInvincible(veh, true) -- Prevents further spread and explosion

        Wait(20000)
        RemoveScriptFire(fire)

        Wait(1000)
        SetEntityInvincible(veh, false)
    end)
end

function HashTable(tbl)
    local newTbl = {}

    for _, value in pairs(tbl) do
        if (type(value) == "string") then
            newTbl[joaat(value)] = true
        else
            newTbl[value] = true
        end
    end

    return newTbl
end

local function FetchClosestVehicle(vehicles)
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply)
    local closestDst = 999999
    local _closestVehicle = nil

    for _, veh in pairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        local dst = #(plyCoords - vehCoords)

        if (dst < closestDst) then
            closestDst = dst
            _closestVehicle = veh
        end
    end

    return _closestVehicle
end

timers = {
    ["fetchCloseVehiclesTimer"] = {
        delay = 2500,
        func = function() closeVehicles = FetchCloseVehicles() end,
    },
    ["fetchClosestVehicleTimer"] = {
        delay = 500,
        func = function() closestVehicle = FetchClosestVehicle(closeVehicles) end,
    },
    ["shouldDisplayTamperingTimer"] = {
        delay = 1500,
        func = function() shouldDisplayTampering = ShouldDisplayTampering() end,
    },
}

-- Handles all of the requirements, caching etc, used to improve performance and reduce the amount of copy paste code
local function HandleTimers()
    for _, timer in pairs(timers) do
        if ((timer.timer or 0) < GetGameTimer()) then
            timer.timer = GetGameTimer() + timer.delay

            if (timer.func) then
                timer.func()
            end
        end
    end
end

CreateThread(function()
    Config.RearEngines = HashTable(Config.RearEngines)
    Config.BlacklistedVehicles = HashTable(Config.BlacklistedVehicles)

    while true do
        local ply = PlayerPedId()
        local plyCoords = GetEntityCoords(ply)
        local sleep = 500

        HandleTimers()

        if (shouldDisplayTampering) then
            if ((closestVehicle) and (not IsVehicleBlacklisted(closestVehicle)) and (not IsPedInAnyVehicle(ply, true)) and (not IsVehicleInDisabledClass(closestVehicle))) then
                local isRear = IsVehicleRearEngine(closestVehicle)
                local isMotorcycle = GetVehicleClass(closestVehicle) == 8
                local adjust = isMotorcycle and 0.0 or (isRear and -2.5 or 2.5)
                local tamperLocation = GetOffsetFromEntityInWorldCoords(closestVehicle, 0.0, adjust, 0.0)
                local dst = #(plyCoords - tamperLocation)

                if ((dst < 1) and (GetVehicleEngineHealth(closestVehicle) > 0)) then
                    sleep = 3
                    z.Draw3DText(tamperLocation, Config.Strings.tamper, 0.3)

                    if (IsControlJustReleased(0, 38)) then
                        BurnCar(closestVehicle, isRear)
                    end
                end
            end
        else
            sleep = 1000
        end

        Wait(sleep)
    end
end)

-- Don't touch, this is used to fetch a valid token to authorize requests sent to zyke_gangs' server side
if (Config.Settings.zykeGangs.enabled) then
    function GetToken()
        local p = promise.new()
        z.Callback("zyke_gangs:GetToken", function(res)
            p:resolve(res)
        end)

        return Citizen.Await(p)
    end
end