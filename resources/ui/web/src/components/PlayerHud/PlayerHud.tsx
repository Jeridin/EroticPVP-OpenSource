import React, { useState } from 'react';
import './PlayerHud.scss';

import { debugData } from "../../utils/debugData";
import { fetchNui } from "../../utils/fetchNui";
import { useNuiEvent } from "../../hooks/useNuiEvent";

// Debugging values
debugData([{ action: 'showPlayerHud', data: true }]);
debugData([{ action: 'setStatusData', data: { health: 50, armor: 50 } }]);

const PlayerHud: React.FC<{ visible: boolean }> = ({ visible }) => {
  const [statusData, setStatusData] = useState({ health: 100, armor: 100 });

  useNuiEvent<any>('setStatusData', setStatusData);

  if (!visible) return null;

  return (
    <div className="hud-wrapper">
      {/* HEALTH BAR */}
      <div className="hud-bar health">
        <div className="label">
          <span className="hud-title">HEALTH</span>
          <div className="bar-icon">
          </div>
          <span
            className={`hud-value ${statusData.health < 25 ? 'low-value' : ''}`}
          >
            {statusData.health}%
          </span>
        </div>
        <div className="bar-bg">
          <div
            className={`bar-fill health ${statusData.health < 25 ? 'low-value' : ''}`}
            style={{ width: `${statusData.health}%` }}
          />
        </div>
      </div>

      {/* ARMOR BAR */}
      <div className="hud-bar armor">
        <div className="label">
          <span className="hud-title">ARMOR</span>
          <div className="bar-icon">
          </div>
          <span
            className={`hud-value ${statusData.armor < 25 ? 'low-value' : ''}`}
          >
            {statusData.armor}%
          </span>
        </div>
        <div className="bar-bg">
          <div
            className={`bar-fill armor ${statusData.armor < 25 ? 'low-value' : ''}`}
            style={{ width: `${statusData.armor}%` }}
          />
        </div>
      </div>
    </div>
  );
};

export default PlayerHud;
