# GungeonMate — Design Contract

> Standing design rules for the app. New UI work extends this contract;
> it never contradicts it silently. If a decision changes, update this
> file in the same commit.
>
> Sources of truth: `lib/theme/tokens.dart`, `lib/utils/responsive.dart`,
> `lib/services/theme/theme_flair_prefs.dart`,
> `lib/services/theme/app_theme_modes.dart`.
> Interactive reference: `design-lab/` (HTML mirror — see §10).

**Design read:** companion app for *Enter the Gungeon* players,
Android-first, expressive register (design is part of the product), dark
chrome with game-identity accents. Dials — VARIANCE 6 (consistent
anatomy, art-directed headers/stats), MOTION 5 (micro-interactions +
themed particles), DENSITY 6 (data-rich but card-organized).

---

## 1. Single sources of truth — never duplicate

| Concern | Owner | Never do |
|---|---|---|
| Spacing / gaps / paddings | `Insets` (tokens.dart) | Magic numbers in `EdgeInsets`/`SizedBox` |
| Corner radii (unthemed) | `Radii` (tokens.dart) | `BorderRadius.circular(N)` inline |
| Corner radii (themed) | `flair.cardRadius` / `flair.chipRadius` | `Radii.*` on themed cards/chips |
| Durations | `Motion` (tokens.dart) | `Duration(milliseconds: N)` inline |
| Type styles | `TypeScale` / `Theme.of(context).textTheme` | Inline `fontSize:`/`fontWeight:` |
| Colors (themed surfaces) | `flair.*` + `ColorScheme` | Raw `Colors.white/black`, `Color(0xFF…)` |
| Codex category colors | `CodexColors` (fixed identity) | Per-theme colors for category identity |
| Screen-size decisions | `ScreenProfile` / `Responsive` | Hardcoded `MediaQuery` breakpoints |

Hard rule: typing `Color(0xFF...)`, `fontSize:`, or
`BorderRadius.circular(...)` inside a screen file means the value
belongs in a token or the theme. Exceptions are documented one-offs
(the main-menu logo stroke `#C62828` / fill `#FFD54F` is a fixed brand
mark, intentionally not themed).

## 2. Spacing — one 4pt scale

