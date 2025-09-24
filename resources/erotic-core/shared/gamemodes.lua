core = core or {}

core.gamemodeSettings = {
    lobby = {
        blips       = false,
        respawn     = true,
        locals      = false,    -- let people see traffic/NPCs in the lobby
        headshots   = false,
        helmets     = false,
        ragdoll     = false,
        spawningcars= false,
        world       = {
            type    = "static",
            bucket  = 0,
            capacity= nil,
            name    = "Lobby"
        }
    },

    ffa = {
        blips       = true,
        blipInterval= 3000,
        recoil = "pma",
        respawn     = true,
        locals      = false,
        headshots   = false,
        helmets     = false,
        ragdoll     = false,
        spawningcars= false,
        bucket      = 1000,
        spawns      = {
            vector4(90.0182, -1966.9272, 20.7473, 142.1477),
            vector4(85.7977, -1949.3544, 20.8465, 93.8788),
        },
        world       = {
            type     = "static",
            bucket   = 1000,
            capacity = 48,
            name     = "Global FFA"
        }
    },

    duel = {
        blips       = true,
        blipInterval= 3000,
        respawn     = false,
        locals      = false,
        headshots   = true,
        helmets     = false,
        ragdoll     = false,
        spawningcars= false,
        roundsToWin = 3,
        world       = {
            type     = "match",
            capacity = 2,
            queue    = true,
            name     = "1v1 Duel"
        }
    },

    ranked4v4 = {
        blips       = true,
        blipInterval= 5000,
        respawn     = false,
        locals      = false,
        headshots   = true,
        helmets     = false,
        ragdoll     = false,
        spawningcars= false,
        skeletons   = false,
        roundsToWin = 5,
        teamSpawns  = {
            A = {
                vector4(90.0, -1960.0, 20.7, 140.0),
                vector4(92.0, -1962.0, 20.7, 140.0),
                vector4(94.0, -1964.0, 20.7, 140.0),
                vector4(96.0, -1966.0, 20.7, 140.0),
            },
            B = {
                vector4(85.7, -1950.0, 20.8, 94.0),
                vector4(83.7, -1952.0, 20.8, 94.0),
                vector4(81.7, -1954.0, 20.8, 94.0),
                vector4(79.7, -1956.0, 20.8, 94.0),
            }
        },
        world       = {
            type     = "match",
            capacity = 8,
            queue    = true,
            name     = "Ranked 4v4"
        }
    },

    custom = {
        blips        = false,
        respawn      = false,
        locals       = false,
        headshots    = true,
        helmets      = false,
        ragdoll      = false,
        spawningcars = false,
        defaultSpawn = vector4(-1598.15, -3011.45, -78.25, 355.0),
        world        = {
            type      = "personal",
            capacity  = 12,
            name      = "Personal Arena"
        }
    }
}
