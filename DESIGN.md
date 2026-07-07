# Design System — Naru

Source of truth. Derived from Mickey's references, not generated taste.
Match the references; do not invent directions.

## References (canonical)
- Genie iOS — https://mobbin.com/apps/genie-ios-ca2f73fe-0974-4841-8cd8-ffe7217ac82c (serif wordmark accent, white ground, black pills, orbiting-avatar micro-motion)
- Cosmos iOS — https://mobbin.com/apps/cosmos-ios-8bfdb726-e2c2-4305-8185-7e915a61d351 (collection tiles = Naru's blueprint: rounded 2-col grid, "N elements · Private" metadata, floating capsule nav, underline tabs)
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

## Typography
- Everything: SF Pro (system), rely on Dynamic Type styles
  - Screen title: title2 semibold · Tile name: subheadline semibold
  - Metadata: footnote regular, systemGray · Buttons: body semibold
- Single exception: the 나루/Naru wordmark uses New York serif
  (`.fontDesign(.serif)`), like Genie's serif logo accent. Nothing else.
- Counts use monospacedDigit + `.contentTransition(.numericText())` (NumberFlow feel).

## Layout
- Save tiles: 2-column grid, corner radius 22, aspect ~1:1 for visual saves;
  text saves get gray surface tile with serif quote/title inside
- Below each tile: name (1 line, semibold) + metadata line "domain · 2h" in gray
- Category navigation: horizontal underline tabs with count (Cosmos style)
- Primary actions float: capsule bar/button at bottom (Cosmos floating nav)
- Margins 20pt, gutter 12pt, section spacing 28pt
- Sheets: white, corner radius 24 top, list rows, big black Done pill

## Motion
- Restraint: 200-350ms, ease-out; no spring bounce on chrome
- Count changes animate numerically (NumberFlow equivalent)
- Save confirmation: Sonner-style toast — small capsule slides up from
  bottom, auto-dismisses ~2s, one soft haptic
- Tile appearance: gentle fade+scale(0.97→1), never slides across screen
- Later: drag-to-organize collections (dnd kit feel), command-style search sheet (cmdk feel)

## Source icons
Brand logos are bundled Simple Icons SVGs (Assets.xcassets/Brands),
template-rendered and tinted systemGray — never full-color favicons.
Unknown domains get the SF Symbol globe. Add brands by dropping a new
Simple Icons SVG imageset and one mapping row in SourceIcon.

## Anti-rules (learned, do not revisit)
- No dark-navy + teal theme. No warm-paper/museum/heritage styling.
- No decorative texture, no colored category chips, no card borders.
- Do not generate new "design directions" — extend from the references above.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-08 | System derived from Genie/Cosmos/ChatGPT refs | Mickey rejected 3 generated directions; references are the spec |
