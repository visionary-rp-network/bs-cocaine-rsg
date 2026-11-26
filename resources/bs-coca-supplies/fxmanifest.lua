-- Custom scripts: Visionary RP Network (VRP) | Broken Spur project | sovereign_rp. Original upstream credits and licenses retained.
fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'bs-coca-supplies'
author 'Visionary RP Network (VRP) | Broken Spur project | sovereign_rp'
description 'Admin-placed gathering, searching, and custom interaction points for Broken Spur.'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'rsg-core'
}

-- Server-only brand banner; printed once per resource start.
server_script 'branding.lua'
