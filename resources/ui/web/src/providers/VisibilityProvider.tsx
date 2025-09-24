import React, {
  Context,
  createContext,
  useContext,
  useEffect,
  useState,
} from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../utils/fetchNui";
import { isEnvBrowser } from "../utils/misc";

const VisibilityCtx = createContext<VisibilityProviderValue | null>(null);

type UIKey = 'visible' | 'playerHud' | 'inventory' | 'crosshair' | 'taskbar' | 'lobbypage';
interface VisibilityProviderValue {
  state: Record<UIKey, boolean>;
  setUI: (key: UIKey, value: boolean) => void;
}

// This should be mounted at the top level of your application, it is currently set to
// apply a CSS visibility value. If this is non-performant, this should be customized.
interface VisibilityProviderProps {
  children: React.ReactNode;
}

export const VisibilityProvider = ({ children }: VisibilityProviderProps) => {
  const [state, setState] = useState<Record<UIKey, boolean>>({
    visible: false,
    playerHud: false,
    inventory: false,
    crosshair: false,
    taskbar: false,
    lobbypage: false,
  });

  const setUI = (key: UIKey, value: boolean) => {
    setState((prev) => ({ ...prev, [key]: value }));
  };

  useNuiEvent<boolean>("setVisible", (v) => setUI('visible', v));
  useNuiEvent<boolean>("showPlayerHud", (v) => setUI('playerHud', v));
  useNuiEvent<boolean>("showInventory", (v) => setUI('inventory', v));
  useNuiEvent<boolean>("showCrosshair", (v) => setUI('crosshair', v));
  useNuiEvent<boolean>("showTaskbar", (v) => setUI('taskbar', v));
  useNuiEvent<boolean>("showLobbyPage", (v) => setUI('lobbypage', v));

  useEffect(() => {
    if (!state.visible) return;
    const keyHandler = (e: KeyboardEvent) => {
      if (["Backspace", "Escape"].includes(e.code)) {
        if (!isEnvBrowser()) fetchNui("hideFrame");
        else setUI('visible', false);
      }
    };
    window.addEventListener("keydown", keyHandler);
    return () => window.removeEventListener("keydown", keyHandler);
  }, [state.visible]);

  return (
    <VisibilityCtx.Provider value={{ state, setUI }}>
      <div style={{ visibility: state.visible ? "visible" : "hidden", height: "100%" }}>
        {children}
      </div>
    </VisibilityCtx.Provider>
  );
};

// To add a new UI element:
// 1. Add the key to the UIKey type below (e.g., 'myNewElement')
// 2. Add the key to the initial state in useState
// 3. Add a useNuiEvent line for the new element (e.g., useNuiEvent<boolean>("showMyNewElement", (v) => setUI('myNewElement', v));)
// 4. Use state.myNewElement in your components

export const useVisibility = () =>
  useContext<VisibilityProviderValue>(
    VisibilityCtx as Context<VisibilityProviderValue>,
  );
