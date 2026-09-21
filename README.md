# Naru

Everyone can build anything now. Knowing *what* to build is the
bottleneck, and the answer is already scattered across the places you
save things: Instagram, TikTok, YouTube, Spotify, X, Are.na.

Naru brings those saves into one space so you can see who you are and
decide what to make. Type a thought and your saves gather around it: the
ones that agree, the ones that disagree, the references, the precedents.
What comes back is a brief you can hand to a coding agent.

Naru (나루) is the Korean word for a small river ferry landing: the place
things arrive.

## Two surfaces

| | What it is | Where |
|---|---|---|
| **Web** | The space. One canvas, one bar, one verb: gather. | `web/` |
| **iOS** | The capture end. Share anything into the archive, read it back. | `Naru/`, `NaruShare/` |

## The space (web)

A canvas of every save on one grid. Type a thought in the bar and press
Gather: the saves that relate to it slide into a ring around a new tile,
then re-sort into how they relate — agrees, disagrees, visual, precedent,
how-to, mood. Open the tile and it is a document: every save under the
relationship it has to the idea, the questions your own saves raise
against it, and a build brief to copy.

Also there: a 3D view where distance means relatedness, a scope control
that narrows what Gather pulls from (a source, your favorites, tags), and
a Sources sheet where connections are added and removed.

```sh
cd web
npm install
npm run dev          # http://localhost:3000
```

`?lab=1` opens the same space with DialKit mounted: every layout, timing
and material value is a live knob. Dev only.

**The data is mock.** 1,228 saves, ten hand-written ideas, thumbnails
pulled from public Are.na channels and album covers from Apple's charts.
The scripts that fetch them are in `web/scripts/`. Nothing here talks to a
real platform yet; the sync in the Sources sheet is a replay. Every image
belongs to whoever posted it.

Next.js 16 · React 19 · TypeScript · React Flow · Motion

## The app (iOS)

Share anything to Naru from any app. It collects, categorizes and
summarizes what you save: a two-column tile archive with fetched titles,
thumbnails and source marks, on-device summaries through Apple's
Foundation Models with an extractive fallback, notes, and one search
field across all of it. No server, no API keys, nothing leaves the
device.

SwiftUI · iOS 26 · XcodeGen · fastlane

The Xcode project is generated. `Naru.xcodeproj` is not checked in.

```sh
brew install xcodegen
xcodegen generate
open Naru.xcodeproj
```

### Shipping

fastlane drives the TestFlight pipeline (see `fastlane/Fastfile`):

| Lane | Purpose |
|------|---------|
| `bootstrap` | one-time bundle ID + app record checks |
| `signing` | certificates + provisioning profiles |
| `ship` | build, sign (app + extension), upload to TestFlight |
| `status` | build processing / review state |
| `external` | invite external testers + beta review submission |

Copy `fastlane/.env.example` to `fastlane/.env` and fill in your App
Store Connect API key details. Secrets never enter the repo.

## Documents

`DESIGN.md` holds the design system and a log of every visual decision
with its reason. `gotchas.md` holds the process lessons. Both are kept
out of git. `legacy/` holds the planning documents from before this
direction; where they disagree with the code, the code is right.
