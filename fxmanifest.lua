fx_version "cerulean"
game "gta5"
author "discord.gg/zykeresources"
lua54 "yes"
version "1.0.1"

shared_script "@zyke_lib/imports.lua"

files {
    "client.lua",
    "config.lua",

    "locales/*.lua",
}

loader {
    "shared:@ox_lib/init.lua", -- Progressbar
    "shared:config.lua",
    "server.lua",
    "client.lua",
}

dependency "zyke_lib"
dependency "ox_lib"