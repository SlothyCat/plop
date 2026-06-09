// store.jsx — single source of truth for categories (localStorage-backed).
// A category: { id, name, icon (registry key), color, budget (monthly) }.
const CAT_ICON_REGISTRY = {
  School: window.SchoolIcon,
  Food:   window.FoodIcon,
  Subs:   window.SubsIcon,
  Tag:    window.TagIcon,
  Dollar: window.DollarIcon,
  Grid:   window.GridIcon,
};
const CAT_ICON_KEYS = ['School', 'Food', 'Subs', 'Tag', 'Dollar', 'Grid'];
function catIcon(key) { return CAT_ICON_REGISTRY[key] || window.TagIcon; }

// Curated emoji palette for category icons (user can also type any emoji).
const CAT_EMOJI = ['🎓', '🍔', '📺', '🚗', '🏠', '✈️', '🛒', '💡', '🐶', '💪', '🎁', '💰', '☕', '🎮', '👕', '💊', '🎵', '🧾'];

// Renders a category's icon — either a line glyph or an emoji.
function CatIcon({ cat, size = 22, sw = 1.7 }) {
  if (cat && cat.iconType === 'emoji') {
    return <span style={{ fontSize: Math.round(size * 0.92), lineHeight: 1 }}>{cat.icon}</span>;
  }
  const G = catIcon(cat ? cat.icon : 'Tag');
  return <G size={size} sw={sw} />;
}

const CAT_SWATCHES = ['#8CC0EB', '#BFDDF0', '#FFEBCC', '#FFF9D2'];

const DEFAULT_CATS = [
  { id: 'school', name: 'School',        iconType: 'glyph', icon: 'School', color: '#8CC0EB', budget: 900 },
  { id: 'food',   name: 'Food',          iconType: 'glyph', icon: 'Food',   color: '#FFEBCC', budget: 300 },
  { id: 'subs',   name: 'Subscriptions', iconType: 'glyph', icon: 'Subs',   color: '#FFF9D2', budget: 120 },
];

// Sample spend per category, by period (transaction-derived in a real app).
const SPENT = {
  'This Month': { School: 842.30, Food: 214.75, Subscriptions: 96.00 },
  'This Year':  { School: 9640.00, Food: 3180.40, Subscriptions: 2000.00 },
};
const YEAR_MULT = 12; // year budget = monthly budget × 12

function useCategories() {
  const [cats, setCats] = React.useState(() => {
    try { const s = localStorage.getItem('cats_v1'); return s ? JSON.parse(s) : DEFAULT_CATS; }
    catch { return DEFAULT_CATS; }
  });
  React.useEffect(() => {
    try { localStorage.setItem('cats_v1', JSON.stringify(cats)); } catch {}
  }, [cats]);

  const addCat = (c) => setCats(p => [...p, { ...c, id: 'c' + Date.now() }]);
  const updateCat = (id, patch) => setCats(p => p.map(c => c.id === id ? { ...c, ...patch } : c));
  const deleteCat = (id) => setCats(p => p.filter(c => c.id !== id));
  const resetCats = () => setCats(DEFAULT_CATS);
  return { cats, addCat, updateCat, deleteCat, resetCats };
}

function catByName(cats, name) { return cats.find(c => c.name === name); }

// ── Currency ─────────────────────────────────────────────────────────────────
// Symbol/format only — values are stored as entered (no FX conversion).
// JPY & KRW use 0 decimal places by convention.
const CURRENCIES = [
  { code: 'USD', symbol: '$',   dp: 2, name: 'US Dollar',          cc: 'us' },
  { code: 'EUR', symbol: '€',   dp: 2, name: 'Euro',               cc: 'eu' },
  { code: 'CNY', symbol: '¥',   dp: 2, name: 'Chinese Yuan (RMB)', cc: 'cn' },
  { code: 'SGD', symbol: 'S$',  dp: 2, name: 'Singapore Dollar',   cc: 'sg' },
  { code: 'AUD', symbol: 'A$',  dp: 2, name: 'Australian Dollar',  cc: 'au' },
  { code: 'CAD', symbol: 'C$',  dp: 2, name: 'Canadian Dollar',    cc: 'ca' },
  { code: 'HKD', symbol: 'HK$', dp: 2, name: 'Hong Kong Dollar',   cc: 'hk' },
  { code: 'JPY', symbol: 'JP¥', dp: 0, name: 'Japanese Yen',       cc: 'jp' },
  { code: 'KRW', symbol: '₩',   dp: 0, name: 'South Korean Won',   cc: 'kr' },
];
// Square (1x1) flag SVGs from flag-icons (MIT licensed); flags are public domain.
function flagSrc(cc) { return `https://cdn.jsdelivr.net/npm/flag-icons@7.5.0/flags/1x1/${cc}.svg`; }
const CUR = { ...CURRENCIES[0] };
function applyCurrency(code) {
  const c = CURRENCIES.find(x => x.code === code) || CURRENCIES[0];
  Object.assign(CUR, c);
}
function useCurrency() {
  const [code, setCode] = React.useState(() => { try { return localStorage.getItem('currency_v1') || 'USD'; } catch { return 'USD'; } });
  const set = (c) => { setCode(c); try { localStorage.setItem('currency_v1', c); } catch {} };
  return [code, set];
}

