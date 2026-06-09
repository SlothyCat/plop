// theme.jsx — shared design tokens. `T` is a LIVE object whose values are
// swapped by applyTheme(isDark); every component reads T.* at render, so a
// top-level re-render after applyTheme repaints the whole app in the new theme.

// Constants — identical in both themes.
//  • brand accents stay the same (the blue reads on light & dark)
//  • tileInk: charcoal glyph color for icons sitting on the fixed pastel /
//    accent tiles (those tiles never change color, so their glyph must not flip)
const THEME_CONST = {
  accent: '#8CC0EB',
  accentSoft: '#BFDDF0',
  cream: '#FFEBCC',
  yellow: '#FFF9D2',
  tileInk: '#2A2A2A',
  font: '-apple-system, "SF Pro Text", system-ui, sans-serif',
};

const THEME_LIGHT = {
  ...THEME_CONST,
  dark: false,
  bg: '#DCEBF7',        // baby blue app background
  pageBg: '#C7DCEE',    // cool backdrop behind the device
  card: '#FFFFFF',      // white cards
  field: '#FCFDFE',     // inputs / inset wells
  ink: '#2A2A2A',       // charcoal — text & icons
  ink60: 'rgba(42,42,42,0.55)',
  ink40: 'rgba(42,42,42,0.38)',
  ink12: 'rgba(42,42,42,0.10)',
  hair: 'rgba(42,42,42,0.08)',
  scrim: 'rgba(42,42,42,0.32)',
};

const THEME_DARK = {
  ...THEME_CONST,
  dark: true,
  bg: '#121922',        // deep slate-blue app background
  pageBg: '#070B10',    // near-black backdrop behind the device
  card: '#1C2530',      // raised dark card
  field: '#232E3A',     // inputs / inset wells
  ink: '#EAF1F7',       // cool off-white — text & icons
  ink60: 'rgba(234,241,247,0.62)',
  ink40: 'rgba(234,241,247,0.40)',
  ink12: 'rgba(234,241,247,0.14)',
  hair: 'rgba(234,241,247,0.10)',
  scrim: 'rgba(0,0,0,0.5)',
};

// Live token object — starts light, mutated in place by applyTheme.
const T = { ...THEME_LIGHT };

function applyTheme(isDark) {
  Object.assign(T, isDark ? THEME_DARK : THEME_LIGHT);
}

Object.assign(window, { T, THEME_LIGHT, THEME_DARK, applyTheme });
