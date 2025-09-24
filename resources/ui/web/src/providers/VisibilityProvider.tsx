import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../utils/fetchNui";

interface VisibilityProviderValue {
  setVisible: (visible: boolean) => void;
  visible: boolean;
}

const VisibilityCtx = createContext<VisibilityProviderValue | undefined>(
  undefined
);

interface VisibilityProviderProps {
  children: ReactNode;
}

// This should be mounted at the top level of your application.
// Currently applies a CSS visibility toggle; feel free to extend.
export const VisibilityProvider = ({ children }: VisibilityProviderProps) => {
  const [visible, setVisible] = useState(false);

  useNuiEvent<boolean>("setVisible", setVisible);

  // Handle pressing escape/backspace
  useEffect(() => {
    if (!visible) return;

    const keyHandler = (e: KeyboardEvent) => {
      if (["Backspace", "Escape"].includes(e.code)) {
        fetchNui("hideFrame");
      }
    };

    window.addEventListener("keydown", keyHandler);
    return () => window.removeEventListener("keydown", keyHandler);
  }, [visible]);

  return (
    <VisibilityCtx.Provider value={{ visible, setVisible }}>
      <div style={{ visibility: visible ? "visible" : "hidden", height: "100%" }}>
        {children}
      </div>
    </VisibilityCtx.Provider>
  );
};

export const useVisibility = (): VisibilityProviderValue => {
  const ctx = useContext(VisibilityCtx);
  if (!ctx) {
    throw new Error("useVisibility must be used within a VisibilityProvider");
  }
  return ctx;
};
