// icons.jsx — single consistent SF-Symbols-style line-icon set.
// All stroke-based, currentColor, no fills, no emoji.
function Icon({ d, size = 24, sw = 1.8, fill = 'none', children, vb = 24, style }) {
  return (
    <svg width={size} height={size} viewBox={`0 0 ${vb} ${vb}`} fill="none"
      stroke="currentColor" strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"
      style={style}>
      {d ? <path d={d} fill={fill} /> : children}
    </svg>
  );
}

// — Top bar / nav —
const SearchIcon = (p) => <Icon {...p}><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></Icon>;
const FilterIcon = (p) => <Icon {...p}><path d="M4 7h16M7 12h10M10 17h4" /></Icon>;
const CloseIcon  = (p) => <Icon {...p}><path d="M6 6l12 12M18 6L6 18" /></Icon>;
const RepeatIcon = (p) => <Icon {...p}><path d="M4 9a6 6 0 016-6h5M4 9l3-3M4 9l3 3" /><path d="M20 15a6 6 0 01-6 6H9m11-6l-3 3m3-3l-3-3" /></Icon>;
const BackspaceIcon = (p) => <Icon {...p}><path d="M9 5h10a2 2 0 012 2v10a2 2 0 01-2 2H9l-6-7 6-7z" /><path d="M16 9l-5 6M11 9l5 6" /></Icon>;
const NoteIcon   = (p) => <Icon {...p}><path d="M4 7h16M4 12h16M4 17h9" /></Icon>;
const CalendarIcon = (p) => <Icon {...p}><rect x="4" y="5" width="16" height="16" rx="3" /><path d="M4 9h16M8 3v4M16 3v4" /></Icon>;
const GridIcon   = (p) => <Icon {...p}><rect x="4" y="4" width="6.5" height="6.5" rx="2" /><rect x="13.5" y="4" width="6.5" height="6.5" rx="2" /><rect x="4" y="13.5" width="6.5" height="6.5" rx="2" /><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="2" /></Icon>;
const CheckIcon  = (p) => <Icon {...p}><path d="M5 13l4.5 4.5L19 7" /></Icon>;
const PlusIcon   = (p) => <Icon {...p}><path d="M12 5v14M5 12h14" /></Icon>;

// — Tab bar —
const ReceiptIcon = (p) => <Icon {...p}><path d="M6 3h12v18l-2.5-1.6L13 21l-2.5-1.6L8 21l-2.5-1.6L6 21V3z" /><path d="M9 8h6M9 12h6" /></Icon>;
const ChartIcon   = (p) => <Icon {...p}><path d="M5 20V10M12 20V4M19 20v-7" /></Icon>;
const GearIcon    = (p) => <Icon {...p}><circle cx="12" cy="12" r="3.2" /><path d="M12 2.5v3M12 18.5v3M21.5 12h-3M5.5 12h-3M18.7 5.3l-2.1 2.1M7.4 16.6l-2.1 2.1M18.7 18.7l-2.1-2.1M7.4 7.4L5.3 5.3" /></Icon>;
const HomeIcon    = (p) => <Icon {...p}><path d="M4 11l8-7 8 7" /><path d="M6 10v9h12v-9" /><path d="M10.5 19v-4.5h3V19" /></Icon>;

// — Settings rows —
const ExportIcon  = (p) => <Icon {...p}><path d="M12 15V3M12 3L8 7M12 3l4 4" /><path d="M5 13v6a2 2 0 002 2h10a2 2 0 002-2v-6" /></Icon>;
const TagIcon     = (p) => <Icon {...p}><path d="M4 4h7l9 9-7 7-9-9V4z" /><circle cx="8.5" cy="8.5" r="1.4" fill="currentColor" stroke="none" /></Icon>;
const DollarIcon  = (p) => <Icon {...p}><path d="M12 3v18M16 7.5c0-1.9-1.8-3-4-3s-4 1-4 2.8c0 3.7 8 2 8 5.6 0 1.9-1.8 3-4 3s-4-1.1-4-3" /></Icon>;
const SunIcon     = (p) => <Icon {...p}><circle cx="12" cy="12" r="4" /><path d="M12 2v2.5M12 19.5V22M22 12h-2.5M4.5 12H2M18.4 5.6l-1.8 1.8M7.4 16.6l-1.8 1.8M18.4 18.4l-1.8-1.8M7.4 7.4L5.6 5.6" /></Icon>;
const BugIcon     = (p) => <Icon {...p}><path d="M5 8h14a8 8 0 01-8 13A8 8 0 015 8z" /><path d="M12 3v3M12 11v8M5 12H2M22 12h-3" /></Icon>;
const MoonIcon    = (p) => <Icon {...p}><path d="M20 14.5A8 8 0 119.5 4a6.3 6.3 0 0010.5 10.5z" /></Icon>;
const ChevronIcon = (p) => <Icon {...p}><path d="M9 6l6 6-6 6" /></Icon>;
const PhotoIcon   = (p) => <Icon {...p}><rect x="3" y="5" width="18" height="14" rx="3" /><circle cx="8.5" cy="10" r="1.6" /><path d="M21 16l-5-4-7 6" /></Icon>;
const TrashIcon   = (p) => <Icon {...p}><path d="M5 7h14M10 7V5a1 1 0 011-1h2a1 1 0 011 1v2M6 7l1 12a2 2 0 002 2h6a2 2 0 002-2l1-12" /></Icon>;
const TargetIcon  = (p) => <Icon {...p}><circle cx="12" cy="12" r="8.5" /><circle cx="12" cy="12" r="4.5" /><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none" /></Icon>;

// — Category glyphs —
const SchoolIcon = (p) => <Icon {...p}><path d="M12 4L2.5 8.5 12 13l9.5-4.5L12 4z" /><path d="M6 10.5V15c0 1.4 2.7 2.5 6 2.5s6-1.1 6-2.5v-4.5" /><path d="M21.5 8.5v5" /></Icon>;
const FoodIcon   = (p) => <Icon {...p}><path d="M7 3v8M5 3v4.5a2 2 0 004 0V3M7 11v10" /><path d="M16 3c-1.5 0-2.5 2-2.5 5s1 4 2.5 4 2.5-1 2.5-4-1-5-2.5-5zM16 12v9" /></Icon>;
const SubsIcon   = (p) => <Icon {...p}><path d="M4 11a8 8 0 0114-5l2 2M20 13a8 8 0 01-14 5l-2-2" /><path d="M20 4v4h-4M4 20v-4h4" /></Icon>;

Object.assign(window, {
  Icon, SearchIcon, FilterIcon, CloseIcon, RepeatIcon, BackspaceIcon, NoteIcon,
  CalendarIcon, GridIcon, CheckIcon, PlusIcon,
  ReceiptIcon, ChartIcon, GearIcon, HomeIcon,
  ExportIcon, TagIcon, DollarIcon, SunIcon, MoonIcon, BugIcon, ChevronIcon, PhotoIcon, TrashIcon, TargetIcon,
  SchoolIcon, FoodIcon, SubsIcon,
});
