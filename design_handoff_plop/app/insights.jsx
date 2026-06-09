// insights.jsx — Tab 2: Insights
//   mode 'breakdown' → donut of spend split (center = total spent)
//   mode 'budget'    → donut of spend vs total budget (center = remaining);
//                      legend rows show per-category budget bars and are
//                      tappable to edit that category's monthly budget.
function fmt(n, dp) {
  return money(n, dp);
}

function PeriodToggle({ value, onChange }) {
  const opts = ['This Month', 'This Year'];
  return (
    <div style={{ display: 'flex', background: 'rgba(42,42,42,0.06)', borderRadius: 999, padding: 3, gap: 2 }}>
      {opts.map((o) => {
        const on = value === o;
        return (
          <button key={o} onClick={() => onChange(o)} style={{
            border: 'none', cursor: 'pointer', borderRadius: 999, padding: '7px 16px',
            fontSize: 13.5, fontWeight: 600, letterSpacing: -0.1,
            color: on ? T.ink : T.ink40,
            background: on ? T.card : 'transparent',
            boxShadow: on ? '0 1px 3px rgba(42,42,42,0.12)' : 'none'
          }}>{o}</button>);

      })}
    </div>);

}

function Donut({ rows, denom, animKey, center }) {
  const size = 216,sw = 30,r = (size - sw) / 2,C = 2 * Math.PI * r;
  const gap = 0.012 * C;
  const SWEEP = 1100; // total ms for the whole ring to draw
  const FADE = 360;   // ring fade-in; filling waits this long so the empty
                      // ring is fully visible before any color appears
  const svgRef = React.useRef(null);
  const arcRefs = React.useRef([]);

  // Arc geometry. Each arc sits at dasharray `len C` and is rotated to its
  // start angle; we animate stroke-dashoffset len→0 to draw it clockwise.
  let cursor = 0;
  const arcData = rows.map((row) => {
    const frac = denom > 0 ? Math.min(1, row.value / denom) : 0;
    const len = Math.max(0, frac * C - gap);
    const before = cursor;
    cursor += frac;
    return { key: row.key, color: row.color, len, before, frac };
  });

  // Drive the draw with the Web Animations API rather than CSS keyframes: no
  // injected <style> to race against, it replays on every mount (tab switch)
  // and whenever animKey changes (Month/Year toggle), and `fill: 'both'` holds
  // each arc HIDDEN through its delay so colors never appear before their turn.
  React.useLayoutEffect(() => {
    if (svgRef.current) {
      svgRef.current.getAnimations().forEach((a) => a.cancel());
      svgRef.current.animate([{ opacity: 0 }, { opacity: 1 }], { duration: FADE, easing: 'ease', fill: 'both' });
    }
    arcData.forEach((a, i) => {
      const el = arcRefs.current[i];
      if (!el) return;
      el.getAnimations().forEach((an) => an.cancel());
      const dur = Math.max(1, a.frac * SWEEP);
      const delay = FADE + a.before * SWEEP;
      // opacity 0 is baked into the FIRST keyframe with `both` fill, so the arc
      // (including its round line-cap dot) is guaranteed invisible all the way
      // through its delay — it only appears the instant its own draw begins.
      el.animate(
        [
          { opacity: 0, strokeDashoffset: a.len, offset: 0 },
          { opacity: 1, strokeDashoffset: a.len, offset: 0.0001 },
          { opacity: 1, strokeDashoffset: 0, offset: 1 }],

        { duration: dur, delay, easing: 'linear', fill: 'both' });

    });
  }, [animKey]);

  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg ref={svgRef} width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(42,42,42,0.06)" strokeWidth={sw} />
        {arcData.map((a, i) =>
        <circle key={a.key} ref={(el) => arcRefs.current[i] = el}
        cx={size / 2} cy={size / 2} r={r} fill="none"
        stroke={a.color} strokeWidth={sw} strokeLinecap="round"
        transform={`rotate(${(a.before * 360).toFixed(3)} ${size / 2} ${size / 2})`}
        strokeDasharray={`${a.len.toFixed(2)} ${C.toFixed(2)}`}
        style={{ strokeDashoffset: a.len, opacity: 0 }} />
        )}
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3 }}>
        {center}
      </div>
    </div>);

}

function BudgetBar({ pct, color, over }) {
  return (
    <div style={{ height: 6, borderRadius: 999, background: 'rgba(42,42,42,0.08)', overflow: 'hidden', marginTop: 8 }}>
      <div style={{
        height: '100%', width: `${Math.min(100, pct)}%`, borderRadius: 999,
        background: over ? '#2A2A2A' : color,
        transition: 'width 720ms cubic-bezier(0.22,1,0.36,1)'
      }} />
    </div>);

}

