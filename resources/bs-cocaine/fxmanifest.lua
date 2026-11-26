-- Custom scripts: Visionary RP Network (VRP) | Broken Spur project | sovereign_rp. Original upstream credits and licenses retained.
fx_version 'cerulean'
game 'rdr3'
lua54 'yes'

author 'Visionary RP Network (VRP) | Broken Spur project | sovereign_rp'
description 'Coca harvesting, crafting and NPC sales'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'rsg-core',
    'rsg-inventory', 'rsg-target'
}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'