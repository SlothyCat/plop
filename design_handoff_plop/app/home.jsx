// home.jsx — Tab 1: Home (view records), derived from the transactions store.
function TxRow({ tx, cats, onClick }) {
  const meta = catByName(cats, tx.catName);
  const tile = meta ? meta.color : 'rgba(42,42,42,0.08)';
  const amt = signed(tx);
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 14, padding: '11px 0', width: '100%',
      background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left', fontFamily: 'inherit',
    }}>
      <div style={{
        width: 46, height: 46, borderRadius: 14, background: tile,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: T.tileInk, flexShrink: 0,
      }}>
        <CatIcon cat={meta} size={24} sw={1.7} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 17, fontWeight: 600, color: T.ink, letterSpacing: -0.2, display: 'flex', alignItems: 'center', gap: 6 }}>
          {tx.catName || 'Uncategorized'}
          {tx.recurring && <RepeatIcon size={14} sw={2} style={{ color: T.ink40, flexShrink: 0 }} />}
        </div>
        <div style={{ fontSize: 13, color: T.ink40, marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {tx.note ? tx.note : fmtTime(tx.time)}
        </div>
      </div>
      <div style={{ fontSize: 17, fontWeight: 600, color: amt > 0 ? '#1F8A5B' : T.ink, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3 }}>
        {fmtAmt(amt, true)}
      </div>
    </button>
  );
}

