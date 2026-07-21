# Archive Masonry Redesign — Notes-style Cards

Date: 2026-07-21
Reference: Apple iOS 26 Notes-style masonry press shot (supplied by Mickey,
`~/Desktop/Siri AI Conversation Overview.jpg`). Becomes a canonical layout
reference in DESIGN.md.

## Goal

Replace the uniform 2-column square grid with a staggered two-column
masonry of self-contained cards, and replace the floating "Save a link"
pill with corner glass buttons. Keep: category tabs (weight-driven, no
underline), the SourceIcon brand-glyph system, background wash, status-bar
frost, swipe paging between categories.

## Layout

- Two-column masonry: `HStack` of two `LazyVStack` columns, 12pt gutter,
  20pt margins, 12pt vertical spacing. Items distribute in save order to
  the currently-shorter column using estimated card heights (nominal
  column width; rough heuristics are fine — balance, not pixel accuracy).
- Per-tab identity swap (`.id(selectedTab)`) and directional push on
  category swipe carry over unchanged.

## Card anatomy (one language, three variants)

All cards: corner radius 22, surface `secondarySystemGroupedBackground`
(white in light, elevated dark gray in dark), content inside the card —
nothing renders below it anymore.

- **Text card** (no thumbnail): metadata line (SourceIcon glyph +
  `domain · relative time`, 13 regular systemGray) → title 17 bold SF,
  ≤3 lines → summary preview, Garamond 15 regular, systemGray, ≤6 lines,
  lineSpacing 4. Padding 16.
- **Inset-image card**: metadata line + title on the surface, then the
  thumbnail as a rounded (radius 12) image at natural aspect ratio,
  clamped to w/h 0.75–1.3. Padding 14.
- **Full-bleed card**: edge-to-edge thumbnail (aspect clamped w/h
  0.68–0.95, reads tall), top scrim (black 0.55 → clear), white metadata +
  title overlaid top-leading. Every third thumbnail save within the shown
  list (deterministic by position). Not used in the search sheet.

Thumbnail aspect ratios are read once per item from the stored JPEG and
cached by id.

## Chrome (full reference match)

- Ellipsis menu: lone 44pt glass circle top-right
  (`glassEffect(.regular.interactive(), in: Circle())`).
- Search: 52pt glass circle bottom-left. Plus (opens SaveSheet): 52pt
  glass circle bottom-right. Both inside one `GlassEffectContainer`;
  both slide off on scroll-down and return on scroll-up (the pill's
  existing accumulator logic).
- Save pill retired. `search-button` accessibility id stays on the new
  bottom-left button.
- Tabs, wash, VariableBlur frost, toast: unchanged.

## Search sheet

Results reuse the same masonry with text/inset cards only.

## Files

`SaveTile.swift` → `SaveCard.swift` (SaveCard + MasonryGrid + SourceIcon),
`ContentView.swift` (chrome + masonry), `SearchSheet.swift` (call site),
`DESIGN.md` (reference, Layout, Top chrome, decisions log).
No model/store changes.

## Risk

White-on-image legibility in full-bleed cards on bright thumbnails; the
scrim mitigates. If it fails in practice, drop to inset-only — variants
share one component.
