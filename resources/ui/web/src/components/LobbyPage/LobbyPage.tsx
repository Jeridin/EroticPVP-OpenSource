import React, { useEffect, useMemo, useState } from "react";
import "./LobbyPage.scss";
import { fetchNui } from "../../utils/fetchNui";
import { debugData } from "../../utils/debugData";
import { useNuiEvent } from "../../hooks/useNuiEvent";

type WorldSummary = {
  id: string;
  name: string;
  gamemode: string;
  type: string;
  bucket: number;
  capacity?: number | null;
  playerCount: number;
  owner?: string | null;
  ownerName?: string | null;
  template?: string | null;
  templateLabel?: string | null;
};

type CustomTemplate = {
  id: string;
  label: string;
  description?: string;
};

const FALLBACK_TEMPLATES: CustomTemplate[] = [
  {
    id: "default",
    label: "Training Facility",
    description: "Balanced interior with short sightlines.",
  },
  {
    id: "hangar",
    label: "LSIA Hangar",
    description: "Wide open hangar floor ideal for team fights.",
  },
  {
    id: "rooftop",
    label: "Downtown Rooftop",
    description: "Vertical engagements with plenty of cover.",
  },
];

debugData([
  { action: "showLobbyPage", data: true },
  {
    action: "updateWorldList",
    data: [
      {
        id: "lobby",
        name: "Lobby",
        gamemode: "lobby",
        type: "static",
        bucket: 0,
        capacity: null,
        playerCount: 12,
      },
      {
        id: "ffa-main",
        name: "Global FFA",
        gamemode: "ffa",
        type: "static",
        bucket: 1000,
        capacity: 48,
        playerCount: 18,
      },
      {
        id: "custom-demo",
        name: "Tester\'s Arena",
        gamemode: "custom",
        type: "personal",
        bucket: 2005,
        capacity: 12,
        playerCount: 2,
        ownerName: "Tester",
        template: "rooftop",
        templateLabel: "Downtown Rooftop",
      },
    ],
  },
  { action: "updateCustomTemplates", data: FALLBACK_TEMPLATES },
]);

