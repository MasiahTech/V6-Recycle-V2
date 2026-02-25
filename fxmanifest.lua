fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Onecitgo'
description 'Recycle System - Collect boxes and trade materials'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/nui.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
