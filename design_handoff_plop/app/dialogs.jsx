// dialogs.jsx — shared modal shell + all dialogs.
// Consistent: 26px corner radius, same button style, same spacing.
function Dialog({ open, onClose, children, maxWidth = 320 }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 90,
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
      pointerEvents: open ? 'auto' : 'none',
    }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: T.scrim,
        backdropFilter: 'blur(2px)', WebkitBackdropFilter: 'blur(2px)',
        opacity: open ? 1 : 0, transition: 'opacity 280ms ease',
      }} />
      <div style={{
        position: 'relative', width: `calc(100% - 24px)`, maxWidth, marginBottom: 18,
        background: T.card, borderRadius: 26, padding: 22,
        boxShadow: '0 20px 50px rgba(42,42,42,0.25)',
        transform: open ? 'translateY(0)' : 'translateY(40px)',
        opacity: open ? 1 : 0,
        transition: 'transform 320ms cubic-bezier(0.32,0.72,0,1), opacity 220ms ease',
        maxHeight: 'calc(100% - 60px)', overflowY: 'auto',
      }}>
        {children}
      </div>
    </div>
  );
}

const btnPrimary = () => ({
  border: 'none', cursor: 'pointer', borderRadius: 15, padding: '14px 0',
  background: T.accent, color: T.tileInk, fontSize: 16, fontWeight: 700, letterSpacing: -0.2,
  width: '100%', boxShadow: '0 4px 12px rgba(140,192,235,0.45)',
});
const btnGhost = () => ({
  border: 'none', cursor: 'pointer', borderRadius: 15, padding: '13px 0',
  background: 'transparent', color: T.ink60, fontSize: 16, fontWeight: 600, width: '100%',
});
const dlgTitle = () => ({ margin: '0 0 6px', fontSize: 20, fontWeight: 700, color: T.ink, letterSpacing: -0.3 });
const dlgBody = () => ({ margin: '0 0 18px', fontSize: 14.5, lineHeight: 1.5, color: T.ink60 });
const fieldLabel = () => ({ fontSize: 12.5, fontWeight: 600, letterSpacing: 0.4, color: T.ink40, marginBottom: 7, display: 'block' });
const textField = () => ({
  width: '100%', boxSizing: 'border-box', border: `1px solid ${T.ink12}`, borderRadius: 13,
  padding: '12px 14px', fontSize: 16, color: T.ink, background: T.field, outline: 'none', fontFamily: 'inherit',
});
function fmtMoney(n, dp = 0) { return money(n, dp); }