function DateGroup({ group, cats, onEditTx }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 4px 4px' }}>
        <span style={{ fontSize: 12.5, fontWeight: 600, letterSpacing: 0.6, color: T.ink40 }}>{group.day}</span>
        <span style={{ fontSize: 12.5, fontWeight: 600, letterSpacing: 0.2, color: T.ink40, fontVariantNumeric: 'tabular-nums' }}>{fmtAmt(group.subtotal)}</span>
      </div>
      <div style={{ height: 1, background: T.hair, margin: '0 0 4px' }} />
      <div style={{
        background: T.card, borderRadius: 22, padding: '4px 16px',
        boxShadow: '0 1px 2px rgba(42,42,42,0.04), 0 6px 18px rgba(42,42,42,0.04)',
      }}>
        {group.rows.map((r, i) => (
          <React.Fragment key={r.id}>
            {i > 0 && <div style={{ height: 1, background: T.hair, marginLeft: 60 }} />}
            <TxRow tx={r} cats={cats} onClick={() => onEditTx(r)} />
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}

// Period filtering, relative to TODAY_ISO ('2026-05-30').
const PERIODS = [
  { key: 'week',  label: 'Week',  pill: 'this week' },
  { key: 'month', label: 'Month', pill: 'this month' },
  { key: 'year',  label: 'Year',  pill: 'this year' },
];
// Inclusive ISO bounds for the period containing TODAY_ISO.
function periodRange(key) {
  const today = new Date(TODAY_ISO + 'T00:00');
  const iso = (d) => d.toISOString().slice(0, 10);
  if (key === 'week') {
    const start = new Date(today);
    const dow = (start.getDay() + 6) % 7; // Mon=0 … Sun=6
    start.setDate(start.getDate() - dow);
    const end = new Date(start); end.setDate(start.getDate() + 6);
    return [iso(start), iso(end)];
  }
  if (key === 'year') {
    return [`${today.getFullYear()}-01-01`, `${today.getFullYear()}-12-31`];
  }
  const y = today.getFullYear(), m = String(today.getMonth() + 1).padStart(2, '0');
  const last = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
  return [`${y}-${m}-01`, `${y}-${m}-${String(last).padStart(2, '0')}`];
}

function FilterMenu({ period, onPick }) {
  const [open, setOpen] = React.useState(false);
  return (
    <div style={{ position: 'relative' }}>
      <button style={iconBtn} onClick={() => setOpen(o => !o)} aria-label="Filter by period">
        <FilterIcon size={24} sw={1.9} />
      </button>
      {open && (
        <React.Fragment>
          <div onClick={() => setOpen(false)} style={{ position: 'fixed', inset: 0, zIndex: 30 }} />
          <div style={{
            position: 'absolute', top: 40, right: 0, zIndex: 31, minWidth: 152,
            background: T.card, borderRadius: 16, padding: 6,
            border: `1px solid ${T.ink12}`,
            boxShadow: '0 8px 30px rgba(42,42,42,0.16), 0 2px 6px rgba(42,42,42,0.08)',
          }}>
            {PERIODS.map(p => {
              const active = p.key === period;
              return (
                <button key={p.key} onClick={() => { onPick(p.key); setOpen(false); }} style={{
                  display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10,
                  width: '100%', padding: '10px 12px', borderRadius: 11, border: 'none', cursor: 'pointer',
                  background: active ? T.field : 'transparent', textAlign: 'left', fontFamily: 'inherit',
                  fontSize: 15.5, fontWeight: active ? 600 : 500, color: T.ink,
                }}>
                  <span>{p.label}</span>
                  {active && <CheckIcon size={18} sw={2.2} />}
                </button>
              );
            })}
          </div>
        </React.Fragment>
      )}
    </div>
  );
}

function HomeScreen({ bg = T.bg, cats = [], txs = [], onEditTx }) {
  const [period, setPeriod] = React.useState('month');
  const [from, to] = periodRange(period);
  const inRange = txs.filter(t => t.date >= from && t.date <= to);
  const groups = groupTx(inRange);
  const net = inRange.reduce((s, t) => s + signed(t), 0);
  const sign = (net < 0 ? '-' : '') + CUR.symbol;
  const rest = Math.abs(net).toLocaleString('en-US', { minimumFractionDigits: CUR.dp, maximumFractionDigits: CUR.dp });
  const pill = PERIODS.find(p => p.key === period).pill;

  return (
    <div style={{ position: 'absolute', inset: 0, background: bg, display: 'flex', flexDirection: 'column' }}>
      {/* top bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'flex-end',
        padding: '64px 22px 0', color: T.ink, flexShrink: 0,
      }}>
        <FilterMenu period={period} onPick={setPeriod} />
      </div>

      {/* net total */}
      <div style={{ textAlign: 'center', padding: '18px 0 22px', flexShrink: 0 }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
          <span style={{ fontSize: 16, fontWeight: 500, color: T.ink60 }}>Net total</span>
          <span style={{
            fontSize: 13, fontWeight: 600, color: T.ink, background: T.card,
            border: `1px solid ${T.ink12}`, borderRadius: 999, padding: '3px 11px',
          }}>{pill}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', color: T.ink }}>
          <span style={{ fontSize: 38, fontWeight: 500, color: T.ink40, marginRight: 1, letterSpacing: -1 }}>{sign}</span>
          <span style={{ fontSize: 60, fontWeight: 600, letterSpacing: -2.5, fontVariantNumeric: 'tabular-nums' }}>{rest}</span>
        </div>
      </div>

      {/* scrolling list — overflows, last row faded at the bottom edge */}
      <div style={{ flex: 1, overflow: 'auto', padding: '6px 18px 150px', WebkitMaskImage: 'linear-gradient(to bottom, #000 88%, transparent 100%)' }}>
        {groups.length === 0 ? (
          <div style={{ textAlign: 'center', color: T.ink40, fontSize: 15, padding: '40px 0' }}>
            No transactions {pill}.
          </div>
        ) : groups.map((g, i) => <DateGroup key={i} group={g} cats={cats} onEditTx={onEditTx} />)}
      </div>
    </div>
  );
}

const iconBtn = {
  background: 'none', border: 'none', padding: 6, margin: -6, cursor: 'pointer',
  color: T.ink, display: 'flex', alignItems: 'center', justifyContent: 'center',
};

Object.assign(window, { HomeScreen });
