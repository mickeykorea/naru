# Naru

A beautiful personal archive. Share anything to Naru from any app — it
collects, categorizes, and summarizes what you save.

Naru (나루) is the Korean word for a small river ferry landing: the place
things arrive.

## Features

- **Save from anywhere** — share sheet extension accepts links from any
  app; pick a category as you save, Pinterest-style
- **A grid worth looking at** — 2-column tile archive with fetched
  titles, thumbnails, and brand source icons; swipe left/right to page
  between categories
- **Free on-device summaries** — Apple's Foundation Models when
  available, extractive NaturalLanguage fallback everywhere else; no
  server, no API keys, nothing leaves the device
- **Notes** — annotate any save in your own words
- **Search** — one field across titles, sources, categories, summaries,
  and notes
- **iOS 26 native** — Liquid Glass chrome, progressive status-bar frost,
  scroll-collapsing detail hero

## Stack

SwiftUI · iOS 26 · XcodeGen · fastlane

The Xcode project is generated — `Naru.xcodeproj` is not checked in.

```sh
brew install xcodegen
xcodegen generate
open Naru.xcodeproj
```

## Shipping

fastlane drives the whole TestFlight pipeline (see `fastlane/Fastfile`):

| Lane | Purpose |
|------|---------|
| `bootstrap` | one-time bundle ID + app record checks |
| `signing` | certificates + provisioning profiles |
| `ship` | build, sign (app + extension), upload to TestFlight |
| `status` | build processing / review state |
| `external` | invite external testers + beta review submission |

Copy `fastlane/.env.example` to `fastlane/.env` and fill in your App
Store Connect API key details. Secrets never enter the repo.

## Design

The design system lives in [DESIGN.md](DESIGN.md) — references, type
scale, materials, motion rules, and a log of every decision. Process
lessons live in [gotchas.md](gotchas.md).
