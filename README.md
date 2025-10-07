<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/290db11b-45a9-4218-bd71-fcbfebd2a44e" />

# Erotic Core — Arena Framework

A lightweight modular **arena & gamemode framework** for FiveM.  
It provides **persistent worlds**, **matchmaking**, and **gamemode logic** with a clean separation of **server** and **client** responsibilities.

---

## 🚀 Features

- **Dynamic Worlds** — Predefined arenas (FFA, Duels, Practice, Freemode) or create new ones dynamically.
- **Player Routing Buckets** — Automatic isolation of each world.
- **Gamemodes** — Each world can have its own game logic (e.g., FFA with random spawns & respawns).
- **Live Player Tracking** — Server keeps `players` table per world up to date.
- **Respawn System** — Gamemodes can fully control how/where players spawn or respawn.
- **Extendable** — Add new worlds, gamemodes, and rules without rewriting the core.

---

## 🏗️ Architecture

```
resources/
└── erotic-core/
    ├── server/
    │   ├── sv_worlds.lua     ← main world manager
    │   └── sv_ffa.lua        ← FFA specific spawn/respawn logic
    ├── client/
    │   └── cl_ffa.lua        ← client FFA respawn handling
    └── fxmanifest.lua
```

### Key Concepts

- **World** — A match instance with:
  - Unique `id` & `bucket`
  - `name` & `gamemode` type
  - `settings` (recoil, headshots, etc.)
  - `spawns` array of {x, y, z, h}
  - `players` table tracking who’s inside

- **Gamemode** — The rule set of a world (`ffa`, `duel`, `practice`, `freemode`).  
  Each gamemode can hook into world events like player join, respawn, etc.

---

## 🔑 Server Flow

1. **Joining a World**
   ```lua
   TriggerEvent("erotic-core:joinWorld", playerId, worldId)
   ```
   - Removes player from any existing world
   - Moves them into the world’s routing bucket
   - Sends world settings & gamemode to the client
   - Fires gamemode events (e.g., FFA spawns the player)

2. **Player Dropped**
   - Automatically removes them from the world’s `players` list.
   - Destroys empty dynamically created worlds.

---

## 🎮 Client Flow

- Receives **`applyGameSettings`** & **`worldJoined`** when joining.
- Gamemode code (e.g., `cl_ffa.lua`) handles spawn & respawn behavior.
- FFA:
  - Server sends first spawn (`spawnAt`).
  - Client watches death state and respawns locally using the same spawn pool.

---

## 🛠️ Commands

| Command            | Description                                                |
|--------------------|------------------------------------------------------------|
| `/listworlds`       | Shows all current worlds and player counts.               |
| `/joinworld <id>`   | Join an existing world by its numeric ID.                  |
| `/createworld`      | Create a quick custom world (for testing/development).     |

---
<img width="1919" height="1079" alt="image" src="https://github.com/user-attachments/assets/253d0118-69ca-40a5-84bf-91db352dd689" />
![Uploading image.png…]()


## 🧩 Extending the Framework

- **Add New Gamemode**
  - Create a new server file `sv_<gamemode>.lua`.
  - Hook into the event:  
    ```lua
    AddEventHandler("erotic-core:serverJoinedWorld", function(src, worldId)
        local world = core.worlds[worldId]
        if world.gamemode ~= "mynewmode" then return end
        -- spawn/respawn logic here
    end)
    ```
  - Add client logic in `cl_<gamemode>.lua` if needed.

- **Add New Predefined Worlds**
  - Edit `sv_worlds.lua` and append to `core.worlds`:
    ```lua
    [6] = {
        id = 6,
        bucket = 6,
        name = "Sniper Duel",
        gamemode = "duel",
        settings = {recoil="sniper", headshots=true, helmets=false},
        spawns = { {x=100, y=200, z=30, h=90}, {x=110, y=210, z=30, h=270} },
        players = {}
    }
    ```

---

## ⚡ Developer Notes

- **Buckets** isolate players so they only interact inside their world.
- **Players cleanup** is automatic when they leave or disconnect.
- **Gamemode logic** should live outside `sv_worlds.lua` to keep the core clean.
- **Client is minimal** — only handles spawn/respawn and applying settings.
