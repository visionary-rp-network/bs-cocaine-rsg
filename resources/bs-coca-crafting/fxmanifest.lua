fx_version 'cerulean'
game 'rdr3'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
author 'Broken Spur; RSG Team (upstream crafting base)'
version '0.1.0'
shared_scripts {'@rsg-core/shared/locale.lua','shared/config.lua'}
client_scripts {'@ox_lib/init.lua','client/client.lua'}
server_scripts {'server/sv_config.lua','server/webhook.lua','server/stations.lua','server/recipes.lua','server/server.lua','server/placement.lua'}
ui_page 'html/index.html'
files {'html/index.html','html/script.js','html/style.css','locales/*.json'}
dependencies {'rsg-core','rsg-inventory','ox_lib'}
