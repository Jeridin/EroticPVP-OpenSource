import { useState } from "react";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";
import { debugData } from "../../utils/debugData";
import "./LobbyPage.scss";

debugData([{ action: 'showLobbyPage', data: true }]);

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

type PartyMember = {
  id: string;
  username: string;
  level: number;
  isLeader: boolean;
};

const LobbyPage: React.FC<{ visible: boolean }> = ({ visible }) => {
  const [activeTab, setActiveTab] = useState("HQ");
  const [worlds, setWorlds] = useState<World[]>([]);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [partyMembers, setPartyMembers] = useState<PartyMember[]>([
    { id: "1", username: "PlayerOne", level: 85, isLeader: true }
  ]);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [selectedWorld, setSelectedWorld] = useState<World | null>(null);
  const [password, setPassword] = useState("");

  useNuiEvent<World[]>('setWorlds', setWorlds);
  useNuiEvent<UserData>('setUserData', setUserData);

  useNuiEvent<{success: boolean, message: string}>('joinResult', (data) => {
    if (data.success) {
      setShowJoinModal(false);
      setPassword("");
    } else {
      const modal = document.querySelector(".join-modal");
      modal?.classList.remove("shake");
      void (modal as HTMLElement)?.offsetWidth;
      modal?.classList.add("shake");
    }
  });

  const handleJoinClick = (w: World) => {
    setSelectedWorld(w);
    setShowJoinModal(true);
  };

  const confirmJoin = async () => {
    if (!selectedWorld) return;
    
    try {
      await fetchNui("joinWorld", {
        worldId: selectedWorld.id,
        password: selectedWorld.information.passwordProtected ? password : undefined
      });
    } catch (error) {
      console.error('[LobbyPage] Error joining world:', error);
    }
  };

  if (!visible) return null;

  return (
    <div className={`warzone-lobby ${activeTab !== "HQ" ? "has-backdrop" : ""}`}>
      {/* Top Navigation */}
      <header className="top-nav">
        <div className="nav-left">
          <div className="logo">ARENA</div>
        </div>
        
        <div className="nav-center">
          {["HQ", "SERVERS", "STATS", "SHOP", "LOADOUT"].map((tab) => (
            <button
              key={tab}
              className={`nav-tab ${activeTab === tab ? "active" : ""}`}
              onClick={() => setActiveTab(tab)}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="nav-right">
          <div className="stat-badge">
            <span className="icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
                <path fill="currentColor" fillRule="evenodd" d="M7 1h-.414l-.293.293l-3 3L3 4.586v14.828l.293.293l3 3l.293.293h10.828l.293-.293l3-3l.293-.293V4.586l-.293-.293l-3-3L17.414 1zM5 6v12h1V6zm3 15h8v-1H8zm11-3V6h-1v12zM16 3H8v1h8zm0 3v12H8V6z" clipRule="evenodd" />
              </svg>
            </span>
            <span>{userData?.gems ?? 1250}</span>
          </div>
          <div className="stat-badge">
            <span className="icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
                <path fill="currentColor" d="M12 2L9 9l-7 1l5.5 5L6 22l6-3.5l6 3.5l-1.5-7L22 10l-7-1z"/>
              </svg>
            </span>
            <span>{userData?.level ?? 85}</span>
          </div>
          <button className="party-btn">
            <span className="icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24">
                <path fill="currentColor" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3s1.34 3 3 3m-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5S5 6.34 5 8s1.34 3 3 3m0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5m8 0c-.29 0-.62.02-.97.05c1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5"/>
              </svg>
            </span>
            PARTY ({partyMembers.length}/4)
          </button>
          <button className="settings-btn" onClick={() => console.log('Settings clicked')}>
            <span className="icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24">
                <path fill="currentColor" d="M19.14 12.94c.04-.3.06-.61.06-.94c0-.32-.02-.64-.07-.94l2.03-1.58a.49.49 0 0 0 .12-.61l-1.92-3.32a.488.488 0 0 0-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54a.484.484 0 0 0-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58a.49.49 0 0 0-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6s3.6 1.62 3.6 3.6s-1.62 3.6-3.6 3.6"/>
              </svg>
            </span>
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="lobby-main">
        {activeTab === "HQ" ? (
          <>
            {/* HQ View - Squad at bottom center */}
            <div className="hq-view">
              <div className="hq-squad-display">
                {partyMembers.map((member, index) => (
                  <div key={member.id} className="squad-member" style={{ left: `${30 + (index * 15)}%` }}>
                    <div className="member-card">
                      <div className="member-info">
                        <div className="member-name">{member.username}</div>
                        <div className="member-stats">
                          <span className="level">LVL {member.level}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}

                {/* Empty slots */}
                {[...Array(4 - partyMembers.length)].map((_, index) => (
                  <div 
                    key={`empty-${index}`} 
                    className="squad-member empty"
                    style={{ left: `${30 + ((partyMembers.length + index) * 15)}%` }}
                  >
                    <div className="member-card">
                      <div className="empty-slot">+</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Players Info - Right Side */}
            <aside className="hq-players-sidebar">
              <div className="info-panel">
                <div className="panel-header">PROFILE</div>
                <div className="panel-content">
                  <div className="profile-stat">
                    <span>Username:</span>
                    <span>{userData?.username ?? "PlayerOne"}</span>
                  </div>
                  <div className="profile-stat">
                    <span>Level:</span>
                    <span>{userData?.level ?? 85}</span>
                  </div>
                  <div className="profile-stat">
                    <span>XP:</span>
                    <span>{userData?.xp ?? 12450}</span>
                  </div>
                  <div className="profile-stat">
                    <span>Gems:</span>
                    <span>{userData?.gems ?? 1250}</span>
                  </div>
                </div>
              </div>

              <div className="info-panel">
                <div className="panel-header">PARTY MEMBERS</div>
                <div className="panel-content">
                  {partyMembers.map((member) => (
                    <div key={member.id} className="party-member-item">
                      <div className="member-name">{member.username}</div>
                      <div className="member-level">LVL {member.level}</div>
                    </div>
                  ))}
                  {partyMembers.length < 4 && (
                    <div className="empty-party-slots">
                      {4 - partyMembers.length} EMPTY SLOT{4 - partyMembers.length > 1 ? 'S' : ''}
                    </div>
                  )}
                </div>
              </div>
            </aside>
          </>
        ) : activeTab === "SERVERS" ? (
          <>
            {/* Server Browser View - ONLY SERVER LIST */}
            <div className="servers-view">
              <div className="servers-header">
                <h2>AVAILABLE SERVERS</h2>
                <div className="server-count">{worlds.length} ONLINE</div>
              </div>

              <div className="servers-grid">
                {worlds.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">🎮</div>
                    <div className="empty-text">NO SERVERS AVAILABLE</div>
                  </div>
                ) : (
                  worlds.map((world) => (
                    <div
                      key={world.id}
                      className="server-card-large"
                      onClick={() => handleJoinClick(world)}
                    >
                      <div className="server-card-header">
                        <h3>{world.information.name}</h3>
                        {world.information.passwordProtected && (
                          <span className="lock-icon">🔒</span>
                        )}
                      </div>
                      <div className="server-card-body">
                        <div className="server-stat">
                          <span className="label">PLAYERS</span>
                          <span className="value">{world.playerCount}/{world.information.maxPlayers ?? 100}</span>
                        </div>
                        <div className="server-stat">
                          <span className="label">MODE</span>
                          <span className="value">{world.information.gamemode.toUpperCase()}</span>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </>
        ) : activeTab === "STATS" || activeTab === "SHOP" || activeTab === "LOADOUT" ? (
          <div className="coming-soon">
            <h2>{activeTab}</h2>
            <p>COMING SOON</p>
          </div>
        ) : (
          <div className="coming-soon">
            <h2>{activeTab}</h2>
            <p>COMING SOON</p>
          </div>
        )}
      </main>

      {/* Join Modal */}
      {showJoinModal && (
        <div className="modal-overlay" onClick={() => setShowJoinModal(false)}>
          <div className="join-modal" onClick={(e) => e.stopPropagation()}>
            <h3>JOIN SERVER</h3>
            <div className="modal-server-name">{selectedWorld?.information.name}</div>
            {selectedWorld?.information.passwordProtected && (
              <input
                type="password"
                placeholder="ENTER PASSWORD"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            )}
            <div className="modal-actions">
              <button className="btn-primary" onClick={confirmJoin}>CONNECT</button>
              <button className="btn-secondary" onClick={() => setShowJoinModal(false)}>CANCEL</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LobbyPage;