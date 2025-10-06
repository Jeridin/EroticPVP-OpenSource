import { useState } from "react";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";

interface LobbyPageProps {
  visible: boolean;
}

type World = {
  id: number;
  bucket: number;
  information: {
    name: string;
    gamemode: string;
    tags?: string[];
    maxPlayers?: number;
    passwordProtected?: boolean;
    password?: string;
  };
  playerCount: number;
};

type UserData = {
  id: number;
  arena_id: number;
  username: string;
  steam: string;
  level: number;
  xp: number;
  gems: number;
};

export default function LobbyPage({ visible }: LobbyPageProps) {
  const [activeTab, setActiveTab] = useState("Servers");
  const [worlds, setWorlds] = useState<World[]>([]);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [selectedWorld, setSelectedWorld] = useState<World | null>(null);
  const [password, setPassword] = useState("");
  const [showCustomModal, setShowCustomModal] = useState(false);
  const [customName, setCustomName] = useState("");
  const [customMax, setCustomMax] = useState(10);
  const [customPwProtected, setCustomPwProtected] = useState(false);
  const [customPw, setCustomPw] = useState("");
  const [customGamemode, setCustomGamemode] = useState("ffa");

  // Listen for worlds data from Lua
  useNuiEvent<World[]>('setWorldsData', (data) => {
    console.log('[LobbyPage] Received worlds data:', data);
    setWorlds(data);
  });

  // Listen for user data from Lua
  useNuiEvent<UserData>('setUserData', (data) => {
    console.log('[LobbyPage] Received user data:', data);
    setUserData(data);
  });

  // Listen for join results
  useNuiEvent<{success: boolean, message: string}>('joinResult', (data) => {
    console.log('[LobbyPage] Join result:', data);
    if (data.success) {
      console.log('[LobbyPage] Join successful, closing modal');
      setShowJoinModal(false);
      setPassword("");
    } else {
      console.log('[LobbyPage] Join failed:', data.message);
      const modal = document.querySelector(".custom-modal");
      modal?.classList.remove("shake");
      void (modal as HTMLElement)?.offsetWidth;
      modal?.classList.add("shake");
    }
  });

  const handleJoinClick = (w: World) => {
    console.log('[LobbyPage] Opening join modal for world:', w);
    setSelectedWorld(w);
    setShowJoinModal(true);
  };

  const confirmJoin = async () => {
    if (!selectedWorld) {
      console.log('[LobbyPage] No world selected');
      return;
    }
    
    console.log('[LobbyPage] Attempting to join world:', {
      worldId: selectedWorld.id,
      hasPassword: !!password,
      isProtected: selectedWorld.information.passwordProtected
    });

    try {
      const result = await fetchNui("joinWorld", {
        worldId: selectedWorld.id,
        password: selectedWorld.information.passwordProtected ? password : undefined
      });
      console.log('[LobbyPage] fetchNui joinWorld result:', result);
    } catch (error) {
      console.error('[LobbyPage] Error joining world:', error);
    }
  };

  const confirmCreate = async () => {
    console.log('[LobbyPage] Creating custom world:', {
      name: customName,
      gamemode: customGamemode,
      maxPlayers: customMax,
      passwordProtected: customPwProtected
    });

    try {
      const result = await fetchNui("createWorld", {
        name: customName,
        gamemode: customGamemode,
        maxPlayers: customMax,
        passwordProtected: customPwProtected,
        password: customPwProtected ? customPw : undefined
      });
      console.log('[LobbyPage] fetchNui createWorld result:', result);
      
      setShowCustomModal(false);
      setCustomName("");
      setCustomMax(10);
      setCustomPwProtected(false);
      setCustomPw("");
      setCustomGamemode("ffa");
    } catch (error) {
      console.error('[LobbyPage] Error creating world:', error);
    }
  };

  const getPlayerCount = (world: World) => {
    return world.playerCount || 0;
  };

  if (!visible) {
    console.log('[LobbyPage] Not visible, not rendering');
    return null;
  }

  console.log('[LobbyPage] Rendering with', worlds.length, 'worlds');

  return (
    <>
      <style>{`
        .app-shell { 
          box-sizing: border-box;
          display: flex; 
          flex-direction: column; 
          height: 100vh;
          width: 100vw;
          background: linear-gradient(rgba(0,0,0,.85), rgba(0,0,0,.7)), #111;
          color: #fff;
          font-family: system-ui, -apple-system, sans-serif;
          text-transform: uppercase;
          overflow: hidden;
          position: fixed;
          top: 0;
          left: 0;
        }
        
        .app-shell *::-webkit-scrollbar { display: none; }
        .app-shell * { scrollbar-width: none; }

        .avatar { transform: scale(1.3); }
        .avatar svg {
          border-radius: 50%;
          color: rgba(0,255,0,.54);
          box-shadow: 0 0 8px rgba(0,255,0,.7);
        }

        .app-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: .8rem 2rem;
          background: rgba(12,12,14,.6);
          border-bottom: 1px solid rgba(255,255,255,.05);
          backdrop-filter: blur(10px);
        }

        .main-nav ul { display: flex; list-style: none; gap: 10px; }

        .nav-link {
          padding: 12px 28px;
          background: #1a1a1c;
          color: #aaa;
          font-size: 13px;
          font-weight: 700;
          border: none;
          cursor: pointer;
          text-transform: uppercase;
          transition: .25s;
          backdrop-filter: blur(8px);
          box-shadow: inset 0 0 6px rgba(0,255,0,.1), 0 3px 6px rgba(0,0,0,.3);
        }
        .left-shape {
          clip-path: polygon(16px 0%, calc(100% - 16px) 0%, 75% 50%, calc(100% - 16px) 100%, 16px 100%, 0% 50%);
        }
        .right-shape {
          clip-path: polygon(25% 0%, calc(100% - 16px) 0%, 100% 50%, calc(100% - 16px) 100%, 25% 100%, 0% 50%);
        }

        .nav-link:hover {
          background: #262626;
          color: #8aff8a;
          box-shadow: 0 0 8px rgba(0,255,0,.3);
        }
        .nav-link.active {
          background: #00ff00;
          color: #000;
          box-shadow: 0 0 10px #00ff00;
        }

        .logo {
          font-size: 20px;
          font-weight: bold;
          color: #8aff8a;
          text-shadow: 0 0 6px rgba(0,255,0,.3);
          padding: 12px 28px;
          background: #1a1a1c;
          clip-path: polygon(16px 0%, calc(100% - 16px) 0%, 100% 50%, calc(100% - 16px) 100%, 16px 100%, 0% 50%);
        }

        .user-actions { display: flex; align-items: center; gap: 15px; }
        .gems, .notifications {
          font-size: 12px;
          color: #0f0;
          padding: 5px 10px;
          border-radius: 8px;
          background: rgba(0,255,0,.05);
        }

        main { display: flex; flex: 1; gap: 1em; padding: 2%; overflow: hidden; }
        .view-section {
          flex: 1; display: flex; flex-direction: column; gap: 12px;
          background: rgba(255,255,255,.03);
          border-radius: 12px; backdrop-filter: blur(10px);
          padding: 2em; margin-left: 8em; min-width: 0;
        }
        .view-header { display: flex; justify-content: space-between; align-items: center; }
        .view-header h2 { color: #0f0; }
        .servers-scroll {
          flex: 1; overflow-y: auto;
          border: 1px solid rgba(255,255,255,.05);
          border-radius: 8px;
          background: rgba(255,255,255,.02);
        }

        .servers-table { width: 100%; border-collapse: collapse; }
        .servers-table th, .servers-table td {
          padding: 1rem; text-align: left;
          border-bottom: 1px solid rgba(255,255,255,.05);
        }
        .servers-table thead th {
          position: sticky; top: 0; z-index: 1;
          background: rgba(34,34,34,.5);
          backdrop-filter: blur(6px);
          color: #aaa;
        }
        .servers-table tbody tr { transition: background .25s; cursor: pointer; }
        .servers-table tbody tr:hover { background: rgba(0,255,0,.08); }

        .queue-btn {
          padding: 8px 18px;
          background: rgba(0,255,0,.05);
          color: #0f0;
          border: 2px solid rgba(0,255,0,.15);
          font-weight: bold;
          cursor: pointer;
          transition: .25s;
          box-shadow: 0 0 4px rgba(0,255,0,.5);
          border-radius: 4px;
        }
        .queue-btn:hover {
          box-shadow: 0 0 1rem #0f0;
          border: 2px solid rgba(0,255,0,.7);
        }
        .queue-btn.outline { background: transparent; color: #0f0; }

        .sidebar {
          width: 280px; background: rgba(255,255,255,.03);
          border-radius: 12px; backdrop-filter: blur(10px);
          padding: 20px; margin-right: 8em; overflow: hidden;
        }
        .profile-section { background: rgba(255,255,255,.02); border-radius: 10px; padding: 15px; }
        .profile-section h3 { color: #0f0; margin-bottom: 15px; }
        .user-info { display: flex; align-items: center; gap: 10px; }
        .username { font-weight: bold; }
        .rank { font-size: 10px; color: #aaa; }

        .custom-modal-overlay {
          position: fixed; inset: 0;
          background: rgba(0,0,0,.4);
          backdrop-filter: blur(8px);
          display: flex; justify-content: center; align-items: center;
          z-index: 500;
        }
        .custom-modal {
          background: rgba(20,20,22,.95);
          border: 1px solid rgba(0,255,0,.3);
          padding: 20px; border-radius: 12px;
          max-width: 400px; width: 90%;
          animation: fadeIn .25s;
        }
        .custom-modal h3 { margin-bottom: 12px; color: #0f0; }
        .custom-modal input, .custom-modal select {
          width: 100%; padding: 8px; margin-bottom: 8px;
          background: rgba(255,255,255,.03);
          color: #fff;
          border: 1px solid rgba(255,255,255,.08);
          border-radius: 6px;
          font-family: inherit;
          text-transform: inherit;
        }
        .custom-modal input::placeholder {
          color: rgba(255,255,255,.4);
        }
        .modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 16px; }

        @keyframes fadeIn {
          from { opacity: 0; transform: scale(.95); }
          to { opacity: 1; transform: scale(1); }
        }

        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-10px); }
          75% { transform: translateX(10px); }
        }
        .shake { animation: shake 0.3s; }

        @media (max-width: 900px) {
          main { flex-direction: column; }
          .sidebar { width: 100%; height: auto; }
          .servers-scroll { max-height: 50vh; }
        }
      `}</style>

      <div className="app-shell">
        <header className="app-header">
          <nav className="main-nav left">
            <ul>
              {["Servers", "Profile"].map((tab) => (
                <li key={tab}>
                  <button
                    className={`nav-link left-shape ${activeTab === tab ? "active" : ""}`}
                    onClick={() => setActiveTab(tab)}
                  >
                    {tab}
                  </button>
                </li>
              ))}
            </ul>
          </nav>

          <div className="logo">
            ARENA <span>Lobby</span>
          </div>

          <nav className="main-nav right">
            <ul>
              {["Shop", "Settings"].map((tab) => (
                <li key={tab}>
                  <button
                    className={`nav-link right-shape ${activeTab === tab ? "active" : ""}`}
                    onClick={() => setActiveTab(tab)}
                  >
                    {tab}
                  </button>
                </li>
              ))}
            </ul>
          </nav>

          <div className="user-actions">
            <div className="gems">Gems: {userData?.gems ?? 0}</div>
            <div className="notifications">Alerts</div>
            <div className="avatar">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
                <path
                  fill="currentColor"
                  d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10s10-4.48 10-10S17.52 2 12 2m0 4c1.93 0 3.5 1.57 3.5 3.5S13.93 13 12 13s-3.5-1.57-3.5-3.5S10.07 6 12 6m0 14c-2.03 0-4.43-.82-6.14-2.88a9.95 9.95 0 0 1 12.28 0C16.43 19.18 14.03 20 12 20"
                />
              </svg>
            </div>
          </div>
        </header>

        <main>
          {activeTab === "Servers" && (
            <section className="view-section">
              <div className="view-header">
                <h2>Available Servers</h2>
                <button className="queue-btn" onClick={() => {
                  console.log('[LobbyPage] Create custom mode clicked');
                  setShowCustomModal(true);
                }}>
                  + Create Custom Mode
                </button>
              </div>
              <div className="servers-scroll">
                <table className="servers-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Gamemode</th>
                      <th>Players</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {worlds.length === 0 ? (
                      <tr>
                        <td colSpan={4} style={{ textAlign: 'center', padding: '2rem', color: '#666' }}>
                          No worlds available
                        </td>
                      </tr>
                    ) : (
                      worlds.map((w) => (
                        <tr
                          key={w.id}
                          onClick={(e) => {
                            if ((e.target as HTMLElement).closest("button")) return;
                            handleJoinClick(w);
                          }}
                        >
                          <td>{w.information.name}</td>
                          <td>{w.information.gamemode}</td>
                          <td>{getPlayerCount(w)}/{w.information.maxPlayers ?? "∞"}</td>
                          <td>
                            <button className="queue-btn" onClick={() => handleJoinClick(w)}>
                              CONNECT
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </section>
          )}

          {activeTab === "Profile" && (
            <section className="view-section">
              <h2>Profile</h2>
              <div style={{ padding: '1rem' }}>
                <p>Username: {userData?.username ?? "Loading..."}</p>
                <p>Arena ID: {userData?.arena_id ?? "Loading..."}</p>
                <p>Level: {userData?.level ?? 1}</p>
                <p>XP: {userData?.xp ?? 0}</p>
                <p>Gems: {userData?.gems ?? 0}</p>
              </div>
            </section>
          )}
          {activeTab === "Shop" && (
            <section className="view-section">
              <h2>Shop</h2>
              <p>Buy skins, gems, and more.</p>
            </section>
          )}
          {activeTab === "Settings" && (
            <section className="view-section">
              <h2>Settings</h2>
              <p>Adjust game options and controls.</p>
            </section>
          )}

          <aside className="sidebar">
            <div className="profile-section">
              <h3>Profile</h3>
              <div className="user-info">
                <div className="avatar">
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
                    <path
                      fill="currentColor"
                      d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10s10-4.48 10-10S17.52 2 12 2m0 4c1.93 0 3.5 1.57 3.5 3.5S13.93 13 12 13s-3.5-1.57-3.5-3.5S10.07 6 12 6m0 14c-2.03 0-4.43-.82-6.14-2.88a9.95 9.95 0 0 1 12.28 0C16.43 19.18 14.03 20 12 20"
                    />
                  </svg>
                </div>
                <div>
                  <div className="username">{userData?.username ?? "PlayerOne"}</div>
                  <div className="rank">Level {userData?.level ?? 1}</div>
                </div>
              </div>
            </div>
          </aside>
        </main>

        {showJoinModal && (
          <div className="custom-modal-overlay" onClick={() => setShowJoinModal(false)}>
            <div className="custom-modal" onClick={(e) => e.stopPropagation()}>
              <h3>Join {selectedWorld?.information.name}</h3>
              {selectedWorld?.information.passwordProtected && (
                <input
                  type="password"
                  placeholder="Enter password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              )}
              <div className="modal-actions">
                <button className="queue-btn" onClick={confirmJoin}>CONNECT</button>
                <button className="queue-btn outline" onClick={() => setShowJoinModal(false)}>Cancel</button>
              </div>
            </div>
          </div>
        )}

        {showCustomModal && (
          <div className="custom-modal-overlay" onClick={() => setShowCustomModal(false)}>
            <div className="custom-modal" onClick={(e) => e.stopPropagation()}>
              <h3>Create Custom Mode</h3>
              <input
                type="text"
                placeholder="Lobby Name"
                value={customName}
                onChange={(e) => setCustomName(e.target.value)}
              />
              <input
                type="number"
                placeholder="Max Players"
                value={customMax}
                min={2}
                max={64}
                onChange={(e) => setCustomMax(Number(e.target.value))}
              />
              <select value={customGamemode} onChange={(e) => setCustomGamemode(e.target.value)}>
                <option value="ffa">FFA</option>
                <option value="freemode">Freemode</option>
                <option value="duel">Duel</option>
              </select>
              <label style={{ display: "flex", gap: "6px", alignItems: "center", marginTop: "8px" }}>
                <input
                  type="checkbox"
                  checked={customPwProtected}
                  onChange={(e) => setCustomPwProtected(e.target.checked)}
                />
                Password Protected
              </label>
              {customPwProtected && (
                <input
                  type="password"
                  placeholder="Set password"
                  value={customPw}
                  onChange={(e) => setCustomPw(e.target.value)}
                />
              )}
              <div className="modal-actions">
                <button className="queue-btn" onClick={confirmCreate}>Create</button>
                <button className="queue-btn outline" onClick={() => setShowCustomModal(false)}>Cancel</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
}