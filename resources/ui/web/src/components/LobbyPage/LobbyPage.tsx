import { useState } from "react";
import { useNuiEvent } from "../../hooks/useNuiEvent";
import { fetchNui } from "../../utils/fetchNui";
import { debugData } from "../../utils/debugData";
import "./LobbyPage.scss";

debugData([{ action: "showLobbyPage", data: true }]);

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
  avatarUrl?: string;
  rank?: "copper" | "silver" | "gold" | "diamond" | "ruby";
  tier?: number;
};

type PartyMember = {
  id: string;
  username: string;
  level: number;
  isLeader: boolean;
  avatarUrl?: string;
};

const LobbyPage: React.FC<{ visible: boolean }> = ({ visible }) => {
  const [activeTab, setActiveTab] = useState("HQ");
  const [worlds, setWorlds] = useState<World[]>([]);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [partyMembers, setPartyMembers] = useState<PartyMember[]>([]);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [selectedWorld, setSelectedWorld] = useState<World | null>(null);
  const [password, setPassword] = useState("");
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [friendsList, setFriendsList] = useState<{id: string, username: string, status: 'online' | 'offline' | 'ingame'}[]>([]);
  const [showAddFriendModal, setShowAddFriendModal] = useState(false);
  const [copied, setCopied] = useState(false);

  // XP Calculation
  const currentXP = userData?.xp ?? 14600;
  const currentLevel = userData?.level ?? 5;
  const nextLevelXP = Math.floor(1000 * Math.pow(1.5, currentLevel)); // Dynamic XP scaling
  const progress = Math.min((currentXP / nextLevelXP) * 100, 100);

  useNuiEvent<World[]>("setWorldsData", (worldsData) => {
    console.log("[LobbyPage] Received worlds data:", worldsData);
    setWorlds(worldsData);
  });

  useNuiEvent<UserData>("setUserData", (data) => {
    setUserData(data);
    if (partyMembers.length === 0) {
      setPartyMembers([
        {
          id: data.id.toString(),
          username: data.username,
          level: data.level,
          isLeader: true,
          avatarUrl: data.avatarUrl,
        },
      ]);
    }
  });

  useNuiEvent<PartyMember[]>("setPartyMembers", setPartyMembers);

  useNuiEvent<any[]>("setFriendsList", (friends) => {
    setFriendsList(friends);
  });

  useNuiEvent<{ success: boolean; message: string }>("joinResult", (data) => {
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
        password: selectedWorld.information.passwordProtected
          ? password
          : undefined,
      });
    } catch (error) {
      console.error("[LobbyPage] Error joining world:", error);
    }
  };

  const handleInviteClick = () => {
    setShowInviteModal(true);
  };

  const sendInvite = async (playerName: string) => {
    try {
      await fetchNui("inviteToParty", { playerName });
      setShowInviteModal(false);
    } catch (error) {
      console.error("[LobbyPage] Error inviting player:", error);
    }
  };

const copyArenaId = () => {
  if (!userData?.arena_id) return;
  const textToCopy = `${userData.arena_id}`;

  // Try modern API
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(textToCopy)
      .then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      })
      .catch(() => fallbackCopy(textToCopy));
  } else {
    fallbackCopy(textToCopy);
  }
};