// ── Budget ────────────────────────────────────────────────────────────────
// mode 'general'  → one monthly total, categories ignored
// mode 'category' → per-category budgets (stored on each category) summed
const DEFAULT_BUDGET = { mode: 'category', total: 1320 };
function useBudget() {
  const [budget, setBudget] = React.useState(() => {
    try { const s = localStorage.getItem('budget_v1'); return s ? { ...DEFAULT_BUDGET, ...JSON.parse(s) } : DEFAULT_BUDGET; }
    catch { return DEFAULT_BUDGET; }
  });
  React.useEffect(() => { try { localStorage.setItem('budget_v1', JSON.stringify(budget)); } catch {} }, [budget]);
  const setMode = (mode) => setBudget(b => ({ ...b, mode }));
  const setTotal = (total) => setBudget(b => ({ ...b, total }));
  return { budget, setMode, setTotal };
}
// money helper honoring the active currency; dp clamps to the currency's max.
function money(n, dp) {
  const d = Math.min(dp == null ? CUR.dp : dp, CUR.dp);
  return CUR.symbol + Number(n).toLocaleString('en-US', { minimumFractionDigits: d, maximumFractionDigits: d });
}

// ── Transactions ─────────────────────────────────────────────────────────
// tx: { id, catName, amount (positive), type 'expense'|'income', note, date (ISO yyyy-mm-dd), time ('HH:MM' 24h), ts }
const TODAY_ISO = '2026-05-30'; // app's "today" anchor (matches current date)

const DEFAULT_TX = [
  // ── This week (week containing 2026-05-30) ──
  { id: 't1', catName: 'School',        amount: 612.00, type: 'expense', note: 'Semester tuition', date: '2026-05-29', time: '22:41', ts: 220 },
  { id: 't2', catName: 'School',        amount: 5.10,   type: 'expense', note: '', date: '2026-05-29', time: '13:16', ts: 210 },
  { id: 't3', catName: 'Food',          amount: 4.00,   type: 'expense', note: 'Coffee run', date: '2026-05-29', time: '13:16', ts: 209 },
  { id: 't4', catName: 'Food',          amount: 4.00,   type: 'expense', note: '', date: '2026-05-26', time: '11:01', ts: 130 },
  { id: 't5', catName: 'Food',          amount: 1.50,   type: 'expense', note: '', date: '2026-05-26', time: '11:01', ts: 129 },
  { id: 't6', catName: 'Subscriptions', amount: 6.48,   type: 'expense', note: 'Music', date: '2026-05-26', time: '00:08', ts: 120 },
  // ── Earlier this month (before this week — shows under Month, not Week) ──
  { id: 't7',  catName: 'Food',          amount: 38.20,  type: 'expense', note: 'Groceries', date: '2026-05-12', time: '18:30', ts: 95 },
  { id: 't8',  catName: 'Subscriptions', amount: 14.99,  type: 'expense', note: 'Streaming', date: '2026-05-05', time: '09:00', ts: 90 },
  { id: 't9',  catName: 'School',        amount: 1200.00, type: 'income',  note: 'Scholarship', date: '2026-05-02', time: '10:00', ts: 88 },
  // ── Earlier this year (before May — shows under Year, not Month) ──
  { id: 't10', catName: 'Food',          amount: 52.40,  type: 'expense', note: 'Dinner', date: '2026-03-18', time: '20:15', ts: 60 },
  { id: 't11', catName: 'School',        amount: 430.00, type: 'expense', note: 'Textbooks', date: '2026-02-09', time: '14:22', ts: 55 },
  { id: 't12', catName: 'Subscriptions', amount: 9.99,   type: 'expense', note: 'Cloud storage', date: '2026-01-15', time: '08:45', ts: 50 },
  // ── Last year (2025 — shows only when no period filter would include it) ──
  { id: 't13', catName: 'Food',          amount: 27.80,  type: 'expense', note: 'Takeout', date: '2025-11-22', time: '19:40', ts: 40 },
  { id: 't14', catName: 'School',        amount: 612.00, type: 'expense', note: 'Fall tuition', date: '2025-09-01', time: '12:00', ts: 35 },
  // ── Two years ago (2024) ──
  { id: 't15', catName: 'Subscriptions', amount: 5.99,   type: 'expense', note: 'Old plan', date: '2024-07-10', time: '16:00', ts: 20 },
];

