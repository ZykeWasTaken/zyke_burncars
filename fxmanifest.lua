fx_version "cerulean"
game "gta5"
author "discord.gg/zykeresources"
lua54 "yes"
version "1.0.1"

shared_script {
    "@zyke_lib/imports.lua",
    "@ox_lib/init.lua", -- Progressbar
    "config.lua"
}

server_script "server.lua"
client_script "client.lua"
file "locales/*.lua"

dependency "zyke_lib"