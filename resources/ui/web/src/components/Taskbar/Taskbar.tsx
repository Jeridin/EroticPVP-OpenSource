import React from 'react';

const Taskbar: React.FC<{ visible: boolean }> = ({ visible }) => {
  if (!visible) return null;
  return (
    <div style={{ position: 'fixed', bottom: 10, left: '50%', transform: 'translateX(-50%)', background: '#444', color: '#fff', padding: 10, borderRadius: 8 }}>
      Taskbar Example
    </div>
  );
};

export default Taskbar;
