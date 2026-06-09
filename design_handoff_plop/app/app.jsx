// app.jsx — root: hosts tab + category store + dialogs inside the iOS frame
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "appBg": "#DCEBF7",
  "insightsView": "budget"
}/*EDITMODE-END*/;

// Track the device's light/dark preference (for theme = Automatic).
function useSystemDark() {
  const [d, setD] = React.useState(() => !!(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches));
  React.useEffect(() => {
    if (!window.matchMedia) return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const fn = e => setD(e.matches);
    mq.addEventListener ? mq.addEventListener('change', fn) : mq.addListener(fn);
    return () => { mq.removeEventListener ? mq.removeEventListener('change', fn) : mq.removeListener(fn); };
  }, []);
  return d;
}

// Persisted theme mode: 'light' | 'dark' | 'system'.
function useThemeMode() {
  const [mode, setMode] = React.useState(() => { try { return localStorage.getItem('theme_v1') || 'light'; } catch { return 'light'; } });
  const set = (m) => { setMode(m); try { localStorage.setItem('theme_v1', m); } catch {} };
  return [mode, set];
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const { cats, addCat, updateCat, deleteCat } = useCategories();
  const { txs, addTx, updateTx, deleteTx } = useTransactions();

  const [themeMode, setThemeMode] = useThemeMode();
  const systemDark = useSystemDark();
  const isDark = themeMode === 'dark' || (themeMode === 'system' && systemDark);
  applyTheme(isDark); // mutate the live T tokens before children render

  const [currency, setCurrency] = useCurrency();
  applyCurrency(currency); // mutate the live CUR token before children render

  const { budget, setMode: setBudgetMode, setTotal: setBudgetTotal } = useBudget();

  const [tab, setTab] = React.useState('home');
  const [entry, setEntry] = React.useState(false);
  const [editingTx, setEditingTx] = React.useState(null); // tx being edited, or null = add
  const [dialog, setDialog] = React.useState(null); // 'export'|'manage'|'category'|'budget'|'bug'
  const [editingCat, setEditingCat] = React.useState(null);
  const [budgetCat, setBudgetCat] = React.useState(null);
  const [returnToManage, setReturnToManage] = React.useState(false);

  const bg = isDark ? T.bg : t.appBg;
  const isHome = tab === 'home';
  const themeLabel = themeMode === 'system' ? 'Automatic' : (themeMode === 'dark' ? 'Dark' : 'Light');

  // Monthly budget total: a single figure in general mode, or the sum of
  // per-category budgets in category mode.
  const catBudgetSum = cats.reduce((s, c) => s + (c.budget || 0), 0);
  const budgetMonthlyTotal = budget.mode === 'general' ? (budget.total || 0) : catBudgetSum;
  const budgetLabel = budgetMonthlyTotal > 0
    ? money(budgetMonthlyTotal, 0) + '/mo'
    : 'Off';

  // Persist the chosen budget: general writes the single total; category
  // writes each category's budget and recomputes the summed total.
  const saveBudget = ({ mode, total, catBudgets }) => {
    setBudgetMode(mode);
    if (mode === 'general') {
      setBudgetTotal(total);
    } else {
      if (catBudgets) Object.entries(catBudgets).forEach(([id, v]) => updateCat(id, { budget: v }));
      setBudgetTotal(total);
    }
  };

  // Spend per category, derived from transactions, for each period the
  // Insights screen can show. Single source of truth = the same `txs` Home uses.
  const spentByPeriod = React.useMemo(() => {
    const ym = TODAY_ISO.slice(0, 7);  // current year-month, e.g. '2026-05'
    const yr = TODAY_ISO.slice(0, 4);  // current year, e.g. '2026'
    const month = {}, year = {};
    txs.forEach(tx => {
      if (tx.type !== 'expense' || !tx.catName || !tx.date) return;
      if (tx.date.slice(0, 4) === yr) year[tx.catName] = (year[tx.catName] || 0) + tx.amount;
      if (tx.date.slice(0, 7) === ym) month[tx.catName] = (month[tx.catName] || 0) + tx.amount;
    });
    return { 'This Month': month, 'This Year': year };
  }, [txs]);

  const openAdd = (fromManage) => { setEditingCat(null); setReturnToManage(!!fromManage); setDialog('category'); };
  const openEdit = (c) => { setEditingCat(c); setReturnToManage(true); setDialog('category'); };
  const closeCatDialog = () => { setDialog(returnToManage ? 'manage' : null); };
  const saveCat = (data) => { if (editingCat) updateCat(editingCat.id, data); else addCat(data); };

  const openAddTx = () => { setEditingTx(null); setEntry(true); };
  const openEditTx = (tx) => { setEditingTx(tx); setEntry(true); };
  const submitTx = (data) => {
    if (editingTx) updateTx(editingTx.id, data); else addTx(data);
    setEntry(false); setEditingTx(null);
  };
  const removeTx = () => { if (editingTx) deleteTx(editingTx.id); setEntry(false); setEditingTx(null); };

  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh', padding: 28, background: T.pageBg }}>
      <IOSDevice width={393} height={852} dark={isDark}>
        <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', fontFamily: T.font }}>
          {tab === 'home' && <HomeScreen bg={bg} cats={cats} txs={txs} onEditTx={openEditTx} />}
          {tab === 'insights' && <InsightsScreen bg={bg} cats={cats} spentByPeriod={spentByPeriod} budget={budget}
            mode={t.insightsView === 'budget' ? 'budget' : 'breakdown'}
            onEditBudget={(c) => { setBudgetCat(c); setDialog('budget'); }} />}
          {tab === 'settings' && <SettingsScreen bg={bg}
            themeLabel={themeLabel}
            currencyLabel={CUR.code + '  ' + CUR.symbol}
            budgetLabel={budgetLabel}
            onExport={() => setDialog('export')}
            onBudget={() => setDialog('setbudget')}
            onCategory={() => setDialog('manage')}
            onCurrency={() => setDialog('currency')}
            onTheme={() => setDialog('theme')}
            onBug={() => setDialog('bug')} />}

          <TabBar active={tab} onTab={setTab} />

          {/* Context-aware center button — seated in the routing bar. On Home
              it adds; elsewhere it returns you Home. */}
          <div style={{ position: 'absolute', left: '50%', bottom: 30, transform: 'translateX(-50%)', zIndex: 45 }}>
            <CenterButton
              size={56}
              icon={isHome ? PlusIcon : HomeIcon}
              halo={isHome}
              label={isHome ? 'Add' : 'Home'}
              onClick={isHome ? openAddTx : () => setTab('home')}
            />
          </div>

          {/* Entry slides up over everything — add or edit */}
          <div style={{
            position: 'absolute', inset: 0, zIndex: 70,
            transform: entry ? 'translateY(0)' : 'translateY(100%)',
            transition: 'transform 360ms cubic-bezier(0.32, 0.72, 0, 1)',
            pointerEvents: entry ? 'auto' : 'none',
          }}>
            <EntryScreen onClose={() => { setEntry(false); setEditingTx(null); }} bg={bg} cats={cats}
              editing={editingTx} onSubmit={submitTx} onDelete={removeTx}
              onAddCategory={() => openAdd(false)} />
          </div>

          {/* Dialogs — above the entry sheet */}
          <ExportDialog open={dialog === 'export'} onClose={() => setDialog(null)} />
          <ManageCategoriesDialog open={dialog === 'manage'} onClose={() => setDialog(null)}
            cats={cats} onEdit={openEdit} onDelete={deleteCat} onAdd={() => openAdd(true)} />
          <AddCategoryDialog open={dialog === 'category'} onClose={closeCatDialog}
            onSave={saveCat} initial={editingCat} />
          <BudgetDialog open={dialog === 'budget'} onClose={() => setDialog(null)}
            category={budgetCat} onSave={(v) => budgetCat && updateCat(budgetCat.id, { budget: v })} />
          <SetBudgetDialog open={dialog === 'setbudget'} onClose={() => setDialog(null)}
            cats={cats} budget={budget} onSave={saveBudget} />
          <BugDialog open={dialog === 'bug'} onClose={() => setDialog(null)} />
          <ThemeDialog open={dialog === 'theme'} onClose={() => setDialog(null)}
            value={themeMode} onChange={setThemeMode} />
          <CurrencyDialog open={dialog === 'currency'} onClose={() => setDialog(null)}
            value={currency} onChange={setCurrency} />
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="Appearance" />
        <TweakRadio label="Theme" value={themeMode}
          options={['light', 'dark', 'system']}
          onChange={setThemeMode} />
        <TweakColor label="Light background" value={t.appBg}
          options={['#DCEBF7', '#E6F1FA', '#CBE2F4', '#D8E9F2']}
          onChange={(v) => setTweak('appBg', v)} />
        <TweakSection label="Insights" />
        <TweakRadio label="View" value={t.insightsView}
          options={['breakdown', 'budget']}
          onChange={(v) => setTweak('insightsView', v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