// 1 — Export to Google Sheets
function ExportDialog({ open, onClose }) {
  const [range, setRange] = React.useState('This month');
  const opts = ['This month', 'Date range'];
  const [start, setStart] = React.useState('2026-05-01');
  const [end, setEnd] = React.useState(TODAY_ISO);
  const [sheet, setSheet] = React.useState(null); // 'start' | 'end' | null

  // keep end >= start
  React.useEffect(() => { if (end < start) setEnd(start); }, [start]);

  const datePill = (label, value, which) => (
    <button onClick={() => setSheet(which)} style={{
      flex: 1, display: 'flex', flexDirection: 'column', gap: 2, alignItems: 'flex-start',
      background: T.field, border: `1px solid ${T.ink12}`, borderRadius: 13, padding: '10px 14px',
      cursor: 'pointer', textAlign: 'left',
    }}>
      <span style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.4, color: T.ink40 }}>{label}</span>
      <span style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 15, fontWeight: 600, color: T.ink }}>
        <CalendarIcon size={16} sw={1.8} /> {dayLabelLong(value)}
      </span>
    </button>
  );

  return (
    <React.Fragment>
    <Dialog open={open} onClose={onClose}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <span style={{ width: 40, height: 40, borderRadius: 12, background: T.accent, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <ExportIcon size={22} sw={1.9} />
        </span>
        <h2 style={{ ...dlgTitle(), margin: 0 }}>Export to Google Sheets</h2>
      </div>
      <p style={dlgBody()}>Your transactions for the selected period will be sent to a new sheet in your Google account.</p>
      <span style={fieldLabel()}>WHAT GETS EXPORTED</span>
      <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 13, padding: 3, gap: 2, marginBottom: range === 'Date range' ? 12 : 20 }}>
        {opts.map(o => {
          const on = range === o;
          return (
            <button key={o} onClick={() => setRange(o)} style={{
              flex: 1, border: 'none', cursor: 'pointer', borderRadius: 11, padding: '9px 0',
              fontSize: 14, fontWeight: 600, color: on ? T.ink : T.ink40,
              background: on ? T.card : 'transparent', boxShadow: on ? '0 1px 3px rgba(42,42,42,0.12)' : 'none',
            }}>{o}</button>
          );
        })}
      </div>

      {range === 'Date range' && (
        <div style={{ display: 'flex', gap: 10, marginBottom: 20 }}>
          {datePill('FROM', start, 'start')}
          {datePill('TO', end, 'end')}
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <button style={btnPrimary()} onClick={onClose}>Export</button>
        <button style={btnGhost()} onClick={onClose}>Cancel</button>
      </div>
    </Dialog>

      <DatePickerSheet open={sheet === 'start'} date={start} title="From"
        onClose={() => setSheet(null)} onApply={(d) => setStart(d)} />
      <DatePickerSheet open={sheet === 'end'} date={end} title="To" minDate={start}
        onClose={() => setSheet(null)} onApply={(d) => setEnd(d)} />
    </React.Fragment>
  );
}

// 2 — Add / Edit category. `initial` (a category) switches to edit mode.
function AddCategoryDialog({ open, onClose, onSave, initial }) {
  const [name, setName] = React.useState('');
  const [iconType, setIconType] = React.useState('glyph'); // 'glyph' | 'emoji'
  const [icon, setIcon] = React.useState('Tag');
  const [color, setColor] = React.useState('#8CC0EB');
  const [budget, setBudget] = React.useState('');
  const colorInputRef = React.useRef(null);

  React.useEffect(() => {
    if (open) {
      setName(initial?.name || '');
      setIconType(initial?.iconType || 'glyph');
      setIcon(initial?.icon || 'Tag');
      setColor(initial?.color || '#8CC0EB');
      setBudget(initial?.budget != null ? String(initial.budget) : '');
    }
  }, [open, initial]);

  const save = () => {
    const trimmedBudget = budget.trim();
    onSave({
      name: name.trim(), iconType, icon, color,
      budget: trimmedBudget === '' ? null : (Number(trimmedBudget) || 0),
    });
    onClose();
  };

  const isCustomColor = !CAT_SWATCHES.includes(color);

  return (
    <Dialog open={open} onClose={onClose}>
      <h2 style={dlgTitle()}>{initial ? 'Edit category' : 'New category'}</h2>
      <p style={dlgBody()}>Group your transactions under a custom label.</p>

      <span style={fieldLabel()}>NAME</span>
      <input style={{ ...textField(), marginBottom: 18 }} placeholder="e.g. Transport" value={name} onChange={e => setName(e.target.value)} />

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 7 }}>
        <span style={{ ...fieldLabel(), margin: 0 }}>ICON</span>
        <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 999, padding: 2, gap: 2 }}>
          {['glyph', 'emoji'].map(tp => {
            const on = iconType === tp;
            return (
              <button key={tp} onClick={() => { setIconType(tp); setIcon(tp === 'glyph' ? 'Tag' : '🛒'); }} style={{
                border: 'none', cursor: 'pointer', borderRadius: 999, padding: '5px 13px',
                fontSize: 12.5, fontWeight: 600, color: on ? T.ink : T.ink40,
                background: on ? T.card : 'transparent', boxShadow: on ? '0 1px 2px rgba(42,42,42,0.12)' : 'none',
              }}>{tp === 'glyph' ? 'Icons' : 'Emoji'}</button>
            );
          })}
        </div>
      </div>

      {iconType === 'glyph' ? (
        <div style={{ display: 'flex', gap: 9, marginBottom: 18, flexWrap: 'wrap' }}>
          {CAT_ICON_KEYS.map(k => {
            const G = catIcon(k); const on = icon === k;
            return (
              <button key={k} onClick={() => setIcon(k)} style={{
                width: 46, height: 46, borderRadius: 13, cursor: 'pointer',
                background: on ? color : T.field, color: on ? T.tileInk : T.ink,
                border: on ? 'none' : `1px solid ${T.ink12}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><G size={22} sw={1.7} /></button>
            );
          })}
        </div>
      ) : (
        <div style={{ marginBottom: 18 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 8, marginBottom: 10 }}>
            {CAT_EMOJI.map(e => {
              const on = icon === e;
              return (
                <button key={e} onClick={() => setIcon(e)} style={{
                  height: 44, borderRadius: 12, cursor: 'pointer', fontSize: 22,
                  background: on ? color : T.field, border: on ? 'none' : `1px solid ${T.ink12}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>{e}</button>
              );
            })}
          </div>
          <input style={{ ...textField() }} maxLength={2} placeholder="…or type any emoji 😊"
            value={CAT_EMOJI.includes(icon) ? '' : icon}
            onChange={e => { const v = [...e.target.value].slice(-1).join(''); if (v) setIcon(v); }} />
        </div>
      )}

      <span style={fieldLabel()}>COLOR</span>
      <div style={{ display: 'flex', gap: 12, marginBottom: 22, alignItems: 'center' }}>
        {CAT_SWATCHES.map(c => {
          const on = color === c;
          return (
            <button key={c} onClick={() => setColor(c)} aria-label={c} style={{
              width: 34, height: 34, borderRadius: 999, cursor: 'pointer', background: c,
              border: on ? `2.5px solid ${T.ink}` : `1px solid rgba(42,42,42,0.12)`,
              boxShadow: on ? '0 0 0 2px #fff inset' : 'none',
            }} />
          );
        })}
        {/* custom color */}
        <button onClick={() => colorInputRef.current && colorInputRef.current.click()} aria-label="Custom color" style={{
          width: 34, height: 34, borderRadius: 999, cursor: 'pointer', position: 'relative',
          background: isCustomColor ? color : 'conic-gradient(from 0deg, #ff6b6b, #feca57, #48dbfb, #1dd1a1, #ff6b6b)',
          border: isCustomColor ? `2.5px solid ${T.ink}` : `1px solid rgba(42,42,42,0.12)`,
          boxShadow: isCustomColor ? '0 0 0 2px #fff inset' : 'none',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
        }}>
          {!isCustomColor && <PlusIcon size={16} sw={2.6} />}
          <input ref={colorInputRef} type="color" value={isCustomColor ? color : '#8CC0EB'}
            onChange={e => setColor(e.target.value)}
            style={{ position: 'absolute', inset: 0, opacity: 0, cursor: 'pointer', width: '100%', height: '100%', border: 'none', padding: 0 }} />
        </button>
      </div>

      <span style={fieldLabel()}>MONTHLY BUDGET · OPTIONAL</span>
      <div style={{ position: 'relative', marginBottom: 22 }}>
        <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: T.ink40, fontSize: 16, fontWeight: 600 }}>{CUR.symbol}</span>
        <input style={{ ...textField(), paddingLeft: 20 + CUR.symbol.length * 10 }} inputMode="numeric" placeholder="No budget" value={budget}
          onChange={e => setBudget(e.target.value.replace(/[^0-9.]/g, ''))} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <button style={{ ...btnPrimary(), opacity: name.trim() ? 1 : 0.45 }} disabled={!name.trim()} onClick={save}>Save</button>
        <button style={btnGhost()} onClick={onClose}>Cancel</button>
      </div>
    </Dialog>
  );
}