function useTransactions() {
  const [txs, setTxs] = React.useState(() => {
    try { const s = localStorage.getItem('txs_v3'); return s ? JSON.parse(s) : DEFAULT_TX; }
    catch { return DEFAULT_TX; }
  });
  React.useEffect(() => {
    try { localStorage.setItem('txs_v3', JSON.stringify(txs)); } catch {}
  }, [txs]);

  const nowTime = () => { const d = new Date(); return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0'); };
  const addTx = (t) => setTxs(p => [{ date: TODAY_ISO, time: nowTime(), ...t, id: 't' + Date.now(), ts: Date.now() }, ...p]);
  const updateTx = (id, patch) => setTxs(p => p.map(t => t.id === id ? { ...t, ...patch } : t));
  const deleteTx = (id) => setTxs(p => p.filter(t => t.id !== id));
  return { txs, addTx, updateTx, deleteTx };
}

// signed amount: expense negative, income positive
function signed(t) { return t.type === 'income' ? t.amount : -t.amount; }
function fmtAmt(n, withPlus) {
  const sign = n < 0 ? '-' : (withPlus ? '+' : '');
  return sign + CUR.symbol + Math.abs(n).toLocaleString('en-US', { minimumFractionDigits: CUR.dp, maximumFractionDigits: CUR.dp });
}
// '13:16' (24h) → '1:16 PM'
function fmtTime(t) {
  if (!t) return '';
  const [h, m] = t.split(':').map(Number);
  const ap = h >= 12 ? 'PM' : 'AM';
  const h12 = ((h + 11) % 12) + 1;
  return `${h12}:${String(m).padStart(2, '0')} ${ap}`;
}
// ISO date → group header label relative to TODAY_ISO
function dayLabel(iso) {
  if (iso === TODAY_ISO) return 'TODAY';
  const d = new Date(iso + 'T00:00'), today = new Date(TODAY_ISO + 'T00:00');
  const diff = Math.round((today - d) / 86400000);
  if (diff === 1) return 'YESTERDAY';
  const wd = d.toLocaleDateString('en-US', { weekday: 'short' });
  const mo = d.toLocaleDateString('en-US', { month: 'short' });
  return `${wd}, ${d.getDate()} ${mo}`.toUpperCase();
}
// full date for the entry pill, e.g. 'Today' or 'Fri, 29 May'
function dayLabelLong(iso) {
  if (iso === TODAY_ISO) return 'Today';
  const d = new Date(iso + 'T00:00'), today = new Date(TODAY_ISO + 'T00:00');
  const diff = Math.round((today - d) / 86400000);
  if (diff === 1) return 'Yesterday';
  const wd = d.toLocaleDateString('en-US', { weekday: 'short' });
  const mo = d.toLocaleDateString('en-US', { month: 'short' });
  return `${wd}, ${d.getDate()} ${mo}`;
}
// group txs by ISO date, newest day first, newest time first within a day
function groupTx(txs) {
  const map = {};
  txs.forEach(t => { (map[t.date] = map[t.date] || []).push(t); });
  return Object.keys(map).sort((a, b) => b.localeCompare(a)).map(date => {
    const rows = map[date].slice().sort((a, b) => (b.time || '').localeCompare(a.time || ''));
    const subtotal = rows.reduce((s, t) => s + signed(t), 0);
    return { day: dayLabel(date), date, rows, subtotal };
  });
}

Object.assign(window, {
  CAT_ICON_REGISTRY, CAT_ICON_KEYS, catIcon, CatIcon, CAT_EMOJI, CAT_SWATCHES,
  DEFAULT_CATS, SPENT, YEAR_MULT, useCategories, catByName, useBudget,
  DEFAULT_TX, TODAY_ISO, useTransactions, signed, fmtAmt, fmtTime, dayLabel, dayLabelLong, groupTx,
  CURRENCIES, CUR, applyCurrency, useCurrency, money, flagSrc,
});