const fallbackCopy = (text: string) => {
  const textArea = document.createElement("textarea");
  textArea.value = text;
  textArea.style.position = "fixed";
  textArea.style.opacity = "0";
  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();
  try {
    document.execCommand("copy");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  } catch (err) {
    console.error("Fallback copy failed:", err);
  }
  document.body.removeChild(textArea);
};


  const addFriend = async (arenaId: string) => {
    try {
      await fetchNui("addFriend", { arenaId });
      setShowAddFriendModal(false);
    } catch (error) {
      console.error("[LobbyPage] Error adding friend:", error);
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
                <path
                  fill="currentColor"
                  fillRule="evenodd"
                  d="M7 1h-.414l-.293.293l-3 3L3 4.586v14.828l.293.293l3 3l.293.293h10.828l.293-.293l3-3l.293-.293V4.586l-.293-.293l-3-3L17.414 1zM5 6v12h1V6zm3 15h8v-1H8zm11-3V6h-1v12zM16 3H8v1h8zm0 3v12H8V6z"
                  clipRule="evenodd"
                />
              </svg>
            </span>
            <span>{userData?.gems ?? 1250}</span>
          </div>
          <div className="stat-badge">
            <span className="icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
                <path fill="currentColor" d="M12 2L9 9l-7 1l5.5 5L6 22l6-3.5l6 3.5l-1.5-7L22 10l-7-1z" />
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
          <button className="settings-btn" onClick={() => console.log("Settings clicked")}>
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
            {/* HQ View - Main Display Area */}
            <div className="hq-view">
              {/* This area can be used for other HQ content like character model, stats, etc. */}
              <div className="hq-main-content">
                {/* Placeholder for future content */}
              </div>
            </div>

            {/* Players Info - Right Side */}
            <aside className="hq-players-sidebar">
              <div className="info-panel">
                <div className="panel-header">PROFILE</div>
                <div className="panel-content">
                  <div className="player-header">
                    <img
                      src={userData?.avatarUrl ?? "/icons/player.svg"}
                      alt="avatar"
                      className="player-icon"
                    />
                    <div className="player-main">
<span className="player-name">
  {userData?.username ?? "PlayerOne"}{" "}
  <span
    className={`arena-id ${userData?.arena_id ? "clickable" : "disabled"}`}
    onClick={() => {
      if (userData?.arena_id) copyArenaId();
    }}
    style={{ cursor: userData?.arena_id ? "pointer" : "not-allowed" }}
    title={
      userData?.arena_id
        ? copied
          ? "Copied!"
          : "Click to copy Arena ID"
        : "No Arena ID"
    }
  >
    ({userData?.arena_id ?? "nil"})
    {userData?.arena_id && (
      <div className="copy-hint">{copied ? "Copied" : "Copy"}</div>
    )}
  </span>
</span>

                      <span className={`player-rank rank-${userData?.rank ?? "copper"}`}>
                        {(userData?.rank ?? "copper").toUpperCase()} {userData?.tier ?? 1}
                      </span>
                    </div>
                  </div>

                  {/* Inline Level / XP Progress */}
                  <div className="level-progress">
                    <span className="level-label">LVL {currentLevel}</span>
                    <div className="xp-bar-inline">
                      <div
                        className="xp-fill-inline"
                        style={{ width: `${progress}%` }}
                      ></div>
                    </div>
                  </div>
                  <div className="xp-text-box">
                    <span className="xp-text">
                      {currentXP.toLocaleString()}/{nextLevelXP.toLocaleString()} XP
                    </span>
                  </div>
                </div>
              </div>

              <div className="info-panel">
                <div className="panel-header">FRIENDS LIST</div>
                <div className="panel-content">
                  <div className="friends-actions">
                    <button className="add-friend-btn" onClick={() => setShowAddFriendModal(true)}>
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
                        <path fill="currentColor" d="M15 12c2.21 0 4-1.79 4-4s-1.79-4-4-4s-4 1.79-4 4s1.79 4 4 4m-9-2V7H4v3H1v2h3v3h2v-3h3v-2m9 4c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4"/>
                      </svg>
                      ADD FRIEND
                    </button>
                  </div>
                  <div className="friends-list">
                    {friendsList.length > 0 ? (
                      friendsList.map((friend) => (
                        <div key={friend.id} className={`friend-item ${friend.status}`}>
                          <div className="friend-status-indicator"></div>
                          <span className="friend-name">{friend.username}</span>
                          <span className="friend-status-text">
                            {friend.status === 'online' ? 'ONLINE' : 
                             friend.status === 'ingame' ? 'IN GAME' : 'OFFLINE'}
                          </span>
                        </div>
                      ))
                    ) : (
                      <div className="no-friends">
                        <span>No friends added yet</span>
                        <span className="add-friends-hint">Click ADD FRIEND to connect!</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="info-panel">
                <div className="panel-header">SQUAD MEMBERS</div>
                <div className="panel-content">
                  <div className="squad-display">
                    {/* Show other party members (excluding the leader/current user) */}
                    {partyMembers.filter(member => !member.isLeader).slice(0, 3).map((member, index) => (
                      <div key={member.id} className="squad-member-card">
                        <div className="squad-member-avatar">
                          {member.avatarUrl ? (
                            <img src={member.avatarUrl} alt={member.username} />
                          ) : (
                            <div className="avatar-placeholder">
                              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
                                <path fill="currentColor" d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4s-4 1.79-4 4s1.79 4 4 4m0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4"/>
                              </svg>
                            </div>
                          )}
                        </div>
                        {/* <div className="squad-member-info">
                          <div className="squad-member-name">{member.username}</div>
                          <div className="squad-member-level">LVL {member.level}</div>
                        </div> */}
                      </div>
                    ))}
                    
                    {/* Show empty slots (3 total slots for squad mates) */}
                    {[...Array(Math.max(0, 3 - partyMembers.filter(m => !m.isLeader).length))].map((_, index) => (
                      <div 
                        key={`empty-${index}`} 
                        className="squad-member-card empty"
                        onClick={handleInviteClick}
                      >
                        <div className="squad-member-avatar empty">
                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
                            <path fill="currentColor" d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6z"/>
                          </svg>
                        </div>
                        {/* <div className="squad-member-info">
                          <div className="squad-member-name">Empty Slot</div>
                          <div className="squad-member-level">Click to Invite</div>
                        </div> */}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </aside>
          </>
        ) : activeTab === "SERVERS" ? (
          <>
            {/* Server Browser View */}
            <div className="servers-view">
              <div className="servers-header">
                <h2>AVAILABLE SERVERS</h2>
                <div className="server-count">
                  {worlds.length} SERVER{worlds.length !== 1 ? "S" : ""} | {worlds.reduce((total, world) => total + world.playerCount, 0)} PLAYER{worlds.reduce((total, world) => total + world.playerCount, 0) !== 1 ? "S" : ""} ONLINE
                </div>
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
                autoFocus
              />
            )}
            <div className="modal-actions">
              <button className="btn-primary" onClick={confirmJoin}>CONNECT</button>
              <button className="btn-secondary" onClick={() => setShowJoinModal(false)}>CANCEL</button>
            </div>
          </div>
        </div>
      )}

            {/* Add Friend Modal */}
      {showAddFriendModal && (
        <div className="modal-overlay" onClick={() => setShowAddFriendModal(false)}>
          <div className="join-modal add-friend-modal" onClick={(e) => e.stopPropagation()}>
            <h3>ADD FRIEND</h3>
            <div className="modal-server-name">Enter player's Arena ID to add them</div>
            <input
              type="text"
              placeholder="XXXXXX"
              onKeyPress={(e) => {
                if (e.key === 'Enter') {
                  addFriend((e.target as HTMLInputElement).value);
                }
              }}
              autoFocus
            />
            <div className="modal-actions">
              <button 
                className="btn-primary" 
                onClick={(e) => {
                  const input = e.currentTarget.parentElement?.previousElementSibling as HTMLInputElement;
                  if (input?.value) {
                    addFriend(input.value);
                  }
                }}
              >
                ADD FRIEND
              </button>
              <button className="btn-secondary" onClick={() => setShowAddFriendModal(false)}>CANCEL</button>
            </div>
          </div>
        </div>
      )}

      {/* Invite Modal */}
      {showInviteModal && (
        <div className="modal-overlay" onClick={() => setShowInviteModal(false)}>
          <div className="join-modal invite-modal" onClick={(e) => e.stopPropagation()}>
            <h3>INVITE PLAYER</h3>
            <div className="modal-server-name">Send party invite to player</div>
            <input
              type="text"
              placeholder="ENTER PLAYER NAME"
              onKeyPress={(e) => {
                if (e.key === 'Enter') {
                  sendInvite((e.target as HTMLInputElement).value);
                }
              }}
              autoFocus
            />
            <div className="modal-actions">
              <button 
                className="btn-primary" 
                onClick={(e) => {
                  const input = e.currentTarget.parentElement?.previousElementSibling as HTMLInputElement;
                  if (input?.value) {
                    sendInvite(input.value);
                  }
                }}
              >
                SEND INVITE
              </button>
              <button className="btn-secondary" onClick={() => setShowInviteModal(false)}>CANCEL</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default LobbyPage;