// 3 — Manage categories: list + edit + delete + add
function ManageCategoriesDialog({ open, onClose, cats, onEdit, onDelete, onAdd }) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth={340}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
        <h2 style={{ ...dlgTitle(), margin: 0 }}>Categories</h2>
        <button onClick={onClose} aria-label="Close" style={{
          width: 32, height: 32, borderRadius: 999, border: 'none', cursor: 'pointer',
          background: 'rgba(42,42,42,0.06)', color: T.ink, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}><CloseIcon size={17} sw={2} /></button>
      </div>
      <p style={dlgBody()}>Tap a category to edit it, or remove ones you don't use.</p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 18 }}>
        {cats.map(c => {
          return (
            <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '9px 10px', borderRadius: 14, background: T.field, border: `1px solid ${T.ink12}` }}>
              <button onClick={() => onEdit(c)} style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 1, background: 'none', border: 'none', cursor: 'pointer', textAlign: 'left', padding: 0 }}>
                <span style={{ width: 38, height: 38, borderRadius: 11, background: c.color, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <CatIcon cat={c} size={20} sw={1.7} />
                </span>
                <span style={{ flex: 1 }}>
                  <span style={{ display: 'block', fontSize: 16, fontWeight: 600, color: T.ink }}>{c.name}</span>
                  <span style={{ display: 'block', fontSize: 13, color: T.ink40, fontVariantNumeric: 'tabular-nums' }}>{c.budget != null ? `${fmtMoney(c.budget)}/mo` : 'No budget'}</span>
                </span>
              </button>
              <button onClick={() => onDelete(c.id)} aria-label={`Delete ${c.name}`} style={{
                width: 34, height: 34, borderRadius: 10, border: 'none', cursor: 'pointer',
                background: 'rgba(42,42,42,0.05)', color: T.ink60, display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><TrashIcon size={18} sw={1.8} /></button>
            </div>
          );
        })}
      </div>

      <button style={btnPrimary()} onClick={onAdd}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}><PlusIcon size={18} sw={2.4} /> Add category</span>
      </button>
    </Dialog>
  );
}

