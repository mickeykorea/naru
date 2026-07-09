# Design System — Naru

Source of truth. Derived from Mickey's references, not generated taste.
Match the references; do not invent directions.

## References (canonical)
- BeReal iOS — https://mobbin.com/apps/be-real-ios-9315d60d-7c8c-4b1d-98eb-e696e0ef3859 — THE design-system reference since 2026-07-08, adopted "in white": weight-driven hierarchy, no-underline weight/color tabs, uppercase tracked section labels, chunky rounded surfaces
- iOS 26 Clock app (world clock) — the top-chrome reference since build 15: no screen title, floating circular Liquid Glass icon buttons (more top-left, search top-right), content starts directly with navigation
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

## Typography (BeReal weight system, SF Pro, in white)
- Everything: SF Pro (`.system(size:weight:)`) — NO custom/bundled fonts
  (Inter was tried 2026-07-08 and rejected same day; system font only).
- Accent voice: EB Garamond (bundled Naru/Resources/Fonts, OFL, static
  instances cut from the Google variable font, runtime-registered via
  Typeface.register()). Used ONLY for content-voice moments: text-only
  tile titles (18 medium), detail-sheet gray hero fallback (23 medium),
  summary body (17 regular, lineSpacing 5). Garamond runs small — size up
  ~2pt vs the SF equivalent. `.font(.garamond(size, weight))`.
- Weight does the hierarchy work; sizes stay small and tight:
  - Wordmark: retired from the home screen (build 15, Clock-style chrome).
    If "Naru" ever appears as type again: 24 BOLD (heavy/black go blobby
    in SF Pro — specimen-verified), NO trailing period.
  - Sheet/detail headlines: 20 bold · Empty-state title: 20 semibold
  - Buttons/pills: 17 semibold · Open Link: 15 semibold
  - Tile title: 15 semibold · Body/chips/fields: 15 regular-medium
  - Metadata: 13 regular systemGray · Toast: 13 medium
  - Section labels: 12 medium, Title Case, tracking 0.6 ("Category",
    "Summary", "Note", "Appearance") — NOT all-caps (looked shouty; 2026-07-09)
  - Tab counts: 11 regular
- No serif anywhere — retired with the BeReal adoption (2026-07-08).
- Counts keep `.contentTransition(.numericText())` (NumberFlow feel).

## Top chrome (Clock-style, build 15+)
- No title. Two floating 44pt circular Liquid Glass buttons pinned above
  the scroll (they do not scroll away): ellipsis top-left (menu — contents
  TBD), magnifyingglass top-right (search sheet). 20pt side margins, 8pt
  below safe area. `.tint(.primary)` on glass buttons — Menu labels
  otherwise pick up the accent asset.
- Background: near-white vertical wash, white at top → Color(white: 0.955)
  at bottom; dark mode inverts (0.09 → black). Never a flat fill.
- Spacing: content starts 76pt from safe-area top (clears buttons + air);
  category tabs get 28pt below before the grid.

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
  and the toast share a theme-matched tint (`savePillTint`): near-white
  translucent in light mode (white @ 0.45), dark grey in dark mode
  (white 0.16 @ 0.9), text `.primary` — the pill blends with the wash
  instead of contrasting. In-sheet buttons stay solid black per the Genie
  reference.
- Sheets with an opaque element pinned inside (detail hero shield) need
  `.presentationBackground(Color(.systemBackground))` — iOS 26's default
  sheet background is translucent glass at the .medium detent and reads
  as a second background color against the shield.
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

## App icon
- White ground (#FFF), black organic vessel: two billowed sails (bezier
  triangles — curves deviate ~5-8% from straight; 20% reads blobby) over a
  slim ferry hull with upturned ends. Derived from Figma node 8-6 of
  HWBUKiKo4IJ1WH3ewia3mm but organic, and inverted to white.
- Geometry at 1024: all three inter-shape gaps uniform ~56px; the
  composition's rendered bounding box must center at (512, 512) — verify
  by measuring pixels (numpy bbox), not by eyeballing path coords.
- Regenerate: `swift scripts/render-app-icon.swift <out.png>` → copy to
  Naru/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png.

## Anti-rules (learned, do not revisit)
- No dark-navy + teal theme. No warm-paper/museum/heritage styling.
- No decorative texture, no colored category chips, no card borders.
- Do not generate new "design directions" — extend from the references above.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-08 | System derived from Genie/Cosmos/ChatGPT refs | Mickey rejected 3 generated directions; references are the spec |
| 2026-07-08 | BeReal design system adopted in white: weight-based tabs, uppercase labels, serif retired | Mickey: "We're copying their design system basically but in white" |
| 2026-07-08 | Inter reverted to SF Pro; wordmark period removed | Mickey: system font only; "no fucking dot after the title" |
| 2026-07-08 | Wordmark weight heavy→bold | heavy/black blobby in SF Pro; picked from 12-variant specimen |
| 2026-07-08 | EB Garamond as accent font: text tiles + summary body | Mickey requested a "point font" for no-image previews and summaries |
| 2026-07-08 | App icon: black organic vessel on white, uniform gaps, pixel-centered | Iterated 5 rounds from Figma 8-6; white bg + narrow uniform gaps per Mickey |
| 2026-07-08 | Clock-style chrome: title dropped, glass icon buttons, gradient wash | Mickey supplied iOS 26 Clock screenshot as the reference |
| 2026-07-08 | Right glass button = search (title/domain/category/summary/note) | Only credible candidate for an archive; cmdk-style sheet |
| 2026-07-09 | Save pill + toast theme-matched: near-white glass in light, dark grey in dark, primary text | Mickey: "bold move", match the theme instead of contrast |
| 2026-07-09 | Detail sheet pinned to opaque systemBackground | Default glass sheet background split colors against the hero shield at .medium |
| 2026-07-09 | Section labels Title Case, not all-caps | Mickey: uppercase reads as AI/shouty; "Note", "Summary", "Category", "Appearance" |
| 2026-07-09 | Settings: full-height bottom sheet, Appearance override + About + attribution | Mickey supplied Hands Time reference; picked Appearance-only content |
| 2026-07-09 | Settings icons in softly domed circular chips (subtle gradient) | Mickey wanted the reference's "little 3D" — a sanctioned exception to the no-gradient rule, chrome only |
| 2026-07-09 | Settings card pinned to tile color (systemGray6 literal); sheet bg darker | Cards must match the grid tiles; sheet "elevated" appearance was drifting the color and collapsing dark-mode contrast |
| 2026-07-09 | Change category: long-press "Move to" + detail-sheet Category pill | Mickey: both — quick grid move (existing only) and detail editor (view/switch/new) |
