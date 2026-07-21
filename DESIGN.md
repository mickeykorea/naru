# Design System — Naru

Source of truth. Derived from Mickey's references, not generated taste.
Match the references; do not invent directions.

## References (canonical)
- BeReal iOS — https://mobbin.com/apps/be-real-ios-9315d60d-7c8c-4b1d-98eb-e696e0ef3859 — THE design-system reference since 2026-07-08, adopted "in white": weight-driven hierarchy, no-underline weight/color tabs, uppercase tracked section labels, chunky rounded surfaces
- iOS 26 Notes-style masonry (Apple press shot, supplied 2026-07-21) — THE
  archive-layout reference: staggered 2-col cards, metadata + bold title
  inside the card, inset or full-bleed images, corner glass buttons
  (search bottom-left, compose bottom-right), lone menu button top-right
- iOS 26 Clock app (world clock) — top-chrome reference since build 15: no screen title, floating circular Liquid Glass icon buttons, content starts directly with navigation
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
  Typeface.register()). Used ONLY for content-voice moments: card summary
  previews (15 regular, lineSpacing 4), detail-sheet gray hero fallback
  (23 medium), summary body (17 regular, lineSpacing 5). Garamond runs
  small — size up ~2pt vs the SF equivalent. `.font(.garamond(size, weight))`.
- Weight does the hierarchy work; sizes stay small and tight:
  - Wordmark: retired from the home screen (build 15, Clock-style chrome).
    If "Naru" ever appears as type again: 24 BOLD (heavy/black go blobby
    in SF Pro — specimen-verified), NO trailing period.
  - Sheet/detail headlines: 20 bold · Empty-state title: 20 semibold
  - Buttons/pills: 17 semibold · Open Link: 15 semibold
  - Card title: 17 bold · Body/chips/fields: 15 regular-medium
  - Metadata: 13 regular systemGray ("domain · 2w", narrow age, no "ago")
  - Toast: 13 medium
  - Section labels: 12 medium UPPERCASE, tracking 0.6 ("CATEGORY", "SUMMARY")
  - Tab counts: 11 regular
- No serif anywhere — retired with the BeReal adoption (2026-07-08).
- Counts keep `.contentTransition(.numericText())` (NumberFlow feel).

## Chrome (Notes-ref corners, build 16+)
- No title. Lone 44pt circular Liquid Glass ellipsis menu top-right
  (20pt margin, 8pt below safe area), pinned above the scroll.
- Bottom corners, one `GlassEffectContainer`: 52pt glass circle search
  bottom-left (clear glass), 52pt glass circle plus bottom-right
  (primary-tinted 0.92, background-colored icon — replaces the retired
  "Save a link" pill). Both slide off on scroll-down, return on
  scroll-up. `.tint(.primary)` on glass buttons — Menu labels otherwise
  pick up the accent asset.
- Background: light-gray vertical wash, Color(white: 0.97) at top →
  0.93 at bottom (dark: 0.05 → black). Never a flat fill; gray enough
  that white cards read as surfaces.
- Spacing: content starts 76pt from safe-area top (clears the button + air);
  category tabs get 28pt below before the cards.

## Layout (Notes-style masonry)
- Two-column staggered masonry: items flow in save order into the
  currently-shorter column (estimated heights). Margins 20pt, gutter and
  vertical gaps 12pt.
- Cards, radius 22, surface secondarySystemGroupedBackground, everything
  inside the card (nothing below it): metadata line (SourceIcon glyph +
  "domain · 2w", 13 gray) → title 17 bold ≤3 lines → then per variant:
  - Text card: summary preview, Garamond 15 gray, ≤6 lines, padding 16
  - Inset-image card: glass-slab thumbnail — bleeds to a 5pt inset
    (radius 17 continuous, concentric with the card's 22), natural aspect
    clamped w/h 0.75–1.3, 1pt gradient specular rim (white 0.6 topLeading
    → 0.08 → 0.28 bottomTrailing); text block padded 14
  - Full-bleed card: every 3rd loadable-thumbnail save; edge-to-edge
    image (aspect 0.68–0.95), black 0.55→clear top scrim, white text.
    Not used in the search sheet.
- Thumbnail loadability decides variants (hasThumbnail can lie), aspect
  read once per item and cached.
- Category navigation: horizontal text tabs with count — no underline;
  active = black semibold, inactive = systemGray regular (BeReal style)
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
- Floating chrome over scrolling content uses Liquid Glass: the corner
  buttons (plus gets `.regular.tint(.primary.opacity(0.92)).interactive()`,
  search and ellipsis stay clear `.regular.interactive()`) and the toast.
  Both bottom buttons share one GlassEffectContainer. In-sheet buttons
  stay solid black per the Genie reference.
- Never overlay glassEffect on imagery: `.clear` glass over a thumbnail
  blurs the whole image milky (tried 2026-07-21, rejected). The iOS 27
  glass-slab look is hand-built: crisp image + gradient specular stroke.
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
Known brands display a short lowercase name in metadata ("spotify",
"youtube", "x", "nytimes") via SourceIcon.displayName; unknown domains
keep the raw domain. New brands get a name in the same table row.

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
| 2026-07-21 | Notes-style masonry adopted: staggered cards, content inside the card, every-3rd full-bleed | Mickey supplied the Apple press shot as the layout reference |
| 2026-07-21 | Save pill retired → 52pt glass plus bottom-right, search moved to bottom-left, ellipsis alone top-right | Mickey: no big pill when a corner plus works; full reference match chosen |
| 2026-07-21 | Wash darkened to 0.97→0.93 (dark 0.05→0); cards secondarySystemGroupedBackground | White cards need a gray ground to read as surfaces |
| 2026-07-21 | Brand short names in metadata; glass-slab inset thumbnails (5pt bleed + specular rim, no glassEffect overlay) | Mickey: "just be spotify"; iOS 27-crop reference; .clear glass over images blurs them |
