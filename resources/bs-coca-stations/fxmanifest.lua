-- Custom scripts: Visionary RP Network (VRP) | Broken Spur project | sovereign_rp. Original upstream credits and licenses retained.
fx_version 'cerulean'
game 'rdr3'
lua54 'yes'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Visionary RP Network (VRP) | Broken Spur project | sovereign_rp'
description 'Hidden crafting station location preview and interaction'
version '0.1.0'

server_scripts {'config.lua','server.lua'}
client_script 'client.lua'

dependencies {
    'rsg-core',
    'rsg-target',
    'bs-coca-crafting',
}

-- Server-only brand banner; printed once per resource start.
server_script 'branding.lua'