const LobbyPage: React.FC<{ visible: boolean }> = ({ visible }) => {
  const [worlds, setWorlds] = useState<WorldSummary[]>([]);
  const [templates, setTemplates] = useState<CustomTemplate[]>(FALLBACK_TEMPLATES);
  const [customName, setCustomName] = useState("");
  const [customTemplate, setCustomTemplate] = useState<string>(FALLBACK_TEMPLATES[0]?.id ?? "default");
  const [customCapacity, setCustomCapacity] = useState("12");
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [statusType, setStatusType] = useState<"success" | "error" | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useNuiEvent<WorldSummary[]>("updateWorldList", (data) => {
    if (Array.isArray(data)) {
      setWorlds(data);
    }
  });

  useNuiEvent<CustomTemplate[]>("updateCustomTemplates", (data) => {
    if (!Array.isArray(data) || data.length === 0) return;
    setTemplates(data);
    setCustomTemplate((current) => {
      if (data.some((tpl) => tpl.id === current)) {
        return current;
      }
      return data[0].id;
    });
  });

  useEffect(() => {
    if (!visible) return;

    fetchNui<{ success: boolean; worlds?: WorldSummary[] }>("lobbyAction", { action: "getWorlds" })
      .then((resp) => {
        if (resp?.worlds && Array.isArray(resp.worlds)) {
          setWorlds(resp.worlds);
        }
      })
      .catch(() => {});

    fetchNui<{ success: boolean; templates?: CustomTemplate[] }>("lobbyAction", { action: "getTemplates" })
      .then((resp) => {
        if (resp?.templates && resp.templates.length > 0) {
          setTemplates(resp.templates);
          setCustomTemplate((current) => {
            if (resp.templates!.some((tpl) => tpl.id === current)) {
              return current;
            }
            return resp.templates![0].id;
          });
        }
      })
      .catch(() => {});
  }, [visible]);

  if (!visible) return null;

  const handleJoin = (mode: string) => {
    fetchNui("lobbyAction", { action: "join", mode });
  };

  const handleLeave = () => {
    fetchNui("lobbyAction", { action: "leave" });
  };

  const handleCreateCustom = async (event: React.FormEvent) => {
    event.preventDefault();

    setIsSubmitting(true);
    setStatusMessage(null);
    setStatusType(null);

    try {
      const response = await fetchNui<{ success: boolean; error?: string }>("lobbyAction", {
        action: "createCustom",
        options: {
          name: customName,
          template: customTemplate,
          capacity: customCapacity !== "" ? Number(customCapacity) : undefined,
        },
      });

      if (response?.success) {
        setStatusMessage("Custom arena request sent. You'll be moved shortly.");
        setStatusType("success");
      } else {
        setStatusMessage(response?.error || "Unable to create a custom arena right now.");
        setStatusType("error");
      }
    } catch (error) {
      setStatusMessage("Unable to reach the server. Please try again.");
      setStatusType("error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const sortedWorlds = useMemo(() => worlds, [worlds]);
  const selectedTemplate = useMemo(
    () => templates.find((tpl) => tpl.id === customTemplate),
    [templates, customTemplate]
  );

  const formatPlayerCount = (world: WorldSummary) => {
    const total = world.playerCount ?? 0;
    if (world.capacity) {
      return `${total}/${world.capacity}`;
    }
    return `${total}`;
  };

  return (
    <div className="lobby-wrapper">
      <h1 className="lobby-title">Arena Lobby</h1>
      <div className="lobby-grid">
        <section className="worlds-section">
          <div className="section-header">
            <h2>Active Worlds</h2>
            <span>{sortedWorlds.length} total</span>
          </div>
          <div className="worlds-list">
            {sortedWorlds.length === 0 && (
              <p className="empty-message">No worlds available yet. Create one or join a queue!</p>
            )}
            {sortedWorlds.map((world) => (
              <div key={world.id} className={`world-card world-card--${world.type}`}>
                <div className="world-card__header">
                  <h3>{world.name}</h3>
                  <span className="world-card__badge">{world.gamemode.toUpperCase()}</span>
                </div>
                <div className="world-card__meta">
                  <span>{formatPlayerCount(world)} players</span>
                  {world.templateLabel && <span>Template: {world.templateLabel}</span>}
                  {world.ownerName && <span>Owner: {world.ownerName}</span>}
                </div>
              </div>
            ))}
          </div>
        </section>
        <div className="side-panel">
          <section className="actions-section">
            <h2>Quick Join</h2>
            <div className="button-list">
              <button onClick={() => handleJoin("ffa")}>Join FFA</button>
              <button onClick={() => handleJoin("custom")}>Personal Arena</button>
              <button onClick={() => handleJoin("duel")}>Join Duel Queue</button>
              <button onClick={() => handleJoin("ranked4v4")}>Join Ranked 4v4</button>
              <button onClick={handleLeave} className="leave-btn">Leave Current World</button>
            </div>
          </section>
          <section className="custom-section">
            <h2>Create Custom Arena</h2>
            <form onSubmit={handleCreateCustom} className="custom-form">
              <label>
                Arena Name
                <input
                  type="text"
                  value={customName}
                  onChange={(e) => setCustomName(e.target.value)}
                  maxLength={48}
                  placeholder="My Private Arena"
                />
              </label>
              <label>
                Template
                <select
                  value={customTemplate}
                  onChange={(e) => setCustomTemplate(e.target.value)}
                >
                  {templates.map((tpl) => (
                    <option key={tpl.id} value={tpl.id}>
                      {tpl.label}
                    </option>
                  ))}
                </select>
                {selectedTemplate?.description && (
                  <p className="template-description">{selectedTemplate.description}</p>
                )}
              </label>
              <label>
                Max Players
                <input
                  type="number"
                  min={2}
                  max={32}
                  value={customCapacity}
                  onChange={(e) => setCustomCapacity(e.target.value)}
                />
              </label>
              <button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Creating..." : "Launch Custom Arena"}
              </button>
              {statusMessage && (
                <p className={`status-message status-message--${statusType}`}>{statusMessage}</p>
              )}
            </form>
          </section>
        </div>
      </div>
    </div>
  );
};

export default LobbyPage;
