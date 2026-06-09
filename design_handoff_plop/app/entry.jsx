// entry.jsx — full-screen Entry page. Doubles as ADD (editing=null) and
// EDIT (editing=tx) — prefilled, with delete.
function Segmented({ value, onChange }) {
  const opts = ['Expense', 'Income'];
  return (
    <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 999, padding: 3, gap: 2 }}>
      {opts.map(o => {
        const on = value === o;
        return (
          <button key={o} onClick={() => onChange(o)} style={{
            border: 'none', cursor: 'pointer', borderRadius: 999, padding: '8px 22px',
            fontSize: 15, fontWeight: 600, letterSpacing: -0.2,
            color: on ? T.ink : T.ink40,
            background: on ? T.card : 'transparent',
            boxShadow: on ? '0 1px 3px rgba(42,42,42,0.12)' : 'none',
          }}>{o}</button>
        );
      })}
    </div>
  );
}

function CircleBtn({ children, onClick, label, danger, active }) {
  return (
    <button onClick={onClick} aria-label={label} style={{
      width: 42, height: 42, borderRadius: 999,
      background: active ? T.accent : (danger ? 'rgba(42,42,42,0.06)' : T.card),
      border: active ? 'none' : `1px solid ${T.ink12}`, cursor: 'pointer',
      color: active ? T.tileInk : T.ink,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: active ? '0 4px 12px rgba(140,192,235,0.45)' : '0 1px 2px rgba(42,42,42,0.05)', flexShrink: 0,
    }}>{children}</button>
  );
}

// Recurrence intervals. null = one-time.
const RECUR_OPTS = [
  { key: null,      label: 'One-time', sub: "Doesn't repeat" },
  { key: 'daily',   label: 'Daily',    sub: 'Every day' },
  { key: 'weekly',  label: 'Weekly',   sub: 'Every week' },
  { key: 'monthly', label: 'Monthly',  sub: 'Every month' },
  { key: 'yearly',  label: 'Yearly',   sub: 'Every year' },
];
const recurLabel = (k) => ({ daily: 'Daily', weekly: 'Weekly', monthly: 'Monthly', yearly: 'Yearly' })[k] || 'One-time';

function Pill({ children, onClick, style }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 8, background: T.card, border: `1px solid ${T.ink12}`,
      borderRadius: 999, padding: '11px 16px', cursor: 'pointer', color: T.ink,
      fontSize: 15, fontWeight: 500, ...style,
    }}>{children}</button>
  );
}

