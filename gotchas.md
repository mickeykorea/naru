# Gotchas

- 2026-07-08 — Design process: after three rejected AI-generated directions
  (dark-teal cards, hanji museum, and the White Cube/Index/Arcade triptych),
  Mickey said to stop proposing and that he will supply direct links to
  example app interfaces + UI libraries. Rule: for Naru design, do NOT
  generate directions from scratch — work strictly from his references,
  study them, match their patterns exactly (same as his CLAUDE.md rule about
  working code being a better spec than description).

- 2026-07-08 — Design: "warm hanji paper museum / archival editorial" (Open
  Storage Room) also rejected. Two poles dead now: safe dark cards AND warm
  paper heritage. "Beautiful archive" to Mickey ≠ museum metaphor.

- 2026-07-08 — Design: Mickey rejected the v0.2 dark-navy+teal inbox polish as
  generic ("ass design"). Rule: never default to safe dark-theme card lists for
  Naru. His stated memorable-thing is "a beautiful archive" — editorial,
  gallery-like, artifacts on display. Propose distinct directions, not polish.
- 2026-07-08 — Product: MVP scope is share-sheet capture + auto-categorization
  only. No manual paste-a-link inbox as the core interaction.

## 2026-07-08 — Never ship device-rendering theories unverified
Shipped a "device GPU samples the blur mask bottom-up" flip (build 6) based
on a broken-frost report — but the report came from an older build still on
the phone (screenshots predated the fixed build going live). Build 5 with
identical frost code was fine; the flip broke it. Rules:
- Before changing code from a TestFlight report, confirm WHICH build number
  the phone is actually running (TestFlight shows it under the app name).
- Device-affecting rendering changes (esp. private API paths the simulator
  can't reproduce) only ship against a confirmed-good device baseline; if
  the baseline is good, revert to it exactly rather than iterating theory.

## 2026-07-08 — Type: SF Pro only, no wordmark punctuation
Inter (BeReal's font) was rejected same-day: use the system font, always.
Copying a reference's design system means its hierarchy and structure, not
its literal font file or logotype tics ("Naru." period = AI slop). Weight
system, uppercase labels, and no-underline tabs survived.

## 2026-07-08 — Frost "randomly" breaking = UIKit clobbering layer.filters
Every frost regression report (builds 2-10) had one root cause: UIKit
rebuilds UIVisualEffectView internals on scene re-activation and wipes
custom layer.filters -> uniform blur with a hard bottom edge. Applying the
filter once in init is never enough; re-assert in layoutSubviews /
didMoveToWindow / didBecomeActive (identity-check makes it free).
Reproduce BEFORE theorizing: background + re-foreground the app twice in
the simulator. The earlier "device GPU flips the mask" theory was this
bug wearing a costume.

## 2026-07-08 — Scaffold defaults are design decisions waiting to leak
The AccentColor asset kept its scaffold-era teal for 13 builds, invisible
until a Menu label tinted with it. When adopting a design system, sweep
asset-catalog colors too, not just code. Also: new source files need
`xcodegen generate` before they exist to xcodebuild.

## 2026-07-09 — iOS 26 sheets are translucent glass at .medium
The default sheet background at the .medium detent is Liquid Glass, not
systemBackground. Any opaque element pinned inside (the detail hero's
shield) creates a visible two-tone seam. Pin the sheet with
`.presentationBackground(Color(.systemBackground))` whenever sheet content
carries its own opaque backgrounds.

## 2026-07-09 — Horizontal swipes don't cancel SwiftUI buttons
Vertical scrolling cancels a tile Button's press; a horizontal
simultaneousGesture drag does not — finger-up at the end of a category
swipe also fired the tile tap and opened the detail sheet. Veto pattern:
set a flag in the drag's onChanged when horizontal-dominant, guard the
button action on it, lift it ~0.15s after onEnded (the touch-up races
the gesture end).

## 2026-07-09 — Seeding sim app-group defaults: container path only
`simctl spawn <UD> defaults write group.com.mickeyoh.naru ...` writes to
the user-domain prefs, NOT the shared container — reads back fine, app
sees nothing. Write to the real plist instead:
`simctl spawn <UD> defaults write <GroupContainer>/Library/Preferences/group.com.mickeyoh.naru <key> -data <hex>`
where GroupContainer comes from `simctl get_app_container <UD> com.mickeyoh.naru groups`.
UI tests assume seeded fixtures (a spotify item, an "Apple" tile) — reseed
them on any fresh simulator before running NaruUITests.
