# Design System — Naru

Source of truth. Derived from Mickey's references, not generated taste.
Match the references; do not invent directions.

## References (canonical)
- BeReal iOS — https://mobbin.com/apps/be-real-ios-9315d60d-7c8c-4b1d-98eb-e696e0ef3859 — THE design-system reference since 2026-07-08, adopted "in white": Inter typography with weight-driven hierarchy, wordmark with period, no-underline weight/color tabs, uppercase tracked section labels, chunky rounded surfaces
- Cosmos iOS — https://mobbin.com/apps/cosmos-ios-8bfdb726-e2c2-4305-8185-7e915a61d351 (collection tiles = Naru's blueprint: rounded 2-col grid, metadata line, floating capsule nav)
- Genie iOS — https://mobbin.com/apps/genie-ios-ca2f73fe-0974-4841-8cd8-ffe7217ac82c (white ground, black pills)
- ChatGPT iOS — https://mobbin.com/apps/chat-gpt-ios-a96b7f4c-6bfa-4c9d-a6b7-562160feb391 (monochrome restraint, gray chips, content-first hierarchy)
- Interaction taste (web libs, treat as motion/interaction spec): NumberFlow (animated numbers), Sonner (toasts), cmdk (command menus), dnd kit (drag), Virtuoso (smooth virtualized lists), input-otp, Liveline, Leva.

## Aesthetic
iOS-native monochrome minimalism. Chrome disappears; saved content provides
all color. Personality lives in micro-interactions, never in decoration.
No textures, no gradients, no themed palettes.

## Color
- Background: #FFFFFF (dark mode: #000000) — system semantic colors only
- Primary text: label/black
- Secondary text: #8E8E93 (systemGray) — all metadata
- Surface: #F2F2F7 (systemGray6) — chips, icon-button circles, placeholder tiles
- Emphasis: solid black fill, white text (pill buttons). Black IS the accent.
- No accent hue anywhere in chrome. Semantic red only for destructive.

## Typography (BeReal system, in white)
- Everything: Inter, bundled (Naru/Resources/Fonts, SIL OFL) and registered
  at runtime via Typeface.register() in both app and extension. Use
  `.font(.inter(size, weight))` — never `.system` for text (SF Symbols keep
  `.system` sizing next to Inter labels).
- Weight does the hierarchy work; sizes stay small and tight:
  - Wordmark: "Naru." (with period, BeReal-style) — 24 ExtraBold (.heavy)
  - Sheet/detail headlines: 20 bold · Empty-state title: 20 semibold
  - Buttons/pills: 17 semibold · Open Link: 15 semibold
  - Tile title: 15 semibold · Body/chips/fields: 15 regular-medium
  - Metadata: 13 regular systemGray · Toast: 13 medium
  - Section labels: 12 medium UPPERCASE, tracking 0.6 ("CATEGORY", "SUMMARY")
  - Tab counts: 11 regular
- No serif anywhere — retired with the BeReal adoption (2026-07-08).
- Counts keep `.contentTransition(.numericText())` (NumberFlow feel).

## Layout
- Save tiles: 2-column grid, corner radius 22, aspect ~1:1 for visual saves;
  text saves get gray surface tile with serif quote/title inside
- Below each tile: name (1 line, semibold) + metadata line "domain · 2h" in gray
- Category navigation: horizontal text tabs with count — no underline;
  active = black semibold, inactive = systemGray regular (BeReal style)
- Primary actions float: capsule bar/button at bottom (Cosmos floating nav)
- Margins 20pt, gutter 12pt, section spacing 28pt
- Sheets: white, corner radius 24-28 top, list rows, big black Done pill
- Sheet grabber: custom 36×5 capsule (systemGray4) at 10pt from top — the
  system indicator's 5pt placement is too tight against large corner radii;
  content below the grabber gets ≥24pt clearance (hero uses 34pt top inset)

## Motion
- Restraint: 200-350ms, ease-out; no spring bounce on chrome
- Count changes animate numerically (NumberFlow equivalent)
- Save confirmation: Sonner-style toast — small capsule slides up from
  bottom, auto-dismisses ~2s, one soft haptic
- Tile appearance: gentle fade+scale(0.97→1), never slides across screen
- Later: drag-to-organize collections (dnd kit feel), command-style search sheet (cmdk feel)

## Materials (Liquid Glass)
- Floating chrome over scrolling content uses Liquid Glass: the Save pill
  (`glassEffect(.regular.tint(.primary.opacity(0.92)).interactive())`) and
  the toast. In-sheet buttons stay solid black per the Genie reference.
- Status-bar frost: Naru has no nav bar, so `scrollEdgeEffectStyle` won't
  render. Use `VariableBlurView` (Sources/VariableBlur.swift) — a true
  progressive blur (radius 9, 82pt band, quadratic ease-out mask so the
  radius reaches true zero before the band edge — a linear ramp leaves a
  visible seam): content stays saturated and defocuses toward the edge,
  iMessage-style. NOT a masked material — that
  adds a milky veil (rejected). Note: taps CAFilter("variableBlur")
  (private API, industry-common); fallback if ever rejected is the
  gradient-masked ultraThinMaterial.
- Min iOS 26 (raised from 17 for glass APIs).

## Source icons
Brand logos are bundled Simple Icons SVGs (Assets.xcassets/Brands),
template-rendered and tinted systemGray — never full-color favicons.
Unknown domains get the SF Symbol globe. Add brands by dropping a new
Simple Icons SVG imageset and one mapping row in SourceIcon.
Glyphs are optically normalized to icon-grid key heights on the 24-unit
canvas (round 20 · default 19.4 · dense square 18.6 · solid rect 18.8 ·
wide width-capped 22.5) — when adding an icon, wrap its path in the same
transform pattern; never ship a raw 24×24 Simple Icons file.

## Anti-rules (learned, do not revisit)
- No dark-navy + teal theme. No warm-paper/museum/heritage styling.
- No decorative texture, no colored category chips, no card borders.
- Do not generate new "design directions" — extend from the references above.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-08 | System derived from Genie/Cosmos/ChatGPT refs | Mickey rejected 3 generated directions; references are the spec |
| 2026-07-08 | BeReal design system adopted in white: Inter everywhere, "Naru." wordmark, weight-based tabs, serif retired | Mickey: "We're copying their design system basically but in white" |
