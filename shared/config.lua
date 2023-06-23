Config = Config or {}

Config.Settings = {
    zykeGangs = {
        -- When using zyke_gangs (A script that is not yet released), this configuration will allow you to handle grid loyalty upon stabbing wheels, as well as requirements such as being inside someone's grid to stab
        -- Note that the option to tamper with the vehicle will not appear unless the requirements below are met
        enabled = false,
        hasToBeInGang = true, -- Has to be in a gang to tamper with engines
        hasToBeInGrid = true, -- Has to be inside of a gang owned grid (gang territory) to tamper with engines
    },
    requirements = {
        -- "Tamper" will be visible even if these are not met, you'll just get a notification if you fail to meet these requirements
        emptyVehicle = true, -- Vehicle has to be empty in order to start the fire
        vehicleOff = true, -- Vehicle has to be off in order to start the fire
    },
    itemsNeeded = {
        {name = "lighter", amount = 1, remove = false},
        {name = "lighter_fluid", amount = 1, remove = true},
    },
    cooldown = 900, -- In seconds, how long before someone can burn the same vehicle (If it has been repaired) and reap the rewards again
    disabledClasses = {
        [13] = true, -- Bicycles
        [21] = true, -- Trains
    }
}

-- You can't set these vehicles on fire
Config.BlacklistedVehicles = {
    "police",
    "police2",
    "police3",
    "police4",
    "policeb",
    "policet",
    "sheriff",
    "sheriff2",
    "fbi",
    "fbi2",
    "pranger",
    "ambulance",
    "firetruk",
    "riot",
    "riot2",
    "barracks",
    "barracks2",
    "barracks3",
    "crusader",
    "rhino",
}

-- These vehicles will have to be tampered with from the rear, as far as I know there is no native to check this, so you have to add them manually
-- Credit to https://github.com/qbcore-framework/qb-vehiclefailure for the list
Config.RearEngines = {
    "ninef",
    "adder",
    "vagner",
    "t20",
    "infernus",
    "zentorno",
    "reaper",
    "comet2",
    "jester",
    "jester2",
    "cheetah",
    "cheetah2",
    "prototipo",
    "turismor",
    "pfister811",
    "ardent",
    "nero",
    "nero2",
    "tempesta",
    "vacca",
    "bullet",
    "osiris",
    "entityxf",
    "turismo2",
    "fmj",
    "re7b",
    "tyrus",
    "italigtb",
    "penetrator",
    "monroe",
    "ninef2",
    "stingergt",
    "surfer",
    "surfer2",
    "comet3",
    "xa21"
}

Config.Strings = {
    -- Notifications
    ["emptyVehicleFailed"] = {msg = "You'll get caught if you do this, make sure to only tamper with unmanned vehicles.", type = "error"}, -- Config.Settings.requirements
    ["vehicleOffFailed"] = {msg = "The vehicle has to be off, otherwise you'll burn yourself.", type = "error"}, -- Config.Settings.requirements
    ["vehicleIsMoving"] = {msg = "You can't do this while the vehicle is moving, you need to work undisturbed to avoid accidents.", type = "error"}, -- Universal requirement
    ["alreadyReserved"] = {msg = "Someone is already tampering with this vehicle.", type = "error"},
    ["tamperedwithVehicle"] = {msg = "You tampered with the engine, keep your distance.", type = "success"},
    ["missingItem"] = {msg = "You're missing items, you need: %s.", type = "error"},

    -- Misc
    ["tamper"] = "~g~[E] ~w~Tamper",
    ["tamperingWithCar"] = "Tampering with the engine",
}