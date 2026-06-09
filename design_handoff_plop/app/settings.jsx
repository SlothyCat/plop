// settings.jsx — Tab 3: grouped iOS settings list
function Row({ tile, Icon, label, value, onClick, last }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 13, width: '100%', background: 'none',
      border: 'none', cursor: onClick ? 'pointer' : 'default', padding: '11px 16px', textAlign: 'left',
    }}>
      <span style={{ width: 30, height: 30, borderRadius: 9, background: tile, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <Icon size={18} sw={1.9} />
      </span>
      <span style={{ flex: 1, fontSize: 16.5, fontWeight: 500, color: T.ink, letterSpacing: -0.2 }}>{label}</span>
      {value && <span style={{ fontSize: 15.5, color: T.ink40 }}>{value}</span>}
      <span style={{ color: T.ink40, display: 'flex' }}><ChevronIcon size={18} sw={1.8} /></span>
    </button>
  );
}

function Group({ children }) {
  const items = React.Children.toArray(children);
  return (
    <div style={{
      background: T.card, borderRadius: 20, overflow: 'hidden',
      boxShadow: '0 1px 2px rgba(42,42,42,0.04), 0 6px 18px rgba(42,42,42,0.04)',
    }}>
      {items.map((c, i) => (
        <React.Fragment key={i}>
          {i > 0 && <div style={{ height: 1, background: T.hair, marginLeft: 59 }} />}
          {c}
        </React.Fragment>
      ))}
    </div>
  );
}

function GroupLabel({ children }) {
  return <div style={{ fontSize: 12.5, fontWeight: 600, letterSpacing: 0.5, color: T.ink40, padding: '0 6px 8px' }}>{children}</div>;
}

function SettingsScreen({ bg = T.bg, themeLabel = 'Light', currencyLabel = 'USD  $', budgetLabel = '', onExport, onCategory, onCurrency, onTheme, onBug, onBudget }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '64px 22px 0', flexShrink: 0 }}>
        <h1 style={{ margin: 0, fontSize: 26, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Settings</h1>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '20px 18px 120px', display: 'flex', flexDirection: 'column', gap: 22 }}>
        <div>
          <GroupLabel>DATA</GroupLabel>
          <Group>
            <Row tile={T.accent} Icon={ExportIcon} label="Export to Google Sheets" onClick={onExport} />
          </Group>
        </div>

        <div>
          <GroupLabel>PREFERENCES</GroupLabel>
          <Group>
            <Row tile={T.accent} Icon={TargetIcon} label="Set budget" value={budgetLabel} onClick={onBudget} />
            <Row tile={T.accentSoft} Icon={TagIcon} label="Manage categories" onClick={onCategory} />
            <Row tile={T.cream} Icon={DollarIcon} label="Currency" value={currencyLabel} onClick={onCurrency} />
            <Row tile={T.yellow} Icon={SunIcon} label="Theme" value={themeLabel} onClick={onTheme} />
          </Group>
        </div>

        <div>
          <GroupLabel>SUPPORT</GroupLabel>
          <Group>
            <Row tile={T.accentSoft} Icon={BugIcon} label="Report a bug" onClick={onBug} />
          </Group>
        </div>

        <div style={{ textAlign: 'center', fontSize: 12.5, color: T.ink40, paddingTop: 4 }}>Version 1.0.0</div>
      </div>
    </div>
  );
}

Object.assign(window, { SettingsScreen });
