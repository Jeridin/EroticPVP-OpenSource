fx_version 'cerulean'
game 'gta5'

name "erotic-core"
description "core"
author "Jeridin"
version "1.0.0"

shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/worlds.lua',
    'server/users.lua',
    'server/events.lua',
    'server/queue.lua',
    'server/matches.lua',
    'server/ffa.lua'
}
