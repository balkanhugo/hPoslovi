fx_version 'cerulean'
game 'gta5'
description 'original script by nxs-dev'
author 'vibe coded by Chiaroscuric'
version '1.0.1'

client_scripts {
    '@ox_lib/init.lua',
    'client/marker.lua',
    'client/main.lua'
}

shared_scripts {
    'config/*.*',
    '@ox_lib/init.lua',
    '@es_extended/imports.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'locales/*.json'

}