function InsightsScreen({ bg = T.bg, mode = 'breakdown', cats = [], onEditBudget, spentByPeriod = {}, budget }) {
  const [period, setPeriod] = React.useState('This Month');
  const isBudget = mode === 'budget';
  const general = isBudget && budget?.mode === 'general'; // single total, ignore per-cat budgets
  const spentMap = spentByPeriod[period] || {};
  const budgetMult = period === 'This Year' ? YEAR_MULT : 1;

  // build rows from the live category store
  const allRows = cats.map((c) => {
    const hasBudget = !general && c.budget != null;
    return {
      key: c.id, cat: c.name, color: c.color, ref: c, hasBudget,
      spent: spentMap[c.name] || 0,
      budget: hasBudget ? (c.budget || 0) * budgetMult : 0
    };
  });
  const spendingRows = allRows.filter((r) => r.spent > 0);
  const rows = !isBudget || general ? spendingRows : allRows;

  const totalSpent = allRows.reduce((s, r) => s + r.spent, 0);
  let totalBudget, spentBudgeted, donutSource;
  if (general) {
    totalBudget = (budget?.total || 0) * budgetMult;
    spentBudgeted = totalSpent;          // everything counts against the one total
    donutSource = spendingRows;
  } else {
    const budgetedRows = allRows.filter((r) => r.hasBudget);
    totalBudget = budgetedRows.reduce((s, r) => s + r.budget, 0);
    spentBudgeted = budgetedRows.reduce((s, r) => s + r.spent, 0);
    donutSource = isBudget ? budgetedRows : spendingRows;
  }
  const remaining = totalBudget - spentBudgeted;
  const denom = isBudget ? totalBudget : totalSpent;
  const donutRows = donutSource.map((r) => ({ ...r, value: r.spent }));

  const center = isBudget ?
  <>
      <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.5, color: T.ink40 }}>{remaining >= 0 ? 'LEFT' : 'OVER'}</div>
      <div style={{ fontSize: 28, fontWeight: 600, color: T.ink, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>{fmt(Math.abs(remaining))}</div>
      <div style={{ fontSize: 12.5, color: T.ink40, fontVariantNumeric: 'tabular-nums' }}>of {fmt(totalBudget, 0)}</div>
    </> :

  <>
      <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.5, color: T.ink40 }}>SPENT</div>
      <div style={{ fontSize: 30, fontWeight: 600, color: T.ink, letterSpacing: -1, fontVariantNumeric: 'tabular-nums' }}>{fmt(totalSpent)}</div>
    </>;


  return (
    <div style={{ position: 'absolute', inset: 0, background: bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '64px 22px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
        <h1 style={{ margin: 0, fontSize: 26, fontWeight: 700, color: T.ink, letterSpacing: -0.5 }}>Insights</h1>
        <PeriodToggle value={period} onChange={setPeriod} />
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 18px 120px' }}>
        <div style={{ display: 'flex', justifyContent: 'center', padding: '26px 0 22px' }}>
          <Donut rows={donutRows} denom={denom} animKey={period + mode + (general ? 'gen' : 'cat') + cats.length} center={center} />
        </div>

        {isBudget &&
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 18 }}>
            <span style={{ fontSize: 13, fontWeight: 600, color: T.ink, background: T.card, border: `1px solid ${T.ink12}`, borderRadius: 999, padding: '6px 14px' }}>
              {fmt(spentBudgeted, 0)} spent of {fmt(totalBudget, 0)} budget
            </span>
          </div>
        }

        <div style={{ background: T.card, borderRadius: 22, padding: '6px 18px', boxShadow: '0 1px 2px rgba(42,42,42,0.04), 0 6px 18px rgba(42,42,42,0.04)' }}>
          {rows.map((row, i) => {
            const noBudget = isBudget && !general && !row.hasBudget;
            const pct = general ?
            totalBudget > 0 ? Math.round(row.spent / totalBudget * 100) : 0 :
            isBudget ?
            row.budget > 0 ? Math.round(row.spent / row.budget * 100) : 0 :
            totalSpent > 0 ? Math.round(row.spent / totalSpent * 100) : 0;
            const over = isBudget && !general && row.hasBudget && row.spent > row.budget && row.budget > 0;
            const clickable = isBudget && !general && onEditBudget;
            return (
              <React.Fragment key={row.key}>
                {i > 0 && <div style={{ height: 1, background: T.hair, marginLeft: 26 }} />}
                <button
                  onClick={clickable ? () => onEditBudget(row.ref) : undefined}
                  style={{
                    display: 'block', width: '100%', textAlign: 'left', padding: '15px 0',
                    background: 'none', border: 'none', cursor: clickable ? 'pointer' : 'default', fontFamily: 'inherit'
                  }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                    <span style={{ width: 14, height: 14, borderRadius: 5, background: row.color, border: '1px solid rgba(42,42,42,0.1)', flexShrink: 0 }} />
                    <div style={{ flex: 1, fontSize: 17, fontWeight: 600, color: T.ink, letterSpacing: -0.2, display: 'flex', alignItems: 'center', gap: 6 }}>
                      {row.cat}
                      {clickable && <ChevronIcon size={15} sw={1.8} style={{ color: T.ink40 }} />}
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 17, fontWeight: 600, color: T.ink, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3 }}>
                        {isBudget ?
                        general ?
                        fmt(row.spent, 0) :
                        noBudget ?
                        fmt(row.spent, 0) :
                        <>{fmt(row.spent, 0)} <span style={{ color: T.ink40, fontWeight: 500 }}>/ {fmt(row.budget, 0)}</span></> :
                        fmt(row.spent)}
                      </div>
                      <div style={{ fontSize: 13, color: over ? T.ink : T.ink40, fontWeight: over ? 600 : 400, fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
                        {isBudget ? general ? `${pct}% of budget` : noBudget ? 'Set budget' : over ? `${pct}% · over` : `${pct}% used` : `${pct}%`}
                      </div>
                    </div>
                  </div>
                  {isBudget && !noBudget && <BudgetBar pct={pct} color={row.color} over={over} />}
                </button>
              </React.Fragment>);

          })}
        </div>
      </div>
    </div>);

}

Object.assign(window, { InsightsScreen });