return {
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