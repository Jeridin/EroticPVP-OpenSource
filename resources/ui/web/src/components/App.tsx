import React from "react";
import "./App.css";
import { useVisibility } from "../providers/VisibilityProvider";
import PlayerHud from "./PlayerHud/PlayerHud";

import { debugData } from "../utils/debugData";
import { fetchNui } from "../utils/fetchNui";
import { useNuiEvent } from "../hooks/useNuiEvent";
import LobbyPage from "./LobbyPage/LobbyPage";

debugData([{ action: 'setVisible', data: true }]);

const App: React.FC = () => {
  const { state } = useVisibility();

  return (
    <div className="nui-wrapper">
      <PlayerHud visible={state.playerHud} />
      <LobbyPage visible={state.lobbypage} />
      {/* <Inventory visible={state.inventory} />  Planned on adding differnt uis inside the app here so exp inventory sytem ui and also a crosshair and a user porgressbar */}
    </div>
  );
};

export default App;
