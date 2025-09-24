import React from "react";
import "./LobbyPage.scss";
import { fetchNui } from "../../utils/fetchNui";
import { debugData } from "../../utils/debugData";

debugData([{ action: 'showLobbyPage', data: true }]);

const LobbyPage: React.FC<{ visible: boolean }> = ({ visible }) => {
  if (!visible) return null;

  const handleJoin = (mode: string) => {
    fetchNui("lobbyAction", { action: "join", mode });
  };

  const handleLeave = () => {
    fetchNui("lobbyAction", { action: "leave" });
  };

  return (
    <div className="lobby-wrapper">
      <h1 className="lobby-title">Arena Lobby</h1>
      <div className="lobby-buttons">
        <button onClick={() => handleJoin("ffa")}>Join FFA</button>
        <button onClick={() => handleJoin("duel")}>Join Duel</button>
        <button onClick={() => handleJoin("ranked4v4")}>Join 4v4</button>
        <button onClick={handleLeave} className="leave-btn">Leave Lobby</button>
      </div>
    </div>
  );
};

export default LobbyPage;