// 4 — Budget editor (from Insights). category + monthly budget number field.
function BudgetDialog({ open, onClose, category, onSave }) {
  const [budget, setBudget] = React.useState('');
  React.useEffect(() => { if (open && category) setBudget(category.budget != null ? String(category.budget) : ''); }, [open, category]);
  if (!category) return <Dialog open={open} onClose={onClose}><div /></Dialog>;
  return (
    <Dialog open={open} onClose={onClose}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
        <span style={{ width: 42, height: 42, borderRadius: 13, background: category.color, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <CatIcon cat={category} size={22} sw={1.8} />
        </span>
        <div>
          <h2 style={{ ...dlgTitle(), margin: 0 }}>{category.name}</h2>
          <div style={{ fontSize: 13.5, color: T.ink40 }}>Monthly budget</div>
        </div>
      </div>

      <div style={{ position: 'relative', marginBottom: 22 }}>
        <span style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', color: T.ink40, fontSize: 22, fontWeight: 600 }}>{CUR.symbol}</span>
        <input autoFocus style={{ ...textField(), fontSize: 28, fontWeight: 700, padding: '16px 14px', paddingLeft: 22 + CUR.symbol.length * 14, fontVariantNumeric: 'tabular-nums' }}
          inputMode="numeric" placeholder="No budget" value={budget}
          onChange={e => setBudget(e.target.value.replace(/[^0-9.]/g, ''))} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <button style={btnPrimary()} onClick={() => { const b = budget.trim(); onSave(b === '' ? null : (Number(b) || 0)); onClose(); }}>Save budget</button>
        <button style={btnGhost()} onClick={onClose}>Cancel</button>
      </div>
    </Dialog>
  );
}

// 4b — Set budget (from Preferences). Two modes: one general monthly total,
// or per-category budgets that sum into the total.
function SetBudgetDialog({ open, onClose, cats = [], budget, onSave }) {
  const [mode, setMode] = React.useState('category');
  const [total, setTotal] = React.useState('');           // general mode amount
  const [catVals, setCatVals] = React.useState({});       // { catId: string }

  React.useEffect(() => {
    if (!open) return;
    setMode(budget?.mode || 'category');
    setTotal(budget?.total != null ? String(budget.total) : '');
    const m = {};
    cats.forEach(c => { m[c.id] = c.budget != null ? String(c.budget) : ''; });
    setCatVals(m);
  }, [open, budget, cats]);

  const clean = (s) => (s || '').replace(/[^0-9.]/g, '');
  const catSum = cats.reduce((s, c) => s + (Number(catVals[c.id]) || 0), 0);

  const save = () => {
    if (mode === 'general') {
      const t = clean(total).trim();
      onSave({ mode: 'general', total: t === '' ? 0 : Number(t) || 0 });
    } else {
      const catBudgets = {};
      cats.forEach(c => { const v = clean(catVals[c.id]).trim(); catBudgets[c.id] = v === '' ? null : Number(v) || 0; });
      onSave({ mode: 'category', total: catSum, catBudgets });
    }
    onClose();
  };

  const amountField = (value, onChange, opts = {}) => (
    <div style={{ position: 'relative', ...opts.wrap }}>
      <span style={{ position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)', color: T.ink40, fontSize: opts.big ? 22 : 15, fontWeight: 600 }}>{CUR.symbol}</span>
      <input inputMode="numeric" placeholder={opts.placeholder || '0'} value={value}
        onChange={e => onChange(clean(e.target.value))}
        style={{
          ...textField(), textAlign: opts.big ? 'left' : 'right',
          fontSize: opts.big ? 28 : 16, fontWeight: opts.big ? 700 : 600,
          padding: opts.big ? '16px 14px' : '11px 14px',
          paddingLeft: (opts.big ? 22 : 18) + CUR.symbol.length * (opts.big ? 14 : 9),
          fontVariantNumeric: 'tabular-nums',
        }} />
    </div>
  );

  return (
    <Dialog open={open} onClose={onClose} maxWidth={340}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <span style={{ width: 42, height: 42, borderRadius: 13, background: T.accent, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <TargetIcon size={22} sw={1.9} />
        </span>
        <h2 style={{ ...dlgTitle(), margin: 0 }}>Set budget</h2>
      </div>

      <span style={fieldLabel()}>BUDGET TYPE</span>
      <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 13, padding: 3, gap: 2, marginBottom: 8 }}>
        {[['general', 'Total'], ['category', 'By category']].map(([m, label]) => {
          const on = mode === m;
          return (
            <button key={m} onClick={() => setMode(m)} style={{
              flex: 1, border: 'none', cursor: 'pointer', borderRadius: 11, padding: '9px 0',
              fontSize: 14, fontWeight: 600, color: on ? T.ink : T.ink40,
              background: on ? T.card : 'transparent', boxShadow: on ? '0 1px 3px rgba(42,42,42,0.12)' : 'none',
            }}>{label}</button>
          );
        })}
      </div>
      <p style={{ ...dlgBody(), marginBottom: 18 }}>
        {mode === 'general'
          ? 'One monthly limit for everything you spend.'
          : 'Give each category its own limit — they add up to your total.'}
      </p>

      {mode === 'general' ? (
        <div style={{ marginBottom: 22 }}>
          <span style={fieldLabel()}>MONTHLY BUDGET</span>
          {amountField(total, setTotal, { big: true, placeholder: 'No budget' })}
        </div>
      ) : (
        <div style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 14 }}>
            {cats.map(c => (
              <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ width: 38, height: 38, borderRadius: 11, background: c.color, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <CatIcon cat={c} size={20} sw={1.7} />
                </span>
                <span style={{ flex: 1, fontSize: 16, fontWeight: 600, color: T.ink }}>{c.name}</span>
                <div style={{ width: 116 }}>
                  {amountField(catVals[c.id] || '', (v) => setCatVals(p => ({ ...p, [c.id]: v })), { placeholder: '0' })}
                </div>
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px', background: T.field, borderRadius: 14, border: `1px solid ${T.ink12}` }}>
            <span style={{ fontSize: 15, fontWeight: 600, color: T.ink60 }}>Total monthly budget</span>
            <span style={{ fontSize: 19, fontWeight: 700, color: T.ink, letterSpacing: -0.3, fontVariantNumeric: 'tabular-nums' }}>{fmtMoney(catSum)}</span>
          </div>
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <button style={btnPrimary()} onClick={save}>Save budget</button>
        <button style={btnGhost()} onClick={onClose}>Cancel</button>
      </div>
    </Dialog>
  );
}

// 5 — Report a bug
function BugDialog({ open, onClose }) {
  const [desc, setDesc] = React.useState('');
  const [shot, setShot] = React.useState(null); // { name, url } | null
  const fileRef = React.useRef(null);

  // reset + free the object URL when the dialog closes
  React.useEffect(() => {
    if (!open) {
      setDesc('');
      setShot(s => { if (s?.url) URL.revokeObjectURL(s.url); return null; });
    }
  }, [open]);

  const pick = (e) => {
    const f = e.target.files && e.target.files[0];
    if (!f) return;
    setShot(s => { if (s?.url) URL.revokeObjectURL(s.url); return { name: f.name, url: URL.createObjectURL(f) }; });
    e.target.value = ''; // allow re-picking the same file
  };
  const remove = () => setShot(s => { if (s?.url) URL.revokeObjectURL(s.url); return null; });

  return (
    <Dialog open={open} onClose={onClose}>
      <h2 style={dlgTitle()}>Report a bug</h2>
      <p style={dlgBody()}>Tell us what went wrong — the more detail, the faster we can fix it.</p>
      <span style={fieldLabel()}>WHAT HAPPENED</span>
      <textarea style={{ ...textField(), height: 96, resize: 'none', marginBottom: 16 }}
        placeholder="Describe the issue…" value={desc} onChange={e => setDesc(e.target.value)} />

      <span style={fieldLabel()}>SCREENSHOT · OPTIONAL</span>
      <input ref={fileRef} type="file" accept="image/*" onChange={pick}
        style={{ position: 'absolute', width: 1, height: 1, opacity: 0, pointerEvents: 'none' }} />
      {shot ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: 10, border: `1px solid ${T.ink12}`, borderRadius: 13, marginBottom: 22, background: T.field }}>
          <img src={shot.url} alt="" style={{ width: 40, height: 52, objectFit: 'cover', borderRadius: 7, background: T.card, border: `1px solid ${T.ink12}`, flexShrink: 0 }} />
          <span style={{ flex: 1, minWidth: 0 }}>
            <span style={{ display: 'block', fontSize: 14, fontWeight: 600, color: T.ink, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{shot.name}</span>
            <button onClick={() => fileRef.current && fileRef.current.click()} style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer', fontSize: 12.5, fontWeight: 600, color: T.accentInk || T.ink60, fontFamily: 'inherit' }}>Replace</button>
          </span>
          <button onClick={remove} aria-label="Remove screenshot" style={{
            width: 30, height: 30, borderRadius: 999, border: 'none', cursor: 'pointer', flexShrink: 0,
            background: 'rgba(42,42,42,0.06)', color: T.ink60, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><CloseIcon size={15} sw={2} /></button>
        </div>
      ) : (
        <button onClick={() => fileRef.current && fileRef.current.click()} style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%',
          padding: '13px 0', borderRadius: 13, cursor: 'pointer', border: `1.5px dashed ${T.ink12}`,
          background: 'transparent', color: T.ink, fontSize: 15, fontWeight: 600, marginBottom: 22, fontFamily: 'inherit',
        }}>
          <PhotoIcon size={18} sw={1.9} /> Add screenshot
        </button>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        <button style={{ ...btnPrimary(), opacity: desc ? 1 : 0.45 }} disabled={!desc} onClick={onClose}>Send</button>
        <button style={btnGhost()} onClick={onClose}>Cancel</button>
      </div>
    </Dialog>
  );
}

// 6 — Theme picker (Light / Dark / System)
function ThemeDialog({ open, onClose, value, onChange }) {
  const opts = [
    { id: 'light', label: 'Light', sub: 'Always light', Icon: SunIcon },
    { id: 'dark', label: 'Dark', sub: 'Always dark', Icon: MoonIcon },
    { id: 'system', label: 'Automatic', sub: 'Match device appearance', Icon: GearIcon },
  ];
  return (
    <Dialog open={open} onClose={onClose}>
      <h2 style={dlgTitle()}>Appearance</h2>
      <p style={dlgBody()}>Choose how the app looks. Automatic follows your device's light or dark setting.</p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
        {opts.map(o => {
          const on = value === o.id;
          return (
            <button key={o.id} onClick={() => { onChange(o.id); onClose(); }} style={{
              display: 'flex', alignItems: 'center', gap: 13, padding: '12px 14px', borderRadius: 14,
              cursor: 'pointer', textAlign: 'left', width: '100%',
              background: on ? T.accent : T.field,
              border: on ? 'none' : `1px solid ${T.ink12}`,
            }}>
              <span style={{ width: 34, height: 34, borderRadius: 10, background: on ? 'rgba(255,255,255,0.5)' : T.card, color: T.tileInk, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <o.Icon size={19} sw={1.8} />
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
      <button style={btnGhost()} onClick={onClose}>Done</button>
    </Dialog>
  );
}

// 7 — Currency picker
function CurrencyDialog({ open, onClose, value, onChange }) {
  return (
    <Dialog open={open} onClose={onClose}>
      <h2 style={dlgTitle()}>Currency</h2>
      <p style={dlgBody()}>Pick the currency symbol used across the app. Amounts aren't converted.</p>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 7, marginBottom: 18 }}>
        {CURRENCIES.map(c => {
          const on = value === c.code;
          return (
            <button key={c.code} onClick={() => { onChange(c.code); onClose(); }} style={{
              display: 'flex', alignItems: 'center', gap: 13, padding: '11px 14px', borderRadius: 13,
              cursor: 'pointer', textAlign: 'left', width: '100%',
              background: on ? T.accent : T.field,
              border: on ? 'none' : `1px solid ${T.ink12}`,
            }}>
              <span style={{ width: 38, height: 38, borderRadius: 10, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: `inset 0 0 0 1px ${T.ink12}`, background: T.card, color: T.tileInk, fontSize: 15, fontWeight: 700 }}>
                <img src={flagSrc(c.cc)} alt={c.code} width="38" height="38"
                  style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                  onError={(e) => { e.target.style.display = 'none'; e.target.parentNode.textContent = c.symbol; }} />
              </span>
              <span style={{ flex: 1 }}>
                <span style={{ display: 'block', fontSize: 16, fontWeight: 600, color: on ? T.tileInk : T.ink }}>{c.code}</span>
                <span style={{ display: 'block', fontSize: 13, color: on ? 'rgba(42,42,42,0.6)' : T.ink40 }}>{c.name}</span>
              </span>
              {on && <span style={{ color: T.tileInk, display: 'flex' }}><CheckIcon size={20} sw={2.4} /></span>}
            </button>
          );
        })}
      </div>
      <button style={btnGhost()} onClick={onClose}>Done</button>
    </Dialog>
  );
}

Object.assign(window, { ExportDialog, AddCategoryDialog, ManageCategoriesDialog, BudgetDialog, SetBudgetDialog, BugDialog, ThemeDialog, CurrencyDialog });