function EntryScreen({ onClose, bg = T.bg, cats = [], onAddCategory, editing, onSubmit, onDelete }) {
  const [mode, setMode] = React.useState('Expense');
  const [digits, setDigits] = React.useState('');
  const [pickerOpen, setPickerOpen] = React.useState(false);
  const [selectedId, setSelectedId] = React.useState(null);
  const [note, setNote] = React.useState('');
  const [noteOpen, setNoteOpen] = React.useState(false);
  const [date, setDate] = React.useState(TODAY_ISO);
  const [time, setTime] = React.useState('21:12');
  const [whenOpen, setWhenOpen] = React.useState(false);
  const [recurring, setRecurring] = React.useState(null); // null | 'daily' | 'weekly' | 'monthly' | 'yearly'
  const [recurOpen, setRecurOpen] = React.useState(false);

  // (re)initialise whenever the editing target changes
  React.useEffect(() => {
    if (editing) {
      setMode(editing.type === 'income' ? 'Income' : 'Expense');
      setDigits(editing.amount ? String(editing.amount) : '');
      setNote(editing.note || '');
      setDate(editing.date || TODAY_ISO);
      setTime(editing.time || '21:12');
      setRecurring(editing.recurring || null);
      const c = cats.find(x => x.name === editing.catName);
      setSelectedId(c ? c.id : null);
    } else {
      const d = new Date();
      setMode('Expense'); setDigits(''); setNote(''); setSelectedId(null);
      setRecurring(null);
      setDate(TODAY_ISO);
      setTime(String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'));
    }
    setNoteOpen(false); setPickerOpen(false); setWhenOpen(false); setRecurOpen(false);
  }, [editing]);

  const selected = cats.find(c => c.id === selectedId) || null;

  const display = React.useMemo(() => {
    if (!digits) return '0';
    const [int, dec] = digits.split('.');
    const grouped = Number(int || '0').toLocaleString('en-US');
    return dec !== undefined ? `${grouped}.${dec}` : grouped;
  }, [digits]);

  const press = (k) => setDigits(d => {
    if (k === '.') return d.includes('.') ? d : (d === '' ? '0.' : d + '.');
    if (d.includes('.') && d.split('.')[1].length >= 2) return d;
    if (d === '0' && k !== '.') return k;
    return d + k;
  });
  const backspace = () => setDigits(d => d.slice(0, -1));

  const amount = parseFloat(digits || '0') || 0;
  const canSave = amount > 0;
  const confirm = () => {
    if (!canSave) return;
    onSubmit({
      catName: selected ? selected.name : (editing ? editing.catName : null),
      amount, type: mode === 'Income' ? 'income' : 'expense', note: note.trim(),
      date, time, recurring,
    });
  };

  const Key = ({ label, onClick, kind, disabled }) => (
    <button onClick={onClick} disabled={disabled} style={{
      border: 'none', cursor: disabled ? 'default' : 'pointer', borderRadius: 18,
      background: kind === 'confirm' ? T.accent : T.card,
      color: kind === 'confirm' ? T.tileInk : T.ink, fontSize: 28, fontWeight: 500,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      height: 62, fontVariantNumeric: 'tabular-nums',
      opacity: kind === 'confirm' && disabled ? 0.4 : 1,
      boxShadow: kind === 'confirm' ? '0 4px 12px rgba(140,192,235,0.45)' : '0 1px 2px rgba(42,42,42,0.05)',
    }}>{label}</button>
  );

  return (
    <div style={{ position: 'absolute', inset: 0, background: bg, display: 'flex', flexDirection: 'column', zIndex: 60 }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '60px 20px 0', flexShrink: 0 }}>
        <CircleBtn onClick={onClose} label="Close"><CloseIcon size={20} sw={2} /></CircleBtn>
        <Segmented value={mode} onChange={setMode} />
        <div style={{ display: 'flex', gap: 8 }}>
          <CircleBtn onClick={() => setRecurOpen(true)} label="Recurring" active={recurring != null}>
            <RepeatIcon size={19} sw={1.9} />
          </CircleBtn>
          {editing && <CircleBtn onClick={onDelete} label="Delete" danger><TrashIcon size={19} sw={1.8} /></CircleBtn>}
        </div>
      </div>

      {/* amount */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 18 }}>
        <div style={{ display: 'flex', alignItems: 'baseline' }}>
          <span style={{ fontSize: 40, fontWeight: 500, color: T.ink40, marginRight: 4 }}>{CUR.symbol}</span>
          <span style={{ fontSize: 66, fontWeight: 600, color: T.ink, letterSpacing: -2, fontVariantNumeric: 'tabular-nums' }}>{display}</span>
        </div>
        <div style={{ position: 'relative', width: '100%', display: 'flex', justifyContent: 'center' }}>
          {noteOpen ? (
            <input autoFocus value={note} onChange={e => setNote(e.target.value)} onBlur={() => { if (!note.trim()) setNoteOpen(false); }}
              placeholder="Add a note…" style={{
                width: 240, textAlign: 'center', border: `1px solid ${T.ink12}`, borderRadius: 999,
                padding: '9px 16px', fontSize: 15, color: T.ink, background: T.card, outline: 'none', fontFamily: 'inherit',
              }} />
          ) : (
            <Pill style={{ padding: '9px 16px' }} onClick={() => setNoteOpen(true)}>
              <NoteIcon size={18} sw={1.9} />
              <span style={{ color: note ? T.ink : T.ink60, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{note || 'Add Note'}</span>
            </Pill>
          )}
          <button onClick={backspace} aria-label="Backspace" style={{
            position: 'absolute', right: 24, top: -78, width: 42, height: 42, borderRadius: 999,
            background: 'rgba(42,42,42,0.06)', border: 'none', cursor: 'pointer', color: T.ink60,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <BackspaceIcon size={22} sw={1.7} />
          </button>
        </div>
        {recurring && (
          <button onClick={() => setRecurOpen(true)} style={{
            display: 'flex', alignItems: 'center', gap: 7, background: 'transparent', border: 'none',
            cursor: 'pointer', color: T.accentInk || T.ink60, fontSize: 13.5, fontWeight: 600, padding: '2px 4px',
            fontFamily: 'inherit',
          }}>
            <RepeatIcon size={15} sw={2} />
            <span>Repeats {recurLabel(recurring).toLowerCase()}</span>
          </button>
        )}
      </div>

      {/* date + category pills */}
      <div style={{ display: 'flex', gap: 10, padding: '0 18px 14px', flexShrink: 0 }}>
        <Pill onClick={() => setWhenOpen(true)} style={{ flex: 1, justifyContent: 'space-between' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <CalendarIcon size={18} sw={1.8} /> {dayLabelLong(date)}
          </span>
          <span style={{ color: T.ink40, fontVariantNumeric: 'tabular-nums' }}>{fmtTime(time)}</span>
        </Pill>
        <Pill onClick={() => setPickerOpen(true)} style={selected ? { borderColor: selected.color, background: selected.color, color: T.tileInk } : undefined}>
          {selected ? <CatIcon cat={selected} size={18} sw={1.8} /> : <GridIcon size={18} sw={1.8} />}
          <span style={{ color: selected ? T.tileInk : T.ink60 }}>{selected ? selected.name : 'Category'}</span>
        </Pill>
      </div>

      {/* custom keypad */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, padding: '0 18px 30px', flexShrink: 0 }}>
        {['1','2','3','4','5','6','7','8','9'].map(n => <Key key={n} label={n} onClick={() => press(n)} />)}
        <Key label="." onClick={() => press('.')} />
        <Key label="0" onClick={() => press('0')} />
        <Key kind="confirm" disabled={!canSave} label={<CheckIcon size={30} sw={2.4} />} onClick={confirm} />
      </div>

      {/* category picker sheet */}
      <CategoryPicker
        open={pickerOpen} cats={cats} selectedId={selectedId}
        onClose={() => setPickerOpen(false)}
        onSelect={(id) => { setSelectedId(id); setPickerOpen(false); }}
        onAddNew={() => { setPickerOpen(false); onAddCategory && onAddCategory(); }}
      />

      {/* native-style date + time picker sheet */}
      <DateTimeSheet
        open={whenOpen} date={date} time={time}
        onClose={() => setWhenOpen(false)}
        onApply={(d, t) => { setDate(d); setTime(t); }}
      />

      {/* recurrence interval picker sheet */}
      <RecurringSheet
        open={recurOpen} value={recurring}
        onClose={() => setRecurOpen(false)}
        onSelect={(k) => { setRecurring(k); setRecurOpen(false); }}
      />
    </div>
  );
}

// Bottom-sheet recurrence picker, lives inside the Entry overlay.
function RecurringSheet({ open, value, onClose, onSelect }) {
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 80, pointerEvents: open ? 'auto' : 'none' }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: T.scrim,
        opacity: open ? 1 : 0, transition: 'opacity 240ms ease',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, background: T.card,
        borderRadius: '26px 26px 0 0', padding: '10px 18px 28px',
        boxShadow: '0 -12px 40px rgba(42,42,42,0.18)',
        transform: open ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 340ms cubic-bezier(0.32,0.72,0,1)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 999, background: 'rgba(42,42,42,0.15)', margin: '0 auto 14px' }} />
        <div style={{ fontSize: 18, fontWeight: 700, color: T.ink, marginBottom: 4, letterSpacing: -0.3 }}>Repeat</div>
        <div style={{ fontSize: 13.5, color: T.ink40, marginBottom: 14 }}>How often does this payment occur?</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {RECUR_OPTS.map(o => {
            const on = (value || null) === o.key;
            return (
              <button key={o.label} onClick={() => onSelect(o.key)} style={{
                display: 'flex', alignItems: 'center', gap: 13, padding: '12px 14px', borderRadius: 14,
                cursor: 'pointer', textAlign: 'left', width: '100%',
                background: on ? T.accent : T.field,
                border: on ? 'none' : `1px solid ${T.ink12}`,
              }}>
                <span style={{ width: 34, height: 34, borderRadius: 10, background: on ? 'rgba(255,255,255,0.5)' : T.card, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <RepeatIcon size={18} sw={1.9} />
                </span>
                <span style={{ flex: 1 }}>
                  <span style={{ display: 'block', fontSize: 16, fontWeight: 600, color: on ? T.tileInk : T.ink }}>{o.label}</span>
                  <span style={{ display: 'block', fontSize: 13, color: on ? 'rgba(42,42,42,0.6)' : T.ink40 }}>{o.sub}</span>
                </span>
                {on && <span style={{ color: T.tileInk, display: 'flex' }}><CheckIcon size={20} sw={2.4} /></span>}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// Bottom-sheet category picker, lives inside the Entry overlay.
function CategoryPicker({ open, cats, selectedId, onClose, onSelect, onAddNew }) {
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 80, pointerEvents: open ? 'auto' : 'none' }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: T.scrim,
        opacity: open ? 1 : 0, transition: 'opacity 240ms ease',
      }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, background: T.card,
        borderRadius: '26px 26px 0 0', padding: '10px 18px 28px',
        boxShadow: '0 -12px 40px rgba(42,42,42,0.18)',
        transform: open ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 340ms cubic-bezier(0.32,0.72,0,1)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 999, background: 'rgba(42,42,42,0.15)', margin: '0 auto 14px' }} />
        <div style={{ fontSize: 18, fontWeight: 700, color: T.ink, marginBottom: 14, letterSpacing: -0.3 }}>Choose category</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
          {cats.map(c => {
            const on = c.id === selectedId;
            return (
              <button key={c.id} onClick={() => onSelect(c.id)} style={{
                display: 'flex', alignItems: 'center', gap: 11, padding: '11px 12px', borderRadius: 15,
                cursor: 'pointer', textAlign: 'left',
                background: on ? c.color : T.field,
                border: on ? `1.5px solid ${T.ink}` : `1px solid ${T.ink12}`,
              }}>
                <span style={{ width: 34, height: 34, borderRadius: 10, background: on ? 'rgba(255,255,255,0.55)' : c.color, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <CatIcon cat={c} size={19} sw={1.7} />
                </span>
                <span style={{ fontSize: 15, fontWeight: 600, color: on ? T.tileInk : T.ink, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.name}</span>
              </button>
            );
          })}
        </div>
        <button onClick={onAddNew} style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%',
          padding: '13px 0', borderRadius: 15, cursor: 'pointer', border: `1.5px dashed ${T.ink12}`,
          background: 'transparent', color: T.ink, fontSize: 15, fontWeight: 600,
        }}>
          <PlusIcon size={18} sw={2.2} /> New category
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { EntryScreen });
