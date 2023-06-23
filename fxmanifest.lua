fx_version "cerulean"
game "gta5"
author "Zyke#0001 / realzyke"
lua54 "yes"

shared_scripts {
    "shared/config.lua"
}

server_scripts {
    "server/webhooks.lua",
    "server/main.lua",
}

client_scripts {
    "client/main.lua",
}

dependencies {
    "zyke_lib",
}