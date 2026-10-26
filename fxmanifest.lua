fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'pure_clothing'
author 'ma3iich'
version '1.0.0'
repository 'https://github.com/ma3iich/pure_clothing'
description 'Clothing shops that sell clothes as items, wear / take off with clean underwear. Standalone or with the Pure suite.'

dependencies {
    '/server:6116',
    'oxmysql',
}

shared_scripts {
    'config.lua',
    'shared/collections_gta.lua',
    'shared/common.lua',
}

client_scripts {
    'client/common.lua',
    'client/camera.lua',
    'client/shop.lua',
    'client/wear.lua',
    'client/preview.lua',
    'client/target.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge/inventory.lua',
    'server/bridge/framework.lua',
    'server/shop.lua',
    'server/wear.lua',
    'server/version.lua',
}

ui_page 'web/index.html'

files {
    'locales/*.json',
    'web/index.html',
    'web/menu.css',
    'web/menu.js',
    'web/*.svg',
    'web/*.png',
    'web/*.jpg',
    'web/*.webp',
    'web/miniatures/index.json',
    'web/miniatures/**/*.webp',
}