`Insets`: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48 · huge 64`.
These are the **only** paddings/gaps in the app.

- Related items: 4–8 apart (icon→label, rows in a card)
- Cards/sections: 12–16 apart
- Screen gutters: 12–16 (`fromLTRB(12,…)`) or `Insets.xl` 24 on hero/menu screens
- Explicit `SizedBox` spacing, **never flex `Spacer()`** on static screens
  (the "hole in the screen" bug — see REWORK_LESSONS_LEARNED §1.9)

## 3. Radii — one family + themed overrides

Baseline (`Radii`): `sm 8 · md 12 · lg 16 · card 12 · sheet 24(top) · pill 999`.

Themed surfaces use `flair.cardRadius`/`flair.chipRadius` instead —
e.g. **Minimalist: card 6, chip 4**; Unicorn: card 18, chip 18. A card's
radius is a theme signature, not a local decision.

## 4. Type — deliberate scale, no defaults

`TypeScale` colorless templates; color applied via `textTheme` (never
bake color into the style — light-on-light bug). Hierarchy = size +
weight, not color. Body ≥ 14 unless a deliberate caption (12) or
micro-label (10).

| Role | Size | Weight | Notes |
|---|---|---|---|
| displaySmall | 32 | 800 | Big stat readouts (DPS, Coolness) — `flair.headlineStat` color |
| headlineMedium/Small | 28 / 24 | 700 | Section headers, screen titles |
| titleLarge/Medium/Small | 22 / 18 / 16 | 800/700 | Card titles, dialogs |
| bodyLarge/Medium/Small | 16 / 14 / 12 | 400 | Content; `bodySmall` = `onSurfaceVariant` |
| labelLarge/Medium/Small | 14 / 12 / 10 | 800/700 | Buttons, chips, badges — wide letterSpacing |

Fonts: **system chrome uses Montserrat always** (home, nav, settings,
menus — wrapped in a fixed-font `Theme`). **Game content uses the
user-selected font** (default `EnterTheGungeonBig`). Never let the user
font leak into chrome surfaces. Tabular figures on for all themes except
Unicorn (`flair.tabularFigures`).

Text-safety rules (landmines):
- Fixed-height text needs `maxLines` + `overflow`/`FittedBox` (1.4×
  text-scale cap is the test)
- `FittedBox(fit: BoxFit.contain)` in fixed-height `SizedBox` for
  uniform visual size — `scaleDown` only shrinks, never normalizes
- Test every screen at **130% text scale** and 320dp width

## 5. Responsive — window classes, not device guesses

Two layers (`lib/utils/responsive.dart`):

- **`Responsive.factor` (`sf`)** — width/400 clamped 0.85–1.25. Scales
  hero metrics (menu button height `62*sf`, icon `24*sf`).
- **`Responsive.heightFactor`/`minScale`** — height/800 clamped
  0.85–1.20; `minScale` = min(w,h) for elements that must fit both axes.
- **`ScreenProfile`** — prefer for new code. M3 breakpoints:
  compact <600 · medium 600–839 · expanded 840–1199 · large ≥1200.
  `isShort` = usable height <700. `isSmallPhone` = compact + short.
  `columnsFor(n)` → 3/4/5/6 grid columns by class, anti-orphan clamp.

Phone-usability rules:
- `SafeArea` always; no RenderFlex overflow at 320dp→768dp, any
  orientation, 1.3× text scale
- Tap targets ≥ 48dp where practical; icon-only controls need tooltips
- Reading-width caps on wide screens: menu column **420**, codex
  detail/synergies **760**
- Compact first: >8 picker items → paged/swipable grid, never a wall
- **No GridView/ListView inside PageView** — Wrap or Row+Expanded
- `Center`/`Align` without heightFactor in bottom-nav = blank-body
  landmine

## 6. Minimalist (default theme) palette

`AppThemeMode.minimalist` — the out-of-box look and the lab's baseline.

| Token | Value | Use |
|---|---|---|
| `flair.scaffold` | `#0A0A0A` | App background |
| `flair.card` | `#121212` | Card/panel fill |
| `flair.primary` | `#E0E0E0` | Accents, borders, icons |
| `flair.secondary` | `#9E9E9E` | Secondary text/icons |
| `flair.headlineStat` | `#FFFFFF` | Big stat numbers |
| `flair.bulletColor` / glyph | `#BDBDBD` / `—` | List bullets |
| `cardBorder` | `rgba(255,255,255,.20)` 1px | Card frames |
| `divider` | `rgba(255,255,255,.13)` 0.5px | Hairlines |
| `headerUnderline` | `rgba(255,255,255,.27)` | Section-title rule |
| `chip` | outline-only, radius 4 | `chipFilled=false` |
| `headerAllCaps` | true | Section titles uppercase |
| `pageFrame` | 1px hairline | Viewport frame — Minimalist signature |
| Ambient glow | `rgba(255,255,255,.07/.03)` | Nearly invisible — "no glow, no noise" |

Quality tiers (fixed game identity, `QualityBadge.colorFor`):
**S** black pill + white text + gold glow · **A** `#E53935` ·
**B** `#43A047` · **C** `#1E88E5` · **D** `#757575` · **N** `#5E35B1`.

Stat groups (semantic): Combat red / Handling cyan / Meta amber unless
`flair.statGroup*` overrides. Codex categories keep `CodexColors`
identity hues across all themes.

## 7. Component patterns

- **Menu button** — 62·sf height, ghost = vertical gradient
  `primary .16→.05` + 1.8px border `primary .55` + soft primary glow;
  hero = solid `flair.primary` + luminance-checked label
  (`main_menu_screen._menuButton`).
- **Card** — `flair.card` fill (or vertical gradient card→black 15%),
  `flair.cardRadius`, 1px `cardBorder`. No nested cards; hairline
  dividers group content inside.
- **List row** (`BrowseRow`) — card, 12/12/10/12 padding, 8px bottom
  margin, 64px icon box, name + type pill + `QualityBadge` + meta pills.
- **Section title** — `headerAllCaps` + 0.5–1px `headerUnderline`
  hairline (+ optional `flair.headerGlyph`). `ThemedSectionTitle`.
- **Chip** — Minimalist: outline + label only (`chipFilled=false`),
  radius 4, 10/5 padding. Pickers show visual + label only, never a
  blurb on the chip.
