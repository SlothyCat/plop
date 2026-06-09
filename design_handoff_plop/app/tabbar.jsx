// tabbar.jsx — bottom tab bar. Home lives in the MIDDLE as the raised center
// button (rendered by App so the bar's backdrop-filter can't clip it).
// Flanking tabs: Insights (left), Settings (right).
function NavTab({ id, Icon, label, active, onTab }) {
  const on = active === id;
  return (
    <button onClick={() => onTab(id)} style={{
      background: 'none', border: 'none', cursor: 'pointer', padding: '4px 8px',
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
      color: on ? T.ink : T.ink40, flex: 'none',
    }}>
      <Icon size={25} sw={on ? 2 : 1.8} />
      <span style={{ fontSize: 10.5, fontWeight: on ? 600 : 500, letterSpacing: 0.1 }}>{label}</span>
    </button>
  );
}

// The raised center button. Swaps glyph by context; pulses a halo only when
// it is the primary "+" (add) action.
function CenterButton({ icon: Glyph, onClick, halo, label, size = 64 }) {
  return (
    <button onClick={onClick} aria-label={label} style={{
      width: size, height: size, borderRadius: size * 0.36, background: T.accent, border: 'none',
      cursor: 'pointer', color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 3px 10px rgba(140,192,235,0.5), 0 1px 3px rgba(42,42,42,0.12)',
      position: 'relative',
    }}>
      {halo && (
        <span style={{
          position: 'absolute', inset: -6, borderRadius: 'inherit',
          boxShadow: '0 0 0 0 rgba(140,192,235,0.55)', animation: 'addhalo 2.8s ease-out infinite',
          pointerEvents: 'none',
        }} />
      )}
      <span key={label} style={{ display: 'flex', animation: 'iconpop 260ms cubic-bezier(0.34,1.56,0.64,1)' }}>
        <Glyph size={size * 0.46} sw={2.4} />
      </span>
    </button>
  );
}

function TabBar({ active, onTab }) {
  const barBg = T.dark ? 'rgba(28,37,48,0.78)' : 'rgba(255,255,255,0.74)';
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0, height: 92, zIndex: 40,
      background: barBg,
      backdropFilter: 'blur(18px) saturate(160%)', WebkitBackdropFilter: 'blur(18px) saturate(160%)',
      borderTop: `1px solid ${T.hair}`,
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', height: '100%', padding: '12px 0 0' }}>
        <div style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
          <NavTab id="insights" Icon={ChartIcon} label="Insights" active={active} onTab={onTab} />
        </div>
        <div style={{ width: 84, flexShrink: 0 }} />
        <div style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
          <NavTab id="settings" Icon={GearIcon} label="Settings" active={active} onTab={onTab} />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { TabBar, CenterButton });
