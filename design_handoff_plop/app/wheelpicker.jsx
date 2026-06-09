// wheelpicker.jsx — native-style iOS "When" sheet:
//   • DATE  → graphical calendar grid (.datePickerStyle(.graphical)) with
//             month title, prev/next chevrons, weekday header, selected day
//             in a filled accent circle.
//   • TIME  → wheels (hour / minute / AM·PM spinning drums).
// Presented as a bottom sheet; edits commit on "Done".

const PICK_BLUE = '#2A8FE0'; // iOS-style action blue for Done / selection

// ── Calendar ───────────────────────────────────────────────────────────────
const WEEKDAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
function isoOf(y, m, d) {
  return `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}
function CalendarGrid({ value, onChange, minDate }) {
  // value: ISO string. view month derived from it.
  const init = value ? new Date(value + 'T00:00') : new Date(TODAY_ISO + 'T00:00');
  const [view, setView] = React.useState({ y: init.getFullYear(), m: init.getMonth() });

  React.useEffect(() => {
    const d = new Date((value || TODAY_ISO) + 'T00:00');
    setView({ y: d.getFullYear(), m: d.getMonth() });
  }, [value]);

  const first = new Date(view.y, view.m, 1);
  const startDow = first.getDay();
  const daysInMonth = new Date(view.y, view.m + 1, 0).getDate();
  const monthName = first.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  const cells = [];
  for (let i = 0; i < startDow; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);

  const step = (dir) => setView(v => {
    let m = v.m + dir, y = v.y;
    if (m < 0) { m = 11; y--; } else if (m > 11) { m = 0; y++; }
    return { y, m };
  });

  return (
    <div style={{ padding: '4px 6px 10px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10, padding: '0 6px' }}>
        <span style={{ fontSize: 17, fontWeight: 700, color: T.ink, letterSpacing: -0.3 }}>{monthName}</span>
        <div style={{ display: 'flex', gap: 22 }}>
          <button onClick={() => step(-1)} aria-label="Previous month" style={chevBtn}>
            <Icon size={22} sw={2.2}><path d="M15 5l-7 7 7 7" /></Icon>
          </button>
          <button onClick={() => step(1)} aria-label="Next month" style={chevBtn}>
            <Icon size={22} sw={2.2}><path d="M9 5l7 7-7 7" /></Icon>
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', marginBottom: 2 }}>
        {WEEKDAYS.map(w => (
          <div key={w} style={{ textAlign: 'center', fontSize: 11, fontWeight: 600, letterSpacing: 0.4, color: T.ink40, padding: '4px 0' }}>{w}</div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', rowGap: 2 }}>
        {cells.map((d, i) => {
          if (d == null) return <div key={i} />;
          const iso = isoOf(view.y, view.m, d);
          const on = iso === value;
          const isToday = iso === TODAY_ISO;
          const disabled = minDate && iso < minDate;
          return (
            <div key={i} style={{ display: 'flex', justifyContent: 'center', padding: '1px 0' }}>
              <button onClick={() => !disabled && onChange(iso)} disabled={disabled} style={{
                width: 38, height: 38, borderRadius: 999, border: 'none', cursor: disabled ? 'default' : 'pointer',
                background: on ? T.accent : 'transparent',
                color: disabled ? T.ink40 : (on ? T.tileInk : (isToday ? PICK_BLUE : T.ink)),
                opacity: disabled ? 0.35 : 1,
                fontSize: 18, fontWeight: on || isToday ? 700 : 500, fontVariantNumeric: 'tabular-nums',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: on ? '0 2px 6px rgba(140,192,235,0.5)' : 'none',
              }}>{d}</button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
const chevBtn = { background: 'none', border: 'none', cursor: 'pointer', color: PICK_BLUE, padding: 2, display: 'flex', alignItems: 'center', justifyContent: 'center' };

// ── Wheel (one spinning drum) ────────────────────────────────────────────────
const WHEEL_H = 180, ITEM_H = 36, PAD = (WHEEL_H - ITEM_H) / 2;
function Wheel({ items, index, onChange, width }) {
  const ref = React.useRef(null);
  const raf = React.useRef(null);
  const settle = React.useRef(null);

  React.useEffect(() => {
    const el = ref.current;
    if (el && Math.round(el.scrollTop / ITEM_H) !== index) el.scrollTop = index * ITEM_H;
  }, [index, items.length]);

  const onScroll = () => {
    const el = ref.current; if (!el) return;
    if (raf.current) cancelAnimationFrame(raf.current);
    raf.current = requestAnimationFrame(() => {
      clearTimeout(settle.current);
      settle.current = setTimeout(() => {
        const i = Math.max(0, Math.min(items.length - 1, Math.round(el.scrollTop / ITEM_H)));
        if (i !== index) onChange(i);
      }, 80);
    });
  };

  return (
    <div ref={ref} onScroll={onScroll} style={{
      width, height: WHEEL_H, overflowY: 'scroll', scrollSnapType: 'y mandatory',
      WebkitOverflowScrolling: 'touch', scrollbarWidth: 'none',
      maskImage: 'linear-gradient(to bottom, transparent, #000 30%, #000 70%, transparent)',
      WebkitMaskImage: 'linear-gradient(to bottom, transparent, #000 30%, #000 70%, transparent)',
    }} className="wheel-scroll">
      <div style={{ height: PAD }} />
      {items.map((it, i) => {
        const dist = Math.abs(i - index);
        return (
          <div key={i} onClick={() => ref.current.scrollTo({ top: i * ITEM_H, behavior: 'smooth' })} style={{
            height: ITEM_H, scrollSnapAlign: 'center', display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 22, fontWeight: dist === 0 ? 600 : 500,
            color: dist === 0 ? T.ink : `rgba(42,42,42,${Math.max(0.2, 0.46 - dist * 0.12)})`,
            fontVariantNumeric: 'tabular-nums', cursor: 'pointer',
            transform: `scale(${dist === 0 ? 1 : 0.9})`, transition: 'color 120ms, transform 120ms',
          }}>{it.label}</div>
        );
      })}
      <div style={{ height: PAD }} />
    </div>
  );
}

function TimeWheels({ hIdx, mIdx, apIdx, setHIdx, setMIdx, setApIdx }) {
  const hours = React.useMemo(() => Array.from({ length: 12 }, (_, i) => ({ label: String(i + 1) })), []);
  const mins = React.useMemo(() => Array.from({ length: 60 }, (_, i) => ({ label: String(i).padStart(2, '0') })), []);
  const aps = [{ label: 'AM' }, { label: 'PM' }];
  return (
    <div style={{ position: 'relative', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 4 }}>
      <div style={{ position: 'absolute', left: 24, right: 24, top: PAD, height: ITEM_H, borderRadius: 12, background: 'rgba(42,42,42,0.05)', pointerEvents: 'none' }} />
      <Wheel items={hours} index={hIdx} onChange={setHIdx} width={50} />
      <div style={{ fontSize: 22, fontWeight: 700, color: T.ink }}>:</div>
      <Wheel items={mins} index={mIdx} onChange={setMIdx} width={50} />
      <Wheel items={aps} index={apIdx} onChange={setApIdx} width={56} />
    </div>
  );
}

// ── The combined sheet ───────────────────────────────────────────────────────
function DateTimeSheet({ open, date, time, onClose, onApply }) {
  const [wDate, setWDate] = React.useState(date);
  const [hIdx, setHIdx] = React.useState(0);
  const [mIdx, setMIdx] = React.useState(0);
  const [apIdx, setApIdx] = React.useState(0);
  const [tab, setTab] = React.useState('date'); // 'date' | 'time'

  React.useEffect(() => {
    if (!open) return;
    setWDate(date || TODAY_ISO);
    const [hh, mm] = (time || '00:00').split(':').map(Number);
    setApIdx(hh >= 12 ? 1 : 0);
    setHIdx((hh + 11) % 12);
    setMIdx(mm);
    setTab('date');
  }, [open, date, time]);

  const timeStr = () => {
    let h = (hIdx + 1) % 12; if (apIdx === 1) h += 12;
    return String(h).padStart(2, '0') + ':' + String(mIdx).padStart(2, '0');
  };
  const apply = () => { onApply(wDate, timeStr()); onClose(); };

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 85, pointerEvents: open ? 'auto' : 'none' }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: T.scrim,
        opacity: open ? 1 : 0, transition: 'opacity 240ms ease',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, background: T.card,
        borderRadius: '26px 26px 0 0', padding: '8px 18px 26px',
        boxShadow: '0 -12px 40px rgba(42,42,42,0.18)',
        transform: open ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 340ms cubic-bezier(0.32,0.72,0,1)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 999, background: 'rgba(42,42,42,0.15)', margin: '0 auto 6px' }} />
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, fontWeight: 500, color: T.ink60, padding: '8px 4px', minWidth: 60, textAlign: 'left' }}>Cancel</button>
          {/* Date | Time segmented */}
          <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 999, padding: 3, gap: 2 }}>
            {['date', 'time'].map(s => {
              const on = tab === s;
              return (
                <button key={s} onClick={() => setTab(s)} style={{
                  border: 'none', cursor: 'pointer', borderRadius: 999, padding: '6px 16px',
                  fontSize: 14, fontWeight: 600, color: on ? T.ink : T.ink40,
                  background: on ? T.card : 'transparent', boxShadow: on ? '0 1px 2px rgba(42,42,42,0.12)' : 'none',
                }}>{s === 'date' ? 'Date' : 'Time'}</button>
              );
            })}
          </div>
          <button onClick={apply} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, fontWeight: 700, color: PICK_BLUE, padding: '8px 4px', minWidth: 60, textAlign: 'right' }}>Done</button>
        </div>

        <div style={{ minHeight: WHEEL_H + 8 }}>
          {tab === 'date'
            ? <CalendarGrid value={wDate} onChange={setWDate} />
            : <TimeWheels hIdx={hIdx} mIdx={mIdx} apIdx={apIdx} setHIdx={setHIdx} setMIdx={setMIdx} setApIdx={setApIdx} />}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DateTimeSheet });

// Calendar-only sheet (no time) — used by the Export date-range picker.
function DatePickerSheet({ open, date, title = 'Select date', minDate, onClose, onApply }) {
  const [wDate, setWDate] = React.useState(date);
  React.useEffect(() => { if (open) setWDate(date || TODAY_ISO); }, [open, date]);
  const apply = () => { onApply(wDate); onClose(); };
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 95, pointerEvents: open ? 'auto' : 'none' }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: T.scrim,
        opacity: open ? 1 : 0, transition: 'opacity 240ms ease',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, background: T.card,
        borderRadius: '26px 26px 0 0', padding: '8px 18px 26px',
        boxShadow: '0 -12px 40px rgba(42,42,42,0.18)',
        transform: open ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 340ms cubic-bezier(0.32,0.72,0,1)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 999, background: 'rgba(42,42,42,0.15)', margin: '0 auto 6px' }} />
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, fontWeight: 500, color: T.ink60, padding: '8px 4px', minWidth: 60, textAlign: 'left' }}>Cancel</button>
          <span style={{ fontSize: 16, fontWeight: 700, color: T.ink }}>{title}</span>
          <button onClick={apply} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, fontWeight: 700, color: PICK_BLUE, padding: '8px 4px', minWidth: 60, textAlign: 'right' }}>Done</button>
        </div>
        <CalendarGrid value={wDate} onChange={setWDate} minDate={minDate} />
      </div>
    </div>
  );
}

Object.assign(window, { DatePickerSheet });