- **Collapsible card** (`_CollapsibleCard`) — header row 14/12 padding,
  icon + ALL-CAPS title + chevron; body `fromLTRB(14,0,14,14)`.
- **BottomBackBar** — standard back affordance for detail/flow screens
  (mp_lobby exempt — stage-aware back lives in its AppBar).
- **CTA glow** — primary CTAs get `boxShadow` glow + text shadow;
  secondary actions stay flat.

## 8. Motion

`Motion`: press/small state **150ms**, in-place **250ms**,
sheet/dialog/container enter **400ms** (decelerate), exit **250ms**
(accelerate). Entrance choreography is allowed on key screens; never
`Curves.linear` on UI. Respect `ReduceMotion.isEnabled(context)` —
always check before animating.

## 9. Neo-Skeuo (alternate skin)

`AppThemeMode.neoSkeuo` — a hand-drawn "field manual" skin, toggled
from the home-screen pencil chip or the run-tools row. Toggle-only:
in `kVisibleThemes` (persistable) but never `kPickerThemes`.

| Token | Value | Use |
|---|---|---|
| `Skeuo.paper` | `#F0E9D8` | Page scaffold |
| `Skeuo.card` | `#FAF5E8` | Raised fills |
| `Skeuo.insetPaper` | `#E6DCC4` | Inset wells, pressed |
| `Skeuo.ink` | `#1F1B16` | All strokes, fills, text |
| `Skeuo.pencil` | `#5C5548` | Captions, disabled, hints |
| `Skeuo.accent` | `#8C3B2E` | Red-pencil annotation (errors) |
| `Skeuo.ochre` / `bluePencil` | `#8A6D2F` / `#3E5C6E` | Annotation accents |
| Border weights | 1 / 2 / 4 px | Kit rule |
| Radius scale | 0 / 4 / 8 / 12 | Kit rule |
| Shadow offsets | 3 / 5 / 8 px | Kit elevation L1/L2/L3 |
| Font | `ShantellSans` (bundled) | Everything — no Montserrat chrome |

Rules:
- Skeuo components live in `lib/widgets/skeuo/` (tokens, surface,
  backdrop). Chrome built on `SkeuoSurface` (ink border + hatched or
  solid offset shadow, base/raised/high/inset/pressed).
- While active, all ambiance layers are suppressed by mode in
  `ThemeOverlay` — particles, glow, shader, page frame off; the skin's
  only texture is `SkeuoGrainPainter` + a fixed pencil vignette. User
  VisualPrefs are never mutated; they return on exit.
- `enterSkeuo()`/`exitSkeuo()` persist + restore previous mode and
  font. `flair.font` stays null; `themeFor` resolves `ShantellSans`
  directly so the user's font pref is untouched.
- Light surfaces: `themeFor` picks `ColorScheme.light` when
  `Contrast.luminance(f.card) > 0.5` so M3 chrome stays coherent.
- Customization is locked while active (menu button, run-tools row,
  settings tile, studio guard) — the skin is a fixed identity.

## 10. Design lab (HTML iteration)

`design-lab/` is a static HTML/CSS mirror for iterating on visuals
without an APK build. Serve from the app root:

```
SERVE_LAB.bat   →   http://localhost:8619/design-lab/
```

- `tokens.css` mirrors this file's values 1:1 — CSS var names match
  Dart token names (`--inset-md` ↔ `Insets.md`), so a lab tweak maps
  mechanically back to code.
- The lab is a **design sandbox**: hand-maintained, Minimalist palette
  only, no particles/shaders (approximated statically). It can drift —
  always verify final values in the real app.
- Porting a change: find the CSS var → edit the matching Dart token /
  `ThemeFlair` field → done. Structural tweaks port to the widget file
  listed in each view's header comment.

## 11. Decisions log

- 2026-10-31 — Contract created. Baseline = Minimalist. Lab mirrors
  menu, settings, codex (grid/category/detail), browse, item detail.
- Codex/MP category colors are fixed game identity (`CodexColors`),
  immune to theme changes by design.
- 2026-10-31 — Neo-Skeuo added (§9): alternate skin toggle on home,
  spec-sheet demo at `neo_skeuo_lab_screen.dart`, customization locked
  while active, ambiance suppressed per-mode.
